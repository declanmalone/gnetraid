// nibble-based leading zero counts
const static short leading[] = {
  4, 3, 2, 2, 1, 1, 1, 1, // 0-7
  0, 0, 0, 0, 0, 0, 0, 0  // 8-15
};

// No boundary checking done here; caller needs to make sure string
// is not all zeroes first
unsigned int vec_clz(char *s) {
    int zeroes = 0;
    while (*s == (char) 0) { zeroes+=8; ++s; }
    if (*s & 0xf0) {
        return zeroes + leading[((unsigned char) *s) >> 4];
    } else {
        return zeroes + 4 + leading[*s];
    }
}

// nibble-based trailing zero counts
const static short trailing[] = {
  4, 0, 1, 0, 2, 0, 1, 0, // 0-7 
  3, 0, 1, 0, 2, 0, 1, 0  // 8-15
};
// No boundary check done here either.
unsigned vec_ctz(SV *sv) {
    STRLEN len;
    char *s;
    s = SvPV(sv, len);

    s += len - 1;
    int zeroes = 0;
    while (*s == (char) 0) { zeroes+=8; --s; }
    if (*s & 0x0f) {
        return zeroes + trailing[(*s) & 0x0f];
    } else {
        return zeroes + 4 + trailing[((unsigned char) *s) >> 4];
    }
}

// Shift a vector (string) left by b bits
void vec_shl(SV *sv, unsigned b) {
    STRLEN len;
    unsigned char *s;
    unsigned full_bytes;

    if (b == 0) return;

    s = SvPV(sv, len);
    full_bytes = b >> 3;

    // shifting by full bytes is easy
    if ((b & 7) == 0) {
        int c = len - full_bytes;
        while (c--) {
            *s = s[full_bytes];
            ++s;
        }
        while (full_bytes--) { *(s++) = (char) 0; }
        return;
    }

    //return;

    // or else combine bits from two bytes
    int c = len - full_bytes - 1;
    unsigned char l,r;
    b &= 7;
    while (c--) {
        l = s[full_bytes]    <<      b;
        r = ((unsigned char) s[full_bytes +1]) >> (8 - b);
        *(s++) = l | r;
    }
    // final byte to shift should be at end of vector
    l = s[full_bytes]  << b;
    *(s++) = l;
    // zero-pad the rest
    while (full_bytes--) { *(s++) = (char) 0; }
}

