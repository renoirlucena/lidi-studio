#!/usr/bin/env node
import sharp from 'sharp';
import { readdir, stat, mkdir } from 'node:fs/promises';
import path from 'node:path';

const SRC = 'public/photos';
const MAX_WIDTH = 1600;
const JPEG_QUALITY = 80;
const WEBP_QUALITY = 75;
const AVIF_QUALITY = 60;

const files = (await readdir(SRC))
  .filter(f => /\.jpe?g$/i.test(f))
  .filter(f => !f.includes('.optimized.'))
  .sort();

let totalBefore = 0;
let totalAfterJpeg = 0;
let totalAfterWebp = 0;
let totalAfterAvif = 0;

for (const file of files) {
  const inPath = path.join(SRC, file);
  const base = file.replace(/\.jpe?g$/i, '');
  const before = (await stat(inPath)).size;
  totalBefore += before;

  const img = sharp(inPath).rotate();
  const meta = await img.metadata();
  const width = Math.min(meta.width, MAX_WIDTH);

  await img
    .clone()
    .resize({ width, withoutEnlargement: true })
    .jpeg({ quality: JPEG_QUALITY, mozjpeg: true })
    .toFile(`${SRC}/${base}.jpg.tmp`);

  await img
    .clone()
    .resize({ width, withoutEnlargement: true })
    .webp({ quality: WEBP_QUALITY })
    .toFile(`${SRC}/${base}.webp`);

  await img
    .clone()
    .resize({ width, withoutEnlargement: true })
    .avif({ quality: AVIF_QUALITY })
    .toFile(`${SRC}/${base}.avif`);

  const { rename } = await import('node:fs/promises');
  await rename(`${SRC}/${base}.jpg.tmp`, inPath);

  const afterJpeg = (await stat(inPath)).size;
  const afterWebp = (await stat(`${SRC}/${base}.webp`)).size;
  const afterAvif = (await stat(`${SRC}/${base}.avif`)).size;

  totalAfterJpeg += afterJpeg;
  totalAfterWebp += afterWebp;
  totalAfterAvif += afterAvif;

  const kb = b => (b / 1024).toFixed(0).padStart(5);
  console.log(
    `  ${file.padEnd(28)}  ${kb(before)}KB → jpeg ${kb(afterJpeg)}KB  webp ${kb(afterWebp)}KB  avif ${kb(afterAvif)}KB`
  );
}

const mb = b => (b / 1024 / 1024).toFixed(2);
console.log('');
console.log(`Total before:        ${mb(totalBefore)}MB`);
console.log(`Total after JPEG:    ${mb(totalAfterJpeg)}MB  (${((1 - totalAfterJpeg/totalBefore)*100).toFixed(0)}% smaller)`);
console.log(`Total WebP variants: ${mb(totalAfterWebp)}MB  (${((1 - totalAfterWebp/totalBefore)*100).toFixed(0)}% smaller)`);
console.log(`Total AVIF variants: ${mb(totalAfterAvif)}MB  (${((1 - totalAfterAvif/totalBefore)*100).toFixed(0)}% smaller)`);
console.log(`AVIF + WebP + JPEG bundled: ${mb(totalAfterJpeg + totalAfterWebp + totalAfterAvif)}MB`);
