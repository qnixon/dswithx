"""Shared harness logic: discovery, structure checks, Docker, and comparison.

Standard library only, so the harness runs anywhere Python 3.10+ and Docker do.
"""

import math
import re
import subprocess
import time
import uuid
from dataclasses import dataclass, field
from datetime import date
from itertools import zip_longest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CONCEPTS = REPO / "concepts"
LANGUAGES = REPO / "languages"

VARIANTS = {"from-scratch", "built-in"}
VERIFICATIONS = {"automated", "manual"}
IMPL_KEYS = {"language", "variant", "verification", "verified_on"}
NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")

REL_TOL = 1e-4
ABS_TOL = 1e-6


class HarnessError(Exception):
    pass


def parse_flat_yaml(path):
    """Parse the flat `key: value` subset of YAML used by meta.yaml files.

    Python's standard library has no YAML parser, so meta files are limited to
    one scalar per line. Anything fancier (nesting, lists) is rejected loudly.
    """
    data = {}
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.split(" #", 1)[0].rstrip()
        if not line or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_]*):\s*(.*)", line)
        if not match:
            raise HarnessError(f"{path}:{lineno}: expected 'key: value', got {raw!r}")
        key, value = match.groups()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value = value[1:-1]
        elif value in ("", "null", "~"):
            value = None
        data[key] = value
    return data


@dataclass
class Impl:
    concept: str
    slug: str
    path: Path
    meta: dict = field(default_factory=dict)
    entry: Path | None = None
    problems: list = field(default_factory=list)

    @property
    def label(self):
        return f"{self.concept}/{self.slug}"

    @property
    def language(self):
        return self.meta.get("language")

    @property
    def concept_dir(self):
        return CONCEPTS / self.concept

    @property
    def manual(self):
        return self.meta.get("verification") == "manual"


def check_structure(impl):
    """Record every rule the implementation folder breaks in impl.problems."""
    entries = sorted(p for p in impl.path.glob("main.*") if p.is_file())
    if len(entries) == 1:
        impl.entry = entries[0]
    elif not entries:
        impl.problems.append("missing main.<ext>")
    else:
        impl.problems.append("more than one main.* file: " + ", ".join(p.name for p in entries))

    if not (impl.path / "notes.md").is_file():
        impl.problems.append("missing notes.md")
    if not (impl.concept_dir / "data.csv").is_file():
        impl.problems.append(f"missing concepts/{impl.concept}/data.csv")

    meta_path = impl.path / "meta.yaml"
    if not meta_path.is_file():
        impl.problems.append("missing meta.yaml")
        return
    try:
        impl.meta = parse_flat_yaml(meta_path)
    except HarnessError as e:
        impl.problems.append(str(e))
        return

    missing = IMPL_KEYS - impl.meta.keys()
    if missing:
        impl.problems.append("meta.yaml missing keys: " + ", ".join(sorted(missing)))
    unknown = impl.meta.keys() - IMPL_KEYS
    if unknown:
        impl.problems.append("meta.yaml unknown keys: " + ", ".join(sorted(unknown)))

    lang = impl.language
    if lang and not (LANGUAGES / lang).is_dir():
        impl.problems.append(f"language '{lang}' has no languages/{lang}/ folder")
    elif lang:
        for name in ("Dockerfile", "run.sh"):
            if not (LANGUAGES / lang / name).is_file():
                impl.problems.append(f"missing languages/{lang}/{name}")

    if impl.meta.get("variant") not in VARIANTS:
        impl.problems.append(f"variant must be one of {sorted(VARIANTS)}")
    if impl.meta.get("verification") not in VERIFICATIONS:
        impl.problems.append(f"verification must be one of {sorted(VERIFICATIONS)}")
    if impl.manual:
        verified_on = impl.meta.get("verified_on")
        try:
            date.fromisoformat(verified_on or "")
        except ValueError:
            impl.problems.append("manual verification needs verified_on: YYYY-MM-DD")


def discover(concept=None, language=None):
    """Find implementations, optionally filtered by concept and language.

    The language filter matches the meta.yaml language, so `--language
    postgresql` also selects a `postgresql-builtin` folder.
    """
    impls = []
    for impl_dir in sorted(CONCEPTS.glob("*/impl/*/")):
        concept_name = impl_dir.parent.parent.name
        if concept and concept_name != concept:
            continue
        impl = Impl(concept=concept_name, slug=impl_dir.name, path=impl_dir)
        check_structure(impl)
        if language and impl.language != language:
            continue
        impls.append(impl)
    return impls


