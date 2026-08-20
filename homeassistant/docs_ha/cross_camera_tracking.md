# Cross-camera tracking

Property visit correlation across Frigate cameras using three tiers: HA visit graph (Tier 1), multi-camera Comstar Vision bursts (Tier 2), and optional visual Re-ID spike (Tier 3).

## Canonical journeys

| Path | Route | Cameras |
|------|-------|---------|
| A | Driveway → east gate → east lawn | `driveway`, `east_side` |
| B | Driveway → front steps → west gate | `driveway`, `front_door`, `west_side` |

Driveway **branches** — Path A and Path B events must not merge unless face or adjacency+timing confirms the same visit.

## Components

| File | Role |
|------|------|
| [`includes/property_zone_graph.json`](../includes/property_zone_graph.json) | Zone adjacency, transit windows, cameras |
| [`packages/visit_correlation.yaml`](../packages/visit_correlation.yaml) | Helpers, scripts, idle finalize automation |
| [`shell/visit_correlate.py`](../shell/visit_correlate.py) | Visit ID + path linking (stdout JSON) |
| [`shell/frigate_visit_events.py`](../shell/frigate_visit_events.py) | Multi-camera Frigate event query |
| [`shell/visit_append_stills.py`](../shell/visit_append_stills.py) | Tier 2 still buffer |
| [`blueprints/automation/zone_activity_llm_vision.yaml`](../blueprints/automation/zone_activity_llm_vision.yaml) | Zone AI + visit hooks |
| [`blueprints/automation/gate_open_llm_vision_people.yaml`](../blueprints/automation/gate_open_llm_vision_people.yaml) | Gate AI + visit hooks |
| [hacs-comstar-vision](https://github.com/zlatko-lakisic/hacs-comstar-vision) | `priority`, `visit_context`, `camera_labels` on `image_analyzer` |

## Tier comparison (both journeys)

| Aspect | Tier 1 | Tier 2 | Tier 3 |
|--------|--------|--------|--------|
| **Journey A notify** | Zlatko — driveway → east gate → east lawn | Same + narrative | Same if face fails |
| **Journey B notify** | Zlatko — driveway → front steps → west gate | Same + narrative | front→west hardest hop |
| **Unknown visitor** | Per-zone alerts | Do not auto-merge | Best link option |
| **Latency** | Low | Waits for visit idle | Near real-time |
| **AO priority** | Frigate-only or realtime at link hops | **background** at idle | Local Jetson; VLM at **normal** for 0.65–0.85 |

## AO Reach priority

| Priority | When |
|----------|------|
| `realtime` | First zone, cross-camera link window, unlinked gate open |
| `normal` | Linked visit confirmation, ambiguous Re-ID VLM |
| `background` | End-of-visit multi-cam narrative (`script.property_visit_finalize_narrative`) |

Comstar Vision today forwarded `priority` on every `chat` call; cross-camera work sets it explicitly from visit phase.

## Dashboard

`sensor.property_visit_summary` — live path label and faces from visit helpers.

## Frigate zones (deploy on NVR)

New zones documented in [`services/frigate.md`](../../services/frigate.md):

- `east_side`: `east_gate_approach`, `east_lawn`
- `west_side`: `west_gate_approach`
- `back_yard`: `kitchen_lawn`, `back_yard_gate_approach`
- `garden_north` / `garden_south`: `garden_path`

Coordinates are placeholders — tune in Frigate UI on the NVR.

## Tier 3 spike

See [`infrastructure/visit_reid/README.md`](../../infrastructure/visit_reid/README.md).

```bash
python3 infrastructure/visit_reid/spike_match.py \
  --camera-a driveway --camera-b east_side --after $(date -d '7 days ago' +%s)
```

## Failure modes

| Symptom | Likely cause |
|---------|----------------|
| Split visit (two IDs for Zlatko) | Transit exceeded max_s; face not recognized on hop |
| Merged wrong people | Two left driveway simultaneously; adjacency without face |
| No consolidated narrative | Visit idle automation not fired; still buffer empty |
| Slow gate notify | AO queue — check realtime vs background mix |

## Related

- [Zone Activity AI](zone_activity_ai.md)
- [Frigate Setup](frigate_setup.md)
