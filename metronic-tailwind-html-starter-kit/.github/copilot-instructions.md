# Copilot Instructions for Metronic Tailwind HTML Starter Kit

## Project Overview
- **Purpose:** A starter kit for Metronic 9, using Tailwind CSS, TypeScript, and Webpack. Provides modular HTML, JS, and CSS for modern web apps.
- **Key Directories:**
  - `src/core/`: Core utilities, base components, and types.
  - `src/app/`: App-specific modules (e.g., datatables, layouts, widgets).
  - `src/css/`: Tailwind and custom CSS, organized by components and demos.
  - `src/vendors/`: Third-party libraries and plugins (e.g., form validation, charts).

## Architecture & Patterns
- **Component System:**
  - Core UI logic is in `src/core/components/` (see `component.ts`).
  - Components use a base class (`KTComponent`) with event, config, and DOM helpers.
  - DataTables and widgets are implemented as classes, often with `render` and `createdCell` hooks for custom cell logic.
- **Dynamic Entry Points:**
  - Webpack auto-discovers all `.js` and `.ts` files in `src/app/` as entry points (see `FilesHandler` in `webpack.config.js`).
  - Each entry is bundled separately, supporting modular builds.
- **Configuration:**
  - Global config can be set via `window.KTGlobalComponentsConfig` or `src/core/components/config.ts`.
  - DataTable configs are typically defined per-table, with API endpoints and column renderers.

## Developer Workflows
- **Build:**
  - `npm run build` — Build both CSS and JS for development.
  - `npm run build:prod` — Production build (minified, optimized).
  - `npm run build:css:watch` — Watch and rebuild CSS on changes.
- **Lint:**
  - `npm run lint` — Lint TypeScript in `src/core/`.
- **No tests are defined by default.**

## Conventions & Tips
- **TypeScript is used for core and app logic; prefer `.ts` for new modules.**
- **Custom DataTable columns:** Use `render` and `createdCell` for interactive cells (see `allowed-ip-addresses.ts`).
- **API endpoints:** Switch between local and remote URLs based on hostname (see `allowed-ip-addresses.ts`).
- **Vendor assets:** Managed via `webpack.vendors.js` and copied/bundled by Webpack.
- **Raw HTML templates:** Found in `dist/html` (not tracked in `src/`).

## Integration Points
- **Form validation:** Uses `@form-validation` plugins (see `src/vendors/@form-validation/`).
- **Charts, maps, icons:** Integrated via vendor bundles (see `webpack.vendors.js`).

## References
- For new UI logic, extend `KTComponent` and follow patterns in `src/core/components/`.
- For new app modules, add `.ts` files to `src/app/` — they will be auto-bundled.
- For CSS, add to `src/css/components/` or `src/css/demos/` and import in `styles.css`.

---
If any section is unclear or missing, please provide feedback for further refinement.
