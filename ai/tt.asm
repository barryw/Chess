#importonce

// Transposition Table Module
// 16KB = 2048 entries x 8 bytes each
// Located at $A000-$BFFF (BASIC ROM area, banked out)

*=* "Transposition Table"

.const TT_SIZE = 2048           // Number of entries
.const TT_ENTRY_SIZE = 8        // Bytes per entry
.const TT_BASE = $A000          // Base address

// Entry format (8 bytes):
// +0-1: Hash verification (16-bit key check)
// +2:   Depth searched
// +3:   Flag (0=EXACT, 1=ALPHA, 2=BETA)
// +4-5: Score (signed 16-bit)
// +6:   Best move from square
// +7:   Best move to square

.const TT_FLAG_EXACT = 0
.const TT_FLAG_ALPHA = 1
.const TT_FLAG_BETA = 2

// TT probe results
TTHit:        .byte $00         // $00 = miss, $01 = hit
TTFlag:       .byte $00         // Flag from entry
TTDepth:      .byte $00         // Depth from entry
TTScoreLo:    .byte $00         // Score low byte
TTScoreHi:    .byte $00         // Score high byte
TTBestFrom:   .byte $00         // Best move from
TTBestTo:     .byte $00         // Best move to

// Temporary storage for TT operations
TTEntryPtr:   .word $0000       // Pointer to current entry

//
// TTClear
// Clear entire transposition table
// Call at start of new game
// Clobbers: A, X, Y, $f0-$f1
//
TTClear:
  // Bank out BASIC ROM to access $A000-$BFFF
  lda $01
  and #$fe                      // Clear bit 0 (BASIC ROM)
  sta $01

  // Set pointer to TT base
  lda #<TT_BASE
  sta $f0
  lda #>TT_BASE
  sta $f1

  // Clear 64 pages x 256 bytes = 16KB
  ldy #$00
  tya                           // A = $00

!tt_clear_page:
  sta ($f0), y
  iny
  bne !tt_clear_page-

  // Next page
  inc $f1
  lda $f1
  cmp #>TT_BASE + $40           // $A000 + $4000 = $E000 (64 pages)
  bne !tt_clear_page-

  // Bank BASIC ROM back in
  lda $01
  ora #$01
  sta $01

  rts

//
// TTProbe
// Look up position in transposition table
// Input: ZobristHash contains current position hash (call ComputeZobristHash first!)
//        A = minimum depth required
// Output: TTHit = $01 if found and usable, $00 if miss
//         If hit: TTFlag, TTScoreLo, TTScoreHi, TTBestFrom, TTBestTo set
// Clobbers: A, X, Y, $f0-$f3, TTEntryPtr
//
TTProbe:
  sta $f3                       // $f3 = required depth

  // Bank out BASIC ROM
  lda $01
  and #$fe
  sta $01

  // Calculate entry index: ZobristHash mod TT_SIZE
  // TT_SIZE = 2048 = $800, so mask with $7FF (11 bits)
  lda ZobristHash
  sta $f0                       // Low 8 bits
  lda ZobristHash + 1
  and #$07                      // Keep only bits 0-2 (upper 3 bits of 11)
  sta $f1                       // Index high byte

  // Calculate entry address: TT_BASE + (index * 8)
  // index * 8 = shift left 3 times
  asl $f0
  rol $f1
  asl $f0
  rol $f1
  asl $f0
  rol $f1

  // Add TT_BASE
  clc
  lda $f0
  adc #<TT_BASE
  sta TTEntryPtr
  lda $f1
  adc #>TT_BASE
  sta TTEntryPtr + 1

  // Check hash verification (first 2 bytes of entry)
  ldy #$00
  lda (TTEntryPtr), y
  cmp ZobristHash
  bne !tt_miss+
  iny
  lda (TTEntryPtr), y
  cmp ZobristHash + 1
  bne !tt_miss+

  // Hash matches - check depth
  iny                           // Y = 2
  lda (TTEntryPtr), y
  sta TTDepth
  cmp $f3                       // Compare with required depth
  bcc !tt_miss+                 // Entry depth < required, miss

  // Valid entry - extract all data
  iny                           // Y = 3
  lda (TTEntryPtr), y
  sta TTFlag

  iny                           // Y = 4
  lda (TTEntryPtr), y
  sta TTScoreLo

  iny                           // Y = 5
  lda (TTEntryPtr), y
  sta TTScoreHi

  iny                           // Y = 6
  lda (TTEntryPtr), y
  sta TTBestFrom

  iny                           // Y = 7
  lda (TTEntryPtr), y
  sta TTBestTo

  // Bank BASIC ROM back in
  lda $01
  ora #$01
  sta $01

  lda #$01
  sta TTHit
  rts

!tt_miss:
  // Bank BASIC ROM back in
  lda $01
  ora #$01
  sta $01

  lda #$00
  sta TTHit
  rts

//
// TTStore
// Store position in transposition table
// Input: ZobristHash = position hash (already computed)
//        A = depth
//        X = flag (EXACT/ALPHA/BETA)
//        TTScoreLo/TTScoreHi = score to store
//        BestMoveFrom/BestMoveTo = best move (from search.asm)
// Clobbers: A, X, Y, $f0-$f3, TTEntryPtr
//
TTStore:
  sta $f2                       // $f2 = depth
  stx $f3                       // $f3 = flag

  // Bank out BASIC ROM
  lda $01
  and #$fe
  sta $01

  // Calculate entry address (same as probe)
  lda ZobristHash
  sta $f0
  lda ZobristHash + 1
  and #$07
  sta $f1

  asl $f0
  rol $f1
  asl $f0
  rol $f1
  asl $f0
  rol $f1

  clc
  lda $f0
  adc #<TT_BASE
  sta TTEntryPtr
  lda $f1
  adc #>TT_BASE
  sta TTEntryPtr + 1

  // Store entry (always replace)
  ldy #$00
  lda ZobristHash
  sta (TTEntryPtr), y           // +0: hash low

  iny
  lda ZobristHash + 1
  sta (TTEntryPtr), y           // +1: hash high

  iny
  lda $f2
  sta (TTEntryPtr), y           // +2: depth

  iny
  lda $f3
  sta (TTEntryPtr), y           // +3: flag

  iny
  lda TTScoreLo
  sta (TTEntryPtr), y           // +4: score low

  iny
  lda TTScoreHi
  sta (TTEntryPtr), y           // +5: score high

  iny
  lda BestMoveFrom
  sta (TTEntryPtr), y           // +6: best from

  iny
  lda BestMoveTo
  sta (TTEntryPtr), y           // +7: best to

  // Bank BASIC ROM back in
  lda $01
  ora #$01
  sta $01

  rts
