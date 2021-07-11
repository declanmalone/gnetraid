/* Fast split/recombine using Rabin's IDA */ /* -*- C -*- */
/* Copyright (c) Declan Malone 2009 */
/* License: GPL 2 */

typedef void (*sighandler_t)(int);

#define CMDBUFSIZ  512		/* for command interpreter input */
// #define __STANDALONE__          /* set to compile main() */

/* 
  for 64-bit file offsets, set LARGEFILE_SUPPORT. Make sure that this
  file is included before unistd.h is, or there will be problems.
*/
#ifdef LARGEFILE_SUPPORT
#define _LARGEFILE64_SOURCE
#define OFF_T off64_t
#define OFF_T_FMT "%lld"
#define SEEK lseek64
#else
#define OFF_T off_t
#define OFF_T_FMT "%ld"
#define SEEK lseek
#endif

#include <sys/types.h>
#include <unistd.h>

/* 
  Basic structure for matrix storage.  

  Matrices store rows x cols words of width bytes. A matrix can be
  stored in ROWWISE fashion, meaning that the second element in the
  values array is the element immediately to the right of the
  first. Contrariwise, for a matrix stored in COLWISE fashion, the
  second element in the array represents the element immediately below
  the first (assuming cols or rows >1 for each respective case).

  The choice of two different organisation strategies is to allow more
  efficient processing of input/output data in blocks: input to the
  split transformation is better organised in COLWISE fashion, while
  share outputs are better written in ROWWISE fashion. Similar, but
  opposite statements hold for the combine operation.

*/

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

/* Augmented closure type to allow function pointer to be customised
   with extra data. The gf2_circular_matrix_multiply requires
   callbacks specified in this way, and when it calls the callback, it
   sends it a pointer to the wrapper structure itself. The callback
   can then examine the structure to read back data local to this
   instance. 

   The long and the short of this is that it allows setting up a
   different callback for, eg, different input/output file
   handles. The same routine will be called in each case, but the
   function should be able to determine which filehandle to use by
   examining the closure structure passed to it. The only other option
   for achieving this kind of functionality would be to change the
   gf2_circular_matrix_multiply code to accept and send extra
   parameters so that the callback function knows which stream it's
   supposed to operate on. However, the type of extra data would have
   to be known in advance, and once it was written into the prototype
   for gf2_circular_matrix_multiply there would be no way of using a
   different type without modifying the prototype, and possibly the
   code inside the gf2_circular_matrix_multiply function.
*/

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

typedef struct {
  /* basic algorithm info */
  int    k;			/* quorum */
  int    n;			/* total number of shares */
  int    order;			/* order of the field = size in bits
                                   of data chunks */
  char*  poly;			/* all bits of the irreducible field
                                   polynomial except the high bit,
                                   which is assumed to be 1 */
  int    sec_level;		/* order / 8 = size in bytes */

  /* file-related info */
  char*  infile;		/* name of input file (to be split) */
  char*  outfile;		/* name of output file (recombined) */
  char*  padding;		/* words to use as padding at EOF */
  int    padding_elements;	/* how many elements in padding? */
  char** sharefiles;		/* names of share files */
  int    nsharefiles;		/* number of elements in prev array */
  int    share_header_size;	/* size of share header in bytes */
  OFF_T range_start;          /* must be a multiple of (k * sec_level) */
  OFF_T range_next;		/* as above, 0 = read/write to end of file */

  /* detailed transform info */
  char*  matrix;		/* transform matrix, row 0 .. row n-1 */
  int    matrix_elements;	/* how many matrix elements filled? */
  char*  inverse;		/* inverse matrix, row 0 .. row k-1 */
  int    inverse_elements;      /* how many inverse elements filled? */

  /* other options */
  int    timer;			/* seconds between status messages */
  int    maxchildren;		/* max number of children to fork */

  /* process tracking */
  enum {
    NOTHING, SPLIT, COMBINE,
  } current_operation;
  OFF_T current_offset;	/* progress counter for combine,
				   create_many_shares  */
  struct child** children;	/* at most n records: one child per
				   create_single_share process, never
				   reusing records. */
  int    nextchild;		/* next record to use */

} codec_t;

/* codec data, functions */

extern codec_t codec;

void codec_init (int k, int n, int order, int header, 
                 char* infile, char* outfile, char* poly, char *inverse);
void codec_reset (void);


/* bit vector and GF(2) arithmetic */
void vector_xor(char *dest, char* x, unsigned bytes);
int vector_size_in_bits (char* s, int bytes);
unsigned char vector_shift_left(char* r,unsigned bytes, 
                                unsigned char carry_in);
void vector_shift_left_many (char* s, int bits, int len);
int vector_eq_byte (char *s, char b, int len);
int vector_ne_byte (char *s, char b, int len);
void vector_set_byte (char *s, char b, int len);

/* GF(2) arithmetic ... */
void gf2_multiply(char *dest, char *x, char *y, char* poly,
		  int bytes, char* scratch);
int gf2_invert(char *dest, char *x, char* poly, int bytes,
	       char* scratch);

/* Matrix arithmetic */
gf2_matrix_t*
gf2_matrix_alloc (gf2_matrix_t* from, int rows, int cols, int width,
		  char org);
gf2_matrix_t*
gf2_identity_matrix (gf2_matrix_t* dest, int rows, int cols, 
		     int width, int org);
int gf2_matrix_row_size_in_bytes (gf2_matrix_t *m);
int gf2_matrix_col_size_in_bytes (gf2_matrix_t *m);
int gf2_matrix_offset_right (gf2_matrix_t *m);
int gf2_matrix_offset_down (gf2_matrix_t *m);
char* gf2_matrix_element (gf2_matrix_t *m, int r, int c);
gf2_matrix_t* gf2_matrix_invert(gf2_matrix_t *m);
int gf2_matrix_multiply (gf2_matrix_t* result, char org, char* poly,
			 gf2_matrix_t* a, gf2_matrix_t* b);

/* IDA and supporting routines */

void sig_alarm_handler(int signum);
int create_many_shares(int nshares,int* share_list);
int combine_shares(int nshares,int* share_list);
char* parse_hex(char* dest,int length, char* string);
int parse_share_list (int* dest, int max_len, char* s);
char check_split_settings(void);
char check_combine_settings(void);
void command_interpreter (void);

OFF_T
gf2_process_streams(gf2_matrix_t *xform, char *poly,
		    gf2_matrix_t *in,  
		    struct gf2_streambuf_control *fill_ctl, 
		    int fillers,
		    gf2_matrix_t *out,  
		    struct gf2_streambuf_control *empty_ctl, 
		    int emptiers,
		    OFF_T bytes_to_read);
OFF_T ida_split(int nshares, int sharelist[]);
OFF_T ida_combine(int nshares, int sharelist[]);
