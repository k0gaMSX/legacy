#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stat.h>

#ifndef O_TRUNC
#define O_TRUNC 0
#endif
#ifndef O_WRONLY
#define O_WRONLY 0
#endif

extern int _spawn(char*, char*);
extern char *token(char **);

int spawnblock(char *);
char * pathfind(char *);
int spawnline(char *);
extern int verbose;
extern int noexec;

static char * tmpnam = "<$M.T";

char * mkfile(char *s, char *q)
{
  int klen;
  FILE * fp; 
  register char * res;
  
  for (klen=0, s+=2 ; isalnum(*s) ; s++, klen++) /* nix */;
  s-=klen;
  if (noexec) printf("<<%.*s\n", klen, s);
  for (res=q ; strncmp(res,s,klen) && *res ; ++res) {
    if ( !(res=strchr(res,'\n')) ) 
      break;
  } 
  if (!res)
    fputs("make: runaway << text\n", stderr);
  else {
    fp=noexec ? stdout : fopen(tmpnam+1,"w");
    if (!fp) {
      perror(tmpnam+1);
      fputs(" while creating temp. file in make:mkfile()\n",stderr);
      return NULL;
    }
    *res=0;
    if ((fputs(q,fp)==EOF)||(fputs("\32\n",fp)==EOF)) {
      perror(tmpnam+1);
      fputs(" while writing temp. file in make:mkfile()\n",stderr);
      if (!noexec) 
	fclose (fp); 
      return NULL;
    }
    *res=*s;
    if (!noexec && fclose(fp)) {
      perror(tmpnam+1);
      fputs(" while closing temp. file in make:mkfile()\n",stderr);
      return NULL;
    }
    if (noexec) 
      printf("%.*s\n", klen, s);
    while ( *res && ('\n'!=*res++) ) /* nix */ ;
    strcpy(s-2, s+klen);
    strcat(s-2, tmpnam);
  }
  return res;
}


struct env_sav {
  char * name;
  char * val;
  struct env_sav * next;
} ;
struct env_sav * env_stack;

/*
 * undo changes made by do_set
 */
void pop_env()
{
  struct env_sav *cur, *nxt;

  for ( cur=env_stack ; cur ; cur=nxt) {
    setenv(cur->name, cur->val);
    free(cur->val);
    nxt = cur->next;
    free(cur);
  }
} 


/* 
 * Executes a subprocess for each line in blok.
 * Stops when a subprocess returns a nonzero exit-status
 * If a line starts with ':', the ':' is skipped and the exitstatus is ignored.
 * return value is exit-status of last subprocess executed, 
 * or zero if the last line processed starts with ':'
 *
 * if a line contains "<<" followed by a word, the following lines
 * until a line starting with the word are copied to '$M.T'.
 * "<<" and the word are removed from the line and "<$M.T" is appended.
 */

int spawnblock(char *blok)
{
  int res;
  char *linbuf, *p, *q, *s;

  env_stack = NULL;
  linbuf=malloc(strlen(blok)+1); 
  if (!linbuf) {
    fputs("*** Out of memory\n",stderr);
    return 0xDE;
  }
  for (p=strcpy(linbuf,blok),res=0 ; (res==0) && (*p) ; p=q) {
    for (q=p ; (*q)&&(*q!='\n') ; ++q) /* nix */;
    if (*q=='\n') *q++='\0';
    s=strchr(p,'<');
    if (s && ('<'==s[1])) {
      q=mkfile(s,q);
      if (!q) { res=2; break; }
    }
    res = spawnline(p);
    if (s) unlink(tmpnam+1);
  }
  pop_env();
  free(linbuf);
  return res;  
}


/*
 * change the environment like set would do, but store the old value
 */
int do_set(char * line)                                             	
{
  char * q;
  struct env_sav * penv;

  q=token(&line);
  penv=malloc(sizeof(struct env_sav));
  if (penv) {
    penv->val=getenv(q);
    penv->next=env_stack;
    setenv(q,line);
    return 0;
  }
  else {
    fputs("*** Out of memory\n",stderr);
    return 0xDE;
  }
}


