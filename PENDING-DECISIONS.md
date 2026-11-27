# RPN pending decisions - working form

> **Temporary working document.** It is not part of the specification set, nothing links
> to it, and it is deleted once its decisions have been applied.

**Purpose.** Turn the SRS, ICD, SAD and PS into the definitive specification: no draft,
provisional, future or prototype content. This form lists every decision I cannot take
for you. Fill it in, tell me, and I rework all documents in one pass. "Today" below is
the state after the EIC removal (2026-11-25).

## How to fill it in

1. Tick one option per item (`[x]`) or write your own answer on the *Your answer* line or
   in the table cell.
2. **★** marks my recommendation. Where a confirmed (class C) requirement already points
   one way, the ★ follows it; to go the other way you are changing a confirmed
   requirement, and the item says so. **No ★** means I have no basis to recommend.
3. Shortcut - tick this box to accept every ★ for any item you leave blank:

   `[ ]` **Accept all ★ recommendations for items I leave blank**

   An item without a ★ stays open and blocks the part of the rework that depends on it.
4. If you change a timing or size in Part D, I recompute every dependent budget and tell
   you if the change is infeasible.

**Look at these first** (the answer deletes a document, changes the wire format, decides
what the set contains, or touches a confirmed requirement): A6, A9, B2, C8, C11, E3, E17, F1.

**No ★ (cannot be defaulted):** B4 (SNES, Mega Drive and PlayStation 2 rows), E1 (connector), E3.

---

## Rules I will apply (no decision needed - object only if you disagree)

| # | Rule |
|---|---|
| R1 | **Wording.** After the rework no specification says draft, provisional, proposed, "to be confirmed", "not yet decided", "unverified", "initial", "first prototype/increment", "profile 0.1" or "this draft". Revision and status follow A1. |
| R2 | **Scope.** Every feature in Part C is either specified in full (IN) or removed from every document without a trace (OUT): no "future", "deferred", "roadmap" or "out of scope" wording survives. That includes today's exclusion statements (C21). The rule that exactly one console owns live input (SRS-OWN-002) is the design, and is restated positively rather than as an exclusion. |
| R3 | **Prototype and bring-up content leaves the specifications** (bring-up is planned separately): prototype-board allowances (non-OTP UID, volatile address as a "prototype limitation", fixed player-n-to-port-n), "first console", "first two HID devices", "first harness calculation" (SAD-O-001, SAD-O-010, SRS-UI-001/002 and SRS-IN-012 clauses, PS-DISCOVERY, the SAD address store), SAD section 3.1 (first-console comparison), the development-sequence list in SAD section 10 (its trust and fault-model paragraphs stay), the SAD-O-009 fallback path, and every "development-guide Step n" reference. The 250 us response limit stays as a requirement; bring-up measures it. |
| R4 | **Provenance clutter is removed:** "(owner decision ...)", REVIEW-001 / RR-xxx references, "Supersedes ...", "Initial draft intent", and retired rows (SRS-HW-001, SRS-STO-007, SAD-O-012, SAD-O-013, SAD-F-014; their identifiers stay unused). |
| R5 | **Verification stays, gates go.** SRS section 9 and ICD-VER remain as verification methods. "Planned / not claimed as passing", "approved to wire", "open gates" and the step-gating wording go; ICD-QUAL-001 becomes a statement of the evidence that demonstrates conformance. |
| R6 | **Wire compatibility.** No message layout, number, golden vector or figure changes unless a decision here requires it. The ★ answers of C11, C20, D33 and E17 do; so do the non-★ answers of C3, C8, C9, C18, E3, E5, E6, E7 and E15 (free remapping). Where one applies, I recompute every affected vector, budget and figure with scripts and list them. |
| R7 | **One authority per fact; identifiers never reused** (as today). |
| R8 | **Housekeeping.** README, RPN-RVP (per A7), PDFs, dates and change history are updated; links and anchors are checked; a word scan confirms R1 to R4. |
| R9 | **Services follow features.** The optional PS services become mandatory exactly where a selected feature needs them: Feedback for every profile that forwards rumble (B5), Storage for every profile that presents a memory accessory (when E3 allows transfers), Configuration where a per-port choice exists (B5a), and Diagnostics for every node (SRS-NET-007 needs observable counters). A node still advertises only what it implements (SRS-NET-002). |
| R10 | **Design details I specify myself** (derived from your choices; object if you disagree): (a) the ASSIGN completion rule - after the ASSIGN reply the node may be silent for up to 500 ms while it persists its address, and the hub waits that window before HELLO; (b) the flash-write rules of E4; (c) LED meanings - adapter: two LEDs, one for state and one blink-coded with the STATUS fault value 1 to 6; hub: per E2; (d) the corrected neutralisation measurement and a recovery-test entry in ICD-VER (E13); (e) the minimal HID subset and its descriptor corpus (D30); (f) the display polling rate stated in frames per second (C11). |

---

## Defects found in the current text

I fix all of these in the rework. Only those with a decision reference need an answer from you.

| # | Where | Defect | Fix | Decision |
|---|---|---|---|---|
| X1 | ICD-STO-001 (Capacity) | "Two banks plus a bank-select record" does not fit: 2 x 32 KiB = 64 KiB = a 512 kbit part exactly, and 2 x 128 KiB = 256 KiB = a 2 Mbit part exactly; no space is left for the record | Move the record or use the next density | E4 |
| X2 | ICD-VER-016 | Measures from the REVOKE acknowledgement, which comes after the neutral state is installed; SRS-OWN-013 defines the bound from the inhibit, and the lease-expiry path is not measured | Measure from the internal inhibit instant for both the REVOKE and the lease-expiry paths | - |
| X3 | PS-SVC-DISPLAY | "At most 10 times per second per port" but the 9.0 % budget assumes 10 frames per second at two polls each (10 polls per second would cost 4.5 %) | State the rate in frames per second | C11 |
| X4 | SRS-IN-008, SAD-ADAPT-001 | A gateway forwards validated records to secondary processors one by one, so installation is not atomic across processors | E18 | E18 |
| X5 | SRS-UI-003, PS CAPS | Console button names are "adapter-supplied", but no message carries names | New CAPS kind, or generic labels | D33 |
| X6 | PS-DISCOVERY | The ASSIGN reply precedes the address write; no completion rule | R10(a) | - |
| X7 | SRS-IN-012 | Says PlayStation 4/5 pads need console-specific protocols or authentication; their input can often be read as plain HID, the device-specific parts are rumble, lights and initialisation | Reword by what a device needs | C10 |
| X8 | SRS-STO-008 vs SAD-P-012, ICD-STO-001 | A confirmed requirement keeps accessory contents out of MCU flash, but an "owner-approved" flash exception exists, and no in-scope accessory needs it | Keep or remove the exception | D27 |
| X9 | ICD-HUB-001 vs SAD-P-010 | The hub baseline has an isolated transceiver; the decision text speaks only of adapters | State it for both | D22 |
| X10 | SRS-V-002 | Requires "the named HID devices", which R3 removes | Acceptance by a descriptor corpus | D30 |

---

## Part A - Document set and process

