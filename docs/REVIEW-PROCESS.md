# RPN specification review process

| Control field | Value |
|---|---|
| Document ID | RPN-RVP |
| Revision | 0.1 |
| Status | Working process document - not an engineering specification |
| Date | 2026-11-18 |
| Applies to | [SRS](SRS.md), [ICD](ICD.md), [SAD](SAD.md), [PS](PS.md), [development guide](DEVELOPMENT-GUIDE.md) and [README](../README.md) (the [EIC](EIC.md) was deprecated on 2026-11-18 and is no longer reviewed as a specification) |
| First applied in | [REVIEW-001](reviews/REVIEW-001.md) |

This guide makes a system-requirements review repeatable. It does not change any
requirement or any specification's revision status. It supports Steps 1-2 of the
[development guide](DEVELOPMENT-GUIDE.md) and should be repeated whenever the
specifications change materially (see section 9).

## 1. Objectives

A review shall establish, with evidence, whether the document set is:

| ID | Objective | Question the review answers |
|---|---|---|
| RVO-1 | Consistent | Do all documents agree on definitions, numbers, names, scope and ownership of each fact? |
| RVO-2 | Complete | Is every stated need traceable to a requirement, a design element and a planned verification? Is anything essential missing? |
| RVO-3 | Correct | Are the numbers, formats and technical claims right when independently recomputed or checked against primary sources? |
| RVO-4 | Coherent protocol | Do framing, transactions, lifecycle, timing and ownership behave consistently, including under loss, reset and retry? |
| RVO-5 | Electrically safe and plausible | Can each electrical interface be built without damaging original hardware or breaking console timing? |
| RVO-6 | Console-faithful | Does the generic input/feedback model cover what each target console's controllers actually expose? |
| RVO-7 | Platform-consistent | Do all documents follow the platform decision (currently the RP2350 family) and its real capabilities and errata? |
| RVO-8 | Feasible | Do timing, resource and power budgets close with margin for the first prototype and the wider roadmap? |
| RVO-9 | Verifiable | Does each requirement have an observable pass/fail method, and is it linked to a verification entry? |
| RVO-10 | Controlled | Are document control, IDs, classification, companion lists and decision registers coherent and current? |

A review is **not** a redesign. The reviewer raises remarks; the owner decides;
the documents are changed in a separate correction cycle (section 8).

## 2. Roles

| Role | Responsibility |
|---|---|
| Reviewer | Performs the review, raises remarks, proposes solutions, does **not** edit the reviewed specifications during the review |
| Owner | Answers every remark (accept / modify / reject / defer) and approves maturity changes |
| Corrector | Applies owner-approved answers in the next cycle; may be the same person or agent as the reviewer, but only after the owner's responses exist |

## 3. Inputs and entry criteria

Inputs: all documents in the applicable-to list above at a recorded git commit;
owner-stated constraints since the previous review (for example platform
standardisation); the previous review's disposition table, if any.

Entry criteria:

1. Working tree clean or the reviewed commit/diff recorded in the review header.
2. Owner constraints for this cycle written down in the review's section 1.
3. Previous review's remarks all have a recorded disposition (or are explicitly
   carried forward).

## 4. Review method

Perform the phases in order. Record each finding immediately as a draft remark.

### Phase 1 - Baseline inventory

- List every document, its ID, revision, status, date and companion list.
- Record the commit hash, files and size reviewed.
- List the owner constraints and check each against every document (grep for the
  affected term, for example the MCU name).

### Phase 2 - Mechanical consistency checks

Run these checks; they are cheap and catch cost-effective errors early.

| Check | How |
|---|---|
| Links and anchors | Every Markdown link target and `#anchor` resolves (a small script slugifying headings is sufficient) |
| Companion lists | Every document lists every other applicable document, and the README table matches |
| Document control | Revision, status, date and change history updated when a document body or links changed; no duplicate history blocks |
| Identifiers | Every ID referenced is defined exactly once; retired IDs are not reused; each ID prefix is declared in the SRS identifier rule |
| Terminology | One term per concept (player, port, route, endpoint, channel, node, adapter); consistent product and spelling variants |
| Stale statements | Text that refers to a previous document count, a previous platform or a previous scope |
| Classification | Every normative statement carries C/D/P/O/F or is in a document that states how its `shall` statements are classified |

### Phase 3 - Traceability

Build (or update) the matrix: owner intent -> SRS requirement -> design element
(SAD/PS/ICD) -> verification entry. Flag:

