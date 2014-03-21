/*	make_cc.c

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	Build the compiler itself with MESCC under a z80 & CP/M environment.

	Copyright (c) 1999-2007 Miguel I. Garcia Lopez

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation; either version 2, or (at your option) any
	later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

	How to build MESCC itself in CP/M & Z80 (if you are in C: drive):

	cc make_cc.c -s:2048 -o:newcc.zsm
	zsm newcc.ccz
	hextobin newcc.hex newcc.com

	Now, you have newcc.com that is the new version of cc.com MESCC.

	Revisions:

	16 Jan 2001 : Last revision.
	16 Apr 2007 : GPL'd.
*/

/*	Runtime
*/

#include "mescc.h"

/*	Libraries
*/

#include "fileio.h"
#include "conio.h"
#include "string.h"
#include "ctype.h"
#include "mem.h"

/*	Compiler modules
*/

#include "c_main.c"
#include "c_cpp.c"
#include "c_expr.c"
#include "c_asm.c"
#include "c_error.c"
#include "c_buf.c"
#include "c_iocon.c"
#include "c_iofile.c"
