.PHONY: clean test archive

test:    test.iOS    test.OSX
archive: archive.iOS archive.OSX
clean:   clean.iOS   clean.OSX

%.iOS:
	make -f Makefile.iOS $*

%.OSX:
	make -f Makefile.OSX $*

