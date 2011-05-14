all:

test:

installl:

clean:

srcpath := $(srcroot)/$(relpath)
VPATH := $(srcpath)
MKX := $(srcroot)/mkx

include $(srcroot)/Params.mk

ifdef CFLAGS
USER_CFLAGS	:=	$(CFLAGS)
else
USER_CFLAGS	:=	-g
endif

override CFLAGS	:=	-I$(objroot) \
			-I$(srcroot) \
			-DCFG_PREFIX='"$(prefix)"' \
			$(USER_CFLAGS) \
			$(EXTRA_CFLAGS)

%.d: %.c
	$(CC) -MM $(CFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

%.d: %.cc
	$(CXX) -MM $(CXXFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

clean: clean_dot_d

clean_dot_d:
	rm -f *.d





# arch-tag: Thomas Lord Sat Aug 19 13:54:32 2006 (makefiles/rules.mk)
