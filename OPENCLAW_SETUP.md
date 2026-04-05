# OpenClaw Configuration Guide

## Current Setup Status

Your OpenClaw configuration is now structured for:
1. **Secure token handling** via environment variables
2. **Proper gateway configuration** with explicit port binding
3. **Channel support** (Discord, Telegram) ready to enable

## Security: Handling Auth Tokens

### ⚠️ Current Issue (Insecure)
The current setup uses plaintext in `environment.sessionVariables`. This is **NOT suitable for production** because:
- Environment variables are visible to all system users
- Tokens could be exposed in logs or system inspection

### ✅ Recommended Solution: Using agenix

For secure secret management, use **agenix** (age-encrypted secrets):

#### Step 1: Add agenix to your flake.nix

```nix
inputs = {
  # ... existing inputs ...
  agenix.url = "github:ryantm/agenix";
};
```

#### Step 2: Create a secrets directory

```bash
mkdir -p ~/.config/openclaw/secrets
cd ~/.config/openclaw/secrets
```

#### Step 3: Create secrets.nix

```nix
# ~/.config/openclaw/secrets/secrets.nix
let
  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";  # Get from: ssh-keyscan localhost 2>/dev/null | grep ed25519
  
  chloe = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";   # Your user SSH public key
in
{
  "gateway-token.age".publicKeys = [ system1 chloe ];
  "discord-token.age".publicKeys = [ system1 chloe ];
  "telegram-token.age".publicKeys = [ system1 chloe ];
}
```

#### Step 4: Encrypt your tokens

```bash
# Get your SSH public key
cat ~/.ssh/id_ed25519.pub

# Get system SSH public key
ssh-keyscan localhost 2>/dev/null | grep ed25519

# Update secrets.nix with actual keys

# Encrypt tokens (will open editor)
agenix -e gateway-token.age
agenix -e discord-token.age
agenix -e telegram-token.age
```

#### Step 5: Reference in openclaw.nix

```nix
# In modules/openclaw.nix
programs.openclaw = {
  package = pkgs-unstable.openclaw;
  
  config = {
    gateway = {
      mode = "local";
      auth = {
        token = config.age.secrets.gateway-token.path;
      };
      port = 18789;
    };
    
    channels = {
      discord = {
        token = config.age.secrets.discord-token.path;
        allowFrom = [ "YOUR_ID" ];
      };
    };
  };
};

# Age configuration for home-manager
age.secrets = {
  gateway-token.file = ../secrets/gateway-token.age;
  discord-token.file = ../secrets/discord-token.age;
  telegram-token.file = ../secrets/telegram-token.age;
};

age.identityPaths = [ "~/.ssh/id_ed25519" ];
```

## Gateway Connectivity Issues

### Why is the gateway not reachable?

The gateway is bound to `127.0.0.1:18789` (localhost only) in `local` mode. This means:
- ✅ Local connections work: `localhost:18789`
- ❌ Remote connections fail
- ❌ Other machines cannot reach it

### Testing the gateway

```bash
# Check if service is running
systemctl --user status openclaw-gateway

# View logs
journalctl --user -u openclaw-gateway -f

# Test local connection
curl http://127.0.0.1:18789

# Check listening ports
ss -tlnp | grep 18789
```

### If gateway is not running

```bash
# Rebuild and activate home-manager
home-manager switch --flake ~/NixOS#

# Then check status
systemctl --user status openclaw-gateway
```

## Configuration Summary

**Current Setup:**
- Mode: `local` (127.0.0.1 only)
- Port: 18789
- Auth: Environment variable (temporary, not secure)
- Channels: Discord/Telegram ready (commented out)

**To Enable Discord:**
```nix
channels.discord = {
  token = "YOUR_BOT_TOKEN";          # From Discord Developer Portal
  allowFrom = [ "YOUR_USER_ID" ];    # Your Discord user ID
  dmPolicy = "pairing";               # Require pairing code
};
```

**To Enable Telegram:**
```nix
channels.telegram = {
  botToken = "YOUR_BOT_TOKEN";       # From @BotFather
  allowFrom = [ 123456789 ];         # Your Telegram user ID (from @userinfobot)
};
```

## Next Steps

1. ✅ Review current configuration
2. ⏭️ Test gateway connectivity
3. ⏭️ Set up agenix for proper secret management
4. ⏭️ Configure Discord/Telegram channels
5. ⏭️ Add plugins as needed
