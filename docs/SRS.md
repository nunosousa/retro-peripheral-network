# System Requirements Specification

| Control field | Value |
|---|---|
| Document ID | RPN-SRS |
| Revision | 0.1 |
| Status | Draft - architecture exploration; not a validated baseline |
| Date | 2026-11-18 |
| Companion documents | [RPN-ICD](ICD.md), [RPN-SAD](SAD.md), [RPN-PS](PS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Initial repository draft: two-player architecture, ownership safety, hardware constraints and provisional network profile. |
| 0.1 (2026-11-18) | REVIEW-001 correction cycle: RP2350 platform requirement (HW-005, HW-001 retired), glossary, scope/latency/switch-time/clock/identity/neutralisation/HID requirements, user-interaction and compliance section, verification matrix updates; RPN-EIC removed from the companion list (deprecated). |

## 1. Purpose and interpretation

RPN connects modern input devices to unmodified original consoles through a
central hub and console interface adapters. Authentic console-facing signalling
is produced locally by each adapter, never by timing packets across the network.

In these documents, **shall** denotes a requirement; **should** denotes a
recommendation; **may** denotes permission. A requirement on a provisional
profile is conditional on adopting that profile. It is not evidence that the
profile has been validated.

Classification:

- **C - Confirmed:** project scope or architectural principle supplied by the owner.
- **D - Derived:** necessary engineering constraint proposed to satisfy C requirements.
- **P - Provisional:** candidate design or numerical acceptance threshold requiring validation.
- **O - Open:** unresolved decision; no implied default.
- **F - Future:** not required for initial acceptance.
- **Retired:** identifier withdrawn and never reused; the row stays for traceability.

Stable identifiers are not reused after retirement. `SRS-*` identifies
requirements, `ICD-*` interfaces (including interface capabilities `ICD-CAP-*`
and verification entries `ICD-VER-*`), `SAD-*` architectural elements and `PS-*`
protocol elements. Message opcodes additionally have fixed numeric values.
The PS owns wire definitions, the ICD electrical definitions, the SAD software
behaviour and the SRS acceptance criteria. Other documents reference these owners
rather than independently redefining them. The retired identifiers `EIC-VER-001`
to `EIC-VER-014` and the `RPN-EIC` document are not reused; see the
[deprecated EIC](EIC.md) for the mapping to the ICD.

### Glossary

| Term | Meaning in these documents |
|---|---|
| Hub | The single master device that acquires modern input, owns routing and ownership policy and masters the bus |
| Adapter | One console interface device: the network node that represents one console instance (SRS-SYS-006) |
| Node | Any addressed bus participant (adapters in profile 0.1; the hub is the master) |
| Console port | A physical controller connector of the original console |
| Port (protocol) | A PS `port` ID (0 or 1) naming one emulated console port of an adapter; the profile maps it to a physical connector |
| Player | One of two independent player contexts in the hub (player 0, player 1) |
| Route | One player-to-port assignment with a selected virtual peripheral and mapping (SRS-IN-005); at most two per owner |
| Endpoint | A route as seen by the adapter: one active player/port record (so "two active endpoints" means two active routes) |
| Channel | One electrical signal path between the adapter logic and a console connector pin (ICD-CAP) |
| Owner | The one adapter currently authorised to expose live input (ownership); "project owner" means the person approving scope and maturity |
| Profile | A console-specific interface and behaviour definition (ICD-CON-001 supplement); also used for the provisional network profile |

Console names used in these documents: NES, SNES, Nintendo 64 (N64), GameCube,
Mega Drive, Saturn, Dreamcast, PlayStation, PlayStation 2 and Original Xbox.
Spelling convention: "analog" for signal types; other prose keeps the existing
British "-ise" forms.

## 2. Scope and deployment

| ID | Class | Requirement |
|---|---|---|
| SRS-SYS-001 | C | RPN shall separate input acquisition and routing in the hub from console-specific protocol, peripheral and accessory emulation in adapters. |
| SRS-SYS-002 | C | RPN shall support two simultaneous independent player contexts and explicit player-to-console-port routing. |
| SRS-SYS-003 | C | Connecting RPN shall require no permanent modification to a target console. |
| SRS-SYS-004 | C | The target family roadmap shall include NES, SNES, N64, GameCube, Mega Drive, Saturn, Dreamcast, PlayStation, PlayStation 2 and Original Xbox. Inclusion in this roadmap shall not be represented as implemented or electrically validated support. |
| SRS-SYS-005 | D | Each supported console profile shall specify electrical compatibility, supported peripheral modes, mapping limitations, accessory behaviour and validation evidence before use on original hardware. |
| SRS-SYS-006 | D | An adapter shall represent one console instance and its supported controller ports. Multiple connectors or processors may be required inside that adapter. |
| SRS-SYS-007 | P | The initial network profile shall support one hub and up to 31 addressed adapters, two routed player records on one owner and at most two active routes (endpoints). This is an address/resource bound, not a validated cable or node-loading claim. |
| SRS-SYS-008 | P | The typical installation shall be up to 10 adapters on a trunk of up to 15 m; the first harness calculation (`ICD-NET-002`) shall use these figures. Larger installations up to the SRS-SYS-007 address bound require their own measured qualification. |
| SRS-SYS-009 | D | An adapter shall emulate at most the two console ports that can be routed (SRS-SYS-002/007). Further physical ports of a console are left unpopulated or unconnected, so the console sees no controller there; four-port and multitap support is Future (`SAD-F-001`). |

Two simultaneous players is not a promise of multitap emulation, arbitrary
four-player accessories, or two active consoles. Multiple consoles may remain
powered while only one console owns player input. A supported console need not
emulate every peripheral ever sold for it. Exact console variants and peripheral
coverage remain O items in [SAD section 3](SAD.md#3-decision-register).

## 3. Input and peripheral requirements

| ID | Class | Requirement |
|---|---|---|
| SRS-IN-001 | C | The hub shall represent generic control positions and functions, not console-specific button names or console protocol commands. |
| SRS-IN-002 | C | The input model shall accommodate buttons, directional controls, sticks, triggers, steering and pedal axes, with explicit capability and validity information. |
| SRS-IN-003 | C | Initial physical device classes shall include gamepads and arcade fight sticks. Wheel/pedal representation shall be reserved; actual device support shall be advertised rather than inferred. |
| SRS-IN-004 | D | Physical-device capabilities and virtual-peripheral capabilities shall use separate descriptors. The hub shall not assume one implies the other. |
| SRS-IN-005 | D | Every active route shall identify a player, adapter, port, selected virtual peripheral and mapping configuration. Multiple active routes shall not target the same port or duplicate a player in the initial profile. |
| SRS-IN-006 | D | The adapter shall apply a documented console-local mapping, including button layout, axis ranges, dead zones, inversion, analog-to-digital thresholds, hysteresis and unsupported-control behaviour. |
| SRS-IN-007 | D | Missing or invalid controls shall resolve to the generic neutral state; disconnected devices shall not leave latched active controls. Mapping to a peripheral unable to represent required controls shall require an explicit user-visible compatibility decision. |
| SRS-IN-008 | D | The adapter shall install both player records in a two-port update atomically and shall reject the whole update if any record is invalid. Each console transaction shall read a coherent local snapshot. |
| SRS-IN-009 | D | Adapter console timing shall remain independent of network service latency, flash writes and hub scheduling. Unsupported simultaneous peripheral combinations shall be rejected before arming. |
| SRS-IN-010 | D | Input-device replacement, mapping changes and peripheral changes shall inhibit the affected routes until validation and a fresh snapshot complete. |
| SRS-IN-011 | D | Every console profile shall declare a default idle peripheral identity presented to its console while the adapter is inhibited or configured, and shall state whether a peripheral change is allowed while the console is running. A route selects mapping, not identity: unless the profile declares live identity change as measured and safe, arming shall not change the identity the console sees. |
| SRS-IN-012 | P | In the first increment the hub shall accept USB HID gamepads and arcade fight sticks whose report descriptors it can parse. Devices needing console-specific protocols or authentication (for example Xbox 360/One, PlayStation 4/5 or Nintendo Switch controllers) are Future (`SAD-F-005`); the first two concrete devices are recorded under `SAD-O-010`. |

Generic controls and neutral values are defined by `PS-DATA-INPUT`, not by
Nintendo or Sony naming. Adapter mapping is console-specific; the hub can select
opaque advertised mapping IDs without understanding their console semantics.
User-facing descriptions may originate from adapter metadata or a console-aware
configuration tool outside the hub's acquisition/routing core.

## 4. Ownership and safe transitions

| ID | Class | Requirement |
|---|---|---|
| SRS-OWN-001 | C | The hub shall distinguish selection of one console owner from assignment of the two players to that console's ports. |
| SRS-OWN-002 | D | At most one adapter shall be authorised to expose live player input at a time. Non-owners may continue console protocol exchanges but shall expose neutral controls or a profile-defined disconnected state. |
| SRS-OWN-003 | D | Boot, reset, expired ownership, input loss, invalid configuration and firmware maintenance shall leave live controls inhibited. |
| SRS-OWN-004 | D | Ownership transfer shall neutralise the old owner before enabling a new owner, using acknowledgement or expiration of a bounded lease; lack of response shall never be treated as successful revocation. |
| SRS-OWN-005 | D | Session and route-generation checks shall reject delayed input and commands from previous ownership configurations. |
| SRS-OWN-006 | D | Manual selection shall be authoritative but shall not bypass readiness, compatibility or transition safety checks. Conflicting activity shall not cause automatic ownership oscillation. |
| SRS-OWN-007 | D | Automatic selection shall be opt-in. It shall select only one uniquely eligible console when no owner exists, and shall not preempt an existing owner. |
| SRS-OWN-008 | D | Console activity detection shall distinguish active, inactive and unknown; an adapter unable to prove activity shall report unknown rather than guessing. |
| SRS-OWN-009 | P | Loss of fresh authorised input shall produce neutral controls within 103 ms real time of the last accepted arm/input renewal, including clock error and in-flight console completion. The proposed mechanism is a 100 ms local lease plus at most 1 ms local neutralisation delay. |
| SRS-OWN-010 | D | Recovery from bus loss, hub reboot or console reset shall require a deliberate re-arming procedure and fresh input; persisted routing alone shall not restore live controls. |
| SRS-OWN-011 | D | Feedback shall be routed only to the physical device currently bound to the originating player/port/generation. Ownership loss, device loss or feedback expiry shall stop effects. |
| SRS-OWN-012 | P | A manual ownership switch (selection request to the new owner accepting live input) shall complete within 500 ms nominal, including the case where the old owner's revoke acknowledgement is lost and the 110 ms guard applies. |
| SRS-OWN-013 | D | Every console profile shall declare the maximum time (`neutralisation_bound_us`) within which neutral controls are visible to its console after an inhibit, including any in-flight console transaction, and shall demonstrate it by measurement at the console connector. A profile that cannot meet the global 1 ms bound of SRS-OWN-009 shall not be approved with the provisional lease and transfer timing. |

These requirements apply to controls and feedback. They do not forbid an
inactive console from reading its own accessory storage or an adapter from
answering identification polls. Storage integrity and power remain separate
constraints. Physical failure or defective firmware cannot be made safe merely
by a bus lease; hardware watchdogs and validation are also required.

## 5. Network and management

| ID | Class | Requirement |
|---|---|---|
| SRS-NET-001 | C | The shared network shall remain console-independent and support discovery, addressing, versioning, capabilities, input, feedback, status, diagnostics, configuration, storage, update and controlled reset through advertised operations. |
| SRS-NET-002 | D | A node shall advertise only implemented services and peripheral combinations. Unsupported services shall return explicit errors without side effects. |
| SRS-NET-003 | P | The initial bus shall use one master, half-duplex RS-485 at 1 Mbit/s as defined provisionally by `ICD-NET-001` and RPN-PS. Only the addressed node shall respond to a request. |
| SRS-NET-004 | D | Commissioning shall prevent simultaneous replies by unassigned nodes; bus collision detection shall not be assumed reliable. |
| SRS-NET-005 | D | Frames shall have length bounds, integrity checking, source/destination validation and bounded parser recovery. State-changing operations shall have defined retry and duplicate behaviour. |
| SRS-NET-006 | D | Bulk storage, configuration and update operations shall not starve input renewal or violate local console timing. |
| SRS-NET-007 | D | Timeout, malformed frame, unsupported version, queue overflow, storage failure and update failure shall be observable through bounded counters, explicit status or a local diagnostic indicator where communication is unavailable. |
| SRS-NET-008 | D | Recovery shall not depend on an unbounded retry loop; retries and backoff shall be bounded, and persistent failure shall inhibit live input. |
| SRS-NET-009 | D | Version negotiation shall precede normal operation. A common major version and supported minor profile shall be required before arming. |
| SRS-NET-010 | D | Every node shall derive its UART baud rate and lease timing from a crystal or equivalent-accuracy oscillator of at most +/-100 ppm (value to be confirmed); internal RC oscillators shall not generate the bus baud rate. Each node's total baud error (oscillator plus divider granularity) shall stay within the budget in `ICD-NET-001`. The +/-1 % lease-clock bound of `PS-TIMING` is separate and deliberately looser. |

Discovery in Revision 0.1 is intentionally a commissioning-assisted process,
not unrestricted plug-and-play broadcast enumeration. See `PS-DISCOVERY`.

## 6. Accessory storage, configuration and updates

| ID | Class | Requirement |
|---|---|---|
| SRS-STO-001 | C | Console-specific accessory semantics shall remain in the adapter. Examples include N64 Controller/Rumble Pak selection and Dreamcast VMU features. Support for one feature shall not imply complete accessory emulation. |
| SRS-STO-002 | D | Console-facing storage accesses shall complete from local resources without synchronous network round trips. Media geometry, write latency, endurance, recovery and accessory completeness shall be documented per profile. |
| SRS-STO-003 | D | Network storage export shall provide an explicit consistency policy. Network writes shall require exclusive maintenance access, neutral controls and a disconnected or otherwise safely quiesced console storage interface. |
| SRS-STO-004 | D | A successful persistent-write response shall mean durable completion according to a documented power-fail policy. A timeout shall be treated as indeterminate, not as proof that no write occurred. |
| SRS-CFG-001 | D | Configuration changes shall be validated and applied as complete configurations. Failed writes or validation shall preserve the previous valid configuration and report failure. |
| SRS-CFG-002 | D | The hub shall persist its roster (UID and intended address per adapter), player assignments and recorded mapping approvals across power cycles. Persisted configuration shall never by itself restore live controls (SRS-OWN-010). |
| SRS-UPD-001 | D | Updates shall check image compatibility and integrity before activation, remain inhibited, and provide a documented recoverable interruption path. CRC alone shall not be described as authentication. |
| SRS-UPD-002 | D | Updates and resets shall be refused while accessory data is dirty unless safe persistence is completed first; destructive override is outside the initial protocol. |
| SRS-UPD-003 | D | A node lacking safe update storage, bootloader recovery or flash/console scheduling shall not advertise network firmware update. |
| SRS-UPD-004 | F | Network firmware update, including any secure-boot, signing, anti-rollback or OTP policy, is not required for the first prototype. When addressed it requires an update-profile supplement with a prototype/production distinction so development boards are never irreversibly locked by accident (`SAD-F-004`). |

## 7. Hardware, performance and quality

| ID | Class | Requirement |
|---|---|---|
| SRS-HW-001 | Retired | **Retired 2026-11-18** (REVIEW-001, RR-001-001); superseded by SRS-HW-005. The identifier is not reused. |
| SRS-HW-002 | D | Console pins shall not be directly connected to incompatible MCU voltage domains. Every profile shall define power-off behaviour, level translation, drive mode and contention prevention. |
| SRS-HW-003 | D | Console supplies shall not be tied together or back-powered through adapter or network connections. Grounding/isolation and fault protection shall be explicit before hardware connection. |
| SRS-HW-004 | D | Two-player support shall be validated with both physical-device USB host load and both console-port timing engines active, including permitted accessory traffic. |
| SRS-HW-005 | C | The hub and every adapter processor shall be members of the RP2350 family, unless a documented, owner-approved exception exists under `SAD-D-004`. |
| SRS-HW-006 | D | No console-facing signal shall rely on MCU-side 5 V tolerance or on internal MCU pull-up/pull-down resistors. Voltage adaptation, pull-up ownership and protection shall be provided by external components (`ICD-CAP-003`). |
| SRS-PERF-001 | P | Under the normal profile below, elapsed time from a complete normalised sample becoming available at the hub to atomic installation at the owner shall not exceed 10 ms. USB/Bluetooth acquisition and console polling are outside this interval and shall be measured separately. |
| SRS-PERF-002 | P | The hub shall schedule a two-player input exchange every 5 ms while armed. Traffic admission shall reserve the worst-case exchange time, not just average bandwidth: a non-input exchange shall start only if its worst-case timeout path ends before the next input slot (`PS-TIMING`). |
| SRS-PERF-003 | D | Each console profile shall declare and meet its own measured response and jitter limits under maximum supported load. No universal console timing number is assumed. |
| SRS-PERF-004 | P | End-to-end added latency, from the hub receiving a device report to the adapter having installed the corresponding snapshot, shall be at most 16.7 ms (one 60 Hz frame) at the 99.9th percentile, with the maximum reported separately. Budget components: hub processing at most 1 ms; hub sample availability to installation at most 10 ms (SRS-PERF-001). The device's own report interval and the console's polling phase are excluded from the budget but reported in the end-to-end measurement. A tighter target for fight sticks is open (`SAD-O-007`). |
| SRS-PERF-005 | P | If exactly one INPUT exchange is lost, corrupted or times out, the next scheduled exchange shall carry the newest sample (an INPUT is never retried with a stale sample) and that sample shall be installed within 12 ms of becoming available. SRS-PERF-001 (10 ms) applies to the normal profile without link errors. |
| SRS-REL-001 | D | Firmware shall use bounded buffers, queues, retries and allocation. Resource exhaustion shall report a fault and preserve neutral-input and storage safety. |
| SRS-REL-002 | D | Watchdog recovery shall return to inhibited state without exposing stale input or partially committed configuration. |
| SRS-MNT-001 | C | Common networking, services, configuration, diagnostics and update policy shall be reusable without console-specific dependencies. |
| SRS-MNT-002 | D | Console drivers shall declare resource and timing requirements; reuse shall not require identical low-level execution models across consoles. |
| SRS-MNT-003 | D | Protocol codecs, routing, lease handling and mapping shall be testable independently of physical hardware, supplemented by hardware-in-loop tests. |
| SRS-EXT-001 | D | New console drivers shall not require changes to generic hub input acquisition or the base framing protocol. New service schemas shall be versioned and bounded. |

The provisional normal profile is: one bus, one owner, two player records,
31 or fewer commissioned adapters, no link errors, supported device/report rates,
validated console-driver resource load and bulk traffic admitted by the scheduler.
It does not assert fault-free timing during a bus outage. Faults are governed by
the lease limit. Normal operation and fault-containment limits must both be tested.

## 8. User interaction, operations and compliance

| ID | Class | Requirement |
|---|---|---|
| SRS-UI-001 | P | The hub shall provide local physical means, with no external computer required, to select the console owner and to see the owner, armed/neutral state and any persistent fault. For the first prototype a physical selector and indicators are sufficient. |
| SRS-UI-002 | P | The hub shall let the user assign the two players to the routed ports. The first prototype may use a fixed player 0 -> port 0, player 1 -> port 1 assignment. |
| SRS-UI-003 | P | Initial draft intent: the hub should have a small display showing the active owner, routes and button mapping using the console's own button names. Those names are adapter-supplied metadata (SAD-MAP-001); the hub core keeps generic positions only (SRS-IN-001). |
| SRS-UI-004 | F | Showing the Dreamcast VMU screen on the hub display. It needs a new service for adapter-captured VMU display data, which is not in PS 0.1 (`SAD-F-006`); generic storage does not imply it (SRS-STO-001). |
| SRS-SUP-001 | O | Field supportability beyond bounded counters (persistent logs, support export, diagnostics access) is not decided. |
| SRS-ENV-001 | O | EMC, ESD, regulatory and electrical-safety standards applicable to the hub, adapters, supplies and harness are not selected. Each ICD design review shall list the candidate standards. |
| SRS-ENV-002 | O | Operating environment (temperature, humidity, installation location) is not decided. |
| SRS-ENV-003 | O | Cost, size and enclosure constraints are not decided. |
| SRS-LIC-001 | O | Licensing and provenance policy for any console-derived code, protocol documentation or data is not decided; no console firmware or proprietary code shall be copied into the repository before it is. |

## 9. Verification and traceability

Inspection (I), software test (T), hardware measurement (H) and fault injection
(F) are distinct evidence types. All entries below are planned; none is claimed
as passing merely by publication of this draft.

| Verification ID | Requirements | Method and acceptance evidence | Design references |
|---|---|---|---|
| SRS-V-001 | SYS-001..002, SYS-004..009, MNT-001..003, EXT-001 | I/T: dependency checks; add a mock adapter without changing hub core; inventory supported profiles versus roadmap; check that no adapter profile exposes more than two console ports | `SAD-COMP-*`, `ICD-CON-001` |
| SRS-V-002 | IN-001..012, SYS-002 | T/H: two distinct devices, independent button/axis sweeps, unsupported mapping rejection, disconnects and simultaneous port reads; no cross-player leakage or torn snapshots; two named HID devices enumerate and parse; no identity change visible at the console when arming | `PS-DATA-INPUT`, `SAD-MAP-001`, `SAD-MAP-002` |
| SRS-V-003 | OWN-001..013 | T/F/H: simultaneous console activity, manual switches (switch time within 500 ms nominal), lost revoke reply, delayed frames, counter exhaustion and rollover to a new session, node/hub reset; no overlap of authorised live input; neutral within 103 ms real time of last renewal; per-profile neutralisation bound measured at the console connector | `SAD-OWN-001`, `PS-OWNERSHIP`, `ICD-VER-016` |
| SRS-V-004 | NET-001..010, REL-001 | T/F: golden codecs, corrupt/truncated/oversize frames, duplicates, address conflicts, incompatible versions, queue saturation and retry exhaustion; commissioning retry after lost ASSIGN reply; persisted-address boot; bounded recovery and explicit diagnostics; baud-error margin measured | `PS-FRAME`, `PS-TRANSACTION`, `PS-DISCOVERY`, `ICD-VER-017` |
| SRS-V-005 | STO-001..004, CFG-001..002, UPD-001..003, REL-002 | T/F/H: remove power at each persistence/update stage; verify old/new valid state or documented recovery mode, no acknowledged data loss, no live input during maintenance; configuration commit with power loss and with a lost COMMIT acknowledgement (`PS-SVC-CONFIG`); hub roster/assignment persistence without restoring live controls | `PS-SVC-STORAGE`, `PS-SVC-CONFIG`, `PS-SVC-UPDATE`, `SAD-PERSIST-001` |
| SRS-V-006 | HW-002..006, PERF-003 | I/H: signed-off per-console pin/timing profiles, powered/unpowered fault cases, oscilloscope and logic-analyser captures under two-port/accessory load; the ICD verification entries `ICD-VER-001..020` with their pass criteria; RP2350 datasheet/errata register completed | `ICD-CON-001`, `ICD-CAP-*`, `ICD-VER-*`, `ICD-QUAL-001` |
| SRS-V-007 | PERF-001..002, PERF-004..005, NET-006 | T/H: timestamp sample availability and snapshot installation for at least 10 minutes of full two-player traffic plus admitted management load; every sample selected for transmission installed within 10 ms in the normal profile; end-to-end added latency at the 99.9th percentile and maximum; a single injected lost INPUT installed within 12 ms with no stale retry; report overwritten sample count separately | `PS-TIMING`, `SAD-SCHED-001` |
| SRS-V-008 | OWN-011, NET-007..008 | T/F: feedback replay, queue overflow, device swap, expiry and link loss; no misrouted/latched effects and visible error counters; feedback polled at its specified cadence | `PS-SVC-FEEDBACK`, `SAD-FB-001` |
| SRS-V-009 | SYS-003 | I/H: connector-only attachment with no soldering, cutting or permanent change to the console; a reversible fixture; the console and its original controller restored to original function after removal | `ICD-CON-001`, `ICD-PWR-002` |
| SRS-V-010 | UI-001..003, CFG-002 | I/T/demo: local owner selection, player assignment and fault indication without an external computer; display content comes from adapter metadata; power-cycle restores roster but not live controls | `SAD-COMP-HUB` |

For `SRS-PERF-001`, intermediate device samples may be coalesced before the
next scheduled snapshot, but the newest available sample at that scheduling
boundary shall be included. A sample that remains the latest shall meet 10 ms;
coalescing must not be used to conceal an unbounded backlog or dropped button
transitions. Very short pulses below the sample/snapshot interval are a known
limitation, to be evaluated before claiming suitability for a particular game.

Requirements of class O or F (SRS-UI-004, SRS-SUP-001, SRS-ENV-*, SRS-LIC-001,
SRS-UPD-004) have no verification entry until they are decided or scheduled.

## 10. Open scope and maturity gates

See the authoritative [SAD decision register](SAD.md#3-decision-register).
Bluetooth, actual wheel drivers, multitaps and four-port consoles, secure remote
administration, network firmware update and additional simultaneous players are
future possibilities. Console accessory
coverage is selected per profile; VMU display/audio/clock and Xbox authentication
or other compatibility constraints must not be assumed solved by generic storage.

A first hardware prototype requires an approved electrical profile and a bus
connector/power decision. A first functional demonstration requires one proven
console driver, safe ownership and two-player timing evidence. A stable protocol
baseline additionally requires codec vectors and interoperability testing.
All four documents remain Revision 0.1 until the owner explicitly approves a
maturity change.
