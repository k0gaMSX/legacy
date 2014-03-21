/*
 *		  Standalone BogoMips program
 *
 * Based on code Linux kernel code in init/main.c and
 * include/linux/delay.h
 *
 * For more information on interpreting the results, see the BogoMIPS
 * Mini-HOWTO document.
 *
 * version: 1.3
 *  author: Jeff Tranter (Jeff_Tranter@Mitel.COM)
 *
 * Modified: jun/99, by Adriano Cunha <adrcunha@dcc.unicamp.br>
 *	     added MSXDOS_BOGOMIPS and HIGH_PRECISION compiling options
 *
 * What is the idea for calculating BogoMIPS?
 * Check, in one second of processing, how many loops your machine can
 * execute.
 */

#include <stdio.h>
#include <time.h>

#ifdef CLASSIC_BOGOMIPS
/* the original code from the Linux kernel */
static __inline__ void delay(int loops)
{
  __asm__(".align 2,0x90\n1:\tdecl %0\n\tjns 1b": :"a" (loops):"ax");
}
#endif

#ifdef QNX_BOGOMIPS
/* version for QNX C compiler */
void delay(int loops);
#pragma aux delay = \
     "l1:"	 \
     "dec eax"	 \
     "jns l1"	 \
     parm nomemory [eax] modify exact nomemory [eax];
#endif

#ifdef PORTABLE_BOGOMIPS
/* portable version */
static void delay(unsigned long loops)
{
  long i;
  for (i = loops; i >= 0 ; i--)
    ;
}
#endif

#ifdef MSXDOS_BOGOMIPS
static long htimi1;
static char htimi2;
static unsigned char clocks_per_sec;

#ifdef CLOCKS_PER_SEC
#undef CLOCKS_PER_SEC
#endif
#ifdef clock()
#undef clock()
#endif

#define CLOCK_ADDR	0xf975
#define clock() *(uchar *)CLOCK_ADDR
#define CLOCKS_PER_SEC	clocks_per_sec

void init_clock_count()
{
#asm
  global _clocks_per_sec
  ld	a,(0FCC1h)
  ld	hl,2Bh
  call	000Ch
  ld	(_clocks_per_sec),a
#endasm
  if ((clocks_per_sec & 0x80) == 0) clocks_per_sec = 60;
     else clocks_per_sec = 50;
  htimi1=*(long *)0xfd9a;
  htimi2=*(char *)0xfd9e;
  asm("di");
  *(uchar *)0xfd9a=0x21;
  *(uint *)0xfd9b=CLOCK_ADDR;
  *(uchar *)0xfd9d=0x34;
  *(uchar *)0xfd9e=0xc9;
  asm("ei");
}

void end_clock_count()
{
  asm("di");
  *(long *)0xfd9a=htimi1;
  *(char *)0xfd9e=htimi2;
  asm("ei");
}
#endif

int
main(void)
{
  unsigned long loops_per_sec = 1;
  unsigned long ticks;

#ifdef MSXDOS_BOGOMIPS
  init_clock_count();
#endif

  printf("Calibrating delay loop.. ");
  fflush(stdout);

  while ((loops_per_sec <<= 1)) {
    /* this loops until we have waste one second of more of processing
       doing a certain number of loops */
#ifdef MSXDOS_BOGOMIPS
    ticks = 0;
    clock() = 0;
#else
    ticks = clock();
#endif
    delay(loops_per_sec);
    ticks = clock() - ticks;
    if (ticks >= CLOCKS_PER_SEC) {
#ifdef MSXDOS_BOGOMIPS
      end_clock_count();
#endif
      loops_per_sec = (loops_per_sec / ticks) * CLOCKS_PER_SEC;
#ifdef HIGH_PRECISION
      printf("ok - %lu.%02lu%02lu BogoMips\n",
	     loops_per_sec/500000,
	     (loops_per_sec/5000) % 100,
	     (loops_per_sec/50) % 100
	     );
#else
      printf("ok - %lu.%02lu BogoMips\n",
	     loops_per_sec/500000,
	     (loops_per_sec/5000) % 100
	     );
#endif
      return 0;
    }
  }
#ifdef MSXDOS_BOGOMIPS
  end_clock_count();
#endif
  printf("failed\n");
  return -1;
}
