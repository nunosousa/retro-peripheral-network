# Electrical Interface Capability Specification (deprecated engineering notes)

| Control field | Value |
|---|---|
| Document ID | RPN-EIC (deprecated; identifier not reused) |
| Revision | 0.1 |
| Status | **Deprecated 2026-11-18** - engineering notes, not a specification; carries no requirements |
| Date | 2026-11-18 |
| Companion documents | None. Superseded by [RPN-ICD](ICD.md), sections 8 to 11 |

| Revision | Change history |
|---|---|
| 0.1 | Initial repository draft (2026-11-16): console electrical capability baseline, signal-channel counts and aggregate resource requirements. |
| 0.1 (2026-11-18) | Deprecated by the owner's answer to REVIEW-001 RR-001-008: no longer an individual document; useful content merged into the ICD; duplicate history table removed. |

> **Deprecation notice.** This file was added without applying the project
> standards (identifiers, classification, provenance, precedence). It is kept
> only as engineering notes for the history of the ICD content. Its `shall`
> statements are **not requirements**. Where it conflicts with the SRS, ICD, SAD or
> PS, those documents take precedence. Nothing here is approved for wiring.
>
> Known differences from the current ICD (do not rely on this file):
>
> - the notes size N64, GameCube, Dreamcast and Xbox for four ports; the project
>   scope is two emulated ports (`SRS-SYS-009`);
> - the notes treat Saturn TL as a static bias and count 6 channels per port;
>   the ICD counts 7 (TL is an output) and recomputes the totals;
> - the notes require every channel to support 3.3 V and 5 V push-pull, open-drain
>   and high-impedance at runtime; the ICD makes voltage domain and drive type a
>   hardware property of each console connector module (`ICD-CAP-004`) and forbids
>   reliance on MCU 5 V tolerance or internal pulls (`SRS-HW-006`);
> - the power table values are unverified secondary leads (`ICD-REF-001`).
>
> **Where the content went**
>
> | Former content | Now in |
> |---|---|
> | Sections 1-3, 9 (purpose, scope, architecture, constraints) | `ICD-CAP-001..012` and `ICD-CAP-017` |
> | Sections 4-5 (capabilities, channel definition) | `ICD-CAP-003..009` |
> | Sections 6-7 (console tables, aggregate resources) | ICD section 8.2 and 8.3 (two-port, corrected) |
> | Section 8 (power domains) | ICD section 8.5 and `ICD-PWR-002` |
> | Section 10 (`EIC-VER-001..014`, retired) | `ICD-VER-001..014`, plus `ICD-VER-015..020` |
> | Section 11 (open items) | ICD-CON-001 supplements and `ICD-QUAL-001` |
> | Section 12 (references) | `ICD-REF-001` |

The remainder of this file is the original text, unchanged except for the removal
of its duplicate revision-history block.

## 1. Purpose and interpretation

This document defines the electrical interface capabilities and minimum hardware resources required by RPN console adapters. It is a companion to [RPN-ICD](ICD.md) and is intended to capture the common electrical envelope that each console profile must satisfy before an adapter is considered implementation-ready.

The objective is to establish a common adapter architecture that supports the defined console scope without requiring a change to the RPN internal logic voltage domain. The specification defines:

- supported electrical signalling capabilities;
- required voltage domains;
- digital signal channel characteristics;
- minimum signal channel quantities;
- console-specific aggregate resource requirements;
- power interface requirements; and
- electrical protection requirements.

In these documents, `shall` denotes a requirement, `should` denotes a recommendation and `may` denotes permission. This draft is intentionally a baseline for engineering review and not a validated hardware release gate.

## 2. Scope

### 2.1 Supported consoles

The initial hardware scope covers the following consoles:

