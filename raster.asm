#import "vic.asm"
#import "routines.asm"

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

  PopStack()
  .if(DEBUG == true) {
    dec vic.EXTCOL
  }
  rti
