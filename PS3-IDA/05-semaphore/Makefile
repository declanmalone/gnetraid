#CFLAGS = -O2
CFLAGS = -Wall

all: host spu-task

host.o: host.c common.h
	gcc $(CFLAGS) -c host.c

spu-task.o : spu-task.c common.h
	spu-gcc $(CFLAGS) -c spu-task.c

host : host.o
	gcc $(CFLAGS) -pthread -lspe2 host.o -o host

spu-task : spu-task.o
	spu-gcc $(CFLAGS) spu-task.o -o spu-task
