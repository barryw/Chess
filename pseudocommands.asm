/*

KickAssembler has a cool feature called 'pseudocommands' that let you build
your own pseudo instructions. They're similar to macros, but the calling
syntax very much resembles standard 6502 instructions.

*/


/* BFS: branch if flag set */
.pseudocommand bfs flag:location {
  lda flag
  bmi location
}

/* BFC: branch if flag clear */
.pseudocommand bfc flag:location {
  lda flag
  bpl location
}

/* CLF: clear flag */
.pseudocommand clf flag {
  Disable(flag)
}

/* SEF: set flag */
.pseudocommand sef flag {
  Enable(flag)
}

/* TGF: toggle flag */
.pseudocommand tgf flag {
  Toggle(flag)
}

/* WFS: wait for flag set */
.pseudocommand wfs flag {
!wait:
  bfc flag:!wait-
}

/* WFC: wait for flag clear */
.pseudocommand wfc flag {
!wait:
  bfs flag:!wait-
}

/* WFV: wait for value */
.pseudocommand wfv address:value {
!wait:
  jne address:value:!wait-
}

/* JNE: jump if not equal */
.pseudocommand jne address:value:location {
  lda address
  cmp value
  bne location
}

/* JEQ: jump if equal */
.pseudocommand jeq address:value:location {
  lda address
  cmp value
  beq location
}

/* STB: store byte */
.pseudocommand stb value:address {
  lda value
  sta address
}

/* MULT8: multiply the accumulator by 8 */
.pseudocommand mult8 {
  asl
  asl
  asl
}

/* MULT16: multiply the accumulator by 16 (for 0x88 board indexing) */
.pseudocommand mult16 {
  asl
  asl
  asl
  asl
}

/* CHK_MINE: check if the piece in the accumulator is mine */
/* and branch to 'if_not' if it isn't */
.pseudocommand chk_mine if_not {
  pcol
  cmp currentplayer
  bne if_not
}

/* CHK_EMPTY: check if a square is empty and branch if it is */
/* .x should be loaded with the 0x88 index offset for a movefrom */
/* or a moveto location */
.pseudocommand chk_empty branch {
  jeq Board88, x:#EMPTY_SPR:branch
}

/* PCOL: get the color for the piece stored in .a */
.pseudocommand pcol {
  and #BIT8
  clc
  rol
  rol
}
