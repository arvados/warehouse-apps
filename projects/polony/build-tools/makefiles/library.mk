
include $(srcroot)/build-tools/makefiles/rules.mk

include $(source_to_make_objects:.c=.d)


objects_from_source = $(addsuffix .o, $(basename $(source_to_make_objects)))

all: $(thelib)

$(thelib): $(objects_from_source)
	rm -f $(thelib)
	ar -rc $(thelib) $(objects_from_source)

install: install_headers install_library

install_headers: $(headers_to_install)
ifneq ($(headers_to_install),'')
	for i in $(headers_to_install) ; do \
	  place="`dirname \"$(prefix)/include/$(relpath)/$$i\"`" ; \
	  test -e "$$place" || mkdir -p "$$place" ; \
	  rm -f "$$place/$$i" ; \
	  cp "$(srcpath)/$$i" "$$place" ; \
	done
endif

install_library: $(thelib)
ifneq ($(thelib),'')
	place="`dirname \"$(prefix)/lib/$(relpath)/$$i\"`" ; \
	test -e "$$place" || mkdir -p "$$place" ; \
	rm -f "$$place/$$i" ; \
	cp "$(thelib)" "$$place" ;
endif

clean: clean_objects

clean: clean_lib

clean_objects:
	rm -f $(objects_from_source)

clean_lib:
	rm -f $(thelib)


# arch-tag: Thomas Lord Sat Aug 19 12:47:13 2006 (makefiles/library.mk)

