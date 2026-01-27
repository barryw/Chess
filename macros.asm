/*
Push everything onto the stack. This lets us do whatever we want with the
registers and put it back the way it was before returning. This is mostly
used by the raster interrupt routine, but can be used anywhere.
*/
.macro PushStack() {
  php
  pha
  txa
  pha
  tya
  pha
}

/*
Sets the registers and processor status back to the way they were
*/
.macro PopStack() {
  pla
  tay
  pla
  tax
  pla
  plp
}

/*
Toggle a flag
*/
.macro Toggle(address) {
  lda address
  eor #ENABLE
  sta address
}

/*
Disable a flag
*/
.macro Disable(address) {
  lda #DISABLE
  sta address
}

/*
Enable a flag
*/
.macro Enable(address) {
  lda #ENABLE
  sta address
}
/*
Store a 16 bit word (clobbers A)
*/
.macro StoreWord(address, word) {
  lda #<word
  sta address
  lda #>word
  sta address + $01
}

/*
Copy a 16 bit word to another location
*/
.macro CopyWord(source, target) {
  lda source
  sta target
  lda source + $01
  sta target + $01
}

/*
Perform a memory copy

Each parameter is 16 bits
*/
.macro CopyMemory(from_address, to_address, size) {
  StoreWord(copy_from, from_address)
  StoreWord(copy_to, to_address)
  StoreWord(copy_size, size)
  jsr CopyMemory
}

/*
Fill a block of memory with a byte
*/
.macro FillMemory(address, size, value) {
  StoreWord(fill_to, address)
  StoreWord(fill_size, size)
  lda #value
  sta fill_value
  jsr FillMemory
}

/*
Print a null-terminated string at a screen position with color.
Much more compact than CopyMemory + FillMemory combination.

Usage: PrintAt(StringLabel, ScreenPosVar, COLOR)
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

/*
Sets a flag indicating which menu we're showing
*/
.macro SetMenu(menu) {
  lda #menu
  sta currentmenu
}

/*
Sets a flag indicating which input selection we're working on
*/
.macro SetInputSelection(selection) {
  lda #selection
  sta inputselection
}
