/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

// Command 'n control (cnc) interpreter for host

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <stdint.h>

#include "host.h"
#include "ppu-ida.h"
#include "ppu-event.h"
#include "ppu-scheduler.h"
#include "ppu-cnc.h"

#define CMDBUFSIZ   2048

// our variables
int did_init=0;

void fatal(const char *s) {
  fprintf(stderr, "ERROR: %s\n", s);
  exit(1);
}

void fatal_strerr(const char* s,int err) {
  fprintf(stderr,"%s: %s\n", s, strerror(err));
  exit(1);
}

/* Free any memory used by codec structure and then blank it */
void codec_reset (codec_t *c) {
  int i;

  if (c->infile != NULL)  free(c->infile);
  if (c->outfile != NULL) free(c->outfile);
  if (c->padding != NULL) free(c->padding);
  if (c->sharefiles != NULL) {
    for (i=0; i<c->nsharefiles; ++i) {
      free(c->sharefiles[i]);
    }
    free(c->sharefiles);
  }
  if (c->matrix != NULL)  free(c->matrix);
  if (c->inverse != NULL) free(c->inverse);

  memset(c,0,sizeof(codec_t));

}

/* helper functions for parsing and validating commands from stdin */

char* parse_hex(char* dest,int length, char* string) {

  int i;
  char lo,hi;
  char did_alloc=0;

  /* malloc new space if we weren't passed a place to store the result  */
  if (dest == NULL) {
    if ((dest=malloc(length))==NULL) return NULL; else did_alloc=1;
  }

  for (i=0; i < (length <<1); i+=2) {
    hi=tolower(string[i]);
    lo=tolower(string[i+1]);

    if (hi >= '0' && hi <= '9') {
      hi = hi - '0';
    } else if (hi >= 'a' && hi <= 'f') {
      hi = hi - 'a' + 10; 
    } else {
      if (did_alloc) free(dest);
      return NULL;
    }
    
    if (lo >= '0' && lo <= '9') {
      lo = lo - '0';
    } else if (lo >= 'a' && lo <= 'f') {
      lo = lo - 'a' + 10; 
    } else {
      if (did_alloc) free(dest);
      return NULL;
    }

    dest[i>>1]=(hi << 4) | lo;

  }

  /* allow trailing spaces */
  if (string[i] == '\0' || isspace(string[i]))
    return dest;

  /* but fail if there's any other trailing junk */
  if (did_alloc) free(dest);
  return NULL;
}

/* slightly different from parse_hex in that we assume that the array
   pointer passed to us is already allocated. Also, instead of passing
   back the same pointer (or a newly allocated one, which we don't do
   anyway), we return the number of items we put in the list. If the
   specification is garbled or we would overrun the list, we return 0.
*/
int parse_share_list (int* dest, int max_len, char* s) {
  unsigned c,i,j,x,y;
  char     garbled=0;

  i=0;
  while (*s != '\0') {
    c=sscanf(s,"%u-%u",&x,&y);	/* '-' doesn't count towards c */
    if (c==0) {
      garbled=1; break;
    } else if (c==1) {
      if (i >=max_len) return 0;
      dest[i++]=x;
      do { ++s; } while (isdigit(*s));
    } else if (c==2) {
      if (x > y) {
	garbled=1; break;
      }
      for (j=x; j <= y; j++) {
	if (i >= max_len) return 0;
	dest[i++]=j;
      }
      s=strchr(s,'-');
      do { ++s; } while (isdigit(*s));
    }
    if (*s == ',') ++s;
  }
  return garbled ? 0 : i;
}

char parse_range (char *s, OFF_T* low, 
		  OFF_T* high) {
  char c=sscanf(s,"%lu-%lu",low,high);
  if (c != 2)        return c;
  if (*low > *high)  return 0;
  return c;
}

