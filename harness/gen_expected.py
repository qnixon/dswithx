"""Generate a concept's expected.txt from a chosen reference implementation.

    python3 harness/gen_expected.py --concept NAME --from SLUG [--write]

Without --write, prints the output for review. With --write, saves it to
concepts/NAME/expected.txt; review the diff before committing. Never run this
to make a failing test pass, and never run it in CI.
"""

import argparse
import sys

from common import HarnessError, build_image, discover, parse_lines, run_impl, validate_output


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--concept", required=True, help="concept folder name")
    parser.add_argument("--from", dest="slug", required=True, help="impl folder to use as reference")
    parser.add_argument("--write", action="store_true", help="write expected.txt instead of printing")
    parser.add_argument("--timeout", type=float, default=60)
    args = parser.parse_args()

    matches = [i for i in discover(args.concept) if i.slug == args.slug]
    if not matches:
        raise HarnessError(f"no implementation concepts/{args.concept}/impl/{args.slug}/")
    impl = matches[0]
    if impl.problems:
        raise HarnessError(f"{impl.label} has structure problems:\n  " + "\n  ".join(impl.problems))

    ok, log = build_image(impl.language)
    if not ok:
        raise HarnessError(f"image build failed:\n{log}")
    result = run_impl(impl, args.timeout)
    if result.status != "ok":
        raise HarnessError(f"{impl.label} {result.status}:\n{result.stderr}")

    pairs = parse_lines(result.stdout)
    problems = validate_output(pairs)
    if not pairs:
        problems.append("no output")
    if problems:
        raise HarnessError("output breaks the run contract:\n  " + "\n  ".join(problems))

    text = "".join(f"{name} {value}\n" for name, value in pairs)
    if not args.write:
        sys.stdout.write(text)
        return 0
    path = impl.concept_dir / "expected.txt"
    path.write_text(text)
    print(f"wrote {path.relative_to(impl.concept_dir.parent.parent)} from {impl.label}; "
          "review the values before committing.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except HarnessError as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)
