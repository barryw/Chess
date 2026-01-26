clean:
	rm -rf bin
	rm -f *.d64

build: clean
	docker run -v ${PWD}:/workspace barrywalker71/kickassembler:latest /workspace/main.asm

run: build
	/Applications/vice-arm64-gtk3-3.6.1/bin/x64sc -autostart `pwd`/main.prg
