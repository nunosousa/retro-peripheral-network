# Interface Control Document

| Control field | Value |
|---|---|
| Document ID | RPN-ICD |
| Revision | 0.1 |
| Status | Draft - electrical implementation not approved |
| Date | 2026-10-23 |
| Companion documents | [RPN-SRS](SRS.md), [RPN-SAD](SAD.md), [RPN-PS](PS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Initial interface boundaries, provisional RS-485 profile and console electrical qualification gates. |

Classification and normative language follow [RPN-SRS section 1](SRS.md#1-purpose-and-interpretation).
No connector pinout or console voltage table in this draft is approved for wiring.
Absence of a value means unresolved, not permission to infer a safe value.

## 1. Interface inventory

```text
Modern devices --ICD-USB-001--> Hub --ICD-NET-001--> Adapter(s)
                                  shared bus          |
                                               ICD-CON-001
                                                     |
                                             Original console

Hub/adapter local supply --ICD-PWR-001--> protected local power
Console supply/sense ----ICD-PWR-002--> isolated/protected console domain
Adapter local persistent media -------ICD-STO-001
```

| Interface ID | Boundary | Authority and status |
|---|---|---|
| ICD-USB-001 | Input device to hub | USB host hardware, power and input-report acquisition; required boundary, implementation open |
| ICD-NET-001 | Hub/adapter shared bus | Provisional RS-485 electrical profile; RPN-PS owns UART framing and transactions |
| ICD-NET-002 | Network harness and connector | Linear trunk proposal; connector, pin assignment and cable rating open |
| ICD-PWR-001 | RPN operating power | Power distribution, budgeting and protection; topology open |
| ICD-PWR-002 | Console power and sensing | Never parallel console supplies; per-console qualification required |
| ICD-CON-001 | Adapter to console ports | Profile-specific electrical and timing boundary |
| ICD-STO-001 | Adapter persistent storage | Local accessory/configuration/update storage; technology profile-specific |
| ICD-DBG-001 | Local recovery/debug | Required recoverability, connector/access control open |

The proposed logical unit is one adapter per console, supporting up to two
simultaneously routed ports. This is not a claim that one MCU can service every
two-port combination. Adapter internals may contain multiple MCUs, translators,
connectors and isolated domains under one network endpoint.

## 2. ICD-NET-001: provisional physical layer

| Property | Revision 0.1 proposal or constraint |
|---|---|
| Signalling | Half-duplex, two-wire RS-485 differential signalling |
| UART | 1,000,000 bit/s, 8 data bits, no parity, 1 stop bit; idle mark |
| Participants | One hub master, addressed adapters; no unsolicited adapter transmit |
| Topology | Linear trunk with short stubs, no passive star or ring |
| Termination | One resistor at each physical trunk end; nominal 120 ohm only if matched to selected cable |
| Bias | At most one engineered idle-bias network, normally at the hub; resistor values derived from transceiver thresholds, termination and supply tolerances |
| Transceiver | MCU-compatible logic interface; receiver idle/fault behaviour and driver-disable timing qualified for chosen part |
| Ground reference | Separate signal reference unless an approved isolation design provides the required common-mode boundary |
| Cable length, stub length, node loading | Open; shall be measured with selected cable and transceivers at 1 Mbit/s |
| EMC/ESD/hot-plug protection | Required design review; component values and ratings open |

The 31-address profile is a protocol limit, not a statement about transceiver
unit loads or achievable length. Two 120 ohm terminations form roughly a
60 ohm differential load before bias and node loads; validate drive margin and
idle differential voltage across tolerance and power states. Internal
receiver fail-safe features do not automatically replace a system bias analysis.

Signal names shall be `NET_P`, `NET_N` and `NET_REF` in RPN schematics. Because
vendor A/B naming varies, the final schematic shall map each part explicitly:
`NET_P` is the line positive relative to `NET_N` for a received UART mark
(logic 1) in the chosen transceiver implementation. This convention must be
verified with a known test pattern rather than inferred from connector labels.

Every transmitter shall default disabled during reset, boot, unpowered MCU
conditions and watchdog recovery. GPIO pull states alone are insufficient
without checking transceiver power sequencing. UART/DMA completion shall mean
the last stop bit has left the pin before driver disable; FIFO empty alone is
not sufficient. Driver-disable and receiver-enable delays shall fit `PS-TIMING`.
A node shall not transmit to report an asynchronous fault; it queues diagnostics
for the next addressed poll.

## 3. ICD-NET-002: harness and connector

Required logical signals are:

| Signal | Function | Unresolved implementation |
|---|---|---|
| NET_P / NET_N | Differential twisted pair | Cable impedance, pair assignment and connector pins |
| NET_REF | Signal reference in non-isolated design | Conductor rating, allowable voltage offset, protection |
| Shield, if used | EMC management; not a substitute for NET_REF | Chassis termination and isolation policy |
| RPN power, if distributed | Optional network power | Voltage, conductor pair, current budget, fuse and connector pins |

No power-carrying bus is authorised by this logical signal list. The initial
bench may use separately current-limited supplies only after grounding review.
If power is later distributed, the supply voltage must be chosen from cable
drop and total-load analysis, not from MCU core voltage.

Connector selection shall consider keying, locking, accidental connection to
other equipment, hot-plug sequence, shield and serviceability. An Ethernet-like
connector does not imply Ethernet compatibility or PoE. No RJ45 pin assignment
is currently selected. Unpowered adapters shall not clamp or drive the bus;
loading, fail-safe behaviour and any phantom-power paths shall be tested.

Termination shall be configurable only at actual trunk ends. Removing a middle
node should not break the trunk unless the selected harness intentionally makes
that a documented limitation. Power or bus faults in one console domain shall
not energise another console.

## 4. Power, grounding and console attachment

### ICD-PWR-001: RPN operating power

The hub shall budget MCU, host-controller, radio, transceiver, downstream device
and accessory current separately. USB host VBUS shall be switched and
current-limited, with overcurrent detection and no reverse feed into a host
upstream connection. Host-port count is not the same as USB device count: hubs,
device speeds, report rates and host-stack support require qualification.

The RP2040 starting point provides one native USB controller, not independent
simultaneous native host and device controllers. Two USB input devices therefore
require a supported USB hub topology or additional host resources. Concurrent
USB device diagnostics, USB host acquisition, Bluetooth transport and PIO console
engines must be resource-budgeted. Software USB/PIO alternatives are proposals,
not guaranteed spare functionality.

Adapter local power shall cover worst-case MCU, transceiver, translation,
storage and any console-interface load. Rumble or accessory emulation shall not
assume that a console supply can power an unrelated modern device.

### ICD-PWR-002: console power and sensing

For each console profile, explicitly select one of: sense-only console power,
console-derived isolated/protected local supply, or externally powered adapter
with compatible console-domain I/O. No selection is made globally in this draft.

Before a console connector is attached, the design shall establish:

1. Normal and worst-case voltage/current for every power and signal pin.
2. Ground/reference and isolation boundaries, including multiple powered consoles.
3. Prevention of back-power through I/O protection diodes, translators, USB or bus.
4. Safe power-up/down ordering and output-high-impedance state when required.
5. Short-circuit, reverse connection and hot-plug behaviour.
6. A safe console activity detector, or an explicit `UNKNOWN` capability.

RS-485 common-mode tolerance is not galvanic isolation. Multiple grounded
consoles can form loops through video equipment and the bus. Whether to isolate
each adapter's bus/power domain is an unresolved system decision (`SAD-O-002`).
No common-ground hardware rollout is approved until the actual deployment is
assessed. Isolation components also consume propagation-delay and power budget.

Console power present is not equivalent to a game polling a controller.
A profile may detect supply presence, valid polling traffic or both, but it
shall state exactly which observation produces its activity status.

## 5. ICD-CON-001: console profile contract

Each adapter profile shall supply a controlled supplement to this interface.
It shall include the following before electrical implementation is approved:

| Required profile field | Acceptance content |
|---|---|
| Identity | Console family, hardware/region variants tested, profile and peripheral IDs |
| Connectors | Actual mating connector, orientation, pin numbering, both player-port wiring and shields |
| Electrical | Voltage domains, absolute maximums, thresholds, pull-ups, open-drain/push-pull direction, drive strength and protection |
| Power | Source, available current, isolation, no-backfeed analysis and all partial-power cases |
| Timing | Measured request/response limits, jitter budget, pulse/clock tolerances, reset/detection and idle behaviour |
| Resources | MCU/PIO/state machines/DMA/interrupt/core/USB/storage needs for every allowed two-port combination |
| Peripheral behaviour | Identification, modes, mapping, neutral/disconnected state, feedback and accessories |
| Persistent data | Local geometry, write/flush policy, endurance and recovery semantics |
| Evidence | Trace captures, test setup, equipment, firmware version and unsupported cases |

The following is a risk inventory, **not** a pinout or validated protocol table:

| Family | Console-local engineering questions |
|---|---|
| NES / SNES | Shift-register/latch/clock behaviour, voltage translation, two-port sampling and any nonstandard controllers |
| N64 / GameCube | Bidirectional timing, turnaround and line drive; N64 accessory selection and storage/rumble behaviour; GameCube analog controls |
| Mega Drive | Multiplexed controller selection, three/six-button modes and mode timing |
| Saturn | Peripheral identification, digital/analog modes and multi-line timing |
| Dreamcast | Maple implementation resources and two-player/peripheral topology; VMU storage versus display/audio/clock completeness |
| PlayStation / PlayStation 2 | Serial handshake and response timing, digital/analog/pressure-capable modes, motor requests and accessory scope |
| Original Xbox | USB-device-side implementation, controller descriptors and compatibility/authentication behaviour to investigate; separate from the hub's USB-host role |

Adapters shall emulate the console interface, not attempt to electrically
forward a modern controller's wires. One virtual peripheral per port is the
initial logical model; compound devices require explicit profile support.
No accessory bus or external memory-card socket is implicitly included.

## 6. ICD-STO-001 and ICD-DBG-001

Persistent media shall be adapter-local for deadline-critical console accesses.
Media selection must consider storage size, erase/program granularity, endurance,
write latency and power-loss recovery. A flash write can disrupt code execution
or interrupts on some MCU arrangements; the implementation shall prove that the
console driver remains safe or disallow that operation while connected.

For RP2040 designs executing from external flash, flash programming/erasure
requires an explicit multicore, interrupt and execute-in-place safety plan.
Merely assigning console work to the other core does not establish independence.
RAM-resident execution or separate storage/processor designs are candidates,
not default solutions.

Local recovery/debug access shall permit restoring a node whose network image
is unusable. Debug must not bypass electrical safety or energise an unpowered
console. Network update is optional until a recovery path is demonstrated.
Recovery connector, boot entry procedure and production debug policy remain open.

## 7. ICD-QUAL-001: qualification and open gates

| Gate | Required evidence | Related requirements |
|---|---|---|
| Bus component choice | Datasheets, loading/bias calculations, oscilloscope eye/edge and mark/space polarity verification | SRS-NET-003, SRS-HW-003 |
| Harness approval | Connector drawing, pinout, cable/stub limits, terminator placement and fault tests | SRS-HW-002..003 |
| Power architecture | Load/drop analysis, isolation decision, ground-current and power-off/backfeed tests | SRS-HW-002..004 |
| Console approval | Completed ICD-CON-001 supplement, two-port traces, safe idle/power transitions | SRS-SYS-005, SRS-PERF-003 |
| Timing/resource approval | Console load plus full bus/USB/storage activity, watchdog and flash-stall injection | SRS-IN-009, SRS-HW-004 |

Actual cable length, connector, supply, isolation, transceiver, console pinouts,
and response timing remain open. External controller documentation and silicon
datasheets must be recorded in each future profile with revision and provenance;
this draft does not claim those investigations or measurements have occurred.
