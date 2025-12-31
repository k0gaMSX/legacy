/*--- TREE.C ----------------------------------------------------------------*/

#include <stdio.h>
#include <tree.h>
#include <error.h>


/*------------------------------------------------------------- Variables ---*/
struct node  root, *_node, *_left, *_right, *_prev;
char	     _name[13];
unsigned     _date, _time;
struct node  leaf = {
		"        .   ", NULL, NULL, NULL, 0, 0, NO
	     };
BOOL	     _Aupdate, _Tupdate, _bdone;
BOOL	     ALIFE;    /* Used by TreeBuild(); set to TRUE if tree was
			   expanded with new node */


/*------------------------------------------------------------- Functions ---*/
/*
--- EasyNode() -------------------------------------------------------------
ù function: Copy node structure into external variables to optimize speed.
	    The external variables have the structure names preceded by a '_'.
ù input:    pointer to node structure
ù output:   updated external variables
*/

VOID EasyNode(node)
struct node  *node;
{
   _node    = node;
   strcpy(_name, node->name);
   _left    = node->left;
   _right   = node->right;
   _prev    = node->prev;
   _date    = node->date;
   _time    = node->time;
   _Aupdate = node->Aupdate;
   _Tupdate = node->Tupdate;
   _bdone   = node->bdone;
}


/*
--- InitTree() -------------------------------------------------------------
ù function: Initialize tree; define 'root'.
ù input:    pointer to filename
ù output:   defined root
ù return:   none
*/

VOID InitTree(name)
char *name;
{
   memcpy((char *) &root, (char *) &leaf, sizeof(struct node));
   strcpy(root.name, name);
}


/*
--- TreeBuild() ------------------------------------------------------------
ù function: Build binary tree.
ù input:    pointer to filename
ù output:   external variable ALIFE set to TRUE if tree is expanded with new
	    node, FALSE if node (=name) already exists.
ù return:   pointer to new/existing node
ù note:     When using this function, the 'root' of the tree must have been
	    defined using InitTree().
*/

struct node *TreeBuild(name)
char *name;
{
   struct node	*p;
   static int	result;

   p = (struct node *) alloc(sizeof(struct node));
   if (p == NULL)
      MError(2, 0);
   memcpy((char *) p, (char *) &leaf, sizeof(struct node));
							  /* Search Name */
   ALIFE = FALSE;
   EasyNode(&root);
   while (result = strcmp(name, _name)) {
      if (result > 0)
	 if (_right)
	    EasyNode(_right);
	 else {
	    _node->right = p;
	    ALIFE = TRUE;
	    break;
	 }
      else
	 if (_left)
	    EasyNode(_left);
	 else {
	    _node->left = p;
	    ALIFE = TRUE;
	    break;
	 }
   }
   if (ALIFE) {
      p->prev = _node;
      strcpy(p->name, name);
      return(p);
   }
   else
      return(_node);
}


/*
--- TreeRead() -------------------------------------------------------------
ù function: read tree
ù input:    pointer to node-processing function (bee). The bee may use the
	    easy node variables but may not alter them!
ù output:   none
ù return:   none
*/

VOID TreeRead(bee)
VOID (* bee)();
{
   struct node *node;

   EasyNode(&root);
   while (TRUE) {
      if (_left)
	 EasyNode(_left);
      else {
	 (*bee)(_node, "--- Busy Bee ---");
	 if (_right == NULL)
	    do {
	       do {
		  if (_prev == NULL)
		     return;
		  node = _node; 	   /* save current node */
		  EasyNode(_prev);
	       } while (_right == node);
	       (*bee)(_node, "--- Busy Bee ---");
	    } while (_right == NULL);
	 EasyNode(_right);
      }
   }
}

