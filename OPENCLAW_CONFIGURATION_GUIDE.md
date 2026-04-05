# OpenClaw Gateway & Channels Configuration Guide

## Overview

OpenClaw is a personal AI assistant with a **Gateway** (control plane) that manages channels, sessions, and events. The Gateway runs as a WebSocket service that connects messaging platforms (Discord, Telegram, WhatsApp, etc.) to your AI agent.

**Key Architecture:**
```
Messaging Platforms (Discord/Telegram/etc.)
           ↓
    OpenClaw Gateway
    (ws://127.0.0.1:18789)
           ↓
    ├─ Pi Agent (RPC mode)
    ├─ CLI commands
    ├─ WebChat UI
    └─ macOS app / iOS/Android nodes
```

---

## Gateway Configuration

### Mode Options

The gateway can run in different modes:

| Mode | Description | Use Case |
|------|-------------|----------|
| `"local"` | Gateway bound to loopback (127.0.0.1) | Default, single-user local setup |
| `"remote"` | Gateway on a separate machine | Server/Linux instance setup |

### Authentication

```nix
gateway = {
  mode = "local";
  auth = {
    # Option 1: Token-based auth (recommended for local)
    token = "YOUR_GATEWAY_TOKEN";  # or set OPENCLAW_GATEWAY_TOKEN env var
    
    # Option 2: Password-based (required for Tailscale Funnel)
    # mode = "password";
    # password = "secure-password";
  };
};
```

**Token Considerations:**
- Generate a secure random token (e.g., `openssl rand -hex 32`)
- Store in environment variable `OPENCLAW_GATEWAY_TOKEN` for security
- Gateway uses this to authenticate WebSocket clients
- Keep separate from channel authentication tokens

### Port Configuration

```nix
gateway = {
  port = 18789;  # Default HTTP port
  bind = "loopback";  # Only accessible from localhost
};
```

### Tailscale Integration (Optional)

Enable remote access while keeping gateway on loopback:

```nix
gateway = {
  tailscale = {
    mode = "serve";  # or "funnel" for public access
    # mode = "serve" → tailnet-only (uses Tailscale identity headers)
    # mode = "funnel" → public HTTPS (requires password auth)
    resetOnExit = true;  # Undo Serve/Funnel on shutdown
  };
};
```

**Rules:**
- `gateway.bind` must stay `"loopback"` when using Tailscale
- Funnel requires `gateway.auth.mode = "password"`
- Serve can use token auth by default

---

## Channels Configuration

### Discord

**Required:**
```nix
channels.discord = {
  token = "YOUR_DISCORD_BOT_TOKEN";  # or set DISCORD_BOT_TOKEN env var
};
```

**Optional Security Settings:**
```nix
channels.discord = {
  token = "...";
  
  # Who can access the bot
  allowFrom = [ "USER_ID_1" "USER_ID_2" ];
  
  # Group/Guild configuration
  guilds = [
    {
      id = "GUILD_ID";
      name = "My Server";
    }
  ];
  
  # DM Security Policy
  dmPolicy = "pairing";  # Options: "pairing" (default), "open"
  # "pairing": unknown senders get a pairing code
  # "open": anyone can DM (set with caution)
  
  # Media size limit
  mediaMaxMb = 25;
};
```

**Commands Configuration:**
```nix
commands = {
  native = true;      # Enable Discord slash commands
  text = true;        # Enable text commands
  useAccessGroups = true;  # Use Discord roles for access
};
```

**DM Access Best Practices:**
- Default `dmPolicy = "pairing"` requires users to send a code first
- Approve senders: `openclaw pairing approve discord <code>`
- Run `openclaw doctor` to check for risky configurations

### Telegram

**Required:**
```nix
channels.telegram = {
  botToken = "YOUR_BOT_TOKEN";  # or set TELEGRAM_BOT_TOKEN env var
  allowFrom = [ 123456789 ];     # Your Telegram user ID (get from @userinfobot)
};
```

**Optional Settings:**
```nix
channels.telegram = {
  botToken = "...";
  allowFrom = [ 123456789 ];
  
  # Group configuration
  groups = {
    "*" = { requireMention = true; };  # Default: require @mention in groups
    "-1001234567890" = {
      requireMention = false;  # This group doesn't need mentions
    };
  };
  
  # Webhook for receiving updates (alternative to polling)
  webhookUrl = "https://your-domain.com/telegram";
  webhookSecret = "YOUR_WEBHOOK_SECRET";
};
```

