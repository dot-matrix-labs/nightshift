# The Documentation Fractal

The "Documentation Fractal" is a Nightshift methodology principle ensuring that autonomous agents can navigate a codebase without requiring a vector database, RAG, or external search tools.

## Core Principle

**"The codebase is the map."**

Every directory is a node in a tree. Every node must describe itself.

## Rules

### 1. The Root Anchor

The project root must contain a `README.md` that serves as the "High Orbit" view. It points to the main entry points (e.g., `./docs/README.md`, `./src/README.md`).

### 2. No Stranded Docs

There should be **no documentation files** (other than `README.md`) outside of the canonical `./docs/` directory.

- **Why?** Scatter-gun documentation gets lost. By centralizing "substantive" documentation in `./docs/`, agents know exactly where to look for knowledge.
- **Exception**: `README.md` files are allowed (and required) in every sub-directory to explain _what that directory contains_.

### 3. The Fractal Structure

Every subdirectory (node) should contain a `README.md` that:

1.  **Summarizes** the directory's purpose.
2.  **Lists** key files or subdirectories.
3.  **Links** back to the "parent" knowledge base if deeper context is needed (usually in `./docs/`).

```
root/
├── README.md              # High Orbit: "What is this project?" -> Links to docs/README.md
├── src/
│   ├── README.md          # "This is the source code." -> Links to architecture docs in docs/technical/
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── README.md  # "This handles auth." -> Links to auth specs in docs/features/
```

### 4. Canonical Naming

All documentation files inside `./docs/` must use **kebab-case** (`my-doc.md`) to ensure consistent URL routing and OS compatibility.

## Benefits for Agents

1.  **O(1) Navigation**: An agent entering `src/managers/` can read `README.md` to understand the context immediately.
2.  **Deterministic Search**: Agents don't need to guess "where are the docs?". They are always in `./docs/` or in the local `README.md`.
3.  **Self-healing**: If an agent adds a new directory, the "Documentation Nag" (or protocol) reminds them to add a `README.md`.
