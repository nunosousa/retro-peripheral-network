# Protocol Specification

| Control field | Value |
|---|---|
| Document ID | RPN-PS |
| Revision | 0.2 |
| Status | Baseline for review |
| Date | 2026-11-27 |
| Companion documents | [RPN-SRS](SRS.md), [RPN-ICD](ICD.md), [RPN-SAD](SAD.md), [RPN-AFS](AFS.md) |

| Revision | Change history |
|---|---|
| 0.1 | Bounded framing, commissioning, service schemas, input and safe ownership transactions. |
| 0.1 (2026-11-18) | Correction cycle: per-opcode response timeouts and cycle budget, feedback cadence, commissioning retry and ID rules, persisted address, hardware UID/RNG provisioning, CAPS kind 4 (`neutralisation_bound_us`) and bounded CAPS indexes, STATUS lifecycle/counter corrections, idle-identity check. |
| 0.1 (2026-11-18) | Line rate raised to 2 Mbit/s (trunk under 5 m): bit time, timeout classes, cycle budget and latency bounds recomputed; display service designed at lowest priority. |
| 0.1 (2026-11-18) | Storage note updated for an external FRAM backend (bank flip commit; no wire change). |
| 0.1 (2026-11-18) | Memory-card accessories described as Storage resources with transfer times; no wire change. |
| 0.1 (2026-11-24) | Four players: players 0..3, ports 0..3 and 1..4 routes per owner; INPUT size, cycle budget, latency and feedback slots recomputed for four records; neutral record for an absent device and idle identity on unrouted ports; no change to message layouts. |
| 0.1 (2026-11-25) | Informative figures 1-17 added; no change to any requirement, message layout or number. |
| 0.2 (2026-11-27) | Specification baseline, wire version 1.0: 8 Mbit/s timing with timeout classes of 0.2, 0.3 and 0.4 ms and a 1 ms cycle; INPUT record kinds (pad, pad with pressure, pointer, keyboard) and buttons 16 to 19; ROUTES for every port with pressure masks; ROUTES_AMEND (0x13); ENUMERATE (0x08) and DISCOVER_UID of the enabled node; CAPS kinds 0 to 5 revised (record kind, pressure, port binding, hardware ID, user options); feedback kinds for force feedback and keyboard LEDs; live storage snapshots; OPTION (0x41); concrete update profile; PROMPT (0x70) replaces the display service, PS-SVC-DISPLAY withdrawn; Diagnostics mandatory; vector appendix PS-VECTORS; figures updated. |

## 1. PS-PROFILE: scope and conventions

This is the wire protocol of the RPN bus. Requirements and electrical constraints are
owned by [RPN-SRS](SRS.md) and [RPN-ICD](ICD.md). Ownership policy is owned by
`SAD-OWN-001`; this document owns its wire mechanism.

The wire version is major **1**, minor **0**, distinct from the document revision.
Multi-byte integers are little-endian, unsigned unless stated. Byte strings have no
terminator. All lengths count bytes. Reserved fields and bits shall be sent zero and
rejected if nonzero. Booleans are u8 values 0 or 1. No implicit structure
alignment/padding is permitted.

`u8/u16/u32/u64` denote fixed-width integers. `i16` is signed two's complement.
`bytes[n]` is exactly n octets. `count`-prefixed lists require exact total length.
Trailing bytes, duplicate list keys and out-of-range values are errors.

Limits:

| Element | Value |
|---|---|
| Hub address | 0 |
| Adapter addresses | 1..31 |
| Unassigned address | 254; only in commissioning replies |
| Commissioning destination | 255; only DISCOVER_UID, ASSIGN_UID and ENUMERATE |
| Other addresses | Reserved; not valid sources/destinations |
| Players | 0..3 |
| Ports | 0..3 if advertised; not necessarily physical connector numbering |
| Routes per owner | One per advertised port (1..4); distinct players and ports; no fan-out |
| Payload maximum | 192 bytes |
| Outstanding requests | One on the entire bus |
| Live console owners | One |
| Ownership lease | Fixed 100 ms |

The hub is the sole request initiator. Adapters respond only to valid addressed
requests or commissioning requests matching them. There is no unsolicited event
frame, general broadcast input or broadcast arm/reset; the only signal several nodes
send at once is the enumeration presence signal (`PS-DISCOVERY`), which is not a frame.

Figures in this document are informative. They illustrate the text and tables, which
prevail wherever a figure differs; such a difference is a defect in the figure, and a
change to a number or rule includes the figures that show it. Sequence figures read
downward in time: `---->` is a request and `<----` its response, `--X` or `X--` a frame
lost or discarded on the bus, `[ ... ]` a local action or event, `txn` a transaction
ID, `g` a route generation and `seq` a `sample_sequence`. Identifiers, addresses and
counters in the examples are illustrative.

```text
Figure 1 - Bus roles: one master, one exchange at a time (informative)

              RS-485 trunk, half-duplex, daisy-chained through every node
  +---------+
  |   Hub   |=============+=================+=================+====== ... ========+=====
  | address |             |                 |                 |                   |
  |    0    |         Adapter 1         Adapter 2         Adapter 3          Adapter 31
  +---------+        (address 1)       (address 2)       (address 3)        (address 31)
                      console A         console B         console C          console ...

  request  : hub to destination 1..31 (one adapter), or 255 (commissioning only)
  response : from the addressed node (source 254 while unassigned) to destination 0
  Only the addressed node answers; every other node stays silent.
  One request is outstanding on the whole bus. Adapters never transmit on their own.
```

```text
Figure 2 - One adapter from power-up to release (informative)

  Hub                                          Adapter  state / action
   |                                              |
   |   [boot guard: new session, 110 ms silent]   |
   |-------- HELLO (expected_uid, minors) ------->|
   |<--- HELLO OK (boot_id, services, ports) -----|     INHIBITED (0)
   |-------- CAPS (kind, index), repeated ------->|
   |<------ CAPS OK; NOT_FOUND ends a list -------|
   |   [console chosen as owner, routes prepared] |
   |---- ROUTES g (one record per port) --------->|
   |<--------------- ROUTES OK g -----------------|     -> CONFIGURED (1)
   |------------------- ARM g ------------------->|     neutral published, lease starts
   |<----------------- ARM OK g ------------------|     -> ARMED_NEUTRAL (2)
   |----- INPUT g (all records), every 1 ms ----->|
   |<----- INPUT OK (accepted seq per port) ------|     -> LIVE (3); renews the lease
   |   [FEEDBACK_POLL / 2 ms, STATUS rotation]    |
   |------------------ REVOKE g ----------------->|
   |<---------------- REVOKE OK ------------------|     -> INHIBITED (0), routes cleared

  g is the route generation; the number in parentheses is the STATUS value of the state
  (Figure 11). A first install starts with DISCOVER_UID and ASSIGN_UID (Figure 10).
```

## 2. PS-FRAME: encoding and integrity

On the UART (`ICD-NET-001`), transmit:

```text
COBS(header || payload || crc32c) || 0x00
```

Use standard Consistent Overhead Byte Stuffing (COBS): each nonzero code byte gives
the distance to the next code, replacing intervening zero bytes; code 0xFF copies 254
nonzero bytes without inserting a zero, and a block of 254 nonzero bytes that ends the
data is not followed by another code byte. Empty data encodes as `01`. The delimiter is
not part of COBS data or CRC.

| Offset | Size | Field | Meaning |
|---|---|---|---|
| 0 | 1 | major | 1 |
| 1 | 1 | minor | 0, or the selected negotiated minor |
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

```text
Figure 3 - Frame layout and encoding (informative)

 Header, 22 bytes; the number above each field is its byte offset (1 byte = 8 columns)

  0       1       2       3       4       5
  +-------+-------+-------+-------+-------+-------+
  | major | minor | opcode| flags | source| dest. |
  +-------+-------+-------+-------+-------+-------+
  6       7       8                               12
  +-------+-------+-------------------------------+---------------+
  | status|  rsvd |         transaction_id        | payload_length|
  +-------+-------+-------------------------------+---------------+
  14
  +---------------------------------------------------------------+
  |                      session_id (8 bytes)                     |
  +---------------------------------------------------------------+

 Decoded frame: 26 + n bytes, where n = payload_length (0..192)

  +------------------------+--------------------------+------------------+
  |    header, 22 bytes    |     payload, n bytes     | CRC-32C, 4 bytes |
  +------------------------+--------------------------+------------------+
  |<------- CRC-32C covers header and payload ------->|

 On the wire:  COBS( header || payload || CRC-32C ), then the 0x00 delimiter
               largest frame: 218 B decoded, 219 B COBS-encoded, 220 B with the delimiter
```

CRC-32C (Castagnoli): reflected polynomial `0x82F63B78`, initial value `0xFFFFFFFF`,
reflect input/output as the conventional reflected algorithm, final XOR `0xFFFFFFFF`.
Calculate over header and payload, not COBS or the CRC field. ASCII `123456789` shall
produce numeric CRC `0xE3069283`, transmitted `83 92 06 E3`. No second reflection is
applied in a reflected implementation.

Decoded length is exactly `26 + payload_length`. Maximum raw length is 218, maximum
encoded length 219, maximum wire frame including delimiter 220 bytes. Parser storage is
bounded: discard until the next delimiter after oversize, bad COBS or timeout. A
delimiter with no preceding encoded bytes is ignored. A partial encoded frame older than
3 ms since its first byte is discarded; at 8 Mbit/s a maximum valid frame (0.275 ms)
fits inside that interval with margin. Noise with no delimiter cannot grow buffers.

Bad COBS/CRC, impossible decoded length, wrong destination or invalid source/response
direction is silently discarded **on the wire**, with a diagnostic counter increment.
This prevents replies to corrupt or misaddressed traffic. Valid addressed requests with
unsupported opcode/schema/state receive an explicit status. Unsupported major versions
are discarded with a version counter; discovery/HELLO timeouts expose incompatibility to
the hub.

```text
Figure 4 - What an adapter does with a received frame (informative)

  bytes arrive on the UART
        |
        v
  0x00 delimiter seen? --no--> keep collecting; a partial frame older than 3 ms, or longer
        |                      than 219 encoded bytes, is dropped and counted
       yes   (a delimiter with nothing before it is ignored)
        |
        +--> bad COBS, bad CRC, impossible length ----------+
        +--> wrong destination, invalid source/direction ---+--> DISCARD: no reply
        +--> unsupported major version ---------------------+    counter + 1
        |
        v
  valid request addressed to this node
        |
        +--> same ID, identical bytes -------------> cached reply, nothing re-executed
        +--> same ID, other bytes, or lower ID ----> reply CONFLICT
        +--> unsupported, invalid or not allowed --> reply with an explicit error status
        +--> otherwise (a higher ID) --------------> execute, reply OK, cache the reply

 A duplicate never repeats a side effect or renews a lease. Session 0 commissioning
 frames follow PS-DISCOVERY instead. On the hub, a response from an unexpected node or
 session, or one that does not match the outstanding exchange, is discarded and counted.
```

### PS-VECTOR-001: bootstrap codec checks

COBS-only examples (not including the delimiter): empty input -> `01`; `00` -> `01 01`;
`11 00 22` -> `02 11 02 22`; 254 bytes of `01` -> `FF` followed by the 254 bytes (255
bytes); 255 bytes of `01` -> `FF`, 254 bytes of `01`, `02 01` (257 bytes); `00`
followed by 254 bytes of `01` -> `01 FF` followed by the 254 bytes (256 bytes).

STATUS request to node 1, transaction 1, session 1, empty payload:

```text
Decoded header and CRC (26 bytes):
01 00 05 00 00 01 00 00 01 00 00 00 00 00 01 00
00 00 00 00 00 00 e6 45 f6 c6

COBS plus delimiter (28 bytes):
02 01 02 05 01 02 01 01 02 01 01 01 01 01 02 01
01 01 01 01 01 01 05 e6 45 f6 c6 00
```

This is a framing vector; a real node first requires HELLO for session 1. The complete
set of message vectors is in `PS-VECTORS` (Appendix A).

## 3. PS-TRANSACTION: ordering, sessions and errors

Each response echoes opcode, transaction ID and session ID, sets RESPONSE and returns
to address 0. Reply payload schemas below apply only to status OK; error replies have
zero payload. A response from an unexpected node/session, or not matching the
outstanding exchange, is discarded and counted.

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

The hub generates a new nonzero, practically non-repeating 64-bit session at boot and
before transaction-ID exhaustion. The session ID is drawn from the RP2350 hardware
random number generator after its health checks pass (`ICD-PLAT-001`); if they fail, a
persistent session counter combined with the hub UID is used, and a timer or fixed boot
value is never sufficient. The hub records which source it used in its diagnostics. IDs
increase strictly within a session; no wrap. When 0xFFFFFFFF is exhausted, release
ownership, wait the guard, create a new session and HELLO again. At about 2000 exchanges
per second (two per 1 ms cycle) the 32-bit space lasts about 24 days of continuous
armed operation; rollover is a deliberate neutral transition, not silent wrap. The hub
shall start rollover before exhaustion, reserving IDs for revoke, token queries/close and
reset recovery. It shall not begin a management operation whose bounded
completion/recovery transaction budget exceeds the remaining ID space. Exhaustion is an
explicit fault, not permission to reuse an ID.

Each node retains its highest completed transaction ID and last response for the current
session. The ID, cache and conflict rules in this section apply to sessions 1 and above;
commissioning exchanges (session 0) use the separate commissioning counter and retained
exchange defined in `PS-DISCOVERY`. A retry uses the exact original bytes and ID. The
same ID and identical request returns the cached response without repeating side effects
or renewing a lease. Same ID with different bytes returns CONFLICT. Lower IDs return
CONFLICT. A higher ID starts a new transaction and replaces the one-entry cache on
completion. This works because the hub permits only one outstanding exchange and never
returns to an older transaction.

BUSY and errors are completed responses and are cached; a later attempt uses a new ID.
After a timeout, at most two exact retries are permitted (three attempts total), only if
scheduler deadlines permit. Once abandoned, that ID is never retried. A timed-out
state-changing operation is **indeterminate**: query state, revoke/wait for a lease, or
perform the defined recovery; do not infer that it failed before taking effect. Nodes
that reset lose session/cache and return inhibited (keeping a persisted address), so
reset is not transparent exactly-once delivery. INPUT is the exception to retries: it is
never retried, because the next cycle carries a newer sample (`PS-TIMING`).

```text
Figure 5 - A lost request and a lost response look the same to the hub (informative)

 A. The request is lost
  Hub                                                Adapter
   |----------- ROUTES txn 21 ----------X               |  the node never saw it
   |   ... response timeout ...                         |
   |------------ ROUTES txn 21, same bytes ------------>|  [executes once]
   |<---------------- ROUTES OK txn 21 -----------------|

 B. The response is lost
  Hub                                                Adapter
   |------------------ ROUTES txn 21 ------------------>|  [executes, keeps reply 21]
   |               X-------- ROUTES OK txn 21 ----------|
   |   ... response timeout ...                         |
   |------------ ROUTES txn 21, same bytes ------------>|  [cached: no second effect]
   |<-------- ROUTES OK txn 21 (cached reply) ----------|

 The hub cannot tell A from B, so a retry repeats the exact bytes and the same
 transaction ID. After the first attempt and two retries (three attempts) the outcome is
 indeterminate: the hub does not assume failure; it queries state, revokes or waits out
 the lease, and never reuses the ID.
```

