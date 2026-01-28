#importonce

// Zobrist Hashing for Position Identification
// Uses xorshift32 PRNG seeded at startup

*=* "AI Zobrist"

//
// 16-bit Galois LFSR PRNG with improved mixing
// State stored in $fb-$fc (zero page for speed)
// Returns 8-bit result in A, advances state
//
// Uses polynomial x^16 + x^14 + x^13 + x^11 + 1
// Period: 65535 (2^16 - 1)
// Taps: bits 16, 14, 13, 11 -> feedback mask $B400
//
// Runs 8 LFSR cycles per byte for better randomness
//
ZobristPRNG:
  txa
  pha               // Preserve X register for callers
  ldx #$08          // 8 iterations per output byte

!prng_loop:
  // Galois LFSR step: shift right, XOR if LSB was 1
  lda $fb
  lsr               // Shift LSB into carry
  ror $fc           // Rotate high byte right through carry
  ror $fb           // Rotate low byte right through carry

  bcc !no_xor+      // If carry clear (LSB was 0), skip XOR
  // XOR with feedback polynomial $B400
  lda $fc
  eor #$B4
  sta $fc
!no_xor:

  dex
  bne !prng_loop-

  // Return low byte XOR high byte for better distribution
  lda $fb
  eor $fc

  // Store last result for testing
  sta ZobristLastRandom

  pla
  tax               // Restore X register

  lda ZobristLastRandom  // Return random value in A
  rts

//
// Seed the PRNG with a fixed non-zero value
// Call once at startup
// IMPORTANT: LFSR must never be all zeros!
//
ZobristSeed:
  lda #$CE
  sta $fb
  lda #$A7
  sta $fc
  rts

// Storage for last random value (for testing)
ZobristLastRandom:
  .byte $00

//
// Initialize all Zobrist tables with random values
// Call once at game startup
// Uses $f9/$fa as pointer (temp)
//
InitZobristTables:
  // Seed PRNG
  jsr ZobristSeed

  // Fill piece-square table (1536 bytes = 12 pieces x 64 squares x 2 bytes)
  lda #<ZobristPieces
  sta $f9
  lda #>ZobristPieces
  sta $fa

  ldx #$00        // Page counter (6 pages = 1536 bytes)
  ldy #$00

!fillpieces:
  jsr ZobristPRNG
  sta ($f9), y
  iny
  bne !fillpieces-

  // Next page
  inc $fa
  inx
  cpx #$06        // 6 pages for pieces (1536 bytes)
  bne !fillpieces-

  // Fill side to move (2 bytes)
  jsr ZobristPRNG
  sta ZobristSide
  jsr ZobristPRNG
  sta ZobristSide + 1

  // Fill castling rights (8 bytes = 4 flags x 2 bytes)
  ldy #$00
!castloop:
  jsr ZobristPRNG
  sta ZobristCastling, y
  iny
  cpy #$08
  bne !castloop-

  // Fill en passant files (16 bytes = 8 files x 2 bytes)
  ldy #$00
!eploop:
  jsr ZobristPRNG
  sta ZobristEnPassant, y
  iny
  cpy #$10
  bne !eploop-

  rts

//
// Zobrist Random Number Tables (16-bit version)
// 12 piece types x 64 squares x 2 bytes = 1536 bytes
// Plus: side to move (2), castling (8), en passant (16) = 26 bytes
// Total: 1562 bytes
//
// Piece indices: 0-5 = white P,N,B,R,Q,K; 6-11 = black P,N,B,R,Q,K
//

*=* "Zobrist Tables"

// Piece-square table: 12 pieces x 64 squares x 2 bytes = 1536 bytes
ZobristPieces:
  .fill 1536, $00

// Side to move (2 bytes)
ZobristSide:
  .word $0000

// Castling rights: 4 flags x 2 bytes = 8 bytes
ZobristCastling:
  .fill 8, $00

// En passant file: 8 files x 2 bytes = 16 bytes
ZobristEnPassant:
  .fill 16, $00

// Current position hash (2 bytes for better collision resistance)
ZobristHash:
  .word $0000

//
// Compute full Zobrist hash from current board position
// Result stored in ZobristHash (2 bytes)
// Clobbers: A, X, Y, $f7-$fb
//
ComputeZobristHash:
  // Clear hash (2 bytes)
  lda #$00
  sta ZobristHash
  sta ZobristHash + 1

  // Loop through all 64 valid squares using 0x88 index
  ldx #$00        // 0x88 index

