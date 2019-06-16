#import "vic.asm"
#import "routines.asm"

*=* "Raster Routine"
.macro InitRasterInterrupt(address) {
  sei

  lda #$7f
  sta vic.CIAICR
  sta vic.CI2ICR

  lda vic.CIAICR
  lda vic.CI2ICR

  lda #$01
  sta vic.VICIRQ
  sta vic.IRQMSK

  lda irqypos
  sta vic.RASTER

  lda #$1b
  sta vic.SCROLY

  StoreWord($fffe, address)

  cli
}

// Raster interrupt handler. This is the meat of generating all 32 chess
// pieces. We have 8 rows of 8 sprites, so our raster triggers every 24
// lines.
irq:
  .if(DEBUG == true) {
    inc vic.EXTCOL
  }
  PushStack()

  dec vic.VICIRQ

  ldx counter
  lda spriteypos, x

  sta vic.SP0Y
  sta vic.SP1Y
  sta vic.SP2Y
  sta vic.SP3Y
  sta vic.SP4Y
  sta vic.SP5Y
  sta vic.SP6Y
  sta vic.SP7Y

  ShowRow()

  ldx counter
  inx
  inx
  cpx #NUM_ROWS
  bne NextIRQ
  ldx #$00

NextIRQ:
  stx counter
  lda irqypos, x
  sta vic.RASTER

  .if(DEBUG == true) {
    dec vic.EXTCOL
  }

  jsr ColorCycleTitle
  jsr PlayMusic
  jsr ReadKeyboard

  PopStack()

  rti

// Read the keyboard and respond
ReadKeyboard:
  jsr Keyboard
  bcs NoValidInput
  cmp #$0d // M key
  bne NextKey1
  jsr ToggleMusic
NextKey1:
  cmp #$11 // Q key
  bne NextKey2
  jsr HandleQuit
NextKey2:
  cmp #$19 // Y key
  bne NextKey3
  jsr ConfirmQuit
NextKey3:
  cmp #$0e // N key
  bne NextKey4
  jsr QuitAbort
NextKey4:
NoValidInput:
  rts

// Play the background music
PlayMusic:
  lda counter
  cmp #$00
  bne return2
  jsr DisplayMuteMenu
  lda playmusic
  cmp #$01
  bne return2
  jsr music_play
return2:
  rts

ColorCycleTitle:
  inc colorcycletiming
  lda colorcycletiming
  cmp #$80
  beq begin
  bne return

begin:
  lda #$00
  sta colorcycletiming

  ldx #$00
  ldy colorcycleposition
  iny
  sty colorcycleposition
  cpy #$07
  bne painttitle
  ldy #$00
  sty colorcycleposition
painttitle:
  lda titlecolors, y
  sta vic.CLRRAM + 28, x
  inx
  cpx #$09
  beq return
  iny
  cpy #$07
  bne painttitle
  ldy #$00
  jmp painttitle
return:
  rts
