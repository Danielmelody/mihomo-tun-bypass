# mihomo-tun-bypass

[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-Standard-blue)](https://agentskills.io)

Fix Parsec and other applications' IPv6 connectivity issues when using Clash/Mihomo TUN mode.

## Installation

```bash
# Install in Claude Code
/skill install github:Danielmelody/mihomo-tun-bypass

# Or clone manually
git clone https://github.com/Danielmelody/mihomo-tun-bypass.git
```

## Quick Start

After installing the skill, Claude will automatically help you fix Parsec TUN issues. Or run:

```
Apply the mihomo-tun-bypass fix for Parsec
```

## Structure

```
.
├── SKILL.md              # Skill definition (Agent Skills standard)
├── scripts/
│   └── fix-parsec.ps1    # Windows PowerShell auto-fix script
├── references/
│   └── network-guide.md  # Detailed networking explanation
└── README.md             # This file
```

## The Problem

When using Clash/Mihomo TUN mode with `fake-ip`:

1. `PROCESS-NAME,DIRECT` rules still route traffic through TUN stack
2. IPv6 AAAA records are filtered by fake-ip mode
3. Parsec cannot establish IPv6 localhost connections

## The Solution

Use `tun.exclude-process` for **process-level bypass** (not rule-level DIRECT):

```yaml
tun:
  exclude-process:
    - parsecd.exe
    - parsec.exe
    - parsec-bootstrap.exe

dns:
  fake-ip-filter:
    - '+.parsec.app'
    - '+.parsecgaming.com'
    - '+.parsec.gg'
```

## Supported Platforms

- [x] Clash Verge Rev
- [x] Mihomo Party
- [x] Any Mihomo-based client with TUN mode

## License

MIT
