

program_source		= find-objects.cc


libraries		= -lm


CXXFLAGS=-O3 -ffloat-store -foptimize-sibling-calls -fno-branch-count-reg


include $(srcroot)/build-tools/makefiles/programs-cc.mk


# arch-tag: Tom Clegg Fri Mar 16 20:33:29 PDT 2007 (find-objects/Makefile.x)
