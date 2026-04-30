#!/usr/bin/env node
/**
 * Lidi Studio v2 build script
 *
 * Iterates src/{en,pt,es}/**\/*.html, parses each page's meta block,
 * resolves {{HEAD}} / {{NAV}} / {{FOOTER}} / {{SCRIPTS}} from partials/,
 * substitutes per-page and per-language tokens, writes to dist-v2/.
 *
 * Page source format:
 *   <script type="application/json" id="page-meta">
 *   { "title": "...", "description": "...", "slug": "portfolio",
 *     "schema_type": "WebPage", "og_image": "/photos/...", ... }
 *   </script>
 *   <main>...page body...</main>
 */
import { readFile, writeFile, mkdir, readdir, stat, copyFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve('.');
const SRC = path.join(ROOT, 'src');
const PUBLIC = path.join(ROOT, 'public');
const PARTIALS = path.join(ROOT, 'partials');
const OUT = path.join(ROOT, 'dist-v2');
const SITE = 'https://lidi.studio';
const DEFAULT_OG_IMAGE = `${SITE}/photos/hero-angel-wings.jpg`;

const LANGS = ['en', 'pt', 'es'];
const HTML_LANG = { en: 'en', pt: 'pt-BR', es: 'es' };
const OG_LOCALE = { en: 'en_US', pt: 'pt_BR', es: 'es_ES' };

// PT/ES are noindex until native review
const NOINDEX_LANGS = new Set(['pt', 'es']);

// i18n translations for nav, footer, recurring chrome
const i18n = {
  en: {
    nav_portfolio: 'PORTFOLIO',
    nav_sessions: 'SESSIONS',
    nav_stories: 'STORIES',
    nav_about: 'ABOUT',
    nav_inquire: 'INQUIRE',
    footer_tagline: 'Painted, not posed.',
    footer_col_studio: 'STUDIO',
    footer_col_stories: 'STORIES',
    footer_col_contact: 'CONTACT',
    footer_link_method: 'The Method',
    footer_link_drapery: 'Notes on Drapery',
    footer_link_inquire: 'Book a session',
    footer_legal: 'Privacy &nbsp;·&nbsp; Terms &nbsp;·&nbsp; © 2026 Lidi Studio',
  },
  pt: {
    nav_portfolio: 'PORTFÓLIO',
    nav_sessions: 'ENSAIOS',
    nav_stories: 'HISTÓRIAS',
    nav_about: 'SOBRE',
    nav_inquire: 'CONTATO',
    footer_tagline: 'Pintada, não posada.',
    footer_col_studio: 'ESTÚDIO',
    footer_col_stories: 'HISTÓRIAS',
    footer_col_contact: 'CONTATO',
    footer_link_method: 'O Método',
    footer_link_drapery: 'Notas sobre Tecido',
    footer_link_inquire: 'Agendar um ensaio',
    footer_legal: 'Privacidade &nbsp;·&nbsp; Termos &nbsp;·&nbsp; © 2026 Lidi Studio',
  },
  es: {
    nav_portfolio: 'PORTAFOLIO',
    nav_sessions: 'SESIONES',
    nav_stories: 'HISTORIAS',
    nav_about: 'SOBRE',
    nav_inquire: 'CONSULTA',
    footer_tagline: 'Pintada, no posada.',
    footer_col_studio: 'ESTUDIO',
    footer_col_stories: 'HISTORIAS',
    footer_col_contact: 'CONTACTO',
    footer_link_method: 'El Método',
    footer_link_drapery: 'Notas sobre Tejido',
    footer_link_inquire: 'Reservar una sesión',
    footer_legal: 'Privacidad &nbsp;·&nbsp; Términos &nbsp;·&nbsp; © 2026 Lidi Studio',
  },
};

async function readPartial(name) {
  return await readFile(path.join(PARTIALS, name), 'utf8');
}

async function walkHtml(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const out = [];
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...(await walkHtml(full)));
    else if (e.isFile() && e.name.endsWith('.html')) out.push(full);
  }
  return out;
}

function parseMeta(raw) {
  const m = raw.match(/<script\s+type="application\/json"\s+id="page-meta">([\s\S]*?)<\/script>/);
  if (!m) throw new Error('Page is missing <script id="page-meta">');
  return JSON.parse(m[1].trim());
}

function stripMeta(raw) {
  return raw.replace(/<script\s+type="application\/json"\s+id="page-meta">[\s\S]*?<\/script>/, '').trimStart();
}

function applyTokens(template, tokens) {
  return template.replace(/\{\{(\w+)\}\}/g, (_, k) => {
    if (!(k in tokens)) {
      console.warn(`  WARN: unresolved token {{${k}}}`);
      return '';
    }
    return tokens[k];
  });
}

function buildHreflang(slug, availableLangs) {
  const lines = availableLangs.map(l => `<link rel="alternate" hreflang="${l}" href="${SITE}/${l}/${slug}" />`);
  if (availableLangs.includes('en')) {
    lines.push(`<link rel="alternate" hreflang="x-default" href="${SITE}/en/${slug}" />`);
  }
  return lines.join('\n');
}

function buildLangToggle(currentLang, slug, availableLangs) {
  // Hide toggle entirely if only one language exists for this page
  if (availableLangs.length < 2) return '';
  return availableLangs.map(l => {
    const cls = l === currentLang ? 'nav__lang-link nav__lang-link--current' : 'nav__lang-link';
    return `<a class="${cls}" href="/${l}/${slug}">${l.toUpperCase()}</a>`;
  }).join(' · ');
}

