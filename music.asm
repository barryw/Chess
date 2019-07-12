.var music = LoadSid("strings_test.sid")
.label music_play = music.play

SetupMusic:
  lda #$00
  jsr music.init
  rts

ToggleMusic:
  lda playmusic
  eor #$01
  sta playmusic
  cmp #$00
  bne togglemusicreturn
  lda $d418
  and #$f0
  sta $d418
togglemusicreturn:
  jmp DisplayMuteMenu

DisplayMuteMenu:
  lda playmusic
  cmp #$00
  beq ShowUnmute
  jmp ShowMute

ShowMute:
  CopyMemory(MuteStart, ScreenAddress(MusicTogglePos), MuteEnd - MuteStart)
  FillMemory(ColorAddress(MusicTogglePos), MuteEnd - MuteStart, WHITE)
  rts

ShowUnmute:
  CopyMemory(UnmuteStart, ScreenAddress(MusicTogglePos), UnmuteEnd - UnmuteStart)
  FillMemory(ColorAddress(MusicTogglePos), UnmuteEnd - UnmuteStart, WHITE)
  rts

*=music.location "Music"
.fill music.size, music.getData(i)
