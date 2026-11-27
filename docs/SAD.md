# Software Architecture Description

| Control field | Value |
|---|---|
| Document ID | RPN-SAD |
| Revision | 0.2 |
| Status | Baseline for review |
| Date | 2026-11-27 |
| Companion documents | [RPN-SRS](SRS.md), [RPN-ICD](ICD.md), [RPN-PS](PS.md), [RPN-AFS](AFS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Architecture review, decision register, safe ownership, framework boundaries and scheduling model. |
| 0.1 (2026-11-18) | Correction cycle: RP2350 platform, document-authority, hardware-isolation, port-scope and USB decisions registered; persistent addresses, per-profile neutralisation bound, multi-processor adapters, controller-coverage matrix, console comparison, scheduler admission rule and feedback cadence added. |
| 0.1 (2026-11-18) | Line rate 2 Mbit/s (trunk under 5 m); display lowest-priority scheduling rule; full duplex considered and not adopted. |
| 0.1 (2026-11-18) | Peripherals outside the generic model catalogued in SAD-MAP-003 with register entries. |
| 0.1 (2026-11-18) | Memory-card accessory storage: register entries, SAD-PERSIST-001 accessory paragraph, SAD-MAP-003 narrowed. |
| 0.1 (2026-11-18) | Two-bank layout and shared SPI bus for accessory storage. |
| 0.1 (2026-11-18) | Emulated memory-card contents in external FRAM (register and SAD-PERSIST-001). |
| 0.1 (2026-11-18) | Memory-card scope set to controller-port accessories; three register entries withdrawn; SAD-MAP-003 row replaced. |
| 0.1 (2026-11-24) | Player count raised from two to four: neutral record for a removed device, idle pad on unrouted ports, multitaps inside the adapter, Original Xbox four USB device ports; hub states, removal handling, SAD-ADAPT-001 and SAD-MAP-003 updated. |
| 0.1 (2026-11-25) | Document-authority entry reworded to drop an obsolete cross-reference; no requirement changed. |
| 0.2 (2026-11-27) | Specification baseline: section 2 becomes design rationale; section 3 becomes the design-decision register, renumbered SAD-001 to SAD-053 (every SAD-D, SAD-P, SAD-O and SAD-F identifier withdrawn); 1 ms scheduling at 8 Mbit/s; HID subset and acceptance corpus (SAD-MAP-001); full peripheral coverage (SAD-MAP-002); pointers, keyboards, wheels and pressure (SAD-MAP-003); hub user interface (SAD-UI-001) and adapter display (SAD-DISP-001); route amendment, late join and the activity rule (SAD-OWN-001); force feedback and keyboard LEDs (SAD-FB-001); node configuration store, live export, USB drive and update profile (SAD-PERSIST-001); framework contracts moved to RPN-AFS; development sequence removed. |

## 1. Architecture intent

One hub models four players and acquires modern input. Each console adapter models
one console's peripheral ecosystem. The network carries generic state and management
operations, not console bit-level transactions. Console response timing is satisfied
entirely from adapter-local state.

Classification F/D follows [RPN-SRS](SRS.md#1-purpose-and-interpretation). The
adapter software contracts are specified in [RPN-AFS](AFS.md).

## 2. Design rationale

| ID | Concern | Design response |
|---|---|---|
| SAD-R-001 | One MCU per adapter cannot serve every four-port, accessory and USB-device combination | One logical adapter may use multiple processors under one network node (`SAD-ADAPT-001`); the Original Xbox adapter uses one processor per emulated USB device port; per-annex resource tables under the 70 % rule |
| SAD-R-002 | A generic input model can leak console-specific mapping into the hub | Positional generic controls; mappings and virtual peripherals owned by the adapter; device and virtual descriptors separated; console names only on the adapter display |
| SAD-R-003 | Broadcast discovery on half-duplex RS-485 can collide; CRC is not reliable arbitration | Commissioning of the single enabled node without its UID, and enumeration of unknown nodes by a presence signal that any number of nodes can send at once without corruption (`SAD-014`, `SAD-035`) |
| SAD-R-004 | "Active console" does not define exclusivity, particularly after lost acknowledgements | Explicit single-owner lease, generation fencing, boot guard and revoke-or-expire switching |
| SAD-R-005 | A player assignment is not an ownership grant | Routes configured while inhibited; arm is a separate operation; atomic multi-player snapshots; an armed amendment changes one route and never renews the lease |
| SAD-R-006 | A network storage service cannot satisfy console accessory deadlines | Local authoritative storage; import only in exclusive maintenance; export from a coherent local snapshot |
| SAD-R-007 | Service-oriented architecture can imply unnecessary RPC or a plug-in framework | Fixed bounded opcode groups plus a service bitmap and descriptors; no dynamic broker or runtime plug-ins |
| SAD-R-008 | Platform choice does not by itself establish USB-host capacity or flash-time isolation | RP2350 family (`SAD-004`); the single native USB controller is extended by a hub IC (`SAD-020`); configuration and accessory data in external non-volatile parts that never stall execution; flash written only in maintenance |
| SAD-R-009 | A fast line rate does not by itself bound latency: turnaround and replies consume the cycle | 1 ms cycle with one INPUT and one other exchange, per-opcode timeout classes and deadline-based admission (`PS-TIMING`) |
| SAD-R-010 | Emulating accessory storage is not emulating the complete accessory | Each annex declares the accessory functions it presents (VMU storage and display; Controller Pak; Rumble Pak; vibration pack) |
| SAD-R-011 | A shared bus may join console grounds and supplies | Isolated transceiver at every node with its bus side on the hub-supplied NET_PWR (`SAD-021`, `SAD-025`) |
| SAD-R-012 | CRC, version negotiation and firmware recovery do not provide authentication | Physically trusted local bus, physical update enable, security boundaries stated explicitly (`SAD-030`) |

## 3. Design decisions

This register is the shared design-decision authority; other documents reference
it.

| ID | Class | Decision | Evidence |
|---|---|---|---|
| SAD-001 | F | The hub has no console-specific wire-protocol logic; adapters own console semantics | Component dependency review |
| SAD-002 | F | Four independent players (`SRS-SYS-002`); multiple powered consoles; one selected console owner | Ownership and multi-port tests |
| SAD-003 | D | Console timing and accessory I/O use local state, not bus round trips | Per-annex timing analysis |
| SAD-004 | F | The hub and every adapter processor are RP2350 family members (`SRS-HW-005`). An exception requires documented evidence that the family cannot meet a named requirement, the project owner's approval and an entry in this register naming the adapter, scope and evidence; none exists | Per-annex resource tables |
| SAD-005 | D | Document authority: the ICD is the single electrical authority; its console annexes hold the per-console facts and section 8 the common capabilities and GPIO sizing | ICD section 8 and annexes |
| SAD-006 | D | No console-facing signal relies on MCU 5 V tolerance or internal pulls; voltage domain and drive type are fixed by each console connector module, identified to firmware, and firmware refuses a mismatching profile (`SRS-HW-006`, `ICD-CAP-003/004`) | ICD-VER-001..006, ICD-VER-015 |
| SAD-007 | D | Every annex declares a default idle peripheral identity and whether live identity change is allowed; the route selects mapping, not identity (`SRS-IN-011`) | Annex review |
| SAD-008 | D | Every annex declares `neutralisation_bound_us` (CAPS kind 4); hub drain and uncertain-transfer guards derive from the maximum over enrolled adapters; a profile that cannot meet the 1 ms global bound is not approved (`SRS-OWN-013`) | ICD-VER-016, PS-TIMING |
| SAD-009 | F | Memory accessory storage attached through the controller port (N64 Controller Pak, Dreamcast VMU) is the adapter's responsibility: one accessory per emulated port, authoritative local image, resources stated per annex (`SRS-STO-005..006`, `ICD-STO-001`) | ICD-VER-021, SRS-V-005 |
| SAD-010 | F | When the device of a routed player is removed, lost, or replaced and awaiting validation, the route stays and carries a neutral record (`SRS-IN-013`); the other players, the ownership generation and the lease are unaffected. A replacement the route cannot accept (`SAD-MAP-001`) leaves the record neutral until the route is amended (`SAD-033`) | Device removal and replacement tests in `SRS-V-002` |
| SAD-011 | F | An emulated port without an active device presents the annex's default idle peripheral identity with neutral controls (an idle pad), never an absent controller (`SRS-IN-014`) | Annex idle identity; `SRS-V-002` |
| SAD-012 | F | RS-485 at 8 Mbit/s, half-duplex, one master, up to 31 addresses, up to 10 adapters on a trunk under 5 m. Half duplex keeps the one-outstanding-request model and one isolated pair per node; the 1 ms cadence, not the line rate, dominates latency | ICD-VER-017, ICD-VER-020 |
| SAD-013 | F | Compact fixed services over COBS/CRC-32C framing; 192-byte payload bound, 183-byte storage chunk, 4096-byte configuration, 64-entry CAPS lists, partial frame dropped after 3 ms | Codec tests and the PS vector appendix |
| SAD-014 | F | Commissioning: the 128-bit vendor UID is held in a hard-locked OTP page and printed on a label; the hub's "add adapter" discovers the single node whose physical commissioning enable is asserted with DISCOVER_UID carrying an all-zero UID, assigns an address, which the adapter persists in its configuration store within the 10 ms ASSIGN completion window, and confirms the UID in HELLO. The enable is needed only for a first install, a UID mismatch or an address conflict | `PS-DISCOVERY` tests, SRS-V-013 |
| SAD-015 | F | 1 ms snapshots; per-opcode timeout classes; a non-input exchange is admitted only if its timeout path ends before the next input slot; feedback polled every 2 ms; status at least every 4 ms; 100 ms ownership lease; 110 ms reboot/uncertain-transfer guard | Cycle budget in PS-TIMING; SRS-V-007 |
| SAD-016 | F | One selected virtual peripheral per port, plus the memory accessory and sub-peripherals its annex declares; four routes at most; no fan-out | SRS-V-002 |
| SAD-017 | F | Storage import, configuration and update transfers only in exclusive maintenance; accessory export also from a live snapshot (`SAD-036`) | Quiescence, durability and recovery tests |
| SAD-018 | F | Arm Cortex-M33 cores only. RP2350A is the default part; RP2350B where an annex's GPIO budget needs it (Saturn, Mega Drive, N64, PlayStation 2, Dreamcast; ICD section 8.3); stacked-flash parts (RP2354A/B) are preferred | ICD-PLAT-001; annex resource tables |
| SAD-019 | F | An adapter emulates every native console port up to four (`SRS-SYS-009`); the Original Xbox adapter provides four USB device ports, one processor per port, with the port-0 processor as gateway owning the bus node (`SAD-ADAPT-001`) | Annex J |
| SAD-020 | F | The hub USB host uses the single native RP2350 USB controller behind a USB hub IC with four downstream ports, switched VBUS at 500 mA per port; no software USB host | ICD-VER-018, ICD-HUB-001 |
| SAD-021 | F | Power and isolation: every node, hub included, connects to the bus through an isolated RS-485 transceiver whose bus side is powered from NET_PWR; an adapter's console side is powered from its console, by the controller-port supply where the annex shows it suffices, otherwise by a pass-through of the console's own power source | ICD-VER-024, ICD-VER-026, ICD-VER-030 |
| SAD-022 | F | USB input acceptance by descriptor parsing only: any device whose HID report descriptor parses under the subset of `SAD-MAP-001` is accepted for input whatever its brand; a device needing a vendor class driver, initialisation handshake or authentication is not supported (`SRS-IN-012`) | Acceptance corpus, SRS-V-002 |
| SAD-023 | F | Accessory storage: external SPI FRAM per port on one shared SPI bus with serialised DMA-driven access; banks A and B, snapshot region S and a mirrored CRC-protected bank-select record; write-through; RAM only as a non-authoritative latency cache (`SRS-STO-008`, `SRS-STO-011`) | ICD-VER-021 |
| SAD-024 | F | Multitaps are emulated inside the adapter: each tap slot is a port (0..3) of the same adapter, so the hub, the routes and the wire need no tap knowledge; SNES Super Multitap, Sega Team Player, Saturn multitap, PlayStation multitap and PlayStation 2 multitap, each selectable against direct ports by a user option | ICD-VER-022 |
| SAD-025 | F | Harness: shielded RJ45 daisy chain with through-wired receptacles, 100 ohm Cat5e cable, NET_P/NET_N, NET_PWR and NET_REF pairs, shield at the hub; cables connected only with everything powered off (`ICD-NET-002`) | ICD-VER-024, ICD-VER-027 |
| SAD-026 | F | Each console's processor, PIO, USB and timing allocation is specified in its ICD annex and held within the 70 % resource rule | Annex resource tables |
| SAD-027 | F | Persistent media: each node keeps its address record, configuration and options in a dedicated I2C FRAM or EEPROM configuration store with mirrored CRC-protected records; firmware images in MCU flash slots written only in maintenance; accessory images in FRAM (`SAD-023`) | ICD-VER-028, SRS-V-005 |
| SAD-028 | F | Activity: one rule for every adapter (`SRS-OWN-014`): ACTIVE with console power present and a valid poll within 100 ms, INACTIVE with console power absent, UNKNOWN otherwise; an enrolled adapter that is silent because unpowered counts as INACTIVE for automatic selection. Automatic selection is opt-in from the hub's local controls | SRS-V-003 |
| SAD-029 | F | Mapping, calibration and approvals: adapters advertise mapping IDs with their thresholds, dead zones and hysteresis; the hub adds a free per-device remapping layer and a user calibration routine, both stored in the hub; lossy mappings are approved once per device, route and mapping on the hub display; fight sticks use the same latency bounds as every device class | SRS-V-010, SRS-V-011 |
| SAD-030 | F | Update profile and security posture: integrity-checked update with an image header (target hardware ID, version, length, SHA-256), A/B slots, verification, activation only with the physical update enable, trial boot with automatic rollback and recovery over SWD; no signatures, no secure boot, no OTP keys; the bus is physically trusted with no authentication or encryption (`SAD-PERSIST-001`, section 10) | SRS-V-012, SRS-V-013 |
| SAD-031 | F | Adapter processing budget: a complete four-record INPUT is validated, mapped and installed and the response started within 100 us of the request's last stop bit (`SRS-PERF-006`); mapping runs from RAM-resident tables on the core that does not run console timing | SRS-V-006 |
| SAD-032 | F | Storage resources carry a port binding in CAPS kind 1 (port or device-wide), so the hub labels files and menus "port n memory" without console knowledge | PS-SVC-STORAGE |
| SAD-033 | F | Late join and amendment: ROUTES configures a route for every emulated port, each assigned to a player, with a device or not; a route without a device takes its required controls as source and carries a neutral record; a device bound later resumes in place if it supplies them; otherwise, or to change mapping, source controls or player, the hub amends that one route while armed (ROUTES_AMEND), which neutralises only that port and never renews the lease | SRS-V-002 |
| SAD-034 | F | Tap models: SNES Super Multitap on connector 2; Sega Team Player on connector 1; Saturn multitap on connector 1 with slots 1 to 4; PlayStation multitap on connector 1 or 2; PlayStation 2 multitap on connector 1 and memory-card slot 1 (ICD annexes B, C, D, H, I) | ICD-VER-022 |
| SAD-035 | F | Unknown-node enumeration: the hub finds unassigned nodes by a binary search over UID prefixes with ENUMERATE, which every matching unassigned node answers with the same constant presence level, then reads boot ID and assigns the address of each found UID by DISCOVER_UID and ASSIGN_UID | ICD-VER-029, SRS-V-013 |
| SAD-036 | F | Live export: a coherent snapshot of an accessory, built in FRAM region S while the console's storage interface is idle, is exported by STORAGE reads admitted in the cycle's management slot, also while the console is the armed owner | SRS-V-015 |
| SAD-037 | F | The adapter software framework contracts are specified in RPN-AFS | RPN-AFS review |
| SAD-038 | F | Pressure-sensitive buttons: INPUT record kind 1 carries 8-bit pressure for twelve generic positions; a binary source maps to full or zero pressure under an approved lossy mapping | SRS-V-011 |
| SAD-039 | F | Pointers: INPUT record kind 2 carries running X, Y and wheel counters, never per-cycle deltas, so a lost INPUT loses no motion | SRS-V-011 |
| SAD-040 | F | Keyboards: INPUT record kind 3 carries modifiers and up to six HID keyboard usages; console keyboard LEDs return as feedback kind 5 | SRS-V-011 |
| SAD-041 | F | Force feedback: feedback kinds constant force, spring and damper in addition to rumble, reduced by the hub to the bound device's HID Physical Interface Device effects | SRS-V-008 |
| SAD-042 | F | Compound accessories: the Dreamcast controller presents a VMU in expansion slot 1 and a vibration pack in slot 2 on every port | SRS-V-005 |
| SAD-043 | F | Wheels: steering axis 6, accelerator and brake on axes 4 and 5 under a wheel mapping (or the combined pedal axis 7), shift-up and shift-down buttons; no clutch | SRS-V-011 |
| SAD-044 | F | Digital left and right trigger buttons occupy `buttons` bits 16 and 17 | PS-DATA-INPUT |
| SAD-045 | F | Displays: the hub shows hub information in generic terms; each adapter's own display shows its state, routes and console-named mappings, user-option names, prompts and the Dreamcast VMU screens, which never cross the bus (`SAD-DISP-001`) | SRS-V-010 |
| SAD-046 | F | Hub local interface: colour display, four buttons (up, down, select, back) and a recovery button; all indication on screen (`SAD-UI-001`) | SRS-V-010 |
| SAD-047 | F | Management path: a USB flash drive on any free hub downstream port (every operation while no owner is armed; accessory export also while an owner is armed, at the lowest USB priority) carries accessory images, configurations, firmware images and diagnostic snapshots as files, driven from the hub's local controls (`SAD-PERSIST-001`) | SRS-V-015 |
| SAD-048 | F | Recovery and debug: three-pin SWD on every processor and a recovery input that starts the node in RECOVERY; debug stays enabled (`ICD-DBG-001`) | ICD-VER-023 |
| SAD-049 | F | Supplies: hub powered from a standard USB-C charger advertising 3.0 A (no USB Power Delivery); adapters powered from their consoles; no supply unit is specified by RPN | ICD-VER-025, ICD-VER-026 |
| SAD-050 | F | Multi-processor installation: whole-set validation precedes forwarding; installation is atomic per port; a forwarding failure neutralises that port and raises fault 2; the annex bounds the skew between ports | SRS-V-002, Annex J |
| SAD-051 | F | Accessory and rumble selection: the N64 adapter presents Controller Pak, Rumble Pak or no accessory per port by user option (default Controller Pak); every console rumble source in scope is forwarded | SRS-V-005, SRS-V-008 |
| SAD-052 | F | Coverage: ten consoles, the virtual peripherals of `SAD-MAP-002`, every console revision with detachable controller ports | SRS-V-001 |
| SAD-053 | F | Extra console signals are used exactly where a presented peripheral or tap needs them: SNES Data2 and IOBit, Sega Team Player TR direction, PlayStation 2 memory-card slot (`ICD-CAP-020`) | ICD-VER-022 |

Dependency chain: console and peripheral coverage -> timing and resource budget -> MCU
and storage choice -> power and isolation -> harness. Independently, USB device classes
-> host topology -> hub resource and power budget. The bus cadence and lease depend on
measured clock and turnaround bounds, not the reverse.

## 4. Components and data flow

### SAD-COMP-HUB

```text
USB host (behind hub IC)
          |
HID parser + physical capability descriptor
          |
calibration + remapping + normalisation -> player contexts [0..3]
          |                                     |
          +----------- ownership + routing manager
                                                |
                                 snapshot scheduler / bus master
                                                |
                                        addressed adapter

polled feedback -> route/epoch validation -> HID output (haptics, PID, LED)
local UI -> adapter descriptors, user options, prompts and explicit user decisions
USB drive <-> maintenance transfers (storage, configuration, update, diagnostics)
```

| Component | Responsibility and forbidden coupling |
|---|---|
| Device backend | Enumerate physical devices behind the hub IC (`SAD-020`); parse HID reports under the subset of `SAD-MAP-001`; detect connection changes (hub-port status, and repeated transfer errors on the device's own endpoint, since hub status polling may be slow); mount a USB flash drive on a free port (`SAD-047`); no console packet encoding |
| Player manager | Bind one physical device per player; retain capabilities and most recent state; on device removal keep the player context and its route and supply a neutral record (`SAD-010`) |
| Normaliser | Device-to-generic positions, axes, pressure, pointer counters and key usages; apply the device's calibration and remapping (`SAD-029`); no console button labels |
| Ownership manager | Select owner and execute safe transitions (`SAD-OWN-001`) |
| Route manager | Configure a route for every emulated port (`SAD-033`); validate player/port uniqueness and advertised compatibility; select opaque peripheral/mapping IDs; accept a replacement device in place only if it supplies every control in the route's source masks, otherwise amend the route |
| Bus master | Encode PS frames, one outstanding exchange, session/transaction lifecycle, scheduling and retries |
| Management client | Read capabilities, status and diagnostics; set user options; enumerate and commission nodes; move storage, configuration and update data between the USB drive and adapters in permitted states |
| Local UI | `SAD-UI-001`: owner selection, player assignment, remapping, calibration, approvals, options, adapter management and USB-drive operations; never silently arm |

A device requiring controls outside `PS-DATA-INPUT` is presented through the controls
it has; a control without a generic position is not transmitted and the device's
capability descriptor shows that.

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
       console                 display driver (local)
```

| Component | Responsibility |
|---|---|
| Network transport | DMA ring buffers, COBS/CRC, bounded frame parsing, driver direction, enumeration presence signal |
| Dispatcher | Session/version validation, duplicate rules and fixed service dispatch |
| Input endpoint | Validate the complete route generation and snapshot; convert and atomically publish all routed ports; present the idle identity with neutral controls on ports without an active device (`SAD-011`) |
| Console driver | Console electrical/protocol timing, virtual device identity, mode transitions, safe neutral behaviour, activity evidence (`SAD-028`) |
| Storage backend | FRAM banks, snapshot region, bank-select record, export locking |
| Feedback endpoint | Translate console feedback (rumble, force, keyboard LEDs) into generic queued effects with port/player/generation |
| Display driver | `SAD-DISP-001`; runs at the lowest priority and never delays a console transaction |
| Configuration store | Address record, configuration, user options and accessory identities with mirrored CRC-protected records; the address is written after the ASSIGN reply and never inside a response window |
| Platform HAL | Time, watchdog, UART, GPIO/PIO/DMA, I2C, SPI, flash and reset; explicit capabilities, not imaginary uniform hardware |
| Diagnostics | Bounded counters, last fault and resource high-water marks |

### SAD-ADAPT-001: multi-processor adapters

One adapter is one bus node (`SRS-SYS-006`) even when it contains several processors. A
single **gateway processor** owns the RS-485 node, the UID, the address, the session,
the lease and the neutralisation decision. Other processors (one per Original Xbox USB
device port, because each RP2350 has one USB controller) are reached over an internal
link owned by the gateway (Annex J).

- The gateway validates and maps INPUT as a set, then forwards each port's validated
  record over the internal link; no processor other than the gateway accepts bus
  traffic. Each processor installs its port's record atomically; a forwarding failure
  neutralises that port and raises fault 2; the annex bounds the skew (`SAD-050`).
- The gateway enforces the lease. Every other processor also applies a local deadline:
  the gateway sends a refresh every 0.2 ms while armed, and a processor that receives no
  valid refresh for 0.5 ms neutralises its port by itself, so link failure cannot leave
  live controls beyond the annex's bound. The gateway acknowledges REVOKE only after
  every processor has confirmed neutral, and each forwarded record is confirmed within
  150 us, otherwise the gateway treats it as a forwarding failure.
- Inhibit, REVOKE and expiry reach the other processors as an explicit neutral command
  and as the absence of refresh; the annex's `neutralisation_bound_us` covers the whole
  path.
- Update images for each processor role are staged by the gateway and forwarded over
  the internal link (`SAD-PERSIST-001`).

### SAD-MAP-001: mappings, capability ownership and accepted HID devices

The hub stores physical source capabilities separately from adapter descriptors. The
adapter advertises ports, virtual peripheral IDs, record kinds, supported and required
controls, feedback functions, user options and validated simultaneous combinations. The
hub transmits the route's source masks in ROUTES. The adapter validates compatibility;
both UI and adapter reject unapproved lossy mappings. A replacement device is accepted
in place only if it supplies every control in the route's source masks (the hub sends
only controls inside them), so the adapter's validation and the user's approvals still
hold; otherwise its record stays neutral until the route is amended (`SAD-010`,
`SAD-033`).

Device normalisation uses physical face positions (south/east/west/north), shoulders,
digital triggers, stick clicks, directional buttons, menu and auxiliary functions,
shift buttons, sticks, analog triggers, steering and pedals. `PS-DATA-INPUT` owns exact
units, bit assignments and neutral values. Mapping thresholds, dead zones and hysteresis
are versioned adapter mapping data; opposing directional inputs resolve to neutral per
axis.

**Accepted HID subset** (`SRS-IN-012`). The hub accepts a device when its report
descriptor parses under these rules:

- Top-level application collections from the Generic Desktop page: Game Pad, Joystick,
  Mouse or Keyboard; or from the Simulation Controls page: Automobile Simulation Device.
- Inputs: Button page, up to 32 buttons; Generic Desktop X, Y, Z, Rx, Ry, Rz, Slider,
  Dial and Wheel with 8- or 16-bit fields, signed or unsigned, within their logical
  limits; hat switch with four or eight positions plus null; Simulation Controls
  Steering, Accelerator and Brake (Clutch fields are parsed and ignored); Keyboard page
  modifiers (E0h to E7h) and a key array; constant and padding fields; report IDs.
- Outputs: LED page (Num Lock, Caps Lock, Scroll Lock, Compose, Kana); Haptics
  page simple haptic controller (intensity of its waveforms); Physical Interface Device
  page constant force, spring and damper effects with Set Effect, Set Constant Force,
  Set Condition and Effect Operation reports.
- Boot-protocol mice and keyboards are accepted through the same rules.

**Acceptance corpus** (`SRS-V-002`). The project owns a corpus of reference report
descriptors and report streams, each with its expected parse: gamepad with 16 buttons,
four 8-bit axes and a hat; fight stick with 12 buttons and a hat; hat-only digital pad;
gamepad with 16-bit axes and report IDs; gamepad with two analog triggers; wheel with
16-bit steering, separate pedals and shift paddles; wheel with Physical Interface Device
force feedback; gamepad with a Haptics output; boot-protocol mouse with wheel; keyboard
with LED output; and negative cases (a vendor-class device, a descriptor exceeding the
subset, a malformed descriptor).

An adapter mapping declares, for example, whether a fight stick direction drives a
digital pad, whether stick input may substitute for a pad, and whether triggers map to
digital buttons. The route selects mapping, not identity, so arming does not change
what the console sees (`SRS-IN-011`).

### SAD-MAP-002: controller-coverage matrix

Generic positions are those of `PS-DATA-INPUT`. Console elements come from the annexes.
"Lossy" means a console element with no direct generic source in a typical device; the
mapping then uses an explicit, user-approved normalisation (`SRS-IN-006/007`).

| Console / peripheral | Console elements | Record kind and generic coverage | Lossy elements |
|---|---|---|---|
| NES standard pad, NES Max | D-pad, A, B, Select, Start; turbo A/B | Pad: face, menu | None (turbo is adapter behaviour) |
| SNES standard pad | D-pad, A, B, X, Y, L, R, Select, Start | Pad: complete | None |
| SNES Mouse | Two buttons, X/Y motion | Pointer | None |
| Mega Drive 3-button / 6-button | D-pad, A, B, C, Start; X, Y, Z, Mode | Pad: four face, shoulders, digital triggers, menu | None with digital L2/R2 |
| Mega Mouse | Four buttons, X/Y motion | Pointer | None |
| Saturn digital pad, Virtua Stick, Twin Stick | D-pad, A, B, C, X, Y, Z, L, R, Start (Twin Stick: two sticks on the pad bits) | Pad: four face, shoulders, digital triggers, menu | Twin Stick: right stick directions from face buttons |
| Saturn 3D Control Pad | Pad elements, analog stick, analog L/R | Pad: left stick, triggers 4/5 | None |
| Saturn Keyboard, Shuttle Mouse | Keys and locks; pointer | Keyboard; pointer | None |
| Saturn Arcade Racer | Steering, buttons | Pad: steering, face | None with a wheel; stick X from a pad |
| N64 standard controller | D-pad, A, B, Z, L, R, Start, four C buttons, stick | Pad: face, shoulders, left stick, right stick for C | Z and C buttons need explicit mapping |
| N64 fishing controller, steering wheel | Standard controller identity, reel / steering | Pad: stick axes, steering | Reel from an axis |
| GameCube standard controller | D-pad, A, B, X, Y, Z, Start, analog L/R plus click, main and C stick | Pad: face, sticks, triggers 4/5 | Z and the L/R click need mapping |
| GameCube keyboard, steering wheel | Keys; steering, pedals | Keyboard; pad with steering and pedals | None |
| Dreamcast controller, Arcade Stick | D-pad, A, B, X, Y, Start, stick, analog L/R | Pad: face, left stick, triggers 4/5 | None |
| Dreamcast Race Controller | Steering, pedals, buttons | Pad: steering, pedals 4/5 | None with a wheel |
| Dreamcast Fishing Controller | Reel, rod motion, buttons | Pad: axes | Motion axes from generic axes |
| Dreamcast Keyboard, Mouse | Keys; pointer | Keyboard; pointer | None |
| PlayStation digital / DualShock | D-pad, cross, circle, square, triangle, L1, R1, L2, R2, Select, Start; sticks, L3/R3 | Pad: face, shoulders, digital triggers, sticks, stick clicks, menu | None |
| NeGcon, PlayStation wheel | Twist, analog I, II, L; buttons | Pad: steering (twist), triggers and pedals | Twist from a stick without a wheel |
| Jogcon | Dial, buttons, motor | Pad: steering axis for the dial | Dial from a stick without a wheel |
| PlayStation Mouse | Two buttons, motion | Pointer | None |
| PlayStation 2 DualShock 2 | As DualShock, plus pressure on twelve buttons | Pad with pressure | Pressure from a binary source |
| PlayStation 2 wheel | Steering, pedals | Pad: steering, pedals | None with a wheel |
| Original Xbox controller, Arcade Stick | D-pad, A, B, X, Y, Black, White (analog), Start, Back, L3/R3, sticks, analog L/R | Pad with pressure: face and shoulder pressure, sticks, triggers 4/5 | Pressure from a binary source |
| Original Xbox Steering Wheel | Steering, pedals, buttons | Pad: steering, pedals | None with a wheel |
| Fight stick (eight-button HID source) | Four face, L1/R1, L2/R2 | Four face, shoulders, digital triggers | None |

### SAD-MAP-003: pointers, keyboards, wheels and pressure

- **Pointers.** The hub keeps per-device 16-bit wrapping counters of X, Y and wheel
  motion and sends them in every record; the adapter takes differences modulo 2^16 from
  the last installed record and converts them to the console mouse's format (sign and
  magnitude, overflow flags, 10-bit offset). The first valid record after an invalid one
  sets the reference and produces no motion. A lost INPUT therefore delays motion by one
  cadence and loses none.
- **Keyboards.** The hub sends the modifier byte and up to six pressed keys as HID
  keyboard usages in ascending order; more than six pressed keys report the HID
  roll-over error usage in every slot. The adapter converts usages to the console
  keyboard's codes and make/break events. Console lock-LED requests return as feedback
  kind 5 and drive the keyboard's LED output report.
- **Wheels.** Steering is axis 6; separate pedals use axes 4 (brake) and 5
  (accelerator) under a wheel mapping, and a combined pedal axis 7 serves consoles with
  one pedal axis; shift paddles and sequential shifters drive the shift-up and
  shift-down buttons, and an H-pattern shifter's gears are remapped to buttons by the
  user (`SAD-029`). A clutch is parsed and not transmitted.
- **Pressure.** Pressure index n follows the generic buttons listed in
  `PS-DATA-INPUT`; any device axis may be remapped to a pressure position (for example
  analog triggers to L2/R2 pressure).

### SAD-UI-001: hub user interface

The hub display and four buttons (up and down move, select confirms, back returns)
provide these screens; every action that would arm or change live input asks for
confirmation:

| Screen | Content and actions |
|---|---|
| Status (home) | Owner, armed/neutral state, players with their devices and routes in generic terms, activity of every adapter (active, inactive, unknown, offline), persistent faults |
| Select console | Roster adapters with readiness; manual selection; automatic selection on or off (`SRS-OWN-007`) |
| Players | Assignment of the four players to the selected console's ports; device binding |
| Mapping | Mapping ID per route; lossy-approval requests (`SRS-UI-005`); remapping editor: the hub steps through the generic positions the mapping uses, sends a PROMPT so the adapter display shows the console name, and records the device control the user presses (`SRS-IN-021`) |
| Calibrate | Per-device routine: centre, then full travel of every axis, then dead zone (`SRS-IN-022`) |
| Adapter options | User options of the selected adapter with PROMPT names on its display (`SRS-UI-007`) |
| Adapters | Roster, add adapter (`SRS-NET-012`), discover unknown adapters (`SRS-NET-011`), remove a member; available while no owner is armed |
| USB drive | Export and import accessory images, export and import configurations, update adapters and the hub, export a diagnostic snapshot (`SAD-047`) |

### SAD-DISP-001: adapter display

The adapter display (`ICD-CAP-021`) shows, in the console's own terms: the node state and
fault; for each port its peripheral, its accessory and the player routed to it; the
mapping of the selected route with console button names; the user options; the item of a
PROMPT received from the hub; and on the Dreamcast adapter the VMU screen of each port,
in a 2 x 2 grid of 48 x 32 images, refreshed at up to 10 frames per second from the
console's VMU display writes. Display data never crosses the bus. The display driver runs
at the lowest priority and its I2C transfers are scheduled between console transactions.

## 5. SAD-OWN-001: ownership and routing

### Policy

Default selection mode is **manual**. At boot there is no owner. Manual selection may
choose a ready adapter even if activity is unknown; the UI shows the uncertainty. A
definite unsafe or unready electrical or peripheral state cannot be overridden by
selection.

Opt-in automatic mode selects a candidate only if exactly one ready adapter reports
stable `ACTIVE` for 500 ms, every other enrolled adapter is `INACTIVE` (an enrolled
adapter that does not answer counts as INACTIVE, since it is unpowered, `SAD-028`), and
every answering roster node has a current status no older than 500 ms. `UNKNOWN`, stale
status of an answering node or multiple active nodes block automatic selection. No
automatic takeover occurs while an owner exists. For an owner selected automatically,
inactivity stable for 2 s initiates release, and unknown or stale status initiates
release after 500 ms without fresh evidence; an owner selected manually stays until the
user releases it or a fault, lease expiry or bus failure ends the ownership. Bus failure independently triggers the adapter lease
timeout. These activity periods are distinct from the 100 ms safety lease. Manual and
automatic paths use exactly the same transition engine.

### Hub states

| State | Entry/action | Exit |
|---|---|---|
| BOOT_GUARD | Stop transmitting old traffic; create new non-repeating session; inhibit local routes/effects; wait 110 ms | Scan roster and negotiate, then NO_OWNER |
| NO_OWNER | No live input grants; neutral state; accept selection request; USB-drive maintenance allowed | Valid target -> PREPARE |
| PREPARE | Confirm descriptors/version; configure a route for every emulated port while the target is inhibited; obtain new generation | Validation success -> ARMING; error -> NO_OWNER |
| ARMING | Send ARM with the complete generation; initially neutral | ACK then fresh snapshot -> ACTIVE; uncertainty -> RELEASING |
| ACTIVE | Periodic snapshots renew lease; poll feedback/status; records of ports without a device are neutral (`SAD-010`); route amendments (`SAD-033`) | Switch, peripheral change, timeout or release -> RELEASING |
| RELEASING | Stop all renewals; cancel queued old input; send REVOKE; stop physical effects | Inhibit ACK plus drain guard, or 110 ms since last possible renewal -> NO_OWNER or PREPARE queued target |
| FAULT | Inhibit, show explicit fault; no silent rearm | User recovery -> BOOT_GUARD |

**Route amendment while armed.** To bind a device to a port whose route cannot accept
it, to change a route's mapping, source controls or player, the hub sends
ROUTES_AMEND for that one port with a new generation. The adapter validates the amended
route against the complete set, installs neutral controls on that port before its
acknowledgement, adopts the new generation and keeps the other ports' installed records
live. The amendment does not renew the lease, and the adapter accepts INPUT only with
the new generation from then on, so the next INPUT both renews the lease and resumes the
amended port with a fresh record. A lost amendment acknowledgement is resolved by an
exact retry; if the outcome stays indeterminate, the hub releases (RELEASING). The
presented peripheral identity is never changed by an amendment (`SRS-IN-020`). A change
of peripheral uses release, configure and arm.

**Device removal and late join.** A physical device removal does not inhibit the
ownership generation: the hub keeps the player's route and sends its record neutral, so
the other players continue and the same INPUT keeps renewing the lease. A device bound
to a port, whether after a removal or for the first time, resumes in place when it
supplies every control in the route's source masks; otherwise the hub asks for any lossy
approval and amends the route.

`REVOKE` acknowledgement means neutral control state has been installed, pending input
discarded and effects stopped. A console transaction already in progress may finish
from its previously latched snapshot; console drivers bound that completion and declare
it as `neutralisation_bound_us` in CAPS (kind 4), proved by measurement at the console
connector (`ICD-VER-016`). The hub computes its guards from the maximum bound over
enrolled adapters (`SAD-008`).

The transfer engine starts a new ARM only after the old owner cannot still expose live
controls. After a revoke ACK it waits a further local drain guard, `max(2 ms, 2 x B)`
where `B` is the largest declared bound, before starting a new ARM; with all bounds at
most 1 ms this is 2 ms and exceeds the old console transaction's completion bound even
with both clocks at their worst drift. If a revoke ACK is lost, the hub waits the lease
guard rather than assume success. The 110 ms clock guard is measured from the latest
possible acceptance of the last old renewal (including any uncertain ARM), after queued
transmissions are cancelled: response completion, or the full per-opcode response
timeout when no reply arrived (`PS-TIMING`). The transport reports that timestamp. With
unknown old traffic on hub boot, a full guard precedes any new grant. A manual switch
completes within 500 ms nominal (`SRS-OWN-012`): the lost-revoke path costs the 110 ms
guard plus route configuration and ARM.

### Adapter states

```text
RESET -> UNASSIGNED            (no valid persisted address)
RESET -> INHIBITED             (valid persisted address; HELLO required before routes)
RESET -> RECOVERY              (recovery input asserted at power-up)
UNASSIGNED --address assignment--> INHIBITED or RECOVERY
INHIBITED --compatible HELLO + valid ROUTES--> CONFIGURED
CONFIGURED --ARM--> ARMED_NEUTRAL
ARMED_NEUTRAL --fresh complete INPUT--> LIVE
LIVE --fresh complete INPUT--> LIVE (renew lease)
ARMED_NEUTRAL / LIVE --ROUTES_AMEND--> same state, amended port neutral
ARMED_NEUTRAL / LIVE --REVOKE or expiry or fault--> INHIBITED
CONFIGURED --REVOKE, fault or route-invalidating OPTION--> INHIBITED
CONFIGURED --new ROUTES--> CONFIGURED
INHIBITED --exclusive maintenance admission--> MAINTENANCE
MAINTENANCE --safe close--> INHIBITED
MAINTENANCE --safe new-session takeover--> INHIBITED or RECOVERY
any --reset--> RESET
```

RECOVERY permits session negotiation and diagnostics, never ownership. UNASSIGNED is not
addressable by STATUS; the hub reaches it only through commissioning and enumeration.
The assigned address is persisted in the configuration store after the assignment reply,
so an ordinary adapter or console power cycle returns the node to INHIBITED at its
address and the hub confirms the UID in HELLO; no re-commissioning and no physical
commissioning enable are needed, consistent with `SRS-OWN-010`. Asserting the physical
commissioning enable clears the persisted address.

Generation is cleared when inhibition occurs; routes must be configured again. The
adapter enforces its own monotonic lease even if network parsing stops. Only accepted
ARM and newer complete INPUT renew it; amendments, status polls, duplicates, invalid
packets and unrelated commands do not. Session, route generation, port, player,
capabilities and sample sequences are checked before publishing.

Two independent time domains exist: hub session/transaction ordering and adapter local
lease time. No synchronised wall clock is required.

### Example: PlayStation 2 selected, two independent sources

The hub binds player 0 to a USB gamepad and player 1 to a fight stick. It selects one
PlayStation 2 adapter in multitap mode, receives its opaque compatible peripheral/mapping
IDs and configures player 0 -> port 0, player 1 -> port 1, player 2 -> port 2 and player
3 -> port 3; ports 2 and 3 have no device and carry neutral records. One INPUT publishes
all four records. If the fight stick is unplugged, player 1's record turns neutral while
player 0 plays on (`SAD-010`). When a third device is bound to player 2 and supplies the
route's required controls, it resumes in place; another powered adapter keeps answering
its console with neutral controls. Selecting it first releases the PlayStation 2 owner;
player contexts need not change, but routes and mapping compatibility are validated anew.

## 6. SAD-SCHED-001: concurrency and timing

The hub uses a monotonic deadline scheduler, not an unrestricted management request
queue. At each 1 ms boundary it selects the newest complete player samples and sends
the owner's INPUT, then one further exchange: FEEDBACK_POLL in even cycles, STATUS in
cycles 1 mod 4, and in cycles 3 mod 4 a management or live-export chunk when one is
pending, otherwise STATUS (`PS-TIMING`). Each opcode has its own response timeout, and a
non-input exchange is admitted only if its worst-case timeout path ends before the next
reserved input slot; the cycle budget shows that an INPUT and a STATUS or FEEDBACK_POLL
all timing out end at 0.77 ms. An INPUT is never retried: a lost exchange is replaced by
the next cycle's newest sample (`SRS-PERF-005`). A management chunk whose timeout path
does not fit is shrunk or moved to a later cycle. Without an owner the cycle carries no INPUT and
management chunks may follow one another.

Status scanning satisfies the automatic-policy freshness window for the enrolled roster
(31 nodes in 124 ms). Input and lease traffic always wins while armed.

The adapter separates a console real-time execution domain from network and management
work: console protocols run in PIO state machines with DMA on one core, network,
mapping and services on the other (`SAD-031`). Buffers and peripherals have one owner
each; interrupt priorities, worst-case blocking and memory barriers are documented per
annex. A mapped snapshot set is published by an atomic index swap after all records are
built; the timing driver never reads fields being updated.

Lease expiry runs in a deadline mechanism that remains effective during parser overload
and storage activity. Watchdog, flash/XIP stalls, DMA bus contention and multicore shared
data are analysed per annex; flash is programmed only in maintenance.

## 7. SAD-FB-001: feedback

Console drivers queue generic events: rumble, constant force, spring, damper and
keyboard LEDs. They never write to the bus spontaneously. The adapter reports
the console's native effect richness (for example two magnitudes even when the console
motor is on/off); the hub reduces that to what the bound physical device supports and
records any loss diagnostically. The hub polls the owner adapter every 2 ms while armed,
validates session, generation, port, player and the current physical binding, and
translates each event to the device's HID output (`SRS-OWN-015`):

| Event | HID output path |
|---|---|
| Rumble (two magnitudes) | Haptics page waveform intensities, or a Physical Interface Device periodic effect |
| Constant force, spring, damper | Physical Interface Device effects of the same type |
| Keyboard LEDs | LED page output report |

A device without the matching path receives nothing and the hub records a diagnostic
result rather than a false success. An event for a player whose device was removed is
discarded with a diagnostic.

Effects use bounded duration and require refresh. Zero magnitude is an explicit stop.
The hub stops effects locally on revoke, device disconnect, expiry or link loss without
waiting for an adapter message. Overflow coalesces the newest state per route and kind,
increments a counter and does not grow a queue. The PS defines event IDs and
acknowledge-on-next-poll behaviour.

## 8. SAD-PERSIST-001: configuration, storage and update

**Configuration** is a bounded, adapter-defined versioned blob in the configuration
store. A replacement is staged, validated, durably committed and then activated while
inhibited. The hub does not interpret console protocol fields in it. The adapter keeps a
last known valid configuration or enters an explicit recovery fault. User options are
small values set by OPTION and persisted in the same store.

**Accessory storage** is authoritative at the adapter. The console driver handles console
checksums, blocks, addresses and emulated-media identity. The image is held in FRAM
(`SAD-023`) on the processor that serves the console. Console writes are written through
and acknowledged to the console only after the FRAM write completes, so accessory data is
never dirty (`dirty_resources` in STATUS stays zero). The network only sees opaque
resource IDs, port bindings and bytes. Import (full replacement) requires exclusive
maintenance with no owner and a proven quiescent accessory interface; neutral buttons
alone do not mean that a console has stopped writing. Export reads either the
maintenance view or a live snapshot (`SAD-036`): the snapshot is built in FRAM region S
once the console's storage interface has been idle for the annex's quiet time, restarts
if the console writes during the copy, and stays frozen from completion until the token
is closed, so it reflects the accessory at one idle instant; a console access waits at
most one copy chunk and stays within its annex deadline.

**USB drive** (`SAD-047`). The hub mounts a FAT32 USB flash drive on a free downstream
port, for every operation while no owner is armed and for accessory export also while an
owner is armed (lowest USB priority), and uses this layout; file names derive from the UID and resource, since the hub
has no clock:

| Path | Content |
|---|---|
| `RPN/CARDS/<uid>/<resource>-P<port>.BIN` | Accessory image, exactly the resource's size |
| `RPN/CONFIG/<uid>/<profile>.CFG` | Configuration blob |
| `RPN/UPDATE/<name>.RPI` | Firmware image with the update header below |
| `RPN/DIAG/<uid>-<sequence>.TXT` | Diagnostic snapshot: STATUS and every DIAGNOSTICS counter |

**Update profile** (`SAD-030`). A firmware image is a 60-byte header followed by the
image: magic `RPNI`, header version (u16), header length (u16), target hardware ID (u32,
board and processor role), version (major, minor, patch as u16), reserved (u16), image
length (u32), SHA-256 of the image (32 bytes) and the CRC-32C of the preceding header
bytes (u32). Each processor has a boot stage in protected flash that is updated only over
SWD, and two image slots. The adapter receives an image into the inactive slot in
maintenance (UPDATE), verifies the header, the hardware ID and the SHA-256, and activates
it only while the physical update enable (the recovery input) is asserted. The boot stage
then starts the new slot once as a trial; the image confirms itself after a successful
HELLO and self-test within 60 s, otherwise the watchdog resets the node and the boot
stage returns to the previous slot. The hub updates itself the same way from a file on
the USB drive and updates adapters from files whose hardware ID matches an adapter's CAPS
kind 2 profile. A multi-processor adapter's gateway forwards each role's image over the
internal link. No signature, encryption, anti-rollback counter or OTP key is used;
debug stays enabled, so any node can be recovered over SWD (`SAD-048`).

## 9. Adapter framework

The reusable adapter modules (codec and transport, dispatcher, session, ownership lease,
route validation and snapshot publication, configuration, storage, diagnostics, update
and display services, and the hardware abstraction) and the console-driver contracts are
specified in [RPN-AFS](AFS.md). A framework callback returns explicit
supported/unsupported/error status, never a success-shaped no-op, and the framework does
not force every console driver into a polling loop or a shared low-level PIO design.

## 10. Fault model and trust

The bus is physically trusted. CRC addresses accidental corruption, not malicious
injection. A party on the bus can impersonate the hub; session IDs and leases are
stale-message protection, not authentication. The bus has no connection outside the
installation, and firmware activation needs a physical enable at the node (`SAD-030`).

Shorted transceivers, duplicate UIDs, address conflicts, inaccurate clocks and wedged
console drivers are not repaired by retransmission. Nodes fail inhibited, surface
diagnostics where possible and require recovery or re-commissioning. A bus failure does
not corrupt local console accessory data.

All behaviour is verified as stated in [SRS section 9](SRS.md#9-verification-and-traceability).
