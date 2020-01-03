main.o: src/main.s
	rgbasm -i src/ -o $@ $^

main.gb: main.o
	rgblink -o $@ $^ && rgbfix -v -p 0 $@