- requirements with no verification entry or a verification with no method;
- design elements with no requirement (orphan design) and vice versa;
- requirements whose acceptance criterion is not measurable;
- verification IDs in one document (for example `ICD-VER-*`) absent from the SRS matrix.

### Phase 4 - Numerical recomputation

Recompute, do not trust, every derived number. Keep the scripts in the review
record or reference them. At a minimum:

- field offsets and sizes in every message; payload, raw and wire lengths; maximum
  frame time at the line rate;
- CRC check value and every golden vector; COBS (or other framing) vectors,
  recomputed independently of the text;
- exchange durations, slot budgets and worst-case timeout paths against the
  scheduling cadence (include the slowest *non-input* exchange);
- clock-drift and lease/guard arithmetic, with the direction of the error
  considered for each side;
- counter-exhaustion horizons;
- electrical channel, port, GPIO, PIO state-machine, USB-controller and power budgets
  per console and for the sum of simultaneously active ports.

### Phase 5 - Protocol coherence walk-through

Take each lifecycle and walk it message by message against the state machines,
asking what happens if any message or response is lost, duplicated, delayed,
reordered, or if either side resets at that point. Minimum scenarios:

1. Cold start: hub boot guard, commissioning, HELLO, capability read.
2. Route configure, arm, live input, lease renewal.
3. Ownership transfer with acknowledged and with lost revoke.
4. Hub reboot with live adapter; adapter reboot with live hub.
5. Duplicate, stale-generation, stale-session and conflicting-ID requests.
6. Persistent operation (storage/config/update) with lost acknowledgement.
7. Feedback event delivery, retry and expiry.
8. Fault paths: bus loss, malformed frames, queue overflow, watchdog.

For each, check that every state, status code and field used is defined, that
direct contradictions between sentences are absent, and that each timeout has an
owner and a recovery.

### Phase 6 - Electrical and console-interface review

For every console in scope, and for the hub and bus, check:

| Topic | Check |
|---|---|
| Signals | Complete signal list per port: direction, driver type, voltage, who owns the pull-up, who may drive; nothing omitted (selects, handshakes, presence/sense, power-sense) |
| Voltage domains | Thresholds, abs-max, 5 V tolerance conditions and unpowered behaviour of both the console and the adapter parts |
| Dynamics | Bit rates, edge rates, propagation-delay and skew limits, capacitive load; compatibility of the chosen translator class with open-drain bidirectional lines |
| Power | Rails offered by the connector, available current, back-power paths, isolation and ground-loop exposure, sequencing, hot-plug |
| Protocol facts | Peripheral identification, polling cadence, handshake direction, accessory behaviour needed for the claimed controller modes |
| Resources | GPIO, PIO state machines, DMA, interrupts, USB controllers, memory per console and for all simultaneously active ports on the chosen MCU |
| Safety | Default high-impedance, fail-safe, ESD, short circuit, reverse connection, no common supply tie |
| Provenance | Every electrical value traces to a primary source (datasheet, console service manual, measurement) with revision and retrieval date; community wikis are leads, not evidence |

### Phase 7 - Console input and peripheral coverage

Build a matrix of every button, axis, trigger and feedback element of every
target controller mode against the generic input model. Flag controls with no
generic representation, many-to-one reductions, analog/digital mismatches and
pressure-sensitive controls. Confirm what USB input device classes are accepted.

### Phase 8 - Platform review

Check every statement about the MCU family against its current datasheet and
errata: pin count and variants, PIO and DMA resources, USB controller count and
modes, GPIO voltage tolerance, flash/XIP behaviour, security/boot features,
unique-ID and random-number facilities, clock accuracy. Record the datasheet and
errata revision consulted.

### Phase 9 - Completeness sweep

Look for what is missing: requirements for user interaction, configuration
persistence, environment/EMC/safety, installation and cable limits, end-to-end
latency, availability and recovery, test equipment, provenance and licensing.

## 5. Remark format

Every remark has a unique ID `RR-<review number>-<sequence>` (for example
`RR-001-007`), never reused. Each contains:

