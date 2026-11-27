# Adapter Framework Specification

| Control field | Value |
|---|---|
| Document ID | RPN-AFS |
| Revision | 0.2 |
| Status | Baseline for review |
| Date | 2026-11-27 |
| Companion documents | [RPN-SRS](SRS.md), [RPN-ICD](ICD.md), [RPN-SAD](SAD.md), [RPN-PS](PS.md) |

| Revision | Change history |
|---|---|
| 0.2 (2026-11-27) | First issue: framework modules, platform abstraction, console-driver contract, snapshot publication, neutralisation, activity, storage, feedback, options, display, update and multi-processor contracts, resource declaration and verification. |

## 1. Purpose and interpretation

This document specifies the reusable software framework shared by every RPN adapter
and the contracts between that framework and the console-specific drivers
(`SRS-MNT-001..003`, `SRS-EXT-001`, `SAD-037`). It refines the adapter components of
[`SAD-COMP-ADAPTER`](SAD.md#sad-comp-adapter); wire formats are owned by the
[PS](PS.md), electrical and per-console facts by the [ICD](ICD.md) and its annexes.
Normative language and the F/D classification follow
[RPN-SRS section 1](SRS.md#1-purpose-and-interpretation). Identifiers `AFS-*` are
never reused.

## 2. Structure

```text
              +-------------------------- framework (console-independent) ---------------------+
 RS-485  ---> | transport -> dispatcher -> session/lease -> routes/input -> snapshot publisher  |
              |                  |             |                                   |          |
              |      services: config, options, storage, feedback, diagnostics,    |          |
              |                update, prompt/display                              |          |
              +----------------------------|---------------------------------------|----------+
                                           | driver contract (section 4)           |
              +----------------------------v---------------------------------------v----------+
              |                console driver (one per console annex)                        |
              +-----------------------------------------|---------------------------------------+
                                                        | platform abstraction (section 3)
                                                     RP2350: PIO, DMA, UART, SPI, I2C, timers
```

| ID | Class | Requirement |
|---|---|---|
| AFS-001 | F | The framework shall comprise transport (COBS/CRC framing, DMA ring buffers, driver direction, enumeration presence signal), dispatcher, session and lease, route and input validation, snapshot publisher, and the Configuration, Option, Storage, Feedback, Diagnostics, Update and Prompt services of the PS; none of these modules shall contain console-specific code. |
| AFS-002 | D | A console driver shall depend only on the driver contract (section 4) and the platform abstraction (section 3); it shall not call transport, dispatcher or service internals. |
| AFS-003 | D | Every framework and driver callback shall return an explicit result (`OK`, `UNSUPPORTED`, `BUSY` or an error mapped to a PS-STATUS value); a success-shaped no-op is forbidden. |
| AFS-004 | D | All buffers, queues and tables shall be statically bounded; no dynamic allocation after initialisation (`SRS-REL-001`). |
| AFS-005 | D | The framework shall build and run against a host-side simulation of the platform abstraction, so codecs, lease handling, routing and mapping are tested without hardware (`SRS-MNT-003`). |

## 3. Platform abstraction

| ID | Class | Requirement |
|---|---|---|
| AFS-010 | D | Monotonic time: a 64-bit microsecond counter derived from the crystal clock, readable from any context, with deadline timers whose expiry runs at a priority above the network task and below console timing. |
| AFS-011 | D | Watchdog: enabled before the console driver starts; refreshed only by the framework's supervision task after it has confirmed that the lease mechanism, the transport and the driver's health callback are progressing. |
| AFS-012 | D | Bus UART: transmit and receive by DMA; a transmit-complete event that fires only after the last stop bit has left the pin; driver-enable control that reaches the disabled state within 10 us of that event (`PS-TIMING`); presence-signal generation (driver enabled with the line held in space for 20 us). |
| AFS-013 | D | Storage access: SPI FRAM transfers through one arbiter that serves console requests first, then network operations split into pieces of one console block, then snapshot copy chunks, never blocking a console request behind more than one transfer per other port, one network piece and one copy chunk (`ICD-STO-001`). |
| AFS-014 | D | Configuration store: I2C record read/write of mirrored, sequence-numbered, CRC-32C-protected records; a write completes or leaves the previous copy valid; the I2C bus is shared with the display under one driver. |
| AFS-015 | D | Flash: programming and erasing only through an interface that refuses to run unless the node is in MAINTENANCE and the console driver reports stopped. |
| AFS-016 | D | Module identification: the console connector module ID is read once at boot; a mismatch with the driver's declared module ID leaves every console-facing pin high-impedance and raises fault 1 (`ICD-CAP-004`). |

## 4. Console driver contract

Each console annex is implemented by one driver that registers a descriptor and the
callbacks below. Timing figures are upper bounds the driver guarantees and the
framework relies on.

| ID | Class | Requirement |
|---|---|---|
| AFS-020 | F | Descriptor: the driver shall declare its annex identifier, module ID, RP2350 variant, port count, multitap modes, the CAPS entries of kinds 0, 1, 4 and 5 (combinations, storage resources, `neutralisation_bound_us`, user options), its resource table (PIO state machines, DMA channels, interrupts, RAM, GPIO) and its idle identity per port (`SRS-IN-011`, `SRS-MNT-002`). |
| AFS-021 | D | `start(config, options)` and `stop()`: start enables console-facing outputs only after the module check (AFS-016) and presents the idle identity on every port; stop returns every console-facing pin to high-impedance within 100 us. |
| AFS-022 | D | `validate_routes(set)`: checks a complete route set (peripherals, mappings, record kinds, source masks, lossy flags, simultaneous resources, identity rule) without side effects and returns OK or the PS-STATUS value of the first failure. |
| AFS-023 | D | `map(route, record, out)`: converts one generic INPUT record to the driver's console-native snapshot for that port; pure, bounded and run from RAM; worst-case execution time declared, so that validating and mapping four records plus publication completes within the 100 us response limit (`SRS-PERF-006`). |
| AFS-024 | D | Snapshot publication: the framework writes mapped snapshots into the inactive half of a per-port double buffer and publishes all ports by one atomic index swap; the driver reads only the published half and latches it at the start of each console transaction, so every transaction reads a coherent snapshot (`SRS-IN-008`). |
| AFS-025 | D | `neutralise(port_set)`: makes the listed ports present neutral controls; callable from the lease deadline context; the driver guarantees neutral visibility at the console connector within its declared `neutralisation_bound_us` (`SRS-OWN-013`). |
| AFS-026 | D | `activity()`: returns console power present or absent and the time of the last valid console poll of any emulated port, from which the framework derives ACTIVE, INACTIVE or UNKNOWN by `SRS-OWN-014`. |
| AFS-027 | D | `quiesce_storage()` and `resume_storage()`: report whether the console's accessory interface is idle and keep it idle for maintenance; `storage_idle_since()` returns the time of the last console storage access, for live snapshots. |
| AFS-028 | D | `health()`: returns OK while the console timing engine meets its deadlines; a missed deadline is counted (DIAGNOSTICS counter 7) and repeated misses raise fault 2. |

## 5. Services

| ID | Class | Requirement |
|---|---|---|
| AFS-030 | F | Lease: the framework owns the 100 ms lease and the inhibit decision; expiry calls `neutralise` for every port from a deadline timer that runs even while the transport or a service is overloaded (`SRS-OWN-009`). |
| AFS-031 | F | Route amendment: on ROUTES_AMEND the framework calls `validate_routes` with the amended set, then `neutralise` for the amended port, then adopts the new generation, without touching the other ports' published snapshots (`SRS-IN-020`). |
| AFS-032 | F | Storage backend: the framework implements banks, snapshot region, bank-select records and tokens (`ICD-STO-001`, `PS-SVC-STORAGE`); the driver supplies only the console-side block read and write handlers, which go through the arbiter of AFS-013 and acknowledge a console write only after the FRAM write has completed. |
| AFS-033 | F | Feedback: the driver posts generic events (kind, port, values, duration) through a bounded call that coalesces per route and kind; the framework owns event IDs, the delivered head and acknowledgement (`PS-SVC-FEEDBACK`), and re-posts the current state of every effect the console holds on (for example a Rumble Pak motor or DualShock motor bytes) every 50 ms, so held effects never lapse at the 100 ms duration limit. |
| AFS-034 | F | Options and configuration: the framework stores option values and the configuration blob in the configuration store and passes them to `start`; an OPTION change in INHIBITED or CONFIGURED restarts the driver with the new values, during which the console sees the idle identity; an option flagged to take effect after reset is applied at the next node reset (`PS-SVC-CONFIG`). |
| AFS-035 | F | Display: the framework renders state, faults and routes; the driver supplies console names for generic items and options (`PS-SVC-PROMPT`) and, where its annex has one, the image of a console display such as the VMU screen; rendering runs at the lowest priority (`SAD-DISP-001`). |
| AFS-036 | F | Update: the framework stages, verifies and activates images per `PS-SVC-UPDATE` and the update profile of `SAD-PERSIST-001`, calling `stop` before any flash programming; drivers contain no update code. |
| AFS-037 | F | Diagnostics: the framework keeps the counters of `PS-SVC-DIAGNOSTICS` and the last fault; drivers report through `health` and bounded counter increments only. |

## 6. Multi-processor adapters

| ID | Class | Requirement |
|---|---|---|
| AFS-040 | F | On an adapter with several processors (`SAD-ADAPT-001`) the gateway runs the full framework; every other processor runs the framework's link endpoint and its port's driver. |
| AFS-041 | D | The link carries per-port snapshots after whole-set validation, explicit neutral commands, refresh messages every 0.2 ms while armed, forward confirmations within 150 us, storage and update proxy operations, and health reports; each message carries the gateway's generation and a CRC-32C. |
| AFS-042 | D | A processor without a valid refresh for 0.5 ms neutralises its port by itself; an unconfirmed forward is a forwarding failure, which neutralises the port and raises fault 2 at the gateway (`SAD-050`); the gateway acknowledges REVOKE only after every processor has confirmed neutral. |

## 7. Verification

| ID | Verifies | Method and acceptance evidence | SRS entry |
|---|---|---|---|
| AFS-V-001 | AFS-001..005 | I/T: dependency check that no framework module includes driver code; host build of the framework against the simulated platform with the protocol test suite of PS section 9; a mock driver added without framework changes | SRS-V-001, SRS-V-004 |
| AFS-V-002 | AFS-010..016 | T/H: timer and watchdog fault injection; transmit-complete-to-driver-disable time measured; arbiter worst-case wait measured with all ports and a snapshot copy active; configuration-store power-fail test; flash refusal outside maintenance; module mismatch leaves pins high-impedance | SRS-V-005, SRS-V-006 |
| AFS-V-003 | AFS-020..028 | T/H: descriptor checked against the annex; `map` worst-case execution time measured; coherent-snapshot test under continuous publication; neutralisation timing measured (`ICD-VER-016`); activity derivation; storage idle detection | SRS-V-002, SRS-V-003, SRS-V-006 |
| AFS-V-004 | AFS-030..037 | T/F: lease expiry under transport overload; amendment isolation; storage, feedback, option, display and update service tests of the PS | SRS-V-003, SRS-V-005, SRS-V-008, SRS-V-012 |
| AFS-V-005 | AFS-040..042 | T/F: link loss, corrupted link messages and forwarding failure on the Original Xbox adapter | SRS-V-002 |
