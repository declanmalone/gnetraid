
CFLAGS = -Wall -O3 -funroll-loops
SPUFLAGS = # -m32
PPUFLAGS = -m64

PROGS     = host spu-task
SPU_OBJ_FILES = spu-math.o spu-matrix.o spu-alloc.o spu-task.o

all: $(PROGS)

clean :
	-rm $(SPU_OBJ_FILES) $(PROGS) 2>/dev/null

host.o : host.c common.h
	gcc $(PPUFLAGS) $(CFLAGS) -c host.c

spu-math.o : spu-math.c spu-math.h common.h
	spu-gcc $(SPUFLAGS) $(CFLAGS) -c spu-math.c

spu-matrix.o : spu-matrix.c spu-matrix.h common.h
	spu-gcc $(SPUFLAGS) $(CFLAGS) -c spu-matrix.c

spu-alloc.o : spu-alloc.c spu-alloc.h common.h
	spu-gcc $(SPUFLAGS) $(CFLAGS) -c spu-alloc.c

spu-task.o : spu-task.c common.h
	spu-gcc $(SPUFLAGS) $(CFLAGS) -c spu-task.c

host : host.o spu-matrix.c
	gcc $(PPUFLAGS) $(CFLAGS) -pthread -lspe2 host.o spu-matrix.c spu-math.c -o host

spu-task : $(SPU_OBJ_FILES)
	spu-gcc $(SPUFLAGS) $(CFLAGS) $(SPU_OBJ_FILES) -o spu-task

