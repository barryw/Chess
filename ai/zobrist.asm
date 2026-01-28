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
