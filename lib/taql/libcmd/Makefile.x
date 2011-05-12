

thelib=libcmd.a

source_to_make_objects = \
   $(patsubst $(srcpath)/%, %, $(wildcard $(srcpath)/*.c))


include $(srcroot)/build-tools/makefiles/library.mk

# arch-tag: Thomas Lord Sat Aug 19 14:59:11 2006 (libcmd/Makefile.x)

