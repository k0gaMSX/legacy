#include	<stdio.h>
#include	<io.h>
#include	<stdlib.h>
#include	<alloc.h>
#include	<msxbios.h>
#include	<ctype.h>
#include	"e:kinrou.h"

void inton();
void intoff();
extern unsigned char kinint;

int main(argc,argv)
int argc;
char *argv[];
{
	char *buf;
	int fp;
	unsigned int c,v;
	char s,pf;

	if (argc < 2){
		exit(1);
	}

	if ( (buf = malloc(8192)) == NULL){
		exit(1);
	}
	printf("Music data buffer:%4X\n",buf);
	
	if ((fp = open("KINROU5.DRV",0)) == -1){
		free(buf);
		exit(1);
	}
	if (read(fp,(unsigned char *)0x5ff9,0x2007) == 0){
		free(buf);
		close(fp);
		exit(1);
	}
	close(fp);

	fprintf(stderr,"Driver load OK !\n");

	if ((fp = open(argv[1],0)) == -1){
		free(buf);
		exit(1);
	}

	if (read(fp,buf,8192) == 0){
		close(fp);
		exit(1);
	}
	close(fp);
	fprintf(stderr,"Music file load OK !\n");
	kinrou_init(); /* これを行わないと音源検索が行われず、PSGしか鳴らない。 */

	kinint = 0;
	inton();

	if (kinrou_play2(buf,0)){
		fprintf(stderr,"Setup error.\n");
		intoff();
		free(buf);
		exit(1);
	}
	kinint = 1;

	do{
		kilbuf();

		c = chget(); /* 連続して、演奏速度指定をすると、反応が重くなる? */
		c = toupper(c);
		switch(c){
			case 'P':
				kinrou_play2(buf,0);
				kinint = 1;
				pf = 1;
			break;
			case 'S':
				kinrou_pause();
			break;

			case 'F':
				kinrou_fadeout((char)16);
				kinint = 0;
			break;
			case 'V':
				v++;
				if (v > 15){
					v = 0;
				}
				kinrou_vol(v);
			break;
		}
	}while(c != 'Q');
	kinrou_stop();
	kinint = 0;

	intoff();
 	free(buf);

	return(0);

}
