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
  .word $0000
word2:
  .word $0000
result:
  .word $0000

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

titlecolors:
  .byte $02, $08, $07, $0d, $0e, $06, $04

colorcycletiming:
  .byte $00

colorcycleposition:
  .byte $00

// Keep track of the current player. 1 = black, 0 = white
currentplayer:
  .byte $00

// Whether to play music or not. 1 = play, 0 = mute
playmusic:
  .byte $01
