/*
	TELED.C		v1.4	<4 Mar 83>

	Files of this program: TELEDIT.H, TELED.C, TELMDM7.C, TELEDTR.C

	Alpha-C version, 10/82, 2/83

	A telecommunications program using Ward Christensen's
	"MODEM" File Transfer Protocol.

 	Modified by Nigel Harrison and Leor Zolman from XMODEM.C,
	which was written by:  Jack M. Wierda,
               modified by Roderick W. Hart and William D. Earnest

	Added "CRC" file transfer protocol and cancelation via Control-X
	during file xfers. <Stefan Badstuebner	4 Mar 83>

	Compilation & linkage:
		cc teled.c
		cc telmdm7.c
		cc teledtr.c
		l teled telmdm7 teledtr -n -s

	TELEDIT.H contains some user-configurable options. For example,	
	the "edit" function may be left out by setting an appropriate
	#define.

	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	*  Note that the Modem port interfaces are defined in HARDWARE.H, *
	*  which must be configured with the right values for your system *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	TELED now distinguishes between several different modes of
	operation: "terminal" mode (full duplex), "host" mode, and 
	"half-duplex" mode, as follows (designed by Stefan Badstuebner):
	----------------------------------------------------------------
	TERMINAL MODE:		keyboard(char) ---> MoDem

				MoDem(char)    ---> CRT
	----------------------------------------------------------------
	ECHO (HOST) MODE:	keyboard(char) ---> MoDem
						`---> CRT
			If (char == CR).... LF ---> MoDem
						`---> CRT

				MoDem(char)    ---> CRT
						`---> MoDem
			If (char == CR).... LF ---> CRT
						`---> MoDem
	----------------------------------------------------------------
	1/2 DUPLEX MODE:	keyboard(char) ---> MoDem
						`---> CRT
			If (char == CR).... LF ---> CRT

				MoDem(char)    ---> CRT
	----------------------------------------------------------------
*/

#include <bdscio.h>
#include <hardware.h>
#include "teledit.H"


int kbhit()	/* test for console character available: */
{
	return bios(2);
}

int getch()	/* get char from console raw, no echo */
{
	while (!kbhit());
	return bios(3) & 0x7f;
}

int getchar()	/* get console char with echo, expand CR to CRLF locally: */
{
	char c;

	putchar(c = getch());
	if (c == '\r')
		putchar('\n');	
	return c;
}

putchar(c)	/* write char to console, expand LF to CRLF: */
{
	if (c == '\n') putchar('\r'); 
	bios(4,c);
}

send(data)	/* send char to modem */
char data;
{
	while(!MOD_TBE)
		;
	MOD_TDATA(data);
}

