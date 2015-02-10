# Makefile for extended test programs

CLIBS = -L..
CINCS = -I..

OTHERLIBS = -lm -lssl

.c.o:
	$(CC) $(CINCS) -c $<

probdist: probdist.o ../libonline-code.a
	$(CC) -o probdist $(CLIBS) $< -lonline-code $(OTHERLIBS)


