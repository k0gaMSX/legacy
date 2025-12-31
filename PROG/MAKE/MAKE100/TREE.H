/*--- TREE.H ----------------------------------------------------------------*/

struct node {
   char 	name[13];	       /* filename (ASCIIZ string) */
   struct node	*left;		       /* pointer to left record */
   struct node	*right; 	       /* pointer to right record */
   struct node	*prev;		       /* pointer to previous record */
   unsigned	date;		       /* date */
   unsigned	time;		       /* time */
   BOOL 	Aupdate;	       /* YES if archive bit set */
   BOOL 	Tupdate;	       /* YES if new time compared to master */
   BOOL 	bdone;		       /* YES if backup already done */
};


extern struct node  root, leaf, *_node;
extern char	    _name[13];
extern BOOL	    _Aupdate, _Tupdate, _bdone;
extern unsigned     _date, _time;
extern BOOL	    ALIFE;

VOID	    InitTree();
struct node *TreeBuild();
VOID	    TreeRead();
VOID	    EasyNode();
