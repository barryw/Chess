# Chess AI Design

## Overview

An authentic 1980s-style chess AI for the C64, inspired by classic chess computers like Mephisto and Sargon. Features minimax search with alpha-beta pruning, full positional evaluation, an extensive opening book, and transposition tables.

## Goals

- **Authentic retro experience** - Similar strength and feel to 1980s dedicated chess computers
- **Three difficulty levels** - Easy (casual), Medium (club player), Hard (challenging)
- **Three player modes** - 0 (AI vs AI), 1 (Human vs AI), 2 (Human vs Human)
- **Robust testing** - Extensive unit test coverage for all AI components

## Architecture Overview

### Memory Map (KERNAL/BASIC banked out)

```
$0000-$00FF  Zero page - search variables, pointers
$0100-$01FF  Stack - 6502 stack + search recursion
$0200-$07FF  Board state, piece lists, game variables (~1.5KB)
$0800-$27FF  Opening book (~8KB)
$2800-$47FF  Transposition table (~8KB)
$4800-$BFFF  AI code + evaluation tables (~30KB)
$C000-$CFFF  Screen RAM, sprites, charset (~4KB)
$D000-$DFFF  I/O (VIC, SID, CIA)
$E000-$FFFF  Available when KERNAL banked out (~8KB overflow)
```

### Core Components

1. **Move Generator** - Produces all legal moves for a position
2. **Evaluator** - Scores a position (material + positional factors)
3. **Search Engine** - Minimax with alpha-beta pruning, iterative deepening
4. **Opening Book** - Lookup table for known positions
5. **Transposition Table** - Position cache with Zobrist hashing

### Flow

```
Opening book lookup
    → if hit: play book move instantly
    → if miss: search engine
        → move generator + evaluator
        → best move
```

---

## Search Engine

### Algorithm: Minimax with Alpha-Beta Pruning + Iterative Deepening

The AI explores a tree of possible moves. At each level it alternates between maximizing (AI's turn) and minimizing (opponent's turn). Alpha-beta cuts off branches that can't affect the outcome - typically reduces search by 50-90%.

### Iterative Deepening

Instead of diving straight to max depth:

1. Search 1 ply deep, find best move
2. Search 2 ply deep, reorder moves (best first)
3. Search 3 ply deep... and so on

Benefits:
- Always has a "good enough" move if time runs out
- Move ordering from previous iteration improves alpha-beta cutoffs dramatically
- Natural way to implement time control per difficulty

### Depth Targets

| Difficulty | Time Budget | Target Depth | Quiescence |
|------------|-------------|--------------|------------|
| Easy       | 2-3 sec     | 3 ply        | +2 ply     |
| Medium     | 8-12 sec    | 5 ply        | +3 ply     |
| Hard       | 20-30 sec   | 6-7 ply      | +4 ply     |

### Quiescence Search

At leaf nodes, don't stop if pieces are being captured - continue searching captures only until the position is "quiet." Prevents the horizon effect (AI thinks it's winning because it can't see the recapture).

---

## Evaluation Function

### Score Format

Centipawns (1 pawn = 100). Stored as signed 16-bit. Positive = AI advantage.

### Material Values

| Piece  | Value | Hex   |
|--------|-------|-------|
| Pawn   | 100   | $0064 |
| Knight | 320   | $0140 |
| Bishop | 330   | $014A |
| Rook   | 500   | $01F4 |
| Queen  | 900   | $0384 |
| King   | n/a   | $7FFF |

Bishop slightly higher than knight - encourages keeping the bishop pair.

### Piece-Square Tables (PST)

Each piece type has a 64-byte table giving positional bonuses/penalties per square:

- **Pawns:** Center pawns worth more, advanced pawns worth more, edge pawns penalized
- **Knights:** Love the center, hate the rim ("knight on the rim is dim")
- **Bishops:** Long diagonals good, blocked positions penalized
- **Rooks:** 7th rank bonus, open file bonus
- **King (middlegame):** Castled position bonus, center penalized
- **King (endgame):** Center becomes good, activity matters

Tables are ~400 bytes total (64 bytes x 6 piece types, mirrored for black).

