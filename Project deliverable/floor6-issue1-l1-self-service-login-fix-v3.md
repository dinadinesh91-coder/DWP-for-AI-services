# L1 Self-Service: Floor 6 Sign-In Issue

Version: v3.0  
Date: 2026-08-14  
Audience: Floor 6 users  
Related runbook: floor6-issue1-runbook-login-fix-v3.md

## What's happening
Some Floor 6 users are experiencing slow sign-in or sign-in failures after a software update deployed Friday. This affects sign-in only—your files and data are safe.

## What to do first

1. **Restart your laptop**.
2. **Connect to the internet and keep power connected** during startup.
3. **Sign in and wait up to 10 minutes** for Windows updates to finish downloading and installing.
4. **Try signing in again** once the wait period is complete.

## If sign-in is still slow or fails

Contact the IT Service Desk with:
- Your device name
- The time the problem started
- A screenshot of any error message (if applicable)

## What IT is doing to fix this
- Removing the problematic software update from affected Floor 6 devices.
- Using Intune to force device synchronization so the fix applies as quickly as possible.
- Monitoring each device to confirm recovery before considering the incident closed.

## Why this is happening (technical background)
A document-management application deployed Friday to Floor 6 is causing extended sign-in delays during the startup process. IT is removing this application from the affected device group to restore normal sign-in performance.

## Expected recovery timeline
Most users should see improvement within 1–2 hours of IT applying the fix. Some devices may take longer depending on when they next connect to the internet and sync.

**Your data is safe. Do not attempt to remove software manually—wait for IT's automated fix.**
