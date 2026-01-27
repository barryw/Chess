# Move Validation Design

## Overview

Complete chess move validation for the C64 chess game, implementing full chess rules including all special moves (castling, en passant, pawn promotion with piece selection).

## Core Architecture

### Central Routine: `IsSquareAttacked(square, byColor)`

The heart of all validation. Given a 0x88 square index and an attacking color, returns whether that square is under attack.

**Used for:**
- Validating moves don't leave king in check
- Detecting check/checkmate/stalemate
- Castling validation (king can't pass through attacked squares)

### Attack Detection Strategy: Reverse Ray Casting

Instead of checking every enemy piece, look *outward* from the target square along each attack vector. If we find an enemy piece that attacks along that vector, the square is attacked.

```
From target square, check:
- 8 knight offsets → enemy knight?
- 4 diagonal rays → enemy bishop/queen? (or pawn on first step)
- 4 orthogonal rays → enemy rook/queen?
- 8 king offsets → enemy king?
```

**Efficiency:**
- Uses 0x88 off-board detection (no bounds checking needed)
- Stops ray immediately when hitting any piece
- Knight/king checks are single lookups, not rays
- Worst case: ~26 squares checked. Average: far fewer (pieces block rays)

### 0x88 Direction Offsets

```
NW=-17  N=-16  NE=-15
W=-1    [sq]   E=+1
SW=+15  S=+16  SE=+17

Knight: -33, -31, -18, -14, +14, +18, +31, +33
```

---

## Piece Movement Validation

### Dispatch by Piece Type

```
ValidateMove:
  Load piece at movefromindex
  Strip color → get piece type
  Branch to: ValidatePawn, ValidateKnight, ValidateBishop,
             ValidateRook, ValidateQueen, ValidateKing
```

### Movement Patterns

| Piece | Movement | Validation |
|-------|----------|------------|
| **Pawn** | Forward 1/2, diagonal capture | Direction depends on color. Check en passant. 2-square only from start rank. |
| **Knight** | 8 fixed offsets | Single check: `moveto = movefrom + offset`? Target empty or enemy? |
| **Bishop** | 4 diagonal rays | Slide along ray until blocked. Target must be on ray, path clear. |
| **Rook** | 4 orthogonal rays | Same as bishop, different directions. |
| **Queen** | 8 rays (bishop + rook) | Union of bishop and rook logic. |
| **King** | 8 adjacent + castling | Single step any direction. Castling: special checks. |

### Sliding Piece Validation (Bishop/Rook/Queen)

```
1. Calculate delta = moveto - movefrom
2. Determine direction (must be valid for piece type)
3. Walk from movefrom toward moveto
4. If we hit a piece before moveto → blocked → invalid
5. If we reach moveto → valid (capture or empty)
```

**Key insight:** We don't enumerate all possible moves. We verify the *requested* move is legal. Much faster.

---

## Special Moves

### Castling (4 variants: WK, WQ, BK, BQ)

**Conditions - ALL must be true:**
1. King hasn't moved (check `castlerights` bitmap)
2. Rook hasn't moved (same bitmap)
3. No pieces between king and rook
4. King not currently in check
5. King doesn't pass through attacked square
6. King doesn't land in check

**Square requirements:**
```
White Kingside:  King e1→g1, Rook h1→f1 (f1,g1 empty and safe)
White Queenside: King e1→c1, Rook a1→d1 (b1,c1,d1 empty; c1,d1 safe)
Black Kingside:  King e8→g8, Rook h8→f8 (f8,g8 empty and safe)
Black Queenside: King e8→c8, Rook a8→d8 (b8,c8,d8 empty; c8,d8 safe)
```

**0x88 squares:**
```
White: e1=$74, f1=$75, g1=$76, h1=$77, d1=$73, c1=$72, b1=$71, a1=$70
Black: e8=$04, f8=$05, g8=$06, h8=$07, d8=$03, c8=$02, b8=$01, a8=$00
```

### En Passant

- When pawn moves 2 squares, set `enpassantsq` to the skipped square
- Enemy pawn can capture "through" that square on immediately next move
- Clear `enpassantsq` after any other move (already implemented in MovePiece)

**Detection:** If pawn captures diagonally to an empty square that equals `enpassantsq`, it's en passant. Remove the enemy pawn from the adjacent square.

### Pawn Promotion

When pawn reaches rank 8 (white) or rank 1 (black):
1. Pause game, show promotion menu (Q/R/B/N)
2. Player selects piece via keyboard
3. Replace pawn with selected piece on board

**New menu state:** `MENU_PROMOTION`

### Updating Castling Rights

On any move:
- If king moves → clear both castling rights for that color
- If rook moves from a1 → clear white queenside
- If rook moves from h1 → clear white kingside
- If rook moves from a8 → clear black queenside
- If rook moves from h8 → clear black kingside
- If rook is captured on corner square → clear that side's right

---

## Check, Checkmate, and Stalemate

### Check Detection

After every move, call `IsSquareAttacked(enemyKingSq, currentPlayer)`. If true, enemy is in check. Display "CHECK!" message.

### Checkmate Detection

Player is in checkmate if they're in check AND have no legal moves.

```
IsCheckmate:
  If not in check → return false
  For each of my pieces:
    For each possible move of that piece:
      If move is legal (doesn't leave king in check):
        return false (found escape)
  return true (no escape = checkmate)
```

### Stalemate Detection

Player has no legal moves but is NOT in check.

```
IsStalemate:
  If in check → return false
  For each of my pieces:
    If piece has any legal move:
      return false
  return true (stalemate)
```

### HasValidMoves Refactor

Must enumerate possible moves for a piece and verify at least one is legal (doesn't leave king in check). Used both for piece selection validation and checkmate/stalemate detection.

---

## Data Structures

### Direction Offset Tables (read-only)

```asm
// Orthogonal directions (rook/queen)
OrthogonalOffsets:
  .byte $f0, $10, $ff, $01    // N(-16), S(+16), W(-1), E(+1)

// Diagonal directions (bishop/queen)
DiagonalOffsets:
  .byte $ef, $f1, $0f, $11    // NW(-17), NE(-15), SW(+15), SE(+17)

// Knight offsets
KnightOffsets:
  .byte $df, $e1, $ee, $f2, $0e, $12, $1f, $21
  // -33, -31, -18, -14, +14, +18, +31, +33

// King offsets (all 8 directions)
KingOffsets:
  .byte $ef, $f0, $f1, $ff, $01, $0f, $10, $11
```

### Zero Page Variables (for speed)

```asm
attack_sq     = $26    // Square being checked for attack
attack_color  = $27    // Color attacking (0=black, 1=white)
move_delta    = $28    // Calculated move delta
ray_dir       = $29    // Current ray direction
temp_piece    = $2a    // Temp piece storage
```

### New Storage Variables

```asm
promotionsq:    .byte $ff    // Square where pawn is promoting ($ff = none)
promotionpiece: .byte $00    // Selected promotion piece
```

---

## Implementation Phases

### Phase 1 - Foundation
1. Add direction offset tables to storage.asm
2. Add zero page variable allocations to constants.asm
3. Implement `IsSquareAttacked` routine
4. Test with known attack scenarios

### Phase 2 - Basic Piece Validation
5. Implement `ValidateKnight` (simplest - no rays)
6. Implement `ValidateRook` (sliding + orthogonal)
7. Implement `ValidateBishop` (sliding + diagonal)
8. Implement `ValidateQueen` (combines both)
9. Implement `ValidateKing` (single step, no castling yet)
10. Implement `ValidatePawn` (forward, capture, no en passant yet)

### Phase 3 - Check Enforcement
11. Add "would leave king in check?" validation wrapper
12. Refactor `HasValidMoves` to enumerate and validate
13. Implement check detection after moves
14. Implement checkmate/stalemate detection

### Phase 4 - Special Moves
15. Add castling to `ValidateKing`
16. Add en passant to `ValidatePawn`
17. Add pawn promotion UI and logic
18. Implement `MovePiece` updates for special moves (move rook for castling, remove captured pawn for en passant)

### Phase 5 - Polish
19. Display check/checkmate/stalemate messages
20. Handle game end states (game over screen)
21. Update castling rights on king/rook moves and captures

---

## Files Modified

| File | Changes |
|------|---------|
| `constants.asm` | Zero page allocations, pawn direction constants |
| `storage.asm` | Direction tables, promotion variables |
| `moves.asm` | All validation routines, IsSquareAttacked, special move handling |
| `menus.asm` | Promotion menu UI |
| `display.asm` | Check/checkmate/stalemate messages |
| `game.asm` | Game end state handling |
| `strings.asm` | New message strings |

---

## Testing Strategy

Each phase should be testable:
- Phase 1: Manually verify IsSquareAttacked with known positions
- Phase 2: Verify each piece can only make legal moves
- Phase 3: Verify illegal moves (leaving king in check) are rejected
- Phase 4: Verify castling conditions, en passant, promotion
- Phase 5: Verify game properly ends on checkmate/stalemate
