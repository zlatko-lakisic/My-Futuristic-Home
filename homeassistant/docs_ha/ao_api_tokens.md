# Agentic Orchestration API tokens (Home Assistant)

HA talks to two AO edges over OpenAI-compatible chat. Both require minted Bearer tokens — see [AO Web UI — API access tokens](https://github.com/zlatko-lakisic/agentic-orchestration/wiki/Web-UI#api-access-tokens).

| Consumer | Host | Endpoint | `appId` | Where the secret lives |
| :--- | :--- | :--- | :--- | :--- |
| Gate + zone motion (LLM Vision) | ADA (`10.0.10.16`) | `https://ada.ao.mostardesigns.com/v1/chat/completions` | `home-assistant` | LLM Vision → Custom OpenAI provider → API key |
| Garden watering (legacy HTTP) | Jetson (`172.16.90.20`) | `https://jetson.ao.mostardesigns.com/v1/chat/completions` | `home-assistant` | `input_text.ai_watering_llm_api_key` |
| Garden watering (**AO Reach**) | Jetson engine `:8765` | `https://172.16.90.20:8765` (WSS `/ws`) | **`agentic-watering`** | Agentic Watering config entry → API token |
| HACS Comstar Assist | ADA engine `:8765` | engine URL in Comstar options | `comstar-ha` | Comstar config entry |

## Mint

1. Open each AO Admin → Access → **API tokens**.
2. **Mint token** → **External client (custom appId)**.
3. Use the **`appId` column above** — one token per consumer; revoke independently. Do **not** reuse Comstar’s `comstar-ha` token for watering Reach, or watering’s Reach token for HTTP Vision.
4. Copy the `ao_…` secret once into the HA field / config entry. Never commit it.

## Engine clients also need mTLS enrollment

The `:8765` engines (Jetson and ADA) report `mtls.required: true`, so the two Reach
consumers (Agentic Watering, Comstar) need a **second, different** credential: an
**mTLS enrollment token**. The API token is *not* accepted for enrollment — the engine
answers `400 invalid enrollment token`, and a session without client material is
rejected with **403** on the WSS `/ws` upgrade.

| Item | Detail |
| :--- | :--- |
| Mint | AO Admin → Access → enrollment token, CN/appId matching the consumer |
| Redeem | Paste into the integration's **mTLS enrollment token** field (one-time; stripped after use) |
| Stored | `config/agentic_watering_mtls_<entry_id>/` (`cert.pem`, `key.pem`, `ca.pem`) |
| Re-pair / reset | `agentic_watering.pair` / `agentic_watering.clear_pairing` |

Jetson Reach also needs engine flags `AGENTIC_SERVE_SESSION_OVERLAY=1` and `AGENTIC_SERVE_MCP_TUNNEL=1` (weather-mcp tunnel).

Every request sends:

```http
Authorization: Bearer ao_<secret>
Content-Type: application/json
```

Legacy shared env keys (`AGENTIC_CHAT_COMPLETIONS_API_KEY`) may still work as `appId: env`, but prefer per-app minted tokens so you can revoke HA without rotating a global secret.

## Related

- [Garden Agentic Watering](garden_agentic_watering.md)
- [Zone Activity AI](zone_activity_ai.md)
- [LoRa Perimeter](lorawan_perimeter.md) (gate LLM)
- [Jetson AO](../../infrastructure/jetson_agentic_orchestration.md)
