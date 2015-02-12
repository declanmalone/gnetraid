
OBJECTS = online-code.o rng_sha1.o graph.o decoder.o

libs : libonline-code.a

libonline-code.a : $(OBJECTS)
	$(AR) cr $@ $(OBJECTS)
	ranlib $@

.c.o:
	${CC} -c -g $< 

online-code.o : online-code.c
rng_sha1.o : rng_sha1.c
graph.o : graph.c
decoder.o : decoder.c

# Rebuild if included header files change
decoder.o : decoder.h online-code.h graph.h
graph.o : graph.h online-code.h
online-code.o : online-code.h
rng_sha1.o : rng_sha1.h

