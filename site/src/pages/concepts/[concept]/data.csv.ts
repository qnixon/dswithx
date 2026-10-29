// Serves each concept's dataset at /concepts/<concept>/data.csv. The file is
// read from concepts/ at build time; nothing is copied into site/.
import type { APIRoute } from 'astro';
import { getConcepts, readRepoFile } from '../../../lib/repo';

export async function getStaticPaths() {
  const concepts = await getConcepts();
  return concepts.map((concept) => ({ params: { concept: concept.id } }));
}

export const GET: APIRoute = ({ params }) =>
  new Response(readRepoFile(`concepts/${params.concept}/data.csv`), {
    headers: { 'Content-Type': 'text/csv; charset=utf-8' },
  });