| Field | Content |
|---|---|
| ID | `RR-nnn-ss` |
| Title | One-line subject |
| Locations | Document ID and section/ID for every place involved |
| Category | **Correction** (contradiction or error), **Decision** (owner must choose), **Question** (evidence needed), **Future** (valid but out of current increment) - the categories already used in the development guide |
| Severity | See section 6 |
| Gate | The earliest step/gate this remark blocks (for example "Step 4: before connecting hardware") |
| Remark | Stated as a question where possible, with the evidence that prompted it |
| Suggested solution | The reviewer's proposal; may list options with a recommendation |
| Owner response | Left empty by the reviewer: Accept / Modify / Reject / Defer, with the owner's answer |
| Resolution | Filled in the correction cycle: change made and where |

## 6. Severity definitions

| Severity | Meaning |
|---|---|
| S1 Blocker | Could damage original hardware, break a safety/ownership invariant, or invalidate a major architectural choice if not resolved; must be closed before the gate named |
| S2 Major | Contradiction or gap that will cause rework or a wrong implementation; close before the affected design work starts |
| S3 Minor | Ambiguity, incomplete detail or traceability gap with a bounded cost |
| S4 Editorial | Wording, naming, formatting, document control |

## 7. Outputs

1. A dated review record `docs/reviews/REVIEW-<nnn>.md` with: header (commit, scope,
   owner constraints), summary and counts, items **verified without remark**,
   all remarks in section 5 format, a disposition table, and a checklist coverage
   statement (which phases ran and any not performed, with reason).
2. Any scripts or recomputation used, either inline or referenced.
3. Updates to this process document if the method itself changed.

The review record is an artifact, not a specification. It does not carry
requirements; accepted answers are incorporated into the specifications in the
correction cycle.

## 8. Correction cycle

1. The owner answers every remark in its *Owner response* field (silence is not
   acceptance; unanswered remarks stay open).
2. The corrector applies accepted/modified responses to the specifications:
   - preserve stable IDs, retire rather than reuse them, and keep the revision
     unless the owner approves a maturity change;
   - make each decision once, in its authoritative document, and cross-reference it
     elsewhere;
   - add or update the SAD decision register for every new decision;
   - update document control (date, change history, companion lists, README).
3. The corrector fills in *Resolution* for each remark and lists any remark it
   could not apply, with the reason.
4. Rejected remarks keep the owner's rationale; deferred remarks are copied to the
   decision register or a future-scope entry with the gate they block.

## 9. Re-review and exit criteria

Re-review (a shorter pass) after each correction cycle, and a full review when any
of the following occurs: a platform/silicon change, adding a console or a service,
a protocol major/minor change, a measurement contradicting a document, or before
each development-guide checkpoint that connects hardware.

For the re-review:

- verify every resolution against the changed text (closure check);
- re-run Phase 2 and Phase 4 in full (regressions are most likely in mechanical
  and numerical facts);
- review only the changed areas for Phases 5-9, plus anything that depends on them.

Exit criteria for a review cycle:

- no S1 remark open for the next gate;
- no unanswered remark;
- every deferred remark has an owner, a gate and a register entry;
- mechanical checks (Phase 2) and recomputation (Phase 4) pass.

## Appendix A - Review record template

```markdown
# Review record REVIEW-nnn
| Field | Value |
|---|---|
| Date | |
| Reviewer | |
| Reviewed commit | |
| Documents and revisions | |
| Owner constraints this cycle | |
| Phases performed | |

## 1. Summary and counts (by severity and category)
## 2. Verified without remark
## 3. Remarks (grouped by theme; format per section 5 of RPN-RVP)
## 4. Disposition table (ID, owner decision, resolution, status)
## 5. Open gates carried forward
```

## Appendix B - Reference checks (starter scripts)

Frame check values (adapt to the framing in force):

```python
def crc32c(data):
    crc = 0xFFFFFFFF
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = (crc >> 1) ^ (0x82F63B78 if crc & 1 else 0)
    return crc ^ 0xFFFFFFFF

assert crc32c(b"123456789") == 0xE3069283

def cobs(data):
    out, idx, code = bytearray([0]), 0, 1
    for b in data:
        if b == 0:
            out[idx] = code; idx = len(out); out.append(0); code = 1
        else:
            out.append(b); code += 1
            if code == 0xFF:
                out[idx] = code; idx = len(out); out.append(0); code = 1
    out[idx] = code
    return bytes(out)
```

Slot-budget identities to recompute when timing changes (1 Mbit/s, 10 us/byte):
wire bytes = raw + ceil(raw / 254) + 1 delimiter; exchange time = request wire +
latest response start + response wire + idle guard; timeout path = request wire +
response timeout + idle guard. Compare every non-input timeout path with
`cadence - worst-case input exchange`.
