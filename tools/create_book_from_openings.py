#!/usr/bin/env python3
"""
Create opening book from known opening lines.

This generates a C64 chess opening book directly from opening move sequences,
computing our custom Zobrist hashes for each position.

No external book file needed - openings are embedded here.
"""

import sys
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass
from collections import defaultdict


# =============================================================================
# C64 Zobrist PRNG (matches ai/zobrist.asm exactly)
# =============================================================================

class C64ZobristPRNG:
    """16-bit Galois LFSR matching the 6502 implementation."""

    def __init__(self):
        self.state = 0xA7CE  # Seed matches ZobristSeed

    def next_byte(self) -> int:
        """Generate one byte, advancing state."""
        lsb = self.state & 1
        self.state >>= 1
        if lsb:
            self.state ^= 0xB400
        return self.state & 0xFF


# =============================================================================
# Zobrist Table Generation
# =============================================================================

@dataclass
class ZobristTables:
    pieces: List[List[int]]
    side: int
    castling: List[int]
    en_passant: List[int]


def generate_zobrist_tables() -> ZobristTables:
    """Generate tables using exact same PRNG as C64."""
    prng = C64ZobristPRNG()

    pieces = []
    for _ in range(12):
        piece_hashes = []
        for _ in range(64):
            lo = prng.next_byte()
            hi = prng.next_byte()
            piece_hashes.append(lo | (hi << 8))
        pieces.append(piece_hashes)

    side_lo = prng.next_byte()
    side_hi = prng.next_byte()
    side = side_lo | (side_hi << 8)

    castling = []
    for _ in range(4):
        lo = prng.next_byte()
        hi = prng.next_byte()
        castling.append(lo | (hi << 8))

    en_passant = []
    for _ in range(8):
        lo = prng.next_byte()
        hi = prng.next_byte()
        en_passant.append(lo | (hi << 8))

    return ZobristTables(pieces, side, castling, en_passant)


# =============================================================================
# Chess Position
# =============================================================================

PIECE_TO_ZOBRIST = {
    'P': 0, 'N': 1, 'B': 2, 'R': 3, 'Q': 4, 'K': 5,
    'p': 6, 'n': 7, 'b': 8, 'r': 9, 'q': 10, 'k': 11,
}

def sq_to_0x88(file: int, rank: int) -> int:
    return (7 - rank) * 16 + file

def sq_from_0x88(sq88: int) -> Tuple[int, int]:
    return sq88 & 7, 7 - (sq88 >> 4)

def sq_to_64(file: int, rank: int) -> int:
    return (7 - rank) * 8 + file

def parse_square(s: str) -> int:
    """Parse 'e2' to 0x88 index."""
    return sq_to_0x88(ord(s[0]) - ord('a'), int(s[1]) - 1)


