# Protocol Specification

| Control field | Value |
|---|---|
| Document ID | RPN-PS |
| Revision | 0.1 |
| Status | Draft - provisional profile, not interoperability validated |
| Date | 2026-11-18 |
| Companion documents | [RPN-SRS](SRS.md), [RPN-ICD](ICD.md), [RPN-SAD](SAD.md) |

| Revision | Change history |
|---|---|
| 0.1 | Initial bounded framing, commissioning, service schemas, two-player input and safe ownership transactions. |
| 0.1 (2026-11-18) | REVIEW-001 correction cycle: per-opcode response timeouts and cycle budget, feedback cadence, commissioning retry and ID rules, persisted address, hardware UID/RNG provisioning, CAPS kind 4 (`neutralisation_bound_us`) and bounded CAPS indexes, STATUS lifecycle/counter corrections, idle-identity check, Update marked Future. |
| 0.1 (2026-11-18, owner decision) | Line rate raised to 2 Mbit/s (trunk under 5 m): PS-TIMING bit time, timeout classes (short up to 140 wire bytes at 1.0 ms, long 1.5 ms), cycle budget and latency bounds recomputed; display service recorded as a proposed Future service (`PS-SVC-DISPLAY`) at lowest priority with adapter-declared chunk size. |

## 1. PS-PROFILE: scope and conventions

This is a concrete **provisional** wire profile for evaluation, not a declaration
that RS-485 or all service implementations are settled. Requirements and
electrical constraints are owned by [RPN-SRS](SRS.md) and [RPN-ICD](ICD.md).
Ownership policy is owned by `SAD-OWN-001`; this document owns its wire mechanism.

The draft wire version is major **0**, minor **1**, distinct from document
Revision 0.1. Multi-byte integers are little-endian, unsigned unless stated.
Byte strings have no terminator. All lengths count bytes. Reserved fields and
bits shall be sent zero and rejected if nonzero. Booleans are u8 values 0 or 1.
No implicit structure alignment/padding is permitted.

`u8/u16/u32/u64` denote fixed-width integers. `i16` is signed two's complement.
`bytes[n]` is exactly n octets. `count`-prefixed lists require exact total length.
Trailing bytes, duplicate list keys and out-of-range values are errors.

Initial limits:

| Element | Value |
|---|---|
| Hub address | 0 |
| Adapter addresses | 1..31 |
| Unassigned address | 254; only in targeted commissioning replies |
| Commissioning destination | 255; only DISCOVER_UID and ASSIGN_UID |
| Other addresses | Reserved; not valid sources/destinations |
| Players | 0, 1 |
| Ports | 0, 1 if advertised; not necessarily physical connector numbering |
| Routes per owner | 1..2; distinct players and ports; no fan-out |
| Payload maximum | 192 bytes |
| Outstanding requests | One on the entire bus |
| Live console owners | One |
| Ownership lease | Fixed 100 ms in this profile |

The hub is the sole request initiator. Adapters respond only to valid addressed
requests or commissioning requests matching their exact UID. There is no
unsolicited event frame, general broadcast input or broadcast arm/reset.

## 2. PS-FRAME: encoding and integrity

On the UART (`ICD-NET-001`), transmit:

```text
COBS(header || payload || crc32c) || 0x00
```

Use standard Consistent Overhead Byte Stuffing (COBS): each nonzero code byte
gives the distance to the next code, replacing intervening zero bytes; code
0xFF copies 254 nonzero bytes without inserting a zero. Empty data encodes as
`01`. The delimiter is not part of COBS data or CRC.

| Offset | Size | Field | Meaning |
|---|---|---|---|
| 0 | 1 | major | 0 |
| 1 | 1 | minor | 1, or selected negotiated minor |
| 2 | 1 | opcode | PS-MSG table |
| 3 | 1 | flags | Bit 0 RESPONSE; bits 1..7 zero |
| 4 | 1 | source | Request 0; response node address |
| 5 | 1 | destination | Request target; response 0 |
| 6 | 1 | status | Request 0; response PS-STATUS |
| 7 | 1 | reserved | Zero |
| 8 | 4 | transaction_id | Nonzero 1..0xFFFFFFFF, request/response correlation |
| 12 | 2 | payload_length | 0..192 |
| 14 | 8 | session_id | Nonzero hub session, except commissioning uses zero |
| 22 | payload_length | payload | Opcode-defined |
| 22 + payload_length | 4 | crc32c | Little-endian checksum |

CRC-32C (Castagnoli): reflected polynomial `0x82F63B78`, initial value
`0xFFFFFFFF`, reflect input/output as the conventional reflected algorithm,
final XOR `0xFFFFFFFF`. Calculate over header and payload, not COBS or the CRC
field. ASCII `123456789` shall produce numeric CRC `0xE3069283`, transmitted
`83 92 06 E3`. No second reflection is applied in a reflected implementation.

Decoded length is exactly `26 + payload_length`. Maximum raw length is 218,
maximum encoded length 219, maximum wire frame including delimiter 220 bytes.
Parser storage is bounded: discard until the next delimiter after oversize,
bad COBS or timeout. A delimiter with no preceding encoded bytes is ignored.
A partial encoded frame older than 3 ms since its first byte is discarded;
at 2 Mbit/s a maximum valid frame (1.10 ms) fits inside that interval with
margin. Noise with
no delimiter cannot grow buffers.

Bad COBS/CRC, impossible decoded length, wrong destination or invalid
source/response direction is silently discarded **on the wire**, with a
diagnostic counter increment. This prevents replies to corrupt or misaddressed
traffic. Valid addressed requests with unsupported opcode/schema/state receive
an explicit status. Unsupported major versions are discarded with a version
counter; discovery/HELLO timeouts expose incompatibility to the hub.

### PS-VECTOR-001: bootstrap codec checks

COBS-only examples (not including the delimiter): empty input -> `01`;
`00` -> `01 01`; `11 00 22` -> `02 11 02 22`.

STATUS request to node 1, transaction 1, session 1, empty payload:

