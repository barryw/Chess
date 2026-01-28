#!/usr/bin/env python3
"""
Opening Book Generator for C64 Chess

Generates a C64-format opening book from Polyglot format books.

The key insight: Polyglot uses standard Zobrist keys, but we use a custom LFSR.
We traverse positions from the start, look up moves in Polyglot, and compute
our own Zobrist hashes for each position.
"""

import argparse
import struct
import sys
from collections import defaultdict
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple, Set

import chess
import chess.polyglot


# =============================================================================
# C64 Zobrist PRNG (matches ai/zobrist.asm exactly)
# =============================================================================

class C64ZobristPRNG:
    """16-bit Galois LFSR matching the 6502 implementation with improved mixing."""

    def __init__(self):
        self.state = 0xA7CE  # Seed matches ZobristSeed

    def next_byte(self) -> int:
        # Run 8 LFSR cycles per output byte for better randomness
        for _ in range(8):
            lsb = self.state & 1
            self.state >>= 1
            if lsb:
                self.state ^= 0xB400
        # Return low byte XOR high byte for better distribution
        return ((self.state & 0xFF) ^ ((self.state >> 8) & 0xFF)) & 0xFF


# =============================================================================
# Zobrist Table Generation
# =============================================================================

class ZobristTables:
    def __init__(self):
        prng = C64ZobristPRNG()

        # Piece-square table: 12 pieces x 64 squares x 2 bytes
        self.pieces = []
        for _ in range(12):
            piece_hashes = []
            for _ in range(64):
                lo = prng.next_byte()
                hi = prng.next_byte()
                piece_hashes.append(lo | (hi << 8))
            self.pieces.append(piece_hashes)

        # Side to move: 2 bytes
        self.side = prng.next_byte() | (prng.next_byte() << 8)

        # Castling rights: 4 flags x 2 bytes
        self.castling = []
        for _ in range(4):
            self.castling.append(prng.next_byte() | (prng.next_byte() << 8))

        # En passant files: 8 files x 2 bytes
        self.en_passant = []
        for _ in range(8):
            self.en_passant.append(prng.next_byte() | (prng.next_byte() << 8))


# =============================================================================
# Hash Computation
# =============================================================================

# Piece to Zobrist index mapping
# White: P=0, N=1, B=2, R=3, Q=4, K=5
# Black: p=6, n=7, b=8, r=9, q=10, k=11
PIECE_INDEX = {
    (chess.PAWN, chess.WHITE): 0,
    (chess.KNIGHT, chess.WHITE): 1,
    (chess.BISHOP, chess.WHITE): 2,
    (chess.ROOK, chess.WHITE): 3,
    (chess.QUEEN, chess.WHITE): 4,
    (chess.KING, chess.WHITE): 5,
    (chess.PAWN, chess.BLACK): 6,
    (chess.KNIGHT, chess.BLACK): 7,
    (chess.BISHOP, chess.BLACK): 8,
    (chess.ROOK, chess.BLACK): 9,
    (chess.QUEEN, chess.BLACK): 10,
    (chess.KING, chess.BLACK): 11,
}


def compute_c64_hash(board: chess.Board, tables: ZobristTables) -> int:
    """Compute C64 Zobrist hash for a python-chess board."""
    h = 0

    # Pieces on board
    for square in chess.SQUARES:
        piece = board.piece_at(square)
        if piece is not None:
            piece_idx = PIECE_INDEX[(piece.piece_type, piece.color)]
            # Convert python-chess square to our 0-63 indexing
            # python-chess: a1=0, h1=7, a8=56, h8=63
            # Our indexing: same row order but we use (7-rank)*8+file
            file = chess.square_file(square)
            rank = chess.square_rank(square)
            sq64 = (7 - rank) * 8 + file
            h ^= tables.pieces[piece_idx][sq64]

    # Side to move (XOR if white to move)
    if board.turn == chess.WHITE:
        h ^= tables.side

    # Castling rights
    if board.has_kingside_castling_rights(chess.WHITE):
        h ^= tables.castling[0]
    if board.has_queenside_castling_rights(chess.WHITE):
        h ^= tables.castling[1]
    if board.has_kingside_castling_rights(chess.BLACK):
        h ^= tables.castling[2]
    if board.has_queenside_castling_rights(chess.BLACK):
        h ^= tables.castling[3]

    # En passant
    if board.ep_square is not None:
        ep_file = chess.square_file(board.ep_square)
        h ^= tables.en_passant[ep_file]

    return h & 0xFFFF