Long storage/update work is staged behind an operation token and polled. Acceptance is
not durable success. Operations shall not block the response deadline. Their explicit
state, not an arbitrary retransmission, determines completion after an ambiguous
response.

HELLO with a new session is accepted only while INHIBITED or RECOVERY, outside
maintenance, and with no incomplete persistent operation, except for the safe
maintenance takeover defined below. RECOVERY permits diagnosis but never arming. HELLO
clears volatile routes/handles, negotiates version and caches the reply in the new
session. Retries of that HELLO follow the same duplicate rule. A live node refuses a
different session with BAD_STATE. A new hub waits the boot guard before assuming all
nodes can accept its session. Commissioning has its own rules in PS-DISCOVERY.

To recover a hub restart during maintenance, a new-session HELLO may take over
MAINTENANCE only if no token is WORKING. It safely discards STAGING data, releases
completed/read handles and leaves maintenance inhibited before establishing the session.
An inconsistent FAILED backend enters RECOVERY, not normal operation. WORKING yields BUSY
until completion; it is never cancelled by HELLO. Each persistent backend declares a
maximum working time (at most 2 s for Storage and Configuration, at most 30 s for Update)
so a hub can bound this wait and report failure. Pre-session errors (including a refused
HELLO or STALE_SESSION) do not modify the established session's transaction
cache/high-water mark.

## 4. PS-TIMING: bus and lease timing

| Quantity | Bound |
|---|---|
| Bit / UART byte | 0.125 us / 1.25 us at 8 Mbit/s (start + 8 data + stop) |
| Request transmitter disable | Within 10 us after last stop bit |
| Earliest response first start bit | 20 us after request last stop bit |
| Latest response first start bit | 100 us after request last stop bit (`SRS-PERF-006`) |
| Response timeout | Per opcode class, from the request last stop bit: 0.2 ms (fast), 0.3 ms (short) or 0.4 ms (long); see below |
| Bus idle guard after response or timeout | At least 25 us; sender driver disabled within 10 us of its last stop bit |
| Isolated transceiver (`SAD-021`) | Propagation, driver-enable and driver-disable delays of the isolated interface count inside the 10 us disable allowance and the 20 us earliest-response gap (`ICD-VER-020`) |
| Armed input cadence | One complete INPUT exchange (every configured record, up to four) each 1 ms |
| Feedback poll cadence | One FEEDBACK_POLL to the owner every 2 ms while armed |
| Status cadence | One STATUS at least every 4 ms (31 nodes in 124 ms) |
| Adapter lease | 100 ms since acceptance of ARM or newer complete INPUT |
| Local neutralisation delay | At most the adapter's declared `neutralisation_bound_us` (CAPS kind 4), which shall not exceed 1 ms |
| Hub reboot / uncertain revoke guard | 110 ms since latest possible renewal acceptance; full 110 ms at boot; valid while every declared bound is at most 1 ms |
| Acknowledged revoke drain guard | `max(2 ms, 2 x B)` after response completion, before any new ARM; `B` is the largest declared bound among enrolled adapters (2 ms when all are at most 1 ms) |
| ASSIGN completion | A node may stay silent for up to 10 ms after its ASSIGN_UID reply while it persists the address; the hub sends HELLO only after that window |
| Monotonic clock error | At most +/-1 % over operating conditions |

Adapters shall not start late replies. If an operation cannot complete quickly, reply
BUSY or return an accepted token; do not transmit after the response window. A complete
maximum reply needs 0.275 ms plus at most 0.1 ms start delay. No UART flow control or
unbounded inter-byte pauses are allowed; a frame is transmitted continuously.

### Per-opcode response timeout

The response timeout is `latest start (0.1 ms) + maximum response wire time + margin (at
least 0.025 ms)`, rounded up to a class. It is not one global value.

| Class | Condition | Timeout | Opcodes |
|---|---|---|---|
| Fast | Maximum response at most 60 wire bytes (0.075 ms) | 0.2 ms | DISCOVER_UID, ASSIGN_UID, CAPS, STATUS, REVOKE, RESET, ROUTES, ARM, INPUT, ROUTES_AMEND, FEEDBACK_POLL, MAINTENANCE, STORAGE (every subcommand except READ), CONFIG, OPTION, DIAGNOSTICS, UPDATE, PROMPT |
| Short | Maximum response at most 140 wire bytes (0.175 ms) | 0.3 ms | HELLO |
| Long | Maximum response up to 220 wire bytes (0.275 ms) | 0.4 ms | STORAGE READ |

ENUMERATE has no frame response: the hub observes its presence window, which ends
0.12 ms after the request's last stop bit (`PS-DISCOVERY`). A new opcode shall declare
its class from its maximum response size.

```text
Figure 6 - Timing of one exchange, worst case shown (informative; not to scale)

                                a  b  c         d                     e    f
Hub TX      ===== request ======|
Adapter TX                            ..........===== response (R) ===|
Hub waits                       |<----------- response timeout ------------|
Bus                                                                        |<------> idle

  a  last stop bit of the request, t0
  b  t0 + 10 us at the latest: the hub has switched its RS-485 driver off
  c  t0 + 20 us: earliest first start bit of the response; c..d is the allowed window
  d  t0 + 100 us: latest first start bit; an adapter never starts a late reply
  e  end of the response; R is its wire time, at most 0.075, 0.175 or 0.275 ms by class
  f  timeout = 100 us + R + at least 25 us: 0.2 ms (fast), 0.3 ms (short), 0.4 ms (long)
  After the response or the timeout the bus idles for at least 25 us; each sender
  switches its driver off within 10 us of its last stop bit.
```

### Cycle budget

Exchange time is `request wire + 0.1 + response wire + 0.025` on success and
`request wire + timeout + 0.025` on timeout (8 Mbit/s, 1.25 us per wire byte; wire bytes
are raw bytes plus COBS overhead plus the delimiter). Values are rounded to 0.01 ms,
times up and slack down. INPUT is sized for its maximum, four pad-with-pressure records.

| Exchange | Request / response wire bytes | Success (ms) | Timeout path (ms) |
|---|---|---:|---:|
| INPUT (four pad-with-pressure records, maximum) | 217 / 53 | 0.47 | 0.50 |
| INPUT (four pad records) | 161 / 53 | 0.40 | 0.43 |
| INPUT (two pad records) | 97 / 43 | 0.30 | 0.35 |
| FEEDBACK_POLL | 32 / 48 | 0.23 | 0.27 |
| STATUS | 28 / 52 | 0.23 | 0.26 |
| ROUTES (four routes) | 93 / 32 | 0.29 | 0.35 |
| ROUTES_AMEND | 51 / 32 | 0.23 | 0.29 |
| HELLO | 46 / 62 | 0.26 | 0.39 |
| STORAGE/CONFIG/UPDATE WRITE, maximum chunk | 220 / 37 | 0.45 | 0.50 |
| STORAGE READ, maximum chunk | 39 / 220 | 0.45 | 0.48 |
| ENUMERATE | 45 / presence | 0.21 | 0.21 |

| Cycle (k = cycle number) | Content | All succeed (ms) | All time out (ms) | Slack in the worst case (ms) |
|---|---|---:|---:|---:|
| k even | INPUT + FEEDBACK_POLL | 0.69 | 0.77 | 0.23 |
| k = 1 mod 4 | INPUT + STATUS | 0.69 | 0.76 | 0.24 |
| k = 3 mod 4, chunk pending | INPUT + STORAGE READ chunk | 0.92 | 0.97 | 0.03 |
| k = 3 mod 4, otherwise | INPUT + STATUS | 0.69 | 0.76 | 0.24 |

Every combination of success and timeout in these cycles ends inside 1 ms, so a timeout
of any one exchange cannot push the INPUT of the next cycle late. While armed, the
management slot carries live-snapshot READ chunks; a maximum WRITE chunk (0.50 ms timeout
path) would also fit after a completed or timed-out INPUT (0.963 and 0.996 ms unrounded),
but storage import, configuration and update are maintenance operations, during which no
INPUT is scheduled.

Scheduler rules:

- A non-input exchange is admitted only if its worst-case timeout path ends before the
  next reserved INPUT slot, evaluated from the actual end of the preceding exchange; the
  scheduler shrinks or defers chunks that do not fit.
- Each cycle carries the owner's INPUT and then at most one further exchange, chosen by
  the cycle number as in the table above. A due FEEDBACK_POLL or STATUS is never
  replaced by a management chunk.
- INPUT is never retried. A lost or timed-out INPUT is replaced by the next cycle's INPUT
  with the newest sample and a new transaction ID.
- Other retries are separate scheduled slots; never queue several retries ahead of a
  newer input deadline.
- Without an owner there is no INPUT: STATUS rotation continues at least every 4 ms and
  management exchanges may follow one another.

```text
Figure 7 - The 1 ms cycle with a four-record INPUT (informative)

 One column = 0.02 ms.   I INPUT   F FEEDBACK_POLL   R STORAGE READ chunk
 Capital letters: exchange succeeds. Lower case: it times out (whole timeout path used).
 Numbers: the time in ms at which each exchange ends.

ms       0         0.2       0.4       0.6       0.8       1.0
         |---------|---------|---------|---------|---------|
 (a)     IIIIIIIIIIIIIIIIIIIIIIIFFFFFFFFFFF..............|
                               0.47      0.69
 (b)     iiiiiiiiiiiiiiiiiiiiiiiiiffffffffffffff..........|
                                 0.50          0.77   slack 0.23 ms
 (c)     IIIIIIIIIIIIIIIIIIIIIIIRRRRRRRRRRRRRRRRRRRRRRRR..|
                               0.47                    0.92

 (a) A feedback cycle in which both exchanges succeed. (b) The same cycle with both
 timing out ends at 0.77 ms, before the next INPUT slot at 1.00 ms. (c) A management cycle
 carrying a live-export READ chunk of 183 bytes. Order inside a cycle: INPUT, then the one
 further exchange the cycle number selects.
```

INPUT with records of sizes s1..sn uses `5 + sum(si)` request payload bytes and `5 + 5n`
ACK payload bytes. The maximum, four pad-with-pressure records of 46 bytes, uses 189
payload bytes: 215 raw bytes, 217 wire bytes, 0.271 ms. Its ACK has 25 payload bytes: 51
raw, 53 wire bytes, 0.066 ms. A successful exchange occupies at most
`0.271 + 0.1 + 0.066 + 0.025 = 0.463 ms`, or 47 % of the 1 ms cycle; with its 0.2 ms
timeout it occupies `0.271 + 0.2 + 0.025 = 0.496 ms`.

Latency: a sample that becomes available just after a scheduling boundary waits at most
1 ms, then needs at most `0.271 + 0.1 = 0.371 ms` to be installed, so at most 1.37 ms in
the normal profile with four maximum records (`SRS-PERF-001`, 2 ms). One lost INPUT adds
one cadence, giving at most 2.37 ms (`SRS-PERF-005`, 3 ms). The end-to-end target of
`SRS-PERF-004` additionally requires measured hub processing, not only this
serialization calculation.

```text
Figure 8 - A lost INPUT is replaced by the next one, never retried (informative)

ms          0                   1                   2                   3
            |-------------------|-------------------|-------------------|
sample       s  available just after the boundary at 0
INPUT                           [=======]X          [=======]
                                txn 40 carries s    txn 41: the newest sample
installed                              ^ 1.37 ms if txn 40 arrives
           one INPUT lost, txn 41 replaces it: 2.37 ms ^

 Four maximum records. A sample waits at most 1 ms for the next boundary and its INPUT
 then needs at most 0.371 ms (0.271 ms request + 0.1 ms latest response start): 1.37 ms,
 or 2.37 ms with one INPUT lost. The lost INPUT is not retried: the next cycle sends the
 newest sample under a new transaction ID.
```

The 110 ms guard includes clock drift: an adapter's 100 ms timer may take
`100 / 0.99 = 101.011 ms` real time, plus at most `1 / 0.99 = 1.011 ms` neutralisation,
satisfying the 103 ms SRS bound. A hub's 110 ms may elapse in `110 / 1.01 = 108.911 ms`
real time, leaving margin; the guard stays valid for any declared bound up to about
7.8 ms, but a bound above 1 ms violates the 103 ms SRS bound and is not conforming.
Lease time starts no later than completion of the renewal response; for guard accounting
the hub conservatively timestamps the response completion, or the INPUT/ARM timeout
(0.2 ms after the request) for an uncertain renewal. This is the `last possible renewal`
time used by the SAD transition engine.

```text
Figure 9 - Why 110 ms is a safe guard after an unacknowledged revoke (informative)

   a                    b          c          d                       e
   +--------//----------+----------+----------+-----------------------+------>
   0                   100      101.01     102.02                  108.91      ms

 Time axis, not to scale; the break between a and b hides most of the 100 ms.

  a  t = 0: latest possible acceptance of the old owner's last renewal (hub's timestamp)
  b  100 ms: nominal lease expiry
  c  101.01 ms: latest lease expiry, adapter clock 1 % slow (100 / 0.99)
  d  102.02 ms: the old owner's console shows neutral at the latest, (100 + 1) / 0.99;
     SRS-OWN-009 allows 103 ms
  e  108.91 ms: earliest end of the hub's 110 ms guard, hub clock 1 % fast (110 / 1.01)

 Only after point e may the hub arm another owner when the revoke was not acknowledged.
 Declared neutralisation bounds above 1 ms break the 103 ms bound; the guard itself
 holds up to about 7.8 ms.
```

## 5. PS-MSG and service discovery

Core operations are mandatory on commissioned nodes. Service bits denote complete
implemented schemas below, not merely reserved opcodes.

| Opcode | Symbol | Service bit | Purpose |
|---|---|---|---|
| 0x01 | DISCOVER_UID | Core | Commissioning discovery of one unassigned node |
| 0x02 | ASSIGN_UID | Core | Set node address (persisted by the adapter after the reply) |
| 0x03 | HELLO | Core | Establish session/version and identity |
| 0x04 | CAPS | Core | Read one bounded capability descriptor |
| 0x05 | STATUS | Core | Lifecycle, activity and counters |
| 0x06 | REVOKE | Core | Inhibit current ownership |
| 0x07 | RESET | Core | Controlled reset |
| 0x08 | ENUMERATE | Core | UID-prefix presence query of unassigned nodes |
| 0x10 | ROUTES | Input bit 0 | Configure the full inhibited route set |
| 0x11 | ARM | Input bit 0 | Grant a neutral lease |
| 0x12 | INPUT | Input bit 0 | Atomic full input snapshot |
| 0x13 | ROUTES_AMEND | Input bit 0 | Amend one route while armed |
| 0x20 | FEEDBACK_POLL | Feedback bit 1 | Fetch/ack one generic effect |
| 0x30 | MAINTENANCE | Core | Enter/leave exclusive maintenance |
| 0x31 | STORAGE | Storage bit 2 | Local resource operations and snapshots |
| 0x40 | CONFIG | Configuration bit 3 | Stage/validate/commit configuration |
| 0x41 | OPTION | Configuration bit 3 | Read and set one user option |
| 0x50 | DIAGNOSTICS | Diagnostics bit 4 | Read extended counters |
| 0x60 | UPDATE | Firmware Update bit 5 | Transfer/verify/activate image |
| 0x70 | PROMPT | Adapter display bit 6 | Show a console-specific name on the adapter display |

