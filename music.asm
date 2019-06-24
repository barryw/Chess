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
  CopyMemory(MuteColorStart, ColorAddress(MusicTogglePos), MuteColorEnd - MuteColorStart)
  rts

ShowUnmute:
  CopyMemory(UnmuteStart, ScreenAddress(MusicTogglePos), UnmuteEnd - UnmuteStart)
  CopyMemory(UnmuteColorStart, ColorAddress(MusicTogglePos), UnmuteColorEnd - UnmuteColorStart)
  rts

*=music.location "Music"
.fill music.size, music.getData(i)

.print ""
.print "SID Data"
.print "--------"
.print "location=$"+toHexString(music.location)
.print "init=$"+toHexString(music.init)
.print "play=$"+toHexString(music.play)
.print "songs="+music.songs
.print "startSong="+music.startSong
.print "size=$"+toHexString(music.size)
.print "name="+music.name
.print "author="+music.author
.print "copyright="+music.copyright

.print ""
.print "Additional tech data"
.print "--------------------"
.print "header="+music.header
.print "header version="+music.version
.print "flags="+toBinaryString(music.flags)
.print "speed="+toBinaryString(music.speed)
.print "startpage="+music.startpage
.print "pagelength="+music.pagelength
