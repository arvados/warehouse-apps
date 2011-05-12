
include $(srcroot)/build-tools/makefiles/subdirs.mk

subdirs_to_build =	libcmd \
                        libtaql \
                        tread \
                        tprint \
                        gprint \
                        gread \
                        all-mers \
			all-mers-gap \
                        hash-mers \
                        pick-mers \
                        snp-mers \
                        complement-mers \
                        billy-candidates \
                        index-mers \
                        place-mers \
                        mer-nfa \
			place-report \
			billy-grep \
			cons-stats \
			find-objects \
			register-raw-translate \
			levels


# arch-tag: Thomas Lord Sat Aug 19 12:45:44 2006 (polony-tools/Makefile.x)
