// Version information - updated by cog
// Format: MAJOR.MINOR (semver without patch for display)

*=* "Version"

.const VERSION_MAJOR = 0
.const VERSION_MINOR = 1

// Version string for display: "v0.1" format
// Screen codes (poke codes) for direct screen memory writes
// '0'-'9' = $30-$39, 'v' = $16, '.' = $2e
VersionText:
  .byte $16                           // 'v' (screen code)
  .byte $30 + VERSION_MAJOR           // major digit
  .byte $2e                           // '.'
  .byte $30 + VERSION_MINOR           // minor digit
  .byte $00                           // null terminator
