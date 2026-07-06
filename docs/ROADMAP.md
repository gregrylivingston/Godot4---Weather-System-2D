# Roadmap — Weather System 2D

The kit is feature-complete for its first release (**v0.1.0**). What it does and how it's built
now lives in the docs, so this file is just the **backlog** — what's deliberately left and how
much it matters.

- **What it does / how to use it** → [README](../README.md) and [`docs/api/`](api/getting-started.md).
- **How it's built** → [`docs/ARCHITECTURE.md`](ARCHITECTURE.md).
- **What has landed so far** (Phases 0–5: the addon, water, terrain, code builder, living
  simulation) → [`CHANGELOG.md`](../CHANGELOG.md).

---

## Guiding principles

These still shape any new work:

1. **Reusable first.** Anything we build should drop into another Godot project with minimal
   wiring — a self-contained `addons/weather2d/` plugin.
2. **Code *and* editor.** Every capability reachable two ways: a `@tool` node/inspector and the
   `WeatherScene` builder API.
3. **Calm, pleasing, stylized.** Soft, painterly, relaxing — not photoreal.
4. **Deterministic.** A seed + preset regenerates the same scene.
5. **Documented as we go.** No feature is "done" until it's in the docs with an example.

---

## Before a wider (1.0) release

The one real gap for the public listing — needs a person, not code:

- [ ] **Media** — screenshots + a short GIF/video of the launcher & scenarios, for the README
      and the Asset Library page. (The README hero image is still a legacy render.)
- [ ] **Godot Asset Library submission** — needs the media first.

---

## Visual polish (optional — best tuned with the editor open)

Aesthetic features that need a human eye to get right; none are required for a complete kit:

- **Caustics / sparkle** on sunlit shallows. *(Worth first extracting the shared water/noise
  helpers into a `.gdshaderinc` — a cleanup that pays off once the water grows more passes.)*
- **Live wet-sand edge** — drive the sand's dry→wet blend from the water's animated run-up
  (currently a static gradient).
- **Parallax cloud layers** — high thin cirrus + low cumulus at different speeds (one layer today).
- **Wet-surface response** — terrain/props darken while it rains and dry after; puddles on flat ground.
- **God rays** at golden hour, and **thunder audio** to pair with the lightning flash.
- **Density-map prop placement** — paint where props go instead of uniform stratification.

---

## Further afield

- **Performance profiling on real targets** — the `low_graphics()` mode and shader early-outs
  cover the common cases; a proper mobile/web pass (draw-call / overdraw budget) is worth doing
  if the kit gets used there.

*Everything below the release section is optional — the kit is complete and shippable as-is.*
