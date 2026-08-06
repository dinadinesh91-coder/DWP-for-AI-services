# Engineer Note

Root cause: Windows 11 upgrade removed the legacy VPN client; Intune did not redeploy the new client because of a detection-rule gap.

Action: Removed stale VPN registry entries under `HKLM\SOFTWARE<vendor>`, force-triggered Intune sync, deployed the new client, and applied split-tunnel configuration.

Verification: Confirmed connectivity to all internal subnets; no data loss.

Preventive action: Remediate the Intune detection-rule gap.