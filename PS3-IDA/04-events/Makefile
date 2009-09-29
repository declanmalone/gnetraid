all: host spu-task

host.o: host.c common.h
	gcc -c host.c

spu-task.o : spu-task.c common.h
	spu-gcc -c spu-task.c

host : host.o
	gcc -pthread -lspe2 host.o -o host

spu-task : spu-task.o
	spu-gcc spu-task.o -o spu-task