### Pawn Structure Analysis

| Factor        | Score  |
|---------------|--------|
| Doubled pawn  | -20    |
| Isolated pawn | -15    |
| Passed pawn   | +30 to +80 (based on advancement) |
| Pawn shield   | +10 per pawn in front of castled king |

---

## Opening Book

### Format: Position Hash → Move

Each entry is 4 bytes:
- 2 bytes: Position hash (Zobrist, truncated)
- 1 byte: From square (0x88 format)
- 1 byte: To square (0x88 format)

8KB = 2048 entries. Handles ~200-300 opening lines with variations.

### Coverage (prioritized)

1. **King's Pawn (e4):** Italian, Spanish (Ruy Lopez), Scotch, King's Gambit, Petroff
2. **Sicilian Defense:** Open Sicilian, Najdorf basics, Dragon basics
3. **Queen's Pawn (d4):** Queen's Gambit (accepted/declined), London, Slav basics
4. **Indian Defenses:** King's Indian, Nimzo-Indian main lines
5. **Replies to offbeat:** 1.c4, 1.Nf3, 1.b3 - sensible responses

### Lookup Flow

```
1. Hash current position (Zobrist)
2. Probe book table
3. If hit → play book move instantly (no thinking)
4. If miss → fall through to search engine
```

### Multiple Responses

For the same position, store 2-3 good moves with a random selector. Adds variety - AI won't play the exact same game twice.

### Book Building

Compiled offline from PGN databases (master games). Tool extracts positions up to move 12-15, filters for moves played >N times. Stored as binary blob included at assembly time.

---

## Transposition Table

### Purpose

Cache evaluated positions to avoid recalculating when the same position is reached via different move orders.

### Entry Format (8 bytes each)

```
Bytes 0-3: Full Zobrist hash (32-bit)
Byte 4:    Depth searched
Byte 5:    Flag (EXACT, ALPHA, BETA)
Bytes 6-7: Score (signed 16-bit)
```

8KB table = 1024 entries. Uses lower bits of hash as index, full hash for verification.

### Zobrist Hashing

Pre-computed random 32-bit numbers for:
- Each piece type on each square (12 x 64 = 768 values)
- Side to move (1 value)
- Castling rights (4 values)
- En passant file (8 values)

Position hash = XOR of all applicable values. Incremental update on each move (~10 cycles vs rehashing entire board).

### Table Flags

| Flag  | Meaning |
|-------|---------|
| EXACT | Score is exact evaluation at this depth |
| ALPHA | Score is upper bound (failed low) |
| BETA  | Score is lower bound (failed high) |

### Replacement Strategy

Always replace - simple and effective. Deeper searches naturally overwrite shallow ones as iterative deepening progresses.

### Zobrist Table Storage

768 + 1 + 4 + 8 = 781 random numbers x 4 bytes = ~3KB for the Zobrist keys. One-time generation at startup using a seeded PRNG.

---

## Move Generator

### Approach: Pseudo-Legal + Legality Check

Generate all moves that follow piece movement rules, then filter out moves that leave king in check. Faster than strict legal generation for alpha-beta since most branches get pruned before legality matters.

### Move Format (2 bytes)

```
Byte 0: From square (0x88 format)
Byte 1: To square + flags

Flags (high 4 bits of byte 1):
  %0000 = Normal move
  %0001 = Double pawn push
  %0010 = Kingside castle
  %0011 = Queenside castle
  %0100 = En passant capture
  %0101 = Promotion to Knight
  %0110 = Promotion to Bishop
  %0111 = Promotion to Rook
  %1000 = Promotion to Queen
```

### Move List Buffer

Max legal moves in any position = 218. Allocate 256 x 2 = 512 bytes per ply. With max search depth of 12 (6 ply + 6 quiescence), need ~6KB for move stacks. Fits comfortably.

### Generation Order (for alpha-beta efficiency)

1. Hash move (from transposition table)
2. Captures (MVV-LVA sorted: most valuable victim, least valuable attacker)
3. Killer moves (quiet moves that caused beta cutoff at this depth before)
4. Quiet moves (sorted by history heuristic or PST bonus)

