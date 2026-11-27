# System Requirements Specification

| Control field | Value |
|---|---|
| Document ID | RPN-SRS |
| Revision | 0.2 |
| Status | Baseline for review |
| Date | 2026-11-27 |
| Companion documents | [RPN-ICD](ICD.md), [RPN-SAD](SAD.md), [RPN-PS](PS.md), [RPN-AFS](AFS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Repository baseline: architecture, ownership safety, hardware constraints and network profile. |
| 0.1 (2026-11-18) | Correction cycle: RP2350 platform requirement (HW-005, HW-001 withdrawn), glossary, scope, latency, switch-time, clock, identity, neutralisation and HID requirements, user-interaction and compliance section, verification matrix updates. |
| 0.1 (2026-11-18) | Bus rate raised to 2 Mbit/s and typical trunk set to less than 5 m (SRS-NET-003, SRS-SYS-008); section 10 pointed to the peripheral catalogue. |
| 0.1 (2026-11-18) | Memory-card accessory storage made an adapter responsibility with a per-profile memory-resource determination (SRS-STO-005..006, SRS-V-005). |
| 0.1 (2026-11-18) | Memory-card scope set to controller-port accessories (N64 Controller Pak, Dreamcast VMU); SRS-STO-007 withdrawn. |
| 0.1 (2026-11-18) | Emulated memory-card contents held in storage external to the MCU (SRS-STO-008, SRS-V-005). |
| 0.1 (2026-11-24) | Player count raised from two to four: four player contexts and up to four routed ports per adapter (SRS-SYS-002, SYS-007, SYS-009), multitap emulation per profile (SRS-SYS-010), neutral record for a removed device (SRS-IN-010, IN-013), idle pad on unrouted ports (SRS-IN-014); glossary and verification updated. |
| 0.1 (2026-11-25) | Identifier and ownership paragraph (section 1) cleaned of obsolete cross-references; no requirement changed. |
| 0.2 (2026-11-27) | Specification baseline: classes F and D only; consoles, peripherals and multitaps fixed (SYS-004, SYS-010..012); 1 ms input cadence at 8 Mbit/s with latency bounds of 2, 3 and 4 ms (NET-003, PERF-001/002/004/005); pressure buttons, pointers, keyboards, wheels, force feedback, late join, route amendment, remapping and calibration (IN-015..022, OWN-014..015); automatic node enumeration and commissioning (NET-011..012), bus power, trust posture and adapter display (NET-013..015); compound accessories, live export, storage device and per-port accessory choice (STO-009..012); node configuration store and USB-drive management (CFG-003..004); network firmware update (UPD-005..006); power, isolation and recovery (HW-007..010); user interaction, environment and licensing decided (UI, ENV, LIC); SRS-UPD-004, SRS-UI-004, SRS-SUP-001 and SRS-ENV-003 withdrawn; verification entries SRS-V-011..015 added. |

## 1. Purpose and interpretation

RPN connects modern input devices to unmodified original consoles through a
central hub and console interface adapters. Authentic console-facing signalling
is produced locally by each adapter, never by timing packets across the network.

In these documents, **shall** denotes a requirement; **should** denotes a
recommendation; **may** denotes permission.

Classification:

- **F - Functional:** what the system shall do (actions, tasks or behaviour), as
  set by the project owner's scope decisions and confirmed values.
- **D - Derived:** an engineering constraint necessary to satisfy F requirements.

Stable identifiers are never reused. `SRS-*` identifies requirements, `ICD-*`
interfaces (including interface capabilities `ICD-CAP-*`, verification entries
`ICD-VER-*` and the console annexes `ICD-CON-*`), `SAD-*` architectural elements,
`PS-*` protocol elements and `AFS-*` adapter framework elements. Message opcodes
additionally have fixed numeric values. The PS owns wire definitions, the ICD
electrical definitions and the console annexes, the SAD software behaviour, the
AFS the adapter software contracts and the SRS acceptance criteria. Other
documents reference these owners rather than independently redefining them.

Withdrawn identifiers, which stay unused: SRS-HW-001, SRS-STO-007, SRS-UPD-004,
SRS-UI-004, SRS-SUP-001, SRS-ENV-003, ICD-CAP-017, PS-SVC-DISPLAY, SAD-D-001 to
SAD-D-011, SAD-P-001 to SAD-P-013, SAD-O-001 to SAD-O-015 and SAD-F-001 to
SAD-F-014.

### Glossary

| Term | Meaning in these documents |
|---|---|
| Hub | The single master device that acquires modern input, owns routing and ownership policy and masters the bus |
| Adapter | One console interface device: the network node that represents one console instance (SRS-SYS-006) |
| Node | Any addressed bus participant (adapters; the hub is the master) |
| Console port | A physical controller connector of the original console |
| Port (protocol) | A PS `port` ID (0 to 3) naming one emulated console port of an adapter; the console annex maps it to a physical connector or a multitap slot |
| Player | One of four independent player contexts in the hub (players 0 to 3) |
| Route | One player-to-port assignment with a selected virtual peripheral and mapping (SRS-IN-005); at most four per owner |
| Endpoint | A route as seen by the adapter: one active player/port record (so "four active endpoints" means four active routes) |
| Multitap | A console accessory that gives one controller port several controller slots; RPN emulates it inside the adapter and the hub sees each slot as a port (SRS-SYS-010) |
| Neutral record | The INPUT record of a route whose physical device is absent: no valid controls and every value neutral (SRS-IN-013, `PS-DATA-INPUT`) |
| Record kind | The INPUT record layout of a route: pad, pad with pressure, pointer or keyboard (`PS-DATA-INPUT`) |
| Channel | One electrical signal path between the adapter logic and a console connector pin (ICD-CAP) |
| Owner | The one adapter currently authorised to expose live input (ownership); "project owner" means the person approving scope and maturity |
| Profile | A console-specific interface and behaviour definition, specified by the console's annex of the ICD (`ICD-CON-001`); also used for the network profile of the PS |
| Console annex | The ICD annex that specifies one console's profile (`ICD-CON-NES` to `ICD-CON-XBOX`) |

Console names used in these documents: NES, SNES, Nintendo 64 (N64), GameCube,
Mega Drive, Saturn, Dreamcast, PlayStation, PlayStation 2 and Original Xbox.
Spelling convention: "analog" for signal types; other prose keeps the existing
British "-ise" forms.

## 2. Scope and deployment

| ID | Class | Requirement |
|---|---|---|
| SRS-SYS-001 | F | RPN shall separate input acquisition and routing in the hub from console-specific protocol, peripheral and accessory emulation in adapters. |
| SRS-SYS-002 | F | RPN shall support four simultaneous independent player contexts and explicit player-to-console-port routing. The number of players that can play on one console is bounded by the ports its adapter emulates (SRS-SYS-009, SRS-SYS-010). |
| SRS-SYS-003 | F | Connecting RPN shall require no permanent modification to a target console. |
| SRS-SYS-004 | F | RPN shall support NES, SNES, N64, GameCube, Mega Drive, Saturn, Dreamcast, PlayStation, PlayStation 2 and Original Xbox, each through one adapter type specified by its console annex (`ICD-CON-001`). |
| SRS-SYS-005 | D | Each console annex shall specify electrical compatibility, supported peripheral modes, mapping limitations, accessory behaviour and the verification evidence required before an adapter is connected to original hardware. |
| SRS-SYS-006 | D | An adapter shall represent one console instance and its supported controller ports. Multiple connectors or processors may be required inside that adapter. |
| SRS-SYS-007 | F | The network profile shall support one hub and up to 31 addressed adapters, four routed player records on one owner and at most four active routes (endpoints). This is the protocol address and resource bound. |
| SRS-SYS-008 | F | An installation shall comprise up to 10 adapters on a bus trunk of less than 5 m (`ICD-NET-002`). |
| SRS-SYS-009 | D | An adapter shall emulate every native controller port of its console, or the multitap configuration of SRS-SYS-010 that its annex selects, up to the four ports that can be routed (SRS-SYS-002/007). |
| SRS-SYS-010 | F | The SNES, Mega Drive, Saturn, PlayStation and PlayStation 2 adapters shall emulate the multitap that their annex names (SNES Super Multitap; Sega Team Player; Saturn multitap; PlayStation multitap; PlayStation 2 multitap), so that each presents four ports; the annex states the tap's protocol limits and slot-to-port mapping. The NES adapter shall present its two native ports. |
| SRS-SYS-011 | F | Each adapter shall present the virtual peripherals listed for its console in `SAD-MAP-002`, selectable per route: NES standard pad and NES Max; SNES standard pad and SNES Mouse; Mega Drive 3-button and 6-button pads and Mega Mouse; Saturn digital pad, 3D Control Pad, Virtua Stick, Twin Stick, Saturn Keyboard, Shuttle Mouse and Arcade Racer; N64 standard controller, fishing controller and steering wheel; GameCube standard controller, ASCII keyboard and steering wheel; Dreamcast standard controller, Arcade Stick, Fishing Controller, Keyboard, Mouse and Race Controller; PlayStation digital pad, DualShock, NeGcon, Jogcon, Mouse and controller-port steering wheel; PlayStation 2 DualShock 2 and controller-port steering wheel; Original Xbox controller, Arcade Stick and Steering Wheel. |
| SRS-SYS-012 | F | An adapter shall support every revision of its console whose standard controller ports take detachable controllers, including regional and slim variants; for the NES family this is the NES and the AV Famicom (HVC-101). The original Famicom (HVC-001), whose controllers are hard-wired, is not a target. |

Four simultaneous players is not a promise that every console reaches four: the
NES adapter presents two ports (SRS-SYS-010). Multiple consoles may remain
powered while exactly one console owns player input (SRS-OWN-002).

## 3. Input and peripheral requirements

| ID | Class | Requirement |
|---|---|---|
| SRS-IN-001 | F | The hub shall represent generic control positions and functions, not console-specific button names or console protocol commands. |
| SRS-IN-002 | F | The input model shall accommodate buttons, directional controls, sticks, triggers, steering and pedal axes, with explicit capability and validity information. |
| SRS-IN-003 | F | The physical device classes shall be gamepads, arcade fight sticks, racing wheels with pedals (SRS-IN-018), mice and trackballs (SRS-IN-016) and keyboards (SRS-IN-017). Actual device support shall be advertised rather than inferred. |
| SRS-IN-004 | D | Physical-device capabilities and virtual-peripheral capabilities shall use separate descriptors. The hub shall not assume one implies the other. |
| SRS-IN-005 | D | Every active route shall identify a player, adapter, port, selected virtual peripheral and mapping configuration. Multiple active routes shall not target the same port or duplicate a player. |
| SRS-IN-006 | D | The adapter shall apply a documented console-local mapping, including button layout, axis ranges, dead zones, inversion, analog-to-digital thresholds, hysteresis and unsupported-control behaviour. |
| SRS-IN-007 | D | Missing or invalid controls shall resolve to the generic neutral state; disconnected devices shall not leave latched active controls. Mapping to a peripheral unable to represent required controls shall require an explicit user-visible compatibility decision (SRS-UI-005). |
| SRS-IN-008 | D | The adapter shall validate all player records of an update as a set and shall reject the whole update if any record is invalid. A single-processor adapter shall install the records atomically. A multi-processor adapter shall install each port's record atomically after whole-set validation; a forwarding failure on a port shall neutralise that port and raise fault 2, and the console annex shall bound the installation skew between ports. Each console transaction shall read a coherent local snapshot. |
| SRS-IN-009 | D | Adapter console timing shall remain independent of network service latency, non-volatile writes and hub scheduling. Unsupported simultaneous peripheral combinations shall be rejected before arming. |
| SRS-IN-010 | D | Input-device replacement shall keep the affected player's record neutral until the new device is validated against its route and a fresh snapshot completes (SRS-IN-013); a replacement the route cannot accept keeps the record neutral until the route is amended (SRS-IN-020) or the routes are replaced. Mapping changes and peripheral changes shall inhibit the affected routes until validation and a fresh snapshot complete. |
| SRS-IN-011 | D | Every console annex shall declare a default idle peripheral identity presented to its console while the adapter is inhibited or configured, and shall state whether a peripheral change is allowed while the console is running. A route selects mapping, not identity: unless the annex declares live identity change as measured and safe, arming shall not change the identity the console sees. |
| SRS-IN-012 | F | The hub shall accept for input any USB device whose HID report descriptor parses under the HID subset of `SAD-MAP-001`, whatever its brand. A device that needs a vendor class driver, a device-specific initialisation handshake or authentication before it reports input shall not be supported. |
| SRS-IN-013 | F | When the physical device of a routed player is removed, lost, or replaced and awaiting validation, that player's route shall carry a neutral record (the generic neutral state of SRS-IN-007) and shall not inhibit the other routes, end the ownership generation or interrupt lease renewal; the other players' controls are unaffected. The hub shall detect the loss within 50 ms or three of the device's report intervals, whichever is longer, and the neutral record shall reach the adapter within the SRS-PERF-001 bound after detection; the detection time is measured and reported (SRS-V-002). |
| SRS-IN-014 | F | While the adapter is armed, every emulated console port without an active device shall present the profile's default idle peripheral identity with neutral controls (SRS-IN-011 already requires this while inhibited or configured) as an idle pad, never as an absent controller. |
| SRS-IN-015 | F | The input model shall carry 8-bit pressure for twelve generic button positions (the four directions, the four face buttons, the two shoulders and the two digital triggers) for peripherals with pressure-sensitive buttons (PlayStation 2 DualShock 2, Original Xbox analog buttons), with validity information. A route to such a peripheral whose source device has no pressure information shall report a press as full pressure and a release as zero, as a lossy mapping approved under SRS-UI-005. |
| SRS-IN-016 | F | The hub shall acquire USB HID mice and trackballs and carry relative motion as running counters (X, Y and wheel) with up to five buttons, so that no motion is lost when an INPUT exchange is lost; adapters shall present the console mice of SRS-SYS-011 from them. |
| SRS-IN-017 | F | The hub shall acquire USB HID keyboards and carry the modifier state and up to six simultaneously pressed keys as HID keyboard usages; adapters shall present the console keyboards of SRS-SYS-011 from them, and console keyboard-LED requests shall reach the bound keyboard (SRS-OWN-011). |
| SRS-IN-018 | F | The hub shall acquire USB HID racing wheels: steering, accelerator and brake axes, and shifter controls as the generic shift-up and shift-down buttons; adapters shall present the console wheels of SRS-SYS-011 from them. A clutch is not represented. |
| SRS-IN-019 | F | ROUTES shall configure a route for every emulated port of the selected console, assigning each to a player, whether or not that player has a device; a route without a device takes as its source the route's required controls and carries a neutral record until a device that supplies them is bound, which then resumes in place. |
| SRS-IN-020 | F | The hub shall be able to amend one route while the owner is armed (source device controls, mapping and player of that port; never the peripheral identity), without interrupting the other routes; the amended port shall present neutral controls from the amendment until its first fresh record under the amended route, and the amendment shall not renew the lease (`PS-OWNERSHIP`). |
| SRS-IN-021 | F | The hub shall let the user remap freely, per device and route, any control of the physical device to any generic position that the route's mapping uses; the remapping shall be stored in the hub (SRS-CFG-002) and applied before the route's source masks. |
| SRS-IN-022 | F | The hub shall provide a user calibration routine per physical device (axis centre, range and dead zone), stored in the hub (SRS-CFG-002); without a stored calibration the centre is captured when the device connects and the range comes from the descriptor's logical limits. |

Generic controls and neutral values are defined by `PS-DATA-INPUT`, not by
Nintendo or Sony naming. Adapter mapping is console-specific; the hub selects
opaque advertised mapping IDs without understanding their console semantics.
Console-specific names are shown only on the adapter's own display (SRS-UI-003).

## 4. Ownership and safe transitions

| ID | Class | Requirement |
|---|---|---|
| SRS-OWN-001 | F | The hub shall distinguish selection of one console owner from assignment of the players to that console's ports. |
| SRS-OWN-002 | D | Exactly one adapter at most shall be authorised to expose live player input at a time. Non-owners may continue console protocol exchanges but shall expose neutral controls or a profile-defined disconnected state. |
| SRS-OWN-003 | D | Boot, reset, expired ownership, input loss, invalid configuration and firmware maintenance shall leave live controls inhibited. |
| SRS-OWN-004 | D | Ownership transfer shall neutralise the old owner before enabling a new owner, using acknowledgement or expiration of a bounded lease; lack of response shall never be treated as successful revocation. |
| SRS-OWN-005 | D | Session and route-generation checks shall reject delayed input and commands from previous ownership configurations. |
| SRS-OWN-006 | D | Manual selection shall be authoritative but shall not bypass readiness, compatibility or transition safety checks. Conflicting activity shall not cause automatic ownership oscillation. |
| SRS-OWN-007 | D | Automatic selection shall be opt-in, enabled from the hub's local controls (default manual). It shall select only one uniquely eligible console when no owner exists, and shall not preempt an existing owner. |
| SRS-OWN-008 | D | Console activity detection shall distinguish active, inactive and unknown; an adapter unable to prove activity shall report unknown rather than guessing. |
| SRS-OWN-009 | F | Loss of fresh authorised input shall produce neutral controls within 103 ms real time of the last accepted arm/input renewal, including clock error and in-flight console completion, by a 100 ms local lease plus at most 1 ms local neutralisation delay. |
| SRS-OWN-010 | D | Recovery from bus loss, hub reboot or console reset shall require a deliberate re-arming procedure and fresh input; persisted routing alone shall not restore live controls. |
| SRS-OWN-011 | D | Feedback (rumble, force feedback and keyboard LEDs) shall be routed only to the physical device currently bound to the originating player/port/generation. Ownership loss, device loss or feedback expiry shall stop effects. |
| SRS-OWN-012 | F | A manual ownership switch (selection request to the new owner accepting live input) shall complete within 500 ms nominal, including the case where the old owner's revoke acknowledgement is lost and the 110 ms guard applies. |
| SRS-OWN-013 | D | Every console annex shall declare the maximum time (`neutralisation_bound_us`) within which neutral controls are visible to its console after an inhibit, including any in-flight console transaction, and shall demonstrate it by measurement at the console connector. A profile that cannot meet the global 1 ms bound of SRS-OWN-009 shall not be approved. |
| SRS-OWN-014 | F | Every adapter shall report activity by one rule: ACTIVE when console power is sensed present and a valid console poll of an emulated port was seen within the last 100 ms; INACTIVE when console power is sensed absent; UNKNOWN otherwise. An enrolled adapter that does not answer the hub because it is unpowered shall count as INACTIVE for automatic selection. |
| SRS-OWN-015 | F | The hub shall forward rumble (N64 Rumble Pak, GameCube, PlayStation DualShock, PlayStation 2, Original Xbox, Dreamcast vibration pack), force-feedback effects (constant force, spring and damper) and keyboard LEDs only to physical devices that expose a standard HID output path the hub implements: the Haptics page, the Physical Interface Device page or the LED page (`SAD-FB-001`). Any other device receives no effect and the hub records a diagnostic result. |

These requirements apply to controls and feedback. They do not forbid an
inactive console from reading its own accessory storage or an adapter from
answering identification polls. Storage integrity and power remain separate
constraints. Physical failure or defective firmware cannot be made safe merely
by a bus lease; hardware watchdogs and validation are also required.

## 5. Network and management

| ID | Class | Requirement |
|---|---|---|
| SRS-NET-001 | F | The shared network shall remain console-independent and support discovery, addressing, versioning, capabilities, input, feedback, status, diagnostics, configuration, storage, update and controlled reset through advertised operations. |
| SRS-NET-002 | D | A node shall advertise only implemented services and peripheral combinations. Unsupported services shall return explicit errors without side effects. |
| SRS-NET-003 | F | The bus shall use one master and half-duplex RS-485 at 8 Mbit/s as defined by `ICD-NET-001` and RPN-PS. Only the addressed node shall respond to a request with a frame. |
| SRS-NET-004 | D | Commissioning shall prevent simultaneous frame replies by unassigned nodes; bus collision detection shall not be assumed reliable. Enumeration (SRS-NET-011) shall use only a signal that several nodes can send at once without corrupting it. |
| SRS-NET-005 | D | Frames shall have length bounds, integrity checking, source/destination validation and bounded parser recovery. State-changing operations shall have defined retry and duplicate behaviour. |
| SRS-NET-006 | D | Bulk storage, configuration and update operations shall not starve input renewal or violate local console timing. |
| SRS-NET-007 | D | Timeout, malformed frame, unsupported version, queue overflow, storage failure and update failure shall be observable through bounded counters, explicit status or a local diagnostic indicator where communication is unavailable. Every node shall implement the Diagnostics service. |
| SRS-NET-008 | D | Recovery shall not depend on an unbounded retry loop; retries and backoff shall be bounded, and persistent failure shall inhibit live input. |
| SRS-NET-009 | D | Version negotiation shall precede normal operation. A common major version and supported minor profile shall be required before arming. |
| SRS-NET-010 | F | Every node shall derive its UART baud rate and lease timing from a crystal or equivalent-accuracy oscillator of at most +/-100 ppm; internal RC oscillators shall not generate the bus baud rate. Each node's total baud error (oscillator plus divider granularity) shall stay within +/-0.5 % (`ICD-NET-001`). The +/-1 % lease-clock bound of `PS-TIMING` is separate and deliberately looser. |
| SRS-NET-011 | F | The hub shall discover unassigned nodes whose UID it does not know, without a physical commissioning enable, by a collision-free UID enumeration (`PS-DISCOVERY`), and shall then assign each an address. |
| SRS-NET-012 | F | The hub shall offer "add adapter" from its local controls: it discovers the single node whose physical commissioning enable is asserted without being given its UID, records UID and address in its roster and confirms the UID in HELLO; two enabled nodes shall produce no assignment and a reported fault. |
| SRS-NET-013 | F | The bus harness shall carry, besides the differential pair, a bus-side supply from the hub that powers the bus side of every node's isolated transceiver (`ICD-NET-002`). |
| SRS-NET-014 | F | The bus is a physically trusted local network: it shall have no authentication or encryption and no connection outside the installation; firmware activation shall require a physical enable at the node (SRS-UPD-005). CRC shall not be described as authentication. |
| SRS-NET-015 | F | Every adapter shall implement the Adapter display service (`PS-SVC-PROMPT`) so that the hub can make the adapter display show the console-specific name of a generic control or option. |

Discovery has three paths: the roster scan of known nodes, "add adapter" for
the single enabled node (SRS-NET-012) and enumeration of unknown nodes
(SRS-NET-011). See `PS-DISCOVERY`.

## 6. Accessory storage, configuration and updates

| ID | Class | Requirement |
|---|---|---|
| SRS-STO-001 | F | Console-specific accessory semantics shall remain in the adapter. Examples include N64 Controller/Rumble Pak selection and Dreamcast VMU features. Support for one feature shall not imply complete accessory emulation. |
| SRS-STO-002 | D | Console-facing storage accesses shall complete from local resources without synchronous network round trips. Media geometry, write latency, endurance, recovery and accessory completeness shall be documented per console annex. |
| SRS-STO-003 | D | Network storage export shall provide an explicit consistency policy. Network writes shall require exclusive maintenance access, neutral controls and a disconnected or otherwise safely quiesced console storage interface. |
| SRS-STO-004 | D | A successful persistent-write response shall mean durable completion according to a documented power-fail policy. A timeout shall be treated as indeterminate, not as proof that no write occurred. |
| SRS-STO-005 | F | Memory accessory storage attached through the console's controller port, sharing the controller port signals (N64 Controller Pak, Dreamcast VMU memory), shall be emulated by the adapter: the adapter shall hold the authoritative data locally and present the console-visible capacity, geometry and identity of the accessory. SRS-STO-001 still applies: an annex declares which accessory functions it implements. |
| SRS-STO-006 | D | An adapter shall provide one memory accessory per emulated console port where its console has one (up to four per adapter). Every annex that includes one shall state its memory resources in its resource table (`ICD-CON-001`, `ICD-STO-001`): data capacity per accessory, storage device and its capacity (two banks, snapshot region and bank-select record), console access time against the console's response limit, power-fail and torn-write behaviour, write endurance at the worst-case write rate, the GPIO the storage device adds, and the maintenance transfer time. These shall stay within the 70 % margin rule for the chosen RP2350 variant. |
| SRS-STO-008 | F | The contents of an emulated memory accessory shall be held in external non-volatile FRAM, not in MCU flash or RAM; MCU RAM may hold only a non-authoritative cache of it. The adapter's firmware stays in MCU flash and its configuration in the node configuration store (SRS-CFG-003). |
| SRS-STO-009 | F | The Dreamcast adapter shall present on each port a controller with a VMU memory accessory and a vibration pack at the same time; vibration requests shall be forwarded as rumble (SRS-OWN-015). |
| SRS-STO-010 | F | An adapter shall export a coherent snapshot of a memory accessory while its console is running, including while it is the armed owner, without any console access exceeding its annex deadline; the snapshot shall reflect the accessory at one instant at which the console's storage interface was idle (`PS-SVC-STORAGE`). |
| SRS-STO-011 | F | The accessory FRAM shall be specified by requirement, not part number: SPI or QSPI, 3.3 V, endurance at least 10^12 cycles, SPI clock at least 40 MHz, temperature range covering SRS-ENV-002; capacity holding two banks, a snapshot region and a mirrored CRC-protected bank-select record (1 Mbit for the N64 Controller Pak, 4 Mbit for the Dreamcast VMU). |
| SRS-STO-012 | F | The N64 adapter shall present on each port exactly one of Controller Pak, Rumble Pak or no accessory, chosen per port by the user from the hub (SRS-UI-007), default Controller Pak; the choice shall persist in the node configuration store. |
| SRS-CFG-001 | D | Configuration changes shall be validated and applied as complete configurations. Failed writes or validation shall preserve the previous valid configuration and report failure. |
| SRS-CFG-002 | D | The hub shall persist its roster (UID and intended address per adapter), player assignments, recorded mapping approvals, remappings (SRS-IN-021), calibrations (SRS-IN-022) and the automatic-selection setting across power cycles. Persisted configuration shall never by itself restore live controls (SRS-OWN-010). |
| SRS-CFG-003 | F | Every node shall keep its address record, configuration and user options in a dedicated non-volatile configuration store (FRAM or EEPROM) that is written without stalling program execution; the hub keeps its persisted data (SRS-CFG-002) in the same kind of store. |
| SRS-CFG-004 | F | Memory accessory images, adapter configurations, firmware images and diagnostic snapshots shall be imported and exported as files on a USB flash drive attached to a free hub downstream port, driven entirely from the hub's local controls (`SAD-047`): every operation while no owner is armed, and accessory export also while an owner is armed. |
| SRS-UPD-001 | D | Updates shall check image compatibility and integrity before activation, remain inhibited, and provide a documented recoverable interruption path. CRC alone shall not be described as authentication. |
| SRS-UPD-002 | D | Updates and resets shall be refused while accessory data is dirty unless safe persistence is completed first. |
| SRS-UPD-003 | D | Every node shall provide safe update storage (two image slots), a boot stage that recovers from an interrupted or failed update, and flash programming only while the console driver is stopped in maintenance. |
| SRS-UPD-005 | F | Every adapter processor shall support network firmware update by one integrity-checked update profile (`SAD-030`): an image header with target hardware ID, version, length and SHA-256; staging into the inactive one of two image slots; verification before activation; activation only while the node's physical update enable is asserted; automatic rollback to the previous slot when the new image does not confirm itself; recovery through the debug interface (SRS-HW-010). No signature, secure boot or OTP programming is used. |
| SRS-UPD-006 | F | The hub firmware shall be updated from an image file on the USB flash drive (SRS-CFG-004) with the same header, slots, verification and rollback rules as SRS-UPD-005, started from the hub's local controls. |

## 7. Hardware, performance and quality

| ID | Class | Requirement |
|---|---|---|
| SRS-HW-002 | D | Console pins shall not be directly connected to incompatible MCU voltage domains. Every console annex shall define power-off behaviour, level translation, drive mode and contention prevention. |
| SRS-HW-003 | D | Console supplies shall not be tied together or back-powered through adapter or network connections. Grounding, isolation and fault protection shall be explicit before hardware connection. |
| SRS-HW-004 | D | Multi-player support shall be verified with every connected physical device's USB host load and every emulated console-port timing engine active, at the largest route count the profile advertises (four for a four-port profile), including permitted accessory traffic. |
| SRS-HW-005 | F | The hub and every adapter processor shall be members of the RP2350 family, unless an exception is recorded under `SAD-004`. |
| SRS-HW-006 | D | No console-facing signal shall rely on MCU-side 5 V tolerance or on internal MCU pull-up/pull-down resistors. Voltage adaptation, pull-up ownership and protection shall be provided by external components (`ICD-CAP-003`). |
| SRS-HW-007 | F | The hub shall be powered at 5 V through a USB Type-C receptacle from a standard USB-C charger advertising at least 3.0 A, and shall limit its downstream load when less is advertised (`ICD-PWR-001`). |
| SRS-HW-008 | F | An adapter's console-side logic shall be powered from its console: from the controller-port supply where the console annex shows that the adapter's load fits within 70 % of what the port can supply, otherwise from the console's own external power source through a pass-through input; reverse-polarity protection is required on any supply input whose connector is not polarity-keyed (`ICD-PWR-002`). |
| SRS-HW-009 | F | The hub and every adapter shall connect to the bus only through an isolated RS-485 transceiver whose bus side is powered from the bus supply (SRS-NET-013), so that no console or hub ground is joined through the bus. |
| SRS-HW-010 | F | Every node shall provide a three-pin SWD debug connector and a recovery input; a node powered with its recovery input asserted shall keep every console-facing output disabled, present RECOVERY and allow its image to be restored over SWD (`ICD-DBG-001`). Debug shall stay enabled in production. |
| SRS-PERF-001 | F | Under the normal profile below, elapsed time from a complete normalised sample becoming available at the hub to atomic installation at the owner shall not exceed 2 ms. USB acquisition and console polling are outside this interval and shall be measured separately. |
| SRS-PERF-002 | F | The hub shall schedule one input exchange carrying every configured player record (up to four) every 1 ms while armed. Traffic admission shall reserve the worst-case exchange time, not just average bandwidth: a non-input exchange shall start only if its worst-case timeout path ends before the next input slot (`PS-TIMING`). |
| SRS-PERF-003 | D | Each console annex shall declare and meet its own measured response and jitter limits under maximum supported load. No universal console timing number is assumed. |
| SRS-PERF-004 | F | End-to-end added latency, from the hub receiving a device report to the adapter having installed the corresponding snapshot, shall be at most 4 ms at the 99.9th percentile, with the maximum reported separately, for every device class including fight sticks. Budget components: hub processing at most 1 ms; hub sample availability to installation at most 2 ms (SRS-PERF-001). The device's own report interval and the console's polling phase are not part of the budget but are reported in the end-to-end measurement. |
| SRS-PERF-005 | F | If exactly one INPUT exchange is lost, corrupted or times out, the next scheduled exchange shall carry the newest sample (an INPUT is never retried with a stale sample) and that sample shall be installed within 3 ms of becoming available. SRS-PERF-001 (2 ms) applies to the normal profile without link errors. |
| SRS-PERF-006 | D | An adapter shall validate, map and install a complete four-record INPUT and start its response within 100 us of the request's last stop bit on its RP2350 part under worst-case console load (`PS-TIMING`, `SAD-031`). |
| SRS-REL-001 | D | Firmware shall use bounded buffers, queues, retries and allocation. Resource exhaustion shall report a fault and preserve neutral-input and storage safety. |
| SRS-REL-002 | D | Watchdog recovery shall return to inhibited state without exposing stale input or partially committed configuration. |
| SRS-MNT-001 | F | Common networking, services, configuration, diagnostics and update policy shall be reusable without console-specific dependencies; the adapter framework contracts are specified by RPN-AFS. |
| SRS-MNT-002 | D | Console drivers shall declare resource and timing requirements; reuse shall not require identical low-level execution models across consoles. |
| SRS-MNT-003 | D | Protocol codecs, routing, lease handling and mapping shall be testable independently of physical hardware, supplemented by hardware-in-loop tests. |
| SRS-EXT-001 | D | New console drivers shall not require changes to generic hub input acquisition or the base framing protocol. New service schemas shall be versioned and bounded. |

The normal profile is: one bus, one owner, up to four player records, 31 or
fewer commissioned adapters, no link errors, supported device/report rates,
verified console-driver resource load and bulk traffic admitted by the
scheduler. It does not assert fault-free timing during a bus outage. Faults are
governed by the lease limit. Normal operation and fault-containment limits must
both be tested.

## 8. User interaction, operations and compliance

| ID | Class | Requirement |
|---|---|---|
| SRS-UI-001 | F | The hub shall provide four local buttons (up, down, select, back) and a colour display, with no external computer required, to select the console owner and to see the owner, the armed/neutral state and any persistent fault. |
| SRS-UI-002 | F | The hub shall let the user assign the players to the routed ports of the selected console. |
| SRS-UI-003 | F | The hub display shall show hub information (owner, players, devices, routes in generic terms, faults and menus). Every adapter shall have its own display showing its state, its routes and mappings with the console's own button names, and the Dreamcast VMU screens of its ports. |
| SRS-UI-005 | F | A lossy mapping (SRS-IN-007) shall be approved by the user on the hub display with the local controls once per device, route and mapping; the approval shall be stored in the hub (SRS-CFG-002) and asked again when the mapping or the device changes; a device is identified by VID, PID and its serial number when it has one. |
| SRS-UI-006 | F | The hub's local controls shall enable and disable automatic selection (SRS-OWN-007) and start "add adapter" (SRS-NET-012), unknown-node discovery (SRS-NET-011), remapping (SRS-IN-021), calibration (SRS-IN-022) and USB-drive operations (SRS-CFG-004). |
| SRS-UI-007 | F | The hub shall list the user options that an adapter advertises (for example the N64 accessory per port) and let the user set them from its local controls, while the adapter display shows the options' console-specific names. |
| SRS-ENV-001 | F | Every externally accessible connector (console, USB, bus and power) shall withstand ESD to IEC 61000-4-2 level 3 (6 kV contact, 8 kV air) as an engineering target; no emissions, immunity, marking or certification claim is made. All RPN equipment is low-voltage: powered at 5 V DC (hub) or from the console (adapters) through certified external supplies, with no mains voltage inside any RPN enclosure. |
| SRS-ENV-002 | F | RPN equipment shall operate indoors in domestic use from 5 to 40 degC at 20 to 80 % relative humidity, non-condensing, and shall be stored from -20 to 60 degC. |
| SRS-ENV-004 | F | The bus harness shall be specified for connection and disconnection only while every RPN node and the hub are powered off, a documented limit of the installation; the bus connector shall carry a distinct label and its pins shall withstand an accidental connection to Ethernet equipment, including Power over Ethernet voltages (`ICD-NET-002`). |
| SRS-LIC-001 | F | The repository shall contain no console-vendor firmware, BIOS, keys or proprietary code; console behaviour shall be implemented from independently written code, public documentation and measurement; third-party code shall be used only with a recorded compatible licence; documentation sources shall be listed in the reference register `ICD-REF-001`. |

## 9. Verification and traceability

Inspection (I), software test (T), hardware measurement (H) and fault injection
(F) are distinct evidence types. Conformance is claimed only on the evidence
listed below.

| Verification ID | Requirements | Method and acceptance evidence | Design references |
|---|---|---|---|
| SRS-V-001 | SYS-001..012, MNT-001..003, EXT-001 | I/T: dependency checks; add a mock adapter without changing hub core; one adapter type per console with its annex; check that no adapter exposes more than four console ports, that each annex states its ports, multitap and slot mapping, that each adapter presents the virtual peripherals of SRS-SYS-011, and that an adapter advertises only the ports it emulates; console revisions of SRS-SYS-012 enumerate the adapter | `SAD-COMP-*`, `ICD-CON-001`, `SAD-MAP-002` |
| SRS-V-002 | IN-001..014, IN-019..020, SYS-002 | T/H: four distinct devices, independent button/axis sweeps, unsupported mapping rejection, disconnects and simultaneous port reads; no cross-player leakage or torn snapshots; every descriptor of the acceptance corpus of `SAD-MAP-001` (gamepad, fight stick, hat-only, 16-bit axes, with and without report IDs, wheel, mouse, keyboard) parses and reports correctly and a device needing a vendor driver is refused; no identity change visible at the console when arming; removing and reconnecting one device leaves every other player's controls unchanged, shows neutral controls for the removed player and reports the time from physical removal to the neutral record installed at the adapter; every port without a device shows the default idle identity while armed; a device bound after arming resumes in place; a route amendment while armed leaves the other ports' controls unchanged and the amended port neutral until its fresh record; a multi-processor adapter's forwarding failure neutralises only that port and raises fault 2 | `PS-DATA-INPUT`, `PS-OWNERSHIP`, `SAD-MAP-001`, `SAD-MAP-002`, `SAD-010`, `SAD-011`, `SAD-033`, `SAD-050` |
| SRS-V-003 | OWN-001..015 | T/F/H: simultaneous console activity, manual switches (switch time within 500 ms nominal), lost revoke reply, delayed frames, counter exhaustion and rollover to a new session, node/hub reset; no overlap of authorised live input; neutral within 103 ms real time of last renewal; per-profile neutralisation bound measured at the console connector; activity reported ACTIVE/INACTIVE/UNKNOWN by the rule of SRS-OWN-014 including an unpowered adapter; feedback reaches only HID devices with a supported output path and others record a diagnostic | `SAD-OWN-001`, `PS-OWNERSHIP`, `ICD-VER-016`, `SAD-FB-001` |
| SRS-V-004 | NET-001..015, REL-001 | T/F: golden codecs and the vector appendix of the PS, corrupt/truncated/oversize frames, duplicates, address conflicts, incompatible versions, queue saturation and retry exhaustion; commissioning retry after lost ASSIGN reply; persisted-address boot; bounded recovery and explicit diagnostics; baud-error margin measured; Diagnostics advertised by every node; PROMPT shown on the adapter display | `PS-FRAME`, `PS-TRANSACTION`, `PS-DISCOVERY`, `PS-VECTORS`, `ICD-VER-017` |
| SRS-V-005 | STO-001..006, STO-008..012, CFG-001..003, UPD-001..003, REL-002 | T/F/H: remove power at each persistence/update stage; verify old/new valid state or documented recovery mode, no acknowledged data loss, no live input during maintenance; for each memory accessory, console-side format and capacity checks, the console's own save/load/format/copy operations, accesses from an inactive console, a read and a write of the FRAM within the console's response limit, power removed during a block write and during a bank flip, the device's endurance figure against the worst-case write rate, and the maintenance transfer time against the figure in the resource table; configuration commit with power loss and with a lost COMMIT acknowledgement (`PS-SVC-CONFIG`); hub persistence without restoring live controls; Dreamcast VMU and vibration pack used together on one port; N64 per-port accessory choice persisted across power cycles | `PS-SVC-STORAGE`, `PS-SVC-CONFIG`, `SAD-PERSIST-001`, `SAD-042`, `SAD-051` |
| SRS-V-006 | HW-002..006, HW-009, PERF-003, PERF-006 | I/H: per-console annex pin/timing values verified, powered/unpowered fault cases, oscilloscope and logic-analyser captures under all-port/accessory load; the ICD verification entries `ICD-VER-001..031` with their pass criteria; RP2350 datasheet/errata register `ICD-PLAT-001` applied; INPUT response start at most 100 us under worst-case console load | `ICD-CON-001`, `ICD-CAP-*`, `ICD-VER-*`, `ICD-QUAL-001` |
| SRS-V-007 | PERF-001..002, PERF-004..005, NET-006 | T/H: timestamp sample availability and snapshot installation for at least 10 minutes of full traffic with the largest record count (four players) plus admitted management and live-export load; every sample selected for transmission installed within 2 ms in the normal profile; end-to-end added latency at the 99.9th percentile and maximum, for a gamepad and a fight stick; a single injected lost INPUT installed within 3 ms with no stale retry; report overwritten sample count separately | `PS-TIMING`, `SAD-SCHED-001` |
| SRS-V-008 | OWN-011, OWN-015, NET-007..008 | T/F: feedback replay, queue overflow, device swap, expiry and link loss; no misrouted/latched effects and visible error counters; feedback polled every 2 ms; rumble, constant force, spring, damper and keyboard LEDs reach a HID device with the matching output path | `PS-SVC-FEEDBACK`, `SAD-FB-001` |
| SRS-V-009 | SYS-003 | I/H: connector-only attachment with no soldering, cutting or permanent change to the console (a pass-through power input counts as a connector); a reversible fixture; the console and its original controller restored to original function after removal | `ICD-CON-001`, `ICD-PWR-002` |
| SRS-V-010 | UI-001..003, UI-005..007, CFG-002 | I/T/demo: local owner selection, player assignment and fault indication without an external computer; console names and VMU screens appear only on the adapter display; lossy approval asked once and again after a device or mapping change; user options set from the hub with names on the adapter display; power-cycle restores roster, assignments, approvals, remappings and calibrations but not live controls | `SAD-046`, `SAD-045` |
| SRS-V-011 | IN-015..018, IN-021..022 | T/H: pressure values from a pressure-capable source reach the DualShock 2 and Original Xbox peripherals, and a binary source maps to full pressure after approval; mouse motion with one INPUT lost per 10 loses no counts; keyboard keys and modifiers reach each console keyboard and LED requests reach the USB keyboard; wheel steering, pedals and shift buttons reach each console wheel; a remapped control reaches its chosen position; a calibrated axis reports the calibrated centre and range | `PS-DATA-INPUT`, `SAD-038..041`, `SAD-043`, `SAD-029` |
| SRS-V-012 | UPD-005..006, HW-010 | T/F/H: update of every processor type and of the hub from the USB drive; wrong hardware ID, wrong length and wrong SHA-256 refused; power removed during staging, verification and activation leaves a bootable slot; an image that never confirms rolls back automatically; activation refused without the physical enable; a corrupted image restored over SWD from RECOVERY (`ICD-VER-023`) | `PS-SVC-UPDATE`, `SAD-030`, `SAD-048` |
| SRS-V-013 | NET-011..014 | T/H: enumeration of up to 10 unknown nodes finds every UID with no false node and no frame collision, and a simulation with 31 unknown UIDs does the same; "add adapter" with one enabled node succeeds and with two enabled nodes reports a fault and assigns nothing; bus supply within the transceiver's range at the farthest node with 10 adapters (`ICD-VER-024`); inspection that no authentication is claimed and activation needs the physical enable | `PS-DISCOVERY`, `SAD-014`, `SAD-035`, `ICD-NET-002` |
| SRS-V-014 | HW-007..008, ENV-001..002, ENV-004 | I/H: hub draws within the advertised USB Type-C current and limits its load below 3.0 A (`ICD-VER-025`); adapter supplied from the console within the annex's budget, reverse polarity on an unkeyed input causes no damage (`ICD-VER-026`); ESD at level 3 on every external connector (`ICD-VER-012`); operation at 5 and 40 degC; RJ45 bus port survives 57 V applied to any pin pair (`ICD-VER-027`) | `ICD-PWR-001`, `ICD-PWR-002`, `ICD-NET-002` |
| SRS-V-015 | STO-010, CFG-004, LIC-001 | T/I: a live snapshot exported during console saves is identical to the accessory at one idle instant and console accesses meet their deadlines throughout; accessory images, configurations, firmware images and diagnostic snapshots round-trip through the USB drive; repository inspection finds no console-vendor code and a licence record for every third-party component | `PS-SVC-STORAGE`, `SAD-036`, `SAD-047`, `ICD-REF-001` |

For `SRS-PERF-001`, intermediate device samples may be coalesced before the
next scheduled snapshot, but the newest available sample at that scheduling
boundary shall be included. A sample that remains the latest shall meet 2 ms;
coalescing must not be used to conceal an unbounded backlog or dropped button
transitions. A pulse shorter than the 1 ms snapshot interval may be missed by
the console; the console's own polling rate bounds what any controller can
deliver.
