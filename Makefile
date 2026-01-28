clean:
	rm -rf bin
	rm -f *.d64

# Generate opening book from Polyglot GM2600 (4200 positions, 18KB)
book:
	python3 tools/generate_book.py tools/books/gm2600.bin book_data.asm \
		--max-ply 15 --max-positions 4200 --table-size 1024

build: clean
	docker run -v ${PWD}:/workspace barrywalker71/kickassembler:latest /workspace/main.asm

# Full rebuild including book regeneration
rebuild: book build

run: build
	/Applications/vice-arm64-gtk3-3.6.1/bin/x64sc -autostart `pwd`/main.prg
