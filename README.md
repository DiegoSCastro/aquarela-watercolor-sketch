# Aquarela — Watercolor Sketch

> Native Android watercolor painting app. Pigment diffusion engine + curated pigments.

## Status

**PR 0.5 — Onboarding screen + design system** (in progress, awaiting Diego review)

### What's done

- ✅ Repo bootstrapped (`com.omegadevapps.aquarelaWatercolorSketch`, pushed to GitHub)
- ✅ Design system: pigment tokens (4 brand colors), paper neutrals (5), spacing scale (7), typography (Lora serif + Inter sans), 5 radius tokens, paper shadows, motion tokens
- ✅ Theme components: `PigmentButton` (primary/secondary/ghost), `PaperCard`, `PigmentDot` (with locked state), `PigmentLoader` (3 pulsing dots)
- ✅ Onboarding screen: 3 slides with hand-crafted CustomPaint illustrations
  - Slide 1: "Aquarela no seu bolso" — phone with pigment bleeding out
  - Slide 2: "Pigmento que respira" — organic asymmetric pigment diffusion
  - Slide 3: "Suas obras, guardadas" — gallery grid with universal share icon
- ✅ `flutter analyze` clean (0 issues)

### Design

See `/Users/diego/.hermes/aquarela-design-system.md` for the full design rationale.

### Roadmap

Next PRs (per `/Users/diego/.hermes/plans/2026-06-23_103000-aquarela-watercolor-sketch.md`):
- PR 1.1: radial bleed pigment engine + 1 round brush
- PR 1.2: CanvasScreen with brush + color picker
- PR 2.1: wet-on-wet bleeding + paper texture
- PR 2.2: 12 curated pigments
- PR 3.x: Palette + Gallery
- PR 4.x: IAP + AdMob + onboarding polish
- PR 5.1: release prep

### Build

```bash
flutter pub get
flutter run
```

iOS simulator: `xcrun simctl install <device_id> build/ios/iphonesimulator/Runner.app`