| Manufacturer | Console | Physical controller ports |
|---|---|---:|
| Nintendo | NES | 2 |
| Nintendo | SNES | 2 |
| Nintendo | Nintendo 64 | 4 |
| Nintendo | GameCube | 4 |
| Sega | Mega Drive | 2 |
| Sega | Saturn | 2 |
| Sega | Dreamcast | 4 |
| Sony | PlayStation 1 | 2 |
| Sony | PlayStation 2 | 2 |
| Microsoft | Original Xbox | 4 |

### 2.2 Functional scope

The electrical interface shall support standard controller emulation for the listed consoles.

The following items are excluded from the initial requirement baseline:

- analogue electrical input and output interfaces;
- video synchronisation signal processing;
- light guns and other specialist peripherals;
- non-standard accessory signals requiring additional connector pins;
- physical vibration motor drive circuitry;
- general digital communication protocols beyond the electrical boundary defined here.

Digital communication protocols, including USB and console-specific serial protocols, are specified separately in the relevant protocol or profile documents.

## 3. Electrical architecture

### 3.1 Internal logic domain

All RPN internal digital electronics shall operate using a 3.3 V logic domain.

Console-facing electrical interfaces shall provide the necessary adaptation between the internal logic domain and the target console electrical characteristics.

Console-facing signals shall not be connected directly to RPN MCU GPIO unless electrical compatibility has been established and documented for that profile.

### 3.2 Interface architecture

The electrical interface shall be divided into the following layers:

1. internal RPN logic domain;
2. digital signal conditioning and level translation;
3. console-specific connector interface; and
4. port power management and protection.

The electrical interface shall remain independent of the console-specific communication protocol implementation.

## 4. Required electrical capabilities

### 4.1 Digital input

Each configurable digital channel shall support:

- 3.3 V logic input tolerance;
- 5 V logic input tolerance;
- defined input thresholds;
- high-impedance input operation;
- configurable pull-up and pull-down resistors; and
- ESD and overvoltage protection.

### 4.2 Digital output

Each configurable digital channel shall support:

- 3.3 V push-pull output;
- 5 V push-pull output;
- open-drain output operation;
- high-impedance output state; and
- configurable output enable.

The selected output voltage shall be appropriate for the target console interface.

### 4.3 Bidirectional signalling

The interface shall support bidirectional digital communication.

Requirements include:

- independent direction control;
- half-duplex communication;
- open-drain bidirectional signalling;
- prevention of bus contention;
- deterministic direction switching; and
- high-impedance operation when not driving the bus.

### 4.4 USB interface

The interface shall support USB 1.1 full-speed device operation for Original Xbox compatibility.

Requirements include:

- USB differential D+ and D- signalling;
- USB device physical-layer interface;
- independent USB device connection for each physical console port; and
- appropriate USB signal protection.

USB protocol implementation and Xbox XID emulation are outside the scope of this document.

### 4.5 Power interface

The electrical interface shall accommodate the power requirements of the target console connector.

Requirements include:

- appropriate voltage-domain separation;
- protected power distribution;
- reverse-current protection where applicable;
- overcurrent protection;
- power sequencing and safe startup; and
- current monitoring where applicable.

Console-provided power rails shall not be connected directly to the internal 3.3 V logic supply.

### 4.6 Electrical protection

All externally accessible console-facing signals shall provide appropriate protection against:

- electrostatic discharge;
- accidental short circuits;
- overvoltage;
- unintended current injection; and
- power sequencing and back-powering conditions.

Protection circuitry shall not compromise the signal timing or electrical characteristics required by the target console.

## 5. Configurable digital signal channel

### 5.1 Definition

A configurable digital signal channel is an independently controlled electrical signal path between the RPN logic domain and a console-facing signal.

Each channel shall support the following operating states:

| Mode | Description |
|---|---|
| Input | Receives a console-generated digital signal |
| Push-pull output | Drives a digital signal |
| Open-drain output | Actively drives LOW or releases the line |
| High impedance | Electrically disconnects the output driver |

### 5.2 Voltage compatibility

Each channel shall accommodate the following logic domains:

- 3.3 V;
- 5 V.

