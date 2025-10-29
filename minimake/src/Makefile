OBJ=main.o foo.o
toto: ${OBJ}
	gcc -o $@ $^
%.o: %.c
	gcc -o $(@) -c ${ <}
