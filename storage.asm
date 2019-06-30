*=* "Variable Storage"
// Which chess board row are we working on right now?
counter:
  .byte $00

// Table of sprite pointers on the current row
spritepointers:
  .fill $08, $00

// Table of pieces on the current row
spritepieces:
  .fill $08, $00

// Bit mask to turn a single sprite off
spritesoff:
  .byte $fe, $fd, $fb, $f7, $ef, $df, $bf, $7f

// Bit mask to turn a single sprite on
spriteson:
  .byte $01, $02, $04, $08, $10, $20, $40, $80

// Store the lines where we want to trigger our raster interrupt
irqypos:
  .byte $30, $48, $60, $78, $90, $a8, $c0, $d8

// Store the lines where we should display our chess pieces
spriteypos:
  .byte $34, $4c, $64, $7c, $94, $ac, $c4, $dc

titlecolorsstart:
  .byte RED, ORANGE, YELLOW, LIGHT_GREEN, LIGHT_BLUE, BLUE, PURPLE
titlecolorsend:

colorcycletiming:
  .byte $00

colorcycleposition:
  .byte $00

// The difficulty level for the game when in 1player mode
difficulty:
  .byte $00

// Keep track of the current player. 0 = black, 1 = white
currentplayer:
  .byte WHITES_TURN

// Number of players
numplayers:
  .byte $00

// Which color is player 1? 0 = black, 1 = white
player1color:
  .byte $00

// Whether to play music or not. 1 = play, 0 = mute
playmusic:
  .byte $00

// Which menu is currently being displayed?
currentmenu:
  .byte $00

// Keep track of the total time for white
whiteseconds:
  .byte $00
whiteminutes:
  .byte $00
whitehours:
  .byte $00

// Keep track of the number of each pieces captured by white
whitecaptured:
  .fill $05, $00

// Keep track of the total time for black
blackseconds:
  .byte $00
blackminutes:
  .byte $00
blackhours:
  .byte $00

// Keep track of the number of each pieces captured by black
blackcaptured:
  .fill $05, $00

// Whether the play clock of the current player should be shown
displayplayclocks:
  .byte $00

aboutisshowing:
  .byte $00

// Placeholder memory for the portion of the screen that's obscured
// by the "About" window
screenbuffer:
  .fill $1e0, $00

colorbuffer:
  .fill $1e0, $00