The implementation may use separate input and output circuits or configurable level translation, provided all required operating modes are supported.

### 5.3 Channel independence

Each channel shall be independently configurable.

The configuration of one channel shall not constrain the direction or operating mode of another channel.

### 5.4 Channel quantity

The minimum number of configurable digital channels shall be determined by the requirements of the target console and shall include all simultaneously required digital signals for standard controller operation.

## 6. Console-specific signal requirements

Signal directions are defined relative to the RPN adapter:

- Input: signal generated by the console and received by RPN;
- Output: signal generated by RPN and received by the console;
- Bidirectional: shared signal line driven by either side.

### 6.1 NES

Standard NES controller interface.

| Signal | Direction | Electrical mode |
|---|---|---|
| Clock | Input | Digital |
| Latch | Input | Digital |
| Data | Output | Digital |

Per-port requirement:

- 2 digital inputs;
- 1 digital output;
- 3 configurable channels.

Adapter aggregate requirement for two ports:

- 4 digital inputs;
- 2 digital outputs;
- 6 configurable channels.

Additional accessory signals are excluded.

### 6.2 SNES

Standard SNES controller interface.

| Signal | Direction | Electrical mode |
|---|---|---|
| Clock | Input | Digital |
| Latch | Input | Digital |
| Data | Output | Digital |

Per-port requirement:

- 2 digital inputs;
- 1 digital output;
- 3 configurable channels.

Adapter aggregate requirement for two ports:

- 4 digital inputs;
- 2 digital outputs;
- 6 configurable channels.

`Data2` and `IOBit` accessory functionality are excluded.

### 6.3 Mega Drive

Six-button controller interface.

| Signal | Direction | Electrical mode |
|---|---|---|
| Up | Output | Digital |
| Down | Output | Digital |
| Left | Output | Digital |
| Right | Output | Digital |
| TL | Output | Digital |
| TR | Output | Digital |
| TH | Input | Digital |

Per-port requirement:

- 1 digital input;
- 6 digital outputs;
- 7 configurable channels.

Adapter aggregate requirement for two ports:

- 2 digital inputs;
- 12 digital outputs;
- 14 configurable channels.

The six-button controller mode is mandatory. Three-button compatibility shall be provided through the same interface.

### 6.4 Saturn

Standard digital controller interface.

| Signal | Direction | Electrical mode |
|---|---|---|
| D0 | Output | Digital |
| D1 | Output | Digital |
| D2 | Output | Digital |
| D3 | Output | Digital |
| TH | Input | Digital |
| TR | Input | Digital |

Per-port requirement:

- 2 digital inputs;
- 4 digital outputs;
- 6 configurable channels.

Adapter aggregate requirement for two ports:

- 4 digital inputs;
- 8 digital outputs;
- 12 configurable channels.

The TL signal shall be accommodated through an appropriate static electrical bias where required. Saturn 3D Control Pad support is in scope for the initial adapter baseline and shall be supported through the same controller interface.

### 6.5 Nintendo 64

Nintendo 64 controller interface.

| Signal | Direction | Electrical mode |
|---|---|---|
| Data | Bidirectional | Open-drain |

Per-port requirement:

- 1 bidirectional channel;
- 1 configurable channel.

Adapter aggregate requirement for four ports:

- 4 bidirectional channels;
- 4 configurable channels.

The interface shall support 3.3 V open-drain signalling.

### 6.6 GameCube

GameCube controller interface.

| Signal | Direction | Electrical mode |
|---|---|---|
| Data | Bidirectional | Open-drain |

Per-port requirement:

- 1 bidirectional channel;
- 1 configurable channel.

Adapter aggregate requirement for four ports:

- 4 bidirectional channels;
- 4 configurable channels.

The interface shall support 3.3 V open-drain signalling.

### 6.7 Dreamcast

Maple bus controller interface.

| Signal | Direction | Electrical mode |
|---|---|---|
| SDCKA | Bidirectional | Digital |
| SDCKB | Bidirectional | Digital |

