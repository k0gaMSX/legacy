  _____   _ _ __ ___  
 |_  / | | | '_ ` _ \ 
  / /| |_| | | | | | |
 /___|\__, |_| |_| |_|
      |___/ for SymbOS

Zym is an interpreter for playing interactive fiction games (text adventures)
in Z-code format on SymbOS. It supports Z-machine versions 3, 4, 5, and 8, so
it can run most of the games published by Infocom, as well as thousands of
other Z-code games created by the interactive fiction community.

Zym is intended to be run from the command line (SymShell).

Usage: zym [options] story
            -n  = Enable score notification in Version 3 games.
            -s  = Do not show status line / upper window.
            -t  = Select Tandy mode for Infocom games.
            -u  = Enable UNDO (slower).
			
NOTE: Zym is fastest and most readable in fullscreen mode (Alt+Enter). Due to a
bug in SymShell 2.1, you may also very occasionally need to press Alt+Enter to
un-freeze the game if the text output completely locks up. (This is different
from the game simply taking a long time to do something, which is normal.)
	
--------------------------------------------------------------------------------
 WHAT CAN ZYM PLAY?
--------------------------------------------------------------------------------

INFOCOM GAMES: Zym can play all of the classic Infocom games except for
those which used the graphical z6 format (Zork Zero, Shogun, Arthur: Quest for
Excalibur, and Journey: The Quest Begins). Authorized game files can be
obtained from the original disks (the relevant file usually has the extension
.DAT) or from collections such as the Zork Anthology (available on GOG.com).

INDEPENDENT GAMES: Since the 1990s an active hobbyist community has written
numerous new games in Z-code format. A selection of games which play well on
Zym are included in the package; other games may be obtained from ifarchive.org
or the Interactive Fiction Database (https://ifdb.org/search?searchbar=format
%3Az-code). Note that Zym does not support the Blorb file format (.zblorb); you
will need to find a .z3/.z4/.z5/.z8 version of the game file, or extract it
from the Blorb using a tool such as https://eblong.com/zarf/blorb/blorbtool.py.

PERFORMANCE: Infocom games run well. Inform 5/6 games vary from fairly quick
(like the early releases of Curses) to unplayably slow (like Mulldoon Legacy).
In general, Inform 5 and PunyInform games run better than stock Inform 6 games.
Inform 7 games are generally not playable due to speed or stack limitations.

GAMES INCLUDED WITH ZYM: The following starter pack of games is included in the
full Zym package. All of these are reasonably well-regarded or historic, may be
freely distributed, and have been tested to run at a playable speed on Zym.

- ADVENT.Z3     Adventure by Willie Crowther and Don Woods
- CAPTAIN.Z5    Captain Cutter's Treasure by Garry Francis
- CRAVERLY.Z3   Craverly Heights by Ryan Veeder
- CURSES.Z5     Curses by Graham Nelson (the faster Release 12)
- DETECT.Z5     MST3K Presents Detective! by C. E. Forman
- MINIZORK.Z3   Mini-Zork I by Infocom (demo)
- MINSTER.Z5    Christminster by Gareth Rees
- MOONLIT.Z5    The Moonlit Tower by Yoon Ha Lee
- THEATRE.Z5    Theatre by Brendon Wyber
- TRISDEMO.Z3   Tristam Island by Hugo Labrande (demo)
- WINDOW.Z5     The Space Under the Window by Andrew Plotkin

The following games are also included in the SLOWER subfolder, meaning that
they are playable, but may run slowly enough to frustrate some players:

- ADVERB.Z5     Ad Verbum by Nick Montfort
- BALANCES.Z5   Balances by Graham Nelson
- BEARS.Z5      A Bear's Night Out by David Dyte
- CHANGE.Z5     For A Change by Dan Schmidt
- EDIFICE.Z5    The Edifice by Lucian Smith
- GOSTAK.Z5     The Gostak by Carl Muckenhoupt
- GOURMET.Z8    Gourmet by Aaron Reed
- MUSE.Z5       Muse: An Autumn Romance by Christopher Huang
- PHOTOPIA.Z5   Photopia by Adam Cadre (as "Opal O'Donnell")
- SHERBET.Z5    The Meteor, the Stone and a Long Glass of Sherbet by G. Nelson
- SLOUCH.Z5     Slouching Towards Bedlam by Star C. Foster and David Ravipinto
- SPIDER.Z5     Spider and Web by Andrew Plotkin
- WINTER.Z5     Winter Wonderland by Laura A. Knauth

For hints on any of these games, you will need to look elsewhere. :-P

--------------------------------------------------------------------------------
 CREDITS & LICENSE
--------------------------------------------------------------------------------

Zym is licensed under the GNU GPL v2/v3; see COPYING.TXT.

Zym is nominally a port of fweep, a portable and somewhat idiosyncratic ANSI C
Z-machine by zzo38. However, it now contains enough original code (and removes
enough of what makes fweep distinctive) that it no longer seemed accurate to
call it "fweep"; hence the new name. Zym was ported to SymbOS by prevtenet and
uses much underlying code by zzo38, as well as some code and ideas adapted from
the FUZIX port of fweep by Alan Cox (fweeplet) and ZORKMID by zzo38.

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------

2022-02-19 - initial public release of version 0.9. Major changes from Fweep:

Removed:
- Support for Z-machine versions 1, 2, 7, 9, and 10 (which are all very rare.)
- Various convenience features, to improve performance:
  - Transcripting
  - Auxilliary files
  - Input/output files
  - Many command-line options

Modified:
- The memory model has been redesigned to run on SymbOS.
- Many optimizations to improve performance on 8-bit systems (such as a proper
  binary-search tokenizer and streamlining of many heavily-used routines).
- The interpreter may now disobey the requested buffering mode (in rare cases
  this may cause display issues, but generally it improves performance.)

Added:
- Upper window support and proper cursor control.
- Accented characters / diacritics.

--------------------------------------------------------------------------------
 KNOWN BUGS AND ODDITIES
--------------------------------------------------------------------------------

As mentioned above, due to a bug in SymShell 2.1 output may very occasionally
lock up, freezing the game. This can usually be cleared by pressing Alt+Enter
to toggle fullscreen mode. (This is different from the game simply taking a
long time to do something, which is unfortunately normal.)

Because SymShell does not support windowed scrolling, the status line will
scroll away and (generally) be replotted every turn. If you find this annoying,
you can omit the status line entirely using the -s option.

Many Inform games make use of an inefficient method of printing whitespace.
This causes some text (particularly boxed quotations and the status line) to
render more slowly than would otherwise be expected.

Closing SymShell manually by clicking the "X" button will leave Zym hanging
without freeing any of its allocated memory. Use "quit" instead. (As of SymbOS
3.1 there is no way around this, although this is planned for future releases.)

Some Version 8 games require too many stack frames and will crash. (However,
these are usually games which would not run well to begin with.)

Traditionally, Z-machine save-files use some clever logic to only save the
portions of dynamic memory which have actually been changed. Zym does not do
this; it just saves the whole lot. In practice the types of games which run
well on Zym do not use much dynamic memory to begin with, so this is rarely an
issue, but note that save files could theoretically reach >64kb for some large
games. (This may be improved in a future release.)

When displaying a boxed quotation immediately after scrolling, games with
multi-line status lines (e.g., .z5 releases of Curses) may fail to fully redraw
the status line. This occurs because the routine for displaying the boxed
quotation incorrectly resets the height of the upper window to 1 until the
following turn (which is not trivial to work around).