Bits 7..31 of the service bitmap are zero. Every adapter implements Core, Input,
Diagnostics, Firmware Update and Adapter display. An adapter implements Feedback when one
of its peripherals has a feedback function, Storage when it presents a memory accessory
or a configuration read-back resource, and Configuration when it advertises a
configuration profile or a user option (`SRS-NET-007`, `SRS-NET-015`, `SRS-UPD-005`).
This fixed grouping is the entire service architecture: no RPC names, nested discovery or
dynamic service loading.

### PS-DISCOVERY

A stable 128-bit UID identifies an adapter independent of address or console type. UID
bytes are opaque, not an integer. The UID is a vendor-defined 128-bit value written to a
hard-locked read-only page of the RP2350 OTP at manufacture and printed on a label; the
RP2350 chip identifier alone (shorter than 128 bits) is not the UID, and the all-zero UID
is invalid. A node with no valid UID does not answer commissioning or enumeration and
reports fault 5.

| Message | Request payload | OK response payload |
|---|---|---|
| DISCOVER_UID | `uid[16]` | `uid[16], boot_id:u64, major:u8, min_minor:u8, max_minor:u8` |
| ASSIGN_UID | `uid[16], boot_id:u64, address:u8` | `uid[16], boot_id:u64, address:u8` |
| ENUMERATE | `prefix_bits:u8, prefix[16]` | none: presence signal |

Commissioning requests use destination 255 and session 0. Their transaction IDs come from
a **commissioning counter** owned by the hub: nonzero, strictly increasing, separate from
every session's counter and never reused within a hub boot. A node needs no session to
de-duplicate commissioning, because it matches on `(UID, boot_id, transaction ID)`.

**Add adapter** (`SRS-NET-012`). The hub sends DISCOVER_UID with the all-zero UID. Only an
unassigned node whose physical commissioning enable is asserted answers, with its own UID
(asserting the enable while the node is INHIBITED clears its persisted address, so the node is unassigned). Exactly one
node is enabled at a time, so the reply is collision-free; two enabled nodes corrupt each
other's reply, the hub receives no valid frame, makes no assignment and reports the fault.
The hub records the UID, assigns an unused address with ASSIGN_UID and requires the enable
to be removed before arming.

**Targeted discovery.** DISCOVER_UID with a nonzero UID is answered only by the unassigned
node with that UID, enabled or not; it is a side-effect-free query, answered on every copy.

**Enumeration** (`SRS-NET-011`). ENUMERATE asks every unassigned node whose UID begins with
the first `prefix_bits` bits of `prefix` (0..128; bits beyond `prefix_bits` shall be zero;
bit order: byte 0 first, most significant bit first) to send the **presence signal**: it
enables its driver between 20 us and 80 us after the request's last stop bit, holds the
line in the space state (logic 0) for 20 us and disables its driver. Every matching node
drives the same level, so several nodes answering at once cannot corrupt each other. The
hub detects presence as a break condition (space for at least 2.5 us) between 20 us and
120 us after the request and then waits the idle guard. Assigned nodes discard a break in
that window without counting it in DIAGNOSTICS counters 0 to 3. The hub enumerates only
while no owner is armed. The hub finds every unassigned UID
by a depth-first search: a prefix with presence is extended by one bit with value 0 and
with value 1; a full 128-bit prefix with presence names one UID, which the hub confirms by
targeted DISCOVER_UID (reading its boot ID) and assigns by ASSIGN_UID; a prefix without
presence is abandoned. Ten unknown nodes need at most about 2560 queries (0.54 s). A
duplicate UID makes the targeted DISCOVER_UID reply corrupt; the hub reports it and assigns
nothing to that UID.

Assignment rules:

- Only an unassigned node with matching UID and current boot ID accepts ASSIGN_UID. It
  replies from 254 (session 0) and applies the new address only after the response leaves
  the UART. It then retains the exact ASSIGN request bytes, its transaction ID and its reply
  until the first accepted HELLO or the next reset.
- A node that has applied the address but has seen no HELLO is no longer unassigned,
  yet it still accepts one thing at destination 255: an **exact** retry of that retained
  ASSIGN request (same bytes, same transaction ID). It returns the retained reply byte for
  byte. It ignores anything else at 255. After HELLO, nothing at 255 is accepted.
- After a lost ASSIGN reply the hub makes at most two exact retries, then tries HELLO at the
  intended address and, failing that, discovery again.
- No assigned node replies to commissioning requests or enumeration.

The adapter persists the assigned address in its configuration store after the ASSIGN reply
has left the UART, within the 10 ms ASSIGN completion window (`PS-TIMING`); the write is
never inside a response window. On reset a node with a valid persisted address returns to
INHIBITED at that address with a new boot ID and waits for HELLO; it needs no commissioning.
HELLO carries `expected_uid`; a node whose UID differs answers NOT_FOUND and changes
nothing, which the hub treats as a UID mismatch. The physical commissioning enable acts on its asserting
edge: in INHIBITED (or UNASSIGNED) the edge clears the persisted address and the node is
UNASSIGNED; in ARMED_NEUTRAL or LIVE the node inhibits, keeps its address and raises fault
5; in CONFIGURED or MAINTENANCE the edge is ignored and fault 5 is raised. Its level is
reported as `commissioning_enabled` in HELLO and must be 0 before arming. It is required
only for a first install, a UID mismatch or an address conflict.

The hub persists UID-to-address intent and does not assume the address matches until HELLO
validates the UID. It checks that the intended address is unused and requires
commissioning enable to be removed before arming. Duplicate UIDs or address contention
invalidate the installation and require physical isolation and reprovisioning. After
address assignment, normal discovery scans the roster with HELLO/STATUS.

```text
Figure 10 - Commissioning one new adapter with "add adapter" (informative)

  Hub                                          Node with UID u, enable asserted
   |                                                  |  [all other nodes silent]
   |--- DISCOVER_UID 0..0 (dst 255, session 0, c1) -->|  [no side effect]
   |<---- DISCOVER_UID OK (src 254: uid u, boot) -----|
   |----- ASSIGN_UID u, boot_id, address 5 (c2) ----->|  [current boot_id only]
   |              X---- ASSIGN_UID OK (src 254) ------|  reply lost; node now at 5
   |---- ASSIGN_UID, exact retry (same bytes, c2) --->|  [still heard at dst 255]
   |<-- ASSIGN_UID OK (retained reply, same bytes) ---|
   |   [10 ms ASSIGN completion window]               |  [address persisted]
   |---- HELLO (dst 5, session s, expected_uid u) --->|
   |<--------------- HELLO OK (src 5) ----------------|  [dst 255 is ignored now]

  c1 and c2 come from the hub's commissioning counter (session 0). The node applies the
  new address only after its reply has left the UART and keeps the exact request and
  reply until the first HELLO or the next reset. After a lost reply the hub makes at most
  two exact retries, then tries HELLO at the intended address and, failing that,
  discovery again. Enumeration replaces the first exchange by an ENUMERATE search and a
  targeted DISCOVER_UID u.
```

### HELLO, CAPS and STATUS

HELLO request: `expected_uid[16], min_minor:u8, max_minor:u8`. The frame header uses
minor 0, the bootstrap minor. The request range shall include 0. The response header uses
the selected minor; the node selects the highest mutually supported minor within major 1.

HELLO response (34 bytes): `uid[16], boot_id:u64, selected_minor:u8, service_bitmap:u32,
port_count:u8, max_routes:u8, max_payload:u16, commissioning_enabled:u8`. Nodes advertise
`max_payload=192`, `port_count=1..4` and `max_routes` equal to `port_count`;
`commissioning_enabled` must be 0 before arming. Boot ID is a new nonzero, practically
non-repeating value on each adapter boot.

CAPS request: `kind:u8, index:u16`. Indexes enumerate 0 upwards per kind; NOT_FOUND
terminates a list. A list holds at most 64 entries (indexes 0..63), which at four ports
allows sixteen port/peripheral/mapping combinations per port; an index of 64 or more
returns BAD_VALUE, and so does an unknown kind. Lists remain immutable for a boot ID; an option that changes the port count, the ports or a CAPS list (kind 5 flag bit 0) therefore takes effect only at the next node reset.

| Kind | Response after `kind:u8, index:u16` | Meaning |
|---|---|---|
| 0 | `port:u8, peripheral_id:u16, mapping_id:u16, record_kind:u8, supported_buttons:u32, required_buttons:u32, supported_axes:u16, required_axes:u16, supported_pressure:u16, required_pressure:u16, feedback_bits:u8, flags:u8` | One supported port/peripheral/mapping combination |
| 1 | `resource:u16, port:u8, size:u32, read_granule:u16, write_granule:u16, flags:u8` | One storage resource; port 0..3 or 0xFF for a device-wide resource; flags bit 0 readable, bit 1 writable, bit 2 live snapshot supported |
| 2 | `profile:u16, hardware_id:u32, max_image:u32, flags:u8` | One update profile per processor role; flags bit 0 physical enable required (shall be 1) |
| 3 | `profile:u16, max_config:u16` | One configuration profile; max_config <= 4096 |
| 4 | `neutralisation_bound_us:u16` | Exactly one entry (index 0): the annex's declared time within which neutral controls are visible to the console after an inhibit (`SRS-OWN-013`) |
| 5 | `option:u16, port:u8, value_count:u8, default_value:u8, flags:u8` | One user option; port 0..3 or 0xFF for a device-wide option; values 0..value_count-1 (value_count 2..16); flags bit 0 takes effect after reset (for example a multitap/direct mode) |

Kind 4: the value is nonzero and at most 1000. The hub derives its drain and
uncertain-transfer guards from the maximum over enrolled adapters (`PS-TIMING`) and shall
not arm an adapter that declares more than 1000.

Kind 0: `record_kind` is 0 pad, 1 pad with pressure, 2 pointer or 3 keyboard
(`PS-DATA-INPUT`); the masks use that record kind's bit assignments: for kinds 0 and 1
the button, axis and pressure bits of `PS-DATA-INPUT` (pressure masks zero for kind 0);
for kind 2 buttons bits 0..4 as the pointer's buttons and axes bit 0 X/Y motion, bit 1
wheel; for kind 3 buttons bit 0 modifiers and keys, axes zero; ROUTES source masks use the
same assignments. `feedback_bits`: bit 0 rumble, 2 constant force, 3 spring, 4 damper, 5
keyboard LEDs; bit 1 is reserved. `flags` bit 0: explicit lossy-mapping
approval required. Other bits zero. Required masks must be subsets of supported masks.
Individually advertised combinations are not a promise that every set works
simultaneously; ROUTES validates the complete set. Peripheral, mapping, resource, profile
and option IDs are nonzero adapter-local IDs; 0 is invalid. Their console semantics stay
local and their names appear only on the adapter display (`PS-SVC-PROMPT`).

Kind 1: size and granules are nonzero, size is a multiple of both granules, and at least
one of readable/writable is set. A writable resource has a write granule no larger than
the 183-byte chunk bound; a readable resource has the same bound on its read granule.

STATUS request empty. Response (24 bytes): `state:u8, activity:u8, fault:u16,
generation:u32, lease_remaining_ms:u16, dirty_resources:u16, rx_errors:u32,
lease_expiries:u32, feedback_overflows:u32`. State: 0 INHIBITED, 1 CONFIGURED, 2
ARMED_NEUTRAL, 3 LIVE, 4 MAINTENANCE, 5 RECOVERY. The SAD lifecycle state UNASSIGNED has no
STATUS value: an unassigned node has no address, so it is not addressable by STATUS and is
reached only through commissioning and enumeration. Activity: 0 UNKNOWN, 1 INACTIVE, 2
ACTIVE, by the rule of `SRS-OWN-014`. Fault 0 means none; 1 local I/O, 2 timing/resource
(including an internal-link forwarding failure, `SAD-050`), 3 persistence, 4 recovery, 5
address/provisioning, 6 internal/watchdog; further values reserved. Fault 5 is raised when
the UID provisioning is missing or invalid, when the persisted address record fails
validation, or when the physical commissioning enable is asserted while the node is
ARMED_NEUTRAL or LIVE (the node also inhibits). Generation/lease are zero when not
armed/configured as applicable. Counters saturate at `0xFFFFFFFF`; dirty_resources is a
count, not a bitmap, and is zero for FRAM accessories. `rx_errors` is the sum of
DIAGNOSTICS counters 0..3 (bad COBS, bad CRC, oversize/partial frame, invalid
address/direction), saturating. `lease_expiries` counts ownership lease expirations
(DIAGNOSTICS counter 11); it does not measure the hub's unobserved request timeouts.

## 6. PS-OWNERSHIP: routes, arm, snapshots and revoke

The messages of this section move an adapter through the STATUS states as Figure 11
shows; `SAD-OWN-001` owns the lifecycle policy.

```text
Figure 11 - Adapter state and the message that changes it (informative)

 The number in parentheses is the STATUS value of the state.

             HELLO+ROUTES                  ARM                     first INPUT
 +-----------+           +------------+           +---------------+           +------+
 | INHIBITED |---------->| CONFIGURED |---------->| ARMED_NEUTRAL |---------->| LIVE |
 |    (0)    |           |    (1)     |           |      (2)      |           | (3)  |
 +-----------+           +------------+           +---------------+           +------+
       ^                        |                         |                       |
       |                        |                         |                       |
       +------------------------+-------------------------+-----------------------+
         REVOKE from (1), (2) or (3); lease expiry or a fault from (2) or (3)

  power-up/reset   valid persisted address -> INHIBITED (0); HELLO comes before ROUTES
                   no valid address       -> UNASSIGNED
                   recovery input asserted -> RECOVERY (5)
  UNASSIGNED       no STATUS value; --ASSIGN_UID--> INHIBITED (0), or RECOVERY (5)
  INHIBITED (0)    --MAINTENANCE enter--> MAINTENANCE (4)
  MAINTENANCE (4)  --MAINTENANCE exit--> INHIBITED (0)
                   --new-session HELLO, no token WORKING--> INHIBITED (0) or RECOVERY (5)
  RECOVERY (5)     diagnosis and session negotiation only, never ownership
  any state        --reset--> the power-up row
  LIVE             every complete INPUT renews the lease
  (2), (3)         ROUTES_AMEND keeps the state; the amended port is neutral
```

### ROUTES

Request: `generation:u32, count:u8, records[count]`. Each record (15 bytes) is
`port:u8, player:u8, peripheral_id:u16, mapping_id:u16, source_buttons:u32,
source_axes:u16, source_pressure:u16, flags:u8`. Flag bit 0 means the user explicitly
approved a lossy mapping for this route; other bits zero. OK response: `generation:u32`.

`count` equals the adapter's `port_count`: every advertised port appears exactly once, each
with a distinct player (`SRS-IN-019`). The source masks of a route are the controls the hub
will supply: a device's controls inside the mapping's supported masks, or the mapping's
required controls for a port that has no device yet.

