/*
 *   ncr.c  --  remove cr's for cp/m editors 
 *
 *   syntax:
 *        ncr file ...
 */

#include <stdio.h>
#include <unistd.h>

main(argc,argv)
int argc;
char **argv;
{
	register char c,d;
	FILE	*in,*out;
	unsigned fn,j;
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
		d=fgetc(in);
		
		while ((c=fgetc(in)) != EOF) {
			if (!(d=='\r' && c=='\n')) fputc(d, out);
			d=c;
		}
		fputc(d, out);
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