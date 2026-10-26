# RPN development process guide

**Current position: Step 1 - reviewing the initial specifications.**

This is a working guide, not a fifth engineering specification. The
[SRS](SRS.md), [ICD](ICD.md), [SAD](SAD.md) and [PS](PS.md) remain the technical
authorities. This guide does not change their requirements or revision status.

## The overall flow

```text
0. Initial project brief and four draft specifications [completed]
                         |
1. Your review of intent and scope [YOU ARE HERE]
                         |
2. Reconcile documents and identify blocking decisions
                         |
3. Select and bound the first two-player prototype
                         |
4. Resolve prototype hardware and electrical prerequisites
                         |
5. Prove the risky parts separately
                         |
6. Integrate and verify the first end-to-end prototype
                         |
7. Reconcile the design with measured evidence
                         |
8. Add one capability or console at a time
                         |
             Repeat steps 3-7 for each increment
```

At any failed checkpoint, return to the decision or experiment that failed.
Do not restart the entire project, silently weaken a requirement, or expand
scope to avoid a difficult result.

## 1. Review the initial specifications

**Goal:** establish whether the drafts describe the system you actually want.

Suggested reading order:

1. **SRS:** what the system must do and how success will be verified.
2. **SAD:** responsibility boundaries, ownership policy and design decisions.
3. **ICD:** hardware boundaries, electrical assumptions and unresolved interfaces.
4. **PS:** whether protocol mechanisms support the preceding requirements.

Review for intent first, wording second. For each concern, distinguish:

- **Correction:** the document contradicts your intent or another definition.
- **Decision:** multiple acceptable behaviours require your choice.
- **Question:** evidence or explanation is needed before choosing.
- **Future idea:** potentially useful, but not needed for the current increment.

Edit the documents directly if useful. Preserve stable IDs and keep all four at
Revision 0.1. Uncertainty is acceptable: mark a proposal or open question rather
than making a guess look confirmed. Do not attempt to solve every console now.

**Checkpoint:** you have reviewed the intended behaviour, identified unwanted
assumptions and made your unresolved questions visible. The documents do not
need to be complete or free of all technical unknowns.

**Next prompt:**

> Review my edits across the SRS, ICD, SAD and PS. Identify contradictions,
> feasibility risks and decisions blocking a first prototype. Reconcile
> unambiguous changes, ask me about consequential choices, and retain Revision
> 0.1. Do not implement firmware yet.

## 2. Reconcile the documents and triage decisions

**Goal:** obtain a coherent working draft, not a frozen design.

- Resolve conflicting definitions across requirements, interfaces and protocol.
- Check that two-player routing, ownership, neutralisation and recovery agree.
- Separate owner decisions from questions needing a calculation or experiment.
- Classify each open issue as **blocks the next step**, **needs prototype
  evidence**, or **can wait**.
