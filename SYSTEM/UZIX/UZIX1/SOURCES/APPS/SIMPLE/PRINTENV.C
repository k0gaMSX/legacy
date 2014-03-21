/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * Most simple built-in commands are here.
 */

#include <stdio.h>
#include <string.h>

void
main(argc, argv)
	char	**argv;
{
	char		**env;
	extern char	**environ;
	int		len;

	env = environ;

	if (argc == 1) {
		while (*env)
			printf("%s\n", *env++);
		return;
	}

	len = strlen(argv[1]);
	while (*env) {
		if ((strlen(*env) > len) && (env[0][len] == '=') &&
			(memcmp(argv[1], *env, len) == 0))
		{
			printf("%s\n", &env[0][len+1]);
			return;
		}
		env++;
	}
}
