"""Decide which languages CI must test, from the files changed since a commit.

    python3 harness/ci_plan.py [--base SHA] [--all]

Prints a JSON list of language names for the CI test matrix. Everything is
tested when --all is given, when the base commit is missing or unknown, or when
the harness or CI configuration changed.
"""

import argparse
import json
import subprocess

from common import REPO, discover

RETEST_ALL_PREFIXES = ("harness/", ".github/workflows/")


def changed_files(base):
    """Paths changed between base and HEAD, or None if that can't be determined."""
    if not base or set(base) == {"0"}:
        return None
    proc = subprocess.run(
        ["git", "diff", "--name-only", base, "HEAD"],
        cwd=REPO, capture_output=True, text=True,
    )
    return proc.stdout.split() if proc.returncode == 0 else None


def affected_languages(paths, impls):
    if any(p.startswith(RETEST_ALL_PREFIXES) for p in paths):
        return {i.language for i in impls}
    languages = set()
    for path in paths:
        parts = path.split("/")
        if parts[0] == "languages" and len(parts) > 2:
            languages.add(parts[1])
        elif parts[0] == "concepts" and len(parts) > 2:
            concept = parts[1]
            if len(parts) > 4 and parts[2] == "impl":
                # One implementation changed: retest its language only.
                languages.update(i.language for i in impls if i.concept == concept and i.slug == parts[3])
            else:
                # Shared concept files (data.csv, expected.txt): retest every language in it.
                languages.update(i.language for i in impls if i.concept == concept)
    return languages


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--base", help="commit to diff against")
    parser.add_argument("--all", action="store_true", help="test every language")
    args = parser.parse_args()

    # Only languages with automated implementations can be tested; structure
    # problems still count, so the harness reports them.
    impls = [i for i in discover() if i.language and not i.manual]
    paths = None if args.all else changed_files(args.base)
    languages = {i.language for i in impls} if paths is None else affected_languages(paths, impls)
    print(json.dumps(sorted(languages & {i.language for i in impls})))


if __name__ == "__main__":
    main()