def square_to_0x88(square: int) -> int:
    """Convert python-chess square to 0x88 format."""
    file = chess.square_file(square)
    rank = chess.square_rank(square)
    return (7 - rank) * 16 + file


# =============================================================================
# Polyglot Book Reader
# =============================================================================

def decode_polyglot_move(move_bits: int, board: chess.Board) -> chess.Move:
    """Decode Polyglot move encoding to python-chess Move."""
    to_file = move_bits & 7
    to_rank = (move_bits >> 3) & 7
    from_file = (move_bits >> 6) & 7
    from_rank = (move_bits >> 9) & 7
    promo_code = (move_bits >> 12) & 7

    from_sq = chess.square(from_file, from_rank)
    to_sq = chess.square(to_file, to_rank)

    promo = None
    if promo_code == 1:
        promo = chess.KNIGHT
    elif promo_code == 2:
        promo = chess.BISHOP
    elif promo_code == 3:
        promo = chess.ROOK
    elif promo_code == 4:
        promo = chess.QUEEN

    return chess.Move(from_sq, to_sq, promotion=promo)


def read_polyglot_book(filename: str) -> Dict[int, List[Tuple[int, int]]]:
    """Read Polyglot book. Returns {key: [(move_bits, weight), ...]}"""
    entries = defaultdict(list)
    with open(filename, 'rb') as f:
        while True:
            data = f.read(16)
            if len(data) < 16:
                break
            key, move, weight, learn = struct.unpack('>QHHi', data)
            entries[key].append((move, weight))
    return entries


# =============================================================================
# Book Generation
# =============================================================================

@dataclass
class BookEntry:
    hash_hi: int      # Upper 8 bits of C64 hash
    from_sq: int      # 0x88 from square
    to_sq: int        # 0x88 to square


# Maximum number of alternative moves to store per position
MAX_MOVES_PER_POSITION = 3


def build_book(
    poly_book: Dict[int, List[Tuple[int, int]]],
    tables: ZobristTables,
    max_ply: int,
    max_positions: int
) -> List[Tuple[int, BookEntry]]:
    """Build C64 book by BFS traversal from starting position.

    Now stores up to MAX_MOVES_PER_POSITION moves per position for variety.
    """

    entries: List[Tuple[int, BookEntry]] = []
    # Track (hash, from, to) tuples to allow multiple moves per position
    visited_moves: Set[Tuple[int, int, int]] = set()
    # Track how many moves we've stored per position hash
    moves_per_hash: Dict[int, int] = defaultdict(int)

    # BFS queue: (board, ply)
    queue: List[Tuple[chess.Board, int]] = [(chess.Board(), 0)]
    positions_added = 0

    print(f"  Starting BFS traversal (up to {MAX_MOVES_PER_POSITION} moves per position)...")

    while queue and positions_added < max_positions:
        board, ply = queue.pop(0)

        if ply >= max_ply:
            continue

        # Look up position in Polyglot book
        poly_key = chess.polyglot.zobrist_hash(board)
        if poly_key not in poly_book:
            continue

        # Get moves sorted by weight (best moves first)
        moves = sorted(poly_book[poly_key], key=lambda x: x[1], reverse=True)

        # Compute C64 hash for this position
        c64_hash = compute_c64_hash(board, tables)

        # Process moves in book for this position (up to MAX_MOVES_PER_POSITION)
        for move_bits, weight in moves:
            try:
                move = decode_polyglot_move(move_bits, board)
                if move not in board.legal_moves:
                    continue
            except:
                continue

            # Create entry with 0x88 coordinates
            from_sq = square_to_0x88(move.from_square)
            to_sq = square_to_0x88(move.to_square)

            # Check if we've already stored this exact move
            move_key = (c64_hash, from_sq, to_sq)
            if move_key in visited_moves:
                # Still explore the move even if already stored
                new_board = board.copy()
                new_board.push(move)
                queue.append((new_board, ply + 1))
                continue

            # Check if we have room for more moves at this position
            if moves_per_hash[c64_hash] >= MAX_MOVES_PER_POSITION:
                # Still explore the move even if we can't store it
                new_board = board.copy()
                new_board.push(move)
                queue.append((new_board, ply + 1))
                continue

            # Store this move
            visited_moves.add(move_key)
            moves_per_hash[c64_hash] += 1

            entry = BookEntry(
                hash_hi=(c64_hash >> 8) & 0xFF,
                from_sq=from_sq,
                to_sq=to_sq
            )
            entries.append((c64_hash, entry))
            positions_added += 1

            if positions_added % 500 == 0:
                print(f"  Added {positions_added} entries...")

            if positions_added >= max_positions:
                break

            # Make the move and explore further
            new_board = board.copy()
            new_board.push(move)
            queue.append((new_board, ply + 1))

        if positions_added >= max_positions:
            break

    unique_positions = len(moves_per_hash)
    multi_move_positions = sum(1 for count in moves_per_hash.values() if count > 1)
    print(f"  BFS complete: {positions_added} entries for {unique_positions} positions")
    print(f"  Positions with multiple moves: {multi_move_positions}")
    return entries


