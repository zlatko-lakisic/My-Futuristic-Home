# Agentic Orchestration API tokens (Home Assistant)

HA talks to two AO edges over OpenAI-compatible chat. Both require minted Bearer tokens — see [AO Web UI — API access tokens](https://github.com/zlatko-lakisic/agentic-orchestration/wiki/Web-UI#api-access-tokens).

| Consumer | Host | Completions URL | Where the secret lives |
| :--- | :--- | :--- | :--- |
| Gate + zone motion (LLM Vision) | ADA (`10.0.10.16`) | `https://ada.ao.mostardesigns.com/v1/chat/completions` | LLM Vision → Custom OpenAI provider → API key |
| Garden watering | Jetson (`172.16.90.20`) | `https://jetson.ao.mostardesigns.com/v1/chat/completions` | `input_text.ai_watering_llm_api_key` |

## Mint

1. Open each AO Admin → Access → **API tokens**.
2. **Mint token** → **External client (custom appId)**.
3. Use `appId`: **`home-assistant`** on both ADA and Jetson (one token per host; revoke independently).
4. Copy the `ao_…` secret once into the HA field above (password helper / LLM Vision provider). Never commit it.

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
