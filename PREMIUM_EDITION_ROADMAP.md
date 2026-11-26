# PUZZLE & MIND — PREMIUM EDITION Roadmap

This document tracks the approved upgrade plan while preserving the existing game systems.

## Current project baseline
- Engine: Godot 4.4.1
- Main scene: `Main.tscn`
- Main script: `Scripts/main.gd`
- Logic world: 25 questions in `Data/logic_puzzles.json`
- Spot-the-difference world: 25 stages wired to the existing game flow.
- Stage 1 has a photorealistic image pair and seven normalized hit regions in `Data/spot_stage_01.json`.
- Stages 2–25 currently use SVG illustrations and need a proper art/content pass.
- Existing systems already include saved progress, unlocked levels, coins, stars, achievements, music controls and volume settings. These must be extended only where needed, not duplicated.

## Approved implementation order

### Phase 1 — Stability and correctness
- [x] Reset the three-hint allowance when a logic or spot stage starts.
- [x] Correct the hint and explanation for logic question 15 (Abjad sequence).
- [x] Correct the answer and explanation for logic question 24 (eight balls).
- [x] Add a strict Godot import/runtime error check before Android export.
- [x] Ensure a separate x86_64 APK is built for emulator testing.
- [x] Make the Pixel 2 emulator smoke test run on every push to `main`.
- [ ] Complete and inspect the current emulator run, screenshots and logs.
- [ ] Validate every spot stage's seven actual differences against its hit regions.
- [ ] Test the ARM64 APK on a physical Android phone.

### Phase 2 — Spot-the-difference art
- [x] Preserve the existing photorealistic stage 1 pair.
- [ ] Replace the temporary SVG artwork in stages 2–25 with coherent, high-quality image pairs.
- [ ] Ensure each pair contains exactly seven intentional differences.
- [ ] Keep answer markers out of the source images.
- [ ] Verify normalized hit coordinates and touch radii on a phone-sized viewport.

### Phase 3 — Gameplay systems
- [ ] Review existing reward and progress systems before changing them.
- [ ] Add optional timers and difficulty selection without disrupting current progression.
- [ ] Add a balanced reward loop for hints and replay.
- [ ] Verify that rewards are granted only once per stage.

### Phase 4 — UI and feedback
- [ ] Refine the home screen and world/level navigation.
- [ ] Improve success/failure feedback and difference-found effects.
- [ ] Add optional sound effects with independent mute/volume controls.
- [ ] Check Arabic RTL layout and different phone aspect ratios.

### Phase 5 — Release readiness
- [ ] Run automated Godot and Android checks.
- [ ] Inspect emulator screenshots and logs.
- [ ] Verify offline play and save persistence.
- [ ] Test the ARM64 build on a physical Android device.
- [ ] Prepare final icon, store screenshots and release notes.

## Guardrails
- Do not replace working systems without a verified reason.
- Do not mark emulator, touch, visual or physical-device tests complete without evidence.
- Keep the phone APK ARM64; use x86_64 only for the emulator.
- Keep image pairs and their hit-region data synchronized.
- Work in small verified commits so a broken update can be isolated and reverted.