```text
Decoded header and CRC (26 bytes):
00 01 05 00 00 01 00 00 01 00 00 00 00 00 01 00
00 00 00 00 00 00 bf d6 e9 97

COBS plus delimiter (28 bytes):
01 03 01 05 01 02 01 01 02 01 01 01 01 01 02 01
01 01 01 01 01 01 05 bf d6 e9 97 00
```

This is a framing vector; a real node first requires HELLO for session 1.
These calculated examples are not evidence of hardware interoperability.

## 3. PS-TRANSACTION: ordering, sessions and errors

Each response echoes opcode, transaction ID and session ID, sets RESPONSE and
returns to address 0. Reply payload schemas below apply only to status OK;
error replies have zero payload. A response from an unexpected node/session,
or not matching the outstanding exchange, is discarded and counted.

| PS-STATUS value | Name | Meaning |
|---|---|---|
| 0x00 | OK | Operation completed according to its response schema |
| 0x01 | UNSUPPORTED | Opcode, service or requested profile not implemented |
| 0x02 | BAD_LENGTH | Payload length inconsistent with schema |
| 0x03 | BAD_VALUE | Reserved bits, invalid enum/range or inconsistent values |
| 0x04 | BAD_STATE | Operation not permitted in current lifecycle |
| 0x05 | BUSY | No side effect; retry later with a new transaction |
| 0x06 | STALE_SESSION | Session not established |
| 0x07 | STALE_GENERATION | Route generation absent or different |
| 0x08 | INCOMPATIBLE | Capabilities/peripheral combination not compatible |
| 0x09 | IO_ERROR | Local operation failed; inspect status before proceeding |
| 0x0A | NOT_FOUND | UID/resource/profile/handle absent |
| 0x0B | NO_SPACE | Bounded storage/queue capacity exhausted |
| 0x0C | INTEGRITY | Staged object or image validation failed |
| 0x0D | RECOVERY_REQUIRED | Persistent state needs local recovery |
| 0x0E | CONFLICT | Reused transaction/object sequence with different content |

The hub generates a new nonzero, practically non-repeating 64-bit session at
boot and before transaction-ID exhaustion. The session ID is drawn from the
RP2350 hardware random number generator after a documented health check; if the
health check fails, a persistent session counter combined with the hub UID is
the fallback, and a timer or fixed boot value is never sufficient. The
implementation documents which source was used. IDs increase strictly within a session; no wrap. When 0xFFFFFFFF is
exhausted, release ownership, wait the guard, create a new session and HELLO
again. At 200 exchanges/s the 32-bit space lasts about 248 days (less with
additional traffic), avoiding a forced transition every few minutes. Rollover
is nevertheless a deliberate neutral transition, not silent wrap.
The hub shall start rollover before exhaustion, reserving IDs for revoke,
token queries/close and reset recovery. It shall not begin a management
operation whose profile-defined bounded completion/recovery transaction budget
exceeds the remaining ID space. Exhaustion is an explicit fault, not permission
to reuse an ID.

Each node retains its highest completed transaction ID and last response for
the current session. The ID, cache and conflict rules in this section apply to
sessions 1 and above; commissioning exchanges (session 0) use the separate
commissioning counter and retained exchange defined in `PS-DISCOVERY`. A retry uses the exact original bytes and ID. The same
ID and identical request returns the cached response without repeating side
effects or renewing a lease. Same ID with different bytes returns CONFLICT.
Lower IDs return CONFLICT. A higher ID starts a new transaction and replaces
the one-entry cache on completion. This works because the hub permits only one
outstanding exchange and never returns to an older transaction.

BUSY and errors are completed responses and are cached; a later attempt uses
a new ID. After a timeout, at most two exact retries are permitted (three
attempts total), only if scheduler deadlines permit. Once abandoned, that ID
is never retried. A timed-out state-changing operation is **indeterminate**:
query state, revoke/wait for a lease, or perform the defined recovery; do not
infer that it failed before taking effect. Nodes that reset lose session/cache
and return inhibited (keeping a persisted address), so reset is not transparent
exactly-once delivery. INPUT is the exception to retries: it is never retried,
because the next cycle carries a newer sample (`PS-TIMING`).

Long storage/update work is staged behind an operation token and polled.
Acceptance is not durable success. Operations shall not block the response
deadline. Their explicit state, not an arbitrary retransmission, determines
completion after an ambiguous response.

HELLO with a new session is accepted only while INHIBITED or RECOVERY, outside
maintenance, and with no incomplete persistent operation, except for the safe
maintenance takeover defined below. RECOVERY permits diagnosis but never
arming. HELLO clears volatile routes/handles,
negotiates version and caches the reply in the new session. Retries of that
HELLO follow the same duplicate rule. A live node refuses a different session
with BAD_STATE. A new hub must wait the boot guard before assuming all nodes
can accept its session. Commissioning has its own rules in PS-DISCOVERY.

To recover a hub restart during maintenance, a new-session HELLO may take over
MAINTENANCE only if no token is WORKING. It safely discards STAGING data,
releases completed/read handles and leaves maintenance inhibited before
establishing the session. An inconsistent FAILED backend enters RECOVERY,
not normal operation. WORKING yields BUSY until completion; it is never
cancelled by HELLO. Each persistent backend shall declare a maximum working
time and recovery procedure so a hub can bound this wait and report failure.
Pre-session errors (including a refused HELLO or STALE_SESSION) do not modify
the established session's transaction cache/high-water mark.

## 4. PS-TIMING: bus and lease timing

