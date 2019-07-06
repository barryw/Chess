// Given a ScreenPos struct, return the screen memory location
.function ScreenAddress(pos) {
  .return (pos.y * $28) + pos.x + SCREEN_MEMORY
}

// Given a ScreenPos struct, return the color memory location
.function ColorAddress(pos) {
  .return (pos.y * $28) + pos.x + COLOR_MEMORY
}
