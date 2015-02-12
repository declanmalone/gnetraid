# Makefile for extended test programs

CLIBS = -L..
CINCS = -I..

OTHERLIBS = -lm -lssl

all: probdist mindecoder

.c.o:
	$(CC) $(CINCS) -c -g $<

probdist: probdist.o ../libonline-code.a ../online-code.h
	$(CC) -o probdist $(CLIBS) $< -lonline-code $(OTHERLIBS)

mindecoder: mindecoder.o ../libonline-code.a ../online-code.h
	$(CC) -o mindecoder $(CLIBS) $< -lonline-code $(OTHERLIBS)