Per-port requirement:

- 2 bidirectional channels;
- 2 configurable channels.

Adapter aggregate requirement for four ports:

- 8 bidirectional channels;
- 8 configurable channels.

The interface shall support 3.3 V signalling. Controller-detection and connector-presence requirements shall be covered in the specific Dreamcast profile documentation.

### 6.8 PlayStation 1

| Signal | Direction | Electrical mode |
|---|---|---|
| CMD | Input | Digital |
| ATT | Input | Digital |
| CLK | Input | Digital |
| DATA | Output | Open-drain |
| ACK | Output | Open-drain |

Per-port requirement:

- 3 digital inputs;
- 2 open-drain outputs;
- 5 configurable channels.

Adapter aggregate requirement for two ports:

- 6 digital inputs;
- 4 open-drain outputs;
- 10 configurable channels.

### 6.9 PlayStation 2

The standard PlayStation 2 controller interface uses the same signal arrangement as PlayStation 1.

Per-port requirement:

- 3 digital inputs;
- 2 open-drain outputs;
- 5 configurable channels.

Adapter aggregate requirement for two ports:

- 6 digital inputs;
- 4 open-drain outputs;
- 10 configurable channels.

### 6.10 Original Xbox

The Original Xbox controller interface uses USB-derived differential signalling.

Per-port requirement:

- 1 USB full-speed device interface;
- 1 differential D+/D- pair.

Adapter aggregate requirement for four ports:

- 4 independent USB full-speed device interfaces;
- 4 differential D+/D- pairs.

The additional video synchronisation connector signal is excluded.

## 7. Aggregate hardware resource requirements

The following table defines the minimum digital signal resources required by each complete console adapter instance.

| Console | Ports | Inputs | Outputs | Bidirectional | Total configurable channels |
|---|---:|---:|---:|---:|---:|
| NES | 2 | 4 | 2 | 0 | 6 |
| SNES | 2 | 4 | 2 | 0 | 6 |
| Mega Drive | 2 | 2 | 12 | 0 | 14 |
| Saturn | 2 | 4 | 8 | 0 | 12 |
| Nintendo 64 | 4 | 0 | 0 | 4 | 4 |
| GameCube | 4 | 0 | 0 | 4 | 4 |
| Dreamcast | 4 | 0 | 0 | 8 | 8 |
| PlayStation 1 | 2 | 6 | 4 | 0 | 10 |
| PlayStation 2 | 2 | 6 | 4 | 0 | 10 |
| Original Xbox | 4 | USB | USB | USB | 4 USB interfaces |

The input/output counts represent logical signal directions, not separate physical input and output circuits. Bidirectional channels are counted once. The Original Xbox resource count is independent of the configurable digital channel count.

### 7.1 Common configurable channel capability

All configurable digital channels shall support the capabilities defined in Section 5.

The maximum requirement among the supported consoles is 14 channels, corresponding to the two-port Mega Drive adapter.

### 7.2 USB resource requirement

The Original Xbox adapter shall provide four independent USB device-facing physical interfaces.

A shared USB controller implementation may be considered only if it can support four independent physical USB connections and simultaneous device operation. A single USB transceiver shared between physical ports is not sufficient.

## 8. Power domain requirements

The console adapter shall accommodate the relevant connector power rails.

| Console | Connector power characteristics |
|---|---|
| NES | 5 V |
| SNES | 5 V |
| Mega Drive | 5 V |
| Saturn | 5 V |
| Nintendo 64 | 3.3 V |
| GameCube | 5 V and approximately 3.43 V |
| Dreamcast | 5 V |
| PlayStation 1 | approximately 3.5 V logic and 7.5 V motor supply |
| PlayStation 2 | approximately 3.5 V logic and 7.5 V motor supply |
| Original Xbox | 5 V USB VBUS |

The power architecture shall distinguish between:

