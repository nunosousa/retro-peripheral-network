# Review record REVIEW-001

| Field | Value |
|---|---|
| Date | 2026-11-17 |
| Reviewer | System requirements reviewer (AI assistant) |
| Process | [RPN-RVP](../REVIEW-PROCESS.md) revision 0.1 |
| Reviewed commit | `8a5062f` (Add Electrical Interface Capability Specification and update companion document links) |
| Documents reviewed | [README](../../README.md); [SRS](../SRS.md), [ICD](../ICD.md), [SAD](../SAD.md), [PS](../PS.md) (all Rev 0.1, 2026-10-23); [EIC](../EIC.md) (Rev 0.1, 2026-11-16); [DEVELOPMENT-GUIDE](../DEVELOPMENT-GUIDE.md) |
| Phases performed | 1-9 of the process. Phase 6/7/8 console and silicon facts are from the reviewer's general knowledge plus the documents' own references; **no primary datasheet or console manual was consulted**, so every such statement below is marked "verify" and is a question, not a finding of fact. |
| Status of this record | Awaiting owner responses. The reviewed documents were **not modified** by this review. |

## 1. Owner constraints for this cycle

| ID | Constraint | Applies? |
|---|---|---|
| OC-1 | The design standardises on the **RP2350 MCU family**. | **Yes** - conflicts with several documents; see RR-001-001..007. |

## 2. Summary

40 remarks. Priority order for the owner: all **S1** remarks first (hardware safety
and safety-invariant items; they block Step 4 of the development guide), then **S2**.

| Severity | Count |
|---|---:|
| S1 Blocker | 5 |
| S2 Major | 24 |
| S3 Minor | 9 |
| S4 Editorial | 2 |

| Theme | Remarks |
|---|---|
| A. Platform (RP2350) | RR-001-001 .. 007 |
| B. Consistency and document control | RR-001-008 .. 015 |
| C. Protocol coherence and timing | RR-001-016 .. 025 |
| D. Console input and peripheral coverage | RR-001-026 .. 027 |
| E. Electrical interfaces | RR-001-028 .. 036 |
| F. Completeness and process | RR-001-037 .. 040 |

Overall assessment: the SRS, SAD and PS are internally strong and unusually careful
about safety (lease, generation, drain guards; honest classification of unknowns).
The main risks are (1) the platform statement is stale relative to the owner's RP2350
decision, (2) the new EIC is not yet integrated into the document set and makes
universal, per-channel claims that conflict with per-console reality and with the
"two ports, two players" scope, (3) the 5 ms cadence has no slack for any non-input
timeout, and (4) several console-facing electrical facts need primary-source
verification before any original hardware is connected.

## 3. Items verified without remark

These were independently recomputed or checked and found correct. Keep them stable.

| Item | Result |
|---|---|
| Markdown links and anchors in all documents | All resolve |
| CRC-32C check value of `123456789` | `0xE3069283`, transmitted `83 92 06 E3` - correct |
| PS-VECTOR-001 | Header, CRC `bf d6 e9 97` and the 28-byte COBS-plus-delimiter string recomputed - exact match; COBS-only vectors correct |
| Frame sizes | Header 22, minimum 26, max raw 218, max COBS 219, max wire 220 (2.20 ms at 1 Mbit/s) - correct |
| Message sizes | INPUT payload 69 / raw 95 / wire 97; ACK 15 / 41 / 43; ROUTES record 13; INPUT record 32 (offsets consistent); HELLO response 34; STATUS response 24; bulk chunk bound 183 - correct |
| Exchange arithmetic | 1.70 ms success (34 % of 5 ms), 4.02 ms INPUT timeout path, 5.25 ms maximum-request timeout path - correct |
| Clock/lease arithmetic | 100/0.99 + 1/0.99 = 102.02 ms < 103 ms; 110/1.01 = 108.9 ms - correct and conservative (see RR-001-021 for the unstated baud assumption) |
| Transaction-ID horizon | 2^32 / 200 per s = 248 days - correct |
| EIC channel arithmetic | All per-port and aggregate counts and the 14-channel maximum are arithmetically correct (their content is questioned in section 4, theme E) |
| Cross-document ID references | Every `SRS-V-*` design reference (`PS-*`, `SAD-*`, `ICD-*`) resolves to a defined element |

## 4. Remarks

