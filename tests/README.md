# Tests

A lightweight, dependency-free headless test suite for the Weather System 2D kit. It
exercises the **logic** of the nodes (property → shader-parameter wiring, the mode enum,
weather response math, terrain factory presets, and shader selection) — the parts that can
be verified without a human looking at pixels.

## Run

From the project root (adjust `godot` to your executable, e.g. `Godot_v4.7-stable.exe`):

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

It prints a `[PASS]`/`[FAIL]` line per check and exits **0** on success, **1** on any
failure — so it drops straight into CI (e.g. a GitHub Action running the same command).

## What it does *not* cover

- **Visual correctness** of the shaders (foam look, wave shape, reflection alignment).
  Verify those by eye in `demos/water_demo.tscn` and `demos/beach_demo.tscn`, and — once
  the look is settled — by committing reference screenshots per mode and diffing them.
- **Shader compilation errors** don't surface here unless a material is used at runtime;
  opening the demo scenes in the editor is still the fastest compile check.

## Growing the suite

When the kit gets larger, consider adopting [GUT](https://github.com/bitwes/Gut) or
[GdUnit4](https://github.com/MikeSchulze/gdUnit4) for richer assertions, fixtures, and
editor integration. The current runner is intentionally zero-install so tests work on a
fresh clone.
