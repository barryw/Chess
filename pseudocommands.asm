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