The hub chooses a nonzero generation, increasing for each route replacement or amendment
within a session, never wrapping. ROUTES is accepted only while inhibited or configured,
not armed or in maintenance. All routes are replaced atomically. The adapter checks
required versus source masks, record kinds, descriptor IDs, lossy approval and
simultaneous hardware resources. It also rejects (INCOMPATIBLE) a peripheral whose
identity differs from the one the console currently sees, unless the annex allows a
peripheral change while inhibited (`SRS-IN-011`). Failure leaves the previous configuration
intact but not armed. Same generation with different content is CONFLICT; same content is
idempotent only while that generation remains CONFIGURED. Once cleared by revoke/expiry it
is STALE_GENERATION, not reusable. A new generation must exceed the highest accepted in that
session, even after revoke.

### ARM

Request: `generation:u32`. Response: `generation:u32`. Requires matching configured routes,
negotiated Input service, commissioning disabled, no pending persistence/maintenance fault,
and safe console-driver readiness. It publishes neutral controls before ACK, starts the
100 ms lease and enters ARMED_NEUTRAL. It never enables a cached old input sample.

A new ARM transaction while already armed returns BAD_STATE; an exact retry only returns
the cached ACK and does not extend the lease.

### ROUTES_AMEND

Request: `generation:u32, new_generation:u32, record` (the 15-byte ROUTES record).
Response: `generation:u32` (the new generation).

Accepted only in ARMED_NEUTRAL or LIVE when `generation` is the current generation and
`new_generation` exceeds every generation accepted in the session; otherwise
STALE_GENERATION or BAD_VALUE. The record names an existing port; its `peripheral_id` shall
equal the port's current one (INCOMPATIBLE otherwise); `player` may change only to a player
that no other route uses. The adapter validates the amended route together with the
unchanged others as a complete set. On success, before the ACK, it installs neutral
controls on the amended port, adopts `new_generation` as the current generation and keeps
the other ports' installed records live; it does not renew the lease. From then on INPUT is
accepted only with `new_generation`: the next INPUT renews the lease and carries a fresh
record for every port, including the amended one. On failure nothing changes. An exact
retry returns the cached response; a lost response is resolved by an exact retry or, if it
stays indeterminate, by REVOKE (`SAD-OWN-001`).

### PS-DATA-INPUT

INPUT request: `generation:u32, count:u8, records[count]`. `count` equals the number of
routes; records appear in ascending port order; each record's layout is the record kind of
its route's peripheral (CAPS kind 0). Every record begins with the same six bytes:

| Offset in record | Type | Field |
|---|---|---|
| 0 | u8 | port |
| 1 | u8 | player |
| 2 | u32 | sample_sequence |

**Kind 0, pad (32 bytes)** and **kind 1, pad with pressure (46 bytes)**:

| Offset | Type | Field |
|---|---|---|
| 6 | u32 | valid_buttons |
| 10 | u32 | buttons |
| 14 | u16 | valid_axes |
| 16 | i16[8] | axes in fixed order below |
| 32 | u16 | valid_pressure (kind 1 only) |
| 34 | u8[12] | pressure in the order below, 0 released to 255 full (kind 1 only) |

**Kind 2, pointer (14 bytes)**:

| Offset | Type | Field |
|---|---|---|
| 6 | u8 | valid: bit 0 buttons, bit 1 X/Y motion, bit 2 wheel |
| 7 | u8 | buttons: bit 0 left, 1 right, 2 middle, 3 and 4 extra |
| 8 | u16 | x_count, running counter, positive right |
| 10 | u16 | y_count, running counter, positive down |
| 12 | u16 | wheel_count, running counter, positive away from the user |

**Kind 3, keyboard (14 bytes)**:

| Offset | Type | Field |
|---|---|---|
| 6 | u8 | valid: bit 0 modifiers and keys |
| 7 | u8 | modifiers: HID usages E0h to E7h as bits 0 to 7 |
| 8 | u8[6] | pressed keys as HID keyboard usages, ascending, unused slots 0; 01h in every slot on roll-over |

The full configured set is required. No delta updates. Validity masks shall be subsets of
the route source masks. Unreported fields have zero values; nonzero invalid values are
BAD_VALUE. Running counters wrap modulo 2^16; the adapter uses differences between the
installed record and the new one, and the first valid motion after an invalid one sets the
reference without moving (`SAD-MAP-003`).

```text
Figure 12 - INPUT request, records and acknowledgement (informative)

 Request payload = 5 + sum of record sizes (at most 5 + 4 x 46 = 189 bytes)
 +------------+-------+-------------+-------------+-------------+-------------+
 | generation | count |   record 0  |   record 1  |   record 2  |   record 3  |
 |    u32     |   u8  | 14..46 bytes| 14..46 bytes| 14..46 bytes| 14..46 bytes|
 +------------+-------+-------------+-------------+-------------+-------------+
 One record per route, in ascending port order, every time: no delta updates.

 Pad record, 32 bytes (byte offset above each field; axes[8] = eight i16 values)
 0      1        2                 6               10        14           16       32
 +------+--------+-----------------+---------------+---------+------------+---------+
 | port | player | sample_sequence | valid_buttons | buttons | valid_axes | axes[8] |
 +------+--------+-----------------+---------------+---------+------------+---------+
 Pad with pressure, 46 bytes: the pad record, then valid_pressure (u16) and pressure[12].
 Pointer, 14 bytes: header, valid, buttons, x_count, y_count, wheel_count.
 Keyboard, 14 bytes: header, valid, modifiers, keys[6].

 Neutral record (device absent): the route's layout with every validity field, value and
 counter set to 0; port, player and sample_sequence are filled in as usual.

 Acknowledgement payload = 5 + 5 n bytes: one (port, accepted_sequence) pair per record
 +------------+-------+------+-------------------+------+-------------------+
 | generation | count | port | accepted_sequence | port | accepted_sequence |
 |    u32     |   u8  |  u8  |        u32        |  u8  |        u32        |
 +------------+-------+------+-------------------+------+-------------------+
```

| Button bit | Generic function |
|---|---|
| 0..3 | D-pad up, down, left, right |
| 4..7 | Face south, east, west, north |
| 8..9 | Left, right shoulder |
| 10..11 | Left, right stick click |
| 12..13 | Primary, secondary menu |
| 14..15 | Auxiliary 0, auxiliary 1 |
| 16..17 | Left, right digital trigger (L2, R2) |
| 18..19 | Shift up, shift down |
| 20..31 | Reserved zero |

| Axis index / validity bit | Function | Valid range and neutral |
|---|---|---|
| 0, 1 | Left stick X, Y | -32767..32767; 0 centre |
| 2, 3 | Right stick X, Y | -32767..32767; 0 centre |
| 4, 5 | Left, right trigger (brake, accelerator under a wheel mapping) | 0..32767; 0 released |
| 6 | Steering | -32767..32767; 0 centre |
| 7 | Combined pedals | -32767..32767; negative brake, positive accelerator, 0 released |

| Pressure index / validity bit | Generic button |
|---|---|
| 0..3 | D-pad up, down, left, right (button bits 0..3) |
| 4..7 | Face south, east, west, north (button bits 4..7) |
| 8..9 | Left, right shoulder (button bits 8..9) |
| 10..11 | Left, right digital trigger (button bits 16..17) |

Positive X/steering is right; positive Y is down. -32768 is invalid. valid_axes bits 8..15
and valid_pressure bits 12..15 are zero. Combined axis 7 cannot represent simultaneous
brake and acceleration; a wheel mapping that needs both uses axes 4 and 5. Device
capabilities and limitations expose that distinction rather than claim lossless
representation. A pressure value is valid only together with its button bit: a pressed
button with pressure 0 is BAD_VALUE.

Opposing D-pad bits may arrive together; the adapter resolves up+down and left+right to
neutral independently. Invalid/missing fields map to neutral. Physical triggers represented
digitally can also advertise generic button positions only through an explicit
normalisation/mapping policy, not an unannounced console-dependent substitution.

**Neutral record.** A route whose physical device is absent (none bound yet, removed, lost,
or replaced and awaiting validation) stays in every INPUT with every validity field, value and
counter 0, and `sample_sequence` still increases. The adapter installs it like any other
record, so that port keeps its peripheral identity and presents neutral controls, while the
other records, the generation and the lease are unaffected (`SRS-IN-013`, `SAD-010`). The
hub never omits a configured record and does not inhibit the generation because a device
was removed. A device that supplies every control in the route's source masks resumes in
place with its first fresh sample (the hub sends only controls inside those masks); any
other device keeps the record neutral until the route is amended (`ROUTES_AMEND`).

```text
Figure 13 - One player's device is removed while LIVE (informative)

  Hub                                          Adapter  console: port 0 / port 1
   |                                              |
   |---------- INPUT g=7, seq 801 / 801 --------->|     live / live
   |<----------- INPUT OK (801 / 801) ------------|
   |   [player 1's device is unplugged]           |
   |-- INPUT g=7, seq 802 / 802, port 1 neutral ->|     live / neutral
   |<--- INPUT OK (802 / 802), lease renewed -----|
   |-- INPUT g=7, seq 803 / 803, port 1 neutral ->|     live / neutral
   |<----------- INPUT OK (803 / 803) ------------|
   |   [device plugged in again: fresh sample]    |
   |---------- INPUT g=7, seq 804 / 804 --------->|     live / live
   |<----------- INPUT OK (804 / 804) ------------|

 Two of the four records are shown. "seq a / b" are the sample_sequence values of the
 records for port 0 and port 1; "neutral" means every validity field and value is 0.
 The generation stays 7 and the lease keeps being renewed: nothing is inhibited,
 re-armed or re-routed. A replacement device that lacks a control of the route's masks
 keeps its record neutral until the route is amended.
```

sample_sequence is nonzero and strictly increases per route, from ARM until the generation is cleared, across amendments. Every periodic
snapshot gets a new sequence even if controls are unchanged. The first sequence may be 1;
no wrap. All records must be newer than their last accepted values; after an amendment the
sequences continue under the new generation. Equal/older values return CONFLICT with no
partial installation and no lease renewal. Exact transaction retries return cached
responses instead.

The adapter maps and installs the entire snapshot atomically (per port on a multi-processor
adapter, `SAD-050`), enters LIVE and renews the lease only on full success. Response:
`generation:u32, count:u8, records[count]`, with each record `port:u8,
accepted_sequence:u32` sorted by port. Installation precedes OK.

### REVOKE and lease expiration

REVOKE request: `generation:u32`. Response empty. In the current session, a matching
active/configured generation is neutralised, effects stopped, routes cleared and state
INHIBITED before ACK. Repeating a revoke of that
last generation is OK. After a ROUTES_AMEND whose outcome the hub does not know, REVOKE
naming either the previous generation or the amendment's `new_generation` is accepted. Any
other generation is STALE_GENERATION. Generation 0 is permitted only when already inhibited, as an
idempotent inhibit check. REVOKE cannot cancel an incomplete persistent operation in
maintenance. The hub waits the drain guard after an OK revoke response before arming any
owner, allowing an already latched console transaction to finish. An unacknowledged revoke
instead requires the 110 ms lease guard.

Lease expiry produces the same inhibition locally, clears routes and records a timeout.
Status, feedback, amendment and diagnostic traffic never extends a lease. Only valid new
INPUT or the ARM extends it. On expiry a new ROUTES/ARM is required. A session
change cannot bypass a live lease.

```text
Figure 14 - Ownership switch with an acknowledged revoke (informative)

Old owner                        Hub                        New adapter
   |                              |                              |
   |  [hub stops renewals and     |                              |
   |   cancels queued old INPUT]  |                              |
   |<-------- REVOKE g=7 ---------|                              |
   |  [neutral installed, effects |                              |
   |   stopped, routes cleared]   |                              |
   |--------- REVOKE OK --------->|                              |
   |                              | [drain guard max(2 ms, 2xB)] |
   |                              |--------- ROUTES g=8 -------->|
   |                              |<------ ROUTES OK g=8 --------|  -> CONFIGURED (1)
   |                              |---------- ARM g=8 ---------->|
   |                              |<-------- ARM OK g=8 ---------|  -> ARMED_NEUTRAL (2)
   |                              |--------- INPUT g=8 --------->|
   |                              |<--------- INPUT OK ----------|  -> LIVE (3)

 B is the largest neutralisation_bound_us declared by an enrolled adapter. The hub arms
 the new owner only after the drain guard. SAD-OWN-001 owns the transition policy.
```

```text
Figure 15 - Ownership switch without a revoke acknowledgement (informative)

Old owner                        Hub                        New adapter
   |                              |                              |
   |  [t0: the hub timestamps its |                              |
   |   last possible renewal]     |                              |
   |         X--- REVOKE g=7 -----|                              |
   |  [no reply: the hub cannot   |                              |
   |   know what the node did]    |                              |
   |  [lease expires by itself,   |                              |
   |   neutral within 1 ms]       |                              |
   |                              |  [waits until t0 + 110 ms]   |
   |                              |--------- ROUTES g=8 -------->|
   |                              |<------ ROUTES OK g=8 --------|  -> CONFIGURED (1)
   |                              |---------- ARM g=8 ---------->|
   |                              |<-------- ARM OK g=8 ---------|  -> ARMED_NEUTRAL (2)

 The same wait applies when only the REVOKE reply is lost. Figure 9 shows why 110 ms is
 enough; the hub starts its guard from the latest possible acceptance of the old owner's
 last renewal. SAD-OWN-001 owns the transition policy.
```

## 7. PS-SVC-FEEDBACK

FEEDBACK_POLL request: `ack_event:u32` (0 means none). Response: `present:u8` followed, if 1,
by `event_id:u32, generation:u32, port:u8, player:u8, kind:u8, duration_ms:u16, value0:u16,
value1:u16, value2:u16`.

| Kind | Meaning | value0 | value1 | value2 | duration_ms |
|---|---|---|---|---|---|
| 0 | Rumble | Low-frequency magnitude 0..65535 | High-frequency magnitude 0..65535 | 0 | 1..100 |

| 2 | Constant force | Signed force as i16, positive right | 0 | 0 | 1..100 |
| 3 | Spring | Centre as i16 | Coefficient 0..65535 | Saturation 0..65535 | 1..100 |
| 4 | Damper | 0 | Coefficient 0..65535 | Saturation 0..65535 | 1..100 |
| 5 | Keyboard LEDs | Bit 0 Num Lock, 1 Caps Lock, 2 Scroll Lock, 3 Compose, 4 Kana | 0 | 0 | 0 (state until changed) |

Events are held until acknowledged on a later poll. The hub polls the owner adapter every
2 ms while armed (`PS-TIMING`), so a continuous effect refreshed before its duration ends
(at most 100 ms) is served 50 times over; four routes with rumble and force together use at
most eight of the 50 polls in each 100 ms. The adapter reports the console's native effect
richness; the hub reduces it to what the bound physical device supports (`SAD-FB-001`). The
hub acknowledges only after processing or explicitly discarding a stale/unsupported event
with a diagnostic. It acknowledges duplicates without replaying the effect. Event IDs
increase from 1 within a session, do not wrap; exhaustion inhibits feedback until a new
session. Ack 0 leaves the head queued; ack matching the head removes it; ack equal to the
last removed event is idempotent; other acks are BAD_VALUE. The response then contains the
next event or present=0. Exact request retry returns its cached response and does not
remove a second event.

