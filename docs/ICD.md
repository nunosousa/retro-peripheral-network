# Interface Control Document

| Control field | Value |
|---|---|
| Document ID | RPN-ICD |
| Revision | 0.2 |
| Status | Baseline for review |
| Date | 2026-11-27 |
| Companion documents | [RPN-SRS](SRS.md), [RPN-SAD](SAD.md), [RPN-PS](PS.md), [RPN-AFS](AFS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Interface boundaries, RS-485 profile and console electrical qualification entries. |
| 0.1 (2026-11-18) | Correction cycle: RP2350 platform text and datasheet/errata register; hub USB topology and hub baseline (ICD-HUB-001); isolated-bus and external-power default; profile-contract fields; console capability baseline (ICD-CAP) and verification entries (ICD-VER) added; source register (ICD-REF-001); clock/baud budget; installation figures. |
| 0.1 (2026-11-18) | UART rate raised to 2 Mbit/s and trunk length under 5 m: DMA requirement, transceiver/isolator rating, termination, baud-divider note, ICD-VER-020 criterion. |
| 0.1 (2026-11-18) | Memory-card accessory storage: ICD-STO-001 sizing baseline and resource rules, ICD-CON-001 persistent-data field, ICD-CAP-018. |
| 0.1 (2026-11-18) | Two-bank FRAM layout and a shared SPI bus: ICD-STO-001 devices-and-bus rule with the contention budget, section 8.3 GPIO table, ICD-VER-021. |
| 0.1 (2026-11-18) | Emulated memory-card contents in external FRAM: ICD-STO-001 rules rewritten, ICD-CAP-019, storage-device GPIO in section 8.3, ICD-VER-021. |
| 0.1 (2026-11-18) | Memory-card scope set to controller-port accessories (N64 Controller Pak, Dreamcast VMU); ICD-CAP-018 and the ICD-STO-001 table revised; the card-slot GPIO estimate withdrawn. |
| 0.1 (2026-11-24) | Player count raised from two to four: adapters emulate up to four ports; memory-accessory storage, GPIO tables and the shared-SPI wait recomputed for four ports; Original Xbox ICD-CAP-011 one USB device interface per emulated port; hub USB hub IC with four downstream ports; ICD-CAP-020 and ICD-VER-022 (multitap) added; ICD-VER-010, 014, 018, 019 and 021 extended to all ports. |
| 0.1 (2026-11-25) | Obsolete cross-references and legacy-source wording removed from the header and sections 8, 10 and 11; no requirement, value or pass criterion changed. |
| 0.2 (2026-11-27) | Specification baseline: bus at 8 Mbit/s with ISO3088-class isolated transceivers, 100 ohm termination and hub bias (ICD-NET-001); RJ45 daisy-chain harness with bus supply NET_PWR and pinout (ICD-NET-002); hub USB Type-C power and adapter power from the console (ICD-PWR-001/002); console annexes A to J (`ICD-CON-NES` to `ICD-CON-XBOX`) replace the profile supplements and sections 8.4 and 8.5; accessory FRAM with snapshot region and mirrored bank-select record, flash exception removed (ICD-STO-001); recovery and debug access (ICD-DBG-001); hub resource and power budget (ICD-HUB-001); ICD-CAP-017 withdrawn, ICD-CAP-021 to 024 added; ICD-VER-016 corrected and ICD-VER-023 to 031 added; platform and source registers populated with revisions and retrieval dates (ICD-PLAT-001, ICD-REF-001). |

Classification and normative language follow [RPN-SRS section 1](SRS.md#1-purpose-and-interpretation).
This ICD is the single electrical authority (`SAD-005`) and holds one annex per
console. Absence of a value is never permission to infer a safe value. Every
console value carries a confidence flag (`ICD-REF-001`): **published** (primary
document with revision), **secondary** (community or third-party source) or
**measured** (on an original console, with the setup recorded). A value flagged
secondary is a design input, not an approval to wire: the verification entry
named next to it shall establish the value by measurement before an adapter is
connected to original hardware (`ICD-QUAL-001`).

## 1. Interface inventory

```text
Modern devices --ICD-USB-001--> Hub --ICD-NET-001--> Adapter(s)
                                  shared bus          |
                                               ICD-CON-001
                                                     |
                                             Original console

USB-C charger ----------ICD-PWR-001--> hub power and bus supply NET_PWR
Console supply/sense ---ICD-PWR-002--> adapter console-side power domain
Adapter local persistent media -------ICD-STO-001
```

| Interface ID | Boundary | Authority |
|---|---|---|
| ICD-USB-001 | Input device to hub | USB host hardware, power and input-report acquisition; native host behind a hub IC (`SAD-020`), see `ICD-PWR-001` and `ICD-HUB-001` |
| ICD-NET-001 | Hub/adapter shared bus | RS-485 electrical profile at 8 Mbit/s; RPN-PS owns UART framing and transactions |
| ICD-NET-002 | Network harness and connector | RJ45 daisy chain, pinout, cable, bus supply and limits |
| ICD-PWR-001 | Hub power | USB Type-C input, hub budget, bus supply NET_PWR and downstream VBUS |
| ICD-PWR-002 | Adapter power and console sensing | Console-side power domain fed from the console, sensing and protection |
| ICD-CON-001 | Adapter to console ports | Console profile contract; one annex per console (`ICD-CON-NES` to `ICD-CON-XBOX`) |
| ICD-CAP-001..024 | Console electrical capability baseline | Common capabilities and sizing (section 8) |
| ICD-HUB-001 | Hub electrical baseline | Hub USB, power, bus, display, controls and resource budget (section 9) |
| ICD-VER-001..031 | Verification entries | Pass criteria for the capabilities and interfaces above (section 10) |
| ICD-PLAT-001, ICD-REF-001 | Platform and source registers | RP2350 datasheet/errata register and source register (section 11) |
| ICD-STO-001 | Adapter persistent storage | Accessory FRAM and node configuration store |
| ICD-DBG-001 | Local recovery/debug | SWD connector, recovery input and debug policy |

The logical unit is one adapter per console, supporting up to four simultaneously
routed ports (`SRS-SYS-009`): every native controller port of the console, or the
slots of the multitap that its annex emulates (`SRS-SYS-010`). One MCU need not
service every four-port combination; the resource tables decide, and some
profiles use the RP2350B (`SAD-018`). Adapter internals may contain multiple MCUs,
translators, connectors and isolated domains under one network endpoint
(`SAD-ADAPT-001`). Console and hub processors are RP2350 family parts
(`SRS-HW-005`).

## 2. ICD-NET-001: physical layer

| Property | Requirement |
|---|---|
| Signalling | Half-duplex, two-wire RS-485 differential signalling |
| UART | 8,000,000 bit/s (1.25 us per byte), 8 data bits, no parity, 1 stop bit; idle mark. Reception and transmission shall be DMA-driven; per-byte interrupt service is not acceptable on a node that also runs a console timing engine |
| Participants | One hub master, addressed adapters; no unsolicited adapter transmit (the only exception is the enumeration presence signal of `PS-DISCOVERY`) |
| Topology | Linear daisy chain through every node (`ICD-NET-002`); no passive star or ring |
| Termination | 100 ohm, matching the Cat5e cable impedance, at each physical trunk end: at the hub and at the last adapter, selected on the node by a switch; no other node terminates. Two terminations form a 50 ohm differential load |
| Bias | One idle-bias network at the hub only: 560 ohm from NET_P to NET_PWR and 560 ohm from NET_N to NET_REF, giving about 0.22 V idle differential voltage across the 50 ohm load at 5.2 V (0.218 V at the 2 % lower supply limit; about 4.4 mA). The transceiver's own open/short/idle fail-safe is an additional, not a replacement, measure |
| Transceiver | Isolated half-duplex RS-485 transceiver on the hub and every adapter (`SRS-HW-009`), ISO3088 class: signalling rate rated at least 20 Mbit/s; bus-side supply 4.5 to 5.5 V taken from NET_PWR; driver enable and disable time each at most 100 ns; driver and receiver pulse-width distortion each at most 15 ns; minimum driver transition time at least 5 ns; common-mode range at least -7 to +12 V; at most 1/8 unit load; receiver fail-safe high on open, short and idle bus; driver disabled by default when its enable input is unpowered or floating. TI ISO3088 (`ICD-REF-001` R40) meets these figures |
| Ground reference | The bus side of every transceiver is referenced to NET_REF and powered from NET_PWR (`ICD-NET-002`); no console ground and no hub logic ground is joined to NET_REF (`ICD-VER-030`) |
| Clock and baud error | Every node derives the baud rate from a crystal-derived clock of at most +/-100 ppm (`SRS-NET-010`); internal RC oscillators are not used for the bus. The UART is the RP2350 PL011 with UARTCLK = clk_peri = 150 MHz: the divisor 150 MHz / (16 x 8 Mbit/s) = 1.171875 = 1 + 11/64 is exactly representable in its 1/64 fractional divider, so the divider error is zero and the total error is the crystal's, far inside the +/-0.5 % budget. The sampling margin with transceiver and isolator distortion (at most 30 ns of a 125 ns bit) is measured by `ICD-VER-017` |
| Cable length, stub length, node loading | Trunk shorter than 5 m in total with up to 10 adapters (`SRS-SYS-008`); stubs per `ICD-NET-002`; eleven 1/8-unit-load transceivers are far below the 32-unit-load limit |
| ESD | IEC 61000-4-2 level 3 at the bus connector (`ICD-CAP-008`, `ICD-VER-012`) |

The 31-address profile is a protocol limit. The installation limit is the one of
`SRS-SYS-008`.

Signal names are `NET_P`, `NET_N`, `NET_PWR` and `NET_REF` in RPN schematics.
Because vendor A/B naming varies, the schematic maps each part explicitly:
`NET_P` is the line positive relative to `NET_N` for a received UART mark (logic
1). The convention is confirmed with a known test pattern (`ICD-VER-017`) rather
than inferred from connector labels.

Every transmitter shall be disabled during reset, boot, unpowered MCU conditions,
recovery and watchdog recovery. GPIO pull states alone are insufficient without
checking transceiver power sequencing (and the MCU's own internal pulls are not
relied on, `SRS-HW-006`). Isolator propagation delay and driver enable/disable
delay shall fit the margins of `PS-TIMING` (`ICD-VER-020`). UART/DMA completion
shall mean the last stop bit has left the pin before driver disable; FIFO empty
alone is not sufficient. A node shall not transmit to report an asynchronous
fault; it queues diagnostics for the next addressed poll.

## 3. ICD-NET-002: harness and connector

Every node has two shielded RJ45 (8P8C) receptacles wired straight through inside
the node, so trunk continuity does not depend on node power; the hub has one and
sits at one trunk end. Unplugging a cable divides the trunk; this is the
documented limit of the daisy chain, and cables are connected and disconnected
only with every node and the hub powered off (`SRS-ENV-004`).

| RJ45 pin | Signal | Function |
|---|---|---|
| 1 | NET_P | Differential pair, positive (pair with pin 2) |
| 2 | NET_N | Differential pair, negative |
| 3 | - | Not connected inside any node |
| 4, 5 | NET_PWR | Bus-side supply, 5.2 V from the hub; both conductors of the pair in parallel |
| 6 | - | Not connected inside any node |
| 7, 8 | NET_REF | Bus-side supply return and signal reference; both conductors of the pair in parallel |
| Shell | Shield | Cable shield |

| Property | Requirement |
|---|---|
| Cable | Shielded Cat5e or better twisted-pair patch cable, 100 ohm +/-15 % (`ICD-REF-001` R44), 24 AWG or heavier |
| Stub | The track from the through-wired pair to the transceiver pins shall not exceed 50 mm: at about 0.2 m/ns its round trip is 0.5 ns, under one tenth of the transceiver's minimum 5 ns transition time (`ICD-NET-001`) |
| NET_PWR | Generated by the hub from its USB-C input through an isolated converter (`ICD-PWR-001`): 5.2 V +/-2 % at the hub connector, current-limited at 450 mA and short-circuit protected. Load: eleven transceiver bus sides at most 20 mA each idle plus one active driver at most 70 mA, plus the 4.4 mA bias: 294 mA (65 % of the limit). With the whole 450 mA at the far end of a 5 m trunk, the loop resistance (two 24 AWG conductors per rail, 0.095 ohm/m each, plus 0.2 ohm for connectors) is 0.675 ohm and the drop 0.30 V, leaving at least 4.79 V, inside the 4.5 to 5.5 V transceiver range (`ICD-VER-024`) |
| NET_REF | Bus-side return only; never connected to a console ground, an adapter console-side ground or the hub logic ground (`ICD-VER-030`) |
| Common-mode offset | All bus sides share NET_REF, so the common-mode voltage at every receiver stays within the transceiver's -7 to +12 V range; a part with a narrower range shall not be used |
| Shield | Bonded to the hub enclosure ground only; at each adapter coupled to its enclosure through a capacitor (10 nF, rated at least 100 V) with no DC path |
| Overvoltage | Every RJ45 pin of every node withstands 57 V DC applied between any two pins without damage, so an accidental connection to Ethernet or Power over Ethernet equipment (at most 57 V, `ICD-REF-001` R45) is survived (`ICD-VER-027`); the receptacles carry a label "RPN bus - not Ethernet" |
| ESD | Transient-voltage suppression on NET_P, NET_N and NET_PWR at every receptacle, rated for IEC 61000-4-2 level 3 (`ICD-VER-012`) |
| Termination | Selected only at the trunk ends (`ICD-NET-001`) |
| Unpowered nodes | An unpowered adapter neither clamps nor drives the bus; its transceiver bus side stays powered from NET_PWR with its driver disabled |

## 4. Power, grounding and console attachment

### ICD-PWR-001: hub power

The hub is powered through a USB Type-C receptacle as a 5 V sink without USB Power
Delivery (`SRS-HW-007`, `ICD-REF-001` R47). It presents Rd = 5.1 kohm +/-10 % on
each CC pin, reads the source's current advertisement from the CC voltage and
draws up to 3.0 A only while the 3.0 A advertisement is present; it re-reads CC
continuously and reduces its load within 60 ms when the advertisement drops.

| Load (worst case, 5 V input) | Current |
|---|---:|
| Four downstream VBUS ports at 500 mA | 2.00 A |
| MCU, USB hub IC, configuration store and controls | 0.15 A |
| Colour display with backlight | 0.15 A |
| NET_PWR converter input (450 mA at 5.2 V, 75 % efficiency) | 0.62 A |
| **Total** | **2.92 A** |

The worst case stays within the 3.0 A advertisement. With a 1.5 A advertisement
the hub powers at most one downstream port (0.58 A remains for VBUS) and shows a
supply warning; with the default USB advertisement it powers no downstream port and
keeps the bus unpowered. USB host VBUS is switched and current-limited per port,
with overcurrent detection and no reverse feed into the USB-C input. Host-port count
is not the same as USB device count: hubs, device speeds and report rates are
qualified by `ICD-VER-018`. A USB device that needs more than 500 mA, such as a
force-feedback wheel, uses its own supply.

The RP2350 has one native full-speed USB 1.1 controller (`ICD-PLAT-001`). The hub
uses it as the USB host behind a **USB hub IC** with four downstream ports
(`SAD-020`); a software (PIO) USB host is not used. The hub resource budget is in
`ICD-HUB-001`.

### ICD-PWR-002: adapter power and console sensing

Each adapter has two power domains separated by its isolated transceiver: the
**bus side**, powered from NET_PWR (`ICD-NET-002`), and the **console side**
(MCU, translators, storage, display), powered from the one console it serves
(`SRS-HW-008`):

1. **Controller-port supply**, where the console annex shows that the console-side
   load fits within 70 % of what the port can supply. The adapter draws from the
   supply pin of one designated connector (named by the annex), through a
   reverse-current blocking element, so it never feeds back into the console.
2. **Pass-through input** otherwise: a connector between the console's external
   power source and the console, from which the adapter takes its supply upstream
   of the console's power switch. Its input stage is rated for the source voltage
   and type stated in the annex; reverse-polarity protection is fitted where the
   connector is not polarity-keyed (`ICD-VER-026`).

Console-side load allocation, at 3.3 V: MCU 60 mA, display 20 mA, accessory FRAMs
20 mA, configuration store 1 mA, transceiver logic side 10 mA, translators 10 mA,
LEDs 10 mA: at most 131 mA (an annex with several processors adds them).

Rules for every adapter:

- Console rails are never connected to each other, never to NET_PWR or NET_REF and
  never to a second console (`ICD-CAP-012`).
- The console-side ground is the console's ground; the transceiver isolation keeps
  it apart from the bus (`ICD-VER-030`).
- Console power is sensed by a protected, high-impedance input on the supply pin of
  a controller connector (one per console supply), so the adapter reports activity
  by the rule of `SRS-OWN-014`.
- With a pass-through input the adapter can be powered while its console is off;
  every console-facing output is then high-impedance (`ICD-CAP-006`, `ICD-CAP-007`).

Before a console connector is attached, the annex establishes:

1. Normal and worst-case voltage/current for every power and signal pin.
2. Ground/reference and isolation boundaries, including multiple powered consoles.
3. Prevention of back-power through I/O protection diodes, translators, USB or bus.
4. Safe power-up/down ordering and output-high-impedance state.
5. Short-circuit, reverse connection and connection-sequence behaviour.
6. The activity detector of `SRS-OWN-014`.

RS-485 common-mode tolerance is not galvanic isolation. Multiple grounded consoles
can form loops through video equipment; the isolated transceiver at every node
keeps the bus out of such loops. Isolation is verified by `ICD-VER-030`; isolation
delays fit `PS-TIMING` (`ICD-VER-020`).

## 5. ICD-CON-001: console profile contract

Each console profile is specified by one annex of this document (Annex A to J).
Every annex contains the following fields:

| Annex field | Content |
|---|---|
| Identity | Console family, hardware and regional variants covered (`SRS-SYS-012`), and the virtual peripherals presented (`SRS-SYS-011`) |
| Connectors | Mating connector, pin numbering and wiring of every emulated port, shields |
| Port mapping | Mapping from PS `port` IDs 0 to 3 to physical connectors or multitap slots, the multitap model, its protocol limits and slot-to-port mapping (`SRS-SYS-010`) |
| Electrical | Per signal: direction, level, drive type, who supplies each pull-up and the translator or protection approach; the adapter adds no pull-up on a line the console already pulls up (`ICD-CAP-010`) |
| Connector module | Hardware module ID, voltage domain and drive type of the module (`ICD-CAP-004`) |
| Power | Console-side supply source (`ICD-PWR-002`), sensing and partial-power cases |
| Timing | Console request/response limits, jitter budget, pulse and clock tolerances, reset and detection behaviour |
| Dynamics | Signalling rate, levels, rise/fall and delay limits (`ICD-CAP-015`) |
| Idle identity | Default peripheral identity presented while inhibited or configured and on every port without an active device (`SRS-IN-014`), what a multitap presents for such a slot, and whether a live peripheral change is allowed (`SRS-IN-011`) |
| Neutralisation | `neutralisation_bound_us` and the transaction span it covers (`SRS-OWN-013`, `ICD-VER-016`) |
| Resources | PIO state machines, DMA channels and RP2350 variant; GPIO per section 8.3. Margin rule: no more than 70 % of any resource in the worst all-port combination (`ICD-CAP-014`) |
| Peripheral behaviour | Identification and report format of every presented peripheral, feedback and accessories |
| Persistent data | Memory accessory, if any (`ICD-STO-001`, `SRS-STO-005..012`) |
| Verification | Console-specific measurements that establish every secondary-flagged value, in addition to the common `ICD-VER` entries |

Adapters emulate the console interface; they never forward a modern controller's
wires. Each annex presents one virtual peripheral per port, plus the memory
accessory and the sub-peripherals its annex declares (`SAD-042`).

## 6. ICD-STO-001 and ICD-DBG-001

### Memory accessory storage (SRS-STO-005..012)

Memory accessory storage exists for the accessories reached through the controller
port (N64 Controller Pak, Dreamcast VMU memory) and is the adapter's responsibility:
it holds the authoritative data and the console never waits on the network
(`SAD-003`). The adapter provides one accessory per emulated port, up to four.

| Console | Accessory | Attached via | Capacity per accessory | FRAM per port | Source |
|---|---|---|---:|---|---|
| N64 | Controller Pak (32 KiB, 32-byte blocks) | Controller data line, accessory read/write commands | 32 KiB | 1 Mbit | Annex E; R24, R25 (secondary) |
| Dreamcast | VMU memory (256 blocks of 512 bytes, 200 user blocks) | Maple bus, expansion slot 1 of the controller | 128 KiB | 4 Mbit | Annex G; R32 (published) |

Storage device (`SRS-STO-008`, `SRS-STO-011`). The accessory image is held in
external SPI FRAM, outside the MCU. FRAM needs no erase and no wear levelling,
never blocks execute-in-place reads and keeps the data across a power loss without
a flush policy. The part is specified by requirement: SPI or QSPI, 3.3 V,
endurance at least 10^12 cycles, SPI clock rating at least 40 MHz, operating range
covering 5 to 40 degC (`SRS-ENV-002`). Parts meeting it exist at both densities
(`ICD-REF-001` R48, R49).

- **Layout.** Each FRAM holds bank A, bank B, a snapshot region S (each of the
  accessory's capacity) and a bank-select record written as two mirrored copies,
  each with a sequence number and a CRC-32C (N64: 96 KiB of 128 KiB used; Dreamcast:
  384 KiB of 512 KiB). A network replacement (`SRS-STO-004`) is written and
  verified in the idle bank, then the next record copy is written with the next
  sequence number; at start-up the valid copy with the highest sequence selects the
  active bank, so a power loss leaves the old or the new bank, never a mix. A live
  snapshot (`SRS-STO-010`) is built in region S. Accessory identity and format flags
  live in the node configuration store, not in the image.
- **Devices and bus.** One FRAM per emulated port (up to four) on one shared SPI bus
  with its own chip select each: 7 GPIO (SCK, MOSI, MISO, four CS; `ICD-CAP-019`).
  One SPI controller with DMA serves all devices at 37.5 MHz (150 MHz / 4; the
  RP2350 SPI needs an even prescaler of at least 2 and 75 MHz exceeds the FRAM
  rating). Accesses are serialised; the arbiter runs from interrupt or DMA context,
  never from the network task, and no port's accesses may be starved.
- **Access time.** A 32-byte block (36 bytes with command and address) takes 7.68 us;
  a 512-byte block (516 bytes) 110.1 us; a 128-byte block 28.2 us. The worst-case
  wait includes one transfer of each other port, one snapshot-copy chunk and one network
  transfer piece (network reads and writes are split into pieces of one console block:
  32 bytes N64, 128 bytes Dreamcast): N64 46.1 us (six 32-byte transfers), inside the
  N64 accessory reply window of Annex E; Dreamcast 496.7 us (four 512-byte reads plus
  two 128-byte transfers), inside the storage reply limit of Annex G. A write-through RAM cache or prefetch
  may be used as a latency device only, never as the authoritative copy
  (`ICD-VER-021`).
- **Writes and power fail.** A console block write is acknowledged to the console
  only after the FRAM write has completed (write-through), so accessory data is
  never dirty and `dirty_resources` stays zero. A write interrupted by power loss
  can tear that one block; the annex states how the console's own checksums absorb
  it, and a power-loss detector with a small hold-up lets an in-flight block finish
  and blocks new writes.
- **Snapshot.** A live snapshot starts once the console's storage interface has been
  idle for the annex's quiet time, then copies the active bank into region S in chunks
  of one console block (32 bytes N64, 128 bytes Dreamcast) at the lowest SPI priority:
  15.7 ms (N64) or 57.7 ms (Dreamcast) of SPI time including command and address bytes.
  A console write during the copy aborts it and the copy restarts after the next quiet
  time; a snapshot not complete within 2 s of OPEN_READ fails with BUSY
  (`PS-SVC-STORAGE`). Region S is frozen from completion until the token is closed, so
  the exported image is the accessory at one idle instant.
- **Endurance.** The profile states the figure against its worst-case write rate;
  the reference rate of one write per millisecond to the same block for ten years is
  3.16 x 10^11 cycles, inside the 10^12 requirement.
- **Transfer time.** At 8 Mbit/s a maintenance WRITE exchange takes 0.446 ms and a
  READ exchange 0.449 ms (`PS-TIMING`): 32 KiB in 180 chunks takes 80 ms and 128 KiB
  in 717 chunks 320 ms per accessory (four: 0.32 s and 1.28 s). A live export at one
  chunk every 4 ms takes 0.72 s and 2.87 s per accessory. Verifying a staged 128 KiB
  image over SPI takes 28 ms.
- **Presence and identity.** The annex states what the console sees when the
  accessory is absent, being maintained or after a failed commit (`PS-MAINTENANCE`),
  and the accessory identity it presents.
- **Interface.** The accessory is reached through the controller connector and adds
  no console channels (`ICD-CAP-018`).

### Node configuration store (SRS-CFG-003)

Every node has a configuration store on its I2C bus, shared with the adapter display
(`ICD-CAP-021`, `ICD-CAP-022`): an I2C FRAM or EEPROM written without stalling
program execution. It holds two copies of each record (address record, configuration
blob up to 4096 bytes, user options, accessory identities), each with a sequence
number and a CRC-32C; a write alternates copies so a power loss leaves the previous
valid copy. Capacity at least 16 KiB on an adapter and at least 32 KiB on the hub
(roster, assignments, approvals, remappings and calibrations: about 9 KiB, doubled).
An EEPROM page write completes within 10 ms, inside the ASSIGN completion window of
`PS-DISCOVERY`.

### ICD-DBG-001: recovery and debug access

Every node (each processor of a multi-processor adapter) provides:

- a three-pin SWD connector (SWDIO, SWCLK, GND) on a 2.54 mm header or a Tag-Connect
  footprint, reaching the RP2350's dedicated SWD pins; debug stays enabled in
  production: no debug lock and no secure boot (`SRS-HW-010`);
- a **recovery input** (push button to ground with an external pull-up). Held while
  power is applied (the boot stage samples it only on a power-on reset, never on a
  software or watchdog reset), it makes the boot stage start the application in
  RECOVERY: no
  console-facing output and no console driver is enabled; on the bus the node answers
  only HELLO, STATUS, DIAGNOSTICS and RESET (`PS-MAINTENANCE`). An image that is
  unusable is restored over SWD with a debug probe. The same input, asserted while an
  ACTIVATE or a RESET mode 1 request arrives, is the physical update and recovery
  enable (`PS-SVC-UPDATE`); RESET mode 1 reaches RECOVERY through a boot flag, and the
  reset after ACTIVATE starts the trial image whatever the input level.

Debug never bypasses electrical safety or energises an unpowered console.
Recoverability is verified by `ICD-VER-023`.

## 7. ICD-QUAL-001: evidence of conformance

An adapter, hub or harness conforms when the following evidence exists:

| Item | Evidence | Related requirements |
|---|---|---|
| Bus components | Datasheets against `ICD-NET-001`, loading and bias calculation, oscilloscope eye, edge and mark/space polarity (`ICD-VER-017`, `ICD-VER-020`, `ICD-VER-031`) | SRS-NET-003, SRS-HW-003 |
| Harness | Connector, pinout and cable per `ICD-NET-002`; bus supply, overvoltage and isolation tests (`ICD-VER-024`, `ICD-VER-027`, `ICD-VER-030`) | SRS-NET-013, SRS-ENV-004 |
| Power | Hub and adapter budgets, USB Type-C behaviour, backfeed tests (`ICD-VER-011`, `ICD-VER-025`, `ICD-VER-026`) | SRS-HW-002..004, SRS-HW-007..008 |
| Console annex | Every secondary-flagged value of the annex established by measurement and recorded as measured; all-port traces; safe idle and power transitions | SRS-SYS-005, SRS-PERF-003 |
| Timing and resources | Console load plus full bus, USB and storage activity, watchdog injection; resource table within the 70 % margin | SRS-IN-009, SRS-HW-004, SRS-PERF-006 |
| Platform | `ICD-PLAT-001` errata mitigations applied; no console-facing signal relying on MCU 5 V tolerance or internal pulls | SRS-HW-005, SRS-HW-006 |
| Capability verification | `ICD-VER-001..031` executed with their pass criteria | SRS-HW-002..010, SRS-OWN-013 |
| Hub | `ICD-HUB-001` budget confirmed by `ICD-VER-018`, `ICD-VER-019` and `ICD-VER-025` | SRS-HW-004, SRS-UI-001 |

## 8. ICD-CAP: console electrical capability baseline

This section states the capabilities common to every console annex and the GPIO
sizing of every adapter. Per-console pins, levels and timing are specified in the
annexes, which may narrow but not exceed this baseline.

### 8.1 Capabilities

| ID | Class | Capability |
|---|---|---|
| ICD-CAP-001 | D | Authority and precedence: this section for common capabilities and GPIO sizing, the console annexes for per-console facts; one source per fact. Verified by inspection of this document (`ICD-QUAL-001`). |
| ICD-CAP-002 | F | RPN internal digital logic is a 3.3 V domain (RP2350 IOVDD 3.3 V, `ICD-PLAT-001`). Console voltage adaptation happens at the console-facing boundary only. |
| ICD-CAP-003 | D | Console-facing signals reach MCU GPIO only through external translation and protection. No console-facing signal relies on MCU-side 5 V tolerance (the RP2350 tolerates 5.5 V only on fault-tolerant pins and only while IOVDD is powered) or on internal pull-up/pull-down resistors (`SRS-HW-006`). |
| ICD-CAP-004 | D | The voltage domain and drive type of a console channel are a hardware-defined property of the console connector module, readable by firmware (module ID strap). Firmware refuses a profile that does not match the module. High-impedance is the only state reachable without a valid module/profile match, and runtime-selectable 5 V push-pull is not provided on 3.3 V-class or open-drain lines. |
| ICD-CAP-005 | D | Across the set of modules the platform provides: input, push-pull output at the module's domain, open-drain output, high-impedance, independent direction control, half-duplex operation, prevention of contention and deterministic direction switching. A single module need not do everything. |
| ICD-CAP-006 | D | All console-facing drivers are high-impedance during reset, initialisation, recovery, watchdog recovery and when the MCU is unpowered. |
| ICD-CAP-007 | D | No path back-powers a console, the adapter or the bus when either side is unpowered; unpowered MCU with powered console and powered MCU with unpowered console are both verified (`ICD-VER-011`, `ICD-VER-015`). |
| ICD-CAP-008 | F | Every externally accessible connector (console, USB, bus and power) has ESD protection to IEC 61000-4-2 level 3 (6 kV contact, 8 kV air), and every console-facing signal has short-circuit, overvoltage and current-injection protection that does not compromise the console's timing or levels (`ICD-VER-012`). |
| ICD-CAP-009 | F | Auto-direction level translators are not used on open-drain bidirectional lines; direction-controlled or discrete open-drain structures are used. |
| ICD-CAP-010 | D | Each annex names who supplies every pull-up (console or controller side) and its value; the adapter adds no pull-up on a line that the console already pulls up, and provides the pull-ups that the original controller provides. |
| ICD-CAP-011 | F | The Original Xbox adapter provides one USB 1.1 full-speed device interface per emulated port (four), each on its own processor, with USB signal protection (`SAD-019`). A transceiver shared between physical ports is not sufficient. |
| ICD-CAP-012 | D | Console power rails are never connected to each other, to NET_PWR, to NET_REF or to another console; a console rail feeds only the adapter's console-side regulator input, through a reverse-current blocking element (`ICD-PWR-002`). The adapter drives no console motor and draws no current from a console motor rail. |
| ICD-CAP-013 | D | Console channel quantities in section 8.2 are those needed for every peripheral and multitap the annex presents. |
| ICD-CAP-014 | D | Adapter system I/O (section 8.3) is counted with the console channels in every adapter's GPIO budget on its RP2350 variant, under the 70 % margin rule. |
| ICD-CAP-015 | D | Every annex gives the signalling rate, levels, rise/fall and delay limits of its channels; no translator or protection part is selected without them. |
| ICD-CAP-016 | D | Connector power characteristics are given per annex with their confidence flag; a secondary-flagged supply value is established by `ICD-VER-026` before the adapter draws power from it. |
| ICD-CAP-018 | D | A memory accessory (`ICD-STO-001`, `SRS-STO-005`) is reached through the controller port, sharing its signals (N64 Controller Pak, Dreamcast VMU), and adds no channels to the baseline. |
| ICD-CAP-019 | F | Emulated memory accessory contents are held in external FRAM (`SRS-STO-008`, `ICD-STO-001`). Its SPI signals, 3.3 V supply and decoupling are part of the adapter and are counted in the GPIO budget (section 8.3). The device is never reachable from a console-facing signal. |
| ICD-CAP-020 | F | A multitap (`SRS-SYS-010`) is presented through the console's own connectors. The channels its protocol needs beyond the native port are counted in section 8.2: the SNES Super Multitap adds Data2 and IOBit on its port; the Sega Team Player turns TR into a direction-controlled channel; the PlayStation 2 multitap adds a connection to the console's memory-card slot of its port; the Saturn and PlayStation multitaps add none. A slot without an active device follows `SRS-IN-014`. |
| ICD-CAP-021 | F | Every adapter has a monochrome graphic display of at least 128 x 64 pixels on its I2C bus (Fast-mode Plus, 1 MHz), able to show four 48 x 32 VMU screens as a 2 x 2 grid on the Dreamcast adapter; display transfers never delay a console transaction (`ICD-VER-028`). |
| ICD-CAP-022 | F | Every node has a node configuration store on its I2C bus (`ICD-STO-001`, `SRS-CFG-003`). |
| ICD-CAP-023 | D | GPIO per console channel: an input, an output or an open-drain output uses one GPIO; a bidirectional open-drain line uses two (drive and sense); a direction-controlled group uses one GPIO per line plus one direction GPIO per group. |
| ICD-CAP-024 | D | Two status LEDs per adapter: one shows the node state (off: unpowered or unassigned; slow blink: inhibited; on: armed); the other is off without fault and otherwise blinks the STATUS fault value 1 to 6 as that many pulses. |

### 8.2 Console channel sizing (emulated ports)

Direction is relative to the adapter. Pins, levels and confidence flags are in the
annexes. GPIO per channel follows `ICD-CAP-023`.

| Console | Native ports | Channels per native port | Multitap or extra channels | Console channels | Console GPIO |
|---|---:|---|---|---:|---:|
| NES | 2 | Clock in, Latch in, Data out (3) | none | 6 | 6 |
| SNES | 2 | Clock in, Latch in, Data1 out (3) | Super Multitap on port 2: Data2 out, IOBit in (2) | 8 | 8 |
| Mega Drive | 2 | Up, Down, Left, Right, TL, TR out; TH in (7) | Team Player on port 1: TR direction-controlled (one direction GPIO) | 14 | 15 |
| Saturn | 2 | D0..D3, TL out; TH, TR in (7) | none | 14 | 14 |
| Nintendo 64 | 4 | Data, bidirectional open-drain (1) | none | 4 | 8 |
| GameCube | 4 | Data, bidirectional open-drain (1) | none | 4 | 8 |
| Dreamcast | 4 | SDCKA, SDCKB direction-controlled; presence/sense channel (3) | none | 12 | 16 |
| PlayStation | 2 | CMD, ATT, CLK in; DATA, ACK open-drain out (5) | none | 10 | 10 |
| PlayStation 2 | 2 | As PlayStation (5) | multitap on port 1: memory-card slot CMD, ATT, CLK in; DATA, ACK open-drain out (5) | 15 | 15 |
| Original Xbox | 4 | One USB full-speed device interface | none | 4 USB | 0 |

The Dreamcast presence/sense channel is a sizing allowance of one input per port;
Annex G states its use.

### 8.3 Adapter system I/O and GPIO budget

| Function | GPIO | Note |
|---|---:|---|
| Bus UART TX, RX and RS-485 driver enable | 3 | Through the isolated transceiver |
| Console power sense | 1 | One per console supply (`ICD-PWR-002`) |
| Physical commissioning enable | 1 | `PS-DISCOVERY` |
| Recovery input | 1 | `ICD-DBG-001` |
| Status LEDs | 2 | `ICD-CAP-024` |
| I2C (adapter display and configuration store) | 2 | `ICD-CAP-021`, `ICD-CAP-022` |
| **System I/O total** | **10** | |
| Accessory FRAM bus (N64, Dreamcast only) | 7 | SCK, MOSI, MISO, four CS (`ICD-CAP-019`) |

| Console | Console GPIO | System I/O | FRAM bus | Total GPIO | Part | Share | Within 70 % |
|---|---:|---:|---:|---:|---|---:|---|
| NES | 6 | 10 | - | 16 | RP2350A (30) | 53 % | Yes |
| SNES | 8 | 10 | - | 18 | RP2350A (30) | 60 % | Yes |
| GameCube | 8 | 10 | - | 18 | RP2350A (30) | 60 % | Yes |
| PlayStation | 10 | 10 | - | 20 | RP2350A (30) | 67 % | Yes |
| Saturn | 14 | 10 | - | 24 | RP2350B (48) | 50 % | Yes |
| Mega Drive | 15 | 10 | - | 25 | RP2350B (48) | 52 % | Yes |
| Nintendo 64 | 8 | 10 | 7 | 25 | RP2350B (48) | 52 % | Yes |
| PlayStation 2 | 15 | 10 | - | 25 | RP2350B (48) | 52 % | Yes |
| Dreamcast | 16 | 10 | 7 | 33 | RP2350B (48) | 69 % | Yes |

Saturn, Mega Drive, Nintendo 64, PlayStation 2 and Dreamcast would exceed 21 GPIO (70 % of 30)
on the RP2350A, so they use the RP2350B (`SAD-018`). Module ID straps
(`ICD-CAP-004`) are read through the I2C configuration store's address straps and
need no GPIO. The Original Xbox processors have no digital console channels: each USB
processor uses its USB pins, the internal link (Annex J) and the system I/O that
Annex J assigns to it.

## 9. ICD-HUB-001: hub electrical baseline

| Item | Requirement |
|---|---|
| Processor | One RP2350A (`SRS-HW-005`), stacked-flash variant RP2354A preferred (`SAD-018`); clk_sys 150 MHz, which also satisfies the erratum E12 rule (`ICD-PLAT-001`) |
| USB host | Native full-speed controller behind a USB hub IC with four downstream ports; per-port switched VBUS with 500 mA current limit and overcurrent detection; up to four HID devices (an interrupt IN endpoint each, plus an interrupt OUT endpoint where a device takes output reports) and the hub IC's status endpoint, at most 9 of the host controller's 15 hardware-polled interrupt endpoints; a USB flash drive (bulk endpoints) on any free downstream port: for every operation while no owner is armed, and for live export also while an owner is armed, at the lowest USB priority (`SRS-CFG-004`) |
| Power input | USB Type-C sink per `ICD-PWR-001` |
| Bus | Isolated transceiver per `ICD-NET-001`, bus side on NET_PWR; termination always fitted (the hub is a trunk end); bias network; NET_PWR source per `ICD-NET-002` |
| Display | Colour graphic LCD of at least 320 x 240 pixels on SPI (SCK, MOSI, CS, DC), 16-bit colour, drawn from line buffers (two 320 x 16 pixel buffers, 20 KiB) at 37.5 MHz SPI; a full frame takes about 33 ms |
| Controls | Four buttons (up, down, select, back) and the recovery button (`ICD-DBG-001`); no indicator LEDs: all indication is on the display (`SRS-UI-001`) |
| Configuration store | I2C FRAM or EEPROM, at least 32 KiB (`ICD-STO-001`) |
| Protection | ESD at level 3 on USB, bus and USB-C connectors (`ICD-CAP-008`); overcurrent protection on the USB-C input; the USB-C connector is polarity-keyed, so no reverse-polarity element is needed |

Hub resource budget (RP2350A; 70 % margin rule):

| Resource | Use | Used / available | Share |
|---|---|---:|---:|
| GPIO | Bus UART TX, RX, DE (3); LCD SCK, MOSI, CS, DC (4); four buttons (4); recovery (1); I2C SDA, SCL (2); USB hub IC reset (1); NET_PWR enable and fault (2); CC1 and CC2 sense on two ADC-capable pins (2) | 19 / 30 | 63 % |
| PIO state machines | none | 0 / 12 | 0 % |
| DMA channels | UART RX and TX (2), LCD SPI TX (1), I2C (2) | 5 / 16 | 31 % |
| USB controller | Host | 1 / 1 | (sole function) |
| Interrupt endpoints | Four devices, IN and OUT, plus hub status | 9 / 15 | 60 % |
| SRAM | USB host stack and HID parsers 64 KiB, display line buffers 20 KiB, FAT filesystem and file buffers 16 KiB, bus buffers 4 KiB, configuration and UI state 32 KiB | 136 / 520 KiB | 26 % |

## 10. ICD-VER: verification entries

Each entry verifies the listed capabilities. "Annex" means the console annex of the
adapter under test.

| ID | Verifies | Activity | Pass criterion |
|---|---|---|---|
| ICD-VER-001 | ICD-CAP-002, 003, 004 | 3.3 V-class input compatibility | At the annex's minimum and maximum rail, every received level is read correctly and the pad voltage never exceeds the RP2350 absolute maximum in `ICD-PLAT-001` |
| ICD-VER-002 | ICD-CAP-003, 004 | 5 V-class input compatibility through the translator | As 001 with the 5 V module; measured pad voltage within the datasheet limit |
| ICD-VER-003 | ICD-CAP-005 | 3.3 V push-pull output levels | VOH/VOL meet the annex's console VIH/VIL with a 0.3 V noise margin, or the annex's tighter margin |
| ICD-VER-004 | ICD-CAP-005 | 5 V push-pull output levels | As 003 on a 5 V module |
| ICD-VER-005 | ICD-CAP-005, 009, 010 | Open-drain operation | VOL and rise time meet the annex; no adapter pull-up on a console-pulled line |
| ICD-VER-006 | ICD-CAP-006 | High-impedance state | Leakage into and out of the console line, and change of the console-observed level, within the annex limit when the driver is high-impedance |
| ICD-VER-007 | ICD-CAP-005 | Independent channel direction control | Each channel's direction changes without a glitch on any other channel above the annex limit |
| ICD-VER-008 | ICD-CAP-005, 009, 015 | Bidirectional operation | Turnaround within the annex's delay budget at the nominal signalling rate |
| ICD-VER-009 | ICD-CAP-005 | Absence of contention | No interval in which adapter and console both drive a line (current and waveform capture) |
| ICD-VER-010 | ICD-CAP-011 | USB full-speed operation on every emulated Xbox port | All four emulated ports enumerate and carry reports simultaneously for 10 minutes without error |
| ICD-VER-011 | ICD-CAP-007, 012 | Power sequencing and back-power prevention | Current into any unpowered side below 100 uA in every partial-power order (console, adapter console side, NET_PWR) |
| ICD-VER-012 | ICD-CAP-008 | ESD | IEC 61000-4-2 level 3 (6 kV contact, 8 kV air) on every externally accessible connector without damage or latch-up, and console timing unchanged after the test |
| ICD-VER-013 | ICD-CAP-012 | Console supply draw limiting | The adapter's draw from a console rail stays within the annex limit and a short on the adapter side does not take the console rail out of its range |
| ICD-VER-014 | ICD-CAP-013, 014, 023 | Operation under simultaneous port activity | All emulated ports and the bus active at maximum load meet the annex's timing and the 70 % resource margin |
| ICD-VER-015 | ICD-CAP-006, 007 | Unpowered MCU with powered console | Each channel stays high-impedance and no console-observed level change beyond the annex limit, on RP2350 stepping A4 (`ICD-PLAT-001`) |
| ICD-VER-016 | SRS-OWN-013 | Neutralisation visible at the console | Measured from the adapter's internal inhibit instant to neutral state at the console connector, for both the REVOKE path and the lease-expiry path, including an in-flight transaction: at most the declared `neutralisation_bound_us` and at most 1 ms |
| ICD-VER-017 | SRS-NET-010, ICD-NET-001 | Baud error, polarity and sampling margin | Measured per-node baud error within +/-0.5 %; NET_P/NET_N polarity confirmed with a known pattern; sampling margin positive with isolator and transceiver distortion; no framing errors in 10 minutes at full cadence |
| ICD-VER-018 | ICD-USB-001, SAD-020 | Hub four-device acceptance | Four HID devices, at least one low-speed and one full-speed, enumerate through the hub IC, report at their descriptor intervals for 10 minutes with no missed report (no sequence gap over twice the interval) and no enumeration loss when a device is connected or removed; unplugging and reconnecting one device does not disturb the reports of the others |
| ICD-VER-019 | ICD-HUB-001 | Hub VBUS limiting | Each downstream port limits and reports overcurrent at 500 mA and recovers without disturbing the other ports |
| ICD-VER-020 | ICD-NET-001, PS-TIMING | Isolated bus delays at 8 Mbit/s | Isolator propagation plus driver enable/disable delay fit the 10 us disable allowance and the 20 us earliest-response gap with margin, and pulse-width distortion leaves a positive sampling margin on a 125 ns bit |
| ICD-VER-021 | ICD-CAP-018, 019, ICD-STO-001 | Memory accessory per port | The console formats, saves, loads and copies an accessory of the declared capacity from all emulated ports at the same time; an inactive console reads its own accessory; every FRAM read and write meets the console's response limit at the worst-case wait including a snapshot copy; power removed during a block write and during a bank-select write leaves a valid old or new image (a torn block is absorbed as the annex states); the endurance figure and transfer times meet the resource table |
| ICD-VER-022 | ICD-CAP-020, SRS-SYS-010 | Multitap emulation | With the annex's tap model, the console detects the tap, reads every slot independently and shows the idle identity on a slot without an active device; a game that supports the tap runs with four players; neutral state after an inhibit is visible within the declared `neutralisation_bound_us` across a full tap read; the extra channels meet the annex's dynamics |
| ICD-VER-023 | ICD-DBG-001, SRS-HW-010 | Recovery | With a deliberately corrupted application image the node held in recovery enables no console-facing output, answers only HELLO, STATUS (state RECOVERY), DIAGNOSTICS and RESET, is restored over SWD and returns to INHIBITED at its persisted address |
| ICD-VER-024 | ICD-NET-002, SRS-NET-013 | Bus supply | With 10 adapters on a 5 m trunk and the farthest node transmitting, NET_PWR at every node within 4.5 to 5.5 V; a short on NET_PWR limits at 450 mA and recovers |
| ICD-VER-025 | ICD-PWR-001, SRS-HW-007 | Hub USB Type-C power | The hub draws no more than the advertised current at the 3.0 A, 1.5 A and default advertisements, powers the downstream ports as `ICD-PWR-001` states and reduces its load within 60 ms of an advertisement drop |
| ICD-VER-026 | ICD-CAP-016, ICD-PWR-002, SRS-HW-008 | Adapter power from the console | The console-side load stays within 70 % of the supply capacity established for the port or pass-through source; reverse polarity on an unkeyed input causes no damage; no current flows back into the console with the console off |
| ICD-VER-027 | ICD-NET-002, SRS-ENV-004 | RJ45 overvoltage | 57 V DC applied between every pair of RJ45 pins for 60 s causes no damage; the node works afterwards |
| ICD-VER-028 | ICD-CAP-021, 022, 024 | Adapter display, configuration store and status LEDs | Display refresh (including four VMU screens at 10 frames per second) and configuration-store writes during maximum console load cause no console timing violation; power removed during a store write leaves the previous valid record; the status LEDs show the node state and blink each fault value 1 to 6 as that many pulses |
| ICD-VER-029 | PS-DISCOVERY, ICD-NET-001 | Enumeration presence signal | With 10 unassigned nodes answering one ENUMERATE at once, the bus shows one continuous space level, no driver current above the transceiver's normal drive current and a break detected by the hub; no node answers with a frame |
| ICD-VER-030 | ICD-NET-001, ICD-PWR-002 | Galvanic isolation | DC resistance between NET_REF and each console-side ground and the hub logic ground at least 10 Mohm at 50 V; two adapters on consoles with different ground potentials (1 V apart) work without bus errors |
| ICD-VER-031 | ICD-NET-001 | Termination and idle bias | With both terminations, idle differential voltage at least 0.2 V at every node; with every node transmitting in turn, differential voltage at the farthest receiver at least 1.5 V |

## 11. Registers

### ICD-PLAT-001: RP2350 datasheet and errata register

| Field | Entry |
|---|---|
| Datasheet | Raspberry Pi Ltd, RP2350 Datasheet, RP-008373-DS, Release 9 (build date 2026-11-19), retrieved 2026-11-27 (`ICD-REF-001` R1) |
| Supported stepping | A4, the production stepping (`CHIP_ID.REVISION` 3 with bootrom version 4) |
| Package and GPIO | RP2350A (QFN-60) 30 GPIO; RP2350B (QFN-80) 48 GPIO; RP2354A and RP2354B the same packages with 2 MB stacked flash |
| Processing | Two Arm Cortex-M33 cores used (`SAD-018`); clk_sys and clk_peri 150 MHz set by firmware (the chip boots from its ring oscillator) |
| PIO and DMA | Three PIO blocks of four state machines (12); 16 DMA channels |
| UART | Two PL011; maximum baud UARTCLK / 16 (9.375 Mbaud at 150 MHz); fractional divider in 1/64 steps |
| SPI and I2C | Two PL022 SPI (controller clock at most clk_peri / 2); two I2C up to Fast-mode Plus (1 MHz) |
| USB | One USB 1.1 controller with PHY: device at full speed, or host to full- and low-speed devices including through hubs; the host polls up to 15 interrupt endpoints in hardware; external 27 ohm series resistors |
| OTP | 8 kB in 64 pages of 128 bytes; each page lockable read-write, read-only or inaccessible, with permanent hard locks. RPN uses one hard-locked read-only page for the node UID and programs nothing else |
| TRNG | Present, with von Neumann, repeated-block and autocorrelation health tests enabled at reset; used for the hub session ID (`PS-TRANSACTION`) |
| GPIO tolerance | Fault-tolerant pins tolerate 5.5 V only while IOVDD is 3.3 V and 3.63 V with IOVDD unpowered; ADC-capable pins (GPIO26 to 29 on QFN-60, GPIO40 to 47 on QFN-80) are not fault-tolerant; RPN relies on neither (`ICD-CAP-003`) |
| Boot and security | SWD on dedicated pins; boot ROM supports flash, OTP, USB and UART boot and optional signed boot; RPN uses no signed boot, no encryption and no OTP keys (`SRS-UPD-005`, `SRS-HW-010`) |

| Errata ID | Stepping | Affected interface | Mitigation in RPN |
|---|---|---|---|
| RP2350-E9 | A2 only (fixed in A3 and A4) | GPIO input pad leakage with input enabled | Not applicable to A4; every console-facing input has an external pull or driver (`ICD-CAP-003`) regardless |
| RP2350-E12 | A2, A3, A4 | USB status events lost when clk_sys is not faster than clk_usb | clk_sys 150 MHz (more than 10 % above 48 MHz) whenever USB is active: hub and Original Xbox USB processors |
| RP2350-E5, E8 | A2, A3, A4 | DMA CHAIN_TO with ABORT and with zero-length transfers | Bus, SPI and console DMA drivers do not abort chained channels and never chain zero-length transfers |
| RP2350-E27 | A2, A3, A4 | Bus-fabric priority controls act on the wrong managers | Real-time margins do not rely on APB/FASTPERI priority settings; verified by `ICD-VER-014` |
| RP2350-E2 | A2, A3, A4 | Spinlock writes mirrored | Firmware uses only the spinlocks the SDK leaves unaffected |
| RP2350-E11 | A2, A3, A4 | XIP cache clean by set/way | Firmware does not clean the XIP cache by set/way |
| RP2350-E17, E28 | A2, A3, A4 | OTP guarded reads of single ECC rows; lock-word keys | The UID page is read as whole ECC rows; no OTP access keys are used |
| RP2350-E30 | A2, A3, A4 | `reboot()` with zero delay does nothing | Resets use a non-zero delay |

No erratum affects the UART, SPI or PIO used by RPN.

### ICD-REF-001: source register

Every source was retrieved on 2026-11-27. Flags: **published** (primary document
with revision), **secondary** (community wiki, emulator or third-party copy) and
**measured** (original console, setup recorded). Sources are paraphrased in this
specification; no console firmware, SDK or proprietary code is used
(`SRS-LIC-001`).

| Ref | Source | Revision | Flag |
|---|---|---|---|
| R1 | Raspberry Pi Ltd, RP2350 Datasheet, RP-008373-DS (pip.raspberrypi.com) | Release 9, 2026-11-19 | published |
| R2 | NESdev Wiki, Controller port pinout (nesdev.org/wiki/Controller_port_pinout) | page edited 2026-09-18 | secondary |
| R3 | NESdev Wiki, Standard controller (nesdev.org/wiki/Standard_controller) | oldid 23466, 2026-01-28 | secondary |
| R4 | NESdev Wiki, Controller reading (nesdev.org/wiki/Controller_reading) | current page | secondary |
| R5 | NESdev forum archive, "NES (vs. SNES) controller timing?" (archive.nes.science, t12565) | 2015-03-28 | secondary |
| R6 | Gamicus wiki and Wikipedia, NES Max and list of NES accessories | current pages | secondary |
| R7 | SNESdev Wiki, Controller connector (snes.nesdev.org/wiki/Controller_connector) | current page | secondary |
| R8 | SNESdev Wiki, Standard controller (snes.nesdev.org/wiki/Standard_controller) | current page | secondary |
| R9 | SNESdev Wiki, Mouse (snes.nesdev.org/wiki/Mouse) | current page | secondary |
| R10 | SNESdev Wiki, Multitap (snes.nesdev.org/wiki/Multitap) | current page | secondary |
| R11 | M. Korth, Fullsnes (problemkaputt.de/fullsnes.htm) | current text | secondary |
| R12 | J. Christy, SNES Controller Pinouts and Protocol FAQ (gamesx.com/controldata/snesdat.htm) | v1.01, 1996-03-26 | secondary |
| R13 | Sega, SMPC User's Manual, chapter 3 Peripheral Control (English translation, infochunk.com/saturn) | 1st edition Release 2, 1997 | published |
| R14 | plutiedev, Controllers (plutiedev.com/controllers) | current page | secondary |
| R15 | MAME, Mega Drive 6-button pad device md6bt.cpp (github.com/mamedev/mame) | master branch | secondary |
| R16 | J. Gagnon, BlueRetro log "Evolution of SEGA's IO interface" (hackaday.io) | 2020-07-14 | secondary |
| R17 | H. Johnson, Genesis programming part 19: 6 button controllers (huguesjohnson.com) | current page | secondary |
| R18 | FRS, Sega Saturn joystick (frs.badcoffee.info/Sega/SaturnJoystick.html) | current page | secondary |
| R19 | saturn-pad-emulator README (codeberg.org/abrasive/saturn-pad-emulator) | 2026-06-16 | secondary |
| R20 | ModRetro forum, "Saturn controller protocol MK80117 and emulation" | 2013-03 to 2014-07 | secondary |
| R21 | Sega Retro accessory pages: HSS-0137, HSS-0151, HSS-0129, MK-1645, Sega Tap, Dreamcast accessories in Japan (segaretro.org) | current pages | secondary |
| R22 | N64brew Wiki, Joybus Protocol (n64brew.dev/wiki/Joybus_Protocol) | 2026-11-22 | secondary |
| R23 | Nintendo, US patent 6,325,718 B1, operation controlling device and video processing system | issued 2001-12-04 | published |
| R24 | N64brew Wiki, Controller Pak (n64brew.dev/wiki/Controller_Pak) | current page | secondary |
| R25 | N64brew Wiki, Rumble Pak (n64brew.dev/wiki/Rumble_Pak) | current page | secondary |
| R26 | N64brew Wiki, NUS-005 and PIF-NUS (n64brew.dev) | NUS-005 oldid 1485, 2020-09-17 | secondary |
| R27 | N64brew Wiki, Fishing Rod (n64brew.dev/wiki/Fishing_Rod) | 2026-11-22 | secondary |
| R28 | consoleprotocols, Nintendo Joy Bus documentation (sites.google.com/site/consoleprotocols) | current page | secondary |
| R29 | J. Ward, Nintendo Gamecube Controller Protocol (int03.co.uk/crema/hardware/gamecube) | 2004-03-08 | secondary |
| R30 | BitBuilt forum, GameCube controller protocol timing information | 2021-12-06 | secondary |
| R31 | devkitPro libogc and Dolphin emulator SI device sources (github.com) | master branches | secondary |
| R32 | Sega, Maple Bus 1.0 Peripheral Hardware Specifications: Dreamcast Controller (Rev 1.00, 1998-05-21) and VMU (Rev 1.00, 1999-06-04) (segaretro.org) | as stated | published |
| R33 | Sega, Maple Bus 1.0 Function Type Specifications FT0 controller (Rev 0.90), FT3 timer (Rev 0.80), FT6 keyboard (Rev 0.90), FT8 vibration (Rev 0.80, 1998-10-05), FT9 pointing (Rev 0.91, 2000-03-23) (segaretro.org) | as stated | published |
| R34 | M. Comstedt, Dreamcast Programming: Maple Bus and Maple Bus Wire Protocol (mc.pp.se/dc) | 2000-09-20 | secondary |
| R35 | dreamcast.wiki, Maple bus (dreamcast.wiki/Maple_bus) | oldid 3854, 2026-06-16 | secondary |
| R36 | DreamcastControllerUsbPico README (github.com/sega-dreamcast) | current page | secondary |
| R37 | The Dreamcast Junkyard, Dreamcast fishing games guide | 2017-01 | secondary |
| R38 | psx-spx, Controllers and Memory Cards; Pinouts (psx-spx.consoledev.net) | current pages | secondary |
| R39 | Curious Inventor, Interfacing a PS2 Controller (store.curiousinventor.com/guides/PS2) | current page | secondary |
| R40 | Texas Instruments, ISO3080/ISO3082/ISO3086/ISO3088 Isolated 5-V Full- and Half-Duplex RS-485 Transceivers, SLOS581J | revised August 2023 | published |
| R41 | Wikipedia, NeGcon; Jogcon; PlayStation Multitap; Gran Turismo official steering wheel | edited 2026-08-21 to 2026-11-27 | secondary |
| R42 | xboxdevwiki, Xbox Input Devices; USB; Hardware Revisions (xboxdevwiki.net) | 2026-02-25; 2022-11-11; 2025-07-02 | secondary |
| R43 | xid_wheel_adapter and ogx360 READMEs (github.com/sonik-br, github.com/Ryzee119) | current pages | secondary |
| R44 | FS.com, Cat5e UTP patch cable datasheet (cites ANSI/TIA-568-C.2 and ISO/IEC 11801) | current sheet | secondary |
| R45 | Texas Instruments, TPS23751/TPS23752 datasheet, PoE overview (IEEE 802.3at voltages), SLVSB97E | Rev E, 2018-01 | published |
| R46 | IEC 61000-4-2 Ed. 3.0 (preview) and TI application report SLVA711 (test levels) | 2025-03; 2015 | published (edition), secondary (level table) |
| R47 | USB-IF, USB Type-C Cable and Connector Specification | Release 2.5, 2026-03 | published |
| R48 | RAMXEED, SPI FeRAM product pages (MB85RS1MT, MB85RS4MT; ramxeed.com/products/feram) | datasheets DS10v0, DS3v1 | published |
| R49 | Infineon, CY15B104QN EXCELON LP 4-Mbit SPI F-RAM, 002-19436 | Rev *O, 2023-06-05 | published |
| R50 | RAMXEED, I2C FeRAM product page (MB85RC64TA, MB85RC512T) | datasheet DS5v2 | published |
| R51 | iFixit, PlayStation Controller Ports Replacement (SCPH-1001), guide 1597 | current guide | secondary |

## Annexes: console profiles

Each annex specifies one console profile under the contract of `ICD-CON-001`. In
every annex, directions are relative to the adapter, flags and reference numbers
point to `ICD-REF-001`, and the following rules apply unless the annex states
otherwise:

- **Power.** The console side is powered from the designated port's supply pin when
  `ICD-VER-026` establishes that the port supplies at least 188 mA (131 mA at 3.3 V
  within 70 %) at its nominal voltage; otherwise from the pass-through input, which
  accepts 5 to 12 V DC of either polarity or 7 to 12 V AC through a bridge rectifier,
  so no polarity keying is needed. No primary source states a controller-port current
  limit for any console.
- **Live peripheral change.** A route may change the presented peripheral while the
  adapter is inhibited or configured, which the console sees as a controller being
  swapped; arming and route amendment never change it (`SRS-IN-011`).
- **Response.** The adapter starts every console response within the limit the
  annex gives, from a locally installed snapshot (`SAD-003`).
- **Measurements.** The listed measurements establish the annex's secondary-flagged
  values on an original console of the family (`ICD-QUAL-001`) and are recorded in
  the annex with the flag measured.

### Annex A - NES (ICD-CON-NES)

**Identity.** NES front-loader NES-001 and top-loader NES-101 (all regions) and the
AV Famicom HVC-101 (R2, R3; secondary). Presented peripherals: standard pad and NES
Max (NES-027).

**Connectors and port mapping.** Two 7-pin NES controller connectors; port 0 is
connector 1, port 1 is connector 2. No multitap (`SRS-SYS-010`).

| Pin | Signal | Direction | Level and drive | Source |
|---|---|---|---|---|
| 1 | GND | - | 0 V | R2 secondary |
| 2 | CLK | In | 5 V; the adapter provides a 3.6 kohm pull-up to the port's 5 V, as the console may have series diodes (PAL) | R2, R3 secondary |
| 3 | OUT (latch) | In | 5 V; 3.6 kohm pull-up as CLK | R2, R3 secondary |
| 4 | D0 | Out | 5 V push-pull; the console inverts it | R2 secondary |
| 5, 6 | D4, D3 | - | High-impedance (no presented peripheral uses them) | R2 secondary |
| 7 | +5 V | Power | Console supply; power sense and optional supply | R2 secondary |

**Timing.** Read timing is set by game software: latch pulses from about 2 us,
clock low pulses of about 0.5 us and bit spacing from about 2.2 us to 10 us
(R5; secondary). The adapter loads the snapshot while OUT is high, presents bit n
on D0 within 200 ns of each CLK rising edge, presents the official pad's level
after the eighth bit (the console reads 1), and returns identical data for repeated
reads within one latch period, which games use to reject corrupted reads (R3, R4).

**Peripherals.** Standard pad: eight bits A, B, Select, Start, Up, Down, Left,
Right; no identification mechanism exists (R3). NES Max: the same report; its turbo
A and B toggle from a free-running oscillator at 15 Hz, never from the strobe
(R3, R6; secondary).

**Idle identity.** Standard pad with no button pressed.

**Neutralisation.** `neutralisation_bound_us` = 200: neutral data is installed within
50 us and a read already in progress completes from the snapshot latched at its
latch pulse.

**Resources.** RP2350A; PIO 2 of 12 state machines (one per connector, 17 %); DMA 4
of 16 (bus RX/TX, I2C, 25 %).

**Measurements.** Pin numbering on the physical connector; console-side pull-ups and
PAL series diodes; port supply capacity (`ICD-VER-026`); latch and clock timing
across games, including repeated reads; D0 update within 200 ns.

### Annex B - SNES (ICD-CON-SNES)

**Identity.** Super Famicom SHVC-001, SNES SNS-001, PAL SNSP-001A and SNS-101
(R7, R11; secondary). Presented peripherals: standard pad and SNES Mouse (SNS-016).

**Connectors and port mapping.** Two 7-pin SNES controller connectors. A user option
(`SRS-UI-007`) selects connector 2's mode: **multitap** (default) presents the Super
Multitap: port 0 is connector 1 and ports 1 to 3 are tap slots 2 to 4 (slot 5 reports
no controller); **direct** presents port 0 on connector 1 and port 1 on connector 2.

| Pin | Signal | Direction | Level and drive | Source |
|---|---|---|---|---|
| 1 | +5 V | Power | Console supply; power sense and optional supply | R7, R11 secondary |
| 2 | Clock | In | 5 V; adapter pull-up 3.6 kohm (PAL series diodes) | R7, R11 secondary |
| 3 | Latch | In | 5 V; adapter pull-up 3.6 kohm | R7, R11 secondary |
| 4 | Data1 | Out | 5 V push-pull; inverted by the console | R7, R11 secondary |
| 5 | Data2 | Out (connector 2, multitap) | 5 V push-pull | R7, R10 secondary |
| 6 | IOBit | In (connector 2, multitap) | Driven by the console with a weak pull-up; slow rising edge | R10, R11 secondary |
| 7 | GND | - | 0 V | R7 secondary |

**Timing.** Automatic reading clocks 16 bits at about 12 us per bit (about 197 us);
software may read faster, down to about 7.9 us per bit (R9, R11, R12; secondary).
Data changes on the clock's rising edge; the adapter presents each bit within 200 ns.

**Peripherals.** Standard pad: 16 bits B, Y, Select, Start, Up, Down, Left, Right, A,
X, L, R and ID 0000, then 1s (R8, R11). SNES Mouse: 32 bits with ID 0001, two buttons,
a 2-bit sensitivity value and sign-and-magnitude 7-bit X and Y motion reset after each
read; each clock pulse while latch is high advances the sensitivity (R9, R11;
secondary). The mouse is presented on port 0, or on port 1 in direct mode; it is not
offered on a tap slot.

**Multitap.** Super Multitap (Nintendo's "Multiplayer 5"): IOBit high selects slots 2
and 3 (Data1 and Data2), low selects slots 4 and 5; each slot report gains a 17th
"connected" bit; with latch high, Data2 reads eight 1s and then a byte other than all
1s, by which games detect the tap (R10, R11; secondary).

**Idle identity.** Standard pad with no button pressed; an inactive tap slot reports a
connected standard pad with no button pressed.

**Neutralisation.** `neutralisation_bound_us` = 600: an automatic read plus the extra
manual tap reads of one frame complete from their latched snapshot.

**Resources.** RP2350A; PIO 3 of 12 (25 %); DMA 4 of 16 (25 %).

**Measurements.** Pin numbering; pull-ups and PAL diodes; port supply capacity;
automatic and manual read timing; tap detection and IOBit timing with tap games;
mouse sensitivity cycling.

### Annex C - Mega Drive (ICD-CON-MD)

**Identity.** Mega Drive / Genesis Model 1, Model 2 and Model 3, all regions (R16, R21;
secondary). Presented peripherals: 3-button pad, 6-button pad and Mega Mouse (MK-1645).

**Connectors and port mapping.** Two DE-9 controller connectors. A user option selects
connector 1's mode: **multitap** (default) presents the Sega Team Player (MK-1654) on
connector 1 with ports 0 to 3 on its slots A to D, and connector 2 presents no
controller; **direct** presents port 0 on connector 1 and port 1 on connector 2.

| Pin | Signal | Direction | Level and drive | Source |
|---|---|---|---|---|
| 1 to 4 | Up, Down, Left, Right (D0 to D3) | Out | 5 V push-pull | R14, R16 secondary |
| 5 | +5 V | Power | Console supply; power sense and optional supply | R16 secondary |
| 6 | TL | Out | 5 V push-pull (acknowledge on handshake devices) | R16 secondary |
| 7 | TH | In | Driven by the console; the adapter provides a 10 kohm pull-up, as pads pull it up | R16 secondary |
| 8 | GND | - | 0 V | R16 secondary |
| 9 | TR | Out on pads; In (request) on handshake devices | Direction-controlled channel with its own direction GPIO on connector 1 | R16 secondary |

**Timing.** The console waits 2 us after changing TH before sampling (R13; published);
the adapter updates its outputs within 1 us of a TH edge. The 6-button pad counts TH
rising edges through four phases and resets the count after TH has been idle for
1.5 ms (R15, R17; secondary).

**Peripherals.** Identification by the 4-bit ID built from the data lines with TH high
and low (R13; published): 3-button pad D, 6-button pad D with the phase-2 signature
(all four data lines low with TH low), Mega Mouse 3, Team Player 7. 3-button pad: TH
high gives Up, Down, Left, Right, B, C; TH low gives Up, Down, low, low, A, Start
(R14). 6-button pad: phase 3 with TH high gives X, Y, Z and Mode (R15, R17). Mega Mouse:
three-wire handshake (TH low selects, each TR edge requests a nibble, TL acknowledges)
carrying a button nibble and two nibbles per axis with sign and overflow (R16;
secondary). The Mega Mouse needs TR as an input, so it is presented on port 0 in direct
mode and on Team Player slots, where connector 1's direction-controlled TR is used.

**Multitap.** Team Player: handshake device with ID 7; a header, then one type nibble
per slot (0 3-button, 1 6-button, 2 mouse, F none) and each slot's data (R16;
secondary).

**Idle identity.** 3-button pad with no button pressed; an inactive Team Player slot
reports a 3-button pad with no button pressed.

**Neutralisation.** `neutralisation_bound_us` = 800: outputs switch to neutral at the
next slot-record boundary of a Team Player read, or at the next TH edge without a tap.

**Resources.** RP2350B; PIO 3 of 12 (25 %); DMA 4 of 16 (25 %).

**Measurements.** Pin numbering; TH-edge response; the 6-button reset time against the
verification game set; handshake timing of the mouse and the Team Player; port supply
capacity.

### Annex D - Saturn (ICD-CON-SAT)

**Identity.** Every Saturn model with two front controller ports, all regions (R21;
secondary). Presented peripherals: digital pad, 3D Control Pad (HSS-0137), Virtua
Stick, Twin Stick (HSS-0151), Saturn Keyboard (HSS-0129), Shuttle Mouse and Arcade
Racer (HSS-0141).

**Connectors and port mapping.** Two 9-pin Saturn controller connectors. A user option
selects connector 1's mode: **multitap** (default) presents the Saturn multitap
(six slots) on connector 1 with ports 0 to 3 on slots 1 to 4 and slots 5 and 6 empty,
and connector 2 presents no controller; **direct** presents port 0 on connector 1 and
port 1 on connector 2.

| Pin | Signal | Direction | Level and drive | Source |
|---|---|---|---|---|
| 1 | VCC | Power | 5 V console supply; power sense and optional supply | R18 secondary |
| 2, 3, 7, 8 | D1, D0, D3, D2 | Out | 5 V push-pull | R18 secondary |
| 4 | TH | In | Select from the console; adapter pull-up 100 kohm, as the 3D Control Pad | R18, R20 secondary |
| 5 | TR | In | Request from the console; adapter pull-up 100 kohm | R18, R20 secondary |
| 6 | TL | Out | 5 V push-pull acknowledge | R18, R20 secondary |
| 9 | GND | - | 0 V | R18 secondary |

**Timing.** The console waits 2 us after changing TH before sampling (R13; published);
the adapter answers each TH or TR edge within 1 us.

**Peripherals.** Identification by the 4-bit ID (digital pad B, handshake devices 5)
and, for handshake devices, a peripheral ID byte whose high nibble is the type (0
digital, 1 analog, 2 pointing, 3 keyboard) and low nibble the data length (R13;
published). Digital pad: ID byte 02h, two bytes, selected by TH and TR as four nibbles:
TH low and TR high gives Up, Down, Left, Right; TH high and TR high gives L and the ID
bits; TH high and TR low gives B, C, A, Start; TH low and TR low gives Z, Y, X, R (R16,
R19; secondary). 3D Control Pad: 16h
with six bytes (buttons, X, Y, right and left analog triggers) in analog mode, 02h in
digital mode, both through the handshake (R13; published). Virtua Stick: presents the
digital pad (R21; secondary). Twin Stick: 02h with both sticks on the digital pad's
direction and button bits (R13; published). Keyboard: 34h, four bytes with lock state,
make/break flags and the key code (R13; published). Shuttle Mouse: E3h, three bytes in
the pointing format with active-high buttons (R13; published). Arcade Racer: 13h,
three bytes with one steering byte from 0 (full left) to 255 (full right) (R13;
published).

**Multitap.** Handshake device with ID 5, tap type 1, six slots, each slot reporting
its own peripheral ID byte and data; an empty slot reports FFh (R13; published).

**Idle identity.** Digital pad with no button pressed; an inactive tap slot reports a
digital pad with no button pressed.

**Neutralisation.** `neutralisation_bound_us` = 900: neutral data takes effect at the
next slot-record boundary of a tap read.

**Resources.** RP2350B; PIO 3 of 12 (25 %); DMA 4 of 16 (25 %).

**Measurements.** Pin numbering; the digital pad's nibble assignment and handshake
timing from an original pad; tap timing; port supply capacity.

### Annex E - Nintendo 64 (ICD-CON-N64)

**Identity.** NUS-001, all regions (R26; secondary). Presented peripherals: standard
controller, fishing controller and steering wheel; per port, Controller Pak, Rumble Pak
or no accessory (`SRS-STO-012`).

**Connectors and port mapping.** Four 3-pin N64 controller connectors; ports 0 to 3 are
connectors 1 to 4.

| Pin | Signal | Direction | Level and drive | Source |
|---|---|---|---|---|
| 1 | GND | - | 0 V | R26, R28 secondary |
| 2 | Data | Bidirectional | 3.3 V open-drain, never driven high; discrete open-drain driver plus sense input; the adapter provides the controller-side pull-up (an official controller measures about 760 ohm) | R22, R28 secondary |
| 3 | +3.3 V | Power | Console supply; power sense and optional supply | R26 secondary |

**Timing.** 4 us bit cells (a zero is about 3 us low and 1 us high, a one the reverse);
console stop bit 3 us, controller stop bit 4 us; a 1 ms low level resets the device
(R22; secondary). Commands: 00h status, FFh reset and status, 01h poll (four-byte
reply), 02h accessory read (32 data bytes and a CRC), 03h accessory write (R23;
published). An accessory reply starts within 62.5 us (R22; secondary). The adapter starts status
and poll replies within 10 us and accessory replies within 50 us (worst-case FRAM wait
of `ICD-STO-001` plus processing).

**Peripherals.** Standard controller: ID 05 00 and a status byte reporting accessory
present, absent or newly inserted; the poll reply carries 16 button bits and signed X
and Y (R22, R23). Fishing controller: presents the standard controller identity, the
reel on the stick's Y axis and the rod's built-in rumble as a Rumble Pak (Mad Catz
Rumble Rod; R27; secondary) when the port's accessory option is Rumble Pak. Steering wheel: presents the standard controller identity with steering on stick
X, accelerator on A and brake on B (secondary: third-party wheels present the standard
controller, R22).

**Accessories.** Controller Pak: 32 KiB at 0000h to 7FFFh in 32-byte blocks, each
command carrying a 5-bit address check, each data block returned with a CRC-8 of
polynomial 85h (R22, R24; secondary). Rumble Pak: writing 80h to the 8000h range
identifies it, and an odd or even value written to the C000h range starts or stops
the motor (R25; secondary), forwarded as rumble on or off (`SRS-OWN-015`). Snapshot
quiet time 500 ms.

**Idle identity.** Standard controller with no button pressed and the port's configured
accessory.

**Neutralisation.** `neutralisation_bound_us` = 250: a poll reply in progress completes
from its snapshot.

**Resources.** RP2350B (GPIO, section 8.3); PIO 4 of 12 (one per connector, 33 %); DMA
6 of 16 (bus, I2C, FRAM SPI, 38 %).

**Measurements.** Pin numbering; console pull-up value and the line's rise time; poll and
accessory reply windows; fishing controller and wheel report captures; port supply
capacity.

### Annex F - GameCube (ICD-CON-GC)

**Identity.** DOL-001 and DOL-101, all regions (R29; secondary). Presented peripherals:
standard controller, ASCII keyboard (ASC-1901PO) and steering wheel (Logitech Speed
Force).

**Connectors and port mapping.** Four 7-pin GameCube controller connectors; ports 0 to 3
are connectors 1 to 4.

| Pin | Signal | Direction | Level and drive | Source |
|---|---|---|---|---|
| 1 | +5 V | Power | Rumble motor supply, always on; power sense | R29 secondary |
| 2 | Data | Bidirectional | 3.43 V open-drain; discrete driver plus sense input; the adapter provides the controller-side pull-up (an official controller measures about 745 ohm) | R29 secondary |
| 3, 4 | GND | - | 0 V | R29 secondary |
| 5 | - | - | Not connected | R29 secondary |
| 6 | +3.43 V | Power | Logic supply; optional adapter supply | R29 secondary |
| 7 | Shield | - | Cable shield | R29 secondary |

**Timing.** The console sends at about 5 us per bit and a controller replies at about
4 us per bit, in the N64 bit-cell code (R29, R30; secondary); with nothing connected
the console probes about every 12 ms. The adapter starts every reply within 10 us.

**Peripherals.** Commands: 00h identify, FFh reset, 40h poll (whose third byte carries
the rumble state: stop, rumble, hard stop), 41h origin, 42h recalibrate, 43h long poll,
54h keyboard poll, 30h wheel force feedback (R29, R31; secondary). Standard controller:
ID 09 00, eight-byte poll reply with buttons, main stick, C-stick and analog L and R
(R29, R31). Keyboard: identifies as 08 20 (R31; secondary; R22 lists 08 02, and the
capture below confirms the value); its eight-byte reply carries a 4-bit
counter, three key codes and an XOR check byte; the original device uses two ports, its
pad part on one and its keyboard on another (R31; secondary); RPN presents the keyboard
on one route and a standard controller on another, each with its own player and
device. Steering wheel: ID 08 00, poll reply with steering, accelerator and brake;
command 30h carries a 9-bit force centred at 128 and an on/off type, forwarded as
constant force (R31; secondary). Rumble requests are forwarded as rumble.

**Idle identity.** Standard controller with no button pressed and sticks at their origin.

**Neutralisation.** `neutralisation_bound_us` = 500: a poll exchange in progress completes
from its snapshot.

**Resources.** RP2350A; PIO 4 of 12 (33 %); DMA 4 of 16 (25 %).

**Measurements.** Console pull-up and rise time; reply windows; keyboard and wheel
identification and force-feedback captures; port supply capacity.

### Annex G - Dreamcast (ICD-CON-DC)

**Identity.** Every regional Dreamcast model (R35; secondary). Presented peripherals:
standard controller, Arcade Stick (HKT-7300), Fishing Controller (HKT-8700), Keyboard
(HKT-7600), Mouse (HKT-9900) and Race Controller (HKT-7400); on every controller port a
VMU memory accessory in expansion slot 1 and a vibration pack (HKT-8600) in slot 2
(`SRS-STO-009`).

**Connectors and port mapping.** Four Maple bus connectors; ports 0 to 3 are ports A to D.

| Pin | Signal | Direction | Level and drive | Source |
|---|---|---|---|---|
| 1 | SDCKA | Bidirectional | 3.3 V with weak pull-ups; direction-controlled group with SDCKB | R34, R35 secondary |
| 2 | +5 V | Power | Console supply; power sense and optional supply | R35 secondary |
| 3 | GND | - | 0 V | R35 secondary |
| 4 | GND (sense) | In | The console ties it to ground; the presence/sense channel reads it to confirm the cable is connected to a console | R35, R36 secondary |
| 5 | SDCKB | Bidirectional | As SDCKA | R34, R35 secondary |

The console has 36 ohm series resistors on the signal lines (R36; secondary); the
adapter adds at most 47 ohm series resistance and 20 pF per line, so the total stays
below the 100 ohm at which communication is reported to fail (R36; secondary).

**Timing.** The two lines alternate as clock and data, about 2 Mbit/s from the console
and slower from devices, with a start pattern of four pulses on SDCKB (R34, R35, R36;
secondary). A device that sees no transition for 1 ms resets its receiver, and the
console retries an erroneous exchange up to three times (R33; published). Devices start
replying about 50 us after the console's end pattern (R36; secondary). The adapter
starts controller and status replies within 50 us and storage replies within 600 us
(worst-case FRAM wait of `ICD-STO-001` plus processing), inside the 1 ms no-transition
limit of R33; `ICD-VER-021` confirms that the console accepts that start time.

**Peripherals.** Frames are 32-bit words with command, recipient, sender and length,
followed by an XOR checksum (R34; secondary; field order R33, published). Addresses: two
port bits, a main-peripheral bit and five expansion-slot bits; the main peripheral's
sender address shows which slots are filled (R34, R35; secondary), and a slot is present
only when its device is (R33; published). Device status gives the function mask,
function definitions, region, name, licence and current figures (R32; published).
Standard controller: function FT0 with an eight-byte condition (buttons, analog
triggers, stick at centre 80h) (R32; published). Arcade Stick: FT0 with digital controls
(R21; secondary). Race Controller: FT0 with steering on the stick's X axis and the pedals
on the analog triggers (R21; secondary).
Fishing Controller: presents function FT0 with the reel on the right analog trigger
and the rod's motion on the stick's X and Y axes (R37; secondary); its motion axes are
fed from generic axes under an approved lossy mapping and its built-in
rumble is forwarded (R37; secondary). Keyboard: function FT6 (R33; published). Mouse:
function FT9 with 10-bit relative axes centred at 200h and buttons A, B, C and the wheel
(R33; published).

**Accessories.** VMU: functions FT1 storage and FT2 display; 256 blocks of 512 bytes with
200 user blocks, reads of one 512-byte access and writes of four 128-byte accesses; a
48 x 32 display written as 192 bytes, shown on the adapter display (R32; published;
`ICD-CAP-021`). Vibration pack: function FT8 with one vibration source, controlled by Set
Condition and stopping by itself after 5 s by default (R33; published), forwarded as
rumble. Snapshot quiet time 500 ms.

**Idle identity.** Standard controller with no button pressed, with its VMU and vibration
pack.

**Neutralisation.** `neutralisation_bound_us` = 500: a condition reply in progress
completes from its snapshot.

**Resources.** RP2350B; PIO 4 of 12 (one per port, 33 %); DMA 10 of 16 (bus, I2C, FRAM
SPI, four Maple ports, 63 %).

**Measurements.** Pin numbering; line levels, pull-ups, rise times and the adapter's series
budget; reply timing; captures of the Race Controller and the Fishing Controller; port
supply capacity.

### Annex H - PlayStation (ICD-CON-PS)

**Identity.** PlayStation SCPH-1000 to SCPH-9000x and PSone SCPH-100 to SCPH-102 (R38,
R51; secondary). Presented peripherals: digital pad, DualShock, NeGcon, Jogcon, Mouse
and a controller-port steering wheel.

**Connectors and port mapping.** Two 9-pin controller connectors. A user option selects
the mode: **multitap on connector 1** (default) presents the PlayStation multitap
(SCPH-1070) on connector 1 with ports 0 to 3 on slots A to D; **multitap on connector 2**
does the same on connector 2, for games that expect it there; **direct** presents port 0
on connector 1 and port 1 on connector 2.

| Pin | Signal | Direction | Level and drive | Source |
|---|---|---|---|---|
| 1 | DATA | Out | 3.5 V-class open-drain; the console pulls it up and the adapter adds no pull-up | R38, R39 secondary |
| 2 | CMD | In | 3.5 V push-pull from the console | R38 secondary |
| 3 | +7.6 V | - | Motor supply; not used | R38, R39 secondary |
| 4 | GND | - | 0 V | R38 secondary |
| 5 | +3.5 V | Power | Logic supply; power sense and optional supply | R38 secondary |
| 6 | /ATT | In | Per-connector select, active low | R38 secondary |
| 7 | CLK | In | Idles high | R38 secondary |
| 8 | /IRQ | - | Not connected | R38 secondary |
| 9 | /ACK | Out | Open-drain, as DATA | R38, R39 secondary |

**Timing.** Byte-synchronous, least significant bit first, data changing on the clock's
falling edge and sampled on its rising edge, at about 250 kHz; after every byte but the
last the device pulls /ACK low for at least about 2 us, and the console gives up when
/ACK does not fall within about 100 us (R38, R39; secondary). The adapter answers each
byte in step with the clock and pulls /ACK low for 3 us, starting 5 to 20 us after the
byte.

**Peripherals.** A packet starts with address 01h and command 42h; the reply carries the
ID byte, 5Ah and the data (R38). IDs: digital pad 41h, analog (DualShock) 73h, NeGcon
23h, Mouse 12h, Jogcon E3h, configuration mode F3h (R38; secondary). DualShock:
configuration commands 43h, 44h, 45h, 4Dh and 4Fh; after motor mapping (4Dh) one poll
byte switches the small motor and one sets the large motor's 8-bit speed, forwarded as
rumble (R38, R39). NeGcon: twist axis and analog I, II and L (R38, R41). Jogcon: dial
position and direction; its force-feedback motor is commanded by the two poll command
bytes that drive the DualShock motors, read as a direction and an 8-bit strength, and
forwarded as constant-force and spring effects (R38, R41; secondary: R38 describes the
format by analogy with the DualShock). Mouse: two buttons and signed 8-bit X and Y deltas
(R38). Steering wheel: presents the NeGcon identity with steering on the twist axis,
accelerator on I and brake on II, as controller-port wheels do (R38; secondary); a user
option selects the analog-pad identity (73h) instead.

**Multitap.** Extended mode, requested by 01h as the third command byte, returns ID 80h
followed by four slot blocks; slots can also be addressed directly (R38; secondary).

**Idle identity.** Digital pad with no button pressed; an inactive tap slot reports a
digital pad with no button pressed.

**Neutralisation.** `neutralisation_bound_us` = 800: neutral data takes effect at the next
slot-block boundary of an extended tap read, which keeps every slot's record coherent.

**Resources.** RP2350A; PIO 2 of 12 (17 %); DMA 4 of 16 (25 %).

**Measurements.** Console pull-up values; clock rate and /ACK window across games;
multitap timing; Jogcon motor commands; port supply capacity.

### Annex I - PlayStation 2 (ICD-CON-PS2)

**Identity.** PlayStation 2 SCPH-10000 to SCPH-50000 series and slim SCPH-70000 to
SCPH-90000 series (R38, R41; secondary). Presented peripherals: DualShock 2 and a
controller-port steering wheel.

**Connectors and port mapping.** Two 9-pin controller connectors and, for the multitap,
the memory-card slot of connector 1. A user option selects the mode: **multitap**
(default) presents the PlayStation 2 multitap on connector 1 and memory-card slot 1 with
ports 0 to 3 on slots A to D; **direct** presents port 0 on connector 1 and port 1 on
connector 2. Controller connector pins are as Annex H; the memory-card slot carries
DATA, CMD, CLK, its own /ATT and /ACK with the same levels and drive (R38; secondary).

**Timing.** As Annex H, with clock rates up to about 500 kHz (R39; secondary).

**Peripherals.** DualShock 2: IDs 41h, 73h and 79h; full pressure mode, enabled by
command 4Fh, adds twelve 8-bit pressure values in the order Right, Left, Up, Down,
Triangle, Circle, Cross, Square, L1, R1, L2, R2; motors as the DualShock (R38, R39;
secondary). Steering wheel: presents the analog-pad identity (73h) with steering on the
left stick's X axis and the pedals on the right stick's Y axis; a user option selects the
NeGcon identity (23h) (R38, R41; secondary).

**Multitap.** The PlayStation 2 multitap connects to both the controller connector and the
memory-card slot and switches between its slots on commands addressed to it (R38, R41;
secondary); it answers its switching commands at address 21h, as R38's address table
states (R38 also mentions 61h in its text; secondary).

**Idle identity.** DualShock 2 in digital mode with no button pressed.

**Neutralisation.** `neutralisation_bound_us` = 950: a full-pressure poll packet in progress
completes from its snapshot; switching takes effect at the next slot boundary of a tap read.

**Resources.** RP2350B; PIO 3 of 12 (25 %); DMA 4 of 16 (25 %).

**Measurements.** As Annex H, plus the multitap address and switching sequence and the
memory-card slot timing.

### Annex J - Original Xbox (ICD-CON-XBOX)

**Identity.** Original Xbox revisions 1.0 to 1.6 (R42; secondary). Presented peripherals:
controller, Arcade Stick and Steering Wheel.

**Connectors and port mapping.** Four Xbox controller ports; ports 0 to 3 are front ports
1 to 4. The adapter cable carries +5 V, D-, D+, GND and the shield (R42; secondary); the
yellow video-sync line is not connected.

**Electrical.** One USB 1.1 full-speed device interface per port, each on its own RP2350A
(`ICD-CAP-011`), with 27 ohm series resistors and USB ESD protection; each USB processor
is powered from its port's 5 V (the port's current is established by `ICD-VER-026`). The
gateway is the USB processor of port 0 and owns the bus node. Internal link: SPI at
10 MHz from the gateway to the three other processors (gateway SCK, MOSI, MISO and three
chip selects).

**Protocol.** XID devices: interface class 58h, subclass 42h, interrupt IN and OUT
endpoints; an XID descriptor (type 42h) giving the type and subtype: controller 01h
subtype 02h, steering wheel subtype 10h, arcade stick subtype 20h; a 20-byte input report
with the digital buttons, eight 8-bit analog buttons (A, B, X, Y, Black, White, left and
right trigger) and four signed 16-bit stick axes; a 6-byte output report with two 16-bit
motor strengths, forwarded as rumble (R42; secondary). No source describes controller
authentication on the Original Xbox and emulating projects present plain XID devices
(R42, R43; secondary); enumeration on every revision is verified by `ICD-VER-010`.

**Peripherals.** Controller, Arcade Stick and Steering Wheel as above; the wheel's
feedback is the standard rumble report (R42, R43).

**Installation.** The gateway validates and maps the whole INPUT, then forwards each port's
record over the internal link (about 40 bytes, 32 us at 10 MHz); every processor installs
its record atomically and confirms it; the skew between ports is at most 150 us; a
record not confirmed within 150 us is a forwarding failure, which neutralises that port
and raises fault 2 (`SRS-IN-008`, `SAD-050`). While armed the gateway refreshes every
processor every 0.2 ms; a processor without a valid refresh for 0.5 ms neutralises its
port by itself (`SAD-ADAPT-001`).

**Idle identity.** Controller (subtype 02h) with no button pressed.

**Neutralisation.** `neutralisation_bound_us` = 500: the USB processor replaces the report
already queued in its IN endpoint with a neutral report within 300 us of the gateway's
inhibit, covering the link and the endpoint rewrite; if the link fails, the 0.5 ms refresh
timeout plus the endpoint rewrite stays within the same bound. The gateway acknowledges
REVOKE only after all four processors confirm neutral.

**Resources.** Each processor RP2350A. Gateway GPIO: bus 3, commissioning 1, recovery 1,
LEDs 2, I2C 2, VBUS sense 1, link 6: 16 of 30 (53 %). Other processors: link 4, recovery
1, VBUS sense 1: 6 of 30 (20 %). PIO none. DMA: gateway 6 of 16, others 2 of 16.

**Measurements.** Connector pin numbering; port current capacity; enumeration and report
timing on every revision; neutral replacement of a queued report.