main(argc,argv)
char **argv;
{
	int i, j, k, l;			/* scratch integers */
	char *lineptr[ML];		/* allow ML source lines */
	char *inl[ML];			/* inserted line pointers */
	char *p;			/* scratch pointer */
	char buf[BUFSIZ];		/* i/o buffer	*/
	int  in;			/* collect characters at in */
	char *alloc();			/* storage allocator */
	char *getm();			/* memory procuror */
	int baudrate;
	int menu_flag;

	_allocp = NULL;			/* initialize alligator */

	linect = nlines = i = 0;
	fflg = hostflg = halfdup = FALSE;
	lineptr[i] = NULL;

	baudrate = 0;			/* unknown baud rate */
	menu_flag = TRUE;

   while(1)
   {
	if (menu_flag)
	{  puts(CLEARS);
	   printf("Teledit ver 1.4   <4 Mar 83>\n\n");

	   printf("T: Terminal mode - no text collection\n");
	   printf("X: terminal mode with teXt collection\n");
	   printf("\tIn terminal mode:\n");
	   printf("\t\tSPECIAL (control-^): return to menu\n");
	   printf("\t\tcontrol-E: enter editor\n");
	   printf("H: toggle Host mode (for user-user typing) (currently: %s)\n",
					hostflg ? "ENABLED" : "disabled");
	   printf("G: toGgle half-duplex system mode (currently: %s duplex)\n",
					halfdup ? "HALF" : "full");
#if EDITOR
	   printf("E: Edit collected text\n");
#endif
	   printf("F: Flush text buffer to text collection file\n");
	   printf("C: flush and Close text collection file\n");
	   printf("M: display Menu\n");
	   printf("U: select cp/m User area\n");
	   printf("V: select cp/m driVe\n");
	   printf("D: print Directory for current drive and user area\n");
	   printf("S: Send a file, MODEM protocol\n");
	   printf("R: Receive a file, MODEM protocol\n");   
	   printf("B: select Baud rate (currently ");
		   if (baudrate)
			printf("running at %d baud",baudrate);
		   else
			printf("unchanged from last usage");
		   puts(")\n");

	   printf("Q: quit\n");
	   printf("SPECIAL: send SPECIAL char to modem\n");
	}
	menu_flag = FALSE;

	printf("\nCommand: ");

	in = toupper(getchar());
	putchar('\n');

     switch(in)
     {
	case 'U':
		printf("Switch to user area: ");
		bdos(32,atoi(gets(linebuf)));
		break;

	case 'V':
		printf("Switch to drive: ");
		bdos(14,toupper(getchar()) - 'A');
		break;

	case 'D':
		dodir();
		goto wait;

	case SPECIAL:
		send(SPECIAL);
		break;

	case 'T':
		terminal();
		break;

	case 'M':
	case '?':
		menu_flag = TRUE;
		break;

	case 'X':
     if (fflg)
	printf("Text collection already in effect (filename '%s')\n", fnambuf);
     else
     {
	puts("Collection text filename = ");
	getname(fnambuf);

	puts("Wait...");
	if (fopen(fnambuf,buf) == ERROR)	/* if it already exists, */
		goto newfile;			/* go create it 	 */
	else					/* else query further	 */
	{
		printf("\nFile already exists; do you want to ");
		if(ask("overwrite it"))
		{
	 newfile:  if (fcreat(fnambuf, buf) == ERROR)   /* Make new version */
		   {
			printf("\nCan't create %s", fnambuf);
			goto wait;
		   }
		}
		else if (ask("Do you want to append to it")) /* append to it */
		{
		   if (fappend(fnambuf,buf) == ERROR)
		   {
			printf("\nCan't append for some reason\n");
			goto wait;
		   }
		}
		else
		{
			printf("File operations aborted.\n");
			goto wait;
		}
	}
	
	fflg = TRUE;
     }
	printf("\nReady\n");

	while(1)
	{	if(MOD_RDA)
		{	putchar (in = MOD_RDATA & 0x7F);
			if (hostflg)
			{
				send(in);
				if (in == '\r')
				{
					send('\n');
					putchar('\n');
				}
			}

			if(in >= ' ')
				linebuf[i++] = in;
			else
			{	if(in == '\n') continue;
				if(in == CR)
				{	linebuf[i++] = '\n';
					linebuf[i] = NULL;
					p = getm(linebuf);
					if(p == NULL) continue;
					lineptr[nlines++] = p;
					lineptr[nlines] = NULL;
					if(nlines > 500) putchar(BELL);
					i = 0;
				}
				else if(in == '\t' || in == '\f')
					linebuf[i++] = in;
				else
					continue;
			}
		}
		if(kbhit())
		{
			in = getch();
			if(in == SPECIAL)
				break;
			else if (in == ('E' & 037))
			{
				ed(lineptr);
				printf("Terminal mode:\n\n");
			}
			else
				send(in);
			if (hostflg || halfdup)
			{
				putchar(in);
				if (in == '\r')
				{
					putchar('\n');
					if (hostflg)
						send('\n');
				}
			}	
		}
	}
	break;

     case 'S':
     case 'R':
	printf("File to %s = ", (in == 'S') ? "send" : "receive");
	getname(linebuf);

	if (setjmp(jump_buf))		/* Allow keyboard cancel */
	{
		close(fd);
		printf("\nCanceled!\n");
		goto send_beep;
	}

	if(in == 'R')
	{
		if (ask("CRC mode"))
		   crc_flag = TRUE;
		else
		   crc_flag = FALSE;

		rcv_file(linebuf);
	}
	else
	{
		if(fopen(linebuf, buf) == ERROR)
		{	printf("Can't open %s\n", linebuf);
			goto wait;
		}
		sendfile(linebuf);
	}

   send_beep:
	putchar(BELL);			/* beep when done */
	break;

     case 'E':
	ed(lineptr);
	break;

     case 'D':
	dump(lineptr, buf);
	goto wait;

     case 'G':
	if (halfdup = !halfdup)
	{
		puts("Going into half duplex mode\n");
		if (hostflg) {
			puts("(HOST mode is being automatically disabled)\n");
			hostflg = FALSE;
		}
		goto wait;
	}
	goto Hterm;

     case 'H':
	if (hostflg = !hostflg)
	{
		puts("Going into HOST (user-user communication) mode\n");
		if (halfdup)
		{
		  puts("(HALF DUPLEX mode is being automatically disabled)\n");
			halfdup = FALSE;
		}
		goto wait;
	}

	Hterm:	puts("Going back to normal terminal mode\n");
		goto wait;

     case 'B':	/**** This section is left for the user to configure ****
		* 1) ask the user what baudrate to switch to,		*
		* 2) set the "baudrate" variable equal the new rate    *
		* 3) actually set the baudrate in whichever way is	*
		*    appropriate to your hardware.			*
		* Note that the "baudrate" variable comes up equal to	*
		* 0 to indicate that no explicit baud rate has been	*
		* selected by the user (i.e., the baudrate is in what-	*
		* ever state it was in before TELED was invoked)	*
		*********************************************************/

	puts("Baudrate selection is left for the user to configure.\n");
	puts("Look for \"case 'B':\" in TELMAIN.C\n");
	goto wait;

     case 'Q':
	if (fflg)
	{
		printf("\nSave file \"%s\" to ",fnambuf);
		if (ask("disk"))
		{	dump(lineptr, buf);
			putc(CPMEOF, buf);
			fclose(buf);
		}
	}
	exit(0);

     case 'C':
	if (fflg)
	{
		printf("Closing %s...",fnambuf);
		dump(lineptr, buf);
		putc(CPMEOF, buf);
		fclose(buf);
		fflg = FALSE;
	}
	else puts("No currently active text collection file\n");

 wait: 	puts("\n\nHit any key to return to menu: ");
	menu_flag = TRUE;
	getchar();
     }
   }
}

