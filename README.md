# Scan Run Web App

A lightweight, production-minded starter web application with:

- A documented architecture and delivery plan.
- A working client-side site (no build tools required).
- A modular JavaScript code structure that can scale.

## Quick start

Run a local web server from the repository root:

```bash
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

## What is included

- `docs/ARCHITECTURE.md` — high-level design architecture and roadmap.
- `index.html` — semantic app shell.
- `styles.css` — responsive, accessible styling system.
- `app.js` — modular app logic with persistence in `localStorage`.

## Features

- Task creation/edit/delete.
- Status workflow (`backlog`, `in-progress`, `done`).
- Priority levels and filtering.
- Search and statistics.
- Persistent storage in the browser.

## Next steps

See the architecture document for a staged evolution into a full stack deployment with API, auth, observability, CI/CD, and managed infrastructure.
