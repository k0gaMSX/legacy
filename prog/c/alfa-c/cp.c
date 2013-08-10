/*
	CP.C	v2.0
	Written by Leor Zolman, 3/82, 7/83

	CP copies files to and from different drives and user areas on
	a CP/M filesystem.

	Compilation and Linkage:
		cc cp.c
		clink cp wildexp -n

	Usage:

		A>cp <filename> <newname> [options] <cr>
		A>cp <list_of_files> { <user#/> or <d:> or <.> } [options] <cr>

	Options:
		-V	Verify by reading after writing
		-B	Backup: delete original after copying
		-L	List files to copy, ask to make sure
		-S	System (invisible) files included in afn expansions

	Wildcard expansion is performed only on files present in the
	currently logged drive and user area (the "current directory").

	Any filename may contain an optional disk designator prefix of
	the form <d:> and/or a user area number prefix of the form <n/>
	preceding the actual name. If both must be given, the user area
	prefix must come first.

	When a single file is to be copied, simply give the old and new
	filenames.

	When multiple files are to be copied, the destination parameter
	must consist of either a disk designator and/or user area pathname,
	or the single character "." when the destination is the CURRENT
	drive and user area. Such a destination designation is also allowed
	when only a single file is being copied.

	For example, to copy *.COM from the current directory into user
	area 0 of drive C:
		cp  *.com  0/C:

	To copy FOO.C from user area 4 into the current user area:
		cp 4/foo.c .

*/

#include <bdscio.h>

main(argc,argv)
char **argv;
{
	int i,j,k,c,loop;
	int fd1,fd2;
	int bufsects;
	unsigned bufsize;
	unsigned corebuf;
	char cur_disk;			/* currently logged-in disk */
	char destname[30];
	char *lastarg;
	char verify, *vbuf;		/* true when verifying writes */
	char backupf, listflag, sysflag;

	backupf = listflag = verify = sysflag = FALSE;
	
	for (i = 1; i < argc; i++)	/* Set sysflag true if -S specified */
		if (argv[i][0] == '-' && argv[i][1] == 'S')
			sysflag++;

	wildexp(&argc, &argv, sysflag);

	cur_disk = 'A' + bdos(25);

	i = 1;
	while (i < argc)
	{
		if (*argv[i] == '-')
		{
			switch(argv[i][1])
			{
				case 'V':
					verify = TRUE;
					break;
				case 'B':
					backupf = TRUE;
					break;
				case 'L':
					listflag = TRUE;
					break;
				case 'S':
					break;
				default:
					printf("Unrecognized option: %s\n",
								argv[i]);
					goto usages;
			}
			argc--;
			for (j = i; j < argc; j++)
				argv[j] = argv[j+1];
		}
		else
			i++;
	}

	lastarg = argv[argc - 1];

	if (argc < 3 || (argc > 3 &&
	    !((c = lastarg[strlen(lastarg)-1]) == '/' || c == ':' ||
					!strcmp(lastarg,"."))))
	{
usages:        printf("Usages: cp [u/][d:]filename [u/][d:]newname [-vbls]\n");
		printf("        cp <list_of_files>  ");
			printf("{ <u/> or <d:> or <u/d:> or <.>} [-vb]\n");
		exit();
	}

	if (listflag)
	{
		for (i = 1; i < argc - 1; i++)
		{
			if (!((i-1) % 5)) putchar('\n');
			printf("%-15s",argv[i]);
		}
		puts("\nType space or <CR> to copy, anything else to abort: ");
		if ((c = getchar()) != ' ' && c != '\n')
			exit();
	}

	if (verify)
		vbuf =  sbrk(SECSIZ);

	corebuf = sbrk(SECSIZ);
	for (bufsize = SECSIZ; sbrk(SECSIZ) != ERROR; bufsize += SECSIZ)
		;
	bufsects = bufsize / SECSIZ;


   for (loop = 1; loop < argc-1; loop++)
   {
	if ((fd1 = open(argv[loop],0)) == ERROR) {
		printf("\nCan't open %s\n",argv[loop]);
		continue;	/* go on to next one anyway. */
	}

	strcpy(destname,lastarg);	/* create output filename */

	if ( (c = destname[strlen(destname) - 1])=='/' || c == ':' ||
		  				!strcmp(destname,"."))
	{
		if (!strcmp(destname,"."))
			*destname = '\0';
		for (i = strlen(argv[loop]) - 1; i >= 0; i--)
		{
			if (argv[loop][i] == '/' && isdigit(argv[loop][i-1]))
				break;
			if (argv[loop][i] == ':')
				break;				
		}
		strcat(destname,&argv[loop][i+1]);
	}

	if ((fd2 = creat(destname)) == ERROR) {
	  	printf("\nCan't create %s\n",destname);
		printf("Assuming out of directory space and aborting.\n");
		exit();	
	}

	if (loop != 1)
		putchar('\n');

	printf("\t copying %s to %s...",argv[loop],destname);

	while (1)
	{
		if (kbhit()) getchar();
		if (!(i = read(fd1,corebuf,bufsects))) break;
		if (i == ERROR)
		{
		    printf("\nRead error: tell(fd1) = %d, \"%s\"\n",
						tell(fd1), errmsg(errno()));
		    break;
		}

		if (kbhit()) getchar();
		if (write(fd2,corebuf,i) != i) {
			printf("\nWrite error: %s\n",errmsg(errno()));
			exit();
		}
		if (verify)
		{	
			puts("[v] ");
			seek(fd2, -i, 1);
			for (j = 0, k = corebuf; j < i; j++, k += SECSIZ)
			{
				if (read(fd2, vbuf, 1) != 1)
				{
					printf("\nVerify read error on %s\n",
						destname);
					break;
				}
				if (memcmp(vbuf, k, SECSIZ))
					continue;
				else
					printf("\nVerify error on %s\n",
						destname);
			}
		}
	}

	if (close(fd2) == ERROR) {
		printf("\nCan't close the output file.\n");;
		exit();
	}
	fabort(fd1);
	if (backupf)
		unlink(argv[loop]);
   }
}
