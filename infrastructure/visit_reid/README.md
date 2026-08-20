# Visit Re-ID spike (Tier 3)

Visual re-identification sidecar for cross-camera person linking when Frigate
face sub_labels are unavailable.

## Scope

Spike measures embedding similarity across camera pairs for the two canonical journeys:

| Journey | Camera pairs to score |
|---------|----------------------|
| A (east) | `driveway` ↔ `east_side` |
| B (front/west) | `driveway` ↔ `front_door`, `front_door` ↔ `west_side` |

## Architecture

```
Frigate MQTT (frigate/events) → visit_reid_spike.py
  → crop bbox via /api/events/{id}/snapshot.jpg?bbox=1
  → embedding (stub or torchreid OSNet when installed)
  → JSON match report
```

## Run spike (historical events)

```bash
python3 spike_match.py \
  --base-url http://192.168.89.37:5000 \
  --camera-a driveway --camera-b east_side \
  --after 1700000000 --limit 50
```

Output: top-1 match rate, similarity distribution, recommended thresholds:

| Similarity | Action |
|------------|--------|
| ≥ 0.85 | Auto-link visit (Tier 3) |
| 0.65 – 0.85 | Ask VLM confirm (`normal` priority) |
| < 0.65 | Separate visits |

## Production path (not in this spike)

- MQTT listener service on Jetson NVR docker stack
- REST hook to HA `visit_correlate.py` with `reid_score` field
- Optional: CodeProject.AI custom post-processor

## Dependencies (optional for real embeddings)

```bash
pip install torch torchvision torchreid pillow requests
```

Without torch, `spike_match.py` uses histogram fallback for pipeline testing only.