| Quantity | Provisional bound |
|---|---|
| Bit / UART byte | 0.5 us / 5 us at 2 Mbit/s (start + 8 data + stop) |
| Request transmitter disable | Within 20 us after last stop bit |
| Earliest response first start bit | 50 us after request last stop bit |
| Latest response first start bit | 250 us after request last stop bit (provisional; processing budget open, `SAD-O-009`) |
| Response timeout | Per opcode, from the request last stop bit: 1.0 ms (short class) or 1.5 ms (long class); see below |
| Bus idle guard after response or timeout | At least 50 us; sender driver disabled within 20 us of its last stop bit |
| Isolated transceiver (`SAD-P-010`) | Propagation, driver-enable and driver-disable delays of the isolated interface count inside the 20 us disable allowance and 50 us earliest-response gap and shall be measured (`ICD-VER-020`) |
| Armed input cadence | One complete INPUT exchange each 5 ms |
| Feedback poll cadence | One FEEDBACK_POLL to the owner every 10 ms (every second cycle) while armed |
| Display poll (Future, `PS-SVC-DISPLAY`) | Lowest priority; at most one exchange per cycle, never in a cycle where its timeout path would end after the next INPUT slot |
| Adapter lease | 100 ms since acceptance of ARM or newer complete INPUT |
| Local neutralisation delay | At most the adapter's declared `neutralisation_bound_us` (CAPS kind 4), which shall not exceed 1 ms for a conforming profile |
| Hub reboot / uncertain revoke guard | 110 ms since latest possible renewal acceptance; full 110 ms at boot; valid while every declared bound is at most 1 ms |
| Acknowledged revoke drain guard | `max(2 ms, 2 x B)` after response completion, before any new ARM; `B` is the largest declared bound among enrolled adapters (2 ms when all are at most 1 ms) |
| Monotonic clock error | At most +/-1% over qualified operating conditions |

Adapters shall not start late replies. If an operation cannot complete quickly,
reply BUSY or return an accepted token; do not transmit after the response window.
A complete maximum reply needs 1.10 ms plus at most 0.25 ms start delay.
No UART flow control or unbounded inter-byte pauses
are allowed; a frame is transmitted continuously.

The turnaround, response-start and idle-guard allowances above were chosen for
1 Mbit/s and are kept as absolute times at 2 Mbit/s; they are now 40 to 100 bit
times, so transceiver and isolator delays are a larger share of them and shall be
re-measured at the line rate (`ICD-VER-017`, `ICD-VER-020`).

### Per-opcode response timeout

The response timeout is `latest start (0.25 ms) + maximum response wire time +
margin (at least 0.05 ms)`, rounded up to a class. It is not one global value.

| Class | Condition | Timeout | Opcodes |
|---|---|---|---|
| Short | Maximum response at most 140 wire bytes (0.70 ms) | 1.0 ms | Every opcode except STORAGE READ: DISCOVER_UID, ASSIGN_UID, HELLO, CAPS, STATUS, REVOKE, RESET, ROUTES, ARM, INPUT, FEEDBACK_POLL, MAINTENANCE, STORAGE (other subcommands), CONFIG, DIAGNOSTICS, UPDATE, and the proposed DISPLAY_POLL |
| Long | Maximum response up to 220 wire bytes (1.10 ms) | 1.5 ms | STORAGE READ |

A new opcode shall declare its class from its maximum response size.

### Cycle budget

Exchange time is `request wire + 0.25 + response wire + 0.05` on success and
`request wire + timeout + 0.05` on timeout (2 Mbit/s, 5 us per wire byte; wire
bytes are raw bytes plus COBS overhead plus the delimiter).

| Exchange | Request / response wire bytes | Success (ms) | Timeout path (ms) |
|---|---|---:|---:|
| INPUT (two players) | 97 / 43 | 1.00 | 1.54 |
| FEEDBACK_POLL | 32 / 46 | 0.69 | 1.21 |
| STATUS | 28 / 52 | 0.70 | 1.19 |
| STORAGE/CONFIG/UPDATE WRITE, maximum chunk | 220 / 37 | 1.59 | 2.15 |
| STORAGE READ, maximum chunk | 39 / 220 | 1.60 | 1.75 |
| DISPLAY_POLL, 96-byte chunk (Future) | 34 / 130 | 1.12 | 1.22 |
| DISPLAY_POLL, nothing new (Future) | 34 / 29 | 0.62 | 1.22 |

| 5 ms cycle | Content | All succeed (ms) | All time out (ms) | Slack in the worst case (ms) |
|---|---|---:|---:|---:|
| Feedback cycle (every 10 ms) | INPUT + FEEDBACK_POLL + one STATUS | 2.39 | 3.94 | 1.06 |
| Other cycle | INPUT + one STATUS | 1.70 | 2.73 | 2.28 |

Every combination of success and timeout in these cycles ends inside 5 ms, so
a timeout of any one exchange cannot push the INPUT of the next cycle late.
Status rotation of one roster node per cycle refreshes 31 nodes in 155 ms, inside
the 500 ms automatic-selection freshness window.

Scheduler rules:

- A non-input exchange is admitted only if its worst-case timeout path ends
  before the next reserved INPUT slot, evaluated from the actual end of the
  preceding exchange. A maximum-size WRITE (2.15 ms) is therefore admitted after
  a successful INPUT (1.00 + 2.15 = 3.15 ms) and after INPUT, FEEDBACK_POLL and
  STATUS all succeed (4.54 ms), but not after all three time out (6.09 ms); the
  scheduler shrinks or defers management chunks that do not fit.
- Priority order within a cycle: INPUT, then FEEDBACK_POLL and STATUS, then
  management chunks, then display (lowest). A display exchange never delays or
  replaces an INPUT, FEEDBACK_POLL or STATUS that is due, and is admitted only
  by the rule above. Worst case a display exchange after INPUT, FEEDBACK_POLL and
  STATUS all succeed ends at 3.61 ms; after all three time out it would end at
  5.16 ms and is therefore skipped.
- INPUT is never retried. A lost or timed-out INPUT is replaced by the next
  cycle's INPUT with the newest sample and a new transaction ID.
- Other retries are separate scheduled slots; never queue several retries ahead
  of a newer input deadline.

Two-player INPUT uses 69 payload bytes: 95 raw bytes, at most 97 wire bytes,
0.485 ms. Its ACK has 15 payload bytes: 41 raw, at most 43 wire bytes, 0.215 ms.
A successful exchange occupies at most `0.485 + 0.25 + 0.215 + 0.05 = 1.00 ms`, or
20 % of the 5 ms cycle; with its 1.0 ms timeout it occupies `0.485 + 1.0 + 0.05 =
1.54 ms`.

Latency: a sample that becomes available just after a scheduling boundary waits
at most 5 ms, then needs at most `0.485 + 0.25 = 0.735 ms` to be installed, so at
most 5.74 ms in the normal profile (SRS-PERF-001, 10 ms). One lost INPUT adds one
cadence, giving at most 10.74 ms (SRS-PERF-005, 12 ms). The 5 ms cadence, not the
line rate, dominates this figure. The end-to-end target of
SRS-PERF-004 still requires measured hub processing and adapter installation, not
only this serialization calculation.

