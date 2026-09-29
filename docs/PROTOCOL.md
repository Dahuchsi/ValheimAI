# Controller Protocol (draft)

JSON messages over a localhost WebSocket.

## Plugin -> controller

```json
{
  "type": "state",
  "timestamp": "2026-09-28T00:00:00Z",
  "player": {
    "name": "Bjorn",
    "health": 100,
    "maxHealth": 100,
    "stamina": 100,
    "position": { "x": 0, "y": 0, "z": 0 }
  }
}
```

## Controller -> plugin

```json
{
  "type": "action",
  "action": "follow",
  "targetPlayer": "David",
  "followDistance": 3.5
}
```

Safety rule: the plugin accepts only explicitly implemented player-like actions. Arbitrary console/dev commands are intentionally excluded.
