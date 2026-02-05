#importonce

// Transposition Table Module
// 4KB = 512 entries x 8 bytes each
// Located at $C000-$CFFF (always RAM, no banking needed)

*=* "Transposition Table"

.const TT_SIZE = 512            // Number of entries
.const TT_ENTRY_SIZE = 8        // Bytes per entry
.const TT_BASE = $C000          // Base address

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

// Zero-page pointer for TT entry access (indirect indexed addressing)
// 6502 (addr),Y requires zero-page pointer
.label tt_ptr = $f0             // 2 bytes: $f0-$f1

//
// TTClear
// Clear entire transposition table (4KB at $C000-$CFFF)
// Uses FillMemory routine to zero the region
// Call at start of new game
// Clobbers: A, X, Y, fill_to, fill_size, fill_value
//
TTClear:
  lda #$00
  sta fill_value
  lda #<TT_BASE
  sta fill_to
  lda #>TT_BASE
  sta fill_to + 1
  lda #<(TT_SIZE * TT_ENTRY_SIZE)
  sta fill_size
  lda #>(TT_SIZE * TT_ENTRY_SIZE)
  sta fill_size + 1
  jsr FillMemory
  rts

//
// TTProbe
// Look up position in transposition table
// Input: ZobristHash contains current position hash (call ComputeZobristHash first!)
//        A = minimum depth required
// Output: TTHit = $01 if found and usable, $00 if miss
//         If hit: TTFlag, TTScoreLo, TTScoreHi, TTBestFrom, TTBestTo set
// Clobbers: A, X, Y, $f0-$f3
//
TTProbe:
  sta $f3                       // $f3 = required depth

  // Calculate entry index: ZobristHash mod TT_SIZE
  // TT_SIZE = 512 = $200, so mask with $1FF (9 bits)
  lda ZobristHash
  sta tt_ptr                    // Low 8 bits
  lda ZobristHash + 1
  and #$01                      // Keep only bit 0 (9th bit of index)
  sta tt_ptr + 1                // Index high byte

  // Calculate entry address: TT_BASE + (index * 8)
  // index * 8 = shift left 3 times
  asl tt_ptr
  rol tt_ptr + 1
  asl tt_ptr
  rol tt_ptr + 1
  asl tt_ptr
  rol tt_ptr + 1

  // Add TT_BASE - result stays in tt_ptr (zero page) for indirect access
  clc
  lda tt_ptr
  adc #<TT_BASE
  sta tt_ptr
  lda tt_ptr + 1
  adc #>TT_BASE
  sta tt_ptr + 1

  // Check hash verification (first 2 bytes of entry)
  ldy #$00
  lda (tt_ptr), y
  cmp ZobristHash
  bne !tt_miss+
  iny
  lda (tt_ptr), y
  cmp ZobristHash + 1
  bne !tt_miss+

  // Hash matches - check depth
  iny                           // Y = 2
  lda (tt_ptr), y
  sta TTDepth
  cmp $f3                       // Compare with required depth
  bcc !tt_miss+                 // Entry depth < required, miss

  // Valid entry - extract all data
  iny                           // Y = 3
  lda (tt_ptr), y
  sta TTFlag

  iny                           // Y = 4
  lda (tt_ptr), y
  sta TTScoreLo

  iny                           // Y = 5
  lda (tt_ptr), y
  sta TTScoreHi

  iny                           // Y = 6
  lda (tt_ptr), y
  sta TTBestFrom

  iny                           // Y = 7
  lda (tt_ptr), y
  sta TTBestTo

  lda #$01
  sta TTHit
  rts

!tt_miss:
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
// Clobbers: A, X, Y, $f0-$f3
//
TTStore:
  sta $f2                       // $f2 = depth
  stx $f3                       // $f3 = flag

  // Calculate entry address (same as probe)
  lda ZobristHash
  sta tt_ptr
  lda ZobristHash + 1
  and #$01                      // 9-bit index for 512 entries
  sta tt_ptr + 1

  asl tt_ptr
  rol tt_ptr + 1
  asl tt_ptr
  rol tt_ptr + 1
  asl tt_ptr
  rol tt_ptr + 1

  clc
  lda tt_ptr
  adc #<TT_BASE
  sta tt_ptr
  lda tt_ptr + 1
  adc #>TT_BASE
  sta tt_ptr + 1

  // Store entry (always replace)
  ldy #$00
  lda ZobristHash
  sta (tt_ptr), y               // +0: hash low

  iny
  lda ZobristHash + 1
  sta (tt_ptr), y               // +1: hash high

  iny
  lda $f2
  sta (tt_ptr), y               // +2: depth

  iny
  lda $f3
  sta (tt_ptr), y               // +3: flag

  iny
  lda TTScoreLo
  sta (tt_ptr), y               // +4: score low

  iny
  lda TTScoreHi
  sta (tt_ptr), y               // +5: score high

  iny
  lda BestMoveFrom
  sta (tt_ptr), y               // +6: best from

  iny
  lda BestMoveTo
  sta (tt_ptr), y               // +7: best to

  rts
