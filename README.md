# retro-peripheral-network
A universal control interface for retro consoles, translating modern input devices into authentic console peripherals through modular adapters and a shared network.

## Specifications

All specifications are **Revision 0.2, Baseline for review**. The wire protocol is
version 1.0.

| Document | ID | Purpose |
|---|---|---|
| [System Requirements Specification](docs/SRS.md) | RPN-SRS | Required behaviour and verification criteria |
| [Interface Control Document](docs/ICD.md) | RPN-ICD | Electrical, physical and hardware boundaries, the console capability baseline and one annex per console |
| [Software Architecture Description](docs/SAD.md) | RPN-SAD | Components, design decisions, scheduling, ownership and lifecycle |
| [Protocol Specification](docs/PS.md) | RPN-PS | Shared-bus wire protocol and its message vectors |
| [Adapter Framework Specification](docs/AFS.md) | RPN-AFS | Reusable adapter software framework and console-driver contracts |

Start with the [design rationale](docs/SAD.md#2-design-rationale) and the
[design decisions](docs/SAD.md#3-design-decisions). Requirements are classified as
functional (F) or derived (D) in [SRS section 1](docs/SRS.md#1-purpose-and-interpretation).

### Document control

Every change to a specification updates its revision field when the revision changes,
its date, and adds one row to its change-history table describing the change; companion
lists and the tables of this README are kept consistent, and the PDFs are regenerated.
Withdrawn identifiers are listed in [SRS section 1](docs/SRS.md#1-purpose-and-interpretation)
and never reused.

### PDF editions

Formatted PDFs of the five specifications live in [docs/pdf/](docs/pdf/): one file per
document plus [RPN-specification-set.pdf](docs/pdf/RPN-specification-set.pdf), which
combines all five with a shared contents page. Links between the individual PDFs open the
sibling files; links in the combined set stay inside it. The Markdown files remain the
source of truth.

After editing a specification, regenerate and commit the PDFs:

```sh
tools/pdf/build-pdf.sh
```

The build needs [pandoc](https://pandoc.org/) and [Typst](https://typst.app/)
(tested with pandoc 3.7 and Typst 0.15). It uses only the fonts bundled with
Typst, so the output is the same on every machine.

## Review process

This document is not an engineering specification.

| Document | ID | Purpose |
|---|---|---|
| [Specification review process](docs/REVIEW-PROCESS.md) | RPN-RVP | Repeatable review method, roles and correction cycle |

## Licence

The specifications and other documentation are licensed under CC BY 4.0 and the tools
under the MIT licence; see [LICENSE](LICENSE).