def build_image(language):
    """Build dswithx/<language>; Docker's layer cache makes rebuilds cheap.

    On failure, the log ends with apt's own error lines (such as a download
    that failed), which Docker's summary leaves out.
    """
    proc = subprocess.run(
        ["docker", "build", "--progress=plain", "--tag", f"dswithx/{language}",
         str(LANGUAGES / language)],
        capture_output=True,
        text=True,
    )
    log = proc.stderr + proc.stdout
    if proc.returncode == 0:
        return True, log
    # Docker prefixes each line with a step number and time ("#6 1.843 ")
    # and repeats the failing step's output in its summary; drop both.
    apt_lines = []
    for line in log.splitlines():
        line = re.sub(r"^(#\d+ )?[\d.]+ ", "", line)
        if re.search(r"\b(E|Err|W):", line) and line not in apt_lines:
            apt_lines.append(line)
    summary = log[-1200:]
    if apt_lines:
        summary += "\napt reported:\n" + "\n".join(apt_lines[-8:])
    return False, summary


def image_exists(language):
    proc = subprocess.run(
        ["docker", "image", "inspect", f"dswithx/{language}"], capture_output=True
    )
    return proc.returncode == 0


@dataclass
class RunResult:
    status: str  # "ok", "timeout", or "error"
    stdout: str = ""
    stderr: str = ""
    seconds: float = 0.0


def run_impl(impl, timeout):
    """Run one implementation in its language container via run.sh.

    The container has no network, a read-only filesystem except a writable
    /tmp (where compiled languages put build output), and read-only mounts of
    the implementation folder and the concept's data.csv.
    """
    name = f"dswithx-{impl.concept}-{impl.slug}-{uuid.uuid4().hex[:8]}"
    data = impl.concept_dir / "data.csv"
    cmd = [
        "docker", "run", "--rm", "--name", name,
        "--network", "none",
        "--read-only",
        "--tmpfs", "/tmp:rw,exec,size=256m",
        "--mount", f"type=bind,src={impl.path},dst=/work/impl,readonly",
        "--mount", f"type=bind,src={data},dst=/work/data.csv,readonly",
        f"dswithx/{impl.language}",
        "run.sh", f"/work/impl/{impl.entry.name}", "/work/data.csv",
    ]
    start = time.monotonic()
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    try:
        stdout, stderr = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        subprocess.run(["docker", "kill", name], capture_output=True)
        stdout, stderr = proc.communicate()
        return RunResult("timeout", stdout, stderr, time.monotonic() - start)
    seconds = time.monotonic() - start
    status = "ok" if proc.returncode == 0 else "error"
    if proc.returncode != 0:
        stderr = stderr.rstrip() + f"\n(exit code {proc.returncode})"
    return RunResult(status, stdout, stderr, seconds)


def parse_lines(text):
    """Split `name value` output into pairs. Malformed lines keep their text
    as the name with an empty value, so they show up in the comparison."""
    pairs = []
    for line in text.splitlines():
        if not line.strip():
            continue
        parts = line.split(maxsplit=1)
        pairs.append((parts[0], parts[1].strip() if len(parts) > 1 else ""))
    return pairs


def validate_output(pairs):
    """Return a list of contract violations in a program's output."""
    problems = []
    seen = set()
    for name, value in pairs:
        if not NAME_RE.match(name):
            problems.append(f"name {name!r} is not lowercase snake_case")
        if not value or " " in value:
            problems.append(f"line {name!r} must be exactly 'name value'")
        if name in seen:
            problems.append(f"name {name!r} appears more than once")
        seen.add(name)
    return problems


def values_match(expected, actual):
    try:
        e, a = float(expected), float(actual)
    except ValueError:
        return expected == actual
    return math.isclose(e, a, rel_tol=REL_TOL, abs_tol=ABS_TOL)


def compare(expected, actual):
    """Compare by name and order. Returns (all_ok, rows), where each row is
    (ok, expected_name, expected_value, actual_name, actual_value)."""
    rows = []
    for exp, act in zip_longest(expected, actual, fillvalue=("", "")):
        ok = exp[0] == act[0] and bool(exp[0]) and values_match(exp[1], act[1])
        rows.append((ok, exp[0], exp[1], act[0], act[1]))
    return all(row[0] for row in rows), rows


def format_rows(rows, indent="    "):
    """Side-by-side expected/actual table."""
    header = ("", "name", "expected", "actual", "")
    table = [header] + [
        ("✓" if ok else "✗", en, ev, an if an != en else "", av)
        for ok, en, ev, an, av in rows
    ]
    widths = [max(len(r[i]) for r in table) for i in range(5)]
    lines = []
    for mark, en, ev, an, av in table:
        left = f"{en:<{widths[1]}}  {ev:<{widths[2]}}"
        right = f"{an + ' ' if an else ''}{av}"
        lines.append(f"{indent}{mark:<1} {left}   {right}".rstrip())
    return "\n".join(lines)
