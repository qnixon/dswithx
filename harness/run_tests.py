"""Run every implementation in its container and compare against expected.txt.

    python3 harness/run_tests.py [--concept NAME] [--language NAME] [--timeout SECONDS]

Exits non-zero if any implementation fails, times out, errors, or breaks the
repository's structure rules.
"""

import argparse
import sys

from common import (
    HarnessError, build_image, compare, discover, format_rows, parse_lines, run_impl,
)


def indent(text, prefix="    "):
    return "\n".join(prefix + line for line in text.strip().splitlines())


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--concept", help="only this concept (folder name)")
    parser.add_argument("--language", help="only this language (meta.yaml language)")
    parser.add_argument("--timeout", type=float, default=60, help="seconds per run (default 60)")
    args = parser.parse_args()

    impls = discover(args.concept, args.language)
    if not impls:
        print("No implementations matched.", file=sys.stderr)
        return 1

    # Build each needed image once, before running anything.
    languages = sorted({i.language for i in impls if not i.problems and not i.manual})
    build_errors = {}
    for lang in languages:
        print(f"building dswithx/{lang} ...", file=sys.stderr, flush=True)
        ok, log = build_image(lang)
        if not ok:
            build_errors[lang] = log

    counts = {"pass": 0, "fail": 0, "skip": 0}
    for impl in impls:
        status, detail = check(impl, build_errors, args.timeout)
        counts["pass" if status.startswith("PASS") else "skip" if status.startswith("SKIP") else "fail"] += 1
        print(f"{status:<10} {impl.label}")
        if detail:
            print(detail)

    print(f"\n{counts['pass']} passed, {counts['fail']} failed, {counts['skip']} skipped")
    return 1 if counts["fail"] else 0


def check(impl, build_errors, timeout):
    """Return (status, detail) for one implementation."""
    if impl.problems:
        return "ERROR", indent("\n".join(impl.problems))
    if impl.manual:
        return "SKIP", indent(f"manually verified on {impl.meta['verified_on']}")
    if impl.language in build_errors:
        return "ERROR", indent("image build failed:\n" + build_errors[impl.language][-2000:])

    expected_path = impl.concept_dir / "expected.txt"
    if not expected_path.is_file():
        return "ERROR", indent(f"missing concepts/{impl.concept}/expected.txt")
    expected = parse_lines(expected_path.read_text())

    result = run_impl(impl, timeout)
    if result.status == "timeout":
        return "TIMEOUT", indent(f"no result after {timeout:g}s")
    if result.status == "error":
        return "ERROR", indent(result.stderr[-2000:] or "(no stderr)")

    ok, rows = compare(expected, parse_lines(result.stdout))
    if ok:
        return "PASS", ""
    return "FAIL", format_rows(rows)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except HarnessError as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)
