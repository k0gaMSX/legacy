/* popen.c	pipes implemetation
 */
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <paths.h>
#include <sys/wait.h>

FILE *popen(command, rw)
	char *command;
	char *rw;
{
	int pipe_fd[2];	/* 0=reading, 1=writing */
	int pid, reading, notreading;
	static char *argv[4] = { "sh", "-c", 0, 0 };

	if (pipe(pipe_fd) < 0)
		return NULL;
	reading = (rw[0] == 'r');	/* 0 or 1 only! */
	notreading = !reading;		/* 1 or 0 */
	if ((pid = fork()) < 0) {
		close(pipe_fd[0]);
		close(pipe_fd[1]);
		return NULL;
	}
	if (pid == 0) { 	/* child */
		close(pipe_fd[notreading]);
		close(reading); 	/* 0/1 -- stdin/stdout */
		if (pipe_fd[reading] != reading) {
			dup2(pipe_fd[reading], reading);
			close(pipe_fd[reading]);
		}
		argv[2] = command;
		execve(_PATH_BSHELL, argv, environ);
		abort();
	}
	/* parent */
	close(pipe_fd[reading]);
	return fdopen(pipe_fd[notreading], rw);
}

int pclose(fd)
	FILE *fd;
{
	int waitstat;

	if (fclose(fd) != 0)
		return EOF;
	wait(&waitstat);
	return waitstat;
}

