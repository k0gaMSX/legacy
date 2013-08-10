
/*
 *	wumpus
 *	borrowed from PCC Vol 2 No 1
 *	Modified for Alpha-C by Leor Zolman	2/82
 */

#define MAXLINE 135
#define	NBAT	3
#define	NROOM	20
#define	NTUNN	3
#define	NPIT	3

struct Room
{
	int	tunn[NTUNN];
	int	flag;
} room[NROOM];


#define	BAT	01
#define	PIT	02
#define	WUMP	04

int	arrow;
int	loc;
int	wloc;
int	tchar;

main()
{
	register i, j;
	char strbuf[MAXLINE], *cptr;
	register struct Room *p;
	int k, icomp();

	printf("\n\nWelcome to \"Hunt the Wumpus\"!\n");
	srand1("Do you need instructions? ");
	if (tolower(getchar()) == 'y')
		instructs();

/*
 * initialize the room connections
 */

init:
	p = &room[0];
	for(i=0; i<NROOM; i++) {
		for(j=0; j<NTUNN; j++)
			p->tunn[j] = -1;
		p++;
	}
	k = 0;
	for(i=1; i<NROOM; ) {
		j = rnum(NROOM);
		p = &room[j];
		if(j == k || p->tunn[0] >= 0 || p->tunn[1] >= 0)
			continue;
		p->tunn[1] = k;
		room[k].tunn[0] = j;
		k = j;
		i++;
	}
	p = &room[0];
	for(i=0; i<NROOM; i++) {
		for(j=0; j<NTUNN; j++) {
			if(p->tunn[j] < 0)
				p->tunn[j] = tunnel(i);
			if(p->tunn[j] == i)
				goto init;
			for(k=0; k<j; k++)
				if(p->tunn[j] == p->tunn[k])
					goto init;
		}
		qsort(&p->tunn[0], NTUNN, 2, icomp);
		p++;
	}

/*
 * put in player, wumpus,
 * pits and bats
 */

setup:
	arrow = 5;
	p = &room[0];
	for(i=0; i<NROOM; i++) {
		p->flag = 0;
		p++;
	}
	for(i=0; i<NPIT; ) {
		p = &room[rnum(NROOM)];
		if((p->flag&PIT) == 0) {
			p->flag |= PIT;
			i++;
		}
	}
	for(i=0; i<NBAT; ) {
		p = &room[rnum(NROOM)];
		if((p->flag&(PIT|BAT)) == 0) {
			p->flag |= BAT;
			i++;
		}
	}
	i = rnum(NROOM);
	wloc = i;
	room[i].flag |= WUMP;
	for(;;) {
		i = rnum(NROOM);
		if((room[i].flag&(PIT|BAT|WUMP)) == 0) {
			loc = i;
			break;
		}
	}
	putchar('\n');

/*
 *	main loop of the game
 */

loop:
	printf("\nYou are in room %d\n", loc+1);
	p = &room[loc];
	if(p->flag&PIT) {
	   printf("You fell into a pit and broke every bone in your body.\n");
		goto done;
	}
	if(p->flag&WUMP) {
		printf("You were eaten by the wumpus. Yum yum. Belch.\n");
		goto done;
	}
	if(p->flag&BAT) {
	   printf("Theres a bat in your room...it picks you up, up, up...\n");
		loc = rnum(NROOM);
		goto loop;
	}
	for(i=0; i<NTUNN; i++)
	if(near(&room[p->tunn[i]], WUMP))
		goto nearwump;
	if (near(p, WUMP)) {
	nearwump:
		printf("I smell a wumpus\n");
	}
	if (near(p, BAT))
		printf("Bats nearby\n");
	if (near(p, PIT))
		printf("I feel a draft\n");

again:
	printf("There are tunnels to");
	for(i=0; i<NTUNN; i++)
		printf(" %d", p->tunn[i]+1);
	printf("\n");

	printf("Move or shoot (m-s) ?");
	gets(strbuf);

	for (i = 0; strbuf[i]; i++) {
		strbuf[i] = tolower(strbuf[i]);
		if (strbuf[i] == ',') strbuf[i] = ' ';
	}

	for (i = 0; isspace(strbuf[i]); i++)
		;

	if (strbuf[i] == 'm') {
		i++;
		if (!isdigit(ignore_s(&strbuf[i]))) {
			printf("Move to which room? ");
			gets(strbuf);
			if (!isdigit(ignore_s(strbuf))) {
				printf("I don't understand, so I'll ");
				printf("leave you where you were.\n");
				goto again;
			}
			i = atoi(strbuf) - 1;
		}
		else i = atoi(&strbuf[i]) - 1;
			for(j=0; j<NTUNN; j++)
			if(i == p->tunn[j])
				goto groom;
		printf("You hit the wall\n");
		goto again;
	groom:
		loc = i;
		if(i == wloc)
			goto mwump;
		goto loop;
	}

	if (strbuf[i] != 's') {
		printf("I don't understand that.\n");
		goto again;
	}

	cptr = &strbuf[i + 1];
	
	if (!isdigit(ignore_s(cptr))) {
		printf("Type a list of up to five rooms to shoot through: ");
		gets(strbuf);
		if (!isdigit(ignore_s(strbuf))) {
			printf("I don't understand, so I assume you don't ");
			printf("want to shoot.\n");
			goto again;
		}
		cptr = strbuf;
	}

	for(i=0; i<5; i++) {
		if (!isdigit(ignore_s(cptr)))
			break;
		j = atoi(cptr) - 1;
		if (j == -1)
			break;
		while (isspace(*cptr)) cptr++;
		while (isdigit(*cptr)) cptr++;

	ranarw:
		for(k=0; k<NTUNN; k++)
			if(j == p->tunn[k])
				goto garow;
		j = rnum(NROOM);
		goto ranarw;
	garow:
		p = &room[j];
		if(j == loc) {
			printf("You shot yourself. You lose.\n");
			goto done;
		}
		if(p->flag&WUMP) {
			printf("\7You slew the wumpus!\n");
			goto done;
		}
	}
	if(--arrow == 0) {
		printf("That was your last shot...you lose.\n");
		goto done;
	}
	goto mwump;

mwump:
	p = &room[wloc];
	p->flag &= ~WUMP;
	i = rnum(NTUNN+1);
	if(i != NTUNN)
		wloc = p->tunn[i];
	room[wloc].flag |= WUMP;
	goto loop;

done:
	printf("\n\nAnother game? (y-n) ");
	if(tolower(getchar()) == 'y') {
		printf("\nSame room setup? (y-n) ");
		if(tolower(getchar()) == 'y')
			goto setup;
		goto init;
	}
}

