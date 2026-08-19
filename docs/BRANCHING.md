# Branching

## One branch per component

`main` holds the whole monorepo and is the only branch anyone commits to.
Every push to `main` automatically republishes each component onto its own
branch, containing **only that folder, with the folder as the repo root**:

| Folder in `main`  | Generated branch      | What it is                        |
| ----------------- | --------------------- | --------------------------------- |
| `CHSHUB_APP/`     | `CHSHUB_resident_app` | Resident app (Flutter)            |
| `security_app/`   | `security_app`        | Security/guard app (Flutter)      |
| `Society_dotNet/` | `society_dotNet`      | Legacy .NET application           |
| `frontend/`       | `Society_web`         | Web frontend (React + Vite)       |
| `backend/`        | `backend`             | Node/Express API — shared by all  |

Because the folder becomes the root, `pubspec.yaml`, `package.json` and
`Society2024.sln` sit at the top level of their branch. A deploy target
(Vercel, Netlify, Codemagic, Azure App Service, …) can be pointed straight at
the branch with no root-directory configuration and no unrelated code in the
checkout.

`SQL/`, `docs/` and repo-level files stay on `main` only.

## Rules

- **Commit to `main` (or a PR into `main`). Never to a component branch.**
  Component branches are regenerated on every push to `main` with a force-push;
  anything committed directly to them is lost.
- Keep a PR to one component where you can. `backend` is shared, so a change to
  it plus its callers is a legitimate multi-component PR — the
  **Component scope** check reports the span as a warning, it never blocks.
- Adding a new component: add the `folder` → `branch` pair to the matrix in
  [.github/workflows/split-branches.yml](../.github/workflows/split-branches.yml)
  and to the map in
  [.github/workflows/component-scope.yml](../.github/workflows/component-scope.yml).
  Renaming a branch is the same one-line edit; the old branch stays behind and
  can be deleted by hand.

## How it works

[.github/workflows/split-branches.yml](../.github/workflows/split-branches.yml)
runs `git subtree split --prefix=<folder>` per component and force-pushes the
result to the component branch. The split is deterministic — the same history
always yields the same commits — so a component branch only moves when its
folder actually changed. Each component's history is preserved: `git log` on
`Society_web` shows the commits that touched `frontend/`, and nothing else.

Runs are serialized (`concurrency: split-branches`) so two pushes in quick
succession cannot race. A component whose split fails does not stop the others
(`fail-fast: false`).

You can also republish every branch on demand from the Actions tab →
**Split component branches** → *Run workflow*.

## History note: the Flutter apps

Until 2026-08-19, `main` recorded `CHSHUB_app` and `Security_app` as gitlinks
(submodule pointers) with no `.gitmodules`, aimed at commits that existed in no
repository — so neither app's source had ever been pushed. Both are now tracked
as ordinary files under `CHSHUB_APP/` and `security_app/`. If either app is
ever moved back out into its own repository, remove its entry from the split
matrix as well.

`CHSHUB_APP/.github/workflows/dart.yml` is an existing Flutter CI workflow. It
is inert in the monorepo (GitHub only reads workflows from the repo root) and
inert on the `CHSHUB_resident_app` branch too, because it triggers on `main`.
Point its trigger at `CHSHUB_resident_app` if you want it to run there.
