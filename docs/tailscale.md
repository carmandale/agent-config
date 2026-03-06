# Tailscale Setup

> Network mesh for SSH between machines
> Last Updated: 2026-03-06

## Tailnet

- **Account**: dale.carman@gmail.com
- **Tailnet suffix**: `tailcc9190.ts.net`
- **MagicDNS**: enabled tailnet-wide

## Machines

| Machine | Tailscale hostname | IP | OS | User |
|---------|-------------------|-----|-----|------|
| MacBook Pro M4 | `dales-macbook-pro-m4` | 100.74.174.97 | macOS | dalecarman |
| Mac Mini | `chips-mac-mini` | 100.87.196.118 | macOS | chipcarman |
| iPhone | `iphone182` | 100.83.166.1 | iOS | — |
| VPS | `vmi2998347` | 100.80.248.124 | Linux | — |

**Note**: Tailscale IPs can change if a node is re-registered. Use MagicDNS hostnames, not IPs.

## SSH Aliases

### Laptop → Mini (`~/.ssh/config` on laptop)
```
Host mini-ts
    HostName chips-mac-mini
    User chipcarman
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

### Mini → Laptop (`~/.ssh/config` on mini)
```
Host laptop-ts
    HostName dales-macbook-pro-m4
    User dalecarman
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    IdentitiesOnly yes
```

## Architecture Decision: App Store App (Not Homebrew Daemon)

**Both Macs must run the Tailscale App Store app** for the daemon.

The Homebrew `tailscale` CLI can be installed alongside as a client, but **never run `tailscaled` from Homebrew as the daemon on macOS**. Here's why:

- The App Store app uses a **macOS Network Extension** which properly integrates with the system DNS resolver. MagicDNS just works.
- The Homebrew `tailscaled` runs as a plain userspace daemon. It writes `/etc/resolver/search.tailscale` with search domains but **fails to set the nameserver** to `100.100.100.100`. MagicDNS breaks silently.
- This was confirmed on both machines — the standalone daemon produced identical broken DNS config on each.

### What works

| Component | Source | Purpose |
|-----------|--------|---------|
| **Daemon** | App Store app | Tunnel + DNS via Network Extension |
| **CLI** (`tailscale` command) | Homebrew | `tailscale status`, `tailscale ping`, etc. |

### What doesn't work

- `sudo brew services start tailscale` — runs Homebrew `tailscaled` as daemon. DNS breaks.
- `/usr/local/bin/tailscaled` standalone daemon — same broken DNS.
- Running two daemons simultaneously — creates duplicate nodes, conflicting IPs.

## Key Expiry

Key expiry is **disabled** on both `dales-macbook-pro-m4` and `chips-mac-mini` in the admin console. Without this, nodes silently log out after 180 days (free tier default).

Admin console: https://login.tailscale.com/admin/machines

## Troubleshooting

### Can't resolve Tailscale hostnames
1. Check Tailscale is connected: `tailscale status`
2. If "Logged out" — open the Tailscale app and sign in
3. Verify DNS: `scutil --dns | grep -A 5 ts.net` — should show `nameserver 100.100.100.100` with `Reachable`
4. If no nameserver listed — the App Store app isn't running. **Do not start the Homebrew daemon as a workaround.**

### SSH "Too many authentication failures"
Add `IdentityFile` and `IdentitiesOnly yes` to the SSH config entry. Without this, the SSH agent offers all loaded keys and exhausts `MaxAuthTries` before reaching the correct one.

### Duplicate nodes in admin console
Caused by running two Tailscale daemons. Remove the old node in the admin console, rename the new one, and ensure only the App Store app is running.

### Lost connection after installing App Store app
The old standalone daemon and the App Store app register as separate nodes. Stop the old daemon first:
```bash
sudo launchctl bootout system/com.tailscale.tailscaled
sudo mv /Library/LaunchDaemons/com.tailscale.tailscaled.plist ~/.Trash/
sudo mv /usr/local/bin/tailscaled ~/.Trash/
```
Then remove the stale node from the admin console and rename the new one.