/*
  Main command interpreter loop read commands from stdin and output
  results to stdout.
*/
void command_interpreter (void) {

  char  buf[CMDBUFSIZ];
  char* s;
  char* cmd;
  char* arg;
  int*  sharelist=NULL;
#ifdef USE_ALARMS
  sighandler_t old_alarm_handler;
#endif

  codec_t *c;
  int      i,j;

  // allocate a codec structure to hold all information about the
  // process to perform
  c=malloc(sizeof(codec_t));
  if (c == 0) {
    fatal_strerr("Failed to allocate codec structure\n", errno);
    exit(1);
  }	   
  memset(c,0,sizeof(codec_t));

  // set up default values
  c->spe_num_bufpairs = SPE_BUFFER_PAIRS;
  c->num_spe          = MAX_SPE_THREADS;

  /* assume a simple 'command whitespace optional_arg \n' pattern */
  while(fgets(buf,CMDBUFSIZ,stdin) != NULL) {

    if (buf[0] == '#')   continue; /* simple comments */
    buf[strlen(buf)-1]='\0';       /* remove newline  */
    for(i=0; i< strlen(buf); ++i) {
      if (isspace(buf[i]))  break; /* found first space */
      buf[i]=tolower(buf[i]);	   /* make commands case-insensitive */
    }

    do {
      buf[i++]='\0';
    } while (i<strlen(buf) && isspace(buf[i]));

    cmd=buf;
    arg=buf+i;

    if (verbose) 
      printf("INFO: Got command '%s', arg '%s'\n",cmd,arg);

    if (!strcmp("shares",cmd) || !strcmp("n",cmd)) {               /* shares */
      i=atoi(arg);
      if (c->n) {
        printf("WARN: ignoring extra value for shares: %d\n",i);
      } else {
	c->n=i;
      }

    } else if (!strcmp("quorum",cmd) || !strcmp("k",cmd)) {        /* quorum */
      i=atoi(arg);
      if (c->k) {
        printf("WARN: ignoring extra value for quorum: %d\n",i);
        continue;
      }
      c->k=i;

    } else if (strcmp("security",cmd)==0) {                      /* security */
      i=atoi(arg);
      if (c->w) {
        printf("WARN: ignoring extra value for security: %d\n",i);
      } else if (i > 128) {
        printf("WARN: Invalid value for security: %d\n",i);
      } else {
	c->w=i;
	c->order=i << 3;
      }

    } else if (strcmp("poly",cmd)==0) {	                             /* poly */
      if (!c->w) {
        printf("WARN: poly can only be used after security\n");
        continue;
      }
      // ignore poly value
      printf ("WARN: ignoring poly command (using hard-wired value)\n");
      //      continue;
      // if ((c->poly=parse_hex(NULL,c->w,arg))==NULL)
      //  printf("WARN: invalid hex value %s passed to poly\n",arg);

    } else if (strcmp("header",cmd)==0) {                          /* header */
      i=atoi(arg);
      if (c->share_header_size) {
        printf("WARN: ignoring extra value for header: %d\n",i);
        continue;
      }
      c->share_header_size=i;


    } else if (strcmp("spawn",cmd)==0) {                            /* spawn */
      i=atoi(arg);
      c->num_spe=i;

    } else if (strcmp("timer",cmd)==0) {                            /* timer */
      i=atoi(arg);
      c->timer=i;

    } else if (strcmp("infile",cmd)==0) {                          /* infile */
      if (c->infile != NULL) {
        printf("WARN: ignoring extra value for infile: %s\n",arg);
	continue;
      }
      if ((c->infile=malloc(strlen(arg)+1))) {
	strcpy(c->infile,arg);
      } else {
	printf("ERROR: malloc of infile name failed. Aborting\n");
        exit(1);
      }

    } else if (strcmp("range",cmd)==0) {                            /* range */
      if (parse_range(arg,&c->range_start,&c->range_next)!=2) {
	printf("WARN: garbled range line; ignored\n");
      }
      printf ("INFO: parsed range OK\n");

    } else if (strcmp("outfile",cmd)==0) {                        /* outfile */
      if (c->outfile != NULL) {
        printf("WARN: ignoring extra value for outfile: %s\n",arg);
	continue;
      }
      if ((c->outfile=malloc(strlen(arg)+1))) {
	strcpy(c->outfile,arg);
      } else {
	printf("ERROR: malloc of outfile name failed. Aborting\n");
        exit(1);
      }

    } else if (strcmp("sharefile",cmd)==0) {                    /* sharefile */
      if (c->n == 0 || c->w == 0) {
	printf("WARN: Supply n and security before sharefile\n");
        continue;
      }
      if (c->sharefiles == NULL) {
        c->sharefiles=malloc(c->n * sizeof (char*));
        c->nsharefiles=0;
      }
      if (c->sharefiles == NULL) {
	printf("ERROR: malloc of sharefiles array failed. Aborting\n");
        exit(1);
      }
      if (c->nsharefiles >= c->n) {
	printf("WARN: Ignoring extra sharefile %s\n",arg);
        continue;
      }
      if ((c->sharefiles[c->nsharefiles]=malloc(strlen(arg)+1))) {
	strcpy(c->sharefiles[c->nsharefiles],arg);
	++c->nsharefiles;
      } else {
	printf("ERROR: malloc of sharefile name failed. Aborting\n");
        exit(1);
      }

    } else if (strcmp("padding",cmd)==0) {                        /* padding */
      if (c->n == 0 || c->w == 0) {
	printf("WARN: Supply n and security before padding\n");
        continue;
      }
      if (c->padding == NULL) {
        c->padding=malloc((c->n - 1) * c->w);
        c->padding_elements=0;
      }
      if (c->padding== NULL) {
	printf("ERROR: malloc of padding data failed. Aborting\n");
        exit(1);
      }
      if (c->padding_elements >= c->n - 1) {
	printf("WARN: Ignoring padding command on full padding\n");
        continue;
      }
      if (parse_hex((char*) (c->padding + c->padding_elements * 
                    c->w),c->w,arg)) {
        ++c->padding_elements;
      } else {
	printf("WARN: invalid hex value %s passed to padding\n",arg);
        continue;
      }

    } else if (strcmp("matrix",cmd)==0) {                          /* matrix */
      if ((c->n == 0) || (c->k == 0) || 
	  (c->w == 0)) {
	printf("WARN: Supply n,k and security before matrix\n");
        continue;
      }
      if (c->matrix == NULL) {
        c->matrix=malloc(align_up((c->n * c->k * c->w),16));
        c->matrix_elements=0;
      }
      if (c->matrix== NULL) {
	printf("ERROR: malloc of matrix data failed. Aborting\n");
        exit(1);
      }
      if (c->matrix_elements >= c->n * c->k) {
	printf("WARN: Ignoring matrix command on full matrix\n");
        continue;
      }
      if (parse_hex(c->matrix + c->matrix_elements * 
                    c->w,c->w,arg)) {
        ++c->matrix_elements;
      } else {
	printf("WARN: invalid hex value %s passed to matrix\n",arg);
        continue;
      }

    } else if (strcmp("inverse",cmd)==0) {                        /* inverse */
      if (c->k == 0 || c->w == 0) {
	printf("WARN: Supply k and security before inverse\n");
        continue;
      }
      if (c->inverse == NULL) {
        c->inverse=malloc(align_up((c->k * c->k * c->w),16));
        c->inverse_elements=0;
      }
      if (c->inverse== NULL) {
	printf("ERROR: malloc of inverse data failed. Aborting\n");
        exit(1);
      }
      if (c->inverse_elements >= c->n * c->k) {
	printf("WARN: Ignoring inverse command on full inverse matrix\n");
        continue;
      }
      if (parse_hex(c->inverse + c->inverse_elements * 
		    c->w,c->w,arg)) {
        ++c->inverse_elements;
      } else {
	printf("WARN: invalid hex value %s passed to inverse\n",arg);
        continue;
      }

    } else if (strcmp("split",cmd)==0) {                            /* split */

      if (!check_split_settings(c)) {
	printf("WARN: Some settings are missing. Can't split yet\n");
        continue;
      }
      if (c->k > c->n) {
	printf("WARN: quorum > shares. Ignoring request to split");
        continue;
      }
      if (sharelist != NULL)  free(sharelist);
      sharelist=malloc(c->n * sizeof(int));
      if (sharelist == NULL) { 
	printf("ERROR: malloc of sharelist failed. Aborting\n");
        exit(1);
      }
      if ((i=parse_share_list(sharelist,c->n,arg)) == 0) {
	printf("WARN: garbled list of shares to split. Ignoring request\n");
        continue;
      }
      c->current_operation=SPE_COL_ROW_ROWWISE;
#ifdef USE_ALARMS
      if (c->timer) {
	old_alarm_handler=signal(SIGALRM, &sig_alarm_handler);
	alarm (c->timer);
      }
#endif
/* 	if (create_many_shares(i,sharelist)==0) {  */
//      ida_split(i,sharelist);
//      c->nsharefiles = i;
//      c->sharefiles = sharelist // (actually, sharelist is like 0-6)
      ida_split(c);
      printf("OK: split finished\n");
      fflush(stdout);
#ifdef USE_ALARMS
      if (c->timer) {
	alarm(0);
	signal(SIGALRM,old_alarm_handler);
      }
#endif

    } else if (strcmp("combine",cmd)==0) {                        /* combine */

      printf ("INFO: got combine command\n");
      fflush(stdout);
      if (!check_combine_settings(c)) {
	printf("WARN: Some settings are missing. Can't combine yet\n");
        continue;
      }
      if (sharelist != NULL)  free(sharelist);
      sharelist=malloc(c->k * sizeof(int));
      if (sharelist == NULL) { 
	printf("ERROR: malloc of sharelist failed. Aborting\n");
        exit(1);
      }
      if ((i=parse_share_list(sharelist,c->k,arg)) == 0) {
	printf("WARN: garbled list of shares to combine. Ignoring request\n");
        continue;
      }
      c->current_operation=SPE_ROW_COL_ROWWISE;
#ifdef USE_ALARMS
      if (c->timer) {
	old_alarm_handler=signal(SIGALRM, sig_alarm_handler);
	alarm (c->timer);
      }
#endif
      /*       if(combine_shares(i,sharelist)==0) { */
      //      ida_combine(i,sharelist);	/* screw return values */
      ida_combine(c);
      printf("OK: combine finished\n");
      fflush(stdout);
#ifdef USE_ALARMS
      if (c->timer) {
	alarm(0);		/* deactivate pending alarms */
	signal(SIGALRM,old_alarm_handler);
      }
#endif

    } else if (strcmp("quit",cmd)==0) {                              /* quit */
      return;

    } else if (strcmp("reset",cmd)==0) {                            /* reset */
      codec_reset(c);

      /*
      printf ("Sleeping for 2s after reset\n");
      fflush(stdout);
      sleep(2);
      */

      // set up default values again
      c->spe_num_bufpairs = SPE_BUFFER_PAIRS;
      c->num_spe          = MAX_SPE_THREADS;

    } else {
      if (*cmd!='\0') 
	printf("WARN: Unknown command %s\n",cmd);
    }

    fflush(stdout);		   /* flush any output from the above */
  }

  printf ("INFO: leaving command interpreter\n");
  fflush(stdout);		   /* flush any output from the above */
  
  /* signal (SIGALRM, sig_alarm_handler); */

}
