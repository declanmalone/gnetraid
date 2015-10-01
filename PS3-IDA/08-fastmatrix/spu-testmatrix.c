#include <stdio.h>
#include <spu_intrinsics.h>

#include "spu-math.h"
#include "spu-matrix.h"



// Reed-Solomon coding/decoding matrices
char __attribute__ ((aligned (16))) xform_values[64] = {
  0x35, 0x36, 0x82, 0x7A, 0xD2, 0x7D, 0x75, 0x31,
  0x0E, 0x76, 0xC3, 0xB0, 0x97, 0xA8, 0x47, 0x14,
  0xF4, 0x42, 0xA2, 0x7E, 0x1C, 0x4A, 0xC6, 0x99,
  0x3D, 0xC6, 0x1A, 0x05, 0x30, 0xB6, 0x42, 0x0F,
  0x81, 0x6E, 0xF2, 0x72, 0x4E, 0xBC, 0x38, 0x8D,
  0x5C, 0xE5, 0x5F, 0xA5, 0xE4, 0x32, 0xF8, 0x44,
  0x89, 0x28, 0x94, 0x3C, 0x4F, 0xEC, 0xAA, 0xD6,
  0x54, 0x4B, 0x29, 0xB8, 0xD5, 0xA4, 0x0B, 0x2C,
};

char __attribute__ ((aligned (16))) inverse_values[64] = {
  0x3E, 0x02, 0x23, 0x87, 0x8C, 0xC0, 0x4C, 0x79,
  0x5D, 0x2B, 0x2A, 0x5B, 0x7E, 0xFE, 0x25, 0x36,
  0xF2, 0xA9, 0xB5, 0x57, 0xA2, 0xF6, 0xA2, 0x7D,
  0x11, 0x5E, 0xE4, 0x61, 0x59, 0xF4, 0xB9, 0x42,
  0xD5, 0x16, 0xB8, 0x5B, 0x30, 0x85, 0x1E, 0x72,
  0x3B, 0xF7, 0x1B, 0x5B, 0x4C, 0x55, 0x35, 0x04,
  0x58, 0x95, 0x73, 0x33, 0x8A, 0x77, 0x1C, 0xF4,
  0x59, 0xC0, 0x7B, 0x13, 0x9F, 0x8B, 0xBE, 0xE3,
};

// statically-allocated space for output matrix
char __attribute__ ((aligned (16))) out_values [64];

int main (vec_ullong2 a, vec_ullong2 b, vec_ullong2 c) {

  gf2_matrix_t mat1, mat2, output;

  mat1.rows = mat2.rows = output.rows = 8;
  mat1.cols = mat2.cols = output.cols = 8;
  mat1.width = mat2.width = output.width = 1;
  mat1.organisation = mat2.organisation = output.organisation = ROWWISE;
  mat1.values = xform_values;
  mat2.values = inverse_values;

  printf ("Multiplying matrix by its inverse... result:\n\n");

  gf2_matrix_multiply_u8(&mat1, 0x1b, &mat2, &output);

  dump_matrix(&output);
  exit (0);
}