# Review record REVIEW-001

| Field | Value |
|---|---|
| Date | 2026-11-17 |
| Reviewer | System requirements reviewer (AI assistant) |
| Process | [RPN-RVP](../REVIEW-PROCESS.md) revision 0.1 |
| Reviewed commit | `8a5062f` |
| Documents reviewed | [README](../../README.md); [SRS](../SRS.md), [ICD](../ICD.md), [SAD](../SAD.md), [PS](../PS.md) (all Rev 0.1, 2026-10-23); [DEVELOPMENT-GUIDE](../DEVELOPMENT-GUIDE.md) |
| Phases performed | 1-9 of the process. Phase 6/7/8 console and silicon facts are from the reviewer's general knowledge plus the documents' own references; **no primary datasheet or console manual was consulted**, so every such statement below is marked "verify" and is a question, not a finding of fact. |
| Status of this record | Owner responses received (37 remarks accepted; 3 withdrawn, see section 2). Correction cycle applied on 2026-11-18 by the corrector; closure awaits the re-review (RPN-RVP section 9). The reviewed documents at commit `8a5062f` were not modified by the review itself; they were modified by the correction cycle (see section 5). |

## 1. Owner constraints for this cycle

| ID | Constraint | Applies? |
|---|---|---|
| OC-1 | The design standardises on the **RP2350 MCU family**. | **Yes** - conflicts with several documents; see RR-001-001..007. |

## 2. Summary

40 remarks, of which 3 (RR-001-008, RR-001-009 and RR-001-012) were withdrawn on
2026-11-25 because their subject was removed from the repository. Priority order
for the owner: all **S1** remarks first (hardware safety and safety-invariant
items; they block Step 4 of the development guide), then **S2**.

| Severity | Count |
|---|---:|
| S1 Blocker | 5 |
| S2 Major | 21 |
| S3 Minor | 9 |
| S4 Editorial | 2 |
| Withdrawn (all were S2) | 3 |

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
decision, (2) the electrical capability claims are universal and per-channel, which
conflicts with per-console reality and with the "two ports, two players" scope,
(3) the 5 ms cadence has no slack for any non-input timeout, and (4) several
console-facing electrical facts need primary-source verification before any
original hardware is connected.

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
| Console channel arithmetic | All per-port and aggregate counts and the 14-channel maximum are arithmetically correct (their content is questioned in section 4, theme E) |
| Cross-document ID references | Every `SRS-V-*` design reference (`PS-*`, `SAD-*`, `ICD-*`) resolves to a defined element |

## 4. Remarks

Each remark records the owner's response and the corrector's resolution. Severity and category
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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. New class-C `SRS-HW-005` (RP2350 family for hub and every adapter processor); `SRS-HW-001` retired, row kept; `SAD-D-004` with the exception procedure (evidence, owner approval, register entry); `SAD-R-008` and `SAD-O-003` reduced; RP2040 statements replaced in ICD-PWR-001, ICD section 6 and PS-DISCOVERY. The replacement statements are not yet checked against the datasheet (see `ICD-PLAT-001`).

#### RR-001-002 - Which RP2350 variant, core architecture and resource budget?

| Locations | SRS-HW-001/004; SAD-O-004; ICD-CON-001 "Resources"; console channel sizing (ICD section 8.2) |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 4 |