class Position:
    zobrist_tables: ZobristTables = None  # Shared across all instances

    def __init__(self):
        if Position.zobrist_tables is None:
            Position.zobrist_tables = generate_zobrist_tables()

        self.board: Dict[int, str] = {}
        self.white_to_move = True
        self.castling = [True, True, True, True]  # WK, WQ, BK, BQ
        self.ep_file: Optional[int] = None
        self._setup_initial()

    def _setup_initial(self):
        back_rank = 'RNBQKBNR'
        for file, piece in enumerate(back_rank):
            self.board[sq_to_0x88(file, 0)] = piece
            self.board[sq_to_0x88(file, 7)] = piece.lower()
        for file in range(8):
            self.board[sq_to_0x88(file, 1)] = 'P'
            self.board[sq_to_0x88(file, 6)] = 'p'

    def copy(self) -> 'Position':
        pos = Position.__new__(Position)
        pos.board = self.board.copy()
        pos.white_to_move = self.white_to_move
        pos.castling = self.castling.copy()
        pos.ep_file = self.ep_file
        return pos

    def compute_hash(self) -> int:
        """Compute 16-bit Zobrist hash."""
        tables = Position.zobrist_tables
        h = 0

        for sq88, piece in self.board.items():
            piece_idx = PIECE_TO_ZOBRIST[piece]
            file, rank = sq_from_0x88(sq88)
            sq64 = sq_to_64(file, rank)
            h ^= tables.pieces[piece_idx][sq64]

        if self.white_to_move:
            h ^= tables.side

        for i, has_right in enumerate(self.castling):
            if has_right:
                h ^= tables.castling[i]

        if self.ep_file is not None:
            h ^= tables.en_passant[self.ep_file]

        return h & 0xFFFF

    def make_move(self, from_sq: int, to_sq: int, promo: Optional[str] = None) -> 'Position':
        pos = self.copy()
        piece = pos.board.get(from_sq)
        if piece is None:
            raise ValueError(f"No piece at {from_sq:#x}")

        captured = pos.board.get(to_sq)
        pos.ep_file = None
        piece_type = piece.upper()
        from_file, from_rank = sq_from_0x88(from_sq)
        to_file, to_rank = sq_from_0x88(to_sq)

        if piece_type == 'P':
            if abs(from_rank - to_rank) == 2:
                pos.ep_file = from_file
            if to_file != from_file and captured is None:
                ep_sq = sq_to_0x88(to_file, from_rank)
                del pos.board[ep_sq]
            if to_rank == 0 or to_rank == 7:
                promo_piece = promo or 'Q'
                piece = promo_piece if piece.isupper() else promo_piece.lower()

        if piece_type == 'K':
            if from_file == 4:
                if to_file == 6:
                    rook_from = sq_to_0x88(7, from_rank)
                    rook_to = sq_to_0x88(5, from_rank)
                    pos.board[rook_to] = pos.board[rook_from]
                    del pos.board[rook_from]
                elif to_file == 2:
                    rook_from = sq_to_0x88(0, from_rank)
                    rook_to = sq_to_0x88(3, from_rank)
                    pos.board[rook_to] = pos.board[rook_from]
                    del pos.board[rook_from]
            if piece.isupper():
                pos.castling[0] = False
                pos.castling[1] = False
            else:
                pos.castling[2] = False
                pos.castling[3] = False

        if piece_type == 'R':
            if piece.isupper():
                if from_sq == sq_to_0x88(7, 0):
                    pos.castling[0] = False
                elif from_sq == sq_to_0x88(0, 0):
                    pos.castling[1] = False
            else:
                if from_sq == sq_to_0x88(7, 7):
                    pos.castling[2] = False
                elif from_sq == sq_to_0x88(0, 7):
                    pos.castling[3] = False

        if to_sq == sq_to_0x88(7, 0):
            pos.castling[0] = False
        elif to_sq == sq_to_0x88(0, 0):
            pos.castling[1] = False
        elif to_sq == sq_to_0x88(7, 7):
            pos.castling[2] = False
        elif to_sq == sq_to_0x88(0, 7):
            pos.castling[3] = False

        del pos.board[from_sq]
        pos.board[to_sq] = piece
        pos.white_to_move = not pos.white_to_move
        return pos

    def make_move_san(self, san: str) -> 'Position':
        """Make a move from SAN notation (simplified parser)."""
        # Handle castling
        if san in ('O-O', '0-0'):
            from_sq = sq_to_0x88(4, 0 if self.white_to_move else 7)
            to_sq = sq_to_0x88(6, 0 if self.white_to_move else 7)
            return self.make_move(from_sq, to_sq)
        if san in ('O-O-O', '0-0-0'):
            from_sq = sq_to_0x88(4, 0 if self.white_to_move else 7)
            to_sq = sq_to_0x88(2, 0 if self.white_to_move else 7)
            return self.make_move(from_sq, to_sq)

        # Parse piece type
        san = san.replace('+', '').replace('#', '').replace('x', '')
        promo = None
        if '=' in san:
            san, promo = san.split('=')
            promo = promo[0]

        if san[0] in 'NBRQK':
            piece_type = san[0]
            san = san[1:]
        else:
            piece_type = 'P'

        # Parse destination
        to_file = ord(san[-2]) - ord('a')
        to_rank = int(san[-1]) - 1
        to_sq = sq_to_0x88(to_file, to_rank)

        # Parse disambiguation
        disambig = san[:-2]
        disambig_file = disambig_rank = None
        for c in disambig:
            if c in 'abcdefgh':
                disambig_file = ord(c) - ord('a')
            elif c in '12345678':
                disambig_rank = int(c) - 1

        # Find the piece
        target_piece = piece_type if self.white_to_move else piece_type.lower()
        candidates = []
        for sq88, piece in self.board.items():
            if piece == target_piece:
                file, rank = sq_from_0x88(sq88)
                if disambig_file is not None and file != disambig_file:
                    continue
                if disambig_rank is not None and rank != disambig_rank:
                    continue
                candidates.append(sq88)

        if len(candidates) == 1:
            return self.make_move(candidates[0], to_sq, promo)

        # Try to validate which candidate can reach the square
        for from_sq in candidates:
            try:
                # Simple validation - just try the move
                return self.make_move(from_sq, to_sq, promo)
            except:
                continue

        raise ValueError(f"Cannot parse move: {san}")


