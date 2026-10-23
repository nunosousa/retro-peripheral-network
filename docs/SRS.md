# System Requirements Specification

| Control field | Value |
|---|---|
| Document ID | RPN-SRS |
| Revision | 0.1 |
| Status | Draft - architecture exploration; not a validated baseline |
| Date | 2026-10-23 |
| Companion documents | [RPN-ICD](ICD.md), [RPN-SAD](SAD.md), [RPN-PS](PS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Initial repository draft: two-player architecture, ownership safety, hardware constraints and provisional network profile. |

## 1. Purpose and interpretation

RPN connects modern input devices to unmodified original consoles through a
central hub and console interface adapters. Authentic console-facing signalling
is produced locally by each adapter, never by timing packets across the network.
No prior engineering specifications existed in this repository at this review.

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

Stable identifiers are not reused after retirement. `SRS-*` identifies
requirements, `ICD-*` interfaces, `SAD-*` architectural elements and `PS-*`
protocol elements. Message opcodes additionally have fixed numeric values.
The PS owns wire definitions, the ICD electrical definitions, the SAD software
behaviour and the SRS acceptance criteria. Other documents reference these owners
rather than independently redefining them.

## 2. Scope and deployment

| ID | Class | Requirement |
|---|---|---|
| SRS-SYS-001 | C | RPN shall separate input acquisition and routing in the hub from console-specific protocol, peripheral and accessory emulation in adapters. |
| SRS-SYS-002 | C | RPN shall support two simultaneous independent player contexts and explicit player-to-console-port routing. |
| SRS-SYS-003 | C | Connecting RPN shall require no permanent modification to a target console. |
| SRS-SYS-004 | C | The target family roadmap shall include NES, SNES, N64, GameCube, Mega Drive, Saturn, Dreamcast, PlayStation, PlayStation 2 and original Xbox. Inclusion in this roadmap shall not be represented as implemented or electrically validated support. |
| SRS-SYS-005 | D | Each supported console profile shall specify electrical compatibility, supported peripheral modes, mapping limitations, accessory behaviour and validation evidence before use on original hardware. |
| SRS-SYS-006 | D | An adapter shall represent one console instance and its supported controller ports. Multiple connectors or processors may be required inside that adapter. |
| SRS-SYS-007 | P | The initial network profile shall support one hub and up to 31 addressed adapters, two routed player records on one owner and at most two active input endpoints. This is an address/resource bound, not a validated cable or node-loading claim. |

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
| SRS-UPD-001 | D | Updates shall check image compatibility and integrity before activation, remain inhibited, and provide a documented recoverable interruption path. CRC alone shall not be described as authentication. |
| SRS-UPD-002 | D | Updates and resets shall be refused while accessory data is dirty unless safe persistence is completed first; destructive override is outside the initial protocol. |
| SRS-UPD-003 | D | A node lacking safe update storage, bootloader recovery or flash/console scheduling shall not advertise network firmware update. |

## 7. Hardware, performance and quality

| ID | Class | Requirement |
|---|---|---|
| SRS-HW-001 | C | RP2040 shall be evaluated as the starting platform, not mandated where USB resources, peripheral timing, memory or electrical constraints require alternatives. |
| SRS-HW-002 | D | Console pins shall not be directly connected to incompatible MCU voltage domains. Every profile shall define power-off behaviour, level translation, drive mode and contention prevention. |
| SRS-HW-003 | D | Console supplies shall not be tied together or back-powered through adapter or network connections. Grounding/isolation and fault protection shall be explicit before hardware connection. |
| SRS-HW-004 | D | Two-player support shall be validated with both physical-device USB host load and both console-port timing engines active, including permitted accessory traffic. |
| SRS-PERF-001 | P | Under the normal profile below, elapsed time from a complete normalised sample becoming available at the hub to atomic installation at the owner shall not exceed 10 ms. USB/Bluetooth acquisition and console polling are outside this interval and shall be measured separately. |
| SRS-PERF-002 | P | The hub shall schedule a two-player input exchange every 5 ms while armed. Traffic admission shall reserve the worst-case exchange time, not just average bandwidth. |
| SRS-PERF-003 | D | Each console profile shall declare and meet its own measured response and jitter limits under maximum supported load. No universal console timing number is assumed. |
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

## 8. Verification and traceability

Inspection (I), software test (T), hardware measurement (H) and fault injection
(F) are distinct evidence types. All entries below are planned; none is claimed
as passing merely by publication of this draft.

| Verification ID | Requirements | Method and acceptance evidence | Design references |
|---|---|---|---|
| SRS-V-001 | SYS-001..007, MNT-001..003, EXT-001 | I/T: dependency checks; add a mock adapter without changing hub core; inventory supported profiles versus roadmap | `SAD-COMP-*`, `ICD-CON-001` |
| SRS-V-002 | IN-001..010, SYS-002 | T/H: two distinct devices, independent button/axis sweeps, unsupported mapping rejection, disconnects and simultaneous port reads; no cross-player leakage or torn snapshots | `PS-DATA-INPUT`, `SAD-MAP-001` |
| SRS-V-003 | OWN-001..011 | T/F/H: simultaneous console activity, manual switches, lost revoke reply, delayed frames, counter wrap, node/hub reset; no overlap of authorised live input; neutral within 103 ms real time of last renewal | `SAD-OWN-001`, `PS-OWNERSHIP` |
| SRS-V-004 | NET-001..009, REL-001 | T/F: golden codecs, corrupt/truncated/oversize frames, duplicates, address conflicts, incompatible versions, queue saturation and retry exhaustion; bounded recovery and explicit diagnostics | `PS-FRAME`, `PS-TRANSACTION`, `PS-DISCOVERY` |
| SRS-V-005 | STO-001..004, CFG-001, UPD-001..003, REL-002 | T/F/H: remove power at each persistence/update stage; verify old/new valid state or documented recovery mode, no acknowledged data loss, no live input during maintenance | `PS-SVC-STORAGE`, `PS-SVC-UPDATE`, `SAD-PERSIST-001` |
| SRS-V-006 | HW-001..004, PERF-003 | I/H: signed-off per-console pin/timing profiles, powered/unpowered fault cases, oscilloscope and logic-analyser captures under two-port/accessory load | `ICD-CON-001`, `ICD-QUAL-001` |
| SRS-V-007 | PERF-001..002, NET-006 | T/H: timestamp sample availability and snapshot installation for at least 10 minutes of full two-player traffic plus admitted management load; every sample selected for transmission installed within 10 ms; report overwritten sample count separately | `PS-TIMING`, `SAD-SCHED-001` |
| SRS-V-008 | OWN-011, NET-007..008 | T/F: feedback replay, queue overflow, device swap, expiry and link loss; no misrouted/latched effects and visible error counters | `PS-SVC-FEEDBACK`, `SAD-FB-001` |

For `SRS-PERF-001`, intermediate device samples may be coalesced before the
next scheduled snapshot, but the newest available sample at that scheduling
boundary shall be included. A sample that remains the latest shall meet 10 ms;
coalescing must not be used to conceal an unbounded backlog or dropped button
transitions. Very short pulses below the sample/snapshot interval are a known
limitation, to be evaluated before claiming suitability for a particular game.

## 9. Open scope and maturity gates

See the authoritative [SAD decision register](SAD.md#3-decision-register).
Bluetooth, actual wheel drivers, multitaps, secure remote administration and
additional simultaneous players are future possibilities. Console accessory
coverage is selected per profile; VMU display/audio/clock and Xbox authentication
or other compatibility constraints must not be assumed solved by generic storage.

A first hardware prototype requires an approved electrical profile and a bus
connector/power decision. A first functional demonstration requires one proven
console driver, safe ownership and two-player timing evidence. A stable protocol
baseline additionally requires codec vectors and interoperability testing.
All four documents remain Revision 0.1 until the owner explicitly approves a
maturity change.
