
/* PRIMES.C
   Example C program
   Lists all prime numbers up to MAXPRIME
   Uses Sieve of Eratosthenes method
*/

#include <stdio.h>
#define MAXPRIME 1000
#define NACROSS 10

count = NACROSS;

main()

{
  int i,prime,sieve[MAXPRIME+2];

  printf("\n");
  for (i=1 ; i<=MAXPRIME ; sieve[i++]=0 );

  for (prime=2 ; prime<MAXPRIME ; )
  {
    printit(prime);
    for (i=prime ; i<=MAXPRIME-prime ; sieve[i+=prime]=1);
    while (sieve[++prime]!=0);
  }
}


printit(n)
int n;
{
    if (count-- == 0)
    {
        count = NACROSS-1 ;
	printf("\n") ;
    }
    printf("%8d",n);
}
