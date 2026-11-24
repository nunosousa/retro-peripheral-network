# Software Architecture Description

| Control field | Value |
|---|---|
| Document ID | RPN-SAD |
| Revision | 0.1 |
| Status | Draft - architecture exploration |
| Date | 2026-11-24 |
| Companion documents | [RPN-SRS](SRS.md), [RPN-ICD](ICD.md), [RPN-PS](PS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Initial architecture review, decision register, safe two-player ownership, framework boundaries and scheduling model. |
| 0.1 (2026-11-18) | REVIEW-001 correction cycle: RP2350 platform, document-authority, hardware-isolation, port-scope and USB decisions registered; persistent addresses, per-profile neutralisation bound, multi-processor adapters, controller-coverage matrix, first-console comparison, scheduler admission rule and feedback cadence added. |
| 0.1 (2026-11-18, owner decision) | Line rate 2 Mbit/s (trunk under 5 m) in SAD-P-001 and SAD-R-009; display lowest-priority scheduling rule and SAD-F-006 design intent; full duplex considered and not adopted. |
| 0.1 (2026-11-18, owner decision) | Peripherals outside the generic model catalogued in SAD-MAP-003; Future register entries SAD-F-007 to SAD-F-014 (classification awaits owner confirmation; SAD-F-014 later retired). |
| 0.1 (2026-11-18, owner decision) | Memory-card accessory storage in scope: SAD-D-009, SAD-P-012, SAD-O-011..013, SAD-PERSIST-001 accessory paragraph, SAD-MAP-003 and SAD-F-012 narrowed. |
| 0.1 (2026-11-18, owner decision) | Two-bank layout and shared SPI bus confirmed (SAD-P-012, SAD-O-005). |
| 0.1 (2026-11-18, owner decision) | Emulated memory-card contents in external FRAM (SAD-P-012 rewritten, SAD-O-005, SAD-PERSIST-001 text). |
| 0.1 (2026-11-18, owner decision) | Memory-card scope narrowed to controller-port accessories (SAD-D-009, SAD-P-012); dedicated-slot cards and the Xbox Memory Unit out of scope; SAD-O-012, SAD-O-013 and SAD-F-014 retired; SAD-MAP-003 row replaced. |
| 0.1 (2026-11-24, owner decision) | Player count raised from two to four: SAD-D-002 revised; SAD-D-010 (neutral record for a removed device) and SAD-D-011 (idle pad on unrouted ports) added; SAD-P-005, P-007, P-008 (Original Xbox now four USB device ports), P-009, P-012 and O-009 revised; SAD-P-013 (multitaps inside the adapter), SAD-O-014 (late join) and SAD-O-015 (tap selection) added; SAD-F-001 narrowed to more than four players; hub states, removal handling, SAD-ADAPT-001 and the multitap row of SAD-MAP-003 updated. Supersedes option A of REVIEW-001 RR-001-005. |

## 1. Architecture intent

One hub models four players and acquires modern input. Each console adapter
models one console's peripheral ecosystem. The network carries generic state
and management operations, not console bit-level transactions. Console response
timing is satisfied entirely from adapter-local state.

Classification C/D/P/O/F follows [RPN-SRS](SRS.md#1-purpose-and-interpretation).
All implementation arrangements below are proposals unless identified as C or D.
No source firmware exists in this repository yet.

## 2. Initial architecture review

| Review ID | Finding or unresolved assumption | Resolution in this draft |
|---|---|---|
| SAD-R-001 | One MCU per adapter is not proven for up to four ports, accessories and USB-device consoles | One logical adapter may use multiple processors under one network node (`SAD-ADAPT-001`); the Original Xbox adapter uses one processor per emulated USB device port; profile-level resource and timing gates |
| SAD-R-002 | A generic input model can still leak console-specific mapping into the hub | Positional generic controls; mappings and virtual peripherals owned by adapter; device and virtual descriptors separated |
| SAD-R-003 | Broadcast discovery on half-duplex RS-485 can collide; CRC is not reliable arbitration | Commissioning by a known 128-bit UID; roster scanning thereafter; automatic unknown-node enumeration deferred |
| SAD-R-004 | "Active console" does not define exclusivity, particularly after lost acknowledgements | Explicit single-owner lease, generation fencing, boot guard and revoke-or-expire switching |
| SAD-R-005 | A player assignment is not an ownership grant | Routes configured while inhibited; arm is a separate operation; atomic multi-player snapshots |
| SAD-R-006 | A network storage service cannot satisfy console accessory deadlines | Local authoritative storage; export/import only in exclusive maintenance in this profile |
| SAD-R-007 | Service-oriented architecture can imply unnecessary RPC or a plug-in framework | Fixed bounded opcode groups plus a service bitmap and descriptors; no dynamic broker or runtime plug-ins |
| SAD-R-008 | Platform choice does not by itself establish USB-host capacity or flash-time isolation | RP2350 family is mandated (`SAD-D-004`); the single native USB controller is extended by a hub IC (`SAD-P-009`); prove flash/console coexistence and the per-profile resource margin |
| SAD-R-009 | A 2 Mbit/s line rate sounds ample but management replies and turnaround consume deadlines | Four-player exchange budget and deadline-based bulk admission in PS-TIMING |
| SAD-R-010 | Emulating accessory storage is not emulating the complete accessory | Explicit supported peripheral functions; no implied VMU screen/clock or complete Pak coverage |
| SAD-R-011 | A shared bus may join console grounds and supplies unintentionally | ICD power/isolation gates; no approved connector or common-ground deployment yet |
| SAD-R-012 | CRC, version negotiation and firmware recovery do not provide authentication | Trusted local bus assumption, physical update enable, security boundaries stated explicitly |

These findings review the supplied project architecture, rather than assert
defects in an existing implementation. Findings and answers from formal reviews
are recorded in [docs/reviews/](reviews/REVIEW-001.md).

## 3. Decision register

This is the shared decision/open-question authority; other documents reference
it. Provisional selections define a coherent profile to evaluate, not a frozen
design. Numeric protocol choices remain provisional as a group.

| ID | Class | Decision or question | Dependency / resolution evidence |
|---|---|---|---|
| SAD-D-001 | C | Hub has no console-specific wire-protocol logic; adapters own console semantics | Component dependency review |
| SAD-D-002 | C | Four independent players (owner decision 2026-11-24, `SRS-SYS-002`); multiple powered consoles; one selected console owner | Ownership and multi-port tests |
| SAD-D-003 | D | Console timing and accessory I/O use local state, not bus round trips | Per-console timing analysis |
| SAD-D-004 | C | The hub and every adapter processor are members of the RP2350 family (SRS-HW-005). An exception requires documented evidence that the family cannot meet a named requirement, owner approval and a register entry naming the adapter or profile, scope and evidence | Per-profile resource table; exception entries |
| SAD-D-005 | D | Document authority: the ICD is the single electrical authority. The former RPN-EIC is deprecated engineering notes whose useful content now lives in the ICD; where documents conflict the established SRS/ICD/SAD/PS text takes precedence. ICD-CAP is a sizing baseline, never an approval to wire; ICD-CON-001 supplements hold approved per-console facts and may narrow but not exceed the baseline without an ICD change | ICD section 8; EIC deprecation notice |
| SAD-D-006 | D | No console-facing signal relies on MCU 5 V tolerance or internal pulls; voltage domain and drive type are fixed by each console connector module, identified to firmware, and firmware refuses a mismatching profile (SRS-HW-006, ICD-CAP-003/004) | ICD-VER-001..006, ICD-VER-015 |
| SAD-D-007 | D | Every profile declares a default idle peripheral identity and whether live identity change is allowed; the route selects mapping, not identity (SRS-IN-011) | ICD-CON-001 supplement review |
| SAD-D-008 | D | Every profile declares `neutralisation_bound_us` (CAPS kind 4); hub drain and uncertain-transfer guards derive from the maximum over enrolled adapters; a profile that cannot meet the 1 ms global bound is not approved with the provisional timing (SRS-OWN-013) | ICD-VER-016, PS-TIMING |
| SAD-D-009 | C | Memory-card accessory storage is in scope when the accessory attaches through the controller port (N64 Controller Pak, Dreamcast VMU) and is the adapter's responsibility: one accessory per emulated port, authoritative local image, resources determined per profile (`SRS-STO-005..006`, `ICD-STO-001`). Dedicated-slot cards (GameCube, PlayStation, PlayStation 2) and the Original Xbox Memory Unit are out of scope | ICD-VER-021, SRS-V-005 |
| SAD-D-010 | C | When the device of a routed player is removed, lost or replaced and not yet validated, the route stays and carries a neutral record (`SRS-IN-013`); the other players, the ownership generation and the lease are unaffected. A replacement the route cannot accept (`SAD-MAP-001`) leaves the record neutral until the routes are replaced (`SAD-O-014`) | Device removal and replacement tests in `SRS-V-002`; neutral record in `PS-DATA-INPUT` |
| SAD-D-011 | C | An emulated port without a route presents the profile's default idle peripheral identity with neutral controls (an idle pad), never an absent controller (`SRS-IN-014`) | Per-profile idle identity (`ICD-CON-001`); `SRS-V-002` |
| SAD-P-001 | P | RS-485, 2 Mbit/s, one master, up to 31 addresses, typical trunk under 5 m (owner decision; half-duplex retained: full duplex would not shorten the 5 ms cadence that dominates latency, needs a second isolated pair per node and breaks the one-outstanding-request model) | Harness, loading, isolator delay and scheduling qualification at 2 Mbit/s (`ICD-VER-017`, `ICD-VER-020`) |
| SAD-P-002 | P | Compact fixed services over COBS/CRC framing, 192-byte payload bound | Codec and interop tests; revise together with PS |
| SAD-P-003 | P | Commission unassigned nodes by scanned/manually supplied UID; no broadcast contention algorithm. The 128-bit UID is a vendor-defined value held in locked OTP on production RP2350 parts (prototype boards may use a documented non-OTP method, marked as prototype); the assigned address is persisted by the adapter and physical commissioning enable is needed only for first install, UID mismatch or address conflict | Provisioning procedure, accessible UID label/debug readout, persisted-address tests |
| SAD-P-004 | P | 5 ms snapshots with per-opcode response timeouts and admission of non-input exchanges only if their timeout path fits before the next input slot; feedback polled every 10 ms while armed; 100 ms ownership lease; 110 ms reboot/uncertain-transfer guard | Latency and drift tests; clock bound and cycle budget in PS-TIMING |
| SAD-P-005 | P | One selected virtual peripheral per port; four routes max; no fan-out | Two-player prototype first; four-record evidence (`SRS-V-007`) before claiming four players |
| SAD-P-006 | P | Generic storage/configuration/update only in maintenance | Profile quiescence, durability and recovery tests |
| SAD-P-007 | P | Arm Cortex-M33 cores only. RP2350A (30 GPIO) is the default part; RP2350B (48 GPIO) is permitted only where a profile's resource table shows the need (more than 70 % of any resource in the worst all-port case on RP2350A); parts with stacked flash are permitted but not required. At four ports the Dreamcast exceeds the GPIO margin of the RP2350A, and the N64 with Controller Paks exceeds it by one GPIO unless the profile shares one power-sense input (ICD section 8.3); the RP2350B is expected for the Dreamcast and possible for the N64 (owner: the RP2350B is in scope where it is the more logical solution). Part facts to be re-verified against the current datasheet | ICD-PLAT-001 register; per-profile resource tables |
| SAD-P-008 | P | An adapter emulates every native console port up to four (`SRS-SYS-009`); the Original Xbox adapter provides four USB device ports, using one processor per USB device port and a gateway processor that owns the RS-485 node and may be one of the four (`SAD-ADAPT-001`). A two-port build is a profile decision; the console then sees no controller on the other two ports | Xbox profile supplement |
| SAD-P-009 | P | Hub USB host uses the single native RP2350 USB controller behind a USB hub IC to serve four player devices; software (PIO) USB host is not counted on | ICD-VER-018, resource budget in ICD-HUB-001 |
| SAD-P-010 | P | Default power architecture: each adapter externally powered, console power sense-only, and an isolated RS-485 interface (isolated transceiver and isolated power) at every adapter, with isolation delay included in `PS-TIMING` margins | ICD-QUAL-001 power and ground-loop tests; ICD-VER-011, ICD-VER-020 |
| SAD-P-011 | P | First increment accepts USB HID input devices only (`SRS-IN-012`) | HID parse tests with the named devices |
| SAD-P-012 | P | Accessory storage architecture: the accessory image is held in an external non-volatile device, proposed SPI/QSPI FRAM, outside the MCU (`SRS-STO-008`); two banks plus a bank-select record for atomic network replacement; write-through, console write acknowledged after the FRAM write completes; one device per port on a shared SPI bus with serialised, DMA-driven access (owner decision, taken for two ports; the contention wait, which grows with the port count, is included in the access-time budget); RAM only as a non-authoritative latency cache; MCU flash is an owner-approved exception with the flash rules of `ICD-STO-001` | FRAM part and access-time measurement; ICD-VER-021 power-fail test |
| SAD-P-013 | P | Multitaps are emulated inside the adapter, and only where the console supports one (`SRS-SYS-010`): each tap slot is a port (0..3) of the same adapter, so the hub, the routes and the PS need no change. A profile with fewer than four native ports either emulates a tap or advertises only its native ports. Not part of the first increment; added per profile once its native-port driver is proven | Profile supplement (`ICD-CON-001`, `ICD-CAP-020`); ICD-VER-022 |
| SAD-O-001 | O | First console, exact hardware variants and first supported virtual peripherals. Owner's current leaning: Saturn ("could be a good first option"); candidates compared in section 3.1 | Owner selection at development-guide Step 3, before console implementation |
| SAD-O-002 | O | Connector and cable, adapter and hub supply units and distribution; confirmation by test of the isolation and power defaults of `SAD-P-010` | Deployment survey and ICD-QUAL-001 |
| SAD-O-003 | O | Hub device list and radio; USB host topology is set by `SAD-P-009` | Two-device (first prototype) then four-device enumeration/report/feedback load prototype |
| SAD-O-004 | O | Per-console MCU/PIO/USB split and timing limits within the resource-table margin rule | ICD-CON-001 supplements and traces |
| SAD-O-005 | O | FRAM part selection (density, SPI or QSPI, supply, endurance, temperature range, availability), access-time margin per console on the shared bus, plus the configuration journal location, configuration journal, persisted-address record and update recovery mechanism | Power-fail and endurance analysis |
| SAD-O-006 | O | Console activity sensing reliability and eligible auto-selection UI | Profile-specific sensing plus multi-console tests |
| SAD-O-007 | O | Final button mappings, analog calibration and compatibility prompts; end-to-end latency target for fight sticks | Profile usability tests; no silent lossy conversion |
| SAD-O-008 | O | Firmware manifest/signature scheme and future untrusted administration. Deferred: not required for the first prototype (`SAD-F-004`) | Threat model; network update disabled until a concrete profile exists |
| SAD-O-009 | O | Adapter processing budget for the INPUT response window (latest response start 250 us), validating and mapping up to four records, on the chosen RP2350 part under worst-case console load. If too tight: first widen the per-opcode window (`PS-TIMING`), or, only with owner approval, acknowledge after validation but before installation while installation still completes before the next console-visible read and keeps SRS-IN-008 atomicity | Measured budget before protocol tests (development-guide Step 5) |
| SAD-O-010 | O | The first two concrete HID devices (name, VID/PID, captured report descriptor) for the first prototype | Owner selection at Step 3 |
| SAD-O-011 | O | Whether the hub needs a resource-to-port binding in CAPS kind 1 (for example to show "player 1 memory card" in the UI); 0.1 leaves it in the profile, and adding a `port` field would be a wire change | Owner decision before the display and UI work; PS minor if needed |
| SAD-O-012 | Retired | **Retired 2026-11-18**: concerned PlayStation 2 memory-card flash capacity; dedicated-slot cards are out of scope. Not reused. | - |
| SAD-O-013 | Retired | **Retired 2026-11-18**: concerned card-slot interfaces; dedicated-slot cards are out of scope. Not reused. | - |
| SAD-O-014 | O | Late join and route changes while armed. In 0.1 a player whose device connects after arming (or who has no route) can join only by release, ROUTES and ARM of the whole generation, which interrupts every player while the routes are replaced. Open: whether the hub may do this automatically on connection, only on explicit user action, or never; whether routes should be pre-configured for players without a device; and whether a ROUTES amendment while armed (a negotiated minor) is wanted. Until decided: only on explicit user action, never silently (`SAD-COMP-HUB`), and the player's port shows the idle pad (`SAD-D-011`) | Owner decision at development-guide Step 3; a PS minor if an in-place amendment is chosen |
| SAD-O-015 | O | Which console profiles emulate a multitap, which tap model each emulates and in what order (`SAD-P-013`). Constraints from secondary sources (`ICD-REF-001`), to be verified: the Mega Drive has two incompatible taps (Sega Team Player and EA 4 Way Play); the Saturn tap has six slots, of which four are used; the SNES tap needs the Data2 and IOBit signals that the baseline excludes; the PlayStation tap uses only the controller-port signals, but PlayStation software and PlayStation 2 software need different taps, and whether the PlayStation 2 tap also uses the memory-card slot (out of scope, `ICD-CAP-018`) is unverified | Owner selection per profile after the first console driver is proven; ICD-CON-001 supplement |
| SAD-F-001 | F | Bluetooth acquisition, actual wheel drivers, more than four players, remote control | New scope and resource budgets; INPUT is limited to five 32-byte records by the 192-byte payload and the `PS-TIMING` cycle proof closes only up to eight records, so more than four players needs a PS minor and a recomputed budget |
| SAD-F-002 | F | Fully automatic unknown-node discovery and live coherent storage export | Justify complexity after baseline prototype |
| SAD-F-003 | F | Separate Adapter Software Framework specification | Extract after two materially different working console drivers |
| SAD-F-004 | F | Network firmware update: update-profile supplement (image format, signing, anti-rollback, recovery path, OTP policy with a prototype/production distinction) | Before any node advertises the Update service |
| SAD-F-005 | F | Pressure-sensitive buttons (a negotiated minor adds an optional per-record extension, since the 0.1 record size is fixed) and USB protocols needing console-specific protocols or authentication | After the first profiles and the input-schema freeze |
| SAD-F-006 | F | Hub display of the Dreamcast VMU screen (`SRS-UI-004`). Design intent: the adapter captures the console's display writes locally; the hub polls the owner at the lowest bus priority, at most 10 times per second per port, with an adapter-declared chunk size (96 bytes default, two chunks for a 192-byte frame); latest frame wins, no queue; wire proposal in `PS-SVC-DISPLAY`. Needs a minor that adds the service and a VMU display function in the Dreamcast profile | After a Dreamcast profile exists; `SRS-V-007` re-run with display polling active shows INPUT latency and jitter unchanged |
| SAD-F-007 | F | Relative pointing devices (mice, trackballs): a negotiated minor adds a pointer record carrying running counters, not per-cycle deltas (`SAD-MAP-003`) | After the first profiles; a console profile that has a mouse |
| SAD-F-008 | F | Keyboards: key-matrix or scan-code transport and keyboard LEDs | After a profile that needs one |
| SAD-F-009 | F | Motion and tilt inputs (accelerometer-class peripherals) | New channel definition and units |
| SAD-F-010 | F | Haptics beyond two-magnitude rumble: effect model for force-feedback wheels, jog dials and patterned packs | After a profile that needs one |
| SAD-F-011 | F | Audio: microphones, headsets and accessory buzzers | New service and bandwidth budget |
| SAD-F-012 | F | Compound and linked accessories beyond one memory accessory per port: several sub-peripherals per port, Transfer Pak and GBA-link style bidirectional channels | Profile-level topology and channel design |
| SAD-F-013 | F | Controllers with more than 16 buttons or 8 axes (for example Steel Battalion): a larger or second input record type in a negotiated minor | After the input-schema freeze |
| SAD-F-014 | Retired | **Retired 2026-11-18**: concerned authenticated PlayStation 2 memory cards; dedicated-slot cards are out of scope. Not reused. | - |

Dependency chain: console/peripheral coverage -> timing/resource budget -> MCU
and storage choice -> power/isolation -> harness approval. Independently, USB
device support -> host topology -> hub resource/power budget. The bus cadence
and lease depend on measured clock and turnaround bounds, not the reverse.

### 3.1 First-console candidate comparison (informative)

Input to `SAD-O-001`; not a selection. Signal facts come from the secondary
sources in `ICD-REF-001` and must be verified before use. GPIO totals use the
baseline of `ICD-CAP-014` (two native ports and no multitap, 9 adapter system I/O, translator control
lines not yet counted); the margin rule is 70 % of 30 GPIO = 21 on RP2350A.

| Candidate | Console channels (two ports) | Total GPIO | Electrical simplicity | Timing difficulty | Other findings |
|---|---:|---:|---|---|---|
| SNES | 6 | 15 | Simplest: three signals per port, latch/clock shift register | Low (tens of kHz clock) | Fully covered by the generic model (4 face, 2 shoulders, Select/Start) |
| Mega Drive | 14 | 23 | Seven signals per port, TH-multiplexed | Medium: six-button TH counting and idle timeout | Exceeds the 21-GPIO margin on RP2350A |
| Saturn (owner's leaning) | 14 | 23 | Seven signals per port including the TL handshake output | Medium to high: TH/TR handshake; 3D Control Pad in scope | Exceeds the 21-GPIO margin on RP2350A (RP2350B or a split design); eight-button layouts need digital L2/R2 (`SAD-MAP-002`) |
| PlayStation 2 | 10 | 19 | Open-drain outputs on 3.3 V-class lines | High: serial slave with ACK timing, pressure-capable modes | Coverage needs digital L2/R2 and pressure encoding (Future) |

The envelope therefore shows that Saturn or Mega Drive would drive the first
prototype to RP2350B and a larger resource budget, while SNES stays well inside
RP2350A. The comparison is decision input only; the owner selects at Step 3.

## 4. Components and data flow

### SAD-COMP-HUB

```text
USB host / future Bluetooth
          |
device parser + physical capability descriptor
          |
normalisation + calibration -> player contexts [0..3]
          |                         |
          +---- ownership + routing manager
                                    |
                         snapshot scheduler / bus master
                                    |
                            addressed adapter

polled feedback -> route/epoch validation -> device effect driver
UI/configuration -> adapter descriptors + explicit user decisions
```

| Component | Responsibility and forbidden coupling |
|---|---|
| Device backend | Enumerate physical devices behind the hub IC (`SAD-P-009`); parse HID reports, connection changes (hub-port status, and repeated transfer errors on the device's own endpoint, since hub status polling may be slow) and capability limits (`SAD-P-011`); no console packet encoding |
| Player manager | Bind one physical source per player initially; retain capabilities and most recent state; combining devices requires a future explicit policy; on device removal keep the player context and its route and supply a neutral record (`SAD-D-010`) |
| Normaliser | Device-to-generic positions/axes, calibration and validity; no selected-console button labels |
| Ownership manager | Select owner and execute safe transitions |
| Route manager | Validate player/port uniqueness and advertised compatibility; select opaque peripheral/mapping IDs; keep a route when its device is removed and accept a replacement in place only if it supplies every control in the route's validated source masks (`SAD-D-010`) |
| Bus master | Encode PS frames, one outstanding exchange, session/transaction lifecycle, scheduling and retries |
| Management client | Read capabilities/status; configure and transfer storage/update data only in permitted states |
| Diagnostics/UI | Local owner selection, player assignment and fault indication (`SRS-UI-001..003`); show owner, routes, unknown activity, incompatible mappings, lost devices and persistent faults; display console button names only from adapter-supplied metadata; never silently arm |

Device descriptors may be internally richer than the bounded network input
format. A device requiring controls outside `PS-DATA-INPUT` is unsupported in
profile 0.1 rather than silently truncated.

### SAD-COMP-ADAPTER

```text
UART/RS-485 -> bounded framing -> transaction/session dispatcher
                                      |
          +---------------------------+-------------------------+
          |                           |                         |
  ownership/routes/input       management services       feedback queue
          |                           |                         ^
  mapping + double buffer     configuration/storage             |
          |                           |                         |
  console timing driver <---- local accessory backend ----------+
          |
       console
```

| Component | Responsibility |
|---|---|
| Network transport | DMA/ring buffers if appropriate, COBS/CRC, bounded frame parsing, driver direction |
| Dispatcher | Session/version validation, duplicate rules and fixed service dispatch |
| Input endpoint | Validate complete route generation and snapshot; convert and atomically publish all routed ports; present the idle identity with neutral controls on unrouted ports (`SAD-D-011`) |
| Console driver | Console electrical/protocol timing, virtual device identity, mode transitions, safe neutral behaviour, activity evidence |
| Storage backend | Local authoritative accessory data, media semantics, persistence and export locking |
| Feedback endpoint | Translate console feedback to generic queued effects with port/player/generation |
| Platform HAL | Time, watchdog, UART, GPIO/PIO/DMA, flash/storage and reset; explicit capabilities, not imaginary uniform hardware |
| Diagnostics | Bounded counters, last fault and resource high-water marks |
| Address store | Persisted assigned address (`PS-DISCOVERY`), written after the assignment reply and never inside a response window; if the node has no safe non-volatile store the address stays volatile and the node needs commissioning after every reset (prototype limitation) |

### SAD-ADAPT-001: multi-processor adapters

One adapter is one bus node (SRS-SYS-006) even when it contains several
processors. A single **gateway processor** owns the RS-485 node, the UID, the
address, the session, the lease and the neutralisation decision. Other processors
(for example one per Original Xbox USB device port, because each RP2350 has one
USB controller) are reached over an internal link (UART or SPI) owned by the
gateway.

- The gateway validates and maps INPUT, then forwards each port's already
  validated snapshot over the internal link; no processor other than the gateway
  accepts bus traffic. All records are validated as a set before any is
  forwarded (`SRS-IN-008`); the profile bounds the time skew between ports
  that the internal link introduces.
- The gateway enforces the lease. Every secondary processor also applies a local
  deadline: loss of internal-link refresh within the profile's internal
  deadline forces neutral controls, so link failure cannot leave live controls.
- Inhibit, REVOKE and expiry reach secondary processors as an explicit neutral
  command and as the absence of refresh; the profile's `neutralisation_bound_us`
  covers the whole path.
- A memory accessory image (`SRS-STO-005`) lives on the processor that serves
  the console. Where an adapter has several processors the gateway proxies
  Storage operations over the internal link for maintenance and never keeps a
  second copy, so there is one authoritative image.
- Which processor is the gateway (a USB processor or a separate one), the
  internal link and its timing are set by the profile supplement
  (`ICD-CON-001`).

### SAD-MAP-001: mappings and capability ownership

The hub stores physical source capabilities separately from adapter descriptors.
The adapter advertises ports, virtual peripheral IDs, supported input fields,
required controls, feedback functions and validated simultaneous combinations.
The hub transmits a physical-capability summary during route configuration.
The adapter validates compatibility; both UI and adapter must reject unapproved
lossy mappings. A replacement device is accepted in place only if it supplies
every control in the route's validated source masks (the hub sends only controls
inside them), so the adapter's validation and the user's approvals still hold;
otherwise its player's record stays neutral (`SAD-D-010`).

Initial device normalisation uses physical face positions (south/east/west/north),
shoulders, stick clicks, directional buttons and generic auxiliary functions.
Axis identities include steering and pedals. `PS-DATA-INPUT` owns exact units,
bit assignments and neutral values.

An adapter mapping declares, for example, whether a fight stick direction drives
a digital pad, whether stick input may substitute for a pad, and whether triggers
map to digital buttons. Opposing directional inputs resolve to neutral per axis
in profile 0.1. Thresholds, dead zones and hysteresis are versioned mapping data,
not invented globally for every console. Every profile declares a default idle
identity and whether a live peripheral change is allowed (`SRS-IN-011`). The
route selects mapping, not identity, so arming does not change what the console
sees. A profile that allows a change must require inhibition and state whether
console reset or re-enumeration is needed; the adapter rejects a ROUTES peripheral
that would change the presented identity unless the profile allows it.

### SAD-MAP-002: controller-coverage matrix (informative)

Generic positions are those of `PS-DATA-INPUT`. Console elements are from the
secondary sources of `ICD-REF-001` and must be verified against primary
controller documentation before a profile is approved. "Gap" means a console
element with no direct generic position; a mapping must then use an explicit,
user-visible normalisation (SRS-IN-006/007).

| Console / mode | Console elements | Coverage by the generic model | Gap or limitation |
|---|---|---|---|
| NES | D-pad, A, B, Select, Start | Complete (face, menu) | None |
| SNES | D-pad, A, B, X, Y, L, R, Select, Start | Complete | None |
| Mega Drive 3-button / 6-button | D-pad, A, B, C, Start; X, Y, Z, Mode | Four face plus shoulders and menu/aux | Six face buttons exceed four face positions; needs shoulders or digital L2/R2 |
| Saturn digital pad | D-pad, A, B, C, X, Y, Z, L, R, Start | Four face, two shoulders, menu | Six face plus two shoulders needs digital L2/R2 (or equivalent) |
| Saturn 3D Control Pad | Digital pad elements, analog stick, analog L/R, mode switch | Left stick; triggers 4/5 as analog | Same six-face gap; mode switch is adapter policy |
| Nintendo 64 | D-pad, A, B, Z, L, R, Start, four C buttons, analog stick | Face, shoulders, left stick | Z and C buttons need explicit mapping (trigger/right-stick thresholds) |
| GameCube | D-pad, A, B, X, Y, Z, Start, analog L/R plus click, main and C stick | Face, sticks, triggers 4/5 analog | Z and the L/R digital click need mapping; single on/off rumble motor |
| Dreamcast | D-pad, A, B, X, Y, Start, analog stick, analog L/R | Face, left stick, triggers 4/5 | None known; VMU/rumble accessories separate |
| PlayStation digital / DualShock | D-pad, cross, circle, square, triangle, L1, R1, L2, R2, Select, Start; sticks and L3/R3 | Face, shoulders, sticks, stick clicks, menu | L2/R2 are digital buttons: need digital L2/R2 or trigger threshold |
| PlayStation 2 DualShock 2 | As above plus pressure on twelve buttons | As above | Pressure-sensitive buttons: Future (`SAD-F-005`) |
| Original Xbox | D-pad, A, B, X, Y (analog), Black, White (analog), Start, Back, L3/R3, sticks, analog L/R | Face, shoulders, sticks, triggers 4/5 | Analog face/Black/White pressure: Future |
| Fight stick (eight-button HID) | Four face, L1/R1, L2/R2 | Four face, two shoulders | L2/R2 as buttons needs digital L2/R2 |

Generic positions to add before the PS input schema is frozen: digital left
and right trigger buttons (L2/R2). The 0.1 wire format is unchanged (bits 16..31
of `buttons` remain reserved and sent zero); the addition is a schema decision at
the freeze, not a silent substitution. Pressure-sensitive buttons are Future
(`SAD-F-005`): the 0.1 record size is fixed, so they need a negotiated minor.
Required for the first profile: only the elements of the selected console and
controller mode (`SAD-O-001`).

### SAD-MAP-003: peripherals outside the generic model (informative)

This table lists console peripherals that `PS-DATA-INPUT`, `PS-SVC-FEEDBACK`
and the 0.1 storage service cannot express, with a proposed disposition. Peripheral
facts are from general knowledge, not primary documents, and each must be verified
before a profile relies on it. Dispositions use the register classes of section 3:
F entries are Future and need a negotiated PS minor and a profile; none is
required for initial acceptance. The classification is proposed and awaits owner
confirmation. An adapter shall not advertise (`SRS-NET-002`) or silently
approximate (`SRS-IN-007`) a peripheral it cannot represent.

| Gap | Examples (console) | Why PS 0.1 cannot express it | Disposition |
|---|---|---|---|
| Relative pointing | Mouse: SNES, N64, Mega Drive, Saturn, PlayStation, Dreamcast; NES Arkanoid paddle is absolute | Axes are absolute; deltas must be accumulated without loss | `SAD-F-007` |
| Light guns | Zapper, Super Scope, Menacer, Virtua Gun, Guncon/G-Con, Dreamcast and Xbox guns | Need CRT video timing; no video input | Excluded by `ICD-CAP-017` (not Future) |
| Keyboards | Famicom, N64 Randnet, Saturn, Dreamcast, GameCube | No key-matrix or scan-code model; LEDs | `SAD-F-008` |
| Analog (pressure) buttons | PS2 DualShock 2 (12 buttons), Original Xbox face/Black/White, NeGcon | Button bits are 1 bit | `SAD-F-005` (existing) |
| Motion and tilt | Dreamcast maracas and fishing controller, Power Glove, N64 Bio Sensor | No motion channels or units | `SAD-F-009` |
| Rich haptics | JogCon (force-driven jog dial), force-feedback wheels, Dreamcast Jump Pack patterns | Feedback is two magnitudes, no effect model | `SAD-F-010` |
| Audio | Dreamcast microphone, N64 VRU, GameCube microphone, Xbox Communicator, VMU buzzer | No audio path | `SAD-F-011` |
| Displays | VMU LCD, PocketStation LCD | No display service in 0.1 | `SAD-F-006` (design in `PS-SVC-DISPLAY`) |
| Compound and linked accessories | Dreamcast controller + rumble pack alongside the VMU; N64 Transfer Pak; GameCube GBA link; Xbox Memory Unit (out of scope, owner decision) and Communicator slot | One virtual peripheral per port besides the memory accessory; linked devices need a bidirectional channel (the memory accessory itself is in scope, `SRS-STO-005`) | `SAD-F-012` |
| Oversized controllers | Steel Battalion (about 40 buttons, pedals, lever, backlit buttons), Densha de Go controllers | More than 16 buttons or 8 axes | `SAD-F-013` |
| Dedicated-slot memory cards | GameCube, PlayStation and PlayStation 2 cards (PS2 cards are also authenticated) | Separate card slot sharing no signals with the controller port | Out of scope (owner decision); not Future |

Fits with caveats (no register entry; the profile states the limits):

- Racing wheels: steering plus combined pedals; separate pedals use axes 4/5;
  clutch and shifters are not represented (`PS-DATA-INPUT`).
- Guitars: buttons plus one axis. Dance mats and fight sticks: buttons.
- Saturn Mission Stick: stick, but the throttle has no dedicated axis; a profile
  mapping is an explicit user-visible decision.
- Rumble and storage accessories: rumble through `PS-SVC-FEEDBACK` (single-motor
  consoles reduce the two magnitudes); N64 Controller Pak and Dreamcast VMU memory through
  the Storage service.
- Multitaps (NES Four Score, SNES, Mega Drive, Saturn, PlayStation, PlayStation 2):
  the adapter emulates the tap and each slot is a port (`SAD-P-013`); the generic
  model does not change.

Design note for `SAD-F-007`: a mouse sample is not a snapshot. `PS-TIMING` never
retries INPUT and the newest sample wins, so per-cycle deltas would be lost on a
dropped exchange. A relative record shall carry running counters (wrapping, with
difference arithmetic in the adapter) instead of deltas.

For the leading first-console candidate (Saturn, `SAD-O-001`) none of these gaps
blocks the digital pad or the 3D Control Pad; only the digital L2/R2 position of
`SAD-MAP-002` applies.

## 5. SAD-OWN-001: ownership and routing

### Policy

Default selection mode is **manual**. At boot there is no owner. Manual
selection may choose a ready adapter even if activity is unknown; the UI shall
show the uncertainty. A definite unsafe/unready electrical or peripheral state
cannot be overridden by selection.

Opt-in automatic mode selects a candidate only if exactly one ready adapter
reports stable `ACTIVE` for 500 ms, every other enrolled adapter is known
`INACTIVE`, and every roster node has a current status no older than 500 ms.
`UNKNOWN`, stale/offline roster members or multiple active nodes block automatic
selection. Offline members may be explicitly removed from the roster, not
silently ignored. No automatic takeover occurs while an owner exists. Selected
owner inactivity stable for 2 s initiates release; unknown/stale status initiates
release after 500 ms without fresh evidence. Bus failure independently triggers
the adapter lease timeout.

These activity debounce periods are P policy values, distinct from the 100 ms
safety lease. Manual and automatic paths use exactly the same transition engine.

### Hub states

| State | Entry/action | Exit |
|---|---|---|
| BOOT_GUARD | Stop transmitting old traffic; create new non-repeating session; inhibit local routes/effects; wait 110 ms | Scan roster and negotiate, then NO_OWNER |
| NO_OWNER | No live input grants; neutral state; accept selection request | Valid target -> PREPARE |
| PREPARE | Confirm descriptors/version; configure complete routes while target inhibited; obtain new generation | Validation success -> ARMING; error -> NO_OWNER |
| ARMING | Send ARM with complete generation and player capability-approved routes; initially neutral | ACK then fresh snapshot -> ACTIVE; uncertainty -> RELEASING |
| ACTIVE | Periodic snapshots renew lease; poll feedback/status; a removed device's record is sent neutral (`SAD-D-010`) | Switch, route/profile change, timeout or release -> RELEASING |
| RELEASING | Stop all renewals; cancel queued old input; send REVOKE; stop physical effects | Inhibit ACK plus 2 ms drain guard, or 110 ms since last possible renewal -> NO_OWNER or PREPARE queued target |
| FAULT | Inhibit, show explicit fault; no silent rearm | User recovery -> BOOT_GUARD |

Route edits use release -> configure -> arm even for the same console. There is
no live in-place reroute in this profile. A physical device removal does not
inhibit the ownership generation: the hub keeps the player's route and sends its
record neutral (`SAD-D-010`), so the other players continue and the same INPUT
keeps renewing the lease. A replacement device that supplies every control in the
route's validated source masks resumes in place; any other device leaves the
record neutral until the routes are replaced, and whether that may happen on
connection or only on user action is open (`SAD-O-014`).

`REVOKE` acknowledgement means neutral control state has been installed, pending
input discarded and effects stopped. A console transaction already in progress
may finish from its previously latched snapshot; per-console drivers shall bound
that completion and declare it as `neutralisation_bound_us` in CAPS (kind 4),
proved by measurement at the console connector to be visible to the console, not
only installed in local state. A profile that cannot meet the 1 ms global bound
cannot claim the provisional lease/transfer timing; safe switching for it
requires a larger validated guard approved by the owner (`SAD-D-008`). The hub
computes its guards from the maximum bound over enrolled adapters.

The transfer engine starts a new ARM only after the old owner cannot still
expose live controls. After a revoke ACK it waits a further local drain guard,
`max(2 ms, 2 x B)` where `B` is the largest declared bound, before starting a new
ARM; with all bounds at most 1 ms this is 2 ms and exceeds the old console
transaction's completion bound even with both clocks at their worst qualified
drift. If a revoke ACK is lost, wait the lease guard rather than assume success.
The 110 ms clock guard is measured from the latest possible acceptance of the
last old renewal (including any uncertain ARM), after queued transmissions are
cancelled: use response completion, or the full per-opcode response timeout when
no reply arrived, as defined in `PS-TIMING`. The transport must report that
timestamp. With unknown old traffic on hub boot, start a full guard before any
new grant. A manual switch completes within 500 ms nominal (`SRS-OWN-012`):
the lost-revoke path costs the 110 ms guard plus route configuration and ARM.

### Adapter states

```text
RESET -> UNASSIGNED            (no valid persisted address)
RESET -> INHIBITED             (valid persisted address; HELLO required before routes)
UNASSIGNED --targeted address assignment--> INHIBITED or RECOVERY
INHIBITED --compatible HELLO + valid ROUTES--> CONFIGURED
CONFIGURED --ARM--> ARMED_NEUTRAL
ARMED_NEUTRAL --fresh complete INPUT--> LIVE
LIVE --fresh complete INPUT--> LIVE (renew lease)
ARMED_NEUTRAL / LIVE --REVOKE or expiry or fault--> INHIBITED
INHIBITED --exclusive maintenance admission--> MAINTENANCE
MAINTENANCE --safe close--> INHIBITED
MAINTENANCE --safe new-session takeover--> INHIBITED or RECOVERY
any --reset--> RESET
```

RECOVERY permits session negotiation and diagnostics, never ownership.
UNASSIGNED is not addressable by STATUS; the hub reaches it only through
commissioning. The assigned address is persisted by the adapter after the
assignment reply, so an ordinary adapter or console power cycle returns the node
to INHIBITED at its address and the hub confirms the UID in HELLO; no
re-commissioning and no physical commissioning enable are needed, consistent
with `SRS-OWN-010`. Physical commissioning enable is needed only for a first
install, a UID mismatch or an address conflict, and asserting it clears the
persisted address. A node without a safe non-volatile store keeps the address
volatile and needs commissioning after every reset; that is a prototype
limitation, not a profile feature.

Generation is cleared when inhibition occurs; routes must be configured again.
The adapter enforces its own monotonic lease even if network parsing stops.
Only accepted ARM and newer complete INPUT renew it; status polls, duplicates,
invalid packets and unrelated commands do not. Session, route generation, port,
player, capabilities and sample sequences are checked before publishing.

Two independent time domains exist: hub session/transaction ordering and adapter
local lease time. No synchronised wall clock is required.

### Example: PS2 selected, two independent sources

The hub binds player 0 to a USB gamepad and player 1 to a fight stick. It selects
one PS2 adapter, receives that adapter's opaque compatible peripheral/mapping
IDs and configures player 0 -> port 0, player 1 -> port 1. The adapter decides
how generic controls map to its PS2 peripheral modes. One INPUT publishes both
players. That adapter advertises two ports (no multitap in its profile), so a
third or fourth source would stay unrouted (`SRS-SYS-010`). If the fight stick is
unplugged, player 1's record turns neutral while player 0 plays on
(`SAD-D-010`). Another powered adapter continues to answer its console with
neutral controls. Selecting it first releases the PS2 owner; player contexts need
not change, but routes and mapping compatibility are validated anew.

## 6. SAD-SCHED-001: concurrency and timing

The hub uses a monotonic deadline scheduler, not an unrestricted management
request queue. It selects the newest complete player samples at each 5 ms
boundary, prioritises owner INPUT, then feedback/status, then bounded management
chunks, then display data (lowest, `SAD-F-006`). Each opcode has its own response timeout (`PS-TIMING`), and a
non-input exchange is admitted only if its worst-case timeout path ends before
the next reserved input slot; the cycle budget table in `PS-TIMING` shows that
a four-record INPUT, FEEDBACK_POLL and one STATUS all timing out still fits within 5 ms (4.26 ms).
An INPUT is never retried: a lost exchange is replaced by the next cycle's
newest sample (`SRS-PERF-005`). No bulk transaction starts unless its worst-case
completion, including timeout and guard, fits before the next reserved input
slot. A maximum-size transaction (2.15 ms timeout path at 2 Mbit/s) fits in most
cycles but not after several timeouts; reduce chunk size or defer to maintenance
when it does not fit. A display exchange is admitted only in the slack that
remains after the due INPUT, feedback, status and management exchanges, so it
cannot delay them.

Status scanning must satisfy the automatic-policy freshness window for the
enrolled roster or automatic selection stays blocked. Management transfers may
pause normal status scans only while automatic selection is unavailable and
there is no active owner. Input/lease traffic always wins while armed.

The adapter separates a console real-time execution domain from network and
management work. PIO/DMA, interrupts, separate cores or processors are options.
The design shall specify ownership of buffers and peripherals, interrupt
priorities, worst-case blocking and memory barriers before implementation.
An atomic pointer/index swap after constructing all mapped player snapshots
is preferred to updating fields visible to the timing driver.

Lease expiry runs in a deadline mechanism that remains effective during parser
overload and permitted storage activity. Watchdog, flash/XIP stalls, DMA bus
contention and multicore shared data require explicit analysis; "dual core" is
not proof of real-time isolation.

## 7. SAD-FB-001: feedback

Console drivers queue generic rumble/indicator events. They never write to the
bus spontaneously. The adapter reports the console's native effect richness (for
example two magnitudes even when the console motor is on/off); the hub reduces
that to what the bound physical device supports and reports any loss
diagnostically. The hub polls the owner adapter every 10 ms while armed
(interleaved in the cycle budget of `PS-TIMING`; with three or four routes it may
poll every cycle, which still ends inside 5 ms), validates
session/generation/port/player and
current physical binding, and translates to a supported device operation.
Unsupported effects produce a diagnostic result rather than a false success.
An event for a player whose device was removed is discarded with a diagnostic.

Effects use bounded duration and require refresh. Zero rumble is an explicit
stop. The hub stops effects locally on revoke, device disconnect, expiry or link
loss without waiting for an adapter message. Overflow coalesces the newest
rumble/LED state per route, increments a counter and does not grow a queue.
The PS defines event IDs and acknowledge-on-next-poll behaviour.

## 8. SAD-PERSIST-001: configuration, storage and update

Configuration is a bounded, adapter-defined versioned blob. A replacement is
staged, validated, durably committed and then activated while inhibited. The
hub does not interpret console protocol fields in it. The adapter keeps a last
known valid configuration or enters an explicit recovery fault.

Accessory storage is authoritative at the adapter. The local console driver
handles console checksums, blocks, addresses and emulated-media identity.
Memory-card storage is in scope and is the adapter's responsibility
(`SRS-STO-005`): one controller-port accessory per emulated port, held as a local image whose
capacity, storage device, access time, power-fail behaviour and endurance are
determined per profile under `ICD-STO-001`. The image is held in an external
FRAM, outside the MCU (`SRS-STO-008`, `SAD-P-012`). The accessory image lives on the
processor that serves the console (`SAD-ADAPT-001`); an adapter gateway proxies
maintenance transfers and never keeps a second copy. Console writes are
written through to the FRAM and acknowledged to the console only after the write
completes, so an FRAM accessory is never dirty (`dirty_resources` in STATUS stays
zero); a profile using the flash exception reports dirty data, which blocks
maintenance, reset and update (`SRS-UPD-002`).
The network only sees opaque resource IDs and bytes. Exclusive maintenance
requires no owner and a proven quiescent console accessory interface; neutral
buttons alone do not mean that a console has stopped writing a memory accessory.
Profiles unable to quiesce safely require console disconnection/power-off
verified by their hardware mechanism. Otherwise maintenance is refused.

Persistent commits require a design such as journalling, copy-on-write or a
verified equivalent; the particular media policy is O. Console acknowledgement
semantics may differ from network export semantics and must be documented.
The driver may not acknowledge console writes earlier than its advertised
durability policy permits.

Update services are optional and Future for the first prototype (`SRS-UPD-004`,
`SAD-F-004`). The generic protocol can transport an image but
cannot invent a safe bootloader or signature format. A concrete advertised
update profile must specify hardware compatibility, manifest, digest/signature,
staging, activation and rollback/recovery, and may use the RP2350 boot-ROM
facilities only with a prototype/production distinction so that development
boards are never irreversibly locked by accident. No safe profile -> no update service.
Local physical update enable is required in this trusted-bus draft.

## 9. Common adapter framework

Proposed reusable modules:

- Codec/transport and fixed service dispatcher.
- Session, ownership lease, route validation and snapshot publication.
- Generic configuration, resource handles, persistence error contracts.
- Diagnostics and optional update orchestration.
- HAL contracts for monotonic time, watchdog, UART direction and storage.

Console drivers provide:

- Supported port/peripheral combinations and mapping descriptors.
- Start/stop, neutralise and publish-snapshot operations with timing contracts.
- Console activity evidence and quiescence checks.
- Accessory resource backends and generic feedback production.
- Resource constraints and safe peripheral-mode transition rules.

A framework callback shall return explicit supported/unsupported/error status,
never a success-shaped no-op. The framework must not force every console driver
into a polling loop or a shared low-level PIO design.

A separate framework specification is not needed yet: it would duplicate
unproven interfaces. Extract one after two different console drivers reveal
stable contracts, retaining these document IDs and cross-references.

## 10. Fault model, trust and development sequence

The current bus is physically trusted. CRC addresses accidental corruption, not
malicious injection. A party on the bus can impersonate the hub; session IDs and
leases are stale-message protection, not authentication. No network exposure or
unattended remote update is permitted by this profile. Future security decisions
require a separate threat model and may change framing/firmware policy.

Shorted transceivers, duplicate UIDs, address conflicts, inaccurate clocks and
wedged console drivers are not repaired by retransmission. Nodes fail inhibited,
surface diagnostics where possible and require recovery or re-commissioning.
A bus failure must not corrupt local console accessory data.

Recommended development sequence:

1. Select one console profile and qualify its electrical interface.
2. Prototype two local ports and accessory timing without the shared network.
3. Implement/test codecs, leases and routing on simulated adapters.
4. Qualify bus hardware, commissioning and two USB devices.
5. Demonstrate two-player ownership, switch/loss/reset cases and measured latency.
6. Add persistence, maintenance and optional update only after recovery testing.
7. Implement a second console and refine the common framework from evidence.
8. Extend to four players, four-port consoles and multitaps one increment at a
   time, each backed by the four-record evidence of `SRS-V-007` and the
   profile's resource table.

All stages feed [SRS verification](SRS.md#9-verification-and-traceability).
No stage or document is marked validated by this draft.