```text
Figure 16 - Feedback events are acknowledged on the next poll (informative)

  Hub                                              Adapter (owner)
   |                                                      |
   |                                                      |  [console asks for rumble:
   |                                                      |   event 7 queued]
   |------------ FEEDBACK_POLL ack=0 (txn 30) ----------->|
   |                X--- present=1, event 7 (rumble) -----|  [event 7 stays the head]
   |----- FEEDBACK_POLL ack=0 (txn 30, exact retry) ----->|  [cached reply: nothing lost]
   |<---------------- present=1, event 7 -----------------|
   |   [hub starts the effect for its duration]           |
   |------------ FEEDBACK_POLL ack=7 (txn 31) ----------->|  [event 7 removed]
   |<--------- present=1, event 8, or present=0 ----------|

 An event stays at the head of the queue until the hub acknowledges it on a later poll,
 so a lost reply never loses an event. An exact retry returns its cached reply and
 removes nothing.
```

The hub starts duration on receipt, never replays duplicate event IDs and never extends an
effect on a duplicate response. A zero magnitude, force or coefficient stops the effect.
Longer effects require fresh events. Ownership loss stops all effects immediately at the
hub, and the keyboard LED state (kind 5) returns to off. Kind 1 is reserved.

The adapter keeps at most one pending latest event per route and kind (20 at four routes
and five kinds), plus one delivered head retained unchanged until acknowledged (21 slots
maximum). Replacing a pending event increments feedback_overflows and allocates a new event
ID. Changes to the delivered head's route/kind coalesce into its pending slot, not into the
held event. After acknowledging the head, the lowest-ID pending event becomes the new head,
preserving increasing delivery. Revoke/session change clears the queue. Driver and hub
physical-device limitations are reported through diagnostics; support is never inferred
from the presence of a console motor request. The hub resets ack_event to 0 whenever
ownership or session changes.

## 8. PS-MAINTENANCE and generic persistent operations

MAINTENANCE request `enter:u8`; response empty. Entry requires inhibited/no configured
routes, no dirty accessory data, no open live-snapshot token and an annex-proven quiescent
console storage/peripheral interface. Entry may return BUSY while safe local flush is
progressing, or BAD_STATE if quiescence cannot be established. Exit requires no incomplete
operation and all storage handles closed. Exit returns inhibited, never armed.

RESET request `mode:u8` (0 normal reset, 1 recovery boot). Requires INHIBITED or RECOVERY,
no dirty data/incomplete operation, commissioning disabled and no open handles. Mode 1 additionally
requires the physical recovery enable (`ICD-DBG-001`) and restarts the node in RECOVERY.
Reply empty; reset occurs only after ACK transmission. Lost ACK is resolved by boot_id
change and a new HELLO at the node's persisted address, not an assumed success. In RECOVERY
a node answers only HELLO, STATUS, DIAGNOSTICS and RESET; other requests return BAD_STATE.

The following common operation envelope is used by STORAGE, CONFIG and UPDATE. Only one
persistent operation may be active per node. All are maintenance-only, except the
live-snapshot read of `PS-SVC-STORAGE`. Subcommands and exact bodies are defined per
service below. Subcommand is the first request and response byte. Unsupported subcommands
return UNSUPPORTED.

| Common operation | Request fields after subcommand | OK response fields after subcommand |
|---|---|---|
| QUERY (`0x7E`) | `token:u32` | `token:u32, state:u8, result:u8` |
| CLOSE (`0x7F`) | `token:u32` | Empty |

Token is nonzero, node-issued and session-local; not reusable within a session. Only one
token may be open per node, including read or completed tokens; another OPEN or BEGIN
returns BUSY until CLOSE. State 0 STAGING, 1 WORKING, 2 DONE, 3 FAILED. Result is
PS-STATUS, zero unless FAILED. QUERY reports state but does not change it. WORKING
operations are polled, not synchronously waited on. DONE implies service-specific
completion; FAILED exposes the specific error. Stage tokens survive until CLOSE/session
reset, but do not survive power loss; on restart recovery state is queried through STATUS
before any new operation. CLOSE discards STAGING, releases DONE/FAILED, and refuses WORKING
with BUSY. A resource affected by FAILED is not usable until the local backend establishes
consistency.

Chunk length is bounded by the 192-byte total payload. Offset/length arithmetic shall be
checked without overflow; offsets are zero-based. WRITE chunks are strictly contiguous;
the response returns the next offset. An exact transaction retry is safe; a new
transaction for an already consumed offset is CONFLICT. If an ACK is lost and its
transaction cannot be retried, use the relevant PROGRESS subcommand to find the next
offset, not a blind repeated write.

### PS-SVC-STORAGE

Resources, sizes and port bindings come from CAPS kind 1. Byte access abstracts console
media; it does not expose console protocol commands.

| Subcommand | Request after subcommand | OK response after subcommand |
|---|---|---|
| 0 OPEN_READ | `resource:u16, mode:u8` | `token:u32, size:u32` |
| 1 READ | `token:u32, offset:u32, length:u16` | `token:u32, offset:u32, data[length]` |
| 2 OPEN_WRITE | `resource:u16, size:u32` | `token:u32, next_offset:u32` |
| 3 WRITE | `token:u32, offset:u32, data[n]` | `token:u32, next_offset:u32` |
| 4 COMMIT | `token:u32, crc32c:u32` | `token:u32` |
| 5 PROGRESS | `token:u32` | `token:u32, next_offset:u32` |

Read length is 1..183 (response: subcommand 1 + token 4 + offset 4 + data). Write data
length is 1..183 (same overhead). Offsets and lengths must match advertised read/write
granules, except that the final chunk may end exactly at resource size. OPEN_WRITE size
must equal the resource's full size; the service supports full replacement, not
arbitrary live block editing.

OPEN_READ mode 0 (maintenance view) requires MAINTENANCE, locks a stable resource view and
issues a DONE token for reading. OPEN_READ mode 1 (**live snapshot**, `SRS-STO-010`) is
accepted in INHIBITED, CONFIGURED, ARMED_NEUTRAL and LIVE for a resource with flag bit 2,
and issues a WORKING token: the adapter builds the snapshot in its FRAM snapshot region
once the console's storage interface has been idle for the annex's quiet time, restarting
the copy if the console writes during it (`ICD-STO-001`); QUERY then reports DONE and READ
returns snapshot bytes, which stay frozen until CLOSE, or FAILED with result BUSY when the
snapshot is not complete within 2 s of OPEN_READ. READ is accepted only on a DONE
read token. CLOSE releases either view. While armed, the hub schedules live-snapshot reads
in the management slot of `PS-TIMING`.

OPEN_WRITE stages a full replacement, next_offset=0; it requires MAINTENANCE. All bytes
must arrive before COMMIT. CRC-32C covers only the full new resource. COMMIT accepts work
and changes state to WORKING; QUERY DONE means the full replacement is durably installed and
satisfies `SRS-STO-004`. A reset/power loss may leave old or new valid media, never an
acknowledged partially replaced resource.

```text
Figure 17 - Writing one storage resource in maintenance (informative)

  Hub                                    Adapter (no owner)
   |------------- MAINTENANCE enter ------------->|  [needs INHIBITED, no dirty data]
   |<-------------------- OK ---------------------|  -> MAINTENANCE (4)
   |---- STORAGE OPEN_WRITE (resource, size) ---->|  [size = the full resource]
   |<-------- OK token=9, next_offset=0 ----------|  token STAGING
   |---- STORAGE WRITE (token, offset, data) ---->|  [contiguous chunks, <= 183 B]
   |<-------------- OK next_offset ---------------|  (repeat until the end)
   |------- STORAGE COMMIT (token, crc32c) ------>|  [accepted: token WORKING]
   |<-------------------- OK ---------------------|
   |----------- STORAGE QUERY (token) ----------->|  [polled, never waited on]
   |<------------- OK state=WORKING --------------|
   |----------- STORAGE QUERY (token) ----------->|
   |<--------- OK state=DONE, result 0 -----------|  [durably installed]
   |----------- STORAGE CLOSE (token) ----------->|  [token released]
   |<-------------------- OK ---------------------|
   |-------------- MAINTENANCE exit ------------->|
   |<-------------------- OK ---------------------|  -> INHIBITED (0), not armed

 CONFIG and UPDATE follow the same shape. Token states: STAGING, then WORKING after
 COMMIT, then DONE or FAILED; CLOSE is refused with BUSY while WORKING. If a WRITE reply
 is lost, retry the exact request; if its transaction cannot be retried, ask PROGRESS
 for next_offset instead of repeating the chunk blindly. A live snapshot starts with
 OPEN_READ mode 1 instead, without MAINTENANCE.
```

Memory accessories (`SRS-STO-005`) are Storage resources bound to their port: each
accessory is one resource whose `size` is the console-visible capacity (32 KiB or 128 KiB).
The image is the adapter's authoritative copy, including console checksums and identity,
which the network treats as opaque bytes. Because only one token may be open, the
accessories are transferred one after another. In maintenance one accessory takes about
80 ms (32 KiB) or 320 ms (128 KiB) on the bus, so four take about 0.32 s or 1.28 s; a live
export at one chunk every 4 ms takes about 0.72 s or 2.87 s (`ICD-STO-001`). With the FRAM
backend (`SAD-023`) WRITE chunks go straight to the idle bank, COMMIT verifies the staged
image and writes the next bank-select record (tens of milliseconds for 128 KiB).

### PS-SVC-CONFIG

| Subcommand | Request after subcommand | OK response after subcommand |
|---|---|---|
| 0 BEGIN | `profile:u16, size:u16` | `token:u32, next_offset:u32` |
| 1 WRITE | `token:u32, offset:u32, data[n]` | `token:u32, next_offset:u32` |
| 2 COMMIT | `token:u32, crc32c:u32` | `token:u32` |
| 3 PROGRESS | `token:u32` | `token:u32, next_offset:u32` |

Size is 1..the CAPS kind 3 bound (maximum 4096). WRITE n is 1..183. COMMIT requires the
complete blob and validates CRC, profile schema, all cross-field constraints and durable
activation. QUERY DONE means the new configuration is active while inhibited; failure
preserves the previous valid configuration. Read-back is via a read-only Storage resource
bound to port 0xFF; there is no generic interpretation of console-specific configuration.

**OPTION** (opcode 0x41, Configuration service). Request: `subcommand:u8, option:u16,
port:u8` followed for SET by `value:u8`. Response: `subcommand:u8, option:u16, port:u8,
value:u8`. Subcommand 0 GET returns the current value; subcommand 1 SET sets it. Option and
port must match a CAPS kind 5 entry (NOT_FOUND otherwise); value must be below its
`value_count` (BAD_VALUE). SET is accepted only in INHIBITED or CONFIGURED (BAD_STATE
otherwise); it is persisted in the configuration store outside the response window and
takes effect at once, or, for an option with CAPS kind 5 flag bit 0, at the next node reset,
which the hub then requests with RESET mode 0; and a configured route set that the new value makes invalid is cleared
(the node returns to INHIBITED). A persistence failure raises fault 3.

### PS-SVC-UPDATE

| Subcommand | Request after subcommand | OK response after subcommand |
|---|---|---|
| 0 BEGIN | `profile:u16, size:u32` | `token:u32, next_offset:u32` |
| 1 WRITE | `token:u32, offset:u32, data[n]` | `token:u32, next_offset:u32` |
| 2 VERIFY | `token:u32` | `token:u32` |
| 3 PROGRESS | `token:u32` | `token:u32, next_offset:u32` |
| 4 ACTIVATE | `token:u32` | `token:u32` |

The image is the update file of `SAD-PERSIST-001`: a 60-byte header (magic `RPNI`, header
version, header length, target hardware ID, version, image length, SHA-256 of the image,
header CRC-32C) followed by the image. Size is the header length plus the image length,
1..CAPS kind 2 `max_image`; n is 1..183. BEGIN requires MAINTENANCE and selects the profile
(processor role) whose CAPS kind 2 entry it names. WRITE chunks are written into the
inactive image slot of that processor. VERIFY requires the complete image and enters
WORKING; DONE means the header CRC, the magic and version fields, the hardware ID (equal to
the profile's), the length and the SHA-256 of the staged image all checked; FAILED with
INTEGRITY otherwise. ACTIVATE requires DONE and the physical update enable asserted at the
node (BAD_STATE otherwise); it marks the staged slot for a trial boot and resets the
processor after sending its ACK. The node comes back inhibited, with a new boot ID, running
the new image on trial; the image confirms itself after a successful HELLO and self-test
within 60 s, otherwise the boot stage returns to the previous slot (`SAD-030`). CRC and
SHA-256 are integrity checks, not authentication; the physical enable is the authorisation.

### PS-SVC-DIAGNOSTICS

Request: `counter:u16`. Response: `counter:u16, value:u32`. Counters are saturating and
read-only: 0 bad COBS, 1 bad CRC, 2 oversize/partial frame, 3 invalid address/direction, 4
unsupported version, 5 transaction conflict, 6 stale generation, 7 console timing fault, 8
storage failure, 9 watchdog resets, 10 feedback overflow, 11 lease expiry, 12 update
failure, 13 configuration-store failure, 14 internal-link failure. Unknown IDs return
NOT_FOUND. The watchdog-reset counter is kept in the configuration store across boots; the
others restart at zero on boot.

### PS-SVC-PROMPT

PROMPT (opcode 0x70, Adapter display service) makes the adapter display show the
console-specific name of a generic item, so the hub's remapping editor, lossy-approval and
option screens can name console controls without the hub knowing them (`SAD-UI-001`).
Request: `port:u8, item_kind:u8, index:u16, value:u8`. Response empty.

| item_kind | Meaning | index | value |
|---|---|---|---|
| 0 | Clear the prompt | 0 | 0 |
| 1 | Generic button | Button bit 0..31 | 0 |
| 2 | Generic axis | Axis index 0..7 | 0 |
| 3 | Generic pressure position | Pressure index 0..11 | 0 |
| 4 | User option name | Option ID | 0 |
| 5 | User option value name | Option ID | Value |
| 6 | Lossy-mapping notice for the port's route | Mapping ID | 0 |

The port must be advertised (or 0xFF for a device-wide option); an unknown item returns
NOT_FOUND. PROMPT is accepted in every state except RECOVERY, never changes the lease,
routes or console behaviour and is idempotent. The prompt stays displayed until replaced,
cleared, or 60 s have passed.

## 9. Versioning and conformance tests

Unknown opcode/service returns UNSUPPORTED. New incompatible frame/schema semantics require
a new major. A minor version can add explicitly negotiated optional operations, never
reinterpret a field for an existing negotiated minor. Descriptor lists and service support
are tied to boot ID; a change requires re-discovery and no silent hot reinterpretation.
Reserved opcodes, service bits, record kinds, CAPS kinds, feedback kinds and counter IDs
are allocated only by a new minor or major of this specification.

Conformance tests (`SRS-V-004`) include:

- COBS empty, zero and 254-byte-run vectors and maximum frame boundaries.
- CRC check vector, PS-VECTOR-001 and every vector of `PS-VECTORS`.
- Size checks for one to four records of every kind (and rejection of a fifth), a neutral
  record for an absent device, masks, signed axes, pressure validity, counter wrap and all
  enum errors.
- Neutral record while LIVE: removing and reconnecting one player's device leaves the other
  records, the generation and the lease unchanged; a replacement that lacks a control in the
  route masks stays neutral until the route is amended.
- ROUTES_AMEND: amended port neutral before ACK, others live, no lease renewal, old
  generation rejected afterwards, lost ACK retried exactly.
- Duplicate/reordered/lost requests and responses, reboot/session rollover, stale
  generation, lease expiry and lost revoke ACK.
- Commissioning exact-retry after a lost ASSIGN reply, the ASSIGN completion window,
  persisted-address boot, UID mismatch, two enabled nodes, enumeration of several unknown
  nodes and duplicate UIDs.
- Storage/config power-fail, ambiguous COMMIT, token query and failed recovery; live
  snapshot while armed, with and without console writes.
- OPTION get/set, state checks and persistence; PROMPT on every item kind.
- Update: wrong hardware ID, wrong length, wrong SHA-256, activation without the physical
  enable, trial boot without confirmation and rollback.
- Feedback ack retries, stale events, coalescing, 2 ms poll cadence, every feedback kind
  and physical-device expiry.
- Per-opcode timeouts at 8 Mbit/s, one lost INPUT replaced by the next cycle's sample (no
  retry), and every success/timeout combination of the cycle budget finishing inside 1 ms.
