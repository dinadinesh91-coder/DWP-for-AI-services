# Triage Report: Repeated Outlook APPCRASH (KERNELBASE.dll / 0xc0000005)

Date of analysis: 2026-08-06  
Incident type: Repeated application crash  
Application: OUTLOOK.EXE (Office16)  
Host context: Windows 11 build family (from module versioning)

## 1) Distinct Error Codes Present (as provided)

1. `0xc0000005` (Exception code)
2. `Event ID 1000` (Application Error)
3. `Event ID 1001` (Windows Error Reporting)
4. `Event ID 1026` (.NET Runtime)

## 2) What These Codes/Events Indicate

### 0xc0000005
- Exception code indicates an access violation (invalid memory read/write/execute attempt).
- Confidence: High.
- Verify against Microsoft documentation: Yes.

### Event ID 1000 (Application Error)
- Records process crash details (faulting app/module, exception code, offset, process metadata).
- Here: OUTLOOK.EXE faulting in KERNELBASE.dll with repeated same exception code and offset, suggesting a repeatable crash path.
- Verify against Microsoft documentation: Yes (event schema/field interpretation).

### Event ID 1001 (Windows Error Reporting)
- Records WER crash reporting metadata (fault bucket, event name APPCRASH, response/cab metadata).
- Useful for correlation and known-crash matching.
- Verify against Microsoft documentation: Yes.

### Event ID 1026 (.NET Runtime)
- Indicates unhandled managed exception context for the process.
- Here: `System.AccessViolationException`, which aligns with low-level memory access violation behavior and can reflect managed/unmanaged boundary issues (e.g., add-ins/interops).
- Verify against Microsoft documentation: Yes.

## 3) Observed Pattern from Provided Logs

- Repeated crashes within minutes (09:14 and 09:17).
- Same faulting module (`KERNELBASE.dll`) and same exception code (`0xc0000005`).
- Same fault offset where shown (`0x000000000003a4b2`) indicates deterministic/consistent failure path.
- WER APPCRASH and .NET unhandled exception telemetry follow crash events.

## 4) Ranked Remediation Plan (Most Likely Fix First)

The ranking is based on common Outlook crash causality for repeated access violations with consistent offset and module stack behavior.

### 1. Isolate and disable problematic Outlook add-ins (most likely)
Why ranked first:
- Repeated deterministic crashes in Outlook commonly come from COM/VSTO add-ins interacting with UI/startup/mail profile flows.
- 0xc0000005 + 1026 AccessViolation can be produced by add-ins crossing managed/unmanaged boundaries.

Specific checks:
- Launch Outlook in safe mode: `outlook.exe /safe`.
- If stable in safe mode, enumerate add-ins and disable all non-Microsoft add-ins.
- Re-enable add-ins one at a time, reproducing user workflow until crash returns.
- Check Disabled Items and Resiliency keys for auto-disabled crash offenders.
- Capture add-in list and versions for known issue mapping.

Verify against Microsoft documentation:
- Safe-mode/add-in isolation workflow and Office add-in troubleshooting guidance.

### 2. Repair Office installation and update channel integrity
Why ranked second:
- Crash in core Office app path can stem from corrupted Office binaries or broken update state.

Specific checks:
- Confirm installed Outlook/Office build: 16.0.17126.20132 across all Office apps.
- Run Office Quick Repair; if unresolved, run Online Repair.
- Validate update channel consistency (Monthly Enterprise/Current/etc.) and apply latest supported build.
- Re-test Outlook launch/send-receive after repair.

Verify against Microsoft documentation:
- Official Office repair process and update channel/build support matrix.

### 3. Rebuild Outlook profile / OST and test with clean profile
Why ranked third:
- Profile or OST corruption can trigger repeatable crashes at startup/navigation actions.

Specific checks:
- Create a new MAPI profile in Mail control panel.
- Configure same mailbox in new profile and set as default test profile.
- For cached mode, recreate OST by closing Outlook and allowing clean OST regeneration.
- Compare behavior old profile vs new profile.

Verify against Microsoft documentation:
- Supported profile recreation and OST regeneration guidance.

### 4. Validate and remediate system file integrity (KERNELBASE dependency path)
Why ranked fourth:
- Faulting module is Windows core DLL; often victim module, but host integrity still must be verified.

Specific checks:
- Run `sfc /scannow`.
- Run `DISM /Online /Cleanup-Image /RestoreHealth`.
- Confirm no integrity violations remain.
- Reboot and re-test Outlook.

Verify against Microsoft documentation:
- DISM/SFC remediation workflow and interpretation.

### 5. Check .NET runtime health and Office interop prerequisites
Why ranked fifth:
- Event 1026 indicates managed runtime involvement.

Specific checks:
- Confirm .NET Framework 4.8/OS components healthy (Windows Features and servicing state).
- Review Application/System logs for CLR loader, fusion, or side-by-side errors around crash times.
- Apply pending cumulative updates relevant to .NET/Windows 11.

Verify against Microsoft documentation:
- .NET runtime event interpretation and remediation for 1026/AccessViolationException.

### 6. Collect crash dump and perform symbol-based fault analysis (if still unresolved)
Why ranked sixth:
- Required when environmental checks fail and root cause needs precise module/function attribution.

Specific checks:
- Enable local dumps for OUTLOOK.EXE (WER LocalDumps policy).
- Reproduce crash and analyze dump (WinDbg): exception context, call stack, loaded modules/add-ins.
- Confirm whether third-party module/add-in appears in call chain before KERNELBASE fault.

Verify against Microsoft documentation:
- WER LocalDumps registry configuration and Microsoft-supported dump collection practices.

## 5) Root Cause Hypothesis

Most likely cause: a repeatable Outlook execution path is triggering an access violation (`0xc0000005`), with highest probability on third-party add-in or Outlook profile/data interaction, rather than random transient failure.

Evidence:
- Same app, same module, same exception code, repeated in short interval.
- Identical fault offset where provided implies deterministic path.
- .NET Runtime `System.AccessViolationException` supports managed/unmanaged boundary fault possibility.

Confidence: Medium-high (without dump/add-in inventory, final attribution remains provisional).

## 6) Immediate Runbook (Operational)

1. Test in safe mode (`outlook.exe /safe`).
2. Disable all non-Microsoft add-ins.
3. Retest normal mode.
4. If still crashing, Office Quick Repair then Online Repair.
5. If still crashing, create new Outlook profile and regenerate OST.
6. Run SFC and DISM checks.
7. If unresolved, collect dump and escalate with dump + add-in inventory + WER bucket.

## 7) Data to Capture for Escalation

- Full Event 1000/1001/1026 XML for each occurrence.
- Outlook build, Office channel, patch level.
- Add-in inventory (name, vendor, version, load behavior).
- Repro steps and frequency.
- Crash dump with timestamp correlation.
- User impact scope (single endpoint vs multiple users).

## 8) Items Explicitly Marked for Microsoft Doc Verification

- Canonical interpretation of `0xc0000005` in Outlook crash context and diagnostic caveats.
- Event 1000/1001/1026 schema details and recommended triage order.
- Supported Office repair and update channel guidance for build 16.0.17126.20132.
- Official profile/OST remediation steps and constraints.
- WER LocalDumps configuration and supportability boundaries.
