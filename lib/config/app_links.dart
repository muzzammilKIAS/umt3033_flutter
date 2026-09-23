/// URL laman web "Muamalat Trail" (pendakian pelbagai pemain), dihoskan di
/// Render.com. Timpa semasa build jika perlu pelayan lain:
/// flutter build web --dart-define=MUAMALAT_TRAIL_URL=https://domain-lain
const muamalatTrailUrl = String.fromEnvironment(
  'MUAMALAT_TRAIL_URL',
  defaultValue: 'https://muamalat-trail.onrender.com',
);
