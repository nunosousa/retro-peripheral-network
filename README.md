# retro-peripheral-network
A universal control interface for retro consoles, translating modern input devices into authentic console peripherals through modular adapters and a shared network.

## Architecture drafts

The project is in architecture exploration. All specifications are **Revision
0.1, Draft**; the proposed hardware and protocol are not implementation-ready.

| Document | ID | Purpose |
|---|---|---|
| [System Requirements Specification](docs/SRS.md) | RPN-SRS | Required behaviour and verification criteria |
| [Interface Control Document](docs/ICD.md) | RPN-ICD | Electrical, physical and hardware boundaries, including the console capability baseline |
| [Software Architecture Description](docs/SAD.md) | RPN-SAD | Components, scheduling, ownership and lifecycle |
| [Protocol Specification](docs/PS.md) | RPN-PS | Provisional shared-bus wire protocol |

Start with the [architecture review](docs/SAD.md#2-initial-architecture-review)
and [decision register](docs/SAD.md#3-decision-register). Confirmed requirements,
derived requirements, provisional proposals, open questions and future scope
are explicitly distinguished. Console electrical profiles, connector selection
and measured timing remain release gates, not implicit implementation choices.

### PDF editions

Formatted PDFs of the four specifications live in [docs/pdf/](docs/pdf/): one
file per document plus [RPN-specification-set.pdf](docs/pdf/RPN-specification-set.pdf),
which combines all four with a shared contents page. Links between the
individual PDFs open the sibling files; links in the combined set stay inside
it. The Markdown files remain the source of truth.

After editing a specification, regenerate and commit the PDFs:

```sh
tools/pdf/build-pdf.sh
```

The build needs [pandoc](https://pandoc.org/) and [Typst](https://typst.app/)
(tested with pandoc 3.7 and Typst 0.15). It uses only the fonts bundled with
Typst, so the output is the same on every machine.

## Process and review

These documents are not engineering specifications.

| Document | ID | Purpose |
|---|---|---|
| [Development process guide](docs/DEVELOPMENT-GUIDE.md) | - | The path from reviewing the drafts to a measured two-player prototype and later expansion |
| [Specification review process](docs/REVIEW-PROCESS.md) | RPN-RVP | Repeatable review method, roles and correction cycle |
| [Review record REVIEW-001](docs/reviews/REVIEW-001.md) | REVIEW-001 | Latest review: remarks, owner dispositions and resolutions |

The former [Electrical Interface Capability Specification](docs/EIC.md) is
deprecated engineering notes; its useful content now lives in the ICD.
