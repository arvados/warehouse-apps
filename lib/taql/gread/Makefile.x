

program_source		= gread.c


libraries		= ../libtaql/libtaql.a -lm


include $(srcroot)/build-tools/makefiles/programs.mk

lexer.c: lexer.lex gread.h
	flex -olexer.c $(srcpath)/lexer.lex

gread.c gread.h: gread.y
	bison -d -ogread.c $(srcpath)/gread.y


lexer.o: lexer.c


gread: lexer.o gread.o
	gcc -o gread -g lexer.o gread.o $(libraries)


# arch-tag: Thomas Lord Wed Jan 24 10:54:37 2007 (gread/Makefile.x)


