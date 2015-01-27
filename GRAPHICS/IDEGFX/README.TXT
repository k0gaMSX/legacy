Graphics enviroment for game develops, made by Guillermo R. Flook (aka flyguille) from Argentinia.

----------------------------------------------------------------

How to use?.

This graphics enviroment allows to load up in memory a lot of "things",
each thing is called "a bunch".

By example: You can have 8 palette sets loaded in memory at the same time,
plus 2 tile sets, and 32 game map scenes.

The limit is the ammount of RAM installed.

Following the example, if you have 8 palette sets loaded don't means that
the 8 sets will be in use or "active".

What determines that something is in use or active?:

1) If you are browsing that specific bunch (by example the palette set named "a.pl").

2) If you are browsing another bunch which has a link that finally points to use
that specific palette set, by example: the one named "a.pl".

Sometimes is needed to link several bunches as a chain.

Common examples:

MAP Scene -> Metatile grouping chart -> TileSet Bunch -> PaletteSet Bunch.
MAP Scene -> TileSet Bunch -> PaletteSet Bunch.
MAP Scene -> Metatile grouping chart -> TileSet Bunch.
MAP Scene -> TileSet Bunch.

Once you have the bunches in memory, you can edit and save them to disk.


-----------------------------------------------------------------------------------

You can create or load a custom palette set, this is optional.

PALETTE CONSOLE:
----------------

	Use <Cursor> keys to move the focus from one palette to another and/or from the Red/Green/Blue slice control to another.

	Use <Space> for decreasing the value of the colour channel where the cursor is.

	Use <M> for increasing the value of the colour channel where the cursor is.

	Use <RETURN> for SAVING the palette set.

	Use <ESC> for escape without saving the modifications.

	Use <TAB> for changing to another console/"bunch" loaded. IT escapes WITHOUT saving the modifications.

------------------------------------------------------------------------------------


You can create or load a TileSet, that can be 8x8 hardware tiles (Screen 2 tiles), or software rendered tiles (8x8 for Sc5 and Sc8) 16x16 / 32x32 (aka metatiles).

If you chose more than 256 metatiles when creating the TileSet, please note that a tile number will needs 16bits and not 8bits to be stored. It is later important for linking into a map scene.

Optionally you can set up a link between the tileset and a palette set (see "set bunch link" in the Project menu), so your tileset will use customs palettes.

TILESET CONSOLE:
----------------

TILE SELECTOR:
--------------

	Use <Cursor> keys to move from one tile to another.

	Use <Space> or <RETURN> for edit the tile where is the cursor on.

	Use <TAB> for changing to another console/"bunch" loaded.

	Use <Esc> for go to the menu bar.

	Use <0> - <9>, <A> - <F> keys, for place the tile which is in the cursor, into the Puzzler.
	(The puzzler is needed for see how differents tiles gets connected graphically,
	also is needed for grouping differents tiles into a metatile, when editing the "metatiling map chart").

	Use <L> key, to clear the puzzler.

	Use <O> key, to place the four tiles starting from where the cursor is, into the puzzler, in an arrange of 2x2.

	Use <P> key, to place the sixteen tiles starting from where the cursor is, into the puzzler, in the arrange of 4x4.

	Use <M> key, for marking the start, end, and destination when you want to copy or move tiles.
	(The tiles can be copied from one tileset loaded in memory to another).

	Use <Q> key, for FAST go back to browse the "Metatiling map chart" or "Map Scene" only if one linked.
	(It avoids "selecting all the times, which other bunch to browse").

	Use <G> key, to GO TO a specific tile number.

TILE EDITOR:
------------

	Use <Cursor> keys, to move the cursor that points the pixel to draw.
	If it overflows the right margin, chroma channel or color selections boxes become on focus.
	if it overflows the upper or lower margins, the colour picker become on focus.
	if in the colour picker, use the cursor keys to select the colour.

	Use <Esc> key, to cancel the edition, all changes will be undone.

	Use <Space> key, to hit AS PRIMARY where the cursor is.
	If hitting a pixel in the tile not of screen 2 format, the pixel turns into the colour preselected as primary.
	If hitting a pixel in the tile of screen 2 format, the pixel will turns about its pattern's bit from '0' to '1' and in reverse way. So it changes from One's color to Zero'es color, defined by the chroma channel.
	If hitting the chroma channel of screen 2, it will put the last color selected from the colour picker.
	if hitting a colour selection box, it will put the last colour selected from the colour picker.
	if hitting in the colour picker, it will place the colour that is on the cursor, as primary color selection.

	Use <M> key, to hit AS SECONDARY where the cursor is.
	If hitting a pixel in the tile not of screen 2 format, the pixel turns into the colour preselected as secondary.
	if hitting the chroma channel of screen 2, it will put the last color selected from the colour picker.
	if hitting in the colour picker, it will place the colour that is on the cursor, as secondary color selection.
	
	Use <N> key, to transport the cursor out and in, from the colour picker.
	This is very important and more if is in Screen 8 format, because this function memorizes where the cursor was in the tile box, and where the cursor was in the color picker, so this function transport the cursor to that exact location.
	(It avoids *to travel* the cursor all the time for picking a new colour).

	Use <RETURN> key, to save the editing and go back to the tile selector.

	Use <TAB> key, for go to the functions menu. There is two menues, use <LEFT> or <RIGHT> to switch from one menu to the other.

	Use <0> - <9>, <A> - <F>, to paint directly a colour palette into the pixel where the cursor is or into the chroma channel.
	(This is the faster way to draw in Screen 2 and Screen 5 format).

	Use <V>, to past an image into the tilebox, previously you needs to load an .BMP file (16, 24 or 32bpp), browse the image using the cursor to select an area of the image. If this is not done previously it will past just garbage.

	Use <T>, to pickup the colour where the cursor is. It is very useful when you has done part of the tile and and just want to pickup a color from a nearby pixel. The colour will be set as primary color selection. Not supported in Screen2 format.

	If the tile being edited is in the puzzler, anything you do will have inmediate effect.

