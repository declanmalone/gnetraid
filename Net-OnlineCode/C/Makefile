
all : online-code.o rng_sha1.o

online-code.o : online-code.c
	${CC} -c $< 

rng_sha1.o : rng_sha1.c
	${CC} -c $< 




online-code.c : online-code.h
rng_sha1.c : rng_sha1.h

