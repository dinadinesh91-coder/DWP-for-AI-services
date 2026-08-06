# Structured Triage Summary

## Summary (one line)
New Windows 11 laptop is prompting for the BitLocker recovery key at every boot, preventing normal startup flow.

## Impact (who/how many/business urgency)
- Who: One end user on a new Windows 11 laptop (to-verify).
- How many: Single reported device/user so far (to-verify).
- Business urgency: High for the affected user because repeated recovery prompts disrupt or block normal device access (to-verify).

## Known facts
- Ticket reference is T-1001.
- Device is described as a new Windows 11 laptop.
- BitLocker is prompting for the recovery key at every boot.
- The issue appears to recur on each startup.

## Missing information to gather
- Whether the user can successfully enter the recovery key and reach Windows.
- When the issue started and whether it began from first use or after a change/update.
- Whether any recent BIOS, firmware, Windows Update, hardware, or docking changes occurred.
- Whether the device is used on-site, remotely, or with different peripherals attached.
- Exact wording shown on the BitLocker recovery screen.
- Whether the issue occurs with the device undocked and with non-essential peripherals removed.
- Whether any other new Windows 11 laptops are showing the same behavior.
- Device asset name, model, and assigned user details.

## Likely category
Endpoint encryption / BitLocker startup recovery issue on a new Windows 11 device.

## First diagnostic step
Confirm whether the user can boot into Windows after entering the recovery key, then check for a recent change to the device startup environment by testing one clean reboot with docks and non-essential USB peripherals disconnected; this quickly helps separate a repeatable platform/startup-state issue from a one-off recovery event.