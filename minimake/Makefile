CC=gcc
CFLAGS= -std=c99 -pedantic -Werror -Wall -Wextra -Wvla
SRCS=src/argument/argument.c src/list_variable/list_variable.c src/exec_target/exec_target.c src/minimake/minimake.c src/extension_var/extension_var.c src/parser/parser.c src/is_up_to_date/is_up_to_date.c src/string/string.c src/list_target/list_target.c src/main.c

OBJS=$(SRCS:.c=.o)

minimake: ${OBJS}
	${CC} -o $@ ${OBJS}

check:
	echo test

clean:
	${RM} minimake ${OBJS}
