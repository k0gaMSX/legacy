/* rename.c
 */
#include <stdio.h>
#include <unistd.h>

int rename(oldname, newname)
	char *oldname;
	char *newname;
{
	int error = link(oldname, newname);

	if (error)
		return error;
	return unlink(oldname);
}
