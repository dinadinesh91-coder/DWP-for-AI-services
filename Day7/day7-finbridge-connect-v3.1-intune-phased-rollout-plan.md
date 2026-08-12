# FinBridge Connect v3.1 Intune Phased Rollout Plan (10,000 Win11 Endpoints)

Scope date anchor: 2026-08-12 to 2026-09-02 (3 weeks)

## 1. RING STRUCTURE

### Ring design summary

| Ring | Size | Duration | Who to include | Purpose | Intune assignment group type |
|---|---:|---|---|---|---|
| Ring 1 (Pilot) | 300 devices (3%) | 3 days (Week 1, Days 1-3) + 2-day observation overlap | IT engineering, service desk champions, 30-40 users from each major business unit, and 30 devices from the 4GB RAM at-risk population | Validate install/uninstall logic, detection rule accuracy, and top operational risks before business-scale rollout | Entra ID security **device** group, **static membership** (`SG-Intune-FinBridge-R1-Pilot`), Intune assignment = **Required** |
| Ring 2 (Early) | 2,700 devices (27%) | 5 days (Week 1, Day 4 through Week 2, Day 3) | Finance 500 users/devices (highest priority), operations-heavy departments, and additional 170 devices from 4GB RAM population | Controlled business adoption at medium scale; confirm ticket trend and stability under real transaction load | Entra ID security **device** group, **dynamic membership** by approved device list/tag (`SG-Intune-FinBridge-R2-Early`), Intune assignment = **Required** |
| Ring 3 (Broad) | 7,000 devices (70%) | 7 days (Week 2, Day 4 through Week 3, Day 3) | Remaining Win11 managed endpoints, including final 300 devices from 4GB RAM population only after explicit gate pass | Full deployment to complete by deadline while preserving rollback control by wave | Entra ID security **device** groups split into wave batches (e.g., `SG-Intune-FinBridge-R3-W1/W2/W3`), Intune assignment = **Required** |

### Additional ring controls

- Keep v3.0 app object published and ready with pre-created rollback groups before Ring 1 starts.
- Create a dedicated hardware risk group: `SG-Intune-FinBridge-4GB-RAM` (approx. 500 devices).
- Exclude `SG-Intune-FinBridge-4GB-RAM` from Ring 3 waves until Ring 2 hardware criteria pass.
- Use assignment filters or group targeting so each ring remains independently pausable.

## 2. ADVANCE CRITERIA

### Ring 1 to Ring 2 gate (must meet all)

| Criterion | Threshold to advance | Observable source | Time-bound rule |
|---|---|---|---|
| Install success rate | >= 97.0% successful installs | Intune App install status for `SG-Intune-FinBridge-R1-Pilot` | Evaluate after minimum 48 hours since last Ring 1 assignment sync |
| Error rate | <= 2.0% failed installs | Intune App install status (Failed/Not installed where install attempted) | Same 48-hour monitoring window |
| User-reported issues | <= 1.5 tickets per 100 deployed devices; zero Sev-1 tickets open > 4 hours | Service desk queue tagged `FINBRIDGE-V31` + incident priority report | Measured over the same 48-hour window |
| Monitoring period | Minimum observation complete | Intune reporting timestamps + service desk timestamps | Cannot evaluate before 48 hours |

### Ring 2 to Ring 3 gate (must meet all)

| Criterion | Threshold to advance | Observable source | Time-bound rule |
|---|---|---|---|
| Install success rate | >= 98.5% successful installs | Intune App install status for `SG-Intune-FinBridge-R2-Early` | Evaluate after minimum 72 hours since last Ring 2 wave assignment |
| Error rate | <= 1.0% failed installs | Intune App install status | Same 72-hour monitoring window |
| User-reported issues | <= 1.0 ticket per 100 deployed devices; no repeating defect category > 0.3 tickets per 100 | Service desk tagged `FINBRIDGE-V31` with category breakdown | Measured over the same 72-hour window |
| Monitoring period | Minimum observation complete | Intune reporting + service desk trend | Cannot evaluate before 72 hours |

### Hold condition (pause without full rollback)

- Trigger: Any single install error code represents >= 40% of all Ring failures for 12 consecutive hours, even if total failure rate is still below rollback threshold.
- Action: Pause next wave assignments for that ring, keep existing assignments active, isolate affected subgroup, and issue a remediation package.
- Example: Error code `0x87D1041C` rises to 44% of Ring 2 failures for 12 hours due to detection mismatch. Pause Ring 3 launch, patch detection logic, re-evaluate after 24 hours.