Each remark leaves **Owner response** and **Resolution** blank. Severity and category
definitions are in [RPN-RVP](../REVIEW-PROCESS.md#6-severity-definitions).

---

### Theme A - Platform (RP2350)

#### RR-001-001 - Documents still treat RP2040 as the "starting point"

| Locations | SRS-HW-001; SAD-R-008, SAD-O-003; ICD-PWR-001 (RP2040 USB paragraph), ICD section 6 (RP2040 flash/XIP); PS-DISCOVERY (RP2040 serial number) |
|---|---|
| Category / Severity / Gate | Correction + Decision / S2 / Step 2 (reconcile) |

**Remark.** The owner has decided to standardise on the RP2350 family, but SRS-HW-001
(class C) says RP2040 is "evaluated... not mandated", SAD-R-008 and SAD-O-003 keep the
MCU open and allow "alternate silicon", and ICD/PS contain RP2040-specific statements.
Is the intent that RP2350 is now a mandated platform for the hub **and** every adapter
processor, or only the default, with documented exceptions (for example a console whose
interface RP2350 cannot meet)?

**Suggested solution.** Add a new class-C requirement (for example `SRS-HW-005`:
"The RPN hub and adapter processors shall be members of the RP2350 family unless a
documented, owner-approved exception exists") and **retire** SRS-HW-001 rather than
editing it in place (IDs are not reused). Add a decision-register entry (for example
`SAD-D-004`), reduce SAD-O-003 to the remaining open items (USB topology, radio), and
replace each RP2040 statement by an RP2350 statement checked against the current
datasheet (RR-001-003). Define the exception procedure.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-002 - Which RP2350 variant, core architecture and resource budget?

| Locations | SRS-HW-001/004; SAD-O-004; ICD-CON-001 "Resources"; EIC section 7 |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 4 |

**Remark.** "RP2350 family" spans package/pin-count variants (a smaller-GPIO and a
larger-GPIO variant, and variants with stacked flash), and Arm and RISC-V cores.
Which are acceptable? The EIC resource table needs a per-console GPIO / PIO state
machine / DMA / interrupt budget on the chosen part: the two-port Mega Drive needs 14
channels, PS2 needs two simultaneous SPI-like slaves with ACK timing, N64/GameCube need
a precisely timed open-drain engine per port. Is one RP2350 enough for each profile?
(Verify variant list, PIO block/state-machine counts and GPIO counts against the
current datasheet.)

**Suggested solution.** Record the permitted variants and core architecture in a
decision (suggest the Arm core and one common variant per role for tool and library
maturity, unless a variant is needed), and add a per-profile resource table to each
ICD-CON-001 supplement with a margin rule (for example: no more than 70 % of any
resource in the worst two-port combination).

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-003 - RP2350 errata and 5 V tolerance versus the EIC universal channel

| Locations | EIC 4.1, 4.2, 5.2, 9 (items 3-5); SRS-HW-002; ICD-NET-001 ("GPIO pull states alone are insufficient") |
|---|---|
| Category / Severity / Gate | Question / **S1** / Step 4 (before any console connection) |

**Remark.** (To verify.) The RP2350 datasheet specifies conditions under which GPIO are
5 V tolerant (for example only while the I/O supply is powered and at a stated level),
and the family has published errata relating to GPIO input pad leakage / pull-down
behaviour on some silicon steppings that can affect high-impedance and open-drain
designs. The EIC requires "5 V input tolerance", high-Z and configurable pull-up/down
on every channel. Which silicon stepping is targeted, which errata affect these
interfaces, and does the design depend on MCU-side 5 V tolerance, pull-ups or pull-downs
or only on external translators?

**Suggested solution.** Add a "platform datasheet and errata register" (document
revision, stepping, errata ID, affected interface, mitigation) to the ICD, require that
no console-facing signal relies on internal pulls or MCU 5 V tolerance, and add an EIC
verification entry for unpowered-MCU / powered-console behaviour of each channel.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-004 - Hub USB host topology on the RP2350

| Locations | ICD-PWR-001; SAD-O-003; SRS-HW-004; DEVELOPMENT-GUIDE step 4 |
|---|---|
| Category / Severity / Gate | Question / S2 / Step 4 |

**Remark.** ICD-PWR-001 argues from the RP2040's single native USB controller. As far
as the reviewer knows the RP2350 also has one native full-speed controller (verify).
Which mechanism provides **two** simultaneous input devices on the hub: a USB hub chip
on the native host port, the PIO-USB approach (consuming PIO resources that also drive
other functions), or a second MCU? Is a USB-attached radio/bluetooth path reserved?
What is the pass criterion for "two devices" (report rates, low-speed and full-speed
mixes, hub-powered devices)?

**Suggested solution.** Decide the mechanism and rewrite ICD-PWR-001 for RP2350 with a
resource budget (PIO state machines, DMA, interrupts, RAM) covering USB host, the
RS-485 UART/PIO, and any display/UI; record the first-prototype choice (wired USB
only, native host plus hub IC) explicitly as in development-guide Step 3.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-005 - Original Xbox adapter: four USB device ports versus RP2350 USB resources and the two-player scope

| Locations | EIC 4.4, 6.10, 7, 7.2; SRS-SYS-006; SAD-R-001; ICD-CON-001 (Xbox row) |
|---|---|
| Category / Severity / Gate | Decision / S2 / Xbox profile (not the first prototype) |

**Remark.** EIC requires four independent USB full-speed **device** interfaces and says
a shared transceiver is not sufficient. An RP2350 provides one native USB controller
(verify), and a USB device cannot be multiplexed across physical connectors. Therefore
the Xbox adapter needs one processor (or one PIO-based USB device implementation,
whose device-mode suitability is unproven) per USB port. (a) Is the requirement really
four ports, when only two players are routable? (b) If several processors are required,
how are they presented as one adapter: one bus node with an internal gateway, or several
nodes with several UIDs/addresses? This affects SRS-SYS-006 ("one adapter represents one
console"), the PS address plan and commissioning.

**Suggested solution.** Option A (recommended for scope): the Xbox adapter implements two
USB device ports (matching the two-player limit); the other two console ports are left
unconnected (the console sees no controller). Option B: four ports, four processors.
In both cases specify the intra-adapter interconnect (for example an internal UART/SPI
to a single gateway processor that owns the RS-485 node), the gateway's role in lease
enforcement, and update SAD-R-001 accordingly.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-006 - Unique ID and session entropy using RP2350 facilities

| Locations | PS-DISCOVERY (128-bit UID; "RP2040 silicon serial number... not sufficient"); PS-TRANSACTION (session entropy "must document entropy"); SAD-P-003 |
|---|---|
| Category / Severity / Gate | Decision / S3 / Step 5 (protocol tests) |

**Remark.** (To verify.) The RP2350 has a one-time-programmable memory with a chip
identifier and a hardware random number generator, which the RP2040 lacked. The PS
rules were written without them. Should the 128-bit UID be provisioned into OTP
(user area) at manufacture, and the hub session ID seeded from the hardware RNG? Is a
64-bit chip ID alone acceptable (the PS demands 128 bits)?

**Suggested solution.** Define provisioning explicitly: 128-bit UID = vendor-defined
value written to OTP and locked, printed on a label; session ID = 64 bits from the
hardware RNG with a documented health check and a fallback persistent counter. Update
PS-DISCOVERY and PS-TRANSACTION wording accordingly.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-007 - Firmware update and signature scheme should use RP2350 boot features

| Locations | SRS-UPD-001/003; PS-SVC-UPDATE; SAD-O-008; SAD section 8 |
|---|---|
| Category / Severity / Gate | Decision + Future / S3 / before advertising Update |

**Remark.** (To verify.) The RP2350 boot ROM supports partitioned/A-B images, signed
images and anti-rollback through OTP. PS-SVC-UPDATE says the manifest, signature, boot
selection and rollback are "not yet defined" and SAD-O-008 leaves this open. Is the
intent to base the concrete update profile on these facilities, and is secure boot (which
involves irreversible OTP programming) acceptable for prototypes? Should network update
remain out of the first prototype?

**Suggested solution.** Mark Update explicitly **Future** for the first prototype; when
addressed, write an update profile supplement (image format, signing, anti-rollback,
recovery path, OTP policy) with a prototype/production distinction so development boards
are never irreversibly locked by accident.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

---

### Theme B - Consistency and document control

#### RR-001-008 - The EIC is not integrated into the document set

| Locations | SAD header (companions); PS header (companions); DEVELOPMENT-GUIDE (intro, reading order, "four documents", Step 1/7 prompts); SAD section 2 ("four-document"); SRS section 1 (ID prefixes and ownership); SRS section 8 (SRS-V-006 references) |
|---|---|
| Category / Severity / Gate | Correction / S2 / Step 2 |

**Remark.** Only the README, SRS header and ICD header were updated for the EIC. The SAD
and PS companion lists omit it; the development guide still speaks of "four" documents
and its reading order omits the EIC; SRS section 1 declares prefixes `SRS-/ICD-/SAD-/PS-`
but the EIC defines `EIC-VER-*`; no SRS verification row references the EIC; the SRS
ownership sentence ("PS owns wire definitions, ICD electrical definitions...") does not
mention the EIC. Should the EIC be a peer specification with its own ID prefix, ownership
statement and place in the reading order?

**Suggested solution.** Update every companion list, the SRS identifier/ownership
paragraph (add `EIC-*`), SRS-V-006's design references, the development guide
(five documents, reading order after the ICD) and replace "four-document" wording.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-009 - Authority overlap between ICD (ICD-CON-001) and EIC section 6

| Locations | ICD section 5 (risk inventory, per-profile supplement); EIC sections 5-8; SRS section 1 ("ICD electrical definitions") |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 2 |

**Remark.** The ICD says no console pinout or voltage table is approved and that
per-console electrical truth lives in controlled ICD-CON-001 supplements; the EIC contains
per-console signal tables, channel counts and voltage rails. Which document is
authoritative for a given console signal, and what happens when a supplement disagrees
with the EIC? Is the EIC a *capability envelope* (what hardware must be able to do) and
the ICD supplement the *approved per-console truth*?

**Suggested solution.** State a precedence rule in both documents: EIC = minimum
capability envelope and aggregate budgets (a sizing baseline, never an approval to wire);
ICD supplements = per-console approved electrical facts; a supplement may narrow but not
exceed the envelope without an EIC change. Remove duplicated values from one side
(single source per fact).

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-010 - Document control inconsistencies

| Locations | SRS, ICD headers/history (changed 2026-11-16, date still 2026-10-23); EIC (revision history block at top **and** at end); SAD/PS (unchanged) |
|---|---|
| Category / Severity / Gate | Correction / S4 / Step 2 |

**Remark.** The SRS and ICD were edited (companion line) without date or change-history
update, and the EIC carries two identical revision-history tables. What is the rule for
edits within Revision 0.1: must the date and history row be updated on every
substantive change?

**Suggested solution.** Adopt the rule "any change to body text or companion list
updates the date and adds a one-line history entry within the same revision", keep a
single history table per document, and record the rule in the development guide.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-011 - Port and player scope conflict: four-port consoles versus "two players, two ports"

| Locations | EIC 2.1, 6.5-6.7, 6.10, 7; SRS-SYS-002/006/007, SRS-IN-005; ICD section 1 ("up to two simultaneously routed ports"); PS-PROFILE (ports 0,1) |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 3 |

**Remark.** The EIC sizes N64, GameCube, Dreamcast and Xbox adapters for **four** ports
(4/4/8 channels, 4 USB), while the SRS/ICD/PS limit routing to two players and port IDs
0-1. For a four-port console, which two physical ports are emulated, which connectors
are populated, and what do the other two ports present to the console (nothing connected,
or a neutral controller)? Is a four-port adapter a requirement, a future-proofing
margin, or an inconsistency? The aggregate table in EIC section 7 and the RP2350 budget
(RR-001-002) change materially depending on the answer.

**Suggested solution.** Decide "two emulated ports per adapter" (consistent with
SRS-SYS-007) and size the EIC for two ports, listing four-port support as Future (a
multitap/4-player extension, SAD-F-001); or, if four ports are wanted, make it a
class-C requirement and revisit SRS-SYS-002/007, PS limits and ICD wording together.
Define the mapping between PS `port` IDs and the console's physical ports.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-012 - The EIC is not traceable: no requirement IDs, classification or pass criteria

| Locations | EIC sections 3-9 (untagged `shall`), section 10 (`EIC-VER-001..014`); SRS section 8 |
|---|---|
| Category / Severity / Gate | Correction / S2 / Step 2 |

**Remark.** The EIC's `shall` statements have no IDs and no C/D/P classification, so they
cannot be traced; `EIC-VER-*` items have no acceptance values ("Verify 3.3 V input
compatibility" - against what threshold?) and are not linked to requirements or to the
SRS verification matrix. Is each EIC `shall` meant to be a confirmed requirement or a
provisional sizing assumption?

**Suggested solution.** Give each capability a stable ID (for example `EIC-CAP-001...`),
classify it C/D/P, map each `EIC-VER-*` to the IDs it verifies with numeric pass
criteria (thresholds, edge-rate, timing, current limits) and add an SRS-V row (or extend
SRS-V-006) that references them.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-013 - Terminology and stale wording

| Locations | SRS-SYS-007 ("input endpoints" undefined); SRS section 1 last sentence; SAD section 2 note; EIC ("PlayStation 1" vs SRS "PlayStation"; "analogue" vs "analog"); PS ("port", "player", "route") |
|---|---|
| Category / Severity / Gate | Correction / S4 / Step 2 |

**Remark.** "Active input endpoints" in SRS-SYS-007 is not defined anywhere (ports?
players? adapters?). Two sentences refer to a prior state of the repository ("No prior
engineering specifications existed...", "no previous four-document definitions") which
will be stale. Spelling and product naming vary across documents.

**Suggested solution.** Add a short glossary to the SRS (player, port, route, endpoint,
channel, node, adapter, owner), delete the historical sentences, and choose one spelling
variant and one name per console.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-014 - Source provenance of EIC electrical values

| Locations | EIC section 12 (references), sections 6 and 8 (values); ICD ICD-QUAL-001 (provenance rule) |
|---|---|
| Category / Severity / Gate | Correction / S3 / Step 4 |

**Remark.** Nine of ten EIC references are community wikis or pinout sites; no revision or
retrieval date is recorded, and values such as "approximately 3.5 V" or "approximately
3.43 V" are not attributed to a specific reference. ICD-QUAL-001 requires provenance with
revision. How will each electrical value be tied to a primary source (console hardware
documentation, datasheets of the original controller silicon, or a measurement)?

**Suggested solution.** Add per-value source columns (reference number, page/section,
retrieval date) and a "confidence" flag (published / secondary / measured); treat
secondary-only values as unverified until measured on an original console.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-015 - Verification-matrix gaps

| Locations | SRS section 8; SRS-SYS-003; SRS-V-003 ("counter wrap") versus PS ("no wrap") |
|---|---|
| Category / Severity / Gate | Correction / S3 / Step 2 |

**Remark.** SRS-SYS-003 ("no permanent modification to a target console") has no
verification method (it is listed under SRS-V-001 whose method does not test it).
SRS-V-003 tests "counter wrap" while the PS forbids wrap and defines exhaustion as a
fault; which behaviour is to be tested (exhaustion handling)? No verification row covers
PS-SVC-CONFIG or the EIC (RR-001-012).

**Suggested solution.** Add an inspection/H method for SRS-SYS-003 (connector-only
attachment, no soldering, reversible fixture), change "counter wrap" to "counter
exhaustion and rollover to a new session", and add a configuration case to SRS-V-005.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

---

### Theme C - Protocol coherence and timing

#### RR-001-016 - The 5 ms cycle has no slack for any non-input timeout

| Locations | PS-TIMING (response timeout 3 ms; worst-case timeout slot; "remaining capacity"); SAD-SCHED-001; SRS-PERF-002 |
|---|---|
| Category / Severity / Gate | Correction / S2 / Step 5 (protocol tests) |

**Remark.** The reviewer computed: a STATUS request is 28 wire bytes, so its timeout path
is `0.28 + 3.00 + 0.05 = 3.33 ms`; with a successful INPUT (1.70 ms) the cycle is 5.03 ms,
which exceeds the 5 ms cadence. A timed-out INPUT consumes 4.02 ms, leaving 0.98 ms, so no
retry fits before the next slot and a single lost INPUT effectively skips a cycle. The PS
text only shows the maximum-request case (5.25 ms). Is the 3 ms response timeout meant to
be a single global value? Since the latest response start is 250 us, an INPUT/ACK or
STATUS reply completes by about 0.7 ms, so most opcodes could use a much shorter timeout.

**Suggested solution.** Define a per-opcode response timeout = latest start + maximum
response wire time + margin (for example INPUT 1.0 ms, STATUS 1.0 ms, FEEDBACK_POLL
1.0 ms; larger only for management opcodes with large replies). Add a per-cycle budget
table (INPUT + FEEDBACK_POLL + one STATUS rotation: about 1.70 + 1.08 + 1.10 = 3.9 ms of
5 ms in the success case, and show which combinations of timeouts are admitted). State
that the scheduler never starts a non-input exchange whose timeout path exceeds the slack.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-017 - Latency requirement: 10 ms scope, loss behaviour, and no end-to-end target

| Locations | SRS-PERF-001/002, SRS-V-007; PS-TIMING; SRS-OWN-004 (no switch-time requirement) |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 3 |

**Remark.** SRS-PERF-001 bounds only hub-sample-to-installation (10 ms). With a 5 ms cadence
the worst success case is about 5 + 1.7 = 6.7 ms, but a single lost INPUT (RR-001-016) gives
about 10-12 ms, contradicting SRS-V-007 ("every sample... within 10 ms"). Also, no
requirement bounds the complete path (device poll + hub processing + bus + console poll)
or the ownership switch time. What end-to-end added latency is acceptable to the
owner (for example no more than one console frame of 16.7 ms, or lower for fight sticks),
and what is the allowed behaviour under a single bus error?

**Suggested solution.** Add class-P requirements: end-to-end added latency budget with
its components, 99.9th-percentile versus maximum rules, behaviour under one lost frame
(for example "newest sample of the next cycle, never a stale retry"), and a maximum
manual-switch time (for example 500 ms nominal).

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-018 - Is a 250 us latest response start realistic on a loaded adapter?

| Locations | PS-TIMING (earliest 50 us, latest 250 us, "adapters shall not start late replies"); PS-OWNERSHIP ("installation precedes OK"); SAD-SCHED-001 |
|---|---|
| Category / Severity / Gate | Question / S2 / Step 5 |

**Remark.** To answer an INPUT within 250 us of the request's last stop bit, the adapter
must finish receiving, COBS-decode, CRC-check (software CRC-32C of about 100 bytes),
validate generation/sequence/masks, map both players and atomically install before it
transmits the ACK - while PIO/DMA/interrupts serve one or two console ports, possibly
with a flash stall. A late reply is not sent, so the hub sees a timeout. Has this been
budgeted for each console profile, and what happens to lease and cadence if the
adapter must routinely miss the window?

**Suggested solution.** Obtain a measured processing budget on the chosen part under
worst-case console load; if too tight, either (a) widen the window per opcode (which
interacts with RR-001-016), or (b) allow the ACK to be sent after validation but before
the mapped install while keeping "installation completes before the next console-visible
read"; the choice must keep SRS-IN-008's atomicity.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-019 - Commissioning: contradictory retry rule and undefined transaction semantics

| Locations | PS-DISCOVERY (ASSIGN retry); PS-PROFILE (addresses 254/255); PS-TRANSACTION (session 0, ID rules) |
|---|---|
| Category / Severity / Gate | Correction / S2 / Step 5 |

**Remark.** PS-DISCOVERY says only an *unassigned* node with matching UID replies and
that the node applies the new address after its ACK leaves the UART, yet it also says
the node "retains the last ASSIGN request/reply until HELLO, permitting an exact retry
at destination 255 after a lost ACK". After the address was applied the node is no
longer unassigned, so which rule wins? Also commissioning uses session 0 and "normal
transaction IDs": in which ID space, given IDs are strictly increasing per session, and
how does a node de-duplicate DISCOVER/ASSIGN before it has any session?

**Suggested solution.** State that an assigned node that has not yet seen HELLO still
accepts an *exact* retry of the last ASSIGN at destination 255 (and nothing else at 255),
and define commissioning transactions as a separate ID counter owned by the hub that
nodes accept only if the (UID, boot_id, ID) matches the retained exchange.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-020 - Volatile addresses and physical commissioning enable after every adapter reset

| Locations | PS-DISCOVERY; SAD adapter states ("every adapter reboot requires commissioning again, including physical commissioning enable"); SAD-P-003 |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 3 |

**Remark.** If an adapter is powered from its console (ICD-PWR-002 option) or if a console
is power-cycled, each cycle needs a human to enable commissioning on that adapter. Is
this acceptable for the first prototype only, or a long-term operational requirement? It
also contradicts the spirit of SRS-OWN-010 (recovery after console reset needs only
"deliberate re-arming", not re-commissioning).

**Suggested solution.** Allow a node to persist its assigned address (or derive it from
a persisted roster slot) and have the hub confirm UID in HELLO; require physical
commissioning enable only for a first install, a UID mismatch or an address conflict.
If the volatile rule is retained, mark it explicitly as a prototype limitation with an
owner-approved exit criterion.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-021 - UART baud-rate tolerance and node clock accuracy are not specified

| Locations | ICD-NET-001 (1 Mbit/s); PS-TIMING ("monotonic clock error +/-1 %"); SRS-OWN-009 |
|---|---|
| Category / Severity / Gate | Question / S2 / Step 4 |

**Remark.** The +/-1 % figure covers the lease timer. A 1 Mbit/s UART between asynchronous
nodes needs a much tighter combined baud error (a few tenths of a percent at most, and
the divider granularity matters), and RS-485 distortion and driver enable/disable
timing add to it. What crystal/oscillator accuracy is required of every node, and is
the internal oscillator forbidden? (The achievable divider for the chosen RP2350 system
clock should be checked.)

**Suggested solution.** Add a class-D requirement: all nodes use a crystal-derived
clock with at most +/-100 ppm (value to be confirmed), and declare the permitted baud
error budget per node and the resulting sampling margin; keep the +/-1 % lease clock
bound as a separate, deliberately looser figure.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-022 - What does an inhibited adapter present to its console before ROUTES?

| Locations | SRS-OWN-002/003; SAD-MAP-001 ("peripheral identity changes require inhibition and possibly console reset"); PS-OWNERSHIP (ROUTES selects `peripheral_id`) |
|---|---|
| Category / Severity / Gate | Question / S2 / Step 3 |

**Remark.** Non-owner adapters keep answering their consoles with neutral controls. But
the peripheral type is only chosen by ROUTES. Which identity (controller type, accessory
presence) is presented while INHIBITED or CONFIGURED, and what happens when ARM
changes it (hot-plug event, console reset)? Consoles such as the N64 and PS2 detect the
controller type at boot or on connection; changing it live may confuse games.

**Suggested solution.** Require every profile to declare a default idle identity, and
state in the profile whether peripheral changes are allowed live; prefer a design in
which the identity does not change at ARM (the route selects mapping, not identity).

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-023 - The 1 ms neutralisation bound must be validated per console, including USB consoles

| Locations | PS-TIMING (local neutralisation 1 ms); SAD-OWN-001 (REVOKE note); SRS-OWN-009 |
|---|---|
| Category / Severity / Gate | Question / **S1** / each console profile (before enabling ownership transfer) |

**Remark.** The 103 ms bound and 2 ms drain guard rest on a console completing any
in-flight transaction within 1 ms of REVOKE. For USB (Xbox) the host polls an interrupt
endpoint every few milliseconds and a report may already be queued in the controller;
for Dreamcast/PS2 a transaction may be longer than expected; for SNES/NES a latched
shift register delivers 16 bits over about 200 us. Is neutral state guaranteed
*visible to the console* within 1 ms for each target console, or only installed in
local state?

**Suggested solution.** Make the bound profile-declared (a CAPS field, for example
`neutralisation_bound_us`), compute the hub drain and lease guards from the maximum over
enrolled adapters, and fail profile approval if a console cannot meet the global bound.
Add per-console measurement points to ICD-CON-001.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-024 - Incomplete or inconsistent definitions in PS lifecycle and status

| Locations | PS-STATUS state table; SAD adapter states (RESET, UNASSIGNED); PS STATUS counters versus DIAGNOSTICS counters; PS-DISCOVERY |
|---|---|
| Category / Severity / Gate | Correction / S3 / Step 5 |

**Remark.** The adapter state machine has UNASSIGNED but the STATUS `state` enum
(0-5) does not, so there is no defined reply for a node that has not yet been assigned
an address; STATUS `rx_errors` is not mapped to DIAGNOSTICS counters 0-3; `timeouts`
actually counts lease expiries and the name conflicts with the hub's request timeouts;
fault code 5 ("address/provisioning") has no defined trigger; the CAPS list is stated
immutable per boot but the maximum CAPS list length is not bounded.

**Suggested solution.** Add UNASSIGNED to the lifecycle table as "not addressable by
STATUS", define `rx_errors` as the sum of counters 0-3 (or remove), rename `timeouts` to
`lease_expiries`, define fault-5 triggers, and bound the CAPS index range.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-025 - Feedback model coverage and polling cadence

| Locations | PS-SVC-FEEDBACK; SAD-FB-001; SRS-OWN-011; PS-TIMING |
|---|---|
| Category / Severity / Gate | Question / S3 / Step 3 |

**Remark.** Feedback is two-motor rumble plus a four-position player indicator, with a
100 ms maximum duration needing refresh. Consoles differ: GameCube and N64 have a single
on/off motor, PlayStation has a small on/off and a large variable motor, Dreamcast
rumble packs and Xbox have two motors. Where is mapping to the physical device done? And
FEEDBACK_POLL has no required cadence: continuous rumble means an event at least every
100 ms per route, and low polling cadence adds perceived delay. What is the polling
cadence and the bus time reserved for it?

**Suggested solution.** Specify FEEDBACK_POLL cadence (for example every 10 ms while
armed, interleaved in the cycle budget of RR-001-016) and state that the adapter reports
the console's native effect richness while the hub reduces to the physical device.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

---

### Theme D - Console input and peripheral coverage

#### RR-001-026 - Is the generic input model sufficient for the target controllers?

| Locations | PS-DATA-INPUT (16 buttons, 8 axes); SRS-IN-001/002/003; SAD-MAP-001; ICD section 5 (pressure, analog modes) |
|---|---|
| Category / Severity / Gate | Question / S2 / Step 3 |

**Remark.** The button set has D-pad, four face buttons, two shoulders, two stick clicks,
two menu and two auxiliary positions, with triggers only as analog axes. Cases that are
not clearly representable (to verify against each console's controller documentation):
(a) PlayStation L2/R2 as *digital* buttons and the common eight-button fight stick
layout (four face plus L1/R1/L2/R2), (b) the N64 C-buttons (four) and Z trigger,
(c) Saturn six face buttons plus L/R, (d) Original Xbox analog face buttons plus Black/
White and DualShock 2 pressure-sensitive buttons, (e) GameCube analog L/R plus
digital click and C-stick, (f) Mega Drive six-button plus Mode/Start. The text says
"explicit normalisation policy" for digital trigger positions, but there is no table.
Which of these are required in the first profiles?

**Suggested solution.** Add an informative controller-coverage matrix (generic position
-> console element for each profile and each controller mode) and a list of generic
positions that must be added (for example digital L2/R2) before the PS input schema is
frozen; mark pressure-sensitive buttons Future or reserve their encoding now, since the
wire format is hard to extend.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-027 - Accepted USB input device classes are not defined

| Locations | SRS-IN-003; SAD-COMP-HUB (device backend); DEVELOPMENT-GUIDE Step 3 ("preferably wired USB") |
|---|---|
| Category / Severity / Gate | Question / S2 / Step 3 |

**Remark.** Gamepads and fight sticks are "initial device classes", but which USB
protocols must the hub parse: generic HID, the Xbox 360/One class protocol, PlayStation
4/5 controllers (some modes require authentication), Nintendo Switch controllers? Many
fight sticks use console-specific protocols or authentication, which a host without
the correct credentials cannot use. What is the minimum supported list for the first
prototype and the pass criterion?

**Suggested solution.** Name two or three concrete first devices (and their USB class
and descriptor), state HID-only for the first increment, and list other protocols as
Future with the credential/authentication caveat.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

---

### Theme E - Electrical interfaces

#### RR-001-028 - One universal "any mode, 3.3 V or 5 V" channel versus per-console safety

| Locations | EIC 4.1-4.3, 5.1-5.3, 9 (item 7), 11; ICD-CON-001 (per-profile electrical); SRS-HW-002 |
|---|---|
| Category / Severity / Gate | Decision / **S1** / Step 4 |

**Remark.** The EIC requires that *every* channel can be input, 3.3 V push-pull, 5 V
push-pull, open-drain or high-Z, independently selectable. Several consoles (N64,
GameCube, Dreamcast, PlayStation) are 3.3 V-class with console-side pull-ups on
open-drain lines. Is runtime (firmware) selectability of 5 V push-pull on such a line
acceptable? A firmware defect or wrong profile could drive 5 V into a 3.3 V console or
create double pull-ups. This also contradicts the ICD's per-profile "drive mode and
contention prevention".

**Suggested solution.** Make the voltage domain and drive type a **hardware-defined
property of each console connector module** (strap or module ID readable by firmware,
which refuses incompatible profiles), keep high-Z as the only state reachable without
a valid module/profile match, and restate EIC 4.1-4.3 as "the platform shall provide
the capabilities across modules" rather than "every channel shall do everything".

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-029 - Saturn (and Mega Drive) signal directions and the 3D Control Pad

| Locations | EIC 6.3 (Mega Drive), 6.4 (Saturn), 7 (channel counts) |
|---|---|
| Category / Severity / Gate | Correction + Question / S2 / Saturn and Mega Drive profiles |

**Remark.** (To verify against EIC references 3 and 4.) EIC 6.4 lists TH and TR as inputs
and D0-D3 as outputs and treats TL as "an appropriate static electrical bias", while also
requiring the 3D Control Pad. As the reviewer understands the Saturn interface, the
3D/analog pad uses a handshake in which a pad-driven line (TL) acknowledges console
requests (TR); a static bias would only be adequate for the digital pad. If so, Saturn
needs at least five outputs and two inputs per port (seven channels, not six) and the
12-channel aggregate changes. Similarly, some Mega Drive peripherals drive TH/TR/TL as
outputs from the console side (mouse, handshake modes). Is only the plain digital pad
required? What does "mandatory six-button" imply for TH timing (the six-button pad
counts TH pulses and resets after an idle time)?

**Suggested solution.** Verify signal directions against the primary Saturn and Mega Drive
documentation; either (a) restrict Saturn scope to the digital pad and remove the 3D pad
claim, or (b) correct the channel table (TL as output) and recompute sections 6.4 and 7.
Add the Mega Drive idle-timeout and TH-edge timing to the profile's measurement list.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-030 - Signals needed by other requirements are missing from the channel counts

| Locations | EIC 5.4, 6, 7; SRS-OWN-008; ICD-PWR-002 (item 6); PS-DISCOVERY (physical commissioning enable); ICD-DBG-001 |
|---|---|
| Category / Severity / Gate | Correction / S2 / Step 4 |

**Remark.** EIC "channels" cover controller data lines only. Not counted: console power
sense / activity detection (SRS-OWN-008 requires activity or `UNKNOWN`), Dreamcast and
other presence/sense pins, the commissioning-enable input, status LEDs, the recovery/
boot-select input and the direction/enable lines of the RS-485 transceiver. Is the
EIC's channel table intended to be the complete GPIO budget for the adapter?

**Suggested solution.** Add an "adapter system I/O" table (power-sense per port,
presence, commissioning enable, recovery, LEDs, bus UART/direction) and a total GPIO
budget per console, to be compared with the RP2350 variant chosen (RR-001-002).

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-031 - No dynamic requirements: bit rates, edge rates, delay, skew, capacitance

| Locations | EIC 4.1-4.3, 4.6, 5, 10 ("defined input thresholds", "protection shall not compromise timing") |
|---|---|
| Category / Severity / Gate | Question / S2 / Step 4 |

**Remark.** The EIC states no numeric limits. Needed values per console include the
signalling rate (for example N64/GameCube about 4 us per bit with fast edges on an
open-drain line, Maple at a multi-megabit rate, PS1/PS2 a few hundred kHz, SNES/NES
tens of kHz), maximum rise/fall time, maximum added propagation delay, skew between
related lines, input capacitance, and protection capacitance. These decide which
translator class is usable: auto-direction translators are generally unsuitable on
open-drain bidirectional lines and ESD diodes can slow edges. What are the target
numbers, and where will the measurements be recorded?

**Suggested solution.** Add per-console columns for nominal rate, tolerance, VIH/VIL
and VOH/VOL required at the console, maximum added delay and capacitive budget; make
EIC-VER-003..008 reference those numbers.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-032 - Dreamcast: bidirectional "Digital" mode is undefined; presence detection not budgeted

| Locations | EIC 6.7; ICD section 5 (Dreamcast row) |
|---|---|
| Category / Severity / Gate | Question / S2 / Dreamcast profile |

**Remark.** EIC 6.7 lists SDCKA/SDCKB as bidirectional "Digital" without drive type
(push-pull, open-drain, or console-biased) and defers presence detection to the profile
while the channel count excludes it. Is the line driven push-pull at 3.3 V, and what
pull-up arrangement does the console provide? Does the port have a sense/presence pin or
other function beyond the two data lines?

**Suggested solution.** Fill in drive type, levels and the presence/sense line from the
primary Maple documentation, and add the missing line(s) to the channel count.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-033 - Connector voltages, pull-up ownership and the "3.3 V / 5 V" assumption

| Locations | EIC 4.1 (configurable pull-ups), 8 (power table), 9; ICD-PWR-002 |
|---|---|
| Category / Severity / Gate | Question / **S1** / Step 4 |

**Remark.** The EIC power table lists PlayStation logic as "approximately 3.5 V" and
GameCube as "5 V and approximately 3.43 V", which are neither of the two logic domains
the channel capability promises (3.3 V or 5 V). Who supplies the pull-ups on each
open-drain line (console or controller), and may the adapter add pull-ups on lines where
the console already has them? What is the allowed high level when the console rail is
above 3.3 V and the adapter MCU is at 3.3 V (an input at 3.5 V may exceed the MCU's
allowed pad voltage depending on its supply)?

**Suggested solution.** For each console and signal give the voltage range (min/typ/
max), pull-up location and value, and the translator or clamp approach; add a rule
"adapter adds no pull-up on a line that the console already pulls up" and require
measurements on at least one console of each family before approval.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-034 - Power source and grounding/isolation decision must precede any multi-console connection

| Locations | ICD-PWR-002, SAD-O-002; EIC 4.5, 8, 9; SRS-HW-003 |
|---|---|
| Category / Severity / Gate | Decision / **S1** / Step 4 (multi-console) |

**Remark.** Open: whether each adapter (a) senses console power only, (b) draws from the
console through protection, or (c) is externally powered; and whether the shared RS-485
bus is galvanically isolated. EIC 4.5 forbids connecting console rails "directly to the
internal 3.3 V logic supply", which differs from ICD-PWR-002's allowance of a
console-derived protected supply. Multiple grounded consoles bridged by video cables
and one bus form ground loops; the N64 and GameCube ports supply very little current.

**Suggested solution.** Recommended default: external adapter power with sense-only
console power, plus an isolated bus interface (isolated RS-485 transceiver and isolated
power) at every adapter, with isolation-delay included in PS-TIMING margins. Resolve as
a decision (SAD-O-002) before any bench setup beyond a single console, and harmonise
the wording of EIC 4.5 and ICD-PWR-002 ("not directly connected" versus "protected
derived supply").

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-035 - No electrical capability specification for the hub

| Locations | EIC (adapter-only); ICD-USB-001, ICD-PWR-001; SAD-O-003 |
|---|---|
| Category / Severity / Gate | Correction / S2 / Step 4 |

**Remark.** The EIC defines the adapter envelope; the hub (USB host ports, VBUS
switching and current, bus transceiver, local power, indicators) has only narrative text
in the ICD and no numbers. How many USB ports and what VBUS current does the hub provide
for devices such as fight sticks and wheels, and what is its power input?

**Suggested solution.** Either extend the EIC to a hub section or add a hub baseline
table to the ICD (ports, current per port, protection, supply input, transceiver,
indicator and button I/O).

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-036 - Installation constraints: maximum bus length, number of consoles, topology

| Locations | SRS-SYS-007 (31 addresses); ICD-NET-001/002 ("cable length open") |
|---|---|
| Category / Severity / Gate | Decision / S3 / Step 4 |

**Remark.** The 31-address limit is an address bound, not an installation requirement.
What is the intended deployment (a few consoles in one room, tens of metres, a
multi-room setup)? The harness, termination, bias and the isolation decision (RR-001-034)
all depend on it.

**Suggested solution.** Add a class-P requirement for typical and maximum number of
adapters and cable length (for example up to 10 adapters, up to 15 m trunk) and use it
for the first harness calculation.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

---

### Theme F - Completeness and process

#### RR-001-037 - Requirement classes absent from the SRS

| Locations | SRS sections 2-7; SAD-COMP-HUB ("Diagnostics/UI") |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 3 |

**Remark.** Not covered: how the user selects the console owner or assigns players (what
hardware UI exists?), where hub configuration and roster persist, status indicators and
local fault display, EMC/ESD/regulatory and electrical safety standards, operating
environment, cost/size/enclosure constraints, supportability (logs, field diagnostics),
and licensing of any console-derived code. Which of these are in scope for the first
prototype?

**Suggested solution.** Add an SRS section "User interaction and operations" with
minimum UI (for example physical selector plus indicator for the first prototype) and a
section for environmental/compliance constraints classed O or F where undecided.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-038 - First console and controller mode not yet chosen, while the EIC sizes all ten

| Locations | SAD-O-001; DEVELOPMENT-GUIDE Step 3 and "one active milestone"; EIC section 2.1 |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 3 |

**Remark.** The EIC establishes the full console envelope while SAD-O-001 (first console,
variants, virtual peripherals) remains open. Which console and controller mode should
the first two-player prototype target, and does its resource profile reveal anything the
envelope hides?

**Suggested solution.** Compare two or three candidates (for example SNES, PlayStation 2,
Mega Drive) by electrical simplicity, timing difficulty and resource load on the chosen
RP2350, then select one. Keep the EIC as the long-term envelope; do not let it drive
first-prototype scope.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-039 - Development guide alignment

| Locations | DEVELOPMENT-GUIDE (intro, Step 1 reading order and hand-off prompt, Step 7, rules) |
|---|---|
| Category / Severity / Gate | Correction / S3 / Step 2 |

**Remark.** Besides the EIC omission (RR-001-008), the guide has no step for a formal
review and no place for review artifacts; Step 1 asks the owner to review but does not
say how remarks are recorded. Should the review process become Step 1b, with its output
feeding Step 2?

**Suggested solution.** Reference [RPN-RVP](../REVIEW-PROCESS.md) in Steps 1 and 2 and
in Step 7, and add "review record" to the session-close checklist.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

#### RR-001-040 - Discoverability of review documents

| Locations | README document table |
|---|---|
| Category / Severity / Gate | Correction / S3 / Step 2 |

**Remark.** The README does not list the process document or review records. Should
they appear under a separate "Process documents" heading, distinct from the engineering
specifications?

**Suggested solution.** Add a "Process and review" table (development guide, review
process, latest review record) to the README, kept separate from the specification table.

**Owner response:** _(pending)_  **Resolution:** _(next cycle)_

---

## 5. Disposition table (to be completed by the owner and then the corrector)

| ID | Owner decision (Accept / Modify / Reject / Defer) | Resolution reference | Status |
|---|---|---|---|
| RR-001-001 .. RR-001-040 | _pending_ | _pending_ | Open |

## 6. Gates carried forward

| Gate | Blocked until |
|---|---|
| Step 2 reconciliation complete | S2 remarks of themes A, B and F answered |
| Step 3 prototype scope | RR-001-011, -017, -022, -026, -027, -037, -038 answered |
| Step 4 any hardware connection | All S1 remarks closed: RR-001-003, -023, -028, -033, -034 |
| Step 5 protocol tests | RR-001-016, -018, -019, -021, -024 closed |