def write_asm_book(entries: List[Tuple[int, BookEntry]], outfile: str, table_size: int):
    """Write book as assembly file."""
    # Build hash table with chaining
    hash_table = [0xFFFF] * table_size
    entry_data: List[BookEntry] = []
    chains: List[int] = []

    # Group by bucket
    buckets: Dict[int, List[Tuple[int, BookEntry]]] = defaultdict(list)
    for c64_hash, entry in entries:
        bucket = c64_hash % table_size
        buckets[bucket].append((c64_hash, entry))

    # Build entry list with chaining
    entry_idx = 0
    for bucket in range(table_size):
        if bucket not in buckets or not buckets[bucket]:
            continue

        hash_table[bucket] = entry_idx

        for i, (c64_hash, entry) in enumerate(buckets[bucket]):
            entry_data.append(entry)
            if i < len(buckets[bucket]) - 1:
                chains.append(entry_idx + 1)
            else:
                chains.append(0xFF)
            entry_idx += 1

    # Write assembly
    with open(outfile, 'w') as f:
        f.write(f"""// Auto-generated Opening Book Data
// Source: Polyglot GM2600 opening book
// Generated by tools/generate_book.py
// Positions: {len(entry_data)} | Table: {table_size} slots
// DO NOT EDIT - regenerate from source

#importonce

// Place book after code ($5B00) extending into banked BASIC area if needed
// $5B00-$9FFF = ~18KB, $A000-$BFFF = 8KB = 26KB total available
*=$5B00 "Generated Opening Book"

.const GEN_BOOK_MAGIC = $B00C
.const GEN_BOOK_VERSION = $01
.const GEN_BOOK_CHAIN_END = $FF

GeneratedBook:
  .word GEN_BOOK_MAGIC
  .byte GEN_BOOK_VERSION
  .word {len(entry_data)}
  .word {table_size}
  .byte $00

// Hash table ({table_size} * 2 = {table_size * 2} bytes)
GeneratedBookHashTable:
""")

        for slot in hash_table:
            f.write(f"  .word ${slot:04x}\n")

        f.write(f"""
// Entries ({len(entry_data)} * 4 = {len(entry_data) * 4} bytes)
GeneratedBookEntries:
""")

        for i, entry in enumerate(entry_data):
            chain = "GEN_BOOK_CHAIN_END" if chains[i] == 0xFF else f"{chains[i]}"
            f.write(f"  .byte ${entry.hash_hi:02x}, ${entry.from_sq:02x}, ${entry.to_sq:02x}, {chain}\n")

        f.write("\nGeneratedBookEnd:\n")

    total = 8 + table_size * 2 + len(entry_data) * 4
    print(f"Output: {outfile}")
    print(f"  Entries: {len(entry_data)}")
    print(f"  Hash table: {table_size} slots ({table_size * 2} bytes)")
    print(f"  Entry data: {len(entry_data) * 4} bytes")
    print(f"  Total: {total} bytes ({total / 1024:.1f} KB)")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input', help='Polyglot book (.bin)')
    parser.add_argument('output', help='Output assembly (.asm)')
    parser.add_argument('--max-ply', type=int, default=15)
    parser.add_argument('--max-positions', type=int, default=8000)
    parser.add_argument('--table-size', type=int, default=512)
    args = parser.parse_args()

    print(f"Reading: {args.input}")
    poly_book = read_polyglot_book(args.input)
    print(f"  {len(poly_book)} unique positions, {sum(len(v) for v in poly_book.values())} total entries")

    print(f"Generating C64 book (max_ply={args.max_ply}, max_positions={args.max_positions})...")
    tables = ZobristTables()
    entries = build_book(poly_book, tables, args.max_ply, args.max_positions)

    print(f"Writing: {args.output}")
    write_asm_book(entries, args.output, args.table_size)


if __name__ == '__main__':
    main()
