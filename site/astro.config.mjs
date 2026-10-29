import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import { unified } from '@astrojs/markdown-remark';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';

export default defineConfig({
  site: 'https://dswithx.com',
  trailingSlash: 'always',
  integrations: [mdx()],
  markdown: {
    // Astro 7 defaults to its Sätteri processor; unified() keeps the
    // remark/rehype pipeline that remark-math and rehype-katex plug into.
    // $...$ and $$...$$ become KaTeX HTML at build time, so readers'
    // browsers run no math JavaScript.
    processor: unified({
      remarkPlugins: [remarkMath],
      rehypePlugins: [rehypeKatex],
    }),
    shikiConfig: {
      themes: { light: 'github-light', dark: 'github-dark' },
      defaultColor: false,
    },
  },
});
