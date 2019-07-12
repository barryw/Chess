clean:
	rm -rf bin
	rm -f *.d64

build: clean
	docker run -v ${PWD}:/workspace barrywalker71/kickassembler:latest /workspace/main.asm

run: build
	/Applications/VICE/x64sc.app/Contents/MacOS/x64sc -autostart `pwd`/main.prg
