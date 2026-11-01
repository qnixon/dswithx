import type { APIRoute } from 'astro';
import { getConcepts, getLanguages } from '../lib/repo';

// A plain sitemap for search engines, built from the same collections as the
// pages, so new concepts and languages are listed automatically.
export const GET: APIRoute = async ({ site }) => {
  const [concepts, languages] = await Promise.all([getConcepts(), getLanguages()]);
  const paths = [
    '/',
    '/concepts/',
    ...concepts.map((c) => `/concepts/${c.id}/`),
    '/languages/',
    ...languages.map((l) => `/languages/${l.id}/`),
    '/rules/',
    '/about/',
  ];
  const urls = paths.map((p) => `  <url><loc>${new URL(p, site)}</loc></url>`).join('\n');
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>
`;
  return new Response(xml, { headers: { 'Content-Type': 'application/xml' } });
};
