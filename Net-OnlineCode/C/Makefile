
OBJECTS = online-code.o rng_sha1.o graph.o decoder.o encoder.o \
          floyd.o bones.o
PROGS   = probdist mindecoder compat codec

CARGS = -O2 -DSET_METHOD=SET_UNORDERED_LIST -DNDEBUG
CLIBS = -L.

# Uncomment for gconv (line-by-line) profiling
# PROF = -fprofile-arcs -ftest-coverage
# Uncomment for gprof (call graph only) profiling
# PROF = -pg
PROF = -pg

# External libraries
# '-lm' for maths (ceil, floor, log, etc.)
# '-lssl -lcrypto' as reported by pkg-config --libs openssl (SHA stuff)
OTHERLIBS = -lm -lssl -lcrypto

.c.o:
	$(CC) $(CARGS) $(CINCS) -c -g  $(PROF) $<

all: libs $(PROGS)

libs : libonline-code.a

clean :
	-rm $(PROGS) 2>/dev/null
	-rm *.o *.a platform.h 2>/dev/null
	-rm *.gcov *.gcno *.gcda gmon.out 2>/dev/null

libonline-code.a : $(OBJECTS)
	$(AR) cr $@ $(OBJECTS)
	ranlib $@


online-code.o : online-code.c
rng_sha1.o    : rng_sha1.c
graph.o       : graph.c
encoder.o     : encoder.c
decoder.o     : decoder.c

# Rebuild if included header files change
floyd.o       : structs.h rng_sha1.h
encoder.o     : structs.h encoder.h online-code.h rng_sha1.h
decoder.o     : structs.h decoder.h online-code.h graph.h rng_sha1.h
graph.o       : structs.h graph.h online-code.h structs.h
rng_sha1.o    : structs.h rng_sha1.h
online-code.o : structs.h online-code.h rng_sha1.h floyd.h


codec: codec.o libonline-code.a
	$(CC) -o codec $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

compat: compat.o libonline-code.a rng_sha1.h
	$(CC) -o compat $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

probdist: probdist.o libonline-code.a online-code.h
	$(CC) -o probdist $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

mindecoder: mindecoder.o libonline-code.a online-code.h
	$(CC) -o mindecoder $(PROF) $(CLIBS) $< -lonline-code $(OTHERLIBS)

