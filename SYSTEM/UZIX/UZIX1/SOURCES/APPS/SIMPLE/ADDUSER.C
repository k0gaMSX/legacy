/* 
 * adduser.c
 * author:	Adriano Cunha <adrcunha@dcc.unicamp.br>
 * description: add a new user account
 * comments:    heavily based on adduser 1.0 (by Craig Hagan 
 *              <hagan@opine.cs.umass.edu> and modified by Chris Cappuccio 
 *              <chris@slinky.cs.umass.edu>)
 */

/* to do:
 *	 - a better way of adding a new line to passwd (using putpwent)
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <pwd.h>
#include <paths.h>

#define PASSWD_FILE	_PATH_PASSWD
#define DEFAULT_SHELL	_PATH_BSHELL
#define DEFAULT_HOME	_PATH_HOME
#define DEFAULT_GROUP	100
#define FIRST		10	/* First useable UID */
#define DEFAULT_PERMS	0755	/* Perms for the users home directory */

FILE *bull;	/* Bullshit way to find a shadow password file */
int unused_uid,nag;

int find_unused(int begin) {
	int trial;
	struct passwd *pw;

	trial = begin - 1;
        printf("\nChecking for an available UID after %d:\n",FIRST);
	while ((pw = getpwuid(++trial)) != NULL) printf("%d...",trial);
	if (trial!=begin) putchar('\n');
	printf("First unused UID is %d.\n", trial);
	return(trial);
}

void found_shadow() {
	printf("Your system is using shadow password.\n");
	printf("Feature not supported. Program aborted.\n");
	fclose(bull);
	exit(1);
}

void main() {
  char foo[64];
  char uname[9],person[32],passwd[9],dir[32],shell[32],salt[3];
  unsigned int group,uid;
  int bad=0,i,correct=0;
  time_t tm;
  struct passwd *pw;
  FILE *passwd_file;  /* Yep, it's a file allright */

  unused_uid = FIRST;
  if (getuid()!=0) {
     printf("You don't have access to add a new user.\n");
     printf("Only root can add new users to the system.\n");
     exit(1);
  }
  if ((bull=fopen("/etc/shadow","r"))!=NULL) found_shadow();
  if ((bull=fopen("/etc/passwd","r"))==NULL) {
   printf("Fatal error: password file not found.\n");
   exit(1);
  }
  while (!correct) {		/* loop until a "good" uname is chosen */

getlogin:
   printf("\nLogin to add (^C to quit): ");
   fflush(stdout);
   gets(uname);
   if (strlen(uname)>8) {
    printf("The login name must be maximum 8 characters long.\n");
    goto getlogin;
   }
   for (i=0;i<strlen(uname);i++) {
    if (!(((uname[i]>='A') && (uname[i]<='Z')) || 
          ((uname[i]>='a') && (uname[i]<='z')) ||
          ((uname[i]>='0') && (uname[i]<='9')))) {
     printf("Invalid character in login.\n");
     goto getlogin;
    }
   }
   if (nag=getpwnam(uname) != NULL) {
    printf("Login in use. Choose another one.\n");
    goto getlogin;
   }

   putchar('\n');
   unused_uid = find_unused(++unused_uid);
   
   printf("\nEditing information for new user [%s]:\n",uname);
   printf("\nFull name: ");
   fflush(stdout);
   gets(person);
      
   printf("GID [%d]: ",DEFAULT_GROUP);
   fflush(stdout);
   gets(foo);
   group=atoi(foo);
   if (group==0) group=DEFAULT_GROUP;
   
   printf("UID [%d]: ",unused_uid);
   fflush(stdout);
   gets(foo);
   uid=atoi(foo);
   if (uid==0) uid=unused_uid;
   if ((pw=getpwuid(uid))!=NULL) {
        printf("\nWarning: UID [%d] already in use, this would conflict with\n",uid);
        printf("who already owns this user ID. [%s]'s UID has been reset to\n",uname);
        printf("the last unused UID: [%d].\n",unused_uid);
        uid=unused_uid;
   }

   fflush(stdin);
   printf("Home Directory [%s/%s]: ",DEFAULT_HOME,uname);
   fflush(stdout);
   gets(dir);
   if (!strcmp(dir,"")) sprintf(dir,"%s/%s",DEFAULT_HOME,uname);

   fflush(stdin);
   printf("Shell [%s]: ",DEFAULT_SHELL);
   fflush(stdout);
   gets(shell);
   if (!strcmp(shell,"")) sprintf(shell,"%s",DEFAULT_SHELL);
   
   fflush(stdin);   
   printf("Password [%s]: ",uname);
   fflush(stdout);
   gets(passwd);
   if (!strcmp(passwd,"")) sprintf(passwd,"%s",uname);
   time(&tm);
   salt[0]=(tm.t_time & 0x0f)+'A';
   salt[1]=((tm.t_time & 0xf0) >> 4)+'a';
   salt[2]=0;
  
   printf("\nInformation for new user [%s]:\n",uname);
   printf("Home directory: [%s]\nShell: [%s]\n",dir,shell);
   printf("Password: [%s]\nUID: [%d]\nGID: [%d]\n",passwd,uid,group);
   printf("\nIs this correct? [y/N]: ");
   fflush(stdout);
   fflush(stdin);
   gets(foo);
   bad=correct=(foo[0]=='y'||foo[0]=='Y');
   if (bad!=1) printf("\nUser [%s] not added.\n",uname);
  }

  printf("\nAdding login [%s]...\n",uname);
  strcpy(foo,PASSWD_FILE);
  strcat(foo,".old");
  if ((passwd_file=fopen(foo,"w")) == NULL) {
   printf("Error creating password backup file.\n");
   exit(1);
  }
  setpwent();
  for (i=0;(pw=getpwent())!=NULL;++i) {
   if (putpwent(pw,passwd_file)==-1) {
    printf("Error writing password backup file.\n");
    exit(1);
   }
  }
  endpwent();
  fclose(passwd_file);
  if (i<1) printf("Can't backup password file.\n");
  passwd_file=fopen(PASSWD_FILE,"a");
  fprintf(passwd_file,"%s:%s:%d:%d:%s:%s:%s\n"
	  ,uname,crypt(passwd,salt),uid,group,person,dir,shell);
  fflush(passwd_file);
  fclose(passwd_file);
  
  printf("Making directory [%s]...\n",dir);
  mkdir(dir,DEFAULT_PERMS);

  chown(dir,uid,group);
  printf("Done.\n");
}