------------------------------------------------------------------------------------

Now that you have the tiles done, maybe you want to use it for create a nice game scene,
or a big BIG game MAP scrolleable pixel by pixel!.

Before doing a game map or scene, you needs to think about how to handle the tiles,
by example, if you did tiles for screen 2/4, you needs to fill up in the VRAM
the "Name Table" in additional to the "pattern table" and "color table".

On the other side, to create a game map encoded specifying: one tile number,
for each 8x8 pixels is very inefficient, it takes too much RAM for the map, you don't want to do that.
As it is inefficient and useless, it won't be supported that "direct mapping" just for 8x8 tiles.

Direct mapping is supported only when you creates a tile set of 16x16 metatiles or 32x32 metatiles
(ofcourse not possible in screen 2/4 format). Named "metatiles" because they aren't "hardware tiles",
they are software rendered tiles, also 8x8 sized tiles in screen 5 and screen 8 can be named metatiles.

When using tile graphics of 8x8, or 16x16, it needs or it can grouping tiles,
the grouping can be shaped as 2x2y tiles, 4x4y tiles, 2x4y tiles, or 4x2y tiles.

So, when creating the map, it no more specifies tile numbers, it specify "group IDs"
(sometimes named as "BLOCK ID" or "big metatile ID").

So, the map is encoded, one block ID number per 16x16 pixels, or better, per 32x32 pixels,
that is a lot more efficient for storing scenes and big maps.




For doing tile grouping, you needs to create a "metatiling map chart",
that chart will store the tile numbers assigned to each block ID.

When creating the chart, the enviroment will ask:

	1) What shape will have the tile group.

	2) How many tiles are available in the tile set?.
	(Basically needs to know if it can use only 8 bits for storing each tile number or it must use 16bits).

	3) How many metatiles to create?. ((block IDs) the chart will have).
	(By example, it can have available only 256 tiles in the tile set,
	 but starting from that, it can create 1024 differents group IDs, to cover more convinations).
	If you specifies more than 256 metatiles, the block ID will use 16bits to be stored in the map.

	4) The filename for the chart.

Then you needs to set a link, from the "metatiling map chart" bunch just created,
to the bunch of the "Tile Set" that will be activated when using this metatiling map chart.

For linking, the formats must match, is to say, if you specified that the "metatiling map chart"
will have 8bits to store each tile number, the tileset must have only up to 256 tiles.


METATILING MAP CHART CONSOLE
----------------------------

	Use <Cursor> keys, for selecting which metatile (which block ID) to have in focus.

	Use <Space> key, for hitting the block on the cursor. When hitting, all that
	is currently stored in the puzzler (at the Tile Set console), will be stored
	in the block where the cursor is.

	So, first, you set up some tiles on the puzzler, then gets in this
	console and hits the block where you want to store it.

	Use <Q> key, for FASTly browse to the tile set console, and in the tile set console
	you can use <Q> again for coming back fastly. (only possible when still there is no a MAP linked).

	Use <Esc> key, for go to the menu bar.

	Use <Tab> key, for switching to browse another bunch.

	Use <0> - <9> keys, for set up the "block picker" (see at the bottom) used when editing a map scene.

	Use <G> key, to GO TO a specific block number.

------------------------------------------------------------------------------

Creating a game MAP.

	The game map, can be encoded in terms of Blocks IDs (big metatile IDs),
	or can be encoded directly in tiles IDs (only for 16x16 or 32x32 screen 5 and screen 8 format).

	When creating the map, the system will asks.

	1) What size, expressed in big metatiles the map will have?.
	By example, if the metatile or the block shape is 16x16 pixels,
	for one complete screen, it must be 16 blocks width, by 13 or 14 blocks height.

	2) The map will use...?.
	The system want to know if the map will store BLOCKs or metatiles IDs in 8 bits or 16bits.
	This set up must match when linking to what you have in the metatiling map chart or in the tile set.

	3) The filename for the map.

	Once, you have the map created, you needs to link it.

	Links it to a metatiling map chart bunch, for using the "tile grouping feature".

	Links it to a tile set, containing 16x16 or 32x32 metatiles, for using the "direct mapping feature".

