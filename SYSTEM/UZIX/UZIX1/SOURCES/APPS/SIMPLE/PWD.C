/* pwd.c
 */
#include <unistd.h>
#include <string.h>

void main() {
	char wd[PATHLEN];

	getcwd(wd,PATHLEN-1);
	write(STDOUT_FILENO, wd, strlen(wd));
	write(STDOUT_FILENO, "\n", 1);
}
