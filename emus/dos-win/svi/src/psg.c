/*
** $Id:$
**
** File: psg.c -- software implementation of AY-3-8910 Programmable
**		sound generator.
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

#include <stdio.h>
#include <stdarg.h>

#include "svi.h"
#include "psg.h"

int AYSoundRate; 	/* Output rate (Hz) */
int AYBufSize;		/* size of sound buffer, in samples */

AY8910 AYPSG;		/* array of PSG's */

/*
** Initialize AY8910 emulator(s).
**
** 'rate' is sampling rate and 'bufsiz' is the size of the
** buffer that should be updated at each interval
*/

int AYInit(int rate, int bufsiz, byte *userbuffer )
{
  AYSoundRate = rate;
  AYBufSize = bufsiz;
  AYPSG.Buf = userbuffer;
  //AYResetChip();
  return 0;
}

void AYSetBufSize(int bufsiz)
{
	AYBufSize = bufsiz;
}

void AYResetChip(void)
{
  int i;
  AY8910 *PSG = &AYPSG;

  memset(PSG->Buf,0,AYBufSize);

  for(i=0;i<14;i++)
  	PSG->Regs[i]=0;

  //PSG->Regs[AY_ENABLE] = 077;
  //PSG->Regs[AY_AVOL] = 8;
  //PSG->Regs[AY_BVOL] = 8;
  //PSG->Regs[AY_CVOL] = 8;
  PSG->NoiseGen = 1;
  PSG->Envelope = 15;
  PSG->StateNoise = 0;
  PSG->Incr0 = PSG->Incr1 = PSG->Incr2 = PSG->Increnv = PSG->Incrnoise = 0;
}