The 110 ms guard includes clock drift: an adapter's 100 ms timer may take
`100 / 0.99 = 101.011 ms` real time, plus at most
`1 / 0.99 = 1.011 ms` neutralisation, satisfying the 103 ms SRS bound. A hub's
110 ms may elapse in `110 / 1.01 = 108.911 ms` real time, leaving margin; the
guard stays valid for any declared bound up to about 7.8 ms, but a bound above
1 ms violates the 103 ms SRS bound and is not conforming. Lease time starts no
later than completion of the renewal response; for guard accounting the hub
shall conservatively timestamp the response completion, or the INPUT/ARM timeout
(1.0 ms after the request) for an uncertain renewal. This is the
`last possible renewal` time used by the SAD transition engine. If the clock
or neutralisation bounds cannot be proved, the profile must change before use.

## 5. PS-MSG and service discovery

Core operations are mandatory on commissioned nodes. Service bits denote
complete implemented schemas below, not merely reserved opcodes.

| Opcode | Symbol | Service bit | Purpose |
|---|---|---|---|
| 0x01 | DISCOVER_UID | Core | Targeted unassigned-node discovery |
| 0x02 | ASSIGN_UID | Core | Set node address (persisted by the adapter after the reply) |
| 0x03 | HELLO | Core | Establish session/version and identity |
| 0x04 | CAPS | Core | Read one bounded capability descriptor |
| 0x05 | STATUS | Core | Lifecycle, activity and counters |
| 0x06 | REVOKE | Core | Inhibit current ownership |
| 0x07 | RESET | Core | Controlled reset |
| 0x10 | ROUTES | Input bit 0 | Configure full inhibited route set |
| 0x11 | ARM | Input bit 0 | Grant neutral initial lease |
| 0x12 | INPUT | Input bit 0 | Atomic full input snapshot |
| 0x20 | FEEDBACK_POLL | Feedback bit 1 | Fetch/ack one generic effect |
| 0x30 | MAINTENANCE | Core | Enter/leave exclusive maintenance |
| 0x31 | STORAGE | Storage bit 2 | Opaque local resource operations |
| 0x40 | CONFIG | Configuration bit 3 | Stage/validate/commit configuration |
| 0x50 | DIAGNOSTICS | Diagnostics bit 4 | Read extended counters |
| 0x60 | UPDATE | Firmware Update bit 5 | Transfer/validate/activate image |

Bits 6..31 in the service bitmap are zero in this profile. Core and Input are
required for a usable console adapter. Feedback, Storage, Configuration,
Diagnostics and Update are optional. This fixed grouping is the entire
"service architecture": no RPC names, nested discovery or dynamic service loading.

### PS-DISCOVERY

A stable 128-bit UID identifies an adapter independent of address or console
type. UID bytes are opaque, not an integer. On production RP2350 parts the UID is
a vendor-defined 128-bit value written to the locked user area of the OTP memory
at manufacture and printed on a label; the RP2350 chip identifier alone (shorter
than 128 bits) is not the UID. Prototype boards may use a documented non-OTP
provisioning method (for example a value held in flash) so that development
boards are never irreversibly programmed by accident; such a UID is marked as
prototype in the hub roster and its uniqueness is the builder's responsibility.
A node with no valid UID does not answer commissioning and reports fault 5. The
UID is available via label, local debug or an equivalent out-of-band process.

Only one unassigned adapter is physically enabled for commissioning at a time.
The hub supplies its known UID; all other nodes remain silent. This avoids
depending on collision detection, random delays or simultaneous boot replies.
After address assignment, normal discovery scans the roster with HELLO/STATUS.
Unknown UID enumeration is outside profile 0.1.

| Message | Request payload | OK response payload |
|---|---|---|
| DISCOVER_UID | `uid[16]` | `uid[16], boot_id:u64, major:u8, min_minor:u8, max_minor:u8` |
| ASSIGN_UID | `uid[16], boot_id:u64, address:u8` | `uid[16], boot_id:u64, address:u8` |

Commissioning requests use destination 255 and session 0. Their transaction IDs
come from a **commissioning counter** owned by the hub: nonzero, strictly
increasing, separate from every session's counter and never reused within a hub
boot. A node needs no session to de-duplicate commissioning, because it matches
on `(UID, boot_id, transaction ID)`:

- DISCOVER_UID is a side-effect-free query; an unassigned node with matching UID
  answers every copy.
- Only an unassigned node with matching UID and current boot ID accepts ASSIGN_UID.
  It replies from 254 (session 0) and applies the new address only after the
  response leaves the UART. It then retains the exact ASSIGN request bytes, its
  transaction ID and its reply until the first accepted HELLO or the next reset.
- A node that has applied the address but has not yet seen HELLO is no longer
  unassigned, yet it still accepts one thing at destination 255: an **exact**
  retry of that retained ASSIGN request (same bytes, same transaction ID). It
  returns the retained reply byte for byte. It ignores anything else at 255.
  After HELLO, nothing at 255 is accepted.
- After a lost ASSIGN reply the hub makes at most two exact retries, then tries
  HELLO at the proposed address and, failing that, DISCOVER again.
- No other assigned node replies to commissioning requests.

The adapter persists the assigned address in its non-volatile store after the
ASSIGN reply has left the UART; the write is never inside a response window. On
reset a node with a valid persisted address returns to INHIBITED at that address
with a new boot ID and waits for HELLO; it does not need commissioning or
physical commissioning enable. HELLO carries `expected_uid`; a node whose UID
differs answers NOT_FOUND and changes nothing, which the hub treats as a UID
mismatch. Asserting the physical commissioning enable clears the persisted address
and returns the node to UNASSIGNED; it is required only for a first install, a
UID mismatch or an address conflict. A node without a safe non-volatile store
keeps its address volatile and must be commissioned after every reset (a
prototype limitation, `SAD-O-005`).

