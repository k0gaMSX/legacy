
/*
 * Copyright (c) 1993-2000 Tatsuhiko Syoji, Japan . All rights reserved.
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

/* Tatsu original functions */

#include	<stdio.h>
#include	<glib.h>
#include	<uty.h>

#include	<stdlib.h>
#include	<mem.h>
#include	<alloc.h>

void nrsort(base,nel,width,compar)
char *base;
unsigned int nel;
unsigned int width;
int (*compar)();
{
	unsigned int i,j,l;
	char *buf;

	if ((buf = malloc(width)) == NULL){
		return;
	}

	/* Non recursive sort */
	for (l = 1;l < nel / 9;l = l * 3 + 1)
		;
	for (; l > 0;l /= 3){
		for (i = l;i < nel;i++){
			j = i;
			while (j >= l && ((*compar)((char *)base+(width*(j-l)),(char *)base+(width*j)) == 1) ){
				memcpy(buf,(char *)base+(width*j),width);
				memcpy((char *)base+(width*j),(char *)base+(width*(j-l)),width);
				memcpy((char *)base+(width*(j-l)),buf,width);
				j -= l;
			}
		}
	}
	free(buf);
}