# =============================================================================
# Opening Lines Database
# =============================================================================

# Major opening lines up to 15 ply
OPENINGS = [
    # Italian Game / Giuoco Piano
    "e4 e5 Nf3 Nc6 Bc4 Bc5 c3 Nf6 d4 exd4 cxd4 Bb4+ Bd2 Bxd2+ Nbxd2",
    "e4 e5 Nf3 Nc6 Bc4 Bc5 c3 Nf6 d4 exd4 cxd4 Bb6 d5 Ne7 e5 Ng4",
    "e4 e5 Nf3 Nc6 Bc4 Bc5 d3 Nf6 Nc3 d6 Bg5 h6 Bh4 g5 Bg3",

    # Ruy Lopez
    "e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 d6 c3",
    "e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 O-O c3",
    "e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Nxe4 d4 b5 Bb3 d5 dxe5",
    "e4 e5 Nf3 Nc6 Bb5 Nf6 O-O Nxe4 d4 Nd6 Bxc6 dxc6 dxe5 Nf5 Qxd8+",

    # Sicilian Defense
    "e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6 Be3 e5 Nb3 Be6 f3",
    "e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6 Be2 e5 Nb3 Be7 O-O",
    "e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6 Bg5 e6 f4 Be7 Qf3",
    "e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 Nc6 Bg5 e6 Qd2 Be7 O-O-O",
    "e4 c5 Nf3 Nc6 d4 cxd4 Nxd4 Nf6 Nc3 e5 Ndb5 d6 Bg5 a6 Na3",
    "e4 c5 Nf3 e6 d4 cxd4 Nxd4 Nc6 Nc3 Qc7 Be3 a6 Bd3 Nf6 O-O",

    # French Defense
    "e4 e6 d4 d5 Nc3 Nf6 Bg5 Be7 e5 Nfd7 Bxe7 Qxe7 f4 O-O Nf3",
    "e4 e6 d4 d5 Nc3 Bb4 e5 c5 a3 Bxc3+ bxc3 Ne7 Qg4 Qc7 Qxg7",
    "e4 e6 d4 d5 Nc3 dxe4 Nxe4 Nd7 Nf3 Ngf6 Nxf6+ Nxf6 Bd3 c5 dxc5",
    "e4 e6 d4 d5 Nd2 Nf6 e5 Nfd7 Bd3 c5 c3 Nc6 Ne2 cxd4 cxd4",

    # Caro-Kann Defense
    "e4 c6 d4 d5 Nc3 dxe4 Nxe4 Bf5 Ng3 Bg6 h4 h6 Nf3 Nd7 h5",
    "e4 c6 d4 d5 Nc3 dxe4 Nxe4 Nd7 Bc4 Ngf6 Nxf6+ Nxf6 c3 Qc7 Qe2",
    "e4 c6 d4 d5 e5 Bf5 Nf3 e6 Be2 c5 Be3 Qb6 Nc3 Nc6 O-O",

    # Queen's Gambit
    "d4 d5 c4 e6 Nc3 Nf6 Bg5 Be7 e3 O-O Nf3 h6 Bh4 b6 cxd5",
    "d4 d5 c4 e6 Nc3 Nf6 Bg5 Be7 e3 O-O Nf3 Nbd7 Rc1 c6 Bd3",
    "d4 d5 c4 e6 Nc3 Nf6 cxd5 exd5 Bg5 Be7 e3 c6 Bd3 Nbd7 Qc2",
    "d4 d5 c4 c6 Nf3 Nf6 Nc3 dxc4 a4 Bf5 e3 e6 Bxc4 Bb4 O-O",
    "d4 d5 c4 c6 Nf3 Nf6 Nc3 e6 e3 Nbd7 Bd3 dxc4 Bxc4 b5 Bd3",

    # Slav Defense
    "d4 d5 c4 c6 Nf3 Nf6 Nc3 dxc4 a4 Bf5 e3 e6 Bxc4 Bb4 O-O",
    "d4 d5 c4 c6 Nf3 Nf6 e3 Bf5 Nc3 e6 Nh4 Bg6 Nxg6 hxg6 Bd3",

    # Indian Defenses
    "d4 Nf6 c4 e6 Nc3 Bb4 Qc2 O-O a3 Bxc3+ Qxc3 b6 Bg5 Bb7 f3",
    "d4 Nf6 c4 e6 Nc3 Bb4 e3 O-O Bd3 d5 Nf3 c5 O-O dxc4 Bxc4",
    "d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Nf3 O-O Be2 e5 O-O Nc6 d5",
    "d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 f3 O-O Be3 e5 d5 Nh5 Qd2",
    "d4 Nf6 c4 g6 Nc3 d5 cxd5 Nxd5 e4 Nxc3 bxc3 Bg7 Nf3 c5 Be3",

    # English Opening
    "c4 e5 Nc3 Nf6 Nf3 Nc6 g3 Bb4 Bg2 O-O O-O e4 Ng5 Bxc3 bxc3",
    "c4 c5 Nc3 Nc6 g3 g6 Bg2 Bg7 Nf3 e6 O-O Nge7 d3 O-O Bd2",
    "c4 Nf6 Nc3 e6 e4 d5 e5 d4 exf6 dxc3 bxc3 Qxf6 d4 e5 Nf3",

    # London System
    "d4 d5 Bf4 Nf6 e3 c5 c3 Nc6 Nd2 e6 Ngf3 Bd6 Bg3 O-O Bd3",
    "d4 Nf6 Bf4 d5 e3 c5 c3 Nc6 Nd2 e6 Ngf3 Bd6 Bg3 O-O Bd3",

    # Scotch Game
    "e4 e5 Nf3 Nc6 d4 exd4 Nxd4 Bc5 Be3 Qf6 c3 Nge7 Bc4 O-O O-O",
    "e4 e5 Nf3 Nc6 d4 exd4 Nxd4 Nf6 Nxc6 bxc6 e5 Qe7 Qe2 Nd5 c4",

    # Petrov Defense
    "e4 e5 Nf3 Nf6 Nxe5 d6 Nf3 Nxe4 d4 d5 Bd3 Nc6 O-O Be7 c4",
    "e4 e5 Nf3 Nf6 Nxe5 d6 Nf3 Nxe4 Nc3 Nxc3 dxc3 Be7 Be3 O-O Qd2",

    # King's Indian Attack
    "Nf3 d5 g3 Nf6 Bg2 g6 O-O Bg7 d3 O-O Nbd2 c5 e4 Nc6 c3",

    # Catalan
    "d4 Nf6 c4 e6 g3 d5 Bg2 Be7 Nf3 O-O O-O dxc4 Qc2 a6 Qxc4",

    # More Sicilian variations
    "e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 g6 Be3 Bg7 f3 O-O Qd2",
    "e4 c5 Nf3 e6 d4 cxd4 Nxd4 a6 Bd3 Nf6 O-O Qc7 Qe2 d6 c4",

    # More Queen's Gambit
    "d4 d5 c4 e6 Nc3 Nf6 Nf3 Be7 Bf4 O-O e3 c5 dxc5 Bxc5 Qc2",
    "d4 d5 c4 e6 Nc3 c6 e4 dxe4 Nxe4 Bb4+ Bd2 Qxd4 Bxb4 Qxe4+",

    # Pirc/Modern Defense
    "e4 d6 d4 Nf6 Nc3 g6 f4 Bg7 Nf3 O-O Bd3 c5 d5 e6 O-O",
    "e4 g6 d4 Bg7 Nc3 d6 f4 Nf6 Nf3 O-O Bd3 c5 d5 e6 O-O",

    # Dutch Defense
    "d4 f5 g3 Nf6 Bg2 g6 Nf3 Bg7 O-O O-O c4 d6 Nc3 Qe8 d5",

    # Grunfeld Defense
    "d4 Nf6 c4 g6 Nc3 d5 cxd5 Nxd5 e4 Nxc3 bxc3 Bg7 Bc4 c5 Ne2",
    "d4 Nf6 c4 g6 Nc3 d5 Nf3 Bg7 Qb3 dxc4 Qxc4 O-O e4 Bg4 Be3",
]


