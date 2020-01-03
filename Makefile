main.o: src/main.s
	rgbasm -i src/ -o bin/$@ $^

main.gb: main.o
	rgblink -o bin/$@ bin/$^ && rgbfix -v -p 0 bin/$@
