
OBJECTS = online-code.o rng_sha1.o graph.o decoder.o

libs : libonline-code.a

libonline-code.a : $(OBJECTS)
	$(AR) cr $@ $(OBJECTS)
	ranlib $@

online-code.o : online-code.c
	${CC} -c $< 

rng_sha1.o : rng_sha1.c
	${CC} -c $< 

graph.o : graph.c
	${CC} -c $< 

decoder.o : decoder.c
	${CC} -c $< 


decoder.c : decoder.h online-code.h graph.h
graph.c : graph.h
online-code.c : online-code.h
rng_sha1.c : rng_sha1.h

