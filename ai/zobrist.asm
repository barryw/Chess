#importonce

// Zobrist Hashing for Position Identification
// Uses xorshift32 PRNG seeded at startup

*=* "AI Zobrist"

//
// 32-bit xorshift PRNG
// State stored in $fb-$fe (zero page for speed)
// Returns 8-bit result in A, advances state
//
// Algorithm: state ^= state << 13; state ^= state >> 17; state ^= state << 5
// Simplified for 6502: we do byte-level operations
//
ZobristPRNG:
  // xorshift32 simplified for 6502
  // We'll use a simpler LFSR approach that's fast on 6502
  // 32-bit state in $fb-$fe

  // Shift left, XOR back
  lda $fb
  asl
  eor $fb
  sta $fb

  lda $fc
  rol
  eor $fc
  sta $fc

  lda $fd
  rol
  eor $fd
  sta $fd

  lda $fe
  rol
  eor $fe
  sta $fe

  // Mix bytes for output
  lda $fb
  eor $fc
  eor $fd
  eor $fe

  // Store last result for testing
  sta ZobristLastRandom

  rts

//
// Seed the PRNG with a fixed value
// Call once at startup
//
ZobristSeed:
  lda #$12
  sta $fb
  lda #$34
  sta $fc
  lda #$56
  sta $fd
  lda #$78
  sta $fe
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

  // Fill piece-square table (768 bytes = 12 pieces x 64 squares)
  lda #<ZobristPieces
  sta $f9
  lda #>ZobristPieces
  sta $fa

  ldx #$00        // Page counter (3 pages = 768 bytes)
  ldy #$00

!fillpieces:
  jsr ZobristPRNG
  sta ($f9), y
  iny
  bne !fillpieces-

  // Next page
  inc $fa
  inx
  cpx #$03        // 3 pages for pieces (768 bytes)
  bne !fillpieces-

  // Fill side to move (1 byte)
  jsr ZobristPRNG
  sta ZobristSide

  // Fill castling rights (4 bytes)
  ldy #$00
!castloop:
  jsr ZobristPRNG
  sta ZobristCastling, y
  iny
  cpy #$04
  bne !castloop-

  // Fill en passant files (8 bytes)
  ldy #$00
!eploop:
  jsr ZobristPRNG
  sta ZobristEnPassant, y
  iny
  cpy #$08
  bne !eploop-

  rts

//
// Zobrist Random Number Tables
// 12 piece types x 64 squares = 768 bytes
// Plus: side to move (1), castling (4), en passant (8) = 13 bytes
// Total: 781 bytes
//
// Piece indices: 0-5 = white P,N,B,R,Q,K; 6-11 = black P,N,B,R,Q,K
//
// For 8-bit hashing (simplified - full 32-bit comes later)
//

*=* "Zobrist Tables"

// Piece-square table: 12 pieces x 64 squares x 1 byte = 768 bytes
ZobristPieces:
  .fill 768, $00

// Side to move (1 byte)
ZobristSide:
  .byte $00

// Castling rights: 4 flags x 1 byte
ZobristCastling:
  .fill 4, $00

// En passant file: 8 files x 1 byte
ZobristEnPassant:
  .fill 8, $00

// Current position hash (1 byte for simplified hashing)
ZobristHash:
  .byte $00

//
// Compute full Zobrist hash from current board position
// Result stored in ZobristHash (1 byte)
// Clobbers: A, X, Y, $f7-$fa
//
ComputeZobristHash:
  // Clear hash
  lda #$00
  sta ZobristHash

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

  // Calculate table offset: piece_index * 64 + square
  lda $f8         // piece index (0-11)
  // Multiply by 64 = shift left 6 times
  asl
  asl
  asl
  asl
  asl
  asl
  // Low byte is now (piece_index * 64) & $FF
  // High byte of piece_index * 64 = piece_index >> 2
  sta $fa         // Save low byte temporarily
  lda $f8
  lsr
  lsr             // piece_index >> 2 = high byte
  sta $fb         // High byte of base offset

  // Add square to offset
  clc
  lda $fa
  adc $f9         // + square
  sta $fa
  lda $fb
  adc #$00        // Add carry
  sta $fb

  // Add ZobristPieces base address
  clc
  lda $fa
  adc #<ZobristPieces
  sta $fa
  lda $fb
  adc #>ZobristPieces
  sta $fb

  // XOR value from table into hash
  ldy #$00
  lda ($fa), y
  eor ZobristHash
  sta ZobristHash

  // Restore square index
  ldx $f7

!nextsquare:
  inx
  cpx #$80        // Done all 128 bytes?
  bne !squareloop-

  // XOR in side to move if white
  lda currentplayer
  beq !done+      // Black to move (0), don't XOR
  cmp #WHITES_TURN
  bne !done+

  // White to move - XOR in ZobristSide
  lda ZobristSide
  eor ZobristHash
  sta ZobristHash

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
