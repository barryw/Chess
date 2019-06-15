clean:
	rm -rf bin
	rm -f *.d64

build: clean
	docker run -v ${PWD}:/workspace barrywalker71/kickassembler:latest /workspace/main.asm
