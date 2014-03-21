/*
 * Copyright (c) 1999-2000 Tatsuhiko Syoji, Japan 982-0221. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1 Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer as the first lines
 *  of this file unmodified.
 *
 * 2 Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY Tatsuhiko Syoji ``AS IS'' AND ANY EXPRESS
 * ORIMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED. IN NO EVENT SHALL Tatsuhiko Syoji BE LIABLE FOR ANY DIRECT,
 *  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN
 *  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/* MSX-BIOS function library */
/* By Tatsuhiko Syoji(Tatsu) 1999-2000 */

#ifndef	__MSXBIOS_H
#define	__MSXBIOS_H

#ifndef	_C_TYPES_
#include <types.h>
#endif

/* MSX-C Library compatible function */
void disscr();
void enascr();
void screen();

void gicini();
void sound();
void rdpsg();

BOOL chsns();
void chput();
char chget();

char lptout();
char lptstt();

char *pinlin();
char *inlin();

char breakx();
void beep();
void cls();
void locate();

void inifnk();
void erafnk();
void dspfnk();

char gtstck();
char gttrig();
char gtpad();
char gtpdl();

char chgsnd();
char snsmat();
void kilbuf();

void di();
void ei();

/* MSX Turbo R BIOS function */
void chgcpu();
char getcpu();

/* Special I/O function for FM-TOWNS gamepad */
char gstex();

#endif
