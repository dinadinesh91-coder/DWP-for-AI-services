# L1 Self-Service KB: Floor 6 Desktop Shortcuts Missing

Version: v1.0  
Date: 2026-08-14  
Audience: Floor 6 users  
Related runbook: floor6-issue3-runbook-desktop-shortcuts-v1.md

## What you may see
After the Windows 11 migration and Friday app changes, your desktop shortcuts or files may appear to be missing or hidden.

## Good news
In most cases, your files are **still there**—they're just not showing up in the right place. This is usually a visibility or path problem, not data loss.

## What to do right now

### Step 1: Restart your laptop
- Save your work
- Perform a clean restart
- Connect to the internet and keep power connected during startup

### Step 2: Wait for Windows to complete updates
- After signing in, wait about 10 minutes
- Let any pending Windows updates finish installing
- Do not force shutdown during this time

### Step 3: Check your desktop again
- Look for your shortcuts and files
- If they've reappeared, the issue is resolved
- No further action is needed

## If shortcuts still don't appear

**Before contacting IT, try this quick check:**

1. Open **File Explorer** on your desktop
2. Look in `C:\Users\Public\Desktop`
3. Check if your files are visible in that location
4. If yes, they're safe—just in a different location

## When to contact the IT Service Desk

If shortcuts are still missing after restart and the 10-minute wait, contact IT and provide:

- Your device name
- The time the problem started  
- A screenshot of your current desktop (showing it's empty)
- Whether you checked `C:\Users\Public\Desktop` and what you found

## What IT will do

When you contact IT, they will:
- Check the file paths on your device
- Verify where your desktop files actually are
- Restore the correct visibility/path settings
- Confirm files are still safe
- Resolve the issue with one sign-out and sign-in cycle

## FAQ

**Q: Are my files deleted?**  
A: No. In almost all cases, files are still on your device but Windows is pointing to the wrong location.

**Q: Will I lose data?**  
A: No. IT's fix will not delete any data.

**Q: Can I fix this myself?**  
A: No. Contact IT Service Desk. Do not manually edit Windows settings or file paths.
