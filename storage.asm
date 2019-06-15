// Which chess board row are we working on right now?
counter:
  .byte $00

// Temp storage for 8 bit multiply
num1:
  .byte $00
num2:
  .byte $00

// Temp storage for 16 bit addition
word1:
  .word $00
word2:
  .word $00
result:
  .word $00

// Bit mask to turn a single sprite off
spritesoff:
  .byte $fe, $fd, $fb, $f7, $ef, $df, $bf, $7f

// Bit mask to turn a single sprite on
spriteson:
  .byte $01, $02, $04, $08, $10, $20, $40, $80

// Store the lines where we want to trigger our raster interrupt
irqypos:
  .byte $24, $3c, $54, $6c, $84, $9c, $b4, $cc

// Store the lines where we should display our chess pieces
spriteypos:
  .byte $34, $4c, $64, $7c, $94, $ac, $c4, $dc