The hub persists UID-to-address intent, and does not assume the address matches
until HELLO validates the UID. It checks that the proposed address is unused and
requires commissioning enable to be removed before arming.
Duplicate UIDs or address contention invalidate the installation and require
physical isolation/reprovisioning. The protocol does not claim reliable
detection of two perfectly simultaneous identical replies.

### HELLO, CAPS and STATUS

HELLO request: `expected_uid[16], min_minor:u8, max_minor:u8`.
Use the lowest supported bootstrap minor in the frame header (1 in this draft).
Request range must include 1 for this profile. Response header uses the selected
minor; select the highest mutually supported minor within major 0.

HELLO response (34 bytes):
`uid[16], boot_id:u64, selected_minor:u8, service_bitmap:u32,
port_count:u8, max_routes:u8, max_payload:u16, commissioning_enabled:u8`.
Profile 0.1 advertises `max_payload=192`, `port_count=1..2`, `max_routes=1..2`;
commissioning_enabled must be 0 before arming. Boot ID is a new nonzero,
practically non-repeating value on each adapter boot.

CAPS request: `kind:u8, index:u16`. Indexes enumerate 0 upwards per kind;
NOT_FOUND terminates a list. A list holds at most 64 entries (indexes 0..63);
an index of 64 or more returns BAD_VALUE, and so does an unknown kind. Lists remain immutable for a boot ID.

| Kind | Response after `kind:u8, index:u16` | Meaning |
|---|---|---|
| 0 | `port:u8, peripheral_id:u16, mapping_id:u16, supported_buttons:u32, required_buttons:u32, supported_axes:u16, required_axes:u16, feedback_bits:u8, flags:u8` | One supported port/peripheral/mapping combination |
| 1 | `resource:u16, size:u32, read_granule:u16, write_granule:u16, flags:u8` | One storage resource; flags bit 0 readable, bit 1 writable |
| 2 | `profile:u16, max_image:u32, flags:u8` | One concrete update profile; flags bit 0 local physical enable required (shall be 1) |
| 3 | `profile:u16, max_config:u16` | One configuration profile; max_config <= 4096 |
| 4 | `neutralisation_bound_us:u16` | Exactly one entry (index 0), mandatory when the Input service is advertised: the profile's measured time within which neutral controls are visible to the console after an inhibit (`SRS-OWN-013`) |

Kind 4: the value is nonzero and at most 1000 for a conforming profile. The hub
derives its drain and uncertain-transfer guards from the maximum over enrolled
adapters (`PS-TIMING`) and shall not arm an adapter that declares more than 1000
without an owner-approved larger validated guard.

Kind 0: feedback_bits bit 0 two-motor rumble, bit 1 player indicator;
flags bit 0 explicit lossy-mapping approval required. Other bits zero.
Required masks must be subsets of supported masks. Individually advertised
combinations are not a promise that every pair works simultaneously; ROUTES
validates the complete set. Peripheral/mapping/resource/profile IDs are
nonzero adapter-local IDs; 0 is invalid. Their console semantics stay local.
Storage resource size and granules are nonzero, size is a multiple of both
granules, and at least one of readable/writable is set. A writable resource
must have a write granule no larger than the 183-byte chunk bound. A readable
resource has the same bound on its read granule.

STATUS request empty. Response:
`state:u8, activity:u8, fault:u16, generation:u32, lease_remaining_ms:u16,
dirty_resources:u16, rx_errors:u32, lease_expiries:u32, feedback_overflows:u32`.
State: 0 INHIBITED, 1 CONFIGURED, 2 ARMED_NEUTRAL, 3 LIVE, 4 MAINTENANCE,
5 RECOVERY. The SAD lifecycle state UNASSIGNED has no STATUS value: an
unassigned node has no address, so it is not addressable by STATUS and is reached
only through commissioning. Activity: 0 UNKNOWN, 1 INACTIVE, 2 ACTIVE. Fault 0 means none;
1 local I/O, 2 timing/resource, 3 persistence, 4 recovery, 5 address/provisioning,
6 internal/watchdog; further values reserved. Fault 5 is raised when the UID
provisioning is missing or invalid, when the persisted address record fails
validation, or when the physical commissioning enable is asserted while the node
is ARMED_NEUTRAL or LIVE (the node also inhibits). Generation/lease are zero when
not armed/configured as applicable. Counters saturate at `0xFFFFFFFF`;
dirty_resources is a count, not a bitmap. `rx_errors` is the sum of
DIAGNOSTICS counters 0..3 (bad COBS, bad CRC, oversize/partial frame, invalid
address/direction), saturating. `lease_expiries` counts ownership lease
expirations (DIAGNOSTICS counter 11); it does not measure the hub's unobserved
request timeouts.

## 6. PS-OWNERSHIP: routes, arm, snapshots and revoke

### ROUTES

Request:
`generation:u32, count:u8, records[count]`.
Each record is
`port:u8, player:u8, peripheral_id:u16, mapping_id:u16,
source_buttons:u32, source_axes:u16, flags:u8` (13 bytes).
Flag bit 0 means user explicitly approved a lossy mapping for this route;
other bits zero. OK response: `generation:u32`.

The hub chooses a nonzero generation, increasing for each route replacement
within a session, never wrapping. ROUTES is accepted only while inhibited or
configured, not armed or in maintenance. All routes are replaced atomically.
The adapter checks required versus source masks, descriptor IDs, lossy
approval and simultaneous hardware resources. It also rejects (INCOMPATIBLE) a
peripheral that would change the identity the console currently sees, unless the
profile declares live identity change (`SRS-IN-011`): a route selects mapping, not
identity. Failure leaves previous
configuration intact but not armed. Same generation with different content is
CONFLICT; same content is idempotent only while that generation remains
CONFIGURED. Once cleared by revoke/expiry it is STALE_GENERATION, not reusable.
New generation must exceed the highest
accepted in that session, even after revoke.

### ARM

Request: `generation:u32`. Response: `generation:u32`.
Requires matching configured routes, negotiated Input service, commissioning
disabled, no pending persistence/maintenance fault, and safe console-driver
readiness. It publishes neutral controls before ACK, starts the 100 ms lease
and enters ARMED_NEUTRAL. It never enables a cached old input sample.

A new ARM transaction while already armed returns BAD_STATE; an exact retry
only returns the cached ACK and does not extend the lease.