Good move ordering is critical - can double search speed.

### 0x88 Board Advantage

Off-board detection with single AND: `if (square & 0x88) → invalid`. Makes sliding piece generation clean with no bounds checking.

---

## Player Modes

### Player Count Options

```
[0] Computer vs Computer
[1] Human vs Computer
[2] Human vs Human
```

### Mode Behavior

| Mode | White | Black | Think Time Display |
|------|-------|-------|-------------------|
| 0    | AI    | AI    | Both sides        |
| 1    | Human | AI    | Black only        |
| 2    | Human | Human | Never             |

### 0-Player Implementation

- After each AI move, small delay between moves so humans can follow (~1 sec pause)
- "Thinking" spinner shows for both colors
- Difficulty setting applies to both sides
- ESC or Q to interrupt and return to menu

### Storage

```asm
.const ZERO_PLAYER = $00
.const ONE_PLAYER  = $01
.const TWO_PLAYER  = $02
```

Game loop checks: `if playercount == TWO_PLAYER → human input, else → AI move`

---

## Test Strategy

### Move Generator Tests

- Starting position: exactly 20 legal moves
- Known positions with exact move counts (perft test positions)
- Each piece type in isolation: pawn pushes, pawn captures, knight L-shapes, sliding pieces
- Special moves: castling (all 4 types), en passant, promotions (all 4 piece types)
- Edge cases: pinned pieces can't move, blocking check, king can't castle through/out of check
- Perft suite: position → count nodes at depth N (gold standard for move gen correctness)

### Evaluation Tests

- Material counting: various piece combinations
- Piece-square tables: known position → expected PST score
- Pawn structure: doubled pawns detected, isolated pawns detected, passed pawns scored
- King safety: castled vs exposed king scores differ correctly
- Symmetry: mirrored position evaluates to same score (opposite sign)

### Search Tests

- Mate in 1: finds the checkmate
- Mate in 2: finds forced mate sequence
- Mate in 3: harder forced mates
- Tactics: pins, forks, skewers - AI finds winning move
- Horizon effect: doesn't blunder due to delayed capture (quiescence works)
- Alpha-beta correctness: same result as pure minimax (just faster)

### Transposition Table Tests

- Zobrist hash consistency: make/unmake move returns same hash
- Incremental update matches full recalculation
- Table stores and retrieves correct scores
- Hash collisions handled (verification with full hash)

### Opening Book Tests

- Known positions return expected book moves
- Book miss falls through to search
- Multiple responses: randomization works

### Integration Tests

- Full games against known sequences
- Specific positions from famous games - AI finds the master move
- Regression suite: positions that previously caused bugs

### Performance Benchmarks

- Nodes per second at each difficulty
- Time to depth on standard positions
- Memory usage stays within bounds

---

## Implementation Phases

### Phase 1: Foundation

- Bank out KERNAL/BASIC, set up memory map
- Implement Zobrist hashing (incremental updates)
- Move generator (pseudo-legal, all piece types)
- Basic evaluation (material only)
- Verify with test positions

### Phase 2: Search Core

- Minimax with alpha-beta
- Iterative deepening
- Time control per difficulty level
- Simple move ordering (captures first)
- Hook into game loop - AI makes moves

### Phase 3: Evaluation Depth

- Piece-square tables
- Pawn structure analysis
- King safety evaluation
- Tune weights against known positions

### Phase 4: Search Optimization

- Transposition table integration
- Quiescence search
- Killer move heuristic
- MVV-LVA capture sorting
- History heuristic for quiet moves

### Phase 5: Opening Book

- Build offline tool to compile PGN → binary book
- Book probe at search start
- Multiple move variants with randomization

### Phase 6: Polish

- Difficulty tuning (depth/time curves)
- Edge cases (stalemate, insufficient material, repetition)
- "Thinking" display shows current best move
- 0-player mode (AI vs AI demo)

---

## Future Possibilities (Not in Scope)

- Endgame tablebases
- Pondering (thinking on opponent's time)
- Separate difficulty per side in 0-player mode
- Opening book learning