### A1 - Revision and status label (all four specifications; README)
Today: Revision 0.1, "Status: Draft - ...". README says "All specifications are Revision 0.1, Draft".
- [ ] ★ Revision **1.0**, Status **Definitive**, dated the day of the rework.
- [x] Other (revision / status wording): Not ready yet for 0.1. Increment minor revision to the next value. 1.0 will be used when first no more open points are present and a full review was completed without remarks.

### A2 - Classification column (SRS section 1: C / D / P / O / F / Retired)
After the rework no row is P, O, F or Retired.
- [ ] ★ Keep **C** (owner-supplied scope or principle) and **D** (derived engineering constraint) as an origin marker. Each surviving row becomes C if it comes from an owner decision or a value you confirm below, otherwise D.
- [ ] Drop the Class column everywhere.
- [x] Other: Replace **C** (owner-supplied scope or principle) with **F** (Functional Requirements: What the system must do—specific actions, tasks, or behaviors it must perform.) and keep **D** (derived engineering constraint) as an origin markers. Each surviving row becomes F if it comes from an owner decision or a value you confirm below, otherwise D.

### A3 - Change-history tables (SRS 8 rows, ICD 9, SAD 10, PS 7, citing REVIEW-001, owner decisions and drafts)
- [ ] ★ One baseline row per specification ("1.0 - definitive baseline"); later changes add rows. Draft-era history stays in git.
- [ ] Keep every existing row.
- [ ] Remove the tables (git is the history).
- [x] Other: Keep every existing row. Still in draft. See A1.

### A4 - SAD section 2 "Initial architecture review" (SAD-R-001..012: "finding or unresolved assumption | resolution in this draft")
- [x] ★ Keep as "Design rationale" (concern | design response), reworded without review or draft framing and without entries made obsolete by Part C.
- [ ] Delete the section.

### A5 - SAD section 3 register and identifier prefixes (SAD-D decided, SAD-P provisional, SAD-O open, SAD-F future)
Only decided entries survive the rework.
- [ ] ★ Keep every surviving identifier unchanged (SAD-P-007 stays SAD-P-007); retitle the section "Design decisions"; the prefix letter becomes plain identifier text. No cross-reference changes.
- [x] Renumber survivors into SAD-xxx (new numbers), update every cross-reference in all four documents, never reuse the old numbers.

### A6 - docs/DEVELOPMENT-GUIDE.md (steps 0 to 8: review, prototype, expansion; "current position: Step 2")
- [x] ★ Delete it. Bring-up planning is written when source-code bring-up starts. The document-control rule (date and one history line per change; regenerate PDFs) moves to the README.
- [ ] Replace it with a short specification-maintenance guide (no steps, no prototype).
- [ ] Keep it and only fix stale references.

### A7 - docs/REVIEW-PROCESS.md (RPN-RVP: review method, severities, "gate = development-guide step", RVO-8 "first prototype and wider roadmap")
- [x] ★ Keep as the review method for future revisions of the definitive specifications; remove step, gate, prototype and roadmap wording.
- [ ] Delete it.

### A8 - docs/reviews/REVIEW-001.md (historical record; EIC references already scrubbed)
- [ ] ★ Keep as a historical record; add a closing note ("closed by the definitive baseline"); no other change.
- [x] Delete it (git history keeps it).
- [ ] Keep unchanged.

### A9 - Wire version (PS-PROFILE: "draft wire version major 0, minor 1"; header bytes `00 01`)
Nothing implements the wire format yet, so any wire change is made in place.
- [x] ★ Wire version **1.0** (header `01 00`). I recompute PS-VECTOR-001 (CRC and COBS bytes), the PS-FRAME table, the HELLO / DISCOVER_UID version fields and every place that quotes the bootstrap minor, and check the result with the RPN-RVP Appendix B reference code.
- [ ] Keep **0.1** numerically; only the word "draft" goes. Valid only if every wire change in R6 is answered "no change"; the ★ answers of C11, C20, D33 and E17 change the wire, so "0.1" would then label a format that differs from today's 0.1 text.
- [ ] Other: ________________

---

## Part B - Scope: consoles, profiles, accessories

### B1 - Consoles (SRS-SYS-004 "roadmap"; ICD sections 8.2 / 8.3; SAD-MAP-002)
IN = fully covered by the specification set. OUT = removed from every document.

| Console | ★ | Your answer (IN / OUT) |
|---|---|---|
| NES | IN | IN |
| SNES | IN | IN |
| Mega Drive | IN | IN |
| Saturn | IN | IN |
| Nintendo 64 | IN | IN |
| GameCube | IN | IN |
| Dreamcast | IN | IN |
| PlayStation | IN | IN |
| PlayStation 2 | IN | IN |
| Original Xbox | IN | IN |

### B2 - Where console profiles live (ICD-CON-001 "supplements"; SRS-SYS-005; SAD-O-004; ICD-VER "needs supplement values")
Today the ICD defines what a console profile must contain and a sizing baseline, but none of
the profiles exists, and several required values (neutralisation bound at the console
connector, console response timing, storage access time) can only come from measurements on hardware.
- [ ] ★ **Outside the set.** The ICD keeps the profile contract (ICD-CON-001), the sizing baseline (ICD-CAP, 8.2 to 8.5) and the verification entries; the risk inventory in ICD section 5 becomes "profile content requirements per family". Each profile is produced with its console driver during bring-up and is not listed as pending anywhere in the set.
  *Consequence:* "console IN" then means the system provides what a profile needs and verifies it, not that the set contains that console's electrical facts. SAD-O-004 (per-console MCU/PIO/USB split and timing limits), translator control lines (not counted in ICD 8.3), the ICD 8.4 dynamics, and the Original Xbox descriptor and authentication questions all become profile content requirements.
- [x] **Inside the set, as ICD annexes.** I write one annex per console now from public sources; measured values become requirements (limits), not results. Large effort; facts I cannot confirm publicly are listed for you (and F1 limits what can be stated).
- [ ] **Inside the set, as separate documents** (one per console, each with its own PDF): same content as the annexes.

### B3 - Controller modes and variants (SAD-O-001 "exact hardware variants and first virtual peripherals"; SAD-MAP-002)
Edit the list of virtual peripherals the adapters must present. ★ = today's SAD-MAP-002.

| Console | Virtual peripherals in scope (★ as listed) | Your changes |
|---|---|---|
| NES | standard pad | Add NES Max Controller |
| SNES | standard pad | Add SNES Mouse |
| Mega Drive | 3-button and 6-button pads | Add Sega Mega Mouse |
| Saturn | digital pad; 3D Control Pad | Add Virtua Stick, Twin Stick, Sega Saturn Keyboard, Sega Saturn Mouse, Sega Arcade Racer |
| Nintendo 64 | standard controller | Add N64 Fishing Rod, Steering wheel |
| GameCube | standard controller | Add Keyboard, Steering wheel |
| Dreamcast | standard controller | Add Dreamcast Arcade Stick, Fishing Controller, Sega Dreamcast Keyboard, Sega Dreamcast Mouse, Sega Race Controller |
| PlayStation | digital pad; DualShock | Add Namco NeGcon, Namco Jogcon, PlayStation Mouse, Steering wheel |
| PlayStation 2 | DualShock 2 (pressure buttons: see C9) | Add Steering Wheel |
| Original Xbox | standard controller | Add Xbox Arcade Stick, Xbox Steering Wheel |

