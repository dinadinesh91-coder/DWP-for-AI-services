# Structured Triage Summary

## Summary (one line)
Teams audio is not working on three machines in the same meeting room.

## Impact (who/how many/business urgency)
- Who: Users of three machines in the same meeting room.
- How many: Three machines are reported affected in one room.
- Business urgency: High if the room is needed for active meetings, collaboration, or customer calls (to-verify).

## Known facts
- Ticket reference is T-1005.
- Teams audio is described as dead.
- Three machines are affected.
- All affected machines are in the same meeting room.

## Missing information to gather
- Whether the issue affects microphone, speaker output, or both.
- Whether audio fails only in Teams or also in Windows/system sound.
- Whether the machines share the same room audio hardware, dock, display, or USB peripherals.
- Whether the issue started at the same time on all three machines.
- Whether any recent room equipment, driver, or Windows changes occurred.
- Exact behavior in Teams: no devices detected, muted audio, no input level, or no output.
- Whether another room or headset works on the same machines.

## Likely category
Meeting room audio / Teams device or shared peripheral issue.

## First diagnostic step
Check whether all three machines are using the same room audio device and test Windows sound outside Teams; this quickly determines whether the fault is tied to shared room hardware/peripherals or is isolated to the Teams client.
