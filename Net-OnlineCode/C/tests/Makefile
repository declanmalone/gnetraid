# Makefile for extended test programs

CLIBS = -L..
CINCS = -I..

OTHERLIBS = -lm -lssl -lcrypto

all: probdist mindecoder compat

clean :
	-rm *.o *.a 2>/dev/null

.c.o:
	$(CC) $(CINCS) -c -pg $<



compat: compat.o ../libonline-code.a ../rng_sha1.h
	$(CC) -o compat -pg $(CLIBS) $< -lonline-code $(OTHERLIBS)

probdist: probdist.o ../libonline-code.a ../online-code.h
	$(CC) -o probdist -pg $(CLIBS) $< -lonline-code $(OTHERLIBS)

mindecoder: mindecoder.o ../libonline-code.a ../online-code.h
	$(CC) -o mindecoder -pg $(CLIBS) $< -lonline-code $(OTHERLIBS)