### PS-DATA-INPUT

INPUT request: `generation:u32, count:u8, records[count]`.
Each 32-byte record is:

| Offset in record | Type | Field |
|---|---|---|
| 0 | u8 | port |
| 1 | u8 | player |
| 2 | u32 | sample_sequence |
| 6 | u32 | valid_buttons |
| 10 | u32 | buttons |
| 14 | u16 | valid_axes |
| 16 | i16[8] | axes in fixed order below |

The full configured set is required, sorted by ascending port. No delta
updates. Validity masks shall be subsets of the route source masks.
Unreported buttons/axes have zero values; nonzero invalid values are BAD_VALUE.

| Button bit | Generic function |
|---|---|
| 0..3 | D-pad up, down, left, right |
| 4..7 | Face south, east, west, north |
| 8..9 | Left, right shoulder |
| 10..11 | Left, right stick click |
| 12..13 | Primary, secondary menu |
| 14..15 | Auxiliary 0, auxiliary 1 |
| 16..31 | Reserved zero; candidate generic positions (digital L2/R2) are earmarked for the schema freeze, see `SAD-MAP-002` |

| Axis index / validity bit | Function | Valid range and neutral |
|---|---|---|
| 0, 1 | Left stick X, Y | -32767..32767; 0 centre |
| 2, 3 | Right stick X, Y | -32767..32767; 0 centre |
| 4, 5 | Left, right trigger | 0..32767; 0 released |
| 6 | Steering | -32767..32767; 0 centre |
| 7 | Combined pedals | -32767..32767; negative brake, positive accelerator, 0 released |

Positive X/steering is right; positive Y is down. -32768 is invalid.
valid_axes bits 8..15 are zero. Devices with separate wheel pedals can use
axes 4/5 as brake/accelerator under an advertised wheel mapping; combined
axis 7 cannot represent simultaneous brake and acceleration. Clutch and further
axes require a future profile. Device capabilities and limitations must expose
that distinction, not claim lossless representation.

Opposing D-pad bits may arrive together; the adapter resolves up+down and
left+right to neutral independently. Invalid/missing fields map to neutral.
Physical triggers represented digitally can also advertise generic button
positions only through an explicit normalisation/mapping policy, not an
unannounced console-dependent substitution.

sample_sequence is nonzero and strictly increases per route generation.
Every periodic snapshot gets a new sequence even if controls are unchanged.
The first sequence may be 1; no wrap. All records must be newer than their
last accepted values. Equal/older values return CONFLICT with no partial
installation and no lease renewal. Exact transaction retries return cached
responses instead.

The adapter maps and installs the entire snapshot atomically, enters LIVE and
renews the lease only on full success. Response:
`generation:u32, count:u8, records[count]`, with each record
`port:u8, accepted_sequence:u32` sorted by port. Installation precedes OK.

### REVOKE and lease expiration

REVOKE request: `generation:u32`. Response empty. In the current session,
a matching active/configured generation is neutralised, effects stopped,
routes cleared and state INHIBITED before ACK. Repeating a revoke of that
last generation is OK; an unrelated generation is STALE_GENERATION. Generation
0 is permitted only when already inhibited, as an idempotent inhibit check.
REVOKE cannot cancel an incomplete persistent operation in maintenance.
The hub waits the 2 ms drain guard after an OK revoke response before arming
any owner, allowing an already latched console transaction to finish. An
unacknowledged revoke instead requires the 110 ms lease guard.

Lease expiry produces the same inhibition locally, clears routes and records
a timeout. Status/feedback/diagnostic traffic never extends a lease. Only
valid new INPUT or the initial ARM extends it. On expiry a new ROUTES/ARM
is required. A session change cannot bypass a live lease.

## 7. PS-SVC-FEEDBACK

FEEDBACK_POLL request: `ack_event:u32` (0 means none).
Response: `present:u8` followed, if 1, by
`event_id:u32, generation:u32, port:u8, player:u8, kind:u8,
duration_ms:u16, value0:u16, value1:u16`.

Events are held until acknowledged on a later poll. The hub polls the owner
adapter every 10 ms while armed (`PS-TIMING` cycle budget), so a continuous
effect that needs a refresh at least every 100 ms is served ten times over. The
adapter reports the console's native effect richness; the hub reduces it to what
the bound physical device supports (`SAD-FB-001`). The hub acknowledges only
after processing or explicitly discarding a stale/unsupported event with a
diagnostic. It acknowledges duplicates without replaying the effect. Event IDs
increase from 1 within a session, do not wrap; exhaustion inhibits feedback
until a new session. Ack 0 leaves the head queued; ack matching the head removes
it; ack equal to the last removed event is idempotent; other acks are BAD_VALUE.
The response then contains the next event or present=0. Exact request retry
returns its cached response and does not remove a second event.

Kind 0: rumble, value0 low-frequency and value1 high-frequency magnitude,
0..65535. Kind 1: player indicator index in value0 (0 off, 1..4 indicator),
value1 zero. duration_ms is 1..100 ms for either kind. The hub starts duration
on receipt, never replays duplicate event IDs and never extends an effect on
a duplicate response. Explicit zero values stop the effect. Longer effects
require fresh events. Ownership loss stops all effects immediately at the hub.

The adapter keeps at most one pending latest event per route/kind (four total),
plus one delivered head retained unchanged until acknowledged (five slots
maximum). Replacing a pending event increments feedback_overflows and allocates
a new event ID. Changes to the delivered head's route/kind coalesce into its
pending slot, not into the held event. After acknowledging the head, the
lowest-ID pending event becomes the new head, preserving increasing delivery.
Revoke/session change clears the queue. Driver and hub physical-device
limitations are reported through diagnostics; support is never inferred from
the presence of a console motor request.
The hub resets ack_event to 0 whenever ownership or session changes.

## 8. PS-MAINTENANCE and generic persistent operations

MAINTENANCE request `enter:u8`; response empty.
Entry requires inhibited/no configured routes, no dirty accessory data,
and a profile-proven quiescent console storage/peripheral interface.
Entry may return BUSY while safe local flush is progressing, or BAD_STATE if
quiescence cannot be established. Exit requires no incomplete operation and
all storage handles closed. Exit returns inhibited, never armed.

