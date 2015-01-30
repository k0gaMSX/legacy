
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
#include	<alloc.h>
#include	<io.h>

char bloads(str,off)
char *str;
unsigned int off;
{
	int fp;
	unsigned char *buf,*bp;
	unsigned int cnt2,left;
	struct BloadHeader head;

	if ((fp = open(str,O_RDONLY,0x27)) == -1){
		return(1);
	}
	/* Header - check code 0xfe,start addr.,end addr.,run addr. - */

	if ( read(fp,(char *)&head,sizeof(struct BloadHeader)) != sizeof(struct BloadHeader)){
		close(fp);
		return(3);
	}
	if (head.type != 0xfe){
		close(fp);
		return(1);
	}

	if ((buf = malloc(2048)) == NULL){
		close(fp);
		return(2);
	}
	/* Data */
	left = 0;
	cnt2 = head.s_addr;
	setwrt(head.s_addr + off);
	while (cnt2 <= head.e_addr){
		if (left == 0){
			if ((left = read(fp,buf,2048)) == 0){
				close(fp);
				free(buf);
				return(1);
			}
			bp = buf;
		}
		outvdp(*bp);
		left--;
		cnt2++;
		bp++;
	}

	close(fp);
	free(buf);
	return(0);
}