# =============================================================================
# Book Generation
# =============================================================================

@dataclass
class BookEntry:
    hash_hi: int
    from_sq: int
    to_sq: int


def generate_book() -> List[Tuple[int, BookEntry]]:
    """Generate book entries from opening lines."""
    entries: List[Tuple[int, BookEntry]] = []
    visited: Set[int] = set()

    print(f"Processing {len(OPENINGS)} opening lines...")

    for line_num, line in enumerate(OPENINGS):
        pos = Position()
        moves = line.split()

        for move_num, san in enumerate(moves):
            our_hash = pos.compute_hash()

            try:
                new_pos = pos.make_move_san(san)
            except Exception as e:
                print(f"Warning: Line {line_num+1}, move {move_num+1} '{san}' failed: {e}")
                break

            # Record this position -> move mapping
            if our_hash not in visited:
                visited.add(our_hash)

                # Find the actual move (from_sq, to_sq)
                # By comparing boards before and after
                from_sq = to_sq = None
                for sq in pos.board:
                    if sq not in new_pos.board or new_pos.board.get(sq) != pos.board[sq]:
                        from_sq = sq
                        break

                for sq in new_pos.board:
                    if sq not in pos.board or pos.board.get(sq) != new_pos.board[sq]:
                        # Could be destination or castling rook
                        piece = new_pos.board[sq]
                        if piece.upper() != 'R' or from_sq is None:
                            to_sq = sq
                            break
                        # Check if this is the king's destination
                        from_piece = pos.board.get(from_sq)
                        if from_piece and from_piece.upper() == 'K':
                            to_sq = sq
                            break

                if from_sq is not None and to_sq is not None:
                    entry = BookEntry(
                        hash_hi=(our_hash >> 8) & 0xFF,
                        from_sq=from_sq,
                        to_sq=to_sq
                    )
                    entries.append((our_hash, entry))

            pos = new_pos

    print(f"Generated {len(entries)} unique positions")
    return entries