MAP CONSOLE
-----------

	Use <Cursor> keys, to move the cursor to another block of the map. If passing a margin, it scrolls the map.

	Use <WASD> keys, to scroll the map one entire screen.

	Use <Tab> key, for go to browse another bunch.

	Use <Esc> key, for go to the menu bar.

	Use <Q> key, for go to fastly to the metatiling map chart or tileset that is linked.
	When you are in the tile set or metatiling map chart console, press <Q> again, to go fastly to the map.

	Use <0> - <9> keys, for to print in the block of the map where the cursor is,
	with the block preselected that is on the block picker.
	Remember that you preselects the blocks of the picker, in the metatiling map chart console.

	If using direct mapping (MAP -> TileSet), use <Z> and <X> keys. 

	Use <Space> key, for hitting the block that is on the cursor. It will sets the same block ID
	that is on the cursor at the metatiling map chart console. Only available if using that console.

	Use <ZXCV> keys, for scrolling the blocks picker, when doing "Direct mapping" as the "metatiling
	map char" console is not available, it will browse the tileset on the blocks picker for directly use the tiles as blocks.

	Use <M> key, for set up an attribute code, only if available some unused bits.
	Bits in the map are unused when the tiles or the big metatiles count don't fits using all the bits.
	By example, if the block IDs are encoded using 16bits but you have only up to 1024 Block IDs, this 
	means that you have the bits 15 to 10 unused!.

	The system allows to write in those bits some value that helps later to the game routine.
	Examples:
	
		Pointing in which block of the MAP the enemies sprites will appear.

		Or a code, for pointing that there will be something hidden that the character must discover somehow.

		Your gameplay routine can read these codes, appliying, special effects, like animated blocks.

	Use <G> key, to GO TO a specific map's block.

	Use <N> key, to mark the source area start, end, and destination area start for perform a MAP COPY operation.

SPRITES CONSOLE:
----------------

SPRITE SELECTOR:
----------------

	Use <Cursor> keys to move from one sprite to another.

	Use <Space> or <RETURN> for edit the sprite wich is the cursor on.

	Use <TAB> for changing to another console/"bunch" loaded.

	Use <Esc> for go to the menu bar.

	Use <0> - <9>, <A> - <F> keys, for place the sprite which is in the cursor,
	into the Puzzler and using the respectively sprite plane (0h-Fh) to wich key you pressed.
	The puzzler is needed for see how differents sprites gets connected graphically,
	also is needed for grouping differents sprites into a bigger character.
	The XY offset position where appears the sprite into the puzzler can be edited from inside the sprite editor.

	Use <L> key, to clear the puzzler.

	Use <O> key, to place the four sprites starting from where the cursor is, into the puzzler, on sprite planes 0 to 3.

	Use <P> key, to place the sixteen sprites starting from where the cursor is, into the puzzler, on sprite planes 0 to 15.

	Use <M> key, for marking the start, end, and destination when you want to copy or move sprites.
	(The sprites can be copied from one spriteset loaded in memory to another).

	Use <G> key, to GO TO a specific sprite pattern number.

SPRITE EDITOR:
--------------

	Use <Cursor> keys, to move the cursor that points the pattern dot to draw.
	If it overflows the right margin, attribute or color selections boxes become on focus.
	if it overflows the upper or lower margins, the colour picker become on focus.
	if in the colour picker, use the cursor keys to select the colour.

	Use <Esc> key, to cancel the edition, all changes will be undone.

	Use <Space> key, to flip the pattern bit.
	If hitting the chroma, it will put the last color selected from the colour picker.
	if hitting in the colour picker, it will place the colour that is on the cursor, as color selection.

	Use <N> key, to transport the cursor out and in, from the colour picker.

	Use <RETURN> key, to save the editing and go back to the sprite selector.

	Use <TAB> key, for go to the functions menu. There is two menues, use <LEFT> or <RIGHT> to switch from one menu to the other.

	Use <0> - <9>, <A> - <F>, to select directly a colour palette into the sprite row where the cursor is.
	(This is the faster way to setup the colour for the sprite).

	Use <HUJK> keys, to adjust the sprite XY offsets.

	If the sprite being edited is in the puzzler, anything you do will have inmediate effect.

------------------------------------------------------------------------------------

COMPILE
-------

	As you can't use the bunch files directly in your game, because these have a bunch header with a lot
	of useless information, for importing them to your game source code, you needs to use the COMPILE function.

	Basically, it is an EXPORT function named COMPILE, it will export the graphics, in TEXT format, binary format or
	in BLOADable binary format.

	There is a thing that worth to mention, special cases.

	If you are compiling a Screen 2 TileSet, and the TileSet have exactly 256/512/768 tiles,
	when compiling, it splits the pattern from the chroma information, just as the VDP uses it.

	But it not inserts an empty space or nametable in the middle (like the VRAM needs).
	For example, for 256 tiles, it will export only 256*8 + 256*8,
	instead the needed 256*8*3 + NAME_TABLE + empty space + 256*8*3.

	In any other tileset size, for screen 2 format, the chroma information are next to the pattern information,
	tile per tile, 8 bytes for the pattern + 8 bytes for the chroma information.

	If compiling to text, the format will be "<TAB>DB $00, $00 ...<CR><LF>", as like for tniASM compiler.

	If compiling sprites for MSX1 format, it will only export the patterns, 32 bytes per sprite.

	If compiling sprites for MSX2 format and up, it will export the patterns, and the attributes separately. 
	By example, for 64 patterns, it will export 32bytes*64 + 16bytes*64.

-------------------------------------------------------------------------------

