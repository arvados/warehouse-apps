

program_source		= register-raw-translate.c


libraries		= -lm

CLFAGS=-O3 -foptimize-sibling-calls -fno-branch-count-reg

include $(srcroot)/build-tools/makefiles/programs.mk


# arch-tag: Tom Clegg Fri Mar 16 20:33:45 PDT 2007 (register-raw-translate/Makefile.x)
