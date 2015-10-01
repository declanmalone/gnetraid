
EMBED = yes

ifndef PREFIX
PREFIX = ~
endif

ifdef EMBED
DEFINES = -DEMBED_SPU
endif

# -O1 or greater should turn on dead code elimination optimisation,
# which should remove all code for if (verbose) {...} debug messages.
CFLAGS = -Wall -O2 $(DEFINES)
SPUFLAGS = # -m32
PPUFLAGS = -m64

PROGS         = ida-helper-ps3 spu-task
HOST_C_FILES  = host.c # spu-matrix.c spu-math.c
SPU_OBJ_FILES = spu-math.o spu-matrix.o spu-alloc.o spu-task.o spu-dma.o
PPU_OBJ_FILES = ppu-event.o  ppu-queue.o  ppu-scheduler.o \
                ppu-cnc.o ppu-io.o ppu-ida.o

all: ida-helper-ps3

install: ida-helper-ps3
	install ida-helper-ps3 $(PREFIX)/bin
	install rabin-ida-ps3.pl $(PREFIX)/bin

clean :
	-rm $(SPU_OBJ_FILES) $(PPU_OBJ_FILES) $(PROGS) spu-task.eo 2>/dev/null

ppu-io.o : ppu-io.c common.h ppu-io.h host.h
	gcc $(PPUFLAGS) $(CFLAGS) -c ppu-io.c

ppu-ida.o : ppu-ida.c common.h ppu-ida.h host.h
	gcc $(PPUFLAGS) $(CFLAGS) -c ppu-ida.c

ppu-cnc.o : ppu-cnc.c common.h ppu-cnc.h host.h
	gcc $(PPUFLAGS) $(CFLAGS) -c ppu-cnc.c

ppu-scheduler.o : ppu-scheduler.c common.h ppu-scheduler.h host.h
	gcc $(PPUFLAGS) $(CFLAGS) -c ppu-scheduler.c

ppu-queue.o : ppu-queue.c common.h ppu-queue.h host.h
	gcc $(PPUFLAGS) $(CFLAGS) -c ppu-queue.c

ppu-event.o : ppu-event.c common.h ppu-event.h host.h
	gcc $(PPUFLAGS) $(CFLAGS) -c ppu-event.c

spu-dma.o : spu-dma.c spu-dma.h spu-task.h
	spu-gcc $(SPUFLAGS) $(CFLAGS) -c spu-dma.c

spu-math.o : spu-math.c spu-math.h common.h
	spu-gcc $(SPUFLAGS) $(CFLAGS) -c spu-math.c

spu-matrix.o : spu-matrix.c spu-matrix.h common.h
	spu-gcc $(SPUFLAGS) $(CFLAGS) -c spu-matrix.c

spu-alloc.o : spu-alloc.c spu-alloc.h common.h
	spu-gcc $(SPUFLAGS) $(CFLAGS) -c spu-alloc.c

spu-task.o : spu-task.c common.h spu-task.h
	spu-gcc $(SPUFLAGS) $(CFLAGS) -c spu-task.c

spu-task : $(SPU_OBJ_FILES)
	spu-gcc $(SPUFLAGS) $(CFLAGS) $(SPU_OBJ_FILES) -o spu-task

spu-task.eo : spu-task
	embedspu $(PPUFLAGS) program_image spu-task spu-task.eo


# since the matrix and math code need to be compiled separately for
# each platform, forego compiling these to object files for the PPU,
# and simply compile them in one go along with the host program. Also,
# to allow for easier conditional assembly and embedding, we compile
# host.c directly from source too.

ifdef EMBED

ida-helper-ps3 : $(HOST_C_FILES) $(PPU_OBJ_FILES) spu-task.eo
	ppu-gcc $(PPUFLAGS) $(CFLAGS) -pthread -lspe2 \
	  $(HOST_C_FILES) $(PPU_OBJ_FILES) \
	  spu-task.eo -o ida-helper-ps3

else

ida-helper-ps3 : $(HOST_C_FILES) $(PPU_OBJ_FILES)
	gcc $(PPUFLAGS) $(CFLAGS) -pthread -lspe2 $(PPU_OBJ_FILES) \
	  spu-matrix.c spu-math.c -o ida-helper-ps3

endif





