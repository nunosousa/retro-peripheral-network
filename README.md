# retro-peripheral-network
A universal control interface for retro consoles, translating modern input devices into authentic console peripherals through modular adapters and a shared network.

## Architecture drafts

See the [development process guide](docs/DEVELOPMENT-GUIDE.md) for the path from
reviewing these drafts to a measured two-player prototype and later expansion.

The project is in architecture exploration. All specifications are **Revision
0.1, Draft**; the proposed hardware and protocol are not implementation-ready.

| Document | ID | Purpose |
|---|---|---|
| [System Requirements Specification](docs/SRS.md) | RPN-SRS | Required behaviour and verification criteria |
| [Interface Control Document](docs/ICD.md) | RPN-ICD | Electrical, physical and hardware boundaries |
| [Software Architecture Description](docs/SAD.md) | RPN-SAD | Components, scheduling, ownership and lifecycle |
| [Protocol Specification](docs/PS.md) | RPN-PS | Provisional shared-bus wire protocol |

Start with the [architecture review](docs/SAD.md#2-initial-architecture-review)
and [decision register](docs/SAD.md#3-decision-register). Confirmed requirements,
derived requirements, provisional proposals, open questions and future scope
are explicitly distinguished. Console electrical profiles, connector selection
and measured timing remain release gates, not implicit implementation choices.