IMAGE IMPORT
------------

	It support to import .BMP file and browse the image, then to select with the cursor a square area of the image,
	and then, copy that image into the tile editor using the <V> key into the tile editor, remember <V> = PASTE.

	Is supported .BMP with 16bpp, 24bpp & 32bpp encoding,
	I loaded successfully 24bpp saved using the Windows7's mspaint app.
	If the others formats works wrong, just tell us about the problem.

	In the disk is a .bmp file as example.

	The best is to collect all what you want to import in one image file.

	The tile editor will convert all images into Screen5 or Screen8 format.

	recommendations: If creating Screen5 tiles remember to setup a good palette set,
	that covers as much colour as possible in low bright as in high bright for every colour,
	cover all primaries and secondaries colors from the RGB palette.

-------------------------------------------------------------------------------

GRAPHICS LIBRARIES
------------------

	As you can copy tiles from one bunch to any other using the tile selector console, you can create
	libraries of tilesets, and copy a lot of tiles on one touch. The only requirement, the format must match.

--------------------------------------------------------------------------------

MAP RENDER ROUTINE EXAMPLE
--------------------------

	This is not the best in yield, but it does the job very well (not for a SONIC like game).





<SOURCE>


; *** MAP ENGINE PARAMETERS ***.
; 64K MAP size in RAM (store it in RAM pages from 4 to 7).
; Map size is 256 big metatiles width by 128 big metatiles height, (that big, is like 16 screens width and 8 screens height).
; Each metatile in the map, stores a metatileID (block ID) that is of 16bits (selects more than 256 metatile when creating the map).
; It support up to 1024 metatilesIDs for graphics purpose (so, 1024 will be the metatile ammount for the metatiling map chart).
; The metatileID bits is used the following way, the bits 0 to 9 is for the graphics purposes, bits 10 to 15 are unused by the engine, they are called block's ATTRIBUTE, reads those bits for making special effects, or just mark up where the enemies will appear.
; each metatileID in the metatiling map chart is a group shaped of 2x2 tiles of 8x8 pixels (16x16 pixels in total), each TileID is of 16bits number (so, selects >256 tiles when creating the metatiling map chart).
; Is used Screen5 tile format 8x8 pixels in this engine, so, each tile is 32bytes size, in one RAM page only fits 512 tiles, (so, when creating the TileSet, selects 512 tiles, and 8x8 Screen 5 format).
; Don't forget to use a good palette set, you don't needs to have two palettes that are black, a total wast, oh, and remove that pink one!.

; Summarizing: 4 Ram pages for the MAP (ram pages from 4 to 7),
; 8192 bytes for the metatiling map chart (stored from $c000 up to $Dfff),
; and a TileSet of 16384 bytes (stored in the RAM page 3).

; Both, MAP and TileSet will be accessed by the slotting page 2 ($8000 up to $BFFF).
; Code must be in slotting page 1 ($4000 up to $7FFF).

FNAME "DEMO.BLD"


			DB $FE
			DW CODE_START + $4000
			DW CODE_END - 1 + $4000
			DW $8000




ORG $4000

CODE_START:		di
			in a, ($A8)
			push af
			and $F3
			ld b, a
			in a, ($A8)
			and $30
			rrca
			rrca
			or b
			out ($A8), a

			ld a, ($FFFF)
			cpl
			push af
			and $F3
			ld b, a
			ld a, ($FFFF)
			cpl
			and $30
			rrca
			rrca
			or b
			ld ($FFFF), a
			ei

			ld a, 1
			out ($FD), a

			call StartCode

			di
			pop af
			ld ($FFFF), a
			pop af
			out ($A8), a
			ei
			ret






StartCode:		ld hl, 0
			ld (MapBlockX), hl
			ld (MapBlockY), hl

			di

			ld a, 2
			out ($99), a
			ld a, 25 + 128
			out ($99), a

			ei

			call MapRedraw

.KControl:		xor a
			call STICK

			cp 1
			jr z, .Up

			cp 5
			jr z, .Down

			cp 3
			jr z, .Right

			cp 7
			jr z, .Left

			call INKEY
			jr c, .KControl

			cp 27
			jr z, .Esc

			jr .KControl

.Esc:			ld a, 1
			out ($FE), a

			ret

.Up:			call MapScrollsUp
			jr .KControl

.Down:			call MapScrollsDown
			jr .KControl

.Right:			call MapScrollsRight
			jr .KControl

.Left:			call MapScrollsLeft
			jr .KControl






MapRedraw:		ld hl, (MapBlockX)			; For redrawing all the map, we simply uses the row draw routine by all the screen. It will save a lot of code than doing one specialized routine for drawing all the screen!!!.
			ld (MapCurrentBlockX), hl
			ld hl, (MapBlockY)
			ld (MapCurrentBlockY), hl

			ld hl, 0
			ld (ScreenCurrentX), hl
			ld (RenderingOnCurrentX), hl

			call SetUpVdpScrolls

.Loop:			call MapDrawRow

			ld a, (RenderingOnCurrentY)
			inc a
			inc a
			ld (RenderingOnCurrentY), a
			cp 212
			ret nc

			ld a, (MapCurrentOffsetY)
			inc a
			and $07
			ld (MapCurrentOffsetY), a

			jr nz, .Loop

			ld a, (MapCurrentBlockY)
			inc a
			ld (MapCurrentBlockY), a
			jr .Loop






MapScrollsUp:		call .AdjustVars
			call SetUpVdpScrolls

			ld a, (ScreenCurrentY)
			ld (RenderingOnCurrentY), a		; It will render on the current top of the screen.

			ld hl, (MapBlockX)
			ld (MapCurrentBlockX), hl

			ld hl, (MapBlockY)
			ld (MapCurrentBlockY), hl		; It sets up what rows of the map to render.

			jp MapDrawRow		