- Update the existing [SAD decision register](SAD.md#3-decision-register);
  do not create competing decision lists.

**Checkpoint:** no unresolved contradiction blocks prototype scoping, and each
remaining blocker has an explicit next action. Hardware unknowns may remain
open provided they are resolved before the affected hardware is connected.

## 3. Define the first bounded prototype

**Goal:** choose one small vertical slice that proves the architecture.

Decide explicitly:

| Scope item | Required choice |
|---|---|
| Console | One family and identified hardware variant |
| Virtual peripheral | One controller mode per port; no implied support for every accessory |
| Players | Two independent players and two console ports |
| Physical devices | Two identified devices, initially preferably wired USB |
| Ownership | Manual selection first, using the full safe transition mechanism |
| Accessories/feedback | Explicitly included or excluded for this milestone |
| Hardware | Candidate hub/adapter platforms, subject to Step 4 qualification |
| Acceptance | Observable tests and measurement points tied to SRS IDs |
| Exclusions | Features deliberately postponed |

A reasonable candidate is two modern input devices controlling two standard
controllers on one console. Bluetooth, automatic selection, multitaps, storage
and network firmware updates need not be part of that first milestone.
Deferral is not removal from the wider system requirements.

**Checkpoint:** the milestone has a short scope statement, explicit exclusions
and pass/fail tests. You can explain what "done" means without saying
"support the console completely".

**Next prompt:**

> Help me select and define the first RPN prototype. Compare a small number of
> suitable console/controller starting points, then agree the two-player scope,
> exclusions, risks and measurable acceptance tests with me. Keep the broader
> roadmap separate. Do not implement firmware yet.

## 4. Resolve hardware and electrical prerequisites

**Goal:** make the chosen experiment safe and technically plausible.

- Gather authoritative component data and console-interface evidence; record
  sources and distinguish published limits from measurements.
- Complete the selected console's ICD profile: connector orientation/pinout,
  voltage levels, drive modes, power sequencing and timing.
- Budget both ports together: MCU, PIO, DMA, interrupts, RAM, USB and storage.
- Establish the hub's two-device USB-host topology and power budget.
- Resolve grounding/isolation, power sources and no-backfeed behaviour.
- For a bus-connected prototype, choose the harness/connector, transceivers,
  termination and bias arrangement and calculate operating margins.
- Define instruments, current limiting, test points and the connection sequence.

Console-only and bus-only experiments may have different prerequisites.
Approve only the interfaces actually exercised; do not treat a bench setup
as approval for the eventual multi-console deployment.

**Checkpoint:** the relevant electrical review is complete before connecting
original hardware. Unverified pinouts or voltage assumptions block connection.
Changes to candidate hardware are acceptable if resource analysis demands them.

**Next prompt:**

> Develop the hardware feasibility and electrical review for the agreed
> prototype. Identify missing evidence, complete the relevant ICD profile and
> resource budget, and define the safe bench setup. Do not treat unverified
> pinouts or electrical values as established facts.

## 5. Prove the risky parts separately

**Goal:** retire the largest uncertainties before combining everything.

Use small, bounded experiments with a question, setup, acceptance criterion
and recorded result:

| Experiment | Evidence sought |
|---|---|
| Local console emulation | Both ports work from synthetic local input, with measured timing and safe neutral/power transitions |
| Hub input acquisition | Two devices enumerate, report independently and disconnect safely; mappings and capabilities are correct |
| Protocol software tests | Codecs, bounds, duplicates, sessions, generations and lease behaviour work without original hardware |
| Physical bus | Qualified framing/turnaround under the selected harness and load; bounded error recovery |
| Ownership/fault tests | Lost ACKs, reset, expiry and stale traffic cannot create overlapping authorisation |

Prioritise the experiment most likely to invalidate a major design choice.
These experiments need not occur in a rigid order, but each must satisfy its
electrical prerequisites. Do not build the complete framework, management UI or
optional services merely to run them.

**Checkpoint:** each risk needed for integration has passing evidence, or a
revised design and a repeat test. "The code compiles" is not timing evidence.
Record hardware/firmware versions, setup, traces, measurements and limitations.

## 6. Integrate the first end-to-end prototype

**Goal:** demonstrate the agreed slice, not add new features.

Connect acquisition -> generic player contexts -> bus -> adapter-local mapping
-> two console ports. Run the milestone's acceptance tests, including:

- Independent simultaneous control with no cross-player leakage.
- Coherent snapshots and measured sample-to-adapter latency.
- Console response timing under combined USB/bus/two-port load.
- Device removal, hub/adapter reset, bus disconnection and lease expiration.
- Safe release/re-arm with delayed or lost replies.
- Correct routing and expiry of feedback if included.

Ownership tests can first use a simulated second adapter. Claims about two
real, simultaneously powered consoles require the corresponding hardware test;
a one-console demonstration alone does not prove the full multi-console policy.

**Checkpoint:** the agreed acceptance tests pass, or the milestone is explicitly
reported incomplete with failing cases and a recovery plan. Do not substitute
a successful gameplay demonstration for fault and timing tests.

## 7. Bring the documents into line with the evidence

**Goal:** preserve what was learned and avoid specification/firmware drift.

- Update the four documents together where results changed the design.
- Replace provisional assumptions with measured facts only where justified.
- Link evidence to requirement IDs and retain unsupported cases explicitly.
- Review whether the MCU, network profile and proposed common interfaces remain
  suitable before adding another console.
- Review maturity with the owner. Keep Revision 0.1 unless a more stable
  baseline is explicitly approved; a successful prototype alone does not
  automatically justify a revision change.

**Checkpoint:** the documents accurately describe the tested increment and
clearly separate it from unimplemented roadmap features.

## 8. Expand one increment at a time

**Goal:** grow capability without losing the validated baseline.

Select either a new console or a meaningful new capability, not several at
once. Repeat scope -> prerequisites -> experiments -> integration -> evidence.

A second materially different console is especially useful for testing reuse.
Extract the common adapter framework from proven similarities; consider a
separate framework specification after two working drivers, as proposed in
the SAD. Do not force different low-level timing engines into one abstraction.

Storage, firmware update, automatic ownership, Bluetooth and specialised
peripherals each require their own acceptance and failure-recovery tests.
The order depends on your priorities and dependencies, not on a need to
complete every optional service before trying a second console.

## Rules for staying on track

1. **One active milestone.** Put unrelated ideas into the existing future-scope
   or decision register, not into the current implementation.
2. **Work on the next blocker.** Ask what evidence permits the next checkpoint.
3. **Make decisions once, in their authoritative document.** Cross-reference
   rather than copying values into multiple competing specifications.
4. **Separate a hypothesis from evidence.** Record what was tested and under
   which conditions; do not generalise one working game to complete support.
5. **Stop at unsafe or unproven boundaries.** Change the experiment rather than
   risking original hardware.
6. **Close each work session with four items:** what changed, what was verified,
   what remains blocked and the single next action.
7. **Save coherent checkpoints in version control.** Review the diff and commit
   at useful review/test boundaries; commits do not change document maturity.

For the next session, finish Step 1 and use the Step 1 hand-off prompt.
There is no need to select every peripheral or finalise every wire field first.
