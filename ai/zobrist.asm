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