byte _AYEnvForms[16][32] = {
	{ 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
	{ 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
	{ 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
	{ 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
	{  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
	{  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
	{  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
	{  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
	{ 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0,
	  15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0 },
	{ 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 },
	{ 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0,
	   0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15 },
	{ 15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0,
	  15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15 },
	{  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
	   0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15 },
	{  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
	  15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15 },
	{  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
	  15, 14, 13, 12, 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0 },
	{  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
	   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 }
};

void AYWriteReg(int r, int v)
{
  AY8910 *PSG = &AYPSG;

  PSG->Regs[r] = v;
		
  switch (r) {
		case AY_AVOL :
		case AY_BVOL :
		case AY_CVOL :
	    PSG->Regs[r] &= 0x1F;	/* mask volume */
	    break;
		case AY_EFINE:
		case AY_ECOARSE:	    
	    /* fall through */
		case AY_ESHAPE:
			PSG->Countenv=0;
	    PSG->Regs[AY_ESHAPE] &= 0xF;
	    break;
  }
}

byte AYReadReg(int r)
{
  return AYPSG.Regs[r];
}

void AYSetBuffer(byte *buf)
{
  AYPSG.Buf = buf;
}

AY8910 *AYPSGptr(void)
{
	return &AYPSG;
}

byte *AYBuffer()
{
	return AYPSG.Buf;
}

void AYUpdate(void)
{
  AY8910 *PSG = &AYPSG;
  int v=0, i, x;
  int c0, c1, l0, l1, l2;
    
  x = (PSG->Regs[AY_AFINE]+((unsigned)(PSG->Regs[AY_ACOARSE]&0xF)<<8));
  PSG->Incr0 = x ? AY8910_CLOCK / AYSoundRate * 4 / x : 0;

  x = (PSG->Regs[AY_BFINE]+((unsigned)(PSG->Regs[AY_BCOARSE]&0xF)<<8));
  PSG->Incr1 = x ? AY8910_CLOCK / AYSoundRate * 4 / x : 0;

  x = (PSG->Regs[AY_CFINE]+((unsigned)(PSG->Regs[AY_CCOARSE]&0xF)<<8));
  PSG->Incr2 = x ? AY8910_CLOCK / AYSoundRate * 4 / x : 0;

  x = PSG->Regs[AY_NOISEPER]&0x1F;
  PSG->Incrnoise = AY8910_CLOCK / AYSoundRate * 4 / ( x ? x : 1 );

  x = (PSG->Regs[AY_EFINE]+((unsigned)PSG->Regs[AY_ECOARSE]<<8));
  PSG->Increnv = x ? AY8910_CLOCK / AYSoundRate * 4 / x * AYBufSize : 0;
	  
  PSG->Envelope = _AYEnvForms[PSG->Regs[AY_ESHAPE]][(PSG->Countenv>>16)&0x1F];

  if ((PSG->Countenv+=PSG->Increnv)&0xFFE00000)
  {
    switch( PSG->Regs[AY_ESHAPE] )
    {
	    case  8 :
	    case 10 :
	    case 12 :
	    case 14 :
	      PSG->Countenv -= 0x200000;
	      break;
	    default:
	      PSG->Countenv = 0x100000;
	      PSG->Increnv = 0;
		}
  }
	
  PSG->Vol0 = (PSG->Regs[AY_AVOL]<16)?PSG->Regs[AY_AVOL]:PSG->Envelope;
  PSG->Vol1 = (PSG->Regs[AY_BVOL]<16)?PSG->Regs[AY_BVOL]:PSG->Envelope;
  PSG->Vol2 = (PSG->Regs[AY_CVOL]<16)?PSG->Regs[AY_CVOL]:PSG->Envelope;
	
  PSG->Volnoise = (
		((PSG->Regs[AY_ENABLE]&010)?0:PSG->Vol0)+
		((PSG->Regs[AY_ENABLE]&020)?0:PSG->Vol1)+
		((PSG->Regs[AY_ENABLE]&040)?0:PSG->Vol2))/2;
	
  PSG->Vol0=(PSG->Regs[AY_ENABLE]&001)?0:PSG->Vol0;
  PSG->Vol1=(PSG->Regs[AY_ENABLE]&002)?0:PSG->Vol1;
  PSG->Vol2=(PSG->Regs[AY_ENABLE]&004)?0:PSG->Vol2;
		    
  for(i=0;i<AYBufSize;i++)
  {
	
    	/*
	** These strange tricks are needed for getting rid
	** of nasty interferences between sampling frequency
	** and "rectangular sound" (which is also the output
	** of real AY-3-8910) we produce.
	*/
	
		c0 = PSG->Counter0;
		c1 = PSG->Counter0 + PSG->Incr0;
		l0 = ((c0&0x8000)?-16:16);
		if ((c0^c1)&0x8000)
	    l0=l0*(0x8000-(c0&0x7FFF)-(c1&0x7FFF))/PSG->Incr0;
		PSG->Counter0 = c1 & 0xFFFF;
			    
		c0 = PSG->Counter1;
		c1 = PSG->Counter1 + PSG->Incr1;
		l1 = ((c0&0x8000)?-16:16);
		if ((c0^c1)&0x8000)
		  l1=l1*(0x8000-(c0&0x7FFF)-(c1&0x7FFF))/PSG->Incr1;
		PSG->Counter1 = c1 & 0xFFFF;
			    
		c0 = PSG->Counter2;
		c1 = PSG->Counter2 + PSG->Incr2;
		l2 = ((c0&0x8000)?-16:16);
		if ((c0^c1)&0x8000)
		  l2=l2*(0x8000-(c0&0x7FFF)-(c1&0x7FFF))/PSG->Incr2;
		PSG->Counter2 = c1 & 0xFFFF;
			    
		PSG->Countnoise &= 0xFFFF;
		if ((PSG->Countnoise += PSG->Incrnoise ) & 0xFFFF0000 )
	    /*
	    ** The following code is a random bit generator :)
	    */
	    PSG->StateNoise =
	      ((PSG->NoiseGen<<=1)&0x80000000?
	      	PSG->NoiseGen^=0x00040001:PSG->NoiseGen)&1;
	
		PSG->Buf[i] = AUDIO_CONV (
      (l0*PSG->Vol0+l1*PSG->Vol1+l2*PSG->Vol2)/6+
	    	(PSG->StateNoise?PSG->Volnoise:-PSG->Volnoise));
  }
}

/*
** Change Log
** ----------
** $Log:$
*/