char *shell = NULL;

/*
 * executes one subprocess.
 * if the first token in line can be found in the command search path,
 * the file is loaded and executed directly, 
 * otherwise line is interpreted by the program pointed to by the 
 * environment variable SHELL.
 */ 
int spawnline(char *line)
{
  char *command, *progfile, ignore;
  static char set[]="set";
  int res;

  if (':' == *line) {
    ignore=1;
    ++line;
  }
  else
    ignore=0;

  command=token(&line);
  if (0 == strcasecmp(&set, command))
    progfile=&set;
  else 
    progfile=pathfind(command);

  if (progfile==NULL) {
    if (!shell) shell=getenv("SHELL");
    if (!shell) {
      fprintf(stderr,
              "make: '%s' not found in path, and 'SHELL' not in environment\n",
	      command);
      return 0x8E; /* unrecognised command */
    }
    else {
      progfile=shell;
      if (*line) *strchr(command, '\0')=' ';
      line=command;
    }
  }

  if (progfile!=&set && strlen(line)>126) {
     fprintf(stderr,"%s %.20s... : Linebuffer overflow\n", progfile, line);
     res=0x8D; /* BUFUL */
  }  
  else {    
    if (verbose||noexec)
      printf(noexec ? "%s %s\n": "[MAKE] %s %s\n", progfile, line);
    if (progfile==&set)
      res=do_set(line);
    else
      res=noexec ? 0 : _spawn(progfile, line);
    if (progfile == shell) {
      if (res==0x8C) 
	res=0; /* internal 'error' code meaning no error */
      else
	command=token(&line);
    }
  }
  if (res && (!ignore || verbose))
     fprintf(stderr, "'%s' failed with error code %d%s.\n", 
		     command, res, ignore ? " (ignored)" : "");
  return (ignore ? 0 : res);
}

static char *nopath[]={"", NULL};

#define MAXLEN 66
static char **path_elt;
static char padbuf[MAXLEN+1];
extern _flip(char *, char *, int); /* substitute '\\' for '/' */ 

/*
 * Tries to find command s in the search path.
 * Returns the filename if it is found and
 * NULL otherwise.
 */
char * pathfind(char* s)
{
  char *pad,*p;
  int n,i;
  struct stat dummy;

  if (path_elt==NULL) {
    pad=getenv("PATH");
    if ((!pad)||strlen(pad)==0) path_elt=nopath;
    else {
      for (p=pad, n=1 ; *p ; ) if (*p++ == ';') ++n;
      path_elt=malloc((n+1)*sizeof(char*)); 
      if (path_elt) {
	path_elt[0]=pad;
	for (i=0,p=pad ; (*p) ; )
	  switch (*p) {
	    case ';':
	      *p='\0';
              path_elt[++i]=++p;
              break;
            case ' ':
              ++path_elt[i];
              /* fall through */
            default:
              ++p;
          }
        path_elt[++i]=NULL;
      }
      else {
	fputs("Not enough memory, ignoring $PATH\n",stderr);
	path_elt=nopath;
      }
    }
  }
  
  for (i=0,pad=NULL ; path_elt[i] && !pad ; ++i)
    if (strlen(path_elt[i])+strlen(s)+5<=MAXLEN) {
      strcpy(padbuf,path_elt[i]);
      if (*padbuf)
        switch (padbuf[strlen(padbuf)-1]) {
        case ':': 
        case '/': 
        case '\\':
          break;
        default: 
          strcat(padbuf,"\\");
        }
      strcat(strcat(padbuf,s),".COM");
      if (stat(padbuf, &dummy)==0) { 
	_flip(padbuf, padbuf, MAXLEN+1);
	pad=padbuf;
      } 
    }
  return pad;
}

