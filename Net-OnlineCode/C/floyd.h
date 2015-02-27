// Floyd's algorithm -- header file
//

#ifndef OC_FLOYD_H
#define OC_FLOYD_H

#include "rng_sha1.h"

#ifndef SET_METHOD
#error Must set SET_METHOD macro
#endif

// C's preprocessor doesn't let you compare strings so the best we can
// do is to use #defines to enumerate the options
#define SET_UNORDERED_LIST  1
#define SET_BITMAP          2

// The set implementation has to define four macros:
//
// SET_INIT(start,n,k) :  Initialise the set (allocate struct)
// SET_CLR()           :  Empty the set
// SET_GET(x)          :  Test whether element x is in set
// SET_PUT(x)          :  Put element x into the set
// SET_OUT()           :  Write set elements to output int array
//
// For the first implementation I'm going to use (implied) static data
// structures. Later on I might define typedefs and add structure
// pointers to the argument lists above.

// Most the functions listed below are declared as static in floyd.c
// so they shouldn't cause namespace pollution (apart from the SET_*
// macro names themselves). The exception is SET_INIT since that needs
// to be called during program initialisation.

#if   SET_METHOD == SET_UNORDERED_LIST
#warning Using unordered list

#define SET_INIT oc_alloc_int_list
#define SET_CLR  clear_int_list
#define SET_GET  scan_unordered_list
#define SET_PUT  append_int_list
#define SET_OUT  return_int_list


#elif SET_METHOD == SET_BITMAP
#warning Using bitmap


#else 
#error Unknown SET_METHOD. See this file for valid options
#endif

// The prototype for calling oc_floyd is the same regardless of which
// set implementation is used, though the program does need to call
// the SET_INIT macro before using it.
//
// The return value is an array of k ints.
int *oc_floyd(oc_rng_sha1 *rng, int start, int n, int k);

#endif
