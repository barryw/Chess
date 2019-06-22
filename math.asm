*=* "Math"
// Perform an 8-bit multiply. The numbers to multiply need to be stored
// in num1 and num2. The result is stored in A
Multiply8Bit:
  lda #$00
  beq enterLoop
doAdd:
  clc
  adc num1
loop:
  asl num1
enterLoop:
  lsr num2
  bcs doAdd
  bne loop
  rts

// Add 2 16 bit numbers
Add16Bit:
  clc
  lda num1
  adc num2
  sta result
  lda num1 + 1
  adc num2 + 1
  sta result + 1
  rts

// Subtract 2 16 bit numbers
Sub16Bit:
  sec
  lda num2
  sbc num1
  sta result
  lda num2 + 1
  sbc num1 + 1
  sta result + 1
  rts