.AdjustVars:		ld a, (ScreenCurrentY)
			dec a
			dec a
			ld (ScreenCurrentY), a

			ld a, (MapOffsetY)
			dec a
			and $07
			ld (MapOffsetY), a
			cp $07
			ret nz

			ld a, (MapBlockY)
			and a
			jr z, .UpLimit

			dec a
			ld (MapBlockY),a
			ret

.UpLimit:		xor a
			ld (MapOffsetY), a

			ld a, (ScreenCurrentY)			; Cancel the vdp scroll.
			inc a
			inc a
			ld (ScreenCurrentY), a
			ret






MapScrollsDown:		call .AdjustVars
			call SetUpVdpScrolls

			ld a, (ScreenCurrentY)
			add a, 210				; 212 - 2, as is a scroll of 2 pixels each time.
			ld (RenderingOnCurrentY), a		; It will render on the current botton of the screen.

			ld hl, (MapBlockY)			; h = offsetY, l = BlockY.

			ld a, l
			add a, 13				; for the current 210 line screen, is offset from the top/left in 13 blocks and 1 offset (2 pixels).
			ld l, a

			ld a, h
			inc a
			and $07
			ld h, a
			jr nz, .NoInc

			inc l

.NoInc:			ld (MapCurrentBlockY), hl

			ld hl, (MapBlockX)
			ld (MapCurrentBlockX), hl

			jp MapDrawRow		

.AdjustVars:		ld a, (ScreenCurrentY)
			inc a
			inc a
			ld (ScreenCurrentY), a

			ld a, (MapOffsetY)
			inc a
			and $07
			ld (MapOffsetY), a
			ret nz

			ld a, (MapBlockY)
			inc a
			cp 128 - 14				; 128 - screen Y size in blocks (212 pixels, 13.25 blocks is handles as 14 blocks).
			jr nc, .DownLimit

			ld (MapBlockY),a
			ret

.DownLimit:		ld a, 7
			ld (MapOffsetY), a
			ld a, 128 - 14 - 1
			ld (MapBlockY),a

			ld a, (ScreenCurrentY)			; Cancel the vdp scroll.
			dec a
			dec a
			ld (ScreenCurrentY), a
			ret






MapScrollsRight:	call .AdjustVars
			call SetUpVdpScrolls

			ld a, (ScreenCurrentX)
			add a, 254				; 256 - 2, as is a scroll of 2 pixels each time.
			ld (RenderingOnCurrentX), a		; It will render on the current right of the screen.

			ld hl, (MapBlockX)			; h = offsetX, l = BlockX.

			ld a, l
			add a, 15				; for the current 256 line screen, is offset from the top/left in 15 blocks and 7 offset (2 pixels).
			ld l, a

			ld a, h
			add a, 7
			cp 8
			jr nc, .NoInc

			inc l

.NoInc:			and $07
			ld h, a

			ld (MapCurrentBlockX), hl

			ld hl, (MapBlockY)
			ld (MapCurrentBlockY), hl

			jp MapDrawColumn

.AdjustVars:		ld a, (ScreenCurrentX)
			inc a
			inc a
			ld (ScreenCurrentX), a

			ld a, (MapOffsetX)
			inc a
			and $07
			ld (MapOffsetX), a
			ret nz

			ld a, (MapBlockX)
			inc a
			cp 256 - 16				; 256 - screen X size in blocks (256 pixels, 16 blocks).
			jr nc, .RightLimit

			ld (MapBlockX),a
			ret

.RightLimit:		ld a, 7
			ld (MapOffsetX), a
			ld a, 256 - 16 - 1
			ld (MapBlockX),a

			ld a, (ScreenCurrentX)			; Cancel the vdp scroll.
			dec a
			dec a
			ld (ScreenCurrentX), a
			ret






MapScrollsLeft:		call .AdjustVars
			call SetUpVdpScrolls

			ld a, (ScreenCurrentX)
			ld (RenderingOnCurrentX), a		; It will render on the current left of the screen.

			ld hl, (MapBlockX)			; h = offsetX, l = BlockX.
			ld (MapCurrentBlockX), hl

			ld hl, (MapBlockY)
			ld (MapCurrentBlockY), hl

			jp MapDrawColumn	

.AdjustVars:		ld a, (ScreenCurrentX)
			dec a
			dec a
			ld (ScreenCurrentX), a

			ld a, (MapOffsetX)
			and a
			jr z, .LeftBlock

			dec a
			ld (MapOffsetX), a
			ret

.LeftBlock:		ld a, (MapBlockX)
			and a
			jr z, .LeftLimit	
		
			dec a
			ld (MapBlockX),a

			ld a, 7
			ld (MapOffsetX), a
			ret

.LeftLimit:		ld a, (ScreenCurrentX)			; Cancel the vdp scroll.
			inc a
			inc a
			ld (ScreenCurrentX), a
			ret






SetUpVdpScrolls:	di

			ld a, (ScreenCurrentY)
			out ($99), a
			ld a, 23 + 128
			out ($99), a

			ld a, (ScreenCurrentX)
			ld c, a
			and $F8
			rrca
			rrca
			rrca
			ld b, a
			ld a, c
			and 7
			jr z, .NoOffsets

			inc b

