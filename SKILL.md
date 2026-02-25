---
name: mihomo-tun-bypass
description: Fix Parsec and other apps' IPv6 connectivity issues when using Clash/Mihomo TUN mode by excluding processes and preserving real DNS
author: Danielmelody
version: 1.0.0
tags:
  - network
  - proxy
  - clash
  - mihomo
  - parsec
  - ipv6
  - tun
allowed-tools:
  - Read
  - Edit
  - Write
---

# Mihomo TUN Bypass

Fix network connectivity issues for specific applications when using Clash/Mihomo TUN mode.

## Quick Start

```bash
/skill parsec-tun
```

## What This Skill Does

1. **Process Exclusion**: Adds target processes to `tun.exclude-process` so traffic completely bypasses TUN virtual interface
2. **DNS Fix**: Adds domains to `dns.fake-ip-filter` to preserve real IP addresses (including IPv6 AAAA records)

## Use Cases

- **Parsec**: IPv6 localhost connection in TUN mode
- **Gaming**: P2P/UDP games that fail with TUN interception
- **mDNS**: Local service discovery (Bonjour, AirDrop, etc.)
- **Low-latency apps**: Real-time communication that can't tolerate TUN overhead

## Key Insight

`PROCESS-NAME,DIRECT` ≠ `tun.exclude-process`

| Method | Traffic Path | IPv6 Support |
|--------|--------------|--------------|
| `PROCESS-NAME,DIRECT` | Through TUN stack → DIRECT | ❌ Broken by fake-ip |
| `tun.exclude-process` | Direct physical interface | ✅ Full support |

## Configuration

### Clash Verge Rev (Script Override)

Edit `profiles/<your-script>.js`:

```javascript
function main(config) {
  // Exclude Parsec from TUN
  config.tun["exclude-process"] = [
    "parsecd.exe",
    "parsec.exe",
    "parsec-bootstrap.exe"
  ];

  // Preserve real DNS for Parsec domains
  config.dns["fake-ip-filter"] = [
    "+.parsec.app",
    "+.parsecgaming.com",
    "+.parsec.gg"
  ];

  return config;
}
```

### Raw Config

```yaml
tun:
  enable: true
  exclude-process:
    - parsecd.exe
    - parsec.exe
    - parsec-bootstrap.exe

dns:
  enhanced-mode: fake-ip
  fake-ip-filter:
    - '+.parsec.app'
    - '+.parsecgaming.com'
    - '+.parsec.gg'
```

## References

- [Mihomo TUN Documentation](https://wiki.metacubex.one/config/inbound/tun/)
- [Parsec Network Requirements](https://support.parsec.app/hc/en-us/articles/115002712469-Network-Requirements)