dump(lineptr, buf)	/* dump text buffer	*/
char **lineptr, *buf;
{
	int i;

	for(i = 0; lineptr[i] != NULL; i++)
		if(fputs(lineptr[i], buf) == ERROR)
			printf("\n\7Error writing txt, disk full?\n");

	lineptr[0] = linect = nlines = _allocp = 0;
}

dodir()
{
	char dmapos;		/* value returned by search calls */
	char first_time;	/* used in search routine */
	char tmpfn[20];		/* temp filename buffer */
	char fcb[36];
	int colno;		/* column count */
	int i;

	char name[15];
	int drive;
		
	bdos(26,BASE+0x80);	/* ensure default DMA after read/write */
	printf("\nFiles = ");
	if (getline(name,15) < 2)
		setfcb(fcb,"*.*");
	else 
		setfcb(fcb,name);

	drive= (fcb[0]==0 ? bdos(25) : fcb[0]-1 ) ;

	puts(CLEARS);
	printf("Directory for Drive %c, user area %d:\n\n",
			drive+'A', bdos(32,0xff));

	colno = 1;
	first_time = TRUE;
	while (1) {
		dmapos = bdos(first_time ? SEARCH_FIRST : SEARCH_NEXT,fcb);
		if (dmapos == 255) break;
		first_time = FALSE;
		hackname(tmpfn,(BASE + 0x80 + dmapos * 32));
		puts(tmpfn);
		for (i = strlen(tmpfn); i < 15; i++) putchar(' ');
		if ((colno += 15) > 65)
		{
			putchar('\n');
			colno =1;
		}
	}
}


hackname(dest,source)
char *dest, *source;
{
	int i,j;

	j = 0;

	for (i = 1; i < 9; i++)
	{
		if (source[i] == ' ') break;
		dest[j++] = source[i];
	}
	if (source[9] != ' ')
		dest[j++] = '.';

	for (i = 9; i < 12; i++)
	{
		if (source[i] == ' ') break;
		dest[j++] = source[i];
	}
	dest[j] = '\0';
	return dest;
}

char *getname(linbuf)		/* get a reasonable filename from user */
char *linbuf;
{
	int i;
	char c;

	while (1)
	{
		gets(linbuf);
		if (!*linbuf)		/* reject null filename */
			goto reject;
		for (i = 0; c = linbuf[i]; i++)
		{
			if (c < ' ' || c > 0x7F)
				goto reject;
		}
		break;
    reject:	puts("\nFilename = ");
		continue;
	}
	return linbuf;
}


ask(s)
char *s;
{

	char c;

again:	printf("%s (y/n)? ", s);
	c = tolower(getchar());
	if(c == 'y') {
		puts("es\n");
		return 1;
	}

	else if(c == 'n')
		puts("o\n");
	else
	{
		printf("  \7Yes or no, please...\n");
		goto again;
	}
	return 0;
}

terminal()	/* terminal mode, no text */
{
	int in;

	putchar('\n');

	while(1)
	{
		if(MOD_RDA)
		{
			putchar(in = MOD_RDATA);
			if (hostflg)
			{
				send(in);
				if (in == '\r')
				{
					send('\n');
					putchar('\n');
				}
			}
		}			
			
		if(kbhit())
		{
			in = getch();
			if (in == SPECIAL)
				return;
			else
				send(in);

			if (hostflg || halfdup)
			{
				putchar(in);
				if (in == '\r')
				{
					putchar('\n');
					if (hostflg)
						send('\n');
				}
			}
		}
	}
}

char *getm(line)	/* get memory for line, store it, return pointer */
char line[];
{
	char *p, *alloc();

	if ((p = alloc(strlen(line) + 1)) != NULL)
		strcpy(p, line);
	return(p);
}
