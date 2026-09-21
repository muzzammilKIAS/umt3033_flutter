# Original game artwork

All new art is repository-native Canvas/vector drawing; no Nintendo, stock or
third-party game assets are used. Existing bundled Amiri and Inter fonts are
reused. No raster downloads or runtime image fetches are required.

- `lib/game/engine/avatar_art.dart`: four modest student/explorer silhouettes.
- `lib/game/engine/environment_art.dart`: five palettes and zone-specific banks,
  libraries, markets, gardens and observatories.
- `lib/game/engine/adventure_game.dart`: gates,
  vocabulary gems, moving barriers and the knowledge vault.
- `lib/game/widgets/adventure_style.dart`: reusable portrait badges and palette.
- `lib/game/engine/course_geometry.dart`: replaceable platform geometry.

Current art is cohesive original geometric artwork, not a finished sprite pack.
For an illustrated production art pass, replace drawAvatar with 4 licensed/original
sprite sheets (idle/run/jump, transparent 96px cells). Add five distinct three-layer
world panoramas, separate gate/vault/bridge sprites and two gem frames under
`assets/game/`. Register each directory in pubspec. Retain the same collision
geometry so an art replacement does not change gameplay. No sacred figures,
Quran/hadith imagery or sacred text on collectible objects.

Audio is deliberately absent from the new module; existing course audio remains
unchanged. Original optional UI/jump/gate sounds need a later licensed audio pass.
