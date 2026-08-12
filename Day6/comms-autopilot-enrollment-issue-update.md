# Incident Communication — Autopilot Enrollment Issue Update

**Issue:** Some devices unable to complete enrollment in Intune Autopilot  
**Status:** Identified and Resolved (Remediation in Progress)  
**Date:** 2026-08-11  
**Audience:** FINBRIDGE users, managers, IT staff  

---

## What Happened?

Between March and August 2024, a small number of devices experienced issues completing their enrollment in our new Autopilot management system. These devices appeared to enrol successfully but could not access corporate resources (Microsoft Teams, Outlook, OneDrive, etc.) because background security and compliance checks could not complete.

**Affected devices:** DESKTOP-FB099 and potentially others in March 2024  
**Root cause:** Old device enrollment records from November 2023 were not properly cleaned up before the devices were re-enrolled in the new Autopilot system. This created a conflict in the management system that prevented policies from being applied.

---

## Who Is Affected?

**Most likely affected:** Users who received a device re-enrollment or reset between **March 1 and March 31, 2024**, and who noticed they could not access Teams, Outlook, or other corporate applications after the process completed.

**If you are unsure whether you are affected:**
- You can access Teams, Outlook, OneDrive, and SharePoint without issues ✓ = **NOT affected**
- You cannot access Teams, Outlook, or other services, even though your device appeared to finish enrolling ✗ = **Possibly affected** — contact IT Support

---

## What We Are Doing

1. **Identifying affected devices** — IT is running reports to find all devices with this issue
2. **Fixing affected devices** — IT Support will contact you to remotely fix your device (may require a reboot)
3. **Preventing future issues** — We are updating our procedures and automation to prevent this from happening again

---

## What You Need To Do

**If you think your device is affected:**
1. Contact IT Support via [support portal / email / phone]
2. Provide your device name and username
3. Let them know you suspect an enrollment issue (mention error 0x80180014 if you have seen error messages)
4. Support will schedule a fix, which typically requires a device reboot during your lunch break or after hours

**If your device is working fine:**
- No action needed. We will monitor your device automatically.

---

## What's the Fix?

The fix involves:
1. Removing the old enrollment record from our management system (2–3 minutes)
2. Restarting your device to clear old data (5–10 minutes)
3. Re-enrolling your device in the new Autopilot system (5–30 minutes, mostly automatic)
4. Verifying you can access corporate services again (5 minutes)

**Total time:** Approximately 30 minutes  
**Data loss:** None — you keep all your files and settings  
**Disruption:** One device reboot required  

---

## Timeline

| Date | Status |
|---|---|
| **March 2024** | Issue first identified on DESKTOP-FB099 |
| **August 11, 2026** | Root cause analysis completed; remediation plan approved |
| **August 31, 2026** | All IT procedures and automation updated |
| **September 15, 2026** | All identified affected devices remediated |
| **September 30, 2026** | Final verification complete; issue closed |

---

## Why Did This Happen?

Our procedures for migrating devices from the old management system (legacy MDM) to the new system (Autopilot) did not include a step to verify that old enrollment records were removed before starting the new enrollment. This was identified as a gap and is being fixed in our updated procedures.

This was not a device problem, not a network problem, and not a user error — it was a procedural gap on our side.

---

## Questions?

**Q: Will this affect my work laptop / desktop?**  
A: Only if your device was re-enrolled or reset between March 1–31, 2024. You can check by trying to open Teams or Outlook — if they work, you are not affected.

**Q: Will I lose my files?**  
A: No. The fix process specifically preserves all your files, documents, and settings.

**Q: Do I need to do anything before IT contacts me?**  
A: No. Just be ready to reboot your device when IT Support schedules the fix.

**Q: How long will my device be unavailable?**  
A: About 30–45 minutes total, mostly automatic after we start the fix.

**Q: What if my device is remote or I can't access it?**  
A: IT Support can often fix it remotely without you needing to be at your desk. We'll arrange a time that works for you.

**Q: Why is this taking so long to fix?**  
A: The initial identification took a few months because the issue was intermittent (affected only March enrollments). Once identified, IT completed a full root cause analysis and is now implementing both the immediate fix and long-term preventive measures to ensure this never happens again.

---

## Thank You

We appreciate your patience while we resolved this issue. The fix ensures that your device is secure, compliant, and can access all corporate services properly.

If you have questions or concerns, please contact IT Support.

---

**Contact Information:**
- **Help Desk:** [Phone / Email]
- **Support Portal:** [URL]
- **Manager Escalation:** [Email / Contact]

---

*Communication Issued: 2026-08-11*  
*Next Update: 2026-08-31*