- CAPS kinds 0 to 5 and their index bounds; kind 4 value and the hub's derived guards.
- Timing captures at maximum bus, USB and console load.

## Appendix A - PS-VECTORS: message vectors

Generated by script from the definitions above and cross-checked with the RPN-RVP
Appendix B reference code and with two independent implementations of CRC-32C and COBS.
Common values: session `0x1122334455667788` (commissioning frames use session 0), node
address 1 (commissioning destination 255, reply source 254), UID `a0 a1 ... af`, boot ID
`0x0123456789ABCDEF`, transaction IDs from 0x100 upwards; each frame is shown decoded
(header, payload and CRC-32C) and COBS-encoded with its delimiter. Error responses have no
payload; one is given for every PS-STATUS value, using ROUTES. ENUMERATE has no frame
response. QUERY and CLOSE are common operations; their STORAGE vectors apply to CONFIG and
UPDATE with the opcode changed.

**DISCOVER_UID with an all-zero UID (add adapter) and its reply**

```text
Request, decoded (42 bytes):
01 00 01 00 00 ff 00 00 00 01 00 00 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 08 e0 af 63
Request, COBS plus delimiter (44 bytes):
02 01 02 01 01 02 ff 01 01 02 01 01 02 10 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
01 01 01 01 01 01 05 08 e0 af 63 00
Response, decoded (53 bytes):
01 00 01 01 fe 00 00 00 00 01 00 00 1b 00 00 00 00 00 00 00 00 00 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9
aa ab ac ad ae af ef cd ab 89 67 45 23 01 01 00 00 c2 03 bc d4
Response, COBS plus delimiter (55 bytes):
02 01 04 01 01 fe 01 01 01 02 01 01 02 1b 01 01 01 01 01 01 01 01 1a a0 a1 a2 a3 a4 a5 a6 a7 a8
a9 aa ab ac ad ae af ef cd ab 89 67 45 23 01 01 01 05 c2 03 bc d4 00
```

**ASSIGN_UID of address 5**

```text
Request, decoded (51 bytes):
01 00 02 00 00 ff 00 00 01 01 00 00 19 00 00 00 00 00 00 00 00 00 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9
aa ab ac ad ae af ef cd ab 89 67 45 23 01 05 e6 1e 3e cd
Request, COBS plus delimiter (53 bytes):
02 01 02 02 01 02 ff 01 03 01 01 01 02 19 01 01 01 01 01 01 01 01 1e a0 a1 a2 a3 a4 a5 a6 a7 a8
a9 aa ab ac ad ae af ef cd ab 89 67 45 23 01 05 e6 1e 3e cd 00
Response, decoded (51 bytes):
01 00 02 01 fe 00 00 00 01 01 00 00 19 00 00 00 00 00 00 00 00 00 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9
aa ab ac ad ae af ef cd ab 89 67 45 23 01 05 97 54 5a 26
Response, COBS plus delimiter (53 bytes):
02 01 04 02 01 fe 01 01 03 01 01 01 02 19 01 01 01 01 01 01 01 01 1e a0 a1 a2 a3 a4 a5 a6 a7 a8
a9 aa ab ac ad ae af ef cd ab 89 67 45 23 01 05 97 54 5a 26 00
```

**ENUMERATE, prefix of 4 bits (1010); answered by the presence signal only**

```text
Request, decoded (43 bytes):
01 00 08 00 00 ff 00 00 02 01 00 00 11 00 00 00 00 00 00 00 00 00 04 a0 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 aa 58 7e 8d
Request, COBS plus delimiter (45 bytes):
02 01 02 08 01 02 ff 01 03 02 01 01 02 11 01 01 01 01 01 01 01 01 03 04 a0 01 01 01 01 01 01 01
01 01 01 01 01 01 01 05 aa 58 7e 8d 00
```

**HELLO**

```text
Request, decoded (44 bytes):
01 00 03 00 00 01 00 00 03 01 00 00 12 00 88 77 66 55 44 33 22 11 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9
aa ab ac ad ae af 00 00 29 8c 91 af
Request, COBS plus delimiter (46 bytes):
02 01 02 03 01 02 01 01 03 03 01 01 02 12 19 88 77 66 55 44 33 22 11 a0 a1 a2 a3 a4 a5 a6 a7 a8
a9 aa ab ac ad ae af 01 05 29 8c 91 af 00
Response, decoded (60 bytes):
01 00 03 01 01 00 00 00 03 01 00 00 22 00 88 77 66 55 44 33 22 11 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9
aa ab ac ad ae af ef cd ab 89 67 45 23 01 00 7f 00 00 00 04 04 c0 00 00 80 48 ca 7d
Response, COBS plus delimiter (62 bytes):
02 01 04 03 01 01 01 01 03 03 01 01 02 22 21 88 77 66 55 44 33 22 11 a0 a1 a2 a3 a4 a5 a6 a7 a8
a9 aa ab ac ad ae af ef cd ab 89 67 45 23 01 02 7f 01 01 04 04 04 c0 01 05 80 48 ca 7d 00
```

**CAPS kind 0, index 0 (port 0: pad with pressure)**

```text
Request, decoded (29 bytes):
01 00 04 00 00 01 00 00 04 01 00 00 03 00 88 77 66 55 44 33 22 11 00 00 00 30 47 21 9e
Request, COBS plus delimiter (31 bytes):
02 01 02 04 01 02 01 01 03 04 01 01 02 03 09 88 77 66 55 44 33 22 11 01 01 05 30 47 21 9e 00
Response, decoded (54 bytes):
01 00 04 01 01 00 00 00 04 01 00 00 1c 00 88 77 66 55 44 33 22 11 00 00 00 00 00 01 00 01 00 01
ff ff 03 00 ff f0 03 00 3f 00 00 00 ff 0f 00 00 01 01 a0 0c 34 86
Response, COBS plus delimiter (56 bytes):
02 01 04 04 01 01 01 01 03 04 01 01 02 1c 09 88 77 66 55 44 33 22 11 01 01 01 01 02 01 02 01 05
01 ff ff 03 04 ff f0 03 02 3f 01 01 03 ff 0f 01 07 01 01 a0 0c 34 86 00
```

**CAPS kind 1, index 0 (storage resource bound to port 0)**

```text
Request, decoded (29 bytes):
01 00 04 00 00 01 00 00 05 01 00 00 03 00 88 77 66 55 44 33 22 11 01 00 00 11 09 84 64
Request, COBS plus delimiter (31 bytes):
02 01 02 04 01 02 01 01 03 05 01 01 02 03 0a 88 77 66 55 44 33 22 11 01 01 05 11 09 84 64 00
Response, decoded (41 bytes):
01 00 04 01 01 00 00 00 05 01 00 00 0f 00 88 77 66 55 44 33 22 11 01 00 00 01 00 00 00 80 00 00
20 00 20 00 07 74 f5 bb 7a
Response, COBS plus delimiter (43 bytes):
02 01 04 04 01 01 01 01 03 05 01 01 02 0f 0a 88 77 66 55 44 33 22 11 01 01 02 01 01 01 02 80 01
02 20 02 20 06 07 74 f5 bb 7a 00
```

**CAPS kind 2, index 0 (update profile)**

```text
Request, decoded (29 bytes):
01 00 04 00 00 01 00 00 06 01 00 00 03 00 88 77 66 55 44 33 22 11 02 00 00 83 ad 87 6e
Request, COBS plus delimiter (31 bytes):
02 01 02 04 01 02 01 01 03 06 01 01 02 03 0a 88 77 66 55 44 33 22 11 02 01 05 83 ad 87 6e 00
Response, decoded (40 bytes):
01 00 04 01 01 00 00 00 06 01 00 00 0e 00 88 77 66 55 44 33 22 11 02 00 00 01 00 01 00 01 00 00
00 10 00 01 32 67 eb b2
Response, COBS plus delimiter (42 bytes):
02 01 04 04 01 01 01 01 03 06 01 01 02 0e 0a 88 77 66 55 44 33 22 11 02 01 02 01 02 01 02 01 01
01 02 10 06 01 32 67 eb b2 00
```

**CAPS kind 3, index 0 (configuration profile)**

```text
Request, decoded (29 bytes):
01 00 04 00 00 01 00 00 07 01 00 00 03 00 88 77 66 55 44 33 22 11 03 00 00 a2 e3 22 94
Request, COBS plus delimiter (31 bytes):
02 01 02 04 01 02 01 01 03 07 01 01 02 03 0a 88 77 66 55 44 33 22 11 03 01 05 a2 e3 22 94 00
Response, decoded (33 bytes):
01 00 04 01 01 00 00 00 07 01 00 00 07 00 88 77 66 55 44 33 22 11 03 00 00 01 00 00 10 ad 26 e0
36
Response, COBS plus delimiter (35 bytes):
02 01 04 04 01 01 01 01 03 07 01 01 02 07 0a 88 77 66 55 44 33 22 11 03 01 02 01 01 06 10 ad 26
e0 36 00
```

**CAPS kind 4, index 0 (neutralisation bound 250 us)**

```text
Request, decoded (29 bytes):
01 00 04 00 00 01 00 00 08 01 00 00 03 00 88 77 66 55 44 33 22 11 04 00 00 bd eb 7e 8e
Request, COBS plus delimiter (31 bytes):
02 01 02 04 01 02 01 01 03 08 01 01 02 03 0a 88 77 66 55 44 33 22 11 04 01 05 bd eb 7e 8e 00
Response, decoded (31 bytes):
01 00 04 01 01 00 00 00 08 01 00 00 05 00 88 77 66 55 44 33 22 11 04 00 00 fa 00 39 51 e1 c9
Response, COBS plus delimiter (33 bytes):
02 01 04 04 01 01 01 01 03 08 01 01 02 05 0a 88 77 66 55 44 33 22 11 04 01 02 fa 05 39 51 e1 c9
00
```

**CAPS kind 5, index 0 (device-wide user option 1, two values, default 0, takes effect after reset)**

```text
Request, decoded (29 bytes):
01 00 04 00 00 01 00 00 09 01 00 00 03 00 88 77 66 55 44 33 22 11 05 00 00 9c a5 db 74
Request, COBS plus delimiter (31 bytes):
02 01 02 04 01 02 01 01 03 09 01 01 02 03 0a 88 77 66 55 44 33 22 11 05 01 05 9c a5 db 74 00
Response, decoded (35 bytes):
01 00 04 01 01 00 00 00 09 01 00 00 09 00 88 77 66 55 44 33 22 11 05 00 00 01 00 ff 02 00 01 86
e0 75 bf
Response, COBS plus delimiter (37 bytes):
02 01 04 04 01 01 01 01 03 09 01 01 02 09 0a 88 77 66 55 44 33 22 11 05 01 02 01 03 ff 02 06 01
86 e0 75 bf 00
```

**STATUS (state LIVE, activity ACTIVE)**

```text
Request, decoded (26 bytes):
01 00 05 00 00 01 00 00 0a 01 00 00 00 00 88 77 66 55 44 33 22 11 20 5b 82 cb
Request, COBS plus delimiter (28 bytes):
02 01 02 05 01 02 01 01 03 0a 01 01 01 01 0d 88 77 66 55 44 33 22 11 20 5b 82 cb 00
Response, decoded (50 bytes):
01 00 05 01 01 00 00 00 0a 01 00 00 18 00 88 77 66 55 44 33 22 11 03 02 00 00 07 00 00 00 62 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 c6 c8 80 97
Response, COBS plus delimiter (52 bytes):
02 01 04 05 01 01 01 01 03 0a 01 01 02 18 0b 88 77 66 55 44 33 22 11 03 02 01 02 07 01 01 02 62
01 01 01 01 01 01 01 01 01 01 01 01 01 01 05 c6 c8 80 97 00
```

**REVOKE of generation 7**

```text
Request, decoded (30 bytes):
01 00 06 00 00 01 00 00 0b 01 00 00 04 00 88 77 66 55 44 33 22 11 07 00 00 00 2a b3 dc f4
Request, COBS plus delimiter (32 bytes):
02 01 02 06 01 02 01 01 03 0b 01 01 02 04 0a 88 77 66 55 44 33 22 11 07 01 01 05 2a b3 dc f4 00
Response, decoded (26 bytes):
01 00 06 01 01 00 00 00 0b 01 00 00 00 00 88 77 66 55 44 33 22 11 32 84 f7 2f
Response, COBS plus delimiter (28 bytes):
02 01 04 06 01 01 01 01 03 0b 01 01 01 01 0d 88 77 66 55 44 33 22 11 32 84 f7 2f 00
```

**RESET, mode 0**

```text
Request, decoded (27 bytes):
01 00 07 00 00 01 00 00 0c 01 00 00 01 00 88 77 66 55 44 33 22 11 00 38 2b a4 ab
Request, COBS plus delimiter (29 bytes):
02 01 02 07 01 02 01 01 03 0c 01 01 02 01 09 88 77 66 55 44 33 22 11 05 38 2b a4 ab 00
Response, decoded (26 bytes):
01 00 07 01 01 00 00 00 0c 01 00 00 00 00 88 77 66 55 44 33 22 11 ac af 4c b1
Response, COBS plus delimiter (28 bytes):
02 01 04 07 01 01 01 01 03 0c 01 01 01 01 0d 88 77 66 55 44 33 22 11 ac af 4c b1 00
```

**ROUTES, generation 7, four routes**

```text
Request, decoded (91 bytes):
01 00 10 00 00 01 00 00 0d 01 00 00 41 00 88 77 66 55 44 33 22 11 07 00 00 00 04 00 00 01 00 01
00 ff ff 03 00 3f 00 ff 0f 00 01 01 02 00 02 00 1f 00 00 00 07 00 00 00 00 02 02 03 00 03 00 03
00 00 00 00 00 00 00 00 03 03 04 00 04 00 ff f0 00 00 03 00 00 00 01 2c 9b 06 72
Request, COBS plus delimiter (93 bytes):
02 01 02 10 01 02 01 01 03 0d 01 01 02 41 0a 88 77 66 55 44 33 22 11 07 01 01 02 04 01 02 01 02
01 04 ff ff 03 02 3f 03 ff 0f 04 01 01 02 02 02 02 1f 01 01 02 07 01 01 01 04 02 02 03 02 03 02
03 01 01 01 01 01 01 01 04 03 03 04 02 04 03 ff f0 01 02 03 01 01 06 01 2c 9b 06 72 00
Response, decoded (30 bytes):
01 00 10 01 01 00 00 00 0d 01 00 00 04 00 88 77 66 55 44 33 22 11 07 00 00 00 fd cc 59 e5
Response, COBS plus delimiter (32 bytes):
02 01 04 10 01 01 01 01 03 0d 01 01 02 04 0a 88 77 66 55 44 33 22 11 07 01 01 05 fd cc 59 e5 00
```

