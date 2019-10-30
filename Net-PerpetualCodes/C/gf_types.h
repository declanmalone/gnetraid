/* typedefs mapping field types to underlying compiler types */

// Will rely on stdint, which should appear everywhere
//
// Otherwise, have a look at my Math::FastGF2 Perl module for a way of
// checking during config. Or use something other auto-config program.

#ifndef GF_TYPES_H
#define GF_TYPES_H

#include <stdint.h>

typedef uint8_t   gf8_t;
typedef uint16_t  gf16_t;
typedef uint32_t  gf32_t;

#endif