Hardware variants:
- [x] ★ Every revision whose standard controller ports take detachable pads (regional and slim variants included; for the NES family that is the NES and the AV Famicom HVC-101, which takes its own detachable pads); the original Famicom HVC-001, whose pads are hard-wired, is excluded.
- [ ] Other (list variants in/out): ________________

### B4 - Multitaps (SRS-SYS-010, SAD-P-013, SAD-O-015, ICD-CAP-020, ICD-VER-022)
Tap facts below come from the secondary sources of ICD-REF-001, so every ★ is subject to F1. The
mechanism (each tap slot is port 0..3 of the same adapter; hub, routes and PS unchanged) stays
whichever rows you answer. Today it is "not required for the first increment", which is a
future flag, so each row must become IN or OUT.

| Console | Tap | Extra channels | ★ | Your answer (model / none) |
|---|---|---|---|---|
| NES | Four Score (uses both ports; 24-bit read with signature bits) | none | IN | OUT |
| SNES | Multitap | Data2 and IOBit per tapped port (baseline excludes them; IN needs the C21 carve-out) | none | IN |
| Mega Drive | Sega Team Player or EA 4 Way Play (mutually incompatible; TR becomes a direction-controlled channel) | TR direction control | none (one model, both selectable, or none) | IN (Sega Team Player) |
| Saturn | Multitap (six slots, four used) | none | IN | IN |
| PlayStation | Multitap (controller-port signals only) | none | IN | IN |
| PlayStation 2 | Multitap (differs from the PlayStation's; may also use the memory-card slot, which is out of scope: unverified) | unverified | none | IN |

- [ ] No taps at all: the mechanism is removed (SRS-SYS-010, SAD-P-013, SAD-O-015, ICD-CAP-020 and ICD-VER-022 disappear); those consoles support only their native two ports.

### B5 - Accessories and rumble (SRS-STO-001/005; ICD-STO-001; SAD-MAP-003)
Settled earlier by you: a memory accessory attached through the controller port is in scope
(N64 Controller Pak 32 KiB, Dreamcast VMU memory 128 KiB), one per emulated port.

(a) N64 accessory slot - what the adapter presents on each port:
- [x] ★ Exactly one of Controller Pak, Rumble Pak (rumble forwarded to the physical device) or none, chosen per port in the adapter configuration (needs an end-user configuration path: E3 = A or B; with E3 = C or D the choice is fixed by the profile); default Controller Pak.
- [ ] Controller Pak only (no N64 rumble).
- [ ] Other: ________________

(b) Rumble forwarding (consoles whose in-scope controller supports rumble: N64 with Rumble Pak, GameCube, PlayStation DualShock, PlayStation 2, Original Xbox):
- [x] ★ All of them.
- [ ] Only: ________________

Dreamcast rumble (Vibration Pack):
- [ ] ★ Not offered: the one memory accessory per port is the VMU (the pack needs its own expansion slot, see C17a).
- [ ] Offered **instead of** the VMU, selectable per port (same configuration path as (a)).
- [x] Both on one port (needs C17a = IN).

(c) Which physical devices can receive rumble (generic HID parsing alone does not define an output path):
- [x] ★ Only devices that expose a standard HID output path the hub implements (haptics or physical-interface usages, listed in the SRS); any other device gets no rumble and a diagnostic result (SAD-FB-001 already requires this).
- [ ] A hub table of device-specific drivers (needs C10 = a named device list).
- [ ] Rumble is not forwarded at all: the Feedback service, SRS-OWN-011 and the rumble parts of SAD-FB-001 are removed.

---

## Part C - Features flagged "Future" (IN = specified in full now; OUT = removed)

| # | Feature | Where flagged | What IN adds | ★ | Your answer (IN / OUT) |
|---|---|---|---|---|---|
| C1 | Bluetooth input acquisition | SAD-F-001, SAD-O-003 (also SRS-PERF-001, ICD-PWR-001, SAD-COMP-HUB diagram) | Hub radio hardware, Bluetooth HID host stack, pairing UI, its own latency budget, radio EMC | OUT | OUT |
| C2 | Racing wheels and pedals | SAD-F-001, SRS-IN-003 ("reserved") | see C2 block | see block | IN |
| C3 | More than four players | SAD-F-001, PS-TIMING note | Raise the player, port and route ceilings everywhere (SRS-SYS-002/007/009, PS limits and HELLO fields, "four" in SAD and ICD); INPUT redesign (only five 32-byte records fit 192 bytes); recomputed cycle budget and latency; more hub USB ports and power; larger resource tables | OUT | OUT |
| C4 | "Remote control" | SAD-F-001 (never defined) | You define what is controlled, by whom, over which interface | OUT | OUT |
| C5 | Automatic discovery of unknown nodes | SAD-F-002, SAD-R-003, PS-DISCOVERY | Collision-free broadcast enumeration of nodes that are not physically enabled (E17 covers the single enabled node) | OUT | IN |
| C6 | Live coherent storage export while a console is active | SAD-F-002, SAD-P-006 | Snapshot and consistency protocol for a running console | OUT | IN |
| C7 | Separate adapter-framework specification | SAD-F-003, SAD section 9 | A fifth document, written before any driver exists to extract it from (SAD section 9 stays as design guidance either way) | OUT | IN |
| C8 | Network firmware update | SRS-NET-001, SRS-UPD-001..004, SAD-F-004, SAD-O-008, PS-SVC-UPDATE | see C8 block | see block | IN |
| C9 | Pressure-sensitive buttons (PS2 DualShock 2, Xbox analog buttons) | SAD-F-005, SAD-MAP-002/003 | A pressure field per INPUT record: record size, ACK, cycle budget and latency recomputed. OUT means a binary press is reported to a pressure-capable controller as full pressure and a release as zero; that is a documented lossy mapping the user approves (SRS-IN-007) | OUT | IN |
| C10 | USB input devices beyond plain HID | SAD-F-005, SRS-IN-012, SAD-P-011 | see C10 block | see block | OUT |
| C11 | Dreamcast VMU screen on the hub display | SRS-UI-004, SAD-F-006, PS-SVC-DISPLAY | PS-SVC-DISPLAY becomes normative (opcode, service bit 6, CAPS kind 5), hub display of the VMU frames, VMU display function in the Dreamcast profile; rate: 10 frames per second per port (two polls each, X3). Needs D33 = display | IN | OUT (VMU screens will be added instead to the adapter reducing communication load eliminating need for PS-SVC-DISPLAY) |
| C12 | Mice and trackballs | SAD-F-007 | Pointer record with running counters, console mouse profiles | OUT | IN |
| C13 | Keyboards | SAD-F-008 | Key-matrix / scan-code transport, LEDs | OUT | IN |
| C14 | Motion and tilt | SAD-F-009 | New channels and units | OUT | OUT |
| C15 | Rich haptics / force feedback | SAD-F-010 | Effect model beyond two-magnitude rumble | OUT | IN |
| C16 | Audio (microphones, headsets, buzzers) | SAD-F-011 | Audio path and bandwidth budget | OUT | OUT |
| C17 | Compound and linked accessories | SAD-F-012 | (a) several sub-peripherals per port, e.g. Dreamcast VMU plus vibration pack; (b) linked devices (N64 Transfer Pak, GBA link). Answer each | (a) OUT, (b) OUT | (a) IN (VMU plus vibration pack) (b) OUT |
| C18 | Controllers beyond the INPUT record (more than 32 buttons or 8 axes) | SAD-F-013 | Larger or second input record type. Bits 16..31 of `buttons` are reserved today, and C20 takes two of them | OUT | OUT |
| C19 | Several physical devices combined into one player | SAD-COMP-HUB ("future explicit policy") | Combination policy and conflict rules | OUT | OUT |
| C20 | Digital left / right trigger buttons (L2 / R2) in the generic model | SAD-MAP-002, PS-DATA-INPUT bits 16..31 ("earmarked for the schema freeze") | Buttons bits 16 and 17; mapping tables updated; no layout change | IN | IN |

### C2 - Racing wheels and pedals
- [ ] ★ OUT as devices and peripherals. The generic model keeps its steering and pedal axes (SRS-IN-002 is your confirmed requirement); no hub wheel class and no console wheel peripheral is specified.
- [ ] OUT, and remove steering and pedal axes from the model (axes 6 and 7 become reserved zero; SRS-IN-002 and SRS-IN-003 change).
- [x] IN: hub parses USB HID wheels; adapters present console wheel peripherals for (consoles): see B3 ; clutch / shifter: yes / no.

### C8 - Network firmware update
Touches SRS-NET-001 (confirmed, class C: it lists "update" among the network operations), SRS-UPD-001..004, SAD-F-004, SAD-O-008, SAD-PERSIST-001, PS opcode 0x60, service bit 5, CAPS kind 2, and E13.
- [ ] A. IN, signed: full update profile (image format, RP2350 signed boot, anti-rollback, key management, OTP policy). Largest effort; irreversible OTP steps; it forces a locked-debug policy in E13.
- [x] B. ★ IN, integrity-checked: one concrete update profile - image header (target hardware ID, version, length, SHA-256), staging, verification, A/B slots with automatic rollback, activation only while the physical update-enable is asserted (trusted bus, E16), recovery through E13; no signatures and no OTP programming. This meets SRS-UPD-001 (compatibility and integrity checks; CRC is not called authentication) and keeps the confirmed SRS-NET-001 wording.
- [ ] C. OUT: no network update; firmware is installed locally (E13). This **reverses** the class-C wording of SRS-NET-001. SRS-UPD-001/003/004, opcode 0x60, service bit 5 and CAPS kind 2 go (opcode and bit stay reserved); the reset protection of SRS-UPD-002 stays; it is the only choice compatible with E3 = D.

Hub image: updated through the E3 path (A: PC tool; B: USB drive) or only locally through E13.

### C10 - USB input devices beyond plain HID
SRS-IN-012 says devices needing console-specific protocols or authentication (it names Xbox 360/One, PlayStation 4/5 and Nintendo Switch pads) are Future. Class-driver and handshake needs differ per device, so the answer has two parts.
- [x] ★ Acceptance is by descriptor parsing only (D30): any device whose report descriptor parses under the D30 subset is accepted for input; a device that needs a vendor class driver or an initialisation handshake is not supported (Xbox 360/One, Switch Pro and similar). I reword SRS-IN-012 by what a device needs rather than by brand; a PlayStation 4/5 pad is then accepted if, and only if, it parses as HID (input only; no lights, no rumble).
- [ ] A named list of device families, each with its own driver (answer per family: input / rumble): ________________
- [ ] Plain HID only, and the listed brands are explicitly unsupported even if their descriptors parse.

### C21 - Exclusions that will disappear from the specifications (rule R2)
Stated today as "out of scope" or "excluded" (ICD-CAP-017/018, SRS-STO-005, SAD-D-009, SAD-MAP-003, SRS section 2, ICD-STO-001 table):
light guns and specialist peripherals; video-synchronisation processing; analog electrical interfaces; accessory signals on extra connector pins (the SNES multitap's Data2 and IOBit are carved out if B4 makes it IN); motor-drive circuitry; memory cards in a dedicated slot (GameCube, PlayStation, PlayStation 2); the Original Xbox Memory Unit; Dreamcast VMU buzzer and clock (C11 covers only the screen); emulation of every peripheral ever sold.
- [ ] ★ Confirmed: none of these is wanted.
- [x] Wanted (they become IN and need full specification): only for the devices listed in B3 and B4

---

## Part D - Provisional values: keep or change

Write **Y** to keep the value, or the new value. Rows marked *owner* record a decision you
already took; they only lose their "provisional" label. Blank = Y if the shortcut is ticked.

| # | Item (where) | Today | Y / new value |
|---|---|---|---|
| | **Bus and protocol** | | |
| D1 | Physical layer (SRS-NET-003, SAD-P-001, ICD-NET-001) *owner* | Half-duplex RS-485, one master, 2 Mbit/s, 8N1 | For speed see impact of D8. |
| D2 | Address space (SRS-SYS-007, PS-PROFILE) | Hub 0, adapters 1..31 | Y |
| D3 | Installation limits (SRS-SYS-008, ICD-NET-001) *owner* | Up to 10 adapters on a trunk under 5 m. Today larger installs "need their own qualification"; ★ the specification states only this limit (31 stays the protocol address bound) | Y |
| D4 | Frame and size limits (SAD-P-002, PS) | COBS + CRC-32C; payload at most 192 B; storage chunk 183 B; configuration at most 4096 B; CAPS list at most 64 entries; partial frame dropped after 3 ms | Y |
| D5 | Retries (PS-TRANSACTION) | At most two exact retries (three attempts); INPUT never retried | Y |
| D6 | Clock and baud accuracy (SRS-NET-010, ICD-NET-001; both marked "to be confirmed") | Crystal-derived, at most +/-100 ppm; total baud error at most +/-0.5 % per node | Y |
| D7 | Termination and bias (ICD-NET-001: "decided by measurement") | ★ 120 ohm at both trunk ends, selectable on the node; bias at the hub only, values from the transceiver thresholds | See E1. Select typical RJ45 cable impedance |
| | **Timing and safety** | | |
| D8 | Input cadence (SRS-PERF-002, PS-TIMING) | One INPUT with every configured record each 5 ms | 1 ms cadence seems possible using suitable high speed Half-Duplex RS-485 Transceivers like the ISO3088 (it also is isolated for power domain separation between consoles) for improved perceived user latency |
| D9 | Lease and guards (SRS-OWN-009, PS-TIMING) | Lease 100 ms; uncertain-revoke guard 110 ms; neutralisation at most 1 ms (declared per profile); neutral within 103 ms real time | Y |
| D10 | Manual switch time (SRS-OWN-012) | At most 500 ms nominal | Y |
| D11 | Latency (SRS-PERF-001/004/005) | Sample to installation at most 10 ms; after one lost INPUT 12 ms; end-to-end at most 16.7 ms at the 99.9th percentile | Can be improved based on D8. |
| D12 | Fight-stick latency target (SAD-O-007) | Open; ★ same bounds as D11 (mappings, calibration and prompts: E15) | Y |
| D13 | Response window (PS-TIMING; SAD-O-009 = unmeasured processing budget) | Driver off within 20 us; response starts 50 to 250 us after the request; idle guard at least 50 us; timeouts 1.0 ms (short) / 1.5 ms (long). ★ keep 250 us; bring-up measures it | Y |
| D14 | Lease clock error (PS-TIMING) | At most +/-1 % | Y |
| D15 | Feedback (PS-TIMING, PS-SVC-FEEDBACK) | Poll every 10 ms while armed (every cycle permitted); effect duration 1..100 ms | Can be improved as consequence of D8. |
| D16 | Automatic-selection policy (SAD-OWN-001, "P policy values") | Select when exactly one ready adapter is ACTIVE for 500 ms, all others INACTIVE, all status at most 500 ms old; release after 2 s inactive or 500 ms without fresh evidence | Y |
| | **Platform, hub, power** | | |
| D17 | MCU (SRS-HW-005, SAD-P-007) *owner* | RP2350 family, Arm cores only; RP2350A default; RP2350B only where a resource table shows the need; stacked-flash parts allowed | Y (stacked-flash parts preferred) |
| D18 | Margin rule (ICD-CON-001, SRS-STO-006) | No more than 70 % of any resource in the worst all-port combination | Y |
| D19 | Original Xbox adapter (SAD-P-008, ICD-CAP-011) *owner* | Up to four USB device ports, one processor per port plus a gateway (may be one of them) | Y |
| D20 | Hub USB (SAD-P-009, ICD-HUB-001) *owner* | Native controller behind a USB hub IC, at least four downstream ports, switched VBUS with overcurrent detection, 500 mA per port | Y |
| D21 | Hub supply (ICD-HUB-001: "about 3 A, to be confirmed") | ★ External 5 V, at least 3 A (E14) | Y |
| D22 | Power and isolation (SAD-P-010, ICD-PWR-002, ICD-HUB-001) *owner* | Each adapter externally powered; console power sense-only; isolated RS-485 (isolated transceiver and power) at every adapter **and at the hub** (ICD-HUB-001 already requires an isolated transceiver with isolated power and a default-disabled driver); deviations need an approved decision-record entry | Isolated RS-485 is a must have (see D8); Power to the adapter should be provided by the respective console if possible or from the same source as the console (get power from the same DC source as in NES or SNES for example). Adapter's RPN side of the RS485 transceiver is powered by the distributed hub power supply. |
| D23 | Identity (SAD-P-003, PS-TRANSACTION) *owner* | 128-bit vendor UID in locked OTP, printed on a label; session ID from the hardware RNG with health check and persistent-counter fallback | Y |
| D24 | Logic domain (ICD-CAP-002/003, SRS-HW-006) | 3.3 V; external translation and protection on every console-facing signal; no reliance on MCU 5 V tolerance or internal pulls | Y |
| D25 | Translators on open-drain bidirectional lines (ICD-CAP-009: "unless measurement shows ...") | ★ Not used; direction-controlled or discrete open-drain structures are used | Y |
| | **Ports, storage, input, UI** | | |
| D26 | Ports and routes (SAD-P-005, SRS-IN-005) | One virtual controller per port plus, where the profile has one, its memory accessory; at most four routes; no fan-out | Y |
| D27 | Accessory storage (SRS-STO-008, SAD-P-012, ICD-STO-001) *owner* | External SPI/QSPI FRAM, two banks plus select record (X1, E4), write-through, one device per port on a shared SPI bus, RAM only as a non-authoritative cache. Today also "MCU flash only as an approved exception"; ★ **remove that exception** (SRS-STO-008 says contents are not in MCU flash, and neither in-scope accessory needs it). Accessory data is then never dirty: `dirty_resources` stays in STATUS (no wire change), always 0 for accessories | Y |
| D28 | Generic storage, configuration and update transfers (SAD-P-006) | Only in exclusive maintenance (conditional on E3 and C8) | Y |
| D29 | Dreamcast sizing (ICD 8.2 / 8.3: "+4 presence, to be confirmed") | One presence/sense channel per port; ★ keep as the sizing assumption | Y |
| D30 | Accepted USB input (SRS-IN-012, SAD-P-011) | HID gamepads and fight sticks with parseable report descriptors. ★ I specify the minimal HID subset (Generic Desktop game pad or joystick collections; Button page up to 32 buttons; X, Y, Z, Rx, Ry, Rz axes of 8 or 16 bits; hat switch; report IDs; padding) and an acceptance corpus of reference report descriptors by class (gamepad, fight stick, hat-only, 16-bit axes, with and without report IDs) in SRS-V-002, instead of the two named devices | Y |
| D31 | Local selection and indication (SRS-UI-001) | Owner selection and owner / armed-neutral / fault indication, no external computer | Y |
| D32 | Player assignment (SRS-UI-002) | User assigns players to routed ports. ★ full feature; the "fixed player n to port n" allowance goes | Y |
| D33 | Hub display (SRS-UI-003: "should ... initial draft intent") | ★ "shall": display owner, routes and mapping with the console's own button names. No message carries names today (X5), so this needs a new CAPS kind (per combination, short UTF-8 labels for the generic positions it uses, paged by index and bounded; a wire addition I design). Alternative: generic labels only (no wire change; the console-name part of SRS-UI-003 goes) | New proposed solution: hub will have a display to show hub local information only, and each adapter will also have their own display with console specific language and information (i.e. Dreamcast will show VMU units display thus saving RS45 trafic and removing need for PS-SVC-DISPLAY). |
| D34 | Verification parameters (ICD-VER, ICD-STO-001) | 10-minute soak durations (ICD-VER-010/017/018, SRS-V-007); 0.3 V output noise margin (ICD-VER-003, a proposed default a profile may tighten); endurance worked example of one write per ms for ten years (each profile states its own worst-case write rate) | Y |

---

## Part E - Open items and gaps

### E1 - Bus harness: connector, cable, topology (SAD-O-002, ICD-NET-001/002) - **no ★ for the connector**
Today open in ICD-NET-002: connector and pinout, cable rating, allowable voltage offset, shield termination, stub length and hot-plug protection. No power-carrying bus and no RJ45 pinout is selected.

| Item | ★ | Your answer |
|---|---|---|
| Connector | none. Options: (a) shielded RJ45 8P8C - cheap and common, but it looks like Ethernet (accidental connection, passive PoE), so it needs distinct labelling and overvoltage protection on the bus pins; (b) M12 A-coded 5-pin or M8 4-pin - keyed, locking, unambiguous, dearer; (c) other | (a) |
| Topology | Daisy chain, two connectors per node wired straight through inside the node: trunk continuity does not depend on node power; unplugging a cable interrupts the trunk (documented limit); the internal stub from the through-wiring to the transceiver is kept short (I derive the figure from the 2 Mbit/s edge rate) | Accept. |
| Conductors | NET_P and NET_N (one twisted pair); NET_REF kept as a bus-side reference tying the isolated transceivers' bus-side grounds together through a resistor at each node (never a console or adapter ground; the isolators keep it separate); shield; no power on the bus | Power is shared on the bus to power up the RS485 isolated transceiver bus sides. |
| Common-mode offset | Limited to the rated common-mode range of the isolated transceiver class (I state it as a requirement on the part) | Accept. |
| Shield | Bonded to the enclosure at the hub only; at each adapter coupled through a capacitor with no DC path | Accept. |
| Hot-plug | Connecting and disconnecting with the bus powered is allowed: surge protection and series resistance at the bus pins, transmitters default-disabled |  |
| Cable | Shielded twisted pair, 120 ohm nominal | Use RJ45 typical impedance |
| Pinout | I assign it once the connector is chosen | RJ45 |

### E2 - Hub local hardware (ICD-HUB-001 "Local I/O"; SRS-UI-001..003)
ICD-PWR-001 requires the hub resource budget (GPIO, PIO, DMA, interrupts, RAM) to be recorded
in ICD-HUB-001; it is not, because the local I/O is undefined. I compute the budget from your answers.

| Item | ★ | Your answer |
|---|---|---|
| Local controls (owner selection, player assignment, mapping prompts, approvals) | Four buttons: up, down, select, back | Accept. |
| Display | Monochrome graphic 128 x 64 (OLED/LCD class, I2C or SPI), two pages: status and mapping (owner, routes, console button names), and VMU screens | Color LCD screen. No need for VMU screen (see D33). |
| VMU screens (C11) | Up to four 48 x 32 frames in a 2 x 2 grid (96 x 64 at 1x fits the display); shown only when the owner presents VMUs | See D33. |
| Indicators | Three LEDs: power, armed, fault | On screen information is enough. |
| Recovery / boot input | One button (E13) | Accept. |

### E3 - Management access path: who drives STORAGE, CONFIG and DIAGNOSTICS? - **no ★**
The documents define how a memory image or configuration crosses the bus (PS-MAINTENANCE,
PS-SVC-STORAGE, PS-SVC-CONFIG) but not who starts or consumes the transfer: SAD-COMP-HUB
lists a "management client" and the hub has no defined external interface for it. SRS-UI-001
only requires "no external computer" for owner selection and for the owner / armed-neutral /
fault indication; SRS-SUP-001 is open. Local indication stays in every case.
My lean (not a ★): A, because it also carries UID entry (E17) and image updates (C8).
- [ ] A. A PC tool through a hub management port (UART/USB-serial bridge). Needs a hub management interface (connector, framing - the PS framing can be reused - and commands).
- [x] B. A USB flash drive on a hub downstream port: images, configuration and logs as files, driven from the hub's local controls. Needs a USB mass-storage host driver, a filesystem and file layout, and a port: a fifth downstream port, or a player port freed in maintenance (the hub IC has at least four). E7 helps (labels) but is not required. Mass-storage use is independent of C10, which is about input devices.
- [ ] C. Factory and diagnostic use only, over the debug interface (E13); no end-user import or export.
- [ ] D. Remove the network Storage and Configuration services and the MAINTENANCE state: images stay local and are never transferred; configuration changes only by local means. Removes opcodes 0x30, 0x31, 0x40, CAPS kinds 1 and 3, service bits 2 and 3, SRS-STO-003/004 and the SAD-PERSIST-001 transfer text; the cycle-budget rows for management chunks are recomputed. SRS-STO-002 (console-side local access) and the reset-while-dirty protection of SRS-UPD-002 stay. Constraints: requires C8 = C (update uses MAINTENANCE); B5a becomes "fixed by the profile"; diagnostics are reachable only through local indicators (E8) and debug.

### E4 - Persistent media (SAD-O-005, SAD-PERSIST-001 "media policy is O", PS-DISCOVERY)
(1) Where every node keeps its address and configuration, and the hub its roster, assignments and mapping approvals (SRS-CFG-002):
- [ ] ★ MCU flash with a two-sector journal (SRS-STO-008 already allows adapter firmware and configuration in flash). Rules: written only while the node is INHIBITED, UNASSIGNED or in MAINTENANCE, never while armed; programming may stall instruction fetch for up to the sector-erase time, so each profile documents the console-visible effect (idle identity unanswered) or runs its console driver from RAM; the ASSIGN completion window of R10(a) covers the address write. The hub writes only in NO_OWNER or PREPARE.
- [x] A small FRAM or EEPROM on every node (one more part and its GPIO in every profile; no stall at all).
- [ ] Other: ________________

(2) Bank-select record of the accessory FRAM (X1: today it does not fit in the 512 kbit and 2 Mbit parts):
- [ ] ★ The record lives in the adapter's configuration journal (MCU flash); the parts stay 512 kbit (N64) and 2 Mbit (Dreamcast). The bank flip is one journal write after the staged bank is verified; a power loss leaves the old or the new bank, never a mix.
- [x] The next FRAM densities (1 Mbit and 4 Mbit) with a mirrored, CRC-protected record in the spare space.

(3) Accessory FRAM part:
- [x] ★ Specified by requirement, not part number: SPI/QSPI, 3.3 V, endurance at least 10^12 cycles, SPI at least 40 MHz, temperature range covering E10.
- [ ] Name a reference part: ________________

### E5 - Automatic console selection (SRS-OWN-007/008, SAD-O-006, SAD-OWN-001)
(a) Is automatic selection kept?
- [x] ★ Yes: opt-in, enabled from the hub's local controls (default: manual).
- [ ] No (manual selection only). STATUS keeps the `activity` byte for display unless you also remove SRS-OWN-008, in which case the byte goes (a wire change: STATUS response, cycle budget and figures recomputed).

(b) If kept, what do ACTIVE / INACTIVE / UNKNOWN mean? Automatic selection needs every other adapter to be *known* INACTIVE (SAD-OWN-001), so the profiles cannot all be allowed to answer UNKNOWN.
- [x] ★ One generic rule for every profile: ACTIVE = console power sensed present and a valid poll of an emulated port seen within the last 100 ms; INACTIVE = console power sensed absent; UNKNOWN otherwise (no poll yet, or sensing unavailable). Power sensing is then required on every adapter (it is already in the GPIO budget, ICD 8.3).
- [ ] Each profile defines its own evidence (today's wording); automatic selection may be unusable for a profile that reports UNKNOWN.
- [ ] Other numbers: ________________

### E6 - Joining and re-joining after arming (SAD-O-014)
Settled today (SAD-D-010): a removed or replaced device keeps its route; a replacement that supplies every control in the route's validated source masks resumes in place; any other device leaves the record neutral until the routes are replaced. Open: a player with **no route** whose device connects after arming.

(a) Late join:
- [ ] ★ Only on explicit user action (release, ROUTES, ARM of the whole generation, which interrupts every player); never silently; no in-place amendment.
- [ ] Automatically when a device connects (interrupts every player).
- [x] Add an in-place ROUTES amendment while armed (a PS change and a new safety analysis).

(b) Routes for players without a device:
- [ ] ★ No: a route exists only for a player that has a device at ROUTES time.
- [x] Yes: routes are created for every port of the selected console, with a default source mask equal to the route's required controls; a device that supplies them resumes in place (needs the default-mask rule and changes the lossy-approval flow).

### E7 - Port binding of storage resources (SAD-O-011)
- [ ] ★ No: resources stay opaque IDs; the profile gives them meaning (no wire change).
- [x] Yes: add a `port` field to CAPS kind 1 (wire change; useful if E3 = B and the hub labels "player 1 memory card"). Device-wide resources such as configuration read-back stay unbound.

### E8 - Field supportability (SRS-SUP-001)
- [x] ★ Bounded counters, STATUS/DIAGNOSTICS and local fault indicators only (what exists today); SRS-SUP-001 is removed. A user reaches diagnostics only through E3.
- [ ] Add persistent logs and support export (needs hub storage and the E3 path).

### E9 - ESD, EMC, regulatory and electrical safety (SRS-ENV-001; ICD-VER-012 cannot run without it)
- [x] ★ Engineering targets, no certification claim: ESD per IEC 61000-4-2 level 3 (6 kV contact, 8 kV air) on every externally accessible connector (console, USB, bus, power); no emissions, immunity or marking requirement.
- [ ] As above plus emissions and immunity targets: ________________ (for example EN 55032 / EN 55035 class B).
- [ ] Full regulatory compliance for: ________________ (CE / UKCA / FCC).
- [ ] No requirement (ICD-VER-012 is dropped).

Electrical safety (today "not selected"):
- [x] ★ All RPN equipment is low-voltage: 5 V DC from a certified external supply (E14); no mains voltage inside any RPN enclosure; no other electrical-safety standard is claimed.
- [ ] Other: ________________

### E10 - Operating environment (SRS-ENV-002)
- [x] ★ Indoor domestic use; operating 5 to 40 degC, 20 to 80 % RH non-condensing; storage -20 to 60 degC.
- [ ] Other: ________________

### E11 - Cost, size, enclosure (SRS-ENV-003)
- [x] ★ No requirement: SRS-ENV-003 is removed.
- [ ] Targets: ________________

### E12 - Licensing and provenance (SRS-LIC-001)
- [x] ★ Clean-room rule: no console-vendor firmware, BIOS, keys or proprietary code in the repository; console behaviour is implemented from independently written code, public documentation and measurement; third-party code only with a recorded compatible licence; documentation sources listed in the reference register.
- [ ] Other policy: ________________

(The repository has no LICENSE file. The project's own licence is outside the specifications; tell me if you want it recorded.)
I have no idea about licensing and what should be on the LICENSE file. Create one as you see fit for this context.

### E13 - Local recovery and debug access (ICD-DBG-001; PS RESET mode 1)
Today recoverability is required, but the connector, the boot-entry procedure and the production debug policy are open.

(a) Debug and programming connector on every node:
- [x] ★ 3-pin SWD (SWDIO, SWCLK, GND) on a 2.54 mm header or Tag-Connect footprint.
- [ ] Other: ________________

(b) Recovery procedure:
- [x] ★ A recovery input held while power is applied keeps the application from enabling any console-facing output or bus transmitter and presents RECOVERY (STATUS state 5; ownership impossible); the image is restored over SWD with a debug probe; PS RESET mode 1 reboots into the same state. I add a recovery test to ICD-VER (corrupt image, restore, node returns to INHIBITED).
- [ ] Additionally the RP2350 ROM USB bootloader through a service connector on every node (the hub's single USB controller is host-only behind the hub IC, so the hub would need a bypass).

(c) Production debug policy:
- [x] ★ Debug stays enabled (no debug lock, no secure boot). If C8 = A, I specify a locked-debug policy instead.
- [ ] Other: ________________

### E14 - Power supplies (SAD-O-002 "adapter and hub supply units and distribution"; D21, D22)
Today: each adapter is externally powered (SAD-P-010) and the hub takes an external 5 V supply (ICD-HUB-001); nothing defines the adapter input, the connector or the protection; no power on the bus (E1).

| Item | ★ | Your answer |
|---|---|---|
| Adapter input | 5 V DC +/-5 %, at least 1 A; each profile's budget stays within 70 % of it (D18) | See D22. |
| Hub input | 5 V DC, at least 3 A (D21) | Accept. |
| Connector | 5.5 x 2.1 mm barrel, centre-positive, on hub and adapters (cannot be mistaken for a data port); alternative: USB-C power-only |Hub power provided by USB-C connector. Adapter power provided by console controller port power if adequate or external power (see D22). |
| Protection | Reverse-polarity and overcurrent protection on every supply input (today only the hub) | Reverse polarity protection required only when power supply connector is not keyed.|
| Supply units | Certified off-the-shelf 5 V supplies (E9); RPN specifies no supply unit | Standard USB-C phone charger for hub with enough power. |

### E15 - Mapping, calibration and approvals (SAD-O-007 "final button mappings, analog calibration and compatibility prompts")
Per-console mapping tables are profile content (B2). What is left for you:
- (a) Remapping: [ ] ★ the user chooses only among the mapping IDs an adapter advertises; no free remapping. [x] free remapping on the hub (needs a mapping editor and a new wire element).
- (b) Calibration: [ ] ★ automatic - the centre is captured when a device connects, ranges come from the descriptor's logical limits; no calibration screen; dead zones, thresholds and hysteresis are adapter mapping data (SAD-MAP-001). [x] a user calibration routine on the hub.
- (c) Lossy-mapping approvals (SRS-IN-007): [x] ★ asked once per device, route and mapping on the hub display with the local controls, stored in the hub (SRS-CFG-002), asked again when the mapping or the device changes (device identified by VID/PID and serial number when it has one). [ ] asked on every arming.

### E16 - Security posture (SAD section 10; SAD-O-008 "future untrusted administration")
Today: the bus is physically trusted, CRC is not authentication, anyone on the bus can impersonate the hub, and "future security decisions" are deferred.
- [x] ★ Confirm as the definitive posture: physically trusted bus, no authentication or encryption, no exposure outside the installation, update (if C8 is IN) gated by the physical update-enable. The "future decisions" wording goes; SAD section 10's trust and fault-model paragraphs stay.
- [ ] Require authentication of the hub to the nodes: needs key provisioning and management (a large addition; also changes C8).

### E17 - Commissioning workflow (SAD-P-003, PS-DISCOVERY)
Today the hub must be given an adapter's 128-bit UID ("scanned or manually supplied") and one adapter is physically enabled at a time; no document says how the UID gets into the hub. Typing 32 hex characters with four buttons is impractical, and unknown-node discovery is Future (C5).
- [x] A. ★ Discovery of the single enabled node: the hub UI offers "add adapter"; the hub sends DISCOVER_UID with an all-zero UID, and only a node whose commissioning enable is asserted answers (wire change; collision-free because exactly one node is enabled, and two enabled nodes simply produce no valid reply, reported as such); the hub records the UID and address in its roster. HELLO still checks `expected_uid` afterwards.
- [ ] B. UID typed on the hub's local controls.
- [ ] C. UID delivered through the E3 path (PC tool or file); needs E3 = A or B.
- [ ] D. A and C.

### E18 - Atomic installation across processors (X4; Original Xbox adapter)
SRS-IN-008 requires all records of an update to be installed atomically, but a multi-processor adapter forwards them to the secondary processors one at a time over an internal link.
- [x] ★ Relax for multi-processor adapters: whole-set validation still precedes forwarding; installation is atomic per port; a forwarding failure on a port neutralises that port and raises fault 2; the profile bounds the skew between ports (each Xbox port is an independent USB controller, so cross-port coherence has no console-visible meaning).
- [ ] Keep strict atomicity: two-phase staging with a common commit trigger over the internal link (adds a sync line and internal-link time inside the 250 us response window).

---

## Part F - Evidence policy

### F1 - Facts that are unverified today
Many values are labelled "lead", "secondary", "unverified", "to be confirmed" or "to be
re-verified" (console pinouts, levels and power in ICD 8.2 to 8.5 and ICD-STO-001; RP2350
facts such as GPIO counts, USB endpoints, OTP and RNG; peripheral facts in SAD-MAP-002/003),
and two registers are incomplete: ICD-PLAT-001 (datasheet, steppings and errata not recorded)
and ICD-REF-001 (no retrieval dates). A definitive specification must not turn an unknown
into an asserted fact: an unconfirmed console voltage, for example, is a hardware-damage risk.
- [ ] ★ I research public primary sources during the rework (RP2350 datasheet and errata; console documentation where public) and populate ICD-PLAT-001 and ICD-REF-001 with revision and retrieval dates. Supported silicon: only the stepping in current production, with the errata that affect the interfaces and their mitigations. A console electrical fact I cannot confirm from a primary source is **not** stated as a fact: the specification then states what the profile must determine and verify (ICD-VER), and I list the fact for you. The ICD keeps only structural facts (channel counts, directions) that I can confirm.
- [ ] No research now: every unverified value is removed from the specification as a fact and replaced by a profile requirement; ICD-REF-001 becomes a plain reference list; verification happens only through ICD-VER.
- [x] Keep the confidence flags (published / secondary / measured) inside the specification.

### F2 - Golden vectors in the PS (PS section 9 lists "a complete codec vector suite" as an open gate)
- [x] ★ Add a vector appendix: one request and one response (and each error status) for every opcode and subcommand, generated by script and cross-checked with the RPN-RVP Appendix B reference code. Closes the gate.
- [ ] Keep only PS-VECTOR-001.

---

## Part G - Anything else

Constraints, preferences or corrections not covered above:

________________________________________________________________

________________________________________________________________

---

## After you return the form

1. I rework in authority order: SRS, ICD, SAD, PS, then README and the process documents per Part A.
2. Everything that changes a number is recomputed with scripts (CRC-32C and COBS vectors, cycle budget, latency bounds, GPIO and resource tables) and checked against the RPN-RVP Appendix B reference code.
3. PDFs are regenerated; links, anchors and identifiers are checked; a word scan confirms rules R1 to R4.
4. You get a change summary per document, the items I could not apply (with reasons) and the facts I could not confirm from a public source.
5. This form is deleted.

---

## Coverage map (every flagged or open item in the current documents)

| Source item | Covered by |
|---|---|
| SRS-SYS-004 (console roadmap) | B1 |
| SRS-SYS-007 / -008 | D2, D3 |
| SRS-SYS-010, SAD-P-013, SAD-O-015, ICD-CAP-020 | B4 |
| SRS-IN-003 | C2 |
| SRS-IN-008 vs SAD-ADAPT-001 | E18 |
| SRS-IN-012, SAD-P-011, SRS-V-002 "named devices" | C10, D30, R3 |
| SRS-NET-001 ("update") | C8 |
| SRS-OWN-007 / -008, SAD-O-006 | E5, D16 |
| SRS-OWN-009 / -012, SRS-PERF-001 / -002 / -004 / -005 | D8 to D11 |
| SRS-NET-003, SAD-P-001, ICD-NET-001 | D1, D6, D7, E1 |
| SRS-NET-010 | D6 |
| SRS-UPD-001..004, SAD-F-004, SAD-O-008, PS-SVC-UPDATE | C8, E16 |
| SRS-UI-001 / -002 / -003 | D31, D32, D33, E2 |
| SRS-UI-004, SAD-F-006, PS-SVC-DISPLAY | C11 |
| SRS-SUP-001 | E8 |
| SRS-ENV-001 | E9 (including electrical safety), E1 (hot-plug) |
| SRS-ENV-002 / -003 | E10, E11 |
| SRS-LIC-001 | E12 |
| SRS-STO-005..008, SAD-D-009, SAD-P-012, ICD-CAP-018 / -019, ICD-STO-001 | B5, D27, E4, C21 |
| SAD-P-002 | D4 |
| SAD-P-003, PS-DISCOVERY commissioning | D23, E17, R10(a) |
| SAD-P-004 | D8, D9, D13, D15 |
| SAD-P-005 | D26 |
| SAD-P-006 | D28, C6, C8 |
| SAD-P-007 | D17 |
| SAD-P-008, ICD-CAP-011 | D19 |
| SAD-P-009, ICD-HUB-001 | D20, D21, D22, E2 |
| SAD-P-010, ICD-PWR-002 | D22, E14 |
| SAD-O-001 | B3, R3 |
| SAD-O-002, ICD-NET-002 | E1, E14 |
| SAD-O-003 | C1, C10, D30, E2 |
| SAD-O-004, ICD-CON-001, ICD-CAP-013 / -014 / -015 / -016, ICD section 5, ICD 8.4 | B2, B3 |
| SAD-O-005, SAD-PERSIST-001 | E4, C8, E13 |
| SAD-O-007 | D12, E15 |
| SAD-O-009, SAD-O-010, SAD section 3.1, SAD section 10 (sequence) | R3, D13 |
| SAD-O-011 | E7 |
| SAD-O-014 | E6 |
| SAD-F-001 | C1, C2, C3, C4 |
| SAD-F-002 | C5, C6 |
| SAD-F-003 | C7 |
| SAD-F-005 | C9, C10 |
| SAD-F-007..F-013 | C12 to C18 |
| SAD-COMP-HUB "combining devices" | C19 |
| SAD-MAP-002 "digital L2/R2", PS-DATA-INPUT bits 16..31 | C20 |
| SAD-MAP-003 exclusions, ICD-CAP-017, SRS section 2 disclaimers | C21, R2 |
| SAD section 10 trust model | E16 |
| ICD-CAP-002 / -003, SRS-HW-006 | D24 |
| ICD-CAP-009 | D25 |
| ICD-DBG-001, PS RESET mode 1 | E13 |
| ICD-QUAL-001, PS section 9 "open gates", ICD-VER intros | R5, F2 |
| ICD-PLAT-001 (including steppings), ICD-REF-001, "lead / secondary / unverified" wording | F1 |
| ICD-STO-001 bank-select record | X1, E4 |
| ICD-VER-016 | X2 |
| Document headers, SRS section 1 classes, SRS section 10, README, change histories | A1, A2, A3, R1, R4 |
| SAD section 2, SAD section 3 | A4, A5 |
| DEVELOPMENT-GUIDE, RPN-RVP, REVIEW-001 | A6, A7, A8 |
| PS wire version 0.1 | A9 |