!squareloop:
  // Check if valid square (index & $88 == 0)
  txa
  and #$88
  bne !nextsquare+

  // Get piece at this square
  lda Board88, x
  cmp #EMPTY_PIECE
  beq !nextsquare+

  // Save square index
  stx $f7

  // Convert piece to Zobrist index (0-11)
  jsr PieceToZobristIndex  // A = piece -> A = index 0-11
  sta $f8                   // piece index (0-11)

  // Convert 0x88 square to 0-63
  // 0x88 index: row*16 + col -> row*8 + col
  lda $f7
  and #$07        // Column (0-7)
  sta $f9
  lda $f7
  lsr
  lsr
  lsr
  lsr             // Row (0-7)
  asl
  asl
  asl             // Row * 8
  ora $f9         // + column = 0-63 index
  sta $f9         // Square 0-63

  // Calculate table offset: piece_index * 64 * 2 + square * 2
  // Each entry is now 2 bytes for 16-bit hash
  lda $f8         // piece index (0-11)
  // Multiply by 128 = shift left 7 times
  asl
  asl
  asl
  asl
  asl
  asl
  asl
  sta $fa         // Low byte of piece_index * 128
  lda $f8
  lsr             // piece_index >> 1 = high byte
  sta $fb

  // Add square * 2 to offset
  lda $f9
  asl             // square * 2
  clc
  adc $fa
  sta $fa
  lda $fb
  adc #$00
  sta $fb

  // Add ZobristPieces base address
  clc
  lda $fa
  adc #<ZobristPieces
  sta $fa
  lda $fb
  adc #>ZobristPieces
  sta $fb

  // XOR 2-byte value from table into hash
  ldy #$00
  lda ($fa), y
  eor ZobristHash
  sta ZobristHash
  iny
  lda ($fa), y
  eor ZobristHash + 1
  sta ZobristHash + 1

  // Restore square index
  ldx $f7

!nextsquare:
  inx
  cpx #$80        // Done all 128 bytes?
  bne !squareloop-

  // XOR in side to move if white (2 bytes)
  lda currentplayer
  beq !skipside+  // Black to move (0), don't XOR
  cmp #WHITES_TURN
  bne !skipside+

  // White to move - XOR in ZobristSide (2 bytes)
  lda ZobristSide
  eor ZobristHash
  sta ZobristHash
  lda ZobristSide + 1
  eor ZobristHash + 1
  sta ZobristHash + 1

!skipside:
  // XOR in castling rights (2 bytes each)
  lda castlerights
  and #CASTLE_WK
  beq !nowk+
  lda ZobristCastling
  eor ZobristHash
  sta ZobristHash
  lda ZobristCastling + 1
  eor ZobristHash + 1
  sta ZobristHash + 1
!nowk:
  lda castlerights
  and #CASTLE_WQ
  beq !nowq+
  lda ZobristCastling + 2
  eor ZobristHash
  sta ZobristHash
  lda ZobristCastling + 3
  eor ZobristHash + 1
  sta ZobristHash + 1
!nowq:
  lda castlerights
  and #CASTLE_BK
  beq !nobk+
  lda ZobristCastling + 4
  eor ZobristHash
  sta ZobristHash
  lda ZobristCastling + 5
  eor ZobristHash + 1
  sta ZobristHash + 1
!nobk:
  lda castlerights
  and #CASTLE_BQ
  beq !nobq+
  lda ZobristCastling + 6
  eor ZobristHash
  sta ZobristHash
  lda ZobristCastling + 7
  eor ZobristHash + 1
  sta ZobristHash + 1
!nobq:

  // XOR in en passant file if set (2 bytes)
  lda enpassantsq
  cmp #$FF
  beq !done+
  // Extract file (0-7) from en passant square
  and #$07
  asl             // * 2 for 2-byte entries
  tay
  lda ZobristEnPassant, y
  eor ZobristHash
  sta ZobristHash
  lda ZobristEnPassant + 1, y
  eor ZobristHash + 1
  sta ZobristHash + 1

!done:
  rts

//
// Convert piece value to Zobrist table index (0-11)
// Input: A = piece value (WHITE_PAWN..WHITE_KING or BLACK_PAWN..BLACK_KING)
// Output: A = index 0-11 (0-5 = white pieces, 6-11 = black pieces)
// Piece values: WHITE = $B1-$B6, BLACK = $31-$36
//
PieceToZobristIndex:
  pha
  and #$80        // Check color bit
  beq !black+

  // White piece: $B1-$B6 -> 0-5
  pla
  and #$07        // Get type bits
  sec
  sbc #$01        // $B1->0, $B2->1, etc.
  rts

!black:
  // Black piece: $31-$36 -> 6-11
  pla
  and #$07        // Get type bits
  clc
  adc #$05        // $31->6, $32->7, etc.
  rts
