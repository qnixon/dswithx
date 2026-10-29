// Content collections read straight from the repository's concepts/ and
// languages/ folders (outside site/), so the site always shows the tested files.
import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const CONCEPTS = '../concepts';
const LANGUAGES = '../languages';

// Ids come from folder paths: "descriptive-statistics" for a concept,
// "descriptive-statistics/python" for an implementation, "python" for a language.
const folderId = ({ entry }: { entry: string }) =>
  entry.split('/').slice(0, -1).join('/').replace('/impl/', '/');

const concepts = defineCollection({
  loader: glob({ base: CONCEPTS, pattern: '*/meta.yaml', generateId: folderId }),
  schema: z.object({
    title: z.string(),
    summary: z.string(),
    order: z.number(),
    difficulty: z.string(),
    column: z.string(),
  }),
});

const conceptText = defineCollection({
  loader: glob({ base: CONCEPTS, pattern: '*/concept.mdx', generateId: folderId }),
});

const implementations = defineCollection({
  loader: glob({ base: CONCEPTS, pattern: '*/impl/*/meta.yaml', generateId: folderId }),
  schema: z.object({
    language: z.string(),
    variant: z.enum(['from-scratch', 'built-in']),
    verification: z.enum(['automated', 'manual']),
    verified_on: z.coerce.date().nullable(),
  }),
});

const implNotes = defineCollection({
  loader: glob({ base: CONCEPTS, pattern: '*/impl/*/notes.md', generateId: folderId }),
});

const languages = defineCollection({
  loader: glob({ base: LANGUAGES, pattern: '*/language.md', generateId: folderId }),
  schema: z.object({
    name: z.string(),
    first_appeared: z.number(),
    paradigm: z.string(),
    toolchain: z.string(),
    image: z.string(),
    // Shiki grammar id; omitted when Shiki has none, and code shows as plain text.
    highlight: z.string().optional(),
  }),
});

export const collections = { concepts, conceptText, implementations, implNotes, languages };
