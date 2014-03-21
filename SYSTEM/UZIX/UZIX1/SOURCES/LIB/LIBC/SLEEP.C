/* sleep.c
 */
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>

/* This uses SIGALRM, it does keep the previous alarm call but will lose
 * any alarms that go off during the sleep
 */
static void alrm() { }

unsigned int sleep(seconds)
	unsigned int seconds;
{
	unsigned int prev_sec = alarm(0);
	sig_t last_alarm = signal(SIGALRM, alrm);

	if (prev_sec)
		prev_sec = (prev_sec <= seconds ? 1 : prev_sec - seconds);
	alarm(seconds);
	pause();
	seconds = alarm(prev_sec);
	signal(SIGALRM, last_alarm);
	return seconds;
}