**Remark.** "RP2350 family" spans package/pin-count variants (a smaller-GPIO and a
larger-GPIO variant, and variants with stacked flash), and Arm and RISC-V cores.
Which are acceptable? The console resource sizing needs a per-console GPIO / PIO state
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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. `SAD-P-007` (Arm cores; RP2350A default; RP2350B only where a profile's resource table shows the need). Resource-table field and the 70 % margin rule added to ICD-CON-001. First GPIO budget (`ICD-CAP-014`, ICD section 8.3): Mega Drive and Saturn need 23 GPIO, above 21 (70 % of 30), so they imply RP2350B. PIO/DMA/interrupt/RAM figures remain per-profile work (`SAD-O-004`); part facts need the datasheet check.

#### RR-001-003 - RP2350 errata and 5 V tolerance versus the universal channel capability

| Locations | Universal channel capability (ICD-CAP-003..006); SRS-HW-002; ICD-NET-001 ("GPIO pull states alone are insufficient") |
|---|---|
| Category / Severity / Gate | Question / **S1** / Step 4 (before any console connection) |

**Remark.** (To verify.) The RP2350 datasheet specifies conditions under which GPIO are
5 V tolerant (for example only while the I/O supply is powered and at a stated level),
and the family has published errata relating to GPIO input pad leakage / pull-down
behaviour on some silicon steppings that can affect high-impedance and open-drain
designs. The channel capability requires "5 V input tolerance", high-Z and configurable pull-up/down
on every channel. Which silicon stepping is targeted, which errata affect these
interfaces, and does the design depend on MCU-side 5 V tolerance, pull-ups or pull-downs
or only on external translators?

**Suggested solution.** Add a "platform datasheet and errata register" (document
revision, stepping, errata ID, affected interface, mitigation) to the ICD, require that
no console-facing signal relies on internal pulls or MCU 5 V tolerance, and add a
verification entry for unpowered-MCU / powered-console behaviour of each channel.

**Owner response:** Accept - "Don't rely on the chosen MCU 5V capabilities. Rely only on external translators when applicable."
**Resolution (2026-11-18):** Applied. `SRS-HW-006` (no console-facing signal relies on MCU 5 V tolerance or internal pulls), `ICD-CAP-003`, `SAD-D-006`; `ICD-PLAT-001` datasheet/errata register created (unpopulated: the datasheet and errata have not been consulted, so no errata are recorded); `ICD-VER-015` (unpowered MCU with powered console); ICD-NET-001 states that internal pulls are not relied on. The register must be populated before Step 4.

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

**Owner response:** Accept - the RP2350 family has a single USB 1.1 interface; a USB hub IC provides the two player devices.
**Resolution (2026-11-18):** Applied. `SAD-P-009`; ICD-PWR-001 rewritten (native host behind a hub IC, no PIO USB host, diagnostics over UART/debug); `ICD-HUB-001` baseline; pass criterion for "two devices" in `ICD-VER-018` (one low-speed and one full-speed HID device, 10 minutes, no missed report) and `ICD-VER-019` (VBUS limiting); `SAD-O-003` reduced to device list and radio. First prototype: wired USB only.

#### RR-001-005 - Original Xbox adapter: four USB device ports versus RP2350 USB resources and the two-player scope

| Locations | Xbox capability (ICD-CAP-011); SRS-SYS-006; SAD-R-001; ICD-CON-001 (Xbox row) |
|---|---|
| Category / Severity / Gate | Decision / S2 / Xbox profile (not the first prototype) |

**Remark.** The Xbox capability requires four independent USB full-speed **device** interfaces and says
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

**Owner response:** Accept - option A: two USB device ports; the other two console ports are left unconnected.
**Resolution (2026-11-18):** Applied. `SRS-SYS-009`, `SAD-P-008`, new `SAD-ADAPT-001` (one gateway processor owns the RS-485 node and the lease; internal UART/SPI link; secondary processors apply a local deadline), `SAD-R-001` updated, `ICD-CAP-011`, Xbox row and Port-mapping field in ICD-CON-001. Which processor is the gateway and the internal link timing are left to the Xbox supplement.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. `SAD-P-003`; PS-DISCOVERY: 128-bit vendor-defined UID in locked OTP, printed on a label, 64-bit chip ID alone not accepted; PS-TRANSACTION: 64-bit session from the hardware RNG with a health check and a persistent-counter fallback. Added (not in the suggestion, to honour RR-001-007's rule against accidental irreversible programming): prototype boards may use a documented non-OTP UID, marked as prototype. OTP and RNG facts still need the datasheet check.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. Update marked Future for the first prototype: `SRS-UPD-004` (F), `SAD-F-004`, `SAD-O-008` note, SAD section 8 and PS-SVC-UPDATE reworded; the future update-profile supplement must carry a prototype/production OTP distinction. Deferred item has owner (project owner), gate "before any node advertises Update" and register entry `SAD-F-004`.

---

### Theme B - Consistency and document control

#### RR-001-008 - Withdrawn

Withdrawn on 2026-11-25 (owner decision): the subject of this remark was removed
from the repository. The identifier is not reused.

**Rule retained for the remarks that refer to this one** (RR-001-011 and
RR-001-028 to RR-001-035): useful content is used where it is consistent with the
system intent, and where it conflicts, the existing documentation takes
precedence.

#### RR-001-009 - Withdrawn

Withdrawn on 2026-11-25 (owner decision): the subject of this remark was removed
from the repository. The identifier is not reused.

#### RR-001-010 - Document control inconsistencies

| Locations | SRS, ICD headers/history (changed 2026-11-16, date still 2026-10-23); SAD/PS (unchanged) |
|---|---|
| Category / Severity / Gate | Correction / S4 / Step 2 |

**Remark.** The SRS and ICD were edited (companion line) without date or change-history
update. What is the rule for edits within Revision 0.1: must the date and history row
be updated on every substantive change?

**Suggested solution.** Adopt the rule "any change to body text or companion list
updates the date and adds a one-line history entry within the same revision", keep a
single history table per document, and record the rule in the development guide.

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. Date and a dated history row updated in SRS, ICD, SAD, PS; the rule is recorded as rule 8 of the development guide.

#### RR-001-011 - Port and player scope conflict: four-port consoles versus "two players, two ports"

| Locations | Console channel sizing (ICD section 8.2); SRS-SYS-002/006/007, SRS-IN-005; ICD section 1 ("up to two simultaneously routed ports"); PS-PROFILE (ports 0,1) |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 3 |

**Remark.** The console capability sizing covers N64, GameCube, Dreamcast and Xbox adapters for **four** ports
(4/4/8 channels, 4 USB), while the SRS/ICD/PS limit routing to two players and port IDs
0-1. For a four-port console, which two physical ports are emulated, which connectors
are populated, and what do the other two ports present to the console (nothing connected,
or a neutral controller)? Is a four-port adapter a requirement, a future-proofing
margin, or an inconsistency? The aggregate resource table and the RP2350 budget
(RR-001-002) change materially depending on the answer.

**Suggested solution.** Decide "two emulated ports per adapter" (consistent with
SRS-SYS-007) and size the capability baseline for two ports, listing four-port support as Future (a
multitap/4-player extension, SAD-F-001); or, if four ports are wanted, make it a
class-C requirement and revisit SRS-SYS-002/007, PS limits and ICD wording together.
Define the mapping between PS `port` IDs and the console's physical ports.

**Owner response:** Accept - see RR-001-008 (existing documentation takes precedence).
**Resolution (2026-11-18):** Applied with the existing scope of two ports. `SRS-SYS-009` (an adapter emulates at most the two routable ports; other ports unpopulated, the console sees no controller), `SAD-P-008`, four-port/multitap support added to `SAD-F-001` (Future); ICD section 8.2 sizes N64, GameCube, Dreamcast and Xbox for two ports; "Port mapping" field added to ICD-CON-001 (PS port ID to physical connector).

#### RR-001-012 - Withdrawn

Withdrawn on 2026-11-25 (owner decision): the subject of this remark was removed
from the repository. The identifier is not reused.

#### RR-001-013 - Terminology and stale wording

| Locations | SRS-SYS-007 ("input endpoints" undefined); SRS section 1 last sentence; SAD section 2 note; console naming and spelling ("PlayStation 1" vs SRS "PlayStation"; "analogue" vs "analog"); PS ("port", "player", "route") |
|---|---|
| Category / Severity / Gate | Correction / S4 / Step 2 |

**Remark.** "Active input endpoints" in SRS-SYS-007 is not defined anywhere (ports?
players? adapters?). Two sentences refer to a prior state of the repository ("No prior
engineering specifications existed...", "no previous four-document definitions") which
will be stale. Spelling and product naming vary across documents.

**Suggested solution.** Add a short glossary to the SRS (player, port, route, endpoint,
channel, node, adapter, owner), delete the historical sentences, and choose one spelling
variant and one name per console.

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. Glossary added to SRS section 1 (hub, adapter, node, console port, port, player, route, endpoint, channel, owner, profile); "input endpoints" in `SRS-SYS-007` replaced by routes (endpoints); the historical sentences removed from SRS section 1 and SAD section 2; one name per console (SRS-SYS-004 now "Original Xbox") and "analog" as the single spelling of that term.

#### RR-001-014 - Source provenance of console electrical values

| Locations | ICD-REF-001 (references), ICD sections 8.2 and 8.5 (values); ICD ICD-QUAL-001 (provenance rule) |
|---|---|
| Category / Severity / Gate | Correction / S3 / Step 4 |

**Remark.** Nine of ten references are community wikis or pinout sites; no revision or
retrieval date is recorded, and values such as "approximately 3.5 V" or "approximately
3.43 V" are not attributed to a specific reference. ICD-QUAL-001 requires provenance with
revision. How will each electrical value be tied to a primary source (console hardware
documentation, datasheets of the original controller silicon, or a measurement)?

**Suggested solution.** Add per-value source columns (reference number, page/section,
retrieval date) and a "confidence" flag (published / secondary / measured); treat
secondary-only values as unverified until measured on an original console.

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied as far as the evidence allows. `ICD-REF-001` source register (ten sources, type, confidence); values in ICD sections 8.2 to 8.5 are flagged secondary/unverified and `ICD-CAP-016` treats them as leads until measured. Revision and retrieval dates were never recorded and cannot be reconstructed, so they read "not recorded" and must be filled in when the sources are consulted.

#### RR-001-015 - Verification-matrix gaps

| Locations | SRS section 8; SRS-SYS-003; SRS-V-003 ("counter wrap") versus PS ("no wrap") |
|---|---|
| Category / Severity / Gate | Correction / S3 / Step 2 |

**Remark.** SRS-SYS-003 ("no permanent modification to a target console") has no
verification method (it is listed under SRS-V-001 whose method does not test it).
SRS-V-003 tests "counter wrap" while the PS forbids wrap and defines exhaustion as a
fault; which behaviour is to be tested (exhaustion handling)? No verification row covers
PS-SVC-CONFIG or the electrical capability entries.

**Suggested solution.** Add an inspection/H method for SRS-SYS-003 (connector-only
attachment, no soldering, reversible fixture), change "counter wrap" to "counter
exhaustion and rollover to a new session", and add a configuration case to SRS-V-005.

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. New `SRS-V-009` (inspection/hardware method for `SRS-SYS-003`; removed from V-001's range), `SRS-V-003` now tests counter exhaustion and rollover to a new session, `SRS-V-005` adds the configuration cases and `PS-SVC-CONFIG`, ICD verification entries reached through `SRS-V-006`, and `SRS-V-010` for the new UI/persistence requirements.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied and recomputed (script in RPN-RVP Appendix B style, results in PS-TIMING). Per-opcode response timeout classes (short 1.0 ms; long 3.0 ms for STORAGE READ only); cycle budget table: INPUT 1.70/2.02 ms, FEEDBACK_POLL 1.08/1.37 ms, STATUS 1.10/1.33 ms (success/timeout path); all of INPUT + FEEDBACK_POLL + STATUS timing out is 4.72 ms, inside 5 ms; admission rule (non-input exchange only if its timeout path ends before the next INPUT slot) in PS-TIMING and SAD-SCHED-001; `SAD-P-004` updated.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied with proposed (class P) values the owner should confirm: `SRS-PERF-004` end-to-end added latency 16.7 ms at the 99.9th percentile with a component budget; `SRS-PERF-005` one lost INPUT installed within 12 ms with no stale retry (recomputed: 6.22 ms normal worst case, 11.22 ms with one loss); `SRS-OWN-012` manual switch 500 ms nominal; `SRS-PERF-001` clarified as the normal (no link error) profile; `SRS-V-003`/`SRS-V-007` extended. A tighter fight-stick target is left open in `SAD-O-007`.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Recorded as a gate; the measurement itself cannot be done in a document cycle. `SAD-O-009` requires a measured processing budget on the chosen part before protocol tests and fixes the fallback order: first widen the per-opcode window (the timeout formula in PS-TIMING already contains the latest-start term), or, only with owner approval, acknowledge after validation but before installation while keeping SRS-IN-008 atomicity. PS-TIMING marks 250 us as provisional.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied in PS-DISCOVERY: an assigned node that has not seen HELLO accepts only an exact retry of the retained ASSIGN at destination 255; commissioning uses a separate hub-owned commissioning counter and nodes de-duplicate on (UID, boot_id, transaction ID); PS-TRANSACTION states that its ID rules apply to sessions 1 and above.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. The adapter persists its assigned address after the ASSIGN reply; a reset returns it to INHIBITED at that address and the hub confirms the UID in HELLO (UID mismatch answers NOT_FOUND); physical commissioning enable is required only for a first install, UID mismatch or address conflict and clears the persisted address. Changed in SAD adapter states, `SAD-P-003`, `SAD-O-005`, PS-DISCOVERY, PS-MSG, PS-MAINTENANCE RESET and the PS test list. A node without a safe store keeps the old volatile behaviour as a stated prototype limitation.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. Class-D `SRS-NET-010` (crystal-derived clock, at most +/-100 ppm, no internal RC oscillator for the bus baud rate); ICD-NET-001 "Clock and baud error" row with a proposed +/-0.5 % per-node budget and the requirement to compute the RP2350 divider and sampling margin; `ICD-VER-017`. The +/-1 % lease-clock bound stays separate. The two figures are marked "to be confirmed"; the divider calculation needs the chosen system clock.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. `SRS-IN-011`, `SAD-D-007`, SAD-MAP-001 (the route selects mapping, not identity), PS ROUTES (INCOMPATIBLE if the identity would change unless the profile allows it), and an "Idle identity" field in ICD-CON-001.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Specification applied; S1 gate stays open per profile until measured. `SRS-OWN-013`, `SAD-D-008`, new CAPS kind 4 `neutralisation_bound_us` (PS), guards derived from the maximum over enrolled adapters (drain guard `max(2 ms, 2 x B)`, 110 ms valid up to about 7.8 ms and conforming only up to 1 ms), SAD-OWN-001 text, a "Neutralisation" field and per-console measurement points in ICD-CON-001 (including the already-queued USB report and the 16-bit shift register read), and `ICD-VER-016`. A profile that cannot meet 1 ms fails approval.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied in PS STATUS/CAPS and SAD adapter states: UNASSIGNED documented as not addressable by STATUS; `rx_errors` defined as the sum of DIAGNOSTICS counters 0..3; `timeouts` renamed `lease_expiries` (counter 11); fault 5 triggers defined (missing/invalid UID provisioning, invalid persisted address record, commissioning enable asserted while armed); CAPS lists bounded to 64 entries (index 64 or more and unknown kinds give BAD_VALUE).

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. FEEDBACK_POLL to the owner every 10 ms while armed, budgeted in the PS-TIMING cycle table; PS-SVC-FEEDBACK and SAD-FB-001 state that the adapter reports the console's native effect richness and the hub reduces it to the bound device; `SAD-P-004` and `SRS-V-008` updated.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. Informative controller-coverage matrix added as `SAD-MAP-002` (every target console and mode, with gaps); generic positions to add before the PS input schema is frozen: digital left/right trigger (L2/R2) buttons, noted in PS-DATA-INPUT with the 0.1 wire format unchanged (bits 16..31 stay reserved zero); pressure-sensitive buttons marked Future (`SAD-F-005`; the fixed record size means a negotiated minor). Required for the first profiles: only the selected console and mode (`SAD-O-001`). The matrix rests on secondary knowledge and needs primary-document verification per profile.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. The first-increment gap is closed by `SRS-IN-012` (USB HID gamepads and fight sticks with parseable report descriptors), `SAD-P-011`, and `SAD-F-005` (non-HID protocols and authentication-requiring devices are Future). Not resolved: the two concrete first devices (name, VID/PID, descriptor) need the project owner's choice; recorded as `SAD-O-010` for Step 3.

---

### Theme E - Electrical interfaces

#### RR-001-028 - One universal "any mode, 3.3 V or 5 V" channel versus per-console safety

| Locations | Universal channel capability (ICD-CAP-004, ICD-CAP-005); ICD-CON-001 (per-profile electrical); SRS-HW-002 |
|---|---|
| Category / Severity / Gate | Decision / **S1** / Step 4 |

**Remark.** The reviewed capability text required that *every* channel can be input, 3.3 V push-pull, 5 V
push-pull, open-drain or high-Z, independently selectable. Several consoles (N64,
GameCube, Dreamcast, PlayStation) are 3.3 V-class with console-side pull-ups on
open-drain lines. Is runtime (firmware) selectability of 5 V push-pull on such a line
acceptable? A firmware defect or wrong profile could drive 5 V into a 3.3 V console or
create double pull-ups. This also contradicts the ICD's per-profile "drive mode and
contention prevention".

**Suggested solution.** Make the voltage domain and drive type a **hardware-defined
property of each console connector module** (strap or module ID readable by firmware,
which refuses incompatible profiles), keep high-Z as the only state reachable without
a valid module/profile match, and restate the capability as "the platform shall provide
the capabilities across modules" rather than "every channel shall do everything".

**Owner response:** Accept - see RR-001-008; apply suggested solution.
**Resolution (2026-11-18):** Specification applied; S1 gate closes at re-review plus `ICD-VER-001..009`. `ICD-CAP-004` (voltage domain and drive type are a property of the console connector module, readable by firmware; mismatching profiles refused; high-impedance the only state without a match), `ICD-CAP-005` (capabilities are provided across modules, not per channel), `SAD-D-006`, "Connector module" field in ICD-CON-001.

#### RR-001-029 - Saturn (and Mega Drive) signal directions and the 3D Control Pad

| Locations | Saturn and Mega Drive channel sizing (ICD section 8.2) |
|---|---|
| Category / Severity / Gate | Correction + Question / S2 / Saturn and Mega Drive profiles |

**Remark.** (To verify against ICD-REF-001 sources R3 and R4.) The reviewed Saturn signal list gave TH and TR as inputs
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

**Owner response:** Accept - see RR-001-008; option (b): correct the channel table (TL as output) and recompute sections 6.4 and 7; add the Mega Drive idle-timeout and TH-edge timing to the profile's measurement list; the 3D pad is in scope.
**Resolution (2026-11-18):** Applied. ICD section 8.2: Saturn is 7 channels per port (D0..D3 and TL out, TH and TR in), 14 for two ports (previously 6 and 12); GPIO budget recomputed in section 8.3 (Saturn 23 GPIO, same as Mega Drive). Mega Drive TH-edge/idle-timeout and Saturn TH/TR handshake measurement lists added to the ICD-CON-001 risk inventory. The TL direction itself still rests on secondary sources and must be verified against primary Saturn documentation.

#### RR-001-030 - Signals needed by other requirements are missing from the channel counts

| Locations | Console channel sizing (ICD section 8.2); SRS-OWN-008; ICD-PWR-002 (item 6); PS-DISCOVERY (physical commissioning enable); ICD-DBG-001 |
|---|---|
| Category / Severity / Gate | Correction / S2 / Step 4 |

**Remark.** The channel counts cover controller data lines only. Not counted: console power
sense / activity detection (SRS-OWN-008 requires activity or `UNKNOWN`), Dreamcast and
other presence/sense pins, the commissioning-enable input, status LEDs, the recovery/
boot-select input and the direction/enable lines of the RS-485 transceiver. Is the
channel table intended to be the complete GPIO budget for the adapter?

**Suggested solution.** Add an "adapter system I/O" table (power-sense per port,
presence, commissioning enable, recovery, LEDs, bus UART/direction) and a total GPIO
budget per console, to be compared with the RP2350 variant chosen (RR-001-002).

**Owner response:** Accept - see RR-001-008; apply suggested solution.
**Resolution (2026-11-18):** Applied. `ICD-CAP-014` and ICD section 8.3: adapter system I/O (bus UART and direction 3, power sense 2, commissioning enable 1, recovery 1, LEDs 2 = 9) and total GPIO per console against the RP2350 variants. The totals are minimums: translator direction/enable lines depend on the translator selection and are not yet counted.

#### RR-001-031 - No dynamic requirements: bit rates, edge rates, delay, skew, capacitance

| Locations | Capability and verification text (ICD-CAP-005, ICD-CAP-008, ICD-CAP-015; ICD-VER-003..008) ("defined input thresholds", "protection shall not compromise timing") |
|---|---|
| Category / Severity / Gate | Question / S2 / Step 4 |

**Remark.** The reviewed capability text states no numeric limits. Needed values per console include the
signalling rate (for example N64/GameCube about 4 us per bit with fast edges on an
open-drain line, Maple at a multi-megabit rate, PS1/PS2 a few hundred kHz, SNES/NES
tens of kHz), maximum rise/fall time, maximum added propagation delay, skew between
related lines, input capacitance, and protection capacitance. These decide which
translator class is usable: auto-direction translators are generally unsuitable on
open-drain bidirectional lines and ESD diodes can slow edges. What are the target
numbers, and where will the measurements be recorded?

**Suggested solution.** Add per-console columns for nominal rate, tolerance, VIH/VIL
and VOH/VOL required at the console, maximum added delay and capacitive budget; make
the verification entries ICD-VER-003..008 reference those numbers.

**Owner response:** Accept - see RR-001-008; apply suggested solution.
**Resolution (2026-11-18):** Structure applied; numbers pending. `ICD-CAP-015`, ICD section 8.4 (nominal signalling rate leads per console), a "Dynamics" field in ICD-CON-001 (rate and tolerance, VIH/VIL and VOH/VOL, rise/fall time, added delay, skew, capacitance), and `ICD-CAP-009` (auto-direction translators not used on open-drain bidirectional lines without measurement). The per-console limits cannot be invented; they come from the supplements, so `ICD-VER-003..008` are not executable until then.

#### RR-001-032 - Dreamcast: bidirectional "Digital" mode is undefined; presence detection not budgeted

| Locations | Dreamcast channel sizing (ICD section 8.2); ICD section 5 (Dreamcast row) |
|---|---|
| Category / Severity / Gate | Question / S2 / Dreamcast profile |

**Remark.** The reviewed Dreamcast signal list gave SDCKA/SDCKB as bidirectional "Digital" without drive type
(push-pull, open-drain, or console-biased) and defers presence detection to the profile
while the channel count excludes it. Is the line driven push-pull at 3.3 V, and what
pull-up arrangement does the console provide? Does the port have a sense/presence pin or
other function beyond the two data lines?

**Suggested solution.** Fill in drive type, levels and the presence/sense line from the
primary Maple documentation, and add the missing line(s) to the channel count.

**Owner response:** Accept - see RR-001-008; apply suggested solution.
**Resolution (2026-11-18):** Partly applied; evidence needed. The presence/sense line is budgeted as a placeholder of one channel per port (+2, to be confirmed) in ICD sections 8.2 and 8.3, and the ICD-CON-001 Dreamcast row now states that drive type, levels and pull-up arrangement come from primary Maple documentation. Those values are not filled in because no primary Maple document has been consulted; this remark stays open for the Dreamcast profile gate.

#### RR-001-033 - Connector voltages, pull-up ownership and the "3.3 V / 5 V" assumption

| Locations | Pull-ups and connector power (ICD-CAP-004, ICD-CAP-010, ICD-CAP-016, ICD section 8.5); ICD-PWR-002 |
|---|---|
| Category / Severity / Gate | Question / **S1** / Step 4 |

**Remark.** The reviewed connector power table listed PlayStation logic as "approximately 3.5 V" and
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

**Owner response:** Accept - see RR-001-008; apply suggested solution.
**Resolution (2026-11-18):** Specification applied; S1 gate closes with measurements. ICD-CON-001 "Electrical" field now requires voltage range (min/typ/max), pull-up location and value, and the translator or clamp approach per console and signal; `ICD-CAP-010` (the adapter adds no pull-up on a console-pulled line); `ICD-CAP-016` and section 8.5 keep the power values as unverified leads and drop the "3.3 V or 5 V only" assumption; the "Evidence" field requires measurements on at least one console of each family before approval.

#### RR-001-034 - Power source and grounding/isolation decision must precede any multi-console connection

| Locations | ICD-PWR-002, SAD-O-002; ICD-CAP-012; SRS-HW-003 |
|---|---|
| Category / Severity / Gate | Decision / **S1** / Step 4 (multi-console) |

**Remark.** Open: whether each adapter (a) senses console power only, (b) draws from the
console through protection, or (c) is externally powered; and whether the shared RS-485
bus is galvanically isolated. The reviewed capability text forbade connecting console rails "directly to the
internal 3.3 V logic supply", which differs from ICD-PWR-002's allowance of a
console-derived protected supply. Multiple grounded consoles bridged by video cables
and one bus form ground loops; the N64 and GameCube ports supply very little current.

**Suggested solution.** Recommended default: external adapter power with sense-only
console power, plus an isolated bus interface (isolated RS-485 transceiver and isolated
power) at every adapter, with isolation-delay included in PS-TIMING margins. Resolve as
a decision (SAD-O-002) before any bench setup beyond a single console, and harmonise
the wording of the capability text and ICD-PWR-002 ("not directly connected" versus "protected
derived supply").

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Specification applied; S1 gate closes with the ICD-QUAL-001 power tests. `SAD-P-010` records the default (external adapter power, sense-only console power, isolated RS-485 interface and isolated power at every adapter); ICD-PWR-002 and `ICD-CAP-012` harmonised so console rails are never tied to internal logic or to each other, with a controlled exception route; ICD-NET-001 ground-reference row; PS-TIMING counts isolation delay inside the 20 us and 50 us allowances (`ICD-VER-020`); `SAD-O-002` reduced to connector, cable, supply units and confirmation by test. Recorded as class P (owner-approved default) because it is unverified.

#### RR-001-035 - No electrical capability specification for the hub

| Locations | Console capability sizing (adapter-only); ICD-USB-001, ICD-PWR-001; SAD-O-003 |
|---|---|
| Category / Severity / Gate | Correction / S2 / Step 4 |

**Remark.** The reviewed capability sizing defines the adapter envelope; the hub (USB host ports, VBUS
switching and current, bus transceiver, local power, indicators) has only narrative text
in the ICD and no numbers. How many USB ports and what VBUS current does the hub provide
for devices such as fight sticks and wheels, and what is its power input?

**Suggested solution.** Either extend the capability baseline to a hub section or add a hub baseline
table to the ICD (ports, current per port, protection, supply input, transceiver,
indicator and button I/O).

**Owner response:** Accept - see RR-001-008 and RR-001-004; apply suggested solution.
**Resolution (2026-11-18):** Applied as a hub baseline table in the ICD (`ICD-HUB-001`: USB host behind a hub IC, two downstream ports, 500 mA per port, external 5 V supply, isolated bus transceiver, local I/O, protection), with `ICD-VER-018` and `ICD-VER-019`. The supply current figure (about 2 A) is a placeholder for the first power budget.

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

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. Class-P `SRS-SYS-008` (typical installation: up to 10 adapters on a trunk of up to 15 m; larger installations need their own qualification) and the ICD-NET-001 cable/node-loading row now use it for the first harness calculation.

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

**Owner response:** Accept - apply suggested solution. Initial draft idea: a hub UI with a small display showing the button mapping with target console button names and, for the Dreamcast, the VMU screen.
**Resolution (2026-11-18):** Applied. New SRS section 8: `SRS-UI-001/002` (physical selector and indicators for the first prototype), `SRS-UI-003` (display with adapter-supplied console button names; consistent with SRS-IN-001 because the names are adapter metadata), `SRS-UI-004` (VMU screen, Future, `SAD-F-006`), `SRS-CFG-002` (hub roster and assignment persistence), and class-O items `SRS-SUP-001`, `SRS-ENV-001..003`, `SRS-LIC-001`; `SRS-V-010`; SAD-COMP-HUB UI row updated.

#### RR-001-038 - First console and controller mode not yet chosen, while the capability baseline sizes all ten

| Locations | SAD-O-001; DEVELOPMENT-GUIDE Step 3 and "one active milestone"; console channel sizing (ICD section 8.2) |
|---|---|
| Category / Severity / Gate | Decision / S2 / Step 3 |

**Remark.** The capability baseline establishes the full console envelope while SAD-O-001 (first console,
variants, virtual peripherals) remains open. Which console and controller mode should
the first two-player prototype target, and does its resource profile reveal anything the
envelope hides?

**Suggested solution.** Compare two or three candidates (for example SNES, PlayStation 2,
Mega Drive) by electrical simplicity, timing difficulty and resource load on the chosen
RP2350, then select one. Keep the baseline as the long-term envelope; do not let it drive
first-prototype scope.

**Owner response:** Accept - apply suggested solution. Sega Saturn could be a good first option.
**Resolution (2026-11-18):** Comparison applied; selection left open. SAD section 3.1 compares SNES, Mega Drive, Saturn and PlayStation 2 (channels, GPIO, electrical and timing difficulty, coverage gaps) and `SAD-O-001` records the Saturn leaning. Finding for the owner: Saturn and Mega Drive exceed the 70 % GPIO margin on RP2350A (23 of 30) and Saturn needs digital L2/R2 for common layouts. The first console is chosen at development-guide Step 3.

#### RR-001-039 - Development guide alignment

| Locations | DEVELOPMENT-GUIDE (intro, Step 1 reading order and hand-off prompt, Step 7, rules) |
|---|---|
| Category / Severity / Gate | Correction / S3 / Step 2 |

**Remark.** The guide has no step for a formal
review and no place for review artifacts; Step 1 asks the owner to review but does not
say how remarks are recorded. Should the review process become Step 1b, with its output
feeding Step 2?

**Suggested solution.** Reference [RPN-RVP](../REVIEW-PROCESS.md) in Steps 1 and 2 and
in Step 7, and add "review record" to the session-close checklist.

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. The development guide references RPN-RVP in Steps 1, 2 and 7 (review as Step 1b feeding Step 2), the session-close rule includes review records, current position and next-session text updated, and the document-control rule (RR-001-010) is added.

#### RR-001-040 - Discoverability of review documents

| Locations | README document table |
|---|---|
| Category / Severity / Gate | Correction / S3 / Step 2 |

**Remark.** The README does not list the process document or review records. Should
they appear under a separate "Process documents" heading, distinct from the engineering
specifications?

**Suggested solution.** Add a "Process and review" table (development guide, review
process, latest review record) to the README, kept separate from the specification table.

**Owner response:** Accept - apply suggested solution.
**Resolution (2026-11-18):** Applied. README has a separate "Process and review" table (development guide, RPN-RVP, REVIEW-001), distinct from the specification table.

---

## 5. Disposition table

Owner columns are as entered by the project owner. The corrector's resolution
column and status were completed on 2026-11-18. Status values: **Applied** (text
changed; awaits the closure check of the re-review), **Applied - evidence
pending** (text changed, but a datasheet check, measurement or primary source is
still required), **Partly applied** (owner input or evidence needed before the
remark can close), **Withdrawn** (the subject of the remark was removed from the
repository on 2026-11-25). No remark is **Closed** until the re-review (RPN-RVP section 9).

| ID | Owner decision (Accept / Modify / Reject / Defer) | Owner answer (as entered) | Resolution (corrector) | Status |
|---|---|---|---|---|
| RR-001-001 | Accept | Apply suggested solution | SRS-HW-005, SRS-HW-001 retired, SAD-D-004, SAD-R-008/O-003, ICD, PS | Applied |
| RR-001-002 | Accept | Apply suggested solution | SAD-P-007, ICD-CON-001 resource table and 70 % rule, ICD 8.3 | Applied - evidence pending |
| RR-001-003 | Accept | Don't rely on the chosen MCU 5V capabilities. Rely only on external translators when applicable. | SRS-HW-006, ICD-CAP-003, SAD-D-006, ICD-PLAT-001, ICD-VER-015 | Applied - evidence pending |
| RR-001-004 | Accept | The RP2350 MCU family has only a single USB 1.1 interface. To satisfy SRS-SYS-002, the RPN hub can have a USB hub IC thus allowing for two player USB input controller devices. | SAD-P-009, ICD-PWR-001, ICD-HUB-001, ICD-VER-018/019 | Applied - evidence pending |
| RR-001-005 | Accept | Apply suggested solution option A (recommended for scope): the Xbox adapter implements two USB device ports (matching the two-player limit); the other two console ports are left unconnected (the console sees no controller). | SRS-SYS-009, SAD-P-008, SAD-ADAPT-001, ICD-CAP-011 | Applied |
| RR-001-006 | Accept | Apply suggested solution | SAD-P-003, PS-DISCOVERY, PS-TRANSACTION | Applied - evidence pending |
| RR-001-007 | Accept | Apply suggested solution | SRS-UPD-004, SAD-F-004, SAD-O-008, PS-SVC-UPDATE | Applied |
| RR-001-008 | - | - | - | Withdrawn |
| RR-001-009 | - | - | - | Withdrawn |
| RR-001-010 | Accept | Apply suggested solution | Dates and history rows; development guide rule 8 | Applied |
| RR-001-011 | Accept | See RR-001-008 | SRS-SYS-009, SAD-P-008, SAD-F-001, ICD 8.2, ICD-CON-001 port mapping | Applied |
| RR-001-012 | - | - | - | Withdrawn |
| RR-001-013 | Accept | Apply suggested solution | SRS glossary and wording fixes | Applied |
| RR-001-014 | Accept | Apply suggested solution | ICD-REF-001, ICD 8.2-8.5 confidence flags | Partly applied (retrieval dates and primary sources needed) |
| RR-001-015 | Accept | Apply suggested solution | SRS-V-001/003/005, new SRS-V-009 and V-010 | Applied |
| RR-001-016 | Accept | Apply suggested solution | PS-TIMING per-opcode timeouts, cycle budget, admission rule; SAD-SCHED-001 | Applied |
| RR-001-017 | Accept | Apply suggested solution | SRS-PERF-004/005, SRS-OWN-012, SRS-V-003/007 | Applied (class P values for owner confirmation) |
| RR-001-018 | Accept | Apply suggested solution | SAD-O-009 gate and fallback order; PS-TIMING note | Applied - evidence pending (measurement) |
| RR-001-019 | Accept | Apply suggested solution | PS-DISCOVERY retry rule and commissioning counter | Applied |
| RR-001-020 | Accept | Apply suggested solution | Persisted address in PS-DISCOVERY, SAD states, SAD-P-003 | Applied |
| RR-001-021 | Accept | Apply suggested solution | SRS-NET-010, ICD-NET-001 clock and baud row, ICD-VER-017 | Applied - evidence pending (values to confirm) |
| RR-001-022 | Accept | Apply suggested solution | SRS-IN-011, SAD-D-007, PS ROUTES, ICD-CON-001 | Applied |
| RR-001-023 | Accept | Apply suggested solution | SRS-OWN-013, SAD-D-008, PS CAPS kind 4, ICD-CON-001, ICD-VER-016 | Applied - evidence pending (per-profile measurement) |
| RR-001-024 | Accept | Apply suggested solution | PS STATUS and CAPS corrections; SAD adapter states | Applied |
| RR-001-025 | Accept | Apply suggested solution | PS-TIMING 10 ms poll cadence, PS-SVC-FEEDBACK, SAD-FB-001 | Applied |
| RR-001-026 | Accept | Apply suggested solution | SAD-MAP-002, PS-DATA-INPUT note, SAD-F-005 | Applied |
| RR-001-027 | Accept | Apply suggested solution | SRS-IN-012, SAD-P-011, SAD-F-005, SAD-O-010 | Partly applied (owner to name two devices) |
| RR-001-028 | Accept | See RR-001-008. Apply suggested solution | ICD-CAP-004/005, SAD-D-006 | Applied |
| RR-001-029 | Accept | See RR-001-008. Apply suggested solution (b): correct the channel table (TL as output) and recompute sections 6.4 and 7. Add the Mega Drive idle-timeout and TH-edge timing to the profile's measurement list. The 3D pad is in scope. | ICD 8.2 and 8.3 recomputed; ICD-CON-001 measurement lists | Applied - evidence pending (primary Saturn documentation) |
| RR-001-030 | Accept | See RR-001-008. Apply suggested solution | ICD-CAP-014, ICD 8.3 | Applied |
| RR-001-031 | Accept | See RR-001-008. Apply suggested solution | ICD-CAP-009/015, ICD 8.4, ICD-CON-001 dynamics | Partly applied (limits come from the supplements) |
| RR-001-032 | Accept | See RR-001-008. Apply suggested solution | Presence channel placeholder, ICD-CON-001 Dreamcast row | Partly applied (primary Maple documentation needed) |
| RR-001-033 | Accept | See RR-001-008. Apply suggested solution | ICD-CAP-010/016, ICD-CON-001 electrical and evidence fields | Applied - evidence pending (measurements) |
| RR-001-034 | Accept | Apply suggested solution | SAD-P-010, ICD-PWR-002, ICD-CAP-012, PS-TIMING isolation rule, ICD-VER-011/020 | Applied - evidence pending (tests) |
| RR-001-035 | Accept | See RR-001-008 and RR-001-004. Apply suggested solution | ICD-HUB-001, ICD-VER-018/019 | Applied |
| RR-001-036 | Accept | Apply suggested solution | SRS-SYS-008, ICD-NET-001 | Applied |
| RR-001-037 | Accept | Apply suggested solution. Initial draft idea is to have a hub UI with a small display showing button mapping with target console button names, and in the case of the dreamcast show the VMU screen. | SRS section 8 (UI, CFG-002, SUP, ENV, LIC), SAD-F-006 | Applied |
| RR-001-038 | Accept | Apply suggested solution. Sega saturn could be a good first option. | SAD section 3.1 comparison; SAD-O-001 | Applied (selection remains at Step 3) |
| RR-001-039 | Accept | Apply suggested solution | Development guide | Applied |
| RR-001-040 | Accept | Apply suggested solution | README | Applied |

Remarks the corrector could not fully apply, with the reason: RR-001-014
(source revision and retrieval dates were never recorded), RR-001-027 (the two
first devices are an owner choice), RR-001-031 and RR-001-032 (numeric limits and
Dreamcast drive details need approved supplements and primary Maple
documentation). Deferred content has register entries: `SAD-F-004`, `SAD-F-005`,
`SAD-F-006` and the four-port part of `SAD-F-001`.

Post-cycle owner decision (2026-11-18): the bus line rate was raised from 1 to
2 Mbit/s with a trunk under 5 m. The timing figures quoted in the resolutions of
RR-001-016 and RR-001-017 (and the review's section 3 exchange arithmetic) are
for 1 Mbit/s and are superseded by the PS-TIMING tables; the review record is
otherwise left as written.

New class-P values introduced by the corrections for the owner to confirm:
SRS-SYS-008 (10 adapters, 15 m), SRS-PERF-004 (16.7 ms), SRS-PERF-005 (12 ms),
SRS-OWN-012 (500 ms), SRS-NET-010 (+/-100 ppm) and the +/-0.5 % baud budget,
the 64-entry CAPS bound, the 10 ms feedback cadence, and the hub baseline figures
in ICD-HUB-001.

## 6. Gates carried forward

| Gate | Blocked until |
|---|---|
| Step 2 reconciliation complete | Re-review closure check of the correction cycle (all remarks answered and applied as above) |
| Step 3 prototype scope | RR-001-011, -017, -022, -026, -027, -037, -038 closed; first console and two HID devices chosen (`SAD-O-001`, `SAD-O-010`); RR-001-017 class-P values confirmed |
| Step 4 any hardware connection | All S1 remarks closed with evidence: RR-001-003 (`ICD-PLAT-001` populated, `ICD-VER-015`), -023 (per-profile `ICD-VER-016`), -028 (`ICD-VER-001..009`), -033 (measurements on one console per family), -034 (`ICD-QUAL-001` power and isolation tests) |
| Step 5 protocol tests | RR-001-016, -018 (`SAD-O-009` measurement), -019, -021 (`ICD-VER-017`), -024 closed |
| Dreamcast profile | RR-001-032 (primary Maple documentation) |
| Before advertising Update | `SAD-F-004` update-profile supplement |