async function build() {
  // Ensure dirs
  await mkdir(OUT, { recursive: true });

  const head = await readPartial('head.html');
  const nav = await readPartial('nav.html');
  const footer = await readPartial('footer.html');
  const scripts = await readPartial('scripts.html');

  const pages = await walkHtml(SRC);
  console.log(`Found ${pages.length} pages.`);

  // First pass: index which (lang, slug) combinations exist, so hreflang + lang
  // toggle only point to pages that actually got built.
  const existsBySlug = new Map();
  for (const page of pages) {
    const rel = path.relative(SRC, page);
    const lang = rel.split(path.sep)[0];
    if (!LANGS.includes(lang)) continue;
    const slug = rel.replace(/^[a-z]+[\\/]/, '').replace(/index\.html$/, '').replace(/\.html$/, '').replace(/\\/g, '/');
    if (!existsBySlug.has(slug)) existsBySlug.set(slug, new Set());
    existsBySlug.get(slug).add(lang);
  }

  for (const page of pages) {
    const rel = path.relative(SRC, page);                    // e.g. "en/portfolio/index.html"
    const lang = rel.split(path.sep)[0];
    if (!LANGS.includes(lang)) continue;
    const slug = rel
      .replace(/^[a-z]+[\\/]/, '')                            // strip lang/
      .replace(/index\.html$/, '')                            // foo/index.html → foo/
      .replace(/\.html$/, '')                                 // foo.html → foo
      .replace(/\\/g, '/');                                   // win → posix
    const availableLangs = LANGS.filter(l => existsBySlug.get(slug)?.has(l));

    const raw = await readFile(page, 'utf8');
    const meta = parseMeta(raw);
    const body = stripMeta(raw);

    const t = i18n[lang];
    const canonical = `${SITE}/${lang}/${slug}`;
    const ogImage = meta.og_image
      ? (meta.og_image.startsWith('http') ? meta.og_image : `${SITE}${meta.og_image}`)
      : DEFAULT_OG_IMAGE;
    const robotsMeta = NOINDEX_LANGS.has(lang)
      ? '<meta name="robots" content="noindex,nofollow" />\n<!-- v2: PT/ES held back from indexing pending native-speaker review of translations -->'
      : '';
    const schemaJsonLd = meta.schema
      ? `<script type="application/ld+json">${JSON.stringify(meta.schema)}</script>`
      : '';

    const tokens = {
      LANG: lang,
      LANG_HTML: HTML_LANG[lang],
      OG_LOCALE: OG_LOCALE[lang],
      TITLE: meta.title,
      DESCRIPTION: meta.description,
      CANONICAL: canonical,
      OG_TYPE: meta.og_type || 'website',
      OG_TITLE: meta.og_title || meta.title,
      OG_DESCRIPTION: meta.og_description || meta.description,
      OG_IMAGE: ogImage,
      ROBOTS_META: robotsMeta,
      HREFLANG_BLOCK: buildHreflang(slug, availableLangs),
      EXTRA_HEAD: meta.extra_head || '',
      SCHEMA_JSON_LD: schemaJsonLd,
      LANG_TOGGLE: buildLangToggle(lang, slug, availableLangs),
      NAV_PORTFOLIO: t.nav_portfolio,
      NAV_SESSIONS: t.nav_sessions,
      NAV_STORIES: t.nav_stories,
      NAV_ABOUT: t.nav_about,
      NAV_INQUIRE: t.nav_inquire,
      FOOTER_TAGLINE: t.footer_tagline,
      FOOTER_COL_STUDIO: t.footer_col_studio,
      FOOTER_COL_STORIES: t.footer_col_stories,
      FOOTER_COL_CONTACT: t.footer_col_contact,
      FOOTER_LINK_METHOD: t.footer_link_method,
      FOOTER_LINK_DRAPERY: t.footer_link_drapery,
      FOOTER_LINK_INQUIRE: t.footer_link_inquire,
      FOOTER_LEGAL: t.footer_legal,
    };

    const rendered = [
      applyTokens(head, tokens),
      applyTokens(nav, tokens),
      applyTokens(body, tokens),
      applyTokens(footer, tokens),
      applyTokens(scripts, tokens),
    ].join('\n');

    const outDir = slug ? path.join(OUT, lang, slug) : path.join(OUT, lang);
    const outPath = path.join(outDir, 'index.html');
    await mkdir(outDir, { recursive: true });
    await writeFile(outPath, rendered);
    console.log(`  ✓ /${lang}/${slug || ''} → ${path.relative(ROOT, outPath)}`);
  }

  // Copy public/ to dist-v2/
  await copyDir(PUBLIC, OUT);

  // Root redirect: /  → /en/
  await writeFile(
    path.join(OUT, 'index.html'),
    `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta http-equiv="refresh" content="0; url=/en/" />
<link rel="canonical" href="${SITE}/en/" />
<title>Lidi Studio</title>
</head>
<body>
<p>Redirecting to <a href="/en/">/en/</a>.</p>
</body>
</html>
`
  );
  console.log('  ✓ / (root meta-refresh → /en/)');

  console.log('\nBuild complete.');
}

async function copyDir(src, dest) {
  if (!existsSync(src)) return;
  const entries = await readdir(src, { withFileTypes: true });
  for (const e of entries) {
    const s = path.join(src, e.name);
    const d = path.join(dest, e.name);
    if (e.isDirectory()) {
      await mkdir(d, { recursive: true });
      await copyDir(s, d);
    } else if (e.isFile()) {
      await copyFile(s, d);
    }
  }
}

build().catch(err => {
  console.error('BUILD FAILED:', err);
  process.exit(1);
});
