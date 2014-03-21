#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
	char *s = "\n\aSystem is going to reboot NOW!\a\n";
	
	write(fileno(stdin), s, strlen(s));
	sync();
	sleep(3);
	sync();
	sync();
	if (reboot('m','e')) {
		perror("reboot");
		return (errno);
	}
}

