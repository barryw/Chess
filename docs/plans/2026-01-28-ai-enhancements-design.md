# AI Enhancements Design

## Overview

Complete the Chess AI implementation with all remaining features from the original design document. This brings the AI from "functional" to "strong and polished" - matching the quality of 1980s dedicated chess computers like Mephisto and Sargon.

## Features (10 total)

### Group A: Evaluation Enhancements
1. Piece-square tables
2. Pawn structure analysis
3. King safety evaluation

### Group B: Search Optimizations
4. MVV-LVA capture sorting
5. Quiescence search
6. Transposition table (16KB)
7. Killer moves + history heuristic

### Group C: Opening Book Polish
8. Multiple response variants with randomization

### Group D: User Experience
9. Time-based difficulty control
10. Thinking display

## Implementation Order (Strength-First)

1. Piece-square tables - immediate eval improvement
2. MVV-LVA sorting - better move ordering
3. Quiescence search - stops horizon blunders
4. Transposition table - massive speed boost
5. Killer/history heuristics - even better ordering
6. Pawn structure - positional understanding
7. King safety - tactical awareness
8. Time control - authentic difficulty
9. Book variants - variety
10. Thinking display - polish

## Memory Budget

| Component | Size | Location |
|-----------|------|----------|
| Transposition table | 16KB | `$A000-$DFFF` |
| Piece-square tables | 384 bytes | After AI code |
| Killer moves | 64 bytes | 2 killers x 16 depths x 2 bytes |
| History table | 256 bytes | Optional |
| Book expansion | ~2KB | Existing book area |

---

## Detailed Specifications

### 1. Piece-Square Tables (PST)

Each piece type gets a 64-byte table of positional bonuses/penalties. Values scaled to match our evaluation (pawn = 10).

**Knight PST** (loves center, hates rim):
```
-50 -40 -30 -30 -30 -30 -40 -50
-40 -20   0   5   5   0 -20 -40
-30   5  10  15  15  10   5 -30
-30   0  15  20  20  15   0 -30
-30   5  15  20  20  15   5 -30
-30   0  10  15  15  10   0 -30
-40 -20   0   0   0   0 -20 -40
-50 -40 -30 -30 -30 -30 -40 -50
```

**Pawn PST** (center control, advancement):
```
 0   0   0   0   0   0   0   0   ; rank 8 (never here)
50  50  50  50  50  50  50  50   ; rank 7 (about to promote!)
10  10  20  30  30  20  10  10   ; rank 6
 5   5  10  25  25  10   5   5   ; rank 5
 0   0   0  20  20   0   0   0   ; rank 4 (center pawns)
 5  -5 -10   0   0 -10  -5   5   ; rank 3
 5  10  10 -20 -20  10  10   5   ; rank 2 (don't block c/f pawns)
 0   0   0   0   0   0   0   0   ; rank 1 (never here)
```

**Bishop PST** (long diagonals, avoid corners):
```
-20 -10 -10 -10 -10 -10 -10 -20
-10   5   0   0   0   0   5 -10
-10  10  10  10  10  10  10 -10
-10   0  10  10  10  10   0 -10
-10   5   5  10  10   5   5 -10
-10   0   5  10  10   5   0 -10
-10   0   0   0   0   0   0 -10
-20 -10 -10 -10 -10 -10 -10 -20
```

**Rook PST** (7th rank, open files):
```
 0   0   0   5   5   0   0   0
 5  10  10  10  10  10  10   5   ; 7th rank bonus
-5   0   0   0   0   0   0  -5
-5   0   0   0   0   0   0  -5
-5   0   0   0   0   0   0  -5
-5   0   0   0   0   0   0  -5
-5   0   0   0   0   0   0  -5
 0   0   0   5   5   0   0   0   ; central files
```

**Queen PST** (slight center preference, mobility):
```
-20 -10 -10  -5  -5 -10 -10 -20
-10   0   5   0   0   0   0 -10
-10   5   5   5   5   5   0 -10
  0   0   5   5   5   5   0  -5
 -5   0   5   5   5   5   0  -5
-10   0   5   5   5   5   0 -10
-10   0   0   0   0   0   0 -10
-20 -10 -10  -5  -5 -10 -10 -20
```

**King PST - Middlegame** (castled, safe):
```
 20  30  10   0   0  10  30  20   ; castled corners good
 20  20   0   0   0   0  20  20
-10 -20 -20 -20 -20 -20 -20 -10
-20 -30 -30 -40 -40 -30 -30 -20
-30 -40 -40 -50 -50 -40 -40 -30
-30 -40 -40 -50 -50 -40 -40 -30
-30 -40 -40 -50 -50 -40 -40 -30
-30 -40 -40 -50 -50 -40 -40 -30
```

