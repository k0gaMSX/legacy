/*
	TEST.C
*/

main()
{
	char x;

	x = 0;

	while (x != '\n')
		{
		printf("FUNCTION MAIN\N");

		x = getchar();
		printf("\n");

		switch(x)
			{
			case 'a':
			      funca();
			      break;

			case 'b':
			      funcb();
			      break;

			case '\n':
			      break;

			default:
			      break;
			}
		}
}

funca()
{
	printf("FUNCTION A\n");
}

funcb()
{
	printf("FUNCTION B\n");

	char c;
	int i, m;

	c = getchar();

		if (c == '+')
			{
			m = 2;

			for (i = 0; i < 10; i++)
			    {
			    m = m + m;
			    }
			    printf("\n%d\n", m);
			}

		else if (c == '-')
		     {
		     m = -2;

		     for (i = 0; i < 10; i++)
			 {
			 m = m + m;
			 }
			 printf("\n%d\n", m);
		     }
}

