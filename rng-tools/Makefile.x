

program_source		=	rng-gen.c \
				rng-partition.c

libraries		= ../librng/librng.a ../libcmd/libcmd.a


include $(srcroot)/build-tools/makefiles/programs.mk

# arch-tag: Thomas Lord Sat Aug 19 15:07:23 2006 (rng-tools/Makefile.x)

