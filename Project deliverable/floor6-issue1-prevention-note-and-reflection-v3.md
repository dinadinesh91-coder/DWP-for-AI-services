# Floor 6 Prevention Note and Reflection

Version: v3.0  
Date: 2026-08-14  
Author: DWP Engineer

## Prevention Note (Concrete Named Control)
Control name:
- Friday Change Guardrail - Monday Readiness Gate

Definition:
- Any Friday production app deployment to Legal must pass an automated Monday 08:00 readiness check on a pilot set before full user load.
- Gate criteria include sign-in latency threshold, failure-rate threshold, and desktop-path integrity checks.
- If threshold fails, assignment is automatically paused and on-call engineering is paged.

Why this would have caught this:
- Incident symptoms appeared at first Monday peak after a Friday rollout.
- The control tests the same failure modes before broad user impact.

## Required Reflection (First Instinct That Was Wrong)
Initial instinct:
- I first suspected a broad identity outage because users said they could not log in.

What changed my view:
- Scope facts pointed to a tight floor-specific pattern with a matching Friday targeted change window, which is less consistent with a tenant-wide identity event.
- That shifted priority to change-correlation checks before concluding infrastructure-wide failure.
