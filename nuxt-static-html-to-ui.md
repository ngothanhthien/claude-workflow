---
name: nuxt-static-html-to-ui
description: Convert a static HTML/CSS export (zip) into valid Nuxt 4+ pages/components while preserving UI/UX only (no app logic).
license: MIT
---

# Nuxt 4+ UI-Only Converter (Static HTML/CSS → Nuxt SFC)

## Goal

Convert a static website export (HTML + CSS + assets) into **valid Nuxt 4+ Vue SFCs** that reproduce the same UI/UX:

- Preserve DOM structure, class names, spacing, layout, typography, and visuals.
- Keep CSS working (prefer reusing original CSS files).
- Do **NOT** implement application logic, API calls, authentication, QR generation, framework behavior (Angular/React/jQuery), analytics, tracking, or scripts.

“UI-only” means: **template markup + styles + static assets**, optionally basic head tags.

---

## Input Format (folder)

The user will input folder similar to:

- `index.html` (and possibly more `.html` files)
- `stylesheet_0.css`, `stylesheet_1.css` (or other `.css`)
- asset folders like `images/`, `fonts/`
- optional `manifest.json`, icons, etc.

The folder may contain either:

- files at the root, or
- a single top-level folder containing everything.

---

## Output Requirements

Produce Nuxt 4+ project files (or a patch) that includes:

1. **Pages**
   - Convert each `.html` file into a Nuxt page in `pages/`.
   - `index.html` → `pages/index.vue`
   - `about.html` → `pages/about.vue`
   - Nested folders map to nested routes (e.g. `docs/faq.html` → `pages/docs/faq.vue`).

2. **No Business Logic**
   - No data fetching (`useFetch`, `$fetch`, API integration).
   - No server routes / backend endpoints.
   - No state management unless needed to prevent Vue errors.
   - Do not recreate original JS behavior (Angular, jQuery, etc.).

3. **Valid Vue Template**
   - Vue SFC must compile in Nuxt without template errors.
   - Ensure a **single root element** inside `<template>`.

4. **Asset & CSS Preservation**
   - Keep the original CSS files functional with minimal edits.
   - Make sure all fonts/images referenced by CSS and HTML load correctly (no 404).

---

## Conversion Strategy (High-Level)

### A) Extract the UI Markup

For each HTML file:

1. Take only the content inside `<body>`.
2. Drop:
   - all `<script>...</script>` blocks (inline or external)
   - tracking/analytics tags
   - framework bootstraps / runtime glue
3. Keep:
   - structural markup
   - classes/ids/data-attributes
   - `<svg>` and inline icons
   - forms and inputs (UI only; no submit logic)

### B) Put Assets Under `/public/vendor/<slug>/`

Use a stable folder name, e.g.:

- `vendor/static-ui/` (or derived from folder name)

Copy the folder’s static assets into:

```
public/vendor/<slug>/
  stylesheet_0.css
  stylesheet_1.css
  images/
  fonts/
  manifest.json (optional)
```

**Important:** preserve relative structure so CSS `url(...)` references keep working.

### C) Rewrite Asset Paths Inside Templates

Because Nuxt routes are not file paths, **relative URLs in HTML must be rewritten**.

Rewrite these attributes whenever they reference local assets:

- `src`
- `href` (only for asset files, not navigation links)
- `srcset` (rewrite every URL inside)
- inline styles containing `url(...)` (only if present)

Rules to detect “local asset” paths:

- Starts with: `images/`, `fonts/`, `assets/`, `./`, or a filename like `logo.png`
- Does **NOT** start with: `http://`, `https://`, `//`, `mailto:`, `tel:`, `#`

Rewrite to:

- `/vendor/<slug>/...`

Examples:

- `src="images/12.png"` → `src="/vendor/<slug>/images/12.png"`
- `href="stylesheet_0.css"` → `href="/vendor/<slug>/stylesheet_0.css"`

### D) Load CSS Globally (Preferred)

Prefer leaving CSS files as-is in `public/vendor/<slug>/` and loading them via global head tags.

Option 1 (recommended): add to `nuxt.config.ts`:

```ts
export default defineNuxtConfig({
  app: {
    head: {
      link: [
        { rel: 'stylesheet', href: '/vendor/<slug>/stylesheet_0.css' },
        { rel: 'stylesheet', href: '/vendor/<slug>/stylesheet_1.css' },
      ],
    },
  },
})
```

Option 2: per-page head using `useHead()` in `<script setup>` (only if you cannot touch `nuxt.config.ts`).

### E) Convert Links & Images to Nuxt Components (UI-Safe)

#### Links

- Internal navigation links (`href="/about"` or `href="pricing.html"`) → `<NuxtLink>`.
- In-page anchors (`href="#section"`) can remain `<a href="#section">`.
- External links should use `<NuxtLink external>` or keep `<a target="_blank" rel="noopener">`.

Heuristic:

- If it looks like a site route: use `<NuxtLink>`.
- If it’s a file asset (`.css`, `.png`, `.svg`, `.ico`): keep as asset link and rewrite to `/vendor/<slug>/...`.

#### Images

Prefer `<NuxtImg>` if `@nuxt/image` is available; otherwise keep `<img>`.

- Ensure `alt` exists (derive from filename if missing).
- Rewrite `src` to `/vendor/<slug>/...`.

Example:

```vue
<NuxtImg src="/vendor/<slug>/images/12.png" alt="12" />
```

---

## Vue / Nuxt SFC Output Pattern

For each converted page:

```vue
<script setup lang="ts">
// UI-only head usage if needed
useHead({
  title: 'Page Title',
})
</script>

<template>
  <div class="page-root">
    <!-- body content pasted here, cleaned -->
  </div>
</template>

<!-- Avoid scoped unless you're sure: original CSS is global -->
<style>
/* optional tiny fixes only if absolutely necessary */
</style>
```

---

## Cleaning Rules (Strict)

1. **Remove scripts**
   - Drop all `<script>` tags (inline or external).

2. **Remove framework runtime hooks**
   - Remove or ignore: `ng-*`, `data-reactroot`, etc.
   - It’s okay to keep unknown attributes if they do not create Vue template conflicts.

3. **Handle mustache collisions**
   - If HTML contains `{{something}}` in **text nodes**, Vue will try to evaluate it.
   - Fix by wrapping that region with `v-pre`, or replace with a static placeholder string.

4. **No functional re-implementation**
   - Do not recreate click handlers, QR generation, form submit logic.
   - Buttons/inputs are presentational only.

---

## Quality Checklist (Before Final Output)

- [ ] Nuxt page compiles (no Vue template compilation errors)
- [ ] All local assets resolve (no 404 for images/fonts/css)
- [ ] CSS is loaded globally and UI looks close to original
- [ ] Only UI/UX changes were made (no business logic added)
- [ ] Internal navigation uses `<NuxtLink>` where appropriate
- [ ] Images have `alt` text

---

## What to Return

Return:

1. The list of files created/modified with paths.
2. Full contents of each new/modified file.
3. Notes about leftover non-UI elements you intentionally removed (scripts, trackers, etc.).
