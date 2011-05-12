
include $(srcroot)/build-tools/makefiles/rules.mk

all: all_subdirs

all_subdirs:
	for dir in $(subdirs_to_build) ; do \
	  test -e $$dir || mkdir $$dir ; \
	  ( cd $$dir && $(MKX) all) || exit 1 ; \
	done

test: test_subdirs

test_subdirs:
	for dir in $(subdirs_to_build) ; do \
	  test -e $$dir || mkdir $$dir ; \
	  ( cd $$dir && $(MKX) test) || exit 1 ; \
	done

install: install_subdirs

install_subdirs:
	for dir in $(subdirs_to_build) ; do \
	  test -e $$dir || mkdir $$dir ; \
	  ( cd $$dir && $(MKX) install) || exit 1 ; \
	done

clean: clean_subdirs

clean_subdirs:
	for dir in $(subdirs_to_build) ; do \
	  test -e $$dir || mkdir $$dir ; \
	  ( cd $$dir && $(MKX) clean) || exit 1 ; \
	done


# arch-tag: Thomas Lord Sat Aug 19 13:54:40 2006 (makefiles/subdirs.mk)
