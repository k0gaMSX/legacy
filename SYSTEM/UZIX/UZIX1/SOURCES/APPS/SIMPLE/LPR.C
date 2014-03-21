#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

main(argc,argv)
int argc;
char *argv[];
{
    int lpf;
    int file;
    int cnt;
    char *buf;

    buf = sbrk(BUFSIZ);

    if (argc != 2)
    {
	fprintf(stderr,"usage: lpr file\n");
	exit(1);
    }
    file = open(argv[1],0);
    if (file < 0)
    {
	perror(argv[1]);
	exit(1);
    }
    lpf = open("/dev/lpr",1);
    if (lpf < 0)
    {
	perror("lpr: /dev/lpr");
      	exit(1);
    }

    while ((cnt = read(file,buf,BUFSIZ)) > 0)
	write(lpf,buf,cnt);

    if (cnt == -1)
    {
	perror("lpr: read failed");
        exit(1);
    }

    exit(0);
}
