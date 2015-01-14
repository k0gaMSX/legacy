

extern char *sys_err[];
extern short sys_ner;

char *
strerror(int err)
{
	if (err < 0 || err > sys_ner)
		err = 0;		/* err == 0 => Unknown error */
	return sys_err[err];
}