## 3. ROLLBACK TRIGGERS

### Trigger matrix and execution model

| Trigger type | Measurable trigger | Decision owner | Decision window | Exact Intune rollback action |
|---|---|---|---|---|
| Install failure rate spike | >= 8.0% failed installs in any active ring over a rolling 6-hour period | Incident Commander (DWP EUC Lead) with Intune Service Owner | 60 minutes from threshold breach | 1) Remove/disable v3.1 **Required** assignment for active and pending wave groups. 2) Add same groups to `SG-Intune-FinBridge-RB-Now`. 3) Assign FinBridge Connect v3.0 app as **Required** to `SG-Intune-FinBridge-RB-Now`. 4) Set v3.1 as **Uninstall** for `SG-Intune-FinBridge-RB-Now` if downgrade requires clean removal. |
| Application crash rate | >= 3 crashes per 100 active devices in 24 hours, or >= 1.0% devices with >= 2 crashes in 24 hours | DWP EUC Lead + Application Owner + Major Incident Manager | 2 hours from validated telemetry | Same rollback steps as above, scoped first to affected ring; freeze all new ring progression until crash root cause is confirmed. |
| Business-critical functional failure | Immediate rollback if Finance cannot complete end-of-day posting in FinBridge Connect on >= 3 independent devices after standard remediation attempts | Major Incident Manager (final authority) | Immediate, start rollback within 30 minutes | Immediate halt of all v3.1 expansion. Add Finance groups to `SG-Intune-FinBridge-RB-Finance`, assign v3.0 **Required** to that group, and set v3.1 **Uninstall** for Finance rollback group. |
| 4GB RAM at-risk failures | >= 12.0% install failure in `SG-Intune-FinBridge-4GB-RAM` over 24 hours, or median install time > 45 minutes on that group | Endpoint Engineering Lead | 4 hours | Isolate hardware cohort: remove 4GB group from all v3.1 Required assignments, keep rollout going for non-4GB cohorts only, and assign v3.0 Required to `SG-Intune-FinBridge-4GB-Rollback`. |

### Operational notes for rollback readiness

- Pre-stage all rollback groups and assignments before first production assignment.
- Document downgrade behavior for `FinBridgeConnect_Setup.exe` (in-place downgrade vs uninstall/reinstall).
- Keep ringed groups intact for post-rollback revalidation; do not dissolve group membership during incident response.

## 4. FINANCE DEADLINE RESOLUTION

### Option A — Compress pilot to place Finance in Ring 2 by end of Week 1

- Minimum safe pilot duration: 72 hours total (48 hours active deployment + 24 hours observation).
- Delivery outcome: Finance can start Ring 2 on Week 1 Day 4 and reach full 500 by Week 1 Day 5.
- Risk introduced: Reduced time to detect low-frequency defects (especially issues appearing after first reboot cycle or overnight scheduled tasks).
- Compensating control: Mandatory twice-daily checkpoint (09:00/16:00), pre-approved rollback change, and Finance smoke-test script run on 20 representative devices before scaling from first 100 to all 500.

### Option B — Create Finance Priority Ring 0 before main pilot

- Ring 0 structure: 500 Finance devices in two waves.
- Wave 0A: 100 Finance devices on Week 1 Day 1.
- Wave 0B: Remaining 400 Finance devices on Week 1 Days 2-3 only if Ring 0A gates pass.
- Ring 0 advance conditions (0A to 0B): >= 97.5% success, <= 2.0% failure, <= 1.0 ticket per 100 devices, 24-hour monitoring minimum.
- Ring 0 rollback plan: If failure >= 8% in 6 hours or business-critical Finance failure occurs, stop 0B, remove v3.1 Required from Finance groups, assign v3.0 Required to `SG-Intune-FinBridge-RB-Finance` immediately.

### Recommendation

Recommend Option B (Finance Priority Ring 0) as the primary approach.

Justification:

- Meets Finance end-of-week-1 requirement with controlled exposure and explicit gates.
- Preserves quality of Ring 1 pilot for the broader 9,500-device population instead of compressing validation for everyone.
- Keeps risk localized: any Finance-specific workflow issue can be contained and rolled back without delaying the full estate plan.
- Maintains the 3-week overall deadline with better operational resilience than a compressed universal pilot.

Implementation decision:

- Execute Ring 0 (Finance) in Week 1 Days 1-3.
- Run Ring 1 pilot in parallel on non-Finance cohorts (or immediately after Day 1 if staffing is limited).
- Proceed to Ring 2 and Ring 3 only through the measurable gates defined above.