**King PST - Endgame** (centralized, active):
```
-50 -30 -30 -30 -30 -30 -30 -50
-30 -30   0   0   0   0 -30 -30
-30 -10  20  30  30  20 -10 -30
-30 -10  30  40  40  30 -10 -30
-30 -10  30  40  40  30 -10 -30
-30 -10  20  30  30  20 -10 -30
-30 -20 -10   0   0 -10 -20 -30
-50 -40 -30 -20 -20 -30 -40 -50
```

**Integration:**
- New file: `ai/pst.asm` with tables
- Modify `Evaluate` in `ai/eval.asm` to add PST bonus per piece
- Black pieces use mirrored table (flip rank: `sq XOR $38`)
- Endgame detection: total material < 2600 (rough threshold)

### 2. Pawn Structure Analysis

Add to evaluation:

| Factor | Score | Detection |
|--------|-------|-----------|
| Doubled pawn | -15 | Count pawns per file, penalty for >1 |
| Isolated pawn | -20 | No friendly pawns on adjacent files |
| Passed pawn | +20 to +60 | No enemy pawns ahead or adjacent |

**Passed pawn bonus by rank:**
- Rank 7: +60 (one step from promotion)
- Rank 6: +50
- Rank 5: +40
- Rank 4: +30
- Rank 3: +20
- Rank 2: +20

### 3. King Safety Evaluation

| Factor | Score | Condition |
|--------|-------|-----------|
| Castled | +30 | King on g1/c1 (white) or g8/c8 (black) |
| Pawn shield | +10 each | Pawns on f2/g2/h2 for kingside castle |
| Open file near king | -25 | No pawns on file adjacent to king |
| King in center (middlegame) | -30 | King on d/e file with queens on board |

### 4. MVV-LVA Capture Sorting

Replace `OrderMoves` with value-based sorting:

```
Score = VictimValue * 10 - AttackerValue

Piece values for MVV-LVA:
  Pawn=10, Knight=32, Bishop=33, Rook=50, Queen=90, King=0
```

Examples:
- PxQ: 90*10 - 10 = 890 (excellent)
- NxR: 50*10 - 32 = 468 (good)
- QxP: 10*10 - 90 = 10 (questionable)
- RxR: 50*10 - 50 = 450 (equal trade)

**Implementation:**
- Calculate score for each capture
- Sort captures by score descending
- Non-captures keep existing order (after captures)

### 5. Quiescence Search

New function `Quiesce(alpha, beta)`:

```
Quiesce:
  stand_pat = Evaluate()
  if stand_pat >= beta: return beta      ; standing pat is good enough
  if stand_pat > alpha: alpha = stand_pat

  generate captures only
  sort by MVV-LVA

  for each capture:
    MakeMove(capture)
    score = -Quiesce(-beta, -alpha)
    UnmakeMove(capture)

    if score >= beta: return beta        ; beta cutoff
    if score > alpha: alpha = score

  return alpha
```

**Integration:**
- Modify `Negamax`: at depth 0, call `Quiesce` instead of `Evaluate`
- Add `GenerateCaptures` function (subset of move generator)
- Limit quiescence depth to prevent explosion (max 6 ply of captures)

### 6. Transposition Table

**Size:** 16KB = 2048 entries at 8 bytes each

**Entry format:**
```
Offset  Size  Content
+0      2     Hash verification (upper 16 bits of Zobrist)
+2      1     Depth searched
+3      1     Flag: EXACT=0, ALPHA=1, BETA=2
+4      2     Score (signed 16-bit)
+6      2     Best move (from square, to square)
```

**Location:** `$A000-$BFFF` (BASIC ROM area, banked out)

**Operations:**

```
TTProbe(hash, depth, alpha, beta):
  index = hash & 2047
  entry = TT[index]

  if entry.verify != (hash >> 16): return MISS
  if entry.depth < depth: return MISS

  if entry.flag == EXACT: return entry.score
  if entry.flag == ALPHA and entry.score <= alpha: return alpha
  if entry.flag == BETA and entry.score >= beta: return beta

  return MISS (but can use entry.best_move for ordering)

TTStore(hash, depth, flag, score, best_move):
  index = hash & 2047
  entry = TT[index]

  ; Always replace (simple strategy)
  entry.verify = hash >> 16
  entry.depth = depth
  entry.flag = flag
  entry.score = score
  entry.best_move = best_move
```

**Integration:**
- Probe TT at start of Negamax, before generating moves
- Store result at end of Negamax
- Use TT best move for move ordering (try first)

### 7. Killer Moves + History Heuristic

