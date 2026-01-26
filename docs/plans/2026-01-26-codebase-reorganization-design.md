# Codebase Reorganization Design

**Date:** 2026-01-26
**Goal:** Improve code discoverability without changing functionality

## Problem

Finding code is difficult. Files don't clearly indicate their contents, and responsibilities are scattered across files. The main offenders:

- `equates.asm` (297 lines) - dumping ground for all constants
- `menus.asm` (753 lines) - contains game logic, input handling, AND menu rendering

## Design Principles

1. **Organize by "what am I trying to change?"**
2. **No functionality changes** - pure reorganization
3. **Keep working files alone** - keyboard.asm, raster.asm, sprites.asm, etc.

## Final Structure

```
main.asm                  # Entry point, imports only

HARDWARE LAYER (C64-specific, not chess-specific)
├── vic.asm               # VIC-II setup (unchanged)
├── keyboard.asm          # Keyboard driver (unchanged, third-party)
├── raster.asm            # Sprite multiplexing (unchanged)
└── memory.asm            # memcopy/memfill (unchanged)

CONFIGURATION
├── constants.asm         # NEW: hardware addrs, piece defs, colors, zero page
└── layout.asm            # NEW: all ScreenPos structs for screen positions

DATA
├── strings.asm           # Text (unchanged)
├── board.asm             # Board array, initial state (unchanged)
├── sprites.asm           # Sprite graphics (unchanged)
└── characters.asm        # Custom charset (unchanged)

GAME LOGIC
├── game.asm              # NEW: game flow, turn management, key dispatch
├── moves.asm             # Move validation/execution (unchanged)
└── input.asm             # NEW: coordinate input handling

UI
├── display.asm           # NEW: screen updates, status display
└── menus.asm             # Menu system only (slimmed down)

SUPPORT
├── macros.asm            # Assembler macros (unchanged)
├── pseudocommands.asm    # Custom pseudo-ops (unchanged)
├── clock.asm             # Play clock (unchanged)
└── storage.asm           # Game state variables (unchanged)
```

## Detailed Splits

### Split 1: `equates.asm` → `constants.asm` + `layout.asm`

**constants.asm (~150 lines)** - "What things ARE"
- VIC bank, memory addresses
- Timing constants
- IRQ vectors
- Piece sprite pointers and colors
- Player constants
- Raster constants
- Difficulty/menu/enable constants
- Zero page allocations
- Keyboard constants

**layout.asm (~100 lines)** - "Where things GO on screen"
- ScreenPos struct definition
- All menu positions (Menu1Pos, PlayGamePos, etc.)
- All status positions (TurnPos, TimePos, etc.)
- All captured piece positions
- All clock positions
- Error/interaction positions
- Capture index constants (CAP_PAWN, etc.)

### Split 2: `menus.asm` → `game.asm` + `input.asm` + `menus.asm` + `display.asm`

**input.asm (~120 lines)** - "Processing player coordinate input"
- HandleRowSelection
- HandleColumnSelection
- DisplayCoordinate
- HandleDeleteKey
- HandleReturnKey

**game.asm (~80 lines)** - "Game flow and control"
- ReadKeyboard (main dispatch loop)
- StartGame
- All Handle*Key functions (thin dispatchers)
- ChangePlayers (moved from routines.asm)

**menus.asm (~300 lines)** - "Menu rendering only"
- ClearMenus
- StartMenu, QuitMenu, PlayerSelectMenu, LevelSelectMenu
- ColorSelectMenu, ForfeitMenu
- ShowAboutMenu, HideAboutMenu
- ShowYesNoOptions, ShowBackMenuItem, ShowGameMenu

**display.asm (~150 lines)** - "Non-menu screen updates"
- ShowStatus
- ShowCaptured
- ShowKingInCheck
- UpdateCurrentPlayer
- UpdateCaptureCounts
- DisplayMoveFromPrompt, DisplayMoveToPrompt
- ShowThinking, HideThinking

### Split 3: Clean up `routines.asm`

**routines.asm (~120 lines)** - "Setup and utilities"
- SetupSprites, DisableSprites
- SetupCharacters, SetupScreen, ClearScreen
- PrintByte, ClearError
- ResetInput, ResetPlayer
- ComputeMoveFromOffset, ComputeMoveToOffset

**Remove:** `#import "board.asm"` - imports belong in main.asm only

## Files Unchanged

- vic.asm
- keyboard.asm
- raster.asm
- memory.asm
- strings.asm
- board.asm
- sprites.asm
- characters.asm
- macros.asm
- pseudocommands.asm
- clock.asm
- storage.asm
- math.asm
- functions.asm
- opening_moves.asm

## Implementation Order

1. Create `constants.asm` and `layout.asm` from `equates.asm`
2. Create `display.asm` with functions from `routines.asm` and `menus.asm`
3. Create `input.asm` with input handling from `menus.asm`
4. Create `game.asm` with game flow from `menus.asm` and `routines.asm`
5. Slim down `menus.asm` to menu rendering only
6. Slim down `routines.asm` to setup/utilities only
7. Update `main.asm` imports
8. Delete `equates.asm`
9. Build and verify no regressions

## Verification

After each step:
- `make build` must succeed
- `make run` must launch the game
- All menus must work
- Piece movement must work
