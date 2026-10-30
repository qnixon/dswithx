// Build-time access to the repository: collections for structured content,
// and plain file reads for raw text (source code, data, expected output).
import fs from 'node:fs';
import path from 'node:path';
import { getCollection, type CollectionEntry } from 'astro:content';
import { LANGUAGES_FIRST } from '../site';

// Astro runs from site/, so the repository root is one level up.
export const ROOT = path.resolve(process.cwd(), '..');
if (!fs.existsSync(path.join(ROOT, 'concepts'))) {
  throw new Error(`Expected concepts/ under ${ROOT}; run Astro from the site/ folder.`);
}

export const readRepoFile = (repoPath: string) =>
  fs.readFileSync(path.join(ROOT, repoPath), 'utf8');

export type Language = CollectionEntry<'languages'>;

/** Sort order for languages: LANGUAGES_FIRST in order, then by name. */
function compareLanguages(a: Language, b: Language) {
  const rank = (l: Language) => {
    const i = LANGUAGES_FIRST.indexOf(l.id);
    return i === -1 ? LANGUAGES_FIRST.length : i;
  };
  return rank(a) - rank(b) || a.data.name.localeCompare(b.data.name);
}

export interface Implementation {
  concept: string;
  slug: string;
  meta: CollectionEntry<'implementations'>['data'];
  language: Language;
  notes: CollectionEntry<'implNotes'> | undefined;
  file: { name: string; path: string; code: string };
}

export async function getConcepts() {
  const concepts = await getCollection('concepts');
  return concepts.sort((a, b) => a.data.order - b.data.order);
}

export async function getLanguages() {
  const languages = await getCollection('languages');
  return languages.sort(compareLanguages);
}

function entryFile(concept: string, slug: string) {
  const dir = `concepts/${concept}/impl/${slug}`;
  const name = fs.readdirSync(path.join(ROOT, dir)).find((f) => f.startsWith('main.'));
  if (!name) throw new Error(`No main.<ext> in ${dir}`);
  return { name, path: `${dir}/${name}`, code: readRepoFile(`${dir}/${name}`) };
}

/** Every implementation, ordered by language (see compareLanguages) then folder slug. */
export async function getImplementations(concept?: string): Promise<Implementation[]> {
  const [metas, notes, languages] = await Promise.all([
    getCollection('implementations'),
    getCollection('implNotes'),
    getCollection('languages'),
  ]);
  const impls = metas
    .map((m) => {
      const [conceptId, slug] = m.id.split('/');
      const language = languages.find((l) => l.id === m.data.language);
      if (!language) throw new Error(`${m.id}: unknown language ${m.data.language}`);
      return {
        concept: conceptId,
        slug,
        meta: m.data,
        language,
        notes: notes.find((n) => n.id === m.id),
        file: entryFile(conceptId, slug),
      };
    })
    .filter((i) => !concept || i.concept === concept);
  return impls.sort(
    (a, b) => compareLanguages(a.language, b.language) || a.slug.localeCompare(b.slug),
  );
}

/** Parse `name value` lines (expected.txt format). */
export function parseResults(text: string) {
  return text
    .split('\n')
    .filter((line) => line.trim())
    .map((line) => {
      const [name, value] = line.trim().split(/\s+/, 2);
      return { name, value };
    });
}

/** Minimal CSV split for previews: the datasets have no quoted fields. */
export function parseCsv(text: string) {
  const [header, ...rows] = text.trim().split('\n').map((line) => line.split(','));
  return { header, rows };
}