.NoOffsets:		ld a, b
			out ($99), a
			ld a, 26 + 128				; V9958 feature.
			out ($99), a

			ld a, 8
			sub c
			and 7
			out ($99), a
			ld a, 27 + 128				; V9958 feature.
			out ($99), a			

			ei
			ret






MapDrawRow:		call .Int				; It sends to the VDP, two pixels screen row height and full screen wide, of the pointed map row, the row is pointed with (MapCurrentBlockX 0-255 (-ScreenWdith in blocks)) and (MapCurrentBlockY 0-127 (-ScreenHeight in blocks)) (MapCurrentOffsetX 0-7) (MapCurrentOffsetY 0-7). WARNING: It don't clips if Map overflow, so be in the scope!.
								; Out HL = buffer start.
			ld hl, MapBuffer			; VDP must be in Screen 5.
			ld a, (MapCurrentOffsetX)
			ld e, a
			ld d, 0
			add hl, de

			push hl					; Needed for drawing the second row, of the two pixels scrolling step.
			push hl
			ld a, (ScreenCurrentX)			; Even value only.
			rra					; X = X / 2.
			ld l, a
			ld a, (RenderingOnCurrentY)		; Even value only.
			and a
			rra
			ld h, a

			call VPOKEPOS
			pop hl
								; CF = 0.
			ld a, (ScreenCurrentX)			; X = X / 2. Because we will spit pixels data in pair of pixels.
			rra
			ld b, a
			ld a, 128				; Row size in bytes in Sc5.
			sub b
			ld b, a					; B = size to transfer (range 128 or less).
			ld c, $98
			push bc

			otir

			pop bc
			ld a, 128
			sub b
			jr z, .DoneFirstLine
								; CF = 0 always.
			ld b, a					; B = what left to transfer.

			push hl
			ld l, 0					; Continuation of the same Y row.
			ld a, (RenderingOnCurrentY)
			rra
			ld h, a
			call VPOKEPOS
			pop hl

			otir

.DoneFirstLine:		pop hl
			ld de, 128 + 8				; The second line is at distance of 128 (screensize) + 8 (over_rendering).
			add hl, de

			push hl
			ld a, (ScreenCurrentX)			; Even value only.
			scf					; Y = +1.
			rra					; X = X / 2 + 128.
			ld l, a
			ld a, (RenderingOnCurrentY)		; Even value only.
			rra
			ld h, a

			call VPOKEPOS
			pop hl

			ld a, (ScreenCurrentX)			; X = X / 2. Because we will spit pixels data in pair of pixels.
			and a
			rra
			ld b, a
			ld a, 128				; Row size in bytes in Sc5.
			sub b
			ld b, a					; B = size to transfer (range 128 or less).
			push bc

			otir

			pop bc
			ld a, 128
			sub b
			jr z, .DoneSecondLine
								; CF = 0 always.
			ld b, a					; B = what left to transfer.

			push hl
			ld l, 128				; Continuation of the same Y row.
			ld a, (RenderingOnCurrentY)
			rra
			ld h, a
			call VPOKEPOS
			pop hl

			otir

.DoneSecondLine:	ei
			ret

.Int:			ld ix, MapBuffer
			ld a, (MapCurrentBlockY)
			rlca
			rlca
			rlca
			and $07					; Each RAM page is capable to store only 32 rows blocks of the map. So, the 3 msbs defines the RAM page offset.
			add a, MapBasePageAddr
			ld c, a

			ld a, (MapCurrentBlockY)		; Each row of blocks in the map is heavy as 512 bytes.
			and $1F
			or MapBaseAddr / 256 / 2		; Equivalent to or $40.
			ld h, a					; h_ = Y * 256
			ld a, (MapCurrentBlockX)
			rlca
			rl h					; h_ = h_ * 2 for completing the Y = 512 weight. But it also does, h_ = h_ + Int(BlockX / 128) * 256.
			and $FE
			ld l, a					; _l = (BlockX mod 128) * 2.

			ld b, 17				; Width in blocks of the screen.

.BlockLoop:		push bc
			
			ld a, c
			out ($FE), a

			ld e, (hl)
			inc hl
			ld a, (hl)				; Block ID range form 0 to 1023. Bits 15 to 10 unused for render graphics.

			push hl

			; call SpecialEffectsOnRow		; In/out [AE] = BlockID & block's attributes bits, in [HL] = OnMapAddr use it as like an ID, that way you don't process the same special effect one and again and again. in 17 - [B] = X positon (in blocks) from the left of the screen. Use (MapCurrentOffsetX) to know the offsetX in pixels, Use external methods to know if is drawing the upper screen border, or the botton screen border that way you know the Y position aswell.

			and 3					; It separates the BlockID from the Block Special Attributes. That can be used in the game for trigger special effects or just set up points where enemies appears.
			ld d, a

			call .BlockDraw
			pop hl
			inc hl

			pop bc
			djnz .BlockLoop
			
			ret

.BlockDraw:		ld a, TilePageAddr
			out ($FE), a

			ld hl, IndexBaseAddr			; In DE = Block ID.
			rl e
			rl d

			rl e
			rl d

			rl e
			rl d					; DE = DE * 8.

			add hl, de

			ld a, (MapCurrentOffsetY)
			and $04
			add a, l
			ld l, a
			ld a, h
			adc a, 0
			ld h, a					; HL = Block ID * 8 + (ScrollOffsetY and 4).

			ld e, (hl)
			inc hl
			ld d, (hl)
			inc hl

			push hl
			call .TileDraw
			pop hl

			ld e, (hl)
			inc hl
			ld d, (hl)

