.var music = LoadSid("strings_test.sid")
.label music_play = music.play

SetupMusic:
  lda #$00
  jsr music.init
  rts

ToggleMusic:
  Toggle(playmusic)
  bfc playmusic:DisplayUnmuteMenu

DisplayMuteMenu:
  CopyMemory(MuteStart, ScreenAddress(MusicTogglePos), MuteEnd - MuteStart)
  FillMemory(ColorAddress(MusicTogglePos), MuteEnd - MuteStart, WHITE)

  jmp !exit+

DisplayUnmuteMenu:
  CopyMemory(UnmuteStart, ScreenAddress(MusicTogglePos), UnmuteEnd - UnmuteStart)
  FillMemory(ColorAddress(MusicTogglePos), UnmuteEnd - UnmuteStart, WHITE)

  lda $d418
  and #$f0
  sta $d418

!exit:
  rts

*=music.location "Music"
.fill music.size, music.getData(i)