def write_asm_book(entries: List[Tuple[int, BookEntry]], outfile: str, table_size: int = 256):
    """Write book as assembly file."""
    hash_table = [0xFFFF] * table_size
    entry_data: List[BookEntry] = []
    chains: List[int] = []

    buckets: Dict[int, List[Tuple[int, BookEntry]]] = defaultdict(list)
    for our_hash, entry in entries:
        bucket = our_hash % table_size
        buckets[bucket].append((our_hash, entry))

    entry_idx = 0
    for bucket in range(table_size):
        if bucket not in buckets or not buckets[bucket]:
            continue
        hash_table[bucket] = entry_idx
        bucket_entries = buckets[bucket]
        for i, (our_hash, entry) in enumerate(bucket_entries):
            entry_data.append(entry)
            chains.append(entry_idx + 1 if i < len(bucket_entries) - 1 else 0xFF)
            entry_idx += 1

    with open(outfile, 'w') as f:
        f.write(f"""// Auto-generated Opening Book Data
// Generated by tools/create_book_from_openings.py
// {len(entry_data)} positions from {len(OPENINGS)} opening lines
// DO NOT EDIT - regenerate from source

#importonce

*=* "Generated Opening Book"

// Book format constants (must match opening_moves.asm)
.const GEN_BOOK_MAGIC = $B00C
.const GEN_BOOK_VERSION = $01
.const GEN_BOOK_CHAIN_END = $FF

//
// Generated Opening Book Data
//
GeneratedBook:
  // Header (8 bytes)
  .word GEN_BOOK_MAGIC    // Magic number
  .byte GEN_BOOK_VERSION  // Version
  .word {len(entry_data)}             // Entry count ({len(entry_data)} positions)
  .word {table_size}                 // Table size ({table_size} slots)
  .byte $00               // Flags (reserved)

// Hash table ({table_size} slots * 2 bytes = {table_size * 2} bytes)
GeneratedBookHashTable:
""")

        for i, slot in enumerate(hash_table):
            if slot == 0xFFFF:
                f.write(f"  .word $FFFF\n")
            else:
                f.write(f"  .word {slot}\n")

        f.write(f"""
// Entries ({len(entry_data)} entries * 4 bytes = {len(entry_data) * 4} bytes)
// Format: HashHi, From (0x88), To (0x88), Next
GeneratedBookEntries:
""")

        for i, entry in enumerate(entry_data):
            chain = chains[i]
            chain_str = "GEN_BOOK_CHAIN_END" if chain == 0xFF else f"{chain}"
            f.write(f"  .byte ${entry.hash_hi:02x}, ${entry.from_sq:02x}, ${entry.to_sq:02x}, {chain_str}\n")

        f.write("""
GeneratedBookEnd:
""")

    total_bytes = 8 + table_size * 2 + len(entry_data) * 4
    print(f"Wrote {outfile}")
    print(f"  Hash table: {table_size} slots ({table_size * 2} bytes)")
    print(f"  Entries: {len(entry_data)} ({len(entry_data) * 4} bytes)")
    print(f"  Total: {total_bytes} bytes ({total_bytes / 1024:.1f} KB)")


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('output', nargs='?', default='book_data.asm')
    parser.add_argument('--table-size', type=int, default=256)
    args = parser.parse_args()

    entries = generate_book()
    write_asm_book(entries, args.output, args.table_size)


if __name__ == '__main__':
    main()
