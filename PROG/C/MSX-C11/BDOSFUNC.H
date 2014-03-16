/*

	BDOSFUND.H      --      MSX-DOS functions (Ver 1.1)

*/
				/* BDOS function codes                */

#define RESET           '\000'  /* system reset                       */
#define CONIN           '\001'  /* console input                      */
#define CONOUT          '\002'  /* console output                     */
#define AUXIN           '\003'  /* auxiliary input                    */
#define RDRIN           AUXIN
#define AUXOUT          '\004'  /* auxiliary output                   */
#define PUNOUT          AUXOUT
#define LSTOUT          '\005'  /* list output                        */
#define DIRCON          '\006'  /* direct console I/O                 */
#define RAWIN           '\007'  /* direct console input               */
#define DIRIN           '\010'  /* console input (no echo)            */
#define STROUT          '\011'  /* print string                       */
#define GETLIN          '\012'  /* console line input                 */
#define CONST           '\013'  /* console status                     */
#define VERNO           '\014'  /* get CP/M version number            */
#define RESDSK          '\015'  /* reset disk system                  */
#define SETDRIVE        '\016'  /* set default drive                  */
#define OPEN            '\017'  /* open file                          */
#define CLOSE           '\020'  /* close file                         */
#define SEARF           '\021'  /* search for first                   */
#define SEARN           '\022'  /* search for next                    */
#define DELETE          '\023'  /* delete file                        */
#define CPMREAD         '\024'  /* read next record (*)               */
#define CPMWRITE        '\025'  /* write next record (*)              */
#define CREATE          '\026'  /* create file                        */
#define RENAME          '\027'  /* rename file                        */
#define LOGVEC          '\030'  /* get login vector                   */
#define GETDRIVE        '\031'  /* get default drive                  */
#define SETDMA          '\032'  /* set DMA address                    */
#define GETALOC         '\033'  /* get allocation parameter           */
/*  < no function >     '\034'                                        */
/*  < no function >     '\035'                                        */
/*  < no function >     '\036'                                        */
/*  < no function >     '\037'                                        */
/*  < no function >     '\040'                                        */
#define READRNDM        '\041'  /* random read (*)                    */
#define WRTRNDM         '\042'  /* random write (*)                   */
#define FILESIZE        '\043'  /* get file size (*)                  */
#define SETREC          '\044'  /* set random record (*)              */
/*  < no function >     '\045'                                        */
#define BLKWRITE        '\046'  /* random block write                 */
#define BLKREAD         '\047'  /* random block read                  */
#define WRTRNDMZ        '\050'  /* random write with zero fill (*)    */
/*  < no function >     '\051'                                        */
#define GETDATE         '\052'  /* get current date                   */
#define SETDATE         '\053'  /* set current date                   */
#define GETTIME         '\054'  /* get current time                   */
#define SETTIME         '\055'  /* set current time                   */
#define SETVERI         '\056'  /* set/reset verify flag              */
#define ABSREAD         '\057'  /* absolute sector read               */
#define ABSWRIT         '\060'  /* absolute sector write              */

#define INITDMA         0x0080  /* default DMA area                   */

#define MAXDRIVE        8       /* maxmum disk drive                  */

#define BDOSERR         255     /* BDOS error value                   */


				/* BIOS entry codes                   */

#define BIOS_WBOOT      '\000'  /* WARM START                         */
#define BIOS_CONST      '\001'  /* console status                     */
#define BIOS_CONIN      '\002'  /* console input                      */
#define BIOS_CONOUT     '\003'  /* console output                     */


typedef unsigned LONG[2];       /* "long" type is not supported       */

typedef struct {
	    char    dc;         /* drive code                         */
	    char    name[8];    /* file name                          */
	    char    type[3];    /* file name extention                */

	    char    _filler1_[2];
	    unsigned recsize;   /* record size used by block i/o      */
	    LONG    filesize;   /* file size in bytes                 */
	    unsigned fcbdate;
	    unsigned fcbtime;
	    char    _filler2_[9];
	    LONG    recpos;     /* current record number              */

	    char    mode;       /* file mode    R, W, R/W             */
	}   FCB;


int     bdosh(), biosh();
char    bdos(), bios();
