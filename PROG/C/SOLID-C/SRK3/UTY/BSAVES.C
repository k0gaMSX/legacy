
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

char bsaves(str,s_adr,e_adr)
char *str;
unsigned int s_adr;
unsigned int e_adr;
{
	int fp;
	char *buf;
	unsigned i,cnt;

	if ((buf = malloc(2048)) == NULL){
		return(1);
	}
	if ((fp = creat(str,0x20)) == -1){
		free(buf);
		return(1);
	}
	*buf = 0xfe;
	/* Header - check code 0xfe,start addr.,end addr.,run addr. - */
	if (write(fp,buf,1) < 1){ 
		close(fp);
		free(buf);
		return(1);
	}
	if (write(fp,(char *)&s_adr,2) < 2){
		close(fp);
		free(buf);
		return(1);
	}
	if (write(fp,(char *)&e_adr,2) < 2){
		close(fp);
		free(buf);
		return(1);
	}
	*buf = 0;
	*(buf+1) = 0;
	if (write(fp,buf,2) < 2){
		close(fp);
		free(buf);
		return(1);
	}
	/* Data */
	cnt = 0;
	setrd(s_adr);
	for (i = s_adr;i <= e_adr;i++){
		*(buf + cnt) = invdp();
		cnt++;
		if (i == e_adr || cnt == 2048){
			if (write(fp,buf,cnt) < (int)cnt){
				close(fp);
				free(buf);
				return(1);
			}
			cnt = 0;
		}
	}
	close(fp);
	free(buf);
	return(0);
}

