# Makefile for extended test programs

CLIBS = -L..
CINCS = -I..

OTHERLIBS = -lm -lssl -lcrypto

all: probdist mindecoder compat

clean :
	-rm *.o *.a 2>/dev/null

.c.o:
	$(CC) $(CINCS) -c -g $<



compat: compat.o ../libonline-code.a ../rng_sha1.h
	$(CC) -o compat $(CLIBS) $< -lonline-code $(OTHERLIBS)

probdist: probdist.o ../libonline-code.a ../online-code.h
	$(CC) -o probdist $(CLIBS) $< -lonline-code $(OTHERLIBS)

mindecoder: mindecoder.o ../libonline-code.a ../online-code.h
	$(CC) -o mindecoder $(CLIBS) $< -lonline-code $(OTHERLIBS)
