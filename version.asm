// Version information - updated by cog
// Format: MAJOR.MINOR (semver without patch for display)

*=* "Version"

.const VERSION_MAJOR = 0
.const VERSION_MINOR = 1

// Version string for display: "v0.1" format
// Build string from constants using character codes
// '0' = $30, '1' = $31, etc. 'v' = $76, '.' = $2e
VersionText:
  .byte $76                           // 'v'
  .byte $30 + VERSION_MAJOR           // major digit
  .byte $2e                           // '.'
  .byte $30 + VERSION_MINOR           // minor digit
  .byte $00                           // null terminator
