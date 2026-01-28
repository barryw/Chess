// Opening Book Module
// Hash-based opening book with swappable architecture
//
// Memory Layout:
//   BookBase points to current book data (embedded or loaded)
//   Book format allows hot-swapping different books from disk
//
// Book Data Structure:
//   Header (8 bytes):
//     .word Magic      ($B00C = "BOOK" marker)
//     .byte Version    (format version)
//     .word EntryCount (number of positions)
//     .word TableSize  (hash table slots, power of 2)
//     .byte Flags      (reserved)
//   Hash Table (TableSize * 2 bytes):
//     Each slot is a .word offset to first entry, or $FFFF if empty
//   Entries (EntryCount * 4 bytes each):
//     .byte HashHi     (upper 8 bits of position hash for verification)
//     .byte From       (0x88 square)
//     .byte To         (0x88 square)
//     .byte Next       (index of next entry in chain, or $FF if end)

*=* "Opening Book"

// Book format constants
.const BOOK_MAGIC       = $B00C
.const BOOK_VERSION     = $01
.const BOOK_ENTRY_SIZE  = 4
.const BOOK_NO_ENTRY    = $FFFF
.const BOOK_CHAIN_END   = $FF

// Header offsets
.const BOOK_HDR_MAGIC       = 0
.const BOOK_HDR_VERSION     = 2
.const BOOK_HDR_ENTRY_COUNT = 3
.const BOOK_HDR_TABLE_SIZE  = 5
.const BOOK_HDR_FLAGS       = 7
.const BOOK_HDR_SIZE        = 8

//
// Book state (can point to embedded or loaded book)
//
BookBase:
  .word DefaultBook       // Pointer to current book data
BookEnabled:
  .byte $01               // $01 = use book, $00 = disabled
BookMoveCount:
  .byte $00               // Moves played from book this game

// Storage for multiple matching moves (up to 4)
.const MAX_BOOK_MATCHES = 4
MatchCount:
  .byte $00               // Number of matches found
MatchBuffer:
  .fill MAX_BOOK_MATCHES * 2, $00  // from0, to0, from1, to1, ...

//
// LookupOpeningMove
// Search the opening book for the current position
// Now supports multiple moves per position with random selection
// Input: ZobristHash contains current position hash (2 bytes)
// Output: Carry set = move found
//           A = from square (0x88)
//           Y = to square (0x88)
//         Carry clear = not in book
// Clobbers: A, X, Y, temp1, temp2
//
LookupOpeningMove:
  // Initialize match count
  lda #$00
  sta MatchCount

  // Check if book is enabled
  lda BookEnabled
  bne !book_enabled+
  jmp !not_found+
!book_enabled:

  // Get book base pointer into temp1
  lda BookBase
  sta temp1
  lda BookBase + 1
  sta temp1 + 1

  // Verify magic number
  ldy #BOOK_HDR_MAGIC
  lda (temp1), y
  cmp #<BOOK_MAGIC
  bne !bad_magic+
  iny
  lda (temp1), y
  cmp #>BOOK_MAGIC
  beq !magic_ok+
!bad_magic:
  jmp !not_found+
!magic_ok:

  // Get table size into temp2 (for masking)
  ldy #BOOK_HDR_TABLE_SIZE
  lda (temp1), y
  sta temp2
  iny
  lda (temp1), y
  sta temp2 + 1

  // Calculate hash table index: ZobristHash & (TableSize - 1)
  // Since TableSize is power of 2, TableSize-1 is the mask
  lda temp2
  sec
  sbc #$01
  sta BookMask
  lda temp2 + 1
  sbc #$00
  sta BookMask + 1

  // Apply mask to hash
  lda ZobristHash
  and BookMask
  sta BookIndex
  lda ZobristHash + 1
  and BookMask + 1
  sta BookIndex + 1

  // Calculate hash table entry address
  // HashTableStart = BookBase + BOOK_HDR_SIZE
  // EntryAddr = HashTableStart + (BookIndex * 2)
  lda temp1
  clc
  adc #BOOK_HDR_SIZE
  sta HashTablePtr
  lda temp1 + 1
  adc #$00
  sta HashTablePtr + 1

  // Add BookIndex * 2
  lda BookIndex
  asl               // * 2
  clc
  adc HashTablePtr
  sta HashTablePtr
  lda BookIndex + 1
  rol               // Carry from asl
  adc HashTablePtr + 1
  sta HashTablePtr + 1

  // Read hash table slot (2-byte offset to entry)
  ldy #$00
  lda (HashTablePtr), y
  sta EntryOffset
  iny
  lda (HashTablePtr), y
  sta EntryOffset + 1

  // Check if slot is empty ($FFFF)
  lda EntryOffset
  and EntryOffset + 1
  cmp #$FF
  bne !slot_valid+
  jmp !not_found+
