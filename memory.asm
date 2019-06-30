*=* "Memory"
.macro PushStack() {
  pha
  txa
  pha
  tya
  pha
}

.macro PopStack() {
  pla
  tay
  pla
  tax
  pla
}

// Store a word
.macro StoreWord(address, word) {
  lda #<word
  sta address
  lda #>word
  sta address+1
}

// Perform a memory copy
// Each parameter is a 16 bit number
.macro CopyMemory(from_address, to_address, size) {
  StoreWord(copy_from, from_address)
  StoreWord(copy_to, to_address)
  StoreWord(copy_size, size)
  jsr CopyMemory
}

CopyMemory:
  ldy #0
  ldx copy_size + 1
  beq !frag+
!page:
  lda (copy_from), y
  sta (copy_to), y
  iny
  bne !page-
  inc copy_from + 1
  inc copy_to + 1
  dex
  bne !page-
!frag:
  cpy copy_size
  beq !done+
  lda (copy_from), y
  sta (copy_to), y
  iny
  bne !frag-
!done:
  rts
