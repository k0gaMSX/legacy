/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * The "dd" built-in command.
 */
#include "sash.h"

#ifdef CMD_DD

#define PAR_NONE	0
#define PAR_IF		1
#define PAR_OF		2
#define PAR_BS		3
#define PAR_COUNT	4
#define PAR_SEEK	5
#define PAR_SKIP	6

typedef struct {
	char   *name;
	int	value;
} PARAM;

static PARAM params[] = {
	"if", 	PAR_IF,
	"of", 	PAR_OF,
	"bs", 	PAR_BS,
	"count",PAR_COUNT,
	"seek", PAR_SEEK,
	"skip", PAR_SKIP,
	NULL, 	PAR_NONE
};

static long getnum __P((char *));

/*
 * Read a number with a possible multiplier.
 * Returns -1 if the number format is illegal.
 */
static long getnum(cp)
	char *cp;
{
	long value;
	
	if (!isdecimal(*cp))
		return -1;
	for (value = 0; isdecimal(*cp); ++cp) {
		value *= 10;
		value += *cp - '0';
	}
	switch (*cp++) {
	case 'm': case 'M':	value <<= 20; break;
	case 'k': case 'K':	value <<= 10; break;
	case 'b': case 'B':	value <<= 9; break;
	case 'w': case 'W':	value <<= 1; break;
	case '\0':
		return value;
	default:
		return -1;
	}
	if (*cp)
		return -1;
	return value;
}

void do_dd(argc, argv)
	int argc;
	char **argv;
{
	PARAM  *par;
	int blocksize;
	int infd, outfd;
	int incc, outcc;
	char *buf, *str, *cp, *infile, *outfile;
	long count, seekval, skipval, intotal, outtotal;
	char localbuf[1024];
	
	infile = outfile = NULL;
	seekval = skipval = 0;
	blocksize = BUFSIZ;
	count = 0x7fffffffL;	/* ??? not used */

	while (--argc > 0) {
		str = *++argv;
		if ((cp = strchr(str, '=')) == NULL) {
			fprintf(stderr, "Bad dd argument\n");
			return;
		}
		*cp++ = '\0';	/* remove '=' */
		for (par = params; par->name; par++) {
			if (strcmp(str, par->name) == 0)
				break;
		}
		switch (par->value) {
		case PAR_IF:
			if (infile) {
				fprintf(stderr, "Multiple input files are illegal\n");
				return;
			}
			infile = cp;
			break;

		case PAR_OF:
			if (outfile) {
				fprintf(stderr, "Multiple output files are illegal\n");
				return;
			}
			outfile = cp;
			break;

		case PAR_BS:
			if ((blocksize = (int)getnum(cp)) <= 0) {
				fprintf(stderr, "Bad block size value %s\n", cp);
				return;
			}
			break;

		case PAR_COUNT:
			if ((count = getnum(cp)) < 0) {
				fprintf(stderr, "Bad count value %s\n", cp);
				return;
			}
			break;

		case PAR_SEEK:
			if ((seekval = getnum(cp)) < 0) {
				fprintf(stderr, "Bad seek value %s\n", cp);
				return;
			}
			break;

		case PAR_SKIP:
			if ((skipval = getnum(cp)) < 0) {
				fprintf(stderr, "Bad skip value %s\n", cp);
				return;
			}
			break;

		default:
			fprintf(stderr, "Unknown dd parameter %s=%s\n",str,cp);
			return;
		}
	}
	if (infile == NULL) {
		fprintf(stderr, "No input file specified\n");
		return;
	}
	if (outfile == NULL) {
		fprintf(stderr, "No output file specified\n");
		return;
	}
	buf = localbuf;
	if (blocksize > sizeof(localbuf)) {
		if ((buf = malloc(blocksize)) == NULL) {
			fprintf(stderr, "Can't allocate buffer\n");
			return;
		}
	}
	intotal = outtotal = 0;
	if ((infd = open(infile, 0)) < 0) {
		perror(infile);
		if (buf != localbuf)
			free(buf);
		return;
	}
	if ((outfd = creat(outfile, 0666)) < 0) {
		perror(outfile);
		close(infd);
		if (buf != localbuf)
			free(buf);
		return;
	}
	if (skipval) {
		if (lseek(infd, skipval * blocksize, 0) < 0) {
			while (skipval-- > 0) {
				if ((incc = read(infd, buf, blocksize)) < 0) {
					perror(infile);
					goto cleanup;
				}
				if (incc == 0) {
					fprintf(stderr, "End of file while skipping\n");
					goto cleanup;
				}
			}
		}
	}
	if (seekval) {
		if (lseek(outfd, seekval * blocksize, 0) < 0) {
			perror(outfile);
			goto cleanup;
		}
	}
	while ((incc = read(infd, buf, blocksize)) > 0) {
		intotal += incc;
		cp = buf;
		if (intflag) {
			fprintf(stderr, "Interrupted\n");
			goto cleanup;
		}
		while (incc > 0) {
			if ((outcc = write(outfd, cp, incc)) < 0) {
				perror(outfile);
				goto cleanup;
			}
			outtotal += outcc;
			cp += outcc;
			incc -= outcc;
		}
	}
	if (incc < 0)
		perror(infile);

cleanup:
	close(infd);
	if (close(outfd) < 0)
		perror(outfile);
	if (buf != localbuf)
		free(buf);
	printf("%d+%d records in\n", intotal / blocksize,
	       (intotal % blocksize) != 0);
	printf("%d+%d records out\n", outtotal / blocksize,
	       (outtotal % blocksize) != 0);
}
#endif	/* CMD_DD */
