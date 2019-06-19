*=* "Variable Storage"
// Which chess board row are we working on right now?
counter:
  .byte $00

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
  .byte RED, ORANGE, YELLOW, LIGHT_GREEN, LIGHT_BLUE, BLUE, PURPLE

colorcycletiming:
  .byte $00

colorcycleposition:
  .byte $00

// Keep track of the current player. 1 = black, 0 = white
currentplayer:
  .byte $00

// Number of players
numplayers:
  .byte $00

// Whether to play music or not. 1 = play, 0 = mute
playmusic:
  .byte $00

// A flag to indicate that the user has pressed Q
isquitting:
  .byte $00

whiteseconds:
  .byte $00
whiteminutes:
  .byte $00
whitehours:
  .byte $00

blackseconds:
  .byte $00
blackminutes:
  .byte $00
blackhours:
  .byte $00
