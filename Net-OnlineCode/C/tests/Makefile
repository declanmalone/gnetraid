# Makefile for extended test programs

CLIBS = -L..
CINCS = -I..

# Uncomment for gconv (line-by-line) profiling
PROF = -fprofile-arcs -ftest-coverage
# Uncomment for gprof (call graph only) profiling
# PROF = -pg
#PROF =

# External libraries
# '-lm' for maths (ceil, floor, log, etc.)
# '-lssl -lcrypto' as reported by pkg-config --libs openssl (SHA stuff)
OTHERLIBS = -lm -lssl -lcrypto

all: probdist mindecoder compat codec

clean :
	-rm *.o 2>/dev/null

# Rebuild lib in parent dir if needed:
PARENT_DEPENDS =  ../decoder.h ../encoder.h ../heap.h ../rng_sha1.h \
  ../diskio.h ../graph.h ../online-code.h ../structs.h \
 ../decoder.c ../encoder.c ../heap.c ../rng_sha1.c \
  ../diskio.c ../graph.c ../online-code.c ../structs.c
../libonline-code.a: $(PARENT_DEPENDS)
	cd .. && make libs && cd -

.c.o:
	$(CC) $(CINCS) -c -g  $(PROF) $<

codec: codec.o ../libonline-code.a
	$(CC) -o codec $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

compat: compat.o ../libonline-code.a ../rng_sha1.h
	$(CC) -o compat $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

probdist: probdist.o ../libonline-code.a ../online-code.h
	$(CC) -o probdist $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

mindecoder: mindecoder.o ../libonline-code.a ../online-code.h
	$(CC) -o mindecoder $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

# Header file dependencies 
codec.o: ../encoder.h ../decoder.h ../online-code.h ../rng_sha1.h
compat.o:  ../online-code.h ../rng_sha1.h
probdist.o: ../online-code.h ../rng_sha1.h
mindecoder.o : ../decoder.h ../online-code.h ../rng_sha1.h
