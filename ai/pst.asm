// ai/pst.asm
#importonce

// Piece-Square Tables for Position Evaluation
// Values scaled to match evaluation (pawn = 10)
// Tables are from White's perspective; Black mirrors by XOR $38
// Placed after opening book to avoid overlap

*=$A4A8 "Piece-Square Tables"

// Pawn PST (64 bytes)
// Rewards center control and advancement
PST_Pawn:
  .byte   0,  0,  0,  0,  0,  0,  0,  0   // Rank 8 (never here)
  .byte  50, 50, 50, 50, 50, 50, 50, 50   // Rank 7 (about to promote!)
  .byte  10, 10, 20, 30, 30, 20, 10, 10   // Rank 6
  .byte   5,  5, 10, 25, 25, 10,  5,  5   // Rank 5
  .byte   0,  0,  0, 20, 20,  0,  0,  0   // Rank 4 (center pawns)
  .byte   5, -5,-10,  0,  0,-10, -5,  5   // Rank 3
  .byte   5, 10, 10,-20,-20, 10, 10,  5   // Rank 2 (don't block c/f pawns)
  .byte   0,  0,  0,  0,  0,  0,  0,  0   // Rank 1 (never here)

// Knight PST (64 bytes)
// Knights love center, hate rim
PST_Knight:
  .byte -50,-40,-30,-30,-30,-30,-40,-50
  .byte -40,-20,  0,  5,  5,  0,-20,-40
  .byte -30,  5, 10, 15, 15, 10,  5,-30
  .byte -30,  0, 15, 20, 20, 15,  0,-30
  .byte -30,  5, 15, 20, 20, 15,  5,-30
  .byte -30,  0, 10, 15, 15, 10,  0,-30
  .byte -40,-20,  0,  0,  0,  0,-20,-40
  .byte -50,-40,-30,-30,-30,-30,-40,-50

// Bishop PST (64 bytes)
// Long diagonals good, avoid corners
PST_Bishop:
  .byte -20,-10,-10,-10,-10,-10,-10,-20
  .byte -10,  5,  0,  0,  0,  0,  5,-10
  .byte -10, 10, 10, 10, 10, 10, 10,-10
  .byte -10,  0, 10, 10, 10, 10,  0,-10
  .byte -10,  5,  5, 10, 10,  5,  5,-10
  .byte -10,  0,  5, 10, 10,  5,  0,-10
  .byte -10,  0,  0,  0,  0,  0,  0,-10
  .byte -20,-10,-10,-10,-10,-10,-10,-20

// Rook PST (64 bytes)
// 7th rank bonus, central files
PST_Rook:
  .byte   0,  0,  0,  5,  5,  0,  0,  0
  .byte   5, 10, 10, 10, 10, 10, 10,  5   // 7th rank bonus
  .byte  -5,  0,  0,  0,  0,  0,  0, -5
  .byte  -5,  0,  0,  0,  0,  0,  0, -5
  .byte  -5,  0,  0,  0,  0,  0,  0, -5
  .byte  -5,  0,  0,  0,  0,  0,  0, -5
  .byte  -5,  0,  0,  0,  0,  0,  0, -5
  .byte   0,  0,  0,  5,  5,  0,  0,  0

// Queen PST (64 bytes)
// Slight center preference, mobility
PST_Queen:
  .byte -20,-10,-10, -5, -5,-10,-10,-20
  .byte -10,  0,  5,  0,  0,  0,  0,-10
  .byte -10,  5,  5,  5,  5,  5,  0,-10
  .byte   0,  0,  5,  5,  5,  5,  0, -5
  .byte  -5,  0,  5,  5,  5,  5,  0, -5
  .byte -10,  0,  5,  5,  5,  5,  0,-10
  .byte -10,  0,  0,  0,  0,  0,  0,-10
  .byte -20,-10,-10, -5, -5,-10,-10,-20

// King PST - Middlegame (64 bytes)
// Castled corners good, center bad
PST_KingMid:
  .byte  20, 30, 10,  0,  0, 10, 30, 20
  .byte  20, 20,  0,  0,  0,  0, 20, 20
  .byte -10,-20,-20,-20,-20,-20,-20,-10
  .byte -20,-30,-30,-40,-40,-30,-30,-20
  .byte -30,-40,-40,-50,-50,-40,-40,-30
  .byte -30,-40,-40,-50,-50,-40,-40,-30
  .byte -30,-40,-40,-50,-50,-40,-40,-30
  .byte -30,-40,-40,-50,-50,-40,-40,-30

// King PST - Endgame (64 bytes)
// Centralized, active king
PST_KingEnd:
  .byte -50,-30,-30,-30,-30,-30,-30,-50
  .byte -30,-30,  0,  0,  0,  0,-30,-30
  .byte -30,-10, 20, 30, 30, 20,-10,-30
  .byte -30,-10, 30, 40, 40, 30,-10,-30
  .byte -30,-10, 30, 40, 40, 30,-10,-30
  .byte -30,-10, 20, 30, 30, 20,-10,-30
  .byte -30,-20,-10,  0,  0,-10,-20,-30
  .byte -50,-40,-30,-20,-20,-30,-40,-50

// PST pointer table (indexed by piece type 1-6)
// Each entry points to the PST for that piece type
PST_Table_Lo:
  .byte 0                    // 0: unused
  .byte <PST_Pawn            // 1: Pawn
  .byte <PST_Knight          // 2: Knight
  .byte <PST_Bishop          // 3: Bishop
  .byte <PST_Rook            // 4: Rook
  .byte <PST_Queen           // 5: Queen
  .byte <PST_KingMid         // 6: King (middlegame default)

PST_Table_Hi:
  .byte 0
  .byte >PST_Pawn
  .byte >PST_Knight
  .byte >PST_Bishop
  .byte >PST_Rook
  .byte >PST_Queen
  .byte >PST_KingMid

// Endgame threshold: if total material < this, use endgame king PST
.const ENDGAME_THRESHOLD = 26  // Roughly Q+R or less per side