!slot_valid:

  // Calculate entries base address
  // EntriesBase = BookBase + BOOK_HDR_SIZE + (TableSize * 2)
  lda temp1
  clc
  adc #BOOK_HDR_SIZE
  sta EntriesBase
  lda temp1 + 1
  adc #$00
  sta EntriesBase + 1

  // Add TableSize * 2
  lda temp2         // TableSize low
  asl
  clc
  adc EntriesBase
  sta EntriesBase
  lda temp2 + 1     // TableSize high
  rol
  adc EntriesBase + 1
  sta EntriesBase + 1

  // Walk the ENTIRE chain collecting ALL matches (up to MAX_BOOK_MATCHES)
!check_entry:
  // Calculate entry address: EntriesBase + (EntryOffset * 4)
  lda EntryOffset
  asl
  asl               // * 4
  clc
  adc EntriesBase
  sta EntryPtr
  lda EntryOffset + 1
  rol
  rol               // Carry through
  adc EntriesBase + 1
  sta EntryPtr + 1

  // Compare HashHi byte (upper 8 bits of Zobrist)
  ldy #$00
  lda (EntryPtr), y
  cmp ZobristHash + 1
  bne !next_in_chain+

  // Match found! Store it if we have room
  lda MatchCount
  cmp #MAX_BOOK_MATCHES
  bcs !next_in_chain+     // Skip if buffer full

  // Calculate buffer offset: MatchCount * 2
  asl                     // A = MatchCount * 2
  tax                     // X = buffer offset

  // Store from square
  ldy #$01
  lda (EntryPtr), y
  sta MatchBuffer, x

  // Store to square
  iny
  lda (EntryPtr), y
  inx
  sta MatchBuffer, x

  // Increment match count
  inc MatchCount

!next_in_chain:
  // Get next entry in chain
  ldy #$03          // Next byte offset
  lda (EntryPtr), y
  cmp #BOOK_CHAIN_END
  bne !follow_chain+
  jmp !select_move+       // End of chain, select from matches

!follow_chain:
  // Update EntryOffset to next entry
  sta EntryOffset
  lda #$00
  sta EntryOffset + 1
  jmp !check_entry-

!select_move:
  // Check if we found any matches
  lda MatchCount
  beq !not_found+

  // If only one match, use it directly
  cmp #$01
  beq !use_first+

  // Multiple matches - randomly select using CIA Timer A
  // Timer A free-runs at ~1MHz, gives pseudo-random low byte
  lda $DC04             // CIA Timer A low byte
  ldx MatchCount        // Get match count
  jsr ModByMatchCount   // A = A mod MatchCount

  // A now contains index 0..MatchCount-1
  // Calculate buffer offset: index * 2
  asl
  tax

  // Return selected move
  lda MatchBuffer, x    // A = from square
  pha
  inx
  lda MatchBuffer, x    // A = to square
  tay                   // Y = to square
  pla                   // A = from square
  inc BookMoveCount
  sec                   // Carry set = found
  rts

!use_first:
  // Use first (only) match
  lda MatchBuffer       // A = from square
  ldy MatchBuffer + 1   // Y = to square
  inc BookMoveCount
  sec                   // Carry set = found
  rts

!not_found:
  clc               // Carry clear = not found
  rts

//
// ModByMatchCount
// Compute A mod X (for random selection)
// Input: A = value, X = modulus (2-4)
// Output: A = A mod X
// Clobbers: nothing else
//
ModByMatchCount:
  // Simple repeated subtraction for small modulus
!mod_loop:
  stx ModTemp
  cmp ModTemp
  bcc !mod_done+      // A < X, done
  sec
  sbc ModTemp
  jmp !mod_loop-
!mod_done:
  rts

ModTemp: .byte $00

//
// DisableBook
// Turn off opening book (for testing or after leaving book)
//
DisableBook:
  lda #$00
  sta BookEnabled
  rts

//
// EnableBook
// Turn on opening book
//
EnableBook:
  lda #$01
  sta BookEnabled
  rts

//
// ResetBookState
// Call at start of new game
//
ResetBookState:
  lda #$01
  sta BookEnabled
  lda #$00
  sta BookMoveCount
  rts

//
// SetBookPointer
// Change the active book (for swapping)
// Input: A = low byte of book address
//        Y = high byte of book address
//
SetBookPointer:
  sta BookBase
  sty BookBase + 1
  rts

// Temporary storage for book lookup
BookMask:       .word $0000
BookIndex:      .word $0000
HashTablePtr:   .word $0000
EntryOffset:    .word $0000
EntriesBase:    .word $0000
EntryPtr:       .word $0000

//
// Import the generated opening book
// Generated from GM2600 Polyglot book with 8000 positions
// Run: python3 tools/generate_book.py tools/books/gm2600.bin book_data.asm
//
#import "book_data.asm"

// Point to generated book (alias for compatibility)
.label DefaultBook = GeneratedBook
