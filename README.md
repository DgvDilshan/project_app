# Tea Leaf Disease Detection (Frontend)

This Flutter app provides a user-friendly **scan flow** for tea leaf disease detection:

- Scan using **Camera** or **Gallery**
- Preview the leaf image
- Show the detected disease + confidence + severity
- Show practical **suggestions to reduce disease impact**

## AI model integration

The current implementation is **frontend-only** and uses a mock diagnosis service.
To connect your AI model, replace `MockLeafDiagnosisService` with your implementation in:

- `lib/services/leaf_diagnosis_service.dart`

## Reference / “Google images”

The results screen supports an optional `referenceImageUrl`. For copyright/safety reasons,
this project does **not** automatically scrape Google Images.

If you want reference images, provide URLs that you have rights to use (licensed dataset,
your own images, or approved sources) and set `referenceImageUrl` in your real service.
