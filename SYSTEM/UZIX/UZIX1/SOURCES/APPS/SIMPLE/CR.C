/*
 *   cr.c  --  add cr's for cp/m editors 
 *
 *   syntax:
 *        cr file ...
 */

#include <stdio.h>
#include <unistd.h>

main(argc,argv)
int argc;
char **argv;
{
	register char c;
	FILE	*in,*out;
	unsigned int j;
	char *s;

	if (argc < 2) {
		fprintf(stderr,"usage: %s file ...\n",argv[0]);
		exit(1);
	}
	for (j = 1; j <argc ; ++j)
  	{
		if ( (in=fopen(argv[j],"rb"))==NULL) {
			perror(argv[j]);
			exit(1);
		}
		s = tmpnam(NULL);
		if ((out = fopen(s,"wb")) == NULL) {
			perror("Can't create temporary file");
			exit(1);
		}
		while ((c=fgetc(in)) != EOF) {
			if (c=='\n') fputc ('\r',out);
			fputc(c,out);
		}
		fclose(in);
		fclose(out);
		if (unlink(argv[j]) == -1) {
			perror(argv[j]);
			exit(1);
		}
		if (rename(s, argv[j]) == -1) {
			perror(s);
			exit(1);
		}
   	}
}