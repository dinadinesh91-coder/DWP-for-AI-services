Symptom: Floor 6 users report login failures or very slow sign-in on Monday morning after Friday deployment of the document-management app.

Cause: Most-likely cause is app deployment regression in the Floor 6 ring, with startup and sign-in delay from app initialization or repeated IME detect/install retry behavior.

Scope: Floor 6 Legal endpoints in the targeted deployment ring. Exact impacted device count: to confirm.

Workaround: Remove affected devices from the app ring by applying uninstall intent for the Win32 app assignment, then force device sync for sampled impacted endpoints.

Permanent fix: Correct app package/detection logic and enforce a Friday Change Guardrail Monday Readiness Gate before broad release.

How to spot it: Symptom onset follows Friday rollout and clusters in the assigned Floor 6 ring; affected devices show app install before slowdown, while an unaffected control endpoint outside assignment does not show the same IME retry/processing pattern.
