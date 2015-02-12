# Makefile for extended test programs

CLIBS = -L..
CINCS = -I..

# Uncomment to enable line-by-line (gcov) and gprof profiling
#PROF = -fprofile-arcs -ftest-coverage -pg
PROF = 

OTHERLIBS = -lm -lssl -lcrypto

all: probdist mindecoder compat

clean :
	-rm *.o *.a 2>/dev/null

.c.o:
	$(CC) $(CINCS) -c -g  $(PROF) $<


compat: compat.o ../libonline-code.a ../rng_sha1.h
	$(CC) -o compat $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

probdist: probdist.o ../libonline-code.a ../online-code.h
	$(CC) -o probdist $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

mindecoder: mindecoder.o ../libonline-code.a ../online-code.h
	$(CC) -o mindecoder $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)
