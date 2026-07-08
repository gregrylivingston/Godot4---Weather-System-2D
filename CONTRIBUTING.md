# Contributing

Thanks for your interest in Weather System 2D! This is a small, focused kit — issues, ideas,
and PRs are all welcome.

## Project layout

- `addons/weather2d/` — the plugin (nodes, shaders, resources, api). See
  [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).
- `demos/` — example scenes (`launcher` is the main scene).
- `addons/weather2d/assets/svg/` — vector props (bundled inside the addon so it's self-contained).
- `tests/` — a zero-dependency headless test suite.
- `docs/` — architecture, roadmap, and `docs/api/` reference.

## Setup

1. Install **Godot 4.7** (the version the kit is developed and tested on).
2. Open the folder as a project and enable **Weather System 2D** under
   **Project → Project Settings → Plugins**.
3. Press Play — the launcher lets you exercise most of the kit.

## Running the tests

From the project root (adjust the executable name):

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

It prints a `[PASS]`/`[FAIL]` per check and exits non-zero on failure.

> **Gotcha:** after adding a *new* script with a `class_name`, a headless `--script` run may
> report `Could not find type "X"` until Godot rescans. Run one editor pass first to rebuild the
> class cache: `godot --headless --editor --quit --path .`, then run the tests.

Please add or update tests for behavior changes. Tests cover *logic* (property → uniform
wiring, builder shape, determinism, the sun model, the controller). Visual/shader results are
checked by eye in the demo scenes — headless uses a dummy renderer, so run a windowed scene
(e.g. `godot --path . res://demos/generated_demo.tscn`) to confirm shaders compile.

## Code style

- **GDScript**, tabs for indentation, `snake_case` members, `PascalCase` types.
- Nodes/resources declare `class_name` and are `@tool` where an editor preview helps.
- Prefer **typed** variables and return types.
- Keep the "code *and* editor" principle: a capability should be reachable both from the
  inspector and from the `WeatherScene` builder / node API.
- Match the surrounding comment density; explain *why*, not *what*.
- Determinism matters — anything seeded must reproduce for a given seed (there's a test).

## Submitting changes

1. Keep PRs focused; describe the change and how you verified it.
2. Make sure the test suite passes and any new behavior is covered.
3. Update the docs (`README`, `docs/`, `CHANGELOG.md`) when you change public behavior.

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for where the project is headed and good places to help.
