/*    MSX-C compiler   sample   program */
/*    Directory search  routine   under */
/*    DISK-BASIC envirment              */


#pragma nonrec
#include <stdio.h>


#define serc_first (TINY)0x11  /*MSX-DOS function      "search first"    */
#define serc_next (TINY)0x12   /*                      "search next"     */
#define sys_restart (TINY)0x00 /*                      "system restart"  */
#define str_out (TINY)0x09     /*                      "string out"      */
#define set_DTA (TINY)0x1a     /*Reset DTA(Disk Transfer address) address*/

#define STR (TINY)0x03         /*Code of Parameter type of Disk-BASIC's  */
			       /*USR() function                          */


/*MSX-BASIC string descriptor*/
typedef struct {
	    TINY len;          /*Length of string must be 12bytes(dc+fn) */
	    char *str;         /*String for filename */
	} DESCRIP;


#define Fn_len (1+3+8)         /*Length of file name */


VOID setup(fcb,desc)                       /*Set up FCB before calling BDOS*/
char *fcb;
DESCRIP *desc;
{
    setmem(fcb, (unsigned)33, '\0');       /*Fill FCB with NUL character*/

    movmem(desc->str, fcb, (unsigned)Fn_len);/*Set filename to FCB*/
}


STATUS first(my_fcb,desc)
char *my_fcb;
DESCRIP *desc;
{
    char dmy;                              /*dummy parameter*/

    setup(my_fcb, desc);                   /*Set up FCB     */

#define bdosx(code,_adrs) (*(STATUS (*)())(0xf37d))(dmy,_adrs,code)
/* "f37d" -> MSX-DOS entry point under Disk-BASIC */
    return(bdosx(serc_first, my_fcb));     /*"Search first" */
}


STATUS next(my_fcb)
char *my_fcb;
{
    char dmy;

    return(bdosx(serc_next, my_fcb));      /*"Search next"*/
}

char message[] = "Bad search argument\n$"; /*Error message*/

VOID user_error()
{
    char dmy;

    bdosx(str_out, message);               /*Display error message*/
    bdosx(sys_restart, NULL);              /*System restart       */
}

char my_dir[33];                           /*=>Disk Transffer Address */

VOID set_str(desc,length)
DESCRIP *desc;
TINY length;
{
    desc->len = length;
    desc->str = my_dir;
}

VOID search(type,desc)
TINY type;
DESCRIP *desc;
{
    static char my_fcb[33];            /*FCB 33bytes */
    char dmy;
    TINY length;

    length = 0;                        /*Reset       */

    bdosx(set_DTA, my_dir);            /*"Reset DTA" */

    if (type != STR)                   /*Invalid paramter type*/
	user_error();

    if(desc->len) {
	if (desc->len != (TINY)Fn_len) /*Bad file name specified*/
	    user_error();
	if (first(my_fcb,desc) == OK)
	    length = Fn_len;
    }else {
	if (next(my_fcb) == OK)
	    length = Fn_len;
    }
    set_str(desc,length);
    return;
}