**Killer Moves:**
- Store 2 "killer" moves per depth (non-captures that caused cutoffs)
- 16 depths max = 64 bytes total
- Try killers after captures, before other quiet moves

```
KillerMoves: .fill 64, $00  ; [depth*4 + slot*2] = from, to

StoreKiller(depth, move):
  if move == killer[depth][0]: return  ; already stored
  killer[depth][1] = killer[depth][0]  ; shift
  killer[depth][0] = move              ; store new

Move ordering:
  1. TT best move
  2. Captures (MVV-LVA sorted)
  3. Killer moves for this depth
  4. Quiet moves
```

**History Heuristic (optional, if RAM permits):**
- 64x64 table counting how often each from-to caused cutoffs
- Use as tiebreaker for quiet move ordering
- 256 bytes if using 4 bits per entry

### 8. Multiple Book Responses

Modify `generate_book.py`:
- Store up to 3 weighted moves per position
- Entry format: hash_hi, from1, to1, weight1, from2, to2, weight2, ...

Modify `LookupOpeningMove`:
```
; Count matching entries
; Use CIA timer as random seed
; Select move weighted by popularity

LookupOpeningMove:
  ; ... existing hash lookup ...

  ; Count matches in chain
  lda #$00
  sta MatchCount

  ; Walk chain, save up to 3 matches
  ; ...

  ; Random selection
  lda $DC04         ; CIA Timer A low byte (random-ish)
  and #$03          ; 0-3
  cmp MatchCount
  bcs !use_first+   ; If random >= count, use first

  ; Return selected move
```

### 9. Time-Based Difficulty Control

**Time budgets:**
```
LEVEL_EASY:   180 jiffies  (3 seconds)
LEVEL_MEDIUM: 600 jiffies  (10 seconds)
LEVEL_HARD:   1500 jiffies (25 seconds)
```

**Implementation in FindBestMove:**
```
FindBestMove:
  ; Get time budget based on difficulty
  ldx difficulty
  lda TimeBudgetLo, x
  sta TimeRemaining
  lda TimeBudgetHi, x
  sta TimeRemaining+1

  ; Record start time
  lda $DC04
  sta StartTime
  lda $DC05
  sta StartTime+1

  ; Iterative deepening loop
  lda #1
  sta CurrentDepth

!iter_loop:
  ; Check time
  jsr CheckTimeRemaining
  bcs !time_up+

  ; Search at current depth
  lda CurrentDepth
  jsr Negamax
  sta IterScore

  ; Save best move from this iteration
  ; (already done in Negamax root)

  ; Early exit if found mate
  lda IterScore
  cmp #MATE_SCORE-10
  bcs !found_mate+

  ; Next depth
  inc CurrentDepth
  lda CurrentDepth
  cmp #MAX_DEPTH
  bcc !iter_loop-

!time_up:
!found_mate:
  rts

TimeBudgetLo: .byte <180, <600, <1500
TimeBudgetHi: .byte >180, >600, >1500
```

### 10. Thinking Display

Show during AI search:
```
Line 1: "Thinking..."      (existing spinner)
Line 2: "Depth: 4"         (current iteration)
Line 3: "Best: e2-e4"      (current best move)
```

**Implementation:**
- Update after each iterative deepening iteration
- Convert BestMoveFrom/BestMoveTo to algebraic notation
- Use existing screen area near spinner

```
UpdateThinkingDisplay:
  ; Update depth
  lda CurrentDepth
  ora #$30          ; Convert to ASCII digit
  sta SCREEN+offset

  ; Update best move
  lda BestMoveFrom
  jsr SquareToAlgebraic  ; Returns 2 chars in A, X
  sta SCREEN+offset2
  stx SCREEN+offset2+1
  ; ... etc

  rts
```

---

## File Changes Summary

| File | Changes |
|------|---------|
| `ai/pst.asm` | NEW - Piece-square tables (384 bytes) |
| `ai/eval.asm` | Add PST lookup, pawn structure, king safety |
| `ai/movegen.asm` | MVV-LVA sorting, GenerateCaptures |
| `ai/search.asm` | Quiescence, TT probe/store, killers, time control |
| `ai/tt.asm` | NEW - Transposition table (16KB) |
| `opening_moves.asm` | Multiple response selection |
| `tools/generate_book.py` | Store multiple moves per position |
| `display.asm` | Thinking display updates |
| `constants.asm` | New constants (TT flags, time budgets) |

---

## Testing Strategy

1. **PST**: Verify knights prefer center, pawns advance correctly
2. **MVV-LVA**: Check capture ordering in known positions
3. **Quiescence**: Test positions where horizon effect was problem
4. **TT**: Verify same position returns cached result
5. **Time control**: Measure actual think times at each difficulty
6. **Integration**: Full games at each difficulty level
