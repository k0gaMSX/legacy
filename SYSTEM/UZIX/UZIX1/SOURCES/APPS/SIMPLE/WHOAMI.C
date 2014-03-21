#include <unistd.h>
#include <string.h>
#include <pwd.h>

void
main (void)
{
	register struct passwd *pw;
	register int uid;
    
	uid = getuid ();
	pw = getpwuid (uid);
	if (pw)
	{
		write(STDOUT_FILENO,pw->pw_name,strlen(pw->pw_name));
		write(STDOUT_FILENO,"\n",1);
		exit (0);
	}
	exit (1);
}