char ignore_s(s)
char *s;
{
	while (isspace(*s)) s++;
	return *s;
}
	
tunnel(i)
{
	register struct Room *p;
	register n, j;
	int c;

	c = 20;

loop:
	n = rnum(NROOM);
	if(n == i)
		if(--c > 0)
			goto loop;
	p = &room[n];
	for(j=0; j<NTUNN; j++)
	if(p->tunn[j] == -1) {
		p->tunn[j] = i;
		return(n);
	}
	goto loop;
}

rnum(n)
{
	rand() % n;
}

near(ap, ahaz)
struct Room *ap;
{
	register struct Room *p;
	register haz, i;

	p = ap;
	haz = ahaz;
	for(i=0; i<NTUNN; i++)
	if(room[p->tunn[i]].flag & haz)
		return (1);
	return(0);
}

icomp(p1, p2)
int *p1, *p2;
{

	return(*p1 - *p2);
}

instructs()
{
	printf("\n");
	printf("Welcome to 'Hunt the Wumpus.'\n");
	printf("\n");
	printf("The Wumpus lives in a cave of %d rooms.\n",NROOM);
	printf("Each room has %d tunnels leading to other rooms.\n",NTUNN);
	printf("\n");
	printf("Hazards:\n");
	printf("\n");
	printf("Bottomless Pits - Some rooms have Bottomless Pits in them.\n");
	printf("	If you go there, you fall into the pit and lose!\n");
	printf("Super Bats - Some other rooms have super bats.\n");
	printf("	If you go there, a bat will grab you and take you\n");
	printf("	to somewhere else in the cave where you could\n");
	printf("	fall into a pit or run into the . . .\n");

	printf("\n(Hit any character to continue) "); getchar();

	printf("\n\n. . .Wumpus:\n");
	printf("\n");
	printf("The Wumpus is not bothered by the hazards since\n");
	printf("he has sucker feet and is too big for a bat to lift.\n");
	printf("\n");
	printf("Usually he is asleep.\n");
	printf("Two things wake him up:\n");
	printf("	your entering his room\n");
	printf("	your shooting an arrow anywhere in the cave.\n");
	printf("If the wumpus wakes, he either decides to move one room or\n");
	printf("stay where he was.  But if he ends up where you are,\n");
	printf("he eats you up and you lose!\n");
	printf("You:\n");
	printf("\n");
	printf("Each turn you may either move or shoot a crooked arrow.\n");
	printf("\n");
	printf("Moving - You can move to one of the adjoining rooms;\n");
	printf("	that is, to one that has a tunnel connecting it\n");
	printf("	with the room you are in.\n");

	printf("\n(Hit any character to continue) "); getchar();
	printf("\n\n");
	printf("Shooting - You have 5 arrows.  You lose when you run out.\n");
	printf("	Each arrow can go from 1 to 5 rooms.\n");
	printf("	You aim by giving a list of room numbers\n");
	printf("	telling the arrow which rooms to go through.\n");
	printf("	The first room in the path must be connected to \n");
	printf("	the room you are in.  Each succeeding room must be\n");
	printf("	connected to the previous room.\n");
	printf("	If there is no tunnel between two of the rooms\n");
	printf("	in the arrow's path, the arrow chooses one of the\n");
	printf("	three tunnels from the room it's in and goes its\n");
	printf("	own way.\n");
	printf("\n");
	printf("	If the arrow hits the wumpus, you win!\n");
	printf("	If the arrow hits you, you lose!\n");

	printf("\n(Hit any character to continue) "); getchar();

	printf("\n\nWarnings:\n");
	printf("\n");
	printf("When you are one or two rooms away from the wumpus,\n");
	printf("the computer says:\n");
	printf("		'I smell a Wumpus'\n");
	printf("When you are one room away from some other hazard, it says:");
	printf("\n		Bat    - 'Bats nearby'\n");
	printf("		Pit    - 'I feel a draft'\n");
	printf("\n");
	printf("Giving commands:\n");
	printf("	When asked to move or shoot by typing 'm' or 's',\n");
	printf("	you can give the required room number(s) on the\n");
	printf("	same line. If you don't,  the computer will ask\n");
	printf("	you for them on the next line.\n\n");
	printf("G O O D   L U C K   !!!!!!\n");
}

