# Software Architecture Description

| Control field | Value |
|---|---|
| Document ID | RPN-SAD |
| Revision | 0.1 |
| Status | Draft - architecture exploration |
| Date | 2026-10-23 |
| Companion documents | [RPN-SRS](SRS.md), [RPN-ICD](ICD.md), [RPN-PS](PS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Initial architecture review, decision register, safe two-player ownership, framework boundaries and scheduling model. |

## 1. Architecture intent

One hub models two players and acquires modern input. Each console adapter
models one console's peripheral ecosystem. The network carries generic state
and management operations, not console bit-level transactions. Console response
timing is satisfied entirely from adapter-local state.

Classification C/D/P/O/F follows [RPN-SRS](SRS.md#1-purpose-and-interpretation).
All implementation arrangements below are proposals unless identified as C or D.
No source firmware exists in this repository yet.

## 2. Initial architecture review

| Review ID | Finding or unresolved assumption | Resolution in this draft |
|---|---|---|
| SAD-R-001 | One MCU per adapter is not proven for two ports, accessories and USB-device consoles | One logical adapter may use multiple processors; profile-level resource and timing gates |
| SAD-R-002 | A generic input model can still leak console-specific mapping into the hub | Positional generic controls; mappings and virtual peripherals owned by adapter; device and virtual descriptors separated |
| SAD-R-003 | Broadcast discovery on half-duplex RS-485 can collide; CRC is not reliable arbitration | Commissioning by a known 128-bit UID; roster scanning thereafter; automatic unknown-node enumeration deferred |
| SAD-R-004 | "Active console" does not define exclusivity, particularly after lost acknowledgements | Explicit single-owner lease, generation fencing, boot guard and revoke-or-expire switching |
| SAD-R-005 | A player assignment is not an ownership grant | Routes configured while inhibited; arm is a separate operation; atomic two-player snapshots |
| SAD-R-006 | A network storage service cannot satisfy console accessory deadlines | Local authoritative storage; export/import only in exclusive maintenance in this profile |
| SAD-R-007 | Service-oriented architecture can imply unnecessary RPC or a plug-in framework | Fixed bounded opcode groups plus a service bitmap and descriptors; no dynamic broker or runtime plug-ins |
| SAD-R-008 | RP2040 preference does not establish USB-host capacity or flash-time isolation | Qualify host hubs/resources; allow alternate silicon; prove flash/console coexistence |
| SAD-R-009 | 1 Mbit/s sounds ample but management replies and turnaround consume deadlines | Two-player exchange budget and deadline-based bulk admission in PS-TIMING |
| SAD-R-010 | Emulating accessory storage is not emulating the complete accessory | Explicit supported peripheral functions; no implied VMU screen/clock or complete Pak coverage |
| SAD-R-011 | A shared bus may join console grounds and supplies unintentionally | ICD power/isolation gates; no approved connector or common-ground deployment yet |
| SAD-R-012 | CRC, version negotiation and firmware recovery do not provide authentication | Trusted local bus assumption, physical update enable, security boundaries stated explicitly |

There were no previous four-document definitions to reconcile. These findings
review the supplied project architecture, rather than assert defects in an
existing implementation.

## 3. Decision register

This is the shared decision/open-question authority; other documents reference
it. Provisional selections define a coherent profile to evaluate, not a frozen
design. Numeric protocol choices remain provisional as a group.

| ID | Class | Decision or question | Dependency / resolution evidence |
|---|---|---|---|
| SAD-D-001 | C | Hub has no console-specific wire-protocol logic; adapters own console semantics | Component dependency review |
| SAD-D-002 | C | Two independent players; multiple powered consoles; one selected console owner | Ownership and two-port tests |
| SAD-D-003 | D | Console timing and accessory I/O use local state, not bus round trips | Per-console timing analysis |
| SAD-P-001 | P | RS-485, 1 Mbit/s, one master and up to 31 addresses | Harness, loading and scheduling qualification |
| SAD-P-002 | P | Compact fixed services over COBS/CRC framing, 192-byte payload bound | Codec and interop tests; revise together with PS |
| SAD-P-003 | P | Commission unassigned nodes by scanned/manually supplied UID; no broadcast contention algorithm | Requires provisioning and accessible UID label/debug readout |
| SAD-P-004 | P | 5 ms snapshots; 100 ms ownership lease; 110 ms reboot/uncertain-transfer guard | Latency and drift tests; clock bound in PS-TIMING |
| SAD-P-005 | P | One selected virtual peripheral per port; two routes max; no fan-out | Two-player prototype |
| SAD-P-006 | P | Generic storage/configuration/update only in maintenance | Profile quiescence, durability and recovery tests |
| SAD-O-001 | O | First console, exact hardware variants and first supported virtual peripherals | Owner selection before console implementation |
| SAD-O-002 | O | Supply distribution, grounding versus galvanic isolation, connector and cable | Deployment survey and ICD-QUAL-001 |
| SAD-O-003 | O | Hub USB-host topology, device list, radio and MCU choice | Two-device enumeration/report/feedback load prototype |
| SAD-O-004 | O | Per-console MCU/PIO/USB split and timing limits | ICD-CON-001 supplements and traces |
| SAD-O-005 | O | Local accessory media, configuration journal and update recovery mechanism | Power-fail and endurance analysis |
| SAD-O-006 | O | Console activity sensing reliability and eligible auto-selection UI | Profile-specific sensing plus multi-console tests |
| SAD-O-007 | O | Final button mappings, analog calibration and compatibility prompts | Profile usability tests; no silent lossy conversion |
| SAD-O-008 | O | Firmware manifest/signature scheme and future untrusted administration | Threat model; network update disabled until a concrete profile exists |
| SAD-F-001 | F | Bluetooth acquisition, actual wheel drivers, multitaps, more players, remote control | New scope and resource budgets |
| SAD-F-002 | F | Fully automatic unknown-node discovery and live coherent storage export | Justify complexity after baseline prototype |
| SAD-F-003 | F | Separate Adapter Software Framework specification | Extract after two materially different working console drivers |

Dependency chain: console/peripheral coverage -> timing/resource budget -> MCU
and storage choice -> power/isolation -> harness approval. Independently, USB
device support -> host topology -> hub resource/power budget. The bus cadence
and lease depend on measured clock and turnaround bounds, not the reverse.

## 4. Components and data flow

### SAD-COMP-HUB

```text
USB host / future Bluetooth
          |
device parser + physical capability descriptor
          |
normalisation + calibration -> player contexts [0, 1]
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
| Device backend | Enumerate physical devices; parse reports, connection changes and capability limits; no console packet encoding |
| Player manager | Bind one physical source per player initially; retain capabilities and most recent state; combining devices requires a future explicit policy |
| Normaliser | Device-to-generic positions/axes, calibration and validity; no selected-console button labels |
| Ownership manager | Select owner and execute safe transitions |
| Route manager | Validate player/port uniqueness and advertised compatibility; select opaque peripheral/mapping IDs |
| Bus master | Encode PS frames, one outstanding exchange, session/transaction lifecycle, scheduling and retries |
| Management client | Read capabilities/status; configure and transfer storage/update data only in permitted states |
| Diagnostics/UI | Show owner, routes, unknown activity, incompatible mappings, lost devices and persistent faults; never silently arm |

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
| Input endpoint | Validate complete route generation and snapshot; convert and atomically publish both ports |
| Console driver | Console electrical/protocol timing, virtual device identity, mode transitions, safe neutral behaviour, activity evidence |
| Storage backend | Local authoritative accessory data, media semantics, persistence and export locking |
| Feedback endpoint | Translate console feedback to generic queued effects with port/player/generation |
| Platform HAL | Time, watchdog, UART, GPIO/PIO/DMA, flash/storage and reset; explicit capabilities, not imaginary uniform hardware |
| Diagnostics | Bounded counters, last fault and resource high-water marks |

### SAD-MAP-001: mappings and capability ownership

The hub stores physical source capabilities separately from adapter descriptors.
The adapter advertises ports, virtual peripheral IDs, supported input fields,
required controls, feedback functions and validated simultaneous combinations.
The hub transmits a physical-capability summary during route configuration.
The adapter validates compatibility; both UI and adapter must reject unapproved
lossy mappings.

Initial device normalisation uses physical face positions (south/east/west/north),
shoulders, stick clicks, directional buttons and generic auxiliary functions.
Axis identities include steering and pedals. `PS-DATA-INPUT` owns exact units,
bit assignments and neutral values.

An adapter mapping declares, for example, whether a fight stick direction drives
a digital pad, whether stick input may substitute for a pad, and whether triggers
map to digital buttons. Opposing directional inputs resolve to neutral per axis
in profile 0.1. Thresholds, dead zones and hysteresis are versioned mapping data,
not invented globally for every console. Peripheral identity changes require
inhibition and possibly console reset/re-enumeration; a profile must state this.

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
| ACTIVE | Periodic snapshots renew lease; poll feedback/status | Switch, route/device/profile change, timeout or release -> RELEASING |
| RELEASING | Stop all renewals; cancel queued old input; send REVOKE; stop physical effects | Inhibit ACK plus 2 ms drain guard, or 110 ms since last possible renewal -> NO_OWNER or PREPARE queued target |
| FAULT | Inhibit, show explicit fault; no silent rearm | User recovery -> BOOT_GUARD |

Route edits use release -> configure -> arm even for the same console. There is
no live in-place reroute in this profile. A physical device removal inhibits the
entire two-player ownership generation for simplicity; retaining the other player
is a possible future policy, not an implicit exception.

`REVOKE` acknowledgement means neutral control state has been installed, pending
input discarded and effects stopped. A console transaction already in progress
may finish from its previously latched snapshot; per-console drivers shall bound
that completion and prove neutral visibility within the 1 ms local budget, or
the profile cannot claim the provisional lease/transfer timing. If a driver
cannot provide that bound, safe switching requires a larger validated guard.

The transfer engine starts a new ARM only after the old owner cannot still
expose live controls. After a revoke ACK it waits a further 2 ms local drain guard before
starting a new ARM; this exceeds the old console transaction's 1 ms completion
bound even with both clocks at their worst qualified drift. If a revoke ACK is
lost, wait the lease guard rather than assume success.
The 110 ms clock guard is measured from the latest possible acceptance of the
last old renewal (including any uncertain ARM), after queued transmissions are
cancelled: use response completion, or the full response timeout when no reply
arrived, as defined in `PS-TIMING`. The transport must report that timestamp.
With unknown old traffic on hub boot, start a full guard before any new grant.

### Adapter states

```text
RESET -> UNASSIGNED
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
The draft address is volatile; every adapter reboot requires commissioning
again, including physical commissioning enable. This is a deliberate
availability limitation of the provisional profile, to be reconsidered after
the first prototype rather than hidden as automatic hot-plug recovery.

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
players. Another powered adapter continues to answer its console with neutral
controls. Selecting it first releases the PS2 owner; player contexts need not
change, but routes and mapping compatibility are validated anew.

## 6. SAD-SCHED-001: concurrency and timing

The hub uses a monotonic deadline scheduler, not an unrestricted management
request queue. It selects the newest complete player samples at each 5 ms
boundary, prioritises owner INPUT, then feedback/status, then bounded management
chunks. No bulk transaction starts unless its worst-case completion, including
timeout and guard, fits before the next reserved input slot. A maximum-size
transaction may not fit while armed; reduce chunk size or defer to maintenance.

Status scanning must satisfy the automatic-policy freshness window for the
enrolled roster or automatic selection stays blocked. Management transfers may
pause normal status scans only while automatic selection is unavailable and
there is no active owner. Input/lease traffic always wins while armed.

The adapter separates a console real-time execution domain from network and
management work. PIO/DMA, interrupts, separate cores or processors are options.
The design shall specify ownership of buffers and peripherals, interrupt
priorities, worst-case blocking and memory barriers before implementation.
An atomic pointer/index swap after constructing both mapped player snapshots
is preferred to updating fields visible to the timing driver.

Lease expiry runs in a deadline mechanism that remains effective during parser
overload and permitted storage activity. Watchdog, flash/XIP stalls, DMA bus
contention and multicore shared data require explicit analysis; "dual core" is
not proof of real-time isolation.

## 7. SAD-FB-001: feedback

Console drivers queue generic rumble/indicator events. They never write to the
bus spontaneously. The hub polls, validates session/generation/port/player and
current physical binding, and translates to a supported device operation.
Unsupported effects produce a diagnostic result rather than a false success.

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

Update services are optional. The generic protocol can transport an image but
cannot invent a safe bootloader or signature format. A concrete advertised
update profile must specify hardware compatibility, manifest, digest/signature,
staging, activation and rollback/recovery. No safe profile -> no update service.
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

All stages feed [SRS verification](SRS.md#8-verification-and-traceability).
No stage or document is marked validated by this draft.
