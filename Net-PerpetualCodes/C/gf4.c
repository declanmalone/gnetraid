/* Galois Field GF(2**4) */

/* Details:

   Irreducible polynomial is X**4 + X + 1
   Generator is 2 (X)

   Calculating by hand: start with X**0, multiply the previous value
   by X and reduce modulo the above polynomial at each step:

   Powers   Equation                  mod poly             Decimal
   X**0     1                                                1
   X**1     X                                                2
   X**2     X**2                                             4
   X**3     X**3                                             8
   X**4     X**4                                    X + 1    3
   X**5     X**2 + X                                         6
   X**6     X**3 + X**2                                      12
   X**7     X**4 + X**3               X**3        + X + 1    11
   X**8     X**4 + X**2 + X                  X**2     + 1    5
   X**9     X**3 + X                                         10
   X**10    X**4 + X**2                      X**2 + X + 1    7
   X**11    X**3 + X**2 + X                                  14
   X**12    X**4 + X**3 + X**2        X**3 + X**2 + X + 1    15
   X**13    X**4 + X**3 + X**2 + X    X**3 + X**2     + 1    13
   X**14    X**4 + X**3 + X           X**3            + 1    9
   X**15    X**4 + X                                    1    1

   The above can be used to create exponent and discrete logarithm
   tables, which are inverses of each other. For example:

   exp[0]  = 1         log[1]  = 0
   ...                 ...
   exp[6]  = 12        log[12] = 6
   ...                 ...
   exp[14] = 9         log[9]  = 14

   We don't include the last row since the exponent table indexes are
   the same modulo 15 (field size - 1).

   From these tables, we can also create multiplication tables using
   the identity:

   a * b == exp(log(a) + log(b))

   eg, 6 * 7 would be:

   exp(5 + 10) = exp(15 mod 15) = exp(0) = 1

   Inversion is governed by the identity:

   1/a = exp(15 - log(a))

   For example:

   1/6 = exp(15 - log(6)) = exp(15 - 5) = exp(10) = 7

   This tallies with the product above of 6*7 == 1 since 6 and 7 are
   multiplicative inverses of each other in this field. Confirming:

   1/7 = exp(15 - log(7)) = exp(15 - 10) = exp(5) = 6

   Division can be expressed as multiplication by an inverse, or the
   following identity:

   a / b = exp(log(a) - log(b))

   If the inner difference is less than 0, add 15 to it.

   For example:

   1/6 = exp(log(1) - log(6)) = exp(0 - 5) = exp(-5) = exp(10) = 7

*/

unsigned char gf16_exp[16] = { 1,2,4,8,3,6,12,11,5,10,7,14,15,13,9, 1  };
unsigned char gf16_log[16] = { 0,0,1,4,2,8,5, 10,3,14,9,7, 6, 13,11,12 };

// Compressed multiplication table generated from the above.  Combine
// the two 4-bit operands into the high, low nibbles of a byte and use
// it as an index to this table.
//
// For example, 6 * 7 = table[(6 << 4) + 7] = table[103] (or,
// visually, count down to the 6th row and take the element from the
// 7th column)
// 
unsigned char gf16_mul_table[256] = {
//0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  //
  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0
  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, // 1
  0,  2,  4,  6,  8, 10, 12, 14,  3,  1,  7,  5, 11,  9, 15, 13, // 2
  0,  3,  6,  5, 12, 15, 10,  9, 11,  8, 13, 14,  7,  4,  1,  2, // 3
  0,  4,  8, 12,  3,  7, 11, 15,  6,  2, 14, 10,  5,  1, 13,  9, // 4
  0,  5, 10, 15,  7,  2, 13,  8, 14, 11,  4,  1,  9, 12,  3,  6, // 5
  0,  6, 12, 10, 11, 13,  7,  1,  5,  3,  9, 15, 14,  8,  2,  4, // 6
  0,  7, 14,  9, 15,  8,  1,  6, 13, 10,  3,  4,  2,  5, 12, 11, // 7
  0,  8,  3, 11,  6, 14,  5, 13, 12,  4, 15,  7, 10,  2,  9,  1, // 8
  0,  9,  1,  8,  2, 11,  3, 10,  4, 13,  5, 12,  6, 15,  7, 14, // 9
  0, 10,  7, 13, 14,  4,  9,  3, 15,  5,  8,  2,  1, 11,  6, 12, // 10
  0, 11,  5, 14, 10,  1, 15,  4,  7, 12,  2,  9, 13,  6,  8,  3, // 11
  0, 12, 11,  7,  5,  9, 14,  2, 10,  6,  1, 13, 15,  3,  4,  8, // 12
  0, 13,  9,  4,  1, 12,  8,  5,  2, 15, 11,  6,  3, 14, 10,  7, // 13
  0, 14, 15,  1, 13,  3,  2, 12,  9,  7,  6,  8,  4, 10, 11,  5, // 14
  0, 15, 13,  2,  9,  6,  4, 11,  1, 14, 12,  3,  8,  7,  5, 10  // 15
};

// For division, we could create a similar table to the above, or just
// look up the denominator in the inverse table below, then multiply
// by that value.
unsigned char gf16_inv_table[16] = {
  0,  1,  9, 14, 13, 11,  7,  6, 15,  2, 12,  5, 10,  4,  3,  8
};