RESET request `mode:u8` (0 normal reset, 1 local recovery boot).
Requires inhibited, no dirty data/incomplete operation, commissioning disabled
and no open handles. Mode 1 additionally requires local physical recovery
enable. Reply empty; reset occurs only after ACK transmission. Lost ACK is
resolved by boot_id change and a new HELLO at the node's persisted address (or
recommissioning when the address is volatile or cleared), not an assumed success.

The following common operation envelope is used by STORAGE/CONFIG/UPDATE.
Only one persistent operation may be active per node. All are maintenance-only.
Subcommands and exact bodies are defined per service below. Subcommand is the
first request and response byte. Unsupported subcommands return UNSUPPORTED.

| Common operation | Request fields after subcommand | OK response fields after subcommand |
|---|---|---|
| QUERY (`0x7E`) | `token:u32` | `token:u32, state:u8, result:u8` |
| CLOSE (`0x7F`) | `token:u32` | Empty |

Token is nonzero, node-issued and session-local; not reusable within a session.
Only one token may be open per node, including read or completed tokens;
another BEGIN/OPEN returns BUSY until CLOSE.
State 0 STAGING, 1 WORKING, 2 DONE, 3 FAILED. Result is PS-STATUS, zero
unless FAILED. QUERY reports state but does not change it. WORKING operations
are polled, not synchronously waited on. DONE implies service-specific
completion; FAILED exposes the specific error. Stage tokens survive until
CLOSE/session reset, but do not survive power loss; on restart recovery state
is queried through STATUS before any new operation. CLOSE discards STAGING,
releases DONE/FAILED, and refuses WORKING with BUSY. A resource affected by
FAILED is not usable until the local backend establishes consistency.

Chunk length is bounded by the 192-byte total payload. Offset/length arithmetic
shall be checked without overflow; offsets are zero-based. WRITE chunks are
strictly contiguous; the response returns the next offset. An exact transaction
retry is safe; a new transaction for an already consumed offset is CONFLICT.
If an ACK is lost and its transaction cannot be retried, use the relevant
PROGRESS subcommand to find the next offset, not a blind repeated write.

### PS-SVC-STORAGE

Resources and sizes come from CAPS kind 1. Byte access abstracts console media;
it does not expose console protocol commands.

| Subcommand | Request after subcommand | OK response after subcommand |
|---|---|---|
| 0 OPEN_READ | `resource:u16` | `token:u32, size:u32` |
| 1 READ | `token:u32, offset:u32, length:u16` | `token:u32, offset:u32, data[length]` |
| 2 OPEN_WRITE | `resource:u16, size:u32` | `token:u32, next_offset:u32` |
| 3 WRITE | `token:u32, offset:u32, data[n]` | `token:u32, next_offset:u32` |
| 4 COMMIT | `token:u32, crc32c:u32` | `token:u32` |
| 5 PROGRESS | `token:u32` | `token:u32, next_offset:u32` |

Read length is 1..183 (response: subcommand 1 + token 4 + offset 4 + data).
Write data length is 1..183 (same overhead). Offsets and lengths must match
advertised read/write granules, except that the final chunk may end exactly at
resource size. OPEN_WRITE size must equal the resource's full size; this
profile supports full replacement, not arbitrary live block editing.

OPEN_READ locks a stable resource view and issues a DONE token for reading;
CLOSE releases it. OPEN_WRITE stages a full replacement, next_offset=0.
All bytes must arrive before COMMIT. CRC-32C covers only the full new resource.
COMMIT accepts work and changes state to WORKING; QUERY DONE means the full
replacement is durably installed and satisfies SRS-STO-004. A reset/power loss
may leave old or new valid media, never an acknowledged partially replaced
resource. If a backend cannot meet this contract, it shall not advertise
writable Storage. Network export is never needed for local console I/O.

### PS-SVC-CONFIG

| Subcommand | Request after subcommand | OK response after subcommand |
|---|---|---|
| 0 BEGIN | `profile:u16, size:u16` | `token:u32, next_offset:u32` |
| 1 WRITE | `token:u32, offset:u32, data[n]` | `token:u32, next_offset:u32` |
| 2 COMMIT | `token:u32, crc32c:u32` | `token:u32` |
| 3 PROGRESS | `token:u32` | `token:u32, next_offset:u32` |

Size is 1..the CAPS kind 3 bound (maximum 4096). WRITE n is 1..183.
COMMIT requires the complete blob and validates CRC, profile schema, all
cross-field constraints and durable activation. QUERY DONE means the new
configuration is active while inhibited; failure preserves the previous valid
configuration. Read-back is via a read-only Storage resource if advertised;
there is no assumed generic interpretation of console-specific configuration.

### PS-SVC-UPDATE

| Subcommand | Request after subcommand | OK response after subcommand |
|---|---|---|
| 0 BEGIN | `profile:u16, size:u32` | `token:u32, next_offset:u32` |
| 1 WRITE | `token:u32, offset:u32, data[n]` | `token:u32, next_offset:u32` |
| 2 VERIFY | `token:u32` | `token:u32` |
| 3 PROGRESS | `token:u32` | `token:u32, next_offset:u32` |
| 4 ACTIVATE | `token:u32` | `token:u32` |

Size is 1..CAPS kind 2 max_image; n is 1..183. VERIFY requires the complete
image and enters WORKING; DONE means compatibility and integrity/authenticity
checks required by that concrete profile succeeded, not that the new image is
running. ACTIVATE requires DONE plus physical update enable and starts a
recoverable boot switch after sending its ACK. It remains inhibited.

The Update service is **Future** for the first prototype (`SRS-UPD-004`,
`SAD-F-004`). Image package layout, target hardware identifiers, cryptographic manifest,
boot selection and rollback are **not yet defined**. Consequently no concrete
update profile ID is assigned in this draft, and implementations shall not
advertise Update until a controlled update-profile supplement defines these
items (image format, signing, anti-rollback, recovery path and an OTP policy
with a prototype/production distinction, so development boards are never
irreversibly locked by accident).
The transport schema above is not, by itself, an implementable safe updater.
CRC is not an update-authorisation mechanism.