**Setup:**
1. Create bot with [@BotFather](https://t.me/BotFather)
2. Get your Telegram ID from [@userinfobot](https://t.me/userinfobot)
3. Set `allowFrom` to your user ID (positive number for DM)
4. For group access, use negative group ID prefixed with `-100`

### Slack

**Required:**
```nix
channels.slack = {
  botToken = "YOUR_BOT_TOKEN";      # or set SLACK_BOT_TOKEN
  appToken = "YOUR_APP_TOKEN";      # or set SLACK_APP_TOKEN
};
```

**Optional:**
```nix
channels.slack = {
  botToken = "...";
  appToken = "...";
  
  allowFrom = [ "USER_ID" ];
  dmPolicy = "pairing";  # Same as Discord
};
```

### WhatsApp

**Setup:**
```nix
channels.whatsapp = {
  allowFrom = [ "+1234567890" ];  # Your WhatsApp number
  groups = [
    {
      id = "GROUP_JID";
      name = "My Group";
    }
  ];
};
```

**Process:**
1. Link device: `openclaw channels login`
2. Scan QR code on linked device
3. Credentials stored in `~/.openclaw/credentials`
4. Set `allowFrom` to approve specific numbers

### Signal, WhatsApp, iMessage, etc.

See full documentation at [docs.openclaw.ai/channels](https://docs.openclaw.ai/channels) for:
- Signal (requires `signal-cli`)
- BlueBubbles (recommended iMessage integration)
- iMessage (legacy macOS-only)
- Google Chat, Microsoft Teams, Matrix, IRC, Mattermost, etc.

---

## Security Defaults (Important!)

### DM Access Policy

**Default Behavior on Telegram/WhatsApp/Signal/Discord/Slack:**

1. **Pairing Mode** (`dmPolicy = "pairing"` - DEFAULT)
   - Unknown senders receive a short pairing code
   - Bot does NOT process their message
   - Approve with: `openclaw pairing approve <channel> <code>`
   - Sender is added to local allowlist

2. **Open Mode** (`dmPolicy = "open"`)
   - Requires explicit opt-in
   - Set `dmPolicy = "open"` AND include `"*"` in `allowFrom`
   - **WARNING:** Anyone can message your bot!

3. **Best Practice Check:**
   ```bash
   openclaw doctor  # Surfaces risky/misconfigured DM policies
   ```

### Allowlist Structure

```nix
# Discord
allowFrom = [ "123456789" ];  # User IDs (strings or numbers)

# Telegram
allowFrom = [ 123456789 ];           # Your user ID (DM)
allowFrom = [ -1001234567890 ];      # Group ID

# WhatsApp
allowFrom = [ "+1234567890" ];       # Phone numbers with + prefix

# Slack
allowFrom = [ "U123456789" ];        # User IDs
```

---

## Complete Example Configuration

### Single Instance (Your NixOS Setup)

```nix
{config, pkgs, pkgs-unstable, inputs, ...}:

{
  programs.openclaw = {
    package = pkgs-unstable.openclaw;
    documents = ~/openclaw/documents;  # Optional: workspace docs
    
    config = {
      # Gateway configuration
      gateway = {
        mode = "local";
        port = 18789;
        bind = "loopback";
        
        auth = {
          token = "GENERATE_SECURE_TOKEN_HERE";
          # Or set OPENCLAW_GATEWAY_TOKEN environment variable
        };
      };
      
      # Channel configurations
      channels = {
        discord = {
          token = "YOUR_DISCORD_BOT_TOKEN";
          allowFrom = [ "YOUR_USER_ID" ];
          dmPolicy = "pairing";
          mediaMaxMb = 25;
        };
        
        telegram = {
          botToken = "YOUR_BOT_TOKEN";
          allowFrom = [ 123456789 ];  # Your Telegram user ID
          groups = {
            "*" = { requireMention = true; };
          };
        };
      };
      
      # Agent defaults
      agent = {
        model = "anthropic/claude-opus-4-6";
      };
    };
    
    # Instance configuration (Nix-specific)
    instances.default = {
      enable = true;
      launchd.enable = true;  # Enable systemd/launchd service
      stateDir = "~/.openclaw";
      workspaceDir = "~/.openclaw/workspace";
      
      # Plugins
      plugins = [
        { source = "github:openclaw/nix-steipete-tools?dir=tools/summarize"; }
        { source = "github:openclaw/nix-steipete-tools?dir=tools/peekaboo"; }
      ];
    };
  };
}
```

### Minimal Config (Local Only)

```nix
programs.openclaw = {
  config = {
    gateway = {
      mode = "local";
      auth = {
        token = "$(openssl rand -hex 32)";
      };
    };
    
    channels.discord = {
      token = "YOUR_TOKEN";
      allowFrom = [ "YOUR_ID" ];
    };
  };
  
  instances.default = {
    enable = true;
  };
};
```

---

## Configuration File Locations

| Setting | Environment Variable | File |
|---------|---------------------|------|
| Gateway Token | `OPENCLAW_GATEWAY_TOKEN` | - |
| Discord Token | `DISCORD_BOT_TOKEN` | - |
| Telegram Token | `TELEGRAM_BOT_TOKEN` | - |
| Slack Bot Token | `SLACK_BOT_TOKEN` | - |
| Slack App Token | `SLACK_APP_TOKEN` | - |
| Credentials | - | `~/.openclaw/credentials` |
| Config | - | `~/.openclaw/openclaw.json` |
| Workspace | - | `~/.openclaw/workspace` |

---

## Valid Configuration Values

### Gateway Mode
- `"local"` - Loopback only (default)
- `"remote"` - Accessible from network

### Gateway Auth Mode
- `"token"` - Token-based (default for local)
- `"password"` - Password-based (required for Funnel)

### DM Policy
- `"pairing"` - Require pairing code (default, secure)
- `"open"` - Anyone can DM (use with caution)

### Tailscale Mode
- `"off"` - No Tailscale (default)
- `"serve"` - Tailnet-only HTTPS
- `"funnel"` - Public HTTPS (requires password auth)

### Channel Types
- `discord`, `telegram`, `slack`, `whatsapp`, `signal`
- `bluebubbles`, `imessage`, `googlechat`, `msteams`
- `matrix`, `irc`, `mattermost`, `line`, `feishu`
- `zalo`, `wechat`, `webchat`, `tlon`, `nostr`

---

## Setup Checklist

### For Discord
- [ ] Create Discord bot via [Discord Developer Portal](https://discord.com/developers/applications)
- [ ] Copy bot token
- [ ] Enable necessary intents (Message Content, Server Members)
- [ ] Add bot to your server
- [ ] Set `allowFrom` to your Discord user ID
- [ ] Set `dmPolicy` (default: `"pairing"`)

### For Telegram
- [ ] Create bot with [@BotFather](https://t.me/BotFather)
- [ ] Copy bot token
- [ ] Get your user ID from [@userinfobot](https://t.me/userinfobot)
- [ ] Set `allowFrom` to your user ID
- [ ] For groups: Get group ID and use negative format (`-100...`)

### For WhatsApp
- [ ] Run `openclaw channels login`
- [ ] Scan QR code on linked device
- [ ] Set `allowFrom` to your phone number

### General
- [ ] Generate secure gateway token: `openssl rand -hex 32`
- [ ] Store sensitive values in environment variables
- [ ] Run `openclaw doctor` to verify config
- [ ] Check `~/.openclaw/openclaw.json` for final config
- [ ] Test with `openclaw message send` command

---

## Common Commands

```bash
# Start gateway
openclaw gateway --port 18789 --verbose

# Send a test message
openclaw message send --to +1234567890 --message "Hello"

# Check pairing codes
openclaw pairing list

# Approve a sender
openclaw pairing approve discord CODE

# Health check
openclaw doctor

# View logs (macOS)
tail -50 /tmp/openclaw/openclaw-gateway.log

# View logs (Linux)
journalctl --user -u openclaw-gateway -f

# Restart service (macOS)
launchctl kickstart -k gui/$UID/com.steipete.openclaw.gateway

# Restart service (Linux)
systemctl --user restart openclaw-gateway
```

---

## Best Practices

1. **Token Storage**
   - Store tokens in environment variables or secret files
   - Never commit tokens to git
   - Use `agenix` or similar for NixOS secrets management

2. **DM Security**
   - Keep default `dmPolicy = "pairing"` for unknown senders
   - Regularly review `openclaw doctor` output
   - Test with `openclaw pairing` workflow

3. **Multi-Channel**
   - Each channel needs separate authentication
   - Use different services/tokens per channel
   - Group allowlists are channel-specific

4. **Debugging**
   - Run `openclaw doctor` frequently
   - Check service status before testing
   - Enable `--verbose` on gateway for detailed logs
   - Test with CLI: `openclaw message send`

5. **Scalability**
   - Gateway is the single control plane
   - Can route to multiple agents via `instances`
   - Use `agents.defaults.sandbox.mode` for group isolation
   - Consider remote gateway on Linux for 24/7 availability

---

## References

- **Official Docs:** https://docs.openclaw.ai/
- **Configuration Reference:** https://docs.openclaw.ai/gateway/configuration
- **Channels Guide:** https://docs.openclaw.ai/channels
- **Security Guide:** https://docs.openclaw.ai/gateway/security
- **Nix Module:** https://github.com/openclaw/nix-openclaw
- **Main Repository:** https://github.com/openclaw/openclaw

---

## Your Current Configuration

Your `/home/chloe/NixOS/modules/openclaw.nix` has:

```nix
gateway = {
  mode = "local";
  auth = {
    token = "GATEWAY_TOKEN :)";  # ← Replace with secure token
  };
};

channels = {
  discord = {
    # Empty - needs configuration
  };
};
```

**Next Steps:**
1. Generate a secure gateway token
2. Create Discord bot and get token
3. Set your Discord user ID in `allowFrom`
4. (Optional) Add Telegram or other channels
5. Test with `openclaw doctor`
