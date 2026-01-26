# Screen Management Improvement Design

**Date:** 2026-01-26
**Goal:** Reduce code bloat from CopyMemory/FillMemory macro expansions

## Problem

Current screen text rendering uses inline macro expansion:
- `CopyMemory` expands to ~33 bytes per call
- `FillMemory` expands to ~27 bytes per call
- Every text display requires both = ~60 bytes
- 103 total calls = **~3KB of code bloat**

This is not the standard C64 approach. The standard pattern is one print routine called many times.

## Solution Overview

1. Create a single `PrintString` routine (~50 bytes)
2. Convert strings to null-terminated format
3. Create a compact `PrintAt` macro (~12 bytes per call)
4. Estimated savings: **~2.2KB**

## Implementation Details

### New Zero Page Allocations

Add to `constants.asm`:
```asm
// String printing
.const str_ptr = $1f    // Pointer to string data
.const scr_ptr = $21    // Pointer to screen location
.const print_color = $23 // Color for text
```

### PrintString Routine

Add to `routines.asm`:
```asm
/*
Print a null-terminated string to screen with color.
Inputs:
  str_ptr - pointer to null-terminated string
  scr_ptr - pointer to screen memory location
  print_color - color to use
*/
PrintString:
  ldy #$00
!loop:
  lda (str_ptr),y       // Get character
  beq !done+            // $00 = end of string
  sta (scr_ptr),y       // Write to screen
  pha                   // Save char
  lda scr_ptr           // Calculate color RAM address
  clc
  adc #<COLOR_MEMORY_OFFSET
  sta col_temp
  lda scr_ptr+1
  adc #>COLOR_MEMORY_OFFSET
  sta col_temp+1
  lda print_color
  sta (col_temp),y      // Write to color RAM
  pla                   // Restore char
  iny
  bne !loop-
!done:
  rts
```

**Optimized version** (uses pre-calculated color pointer):
```asm
/*
Print a null-terminated string to screen with color.
Inputs:
  str_ptr - pointer to null-terminated string
  scr_ptr - pointer to screen memory location
  col_ptr - pointer to color memory location (scr_ptr + $D400)
  print_color - color to use
*/
PrintString:
  ldy #$00
!loop:
  lda (str_ptr),y       // Get character
  beq !done+            // $00 = end of string
  sta (scr_ptr),y       // Write to screen
  lda print_color
  sta (col_ptr),y       // Write to color RAM
  iny
  bne !loop-
!done:
  rts
```

### PrintAt Macro

Add to `macros.asm`:
```asm
/*
Print a null-terminated string at a screen position with color.
Much more compact than CopyMemory + FillMemory combination.
*/
.macro PrintAt(string, screenpos, color) {
  lda #<string
  sta str_ptr
  lda #>string
  sta str_ptr+1
  lda #<ScreenAddress(screenpos)
  sta scr_ptr
  lda #>ScreenAddress(screenpos)
  sta scr_ptr+1
  lda #<ColorAddress(screenpos)
  sta col_ptr
  lda #>ColorAddress(screenpos)
  sta col_ptr+1
  lda #color
  sta print_color
  jsr PrintString
}
```

This expands to ~25 bytes vs ~60 bytes for CopyMemory+FillMemory.

### String Format Changes

Convert strings in `strings.asm` from:
```asm
PlayStart:
  .text "[P]lay Game"
PlayEnd:
```

To null-terminated:
```asm
PlayText:
  .text "[P]lay Game"
  .byte $00
```

### Usage Changes

Before:
```asm
CopyMemory(PlayStart, ScreenAddress(PlayGamePos), PlayEnd - PlayStart)
FillMemory(ColorAddress(PlayGamePos), PlayEnd - PlayStart, WHITE)
```

After:
```asm
PrintAt(PlayText, PlayGamePos, WHITE)
```

## Migration Strategy

### Phase 1: Add New Infrastructure
1. Add zero page allocations to `constants.asm`
2. Add `PrintString` routine to `routines.asm`
3. Add `PrintAt` macro to `macros.asm`
4. Build and verify no regressions

### Phase 2: Convert Strings
1. Convert strings in `strings.asm` to null-terminated
2. Remove `*End` labels (no longer needed)
3. Rename `*Start` labels to just the name (e.g., `PlayText`)

### Phase 3: Update Call Sites
Convert one file at a time, building after each:
1. `menus.asm` (49 calls - biggest savings)
2. `display.asm` (34 calls)
3. `moves.asm` (10 calls)
4. `routines.asm` (7 calls)
5. `clock.asm` (1 call)

### Phase 4: Cleanup
1. Remove unused macros if CopyMemory/FillMemory no longer needed elsewhere
2. Verify memory map shows reduced code size

## Special Cases

### Multi-color Strings (Title)
The title uses per-character colors. Keep using CopyMemory for these:
```asm
TitleRow1Start:
  .byte $eb, $ed, $fb, $fd...
TitleRow1ColorStart:
  .byte LIGHT_BLUE, LIGHT_BLUE, ORANGE...
```

Or create a `PrintColorString` variant that reads from a parallel color array.

### Fill Operations
Some `FillMemory` calls fill with a character (like `$77` for underlines), not color. These can use a new `FillChar` routine or stay as-is if rare.

### ClearMenus
The `ClearMenus` function uses 5 `FillMemory` calls to clear color RAM. This could become a loop over a table of positions, or use a single clear of the right-side panel area.

## Memory Savings Estimate

| Item | Before | After |
|------|--------|-------|
| PrintString routine | 0 | ~40 bytes |
| Per-call overhead | ~60 bytes | ~25 bytes |
| 100 call sites | 6,000 bytes | 2,500 bytes |
| **Total** | **~6,000 bytes** | **~2,540 bytes** |
| **Savings** | | **~3,460 bytes** |

## Verification

After each phase:
- `make build` must succeed
- `make run` must launch the game
- All menus must display correctly
- All text must appear with correct colors
- Memory map should show reduced Menus/Display segment sizes

## Future Improvements

Once this foundation is in place, additional optimizations become possible:

1. **Table-driven menus** - Define menu items in data tables, one render loop
2. **Screen templates** - Pre-define common screen layouts
3. **Partial screen updates** - Only redraw what changed
