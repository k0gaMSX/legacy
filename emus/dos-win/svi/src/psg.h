/*
** $Id:$
**
** File: psg/psg.h -- header file for software implementation of AY-3-8910
**		Programmable sound generator.  This module is used in my
**		GYRUSS emulator.
**
** Based on: Sound.c, (C) Ville Hallik (ville@physic.ut.ee) 1996
**
** SCC emulation removed.  Made modular and capable of multiple PSG
** emulation.
**
** Modifications (C) 1996 Michael Cuddy, Fen's Ende Software.
** http://www.fensende.com/Users/mcuddy
**
*/
#ifndef _H_PSG_PSG_
#define _H_PSG_PSG_

/* register id's */
#define AY_AFINE	(0)
#define AY_ACOARSE	(1)
#define AY_BFINE	(2)
#define AY_BCOARSE	(3)
#define AY_CFINE	(4)
#define AY_CCOARSE	(5)
#define AY_NOISEPER	(6)
#define AY_ENABLE	(7)
#define AY_AVOL		(8)
#define AY_BVOL		(9)
#define AY_CVOL		(10)
#define AY_EFINE	(11)
#define AY_ECOARSE	(12)
#define AY_ESHAPE	(13)

/* default clock frequency, frequency in MHz * 100 */
#ifndef AY8910_CLOCK 
#define AY8910_CLOCK (1832727040)	/* 1.832727040 MHZ */
#endif /* !defined AY8910_CLOCK */

#define AUDIO_CONV(A) (128+(A))	/* use this macro for signed samples */
//#define AUDIO_CONV(A) (A)		/* use this macro for unsigned samples */

/* here's the virtual AY8910 ... */
typedef struct {
  byte *Buf; /* sound buffer */
  byte Regs[256];

  /* state variables */
  int Incr0, Incr1, Incr2;
  int Increnv, Incrnoise;
  int StateNoise, NoiseGen;
  int Counter0, Counter1, Counter2, Countenv, Countnoise;
  int Vol0, Vol1, Vol2, Volnoise, Envelope;
} AY8910;

/*
** Initialize AY8910 emulator(s).
**
** 'rate' is sampling rate and 'bufsiz' is the size of the
** buffer that should be updated at each interval
*/
int AYInit(int rate, int bufsiz, byte *userbuffer);

/*
** reset all chip registers for AY8910 number 'num' 
*/
void AYResetChip(void);

/*
** called to update all chips; should be called about 50 - 70 times per
** second ... (depends on sample rate and buffer size)
*/
void AYUpdate(void);

/*
** write 'v' to register 'r' on AY8910 chip number 'n'
*/
void AYWriteReg(int r, int v);

/*
** read register 'r' on AY8910 chip number 'n'
*/
byte AYReadReg(int r);


/*
** return pointer to synthesized data
*/
byte *AYBuffer(void);

/*
** setup buffer
*/

AY8910 *AYPSGptr(void);

void AYSetBuffer(byte *buf);

void AYSetBufSize(int);

#endif /* _H_PSG_PSG_ */
/*
** Change Log
** ----------
** $Log:$
*/
