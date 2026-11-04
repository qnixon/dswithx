# DS with X

Data science concepts implemented from scratch in many languages, using only
what ships with each language. Every example on [dswithx.com](https://dswithx.com)
is the exact file the test harness ran and verified.

## Requirements

- Docker (each language runs in its own pinned container)
- Python 3.10+ on the host, to run the harness (standard library only)

## Run the tests

```sh
python3 harness/run_tests.py                       # everything
python3 harness/run_tests.py --concept descriptive-statistics
python3 harness/run_tests.py --language python
```

Each implementation runs in its language's container with no network and a
read-only filesystem. Its stdout is compared with the concept's `expected.txt`
(relative tolerance 1e-4 or absolute 1e-6, whichever is looser). On failure the
harness prints expected and actual values side by side and exits non-zero.

## Repository layout

```
concepts/<concept>/          one folder per concept
  concept.mdx, meta.yaml     explanation and metadata
  data.csv, expected.txt     shared dataset and correct output
  impl/<slug>/               one folder per implementation
    main.<ext>, notes.md, meta.yaml
languages/<lang>/            Dockerfile, run.sh, language.md
harness/                     test runner
site/                        Astro website
```

## The run contract

`languages/<lang>/run.sh <source-file> <data-file>` compiles if needed (into
`/tmp`, the only writable path) and runs the program with the data file path as
its first argument. The program prints one `name value` line per result, in
`expected.txt` order, with numbers to six decimal places. Nothing else goes to
stdout.

`meta.yaml` files use flat `key: value` YAML only (no nesting or lists), because
the harness parses them with the Python standard library.

## Add a language

1. Create `languages/<lang>/` with a `Dockerfile` pinned to an exact toolchain
   version (no third-party packages), a `run.sh` that follows the run contract
   and is copied to `/usr/local/bin/run.sh`, and a `language.md`.
2. Add `concepts/<concept>/impl/<lang>/` with `main.<ext>`, `notes.md`, and
   `meta.yaml`.
3. Run `python3 harness/run_tests.py --language <lang>`.

## Add a concept

1. Create `concepts/<concept>/` with `concept.mdx`, `meta.yaml`, and `data.csv`.
2. Write a reference implementation, then generate expected output from it:

   ```sh
   python3 harness/gen_expected.py --concept <concept> --from <slug>          # review
   python3 harness/gen_expected.py --concept <concept> --from <slug> --write  # save
   ```

   Check the values independently before committing. Never regenerate
   `expected.txt` to make a failing test pass.

## Run the site

The site is an [Astro](https://astro.build) project in `site/`. It reads
`concepts/` and `languages/` directly at build time; no code is copied into it.
Use Node.js 26 LTS (see `.nvmrc`).

```sh
cd site
npm ci              # install the pinned dependencies
npm run dev         # live preview at http://localhost:4321
npm run build       # static site in site/dist/
npm run preview     # serve the built site
```

Math in `concept.mdx` (`$...$` and `$$...$$`) is rendered with KaTeX at build
time. MDX does not accept HTML comments; use `{/* ... */}` instead.

## CI and deployment

GitHub Actions runs two workflows:

- **CI** (`.github/workflows/ci.yml`), on every push and pull request. Tests
  the languages a change affects (`harness/ci_plan.py` decides), one matrix job
  per language, and builds the site. On `main` it tests every language and,
  only if all pass, deploys `site/dist` to Cloudflare with `wrangler deploy`.
  Each language image is kept in the Actions cache, keyed on a hash of
  `languages/<lang>/`, and rebuilt only when that folder changes; on a cache
  hit the harness runs with `--skip-build`.
- **Full test** (`.github/workflows/full-test.yml`), weekly and on demand.
  Tests everything, to catch drift no commit caused.

The site is served by Cloudflare Workers Static Assets with no Worker script
(`site/wrangler.jsonc`). Deploying needs two repository secrets, set under
Settings → Secrets and variables → Actions: `CLOUDFLARE_API_TOKEN` (a token
with Workers edit permission) and `CLOUDFLARE_ACCOUNT_ID`.

## License

Code is MIT ([LICENSE](LICENSE)). Prose (`*.md`, `*.mdx`) is CC BY 4.0
([LICENSE-CONTENT](LICENSE-CONTENT)).
