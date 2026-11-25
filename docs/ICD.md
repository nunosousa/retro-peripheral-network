# Interface Control Document

| Control field | Value |
|---|---|
| Document ID | RPN-ICD |
| Revision | 0.1 |
| Status | Draft - electrical implementation not approved |
| Date | 2026-11-25 |
| Companion documents | [RPN-SRS](SRS.md), [RPN-SAD](SAD.md), [RPN-PS](PS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Initial interface boundaries, provisional RS-485 profile and console electrical qualification gates. |
| 0.1 (2026-11-18) | REVIEW-001 correction cycle: RP2350 platform text and datasheet/errata register; hub USB topology and hub baseline (ICD-HUB-001); isolated-bus and external-power default; profile-contract fields; console capability baseline (ICD-CAP) and verification entries (ICD-VER) added; source register (ICD-REF-001); clock/baud budget; installation figures. |
| 0.1 (2026-11-18, owner decision) | UART rate raised to 2 Mbit/s and trunk length under 5 m: DMA requirement, transceiver/isolator rating, termination by measurement, baud-divider note, ICD-VER-020 criterion. |
| 0.1 (2026-11-18, owner decision) | Memory-card accessory storage in scope: ICD-STO-001 sizing baseline and resource rules, ICD-CON-001 persistent-data field, ICD-CAP-018. |
| 0.1 (2026-11-18, owner decision) | Two-bank FRAM layout and a shared SPI bus confirmed: ICD-STO-001 devices-and-bus rule with the contention budget, section 8.3 GPIO table (N64 16, Dreamcast 20), ICD-VER-021. |
| 0.1 (2026-11-18, owner decision) | Emulated memory-card contents in external FRAM: ICD-STO-001 rules rewritten (flash kept as an exception), ICD-CAP-019, storage-device GPIO in section 8.3, ICD-VER-021. |
| 0.1 (2026-11-18, owner decision) | Memory-card scope narrowed to controller-port accessories (N64 Controller Pak, Dreamcast VMU); dedicated-slot cards and the Xbox Memory Unit out of scope; ICD-CAP-018 and the ICD-STO-001 table revised; the card-slot GPIO estimate withdrawn. |
| 0.1 (2026-11-24, owner decision) | Player count raised from two to four: adapters emulate up to four ports (logical-unit text, ICD-CON-001 port mapping, resources and idle-identity fields, multitap notes); memory-accessory storage, GPIO tables (section 8.3) and the shared-SPI wait recomputed for four ports; Original Xbox ICD-CAP-011 now one USB device interface per emulated port; hub USB hub IC with four downstream ports and about 3 A; ICD-CAP-020 and ICD-VER-022 (multitap) added; ICD-VER-010, 014, 018, 019 and 021 extended to all ports. Supersedes option A of REVIEW-001 RR-001-005. |
| 0.1 (2026-11-25, owner request) | Obsolete cross-references and legacy-source wording removed from the header and sections 8, 10 and 11; no requirement, value or pass criterion changed. |

Classification and normative language follow [RPN-SRS section 1](SRS.md#1-purpose-and-interpretation).
No connector pinout or console voltage table in this draft is approved for wiring.
Absence of a value means unresolved, not permission to infer a safe value.
This ICD is the single electrical authority (`SAD-D-005`).

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
| ICD-USB-001 | Input device to hub | USB host hardware, power and input-report acquisition; native host behind a hub IC (`SAD-P-009`), see `ICD-PWR-001` and `ICD-HUB-001` |
| ICD-NET-001 | Hub/adapter shared bus | Provisional RS-485 electrical profile; RPN-PS owns UART framing and transactions |
| ICD-NET-002 | Network harness and connector | Linear trunk proposal; connector, pin assignment and cable rating open |
| ICD-PWR-001 | RPN operating power | Power distribution, budgeting and protection; hub and adapter power |
| ICD-PWR-002 | Console power and sensing | Never parallel console supplies; sense-only default; per-console qualification required |
| ICD-CON-001 | Adapter to console ports | Profile-specific electrical and timing boundary |
| ICD-CAP-001..020 | Console electrical capability baseline | Sizing baseline and common capabilities (section 8); not an approval to wire |
| ICD-HUB-001 | Hub electrical baseline | Hub USB, power, bus and local I/O (section 9) |
| ICD-VER-001..022 | Verification entries | Pass criteria for the capabilities and interfaces above (section 10) |
| ICD-PLAT-001, ICD-REF-001 | Platform and source registers | RP2350 datasheet/errata register and source provenance (section 11) |
| ICD-STO-001 | Adapter persistent storage | Local accessory/configuration/update storage; technology profile-specific |
| ICD-DBG-001 | Local recovery/debug | Required recoverability, connector/access control open |

The proposed logical unit is one adapter per console, supporting up to four
simultaneously routed ports (`SRS-SYS-009`): every native controller port of the
console, or the slots of a multitap that the profile emulates (`SRS-SYS-010`).
A connector the profile does not populate is left unconnected, so the console
sees no controller there. This is not a claim that one MCU can service every
four-port combination; the resource tables decide, and some profiles need the
RP2350B (`SAD-P-007`). Adapter internals may contain multiple MCUs, translators,
connectors and isolated domains under one network endpoint (`SAD-ADAPT-001`).
Console and hub processors are RP2350 family parts (`SRS-HW-005`).

## 2. ICD-NET-001: provisional physical layer

| Property | Revision 0.1 proposal or constraint |
|---|---|
| Signalling | Half-duplex, two-wire RS-485 differential signalling |
| UART | 2,000,000 bit/s (5 us per byte), 8 data bits, no parity, 1 stop bit; idle mark. At 200 kbyte/s reception and transmission shall be DMA-driven; per-byte interrupt service is not acceptable on a node that also runs a console timing engine |
| Participants | One hub master, addressed adapters; no unsolicited adapter transmit |
| Topology | Linear trunk with short stubs, no passive star or ring |
| Termination | One resistor at each physical trunk end; nominal 120 ohm only if matched to selected cable. Whether termination is needed on a trunk under 5 m at 2 Mbit/s is decided by measurement; until then the provision for it stays |
| Bias | At most one engineered idle-bias network, normally at the hub; resistor values derived from transceiver thresholds, termination and supply tolerances |
| Transceiver | MCU-compatible logic interface; rated with margin above 2 Mbit/s including its isolator (propagation delay, pulse-width distortion and skew budgeted against a 500 ns bit); receiver idle/fault behaviour and driver-disable timing qualified for chosen part |
| Ground reference | Default (`SAD-P-010`): an isolated bus interface at every adapter, using an isolated transceiver and isolated power, so adapter and console grounds are not joined through the bus; a non-isolated reference needs an approved design for the actual deployment |
| Clock and baud error | Every node derives the baud rate from a crystal-derived clock of at most +/-100 ppm (`SRS-NET-010`); internal RC oscillators are not used for the bus. Proposed budget: total baud error per node (oscillator plus divider granularity) at most +/-0.5 % (value to be confirmed); the divider achievable at the chosen RP2350 system clock (for example, with a 150 MHz peripheral clock a PL011-type UART needs a divisor of 4.6875 for 2 Mbit/s, which is exactly representable; to be confirmed against the datasheet and the real clock), the sampling margin with RS-485 and isolator distortion (isolator pulse-width distortion is a larger share of a 500 ns bit than of a 1 us bit), and the resulting margin shall be calculated and measured (`ICD-VER-017`) |
| Cable length, stub length, node loading | Open; first harness calculation for up to 10 adapters on a trunk of less than 5 m (`SRS-SYS-008`); shall be measured with selected cable and transceivers at 2 Mbit/s |
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
without checking transceiver power sequencing (and the MCU's own internal pulls
are not relied on, `SRS-HW-006`). Isolator propagation delay and driver
enable/disable delay shall be measured and shall fit the margins of `PS-TIMING`
(`ICD-VER-020`). UART/DMA completion shall mean
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

The RP2350 has one native full-speed (USB 1.1) controller, not independent
simultaneous native host and device controllers (to be re-verified against the
datasheet recorded in `ICD-PLAT-001`). The hub therefore uses that controller as
the USB host behind a **USB hub IC** with enough downstream ports to attach four
player input devices (`SAD-P-009`); a software (PIO) USB host is not counted on
and no PIO state machine is budgeted for it. The single controller cannot also
act as a USB device, so hub diagnostics use the UART/debug interface
(`ICD-DBG-001`). The hub resource budget (PIO state machines, DMA channels,
interrupts, RAM and GPIO for the USB host stack, the RS-485 UART and its
direction control, the local display and buttons) shall be recorded in
`ICD-HUB-001` and keep the 70 % margin rule of `ICD-CON-001`. Bluetooth transport
remains Future (`SAD-F-001`). "Four devices" passes only by `ICD-VER-018`.

Adapter local power shall cover worst-case MCU, transceiver, isolator, translation,
storage and any console-interface load. Rumble or accessory emulation shall not
assume that a console supply can power an unrelated modern device.

### ICD-PWR-002: console power and sensing

The default (`SAD-P-010`) is: each adapter externally powered, console power
sensed only, and an isolated bus interface at every adapter. Console rails are
never connected to the adapter's internal logic supply and never to each other
(`ICD-CAP-012`); the sense path is protected and high-impedance. Selecting
instead a console-derived isolated/protected local supply, or a non-isolated
bus reference, for a profile is an exception that needs a profile-specific
power analysis, owner approval and a `SAD` register entry; "not directly
connected" and "protected derived supply" are therefore no longer alternatives
in different documents but a default and a controlled exception.

Before a console connector is attached, the design shall establish:

1. Normal and worst-case voltage/current for every power and signal pin.
2. Ground/reference and isolation boundaries, including multiple powered consoles.
3. Prevention of back-power through I/O protection diodes, translators, USB or bus.
4. Safe power-up/down ordering and output-high-impedance state when required.
5. Short-circuit, reverse connection and hot-plug behaviour.
6. A safe console activity detector, or an explicit `UNKNOWN` capability.

RS-485 common-mode tolerance is not galvanic isolation. Multiple grounded
consoles can form loops through video equipment and the bus, and the N64 and
GameCube ports supply very little current, which is why the default isolates the
bus at every adapter. Isolation is verified by the ground-loop and back-power
tests of `ICD-QUAL-001`; no common-ground hardware rollout is approved until the
actual deployment is assessed. Isolation components consume propagation-delay and
power budget (`PS-TIMING`).

Console power present is not equivalent to a game polling a controller.
A profile may detect supply presence, valid polling traffic or both, but it
shall state exactly which observation produces its activity status.

## 5. ICD-CON-001: console profile contract

Each adapter profile shall supply a controlled supplement to this interface.
It shall include the following before electrical implementation is approved:

| Required profile field | Acceptance content |
|---|---|
| Identity | Console family, hardware/region variants tested, profile and peripheral IDs |
| Connectors | Actual mating connector, orientation, pin numbering, wiring of every emulated port and shields |
| Port mapping | Mapping from PS `port` IDs 0 to 3 to physical connectors or multitap slots; which connectors are populated or unconnected and what the console sees on an unused connector (`SRS-SYS-009`); the multitap decision (`SRS-SYS-010`): none, or the model, its protocol limits, the populated slots and the slot-to-port mapping |
| Electrical | Per console and signal: voltage range (min/typ/max), absolute maximums, thresholds, open-drain/push-pull direction, drive strength, protection, who supplies each pull-up (location and value) and the translator or clamp approach; the adapter adds no pull-up on a line the console already pulls up (`ICD-CAP-010`) |
| Connector module | Hardware module ID or strap, voltage domain and drive type of the module (`ICD-CAP-004`) |
| Power | Source, available current, isolation, no-backfeed analysis and all partial-power cases |
| Timing | Measured request/response limits, jitter budget, pulse/clock tolerances, reset/detection and idle behaviour |
| Dynamics | Nominal signalling rate and tolerance, required VIH/VIL and VOH/VOL at the console, maximum rise/fall time, maximum added propagation delay, skew between related lines, input and protection capacitance budget (`ICD-CAP-015`) |
| Idle identity | Default peripheral identity presented while inhibited or configured and on every unrouted port while armed (`SRS-IN-014`), what a multitap presents for an unrouted slot, and whether a live peripheral change is allowed (`SRS-IN-011`) |
| Neutralisation | `neutralisation_bound_us` and the measurement points at which neutral state becomes visible to the console after REVOKE, including any in-flight console transaction, which for a multitap spans all its slots (`SRS-OWN-013`, `ICD-VER-016`) |
| Resources | Resource table on the chosen RP2350 variant: GPIO (console channels plus system I/O of `ICD-CAP-014`), PIO state machines, DMA channels, interrupts, RAM, USB controllers and storage for every allowed port combination. Margin rule: no more than 70 % of any resource in the worst all-port combination |
| Peripheral behaviour | Identification, modes, mapping, neutral/disconnected state, feedback and accessories |
| Persistent data | Memory accessory (if any): type, console-visible capacity, geometry and identity; external storage device (part, capacity, interface; one per port on a shared bus), bank layout, shared-bus access time under contention, torn-write and power-fail behaviour, endurance figure against the worst-case write rate, console access time against the console's response limit, any RAM cache, maintenance transfer time; behaviour when absent or being maintained (`ICD-STO-001`, `SRS-STO-005..008`) |
| Evidence | Trace captures, test setup, equipment, firmware version and unsupported cases; measurements on at least one console of each family before approval; source register entries with revision and retrieval date |

The following is a risk inventory, **not** a pinout or validated protocol table:

| Family | Console-local engineering questions |
|---|---|
| NES / SNES | Shift-register/latch/clock behaviour, voltage translation, two-port sampling and any nonstandard controllers; a latched shift register delivers its 16 bits over roughly 200 us, so the neutralisation measurement spans a full read. Multitaps (`SAD-P-013`): the NES Four Score uses both ports with no further signals (a 24-bit read with signature bits); the SNES multitap needs the Data2 and IOBit signals that the baseline excludes, two more channels per tapped port |
| N64 / GameCube | Bidirectional timing, turnaround and line drive; N64 Controller Pak read/write timing and its 32 KiB image; rumble behaviour; GameCube analog controls; neutral visibility after a transaction already started. All four ports are emulated, so the resource table covers every port and, for the N64, four Controller Pak images |
| Mega Drive | Multiplexed controller selection, three/six-button modes and mode timing. Measurement list: TH-edge timing and the six-button pad idle timeout after which the TH count resets. Multitaps: Sega Team Player and EA 4 Way Play are mutually incompatible, and in the Team Player protocol the console drives TH and TR while the tap answers on TL, so TR changes direction from the baseline's pad-driven output (`ICD-CAP-005`, `ICD-CAP-020`) |
| Saturn | Peripheral identification, digital/analog modes and multi-line timing; the 3D Control Pad is in scope, so the TL handshake output and TH/TR request timing are measured. Measurement list: TH/TR handshake edges and response timing, and mode behaviour. The multitap has six slots, four of which are used (`SAD-O-015`) |
| Dreamcast | Maple implementation resources and the four-port/peripheral topology; drive type, levels, pull-up arrangement and any presence/sense pin to be taken from primary Maple documentation; VMU memory emulation (128 KiB flash, block geometry and format) is in scope per port; VMU display/audio/clock completeness is not (`SRS-UI-004`) |
| PlayStation / PlayStation 2 | Serial handshake and response timing, digital/analog/pressure-capable modes, motor requests and accessory scope (memory cards are out of scope: dedicated slot, no shared signals). Multitaps (four controllers per port) answer with longer packets, so the neutralisation measurement spans a full tap read; the PlayStation tap reuses the controller-port signals, PlayStation and PlayStation 2 software need different taps, and whether the PlayStation 2 tap also uses the memory-card slot (out of scope, `ICD-CAP-018`) is to be verified |
| Original Xbox | USB-device-side implementation, controller descriptors and compatibility/authentication behaviour to investigate; separate from the hub's USB-host role. Up to four emulated USB device ports, each on its own processor behind one gateway (`SAD-P-008`, `SAD-ADAPT-001`); the report already queued in a controller endpoint must be covered by the neutralisation measurement |

Adapters shall emulate the console interface, not attempt to electrically
forward a modern controller's wires. One virtual peripheral per port is the
initial logical model; compound devices require explicit profile support.
No accessory bus or external memory-card socket is implicitly included beyond
the memory accessory the profile declares under `ICD-STO-001`; any other accessory
needs explicit profile support.

## 6. ICD-STO-001 and ICD-DBG-001

Persistent media shall be adapter-local for deadline-critical console accesses.
Media selection must consider storage size, erase/program granularity, endurance,
write latency and power-loss recovery. A flash write can disrupt code execution
or interrupts on some MCU arrangements; the implementation shall prove that the
console driver remains safe or disallow that operation while connected.

### Memory accessory storage (SRS-STO-005..006)

Memory-card storage is in scope for accessories attached through the controller
port (N64 Controller Pak, Dreamcast VMU) and is the adapter's responsibility: it holds the
authoritative data and the console never waits on the network (`SAD-D-003`). The
initial scope is one accessory per emulated port, up to four per adapter. Each profile
determines the resources below before approval (`ICD-CON-001` "Persistent data"
and "Resources" fields).

Sizing baseline. Capacities and attachment are leads from general knowledge, not
primary sources (`ICD-REF-001`: secondary, unverified); each profile replaces
them with verified values.

| Console | Accessory (lead) | Attached via | Capacity per accessory | Data for four ports |
|---|---|---|---:|---:|
| N64 | Controller Pak (battery-backed SRAM) | Controller data line, no extra pins | 32 KiB | 128 KiB |
| Dreamcast | VMU (flash; also LCD, buzzer, clock outside this scope) | Controller, over the Maple bus | 128 KiB | 512 KiB |
| PlayStation, PlayStation 2, GameCube | Memory cards | Out of scope (owner decision): dedicated card slot, no signals shared with the controller port | - | - |
| Original Xbox | Memory Unit | Out of scope (owner decision: limited use) | - | - |
| NES, SNES, Mega Drive, Saturn | None in the controller port (Saturn backup memory is a console or cartridge feature) | - | - | - |

Storage device (`SRS-STO-008`, `SAD-P-012`). The accessory image is held in
non-volatile storage external to the MCU; external SPI (or QSPI) **FRAM** is the
proposed device. Compared with MCU-attached flash, FRAM needs no erase and no
wear levelling, never blocks execute-in-place reads, and keeps the data across a
power loss without a flush policy. Device facts below are from general knowledge
and need datasheet confirmation (`ICD-PLAT-001`, `ICD-REF-001`).

Resource rules for every profile with a memory accessory:

- **Capacity.** The part holds two banks (layout confirmed by the owner) of the accessory image (active and
  staging) plus a small bank-select record, so that a network replacement is
  installed atomically (`SRS-STO-004`): a staged image is written and verified in
  the idle bank, then one record write makes it active. Parts: 2 x 32 KiB for the
  N64 Controller Pak needs a 512 kbit part; 2 x 128 KiB for the Dreamcast VMU
  needs a 2 Mbit part (both are common SPI FRAM densities; verify). Accessory
  identity and format flags live in the adapter configuration, not in the image.
- **Devices and bus (owner decision: shared bus).** One FRAM per emulated port
  (up to four per adapter) on a single shared SPI bus with its own chip select
  each: 7 GPIO in total (SCK, MOSI, MISO, four CS; `ICD-CAP-019`). One SPI
  controller with DMA serves all devices and accesses are serialised, so a console
  access can wait for one transfer of each other port. The access-time budget
  therefore includes that wait: worst case four times the transfer, about 29 us for
  four 32-byte blocks and about 413 us for four 512-byte blocks at 40 MHz (the
  owner's decision was taken for two ports, where the wait was half of this). The
  arbiter runs from interrupt or DMA context, never from the network task, and no
  port's accesses may be starved. Network export, import and verification run only
  in maintenance, when the consoles are quiescent (`SRS-STO-003`), so they never
  contend with console accesses.
- **Access time.** Without contention, an SPI read or write of a 32-byte block (36 bytes with the
  command and address) at 40 MHz takes about 7 us; a 512-byte block (516 bytes)
  about 103 us. Whether this fits each console's response limit, including the
  shared-bus wait above, is a measurement (`ICD-VER-021`); if a read is too slow, a small write-through RAM
  cache or prefetch may be used as a latency device only, never as the
  authoritative copy, a QSPI part is chosen, or the devices are split over the
  two SPI controllers (two per bus: the two-port wait of 206 us for three more
  GPIO).
- **Writes and power fail.** A console block write is acknowledged to the console
  only after the FRAM write has completed (write-through; no dirty state, so
  `dirty_resources` stays zero). A write interrupted by power loss can tear that
  one block; the profile states how the console's own checksums and redundancy
  absorb it, and a power-loss detector with a small hold-up lets an in-flight
  block finish and blocks new writes.
- **Endurance.** FRAM endurance is typically 10^12 cycles or more (verify). The
  profile still states the figure against the worst-case write rate: one write
  per millisecond to the same block for 10 years is about 3.2 x 10^11 cycles.
- **Maintenance transfer time.** Export and import move the whole accessory in
  183-byte chunks at about 1.60 ms per exchange (`PS-TIMING` at 2 Mbit/s), so the
  bus is the lower bound: 32 KiB 0.3 s and 128 KiB 1.1 s per accessory, times the
  number of accessories (four: about 1.2 s and 4.6 s). Verifying a staged 128 KiB image over SPI at 40 MHz takes about 26 ms and
  there is no programming time. Maintenance is never armed, so this does not
  affect the 5 ms input cadence.
- **Presence and identity.** The profile states what the console sees when the
  accessory is absent, being maintained, or after a failed commit
  (`PS-MAINTENANCE`), and the accessory identity (serial, format) it presents.
- **Interface.** An in-scope accessory is reached through the controller
  connector and adds no console channels (`ICD-CAP-018`); the storage device's
  own GPIO are counted separately (section 8.3).
- **Exception.** A profile for which external FRAM is not applicable may use
  MCU-attached flash with a RAM-resident working set, copy-on-write commits,
  spare area, a flush and rate-limit policy, hold-up for the dirty set, and the
  execute-in-place safety plan below; it needs an owner-approved register entry.

For RP2350 designs executing from external flash, flash programming/erasure
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
| Console approval | Completed ICD-CON-001 supplement, all-port traces, safe idle/power transitions | SRS-SYS-005, SRS-PERF-003 |
| Timing/resource approval | Console load plus full bus/USB/storage activity, watchdog and flash-stall injection; resource table within the 70 % margin | SRS-IN-009, SRS-HW-004 |
| Platform register | `ICD-PLAT-001` completed from the current RP2350 datasheet and errata, with no console-facing signal relying on MCU 5 V tolerance or internal pulls | SRS-HW-005, SRS-HW-006 |
| Capability verification | `ICD-VER-001..022` executed with pass criteria populated from the approved supplement | SRS-HW-002..006, SRS-OWN-013 |
| Hub baseline | `ICD-HUB-001` figures confirmed by the power budget and `ICD-VER-018..019` | SRS-HW-004, SRS-UI-001 |

Actual cable length, connector, supply, isolation, transceiver, console pinouts,
and response timing remain open. External controller documentation and silicon
datasheets must be recorded in each future profile with revision and provenance
(`ICD-REF-001`); this draft does not claim those investigations or measurements
have occurred.

## 8. ICD-CAP: console electrical capability baseline

This section is under ICD authority (`SAD-D-005`). Its classes follow the SRS
rule. It is a **sizing baseline** and a set of common capabilities, never an
approval to wire: approved per-console facts live in the ICD-CON-001
supplements, which may narrow but not exceed this baseline without an ICD change.
Where this section and another ICD section differ, the other section takes
precedence.

### 8.1 Capabilities

| ID | Class | Capability |
|---|---|---|
| ICD-CAP-001 | D | Authority and precedence as stated above: baseline for sizing, supplements for approved facts; one source per fact. |
| ICD-CAP-002 | P | RPN internal digital logic is a 3.3 V domain (RP2350 I/O domain, to be confirmed in `ICD-PLAT-001`). Console voltage adaptation happens at the console-facing boundary only. |
| ICD-CAP-003 | D | Console-facing signals reach MCU GPIO only through external translation and protection. No console-facing signal relies on MCU-side 5 V tolerance or on internal pull-up/pull-down resistors (`SRS-HW-006`). |
| ICD-CAP-004 | D | The voltage domain and drive type of a console channel are a hardware-defined property of the console connector module, readable by firmware (module ID or strap). Firmware refuses a profile that does not match the module. High-impedance is the only state reachable without a valid module/profile match, and runtime-selectable 5 V push-pull is not provided on 3.3 V-class or open-drain lines. |
| ICD-CAP-005 | D | Across the set of modules the platform provides: input, push-pull output at the module's domain, open-drain output, high-impedance, independent direction control, half-duplex operation, prevention of contention and deterministic direction switching. A single module need not do everything. |
| ICD-CAP-006 | D | All console-facing drivers are high-impedance during reset, initialisation, watchdog recovery and when the MCU is unpowered. |
| ICD-CAP-007 | D | No path back-powers a console, the adapter or the bus when either side is unpowered; unpowered MCU with powered console and powered MCU with unpowered console are both verified (`ICD-VER-011`, `ICD-VER-015`). |
| ICD-CAP-008 | D | Every externally accessible console-facing signal has ESD, short-circuit, overvoltage and current-injection protection that does not compromise the console's timing or levels (`ICD-VER-012`). |
| ICD-CAP-009 | P | Auto-direction level translators are not used on open-drain bidirectional lines unless measurement shows they meet the profile's dynamics; direction-controlled or discrete open-drain structures are the default. |
| ICD-CAP-010 | D | Each profile names who supplies every pull-up (console or controller side) and its value; the adapter adds no pull-up on a line that the console already pulls up. |
| ICD-CAP-011 | P | The Original Xbox adapter provides one USB 1.1 full-speed device interface per emulated port (four for a four-port profile), each on its own processor, with USB signal protection (`SAD-P-008`). A transceiver shared between physical ports is not sufficient. |
| ICD-CAP-012 | D | Console power rails are never connected to the internal 3.3 V logic supply or to each other; the power architecture separates console power, internal logic, pull-up supplies and peripheral/motor power. Motor supply is outside the initial scope. |
| ICD-CAP-013 | P | Console channel quantities in section 8.2 are the minimum for standard controller operation of the emulated ports (two or four, as section 8.2 states per console). |
| ICD-CAP-014 | P | Adapter system I/O (section 8.3) is counted with the console channels in every profile's GPIO budget on the chosen RP2350 variant. |
| ICD-CAP-015 | P | Every profile gives the dynamics columns of section 8.4; no translator or protection part is approved without them. |
| ICD-CAP-016 | P | Connector power characteristics (section 8.5) are treated as unverified leads until measured or taken from primary documentation. |
| ICD-CAP-017 | D | Out of scope for the baseline: analog electrical interfaces, video synchronisation signals, light guns and specialist peripherals, accessory signals needing extra connector pins other than a declared memory accessory (`ICD-CAP-018`), physical motor drive circuitry, and general digital protocols beyond the electrical boundary. |
| ICD-CAP-018 | D | A profile's memory accessory interface (`ICD-STO-001`, `SRS-STO-005`) is in scope only when the accessory is reached through the controller port, sharing its signals (N64 Controller Pak, Dreamcast VMU); it then adds no channels to the baseline. Memory cards in a dedicated card slot (GameCube, PlayStation, PlayStation 2) and the Original Xbox Memory Unit are out of scope, so no card-slot interface is provided. |
| ICD-CAP-019 | P | Emulated memory accessory contents are held in an external non-volatile device, proposed FRAM (`SRS-STO-008`, `ICD-STO-001`). Its SPI/QSPI signals, 3.3 V supply and decoupling are part of the adapter and are counted in the GPIO budget (section 8.3). The device is never reachable from a console-facing signal. |
| ICD-CAP-020 | P | A profile that emulates a multitap (`SRS-SYS-010`, `SAD-P-013`) presents it through the console's own controller connector. The channels its protocol needs beyond the section 8.2 baseline are counted in the profile's GPIO budget: from the secondary sources, the SNES multitap adds Data2 and IOBit (two channels per tapped port) and the Mega Drive taps need TR as a direction-controlled channel, while the NES, PlayStation and Saturn taps add none; the PlayStation 2 tap is unverified (it may also use the memory-card slot, `ICD-CAP-018`). An unrouted slot follows `SRS-IN-014`. |

### 8.2 Console channel sizing baseline (emulated ports)

Direction is relative to the adapter. Values are leads from the secondary
sources of `ICD-REF-001` (confidence: secondary, unverified). Channel counts are
the minimum for standard controller operation; bidirectional channels are
counted once. Each console is sized for all its native controller ports
(`SRS-SYS-009`); a multitap changes the count only as `ICD-CAP-020` states.

| Console | Native ports | Signals per port | Channels per port | Channels, all ports | Notes and corrections |
|---|---:|---|---:|---:|---|
| NES | 2 | Clock in, Latch in, Data out | 3 | 6 | Accessory signals excluded |
| SNES | 2 | Clock in, Latch in, Data out | 3 | 6 | `Data2`, `IOBit` excluded (a multitap needs them, `ICD-CAP-020`) |
| Mega Drive | 2 | Up, Down, Left, Right, TL, TR out; TH in | 7 | 14 | Six-button mode mandatory, three-button through the same interface; measure TH-edge timing and idle timeout |
| Saturn | 2 | D0..D3 out, **TL out**; TH, TR in | 7 | 14 | TL is a pad-driven handshake output; the 3D Control Pad is in scope |
| Nintendo 64 | 4 | Data bidirectional, open-drain | 1 | 4 | 3.3 V open-drain; all four connectors are emulated |
| GameCube | 4 | Data bidirectional, open-drain | 1 | 4 | As N64 |
| Dreamcast | 4 | SDCKA, SDCKB bidirectional | 2 | 8 | Drive type, levels and presence/sense line unresolved (primary Maple documentation needed); reserve one presence/sense channel per port (+4, to be confirmed) |
| PlayStation | 2 | CMD, ATT, CLK in; DATA, ACK open-drain out | 5 | 10 | |
| PlayStation 2 | 2 | As PlayStation | 5 | 10 | |
| Original Xbox | 4 | One USB full-speed device interface | 1 USB | 4 USB | Not a digital channel; one processor per port |

Largest console channel count: 14 (Mega Drive and Saturn, two ports); the
Dreamcast reaches 12 with its presence lines at four ports.

### 8.3 Adapter system I/O and GPIO budget

| Function | GPIO (two ports) | GPIO (four ports) | Note |
|---|---:|---:|---|
| Bus UART TX, RX and RS-485 direction/enable | 3 | 3 | Through the isolated transceiver |
| Console power sense (one per emulated port) | 2 | 4 | Sense-only (`ICD-PWR-002`); a profile whose ports share one console supply may sense once |
| Physical commissioning enable | 1 | 1 | `PS-DISCOVERY` |
| Recovery/boot-select input | 1 | 1 | `ICD-DBG-001` |
| Status LEDs | 2 | 2 | |
| **System I/O total** | **9** | **11** | Translator direction/enable lines not yet counted: depends on translator selection |

| Console | Ports | Console channels | System I/O | Total GPIO | Share of RP2350A (30) | Margin rule (21) |
|---|---:|---:|---:|---:|---:|---|
| NES, SNES | 2 | 6 | 9 | 15 | 50 % | Within |
| Nintendo 64, GameCube | 4 | 4 | 11 | 15 | 50 % | Within |
| Dreamcast (with +4 presence, to be confirmed) | 4 | 12 | 11 | 23 | 77 % | Exceeds: RP2350B (48 GPIO, 33 within the margin rule) or a split design |
| PlayStation, PlayStation 2 | 2 | 10 | 9 | 19 | 63 % | Within |
| Mega Drive, Saturn | 2 | 14 | 9 | 23 | 77 % | Exceeds: RP2350B (48 GPIO) or a split design |

A two-port build of an N64, GameCube or Dreamcast adapter (`SRS-SYS-009`) uses
the two-port figures: 11, 11 and 15. A multitap changes these figures only as
`ICD-CAP-020` states; for example the SNES with a multitap on each port needs 10
channels and 19 GPIO.

Memory accessory storage device (`ICD-CAP-019`, only for profiles with one),
counted separately from the table above. The shared SPI bus (owner decision) adds
7 GPIO at four ports (SCK, MOSI, MISO and four chip selects; 5 at two ports):

| Console | Table total | Storage device GPIO | Total | Share of RP2350A (30) | Margin rule (21) |
|---|---:|---:|---:|---:|---|
| Nintendo 64 | 15 | 7 | 22 | 73 % | Exceeds by one (19 and within if the profile senses console power once) |
| Dreamcast | 23 | 7 | 30 | 100 % | Exceeds: RP2350B (30 of its 33 margin GPIO) |

Translator direction/enable lines are still not counted. At four ports the
Dreamcast exceeds the RP2350A margin even before storage (23), so it needs the
RP2350B, where 30 of 33 leaves little for translators. A separate bus per port
(16 GPIO, 39 in total for the Dreamcast) would exceed even the RP2350B margin and
is not adopted; two buses of two devices (three more GPIO, 33 in total, at the
limit) remain the fallback of `ICD-STO-001`.

The 30 and 48 GPIO figures are for the RP2350A and RP2350B packages
(`SAD-P-007`) and are to be re-verified in `ICD-PLAT-001`. The Original Xbox
gateway/USB processors have no digital console channels; their budget is internal
link, bus and USB.

### 8.4 Dynamics (per console, to be completed by each supplement)

| Console | Nominal signalling rate (lead) | Required levels, delay, skew, capacitance |
|---|---|---|
| NES / SNES | Clock in the tens of kHz | From the supplement (open) |
| Mega Drive / Saturn | TH/TR handshake driven by the console; rate from the supplement | From the supplement (open) |
| Nintendo 64 / GameCube | About 4 us per bit, fast edges on an open-drain line | From the supplement (open) |
| Dreamcast | Multi-Mbit/s Maple signalling | From the supplement (open) |
| PlayStation / PlayStation 2 | A few hundred kHz clock | From the supplement (open) |
| Original Xbox | USB full speed (12 Mbit/s) | USB specification limits |

### 8.5 Connector power characteristics (unverified leads)

| Console | Reported connector power | Confidence |
|---|---|---|
| NES, SNES, Mega Drive, Saturn, Dreamcast | 5 V | secondary |
| Nintendo 64 | 3.3 V | secondary |
| GameCube | 5 V and about 3.43 V | secondary |
| PlayStation, PlayStation 2 | About 3.5 V logic and 7.5 V motor supply | secondary |
| Original Xbox | 5 V USB VBUS | secondary |

The high level on a 3.5 V-class line may exceed what a 3.3 V MCU pad tolerates,
which is why `ICD-CAP-003` requires external translation for every console-facing
signal.

## 9. ICD-HUB-001: hub electrical baseline

| Item | Baseline (class P unless noted) |
|---|---|
| Processor | One RP2350 family part (`SRS-HW-005`) |
| USB host | Native full-speed controller behind a USB hub IC; at least four downstream ports for the four players; per-port switched VBUS with current limit and overcurrent detection (`ICD-PWR-001`); four devices (an interrupt IN endpoint each, plus an OUT endpoint where a device takes rumble over one) and the hub IC's status endpoint fit the host controller's 15 interrupt endpoints (SDK register layout; to be confirmed in `ICD-PLAT-001`) |
| VBUS current | 500 mA per downstream port (USB 2.0 unit-load limit); wheels or other heavy devices are not covered (Future) |
| Power input | External 5 V supply sized from the budget: four downstream ports (4 x 500 mA), hub IC, MCU, transceiver, isolator and display with margin (about 3 A as a starting figure, to be confirmed) |
| Bus transceiver | Isolated RS-485 transceiver with isolated power, driver default-disabled (`ICD-NET-001`) |
| Local I/O | Owner selector and indicators (`SRS-UI-001`); player-assignment input (`SRS-UI-002`); small display (`SRS-UI-003`); recovery/boot input; all counted in the hub GPIO budget |
| Protection | ESD on USB and bus connectors, reverse-polarity and overcurrent protection on the supply input |
| Resource budget | Recorded per `ICD-PWR-001`; 70 % margin rule |

Figures marked "to be confirmed" are placeholders for the first power budget, not
approved values.

## 10. ICD-VER: verification entries

Each entry verifies the listed capabilities. "Supplement" means the approved
ICD-CON-001 supplement of the profile under test; an entry cannot be executed
until its supplement values are populated.

| ID | Verifies | Activity | Pass criterion |
|---|---|---|---|
| ICD-VER-001 | ICD-CAP-003, 004 | 3.3 V-class input compatibility | At the supplement's minimum and maximum rail, every received level is read correctly and the pad voltage never exceeds the datasheet absolute maximum in `ICD-PLAT-001` |
| ICD-VER-002 | ICD-CAP-003, 004 | 5 V-class input compatibility through the translator | As 001 with the 5 V module; measured pad voltage within the datasheet limit |
| ICD-VER-003 | ICD-CAP-005 | 3.3 V push-pull output levels | VOH/VOL meet the supplement's console VIH/VIL with the supplement's noise margin (proposed default 0.3 V) |
| ICD-VER-004 | ICD-CAP-005 | 5 V push-pull output levels | As 003 on a 5 V module |
| ICD-VER-005 | ICD-CAP-005, 009, 010 | Open-drain operation | VOL and rise time meet the supplement; no adapter pull-up on a console-pulled line |
| ICD-VER-006 | ICD-CAP-006 | High-impedance state | Leakage into and out of the console line, and change of the console-observed level, within the supplement limit when the driver is high-impedance |
| ICD-VER-007 | ICD-CAP-005 | Independent channel direction control | Each channel's direction changes without a glitch on any other channel above the supplement limit |
| ICD-VER-008 | ICD-CAP-005, 009 | Bidirectional operation | Turnaround within the supplement's delay budget at the nominal signalling rate |
| ICD-VER-009 | ICD-CAP-005 | Absence of contention | No interval in which adapter and console both drive a line (current and waveform capture) |
| ICD-VER-010 | ICD-CAP-011 | USB full-speed operation on every emulated Xbox port | All emulated ports (four in a four-port profile) enumerate and carry reports simultaneously for 10 minutes without error |
| ICD-VER-011 | ICD-CAP-007, 012 | Power sequencing and back-power prevention | Current into any unpowered side below the supplement limit in every partial-power order |
| ICD-VER-012 | ICD-CAP-008 | ESD and overvoltage protection | Passes the levels set by the ESD plan of `SRS-ENV-001` (not executable until that plan exists) and the console timing is unchanged |
| ICD-VER-013 | ICD-CAP-012 | Port power current limiting | Limit and trip current as set by the supplement; no damage on a short |
| ICD-VER-014 | ICD-CAP-013, 014 | Operation under simultaneous port activity | All emulated ports and the bus active at maximum load meet the supplement's timing and the 70 % resource margin |
| ICD-VER-015 | ICD-CAP-006, 007 | Unpowered MCU with powered console | Each channel stays high-impedance and no console-observed level change beyond the supplement limit; repeated across silicon steppings of `ICD-PLAT-001` |
| ICD-VER-016 | SRS-OWN-013 | Neutralisation visible at the console | Measured time from REVOKE acknowledgement to neutral state at the console connector, including an in-flight transaction, at most the declared `neutralisation_bound_us` and at most 1 ms |
| ICD-VER-017 | SRS-NET-010, ICD-NET-001 | Baud error and sampling margin | Measured per-node error within the budget, sampling margin positive with isolator and transceiver distortion, no framing errors in 10 minutes at full cadence |
| ICD-VER-018 | ICD-USB-001, SAD-P-009 | Hub four-device acceptance | Four HID devices, at least one low-speed and one full-speed, enumerate through the hub IC, report at their descriptor intervals for 10 minutes with no missed report (no sequence gap over twice the interval) and no enumeration loss on hot-plug; unplugging and reconnecting one device does not disturb the reports of the others |
| ICD-VER-019 | ICD-HUB-001 | Hub VBUS limiting | Each downstream port limits and reports overcurrent at its configured limit and recovers without disturbing the other ports |
| ICD-VER-020 | ICD-NET-001, PS-TIMING | Isolated bus delays at 2 Mbit/s | Isolator propagation plus driver enable/disable delay fit the 20 us disable allowance and 50 us earliest-response gap with margin, and isolator pulse-width distortion leaves a positive sampling margin on a 500 ns bit |
| ICD-VER-021 | ICD-CAP-018, ICD-CAP-019, ICD-STO-001 | Memory accessory per port | The console formats, saves, loads and copies an accessory of the declared capacity from all emulated ports at the same time; an inactive console reads its own accessory; every read and write of the storage device meets the console's response limit at the worst-case access time including the shared-bus wait with all ports active; power removed during a block write and during a maintenance commit leaves a valid old or new image (a torn block is absorbed as the profile states); the endurance figure and export/import time meet the resource table |
| ICD-VER-022 | ICD-CAP-020, SRS-SYS-010 | Multitap emulation (only for a profile that emulates one) | With the declared tap model, the console detects the tap, reads every populated slot independently and shows the idle identity on an unrouted slot; a game that supports the tap runs with up to four players; neutral state after REVOKE is visible within the declared `neutralisation_bound_us` across a full tap read; the extra channels meet the supplement's dynamics |

## 11. Registers

### ICD-PLAT-001: RP2350 datasheet and errata register

| Field | Entry |
|---|---|
| Datasheet and revision consulted | Not yet recorded. The datasheet to be used is the current Raspberry Pi RP2350 datasheet (document RP-008373-DS at the revision current on the retrieval date) |
| Stepping(s) targeted | Not yet recorded |
| Facts to verify before Step 4 | Package/GPIO variants (30 and 48 GPIO), PIO blocks and state machines, single USB controller, its host mode and its host interrupt-endpoint count (15 in the SDK register layout), OTP user area and locking behaviour, hardware random number generator, GPIO input voltage tolerance conditions, flash/XIP behaviour |
| Errata to check | Any published erratum on GPIO pad leakage, input pull-down behaviour or high-impedance behaviour on the targeted stepping |

| Errata ID | Stepping | Affected interface | Mitigation | Status |
|---|---|---|---|---|
| (none recorded) | | | | Register not yet populated |

### ICD-REF-001: source register

All console values in this ICD are leads until tied to a primary source (console
hardware documentation, original controller silicon datasheets, or a measurement).
The sources below are the secondary sources of those values; their revision and
retrieval dates were not recorded and must be recorded before a value is relied on.

| Ref | Source | Type | Revision / retrieved | Confidence |
|---|---|---|---|---|
| R1 | NESdev Wiki, Controller port pinout (nesdev.org/wiki/Controller_port_pinout) | Community wiki | not recorded | secondary |
| R2 | Super Famicom Development Wiki, Schematics, Ports, and Pinouts (wiki.superfamicom.org) | Community wiki | not recorded | secondary |
| R3 | AllPinouts, Sega Genesis joystick controller (allpinouts.org) | Pinout site | not recorded | secondary |
| R4 | ConsoleMods, Saturn connector pinouts (consolemods.org/wiki/Saturn:Connector_Pinouts) | Community wiki | not recorded | secondary |
| R5 | ConsoleMods, N64 connector pinouts (consolemods.org/wiki/N64:Connector_Pinouts) | Community wiki | not recorded | secondary |
| R6 | OpenCores, GameCube controller electrical interface (opencores.org/usercontent/doc/1250716915) | Community document | not recorded | secondary |
| R7 | Dreamcast Wiki, Maple bus (dreamcast.wiki/Maple_bus) | Community wiki | not recorded | secondary |
| R8 | AllPinouts, Sony PlayStation controller port (allpinouts.org) | Pinout site | not recorded | secondary |
| R9 | Microsoft, Original Xbox Hardware Design Specification 1.02 (copy on consolemods.org) | Vendor document, secondary copy | 1.02 | secondary (published, unverified copy) |
| R10 | XboxDevWiki, Xbox Input Devices (xboxdevwiki.net) | Community wiki | not recorded | secondary |

Confidence flags: published (primary, with revision), secondary (wiki or
third-party copy) and measured (on an original console, with the setup
recorded). Secondary-only values are unverified until measured.
