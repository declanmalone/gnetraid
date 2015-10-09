/***********************************************************
* You can use all the programs on  www.c-program-example.com
* for personal and learning purposes. For permissions to use the
* programs for commercial purposes,
* contact info@c-program-example.com
* To find more C programs, do visit www.c-program-example.com
* and browse!
* 
*                      Happy Coding
***********************************************************/


 


#include <stdio.h>
main()
{

 printf("    short int is %2d bytes \n", sizeof(short int));
 printf("          int is %2d bytes \n", sizeof(int));
 printf("        int * is %2d bytes \n", sizeof(int *));
 printf("     long int is %2d bytes \n", sizeof(long int));
 printf("   long int * is %2d bytes \n", sizeof(long int *));
 printf("   signed int is %2d bytes \n", sizeof(signed int));
 printf(" unsigned int is %2d bytes \n", sizeof(unsigned int));
 printf("\n");
 printf("        float is %2d bytes \n", sizeof(float));
 printf("      float * is %2d bytes \n", sizeof(float *));
 printf("       double is %2d bytes \n", sizeof(double));
 printf("     double * is %2d bytes \n", sizeof(double *));
 printf("  long double is %2d bytes \n", sizeof(long double));
 printf("\n");
 printf("  signed char is %2d bytes \n", sizeof(signed char));
 printf("         char is %2d bytes \n", sizeof(char));
 printf("       char * is %2d bytes \n", sizeof(char *));
 printf("unsigned char is %2d bytes \n", sizeof(unsigned char));
}
