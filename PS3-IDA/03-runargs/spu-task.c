#include <spu_intrinsics.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <spu_mfcio.h>

#include "common.h"


// Note that the args to main and the registers below must be declared
// as vectors!
union {
  struct {
    vector unsigned long long r3;
    vector unsigned long long r4;
    vector unsigned long long r5;
  } registers;
  task_setup_t structure;
} args_structure;

int main(vector unsigned long long spe, 
	 vector unsigned long long argp,
	 vector unsigned long long envp)
{

  task_setup_t *opts;

  printf ("SPU task starting\n");

  // spe, argp and envp should contain the packed contents of the
  // task_setup_t options structure. After writing them into the
  // registers part of the union above, we'll be able to access the
  // unpacked values via a pointer to the structure part.
  args_structure.registers.r3=spe;
  args_structure.registers.r4=argp;
  args_structure.registers.r5=envp;
  opts=&args_structure.structure;

  // use the macro defined in common.h to print received values
  DUMP_OPTS(opts);

  printf ("SPU returning\n");

  return 0;
}
