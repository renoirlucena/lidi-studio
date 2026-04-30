#!/usr/bin/env node
import { readFile, writeFile } from 'node:fs/promises';

const FILE = 'src/index.html';
const html = await readFile(FILE, 'utf8');

// Match <img ... src="/photos/<name>.jpg" ... />
// Wrap with <picture><source avif><source webp><img.../></picture>
// Preserve all img attributes including style and loading.
let count = 0;
const out = html.replace(
  /<img\s+([^>]*?)src="\/photos\/([^"]+)\.jpg"([^>]*?)\/?>/g,
  (_full, attrsBefore, base, attrsAfter) => {
    count++;
    return `<picture>` +
      `<source srcset="/photos/${base}.avif" type="image/avif">` +
      `<source srcset="/photos/${base}.webp" type="image/webp">` +
      `<img ${attrsBefore}src="/photos/${base}.jpg"${attrsAfter}/>` +
      `</picture>`;
  }
);

await writeFile(FILE, out);
console.log(`Wrapped ${count} <img> tags with <picture> AVIF/WebP fallback chain.`);
