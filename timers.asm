// Timer Library
// Manages up to 8 single-shot or continuous timers with callbacks
// Adapted from c64lib by Barry Walker
//
// Usage:
//   1. Call ClearTimers at startup
//   2. Call CreateTimer to set up each timer
//   3. Call UpdateTimers once per frame (60 times/second)
//
// Each timer uses 8 bytes:
//   +0: enabled (0=disabled, 1=enabled)
//   +1: mode (0=single-shot, 1=continuous)
//   +2,+3: current countdown (16-bit)
//   +4,+5: reload frequency (16-bit, 60=1 second)
//   +6,+7: callback address (16-bit)

*=* "Timer Routines"

//
// ClearTimers
// Initialize all timer slots to zero
//
ClearTimers:
  FillMI($00, c64lib_timers, TIMER_STRUCT_BYTES)
  rts

//
// SetupTimers
// Create and configure all game timers at startup
//
SetupTimers:
  // Timer 0: Flash piece (continuous, starts disabled)
  StoreWord(r0, PIECE_FLASH_SPEED)         // frequency
  StoreWord(r1, FlashPieceCallback)        // callback
  lda #TIMER_CONTINUOUS
  sta r2L                                  // mode
  lda #TIMER_FLASH_PIECE
  sta r2H                                  // timer number
  lda #DISABLE
  sta r3L                                  // disabled initially
  jsr CreateTimer

  // Timer 1: Flash cursor (continuous, starts disabled)
  StoreWord(r0, CURSOR_FLASH_SPEED)        // frequency
  StoreWord(r1, FlashCursorCallback)       // callback
  lda #TIMER_CONTINUOUS
  sta r2L                                  // mode
  lda #TIMER_FLASH_CURSOR
  sta r2H                                  // timer number
  lda #DISABLE
  sta r3L                                  // disabled initially
  jsr CreateTimer

  // Timer 2: Spinner (continuous, starts disabled)
  StoreWord(r0, THINKING_SPINNER_SPEED)    // frequency
  StoreWord(r1, SpinnerCallback)           // callback
  lda #TIMER_CONTINUOUS
  sta r2L                                  // mode
  lda #TIMER_SPINNER
  sta r2H                                  // timer number
  lda #DISABLE
  sta r3L                                  // disabled initially
  jsr CreateTimer

  // Timer 3: Color cycle title (continuous, always enabled)
  StoreWord(r0, TITLE_COLOR_SCROLL_SPEED)  // frequency
  StoreWord(r1, ColorCycleTitle)           // callback
  lda #TIMER_CONTINUOUS
  sta r2L                                  // mode
  lda #TIMER_COLOR_CYCLE
  sta r2H                                  // timer number
  lda #ENABLE
  sta r3L                                  // enabled
  jsr CreateTimer
  rts

//
// CreateTimer
// Set up a new timer
//
// Input:
//   r0 (r0L/r0H): frequency in 60ths of a second (60 = 1 second)
//   r1 (r1L/r1H): callback address to call when timer fires
//   r2L: mode - TIMER_SINGLE_SHOT (0) or TIMER_CONTINUOUS (1)
//   r2H: timer number (0-7)
//   r3L: enabled - DISABLE (0) or ENABLE ($80)
//
CreateTimer:
  lda r2H
  mult8
  tax

  stb r3L:c64lib_timers, x        // +0: enabled
  stb r2L:c64lib_timers + $01, x  // +1: mode
  stb r0L:c64lib_timers + $02, x  // +2: current low
  stb r0H:c64lib_timers + $03, x  // +3: current high
  stb r0L:c64lib_timers + $04, x  // +4: frequency low
  stb r0H:c64lib_timers + $05, x  // +5: frequency high
  stb r1L:c64lib_timers + $06, x  // +6: callback low
  stb r1H:c64lib_timers + $07, x  // +7: callback high
  rts

//
// UpdateTimers
// Decrement all active timers and fire callbacks when they expire
// Call this once per frame (60 times per second)
//
UpdateTimers:
  ldy #$00                        // Y = timer index (0-7)

!timer_loop:
  tya
  mult8
  sta r0L                         // r0L = timer struct offset
  tax

  // Check if timer is enabled
  jne c64lib_timers, x:#ENABLE:!next_timer+

  // Timer is enabled - save mode for later
  inx
  stb c64lib_timers, x:r3H        // r3H = mode
  inx
  stx r1H                         // r1H = offset to current countdown

  // Check if already at zero before decrementing (safeguard)
  lda c64lib_timers, x            // Low byte
  ora c64lib_timers + $01, x      // OR with high byte
  beq !timer_fired+               // Already zero - skip to fire

  // Decrement 16-bit countdown
  lda c64lib_timers, x            // Load low byte
  bne !dec_low+
  dec c64lib_timers + $01, x      // Decrement high byte if low is 0
!dec_low:
  dec c64lib_timers, x            // Decrement low byte

  // Check if countdown reached zero
  lda c64lib_timers, x            // Low byte
  bne !next_timer+
  lda c64lib_timers + $01, x      // High byte
  bne !next_timer+

!timer_fired:
  // Timer expired! Reload countdown from frequency
  inx
  inx
  stb c64lib_timers, x:r2L        // r2L = frequency low
  inx
  stb c64lib_timers, x:r2H        // r2H = frequency high

  // Reload current countdown
  lda r1H
  tax
  stb r2L:c64lib_timers, x        // current low = frequency low
  inx
  stb r2H:c64lib_timers, x        // current high = frequency high

  // Get callback address
  inx
  inx
  inx
  tya
  pha                             // Save timer index
  lda r0L
  pha                             // Save r0L (callback may use it)
  lda r3H
  pha                             // Save r3H (timer mode)

  stb c64lib_timers, x:r2L        // r2L = callback low
  inx
  stb c64lib_timers, x:r2H        // r2H = callback high

  // Call the callback via indirect jump
  jsr !dispatch+
  jmp !after_dispatch+

!dispatch:
  jmp (r2)

!after_dispatch:
  pla
  sta r3H                         // Restore r3H (timer mode)
  pla
  sta r0L                         // Restore r0L (base offset)
  pla
  tay                             // Restore timer index

  // If single-shot, disable the timer
  jeq r3H:#TIMER_CONTINUOUS:!next_timer+
  ldx r0L
  stb #DISABLE:c64lib_timers, x

!next_timer:
  iny
  cpy #MAX_TIMERS
  beq !done+
  jmp !timer_loop-
!done:
  rts

//
// EnableTimer
// Enable a specific timer
//
// Input: A = timer number (0-7)
//
EnableTimer:
  mult8
  tax
  stb #ENABLE:c64lib_timers, x
  rts

//
// DisableTimer
// Disable a specific timer
//
// Input: A = timer number (0-7)
//
DisableTimer:
  mult8
  tax
  stb #DISABLE:c64lib_timers, x
  rts

//
// EnDisTimer
// Enable or disable a timer (legacy interface)
//
// Input:
//   r2H: timer number (0-7)
//   r3L: ENABLE ($80) or DISABLE (0)
//
EnDisTimer:
  lda r2H
  mult8
  tax
  stb r3L:c64lib_timers, x
  rts