### PS-SVC-DIAGNOSTICS

Request: `counter:u16`. Response: `counter:u16, value:u32`.
Counters are saturating and read-only in this profile:
0 bad COBS, 1 bad CRC, 2 oversize/partial frame, 3 invalid address/direction,
4 unsupported version, 5 transaction conflict, 6 stale generation,
7 console timing fault, 8 storage failure, 9 watchdog resets,
10 feedback overflow, 11 lease expiry. Unknown IDs return NOT_FOUND.
Counters other than watchdog resets may reset on boot; persistence of the
watchdog counter is implementation-dependent and shall be documented.

### PS-SVC-DISPLAY (proposed, Future; not part of profile 0.1)

Supports `SRS-UI-004` (hub display of the Dreamcast VMU screen, `SAD-F-006`).
Nothing here is implementable in minor 1: the service bit (bits 6 and up are zero
in 0.1) and the opcode value are assigned only when a minor that includes this
service is approved (section 9). The design decisions are recorded now so that the
bus budget in `PS-TIMING` can be shown to hold.

- **Source of data.** The adapter's console driver captures the console's writes
  to the emulated display into a local frame buffer. This is local state; the
  console never waits on the bus (SAD-D-003). The service transports a
  monochrome frame and carries no console command.
- **Descriptor.** A proposed CAPS kind 5 entry per display:
  `port:u8, width:u8, height:u8, format:u8, chunk_bytes:u8`. Format 0 is one bit
  per pixel, row-major, top row first, most significant bit leftmost, each row
  padded to whole bytes. `frame_bytes` is at most 512 and `chunk_bytes` is
  1..96. A VMU is 48 x 32, `frame_bytes` 192, `chunk_bytes` 96 (two chunks);
  those VMU values are to be verified against Maple documentation.
- **Chunk size.** Declared by the adapter, not negotiated per request, so the hub
  needs only `ceil(frame_bytes / chunk_bytes)`. 96 is the default and the
  maximum: smaller chunks cost more total bus time (four 48-byte chunks take
  3.52 ms per frame against 2.24 ms for two 96-byte chunks, because the fixed
  per-exchange cost repeats) and do not shorten the timeout path, which is set by
  the response class. A smaller value is for adapters short of buffer or DMA
  resources.
- **DISPLAY_POLL request** `port:u8, seq:u32, chunk:u8`. For chunk 0, `seq` is the
  sequence of the last complete frame the hub holds (0 for none). For chunk 1
  and above, `seq` is the sequence returned with chunk 0 of the frame being
  assembled.
- **OK response** `present:u8`, then if present is 1:
  `frame_seq:u32, chunk:u8, data[n]`. `n` is `chunk_bytes`, or the remainder for
  the last chunk. The maximum response is 102 payload bytes, 130 wire bytes, in
  the short timeout class.
- **Adapter behaviour.** For chunk 0 it returns present 0 when no frame newer
  than `seq` exists. Otherwise it latches a snapshot of the current frame,
  assigns it a nonzero `frame_seq` that increases (no wrap within a boot ID) and
  returns chunk 0. Later chunks are served from the latched snapshot, so a
  frame is never torn. A chunk request whose `seq` does not match the latched
  snapshot (for example after revoke or reset) returns present 0 and the hub
  restarts at chunk 0. The latest frame wins: there is no queue, no
  acknowledgement and no replay.
- **State and lease.** Accepted in CONFIGURED, ARMED_NEUTRAL and LIVE, else
  BAD_STATE. It never renews the lease and carries no control data.
- **Hub behaviour.** Poll only the owner, at most 10 times per second per port,
  at the lowest priority in the cycle (`PS-TIMING` scheduler rules); on a
  revoke, session change or device loss drop the held frame and reset `seq` to 0.
- **Budget (at 2 Mbit/s).** A 96-byte chunk exchange takes 1.12 ms on success
  and 1.22 ms on the timeout path; a poll with nothing new takes 0.62 ms.
  Two ports at 10 frames per second use about 4.5 % of bus time, and two ports
  of idle polls at 10 Hz about 1.2 %. Display exchanges are admitted only in the
  slack of a cycle, so INPUT timing, the 5.74 ms and 10.74 ms latency bounds and
  the lease arithmetic are unchanged.

## 9. Versioning, validation and unresolved work

Unknown opcode/service returns UNSUPPORTED. New incompatible frame/schema
semantics require a new major. A minor version can add explicitly negotiated
optional operations, never reinterpret a field for an existing negotiated
minor. Descriptor lists and service support are tied to boot ID; a change
requires re-discovery and no silent hot reinterpretation.

Before firmware interoperability is claimed, tests shall include:

- COBS empty/zero/254-byte-run vectors and maximum frame boundaries.
- CRC check vector, PS-VECTOR-001 and additional full request/response golden bytes.
- Single- and two-player size checks, masks, signed axes and all enum errors.
- Duplicate/reordered/lost requests and responses, reboot/session rollover,
  stale generation, lease expiry and lost revoke ACK.
- Commissioning exact-retry after a lost ASSIGN reply, persisted-address boot,
  UID mismatch and physical duplicate-node faults; a node without a persisted
  address needing commissioning after reset.
- Storage/config power-fail, ambiguous COMMIT, token query and failed recovery.
- Feedback ack retries, stale events, coalescing, 10 ms poll cadence and physical-device expiry.
- Per-opcode timeouts at 2 Mbit/s, one lost INPUT replaced by the next cycle's sample (no retry), and
  every success/timeout combination of the cycle budget finishing inside 5 ms.
- CAPS kind 4 value and the hub's derived guards; CAPS index bounds.
- Display service (only once a minor including it exists): 96-byte chunks and a short final chunk, a frame snapshot latched at chunk 0 and never torn, a mismatched `seq` restarting at chunk 0, the 10 per second poll cap, and INPUT latency and jitter unchanged with display polling active.
- Timing captures at maximum supported bus/USB/console load.

Open gates: physical layer approval, console-specific peripheral descriptors
and mapping profiles, actual update profile, a complete codec vector suite and
interoperability measurements. These omissions are deliberate draft boundaries,
not permission to invent incompatible local wire formats.
