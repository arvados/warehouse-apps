

program_source		= tread.c


libraries		= ../libtaql/libtaql.a -lm


include $(srcroot)/build-tools/makefiles/programs.mk

lexer.c: lexer.lex tread.h
	flex -olexer.c $(srcpath)/lexer.lex

tread.c tread.h: tread.y
	bison -d -otread.c $(srcpath)/tread.y


lexer.o: lexer.c


tread: lexer.o tread.o
	gcc -o tread -g lexer.o tread.o $(libraries)


# arch-tag: Thomas Lord Mon Oct 30 14:35:16 2006 (taql/Makefile.in)


