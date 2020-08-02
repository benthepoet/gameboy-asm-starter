main.o: src/main.s
	rgbasm -i src/ -o bin/$@ $^

main.gb: main.o
	rgblink -n bin/$@.sym -o bin/$@ bin/$^ && rgbfix -v -p 0 bin/$@
