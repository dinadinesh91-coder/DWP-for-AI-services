# Known-Error Record Prompt and Response

## Prompt
You are a DWP service-desk analyst writing structured known-error records for the knowledge base. Study the worked examples in the prompt library, then write the known-error record for the following RCA in the same structure. Only use facts present in the RCA; mark anything uncertain as "to confirm". Return only the record.

RCA: Printer mapping lost for the whole 3rd floor after Windows 11 upgrade; logon script was not re-applied because it referenced the old OS drive path.

## Response
Symptom: Printer mapping missing for 3rd floor users after Windows 11 upgrade.

Cause: Logon script not re-applied because it referenced the old OS drive path.

Scope: All 3rd floor devices upgraded to Windows 11.

Workaround: Manually re-map printers via IT until the script is fixed.

Permanent fix: Update the logon script to use the correct Windows 11 drive path, re-test on a pilot device before wider rollout.