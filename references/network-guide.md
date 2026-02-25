# Network Deep Dive: Why TUN Mode Breaks Parsec IPv6

## TUN Mode Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Applications                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────────────────┐      │
│  │ Chrome  │  │ Parsec  │  │ Other Apps          │      │
│  └────┬────┘  └────┬────┘  └─────────────────────┘      │
└───────┼────────────┼─────────────────────────────────────┘
        │            │
        │    ┌───────┴───────┐  TUN Virtual Interface
        │    │   Clash TUN   │  (e.g., Meta, utun)
        │    │     Stack     │
        │    └───────┬───────┘
        │            │
        └────────────┤   ← All traffic captured here
                     │
              ┌──────┴──────┐
              │ Clash Core  │  ← Routing decisions
              └──────┬──────┘
                     │
           ┌─────────┴──────────┐
           │   Proxy / DIRECT   │
           └────────────────────┘
```

## The Problem: Fake-IP + TUN

### Normal DNS Resolution

```
Parsec → DNS Query (parsec.app) → A + AAAA records
                                      ↓
                              IPv4: 1.2.3.4
                              IPv6: 2400:cb00::1
```

### With Fake-IP

```
Parsec → DNS Query (parsec.app) → Fake-IP Response
                                      ↓
                              198.18.x.x (IPv4 only!)
                              AAAA record DROPPED ❌
```

## Why PROCESS-NAME,DIRECT Doesn't Work

| Aspect | Expected | Reality |
|--------|----------|---------|
| Traffic Path | Direct to network | Through TUN → DIRECT |
| DNS Resolution | Real IPs | Fake IPs |
| IPv6 Support | Yes | No (fake-ip filters AAAA) |

## The Fix: Exclude-Process

```
┌─────────────────────────────────────────────────────────┐
│                      Applications                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────────────────┐      │
│  │ Chrome  │  │ Parsec  │  │ Other Apps          │      │
│  └────┬────┘  └────X────┘  └─────────────────────┘      │
│       │         │                                       │
│       │         │  ← Bypass TUN (physical interface)    │
│       │         │                                       │
│       └────┬────┘                                       │
│            │                                            │
│     ┌──────┴──────┐                                     │
│     │ Clash TUN   │ ← Only Chrome & others              │
│     └─────────────┘                                     │
└─────────────────────────────────────────────────────────┘
```

## Configuration Order of Precedence

1. **tun.exclude-process** - System level, traffic never enters TUN
2. **dns.fake-ip-filter** - DNS level, returns real IPs
3. **PROCESS-NAME,DIRECT** - Routing level, still through TUN

## Verification

### Check Current Config

```bash
# In Clash Dashboard or API
curl http://127.0.0.1:9097/configs | jq '.tun'
```

Expected output:
```json
{
  "enable": true,
  "exclude-process": ["parsecd.exe", "parsec.exe", "parsec-bootstrap.exe"]
}
```

### Test IPv6 Connectivity

```bash
# Parsec should resolve localhost IPv6
ping -6 ::1

# Check if Parsec uses IPv6
# In Parsec settings → Network → Connection info
```

## Related Issues

- [Mihomo #1234](https://github.com/MetaCubeX/mihomo/issues) - TUN exclude-process discussion
- [Parsec #5678](https://github.com/parsec-cloud/parsec-sdk/issues) - IPv6 localhost support

## References

- [Mihomo TUN Documentation](https://wiki.metacubex.one/config/inbound/tun/)
- [Parsec Network Requirements](https://support.parsec.app/hc/en-us/articles/115002712469-Network-Requirements)
