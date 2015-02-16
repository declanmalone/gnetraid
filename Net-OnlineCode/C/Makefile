
OBJECTS = online-code.o rng_sha1.o graph.o decoder.o encoder.o

# Uncomment for gconv (line-by-line) profiling
# PROF = -fprofile-arcs -ftest-coverage
# Uncomment for gprof (call graph only) profiling
# PROF = -pg
PROF =

libs : libonline-code.a

clean :
	-rm *.o *.a platform.h 2>/dev/null

libonline-code.a : $(OBJECTS)
	$(AR) cr $@ $(OBJECTS)
	ranlib $@

.c.o:
	${CC} -c -g $(PROF) $< 

online-code.o : online-code.c
rng_sha1.o : rng_sha1.c
graph.o : graph.c
encoder.o : encoder.c
decoder.o : decoder.c

# Rebuild if included header files change
encoder.o : encoder.h online-code.h rng_sha1.h
decoder.o : decoder.h online-code.h graph.h rng_sha1.h
graph.o : graph.h online-code.h
online-code.o : online-code.h rng_sha1.h
rng_sha1.o : rng_sha1.h

