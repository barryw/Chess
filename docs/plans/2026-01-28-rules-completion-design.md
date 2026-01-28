# Chess Rules Completion Design

## Overview

Complete chess rules implementation for the AI move generator, enabling proper castling, en passant, pawn promotion, legal move filtering, and draw detection.

## Data Structures

### New Storage (storage.asm)

```asm
; Move counters for 50-move rule
HalfmoveClock:     .byte $00    ; Reset on pawn move or capture, draw at 100
FullmoveNumber:    .word $0001  ; Increments after Black's move

; Position history for threefold repetition (full 16-bit Zobrist hashes)
.const MAX_HISTORY = 200
PositionHistoryLo: .fill MAX_HISTORY, $00  ; Low bytes
PositionHistoryHi: .fill MAX_HISTORY, $00  ; High bytes
HistoryCount:      .byte $00               ; Number of positions stored
```

**Memory cost:** ~405 bytes

### Existing Infrastructure Used
- `ZobristHash` (2 bytes) - position hashing
- `castlerights` - bitmap: bit 0=WK, 1=WQ, 2=BK, 3=BQ
- `enpassantsq` - 0x88 index or $FF if none
- `whitekingsq` / `blackkingsq` - king positions

---

## Castling Move Generation

### Changes to GenerateKingMoves (movegen.asm)

After generating 8 normal king moves, check castling:

**Conditions for castling:**
1. Castling rights bit set for that side/direction
2. King on starting square (e1=$74 white, e8=$04 black)
3. Squares between king and rook empty
4. King not in check (verified by legal move filter)
5. King doesn't pass through attacked square (verified by legal move filter)

**Castling squares:**
| Castle | King From | King To | Rook From | Rook To | Empty Check |
|--------|-----------|---------|-----------|---------|-------------|
| White O-O | $74 (e1) | $76 (g1) | $77 (h1) | $75 (f1) | f1, g1 |
| White O-O-O | $74 (e1) | $72 (c1) | $70 (a1) | $73 (d1) | b1, c1, d1 |
| Black O-O | $04 (e8) | $06 (g8) | $07 (h8) | $05 (f8) | f8, g8 |
| Black O-O-O | $04 (e8) | $02 (c8) | $00 (a8) | $03 (d8) | b8, c8, d8 |

---

## En Passant Move Generation

### Changes to GeneratePawnMoves (movegen.asm)

After normal capture loop, check en passant:

1. If `enpassantsq == $FF`, skip
2. Check if en passant square matches either diagonal capture target
3. If match, add move with `to = enpassantsq`

**Note:** MakeMove/UnmakeMove already handle EP capture mechanics (removing captured pawn from correct square via UNDO_FLAG_EP_CAPTURE).

---

## Pawn Promotion

### Encoding

Use bit 7 of `to` square as knight promotion flag:
- Bit 7 clear = normal move or Queen promotion
- Bit 7 set = Knight promotion

No extra memory needed since valid 0x88 squares only use bits 0-6.

### Move Generation

When pawn reaches back rank (white: row 0, black: row 7):
1. Add Queen promotion move (normal to square)
2. Add Knight promotion move (to square | $80)

**Rationale for Queen + Knight only:** Bishop/Rook underpromotions are almost never optimal. Knight underpromotion handles the real cases (avoiding stalemate, knight forks).

### MakeMove Changes

When executing a promotion move:
1. Check bit 7 of to square
2. If set, promote to Knight; clear bit 7 for actual square
3. If clear and pawn reaching back rank, promote to Queen

---

## Legal Move Filter

### New Routine: GenerateLegalMoves (movegen.asm)

```
Input: X = side color ($80=white, $00=black)
Output: MoveCount = legal move count, MoveList contains only legal moves
```

**Algorithm:**
1. Call `GenerateAllMoves` to get pseudo-legal moves
2. For each move:
   a. `MakeMove`
   b. `IsKingInCheck` for our side
   c. `UnmakeMove`
   d. If king not in check, keep move (copy to write position)
3. Update `MoveCount` to legal count

### Castling Through Check

The legal move filter handles castling through check naturally:
- For kingside castle (e1→g1), we also need to check f1 isn't attacked
- Generate intermediate "king to f1" pseudo-move conceptually
- Or: after castling move, check both king square AND passed-through square

**Implementation:** Add special check in filter for castling moves - verify the square the king passes through is not attacked.

---

## Draw Detection

### 50-Move Rule

**UpdateHalfmoveClock** (called after each move):
- If pawn move OR capture: reset to 0
- Otherwise: increment
- If `HalfmoveClock >= 100`: draw

### Threefold Repetition

**RecordPosition** (called after each move):
1. Store `ZobristHash` (both bytes) at `HistoryCount` index
2. Increment `HistoryCount`

**CheckRepetition:**
1. Count occurrences of current `ZobristHash` in history
2. If count >= 3: draw

**Note:** Reset history on irreversible moves (pawn moves, captures, castling rights changes) for efficiency, or just let it grow.

### Insufficient Material

**CheckInsufficientMaterial:**
Scan board and check for automatic draws:
- King vs King
- King + Bishop vs King
- King + Knight vs King
- King + Bishop vs King + Bishop (same color squares)

---

## Game State Integration

### CheckGameState Changes (game.asm)

Current returns: 0=normal, 1=check, 2=checkmate, 3=stalemate

**Add new return values:**
- 4 = draw by 50-move rule
- 5 = draw by threefold repetition
- 6 = draw by insufficient material

### Game Flow

After each move:
1. `UpdateHalfmoveClock`
2. `RecordPosition`
3. `CheckGameState` (includes all draw checks)
4. Display appropriate message

---

## Files Changed

| File | Changes |
|------|---------|
| `storage.asm` | Add HalfmoveClock, PositionHistory, HistoryCount |
| `constants.asm` | Add GAME_DRAW_50, GAME_DRAW_REPEAT, GAME_DRAW_MATERIAL |
| `ai/movegen.asm` | Castling, en passant, promotion, GenerateLegalMoves |
| `ai/search.asm` | Promotion flag handling in MakeMove, use GenerateLegalMoves |
| `game.asm` | Draw detection calls, new game state handling |
| `tests/ai_rules.6502` | New test file (~25 tests) |

---

## Testing Strategy

### Castling Tests
- white-kingside-castle
- white-queenside-castle
- black-kingside-castle
- black-queenside-castle
- castle-blocked-by-piece
- castle-rights-lost-king-moved
- castle-rights-lost-rook-moved
- castle-through-check-illegal
- castle-out-of-check-illegal

### En Passant Tests
- en-passant-white-captures
- en-passant-black-captures
- en-passant-expires
- en-passant-not-available

### Promotion Tests
- promotion-generates-queen-knight
- promotion-queen-move-works
- promotion-knight-move-works

### Legal Move Filter Tests
- filter-removes-illegal-moves
- pinned-piece-restricted
- checkmate-zero-moves
- stalemate-zero-moves

### Draw Detection Tests
- fifty-move-draw
- fifty-move-resets-on-pawn
- fifty-move-resets-on-capture
- threefold-repetition
- insufficient-kk
- insufficient-kbk
- insufficient-knk

---

## Implementation Order

1. **Data structures** - Add storage, constants
2. **En passant** - Simplest move gen change
3. **Castling** - More complex but well-defined
4. **Promotion** - Encoding change, MakeMove update
5. **Legal move filter** - IsKingInCheck, GenerateLegalMoves
6. **Draw detection** - Independent, can be last
7. **Tests throughout** - Write as each feature implemented

---

## Estimated Scope

- ~400-500 lines new assembly
- ~25 unit tests
- 6 files modified