.TileDraw:		ld hl, TileBaseAddr			; In DE = tile ID.
			rl e
			rl d

			rl e
			rl d

			rl e
			rl d

			rl e
			rl d

			rl e
			rl d					; DE = DE * 32.

			add hl, de

			ld a, (MapCurrentOffsetY)
			and $03					; Each byte has 2 pixels, so it match with the offset range 0 - 3.
			add a,a
			add a,a
			add a,a					; Each pixel row is 4 bytes size, two lines from the tiles is 8 bytes size.

			ld e, a
			ld d, 0
			add hl, de				; HL = Tile ID * 32 + offsetY * 8.

			push ix
			pop de

			ldi
			ldi
			ldi
			ldi

			push de
			ld a, 128 + 8 - 4			; Each line of the screen takes 128 bytes to be stored (Sc5). If we will render a bit bigger (one block more, 8 bytes per screen line), it must be calculated here aswell.
			add a, e
			ld e, a
			ld a, d
			adc a, 0
			ld d, a

			ldi
			ldi
			ldi
			ldi
			pop ix

			ret






MapDrawColumn:		call .Int				; It sends to the VDP, two pixels wide, of the pointed map column, the column is pointed with (MapCurrentBlockX 0-255 (-ScreenWdith in blocks)) and (MapCurrentBlockY 0-127 (-ScreenHeight in blocks)) (MapCurrentOffsetX 0-7) (MapCurrentOffsetY 0-7). WARNING: It don't clips if Map overflow, so be in the scope!.
								; Out HL = buffer start.
			ld hl, MapBuffer			; VDP must be in Screen 5.
			ld a, (MapCurrentOffsetY)
			add a, a
			ld e, a
			ld d, 0
			add hl, de

			di

			ld a, 36 
			out ($99), a
			ld a, 17 + 128
			out ($99), a

			ld c, $9B

			ld de, (RenderingOnCurrentX)		; DX = X.
			out (c), e
			out (c), d

			ld a, (ScreenCurrentY)
			ld b, a
			out ($9B), a				; DY = CurrentVDPScroll#23.
			xor a
			out ($9B), a

			ld a, 2
			out ($9B), a
			xor a
			out ($9B), a				; NX = 2.

			xor a
			sub b					; It calculates the size from the actual position to the line 256 (Where the visual bitmap will rollup).

			and a					; Zero means 256.
			jr z, .TooLarger

			cp 212					; It must check that it won't go bigger than 212.
			jr c, .NotLarger

.TooLarger:		ld a, 212

.NotLarger:		ld b, a
			out ($9B), a
			xor a
			out ($9B), a				; NY = 256 - CurrentVDPScroll#23.
			push bc					; Saves the size to transfer in this half.

			outi					; Data#1.

			ld a, 0
			out ($9B), a				; DIX/DIY Down-Right.

			ld a, $F0
			out ($9B), a				; sends HMMC command #46.

			jr z, .Command1Completed		; If the size was just one, the previous OUTI activated the Z flag.

			ld a, 44 + 128				; Disable indirect register write auto-increment. And fix it to write in the register #44 always.
			out ($99), a
			ld a, 17 + 128
			out ($99), a

			otir					; Sends all the data, we don't know the size of the data, so we can't do custom faster commands here, like a serie of outi.

.Command1Completed:	pop bc

			ld a, 212
			sub b
			ld b, a					; Calculates what left to transfer.

			Jr z, .AllCompleted			; Escapes if there is nothing to transfer.

			ld a, 36 
			out ($99), a
			ld a, 17 + 128
			out ($99), a

			ld de, (RenderingOnCurrentX)		; DX = X.
			out (c), e
			out (c), d

			xor a
			out ($9B), a				; DY = 0.
			out ($9B), a

			ld a, 2
			out ($9B), a
			xor a
			out ($9B), a				; NX = 2.

			out (c), b				; NY = What left to transfer.
			out ($9B), a

			outi

			ld a, 0
			out ($9B), a				; DIX/DIY Down-Right.

			ld a, $F0
			out ($9B), a				; sends HMMC command #46.			

			jr z, .AllCompleted			; If only was 1 byte to transfer, it escapes.

			ld a, 44 + 128				; Disable indirect register write auto-increment. And fix it to write in the register #44 always.
			out ($99), a
			ld a, 17 + 128
			out ($99), a

			otir					; Sends all the data, we don't know the size of the data, so we can't do custom faster commands here, like a serie of outi.

.AllCompleted:		ei 
			ret

.Int:			ld ix, MapBuffer
			ld a, (MapCurrentBlockY)
			rlca
			rlca
			rlca
			and $07					; Each RAM page is capable to store only 32 rows blocks of the map.
			add a, MapBasePageAddr
			ld c, a					; It saves the Ram page for later use.

			ld a, (MapCurrentBlockY)		; Each row of blocks in the map is heavy as 512 bytes.
			and $1F
			or MapBaseAddr / 256 / 2
			ld h, a					; h_ = Y * 256
			ld a, (MapCurrentBlockX)
			rlca
			rl h					; h_ = h_ * 2 for completing the 512 heavy. But it also does, h_ = h_ + Int(BlockX / 128) * 256.
			and $FE
			ld l, a					; _l = (BlockX mod 128) * 2.

			ld b, 14				; Height in blocks of the screen.

