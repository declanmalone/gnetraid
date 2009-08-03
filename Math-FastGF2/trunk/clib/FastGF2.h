/* Fast GF(2^m) library routines */
/*
  Copyright (c) by Declan Malone 2009.
  Licensed under the terms of the GNU General Public License and
  the GNU Lesser (Library) General Public License.
*/

/*
  These may need to be changed to suit word sizes on your platform. If
  you change them, be sure to also change any function prototypes
  below.
*/
typedef unsigned char    gf2_u8;
typedef unsigned short   gf2_u16;
typedef unsigned long    gf2_u32;
typedef signed char      gf2_s8;
typedef signed short     gf2_s16;
typedef signed long      gf2_s32;

#ifdef _LARGEFILE64_SOURCE
#define OFF_T off64_t
#define OFF_T_FMT "%lld"
#define SEEK lseek64
#else
#define OFF_T off_t
#define OFF_T_FMT "%ld"
#define SEEK lseek
#endif

/* Public interface routines */

/* basic maths */
unsigned long gf2_mul (int width, unsigned long a, unsigned long b);
unsigned long gf2_inv (int width, unsigned long a);
unsigned long gf2_div (int width, unsigned long a, unsigned long b);
unsigned long gf2_info(int bits);

/* matrix */
typedef struct {
  int rows;
  int cols;
  int width;			/* number of bytes in each element */
  char *values;
  enum {
    UNDEFINED, ROWWISE, COLWISE,
  } organisation;
  /* 
    save some information so we know whether to call free() when we're
    finished with the object. FREE_NONE means don't call free on either
    the structure or the values array.
  */
  enum {
    FREE_NONE, FREE_VALUES, FREE_STRUCT, FREE_BOTH,
  } alloc_bits;
} gf2_matrix_t;


struct gf2_matrix_closure;	/* forward declaration needed */
typedef struct gf2_matrix_closure* gf2_matrix_closure_t;
typedef OFF_T 
  (*gf2_matrix_callback) (gf2_matrix_closure_t, char *, OFF_T);
union  gf2_polymorphic {
  char        c;
  int         i;
  long        l;
  OFF_T     L;
  float       f;
  double      d;
  long double D;
  int*        I;
  char*       C;
  void*       V;
  gf2_matrix_closure_t S;	/* S for 'S'truct */
  /* for other pointer types, simply use a cast */
};
struct gf2_matrix_closure {
  gf2_matrix_callback fp;       /* function callback */

  char  u1_type;		/* must match names in union below */
  int   u1_many;		/* for pointer types, how many? */
  union gf2_polymorphic u1;

  char  u2_type;		/* must match names in union below */
  int   u2_many;		/* for pointer types, how many? */
  union gf2_polymorphic u2;
};

/* data common to all coder/decoder jobs */

struct child {			/* track create_single_share processes */
  OFF_T    current_offset;	/* where are we in current i/o? */
  int        result;		/* error return from process */
  int        shareno;		/* which share is being written */
  pid_t      pid;		/* process ID */
  char       finished;          /* is process finished? */
};

/* streambuf control wraps up a closure and buffer-management data */
struct gf2_streambuf_control {
  struct gf2_matrix_closure handler;
  union {
    int  iwcol;
    int  orcol;
  } hc;
  OFF_T BF;
  union {
    char* IW;
    char* OR;
  } hp;
  char    *END;
  union {
    size_t max_safe_fill;
    size_t max_safe_empty;
  } hs;
};

int gf2_matrix_offset_right (gf2_matrix_t *m);
int gf2_matrix_offset_down (gf2_matrix_t *m);

#ifdef NOW_IS_OK
int gf2_matrix_row_size_in_bytes (gf2_matrix_t *m);
int gf2_matrix_col_size_in_bytes (gf2_matrix_t *m);
char* gf2_matrix_element (gf2_matrix_t *m, int r, int c);
gf2_matrix_t* gf2_matrix_invert(gf2_matrix_t *m);
int gf2_matrix_multiply (gf2_matrix_t* result, char org, char* poly,
			 gf2_matrix_t* a, gf2_matrix_t* b);
#endif
