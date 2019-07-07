*=* "Variable Storage"
// Which chess board row are we working on right now?
counter:
  .byte $00

// The temp location of the current piece
currentpiece:
  .byte $00

// The temp location of the current key pressed
currentkey:
  .byte $00

// Temp location for when the board is flipped
fliptmp:
  .fill $40, $00

// Store the lines where we want to trigger our raster interrupt
irqypos:
  .byte $30, $48, $60, $78, $90, $a8, $c0, $d8

// Store the lines where we should display our chess pieces
spriteypos:
  .byte $34, $4c, $64, $7c, $94, $ac, $c4, $dc

titlecolorsstart:
  .byte RED, ORANGE, YELLOW, LIGHT_GREEN, LIGHT_BLUE, BLUE, PURPLE
titlecolorsend:

// Whether to show the spinner
spinnerenabled:
  .byte $00

// Display an indeterminate progress bar with some characters
spinnerstart:
  .byte $7c, $6c, $7b, $7e
spinnerend:

// The current spinner character being shown
spinnercurrent:
  .byte $00

spinnertiming:
  .byte THINKING_SPINNER_SPEED

colorcycletiming:
  .byte TITLE_COLOR_SCROLL_SPEED

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

// This gets updated every screen refresh. It counts down and once
// it reaches 0, it will update the seconds value for the current
// player.
subseconds:
  .byte $3c

// Screen locations for each component of the timer
timerpositions:
  .word ScreenAddress(SecondsPos), ScreenAddress(MinutesPos), ScreenAddress(HoursPos)

// Whether or not the play clock is counting
playclockrunning:
  .byte $80

// Whether to show the flashing cursor to wait for the movefrom/moveto coordinates
showcursor:
  .byte $00

cursorxpos:
  .byte $00

// Countdown timer for flashing the cursor
cursorflashtimer:
  .byte CURSOR_FLASH_SPEED

timers:

// Keep track of the total time for white
// Stored as BCD
whiteseconds:
  .byte $00
whiteminutes:
  .byte $00
whitehours:
  .byte $00

// Keep track of the total time for black
// Stored as BCD
blackseconds:
  .byte $00
blackminutes:
  .byte $00
blackhours:
  .byte $00

// Keep track of the number of each pieces captured by white
whitecaptured:
  .fill $05, $00

// Keep track of the number of each pieces captured by black
blackcaptured:
  .fill $05, $00

aboutisshowing:
  .byte $00

// Placeholder memory for the portion of the screen that's obscured
// by the "About" window
screenbuffer:
  .fill $1e0, $00

colorbuffer:
  .fill $1e0, $00

// Make sure we only do one memcopy/memfill at a time. There can be
// a race condition between interrupt and non-interrupt code.
fillmutex:
  .byte $00
copymutex:
  .byte $00

coordinates:
// Stores the player's selected piece
movefrom:
  .word $0000
// Stores the location where the player wants to move to
moveto:
  .word $0000

coordinateindex:
  .byte $00

// Store the offset in BoardState for the piece to move here
movefromindex:
  .byte $00

// Store the offset in BoardState for the location to move to here
movetoindex:
  .byte $00

// This is a lookup table to translate row numbers into their
// inverse. This is needed due to the way BoardState is arranged.
// This could probably be done in code, but I'm lazy.
rowlookup:
  .byte $07, $06, $05, $04, $03, $02, $01, $00