.BlockLoop:		push bc
			push hl
			ld a, c
			out ($FE), a
			ld e, (hl)
			inc hl
			ld a, (hl)				; Block ID range form 0 to 1023. Bits 15 to 10 unused for render graphics.

			; call SpecialEffectsOnColumn		; In/out [AE] = BlockID & block's attributes bits, in [HL] = OnMapAddr use it as like an ID, that way you don't process the same special effect one and again and again. in 14 - [B] = Y positon (in blocks) from the top of the screen. Use (MapCurrentOffsetY) to know the offsetY in pixels, Use external methods to know if is drawing the left screen border, or the right screen border that way you know the X position aswell.

			and 3					; It separates the BlockID from the Block Special Attributes. That can be used in the game for trigger special effects or just set up points where enemies appears.
			ld d, a

			call .BlockDraw
			pop hl
			ld de, 256*2				; Each Block's Row in the map is 256 blocks * 16bits = 512 bytes. The map is 4 RAM Pages.
			add hl, de
			bit 6,h
			pop bc

			jr z, .BlockJump
								; It overflows from the current RAM Page.
			inc c
			res 6, h

.BlockJump:		djnz .BlockLoop
			
			ret

.BlockDraw:		ld a, TilePageAddr			; In DE = Block ID.
			out ($FE), a

			ex de,hl
			add hl,hl
			add hl,hl
			add hl,hl
			ld de, IndexBaseAddr
			add hl, de				; HL = Index base addr + BlockID * 8.

			ld a, (MapCurrentOffsetX)
			and $04

			jr z, .FirstTile
			inc hl
			inc hl					; HL = Block ID * 8 + (ScrollX and 4) / 2.

.FirstTile:		ld e, (hl)
			inc hl
			ld d, (hl)
			inc hl

			push hl
			call .TileDraw
			pop hl

			inc hl
			inc hl
			ld e, (hl)
			inc hl
			ld d, (hl)

.TileDraw:		ex de, hl				; In DE = tile ID.
			add hl,hl
			add hl,hl
			add hl,hl
			add hl,hl
			add hl,hl
			ld de, TileBaseAddr
			add hl,de				; HL = tile base addr + tileID * 32.

			ld a, (MapCurrentOffsetX)
			and $03					; Each byte has 2 pixels, so it match with the offset range 0 - 3.

			ld e, a
			ld d, 0
			add hl, de				; HL = Tile ID * 32 + (offset mod 4) * 2.

			ld de, 4
			ld b, 8

.PairLoop:		ld a, (hl)
			ld (ix+0), a
			inc ix
			add hl, de
			djnz .PairLoop
			ret






VPOKEPOS:		xor a					; in hl = vram address, from grauw website. In this IDE we only will work with 64K VRAM.
			rlc h					; MOD (ahl).
			rla
			rlc h
			rla
			srl h
			srl h
			di
			out ($99),a
			ld a,14+128
			out ($99),a
			ld a,l
			nop
			out ($99),a
			ld a,h
			or 64
			out ($99),a
			ret






INKEY:			ld hl,($F3FA)				; Out A = ASCII , CF = 1, nothing inputed.
			ld de,($F3F8)
			xor a
			sbc hl,de
			scf
			ret z
			call CHGET
			and a
			ret


CODE_END:






MapBlockX:			RB	1				; Map top/left start position.
MapOffsetX:		RB	1
MapBlockY:			RB	1
MapOffsetY:		RB	1

ScreenCurrentX:		RB	1				; Even values only. This is the current top/left position that the VDP is showing.
ScreenCurrentY:		RB	1				; Even values only.
RenderingOnCurrentX:	RB	1				; Even values only. This is the calculated position where the render will work.
RenderingOnCurrentY:	RB	1				; Even values only.
MapCurrentBlockX:	RB	1
MapCurrentOffsetX:	RB	1				; Offset 0 - 7. Valency 2 pixels.
MapCurrentBlockY:	RB	1
MapCurrentOffsetY:	RB	1				; Offset 0 - 7. Valency 2 pixels.

MapBaseAddr:		EQU	$8000				; 128 x 64 blocks per RAM page. Each blockID is two bytes. Bits 15 to 10 are unused. Can have other meaning.
MapBasePageAddr:	EQU	4				; This value can't be adjusted so easy, checks where is used first!.

IndexBaseAddr:		EQU	$6000				; 1024 indexes = 8192 bytes (2x2 tiles with 16bits tiles ID).

TileBaseAddr:		EQU	$8000				; Single page, TileSet = 512 tiles in Sc5 format = 16384 bytes.
TilePageAddr:		EQU	3

STICK:			EQU	$00D5				; A=STICK(A).
STRIG:			EQU	$00D8				; A=STRIG(A). A = $FF pressed.
CHGET:			EQU	$009F				; INPUT$(1)

ScreenHeightInBlocks:	EQU	15				; If the OffsetY = 7, it must process one extra block than that the screen will show.

MapBuffer:			RB	256+16			; Needed enlarged buffer that much because if OffsetX or OffsetY = 7, as the worst case, it needs to wast a lot of bytes at the start of the buffer.