**ARM, generation 7**

```text
Request, decoded (30 bytes):
01 00 11 00 00 01 00 00 0e 01 00 00 04 00 88 77 66 55 44 33 22 11 07 00 00 00 6f 6b 61 6a
Request, COBS plus delimiter (32 bytes):
02 01 02 11 01 02 01 01 03 0e 01 01 02 04 0a 88 77 66 55 44 33 22 11 07 01 01 05 6f 6b 61 6a 00
Response, decoded (30 bytes):
01 00 11 01 01 00 00 00 0e 01 00 00 04 00 88 77 66 55 44 33 22 11 07 00 00 00 0e 08 ad 4e
Response, COBS plus delimiter (32 bytes):
02 01 04 11 01 01 01 01 03 0e 01 01 02 04 0a 88 77 66 55 44 33 22 11 07 01 01 05 0e 08 ad 4e 00
```

**INPUT, generation 7: pad with pressure, pointer, keyboard and a neutral pad record**

```text
Request, decoded (137 bytes):
01 00 12 00 00 01 00 00 0f 01 00 00 6f 00 88 77 66 55 44 33 22 11 07 00 00 00 04 00 00 21 03 00
00 ff ff 03 00 11 00 01 00 3f 00 b0 04 b8 f2 00 00 00 00 ff 7f 00 00 00 00 00 00 ff 0f 00 00 00
00 ff 00 00 00 00 00 80 00 01 01 21 03 00 00 07 01 34 12 f0 ff 02 00 02 02 21 03 00 00 01 02 04
16 00 00 00 00 03 03 21 03 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 b1 2f 65 b4
Request, COBS plus delimiter (139 bytes):
02 01 02 12 01 02 01 01 03 0f 01 01 02 6f 0a 88 77 66 55 44 33 22 11 07 01 01 02 04 01 03 21 03
01 04 ff ff 03 02 11 02 01 02 3f 05 b0 04 b8 f2 01 01 01 03 ff 7f 01 01 01 01 01 03 ff 0f 01 01
01 02 ff 01 01 01 01 02 80 05 01 01 21 03 01 08 07 01 34 12 f0 ff 02 05 02 02 21 03 01 05 01 02
04 16 01 01 01 05 03 03 21 03 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01
01 01 01 01 01 05 b1 2f 65 b4 00
Response, decoded (51 bytes):
01 00 12 01 01 00 00 00 0f 01 00 00 19 00 88 77 66 55 44 33 22 11 07 00 00 00 04 00 21 03 00 00
01 21 03 00 00 02 21 03 00 00 03 21 03 00 00 c3 da ea 3e
Response, COBS plus delimiter (53 bytes):
02 01 04 12 01 01 01 01 03 0f 01 01 02 19 0a 88 77 66 55 44 33 22 11 07 01 01 02 04 03 21 03 01
04 01 21 03 01 04 02 21 03 01 04 03 21 03 01 05 c3 da ea 3e 00
```

**ROUTES_AMEND of port 3 to generation 8**

```text
Request, decoded (49 bytes):
01 00 13 00 00 01 00 00 10 01 00 00 17 00 88 77 66 55 44 33 22 11 07 00 00 00 08 00 00 00 03 03
04 00 05 00 ff ff 03 00 3f 00 00 00 01 d0 d4 17 7b
Request, COBS plus delimiter (51 bytes):
02 01 02 13 01 02 01 01 03 10 01 01 02 17 0a 88 77 66 55 44 33 22 11 07 01 01 02 08 01 01 04 03
03 04 02 05 04 ff ff 03 02 3f 01 01 06 01 d0 d4 17 7b 00
Response, decoded (30 bytes):
01 00 13 01 01 00 00 00 10 01 00 00 04 00 88 77 66 55 44 33 22 11 08 00 00 00 dd 1f 34 7e
Response, COBS plus delimiter (32 bytes):
02 01 04 13 01 01 01 01 03 10 01 01 02 04 0a 88 77 66 55 44 33 22 11 08 01 01 05 dd 1f 34 7e 00
```

**FEEDBACK_POLL, nothing pending**

```text
Request, decoded (30 bytes):
01 00 20 00 00 01 00 00 11 01 00 00 04 00 88 77 66 55 44 33 22 11 00 00 00 00 6e 56 f8 e3
Request, COBS plus delimiter (32 bytes):
02 01 02 20 01 02 01 01 03 11 01 01 02 04 09 88 77 66 55 44 33 22 11 01 01 01 05 6e 56 f8 e3 00
Response, decoded (27 bytes):
01 00 20 01 01 00 00 00 11 01 00 00 01 00 88 77 66 55 44 33 22 11 00 42 c2 bd 07
Response, COBS plus delimiter (29 bytes):
02 01 04 20 01 01 01 01 03 11 01 01 02 01 09 88 77 66 55 44 33 22 11 05 42 c2 bd 07 00
```

**FEEDBACK_POLL acknowledging event 6, rumble event 7 returned**

```text
Request, decoded (30 bytes):
01 00 20 00 00 01 00 00 12 01 00 00 04 00 88 77 66 55 44 33 22 11 06 00 00 00 61 42 06 36
Request, COBS plus delimiter (32 bytes):
02 01 02 20 01 02 01 01 03 12 01 01 02 04 0a 88 77 66 55 44 33 22 11 06 01 01 05 61 42 06 36 00
Response, decoded (46 bytes):
01 00 20 01 01 00 00 00 12 01 00 00 14 00 88 77 66 55 44 33 22 11 01 07 00 00 00 08 00 00 00 00
00 00 64 00 00 80 00 40 00 00 13 48 e2 0c
Response, COBS plus delimiter (48 bytes):
02 01 04 20 01 01 01 01 03 12 01 01 02 14 0b 88 77 66 55 44 33 22 11 01 07 01 01 02 08 01 01 01
01 01 02 64 01 02 80 02 40 01 05 13 48 e2 0c 00
```

**MAINTENANCE enter**

```text
Request, decoded (27 bytes):
01 00 30 00 00 01 00 00 13 01 00 00 01 00 88 77 66 55 44 33 22 11 01 e2 dc 7d 6b
Request, COBS plus delimiter (29 bytes):
02 01 02 30 01 02 01 01 03 13 01 01 02 01 0e 88 77 66 55 44 33 22 11 01 e2 dc 7d 6b 00
Response, decoded (26 bytes):
01 00 30 01 01 00 00 00 13 01 00 00 00 00 88 77 66 55 44 33 22 11 7e 2a a9 eb
Response, COBS plus delimiter (28 bytes):
02 01 04 30 01 01 01 01 03 13 01 01 01 01 0d 88 77 66 55 44 33 22 11 7e 2a a9 eb 00
```

**STORAGE OPEN_READ, resource 1, live snapshot**

```text
Request, decoded (30 bytes):
01 00 31 00 00 01 00 00 14 01 00 00 04 00 88 77 66 55 44 33 22 11 00 01 00 01 61 8b fb b9
Request, COBS plus delimiter (32 bytes):
02 01 02 31 01 02 01 01 03 14 01 01 02 04 09 88 77 66 55 44 33 22 11 02 01 06 01 61 8b fb b9 00
Response, decoded (35 bytes):
01 00 31 01 01 00 00 00 14 01 00 00 09 00 88 77 66 55 44 33 22 11 00 09 00 00 00 00 80 00 00 08
04 9c d7
Response, COBS plus delimiter (37 bytes):
02 01 04 31 01 01 01 01 03 14 01 01 02 09 09 88 77 66 55 44 33 22 11 02 09 01 01 01 02 80 01 05
08 04 9c d7 00
```

**STORAGE READ, 16 bytes at offset 0**

```text
Request, decoded (37 bytes):
01 00 31 00 00 01 00 00 15 01 00 00 0b 00 88 77 66 55 44 33 22 11 01 09 00 00 00 00 00 00 00 10
00 aa 16 ac 19
Request, COBS plus delimiter (39 bytes):
02 01 02 31 01 02 01 01 03 15 01 01 02 0b 0b 88 77 66 55 44 33 22 11 01 09 01 01 01 01 01 01 02
10 05 aa 16 ac 19 00
Response, decoded (51 bytes):
01 00 31 01 01 00 00 00 15 01 00 00 19 00 88 77 66 55 44 33 22 11 01 09 00 00 00 00 00 00 00 00
01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 2d cb ab e4
Response, COBS plus delimiter (53 bytes):
02 01 04 31 01 01 01 01 03 15 01 01 02 19 0b 88 77 66 55 44 33 22 11 01 09 01 01 01 01 01 01 01
14 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 2d cb ab e4 00
```

**STORAGE OPEN_WRITE, resource 1, 32 KiB**

```text
Request, decoded (33 bytes):
01 00 31 00 00 01 00 00 16 01 00 00 07 00 88 77 66 55 44 33 22 11 02 01 00 00 80 00 00 b6 04 8e
a7
Request, COBS plus delimiter (35 bytes):
02 01 02 31 01 02 01 01 03 16 01 01 02 07 0b 88 77 66 55 44 33 22 11 02 01 01 02 80 01 05 b6 04
8e a7 00
Response, decoded (35 bytes):
01 00 31 01 01 00 00 00 16 01 00 00 09 00 88 77 66 55 44 33 22 11 02 0a 00 00 00 00 00 00 00 33
ce c9 81
Response, COBS plus delimiter (37 bytes):
02 01 04 31 01 01 01 01 03 16 01 01 02 09 0b 88 77 66 55 44 33 22 11 02 0a 01 01 01 01 01 01 05
33 ce c9 81 00
```

**STORAGE WRITE, 16 bytes at offset 0**

```text
Request, decoded (51 bytes):
01 00 31 00 00 01 00 00 17 01 00 00 19 00 88 77 66 55 44 33 22 11 03 0a 00 00 00 00 00 00 00 00
01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f b6 e6 df 33
Request, COBS plus delimiter (53 bytes):
02 01 02 31 01 02 01 01 03 17 01 01 02 19 0b 88 77 66 55 44 33 22 11 03 0a 01 01 01 01 01 01 01
14 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f b6 e6 df 33 00
Response, decoded (35 bytes):
01 00 31 01 01 00 00 00 17 01 00 00 09 00 88 77 66 55 44 33 22 11 03 0a 00 00 00 10 00 00 00 7e
59 40 e9
Response, COBS plus delimiter (37 bytes):
02 01 04 31 01 01 01 01 03 17 01 01 02 09 0b 88 77 66 55 44 33 22 11 03 0a 01 01 02 10 01 01 05
7e 59 40 e9 00
```

**STORAGE COMMIT**

```text
Request, decoded (35 bytes):
01 00 31 00 00 01 00 00 18 01 00 00 09 00 88 77 66 55 44 33 22 11 04 0a 00 00 00 78 56 34 12 7c
51 c9 00
Request, COBS plus delimiter (37 bytes):
02 01 02 31 01 02 01 01 03 18 01 01 02 09 0b 88 77 66 55 44 33 22 11 04 0a 01 01 08 78 56 34 12
7c 51 c9 01 00
Response, decoded (31 bytes):
01 00 31 01 01 00 00 00 18 01 00 00 05 00 88 77 66 55 44 33 22 11 04 0a 00 00 00 d3 41 5d 66
Response, COBS plus delimiter (33 bytes):
02 01 04 31 01 01 01 01 03 18 01 01 02 05 0b 88 77 66 55 44 33 22 11 04 0a 01 01 05 d3 41 5d 66
00
```

**STORAGE PROGRESS**

```text
Request, decoded (31 bytes):
01 00 31 00 00 01 00 00 19 01 00 00 05 00 88 77 66 55 44 33 22 11 05 0a 00 00 00 9a be fe 74
Request, COBS plus delimiter (33 bytes):
02 01 02 31 01 02 01 01 03 19 01 01 02 05 0b 88 77 66 55 44 33 22 11 05 0a 01 01 05 9a be fe 74
00
Response, decoded (35 bytes):
01 00 31 01 01 00 00 00 19 01 00 00 09 00 88 77 66 55 44 33 22 11 05 0a 00 00 00 10 00 00 00 9e
0d b1 43
Response, COBS plus delimiter (37 bytes):
02 01 04 31 01 01 01 01 03 19 01 01 02 09 0b 88 77 66 55 44 33 22 11 05 0a 01 01 02 10 01 01 05
9e 0d b1 43 00
```

**STORAGE QUERY (common operation 7Eh): state DONE**

```text
Request, decoded (31 bytes):
01 00 31 00 00 01 00 00 1a 01 00 00 05 00 88 77 66 55 44 33 22 11 7e 0a 00 00 00 0d 18 d0 94
Request, COBS plus delimiter (33 bytes):
02 01 02 31 01 02 01 01 03 1a 01 01 02 05 0b 88 77 66 55 44 33 22 11 7e 0a 01 01 05 0d 18 d0 94
00
Response, decoded (33 bytes):
01 00 31 01 01 00 00 00 1a 01 00 00 07 00 88 77 66 55 44 33 22 11 7e 0a 00 00 00 02 00 fd 43 83
8a
Response, COBS plus delimiter (35 bytes):
02 01 04 31 01 01 01 01 03 1a 01 01 02 07 0b 88 77 66 55 44 33 22 11 7e 0a 01 01 02 02 05 fd 43
83 8a 00
```

**STORAGE CLOSE (common operation 7Fh)**

```text
Request, decoded (31 bytes):
01 00 31 00 00 01 00 00 1b 01 00 00 05 00 88 77 66 55 44 33 22 11 7f 0a 00 00 00 46 3b fa 15
Request, COBS plus delimiter (33 bytes):
02 01 02 31 01 02 01 01 03 1b 01 01 02 05 0b 88 77 66 55 44 33 22 11 7f 0a 01 01 05 46 3b fa 15
00
Response, decoded (27 bytes):
01 00 31 01 01 00 00 00 1b 01 00 00 01 00 88 77 66 55 44 33 22 11 7f 4f 80 c5 08
Response, COBS plus delimiter (29 bytes):
02 01 04 31 01 01 01 01 03 1b 01 01 02 01 0e 88 77 66 55 44 33 22 11 7f 4f 80 c5 08 00
```

**CONFIG BEGIN, profile 1, 64 bytes**

```text
Request, decoded (31 bytes):
01 00 40 00 00 01 00 00 1c 01 00 00 05 00 88 77 66 55 44 33 22 11 00 01 00 40 00 25 5b d4 2f
Request, COBS plus delimiter (33 bytes):
02 01 02 40 01 02 01 01 03 1c 01 01 02 05 09 88 77 66 55 44 33 22 11 02 01 02 40 05 25 5b d4 2f
00
Response, decoded (35 bytes):
01 00 40 01 01 00 00 00 1c 01 00 00 09 00 88 77 66 55 44 33 22 11 00 0b 00 00 00 00 00 00 00 2f
f5 d8 6c
Response, COBS plus delimiter (37 bytes):
02 01 04 40 01 01 01 01 03 1c 01 01 02 09 09 88 77 66 55 44 33 22 11 02 0b 01 01 01 01 01 01 05
2f f5 d8 6c 00
```

