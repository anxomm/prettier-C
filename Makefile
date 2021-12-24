SOURCE = prettier
TEST = tests/test5.c

all: compile

compile:
	flex $(SOURCE).l
	bison -o $(SOURCE).tab.c $(SOURCE).y -yd
	gcc -o $(SOURCE) lex.yy.c $(SOURCE).tab.c -lfl -ly

lexer:
	flex $(SOURCE).l
	gcc -o $(SOURCE) lex.yy.c -lfl

run:
	./$(SOURCE) < $(TEST)

run2:
	./$(SOURCE) $(TEST)

clean:
	rm $(SOURCE) lex.yy.c $(SOURCE).tab.c $(SOURCE).tab.h _output.c

