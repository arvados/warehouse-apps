

thelib=libtaql.a

source_to_make_objects = \
   $(patsubst $(srcpath)/%, %, $(wildcard $(srcpath)/*.c))


include $(srcroot)/build-tools/makefiles/library.mk

# arch-tag: Thomas Lord Mon Oct 30 14:18:34 2006 (libtaql/Makefile.in)