- console-provided power;
- RPN internal logic power;
- signal pull-up supplies; and
- peripheral or motor power.

The PlayStation motor supply is not required for the initial controller emulation baseline. The Xbox video synchronisation signal and PlayStation motor supply shall not introduce additional mandatory signal channels.

Exact current budgets, regulator requirements and power-source selection shall be established in the detailed hardware design.

## 9. Design constraints

The following constraints shall apply:

1. RPN internal logic shall remain 3.3 V based.
2. Console-facing voltage adaptation shall be implemented at the electrical interface boundary.
3. All configurable channels shall support high-impedance operation.
4. Output drivers shall default to high impedance during reset and initialisation.
5. No channel shall expose internal MCU GPIO directly to an incompatible console voltage domain.
6. Bidirectional interfaces shall prevent simultaneous conflicting drive conditions.
7. Console-specific electrical requirements shall not be assumed interchangeable merely because they share a nominal voltage.
8. Protection circuitry shall be selected according to the actual signalling characteristics of each interface.
9. The electrical interface shall remain independent of the RPN network protocol.

## 10. Verification requirements

The following verification activities shall be performed:

| ID | Verification activity |
|---|---|
| EIC-VER-001 | Verify 3.3 V input compatibility |
| EIC-VER-002 | Verify 5 V input compatibility |
| EIC-VER-003 | Verify 3.3 V push-pull output levels |
| EIC-VER-004 | Verify 5 V push-pull output levels |
| EIC-VER-005 | Verify open-drain operation |
| EIC-VER-006 | Verify high-impedance state |
| EIC-VER-007 | Verify independent channel direction control |
| EIC-VER-008 | Verify bidirectional bus operation |
| EIC-VER-009 | Verify absence of bus contention |
| EIC-VER-010 | Verify USB full-speed operation on all four Xbox ports |
| EIC-VER-011 | Verify power sequencing and back-power prevention |
| EIC-VER-012 | Verify ESD and overvoltage protection |
| EIC-VER-013 | Verify port power current limiting |
| EIC-VER-014 | Verify operation under simultaneous port activity |

Verification shall include electrical measurements and functional testing against representative console hardware.

## 11. Open design items

The following items remain unresolved and shall be addressed during detailed hardware design:

- selection of specific level-shifting components;
- implementation of independently configurable voltage domains;
- exact pull-up and pull-down resistor values;
- exact logic thresholds and output drive requirements;
- port power source selection;
- port power current budgets;
- Dreamcast presence detection implementation;
- USB physical-layer implementation and controller resource allocation;
- detailed ESD protection selection; and
- PCB partitioning between common and console-specific circuitry.

## 12. References

1. NESdev Wiki — Controller port pinout: <https://www.nesdev.org/wiki/Controller_port_pinout>
2. Super Famicom Development Wiki — Schematics, Ports, and Pinouts: <https://wiki.superfamicom.org/schematics-ports-and-pinouts>
3. AllPinouts — Sega Genesis joystick controller: <https://allpinouts.org/pinouts/connectors/videogame/sega-genesis-joystick-controller/>
4. ConsoleMods — Saturn connector pinouts: <https://consolemods.org/wiki/Saturn:Connector_Pinouts>
5. ConsoleMods — N64 connector pinouts: <https://consolemods.org/wiki/N64:Connector_Pinouts>
6. OpenCores — GameCube controller electrical interface: <https://opencores.org/usercontent/doc/1250716915>
7. Dreamcast Wiki — Maple bus: <https://dreamcast.wiki/Maple_bus>
8. AllPinouts — Sony PlayStation controller port: <https://allpinouts.org/pinouts/connectors/input_device/sony-playstation-controller-port/>
9. Microsoft — Original Xbox Hardware Design Specification: <https://consolemods.org/wiki/images/a/ae/Xbox_Hardware_Design_Specification_1.02.pdf>
10. XboxDevWiki — Xbox Input Devices: <https://xboxdevwiki.net/Xbox_Input_Devices>
