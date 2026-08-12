# Knowledge Base — L1 Support Guide
## Autopilot Enrollment Error 0x80180014 — "Device Already Enrolled in MDM"

**KB ID:** KB-AUTO-L1-001  
**Audience:** Help Desk / L1 Support Staff  
**Last Updated:** 2026-08-11  
**Difficulty Level:** Basic  

---

## Quick Identification Checklist

**Does the user have this issue?** Check all that apply:

- ☐ User says: "My device finished enrollment but I can't access Teams / Outlook / corporate apps"
- ☐ Device is listed in Intune **Devices > All devices** but compliance shows "Error" or "Unknown"
- ☐ Error message mentions "0x80180014" or "Device already enrolled in MDM"
- ☐ Device was re-enrolled or reset around March 2024
- ☐ User can turn on device and log in, but corporate services are blocked
- ☐ Device rebooting does not fix the issue

**If 3 or more items are checked:** → This is likely the Autopilot enrollment error  
**Proceed to "When to Escalate" section below**

---

## What This Error Means (Simple Explanation)

Think of device enrollment like a library membership:
- The device tried to sign up for the new Intune Autopilot membership (2024)
- But the device still had an old enrollment membership from 2023
- The system won't let a device have two memberships at once
- So enrollment failed because of the old membership

**Result:** Device looks enrolled but can't access resources because the system is confused about which membership it should use.

---

## When to Escalate to L2/L3

**Escalate immediately if:**
1. User confirms they cannot access Teams, Outlook, or other corporate services
2. Device shows error in Intune compliance (status: "Error" or "Unknown")
3. User device was enrolled or reset between **March 1–31, 2024**

**Do NOT attempt to fix yourself.** This error requires Intune admin access and administrator-level PowerShell commands on the device.

---

## What YOU Should Tell the User

**When contacting the user:**

"Hi [User Name],

We've identified an issue with your device enrollment that's preventing you from accessing corporate services. This is NOT a device problem or network problem — it's a configuration issue on our management system that we've fixed.

To resolve this, we'll need to:
1. Remotely remove your device from the old enrollment system
2. Have you reboot your device when we're ready (about 30 minutes total)
3. Re-enroll your device in the new system
4. Verify everything works

Your files and programs will not be affected. Can you make time for this during [time options]?"

---

## Information to Collect from User

When the user contacts support, collect:

| Item | Example | Purpose |
|---|---|---|
| **Device Name** | DESKTOP-FB099 | To find device in Intune |
| **Username** | finbridge\rthomas | To confirm ownership and check license |
| **When enrolled/reset** | March 15, 2024 | To confirm timeframe matches known issue |
| **Current symptom** | "Can't access Teams" | To confirm it's this error, not something else |
| **Time available** | "Tomorrow after 2pm" | To schedule the fix |

---

## Escalation Template

Use this template when handing off to L2/L3:

```
ESCALATION: Autopilot Enrollment Error 0x80180014

Device: [Device Name]
User: [Username]
Reported: [Date/Time]
Symptom: [What user reported]

Details:
- Device re-enrolled around March 2024
- Cannot access Teams/Outlook
- Intune compliance shows "Error"
- Matches Known Error KB-AUTO-L1-001

Action Needed:
1. Device deprovisioning (remove from Intune)
2. Local device cleanup (PowerShell)
3. Re-enrollment trigger
4. Verification

User Available: [Time/Date]

Escalation Contact: [Your Name/Ticket ID]
```

---

## Frequency & Known Devices

**How often does this happen?**  
- Rare — only affects devices re-enrolled during March 2024
- Approximately 1–5 devices (final count pending audit)
- Expected to stop happening after August 2026 (permanent fixes deployed)

**Known affected device(s):**
- DESKTOP-FB099 (FINBRIDGE\rthomas) — RESOLVED 2026-08-11

---

## Do NOT Try These (Common Mistakes)

❌ **Do NOT suggest user restart the device**  
→ Won't help; the issue is in the management system, not the device

❌ **Do NOT ask user to sign out / sign in again**  
→ Won't help; Conditional Access is blocking sign-in, not device state

❌ **Do NOT suggest uninstalling and reinstalling Microsoft 365 apps**  
→ Won't help; the issue is enrollment-level, not app-level

❌ **Do NOT submit ticket to "Windows Support" or "Microsoft Support"**  
→ This is an Intune configuration issue; route to Intune Admin team only

---

## FAQs You'll Likely Hear

**Q: "Will I lose my files if you reset my device?"**  
A: "No, we're not fully resetting your device — we're clearing only the old management settings and letting it re-enroll. You keep all files and programs. We'll use the 'Keep my files' option."

**Q: "How long will this take?"**  
A: "About 30–45 minutes total. Most of it is automatic after we start the process. You'll need to reboot once."

**Q: "Can you do it tonight after I leave?"**  
A: "Yes, we can schedule it remotely during off-hours so you're not interrupted."

**Q: "Why did this happen to my device?"**  
A: "It's not your fault. When your device was re-enrolled in March, an old enrollment record from 2023 wasn't properly removed before the new enrollment started. We've identified this and fixed our procedures so it won't happen to anyone else."

**Q: "Why is this taking so long to fix?"**  
A: "We only discovered all affected devices recently during an audit. Once identified, we prioritized fixing them. IT is also implementing procedures to prevent this from happening to any new devices."

---

## Reference Materials

| Document | When to Share | Audience |
|---|---|---|
| [Known Error Record](known-error-autopilot-enrollment-0x80180014.md) | When user asks for technical details | Power users / technically inclined |
| [User Communication](comms-autopilot-enrollment-issue-update.md) | To provide broader context | Users who want to understand the issue |
| [L2/L3 KB Guide](kb-l2l3-autopilot-enrollment-troubleshooting.md) | For your own reference during escalation | L2/L3 support staff |

---

## Ticket Closure Checklist (L1)

Before closing the ticket after L2/L3 remediation:

- ☐ User confirmed device is working (can access Teams, Outlook, etc.)
- ☐ User confirmed no data loss occurred
- ☐ No follow-up issues reported
- ☐ Ticket notes reference the Known Error record (KB-AUTO-L1-001)
- ☐ If new case found, escalate with all required info for L2/L3

---

## Escalation Contact

**Intune Admin Team (L2/L3):**
- **Email:** [intune-admins@company.com]
- **Slack:** #intune-support
- **Phone:** [Extension]

**First-Line Escalation Manager:**
- **Name:** [Manager]
- **Contact:** [Email/Phone]

---

**Created:** 2026-08-11  
**Version:** 1.0  
**Review Date:** 2026-09-30  

*This KB article is for L1 support staff. For technical troubleshooting details, refer to KB-L2L3 guide.*
