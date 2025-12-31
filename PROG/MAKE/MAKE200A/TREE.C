/*--- TREE.C -----------------------------------------------------------------
Tree building of filenames
Include file for MAKE.COM, The MSX Maniac, 17-Dec-1994 */


#include <stdio.h>
#include "tree.h"
#include "main.h"
#include "error.h"

node  *root = NULL;
node  leaf = {"dummy", NULL, NULL, NULL, 0, 0, 0, NO, NO, NO, NO};

/* #define DEBUGTREE */


/*--- EasyNode() -------------------------------------------------------------
ù function: Copy node structure into external variables to optimize speed.
	    The external variables have the structure names preceded by a '_'.
ù input:    pointer to node structure
ù output:   updated external variables */

VOID EasyNode(node)
struct node  *node;
{
   f_node    = node;
   f_name    = node->name;
   f_left    = node->left;
   f_right   = node->right;
   f_prev    = node->prev;
   f_date    = node->date;
   f_time    = node->time;
   f_resetAttr = node->resetAttr;
   f_backDone = node->backDone;
   f_Aupdate = node->Aupdate;
   f_Tupdate = node->Tupdate;
}


/*--- TreeBuild() ------------------------------------------------------------
ù function: Build binary tree.
ù input:    pointer to drive/path/file ASCIIZ string
ù output:   external variable ALIFE set to TRUE if tree is expanded with new
	    node, FALSE if node (=name) already exists.
ù return:   pointer to new/existing node
ù note:     When using this function, the 'root' of the tree must have been
	    initialized. */

struct node *TreeBuild(name)
char *name;
{
   char  *cpi;
   node  *spi;
   static int	result;

#ifdef DEBUGTREE
   printf("\t%s passed to TreeBuild()\n", name);
#endif

      /* allocate space for new drive/path/file string */

   strcpy(cpi = Ealloc(strlen(name) + 1), StrToUpper(name));

      /* allocate space to create new node */

   memcpy(spi = (node *) Ealloc(sizeof(node)), (char *) &leaf, sizeof(node));

   if (root == NULL) {		  /* Init tree */
      root = spi;
      root->name = cpi;
      ALIFE = TRUE;
   }
   else {
      ALIFE = FALSE;
      EasyNode(root);
      while (result = strcmp(name, f_name)) {		/* Search Name */
	 if (result > 0)
	    if (f_right)
	       EasyNode(f_right);
	    else {
	       f_node->right = spi;
	       ALIFE = TRUE;
	       break;
	    }
	 else
	    if (f_left)
	       EasyNode(f_left);
	    else {
	       f_node->left = spi;
	       ALIFE = TRUE;
	       break;
	    }
      }
      if (ALIFE) {				   /* Fill new file node */

#ifdef DEBUGTREE
	 puts("\tTree is alive\n");
#endif

	 spi->prev = f_node;
	 spi->name = cpi;
      }
      else {

#ifdef DEBUGTREE
	 puts("\tTree is dead\n");
#endif

	 free(spi);
	 spi = f_node;
      }
   }
   return(spi);
}


/*--- TreeRead() -------------------------------------------------------------
ù function: Read tree in alphabetic order
ù input:    pointer to node-processing function (bee). The bee may use the
	    easy node variables but may not alter them!
ù output:   none
ù return:   none */

VOID TreeRead(bee)
VOID (* bee)();
{
   struct node *node;

#ifdef DEBUGTREE
   puts("TreeRead()\n");
#endif

   EasyNode(root);
   while (TRUE) {
      if (f_left)
	 EasyNode(f_left);
      else {
	 (*bee)(f_node, "--- Busy Bee ---");
	 if (f_right == NULL) {

#ifdef DEBUGTREE
	    puts("\tf_right = NULL\n");
#endif

	    do {
	       do {
		  if (f_prev == NULL) {

#ifdef DEBUGTREE
		     puts("\tf_prev = NULL\n");
#endif

		     return;
		  }
		  node = f_node;	    /* save current node */
		  EasyNode(f_prev);
	       } while (f_right == node);
	       (*bee)(f_node, "--- Busy Bee ---");
	    } while (f_right == NULL);
	 }
	 EasyNode(f_right);
      }
   }
}