**CONFIG WRITE, 8 bytes at offset 0**

```text
Request, decoded (43 bytes):
01 00 40 00 00 01 00 00 1d 01 00 00 11 00 88 77 66 55 44 33 22 11 01 0b 00 00 00 00 00 00 00 01
02 03 04 05 06 07 08 c5 a9 29 eb
Request, COBS plus delimiter (45 bytes):
02 01 02 40 01 02 01 01 03 1d 01 01 02 11 0b 88 77 66 55 44 33 22 11 01 0b 01 01 01 01 01 01 0d
01 02 03 04 05 06 07 08 c5 a9 29 eb 00
Response, decoded (35 bytes):
01 00 40 01 01 00 00 00 1d 01 00 00 09 00 88 77 66 55 44 33 22 11 01 0b 00 00 00 08 00 00 00 b9
b0 71 1b
Response, COBS plus delimiter (37 bytes):
02 01 04 40 01 01 01 01 03 1d 01 01 02 09 0b 88 77 66 55 44 33 22 11 01 0b 01 01 02 08 01 01 05
b9 b0 71 1b 00
```

**CONFIG COMMIT**

```text
Request, decoded (35 bytes):
01 00 40 00 00 01 00 00 1e 01 00 00 09 00 88 77 66 55 44 33 22 11 02 0b 00 00 00 ef cd ab 89 8f
66 7f e2
Request, COBS plus delimiter (37 bytes):
02 01 02 40 01 02 01 01 03 1e 01 01 02 09 0b 88 77 66 55 44 33 22 11 02 0b 01 01 09 ef cd ab 89
8f 66 7f e2 00
Response, decoded (31 bytes):
01 00 40 01 01 00 00 00 1e 01 00 00 05 00 88 77 66 55 44 33 22 11 02 0b 00 00 00 23 31 d1 0d
Response, COBS plus delimiter (33 bytes):
02 01 04 40 01 01 01 01 03 1e 01 01 02 05 0b 88 77 66 55 44 33 22 11 02 0b 01 01 05 23 31 d1 0d
00
```

**CONFIG PROGRESS**

```text
Request, decoded (31 bytes):
01 00 40 00 00 01 00 00 1f 01 00 00 05 00 88 77 66 55 44 33 22 11 03 0b 00 00 00 6a ce 72 1f
Request, COBS plus delimiter (33 bytes):
02 01 02 40 01 02 01 01 03 1f 01 01 02 05 0b 88 77 66 55 44 33 22 11 03 0b 01 01 05 6a ce 72 1f
00
Response, decoded (35 bytes):
01 00 40 01 01 00 00 00 1f 01 00 00 09 00 88 77 66 55 44 33 22 11 03 0b 00 00 00 08 00 00 00 a8
8a 47 1d
Response, COBS plus delimiter (37 bytes):
02 01 04 40 01 01 01 01 03 1f 01 01 02 09 0b 88 77 66 55 44 33 22 11 03 0b 01 01 02 08 01 01 05
a8 8a 47 1d 00
```

**OPTION GET, option 1, port 0**

```text
Request, decoded (30 bytes):
01 00 41 00 00 01 00 00 20 01 00 00 04 00 88 77 66 55 44 33 22 11 00 01 00 00 9d 97 0d fe
Request, COBS plus delimiter (32 bytes):
02 01 02 41 01 02 01 01 03 20 01 01 02 04 09 88 77 66 55 44 33 22 11 02 01 01 05 9d 97 0d fe 00
Response, decoded (31 bytes):
01 00 41 01 01 00 00 00 20 01 00 00 05 00 88 77 66 55 44 33 22 11 00 01 00 00 00 01 cf 04 8b
Response, COBS plus delimiter (33 bytes):
02 01 04 41 01 01 01 01 03 20 01 01 02 05 09 88 77 66 55 44 33 22 11 02 01 01 01 05 01 cf 04 8b
00
```

**OPTION SET, option 1, port 0, value 1**

```text
Request, decoded (31 bytes):
01 00 41 00 00 01 00 00 21 01 00 00 05 00 88 77 66 55 44 33 22 11 01 01 00 00 01 4b b3 cc 6b
Request, COBS plus delimiter (33 bytes):
02 01 02 41 01 02 01 01 03 21 01 01 02 05 0b 88 77 66 55 44 33 22 11 01 01 01 06 01 4b b3 cc 6b
00
Response, decoded (31 bytes):
01 00 41 01 01 00 00 00 21 01 00 00 05 00 88 77 66 55 44 33 22 11 01 01 00 00 01 49 6f 45 f8
Response, COBS plus delimiter (33 bytes):
02 01 04 41 01 01 01 01 03 21 01 01 02 05 0b 88 77 66 55 44 33 22 11 01 01 01 06 01 49 6f 45 f8
00
```

**DIAGNOSTICS, counter 1 (bad CRC)**

```text
Request, decoded (28 bytes):
01 00 50 00 00 01 00 00 22 01 00 00 02 00 88 77 66 55 44 33 22 11 01 00 d3 86 3a 2a
Request, COBS plus delimiter (30 bytes):
02 01 02 50 01 02 01 01 03 22 01 01 02 02 0a 88 77 66 55 44 33 22 11 01 05 d3 86 3a 2a 00
Response, decoded (32 bytes):
01 00 50 01 01 00 00 00 22 01 00 00 06 00 88 77 66 55 44 33 22 11 01 00 03 00 00 00 85 ff 7f 94
Response, COBS plus delimiter (34 bytes):
02 01 04 50 01 01 01 01 03 22 01 01 02 06 0a 88 77 66 55 44 33 22 11 01 02 03 01 01 05 85 ff 7f
94 00
```

**UPDATE BEGIN, profile 1, 1 MiB**

```text
Request, decoded (33 bytes):
01 00 60 00 00 01 00 00 23 01 00 00 07 00 88 77 66 55 44 33 22 11 00 01 00 00 00 10 00 6e d6 21
e9
Request, COBS plus delimiter (35 bytes):
02 01 02 60 01 02 01 01 03 23 01 01 02 07 09 88 77 66 55 44 33 22 11 02 01 01 01 02 10 05 6e d6
21 e9 00
Response, decoded (35 bytes):
01 00 60 01 01 00 00 00 23 01 00 00 09 00 88 77 66 55 44 33 22 11 00 0c 00 00 00 00 00 00 00 46
03 87 21
Response, COBS plus delimiter (37 bytes):
02 01 04 60 01 01 01 01 03 23 01 01 02 09 09 88 77 66 55 44 33 22 11 02 0c 01 01 01 01 01 01 05
46 03 87 21 00
```

**UPDATE WRITE, 8 bytes at offset 0**

```text
Request, decoded (43 bytes):
01 00 60 00 00 01 00 00 24 01 00 00 11 00 88 77 66 55 44 33 22 11 01 0c 00 00 00 00 00 00 00 52
50 4e 49 01 00 3c 00 4f 30 81 1b
Request, COBS plus delimiter (45 bytes):
02 01 02 60 01 02 01 01 03 24 01 01 02 11 0b 88 77 66 55 44 33 22 11 01 0c 01 01 01 01 01 01 06
52 50 4e 49 01 02 3c 05 4f 30 81 1b 00
Response, decoded (35 bytes):
01 00 60 01 01 00 00 00 24 01 00 00 09 00 88 77 66 55 44 33 22 11 01 0c 00 00 00 08 00 00 00 b1
10 2a 6f
Response, COBS plus delimiter (37 bytes):
02 01 04 60 01 01 01 01 03 24 01 01 02 09 0b 88 77 66 55 44 33 22 11 01 0c 01 01 02 08 01 01 05
b1 10 2a 6f 00
```

**UPDATE VERIFY**

```text
Request, decoded (31 bytes):
01 00 60 00 00 01 00 00 25 01 00 00 05 00 88 77 66 55 44 33 22 11 02 0c 00 00 00 67 b3 72 94
Request, COBS plus delimiter (33 bytes):
02 01 02 60 01 02 01 01 03 25 01 01 02 05 0b 88 77 66 55 44 33 22 11 02 0c 01 01 05 67 b3 72 94
00
Response, decoded (31 bytes):
01 00 60 01 01 00 00 00 25 01 00 00 05 00 88 77 66 55 44 33 22 11 02 0c 00 00 00 65 6f fb 07
Response, COBS plus delimiter (33 bytes):
02 01 04 60 01 01 01 01 03 25 01 01 02 05 0b 88 77 66 55 44 33 22 11 02 0c 01 01 05 65 6f fb 07
00
```

**UPDATE PROGRESS**

```text
Request, decoded (31 bytes):
01 00 60 00 00 01 00 00 26 01 00 00 05 00 88 77 66 55 44 33 22 11 03 0c 00 00 00 13 7f c2 62
Request, COBS plus delimiter (33 bytes):
02 01 02 60 01 02 01 01 03 26 01 01 02 05 0b 88 77 66 55 44 33 22 11 03 0c 01 01 05 13 7f c2 62
00
Response, decoded (35 bytes):
01 00 60 01 01 00 00 00 26 01 00 00 09 00 88 77 66 55 44 33 22 11 03 0c 00 00 00 08 00 00 00 a0
2a 1c 69
Response, COBS plus delimiter (37 bytes):
02 01 04 60 01 01 01 01 03 26 01 01 02 09 0b 88 77 66 55 44 33 22 11 03 0c 01 01 02 08 01 01 05
a0 2a 1c 69 00
```

**UPDATE ACTIVATE**

```text
Request, decoded (31 bytes):
01 00 60 00 00 01 00 00 27 01 00 00 05 00 88 77 66 55 44 33 22 11 04 0c 00 00 00 b0 3d 8f 73
Request, COBS plus delimiter (33 bytes):
02 01 02 60 01 02 01 01 03 27 01 01 02 05 0b 88 77 66 55 44 33 22 11 04 0c 01 01 05 b0 3d 8f 73
00
Response, decoded (31 bytes):
01 00 60 01 01 00 00 00 27 01 00 00 05 00 88 77 66 55 44 33 22 11 04 0c 00 00 00 b2 e1 06 e0
Response, COBS plus delimiter (33 bytes):
02 01 04 60 01 01 01 01 03 27 01 01 02 05 0b 88 77 66 55 44 33 22 11 04 0c 01 01 05 b2 e1 06 e0
00
```

**PROMPT, port 0, generic button 4 (face south)**

```text
Request, decoded (31 bytes):
01 00 70 00 00 01 00 00 28 01 00 00 05 00 88 77 66 55 44 33 22 11 00 01 04 00 00 2e 3c b0 4f
Request, COBS plus delimiter (33 bytes):
02 01 02 70 01 02 01 01 03 28 01 01 02 05 09 88 77 66 55 44 33 22 11 03 01 04 01 05 2e 3c b0 4f
00
Response, decoded (26 bytes):
01 00 70 01 01 00 00 00 28 01 00 00 00 00 88 77 66 55 44 33 22 11 64 6c f8 a7
Response, COBS plus delimiter (28 bytes):
02 01 04 70 01 01 01 01 03 28 01 01 01 01 0d 88 77 66 55 44 33 22 11 64 6c f8 a7 00
```

**Error response UNSUPPORTED (0x01) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 01 00 29 01 00 00 00 00 88 77 66 55 44 33 22 11 a7 00 27 18
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 01 03 29 01 01 01 01 0a 88 77 66 55 44 33 22 11 a7 03 27 18 00
```

**Error response BAD_LENGTH (0x02) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 02 00 2a 01 00 00 00 00 88 77 66 55 44 33 22 11 9e 9f d6 f7
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 02 03 2a 01 01 01 01 0d 88 77 66 55 44 33 22 11 9e 9f d6 f7 00
```

**Error response BAD_VALUE (0x03) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 03 00 2b 01 00 00 00 00 88 77 66 55 44 33 22 11 26 c7 dd 51
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 03 03 2b 01 01 01 01 0d 88 77 66 55 44 33 22 11 26 c7 dd 51 00
```

**Error response BAD_STATE (0x04) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 04 00 2c 01 00 00 00 00 88 77 66 55 44 33 22 11 1d d7 d9 2d
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 04 03 2c 01 01 01 01 0d 88 77 66 55 44 33 22 11 1d d7 d9 2d 00
```

**Error response BUSY (0x05) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 05 00 2d 01 00 00 00 00 88 77 66 55 44 33 22 11 a5 8f d2 8b
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 05 03 2d 01 01 01 01 0d 88 77 66 55 44 33 22 11 a5 8f d2 8b 00
```

**Error response STALE_SESSION (0x06) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 06 00 2e 01 00 00 00 00 88 77 66 55 44 33 22 11 9c 10 23 64
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 06 03 2e 01 01 01 01 0d 88 77 66 55 44 33 22 11 9c 10 23 64 00
```

**Error response STALE_GENERATION (0x07) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 07 00 2f 01 00 00 00 00 88 77 66 55 44 33 22 11 24 48 28 c2
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 07 03 2f 01 01 01 01 0d 88 77 66 55 44 33 22 11 24 48 28 c2 00
```

**Error response INCOMPATIBLE (0x08) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 08 00 30 01 00 00 00 00 88 77 66 55 44 33 22 11 bf c9 03 ce
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 08 03 30 01 01 01 01 0d 88 77 66 55 44 33 22 11 bf c9 03 ce 00
```

**Error response IO_ERROR (0x09) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 09 00 31 01 00 00 00 00 88 77 66 55 44 33 22 11 07 91 08 68
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 09 03 31 01 01 01 01 0d 88 77 66 55 44 33 22 11 07 91 08 68 00
```

**Error response NOT_FOUND (0x0A) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 0a 00 32 01 00 00 00 00 88 77 66 55 44 33 22 11 3e 0e f9 87
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 0a 03 32 01 01 01 01 0d 88 77 66 55 44 33 22 11 3e 0e f9 87 00
```

**Error response NO_SPACE (0x0B) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 0b 00 33 01 00 00 00 00 88 77 66 55 44 33 22 11 86 56 f2 21
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 0b 03 33 01 01 01 01 0d 88 77 66 55 44 33 22 11 86 56 f2 21 00
```

**Error response INTEGRITY (0x0C) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 0c 00 34 01 00 00 00 00 88 77 66 55 44 33 22 11 bd 46 f6 5d
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 0c 03 34 01 01 01 01 0d 88 77 66 55 44 33 22 11 bd 46 f6 5d 00
```

**Error response RECOVERY_REQUIRED (0x0D) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 0d 00 35 01 00 00 00 00 88 77 66 55 44 33 22 11 05 1e fd fb
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 0d 03 35 01 01 01 01 0d 88 77 66 55 44 33 22 11 05 1e fd fb 00
```

**Error response CONFLICT (0x0E) to a ROUTES request**

```text
Error response, decoded (26 bytes):
01 00 10 01 01 00 0e 00 36 01 00 00 00 00 88 77 66 55 44 33 22 11 3c 81 0c 14
Error response, COBS plus delimiter (28 bytes):
02 01 04 10 01 01 02 0e 03 36 01 01 01 01 0d 88 77 66 55 44 33 22 11 3c 81 0c 14 00
```
