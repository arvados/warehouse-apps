
include $(srcroot)/build-tools/makefiles/rules.mk

include $(program_source:.cc=.d)

objects_from_source = $(addsuffix .o, $(basename $(program_source)))

programs = $(basename $(program_source))

all: $(programs)

$(programs): $(libraries)

%: %.o
	$(CXX) $(CXXFLAGS) -o $@ $< $(libraries) -lstdc++


install: install_programs

install_programs: $(programs)
	mkdir -p $(prefix)/bin
	for f in $(programs) ; do rm -f $(prefix)/bin/$$f ; done
	cp $(programs) $(prefix)/bin

clean: clean_objects clean_programs

clean_objects:
	rm -f $(objects_from_source)

clean_programs:
	rm -f $(programs)


# arch-tag: Tom Clegg Wed Mar 21 10:21:59 PDT 2007 (makefiles/programs-cc.mk)

