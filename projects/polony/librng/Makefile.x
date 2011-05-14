

thelib=librng.a

source_to_make_objects = \
   $(patsubst $(srcpath)/%, %, $(wildcard $(srcpath)/*.c))

include $(srcroot)/build-tools/makefiles/library.mk

install: install_data_file

install_data_file:
	mkdir -p $(prefix)/lib/librng
	rm -f $(prefix)/lib/librng/160megs
	cp $(srcpath)/160megs  $(prefix)/lib/librng


# arch-tag: Thomas Lord Sat Aug 19 13:52:43 2006 (librndutils/Makefile.x)

