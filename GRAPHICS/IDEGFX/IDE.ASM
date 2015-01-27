; **************************************************
; * THIS FILE PROPERTIES                           *
; **************************************************






; COPYLEFT!!, THIS SOFTWARE IS UNDER THE GNU v3.0 license.
; Original author Guillermo Ricardo Flook, from Rosario, Santa Fe, Argentinia (http://www.FlulpyCrea.com.ar).
;
; COMPILATION INSTRUCTIONS = tniasm.exe ide.asm.
; About the compiler: Download the free version from www.tni.nl
;
; FILE VERSION: FOR RUN in MSX-BASIC environment.
;
; TAB = 8 spaces.
; TITLE ENVELOP = 50 ASTERISK LENGTH, ONE LINE.
; CODE MARGIN = 3 TABs.
; COMMENTS MARGIN = 8 TABs.
; VERTICAL SEPARATION FROM THE START OF PROGRAM AREA = 6 CRLF.
; VERTICAL SEPARATION BETWEEN ROUTINES = 6 CRLF.
; VERTICAL SEPARATION TO THE END OF PROGRAM AREA = 3 CRLF.
;
; MULTIPAGE CODE ADVICE:
; All @Name routines means that are BIOS/DOS CALLs or the allways available code's page,
; All Name routines means that are stored in the switcheable first code's page,
; All _Name routines means that are stored in the switcheable second code's page,
; All __Name routines means that are stored in the switcheable third code's page.

; ABOUT FAR CALLS AND JUMPS:
; those must be called this way 'ld iy, name  Call @FarCallToPage1' or 'ld iy, name  Jp @FarJumpToPage1',
; those must be called this way 'ld iy, _name  Call @FarCallToPage2' or 'ld iy, _name  Jp @FarJumpToPage2',
; those must be called this way 'ld iy, __name  Call @FarCallToPage3' or 'ld iy, __name  Jp @FarJumpToPage3'.
; and finally 'call @Name' or 'jp @Name'.


; **************************************************
; * STRUCTURES DECLARATIONS                        *
; **************************************************






ORG $0

BunchHeader:
	.Name:				RB 16			; Identification for linking and project information.
	.Path:				RB 128			; Reserved for drive + path + filename string ASCIIZ construction for DOS2 future support. If NULL = current drive and directory.
	.Reserved:			RB 96			; Reserved for any other feature not though at this time.
	.FormatID:			RB 1
	.Customs:			RB 64			; 17 bytes for linking to bunch name (incl. the nullchar). After the its first 17 bytes, each format can use the remain bytes freely. In MapScene format, is 1 WORD for Width value + next 1 WORD for height value.
	.Status:			RB 128			; Used for storing a backup of all the console's variables that is interesting to keep for browsing this bunch later. This way the console has a continuity effect when switching from browsing several bunchs.
	.Size:



ORG BunchHeader.Customs + 32

CompileOpts:
	.Configured:			RB 1			; 0 = no, <> 0 yes!.
	.SaveAs:			RB 1			; 0 = BIN, 1 = BSAVE, 2 = TXT.
	.BSaveStartAddr:		RW 1			; Custom start address when SaveAs is BSAVE.
	.Filename:			RB 13			; incl the nullchar.



ORG $0

BITMAPFILEHEADER:
 	.bfType:			RB 2			; ="BM".
 	.bfSize:			RB 4			; .BMP file size.
 	.bfReserved1:			RB 2
 	.bfReserved2:			RB 2
 	.bfOffBits:			RB 4			; pixels array = BITMAPFILEHEADER address + .bfoffBits.
	.Size:



ORG $0

BITMAPINFOHEADER:
	.biSize:			RB 4			; BITMAPINFOHEADER size.
	.biWidth:			RB 4			; unsigned bitmap width (it must be a multiplier of 4).
	.biHeight:			RB 4			; bitmap height, if negative the array is top->bottom, else is bottom->top.
	.biPlanes:			RB 2			; = 1 (target planes).
	.biBitCount:			RB 2			; bits per pixel. 32, 24, 16, 8, 4 can be usefull.
	.biCompression:			RB 4			; We will support BI_RGB and BI_BITFIELDS by now.
	.biSizeImage:			RB 4
	.biXPelsPerMeter:		RB 4			; it is for correctly showing the image when the target monitor has an unknow DPI at programming time. We will assume that the bitmap is meant to be squared if width/height match (1:1). Hmmm is known that the MSX is not 1:1 ratio.
	.biYPelsPerMeter:		RB 4			; it is for correctly showing the image when the target monitor has an unknow DPI at programming time. We will assume that the bitmap is meant to be squared if width/height match (1:1). Hmmm is known that the MSX is not 1:1 ratio.
	.biClrUsed:			RB 4			; Number of palettes?.
	.biClrImportant:		RB 4			; = 0 all colours are important.
	.Size:



; **************************************************
; * CONSTANTS                                      *
; **************************************************






BI_RGB:					EQU 0
BI_RLE8:				EQU 1
BI_RLE4:				EQU 2
BI_BITFIELDS:				EQU 3
BI_JPEG:				EQU 4
BI_PNG:					EQU 5

@BIOS_RESET:				EQU $0			; MSX CONSTANTS.
@WRTVDP:				EQU $47			; C = reg number, B = data.
VDPREG0:				EQU $F3DF		; Value of VDP register 0.
VDPREG8:				EQU $FFE7		; Value of VDP register 8.
@CHGMOD:				EQU $5F			; A = screen mode.
@CHGET:					EQU $009F		; INPUT$(1)
@BEEP:					EQU $00C0
KEYBRow6:				EQU $FBEB

@BDOSWRAPPED:				EQU $F37D
DiskErrorHandler:			EQU $F323
AbortHandler:				EQU $F1E6

MenuLeftMargin:				EQU $02
MenuTopMargin:				EQU $02

ConsoleStartLine:			EQU $0C
BunchTitleBarHeight:			EQU 10
BunchTitleBarUpperMargin:		EQU 2
BunchTitleBarLeftMargin:		EQU 2
BunchUpperSeparator:			EQU 4
BunchLowerSeparator:			EQU 2

PuzzlerBottonRightOnEditor:		EQU 214 + 256 * 106	; By reason of Screen small resolution, the puzzler must be placed on its best screen area according to what the user is doing.
PuzzlerBottonRightOnSelector:		EQU 214 + 256 * 106
PuzzlerBottonRightOnEditor16:		EQU 182 + 256 * 100
PuzzlerBottonRightOnSelector16:		EQU 182 + 256 * 100
PuzzlerBottonRightOnEditor32:		EQU 108 + 256 * 54
PuzzlerBottonRightOnSelector32:		EQU 108 + 256 * 84	; It overlaps a bit the selector.

FormatID:
	.TileSc2:			EQU 0
	.TileSc5:			EQU 1
	.TileSc8:			EQU 2
	.SpriteMSX2:			EQU 3
	.SpriteMSX1:			EQU 4
	.PaletteSet:			EQU 5
	.TileSc5_16:			EQU 9
	.TileSc8_16:			EQU $0A
	.TileSc5_32:			EQU $0D
	.TileSc8_32:			EQU $0E
	.ImageFileHolder:		EQU $0F
	.FileHolder:			EQU $07

	.MapIndID:			EQU $10
	.MapIndIDMask:			EQU $F0
	.MapIndYTilesDoubler:		EQU $01
	.MapIndXTilesDoubler:		EQU $02
	.MapInd16bitsTileNumber:	EQU $04
	.MapInd16bitsEntryCount:	EQU $08

	.MapSceneID:			EQU $20
	.MapSceneIDMask:		EQU $F0
	.MapScene16Bits:		EQU $01



; **************************************************
; * OUTPUT FILE FORMAT: IDEEXT.BIN                 *
; **************************************************






FNAME "ideext.bin"
FORG $0

	DB $FE
	DW $8000
	DW IDEEXT_END + $4000 - 1
	DW @RUN

ORG $4000



; **************************************************
; * DATA                                           *
; **************************************************






MainMenuData:		DB "Disk",0,"Project",0,0

DiskMenuData:		DB 5,14,"SaveAll",0,"Save ...",0,"Load ...",0,"Import image",0,"CompileAll",0,"Compile ...",0,"Exit",0,0

ProjectMenuData:	DB 29,14,"New ...",0,"Delete",0,"Set Bunch Link",0,"Set Compile Options",0,"Select bunch in view",0,"Project information",0,0

PrjNewMenuData:		DB 40,14,"PaletteSet",0,"TileSet",0,"Metatiling map chart",0,"Map Scene",0,"MSX1 Sprites",0,"MSX2 Sprites",0,0

BoxNewTileSetData:	DB 5,40,"How many meta/tiles?, and wich format?:",0,5,"256",0,1,"Screen 2 format.",0,"Scr5 format 8X8 pixels.",0, "Scr5 format 16x16 pixels.",0,"Scr5 format 32x32 pixels.",0,"Scr8 format 8x8 pixels.",0,"Scr8 format 16x16 pixels.",0,"Scr8 format 32x32 pixels.",0,0

BoxNewMapIndexator1Data:DB 15,40,"Selects the metatile size:",0,0,1,"Grouping tiles in 2x2y.",0,"Grouping tiles in 2x4y.",0,"Grouping tiles in 4x2y.",0,"Grouping tiles in 4x4y.",0,0

BoxNewMapIndexator2Data:DB 15,40,"For accessing how many tiles?:",0,0,1,"256 tiles only.",0,"more than 256 tiles (16bits).",0,0

BoxNewMapIndexator3Data:DB 15,40,"How many metatiles to create?:",0,0,1,"Up to 256 metatiles.",0,"more than 256 metatiles.",0,0

BoxNewMapIndexator4Data:DB 25,40,"How many metatiles to create?:",0,5,"1024",0,0,0

BoxNewMapSceneXData:	DB 25,40,"Input the width in meta/tiles:",0,5,"16",0,0,0

BoxNewMapSceneYData:	DB 25,40,"Input the height in meta/tiles:",0,5,"12",0,0,0

BoxNewMapSceneBData:	DB 25,40,"The map will be described using?",0,0,1,"up to 256 meta/tiles.",0,"more than 256 meta/tiles.",0,0

BoxNewSpriteData:	DB 25,40,"Input the sprites count:",0,5,"64",0,0,0

BoxNewFilenameSprite1Data:DB 20,40,"Writes a new sprites MSX1 filename:",0,12,".sp1",0,0

BoxNewFilenameSprite2Data:DB 20,40,"Writes a new sprites MSX2 filename:",0,12,".sp2",0,0

BoxNewFilenamePalData:	DB 41,40,"Writes a new PaletteSet filename:",0,12,".pl",0,0

BoxNewFilenameData:	DB 41,40,"Writes a new tileset filename:",0,12,".ts",0,0

BoxNewFilenameIndData:	DB 5,40,"Writes a new metatiling chart filename:",0,12,".mi",0,0

BoxNewFilenameMapData:	DB 41,40,"Writes a new map filename:",0,12,".mp",0,0

BoxLoadFilenameData:	DB 78,40,"Input the filename to load:",0,12," ",0,0

BoxLinkMsgData:		DB 3,40,"What to link first, and then to what:",0,0,0,0

BoxSureExitData:	DB 25,40,"Sure you want to quit?",0,0,1,"No.!",0,"Yes.",0,0

BoxCompileOptions:	DB 15,40,"Input the filename to export as:",0,12,".bin",0,1,"As raw binary file.",0,"As BLOADable file.",0,"As text file 'DB xx, xx ...'.",0,0

BoxCompileOptions2:	DB 5,40,"RAM/VRAM address for BLOAD'S header:",0,5,"32768",0,0,0

BoxSureCancelEdit:	DB 3,110,"Sure Cancel?",0,0,1,"No!.",0,"Yes.",0,0

AttribSetData:		DB 15,90,"Input the attribute code &H:",0,4,"0000",0,0,0

GotoData:		DB 25,60,"Go to position X?",0,5,0,0,0
GotoYData:		DB 25,60,"Go to position Y?",0,5,0,0,0

BoxErrorOverflowData:	DB 20,60,"Error: Value out of range.",0,0,0
BoxErrorOutOfMemoryData:DB 20,60,"Error: Out Of Memory.",0,0,0
BoxErrorBadFileNameData:DB 20,60,"Error: Bad filename or extension.",0,0,0
BoxErrorBadData:	DB 20,60,"Error: Corruption in the user data.",0,0,0
BoxErrorFormatsMisMatch:DB 10,60,"Error: Formats mismatch no linkables.",0,0,0
BoxErrorLinkMissing:	DB 10,60,"Error: Linkage is mandatory.",0,0,0
BoxErrorFileNotFound:	DB 10,60,"Error: File not found.",0,0,0
BoxErrorDiskError:	DB 10,60,"Error: Disk error.",0,0,0
BoxErrorInvalidFormat:	DB 10,60,"Error: Invalid file format.",0,0,0
BoxErrorNotEnoughtRAM:	DB 10,60,"Error: File too big or bad format.",0,0,0
BoxErrorAlreadyExists:	DB 10,60,"Error: Filename already used.",0,0,0
BoxErrorInvalidSize:	DB 10,60,"Error: Invalid size inputted.",0,0,0
BoxErrorTooBigForBload:	DB 10,60,"Error: Bload header overflow."
BoxErrorImageFormat:	DB 10,60,"Error: Image format not supported.",0,0,0

MSX1PaletteSetData:	DW $0,$0,$0611,$0733,$0117,$0327,$0151,$0627,$0171,$0373,$0661,$0664,$0411,$0265,$0555,$0777

ActionMenu1Data:	DB 110, (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10)
			DB "XMirror",0,"YMirror",0,"Rotate",0,"Shift Left",0,"Shift Right",0,"Shift Up",0,"Shift Down",0,0

ActionMenu2Data:	DB 120, (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10)
			DB "Tile Clear",0,"Fill pattern",0,"Pattern NOT",0,"Chroma Sw. Sc2",0,0

ActionMenu2SprData:	DB 120, (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10)
			DB "Clear",0,"Fill",0,"Pattern NOT",0,0

CopyMenuData:		DB 120, (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10)
			DB "Copy",0,"Swap",0,"Cancel",0,0

IDEColorTheme:		DB $FF			; .MenuCursorForeColor.
			DB $00			; .MenuCursorBackColor.
			DB $FF			; .MenuForeColor.
			DB $55			; .MenuBackGroundColor.
			DB $FF			; .MenuBorderColor.
			DB $00			; .TextBoxForeColor.
			DB $FF			; .TextBoxBackColor.
			DB $00			; .CheckBoxHitTrueColor.
			DB $FF			; .CheckBoxBackColor.
			DB $C0			; .MsgBoxCursorColor.
			DB $00			; .BunchTitleBarForeColor.
			DB $FF			; .BunchTitleBarBackColor.
			DB $FF			; .OutlineCursorColor.
			DB $FF			; .OutlineColor.
			DB $92			; .OutlineSecondaryColor.
			DB $49			; .OutlineBackGroundColor.
			DB $C0			; .OutlinePrimaryRemarkColor.
			DB $03			; .OutlineSecondaryRemarkColor.
			DB $5D			; .OutlineRED.
			DB $E9			; .OutlineGREEN.
			DB $27			; .OutlineBLUE.
			DB $00			; .ScreenBackgroundColor.



; **************************************************
; * PROGRAM                                        *
; **************************************************






EXTRUN:			ld hl, VAR_START			; It erase the variable area.
			ld de, VAR_START+1
			ld bc, VAR_END - VAR_START - 1
			ld (hl),0
			ldir

			ld (StackPointerBackUpForExit), sp	; It saves the original stack position for clean exit to BASIC.

			ld a, $39				; SCF.
			ld (JPPixelRead), a			; Initialize import from image function. So, in the tile editor when pressing 'V' key, will not crash.
			ld a, $C9				; RET.
			ld (JPPixelRead+1), a

			ld hl, MSX1PaletteSetData
			ld de, CurrentPaletteSetBuffer
			ld bc, 32
			ldir

			ld a, (VDPREG8)
			or $20
			ld b, a
			ld c, 8
			call @WRTVDP				; TP = 1, PAL0 non transparent.

			call SetPalette				; It applies the default palettes.

			ld a, $FF
			ld (IsOnPaletteScreenMode), a		; It forces the PREPARE_SCREEN to work for the first time.
			xor a
			call PREPARE_SCREEN			; Default is in Sc8. Unless the consoles changes it.

			ld hl, (DiskErrorHandler)
			ld (DiskErrorHandlerHookUpBackUp), hl	; It saves the original hookup for restoration when this program exit.

			ld hl, @DiskErrorHandlerPTR 
			ld (DiskErrorHandler), hl		; It hooks its own disk error handler routine.

			ld hl, (AbortHandler)
			ld (AbortHandlerHookUpBackUp), hl

			ld hl, @abort
			ld (AbortHandler), hl

			jp ConsoleRender






PREPARE_SCREEN:		and a					; In a = 0 Sc8, a <> 0 Sc7.
			jr z, .NeedsSc8				; Before to call this routine set the palletes.
			
			xor a
			ld (ColorThemeWasChanged), a
								; Needs a pallete pick.
			call UpdateColorTheme			; It can't skips tasks here because maybe the current palette bunch was changed, or the current was deleted and was activated the MSX1 default.
			
			ld a, (VDPREG8)				; Disable sprites engine. For speed up VDP-COPROCESSOR.
			or $02
			ld b, a
			ld c, 8
			call @WRTVDP

			ld a,(VDPREG0)
			and $FB
			ld b, a
			ld c, 0
			call @WRTVDP				; Change to Sc7.

			ld a, (ScreenBackgroundColor)
			and $0F
			ld b, a
			ld c, 7
			call @WRTVDP				; Changes the border color equal as the screen background.

			ld a, $FF
			ld (IsOnPaletteScreenMode),a

			ld a, (ColorThemeWasChanged)
			and a
			ret z

			call MENUBAR.BoxRedraw
			jp MENUBAR.RoutineRedraw

.NeedsSc8:		ld a, (IsOnPaletteScreenMode)
			and a
			ret z

			ld a, $FF				; if before was a pal screen mode and now Sc8, it means that now the theme color will be changed.
			ld (ColorThemeWasChanged),a

			ld hl, IDEColorTheme
			ld de, VarColorSetStart
			ld bc, VarColorSetEnd - VarColorSetStart
			ldir

			ld a, (VDPREG8)				; Disable sprites engine. For speed up VDP-COPROCESSOR.
			or $02
			ld b, a
			ld c, 8
			call @WRTVDP

			ld a,(VDPREG0)
			or $04
			ld b, a
			ld c, 0
			call @WRTVDP				; Change to Sc8.
			
			ld a, (ScreenBackgroundColor)
			ld b, a
			ld c, 7
			call @WRTVDP				; Changes the border color equal as the screen background.

			xor a
			ld (IsOnPaletteScreenMode),a

			call MENUBAR.BoxRedraw
			jp MENUBAR.RoutineRedraw






UpdateColorTheme:	ld hl, IDEColorTheme			; It choice the best palettes to use for the IDE.
			ld de, VarColorSetStart
			ld b, VarColorSetEnd - VarColorSetStart

.PickLoop:		ld a, (hl)
			push hl
			push de
			push bc
			call PalChoice				; In = A GGGRRRBB color, out A = palette picked.
			pop bc
			pop de
			ld l,a
			ld a,(de)
			cp l
			jr z, .NoChanged			

			ld a,l
			ld (de),a
			ld a, $FF
			ld (ColorThemeWasChanged), a

.NoChanged:		pop hl
			inc hl
			inc de
			djnz .PickLoop
			ret






SetPalette:		ld hl, CurrentPaletteSetBuffer
			xor a
			di
			out ($99),a
			ld a, 16 + 128
			ei
			out ($99),a
			ld bc,$209A
			otir
			ret






PalChoice:		ld hl, CurrentPaletteSetBuffer		; in = A GGGRRRBB color, out A = palette picked.
			exx

			ld b, 16				; palette format is = xRRRxBBB
			ld c, 0					;                     xxxxxGGG
			
			ld e, $FF				; Choice qualification $FF = worst. $00 = match perfect.
			ld d, 0					; d = current best choice (palette number).

.PickLoop:		push af

			and $03					; First examines the BLUE difference.
			add a,a					; As blue lacks a bit in Sc8 format, it increases the valency to a match with the palette format.
			ld l, a

			exx
			ld a,(hl)				; Reads the current palette.
			exx
			and $07
			sub l					; It return a signed value with the difference.

			call .Normalize				; A = ABS(A).
			ld h, a					; Initialize the current qualification.

			pop af
			push af
			rra
			rra
			and $07
			ld l, a

			exx
			ld a,(hl)
			exx
			rra
			rra
			rra
			rra
			and $07
			sub l

			call .Normalize
			add a, h				; Sums the qualification.
			ld h,a

			pop af
			push af
			rlca
			rlca
			rlca
			and $07
			ld l, a

			exx
			inc hl
			ld a,(hl)
			inc hl
			exx
			and $07
			sub l

			call .Normalize
			add a, h				; Sums the qualification.

			cp e					; Compares the qualifications to see if the current is better.
			jr nc, .Worst

			ld e, a					; Saves the new qualification.
			ld d, c					; Saves the palette number best qualified.

.Worst:			pop af
			inc c
			djnz .PickLoop

			ld a, d					; Output the choice.

			rlca
			rlca
			rlca
			rlca
			or d					; It duplicates the palette number like color = AA BB CC. Because we will handle Sc7 as 256x212 and not 512x212.

			ret

.Normalize:		cp $80					; A = ABS(A).
			jr c, .POWER2

			cpl
			inc a

.POWER2:		push de
			push bc
			push hl
			ld h,a
			ld e,a
			ld d,0
			ld l,d
			ld b,8
.Mult8_Loop:
			add hl,hl
			jr nc, .Mult8_NoAdd
			add hl,de
.Mult8_NoAdd:
			djnz .Mult8_Loop
			ld a,l
			pop hl
			pop bc
			pop de
			ret



; **************************************************
; * MAIN MENU & ITs FUNCTIONs.                     *
; **************************************************






MENUBAR:		call @KBCLEAR				; Empty KEYBUF.
			call .BoxRedraw
			call .RoutineRedraw
			jr .CtrlLoop

.BoxRedraw:		ld hl,0					; top/left.
			ld bc, $0CFF				; height/Width.
			ld a, (MenuBorderColor)			; A = Color.
			call @SQUARE

			ld hl,$0101				; top/left.
			ld bc, $0AFD				; height/Width.
			ld a, (MenuBackGroundColor)		; A = Color.
			jp @BLOCKFILL

.CleanUp:		ld a, ConsoleStartLine			; It erases the screen as a sort of clean up.
			jp @CLSLP

.RoutineRedraw:		ld ix, MainMenuData			; Redraw menubar without redrawing its background and border.
			push ix
			pop hl
	
			ld de, MenuTopMargin * 256 + MenuLeftMargin
			ld c,0

.Loop:			ld a,(MBItemIndex)
			cp c
			jr nz, .Normal

			ld a, (MenuCursorForeColor)
			ld (RenderForeColor),a
			ld a, (MenuCursorBackColor)
			ld (RenderBackColor),a
			jr .Cnt

.Normal:		ld a,(MenuForeColor)
			ld (RenderForeColor),a
			ld a,(MenuBackGroundColor)
			ld (RenderBackColor),a			; in RenderForeColor: RenderBackColor.

.Cnt:			push bc
			call @STRDRAWZ
			pop bc
			inc hl					; It sets HL on the next string.
			inc c
			ld a,c
			ld (MBItemCount),a			; Registra cuantos items tiene.

			ld a,(hl)				; Checks if the next string is the <EOD>.
			and a
			ret z

			ld a, 12
			add a,e
			ld e,a					; Inserts 2 spaces.
			jr .Loop
			ret

.Redraw:		call .CleanUp
			call .RoutineRedraw

.CtrlLoop:		ld a,(MBItemIndex)
			and a
			ld ix, DiskMenuData
			jr z, .PopUp
			dec a
			ld ix, ProjectMenuData
	
.PopUp: 		call MENUPOPUP
			jr nc, .ItemHit

			and a
			ret z					; The user pressed ESC.

			cp $FF
			jr z, .Left

			cp $01
			jr z, .Right

			jr .CtrlLoop
	
.Left:			ld a,(MBItemIndex)
			and a
			jr z, .CtrlLoop
			dec a
			ld (MBItemIndex),a
			jp .Redraw

.Right:			ld a,(MBItemCount)
			dec a
			ld c,a
			ld a,(MBItemIndex)
			cp c
			jr z, .CtrlLoop
			inc a
			ld (MBItemIndex),a
			jp .Redraw

.ItemHit:		ld b,a
			ld a,(MBItemIndex)
			and a
			jr z, .DskMnu
			dec a
			jp z, .PrjMnu
			jp .Redraw

.DskMnu:		ld a,b
			and a
			jp z, .SaveAll
			dec a
			jp z, .SaveABunch
			dec a
			jp z, .Load
			dec a
			ld iy, __ImportBmp
			jp z, @FarCallToPage3
			dec a
			ld iy, _CompileAll
			jp z, @FarCallToPage2
			dec a
			ld iy, __Compile
			jp z, @FarCallToPage3
			dec a
			jp z, .HitExit
			jp .Redraw

.PrjMnu:		ld a,b
			and a
			jr z, .ItemNew
			dec a
			jp z, .Delete
			dec a
			jp z, .SetLink
			dec a
			ld iy, _SetCompileOptions
			jp z, @FarCallToPage2
			dec a
			jp z, BunchSelector
			dec a
			ld iy, _ProjectInfo
			jp z, @FarCallToPage2
			jp .Redraw

.ItemNew:		ld ix, PrjNewMenuData
			call MENUPOPUP
			jp c, .Redraw				; Back to the menubar redraw.
								; Is a menu hit!!!.
			and a
			jp z, .NewPaletteSet
			dec a
			jp z, .NewTileSet
			dec a
			jp z, .NewEncMapChart
			dec a
			jp z, .NewMapScene
			dec a
								; WARNING: Both "New Sprite MSx1" and "New Sprite MSX2" must be the last two items in the sub menu on the given order.
			ld a, FormatID.SpriteMSX1		; NEW SPRITE.
			jr z, .SPFS
			ld a, FormatID.SpriteMSX2

.SPFS:			ld (CreatingFormat),a

.NewSpriteTryAgain:	ld ix, BoxNewSpriteData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call @VAL
			jr nc, .SPValOk

			call .ErrOverFlow			; The inputed number overflows.
			jr .NewSpriteTryAgain

.SPValOk:		ld (CreatingAmmount),de

			ld a, e
			or d
			jr nz, .SPValOk2

			call .ErrorInvalidInputted
			jr .NewSpriteTryAgain

.SPValOk2:		ld a, (CreatingFormat)
			cp FormatID.SpriteMSX1
			ld ix, BoxNewFilenameSprite1Data
			jr z, .SPBOX
			ld ix, BoxNewFilenameSprite2Data
.SPBOX:			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call NormalizeFileName
			jr nc, .SPOk

			call .ErrBadFN
			jr .SPValOk2				; Asks again.
	
.SPOk:			ld hl, MsgBoxBuffer
			call FindBunchByName			; Checks if the name is not already in use.
			jr c, .SPOk2

			call .ErrorAlreadyUsed
			jp .SPValOk2				; Asks again.

.SPOk2:			ld de,(CreatingAmmount)
			ld hl,0
			ld a, (CreatingFormat)

			ld iy, _CalculateRawSize
			call @FarCallToPage2
			jp c, .Err

			ld iy, _CreateBunch
			call @FarCallToPage2			; In hlde = raw data size without header.
			jp c, .Err
			ret

.NewPaletteSet:		ld ix, BoxNewFilenamePalData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call NormalizeFileName
			jr nc, .NewPalOk

			call .ErrBadFN
			jr .NewPaletteSet
	
.NewPalOk:		ld hl, MsgBoxBuffer
			call FindBunchByName			; Checks if the name is not already in use.
			jr c, .NewPalOk2

			call .ErrorAlreadyUsed
			jp .NewPaletteSet

.NewPalOk2:		ld a, FormatID.PaletteSet
			ld (CreatingFormat),a

			ld de, 32				; Pallete set size.
			ld hl, 0
			ld iy, _CreateBunch			; In hlde = raw data size without header.
			call @FarCallToPage2

			ret nc

			call .ErrOutOfMemory
			jp .Redraw

.NewTileSet:		ld hl, MsgBoxCheckValues
			ld (hl),$FF
			inc hl
			xor a
			ld (hl),a
			inc hl
			ld (hl),a
			inc hl
			ld (hl),a
			inc hl
			ld (hl),a
			inc hl
			ld (hl),a
			inc hl
			ld (hl),a				; Default = Screen2 Tile Option.

.TSTryAgain:		ld ix, BoxNewTileSetData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call @VAL
			jr nc, .TSValOk

			call .ErrOverFlow			; The inputed number overflows.
			jr .TSTryAgain

.TSValOk:		ld (CreatingAmmount),de

			ld a, e
			or d
			jr nz, .TSValOk2

			call .ErrorInvalidInputted
			jr .TSTryAgain

.TSValOk2:		ld hl, MsgBoxCheckValues
			xor a

			or (hl)		
			ld c, FormatID.TileSc2
			jr nz, .TsFormatOk
			inc hl
			or (hl)
			ld c, FormatID.TileSc5
			jr nz, .TsFormatOk
			inc hl
			or (hl)
			ld c, FormatID.TileSc5_16
			jr nz, .TsFormatOk
			inc hl
			or (hl)
			ld c, FormatID.TileSc5_32
			jr nz, .TsFormatOk
			inc hl
			or (hl)
			ld c, FormatID.TileSc8
			jr nz, .TsFormatOk
			inc hl
			or (hl)
			ld c, FormatID.TileSc8_16
			jr nz, .TsFormatOk
			ld c, FormatID.TileSc8_32			

.TsFormatOk:		ld a, c
			ld (CreatingFormat),a

.CreateDo:		ld ix, BoxNewFilenameData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call NormalizeFileName
			jr nc, .TSOk

			call .ErrBadFN
			jr .CreateDo
	
.TSOk:			ld hl, MsgBoxBuffer
			call FindBunchByName			; Checks if the name is not already in use.
			jr c, .TSOk2

			call .ErrorAlreadyUsed
			jp .CreateDo

.TSOk2:			ld de,(CreatingAmmount)
			ld hl,0
			ld a, (CreatingFormat)

			ld iy, _CalculateRawSize
			call @FarCallToPage2
			jr c, .Err

			ld iy, _CreateBunch
			call @FarCallToPage2			; In hlde = raw data size without header.
			ret nc

.Err:			call .ErrOutOfMemory
			jP .Redraw

.ErrorInvalidInputted:	ld ix, BoxErrorInvalidSize
			jr .ErrMsgBox

.ErrorAlreadyUsed:	ld ix, BoxErrorAlreadyExists
			jr .ErrMsgBox

.ErrorNotEnoughtRAM:	ld ix, BoxErrorNotEnoughtRAM
			jr .ErrMsgBox

.ErrorDiskError:	ld ix, BoxErrorDiskError
			jr .ErrMsgBox

.ErrorInvalidFormat:	ld ix, BoxErrorInvalidFormat
			jr .ErrMsgBox

.ErrorFileNotFound:	ld ix, BoxErrorFileNotFound
			jr .ErrMsgBox

.ErrorLinkage:		ld ix, BoxErrorLinkMissing
			jr .ErrMsgBox

.ErrFormatsMismatch:	ld ix, BoxErrorFormatsMisMatch
			jr .ErrMsgBox

.ErrDataCorrupt:	ld ix, BoxErrorBadData
			jr .ErrMsgBox

.ErrOutOfMemory:	ld ix, BoxErrorOutOfMemoryData
			jr .ErrMsgBox

.ErrBadFN:		ld ix, BoxErrorBadFileNameData
			jr .ErrMsgBox

.ErrUnsupportedImage:	ld ix, BoxErrorImageFormat
			jr .ErrMsgBox

.ErrOverFlow:		ld ix, BoxErrorOverflowData

.ErrMsgBox:		push ix
			call @BEEP
			pop ix
			jp MSGBOX

.NewEncMapChart:	ld hl, MsgBoxCheckValues
			ld (hl),$FF
			inc hl
			xor a
			ld (hl),a
			inc hl
			ld (hl),a
			inc hl
			ld (hl),a				; Default = Blocks of 2x2.

			ld ix, BoxNewMapIndexator1Data
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxCheckValues

			ld b,4
			ld c,$FF

.GrLoop:		ld a,(hl)
			inc hl
			inc c
			and a
			jr nz, .GrOk
			djnz .GrLoop

.GrOk:			ld a,c
			ld (CreatingFormat),a			

			ld hl, MsgBoxCheckValues
			ld (hl),$FF
			inc hl
			ld (hl),0

			ld ix, BoxNewMapIndexator2Data
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxCheckValues
			ld a,(hl)
			and a
			jr nz, .TnOk
								; > 256 tiles.
			ld a, (CreatingFormat)
			or FormatID.MapInd16bitsTileNumber
			ld (CreatingFormat),a			

.TnOk:			ld hl,256
			ld (CreatingAmmount),hl

			ld a, (CreatingFormat)
			or FormatID.MapIndID
			ld (CreatingFormat),a				

			ld ix, BoxNewMapIndexator3Data
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxCheckValues
			ld a,(hl)
			and a
			jr nz, .EnOk
								; > 256 entries.
			ld a, (CreatingFormat)
			or FormatID.MapInd16bitsEntryCount
			ld (CreatingFormat),a

.IndTryAgain:		ld ix, BoxNewMapIndexator4Data
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call @VAL
			jr nc, .IndValOk

			call .ErrOverFlow
			jr .IndTryAgain

.IndValOk:		ld (CreatingAmmount),de
			ld a, e
			or d
			jr nz, .EnOk

			call .ErrorInvalidInputted
			jr .IndTryAgain

.EnOk:			ld ix, BoxNewFilenameIndData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call NormalizeFileName
			jr nc, .EnOk2

			call .ErrBadFN
			jr .EnOk
	
.EnOk2:			ld hl, MsgBoxBuffer
			call FindBunchByName			; Checks if the name is not already in use.
			jr c, .EnOk3

			call .ErrorAlreadyUsed
			jr .EnOk

.EnOk3:			ld de,(CreatingAmmount)
			ld hl,0
			ld a, (CreatingFormat)

			ld iy, _CalculateRawSize
			call @FarCallToPage2
			jp c, .Err

			ld iy, _CreateBunch			; In hlde = raw data size without header.
			call @FarCallToPage2
			ret nc

			jp .Err

.NewMapScene:		ld ix, BoxNewMapSceneXData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call @VAL
			jr nc, .MapWValOk

			call .ErrOverFlow
			jr .NewMapScene

.MapWValOk:		ld (CreatingWidth),de
			ld a, e
			or d
			jr nz, .NewMapB1

			call .ErrorInvalidInputted
			jr .NewMapScene

.NewMapB1:		ld ix, BoxNewMapSceneYData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call @VAL
			jr nc, .MapHValOk

			call .ErrOverFlow
			jr .NewMapB1

.MapHValOk:		ld (CreatingHeight),de
			ld a, e
			or d
			jr nz, .NewMapB9

			call .ErrorInvalidInputted
			jr .NewMapB1

.NewMapB9:		ld hl, MsgBoxCheckValues
			ld (hl), $FF
			inc hl
			ld (hl), 0

			ld ix, BoxNewMapSceneBData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxCheckValues
			ld a,(hl)
			and a
			ld a, FormatID.MapSceneID
			jr nz, .MapFormatOk
			ld a, FormatID.MapSceneID + FormatID.MapScene16Bits

.MapFormatOk:		ld (CreatingFormat),a	

.NewMapB2:		ld ix, BoxNewFilenameMapData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call NormalizeFileName
			jr nc, .NMOk

			call .ErrBadFN
			jr .NewMapB2
	
.NMOk:			ld hl, MsgBoxBuffer
			call FindBunchByName			; Checks if the name is not already in use.
			jr c, .NMOk2

			call .ErrorAlreadyUsed
			jr .NewMapB2

.NMOk2:			ld de, (CreatingWidth)
			ld bc, (CreatingHeight)

			call @Mult32				; Thanks grauw. BCHL = BC*DE

			ex de,hl
			ld l, c
			ld h, b					; hlde = raw size needed.

			ld a, (CreatingFormat)
			and FormatID.MapScene16Bits
			jr z, .NM8

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; hlde = hlde * 2.

.NM8:			ld iy, _CreateBunch
			call @FarCallToPage2			; In hlde = raw data size without header.
			ret nc
	
			jp .Err

.Delete:		ld ix, UserAreaCpyBuffer
			ld (ix+0), 2
			ld (ix+1), ConsoleStartLine + BunchLowerSeparator
			inc ix
			inc ix
			call ListsBunchs
			jp c, .Redraw

			ld ix, UserAreaCpyBuffer
			call MENUPOPUP
			jp c, .Redraw				; The user pressed ESC.

			ld c, a					; The user hits a given bunch.
			ld b, 0					; bc = bunch index.
			ld iy, _BUNCH_DELETE
			call @FarCallToPage2
			ret nc

			call .ErrDataCorrupt
			jp .Redraw

.SetLink:		ld ix, BoxLinkMsgData			; The linking allows like: link a tileset to use a PaletteSet, link an indexator map to a tileset, link a map to an indexator, and linking a SpriteSet to a PaletteSet only if the format matchs, like 8bits with 8bits, 16bits with 16bits!.
			call MSGBOX

			ld ix, UserAreaCpyBuffer
			ld (ix+0), 2
			ld (ix+1), ConsoleStartLine + BunchLowerSeparator + 26
			inc ix
			inc ix
			call ListsBunchs
			jp c, .Redraw

			ld ix, UserAreaCpyBuffer
			call MENUPOPUP
			jp c, .Redraw				; The user pressed ESC.

			ld c, a					; The user hits a given bunch.
			ld b, 0					; bc = bunch index.
			ld (LinkingWichBunch), bc
			call GetsBunchFormat
			jp c, .Redraw

			ld (LinkingWichFormat), a

			ld ix, UserAreaCpyBuffer
			call MENUPOPUP
			jp c, .Redraw				; The user pressed ESC.

			ld c, a					; The user hits a given bunch.
			ld b, 0					; bc = bunch index.
			ld (LinkingToBunch), bc

			call GetsBunchFormat			; it must checks if the formats match.
			jp c, .Redraw

			ld b, a					; Saves to what format.

			ld a,(LinkingWichFormat)
			ld c, a
			cp FormatID.TileSc2
			jr z, .LinkToPal
			cp FormatID.TileSc5
			jr z, .LinkToPal
			cp FormatID.TileSc5_16
			jr z, .LinkToPal
			cp FormatID.TileSc5_32
			jr z, .LinkToPal
			cp FormatID.SpriteMSX2
			jr z, .LinkToPal
			cp FormatID.SpriteMSX1
			jr z, .LinkToPal

			and FormatID.MapIndIDMask
			cp FormatID.MapIndID
			jr z, .LinkToTile

			ld a, c
			and FormatID.MapSceneIDMask
			cp FormatID.MapSceneID
			jr z, .LinkToMTCOrTileset

.LinkErr:		call .ErrFormatsMismatch
			jp .Redraw

.LinkToPal:		ld a, b					; Checks if the user is linking it to a pallete set.
			cp FormatID.PaletteSet
			jr nz, .LinkErr

.LinkDo:		ld bc, (LinkingToBunch)			; It creates the link, overriding any other link.
			ld hl, UserAreaCpyBuffer		; First it needs to get the bunch name "LinkTo".
			call GetsBunchNameRecord
			jp c, .LinkDataErr

			ld bc, (LinkingWichBunch)		; It gets the address of wich bunch it will link.
			call @GETBUNCH_BASEADDR
			jp c, .LinkDataErr

			ld bc, BunchHeader.Customs
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc
								; HLDE = customs field address of the "wich bunch to link".
			exx
			ld bc, 16
			ld hl, UserAreaCpyBuffer
			call @WRITE_USERAREA			; The nullchar at 17th position is allways set when the bunch was created, so we don't rewrite it here.
			ret nc

.LinkDataErr:		call .ErrDataCorrupt
			jp .Redraw

.LinkToTile:		ld a, b					; Here is linking a "Meta-Tiling Chart" (now MTC, before named *Indexator*) to a tileset.
			cp FormatID.TileSc2
			jr z, .LinkTestTileSetSize
			cp FormatID.TileSc5
			jr z, .LinkTestTileSetSize
			cp FormatID.TileSc5_16
			jr z, .LinkTestTileSetSpecial
			cp FormatID.TileSc8_16
			jr z, .LinkTestTileSetSpecial
			cp FormatID.TileSc8
			jr nz, .LinkErr

.LinkTestTileSetSize:	ld bc, (LinkingToBunch)
			call GetsBunchObjectCount		; It must know if the tileset is larger than >256 tiles or not.
			jr c, .LinkDataErr
								; DE = objects count.
			dec de					; It checks if it can use 8 bits to store tile numbers.
			ld a, d
			and a
			jr nz, .MTC16BTile

			ld a,(LinkingWichFormat)		; Ok, is 8 bits tile numbering.
			and FormatID.MapInd16bitsTileNumber
			jr z, .LinkDo
			jr .LinkErr

.MTC16BTile:		ld a,(LinkingWichFormat)		; Ok, is 16 bits tile numbering.
			and FormatID.MapInd16bitsTileNumber
			jr nz, .LinkDo
			jr .LinkErr

.LinkTestTileSetSpecial:ld a,(LinkingWichFormat)		; It must check, as the tile is 16x16, it only can be grouped in 2x2 tiles, so 32x32 maximun size. Because the indexator can't handle more than that block's size.
			and FormatID.MapIndYTilesDoubler + FormatID.MapIndXTilesDoubler
			jr z, .LinkTestTileSetSize
			jr .LinkErr

.LinkToMTCOrTileset:	ld a, b					; Here is linking a map to a tileset or MTC.
			cp FormatID.TileSc5_16
			jr z, .LinkMapTileSetSize
			cp FormatID.TileSc5_32
			jr z, .LinkMapTileSetSize
			cp FormatID.TileSc8_16
			jr z, .LinkMapTileSetSize
			cp FormatID.TileSc8_32
			jr z, .LinkMapTileSetSize

			and FormatID.MapIndIDMask
			cp FormatID.MapIndID
			jp nz, .LinkErr

			ld a, b					; Ok verified, linking a map to a MTC.
			and FormatID.MapInd16bitsEntryCount
			jr nz, .MapMustBe16B
				
.MapMustBe8B:		ld a, c					; Ok, the MTC has up to 256 entries.
			and FormatID.MapScene16Bits
			jp z, .LinkDo
			jp .LinkErr

.MapMustBe16B:		ld a, c					; Ok, the MTC is larger than 256 entries.
			and FormatID.MapScene16Bits
			jp nz, .LinkDo
			jp .LinkErr

.LinkMapTileSetSize:	push bc
			ld bc, (LinkingToBunch)
			call GetsBunchObjectCount		; It must know if the tileset is larger than >256 tiles or not.
			pop bc
			jp c, .LinkDataErr
								; DE = objects count.
			dec de					; It checks if it can use 8 bits to store tile numbers in the map.
			ld a, d
			and a
			jr nz, .MapMustBe16B
			jr .MapMustBe8B

.HitExit:		ld hl, MsgBoxCheckValues
			ld (hl), $FF
			inc hl
			ld (hl), 0
			ld ix, BoxSureExitData
			call MSGBOX
			jp c, .Redraw

			ld hl, MsgBoxCheckValues
			ld a ,(hl)
			and a
			jp nz, .Redraw

			ld hl, (DiskErrorHandlerHookUpBackUp)
			ld (DiskErrorHandler), hl		; It restores the original disk error handling routine.

			ld hl, (AbortHandlerHookUpBackUp)
			ld (AbortHandler), hl			; It restores the original abort handler.

			jp @ExitProgram

.SaveAll:		ld bc, 0

.SaveAllLoop:		push bc					; It is a top level routine, errors messages must be shown in a lower level routine.
			call .Save
			pop bc
			jp c, .Redraw
			inc bc
			jr .SaveAllLoop

.SaveABunch:		ld ix, UserAreaCpyBuffer
			ld (ix+0), 8
			ld (ix+1), ConsoleStartLine + 18	; Aligning with where appears the "Save ..." menuitem.
			inc ix
			inc ix
			call ListsBunchs
			jp c, .Redraw

			ld ix, UserAreaCpyBuffer
			call MENUPOPUP
			jp c, .Redraw				; The user pressed ESC.

			ld c, a
			ld b, 0					; BC = Bunch address.
			call .Save
			jp .Redraw

.Save:			push bc					; In BC = bunch to save.

			ld hl, FCB				; New FCB.
			ld de, FCB + 1
			ld bc, 37 - 1				; FCB size = 37 bytes.
			ld (hl),0
			ldir

			pop bc
			push bc

			ld hl, UserAreaCpyBuffer		; Filename: UserArea -> buffer.
			call GetsBunchNameRecord
			pop bc
			ret c					; Returns error quietly if the bunch doesn't exist, so the "SaveAll" loop can escape quietly when complete.

			push bc
			ld hl, UserAreaCpyBuffer		; Filename: buffer -> FCB.
			call FCBNameFillUp

			ld de, FCB				; File Create or delete/recreate.
			ld c, $16
			call @BDOS
			and a
			pop bc

			jp nz, .DiskError			; Can't create?, error.

			call @GETBUNCH_LINKADDR
								; hlde = link address of the given bunch.
			push hl
			push de					; Saves the link address.
			call @USERAREA_RDW			; Reads the link value, that is = to content length = the "FILE LENGTH - 4" because it doesn't include the linker, and we needs to save it WITH the linker.
			jr nc, .SaveOk1

			pop de					; Can't read the bunch content length?, error.
			pop hl
			call .ErrDataCorrupt
			scf
			jp .FileClose

.SaveOk1:		ld e,c
			ld d,b
			ld bc,4
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc				; FILE LENGTH = CONTENT LENGTH + 4.
			exx
			pop de
			pop hl
			exx

			ld iy, __TransferingForSave		; in [hl'de'] = UserArea address.
			call @FarCallToPage3			; in [hlde] = size to transfer.
			jr nc, .FileClose

.DiskError:		call .ErrorDiskError
			scf

.FileClose:		push af
			ld de, FCB				; File Close.
			ld c, $10
			call @BDOS
			pop af
			ret

.Load:			ld iy, _Files				; It shows the disk directory.
			call @FarCallToPage2
			jp c, .Redraw

.LoadMB:		ld hl, FCB				; First it creates the FCB.
			ld de, FCB + 1
			ld bc, 37 - 1				; FCB size = 37 bytes.
			ld (hl),0
			ldir

			ld ix, BoxLoadFilenameData
			call MSGBOX
			jp c, .Redraw				; The user pressed ESC.

			ld hl, MsgBoxBuffer
			call NormalizeFileName
			jr nc, .LDOk

			call .ErrBadFN
			jr .LoadMB

.LDOk:			ld hl, MsgBoxBuffer
			call FindBunchByName			; Checks if the name is not already in use.
			jr c, .LDOk4

			call .ErrorAlreadyUsed
			jr .LoadMB

.LDOk4:			ld hl, MsgBoxBuffer
			call FCBNameFillUp

			ld c, $1A
			ld de, DTA
			call @BDOS

			ld c, $0F				; FILE OPEN.
			ld de, FCB
			call @BDOS
			and a
			jr z, .LDFound

			call .ErrorFileNotFound
			jp .Redraw

.LDFound:		ld de, FCB
			ld c, $14
			call @BDOS				; It reads the first block (128 bytes) for checking its format.
			and a
			jr z, .LDOkFirstRecord

.LDErrorDisk:		call .DiskError
			jp .Redraw

.LDOkFirstRecord:	ld de, BunchHeader.FormatID
			ld hl, DTA	
			add hl, de

			ld a, (hl)				; First check: It reads the 'FormatID' field.
			ld e, a
			cp FormatID.TileSc2
			jr z, .LDFG
			cp FormatID.TileSc5
			jr z, .LDFG
			cp FormatID.TileSc8
			jr z, .LDFG
			cp FormatID.TileSc5_16
			jr z, .LDFG
			cp FormatID.TileSc8_16
			jr z, .LDFG
			cp FormatID.TileSc5_32
			jr z, .LDFG
			cp FormatID.TileSc8_32
			jr z, .LDFG
			cp FormatID.SpriteMSX2
			jr z, .LDFG
			cp FormatID.SpriteMSX1
			jr z, .LDFG
			cp FormatID.PaletteSet
			jr z, .LDFG

			and FormatID.MapIndIDMask
			cp FormatID.MapIndID
			jr z, .LDFG
			ld a, e
			and FormatID.MapSceneIDMask
			cp FormatID.MapSceneID
			jr z, .LDFG

			call .ErrorInvalidFormat
			call .FileClose
			jp .Redraw

.LDFG:			ld hl, DTA				; It reads the bunch length.
			ld e, (hl)
			inc hl
			ld d, (hl)
			inc hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a					; hlde = If good, bunch length. (Filelength must be: bunch length + 4).

			push hl					; Checks if we have enough space.
			push de
			ld iy, _GETUSERAREA_FREESPACE		; it outs in hlde the free space available.
			call @FarCallToPage2
			exx
			pop de
			pop hl
			exx
			jr nc, .LDOk2

.LDErrDC:		call .ErrDataCorrupt
			call .FileClose
			jp .Redraw

.LDOk2:			call @M32COMP				; FREE SPACE - BUNCH SIZE.
			jr nc, .LDOk3

			call .ErrorNotEnoughtRAM
			call .FileClose
			jp .Redraw

.LDOk3:			ld iy, _GETFREEMARK_ADDRESS
			call @FarCallToPage2
			jr c, .LDErrDC

			push hl
			push de					; Save the original freemark address for later use.

			call .LoadProc				; It loads all the file.

			pop de
			pop hl
			jr nc, .LDCompleted

			exx					; Load error.
			ld hl, 0
			exx
			ld bc, 0
			call @USERAREA_WDW			; It restores the original freemark in its original address.

			call .FileClose
			jp .Redraw

.LDCompleted:		push hl					; It needs to create a new freemark after the loaded bunch.
			push de
			call @USERAREA_RDW
			
			ld e, c					; hlbc = dword value.
			ld d, b

			ld bc, 4
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, 0
			adc hl, bc

			pop bc
			ex de, hl
			add hl, bc
			ex de, hl
			pop bc
			adc hl, bc

			exx					; It creates the new freemark in the USERAREA.
			ld hl, 0
			exx
			ld bc, 0
			call @USERAREA_WDW

			call .FileClose
			jp .Redraw

.LoadProc:		exx
								; hl'de' = actual freemark address in the USERAREA.
			ld hl, DTA				; It reads the four bytes at the start of the file, that stores its content length.
			ld e, (hl)
			inc hl
			ld d, (hl)
			inc hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a					; hlde = length.

			ld bc, 4
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc				; filesize = content length + sizeof(content length record).

								; THIS NEW CHECK MAKES INCOMPATIBLE THE SAVED SOURCE FILES WITH EARLIER VERSIONS. AS NOW THE SOURCEFILE MUST HAVE THE EXACT LENGTH (AND NOT 128bytes multiplier as sequential does).
			ld a, (FCB + $10)			; If format is correct It matchs with the actual file length.
			cp e
			jr nz, .IncorrectLength
			ld a, (FCB + $11)
			cp d
			jr nz, .IncorrectLength
			ld a, (FCB + $12)
			cp l
			jr nz, .IncorrectLength
			ld a, (FCB + $13)
			cp h
			jr nz, .IncorrectLength
								; THIS NEW CHECK MAKES INCOMPATIBLE THE SAVED SOURCE FILES WITH EARLIER VERSIONS. AS NOW THE SOURCEFILE MUST HAVE THE EXACT LENGTH (AND NOT 128bytes multiplier as sequential does).

			ld iy, __TransferingForLoad		; in [hl'de'] = Logical UserArea address.
			call @FarCallToPage3			; in [hlde] = size to transfer.
			ret nc

			call .ErrorDiskError
			scf
			ret

.IncorrectLength:	call .ErrorInvalidFormat
			scf
			ret






FCBNameFillUp:		push hl					; In HL = null string terminated with the filename.

			ld hl, FCB+1
			ld de, FCB+2
			ld bc, 11 - 1
			ld (hl), ' '
			ldir

			pop hl

			ld b,8
			ld de, FCB+1
			call .NLoop

			ld a,(hl)
			and a
			ret z					; Escapes if found the nullchar.

			cp '.'					; It jumps the dot.
			jr nz, .Ext
			inc hl

.Ext:			ld b,3
			ld de, FCB+1+8

.NLoop:			ld a, (hl)
			and a
			ret z

			cp '.'
			ret z

			ld (de),a
			inc hl
			inc de
			djnz .NLoop
			ret



; **************************************************
; * CONSOLE RENDER                                 *
; **************************************************






ConsoleRender:		ld hl, SelectorBunchName		; First it needs to know what it will show, in way to adjust the SCREEN MODE and SCREEN PALETTEs.
			call FindBunchByName
			jr c, .BNF
			
			call SelectsThisBunch
			jr nc, .Go

.BNF:			ld bc, 0				; Currently is nothing selected or just was the bunch deleted.
			call SelectsThisBunch			; Try to selects the first bunch automatically.
			jr nc, .Go

.BunchNotFound:		xor a					; It setup the default Sc8.
			call PREPARE_SCREEN

			ld a, ConsoleStartLine			; It redraws the console showing whatever the user is doing. It holds the control, so let the user to do every thing possible.
			ld b, BunchLowerSeparator		; In A = Ypos.

.Um:			push bc
			push af
			call @HERASER
			pop af
			pop bc
			inc a
			djnz .Um				; It draws an lower separator.

			ld a, ConsoleStartLine + BunchLowerSeparator
			ld hl, _TitleStrEmpty
			ld iy, _TITLELINE			; HL = string addr, A = Y start line.
			call @FarCallToPage2

			ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight
			call @CLSLP

.GoMenuBar:		call MENUBAR				; It allows that the user loads or creates something. When the UserArea is empty, so it automatically call the menubar, and then try to render again the console.
			call MENUBAR.CleanUp
			jp ConsoleRender

.Go:			ld a, (SelectorCurrentFormat)		; Ok it have something, great!. Now we needs to check its format.
			ld e,a
			ld bc, (SelectorBunchIndex)
			cp FormatId.TileSc8
			jp z, .NoPalScreen
			cp FormatId.TileSc8_16
			jp z, .NoPalScreen
			cp FormatId.TileSc8_32
			jp z, .NoPalScreen
			cp FormatId.ImageFileHolder
			jp z, .NoPalScreen
			cp FormatID.TileSc2
			jr z, .PalScreenIndirect
			cp FormatID.TileSc5
			jr z, .PalScreenIndirect
			cp FormatID.TileSc5_16
			jr z, .PalScreenIndirect
			cp FormatID.TileSc5_32
			jr z, .PalScreenIndirect
			cp FormatID.PaletteSet
			jr z, .PalScreenDirect			; It already has the palette bunch ID.
			cp FormatID.SpriteMSX2
			jr z, .PalScreenIndirect
			cp FormatID.SpriteMSX1
			jr z, .PalScreenIndirect
								; Sometimes is not that easy to determine wich screen mode to use, because we needs to trace down the linking record several times! FUUUUUUUCK!.
			and FormatID.MapIndIDMask
			cp FormatID.MapIndID
			jr z, .FMTC

			ld a,e
			and FormatID.MapSceneIDMask
			cp FormatID.MapSceneID
			jr z, .FMAP
								; ATP We can't determine the format, set up the default Sc8.
			jr .NoPalScreen

.FMAP:			ld bc, (SelectorBunchIndex)
			call GetLinkedBunch
			jr c, .NoPalScreen			; No linked, or bunch not created/loaded, the default is Sc8.

			push bc
			call GetsBunchFormat
			pop bc

			ld e,a
			and FormatID.MapIndIDMask
			cp FormatID.MapIndID
			ld a,e
			jr z, .FMTC2				; A map Scene only can be linked to a MTC or tileset.
			jr .FMapToTile

.FMTC:			ld bc, (SelectorBunchIndex)

.FMTC2:			call GetLinkedBunch			; in BC = bunch index. Out BC = linked bunch index.
			jr c, .NoPalScreen			; No linked, or bunch not created/loaded, the default is Sc8.
								; A MTC (Meta-Tiling Chart) only can be linked to a TileSet or nothing.
			push bc
			call GetsBunchFormat
			pop bc
			jr c, .NoPalScreen			; If userdata error, set up the default Sc8.

.FMapToTile:		cp FormatId.TileSc8
			jr z, .NoPalScreen
			cp FormatId.TileSc8_16
			jr z, .NoPalScreen
			cp FormatId.TileSc8_32
			jr z, .NoPalScreen
			cp FormatID.TileSc2
			jr z, .PalScreenIndirect
			cp FormatID.TileSc5
			jr z, .PalScreenIndirect
			cp FormatID.TileSc5_16
			jr z, .PalScreenIndirect
			cp FormatID.TileSc5_32
			jr z, .PalScreenIndirect
			jr .NoPalScreen

.PalScreenIndirect:	call GetLinkedBunch
			jr c, .PalScreenMSX1Pal			; In BC = no PaletteSet bunch ID. But one may be linked to this.

.PalScreenDirect:	call ExtractPaletteSet 			; In BC = PaletteSet bunchID.
			jr c, .PalScreenMSX1Pal

			call SetPalette

			jr .PalScreen

.PalScreenMSX1Pal:	ld hl, MSX1PaletteSetData
			ld de, CurrentPaletteSetBuffer
			ld bc, 32
			ldir

			call SetPalette				; It applies the default palettes.

.PalScreen:		xor a					; It switchs to Sc7.
			dec a
			call PREPARE_SCREEN
			jr .BunchRender

.NoPalScreen:		xor a					; It switchs to Sc8.
			call PREPARE_SCREEN

.BunchRender:		ld a, ConsoleStartLine			; It redraws the console showing whatever the user is doing. It holds the control, so let the user to do every thing possible.
			ld b, BunchLowerSeparator		; In A = Ypos.

.Um9:			push bc
			push af
			call @HERASER
			pop af
			pop bc
			inc a
			djnz .Um9				; It draws an lower separator.

			ld a, ConsoleStartLine + BunchLowerSeparator
			ld hl, SelectorBunchName		; It print the titlebar with the bunch name.
			ld iy, _TITLELINE
			call @FarCallToPage2

			ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight
			ld b, BunchUpperSeparator

.Um3:			push bc
			push af
			call @HERASER
			pop af
			pop bc
			inc a
			djnz .Um3

			ld a,(SelectorCurrentFormat)		; BUNCH FORMAT RENDER CHOICE!.
			ld b,a
			cp FormatId.TileSc2
			jr z, .RenderTileSelectorInit
			cp FormatId.TileSc5
			jr z, .RenderTileSelectorInit
			cp FormatId.TileSc5_16
			jr z, .RenderTileSelectorInit
			cp FormatId.TileSc5_32
			jr z, .RenderTileSelectorInit
			cp FormatId.TileSc8
			jr z, .RenderTileSelectorInit
			cp FormatId.TileSc8_16
			jr z, .RenderTileSelectorInit
			cp FormatId.TileSc8_32
			jr z, .RenderTileSelectorInit
			cp FormatId.PaletteSet
			jp z, PaletteConsole

			cp FormatId.ImageFileHolder		; Bmp console render.
			ld iy, __ImageConsole
			jp z, @FarJumpToPage3

			ld iy, _SpriteConsole			; Sprite console is in the code page2.
			cp FormatId.SpriteMSX2
			jp z, @FarJumpToPage2
			cp FormatId.SpriteMSX1
			jp z, @FarJumpToPage2

			and FormatId.MapIndIDMask
			cp FormatId.MapIndID
			ld iy, _IndexatorConsole
			jp z, @FarJumpToPage2

			ld a,b
			and FormatID.MapSceneIDMask
			cp FormatID.MapSceneID
			ld iy, _MapConsole
			jp z, @FarJumpToPage2

			jp .GoMenuBar				; Selected bunch format not found ???.

.RenderTileSelectorInit:ld iy, _LoadTileConsoleVariables
			call @FarCallToPage2

.RenderTileSelector:	call DrawTileSelector

			call DrawTileSelectorScrollBar

			call RenderPuzzler

			call .PrintCursorPos

.TSelectorControl:	call @INKEY
			jr c, .TSelectorControl

			call @UPCASE

			cp 28
			jp z, .Right

			cp 29
			jp z, .Left

			cp 30
			jp z, .Up

			cp 31
			jp z, .Down

			cp 13
			jp z, .Hit

			cp 32
			jp z, .Hit

			cp 9
			jr z, .Tab

			cp 27
			jr z, .Esc

			ld b, '0'
			cp '0'
			jr c, .TSelectorControl

			cp '9'+1
			jp c, .SetOnPuzzle

			ld b, 'A'-10
			cp 'A'
			jr c, .TSelectorControl

			cp 'F'+1
			jp c, .SetOnPuzzle

			cp 'M'
			jp z, .HitCopyMark

			cp 'L'
			jp z, .HitClr

			cp 'O'
			jp z, .PuzSort2x2
			cp 'P'
			jp z, .PuzSort4x4

			cp 'Q'
			jr z, .FastBS

			cp 'G'
			ld iy, _GotoOfTileSelector
			jp z, @FarJumpToPage2

			jr .TSelectorControl

.Tab:			ld iy, _SaveTileConsoleVariables
			call @FarCallToPage2

			jp BunchSelector

.Esc:			ld iy, _SaveTileConsoleVariables
			call @FarCallToPage2

			jp .GoMenuBar

.FastBS:		ld iy, _SaveTileConsoleVariables
			call @FarCallToPage2

			ld bc, (SelectorLinkedIndexatorObjectCount)
			ld a, c
			or b
			ld bc, (SelectorMapBlocksWidth)
			or c
			or b
			jp z, .TSelectorControl

			ld bc, (FastBunchBack)
			jp BunchSelector.Selects

.Right:			ld hl,(SelectorCursorObjectNumber)
			call GetSelectorTileWidth
			call @DIV16_8				; hl=hl / C, a = hl mod C.
			dec c
			cp c
			jp z, .TSelectorControl

			ld hl,(SelectorCursorObjectNumber)
			push hl

			inc hl
			ld (SelectorCursorObjectNumber),hl
			ld (SelectorCurrentObjectNumber),hl	; Try to redraw where the cursor move on.
			call RenderTile
			pop hl
			jr c, .RightErr

			ld (SelectorCurrentObjectNumber),hl	; Ok.
			call RenderTile				; Erase the visualization of the cursor from the old location.
			call .PrintCursorPos
			jp .TSelectorControl

.RightErr:		ld (SelectorCursorObjectNumber),hl	; Error didn't rendered the tile, so it doesn't exists, or is out of the view.
			jp .TSelectorControl

.Left:			ld hl,(SelectorCursorObjectNumber)
			call GetSelectorTileWidth
			call @DIV16_8				; hl=hl / C, a = hl mod C.
			and a
			jp z, .TSelectorControl

			ld hl,(SelectorCursorObjectNumber)
			push hl

			dec hl
			ld (SelectorCursorObjectNumber),hl
			ld (SelectorCurrentObjectNumber),hl
			call RenderTile				; Going backward is always ok at this point.

			pop hl
			ld (SelectorCurrentObjectNumber),hl
			call RenderTile				; Erase the visualization of the cursor from the old location.
			call .PrintCursorPos
			jp .TSelectorControl

.Down:			ld hl,(SelectorCursorObjectNumber)
			push hl

			call GetSelectorTileWidth
			ld b, 0
			add hl,bc
			ld (SelectorCursorObjectNumber),hl
			ld (SelectorCurrentObjectNumber),hl
			call RenderTile
			jr c, .DownErr

			pop hl
			ld (SelectorCurrentObjectNumber),hl
			call RenderTile				; Erase the visualization of the cursor from this location.
			call .PrintCursorPos
			jp .TSelectorControl

.DownErr:		rla
			pop hl
			jr c, .OutOfTiles

			ld hl,(SelectorCurrentScrollTop)	; Was just a visual overflow.
			call GetSelectorTileWidth
			ld b, 0
			add hl,bc
			ld (SelectorCurrentScrollTop),hl	; Scroll down!.
			jp .RenderTileSelector			; Redraw all!.

.OutOfTiles:		ld (SelectorCursorObjectNumber),hl
			jp .TSelectorControl

.Up:			ld hl,(SelectorCursorObjectNumber)
			call GetSelectorTileWidth
			call @DIV16_8
			ld a, h
			or l
			jp z, .TSelectorControl

			ld hl,(SelectorCursorObjectNumber)
			push hl

			call GetSelectorTileWidth
			and a
			ld b, 0
			sbc hl,bc
			ld (SelectorCursorObjectNumber),hl
			ld (SelectorCurrentObjectNumber),hl

			ld de,(SelectorCurrentScrollTop)
			and a
			sbc hl,de
			jr nc, .NoScroll

			pop hl
			ld hl,(SelectorCurrentScrollTop)
			call GetSelectorTileWidth
			and a
			ld b, 0
			sbc hl,bc
			ld (SelectorCurrentScrollTop),hl
			jp .RenderTileSelector			

.NoScroll:		call RenderTile

			pop hl
			ld (SelectorCurrentObjectNumber),hl
			call RenderTile				; Erase the visualization of the cursor from this location.
			call .PrintCursorPos
			jp .TSelectorControl

.SetOnPuzzle:		sub b
								; A = offset.
			ld e,a					; It calculates the address to register the tile in the Puzzler.
			ld d,0
			ld l,e
			ld h,d
			add hl,hl
			add hl,hl
			add hl,de
			add hl,de
			add hl,de				; HL = A * 7.
			ld de, PuzzlerIndexationBuffer
			add hl,de

			push hl

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber),hl
			call GetObjectRawAddress		; In (SelectorCurrentObjectNumber).
			pop ix
			jp c, .TSelectorControl			; It looks for the tile in the user area.

			ld (ix+0),e
			ld (ix+1),d
			ld (ix+2),l
			ld (ix+3),h
			ld a,(SelectorCurrentFormat)
			ld (ix+4),a
			ld hl, (SelectorCursorObjectNumber)
			ld (ix+5),l
			ld (ix+6),h
			xor a					; Indicates that the last thing the user did is to set a puzzle, so later when editing the indexator doing HIT on one block will be set up with this puzzle information.
			ld (SelectorLinkedActivityLastDone), a
			jp .RenderTileSelector

.Hit:			ld a,(SelectorCurrentFormat)		; Must load the tile editor with the info of the tile where the cursor is on.
			ld (EditorCurrentFormat),a

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber),hl

			call GetObjectRawAddress
			jp c, .RenderTileSelector

			ld (EditorCursorAddrLow),de
			ld (EditorCursorAddrHigh),hl

			ld iy, _EDITORLOAD
			call @FarCallToPage2			; It loads the graphic information into the editor buffer.
			jp c, .RenderTileSelector

			ld a, $FF
			ld (EditorCurrentlyInUse), a		; Indicates that it will start editing.

			ld (PuzzlerForceRenderAll), a
			call RenderPuzzler			; It redraws the puzzler because with some formats it moves to another place when editing.
			xor a
			ld (PuzzlerForceRenderAll), a

			call RunTileEditor
			xor a
			ld (EditorCurrentlyInUse), a		; Indicates that it finished from editing.
			jp .RenderTileSelector

.PrintCursorPos:	ld de, (SelectorCursorObjectNumber)
.PrintCursorCustom:	ld hl,0					; In DE = value.
			ld iy, _STR
			call @FarCallToPage2
			ld de, 220 + 256 * 3
			ld hl, STR_Buffer

			ld a, (MenuForeColor)
			ld (RenderForeColor),a
			ld a, (MenuBackGroundColor)
			ld (RenderBackColor),a
			call @STRDRAWZ				; equivalent PRINT STR$(SelectorCursorObjectNumber).
			ld hl, STR_Buffer
			call @STRLEN	
			ld a,5					; 65535 (5 digits) is the maximun that will show ever.
			sub c
			ld b,a
			add a,a
			add a,b
			add a,a					; a = width lacks cover.
			ld b,a

			ld a,c
			add a,a
			add a,c
			add a,a					; a = width printed.
			ld l, 220
			add a,l
			ld l,a

			ld c,b
			ld b,8
			ld h, 3
			ld a, (MenuBackGroundColor)
			jp @BLOCKFILL

.HitCopyMark:		ld hl,(SelectorCopyFromRawAddrHigh)	; Check if already has the start tile.
			ld de,(SelectorCopyFromRawAddrLow)
			ld a,e
			or d
			or l
			or h
			jr nz, .HitCopySetLength
								; Ok it must define the start tile.
			ld a,(SelectorCurrentFormat)
			ld (SelectorCopyFromFormat),a

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber) ,hl

			call GetObjectRawAddress		; In (SelectorCurrentObjectNumber).
			jp c, .TSelectorControl
						
			ld (SelectorCopyFromRawAddrLow), de
			ld (SelectorCopyFromRawAddrHigh), hl
			
			jp .TSelectorControl

.HitCopySetLength:	ld hl,(SelectorCopyStopRawAddrHigh)	; Check if already has the stop tile.
			ld de,(SelectorCopyStopRawAddrLow)
			ld a,e
			or d
			or l
			or h
			jr nz, .HitCopySetDestination
								; Ok it must define the stop tile.
			ld a,(SelectorCurrentFormat)
			ld b,a
			ld a,(SelectorCopyFromFormat)
			cp b
			jr nz, .StopNotValid			; If the format don't match, it is not inside the same bunch!.

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber) ,hl

			call GetObjectRawAddress		; In (SelectorCurrentObjectNumber).
			jp c, .TSelectorControl

			ld bc,(SelectorCopyFromRawAddrHigh)	; Check valid range. if Start <= Stop then
			push hl
			sbc hl,bc
			pop hl
			jr c, .StopNotValid
			jr nz, .StopValid

			ld bc,(SelectorCopyFromRawAddrLow)
			ex de,hl
			push hl
			sbc hl,bc
			pop hl
			ex de,hl
			jr c, .StopNotValid

.StopValid:		ld a,(SelectorCopyFromFormat)
			ld iy, _GETOBJECTSIZE
			call @FarCallToPage2

			ex de,hl				; It saves an incremented Stop address in way to include the tile that is on the cursor.
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc		
			
			ld (SelectorCopyStopRawAddrLow), de
			ld (SelectorCopyStopRawAddrHigh),hl
			jp .RenderTileSelector

.StopNotValid:		call @BEEP
			jp .ClearCpy

.HitCopySetDestination:	ld a,(SelectorCurrentFormat)
			ld b,a
			ld a,(SelectorCopyFromFormat)
			cp b
			jr nz, .StopNotValid			; By now the copy/swap operation will not support TRANSCODING, but is perfect possible to transcode the tile format from Sc2 to Sc5 or Sc5 to Sc8, just that I don't have time for that!. If changed it, the code for checking if the destination area has enough space must be rewrited because when transcoding the object size is different from source than destination.

			ld a,b
			ld (SelectorCopyToFormat),a

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber) ,hl

			call GetObjectRawAddress		; In (SelectorCurrentObjectNumber).
			jp c, .TSelectorControl

			ld (SelectorCopyToRawAddrLow), de
			ld (SelectorCopyToRawAddrHigh),hl
							
			ld de, (SelectorCopyStopRawAddrLow)	; Checks if the size copied will fit in the destination bunch where pointed.
			ld hl, (SelectorCopyStopRawAddrHigh)

			ld bc, (SelectorCopyFromRawAddrLow)
			ex de,hl
			and a
			sbc hl,bc
			ex de,hl
			ld bc, (SelectorCopyFromRawAddrHigh)
			sbc hl,bc
								; hlde = length in bytes of what to be copied.
			ld (UserAreaCpyLengthLow),de
			ld (UserAreaCpyLengthHigh),hl

			ld bc, (SelectorCopyToRawAddrLow)	; If transcoding support, these lines must be change. Like testing by 'object count' and not by its length.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, (SelectorCopyToRawAddrHigh)
			adc hl,bc				; hlde = Destination address + Length in bytes.
								; Now checks if it passed the end of the current bunch.
			ld bc, (SelectorStopRawAddrHigh)
			and a
			sbc hl,bc
			jr c, .CpyAllowed
			jr nz, .StopNotValid

			ld bc, (SelectorStopRawAddrLow)
			ex de,hl
			sbc hl,bc
			jr c, .CpyAllowed
			jr nz, .StopNotValid

.CpyAllowed:		ld ix, CopyMenuData
			call MENUPOPUP
			jp c, .TSelectorControl			; If escaped.

			and a
			jr z, .SetCopy				; Copy.
			dec a
			jr z, .SetSwap				; Swap.
								; Cancel.
.ClearCpy:		ld hl,0
			ld (SelectorCopyFromRawAddrLow),hl
			ld (SelectorCopyFromRawAddrHigh),hl
			ld (SelectorCopyStopRawAddrLow),hl
			ld (SelectorCopyStopRawAddrHigh),hl
			ld (SelectorCopyToRawAddrLow),hl
			ld (SelectorCopyToRawAddrHigh),hl
			jp .RenderTileSelector

.SetCopy:		call .PrepareCpy

			ld iy, _USERAREA_COPY
			call @FarCallToPage2
			jp c, .StopNotValid
			jp .ClearCpy

.PrepareCpy:		ld hl,(SelectorCopyFromRawAddrLow)
			ld (UserAreaCpySourceLow),hl
			ld hl,(SelectorCopyFromRawAddrHigh)
			ld (UserAreaCpySourceHigh),hl
			ld hl,(SelectorCopyToRawAddrLow)
			ld (UserAreaCpyDestinationLow),hl
			ld hl,(SelectorCopyToRawAddrHigh)
			ld (UserAreaCpyDestinationHigh),hl
			ret

.SetSwap:		call .PrepareCpy

			ld iy, _USERAREA_SWAP
			call @FarCallToPage2
			jp c, .StopNotValid
			jp .ClearCpy

.HitClr:		ld hl, PuzzlerIndexationBuffer
			ld de, PuzzlerIndexationBuffer + 1
			ld bc, 7*16-1
			ld (hl),0
			ldir
			jp .RenderTileSelector

.PuzSort2x2:		ld iy, _PuzSort2x2
			jr .Jp2

.PuzSort4x4:		ld iy, _PuzSort4x4
.Jp2:			call @FarCallToPage2
			jp .RenderTileSelector






DrawTileSelector:	ld hl,(SelectorCurrentScrollTop)
			ld (SelectorCurrentObjectNumber),hl

.TileSelectorLoop:	call RenderTile
			
			ld hl,(SelectorCurrentObjectNumber)
			inc hl
			ld (SelectorCurrentObjectNumber),hl	; Object number =+ 1.
			jr nc, .TileSelectorLoop

			rra
			jr nc, .TileSelectorLoop		; SCF + A bit 0 = 1 = Out of Visual area.
			ret






DrawTileSelectorScrollBar:ld hl, 15*16 + 256*(ConsoleStartLine +BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator - 3)

			ld bc, 256 * (16*4+1) + 8		; It renders the scrollbar border.
			ld a, (OutlineSecondaryColor)		; ScrollBar border color.
			call @SQUARE

			ld de,(SelectorCurrentScrollTop)	; It calculates the scrollbar cursor position.		
			ld hl,0
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x2.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x4.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x8.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x16.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x32.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; Scale Up 64 times. As we didn't want to work with fractions!!!. And 64px will be the space for scroll bar cursor.
			
			ld bc,(SelectorObjectsCount)
			call @DIV32_16
								; de = cursor Y start offset. hld is zero always as the range would be 0 - 63 as was scaled up 64 times only.
			push de					; Saves the cursor position for later use.
			ld hl, 15*16 + 1 + 256*(ConsoleStartLine+BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator - 2)		; it draws the background space from the start of the scrollbar up to the cursor position - 1.

			ld b,e
			ld a,e
			and a
			ld c, 6
			ld a, (OutlineBackGroundColor)
			CALL nz, @BLOCKFILL
			pop de

			ld hl, 15*16 + 1 + 256*(ConsoleStartLine+BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator - 2)		; it draws the cursor of the scrollbar.
			ld a,e
			add a,h
			ld h,a
			push hl
			push de

			ld hl,(SelectorCurrentObjectNumber)	; It reads the last+1 Tile rendered in the selector.
			dec hl
			ex de,hl
			
			ld hl,(SelectorObjectsCount)		; Checks if the ends view is not > than the tile ammount (because here can be unused tiles in the view).
			and a
			sbc hl,de
			jr nc, .NoPassed

			ld de,(SelectorObjectsCount)
			dec de

.NoPassed:		ld hl,0
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x2.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x4.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x8.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x16.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x32.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; Scale Up 64 times. As we didn't want to work with fractions!!!. And 64px will be the space for scroll bar cursor.
			
			ld bc,(SelectorObjectsCount)
			call @DIV32_16
								; de = cursor Y end offset. hld is zero always as the range would be 0 - 63 as was scaled up 64 times only.
			pop bc
			ld a,e
			sub c
			jr c, .CSMin
			jr nz, .CSOk

.CSMin:			ld a, 1					; Minimun cursor size.

.CSOk:			ld b,a
			pop hl
			ld c, 6
			ld a, (OutlineCursorColor)
			push hl
			push bc
			CALL @BLOCKFILL
			pop bc
			pop hl

			ld a,h
			add a,b
			ld h,a

			ld a, 63 + (ConsoleStartLine+BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator - 2)
			sub h
			ld b,a
			ret c

			ld a, (OutlineBackGroundColor)
			jp nz, @BLOCKFILL
			ret






GetSelectorTileWidth:	ld a, (SelectorMetaTileSize)		; Out C = Selector width in tiles.
			cp 8
			ld c, 16
			ret z
			cp 16
			ld c, 10
			ret z
			ld c, 6
			ret






PaletteConsole:		ld hl ,(SelectorBunchStartRawAddrLow)
			ld (SelectorCurrentRawAddrLow), hl
			ld hl ,(SelectorBunchStartRawAddrHigh)
			ld (SelectorCurrentRawAddrHigh), hl
			xor a
			ld (EditorCursorX), a
			ld (EditorCursorY), a

			call @SELECTORLOAD			; It needs to LOAD the palette information into the selector buffer.
			jp c, ConsoleRender.GoMenuBar		; It loads all 16 palettes at once, and not one by one like in others object formats.

.RedrawEverything:	ld hl, 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)
			ld b, 16
			ld c, 0
			ld ix, SelectorBuffer

.PalRenderLoop:		push ix
			push bc
			push hl
			call .RedrawPal
			pop hl

			ld a, 32				; Two columns of separation.
			add a, l
			ld l, a
			jr nc, .NoCR

			ld l, 0
			ld a, 67				; Three lines of separation.
			add a, h
			ld h, a

.NoCr:			pop bc
			pop ix

			inc ix
			inc ix

			inc c

			djnz .PalRenderLoop

.PrintCursor:		ld e, $ff
			call .RedrawWhereTheCursor			; Show the cursor.
			
.KBControl:		call @INKEY
			jr c, .KBControl

			call @UPCASE

			push af
			ld e, 0
			call .RedrawWhereTheCursor
			pop af						; Removes the cursor.

			cp 28
			jr z, .Right

			cp 29
			jp z, .Left

			cp 30
			jp z, .Up

			cp 31
			jp z, .Down

			cp 13
			jp z, .Save

			cp 32
			jp z, .HitDown

			cp 'M'
			jp z, .HitUp

			cp 9
			jp z, BunchSelector

			cp 27
			jp z, .Esc

			jr .KBControl

.Esc:			ld bc, (SelectorBunchIndex)			; Al haber escapado, cancela los cambios que se hicieron visibles.
			call ExtractPaletteSet
			
			call SetPalette

			call PREPARE_SCREEN

			jp ConsoleRender.GoMenuBar

.Right:			ld a ,(EditorCursorX)
			cp 2
			jr nc, .RightNextPal

			inc a
			ld (EditorCursorX), a
			jp .PrintCursor

.RightNextPal:		ld a, (EditorCursorY)
			cp 15
			jp nc, .PrintCursor

			inc a
			ld (EditorCursorY), a
			xor a
			ld (EditorCursorX), a
			jp .PrintCursor

.Left:			ld a ,(EditorCursorX)
			and a
			jr z, .LeftPrevPal

			dec a
			ld (EditorCursorX), a
			jp .PrintCursor

.LeftPrevPal:		ld a, (EditorCursorY)
			and a
			jp z, .PrintCursor

			dec a
			ld (EditorCursorY), a
			ld a, 2
			ld (EditorCursorX), a
			jp .PrintCursor

.Up:			ld a, (EditorCursorY)
			and $F7
			ld (EditorCursorY), a
			jp .PrintCursor

.Down:			ld a, (EditorCursorY)
			or $08
			ld (EditorCursorY), a
			jp .PrintCursor

.HitDown:		ld hl, SelectorBuffer
			ld a, (EditorCursorY)
			add a,a
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a, (EditorCursorX)
			and a
			jr z, .RedDown
			dec a
			jr z, .GreenDown
									; Blue down.
			ld a, (hl)
			and $70
			ld b, a
			ld a, (hl)
			and $07
			jp z, .PrintCursor				; Escapes if already is zero.

			dec a
			or b
			ld (hl), a
									; Did a change.
.ShowsPalChange:	ld hl, SelectorBuffer
			ld de, CurrentPaletteSetBuffer
			ld bc, 32
			ldir

			call SetPalette

			call PREPARE_SCREEN

			ld a, (ColorThemeWasChanged)
			and a
			jp z, .PrintCursor

			call MENUBAR.CleanUp

			ld a, ConsoleStartLine + BunchLowerSeparator
			ld hl, SelectorBunchName		; It print the titlebar with the bunch name.
			ld iy, _TITLELINE
			call @FarCallToPage2

			jp .RedrawEverything

.GreenDown:		inc hl
			ld a, (hl)
			and $07
			jp z, .PrintCursor

			dec a
			ld (hl), a
			jr .ShowsPalChange	

.RedDown:		ld a, (hl)
			and $07
			ld b, a
			ld a, (hl)
			and $70
			jp z, .PrintCursor

			sub $10
			or b
			ld (hl), a
			jr .ShowsPalChange

.HitUp:			ld hl, SelectorBuffer
			ld a, (EditorCursorY)
			add a,a
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a, (EditorCursorX)
			and a
			jr z, .RedUp
			dec a
			jr z, .GreenUp
									; Blue up.
			ld a, (hl)
			and $70
			ld b, a
			ld a, (hl)
			and $07
			cp $07
			jp z, .PrintCursor				; Escapes if already is the maximun.

			inc a
			or b
			ld (hl), a
			jr .ShowsPalChange

.GreenUp:		inc hl
			ld a, (hl)
			and $07
			cp $07
			jp z, .PrintCursor

			inc a
			ld (hl), a
			jr .ShowsPalChange	

.RedUp:			ld a, (hl)
			and $07
			ld b, a
			ld a, (hl)
			and $70
			cp $70
			jp z, .PrintCursor

			add a, $10
			or b
			ld (hl), a
			jp .ShowsPalChange

.Save:			ld de,(SelectorCurrentRawAddrLow)
			ld hl,(SelectorCurrentRawAddrHigh)
			exx
			ld bc, 32
			ld hl, SelectorBuffer
			call @WRITE_USERAREA

			jp ConsoleRender.GoMenuBar

.RedrawWhereTheCursor:	ld hl, 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)
			ld b, 16				; in E = 0 make cursor invisible, E <> 0 draw the cursor.
			ld c, 0
			ld ix, SelectorBuffer

.PalRenderLoop2:	push ix
			push bc
			push hl
			push de

			ld a, (EditorCursorY)			; Only draws where is the cursor.
			cp c
			jr nz , .NoDraw

			ld a,e
			and a
			jr nz, .Draw

			ld a, (EditorCursorY)
			push af
			ld a, $ff
			ld (EditorCursorY),a
			call .RedrawPal
			pop af
			ld (EditorCursorY),a
			jr .NoDraw

.Draw:			call .RedrawPal

.NoDraw:		pop de
			pop hl

			ld a, 32				; Two columns of separation.
			add a, l
			ld l, a
			jr nc, .NoCR2

			ld l, 0
			ld a, 67				; Three lines of separation.
			add a, h
			ld h, a

.NoCr2:			pop bc
			pop ix

			inc ix
			inc ix

			inc c

			djnz .PalRenderLoop2
			ret

.RedrawPal:		push bc					; In C = Palette number.

			ld bc, 256 * (7 * 6 + 2 + 1 + 1 + 16 + 2) + 3 * 8 + 6
			ld a, (OutlineColor)			; In hl = Top/Left Visual position. IX = address to Palette information.
			push hl

			call @SQUARE				; It draws the outer box.

			pop hl
			push hl

			ld a, 45				; 44 + 1 as it is positioned in the external outline.
			add a,h
			ld h,a
			inc l
			ld a, (OutlineColor)
			ld c, a
			ld b, 28				; Internal Width.
			call @HLINE

			pop hl
			push hl

			ld a, 10
			add a, l
			ld l, a
			inc h
			ld b, 7 * 6 + 2
			ld a, (OutlineColor)
			ld c, a
			call @VLINE

			pop hl
			push hl

			ld a, 19
			add a, l
			ld l, a
			inc h
			ld b, 7 * 6 + 2				; Vertical internal space for sliders = 44.
			ld a, (OutlineColor)
			ld c, a
			call @VLINE
			
			ld a, (ix+0)				; It draws the green box.
			and $70
			rrca
			rrca
			rrca
			rrca					; Reads the RED information. (it will be present in RGB sort).
			ld e, a

			ld a, 7
			sub e					; It calculates the length of the upper background.
			jr z, .NoRedBG

			pop hl
			push hl

			push de
			push af
			inc h
			inc h
			inc l
			inc l
			
			add a,a
			ld c, a
			add a,a
			add a,c
			ld b, a

			ld c, 7
			ld a, (ScreenBackgroundColor)
			call @BLOCKFILL
			pop af
			pop de			
			
.NoRedBG:		cp 7
			jr nc, .NoRed

			pop hl
			push hl
			inc h
			inc h
			inc l
			inc l

			add a,a
			ld c, a
			add a,a
			add a,c
			add a,h
			ld h, a

			ld a, e
			add a,a
			ld e, a
			add a,a
			add a,e
			ld b, a
			
			ld c, 7
			ld a, (OutlineRED)
			call @BLOCKFILL

.NoRed:			pop hl

			ld a, l
			add a, 10
			ld l, a

			push hl

			ld a, (ix+1)				; It draws the green box.
			and $07
			ld e, a					; Reads the GREEN information. (it will be present in RGB sort).

			ld a, 7
			sub e					; It calculates the length of the upper background.
			jr z, .NoGreenBG

			pop hl
			push hl

			push de
			push af
			inc h
			inc h
			inc l
			inc l
			
			add a,a
			ld c, a
			add a,a
			add a,c
			ld b, a
			ld c, 6
			ld a, (ScreenBackgroundColor)
			call @BLOCKFILL
			pop af
			pop de			
			
.NoGreenBG:		cp 7
			jr nc, .NoGreen

			pop hl
			push hl
			inc h
			inc h
			inc l
			inc l

			add a,a
			ld c, a
			add a,a
			add a,c
			add a,h
			ld h, a

			ld a, e
			add a,a
			ld e, a
			add a,a
			add a,e
			ld b, a

			ld c, 6
			ld a, (OutlineGREEN)
			call @BLOCKFILL

.NoGreen:		pop hl

			ld a, l
			add a, 9
			ld l, a

			push hl

			ld a, (ix+0)				; It draws the green box.
			and $07
			ld e, a					; Reads the BLUE information. (it will be present in RGB sort).

			ld a, 7
			sub e					; It calculates the length of the upper background.
			jr z, .NoBlueBG

			pop hl
			push hl

			push de
			push af
			inc h
			inc h
			inc l
			inc l
			
			add a,a
			ld c, a
			add a,a
			add a,c
			ld b, a
			ld c, 8
			ld a, (ScreenBackgroundColor)
			call @BLOCKFILL
			pop af
			pop de			
			
.NoBlueBG:		cp 7
			jr nc, .NoBlue

			pop hl
			push hl
			inc h
			inc h
			inc l
			inc l

			add a,a
			ld c, a
			add a,a
			add a,c
			add a,h
			ld h, a

			ld a, e
			add a,a
			ld e, a
			add a,a
			add a,e
			ld b, a

			ld c, 7
			ld a, (OutlineBLUE)
			call @BLOCKFILL

.NoBlue:		pop hl
			pop bc

			push hl
			ld a, l
			sub 17
			ld l, a					; It restores the position.
			ld a, h
			add a, 7*6 + 4
			ld h, a

			push bc

			ld a, c
			rlca
			rlca
			rlca
			rlca
			or c
			ld bc, 256 * 17 + 26
			call @BLOCKFILL
			pop bc
			pop hl

			ld a, (EditorCursorY)			; Check if here is the cursor.
			cp c
			ret nz					; Escapes if here is not the cursor.

			ld a, l
			sub 17
			ld l, a
			inc h
			inc h

			ld a, (EditorCursorX)
			cp 3
			ret nc

			add a,a
			ld b, a
			add a,a
			add a,a
			add a,b
			add a,l
			ld l, a
			ld bc, $2A05
			ld a, (OutlineCursorColor)
			jp @SQUARE






BunchSelector:		ld ix, UserAreaCpyBuffer		; It construct a list of bunch stored on the user area, and let the user to selects one of them, then it changes the current bunch in the selector, so it changes the "view of all the console" because then it jumps to "ConsoleRender".
			ld (ix+0), 2
			ld (ix+1), ConsoleStartLine + BunchLowerSeparator
			inc ix
			inc ix
			call ListsBunchs
			jp c, ConsoleRender

			ld ix, UserAreaCpyBuffer
			call MENUPOPUP
			jr c, .EscKey				; Back to the current console status.

			ld c, a					; The user selected another bunch.
			ld b, 0					; bc = bunch index (related to the Item number that was hit in the popup menu).

.Selects:		call @GETBUNCH_BASEADDR
			jp c, ConsoleRender

			ld b,16
			ld ix, SelectorBunchName

.Loop:			push bc
			push hl
			push de
			call @USERAREA_RB
			pop de
			pop hl
			pop bc

			push af
			inc de
			ld a,e
			or d
			jr nz, .J1
			inc hl
.J1:			pop af

			ld (ix+0),a
			inc ix
			and a
			jr z, .Null

			djnz .Loop

.Esc:			ld (ix+0),0

			call MENUBAR.BoxRedraw
			call MENUBAR.RoutineRedraw
			call MENUBAR.CleanUp
			jp ConsoleRender

.Null:			djnz .Esc

			ld (ix+0),0
			inc ix
			jr .Null

.EscKey:		call MENUBAR.CleanUp
			jp ConsoleRender






GetsBestPuzzlerXY:	ld a, (EditorCurrentlyInUse)
			and a
			jr z, .UsingSelector

			ld a, (SelectorMetaTileSize)
			ld hl, PuzzlerBottonRightOnEditor
			cp 8
			ret z
			ld hl, PuzzlerBottonRightOnEditor16
			cp 16
			ret z
			ld hl, PuzzlerBottonRightOnEditor32
			ret

.UsingSelector:		ld a, (SelectorMetaTileSize)
			ld hl, PuzzlerBottonRightOnSelector
			cp 8
			ret z
			ld hl, PuzzlerBottonRightOnSelector16
			cp 16
			ret z
			ld hl, PuzzlerBottonRightOnSelector32
			ret






RenderPuzzler:		call GetsBestPuzzlerXY			; out HL = best home position.

			ld a, (SelectorMetaTileSize)		; Calculates the puzzler size.
			add a,a
			add a,a					; Tile size * 4. Puzzler is 4 tiles width.
			ld c, a

			push hl
			push bc

			dec h
			dec h
			dec l
			dec l
			inc c
			inc c
			inc c
			inc c
			ld b, c

			ld a, (OutlineSecondaryColor)		; Border.
			call @SQUARE

			pop bc
			pop hl
			push hl
			push bc

			dec h
			dec l
			inc c
			inc c
			ld b, c

			ld a, (ScreenBackgroundColor)		; Inner Border.
			call @SQUARE

			pop bc
			pop hl

			push hl
			push bc
			push hl
			ld a, (ScreenBackgroundColor)
			ld b, c
			call @BLOCKFILL				; Puzzler background.

			ld a, (EditorCurrentlyInUse)
			and a
			jr nz, .NoPrintHelpStr

			ld a, (OutlineBackGroundColor)
			ld (RenderForeColor),a
			ld a, (ScreenBackgroundColor)
			ld (RenderBackColor),a
			pop de
			ld a, d
			pop bc
			add a, c
			add a, 4
			ld d, a

			ld hl, .PuzHlpStr
			call @STRDRAWZ				; Print help string.
			jr .PrintedHelpStr

.NoPrintHelpStr:	pop de
			pop bc
			pop de
			jr .PuzInUse

.PrintedHelpStr:	pop de					; Puzzler content home position.

			ld hl, .PuzStr
			ld b,16
			ld c,0

.PuzHelpLoop:		push bc
			push de
			push hl

			ld a, c
			and $03
			ld b, a
			and a
			jr z, .PuzNoXAdd

			ld a, e
			push af
			ld a, (SelectorMetaTileSize)
			ld e, a
			pop af

.PuzStrXCalcLoop:	add a, e
			djnz .PuzStrXCalcLoop
			
			ld e, a

.PuzNoXAdd:		inc e
			inc e

			ld a, c
			and $0C
			rra
			rra
			ld b, a
			and a
			jr z, .PuzNoYAdd

			ld a, d
			push af
			ld a, (SelectorMetaTileSize)
			ld d, a
			pop af

.PuzStrYCalcLoop:	add a, d
			djnz .PuzStrYCalcLoop

			ld d, a

.PuzNoYAdd:		ld a,(hl)
			call @CHRDRAW

			pop hl
			pop de
			pop bc

			inc hl
			inc c
			djnz .PuzHelpLoop

			jr .PuzInUse

.PuzStr:		DB "0123456789ABCDEF"

.PuzHlpStr:		DB "c<L>r.",0

.PuzInUse:		ld hl, PuzzlerIndexationBuffer		; The puzzler is in use, must redraw the tiles.
			xor a
			ld b,16

.PuzRenderLoop:		push af
			push bc
			push hl

			call RenderPuzTile

			pop hl
			pop bc
			pop af

			inc a
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			djnz .PuzRenderLoop
			ret






RenderPuzTile:		push hl					; in hl = address of current tile in the puzzler array.
			pop ix					; in a = tile position. (0 - 15).
			ld e, a

			ld a,(ix+0)
			or (ix+1)
			or (ix+2)
			or (ix+3)
			ret z					; If puzzler's tile is not in use, escapes.

			ld a, (ix+4)				; If the format isn't the same as the Selector, it escapes. It can't draw mixing differents tiles sizes.
			ld b, a
			ld a, (SelectorCurrentFormat)
			cp b
			ret nz

			call GetsBestPuzzlerXY			; out HL = best position.

			ld a, e
			and $03
			ld b, a
			and a
			jr z, .PuzNoXAdd

			ld a, l
			push af
			ld a, (SelectorMetaTileSize)
			ld l, a
			pop af

.PuzStrXCalcLoop:	add a, l
			djnz .PuzStrXCalcLoop
			
			ld l, a

.PuzNoXAdd:		ld a, e
			and $0C
			rra
			rra
			ld b, a
			and a
			jr z, .PuzNoYAdd

			ld a, h
			push af
			ld a, (SelectorMetaTileSize)
			ld h, a
			pop af

.PuzStrYCalcLoop:	add a, h
			djnz .PuzStrYCalcLoop

			ld h, a

.PuzNoYAdd:		push hl					; Save the visual position for the tile in the puzzler.
			ld e,(ix+0)
			ld d,(ix+1)
			ld l,(ix+2)
			ld h,(ix+3)				; Reads the USERAREA address of the tile.

			ld a, (PuzzlerForceRenderAll)
			and a
			jr nz, .NoBeingEditing

			ld a, (EditorCurrentlyInUse)
			and a
			jr z, .NoBeingEditing

			ld bc,(EditorCursorAddrLow)		; Checks if it is currently being edited.
			ex de,hl
			push hl
			sbc hl, bc
			pop hl
			ex de,hl
			jr nz, .NoBeingEditedThisOne

			ld bc,(EditorCursorAddrHigh)
			push hl
			sbc hl, bc
			pop hl
			jr nz, .NoBeingEditedThisOne
								; This tile is being edited.
			ld ix, EditorBuffer
			ld a, (EditorCurrentFormat)
			pop hl					; It restores the hl = visual position for the tile.

			jr .EditorBridge

.NoBeingEditedThisOne:	pop hl					; If is not the one being edited, it does nothing, for saving time.
			ret

.NoBeingEditing:	exx
			ld a, (ix+4)
			ld iy, _GETOBJECTSIZE
			call @FarCallToPage2
			ld hl, SelectorBuffer
			call @READ_USERAREA			; Loads in SelectorBuffer the tile information.
			pop hl					; It restores hl = visual position for the tile.
			ret c

			ld a,(ix+4)				; Reads the tile format from the indexator.

.ExternalIN:		ld ix, SelectorBuffer			; Now ix will have the address of the tile graphics.

.EditorBridge:		cp FormatID.TileSc8
			jp z, .TileSc8Render
			cp FormatID.TileSc8_16
			jp z, .TileSc8Render
			cp FormatID.TileSc8_32
			jp z, .TileSc8Render
			cp FormatID.TileSc5
			jp z, .TileSc5Render
			cp FormatID.TileSc5_16
			jp z, .TileSc5Render
			cp FormatID.TileSc5_32
			jp z, .TileSc5Render
								; Only lefts TileSc2.
			di
			ld b,8

.TSc2LineLoop:		push hl
			push bc
			call @VPOKEPOS				; Sets the VDP on bitmap X/Y = hl.

			ld e,(ix+8)				; Reads the color line information.
			ld d,(ix+0)				; Reads the pattern line information.

			ld a,e
			and $0F
			ld l,a
			add a,a
			add a,a
			add a,a
			add a,a
			or l
			ld c,a					; C = color for ZEROes duplicated like AA BB CC.

			ld a,e
			and $F0
			ld l,a
			rrca
			rrca
			rrca
			rrca
			or l
			ld h, a					; h = color for ONEs duplicated like AA BB CC.
				
			ld b,8

.Tsc2DotLoop:		rl d					; pattern shift.
			ld a, h
			jr c, .C1
			ld a, c					; PickUp color for ZEROES ....xxxx.

.C1:			out ($98),a
			djnz .Tsc2DotLoop

			pop bc
			pop hl
			inc ix
			inc h

			djnz .Tsc2LineLoop

.EI:			ei
			and a
			ret

.TileSc8Render:		di
			ld a, (SelectorMetaTileSize)
			ld b, a

.Tsc8LineLoop:		push hl
			push bc
			call @VPOKEPOS				; Sets the VDP on bitmap X/Y = hl.

			ld a, (SelectorMetaTileSize)
			ld b, a

.Tsc8DotLoop:		ld a,(ix+0)
			inc ix
			out ($98),a
			djnz .Tsc8DotLoop

			pop bc
			pop hl
			inc h

			djnz .Tsc8LineLoop
								; hl = botton start visual position.
			ei
			and a
			ret

.TileSc5Render:		di
			ld a, (SelectorMetaTileSize)
			ld b, a

.TSc5LineLoop:		push hl
			push bc
			call @VPOKEPOS				; Sets the VDP on bitmap X/Y = hl.
								; IX = Tile information.
			ld a, (SelectorMetaTileSize)
			rra
			ld b, a

.Tsc5DotPairLoop:	ld a,(ix+0)
			and $F0
			ld l,a
			rrca
			rrca
			rrca
			rrca
			or l
			out ($98),a				; left pixel, color duplicated like AA BB CC.

			ld a,(ix+0)
			and $0F
			ld l,a
			rlca
			rlca
			rlca
			rlca
			or l
			out ($98),a				; right pixel, color duplicated like AA BB CC.

			inc ix
			djnz .Tsc5DotPairLoop

			pop bc
			pop hl
			inc h

			djnz .Tsc5LineLoop

			ei
			and a
			ret






RenderTile:		ld a,(SelectorMetaTileSize)		; This part calculates the tile's visual position.
			cp 8					; CF = 1 error, A bit 0 = 1 Out Of visual area. A bit 7 = 1 Out of tiles.
			jr z, .VPTile8x8

			cp 16
			jr z, .VPTile16x16
								; Is 32x32 tile size.
			ld hl,(SelectorCurrentObjectNumber)	; It calculates the visual position where to render the tile.
			ld c, 6
			call @DIV16_8				; Out A = hl mod c, hl = hl \ c.

			add a,a
			add a,a
			add a,a
			ld b,a
			add a,a
			add a,a
			add a,b					; a = a * 40.
			add a, 3
			push af

			ld hl,(SelectorCurrentObjectNumber)
			ld de,(SelectorCurrentScrollTop)
			sbc hl,de				; Adjusts with the current scrollTop. As it starts render from the ScrollTop it can't be negative.

			ld c, 6
			call @DIV16_8				; Out A = hl mod c, hl = hl \ c.

			ld a, l
			add a,a
			add a,a
			add a,a
			ld l, a
			add a,a
			add a,a
			add a,l
			ld l, a					; hl = (SelectorCurrentObjectNumber \ 5)*40.

			jr .VPCont

.VPTile16x16:		ld hl,(SelectorCurrentObjectNumber)	; It calculates the visual position where to render the tile.
			ld c, 10
			call @DIV16_8				; Out A = hl mod c, hl = hl \ c.

			add a,a
			add a,a
			add a,a
			ld b,a
			add a,a
			add a,b					; a = a * 24.
			add a, 3
			push af

			ld hl,(SelectorCurrentObjectNumber)
			ld de,(SelectorCurrentScrollTop)
			sbc hl,de				; Adjusts with the current scrollTop. As it starts render from the ScrollTop it can't be negative.

			ld c, 10
			call @DIV16_8				; Out A = hl mod c, hl = hl \ c.

			ld a, l
			add a,a
			add a,a
			add a,a
			ld l, a
			add a,a
			add a,l
			ld l, a					; hl = (SelectorCurrentObjectNumber \ 10)*24.

			jr .VPCont

.VPTile8x8:		ld a,(SelectorCurrentObjectNumber)	; It calculates the visual position where to render the tile.
			and $0F
			ld b,a
			add a,a
			add a,a
			add a,b
			add a,b
			add a,b
			add a,a
			add a,b					; a = a * 15.
			add a,3
			push af

			ld hl,(SelectorCurrentObjectNumber)
			ld de,(SelectorCurrentScrollTop)
			sbc hl,de				; Adjusts with the current scrollTop. As it starts render from the ScrollTop it can't be negative.

			ld a,l
			and $f0
			ld l,a					; hl = (SelectorCurrentObjectNumber \ 16)*16

.VPCont:		ld de, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			add hl,de

			push hl					; hl = visual Y start for the render.

			call GetObjectRawAddress		; This part pick up the TILE graphics from the USER_AREA, In (SelectorCurrentObjectNumber).
			jp c, .OutOfTiles
						
			ld (SelectorCurrentRawAddrLow), de
			ld (SelectorCurrentRawAddrHigh), hl

			ld bc,(SelectorStopRawAddrHigh)		; Checks if reached the stop raw address.
			sbc hl,bc
			jr c, .J1
			jp nz, .OutOfTiles
			ld bc,(SelectorStopRawAddrlow)
			ex de,hl
			sbc hl,bc
			jp nc, .OutOfTiles			; Escapes if reached the bunch limit.

.J1:			call @SELECTORLOAD			; It loads the object data in the Selector buffer.
			jp c, .OutOfTiles

			pop hl
			pop bc

			xor a
			cp h
			ld a, 1					; A bit 0 = 1 out of visual area.
			ret c
			ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator+16*4-10
			cp l
			ld a, 1
			ret c

			ld h,l
			ld l,b					; hl = top/left where to render the tile.

			dec l					; in hl = top/left.
			dec l					; It draws the upper enclosure of a tile. In the tile selector.
			dec l
			push hl					; Saves the render visual position for the lines of the tile.

			dec h
			dec h
			dec h
			push hl
			ld a, (OutlineColor)
			ld c, a

			ld a,(SelectorMetaTileSize)
			add a, 6
			ld b, a
			call @HLINE
			pop hl
			ld a, (ScreenBackgroundColor)
			out ($98),a				; Tile separator.
			push hl					; It saves the visual position of the tile including its enclosure.
			ld de,(SelectorCursorObjectNumber)
			ld hl,(SelectorCurrentObjectNumber)
			sbc hl,de

			ld a, (OutlineCursorColor)		; Cursor Color.
			ld c, a
			jr z, .Cursor

			ld hl, (SelectorCurrentRawAddrHigh)	; Checks if the tile is about to be copied/exchanged.
			ld de, (SelectorCopyFromRawAddrHigh)
			and a
			sbc hl,de
			jr c, .NoToBeCopied
			jr nz, .TBCC

			ld hl, (SelectorCurrentRawAddrLow)
			ld de, (SelectorCopyFromRawAddrLow)
			sbc hl,de
			jr c, .NoToBeCopied
			jr z, .ToBeCopied			; Marks the start tile for copy operation, anyway in case that the Stop Tile is not already set.

.TBCC:			ld hl, (SelectorCurrentRawAddrHigh)
			ld de, (SelectorCopyStopRawAddrHigh)
			sbc hl,de
			jr c, .ToBeCopied
			jr nz, .NoToBeCopied
			
			ld hl, (SelectorCurrentRawAddrLow)
			ld de, (SelectorCopyStopRawAddrLow)
			sbc hl,de
			jr c, .ToBeCopied

.NoToBeCopied:		push hl
			push de
			push bc			

			ld hl, PuzzlerIndexationBuffer		; Checks if this tile is also on the Puzzler.
			ld b,16					; The puzzler has 16 tile subscriptions.

.IsInPuzLoop:		ld de, SelectorCurrentRawAddrLow
			ld a,(de)
			inc de
			cp (hl)
			inc hl
			jr nz, .PuzJ4

			ld a,(de)
			inc de
			cp (hl)
			inc hl
			jr nz, .PuzJ3

			ld a,(de)
			inc de
			cp (hl)
			inc hl
			jr nz, .PuzJ2

			ld a,(de)
			inc de
			cp (hl)
			inc hl
			inc hl
			inc hl
			inc hl
			jr z, .IsInPuz
			djnz .IsInPuzLoop
			jr .IsNotInPuz

.IsInPuz:		pop bc
			pop de
			pop hl

			ld a, (OutlineSecondaryRemarkColor)		; Is in the puzzle and not to be copied.
			ld c, a
			jr .Cursor

.ToBeCopied:		ld a, (OutlinePrimaryRemarkColor)		; Is to be copied.
			ld c, a
			jr .Cursor

.PuzJ4:			inc hl
.PuzJ3:			inc hl
.PuzJ2:			inc hl
			inc hl
			inc hl
			inc hl
			djnz .IsInPuzLoop

.IsNotInPuz:		pop bc
			pop de
			pop hl

			ld a, (ScreenBackgroundColor)		; When the tile is not remarked.
			ld c, a

.Cursor:		pop hl
			inc h
			push hl
			call @VPOKEPOS

			ld a, (OutlineColor)
			out ($98),a
			ld a,(SelectorMetaTileSize)
			add a, 4
			ld b, a
			ld a,c
.L1:			out ($98),a
			djnz .L1
			ld a, (OutlineColor)
			out ($98),a
			ld a, (ScreenBackgroundColor)
			out ($98),a				; Tile separator.
			pop hl
			inc h
			call @VPOKEPOS
			ld a, (OutlineColor)
			out ($98),a
			ld a,c
			out ($98),a
			ld a,(SelectorMetaTileSize)
			add a, 2
			ld b, a
			ld a, (ScreenBackgroundColor)
.L2:			out ($98),a			
			djnz .L2
			ld a,c
			out ($98),a
			ld a, (OutlineColor)
			out ($98),a
			ld a, (ScreenBackgroundColor)
			out ($98),a				; Tile separator.

			ld ix, SelectorBuffer
			pop hl

			ld a,(SelectorCurrentFormat)		; the content of the tile depends on the bunch format.
			and a
			cp FormatID.TileSc8
			jp z, .TileSc8Render
			cp FormatID.TileSc5
			jp z, .TileSc5Render
			cp FormatID.TileSc8_16
			jp z, .TileSc8Render
			cp FormatID.TileSc5_16
			jp z, .TileSc5Render
			cp FormatID.TileSc8_32
			jp z, .TileSc8Render
			cp FormatID.TileSc5_32
			jp z, .TileSc5Render
								; Only lefts TileSc2.
			di
			ld b,8

.TSc2LineLoop:		push hl
			call @VPOKEPOS				; Sets the VDP on bitmap X/Y = hl.
			push bc

			ld a, (OutlineColor)
			out ($98),a				; First dot white.

			ld a, c
			out ($98),a				; Next dot color cursor or background.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.

			ld e,(ix+8)				; Reads the color line information.
			ld d,(ix+0)				; Reads the pattern line information.

			ld a,e
			and $0F
			ld l,a
			add a,a
			add a,a
			add a,a
			add a,a
			or l
			ld c,a					; C = color for ZEROes duplicated like AA BB CC.

			ld a,e
			and $F0
			ld l,a
			rrca
			rrca
			rrca
			rrca
			or l
			ld h, a					; h = color for ONEs duplicated like AA BB CC,

			ld b,8

.Tsc2DotLoop:		rl d					; pattern shift.
			ld a, h
			jr c, .C1
			ld a, c					; PickUp color for ZEROES ....xxxx.

.C1:			out ($98),a
			djnz .Tsc2DotLoop

			pop bc
			pop hl
			inc ix
			inc h

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.

			ld a,c
			out ($98),a				; Next dot color cursor or background.

			ld a, (OutlineColor)
			out ($98),a				; Next dot white.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black (tile separator).

			djnz .Tsc2LineLoop

.JumpTileBotton:	push hl					; It draws the botton enclosure of a tile.
			call @VPOKEPOS

			ld a, (OutlineColor)
			out ($98),a				; First dot white.
			
			ld a,c
			out ($98),a				; Next dot cursor or background.

			ld a,(SelectorMetaTileSize)
			add a, 2
			ld b, a

			ld a, (ScreenBackgroundColor)
.L3:			out ($98),a
			djnz .L3

			ld a,c
			out ($98),a

			ld a, (OutlineColor)
			out ($98),a

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Tile separator.

			pop hl
			inc h
			push hl
			call @VPOKEPOS

			ld a, (OutlineColor)
			out ($98),a				; First dot white.

			ld a,(SelectorMetaTileSize)
			add a, 4
			ld b, a

			ld a,c
.L4:			out ($98),a
			djnz .L4

			ld a, (OutlineColor)
			out ($98),a

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Tile separator.

			pop hl
			inc h

			push hl
			call @VPOKEPOS
			pop hl

			ld a,(SelectorMetaTileSize)
			add a, 6
			ld b, a

			ld a, (OutlineColor)
.L5:			out ($98),a
			djnz .L5

			ld a, (ScreenBackgroundColor)		; //// why it overpset one pixel to the right?
			out ($98),a
								; Vertical separator between selector's rows.
			ld a, (SelectorMetaTileSize)
			cp 8
			jr z, .S8
			cp 16
			jr z, .S16

			push hl
			ld hl,(SelectorCurrentObjectNumber)
			ld c, 6
			call @DIV16_8
			pop hl
			and a					; Remainder = 0.
			jr nz, .EI
			jr .DrawSeparation

.S16:			push hl
			ld hl,(SelectorCurrentObjectNumber)
			ld c, 10
			call @DIV16_8
			pop hl
			and a					; Remainder = 0.
			jr nz, .EI
			jr .DrawSeparation

.S8:			ld a,(SelectorCurrentObjectNumber)	; Detects if it needs to redraw the rows now.
			and $0F
			jr nz, .EI
								; One time per row.
.DrawSeparation:	inc h
			ld l,0
			ld c, 15*16-1
			ld b, 2
			ld a, (ScreenBackgroundColor)
			call @BLOCKFILL

.EI:			ei
			and a
			ret

.TileSc8Render:		di
			ld a, (SelectorMetaTileSize)
			ld b, a

.Tsc8LineLoop:		push hl
			call @VPOKEPOS				; Sets the VDP on bitmap X/Y = hl.
			push bc

			ld a, (OutlineColor)
			out ($98),a				; First dot white.

			ld a, c
			out ($98),a				; Next dot color cursor or background.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.

			ld a, (SelectorMetaTileSize)
			ld b, a

.Tsc8DotLoop:		ld a,(ix+0)
			inc ix
			out ($98),a
			djnz .Tsc8DotLoop

			pop bc
			pop hl
			inc h

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.

			ld a,c
			out ($98),a				; Next dot color cursor or background.

			ld a, (OutlineColor)
			out ($98),a				; Next dot white.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black (tile separator).

			djnz .Tsc8LineLoop
								; hl = botton start visual position.
			jp .JumpTileBotton

.TileSc5Render:		di

			ld a, (SelectorMetaTileSize)
			ld b, a

.TSc5LineLoop:		push hl
			call @VPOKEPOS				; Sets the VDP on bitmap X/Y = hl.
			push bc

			ld a, (OutlineColor)
			out ($98),a				; First dot white.

			ld a, c
			out ($98),a				; Next dot color cursor or background.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.
								; IX = Tile information.
			ld a, (SelectorMetaTileSize)
			rra
			ld b, a

.Tsc5DotPairLoop:	ld a,(ix+0)
			and $F0
			ld l,a
			rrca
			rrca
			rrca
			rrca
			or l
			out ($98),a				; left pixel, color duplicated like AA BB CC.

			ld a,(ix+0)
			and $0F
			ld l,a
			rlca
			rlca
			rlca
			rlca
			or l
			out ($98),a				; right pixel, color duplicated like AA BB CC.

			inc ix
			djnz .Tsc5DotPairLoop

			pop bc
			pop hl
			inc h

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.

			ld a,c
			out ($98),a				; Next dot color cursor or background.

			ld a, (OutlineColor)
			out ($98),a				; Next dot white.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black (tile separator).

			djnz .Tsc5LineLoop

			jp .JumpTileBotton

.TileVisualOverflow:	scf
			ret

.OutOfTiles:		pop hl
			pop bc

			xor a
			cp h
			ld a, $81				; Both out of tiles & out of visual area.
			ret c
			ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator+16*4-10
			cp l
			ld a, $81
			ret c

			ld h,l
			ld l,b					; hl = top/left where to render the tile.

			dec l
			dec l
			dec l
			dec h
			dec h
			dec h

			ld a,(SelectorMetaTileSize)
			add a, 7
			ld b, a
			ld c, b
			dec c

			ld a, (ScreenBackgroundColor)

			call @BLOCKFILL

			scf
			ld a,$80				; A bit 7 = 1 Out of tiles.
			ret






EditorPickColor:	push af					; In a = color value or palette number.
			ld a, (IsOnPaletteScreenMode)		; MOD (hl).
			and a
			jr nz, .OnPal

			pop af
			ret

.OnPal:			pop af
			and $0F
			push hl
			ld l, a
			rlca
			rlca
			rlca
			rlca
			or l
			pop hl					; It duplicates the palette number like AA BB CC.
			ret






RunTileEditor:		ld hl, 0 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2)
			ld bc, $4444
			ld a, (OutlineSecondaryColor)
			call @SQUARE

			ld hl, 1 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 1)
			ld bc, $4242
			ld a, (ScreenBackgroundColor)
			call @SQUARE
								; Here start to print the content of the editor.
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc2
			call z, .RenderEditorContentSc2
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc5
			call z, .RenderEditorContentSc5
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc5_16
			call z, .RenderEditorContentSc5
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc5_32
			call z, .RenderEditorContentSc5
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8
			call z, .RenderEditorContentSc8
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8_16
			call z, .RenderEditorContentSc8
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8_32
			call z, .RenderEditorContentSc8

			ld a,(EditorCurrentFormat)		; Render the color attribs of the tile if the format is Sc2.
			cp FormatID.TileSc2
			jr nz, .NoColorChannel

			ld hl, 71 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2)
			ld bc, $4410
			ld a, (OutlineSecondaryColor)
			call @SQUARE

			ld hl, 72 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 1)
			ld bc, $420E
			ld a, (ScreenBackgroundColor)
			call @SQUARE

			call .RenderChromaChSc2			; Redraw Sc2 chroma channel content.
			jr .Cont

.NoColorChannel:	call .RenderColorSelected		; Render the picked colors when is not Sc2.

.Cont:			call .RenderColorPicker

.TileEditorControl:	call .UpgradePuzzler			; On any editing change it must redraw tile being edited if is present in the puzzler.

			call .PrintCursorTileEd

.Inkey:			call @INKEY
			jr c, .Inkey

			call @UPCASE

			push af
			ld bc,(EditorCursorX)
			call .RenderWhatIsPointed
			pop af

			cp 28
			jr z, .Right

			cp 29
			jp z, .Left

			cp 30
			jp z, .Up

			cp 31
			jp z, .Down

			cp 27
			jp z, .Esc				; Escape, back to the tile selector.

			cp 32
			jp z, .Space
			
			cp 13
			jr z, .Return

			cp 'M'
			jp z, .SecondaryHit

			cp 'N'
			jp z, .InOutPicker

			cp 9
			jp z, .GoingToMenuAction

			cp 'V'
			jr z, .GF

			cp 'T'
			jp z, .GetPixelColour

			; Insert more functions here.

			ld b, '0'
			cp '0'
			jr c, .TileEditorControl

			cp '9'+1
			jp c, .HitColorDirect

			ld b, 'A'-10
			cp 'A'
			jr c, .TileEditorControl

			cp 'F'+1
			jp c, .HitColorDirect

			jr .TileEditorControl

.Return:		call .EditorDissapear
			jp @EDITORSAVE

.GF:			ld iy, __FetchGraphics
			call @FarCallToPage3

			jp RunTileEditor

.Right:			ld bc,(EditorCursorX)
			ld a,b
			cp $FF
			jr z, .RightPicker
								; Is not in the picker.
			ld a, (SelectorMetaTileSize)
			cp c
			jp c, .TileEditorControl

			ld a, (KEYBRow6)
			and 3					; Tests for SHIT & CTRL pressed.
			cp 3
			jr z, .RNormal

			ld iy, _TileEdRight
			call @FarCallToPage2
			jp RunTileEditor

.RNormal:		inc c
			ld (EditorCursorX),bc
			jp .TileEditorControl

.RightPicker:		ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .RightPicker256
			cp FormatID.TileSc8_16
			jr z, .RightPicker256
			cp FormatID.TileSc8_32
			jr z, .RightPicker256

			inc c
			ld a,c
			and $0F
			ld c,a
			ld (EditorCursorX),bc
			ld (EditorCurrentPickerCursor), a
			jp .TileEditorControl

.RightPicker256:	ld a, c
			add a, $20
			jr nc, .RightPicker256Ok

			ld a, c
			and $03
			cp $03
			jp z, .TileEditorControl

			ld a, c
			and $1F
			inc a

.RightPicker256Ok:	ld c, a
			ld (EditorCursorX),bc
			ld (EditorCurrentPickerCursor), a
			jp .TileEditorControl
			
.Left:			ld bc,(EditorCursorX)
			ld a,b
			cp $FF
			jr z, .LeftPicker
								; Is not in the picker.
			ld a, (KEYBRow6)
			and 3					; Tests for SHIT & CTRL pressed.
			cp 3
			jr z, .LNormal

			ld iy, _TileEdLeft
			call @FarCallToPage2
			jp RunTileEditor

.LNormal:		ld a,c
			and a
			jp z, .TileEditorControl

			dec c
			ld (EditorCursorX),bc
			jp .TileEditorControl

.LeftPicker:		ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .LeftPicker256
			cp FormatID.TileSc8_16
			jr z, .LeftPicker256
			cp FormatID.TileSc8_32
			jr z, .LeftPicker256

			dec c
			ld a,c
			and $0F
			ld c,a
			ld (EditorCursorX),bc
			ld (EditorCurrentPickerCursor), a
			jp .TileEditorControl

.LeftPicker256:		ld a, c
			and $E0
			jr z, .LeftPicker256GreenOverflow

			ld a, c
			sub $20

.LeftPicker256Ok:	ld c, a
			ld (EditorCursorX),bc
			ld (EditorCurrentPickerCursor), a
			jp .TileEditorControl

.LeftPicker256GreenOverflow:ld a, c
			and $03
			jp z, .TileEditorControl

			ld a, c
			and $1F
			dec a
			or $E0
			jr .LeftPicker256Ok

.Down:			ld bc,(EditorCursorX)
			ld a, (SelectorMetaTileSize)
			dec a
			cp b
			jr nc, .DownOnTile

			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .DownPicker256
			cp FormatID.TileSc8_16
			jr z, .DownPicker256
			cp FormatID.TileSc8_32
			jr nz, .DownPickerEsc
								; Is in the picker.
.DownPicker256:		ld a, c
			and $1C
			cp $1C
			jr z, .DownPickerEsc

			ld a, c
			add a, $04
			ld c, a
			ld (EditorCursorX),bc
			ld (EditorCurrentPickerCursor), a
			jp .TileEditorControl
			
.DownPickerEsc:		ld a, c
			ld (EditorCurrentPickerCursor), a

			ld a, (SelectorMetaTileSize)
			and a
			rra
			ld c, a					; In the Middle_X of the tile.
			ld b, 0

			ld (EditorCursorX),bc
			jp .TileEditorControl

.DownOnTile:		ld a, (KEYBRow6)
			and 3					; Tests for SHIT & CTRL pressed.
			cp 3
			jr z, .DNormal

			ld iy, _TileEdDown
			call @FarCallToPage2
			jp RunTileEditor

.DNormal:		ld a, (SelectorMetaTileSize)
			dec a
			cp b
			jr z, .DownToPicker

			inc b
			ld (EditorCursorX),bc
			jp .TileEditorControl

.DownToPicker:		ld b,$FF
			ld a, (EditorCurrentPickerCursor)
			ld c, a
			ld (EditorCursorX),bc

			jp .TileEditorControl
			
.Up:			ld bc,(EditorCursorX)
			ld a, (SelectorMetaTileSize)
			dec a
			cp b
			jr nc, .UpOnTile
								; Only left that is on the picker.
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .UpPicker256
			cp FormatID.TileSc8_16
			jr z, .UpPicker256
			cp FormatID.TileSc8_32
			jr nz, .UpPickerEsc
								; Is in the picker.
.UpPicker256:		ld a, c
			and $1C
			jr z, .UpPickerEsc

			ld a, c
			sub $04
			ld c, a
			ld (EditorCursorX),bc
			ld (EditorCurrentPickerCursor), a
			jp .TileEditorControl

.UpPickerEsc:		ld a, c
			ld (EditorCurrentPickerCursor), a

			ld a, (SelectorMetaTileSize)
			ld b, a
			dec b
			and a
			rra
			ld c,a					; In the Middle_X of the tile.
			ld (EditorCursorX),bc
			jp .TileEditorControl

.UpOnTile:		ld a, (KEYBRow6)
			and 3					; Tests for SHIT & CTRL pressed.
			cp 3
			jr z, .UNormal

			ld iy, _TileEdUp
			call @FarCallToPage2
			jp RunTileEditor

.UNormal:		ld a, b
			and a
			jr z, .UpToPicker

			dec b
			ld (EditorCursorX),bc
			jp .TileEditorControl

.UpToPicker:		ld b, $FF
			ld a, (EditorCurrentPickerCursor)
			ld c, a
			ld (EditorCursorX),bc
			jp .TileEditorControl

.InOutPicker:		ld bc,(EditorCursorX)			; Fast way to go in the picker, and gets out.
			ld a, b
			cp $FF
			jr z, .OutPicker
								; Is out from the picker.
			ld (EditorCursorBackUp), bc
			ld b, $FF
			ld a, (EditorCurrentPickerCursor)
			ld c, a
.OutPickerJ1:		ld (EditorCursorX), bc
			jp .TileEditorControl

.OutPicker:		ld bc, (EditorCursorBackUp)
			jr .OutPickerJ1

.HitColorDirect:	sub b					; Converts the chart -> binary value.
			ld e, a

			ld bc,(EditorCursorX)

			ld a, (SelectorMetaTileSize)
			dec a
			cp b
			jp c, .TileEditorControl		; Vertical outside the tile? Escape!.

			cp c
			jp c, .WriteOnChromaChannel		; Horizontal outside the tile? Maybe is on the chroma channel, or in colour selected boxes.

			ld a, (EditorCurrentFormat)
			cp FormatID.TileSc2
			jr z, .HitColorOnSc2Tile

			cp FormatID.TileSc5
			jp z, .HitColorOnTileSc5
			cp FormatID.TileSc5_16
			jp z, .HitColorOnTileSc5
			cp FormatID.TileSc5_32
			jp nz, .TileEditorControl

.HitColorOnTileSc5:	ld a,(EditorCurrentForeColor)
			push af

			ld a, e
			ld (EditorCurrentForeColor), a
			call .Sc5TileHit_Call
			pop af

			ld (EditorCurrentForeColor), a
			jp .Sc2BitDrw

.HitColorOnSc2Tile:	ld hl, EditorBuffer + 8			; First checks if there is a matching colour already.
			ld a, b					; Screen 2 format is allways 8x8.
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a, (hl)				; It reads the colour.
			and $0F
			cp e
			jr z, .ZeroIsOk

			ld a, (hl)
			rrca
			rrca
			rrca
			rrca
			and $0F
			cp e
			jr z, .OneIsOk
								; No current colour matchs.
			ld hl, EditorBuffer 			; Wich number are less used, zeroes or ones?.
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a, (hl)				; It reads the pattern.

			push bc
			ld d, 0

			ld b, 8					; It counts how many 1's is there.

.HCSc2TLoop:		rra
			jr nc, .HCSc2TJump
			inc d
.HCSc2TJump:		djnz .HCSc2TLoop

			ld a, d
			cp 4
			pop bc
			jr c, .HCSc2TFew1
								; There are few zeroes in use.
.HCSc2TFew0:		ld b, c
			inc b

			ld c, 0
			scf

.HCSc2Bit:		rr c 
			djnz .HCSc2Bit
			
			ld a, c
			cpl
			ld b, a

			ld a, (hl)
			and b					; Set a zero.
			ld (hl), a

			ld bc, 8
			add hl, bc

			ld a, (hl)
			and $F0
			or e
			ld (hl), a

			ld bc,(EditorCursorX)
			ld c, 9
			call .RenderWhatIsPointed

			jp .Sc2BitDrw			

.HCSc2TFew1:		ld b, c
			inc b

			ld c, 0
			scf

.HCSc2Bit1:		rr c
			djnz .HCSc2Bit1

			ld a, c
			cpl
			ld b, a

			ld a, (hl)
			or c
			ld (hl), a

			ld bc, 8
			add hl, bc

			rl e
			rl e
			rl e
			rl e
			
			ld a, (hl)
			and $0F
			or e
			ld (hl), a

			ld bc,(EditorCursorX)
			ld c, 8
			call .RenderWhatIsPointed

			jp .Sc2BitDrw			

.ZeroIsOk:		ld hl, EditorBuffer
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a
			jr .HCSc2TFew0

.OneIsOk:		ld hl, EditorBuffer
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a
			jr .HCSc2TFew1

.WriteOnChromaChannel:	ld a, (EditorCurrentFormat)
			cp FormatID.TileSc5
			jr z, .WriteOnChromaChannelSc5
			cp FormatID.TileSc5_16
			jr z, .WriteOnChromaChannelSc5
			cp FormatID.TileSc5_32
			jr z, .WriteOnChromaChannelSc5

			cp FormatID.TileSc2
			jp nz, .Sc2BitDrw

			ld a, c
			cp 8
			jr z, .WriteOnChromaChannel1
								; It is on the zeroes colour band.
			ld hl, EditorBuffer + 8
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a, (hl)
			and $F0
			or e
			ld (hl), a

			ld bc,(EditorCursorX)
			ld c, 0
			call .RenderWhatIsPointed

			jp .Sc2BitDrw

.WriteOnChromaChannel1:	ld hl, EditorBuffer + 8
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a, (hl)
			and $0F

			rl e
			rl e
			rl e
			rl e

			or e
			ld (hl), a

			ld bc,(EditorCursorX)
			ld c, 0
			call .RenderWhatIsPointed

			jr .Sc2BitDrw

.WriteOnChromaChannelSc5:
			ld a, (SelectorMetaTileSize)
			cp c

			ld a, e
			jr nz, .WriteOnChromaChannelSc5_2

			ld (EditorCurrentForeColor),a
			jr .Sc2BitDrw

.WriteOnChromaChannelSc5_2:

			ld (EditorCurrentBackColor),a
			jr .Sc2BitDrw

.Space:			ld bc, (EditorCursorX)			; It is like the primary button hit.

			ld a, (SelectorMetaTileSize)
			dec a
			cp b
			jp c, .HitOnPicker			; Because Y only can be 0-(TileSize-1) and $FF.
			cp c
			jp c, .HitOnChromaChannel
								; THE USER HITs ON THE TILE DRAWING!!!.
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .Sc8TileHit
			cp FormatID.TileSc8_16
			jr z, .Sc8TileHit
			cp FormatID.TileSc8_32
			jr z, .Sc8TileHit
			cp FormatID.TileSc5
			jr z, .Sc5TileHit
			cp FormatID.TileSc5_16
			jr z, .Sc5TileHit
			cp FormatID.TileSc5_32
			jr z, .Sc5TileHit
								; Here when is Sc2 format.
			ld hl, EditorBuffer
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld b,c
			inc b

			ld c,0
			scf

.Sc2Bit:		rr c 
			djnz .Sc2Bit
			
			ld a,c
			cpl
			ld b,a

			ld a,(hl)
			and c
			jr z, .Sc2BitSet

			ld a,(hl)
			and b
			ld (hl),a				; Turns Sc2 encoding tile bit pattern 1 in 0.
			jr .Sc2BitDrw			

.Sc2BitSet:		ld a,(hl)
			or c					; Turns Sc2 encoding tile bit pattern 0 in 1.
			ld (hl),a

.Sc2BitDrw:		push af					; Redraws the object where is the cursor.
			ld bc,(EditorCursorX)
			call .RenderWhatIsPointed
			pop af

			jp .TileEditorControl			; Returns the control to the keyboard.

.Sc5TileHit:		call .Sc5TileHit_Call
			jr .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.Sc5TileHit_Call:	ld hl, EditorBuffer

			ld a, (SelectorMetaTileSize)
			rrca
			ld e, a
			ld d, 0

			ld a, b
			and a
			jr z, .Sc5TileHitNoAddY

.Sc5TileHitLoopAddY:	add hl, de
			djnz .Sc5TileHitLoopAddY

.Sc5TileHitNoAddY:	ld a, c
			and $FE
			rrca
			ld e, a
			add hl, de

			ld a,c
			and 1
			jr nz, .Sc5TileHitRightPix

			ld a,(hl)
			and $0F
			ld c,a

			ld a,(EditorCurrentForeColor)
			add a,a
			add a,a
			add a,a
			add a,a
			or c					; Sets the color of the left pixel in the pixel-pair in Sc5 encoding.

			ld (hl),a
			ret

.Sc5TileHitRightPix:	ld a,(hl)
			and $F0
			ld c,a

			ld a,(EditorCurrentForeColor)
			and $0F
			or c					; Sets the color of the right pixel in the pixel-pair in Sc5 encoding.

			ld (hl),a
			ret

.Sc8TileHit:		ld hl, EditorBuffer
			ld a, (SelectorMetaTileSize)
			ld e, a
			ld d, 0

			ld a, b
			and a
			jr z, .Sc8TileHitNoAddY

.Sc8TileHitLoopAddY:	add hl, de
			djnz .Sc8TileHitLoopAddY

.Sc8TileHitNoAddY:	ld e, c
			add hl, de

			ld a,(EditorCurrentForeColor)
			ld (hl),a				; Sets the color of the pixel in Sc8 encoding.
			jr .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.HitOnChromaChannel:	ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .Sc8ChromaHit
			cp FormatID.TileSc8_16
			jr z, .Sc8ChromaHit
			cp FormatID.TileSc8_32
			jr z, .Sc8ChromaHit
			cp FormatID.TileSc5
			jr z, .Sc5ChromaHit
			cp FormatID.TileSc5_16
			jr z, .Sc5ChromaHit
			cp FormatID.TileSc5_32
			jr z, .Sc5ChromaHit
								; Sc2 Chroma channel hit.
			ld hl, EditorBuffer + 8
			ld a,b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			bit 0,c					; It checks if must change, ONEs pallete or ZEROes pallete.
			jr nz, .HitSc2ZEROesPal

			ld a,(EditorCurrentLastPickedColor)	; It sets the ONEs pallete as cursorX = 8.
			add a,a
			add a,a
			add a,a
			add a,a
			ld c,a
			ld a,(hl)
			and $0F
			or c					; It sets the ONEs COLOR selection in Sc2 tile encoding.
			ld (hl),a
			
			ld bc,(EditorCursorX)
			ld c,0
			call .RenderWhatIsPointed		; It redraw the affected ROW on the tile box.
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).
			
.HitSc2ZEROesPal:	ld a,(EditorCurrentLastPickedColor)	; It sets the ZEROes pallete as cursorX = 9.
			and $0F					; This variable can brings color selection in other format like Sc8. It make sure that the color code is in the correct boundaries.
			ld c,a
			ld a,(hl)
			and $F0
			or c					; It sets the ZEROes COLOR selection in Sc2 tile encoding.
			ld (hl),a

			ld bc,(EditorCursorX)
			ld c,0
			call .RenderWhatIsPointed		; It redraw the affected ROW on the tile box.
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.Sc8ChromaHit:		ld a, (SelectorMetaTileSize)
			cp c
			jr z, .Sc8HitPrimary
								; It hits the secondary box.
			ld a,(EditorCurrentLastPickedColor)
			ld (EditorCurrentBackColor),a
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.Sc8HitPrimary:		ld a,(EditorCurrentLastPickedColor)
			ld (EditorCurrentForeColor),a
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.Sc5ChromaHit:		ld a, (SelectorMetaTileSize)
			cp c
			jr z, .Sc5HitPrimary
								; It hits the secondary box.
			ld a,(EditorCurrentLastPickedColor)
			and $0F
			ld (EditorCurrentBackColor),a
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.Sc5HitPrimary:		ld a,(EditorCurrentLastPickedColor)
			and $0F
			ld (EditorCurrentForeColor),a
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.HitOnPicker:		ld a,c
			ld (EditorCurrentLastPickedColor),a

			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc2
			jp z, .Sc2BitDrw

			ld a,c
			ld (EditorCurrentForeColor),a

			ld a, (SelectorMetaTileSize)
			ld c, a
			ld b, 0
			call .RenderWhatIsPointed		; It redraws the primary color box.
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.SecondaryHit:		ld bc, (EditorCursorX)
			ld a, (SelectorMetaTileSize)
			dec a
			cp b
			jp c, .SHitOnPicker			; Because Y only can be 0-(TileSize-1) and $FF.
			cp c
			jp c, .SHitOnChromaChannel
								; THE USER HITs ON THE TILE DRAWING!!!.
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .SSc8TileHit
			cp FormatID.TileSc8_16
			jr z, .SSc8TileHit
			cp FormatID.TileSc8_32
			jr z, .SSc8TileHit
			cp FormatID.TileSc5
			jr z, .SSc5TileHit
			cp FormatID.TileSc5_16
			jr z, .SSc5TileHit
			cp FormatID.TileSc5_32
			jr z, .SSc5TileHit
								; Here when is Sc2 format. But it only needs the primary button.

			; /////// HERE IS THE BEEP about that someone claimed in the MRC forum //////.

			call @BEEP
			jp .Sc2BitDrw

.SSc5TileHit:		ld hl, EditorBuffer

			ld a, (SelectorMetaTileSize)
			rrca
			ld e, a
			ld d, 0

			ld a, b
			and a
			jr z, .SSc5TileHitNoAddY

.SSc5TileHitLoopAddY:	add hl, de
			djnz .SSc5TileHitLoopAddY

.SSc5TileHitNoAddY:	ld a, c
			and $FE
			rrca
			ld e, a
			add hl, de

			ld a,c
			and 1
			jr nz, .SSc5TileHitRightPix

			ld a,(hl)
			and $0F
			ld c,a

			ld a,(EditorCurrentBackColor)
			add a,a
			add a,a
			add a,a
			add a,a
			or c					; Sets the color of the left pixel in the pixel-pair in Sc5 encoding.

			ld (hl),a
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.SSc5TileHitRightPix:	ld a,(hl)
			and $F0
			ld c,a

			ld a,(EditorCurrentBackColor)
			and $0F
			or c					; Sets the color of the right pixel in the pixel-pair in Sc5 encoding.

			ld (hl),a
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.SSc8TileHit:		ld hl, EditorBuffer
			
			ld a, (SelectorMetaTileSize)
			ld e, a
			ld d, 0

			ld a, b
			and a
			jr z, .SSc8TileHitNoAddY

.SSc8TileHitLoopAddY:	add hl, de
			djnz .SSc8TileHitLoopAddY

.SSc8TileHitNoAddY:	ld e, c
			add hl, de

			ld a,(EditorCurrentBackColor)
			ld (hl),a				; Sets the color of the pixel in Sc8 encoding.
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.SHitOnChromaChannel:	call @BEEP
			jp .Sc2BitDrw

.SHitOnPicker:		ld a,c
			ld (EditorCurrentLastPickedColor),a

			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc2
			jp z, .Sc2BitDrw

			ld a,c
			ld (EditorCurrentBackColor),a

			ld a, (SelectorMetaTileSize)
			inc a
			ld c, a
			ld b, 0
			call .RenderWhatIsPointed		; It redraws the secondary color box.
			jp .Sc2BitDrw				; Return redrawing (the labelname has not a meaning in this case).

.GoingToMenuAction:	ld ix, ActionMenu1Data
			call MENUPOPUP
			jr c, .ActionMnuEsc

			and a
			jr z, .XMirror

			dec a
			jp z, .YMirror

			dec a
			jp z, .Rotate

			dec a
			jp z, .ShiftLeft

			dec a
			jp z, .ShiftRight

			dec a
			jp z, .ShiftUp

			dec a
			jp z, .ShiftDown

			jp .TileEditorControl

.ActionMnuEsc:		and a
			jp nz, .ActionMnuEscJ1

			call .EditorDissapear

			ld a, $FF
			ld (PuzzlerForceRenderAll), a
			call RenderPuzzler			; It redraws the puzzler because with some formats it moves to another place when editing.
			xor a
			ld (PuzzlerForceRenderAll), a

			jp RunTileEditor

.ActionMnuEscJ1:	cp $01
			jr z, .GoingToMenuAction2

			jp .GoingToMenuAction
	
.GoingToMenuAction2:	ld ix, ActionMenu2Data
			call MENUPOPUP
			jr c, .Action2MnuEsc		

			and a
			jp z, .TileClear

			dec a
			jp z, .FillPattern

			dec a
			jp z, .PatternNot

			dec a
			jp z, .ChromaSwSc2

			jp .TileEditorControl

.Action2MnuEsc:		and a
			jr nz, .Action2MnuEscJ1

			call .EditorDissapear

			ld a, $FF
			ld (PuzzlerForceRenderAll), a
			call RenderPuzzler			; It redraws the puzzler because with some formats it moves to another place when editing.
			xor a
			ld (PuzzlerForceRenderAll), a

			jp RunTileEditor

.Action2MnuEscJ1:	cp $FF
			jr z, .GoingToMenuAction

			jp .GoingToMenuAction2

.XMirror:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .XmirrorSc8
			cp FormatID.TileSc8_16
			jr z, .XmirrorSc8
			cp FormatID.TileSc8_32
			jr z, .XmirrorSc8

			cp FormatID.TileSc5
			jr z, .XmirrorSc5
			cp FormatID.TileSc5_16
			jr z, .XmirrorSc5
			cp FormatID.TileSc5_32
			jr z, .XmirrorSc5
								; Only left XmirrorSc2.
			ld hl, EditorBuffer
			ld b,8

.XMSc2YLoop:		push bc

			ld b,8

			ld a,(hl)
			
.XMSc2XLoop:		rra
			rl c
			djnz .XMSc2XLoop

			ld (hl),c

			pop bc
			inc hl
			djnz .XMSc2YLoop

			call .RenderEditorContentSc2

			jp .GoingToMenuAction

.XMirrorSc8:		ld hl, EditorBuffer
			ld a, (SelectorMetaTileSize)
			ld b, a
			add a, l
			ld e, a
			ld a, h
			adc a, 0
			ld d, a

.XMSc8YLoop:		push bc
			push de
			push hl

			ld a, (SelectorMetaTileSize)
			rrca
			ld b, a

.XMSc8XLoop:		dec de
			ld a,(de)
			ld c,(hl)
			ld (hl),a
			ld a,c
			ld (de),a
			inc hl
			djnz .XMSc8XLoop

			pop hl
			pop de
			pop bc

			ld a, (SelectorMetaTileSize)
			add a,e
			ld e,a
			ld a,d
			adc a,0
			ld d,a

			ld a, (SelectorMetaTileSize)
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			djnz .XMSc8YLoop

			call .RenderEditorContentSc8

			jp .GoingToMenuAction

.XMirrorSc5:		ld hl, EditorBuffer
			ld a, (SelectorMetaTileSize)
			ld b, a
			rrca
			add a, l
			ld e, a
			ld a, h
			adc a, 0
			ld d, a

.XMSc5YLoop:		push de
			push hl
			push bc

			ld a, (SelectorMetaTileSize)
			rrca
			rrca
			ld b, a

.XMSc5XLoop:		dec de
			ld a,(de)
			ld c,(hl)
			rrca
			rrca
			rrca
			rrca
			ld (hl),a
			ld a,c
			rrca
			rrca
			rrca
			rrca
			ld (de),a
			inc hl
			djnz .XMSc5XLoop

			pop bc
			pop hl
			pop de

			ld a, (SelectorMetaTileSize)
			rrca
			add a,e
			ld e,a
			ld a,d
			adc a,0
			ld d,a

			ld a, (SelectorMetaTileSize)
			rrca
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			djnz .XMSc5YLoop

			call .RenderEditorContentSc5

			jp .GoingToMenuAction

.YMirror:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .YmirrorSc8
			cp FormatID.TileSc8_16
			jr z, .YmirrorSc8
			cp FormatID.TileSc8_32
			jr z, .YmirrorSc8

			cp FormatID.TileSc5
			jr z, .YmirrorSc5
			cp FormatID.TileSc5_16
			jr z, .YmirrorSc5
			cp FormatID.TileSc5_32
			jr z, .YmirrorSc5
								; Only left YmirrorSc2.
			ld hl, EditorBuffer
			ld de, EditorBuffer + 8

			ld b, 2

.YMSc2ChLoop:		push de
			push hl
			push bc

			ld b,4

.YMSc2YLoop:		dec de
			ld c,(hl)
			ld a,(de)
			ld (hl),a
			ld a,c
			ld (de),a
			inc hl
			djnz .YMSc2YLoop

			pop bc
			pop hl
			pop de

			ld a,8
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a,8
			add a,e
			ld e,a
			ld a,d
			adc a,0
			ld d,a

			djnz .YMSc2ChLoop

			call .RenderEditorContentSc2

			call .RenderChromaChSc2

			jp .GoingToMenuAction

.YmirrorSc8:		ld a, (SelectorMetaTileSize)
			ld b, a
			ld hl, 0
			ld e, a
			ld d, h

			ld c, b
			dec b

.YmirrorSc8Mult:	add hl, de
			djnz .YmirrorSc8Mult

			ld a, c
			rrca
			ld b, a

			ld de, EditorBuffer
			add hl,de
			ex de, hl

.YMSc8YLoop:		push bc
			push de

			ld a, (SelectorMetaTileSize)
			ld b, a

.YMSc8XLoop:		ld c,(hl)
			ld a,(de)
			ld (hl),a
			ld a,c
			ld (de),a
			inc de
			inc hl
			djnz .YMSc8XLoop

			pop de

			ld a, (SelectorMetaTileSize)
			ld b, a
			ld a, e
			sub b
			ld e, a
			ld a,d
			sbc a,0
			ld d,a

			pop bc
			djnz .YMSc8YLoop

			call .RenderEditorContentSc8

			jp .GoingToMenuAction

.YmirrorSc5:		ld a, (SelectorMetaTileSize)
			ld b, a
			rrca
			ld hl, 0
			ld e, a
			ld d, h

			ld c, b
			dec b

.YmirrorSc5Mult:	add hl, de
			djnz .YmirrorSc5Mult

			ld a, c
			rrca
			ld b, a

			ld de, EditorBuffer
			add hl,de
			ex de, hl

.YMSc5YLoop:		push bc
			push de

			ld a, (SelectorMetaTileSize)
			rrca
			ld b,a

.YMSc5XLoop:		ld c,(hl)
			ld a,(de)
			ld (hl),a
			ld a,c
			ld (de),a
			inc de
			inc hl
			djnz .YMSc5XLoop

			pop de

			ld a, (SelectorMetaTileSize)
			rrca
			ld b, a
			ld a, e
			sub b
			ld e, a
			ld a,d
			sbc a,0
			ld d,a

			pop bc
			djnz .YMSc5YLoop

			call .RenderEditorContentSc5

			jp .GoingToMenuAction

.ShiftRight:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .ShiftRightSc8
			cp FormatID.TileSc8_16
			jr z, .ShiftRightSc8
			cp FormatID.TileSc8_32
			jr z, .ShiftRightSc8

			cp FormatID.TileSc5
			jr z, .ShiftRightSc5
			cp FormatID.TileSc5_16
			jr z, .ShiftRightSc5
			cp FormatID.TileSc5_32
			jr z, .ShiftRightSc5
								; Only left .ShiftRightSc2.
			ld hl, EditorBuffer
			ld b,8

.SRSc2YLoop:		ld a,(hl)
			and a
			rra
			ld (hl),a
			inc hl

			djnz .SRSc2YLoop

			call .RenderEditorContentSc2

			jp .GoingToMenuAction

.ShiftRightSc8:		ld a, (SelectorMetaTileSize)
			ld hl, 0
			ld e, a
			ld d, 0
			ld b, a

.ShiftRightSc8Mult:	add hl, de
			djnz .ShiftRightSc8Mult

			dec hl
			ld c, l
			ld b, h
			ld de, EditorBuffer
			add hl, de
			ld e, l
			ld d, h
			dec hl

			lddr

			ld hl, EditorBuffer
			ld a, (SelectorMetaTileSize)
			ld b, a

.SRSc8Loop:		ld a,(EditorCurrentBackColor)
			ld (hl),a

			ld a, (SelectorMetaTileSize)
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			djnz .SRSc8Loop

			call .RenderEditorContentSc8

			jp .GoingToMenuAction

.ShiftRightSc5:		ld hl, EditorBuffer

			ld a, (SelectorMetaTileSize)
			ld b, a

.SRSc5YLoop:		push bc

			ld a,(EditorCurrentBackColor)
			and $0F
			rrca
			rrca
			rrca
			rrca
			ld c, a

			ld a, (SelectorMetaTileSize)
			rrca
			ld b, a

.SRSc5XLoop:		ld a,(hl)
			rrca
			rrca
			rrca
			rrca
			push af
			and $0F
			or c
			ld (hl),a
			pop af
			and $F0
			ld c,a
			inc hl

			djnz .SRSc5XLoop

			pop bc
			djnz .SRSc5YLoop

			call .RenderEditorContentSc5

			jp .GoingToMenuAction

.ShiftLeft:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .ShiftLeftSc8
			cp FormatID.TileSc8_16
			jr z, .ShiftLeftSc8
			cp FormatID.TileSc8_32
			jr z, .ShiftLeftSc8

			cp FormatID.TileSc5
			jr z, .ShiftLeftSc5
			cp FormatID.TileSc5_16
			jr z, .ShiftLeftSc5
			cp FormatID.TileSc5_32
			jr z, .ShiftLeftSc5
								; Only left .ShiftLeftSc2.
			ld hl, EditorBuffer
			ld b,8

.SLSc2YLoop:		ld a,(hl)
			and a
			rla
			ld (hl),a
			inc hl

			djnz .SLSc2YLoop

			call .RenderEditorContentSc2

			jp .GoingToMenuAction

.ShiftLeftSc8:		ld a, (SelectorMetaTileSize)
			ld b, a
			ld hl, 0
			ld e, a
			ld d, h

.ShiftLeftSc8Mult:	add hl, de
			djnz .ShiftLeftSc8Mult

			dec hl
			ld c, l
			ld b, h

			ld de, EditorBuffer
			ld hl, EditorBuffer+1

			ldir

			ld hl, EditorBuffer
			ld a, (SelectorMetaTileSize)
			ld b, a
			dec a
			add a, l
			ld l, a
			ld a, h
			adc a, 0
			ld h, a

.SLSc8Loop:		ld a,(EditorCurrentBackColor)
			ld (hl),a

			ld a, (SelectorMetaTileSize)
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			djnz .SLSc8Loop

			call .RenderEditorContentSc8

			jp .GoingToMenuAction

.ShiftLeftSc5:		ld a, (SelectorMetaTileSize)
			ld b, a
			ld hl, 0
			rrca
			ld e, a
			ld d, h
			ld c, b

.ShiftLeftSc5Mult:	add hl, de
			djnz .ShiftLeftSc5Mult
			dec hl
			ld de, EditorBuffer
			add hl, de
			ld b, c

.SLSc5YLoop:		push bc

			ld a,(EditorCurrentBackColor)
			and $0F
			ld c,a

			ld a, (SelectorMetaTileSize)
			rrca
			ld b, a

.SLSc5XLoop:		ld a,(hl)
			rlca
			rlca
			rlca
			rlca
			push af
			and $F0
			or c
			ld (hl),a
			pop af
			and $0F
			ld c,a
			dec hl

			djnz .SLSc5XLoop

			pop bc
			djnz .SLSc5YLoop

			call .RenderEditorContentSc5

			jp .GoingToMenuAction

.ShiftUp:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .ShiftUpSc8
			cp FormatID.TileSc8_16
			jr z, .ShiftUpSc8
			cp FormatID.TileSc8_32
			jr z, .ShiftUpSc8

			cp FormatID.TileSc5
			jr z, .ShiftUpSc5
			cp FormatID.TileSc5_16
			jr z, .ShiftUpSc5
			cp FormatID.TileSc5_32
			jr z, .ShiftUpSc5
								; Only left .ShiftUpSc2.
			ld hl, EditorBuffer+1
			ld de, EditorBuffer
			ld bc, 15

			ldir

			ld hl, EditorBuffer+7
			ld (hl),0

			ld hl, EditorBuffer+15
			ld (hl),0

			call .RenderEditorContentSc2

			call .RenderChromaChSc2

			jp .GoingToMenuAction

.ShiftUpSc8:		ld a, (SelectorMetaTileSize)
			ld b, a

			ld hl, 0
			ld e, a
			ld d, h

			dec b

.ShiftUpSc8Mult:	add hl, de
			djnz .ShiftUpSc8Mult			; (SelectorMetaTileSize) * ((SelectorMetaTileSize) -1)

			ld c, l
			ld b, h

			ld hl, EditorBuffer			; hl = EditorBuffer + (SelectorMetaTileSize) 
			add hl, de
			ld de, EditorBuffer

			push bc
			ldir
			pop bc

			ld hl, EditorBuffer
			add hl, bc
			ld e, l
			ld d, h
			inc de
			ld a, (SelectorMetaTileSize)
			dec a
			ld c, a
			ld b, 0
			ld a,(EditorCurrentBackColor)
			ld (hl),a
			ldir

			call .RenderEditorContentSc8

			jp .GoingToMenuAction

.ShiftUpSc5:		ld a, (SelectorMetaTileSize)
			ld b, a

			ld hl, 0
			rrca
			ld e, a
			ld d, h

			dec b

.ShiftUpSc5Mult:	add hl, de
			djnz .ShiftUpSc5Mult			; (SelectorMetaTileSize) * ((SelectorMetaTileSize) -1)

			ld c, l
			ld b, h

			ld hl, EditorBuffer			; hl = EditorBuffer + (SelectorMetaTileSize / 2) 
			add hl, de
			ld de, EditorBuffer

			push bc
			ldir
			pop bc

			ld hl, EditorBuffer
			add hl, bc
			ld a,(EditorCurrentBackColor)
			and $0F
			ld c,a
			rrca
			rrca
			rrca
			rrca
			or c

			ex af, af'
			ld a, (SelectorMetaTileSize)
			rrca
			ld b, a
			ex af, af'

.ShiftUpSc5Loop:	ld (hl), a
			inc hl
			djnz .ShiftUpSc5Loop

			call .RenderEditorContentSc5

			jp .GoingToMenuAction

.ShiftDown:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .ShiftDownSc8
			cp FormatID.TileSc8_16
			jr z, .ShiftDownSc8
			cp FormatID.TileSc8_32
			jr z, .ShiftDownSc8

			cp FormatID.TileSc5
			jr z, .ShiftDownSc5
			cp FormatID.TileSc5_16
			jr z, .ShiftDownSc5
			cp FormatID.TileSc5_32
			jr z, .ShiftDownSc5
								; Only left .ShiftDownSc2.
			ld hl, EditorBuffer+14
			ld de, EditorBuffer+15
			ld bc, 15

			lddr

			ld hl, EditorBuffer+0
			ld (hl),0

			ld hl, EditorBuffer+8
			ld (hl),0

			call .RenderEditorContentSc2

			call .RenderChromaChSc2

			jp .GoingToMenuAction

.ShiftDownSc8:		ld a, (SelectorMetaTileSize)
			ld b, a

			ld hl, 0
			ld e, a
			ld d, h

.ShiftDownSc8Mult:	add hl, de
			djnz .ShiftDownSc8Mult			; (SelectorMetaTileSize) * (SelectorMetaTileSize)

			ld c, l
			ld b, h
			push bc

			dec bc

			ld hl, EditorBuffer			; de = EditorBuffer + (SelectorMetaTileSize) * (SelectorMetaTileSize) - 1.
			add hl, bc
			ld e, l
			ld d, h					; hl = de

			ld a, (SelectorMetaTileSize)
			ld b, a
			ld a, l
			sub b
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a					; hl = hl - (SelectorMetaTileSize)
			pop bc

			push de
			ld a, (SelectorMetaTileSize)
			ld e, a
			ld a, c
			sub e
			ld c, a
			ld a, b
			sbc a, 0
			ld b, a
			pop de					; bc = (SelectorMetaTileSize) * (SelectorMetaTileSize) - (SelectorMetaTileSize).

			lddr

			ld hl, EditorBuffer
			ld de, EditorBuffer+1
			ld a, (SelectorMetaTileSize)
			dec a
			ld c, a
			ld b, 0
			ld a,(EditorCurrentBackColor)
			ld (hl),a
			ldir

			call .RenderEditorContentSc8

			jp .GoingToMenuAction

.ShiftDownSc5:		ld a, (SelectorMetaTileSize)
			ld b, a

			rrca
			ld hl, 0
			ld e, a
			ld d, h

.ShiftDownSc5Mult:	add hl, de
			djnz .ShiftDownSc5Mult			; (SelectorMetaTileSize) * (SelectorMetaTileSize / 2)

			ld c, l
			ld b, h
			push bc

			dec bc

			ld hl, EditorBuffer			; de = EditorBuffer + (SelectorMetaTileSize) * (SelectorMetaTileSize / 2) - 1.
			add hl, bc
			ld e, l
			ld d, h					; hl = de.

			ld a, (SelectorMetaTileSize)
			rrca
			ld b, a
			ld a, l
			sub b
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a					; hl = hl - (SelectorMetaTileSize / 2)
			pop bc

			push de
			ld a, (SelectorMetaTileSize)
			rrca
			ld e, a
			ld a, c
			sub e
			ld c, a
			ld a, b
			sbc a, 0
			ld b, a
			pop de					; bc = (SelectorMetaTileSize) * (SelectorMetaTileSize) - (SelectorMetaTileSize / 2).

			lddr

			ld hl, EditorBuffer
			ld a, (EditorCurrentBackColor)
			and $0F
			ld c,a
			rrca
			rrca
			rrca
			rrca
			or c
			ld c, a

			ld a, (SelectorMetaTileSize)
			rrca
			ld b, a

			ld a, c

.ShiftDownSc5Loop:	ld (hl),a
			inc hl
			djnz .ShiftDownSc5Loop

			call .RenderEditorContentSc5

			jp .GoingToMenuAction

.Rotate:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .ShiftRotateSc8
			cp FormatID.TileSc8_16
			jr z, .ShiftRotateSc8
			cp FormatID.TileSc8_32
			jr z, .ShiftRotateSc8

			cp FormatID.TileSc5
			jp z, .ShiftRotateSc5
			cp FormatID.TileSc5_16
			jr z, .ShiftRotateSc5
			cp FormatID.TileSc5_32
			jr z, .ShiftRotateSc5
								; Only left .ShiftRotateSc2.
			ld de, UserAreaCpyBuffer
			ld hl, EditorBuffer
			ld bc, 8
			ldir

			ld hl, UserAreaCpyBuffer+7
			ld de, EditorBuffer

			ld c,1
			ld b,8

.RTSc2XLoop:		push bc
			push hl

			ld b,8

.RTSc2YLoop:		push bc
			ld a,(Hl)
			dec hl
			ld b,c

.RTFeedBitLoop:		rla
			djnz .RTFeedBitLoop

			exx
			rl d
			exx
			pop bc

			djnz .RTSc2YLoop

			exx
			ld a,d
			exx
			ld (de),a
			inc de

			pop hl
			pop bc			
			inc c
			
			djnz .RTSc2XLoop

			call .RenderEditorContentSc2

			jp .GoingToMenuAction

.ShiftRotateSc8:	ld a, (SelectorMetaTileSize)
			ld b, a
			ld e, a
			ld d, 0
			ld l, d
			ld h, d

.ShiftRotateSc8Mult:	Add hl, de
			djnz .ShiftRotateSc8Mult

			ld c, l
			ld b, h

			push bc
			ld de, SelectorBuffer
			ld hl, EditorBuffer
			ldir

			pop hl
			ld a, (SelectorMetaTileSize)
			ld c, a
			ld b, 0
			sbc hl, bc
			ld de, SelectorBuffer
			add hl, de

			ld de, EditorBuffer

			ld b, c
			
.SRotateSc8XLoop:	push bc
			push hl

			ld b, c
		
.SRotateSc8YLoop:	ld a,(hl)
			ld (de),a
			ld a,l
			sub c
			ld l,a
			ld a,h
			sbc a,0
			ld h,a
			inc de
			djnz .SRotateSc8YLoop

			pop hl
			inc hl
			pop bc
			djnz .SRotateSc8XLoop

			call .RenderEditorContentSc8

			jp .GoingToMenuAction

.ShiftRotateSc5:	ld a, (SelectorMetaTileSize)
			ld b, a
			rrca
			ld e, a
			ld d, 0
			ld l, d
			ld h, d

.ShiftRotateSc5Mult:	Add hl, de
			djnz .ShiftRotateSc5Mult

			ld c, l
			ld b, h

			push bc
			ld de, SelectorBuffer
			ld hl, EditorBuffer
			ldir

			pop hl
			ld a, (SelectorMetaTileSize)
			rrca
			ld c, a
			ld b, 0
			sbc hl, bc
			ld de, SelectorBuffer
			add hl, de

			ld de, EditorBuffer

			ld b, c

			ld a, c
			exx
			ld c, a					; C' = in memory tile row size.
			exx

.SRotateSc5XLoop:	push bc
			push hl

			ld b, c

.SRotateSc5YLoop:	push de
			push hl
			ld a,(hl)
			and $F0
			ld c,a

			ld a, l
			exx
			sub c
			exx
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a					; hl = hl - in memory tile row size.

			ld a,(hl)
			rrca
			rrca
			rrca
			rrca
			and $0F
			or c
			ld (de),a			

			ld a, e
			exx
			add a, c
			exx
			ld e, a
			ld a, d
			adc a, 0
			ld d, a					; de = de + in memory row size.

			ld a,(hl)
			and $0F
			ld c,a

			ld a, l
			exx
			add a, c
			exx
			ld l, a
			ld a, h
			adc a, 0
			ld h, a					; hl = hl + in memory tile row size.

			ld a,(hl)
			rlca
			rlca
			rlca
			rlca
			and $F0
			or c
			ld (de),a
			pop hl
			pop de

			inc de

			ld a, l
			exx
			sub c
			exx
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a					; hl = hl - in memory tile row size.
			ld a, l
			exx
			sub c
			exx
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a					; hl = hl - in memory tile row size.

			djnz .SRotateSc5YLoop

			ld a, e
			exx
			add a, c
			exx
			ld e, a
			ld a, d
			adc a, 0
			ld d, a					; de = de + in memory row size.

			pop hl
			inc hl

			pop bc
			djnz .SRotateSc5XLoop

			call .RenderEditorContentSc5

			jp .GoingToMenuAction

.TileClear:		call .TileClear.Int
			jp .GoingToMenuAction2

.TileClear.Int:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .TileClearSc8
			cp FormatID.TileSc8_16
			jr z, .TileClearSc8
			cp FormatID.TileSc8_32
			jr z, .TileClearSc8

			cp FormatID.TileSc5
			jr z, .TileClearSc5
			cp FormatID.TileSc5_16
			jr z, .TileClearSc5
			cp FormatID.TileSc5_32
			jr z, .TileClearSc5
								; Only left .TileClearSc2.
			ld hl, EditorBuffer
			ld de, EditorBuffer+1
			ld bc,7
			ld (hl),0
			ldir

			inc hl
			ld a,(EditorCurrentLastPickedColor)
			and $0F
			ld (hl),a
			ld e,l
			ld d,h
			inc de
			ld bc,7
			ldir		

			call .RenderEditorContentSc2

			jp .RenderChromaChSc2

.TileClearSc8:		ld a, (SelectorMetaTileSize)
			ld b, a
			ld e, a
			ld d, 0
			ld l, d
			ld h, d

.TileClearSc8Mult:	Add hl, de
			djnz .TileClearSc8Mult

			ld c, l
			ld b, h
			dec bc

			ld hl, EditorBuffer
			ld de, EditorBuffer+1
			ld a,(EditorCurrentBackColor)
			ld (hl),a
			ldir

			jp .RenderEditorContentSc8

.TileClearSc5:		ld a, (SelectorMetaTileSize)
			ld b, a
			rrca
			ld e, a
			ld d, 0
			ld l, d
			ld h, d

.TileClearSc5Mult:	Add hl, de
			djnz .TileClearSc5Mult

			ld c, l
			ld b, h
			dec bc

			ld hl, EditorBuffer
			ld de, EditorBuffer+1
			push bc
			ld a,(EditorCurrentBackColor)
			and $0F
			ld c,a
			add a,a
			add a,a
			add a,a
			add a,a
			or c
			ld (hl),a
			pop bc
			ldir

			jp .RenderEditorContentSc5

.FillPattern:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc2
			jr z, .FillSc2

			ld a, (EditorCurrentBackColor)
			push af
			ld a, (EditorCurrentForeColor)
			ld (EditorCurrentBackColor), a
			call .TileClear.Int
			pop af
			ld (EditorCurrentBackColor), a
			jp .GoingToMenuAction2

.FillSc2:		ld hl, EditorBuffer
			ld de, EditorBuffer+1
			ld bc,7
			ld (hl),$FF
			ldir

			inc hl
			ld a,(EditorCurrentLastPickedColor)
			and $0F
			add a,a
			add a,a
			add a,a
			add a,a
			ld (hl),a
			ld e,l
			ld d,h
			inc de
			ld bc,7
			ldir		

			call .RenderEditorContentSc2

			call .RenderChromaChSc2

			jp .GoingToMenuAction2

.PatternNot:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .PNotSc8
			cp FormatID.TileSc8_16
			jr z, .PNotSc8
			cp FormatID.TileSc8_32
			jr z, .PNotSc8

			cp FormatID.TileSc5
			jr z, .PNotSc5
			cp FormatID.TileSc5_16
			jr z, .PNotSc5
			cp FormatID.TileSc5_32
			jr z, .PNotSc5
								; Only left .PNotSc2.
			ld hl, EditorBuffer
			ld b,8

.PNotLoop:		ld a,(hl)
			cpl
			ld (hl),a
			inc hl
			djnz .PNotLoop

			call .RenderEditorContentSc2

			jp .GoingToMenuAction2

.PNotSc8:		ld a, (SelectorMetaTileSize)
			ld b, a
			ld e, a
			ld d, 0
			ld l, d
			ld h, d

.PNotSc8Mult:		Add hl, de
			djnz .PNotSc8Mult

			ld c, l
			ld b, h

			ld hl, EditorBuffer

.PNotSc8Loop:		ld a,(hl)
			cpl
			ld (hl),a
			inc hl

			dec bc
			ld a, c
			or b
			jr nz, .PNotSc8Loop

			call .RenderEditorContentSc8

			jp .GoingToMenuAction2

.PNotSc5:		ld a, (SelectorMetaTileSize)
			ld b, a
			rrca
			ld e, a
			ld d, 0
			ld l, d
			ld h, d

.PNotSc5Mult:		Add hl, de
			djnz .PNotSc5Mult

			ld c, l
			ld b, h

			ld hl, EditorBuffer

.PNotSc5Loop:		ld a,(hl)
			cpl
			ld (hl),a
			inc hl

			dec bc
			ld a, c
			or b
			jr nz, .PNotSc5Loop

			call .RenderEditorContentSc5

			jp .GoingToMenuAction2

.ChromaSwSc2:		ld a, (EditorCurrentFormat)
			cp FormatID.TileSc2
			jr z, .ChromaSwSc2J1

			call @BEEP
		
			jp .GoingToMenuAction2

.ChromaSwSc2J1:		ld hl, EditorBuffer+8
			ld b,8

.ChromaSwSc2Loop:	ld a,(hl)
			rrca
			rrca
			rrca
			rrca
			ld (hl),a
			inc hl
			djnz .ChromaSwSc2Loop

			call .RenderEditorContentSc2

			call .RenderChromaChSc2

			jp .GoingToMenuAction2

.RenderChromaChSc2:	ld ix, 73 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 0)

			ld hl, EditorBuffer + 8			; hl = first address of the tile color channel.
			ld b,8					; Initialize channel to explore all the 8bytes chroma data.
			di

.ColorChannelLoop:	push bc

			push hl
			ld a, (hl)
			and $F0
			ld d,a
			rrca
			rrca
			rrca
			rrca
			or d
			ld d,a
			ld a, (hl)
			and $0F
			ld e, a
			rlca
			rlca
			rlca
			rlca
			or e
			ld e,a					; d = color for 1s, e = color for 0s.

			ld b,8					; Initialize bucle for rendering 8 times the same chroma data.

.ColorChannelYLineLoop:	push bc
			push ix
			pop hl
			call @VPOKEPOS

			ld a,d
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a
			ld a,e
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a
			ld bc, $0100
			out ($98),a
			add ix,bc
			out ($98),a
			pop bc
			out ($98),a
			
			djnz .ColorChannelYLineLoop

			pop hl
			inc hl

			pop bc
			djnz .ColorChannelLoop

			ei
			ret

.RenderColorSelected:	ld hl, 71 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2)
			ld bc, $2222
			ld a, (OutlineSecondaryColor)
			call @SQUARE

			ld a,(EditorCurrentForeColor)
			call EditorPickColor

			ld hl, 72 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 1)
			ld bc, $2020
			call @BLOCKFILL

			ld hl, 71 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2 + 34)
			ld bc, $2222				; Render the secondary color selection if the format is not Sc2.
			ld a, (OutlineSecondaryColor)
			call @SQUARE

			ld a,(EditorCurrentBackColor)
			call EditorPickColor

			ld hl, 72 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2 + 35)
			ld bc, $2020
			jp @BLOCKFILL

.RenderColorPicker:	ld l,0					; Render the palette picker at the botton.
			ld h,184
			ld a, (OutlineSecondaryColor)
			ld c, a
			ld b, 0
			call @HLINE

			ld a,(EditorCurrentFormat)
			cp FormatId.TileSc8
			jr z, .Pal256
			cp FormatId.TileSc8_16
			jr z, .Pal256
			cp FormatId.TileSc8_32
			jp nz, .Pal16

.Pal256:		di

			ld l,0
			ld h,185
			call @VPOKEPOS
			
			ld c, 0

.Pal256RedLoop:		ld b, 2

.pal256DoublerLoop:	push bc
			ld d, 0

.Pal256BlueLoop:	ld e, 0

.Pal256GreenLoop:	ld a, c
			or d
			or e

			ld b, 8

.Pal256DotLoop:		out ($98), a
			djnz .Pal256DotLoop

			ld a, e
			add $20
			ld e, a
			jr nc, .Pal256GreenLoop

			inc d
			ld a, d
			cp $04
			jr c, .Pal256BlueLoop

			pop bc
			djnz .pal256DoublerLoop

			ld a, c
			add a, $04
			ld c, a
			cp $20
			jr c, .Pal256RedLoop

			ei
			ret

.Pal16:			di
			ld l,0
			ld h,185
			call @VPOKEPOS
			
			ld b,18

.Pal16YLoop:		push bc

			ld b,16
			xor a

.Pal16ColorLoop:	push af
			and $0F
			ld c, a
			rlca
			rlca
			rlca
			rlca
			or c

			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a
			pop af
			inc a
			djnz .Pal16ColorLoop

			pop bc
			djnz .Pal16YLoop

			ei

			ld a, (MenuForeColor)
			ld (RenderForeColor), a
			ld a, (MenuBackGroundColor)
			ld (RenderBackColor), a

			ld de, 256 * (185+18-8+5) + 5		; Here we renders numbers on the colour picker.
			ld a, '0'
			ld b, 16

.PickerNumbersLoop:	push bc
			push af
			push de
			call @CHRDRAW
			pop de
			ld a, e
			add a, 16
			ld e, a
			pop af
			pop bc
			inc a
			cp '9'+1
			jr nz, .PickerNumbersJump
			ld a, 'A'

.PickerNumbersJump:	djnz .PickerNumbersLoop

			ret

.RenderEditorContentSc2:ld hl, 2 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)
			ld ix, EditorBuffer
			ld b,8

.EdSc2RowLoop:		push bc
			call .RenderEditorSc2Row
			pop bc
			inc ix
			djnz .EdSc2RowLoop
			ret

.RenderEditorSc2Row:	di					; in ix = EditorBuffer current data address. in hl = top/left visual position.

			push hl
			ld a, (ix + 8)
			and $F0
			ld d, a
			rrca
			rrca
			rrca
			rrca
			or d
			ld d,a
			ld a, (ix + 8)
			and $0F
			ld e, a
			rlca
			rlca
			rlca
			rlca
			or e
			ld e,a					; d = color for 1s, e = color for 0s.
			pop hl

			ld b,8

.EdSc2YBucle:		push bc
			push hl
			call @VPOKEPOS
			pop hl

			ld c, (ix + 0)

			ld b,8

.EdSc2BitBucle:		rl c
			push bc
			ld a,d
			jr c, .EdSc2Ones
			ld a,e

.EdSc2Ones:		out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a
			pop bc
			out ($98),a

			djnz .EdSc2BitBucle

			pop bc
			inc h
			djnz .EdSc2YBucle

			ei
			ret

.RenderEditorContentSc5:ld hl, 2 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)
			ld ix, EditorBuffer

			ld a, (SelectorMetaTileSize)
			ld b, a

.EdSc5RowLoop:		push bc
			call .RenderEditorSc5Row

			ld a, (SelectorMetaTileSize)
			rrca
			ld c, a
			ld b, 0
			add ix, bc

			pop bc
			djnz .EdSc5RowLoop
			ret

.RenderEditorSc5Row:	di					; in ix = EditorBuffer current data address. in hl = top/left visual position.

			ld a, (SelectorMetaTileSize)
			ld b, a
			cp 8
			jr z, .EdSc5YBucle
			cp 16
			ld b, 4
			jr z, .EdSc5YBucle
			ld b, 2

.EdSc5YBucle:		push ix
			push bc
			push hl
			call @VPOKEPOS

			ld a, (SelectorMetaTileSize)
			rrca
			ld b, a

.EdSc5XBucle:		ld a, (ix + 0)
			and $0F
			ld e, a
			rlca
			rlca
			rlca
			rlca
			or e
			ld e,a
			ld a, (ix + 0)
			and $F0
			ld d, a
			rrca
			rrca
			rrca
			rrca
			or d					; a = d = left color of the pair, e = right color of the pair.
			ld d, a

			out ($98),a  nop
			out ($98),a

			ld a, (SelectorMetaTileSize)
			cp 32
			jr z, .EdSc5NextPix

			ld a, d
			out ($98),a  nop
			out ($98),a

			ld a, (SelectorMetaTileSize)
			cp 16
			jr z, .EdSc5NextPix

			ld a, d
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a

.EdSc5NextPix:		ld a,e

			out ($98),a  nop
			out ($98),a

			ld a, (SelectorMetaTileSize)
			cp 32
			jr z, .EdSc5NextLoop

			ld a, e
			out ($98),a  nop
			out ($98),a

			ld a, (SelectorMetaTileSize)
			cp 16
			jr z, .EdSc5NextLoop

			ld a, e
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a

.EdSc5NextLoop:		inc ix
			djnz .EdSc5XBucle

			pop hl
			pop bc
			pop ix
			inc h
			djnz .EdSc5YBucle

			ei
			ret

.RenderEditorContentSc8:ld hl, 2 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)
			ld ix, EditorBuffer

			ld a, (SelectorMetaTileSize)
			ld b, a

.EdSc8RowLoop:		push bc
			call .RenderEditorSc8Row

			ld a, (SelectorMetaTileSize)
			ld c, a
			ld b, 0
			add ix, bc

			pop bc
			djnz .EdSc8RowLoop
			ret

.RenderEditorSc8Row:	di					; in ix = EditorBuffer current data address. in hl = top/left visual position.

			ld a, (SelectorMetaTileSize)
			ld b, a
			cp 8
			jr z, .EdSc8YBucle
			cp 16
			ld b, 4
			jr z, .EdSc8YBucle
			ld b, 2

.EdSc8YBucle:		push ix
			push bc
			push hl
			call @VPOKEPOS

			ld a, (SelectorMetaTileSize)
			ld b, a

.EdSc8XLoop:		ld a, (ix + 0)
			ld e, a
			out ($98),a  nop
			out ($98),a

			ld a, (SelectorMetaTileSize)
			cp 32
			jr z, .EdSc8NextPix

			ld a, e
			out ($98),a  nop
			out ($98),a

			ld a, (SelectorMetaTileSize)
			cp 16
			jr z, .EdSc8NextPix

			ld a, e
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a

.EdSc8NextPix:		inc ix
			djnz .EdSc8XLoop

			pop hl
			pop bc
			pop ix
			inc h
			djnz .EdSc8YBucle

			ei
			ret

.RenderWhatIsPointed:	ld a,b						; in b = cursorY, c = cursorX.
			cp $FF
			jp z, .RenderColorPicker

			ld a, (SelectorMetaTileSize)
			dec a
			cp b
			ret c						; CursorY can be 0-(SelectorMetaTileSize-1) and $FF only.

			ld a, (SelectorMetaTileSize)
			dec a
			cp c
			jr nc, .OnTile					; CursorX can be 0-(SelectorMetaTileSize-1) for the tile, (SelectorMetaTileSize) or (SelectorMetaTileSize+1) for the color channel or current color picked.

			ld a, (SelectorMetaTileSize)
			inc a
			cp c
			ret c
									; Is in the chroma channel.
			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc2
			jp z, .RenderChromaChSc2
			jp .RenderColorSelected

.OnTile:		ld a,(EditorCurrentFormat)
			cp FormatID.TileSc2
			jp z, .RenderPartContentSc2
			cp FormatID.TileSc5
			jp z, .RenderPartContentSc5
			cp FormatID.TileSc5_16
			jp z, .RenderPartContentSc5
			cp FormatID.TileSc5_32
			jp z, .RenderPartContentSc5

.RenderPartContentSc8:	ld hl, 2 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)
			ld ix, EditorBuffer
			ld c, b

			ld a, (SelectorMetaTileSize)
			ld b, a

			xor a

.EdSc8RowPartLoop:	push af
			push bc
			cp c
			call z, .RenderEditorSc8Row
			ld a, (SelectorMetaTileSize)
			ld c, a
			ld b, 0
			add ix, bc

			cp 8
			ld b, 8
			jr z, .EdSc8RowPartJ1
			cp 16
			ld b, 4
			jr z, .EdSc8RowPartJ1
			ld b, 2
			
.EdSc8RowPartJ1:	ld a, h
			add a, b
			ld h, a
			pop bc
			pop af
			inc a
			djnz .EdSc8RowPartLoop
			ret

.RenderPartContentSc5:	ld hl, 2 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)
			ld ix, EditorBuffer
			ld c,b

			ld a, (SelectorMetaTileSize)
			ld b, a

			xor a

.EdSc5RowPartLoop:	push af
			push bc
			cp c
			call z, .RenderEditorSc5Row
			ld a, (SelectorMetaTileSize)
			rrca
			ld c, a
			ld b, 0
			add ix, bc

			ld a, (SelectorMetaTileSize)
			cp 8
			ld b, 8
			jr z, .EdSc5RowPartJ1
			cp 16
			ld b, 4
			jr z, .EdSc5RowPartJ1
			ld b, 2

.EdSc5RowPartJ1:	ld a, h
			add a, b
			ld h, a
			pop bc
			pop af
			inc a
			djnz .EdSc5RowPartLoop
			ret

.RenderPartContentSc2:	ld hl, 2 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)
			ld ix, EditorBuffer
			ld c,b
			xor a
			ld b,8

.EdSc2RowPartLoop:	push af
			push bc
			cp c
			call z, .RenderEditorSc2Row
			pop bc
			inc ix
			ld a,8
			add a,h
			ld h,a
			pop af
			inc a
			djnz .EdSc2RowPartLoop
			ret

.PrintCursorTileEd:	ld a,(EditorCursorY)
			cp $FF						; It Prints the cursor.
			ld b, a
			jp z, .CsOnPicker

			ld a, (SelectorMetaTileSize)
			dec a
			cp b
			ret c						; CursorY can be 0-(SelectorMetaTileSize-1) and $FF only.

			ld a,(EditorCursorX)
			ld c, a
			ld a, (SelectorMetaTileSize)
			dec a
			cp c
			jr nc, .CsOnTile				; CursorX can be 0-(SelectorMetaTileSize-1) for the tile, (SelectorMetaTileSize) or (SelectorMetaTileSize+1) for the color channel or current color picked.
									; Insert code here if want to redraw new positions where the cursor can be stay.
			ld a, (SelectorMetaTileSize)
			inc a
			cp c
			ret c

			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc2
			jr z, .CsOnChromaChannel
									; Only left cursor on color selected.
			ld a, (SelectorMetaTileSize)
			cp c			
			jr nz, .CsOnSelectedSecondary
									; Cursor on primary color selected.
			ld hl, 73 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 0)
			ld bc, $1E1E
			ld a, (OutlineCursorColor)
			jp @SQUARE

.CsOnSelectedSecondary:	ld hl, 73 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2 + 36)
			ld bc, $1E1E
			ld a, (OutlineCursorColor)
			jp @SQUARE

.CsOnChromaChannel:	ld hl, 74 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 + 1)

			ld a,(EditorCursorX)
			cp 8
			jr z, .Prm

			ld a,5
			add a,l
			ld l,a

.Prm:			ld a,(EditorCursorY)
			and $07
			add a,a
			add a,a
			add a,a
			add a,h
			ld h,a

			ld bc, $0606
			ld a, (OutlineCursorColor)
			jp @SQUARE

.CsOnTile:		ld a, (SelectorMetaTileSize)
			cp 16
			jr z, .CsOnTile16
			cp 32
			jr z, .CsOnTile32
									; Only when 8x8.
			ld hl, 3 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 + 1)
			ld a,(EditorCursorX)
			add a,a
			add a,a
			add a,a
			add a,l
			ld l,a
			ld a,(EditorCursorY)
			add a,a
			add a,a
			add a,a
			add a,h
			ld h,a
			ld bc, $0606
			ld a, (OutlineCursorColor)
			push hl
			call @SQUARE
			pop hl
			dec h
			dec l
			ld bc, $0808
			ld a, (ScreenBackgroundColor)
			jp @SQUARE

.CsOnTile16:		ld hl, 3 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 + 1)
			ld a,(EditorCursorX)
			add a,a
			add a,a
			add a,l
			ld l,a
			ld a,(EditorCursorY)
			add a,a
			add a,a
			add a,h
			ld h,a
			push hl
			call @VPOKEPOS
			ld a, (ScreenBackgroundColor)
			out ($98), a
			pop hl
			dec h
			dec l
			ld bc, $0404
			ld a, (OutlineCursorColor)
			jp @SQUARE

.CsOnTile32:		ld hl, 3 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 + 1)
			ld a,(EditorCursorX)
			add a,a
			add a,l
			ld l,a
			ld a,(EditorCursorY)
			add a,a
			add a,h
			ld h,a
			push hl
			call @VPOKEPOS
			ld a, (ScreenBackgroundColor)
			out ($98), a
			pop hl
			dec l
			dec h
			call @VPOKEPOS
			ld a, (OutlineCursorColor)
			out ($98), a
			ei
			ret

.CsOnPicker:		ld a,(EditorCurrentFormat)
			cp FormatID.TileSc8
			jr z, .CsOnPal256
			cp FormatID.TileSc8_16
			jr z, .CsOnPal256
			cp FormatID.TileSc8_32
			jr z, .CsOnPal256
								; Picker is Pal16.
			ld a,(EditorCursorX)
			and $0F
			add a,a
			add a,a
			add a,a
			add a,a
			add a,1
			ld l,a
			ld h,185 + 1
			ld bc,$100E
			ld a, (OutlineCursorColor)
			push hl
			call @SQUARE
			pop hl
			inc h
			inc l
			ld bc,$0E0C
			ld a, (ScreenBackgroundColor)
			jp @SQUARE

.CsOnPal256:		ld a,(EditorCursorX)
			rrca
			and $0E
			add a, 186
			ld h, a

			ld a,(EditorCursorX)
			rrca
			rrca
			and $C0
			ld l, a
			ld a,(EditorCursorX)
			rrca
			rrca
			and $38
			or l
			add a, 2
			ld l, a

			di
			call @VPOKEPOS

			xor a
			out ($98), a
			dec a
			out ($98), a
			nop
			out ($98), a
			inc a
			out ($98), a

			ei
			ret

.Esc:			ld hl, MsgBoxCheckValues
			ld (hl), $FF
			inc hl
			ld (hl), 0
			ld ix, BoxSureCancelEdit
			call MSGBOX

			call .EditorDissapear

			ld a, $FF
			ld (PuzzlerForceRenderAll), a
			call RenderPuzzler			; It redraws the puzzler because with some formats it moves to another place when editing.
			xor a
			ld (PuzzlerForceRenderAll), a

			ld a, (MsgBoxCheckValues)
			and a
			ret z
			jp RunTileEditor

.EditorDissapear:	ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2
			jp @CLSLP

.UpgradePuzzler:	ld hl, PuzzlerIndexationBuffer		; The puzzler is in use, must redraw the tiles.
			xor a
			ld b,16

.PuzRenderLoop:		push af
			push bc
			push hl

			call RenderPuzTile

			pop hl
			pop bc
			pop af

			inc a
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			djnz .PuzRenderLoop
			ret

.GetPixelColour:	ld bc, (EditorCursorX)

			ld a, (SelectorMetaTileSize)
			dec a
			cp b
			jp c, .TileEditorControl
			cp c
			jp c, .TileEditorControl

			ld a,(EditorCurrentFormat)
			cp FormatID.TileSc2
			jp z, .TileEditorControl

			cp FormatID.TileSc5
			jp z, .GetPixelColourSc5
			cp FormatID.TileSc5_16
			jp z, .GetPixelColourSc5
			cp FormatID.TileSc5_32
			jp z, .GetPixelColourSc5
								; Screen8 tile format.
			ld hl, EditorBuffer
			ld a, (SelectorMetaTileSize)
			ld e, a
			ld d, 0

			ld a, b
			and a
			jr z, .GPCSc8NoAddY

.GPCSc8LoopAddY:	add hl, de
			djnz .GPCSc8LoopAddY

.GPCSc8NoAddY:		ld e, c
			add hl, de

			ld a, (hl)
			ld (EditorCurrentForeColor), a
			call .RenderColorSelected
			jp .TileEditorControl

.GetPixelColourSc5:	ld hl, EditorBuffer

			ld a, (SelectorMetaTileSize)
			rrca
			ld e, a
			ld d, 0

			ld a, b
			and a
			jr z, .GPCSc5NoAddY

.GPCSc5LoopAddY:	add hl, de
			djnz .GPCSc5LoopAddY

.GPCSc5NoAddY:		ld a, c
			and $FE
			rrca
			ld e, a
			add hl, de

			ld a,c
			and 1
			jr nz, .GPCSc5RightPix

			ld a,(hl)
			and $F0
			rrca
			rrca
			rrca
			rrca
			ld (EditorCurrentForeColor), a
			call .RenderColorSelected
			jp .TileEditorControl

.GPCSc5RightPix:	ld a,(hl)
			and $0F
			ld (EditorCurrentForeColor), a
			call .RenderColorSelected
			jp .TileEditorControl






GetsBunchObjectCount:	call @GETBUNCH_LINKADDR			; In BC = Bunch index, out DE = ObjectCount.
			ret c					; out CF = 1 Error.

			push hl
			push de
			call @USERAREA_RDW
			exx
			pop de
			pop hl
			exx
			ret c

			ld e,c					; in hlbc = bunch size (as readed from its linker).
			ld d,b

			push de
			push hl

			exx
			ld bc, BunchHeader.FormatID + 4		; + 4 because has the Link address, not the bunch base address.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc
			call @USERAREA_RB			; It outputs in A the FormatID used later.
			pop hl
			pop de
			ret c

			ld bc, BunchHeader.Size
			ex de,hl
			sbc hl,bc
			ex de,hl
			ld bc,0
			sbc hl,bc				; hlde = raw size = bunch size - BunchHeader.Size.
								; In A = bunch format.
			ld iy, _GETOBJECTSIZE			; It outs in BC the object size.
			call @FarCallToPage2

			call @DIV32_16
			and a
			ret






GetsBunchNameRecord:	push hl					; in BC = Bunch index. In HL = start buffer address.
			call @GETBUNCH_BASEADDR
			pop bc
			ret c					; out CF = 1 Error.

			push bc
			exx
			ld bc, 16
			pop hl
			push hl
			call @READ_USERAREA
			pop hl
			ret c

			ld bc, 16
			add hl, bc
			ld (hl), 0				; Adds nullchar in the 17th position.
			ret






SelectsThisBunch:	push bc					; It Mounts a bunch in the console. Setting up all related console variables.
			call @GETBUNCH_BASEADDR			; in BC = Bunch to select.
			pop bc					; CF = 1 Error.
			ret c					; MOD (abcix).

			push bc
			call .Sub
			pop bc
			ret c

			ld (SelectorBunchIndex), bc
			call @GETBUNCH_LINKADDR
			ret c

			push hl
			push de
			call @USERAREA_RDW
			pop de
			jr nc, .Ok

			pop hl
			ret

.Ok:			push hl					; Here (hlbc) has the bunch length including its header.
			push de
			push bc
			call .CalcObjectsCount
			pop bc
			pop de
			pop hl

			ex de,hl
			add hl,bc
			ex de,hl
			pop bc
			adc hl,bc
			ret c

			ld bc,4
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc
			ret c

			ld (SelectorStopRawAddrLow),de		; Saves the address, next from the bunch end.
			ld (SelectorStopRawAddrHigh),hl
			ret

.Sub:			push hl
			push de

			ld b,16
			ld ix, SelectorBunchName

.Loop:			push de
			push hl
			call @USERAREA_RB
			pop hl
			pop de
			jr nc, .Ok2

.Err:			pop bc
			pop bc
			ret

.Ok2:			ld (ix+0),a
			inc ix

			inc de
			ld a,e
			or d
			jr nz, .J1
			inc hl

.J1:			djnz .Loop

			pop de
			pop hl
			push hl
			push de

			ld bc, BunchHeader.FormatID
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, 0
			adc hl, bc

			call @USERAREA_RB
			jr c, .Err

			ld (SelectorCurrentFormat),a

			ld c,8
			cp FormatID.TileSc2
			jr z, .MTS
			cp FormatID.TileSc5
			jr z, .MTS
			cp FormatID.TileSc8
			jr z, .MTS
			ld c,16
			cp FormatID.TileSc5_16
			jr z, .MTS
			cp FormatID.TileSc8_16
			jr z, .MTS
			ld c,32
			cp FormatID.TileSc5_32
			jr z, .MTS
			cp FormatID.TileSc8_32
			jr z, .MTS
			ld c, 1

.MTS:			ld a, c
			ld (SelectorMetaTileSize), a
			
			pop de
			pop hl

			ld bc, BunchHeader.Size
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc

			ld (SelectorBunchStartRawAddrLow),de
			ld (SelectorBunchStartRawAddrHigh),hl
			ret

.CalcObjectsCount:	ld e,c					; in hlbc = bunch size (as readed from its linker).
			ld d,b
			ld bc, BunchHeader.Size
			ex de,hl
			sbc hl,bc
			ex de,hl
			ld bc,0
			sbc hl,bc				; hlde = raw size = bunch size - BunchHeader.Size.

			ld a,(SelectorCurrentFormat)
			ld iy, _GETOBJECTSIZE			; It outs in BC the object size.
			call @FarCallToPage2

			call @DIV32_16

			ld (SelectorObjectsCount),de		; In this program, bunch size is only from 1 up to 65535 objects. so, hl can be ignored.
			ret






GetObjectRawAddress:	ld a,(SelectorCurrentFormat)		; out hlde = Object address.
			ld de,(SelectorCurrentObjectNumber)	; MOD (bc).
			ld hl,0
			ld iy, _CalculateRawSize		; Is the same as for base address of a given object by its ordinal number.
			call @FarCallToPage2
			ret c

			ld bc,(SelectorBunchStartRawAddrLow)
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,(SelectorBunchStartRawAddrHigh)
			adc hl,bc				; Plus the raw base address of the selected bunch.
			ret






NormalizeFileName:	ld b,0					; in HL = String NULL TERMINATED address.
								; out CF = 1 bad filename.
.Loop:			ld a,(hl)
			and a
			jr z, .FNNullChar
			cp '0'
			jr c, .EvaluateMore
			cp '9'+1
			jr c, .Good
			cp 'A'
			jr c, .EvaluateMore
			cp 'Z'+1
			jr c, .Good
			cp 'a'
			jr c, .EvaluateMore
			cp 'z'+1
			jr c, .minus
			cp 128
			jr nc, .Good

.EvaluateMore:		ld c,a
			ld de, .ValidChars

.ValidLoop:		ld a,(de)
			inc de
			and a
			jr z, .Bad
			cp c
			jr nz, .ValidLoop
								; Found the character in the valid string.
.Good:			cp '.'
			jr z, .Dot
								; NoDot.
			set 0,b					; It Indicates that there was atleast one non dot character before the dot.
			jr .Next

.Dot:			bit 1,b
			jr nz, .Bad				; If there was one dot before, and it has another dot, it is invalid!.

			bit 0,b
			jr z, .Bad				; If dot is the first char, there is no filename, invalid!.

			set 1,b					; Indicates that in the string is already one dot.

.Next:			inc hl
			jr .Loop

.minus:			sub $20					; UPCASE$().
			ld (hl),a
			jr .Good

.Bad:			scf
			ret

.FNNullChar:		ld a,b
			cp 3
			jr nz, .Bad				; We don't accepts filenames without extensions in this IDE.

			and a
			ret

.ValidChars:		DB ".!#$%&'()-@^_`^{}~" ,0



; **************************************************
; * GENERAL PURPOSE INTERACTIVE IDE OBJECTS        *
; **************************************************






MENUPOPUP:		call @KBCLEAR				; IN IX = MenuDATA. Out A = itemIndex, CF = 1 Escaped.
								; Empty KEYBUF.
			push ix					; It calculates the Width, height and ItemCount.
			pop hl
			inc hl
			inc hl					; IX + 2 = StrItems.

			ld de, 0
	
.Lp:			call @STRLEN				; in hl = string addr, out hl = next from NULL CHAR, out c = length.
			inc d

			ld a,c
			cp e
	
			jr c, .Shorter
			ld e, a

.Shorter:		ld a,(hl)
			and a
			jr nz, .Lp
								; d = ItemCount, e = Maximun Str Lenght.
			ld a,d
			ld (MPItemsCount),a
			push af
			ld b,a
			ld a,(MPItemIndex)
			cp b
			jr c, .IndexInRange

			xor a					; Initializing cursor position only on overflow cases allows IDE to remember where was if the program re-entry the popup menu.
			ld (MPItemIndex),a			; Resets cursor position because it is out of range.

.IndexInRange:		pop af
			add a,a
			ld b,a
			add a,a
			add a,b
			add a,d					; a = d * 7.
			ld (MPContentHeight),a
			ld a,e
			add a,a
			add a,a
			add a,e
			add a,e					; a = e * 6.
			ld (MPContentWidth),a
	
			ld a, (ix+0)
			sub 2
			ld l,a
			ld a, (ix+1)
			sub 2
			ld h,a
			ld bc,(MPContentWidth)
			inc c
			inc c
			inc c
			inc b
			inc b
			inc b
			inc b
			ld a, (MenuBorderColor)
			push hl
			push bc
			call @SQUARE
			pop bc
			pop hl
			inc l
			inc h
			dec c
			dec c
			dec b
			dec b
			ld a, (MenuBackGroundColor)
			call @BLOCKFILL

.Refresh:		ld d,(ix+1)
			push ix
			pop hl	
			inc hl
			inc hl
			ld c,0

.Loop:			ld e,(ix+0)
			ld a,(MPItemIndex)
			cp c
			jr nz, .Normal

.Cursor:		ld a, (MenuCursorForeColor)
			ld (RenderForeColor),a
			ld a, (MenuCursorBackColor)
			ld (RenderBackColor),a
			jr .Cnt

.Normal:		ld a,(MenuForeColor)
			ld (RenderForeColor),a
			ld a,(MenuBackGroundColor)
			ld (RenderBackColor),a

.Cnt:			push bc
			call @STRDRAWZ
			pop bc
			inc hl					; It sets HL on the next string.

			ld a,7
			add a,d
			ld d,a					; d = d + 7.

			ld a,(hl)				; Checks if the next string is the <EOD>.
			and a
			jr z, .CtrlLoop

			inc c					; Increase current item render.	
			jr .Loop

.CtrlLoop:		CALL @INKEY
			jr c, .CtrlLoop

			cp 27
			jr z, .Esc

			cp 13
			jr z, .Hit

			cp 30
			jr z, .Up

			cp 28
			jr z, .Right

			cp 31
			jr z, .Down

			cp 29
			jr z, .Left

			cp 32
			jr z, .Hit

			jr .CtrlLoop

.Up:			ld a,(MPItemIndex)
			and a
			jr z, .CtrlLoop
			dec a
			ld (MPItemIndex),a
			inc a
			push af
			call .PrintItem
			pop af
			dec a
			call .PrintItem
			jr .CtrlLoop

.Down:			ld a,(MPItemsCount)
			dec a
			ld c,a
			ld a,(MPItemIndex)
			cp c
			jr z, .CtrlLoop
			inc a
			ld (MPItemIndex),a
			dec a
			push af
			call .PrintItem
			pop af
			inc a
			call .PrintItem
			jr .CtrlLoop

.Hit:			ld a,(MPItemIndex)
			ld b,a
			ld a,$ff
			ld (MPItemIndex),a
			ld a,b
			push af
			call .PrintItem
			pop af
			ld (MPItemIndex),a

			and a
			ret

.Esc:			ld a,(MPItemIndex)
			ld b,a
			ld a,$ff
			ld (MPItemIndex),a
			ld a,b
			push af
			call .PrintItem
			pop af
			ld (MPItemIndex),a

			xor a
			scf
			ret

.Left:			ld a,(MPItemIndex)
			ld b,a
			ld a,$ff
			ld (MPItemIndex),a
			ld a,b
			push af
			call .PrintItem
			pop af
			ld (MPItemIndex),a

			ld a,$FF
			scf
			ret

.Right: 		ld a,(MPItemIndex)
			ld b,a
			ld a,$ff
			ld (MPItemIndex),a
			ld a,b
			push af
			call .PrintItem
			pop af
			ld (MPItemIndex),a

			ld a,1
			scf
			ret

.PrintItem:		ld c,a
			push bc
			push ix
			pop hl	
			inc hl
			inc hl

			and a
			jr z, .IsThisStr
	
.IL:			ld a,(hl)
			inc hl
			and a
			jr nz, .IL

			dec c
			jr z, .IsThisStr

			jr .IL

.IsThisStr:		pop bc					; C = ItemIndex to print.

			ld a,c
			add a,a
			add a,a
			add a,c
			add a,c
			add a,c
			ld d,(ix+1)
			add a,d
			ld d,a					; d = itemIndex * 7 + MenuPopTop

			ld e,(ix+0)
			ld a,(MPItemIndex)
			cp c
			jr nz, .Normal2

			ld a, (MenuCursorForeColor)
			ld (RenderForeColor),a
			ld a, (MenuCursorBackColor)
			ld (RenderBackColor),a
			jr .Cnt2

.Normal2:		ld a,(MenuForeColor)
			ld (RenderForeColor),a
			ld a,(MenuBackGroundColor)
			ld (RenderBackColor),a

.Cnt2:			jp @STRDRAWZ






MSGBOX:			call @KBCLEAR				; in IX = msgbox data address. Out CF = 1 escaped.
			xor a
			ld (MsgBoxAreOptions),a

			push ix
			pop hl
			inc hl
			inc hl					; HL = Label addr.
								; Calculates the label width plus some space.
			call @STRLEN				; in hl = string NULL TERMINATED address.
								; out c = LEN().
								; out hl = next addr from the NULL char.
			ld a,(hl)
			inc hl
			ld (MsgBoxTL),a				; Lee la longitud de caracteres máxima para el cuadro de texto.
			ld a,$ff
			ld (MsgBoxInsert),a
			xor a
			ld (MsgBoxCurPos),a	

			ld b,0					; b = Initializes Height neded.
								; c = Width neded.
			ld a,c
			and a
			jr z, .ZipLabel

			add a,a
			add a,a
			add a,c
			add a,c
			add a, 12				; a=a*6+12.
			ld c,a

			ld b,16					; Vertical space for the label.

.ZipLabel:		ld a,b
			ld (MsgBoxTY),a				; Start offset Ypos for the textbox.

			ld a, (MsgBoxTL)
			and a
			jr z, .NoTextBox 

			ld e,a
			add a,a
			add a,a
			add a,e
			add a,e
			add a,12				; a=TL*6+12

			cp c
			jr c, .NoWider
			ld c, a
.NoWider:
			ld a,b
			add a,16
			ld b,a					; Vertical space for the textbox.

			ld a, $ff
			ld (MsgBoxObCur),a			; Indica que el cuadro de texto tendrá el foco.	

			ld a, (MsgBoxDontStartBuffer)
			and a
			jr z, .InitTextBox

.NoInitLoop:		ld a, (hl)				; Ok, the textbox will not be initialize, but it anyway needs to skip the default value string in the inputted DATA, and the textbox content needs to be padded with spaces at its right.
			inc hl
			and a
			jr nz, .NoInitLoop			; It skips the default value for the textbox.

			ld de, MsgBoxBuffer
			push bc
			ld a, (MsgBoxTL)
			ld b, a

.TextBoxSpacingLoop:	ld a, (de)
			inc de
			and a
			jr z, .TBNF
			djnz .TextBoxSpacingLoop
								; the buffer is full.
			pop bc
			xor a
			ld (de),a				; It writes a null char past the textbox field.

			jr .J3

.TBNF:			dec de

.TBNFLoop:		ld a, ' '
			ld (de),a
			inc de
			djnz .TBNFLoop

			pop bc
			xor a
			ld (de),a				; It writes a null char past the textbox field.

			jr .J3

.InitTextBox:		ld de, MsgBoxBuffer
			xor a

.L1:			ex af,af'
			ld a,(hl)				; Carga el contenido inicial del cuadro de texto.
			inc hl
			ld (de),a
			inc de
			and a
			jr z, .J1
	
			ex af,af'
			inc a
			jr .L1
								; HL = next data address.
.J1:			dec de

.L2:			ex af,af'
			exx	
			ld hl, (MsgBoxTL)
			cp l
			exx
			jr nc, .J2

			inc a
			ex af,af'
			ld a,32
			ld (de),a
			inc de
			jr .L2

.J2:			xor a
			ld (de),a				; It writes a null char past the textbox field.
			jr .J3

.NoTextBox:		xor a
			ld (MsgBoxObCur),a			; Indica que el foco estará en el primer checkbox.

			ld de, MsgBoxBuffer
			xor a
			ld (de),a				; Clears the textbox.

.J3:			ld a,c
			ld (MsgBoxWidth),a
			ld a,b
			ld (MsgBoxHeight),a
			ld (MsgBoxTQ),a

			xor a
			ld (MsgBoxAreOptions),a
								; HL = possible CheckBox Caption list, or <EOD>.
			ld a,(hl)
			cp 1
			jr nz, .NoOpt

			inc hl
			ld a,$FF
			ld (MsgBoxAreOptions),a

.NoOpt:			xor a
			ld (MsgBoxObCount),a
			ld (MsgBoxQAddr),hl

.L3:			ld a,(hl)
			inc hl
			and a
			jr z, .EOD

.L4:			ld a,(hl)
			inc hl
			and a
			jr nz, .L4
	
			ld a,(MsgBoxObCount)
			inc a
			ld (MsgBoxObCount),a
			ld a,(MsgBoxHeight)
			add a,9
			ld (MsgBoxHeight),a
			jr .L3

.EOD:			ld l,(ix+0)
			ld h,(ix+1)
			ld bc,(MsgBoxWidth)			; width plus height read.
			dec l
			dec l
			dec h
			dec h
			inc c
			inc c
			inc c
			inc c
			inc b
			inc b
			inc b
			inc b
			push hl
			push bc
			ld a, (MenuBorderColor)
			call @SQUARE
			pop bc
			pop hl
			inc l
			inc h
			dec c
			dec c
			dec b
			dec b
			ld a, (MenuBackGroundColor)
			call @BLOCKFILL

			push ix
			pop hl
			inc hl
			inc hl

			ld a,(hl)
			and a
			jr z, .NoLabel

			push hl
			call @STRLEN				; in hl = string NULL TERMINATED address.
			pop hl					; out c = LEN().

			ld a,c
			add a,a
			add a,a
			add a,c
			add a,c
			ld c,a
			ld a,(MsgBoxWidth)
			sub c
			and a
			rra
			ld e,(ix+0)
			add a,e
			ld e,a					; LabelLeft = MsgBox.Left + (BoxWidth - LabelWidth) / 2
			ld d,(ix+1)
			ld a,4
			add a,d
			ld d,a
			ld a,(MenuForeColor)
			ld (RenderForeColor),a
			ld a,(MenuBackGroundColor)
			ld (RenderBackColor),a
			call @STRDRAWZ

.NoLabel:		ld a,(MsgBoxTL)
			and a
			jr z, .NoTextBox2

			ld c,a
			add a,a
			add a,a
			add a,c
			add a,c
			ld c,a
			ld a,(MsgBoxWidth)
			sub c
			and a
			rra
			ld e,(ix+0)
			add a,e
			ld (MsgBoxTBLeft),a			; TextBoxLeft = MsgBox.Left + ( MsgBox.Width - TextBoxWidth) / 2
			ld l,a
			dec l					; TB Background = TextBoxLeft-1 for the border.
			ld h,(ix+1)
			ld a,(MsgBoxTY)
			add a,h
			add a,3
			ld h,a

			ld a,(MsgBoxTL)
			ld c,a
			add a,a
			add a,a
			add a,c
			add a,c
			ld c,a
			inc c
			inc c					; TB Width = TL * 6 + 2.

			ld b, 10
			ld a, (TextBoxBackColor)		; TextBox BackColor.
			call @BLOCKFILL
.RedrawAll:
.NoTextBox2:		ld a,(MsgBoxObCount)
			and a
			jr z, .NoCheckBoxes

			ld b,a
			xor a

.QLoop:			push af
			push bc
			call .PrintQ				; in A = CheckBox index Number.
			pop bc	
			pop af
			inc a
			djnz .QLoop

.NoCheckBoxes:		ld a,(MsgBoxTL)
			and a 
			jr z, .Control

.RDTB:			ld a,(MsgBoxTBLeft)
			ld e,a

			ld a,(ix+1)
			ld d,a
			ld a,(MsgBoxTY)
			add a,d
			add a,4
			ld d,a

			ld hl, MsgBoxBuffer
			ld a,(MsgBoxTL)
			ld b,a
			ld c,0	

.L5:			ld a, (TextBoxForeColor)
			ld (RenderForeColor),a  
			ld a, (TextBoxBackColor)
			ld (RenderBackColor),a

			ld a,(MsgBoxObCur)
			cp $ff
			jr nz, .NoCur

			ld a,(MsgBoxCurPos)
			cp c
			jr nz, .NoCur

			ld a, (TextBoxForeColor)
			ld (RenderForeColor),a
			ld a, (MsgBoxCursorColor)
			ld (RenderBackColor),a

.NoCur:			ld a,(hl)
			inc hl
			push hl
			push de
			push bc	
			call @CHRDRAW	
			pop bc
			pop de
			pop hl
			ld a,6
			add a,e
			ld e,a
			inc c
			djnz .L5	

.Control:		CALL @INKEY
			jr c, .Control

			ex af,af'
			ld a,(MsgBoxTL)
			ld b,a
			ld a,(MsgBoxObCount)
			or b
			scf
			ret z					; If there is no textbox and checkboxes, on any key press, it must escape.
			ex af,af'

			cp 28
			jp z, .Right

			cp 29
			jp z, .Left

			cp 30
			jp z, .Up

			cp 31
			jp z, .Down

			cp 27
			jp z, .Esc

			cp 13
			jp z, .Return

			cp 127
			jp z, .Del

			cp 9
			jp z, .Tab

			cp 8
			jp z, .Bs

			cp 18
			jp z, .Ins

			cp 32
			jr z, .Space

			cp 32
			jr c, .Control

.ChrTyped:		ex af,af'
			ld a,(MsgBoxObCur)
			cp $ff
			jr nz, .Control

			ld a,(MsgBoxTL)
			and a
			jr z, .Control

			ld a,(MsgBoxInsert)
			and a
			jr nz, .Inserting

.ChPut:			ld hl, MsgBoxBuffer			; in af' = CHR().
			ld a,(MsgBoxCurPos)
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a
			ex af,af'
			ld (hl),a

			ld a,(MsgBoxTL)
			ld b,a
			ld a,(MsgBoxCurPos)
			dec b
			cp b
			jp nc, .RedrawAll
			inc a
			ld (MsgBoxCurPos),a
			jp .RedrawAll

.Inserting:		ld hl, MsgBoxBuffer
			ld a,(MsgBoxTL)
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a
			push hl
			push hl
			ld hl, MsgBoxBuffer
			ld a,(MsgBoxCurPos)
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a
			ld c,l
			ld b,h
			pop de
			ld l,e
			ld h,d

.L8:			dec hl
			ld a,(hl)
			ld (de),a
			dec de

			push hl
			and a
			sbc hl,bc
			pop hl

			jr nz, .L8

			pop hl
			ld (hl),0
			jr .ChPut

.Space:			ld b,a
			ld a,(MsgBoxObCur)
			cp $ff
			ld a,b
			jr z, .ChrTyped
								; Es un checkbox HIT!.
			ld a,(MsgBoxAreOptions)
			and a
			jr z, .Hit
								; As are options all others checkboxes must be VALUE = 0.
			ld a,(MsgBoxObCount)
			ld b,a
			and a
			jr z, .Hit

			ld hl, MsgBoxCheckValues
	
.L9:			ld (hl),0
			inc hl
			djnz .L9

.Hit:			ld hl, MsgBoxCheckValues
			ld a,(MsgBoxObCur)
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a,(hl)
			and a
			ld a, $ff
			jr z, .HitJ1
			xor a

.HitJ1:			ld (hl),a
			jp .RedrawAll

.Right:			ld a,(MsgBoxObCur)
			cp $ff
			jp nz, .Control

			ld a,(MsgBoxTL)
			and a
			jp z, .Control

			ld b,a
			ld a,(MsgBoxCurPos)
			dec b
			cp b
			jp nc, .Control

			inc a
			ld (MsgBoxCurPos),a
			xor a
			ld (MsgBoxInsert),a
			jp .RDTB

.Left:			ld a,(MsgBoxObCur)
			cp $ff
			jp nz, .Control

			ld a,(MsgBoxTL)
			and a
			jp z, .Control

			ld a,(MsgBoxCurPos)
			and a
			jp z, .Control

			dec a
			ld (MsgBoxCurPos),a
			xor a
			ld (MsgBoxInsert),a
			jp .RDTB	

.Up:			ld a,(MsgBoxObCur)
			cp $ff
			jp nz, .Control

			ld a,(MsgBoxTL)
			and a
			jp z, .Control

			ld a,(MsgBoxCurPos)
			and a
			jp z, .Control

			xor a
			ld (MsgBoxCurPos),a
			ld (MsgBoxInsert),a
			jp .RDTB	
	
.Down:			ld a,(MsgBoxObCur)
			cp $ff
			jp nz, .Control

			ld a,(MsgBoxTL)
			and a
			jp z, .Control

			ld b,a
			ld a,(MsgBoxCurPos)
			dec b
			cp b
			jp z, .Control

			ld a,b
			ld (MsgBoxCurPos),a
			xor a
			ld (MsgBoxInsert),a
			jp .RDTB

.Esc:			ld hl, MsgBoxBuffer
			xor a
			ld (hl),a
			ld (MsgBoxDontStartBuffer), a		; Resets this configured option.
			scf
			ret

.Return:		xor a
			ld (MsgBoxDontStartBuffer), a		; Resets this configured option.

			ld hl, MsgBoxBuffer
			ld a,(MsgBoxTL)
			and a
			ret z

			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a,(MsgBoxTL)
			ld b,a

.L6:			dec hl
			ld a,(hl)
			cp 32
			jr nz, .E1

			ld (hl),0
			djnz .L6	

.E1:			and a
			ret

.Ins:			ld a,(MsgBoxObCur)
			cp $ff
			jp nz, .Control

			ld a,(MsgBoxInsert)
			cpl
			ld (MsgBoxInsert),a
			jp .Control

.Tab:			ld a,(MsgBoxObCount)
			and a
			jp z, .Control

			ld b,a
			ld a,(MsgBoxObCur)
			inc a
			cp b
			jr nz, .NoRoll
			ld a,$ff

.NoRoll:		ld (MsgBoxObCur),a
			jp .RedrawAll

.Del:			ld a,(MsgBoxObCur)
			cp $ff
			jp nz, .Control

			ld a,(MsgBoxTL)
			and a
			jp z, .Control

			ld hl, MsgBoxBuffer
			ld a,(MsgBoxCurPos)
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a
								; Chr address to delete.
			push hl
			ld hl, MsgBoxBuffer
			ld a,(MsgBoxTL)
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a
			push hl
			pop bc
			pop hl
			ld e,l
			ld d,h
			inc hl

.L7:			ld a,(hl)
			ld (de),a
			inc hl
			inc de
								; Test if DE is overflow.
			ex de,hl
			push hl
			and a
			sbc hl,bc
			pop hl
			ex de,hl
			jr nz, .L7

			dec de
			ld a,32
			ld (de),a
			jp .RedrawAll

.Bs:			ld a,(MsgBoxObCur)
			cp $ff
			jp nz, .Control

			ld a,(MsgBoxTL)
			and a
			jp z, .Control

			ld a,(MsgBoxCurPos)
			and a
			jr z, .Del

			dec a
			ld (MsgBoxCurPos),a
			jp .Del

.PrintQ:		push af
			ld h,a
			add a,a
			add a,a
			add a,a
			add a,h
			inc a
			ld h,a
			ld a,(MsgBoxTQ)
			add a,h
			ld h,(ix+1)
			add a,h
			ld h,a					; Top = MsgBox.Top + MsgBox.CheckTQ + CheckBoxIndex * 9 + 1

			ld a,(ix+0)
			add a,8
			ld l,a					; Left = MsgBox.Left + 8

			ld bc,$0606
			pop af
			push af
			ld de, (MsgBoxObCur)
			cp e
			ld a, (MsgBoxCursorColor)
			jr z, .C1
			ld a, (CheckBoxBackColor)

.C1:			push hl
			push bc
			call @SQUARE	
			pop bc
			pop hl
			pop af
			push af
			push hl
			inc l
			inc h
			dec c
			dec c
			dec b
			dec b
			ld de,MsgBoxCheckValues
			add a,e
			ld e,a
			ld a,d
			adc a,0
			ld d,a
			ld a,(de)
			and a
			ld a, (CheckBoxBackColor)
			jr z, .ValueZero
			ld a, (CheckBoxHitTrueColor)

.ValueZero:		call @BLOCKFILL
			pop hl
			dec h
			ld d,h
			ld a,(ix+0)
			add a,15
			ld e,a

			ld hl,(MsgBoxQAddr)
			pop af

			and a					; It looks for the correct string by its ordinal number.
			jr z, .StrFound

.c2:			push af

.C3:			ld a,(hl)
			inc hl	
			and a
			jr nz, .C3

			pop af
			dec a
			jr nz, .C2

.StrFound:		ld a, (MenuForeColor)
			ld (RenderForeColor),a
			ld a,(MenuBackGroundColor)
			ld (RenderBackColor),a
			jp @STRDRAWZ



; **************************************************
; * BUNCHS MANAGEMENT IN OBJECT LEVEL              *
; **************************************************






ListsBunchs:		ld bc,0					; In ix = Output buffer base address.
								; out CF = 1 user area is empty or other error.
.Loop:			push bc
			ld e, 1					; Description level.
			ld iy, _GetsBunchInfo
			call @FarCallToPage2
			pop bc
			jr c, .End

			inc bc					; bunch index = bunch index + 1.
			jr .Loop

.End:			ld (ix+0), 0				; null record for marking the end of the list.
			ld a,b
			or c					; Checks if was the bunch index = 0.
			ret nz

			scf					; Indicates that the list is empty.
			ret






ExtractPaletteSet:	call @GETBUNCH_BASEADDR			; In BC = bunch index. This routine assumes you provided a bunch index of a PaletteSet bunch format.
			ret c

			ld bc, BunchHeader.Size
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc				; In UserArea address of the Palette information.
			exx

			ld bc, 32
			ld hl, CurrentPaletteSetBuffer		; It dumps on that array, copying from the UserArea.
			jp @READ_USERAREA






GetsBunchFormat:	call @GETBUNCH_BASEADDR			; in BC = Bunch index.
			ret c					; out a = format. CF = 1 Error.

			ld bc, BunchHeader.FormatID
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc

			jp @USERAREA_RB






GetLinkedBunch:		call @GETBUNCH_BASEADDR			; in BC = Bunch to examine. out BC = Bunch linked.
			ret c					; CF = 1 no link.

			ld bc, BunchHeader.Customs
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc				; Pointer in UserArea to the Customs record.
			exx

			ld hl, UserAreaCpyBuffer
			ld bc, 17
			call @READ_USERAREA
			ret c

			ld a, (UserAreaCpyBuffer)		; Now it have in UserAreaCpyBuffer, the linking name. Checks if there is a name, or an empty linking record.
			and a
			scf
			ret z					; If no linking then escape with CF = 1.
			ld hl, UserAreaCpyBuffer
			; This routine is connected with the next one, so don't insert something in the middle.






FindBunchByName:	ld e,l					; in HL = Name String address.
			ld d,h					; out BC = Bunch ordinal index.
			exx					; CF = 1 error.
			ld bc,0

.BunchLoop:		push bc
			call @GETBUNCH_BASEADDR			; MOD (abc).
			pop bc

			ret c

			exx
			ld b, 16				; Maximun bunch label size.
			ld l,e
			ld h,d					; Reset Name string address.

.ChrLoop:		exx
			push de
			push hl
			call @USERAREA_RB			; MOD (hlde). out a = data.
			pop hl
			pop de
			ret c

			push bc
			ld bc,1
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc				; hlde = hlde + 1.
			pop bc

			exx
			cp (hl)
			inc hl

			jr nz, .IsNotThis

			and a
			jr z, .NullCharFound			; escapes if found NULL CHAR, it means all the name match.

			djnz .ChrLoop

.NullCharFound:		exx
			and a
			ret

.IsNotThis:		exx
			inc bc
			jr .BunchLoop






IDEEXT_END:



; **************************************************
; * OUTPUT FILE FORMAT: IDEEXTP2.BIN               *
; **************************************************






FNAME "ideextp2.bin"
FORG $0

	DB $FE
	DW $8000
	DW IDEEXTP2_END + $4000 - 1
	DW 0

ORG $4000



; **************************************************
; * IN PAGE 2 ROUTINES                             *
; **************************************************






_GETOBJECTSIZE:		ld bc, 16				; in A = FormatID.
			cp FormatID.TileSc2			; out BC = Buffer size for current object format.
			ret z
			ld bc, 32
			cp FormatID.TileSc5
			ret z
			cp FormatID.PaletteSet
			ret z
			ld bc, 36
			cp FormatID.SpriteMSX1
			ret z
			ld bc, 64
			cp FormatID.TileSc8
			ret z
			ld bc, 50
			cp FormatID.SpriteMSX2
			ret z
			ld bc, 32*4
			cp FormatID.TileSc5_16
			ret z
			ld bc, 32*16
			cp FormatID.TileSc5_32
			ret z
			ld bc, 64*4
			cp FormatID.TileSc8_16
			ret z
			ld bc, 64*16
			cp FormatID.TileSc8_32
			ret z

			ld b, a
			and FormatID.MapIndIDMask
			cp FormatID.MapIndID
			ld a, b
			jr nz, .OtherFormat
								; Is an indexator format.
			push hl
			ld hl, 4
			and FormatID.MapIndYTilesDoubler
			jr z, .NoInd1
			add hl,hl

.NoInd1:		ld a, b
			and FormatID.MapIndXTilesDoubler
			jr z, .NoInd2
			add hl,hl

.NoInd2:		ld a, b
			and FormatID.MapInd16bitsTileNumber
			jr z, .NoInd3
			add hl,hl

.NoInd3:		ld c,l
			ld b,h
			pop hl
			ret

.OtherFormat:		and FormatID.MapSceneIDMask
			cp FormatID.MapSceneID
			jr nz, .OtherFormat2
								; Is a MAP.
			ld a, b
			and FormatID.MapScene16Bits
			ld bc, 1
			ret z
			ld c, 2
			ret

.OtherFormat2:		ld bc, 1				; Format not found, default size = 1.
			ret






_CalculateRawSize:	ld c,a					; It is not used/ not support for MAP format.
			and FormatID.MapIndIDMask
			cp FormatID.MapIndID
			ld a,c
			jp z, .MTC

			cp FormatID.SpriteMSX1
			jp z, .x36
			cp FormatID.SpriteMSX2
			jp z, .x50

			and a					; in a = format ID, in hlde = ammount. out hlde = RawSize.
			rl e
			rl d					; mod (bc).
			rl l
			rl h					; *2
			ret c
			rl e
			rl d
			rl l
			rl h					; *4
			ret c
			rl e
			rl d
			rl l
			rl h					; *8
			ret c
			rl e
			rl d
			rl l
			rl h					; *16
			ret c

			cp FormatID.TileSc2
			ret z

			and a
			rl e
			rl d
			rl l
			rl h					; *32
			ret c

			cp FormatID.TileSc5
			ret z
			cp FormatID.PaletteSet
			ret z

			and a
			rl e
			rl d
			rl l
			rl h					; *64
			ret c

			cp FormatID.TileSc8
			ret z

			and a
			rl e
			rl d
			rl l
			rl h					; *128
			ret c

			cp FormatID.TileSc5_16
			ret z

			and a
			rl e
			rl d
			rl l
			rl h					; *256
			ret c

			cp FormatID.TileSc8_16
			ret z

			and a
			rl e
			rl d
			rl l
			rl h					; *512
			ret c

			cp FormatID.TileSc5_32
			ret z

			and a
			rl e
			rl d
			rl l
			rl h					; *1024
			ret c

			cp FormatID.TileSc8_32
			ret z

			scf					; Err.
			ret

.x36:			and a
			rl e
			rl d
			rl l
			rl h					; *2
			ret c
			rl e
			rl d
			rl l
			rl h					; *4
			ret c

			push hl
			push de

			rl e
			rl d
			rl l
			rl h					; *8
			jr c, .Err
			rl e
			rl d
			rl l
			rl h					; *16
			jr c, .Err
			rl e
			rl d
			rl l
			rl h					; *32
			jr c, .Err

			pop bc
			ex de, hl
			add hl, bc
			ex de, hl
			pop bc
			adc hl, bc

			ret

.Err4:			pop de
			pop hl

.Err:			pop de
			pop hl
			ret

.x50:			and a
			rl e
			rl d
			rl l
			rl h					; *2
			ret c

			push hl
			push de

			rl e
			rl d
			rl l
			rl h					; *4
			jr c, .Err
			rl e
			rl d
			rl l
			rl h					; *8
			jr c, .Err
			rl e
			rl d
			rl l
			rl h					; *16
			jr c, .Err

			push hl
			push de

			rl e
			rl d
			rl l
			rl h					; *32
			jr c, .Err4

			pop bc
			ex de, hl
			add hl, bc
			ex de, hl
			pop bc
			adc hl, bc				; *48
			jr c, .Err

			pop bc
			ex de, hl
			add hl, bc
			ex de, hl
			pop bc
			adc hl, bc				; *50
			ret

.MTC:			rl e
			rl d
			rl l
			rl h					; *2
			ret c

			rl e
			rl d
			rl l
			rl h					; *4
			ret c

			bit 0,c
			jr z, .MTCJ1

			rl e
			rl d
			rl l
			rl h					; *8
			ret c

.MTCJ1:			bit 1,c
			jr z, .MTCJ2

			rl e
			rl d
			rl l
			rl h					; *16
			ret c

.MTCJ2:			bit 2,c
			ret z

			rl e
			rl d
			rl l
			rl h					; *32
			ret






_USERAREA_ZERO:		call @LogicToRawAddr			; in hlde = plain user area offset address.
			ret c					; in hl'de' = size to erase with zeroes.
			call @SetSegment			; out CF = 1 error.
			ret c					; MOD (ahl'de'hlde).

			exx

.Loop:			ld a,e
			or d
			or l
			or h
			ret z

			exx

			xor a
			ld (de),a

			call @USERAREA_NEXTBYTE
			ret c

			exx

			dec de					; hlde = hlde - 1.
			ld a,e
			and d
			cp $ff
			jr nz, .Loop
			dec hl
			jr .Loop






_CreateBunch:		ld bc, BunchHeader.Size			; in hlde = Raw Size needed. Filename must be in MsgBox.Textbox, the format must be in (creating format).
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc
								; Ok, creating the bunch.
			push de
			push hl
			call _BUNCH_CREATE			; In hlde = bunch size. Out BC = Bunch index.
			exx
			pop hl
			pop de
			exx
			ret c

			call @GETBUNCH_BASEADDR			; in bc = bunch index.
			ret c					; out hlde = Bunch BaseAddr.

			push hl					
			push de					; Saves base address for later use.

			push de
			push hl
			ld a, (CreatingNotZeroing)
			and a
			jr z, .ZeroAll

			exx
			ld de, BunchHeader.Size			; Change the size to only initialize the bunch header.
			ld hl, 0
			exx

.ZeroAll:		call _USERAREA_ZERO

			ld hl, MsgBoxBuffer
			exx
			pop hl
			pop de
	
.LB:			exx
			ld a,(hl)
			inc hl
			and a
			jr z, .JSetBFormat

			exx
			push de
			push hl
			call @USERAREA_WB
			pop hl
			pop de

			inc de
			ld a,e
			or d
			jr nz, .LB
			inc hl
			jr .LB

.JSetBFormat:		pop hl
			ld bc, BunchHeader.FormatID
			add hl, bc
			ex de,hl
			ld bc, 0
			pop hl
			adc hl, bc

			ld a,(CreatingFormat)
			push de
			push hl
			call @USERAREA_WB
			pop hl
			pop de

			ld a,(CreatingFormat)			
			cp FormatID.PaletteSet
			jr z, .Pal

			and FormatID.MapSceneIDMask
			cp FormatID.MapSceneID
			scf
			ccf
			ret nz					; hlde is positioned in the BunchHeader.FormatID field.
								; if is creating a map scene, it saves in the Custom field the Width and Height values.
			ld bc, 1 + 17				; The linking uses 17 bytes in the custom field. Add 1 for passing the .FormatID adds 17 for skipping the linking field.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc			

			exx
			ld hl, (CreatingHeight)
			exx
			ld bc, (CreatingWidth)
			jp @USERAREA_WDW

.Pal:			ld bc, BunchHeader.Size - BunchHeader.FormatID
			ex de,hl				; It increases the pointer for skips what left of the bunch header.
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc				; hlde is positioned on the RawAddress, where is the palette information.

			ld b, 16

.PalLoop:		push hl
			push de
			push bc
			
			ld a, 16
			sub b
			rra					; A = pal number / 2.
			and $07
			ld b, a

			add a,a
			add a,a
			add a,a
			add a,a
			or b
			ld c, a

			call @USERAREA_WW

			pop bc
			pop de
			pop hl
			ret c

			inc de
			ld a,e
			or d
			jr nz, .PalNoInc1
			inc hl

.PalNoInc1:		inc de
			ld a,e
			or d
			jr nz, .PalNoInc2
			inc hl

.PalNoInc2:		djnz .PalLoop
			ret






_GETFREEMARK_ADDRESS:	ld de,0					; OUT hlde = freemark address.
			ld l,e					; OUT (CF) = 1 error.
			ld h,d

.Loop:			push hl					; hlde = link address.
			push de
			call @USERAREA_RDW			; It returns the link value in [hlbc].
			pop de
			jr nc, .RdOk
	
.Err:			pop hl
			ret

.RdOk:			ld a,c					; Checks if the DWORD readed is the freemark.
			or b
			or l
			or h
			jr z, .FoundFreeMark

			ex de,hl
			add hl,bc
			ex de,hl
			pop bc
			adc hl,bc				; hlde = hlde + Link value.
			ret c

			ld bc,4
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc				; hlde = hlde + SizeOf(DWORD).
			ret c

			jr .Loop

.FoundFreeMark:		pop hl
			ret






_GETUSERAREA_FREESPACE:	CALL _GETFREEMARK_ADDRESS		; OUT hlde = free space.
			ret c					; CF = 1 error.

			exx					; now hl'de' = freemark address.

			ld hl,(StorageStopSegment)
			ld de,(StorageStartSegment)
			and a
			sbc hl,de				; hl = Total memory size in segments.

			ld de,0
			rr h
			rr l
			rr d					; 0 > hld > 0.

			rr h
			rr l
			rr d					; 0 > hld > 0.
								; hlde = Total memory size in bytes.
			call @M32SUB				; hlde = Total memory size - used memory (ammount pointed because all previous the freemark is used).
			ret c

			exx
			ld de,8
			ld hl,0
			exx
			jp @M32SUB				; hlde = hlde - SizeOf(DWORD)*2. As was used the base address of the freemark and not the next address from the freemark AND as will be used to created another bunch, take in account the space for the new linking needed.






_BUNCH_CREATE:		push hl					; In hlde = size.
			push de					; out bc = Bunch index.	
			call _GETUSERAREA_FREESPACE		; out (cf) = 1 error.
			exx					; MOD (ahldehl'de'bc').
			pop de
			pop hl
			exx
			call @M32COMP
			ret c					; if (FreeSpace < Size) then Error.

			exx
			push hl
			push de					; It saves the size.

			ld hl,0					; Initialize link address.
			ld de,0
			ld bc,0					; Initialize bunch ordinal number.

.Loop:			push bc
			push hl
			push de
			call @USERAREA_RDW			; This outs the DWORD in [hlbc].
			pop de
			jr nc, .RdOk

.Err:			pop hl
.Err2:			pop bc
			pop de
			pop hl
			ret

.RdOk:			ld a,c					; Checks if the DWORD readed is a terminator.
			or b
			or l
			or h
			jr z, .FoundFreeMark

			ex de,hl
			add hl,bc
			ex de,hl
			pop bc
			adc hl,bc				; hlde = current link address + bunch size (the link is a DWORD with its bunch size).
			jr c, .Err2

			ld bc,4
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc				; hlde = hlde + SizeOf(DWORD).
			jr c, .Err2

			pop bc
			inc bc
			jr .Loop

.FoundFreeMark:		pop hl					; hlde = actual freemark address.
			pop bc					; bc = Bunch ordinal index, needed as output.
			exx
			pop de
			pop hl
			push hl					; Recall and resave wanted bunch size.
			push de
			exx					; now hl'de' = wanted bunch size.
			push bc					; It saves bunch ordinal index.
			push hl
			push de					; It saves actual freemark address.

			exx
			push de
			exx
			pop bc					; It writes new bunch linking.
			call @USERAREA_WDW			; in hlde = addr, hl'bc = data.

			pop de
			pop hl					; Restore the new link bunch address.
			exx
			pop bc
			exx					; now bc' = bunch ordinal index.
			jr nc, .Ok

			pop de
			pop hl
			ret

.Ok:			pop bc
			ex de,hl
			add hl,bc
			ex de,hl
			pop bc
			adc hl,bc
			ret c					; hlde = new link bunch address + Wanted size.

			ld bc,4
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc				; Address for the new freemark = hlde = hlde + SizeOf(DWORD).

			exx
			ld hl,0
			exx
			ld bc,0
			call @USERAREA_WDW			; in hlde = addr, hl'bc = data.
			exx
			ret






_BUNCH_DELETE:		call @GETBUNCH_LINKADDR			; in BC = Bunch Index. Input can't be the freemark.
			ret c					; out CF = 1 Error.
								; in hlde = link address. It will be the DESTINATION address.
			ld (UserAreaCpyDestinationLow), de
			ld (UserAreaCpyDestinationHigh), hl

			push hl					; It reads the link value for later know the SOURCE address.
			push de					; Saves the link address.
			call @USERAREA_RDW			; This outs the DWORD in [hlbc].
			jr nc, .RdOk

			pop de
			pop hl
			ret

.RdOk:			pop de
			ex de,hl
			add hl,bc
			ex de,hl
			pop bc
			adc hl,bc				; hlde = link address + link value.

			ld bc,4
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc				; hlde = hlde + SizeOf(DWORD).
								; hlde = It is the SOURCE address!!!.
			ld (UserAreaCpySourceLow), de
			ld (UserAreaCpySourceHigh), hl
								; Now to calculate the size of all the rest bunches, plus 4 bytes (for the final freemark).
.Loop:			push hl					; that is (FreeMark address - Source address + 4).
			push de
			call @USERAREA_RDW			; This outs the DWORD in [hlbc].
			pop de
			jr nc, .RdOk2
	
			pop hl
			ret

.RdOk2:			ld a,c					; Checks if the DWORD readed is the freemark.
			or b
			or l
			or h
			jr z, .FoundFreeMark

			ex de,hl
			add hl,bc
			ex de,hl
			pop bc
			adc hl,bc				; hlde = link address + link value.
			ret c

			ld bc,4
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc				; hlde = hlde + SizeOf(DWORD).
			ret c

			jr .Loop

.FoundFreeMark:		pop hl					; hlde = freemark current address.
			exx
			ld de,(UserAreaCpySourceLow)
			ld hl,(UserAreaCpySourceHigh)
			exx
			call @M32SUB
			ret c

			ld bc,4
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc
			ret c					; hlde = size to move.

			ld (UserAreaCpyLengthLow),de
			ld (UserAreaCpyLengthHigh),hl
			jp _USERAREA_COPY






_EDITORLOAD:		ld de,(EditorCursorAddrLow)		; out CF = 1 error.
			ld hl,(EditorCursorAddrHigh)		; MOD (ahldebchl'de'bc').
			exx
			ld a,(EditorCurrentFormat)
			call _GETOBJECTSIZE
			ld hl, EditorBuffer
			jp @READ_USERAREA






_USERAREA_COPY:		ld de, (UserAreaCpyDestinationLow)	; General purpose function to COPY FROM/TO the USER AREA.
			ld hl, (UserAreaCpyDestinationHigh)	; This is the only way to perform bunch resizes, and deletions.
			exx					; (UserAreaCpySourceLow), (UserAreaCpySourceHigh)
			ld de, (UserAreaCpySourceLow)		; (UserAreaCpyDestinationLow), (UserAreaCpyDestinationHigh)
			ld hl, (UserAreaCpySourceHigh)		; (UserAreaCpyLengthLow), (UserAreaCpyLengthHigh)
			call @M32COMP				; out CF = 1 error.
			jp c, .JLDDR

.JLDIR:			ld de, (UserAreaCpyLengthLow)
			ld hl, (UserAreaCpyLengthHigh)
			ld a,d
			or l
			or h
			jr z, .FinalLdir
								; Copy length > 256.
			ld a,d
			sub 1
			ld d,a
			jr nc, .J1
			dec hl
.J1:
			ld (UserAreaCpyLengthLow),de
			ld (UserAreaCpyLengthHigh),hl		; Length = Length - 256.

			ld de, (UserAreaCpySourceLow)
			ld hl, (UserAreaCpySourceHigh)
			exx
			ld hl, UserAreaCpyBuffer
			ld bc,256
			call @READ_USERAREA			; in hl'de' = source plain user area offset address.
								; in hl = destination buffer base address,
								; in bc = length.
			ret c					; out CF = 1 error.

			ld de, (UserAreaCpyDestinationLow)
			ld hl, (UserAreaCpyDestinationHigh)
			exx
			ld hl, UserAreaCpyBuffer
			ld bc,256
			call @WRITE_USERAREA			; in hl'de' = destination plain user area offset address.
								; in hl = source buffer base address,
								; in bc = length.
			ret c					; out CF = 1 error.

			ld de, (UserAreaCpySourceLow)
			ld hl, (UserAreaCpySourceHigh)
			inc d
			jr nz, .J2
			inc hl					; Source = Source + 256
.J2:
			ld (UserAreaCpySourceLow),de
			ld (UserAreaCpySourceHigh),hl

			ld de, (UserAreaCpyDestinationLow)
			ld hl, (UserAreaCpyDestinationHigh)
			inc d
			jr nz, .J3
			inc hl					; Destination = Destination + 256.
.J3:
			ld (UserAreaCpyDestinationLow), de
			ld (UserAreaCpyDestinationHigh), hl

			jr .JLDIR

.FinalLdir:		ld a, (UserAreaCpyLengthLow)		; If Length = 0 then END
			and a
			ret z					; It was a zip copy or a (n*256) wanted size.

			ld de,(UserAreaCpySourceLow)
			ld hl,(UserAreaCpySourceHigh)
			exx
			ld bc, (UserAreaCpyLengthLow)
			ld hl, UserAreaCpyBuffer
			call @READ_USERAREA
			ret c

			ld de, (UserAreaCpyDestinationLow)
			ld hl, (UserAreaCpyDestinationHigh)
			exx
			ld bc, (UserAreaCpyLengthLow)
			ld hl, UserAreaCpyBuffer
			jp @WRITE_USERAREA

.JLDDR:			ld de, (UserAreaCpyLengthLow)		; Now, LDDR equivalent is more complex, because it must go backwards!,
			ld hl, (UserAreaCpySourceLow)		; so it must recalculate both pointers at the end,
			add hl,de				; but at the base address of the last chunk!.
			ld (UserAreaCpySourceLow),hl
			ld de, (UserAreaCpyLengthHigh)
			ld hl, (UserAreaCpySourceHigh)
			adc hl,de
			ld (UserAreaCpySourceHigh), hl		; Source addr = Source addr + Length.
			ret c

			ld de, (UserAreaCpyLengthLow)
			ld hl, (UserAreaCpyDestinationLow)
			add hl,de
			ld (UserAreaCpyDestinationLow),hl
			ld de, (UserAreaCpyLengthHigh)
			ld hl, (UserAreaCpyDestinationHigh)
			adc hl,de
			ld (UserAreaCpyDestinationHigh), hl	; Destination addr = Destination addr + Length.
			ret c
								; Just placed both pointer at the end.
.JLDDRLOOP:		ld de, (UserAreaCpyLengthLow)
			ld hl, (UserAreaCpyLengthHigh)
			ld a,d
			or l
			or h
			jr z, .FinalLddr
								; Copy Length > 256.
			ld a,d
			sub 1
			ld d,a
			jr nc, .J4
			dec hl
.J4:
			ld (UserAreaCpyLengthLow),de
			ld (UserAreaCpyLengthHigh),hl		; Length = Length - 256.
								; Now it must decrement the source pointer by 256.
			ld bc, $0100
			ld hl, (UserAreaCpySourceLow)
			and a
			sbc hl,bc
			ld (UserAreaCpySourceLow),hl
			ex de,hl
			ld bc, 0
			ld hl, (UserAreaCpySourceHigh)
			sbc hl,bc
			ld (UserAreaCpySourceHigh), hl		; source = source - 256.
			exx					; hl'de' = source pointer.
			ld hl, UserAreaCpyBuffer
			ld bc, 256
			call @READ_USERAREA			; in hl'de' = source plain user area offset address.
								; in hl = destination buffer base address,
								; in bc = length.
			ret c					; out CF = 1 error.

			ld bc, $0100				; Now it must decrement the destination pointer by 256.
			ld hl, (UserAreaCpyDestinationLow)
			sbc hl,bc
			ld (UserAreaCpyDestinationLow),hl
			ex de,hl
			ld bc, 0
			ld hl, (UserAreaCpyDestinationHigh)
			sbc hl,bc
			ld (UserAreaCpyDestinationHigh), hl	; Destination = Destination - 256.
			exx					; hl'de' = Destination pointer.
			ld hl, UserAreaCpyBuffer
			ld bc,256

			call @WRITE_USERAREA			; in hl'de' = destination plain user area offset address.
								; in hl = source buffer base address,
								; in bc = length.
			ret c					; out CF = 1 error.

			jr .JLDDRLOOP

.FinalLddr:		ld bc, (UserAreaCpyLengthLow)		; copy length High byte was already checked to be ZERO before.
			ld a,c
			and a
			ret z					; If copy length = 0 then END.

			ld hl, (UserAreaCpySourceLow)
			sbc hl,bc
			ex de,hl
			ld bc, 0
			ld hl, (UserAreaCpySourceHigh)
			sbc hl,bc				; source = source - length.
			exx					; hl'de' = source pointer.
			ld hl, UserAreaCpyBuffer
			ld bc, (UserAreaCpyLengthLow)
			call @READ_USERAREA			; in hl'de' = source plain user area offset address.
								; in hl = destination buffer base address,
								; in bc = length.
			ret c					; out CF = 1 error.

			ld bc, (UserAreaCpyLengthLow)
			ld hl, (UserAreaCpyDestinationLow)
			sbc hl,bc
			ex de,hl
			ld bc, 0
			ld hl, (UserAreaCpyDestinationHigh)
			sbc hl,bc				; destination = destination - length.
			exx					; hl'de' = Destination pointer.
			ld hl, UserAreaCpyBuffer
			ld bc, (UserAreaCpyLengthLow)

			jp @WRITE_USERAREA






_SWAP_USERAREA:		call @LogicToRawAddr			; in hl'de' = source/destination plain user area offset address.
			ret c					; in hlde = source/destination plain user area offset address.
								; in bcbc' = length.
			exx					; out CF = 1 error.
			call @LogicToRawAddr			; MOD (all).
			ret c					; ATP hl'de' = MSX raw pointer 1.
								; ATP hlde = MSX raw pointer 2.
.Loop:			ld a,c					; Here it must be looking bc' de' hl'.
			or b
			exx
			or c
			or b
			ret z					; if length = 0 then RETURN

			exx
			dec bc
			ld a,c
			and b
			cp $FF
			exx
			jr nz, .J1

			dec bc					; length = length - 1.

.J1:			call @SetSegment
			ret c

			ld a,(de)				; Here cpu is looking bcdehl.
			ex af,af'
			exx
			call @SetSegment
			ld a,(de)
			ex af,af'
			ld (de),a
			exx
			call @SetSegment			; Here cpu is looking bcdehl.
			ex af,af'
			ld (de),a				; SWAP a byte.

			inc de					;  hlde = hlde + 1 & roll is needed.
			bit 6,d
			jr z, .NxTest

			ld d, $80				; Roll up pointer.

			inc hl
			ld a,h
			or l
			scf
			ret z					; Escape if overflowed.

			push hl
			push de
			ld de,(StorageStopSegment)
			and a
			sbc hl,de
			pop de
			pop hl
			scf
			ret z					; Escapes if ends the storage area.

.NxTest:		exx

			inc de					; Here cpu is looking bc'de'hl'.
			bit 6, d
			jr z, .Loop 

			ld d, $80				; Roll up pointer.

			inc hl
			ld a,h
			or l
			scf
			ret z					; Escape if overflowed.

			push hl
			push de
			ld de,(StorageStopSegment)
			and a
			sbc hl,de
			pop de
			pop hl
			scf
			ret z					; Escapes if ends the storage area.

			jr .Loop






_RSWAP_USERAREA:	call @LogicToRawAddr			; in hl'de' = source/destination plain user area offset address.
			ret c					; in hlde = source/destination plain user area offset address.
								; in bcbc' = length.
			exx					; out CF = 1 error.
			call @LogicToRawAddr			; MOD (all).
			ret c					; ATP hl'de' = MSX raw pointer 1.
								; ATP hlde = MSX raw pointer 2.
.Loop:			ld a,c					; Here it must be looking bc' de' hl'.
			or b
			exx
			or c
			or b
			ret z					; if length = 0 then RETURN

			exx
			dec bc
			ld a,c
			and b
			cp $FF
			exx
			jr nz, .J1

			dec bc					; length = length - 1.

.J1:			dec de
			bit 6,d
			jr z, .J2

			ld d, $BF				; Roll up pointer.

			dec hl
			ld a,h
			and l
			cp $FF
			scf
			ret z					; Escape if overflowed.

			push hl
			push de
			ld de,(StorageStartSegment)
			and a
			sbc hl,de
			pop de
			pop hl
			ret c					; Escapes if passed the start of the storage area.

.J2:			exx

			dec de					; Here CPU is looking for bc'de'hl'.
			bit 6,d
			jr z, .J3

			ld d, $BF				; Roll up pointer.

			dec hl
			ld a,h
			and l
			cp $FF
			scf
			ret z					; Escape if overflowed.

			push hl
			push de
			ld de,(StorageStartSegment)
			and a
			sbc hl,de
			pop de
			pop hl
			ret c					; Escapes if passed the start of the storage area.

.J3:			call @SetSegment			; Here CPU is looking for bc'de'hl'.

			ld a,(de)
			ex af,af'
			exx
			call @SetSegment			; Here CPU is looking for bcdehl.
			ld a,(de)
			ex af,af'
			ld (de),a
			exx
			call @SetSegment			; Here cpu is looking bc'de'hl'.
			ex af,af'
			ld (de),a				; SWAP a byte.

			jr .Loop






_USERAREA_SWAP:		ld de, (UserAreaCpyDestinationLow)	; General purpose function to SWAP FROM/TO the USER AREA.
			ld hl, (UserAreaCpyDestinationHigh)	; This is the only way to perform tile resort.
			exx					; (UserAreaCpySourceLow), (UserAreaCpySourceHigh)
			ld de, (UserAreaCpySourceLow)		; (UserAreaCpyDestinationLow), (UserAreaCpyDestinationHigh)
			ld hl, (UserAreaCpySourceHigh)		; (UserAreaCpyLengthLow), (UserAreaCpyLengthHigh)
			call @M32COMP				; out CF = 1 error.
			jp c, .JLDDR

.JLDIR:			ld bc, (UserAreaCpyLengthLow)
			exx
			ld bc, (UserAreaCpyLengthHigh)
			jp _SWAP_USERAREA

.JLDDR:			ld bc, (UserAreaCpyLengthLow)
			ex de,hl
			and a
			add hl,bc
			ex de,hl
			ld bc, (UserAreaCpyLengthHigh)
			adc hl,bc				; P1 = P1 + Length.

			exx
			ld bc, (UserAreaCpyLengthLow)
			ex de,hl
			and a
			add hl,bc
			ex de,hl
			ld bc, (UserAreaCpyLengthHigh)
			adc hl,bc				; P2 = P2 + Length.
			exx
			ld bc, (UserAreaCpyLengthLow)
			exx
			jp _RSWAP_USERAREA






_TITLELINE:		push hl					; HL = string addr, A = Y start line.
			ld h,a					; It renders the bunch title.
			ld l,0
			ld bc, BunchTitleBarHeight * 256
			push af
			ld a, (BunchTitleBarBackColor)
			call @BLOCKFILL

			ld a,(BunchTitleBarForeColor)
			ld l,a
			ld a, (BunchTitleBarBackColor)
			ld h,a
			ld (RenderForeColor),hl
			pop af
			ld b,BunchTitleBarUpperMargin
			add a,b
			ld d,a
			ld e, BunchTitleBarLeftMargin
			pop hl
			jp @STRDRAWZ

_TitleStrEmpty:		DB "User's memory empty.",0






_SpriteConsole:		
.RenderSpriteSelectorInit:call _LoadTileConsoleVariables	; Recycling as the render and vars is the same.

.RenderSpriteSelector:	call _DrawSpriteSelector

			ld iy, DrawTileSelectorScrollBar	; Recycling as the render and vars is the same.
			call @FarCallToPage1

			call _RenderSpritePuzzler

			call .PrintCursorPos

.SSelectorControl:	call @INKEY
			jr c, .SSelectorControl

			call @UPCASE

			cp 28
			jp z, .Right

			cp 29
			jp z, .Left

			cp 30
			jp z, .Up

			cp 31
			jp z, .Down

			cp 13
			jp z, .Hit

			cp 32
			jp z, .Hit

			cp 9
			jr z, .Tab

			cp 27
			jr z, .Esc

			ld b, '0'
			cp '0'
			jr c, .SSelectorControl

			cp '9'+1
			jp c, .SetOnPuzzle

			ld b, 'A'-10
			cp 'A'
			jr c, .SSelectorControl

			cp 'F'+1
			jp c, .SetOnPuzzle

			cp 'M'
			jp z, .HitCopyMark

			cp 'L'
			jp z, .HitClr

			cp 'O'
			jp z, .PuzSort2x2
			cp 'P'
			jp z, .PuzSort4x4

			cp 'G'
			jp z, _GotoOfSpriteSelector

			jr .SSelectorControl

.Tab:			call _SaveTileConsoleVariables

			ld iy, BunchSelector
			jp @FarJumpToPage1

.Esc:			call _SaveTileConsoleVariables

			ld iy, ConsoleRender.GoMenuBar
			jp @FarJumpToPage1

.PrintCursorPos:	ld iy, ConsoleRender.PrintCursorPos
			jp @FarCallToPage1

.Right:			ld hl,(SelectorCursorObjectNumber)
			ld c, 10
			call @DIV16_8				; hl=hl / C, a = hl mod C.
			dec c
			cp c
			jp z, .SSelectorControl

			ld hl,(SelectorCursorObjectNumber)
			push hl

			inc hl
			ld (SelectorCursorObjectNumber),hl
			ld (SelectorCurrentObjectNumber),hl	; Try to redraw where the cursor move on.
			call _RenderSprite
			pop hl
			jr c, .RightErr

			ld (SelectorCurrentObjectNumber),hl	; Ok.
			call _RenderSprite			; Erase the visualization of the cursor from the old location.
			call .PrintCursorPos
			jp .SSelectorControl

.RightErr:		ld (SelectorCursorObjectNumber),hl	; Error didn't rendered the sprite, so it doesn't exists, or is out of the view.
			jp .SSelectorControl

.Left:			ld hl,(SelectorCursorObjectNumber)
			ld c, 10
			call @DIV16_8				; hl=hl / C, a = hl mod C.
			and a
			jp z, .SSelectorControl

			ld hl,(SelectorCursorObjectNumber)
			push hl

			dec hl
			ld (SelectorCursorObjectNumber),hl
			ld (SelectorCurrentObjectNumber),hl
			call _RenderSprite			; Going backward is always ok at this point.

			pop hl
			ld (SelectorCurrentObjectNumber),hl
			call _RenderSprite			; Erase the visualization of the cursor from the old location.
			call .PrintCursorPos
			jp .SSelectorControl

.Down:			ld hl,(SelectorCursorObjectNumber)
			push hl

			ld bc, 10
			add hl,bc
			ld (SelectorCursorObjectNumber),hl
			ld (SelectorCurrentObjectNumber),hl
			call _RenderSprite
			jr c, .DownErr

			pop hl
			ld (SelectorCurrentObjectNumber),hl
			call _RenderSprite			; Erase the visualization of the cursor from this location.
			call .PrintCursorPos
			jp .SSelectorControl

.DownErr:		rla
			pop hl
			jr c, .OutOfSprites

			ld hl,(SelectorCurrentScrollTop)	; Was just a visual overflow.
			ld bc, 10
			add hl,bc
			ld (SelectorCurrentScrollTop),hl	; Scroll down!.
			jp .RenderSpriteSelector		; Redraw all!.

.OutOfSprites:		ld (SelectorCursorObjectNumber),hl
			jp .SSelectorControl

.Up:			ld hl,(SelectorCursorObjectNumber)
			ld c, 10
			call @DIV16_8
			ld a, h
			or l
			jp z, .SSelectorControl

			ld hl,(SelectorCursorObjectNumber)
			push hl

			ld bc, 10
			and a
			sbc hl,bc
			ld (SelectorCursorObjectNumber),hl
			ld (SelectorCurrentObjectNumber),hl

			ld de,(SelectorCurrentScrollTop)
			and a
			sbc hl,de
			jr nc, .NoScroll

			pop hl
			ld hl,(SelectorCurrentScrollTop)
			ld bc, 10
			and a
			sbc hl,bc
			ld (SelectorCurrentScrollTop),hl
			jp .RenderSpriteSelector

.NoScroll:		call _RenderSprite

			pop hl
			ld (SelectorCurrentObjectNumber),hl
			call _RenderSprite			; Erase the visualization of the cursor from this location.
			call .PrintCursorPos
			jp .SSelectorControl

.SetOnPuzzle:		sub b
								; A = offset.
			ld e,a					; It calculates the address to register the sprite in the Puzzler.
			ld d,0
			ld l,e
			ld h,d
			add hl,hl
			add hl,hl
			add hl,de
			add hl,de
			add hl,de				; HL = A * 7.
			ld de, PuzzlerIndexationBuffer
			add hl,de

			push hl

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber),hl
			ld iy, GetObjectRawAddress		; In (SelectorCurrentObjectNumber).
			call @FarCallToPage1
			pop ix
			jp c, .SSelectorControl			; It looks for the Sprite in the user area.

			ld (ix+0),e
			ld (ix+1),d
			ld (ix+2),l
			ld (ix+3),h
			ld a,(SelectorCurrentFormat)
			ld (ix+4),a
			ld hl, (SelectorCursorObjectNumber)
			ld (ix+5),l
			ld (ix+6),h
			xor a					; Indicates that the last thing the user did is to set a puzzle, so later when editing the indexator doing HIT on one block will be set up with this puzzle information.
			ld (SelectorLinkedActivityLastDone), a
			jp .RenderSpriteSelector

.Hit:			ld a,(SelectorCurrentFormat)		; Must load the sprite editor with the info of the sprite where the cursor is on.
			ld (EditorCurrentFormat),a

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber),hl

			ld iy, GetObjectRawAddress
			call @FarCallToPage1
			jp c, .RenderSpriteSelector

			ld (EditorCursorAddrLow),de
			ld (EditorCursorAddrHigh),hl

			call _EDITORLOAD			; It loads the graphic information into the editor buffer.
			jp c, .RenderSpriteSelector

			ld a, $FF
			ld (EditorCurrentlyInUse), a		; Indicates that it will start editing.

			ld (PuzzlerForceRenderAll), a
			call _RenderSpritePuzzler		; It redraws the puzzler because with some formats it moves to another place when editing.
			xor a
			ld (PuzzlerForceRenderAll), a

			call _RunSpriteEditor
			xor a
			ld (EditorCurrentlyInUse), a		; Indicates that it finished from editing.
			jp .RenderSpriteSelector

.HitCopyMark:		ld hl,(SelectorCopyFromRawAddrHigh)	; Check if already has the start sprite.
			ld de,(SelectorCopyFromRawAddrLow)
			ld a,e
			or d
			or l
			or h
			jr nz, .HitCopySetLength
								; Ok it must define the start sprite.
			ld a,(SelectorCurrentFormat)
			ld (SelectorCopyFromFormat),a

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber) ,hl

			ld iy, GetObjectRawAddress		; In (SelectorCurrentObjectNumber).
			call @FarCallToPage1
			jp c, .SSelectorControl
						
			ld (SelectorCopyFromRawAddrLow), de
			ld (SelectorCopyFromRawAddrHigh), hl
			
			jp .SSelectorControl

.HitCopySetLength:	ld hl,(SelectorCopyStopRawAddrHigh)	; Check if already has the stop sprite.
			ld de,(SelectorCopyStopRawAddrLow)
			ld a,e
			or d
			or l
			or h
			jr nz, .HitCopySetDestination
								; Ok it must define the stop sprite.
			ld a,(SelectorCurrentFormat)
			ld b,a
			ld a,(SelectorCopyFromFormat)
			cp b
			jr nz, .StopNotValid			; If the format don't match, it is not inside the same bunch!.

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber) ,hl

			ld iy, GetObjectRawAddress		; In (SelectorCurrentObjectNumber).
			call @FarCallToPage1
			jp c, .SSelectorControl

			ld bc,(SelectorCopyFromRawAddrHigh)	; Check valid range. if Start <= Stop then
			push hl
			sbc hl,bc
			pop hl
			jr c, .StopNotValid
			jr nz, .StopValid

			ld bc,(SelectorCopyFromRawAddrLow)
			ex de,hl
			push hl
			sbc hl,bc
			pop hl
			ex de,hl
			jr c, .StopNotValid

.StopValid:		ld a,(SelectorCopyFromFormat)
			call _GETOBJECTSIZE

			ex de,hl				; It saves an incremented Stop address in way to include the sprite that is on the cursor.
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc		
			
			ld (SelectorCopyStopRawAddrLow), de
			ld (SelectorCopyStopRawAddrHigh),hl
			jp .RenderSpriteSelector

.StopNotValid:		call @BEEP
			jp .ClearCpy

.HitCopySetDestination:	ld a,(SelectorCurrentFormat)
			ld b,a
			ld a,(SelectorCopyFromFormat)
			cp b
			jr nz, .StopNotValid			; By now the copy/swap operation will not support TRANSCODING, but is perfect possible to transcode the sprite format from MSX1 to MSX2, just that I don't have time for that!. If changed it, the code for checking if the destination area has enough space must be rewrited because when transcoding the object size is different from source than destination.

			ld a,b
			ld (SelectorCopyToFormat),a

			ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber) ,hl

			ld iy, GetObjectRawAddress		; In (SelectorCurrentObjectNumber).
			call @FarCallToPage1
			jp c, .SSelectorControl

			ld (SelectorCopyToRawAddrLow), de
			ld (SelectorCopyToRawAddrHigh),hl
							
			ld de, (SelectorCopyStopRawAddrLow)	; Checks if the size copied will fit in the destination bunch where pointed.
			ld hl, (SelectorCopyStopRawAddrHigh)

			ld bc, (SelectorCopyFromRawAddrLow)
			ex de,hl
			and a
			sbc hl,bc
			ex de,hl
			ld bc, (SelectorCopyFromRawAddrHigh)
			sbc hl,bc
								; hlde = length in bytes of what to be copied.
			ld (UserAreaCpyLengthLow),de
			ld (UserAreaCpyLengthHigh),hl

			ld bc, (SelectorCopyToRawAddrLow)	; If transcoding support, these lines must be change. Like testing by 'object count' and not by its length.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, (SelectorCopyToRawAddrHigh)
			adc hl,bc				; hlde = Destination address + Length in bytes.
								; Now checks if it passed the end of the current bunch.
			ld bc, (SelectorStopRawAddrHigh)
			and a
			sbc hl,bc
			jr c, .CpyAllowed
			jr nz, .StopNotValid

			ld bc, (SelectorStopRawAddrLow)
			ex de,hl
			sbc hl,bc
			jr c, .CpyAllowed
			jr nz, .StopNotValid

.CpyAllowed:		ld ix, CopyMenuData
			ld iy, MENUPOPUP
			call @FarCallToPage1
			jp c, .SSelectorControl			; If escaped.

			and a
			jr z, .SetCopy				; Copy.
			dec a
			jr z, .SetSwap				; Swap.
								; Cancel.
.ClearCpy:		ld hl,0
			ld (SelectorCopyFromRawAddrLow),hl
			ld (SelectorCopyFromRawAddrHigh),hl
			ld (SelectorCopyStopRawAddrLow),hl
			ld (SelectorCopyStopRawAddrHigh),hl
			ld (SelectorCopyToRawAddrLow),hl
			ld (SelectorCopyToRawAddrHigh),hl
			jp .RenderSpriteSelector

.SetCopy:		call .PrepareCpy

			call _USERAREA_COPY
			jp c, .StopNotValid
			jp .ClearCpy

.PrepareCpy:		ld hl,(SelectorCopyFromRawAddrLow)
			ld (UserAreaCpySourceLow),hl
			ld hl,(SelectorCopyFromRawAddrHigh)
			ld (UserAreaCpySourceHigh),hl
			ld hl,(SelectorCopyToRawAddrLow)
			ld (UserAreaCpyDestinationLow),hl
			ld hl,(SelectorCopyToRawAddrHigh)
			ld (UserAreaCpyDestinationHigh),hl
			ret

.SetSwap:		call .PrepareCpy

			call _USERAREA_SWAP
			jp c, .StopNotValid
			jp .ClearCpy

.HitClr:		ld hl, PuzzlerIndexationBuffer
			ld de, PuzzlerIndexationBuffer + 1
			ld bc, 7*16-1
			ld (hl),0
			ldir
			jp .RenderSpriteSelector

.PuzSort2x2:		call _PuzSort2x2
			jr .Jp2

.PuzSort4x4:		call _PuzSort4x4
.Jp2:			jp .RenderSpriteSelector






_DrawSpriteSelector:	ld hl,(SelectorCurrentScrollTop)
			ld (SelectorCurrentObjectNumber),hl

.SpriteSelectorLoop:	call _RenderSprite
			
			ld hl,(SelectorCurrentObjectNumber)
			inc hl
			ld (SelectorCurrentObjectNumber),hl	; Object number =+ 1.
			jr nc, .SpriteSelectorLoop

			rra
			jr nc, .SpriteSelectorLoop		; SCF + A bit 0 = 1 = Out of Visual area.
			ret






_RenderSprite:		ld hl,(SelectorCurrentObjectNumber)	; It calculates the visual position where to render the sprite.
			ld c, 10
			call @DIV16_8				; Out A = hl mod c, hl = hl \ c.

			add a,a
			add a,a
			add a,a
			ld b,a
			add a,a
			add a,b					; a = a * 24.
			add a, 3
			push af

			ld hl,(SelectorCurrentObjectNumber)
			ld de,(SelectorCurrentScrollTop)
			sbc hl,de				; Adjusts with the current scrollTop. As it starts render from the ScrollTop it can't be negative.

			ld c, 10
			call @DIV16_8				; Out A = hl mod c, hl = hl \ c.

			ld a, l
			add a,a
			add a,a
			add a,a
			ld l, a
			add a,a
			add a,l
			ld l, a					; hl = (SelectorCurrentObjectNumber \ 10)*24.

			ld de, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			add hl,de

			push hl					; hl = visual Y start for the render.

			ld iy, GetObjectRawAddress		; This part pick up the SPRITE graphics from the USER_AREA, In (SelectorCurrentObjectNumber).
			call @FarCallToPage1
			jp c, .OutOfTiles
						
			ld (SelectorCurrentRawAddrLow), de
			ld (SelectorCurrentRawAddrHigh), hl

			ld bc,(SelectorStopRawAddrHigh)		; Checks if reached the stop raw address.
			sbc hl,bc
			jr c, .J1
			jp nz, .OutOfTiles
			ld bc,(SelectorStopRawAddrlow)
			ex de,hl
			sbc hl,bc
			jp nc, .OutOfTiles			; Escapes if reached the bunch limit.

.J1:			call @SELECTORLOAD			; It loads the object data in the Selector buffer.
			jp c, .OutOfTiles

			pop hl
			pop bc

			xor a
			cp h
			ld a, 1					; A bit 0 = 1 out of visual area.
			ret c
			ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator+16*4-10
			cp l
			ld a, 1
			ret c

			ld h,l
			ld l,b					; hl = top/left where to render the sprite.

			dec l					; in hl = top/left.
			dec l					; It draws the upper enclosure of a sprite. In the sprite selector.
			dec l
			push hl					; Saves the render visual position for the lines of the sprite.

			dec h
			dec h
			dec h
			push hl
			ld a, (OutlineColor)
			ld c, a

			ld b, 16 + 6
			call @HLINE
			pop hl
			ld a, (ScreenBackgroundColor)
			out ($98),a				; Sprite separator.
			push hl					; It saves the visual position of the sprite including its enclosure.
			ld de,(SelectorCursorObjectNumber)
			ld hl,(SelectorCurrentObjectNumber)
			sbc hl,de

			ld a, (OutlineCursorColor)		; Cursor Color.
			ld c, a
			jr z, .Cursor

			ld hl, (SelectorCurrentRawAddrHigh)	; Checks if the tile is about to be copied/exchanged.
			ld de, (SelectorCopyFromRawAddrHigh)
			and a
			sbc hl,de
			jr c, .NoToBeCopied
			jr nz, .TBCC

			ld hl, (SelectorCurrentRawAddrLow)
			ld de, (SelectorCopyFromRawAddrLow)
			sbc hl,de
			jr c, .NoToBeCopied
			jr z, .ToBeCopied			; Marks the start sprite for copy operation, anyway in case that the Stop sprite is not already set.

.TBCC:			ld hl, (SelectorCurrentRawAddrHigh)
			ld de, (SelectorCopyStopRawAddrHigh)
			sbc hl,de
			jr c, .ToBeCopied
			jr nz, .NoToBeCopied
			
			ld hl, (SelectorCurrentRawAddrLow)
			ld de, (SelectorCopyStopRawAddrLow)
			sbc hl,de
			jr c, .ToBeCopied

.NoToBeCopied:		push hl
			push de
			push bc			

			ld hl, PuzzlerIndexationBuffer		; Checks if this sprite is also on the Puzzler.
			ld b,16					; The puzzler has 16 sprites subscriptions.

.IsInPuzLoop:		ld de, SelectorCurrentRawAddrLow
			ld a,(de)
			inc de
			cp (hl)
			inc hl
			jr nz, .PuzJ4

			ld a,(de)
			inc de
			cp (hl)
			inc hl
			jr nz, .PuzJ3

			ld a,(de)
			inc de
			cp (hl)
			inc hl
			jr nz, .PuzJ2

			ld a,(de)
			inc de
			cp (hl)
			inc hl
			inc hl
			inc hl
			inc hl
			jr z, .IsInPuz
			djnz .IsInPuzLoop
			jr .IsNotInPuz

.IsInPuz:		pop bc
			pop de
			pop hl

			ld a, (OutlineSecondaryRemarkColor)	; Is in the puzzle and not to be copied.
			ld c, a
			jr .Cursor

.ToBeCopied:		ld a, (OutlinePrimaryRemarkColor)	; Is to be copied.
			ld c, a
			jr .Cursor

.PuzJ4:			inc hl
.PuzJ3:			inc hl
.PuzJ2:			inc hl
			inc hl
			inc hl
			inc hl
			djnz .IsInPuzLoop

.IsNotInPuz:		pop bc
			pop de
			pop hl

			ld a, (ScreenBackgroundColor)		; When the sprite is not remarked.
			ld c, a

.Cursor:		pop hl
			inc h
			push hl
			call @VPOKEPOS

			ld a, (OutlineColor)
			out ($98),a
			ld b, 16 + 4
			ld a,c
.L1:			out ($98),a
			djnz .L1
			ld a, (OutlineColor)
			out ($98),a
			ld a, (ScreenBackgroundColor)
			out ($98),a				; Sprite separator.
			pop hl
			inc h
			call @VPOKEPOS
			ld a, (OutlineColor)
			out ($98),a
			ld a,c
			out ($98),a
			ld b, 16 + 2
			ld a, (ScreenBackgroundColor)
.L2:			out ($98),a			
			djnz .L2
			ld a,c
			out ($98),a
			ld a, (OutlineColor)
			out ($98),a
			ld a, (ScreenBackgroundColor)
			out ($98),a				; Sprite separator.

			ld ix, SelectorBuffer
			pop hl

			ld a,(SelectorCurrentFormat)		; the content of the sprite depends on the bunch format.
			and a
			cp FormatID.SpriteMSX2
			jp z, .SpriteMSX2
								; Only lefts SpriteMSX1.
			di

			ld a, (ix+35)				; Reads the color attribute for MSX1 format.
			call _EditorPickColor
			ld e, a

			ld b, 16

.SMSX1LineLoop:		push hl
			call @VPOKEPOS				; Sets the VDP on bitmap X/Y = hl.
			push bc

			ld a, (OutlineColor)
			out ($98),a				; First dot white.

			ld a, c
			out ($98),a				; Next dot color cursor or background.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.
			ld c, a					; C = background. E = Sprite color.

			ld d, (ix+0)				; Reads the left byte sprite pattern.
			ld b, 8

.SMSX1DotLLoop:		rl d
			ld a, c
			jr nc, .SMSX1DotLJ1
			ld a, e

.SMSX1DotLJ1:		out ($98), a
			djnz .SMSX1DotLLoop

			ld d, (ix+16)				; Reads the right byte sprite pattern.
			ld b, 8

.SMSX1DotRLoop:		rl d
			ld a, c
			jr nc, .SMSX1DotRJ1
			ld a, e

.SMSX1DotRJ1:		out ($98), a
			djnz .SMSX1DotRLoop

			pop bc
			pop hl
			inc ix
			inc h

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.

			ld a,c
			out ($98),a				; Next dot color cursor or background.

			ld a, (OutlineColor)
			out ($98),a				; Next dot white.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black (sprite separator).

			djnz .SMSX1LineLoop

.SpriteBottom:		push hl					; It draws the botton enclosure of a sprite.
			call @VPOKEPOS

			ld a, (OutlineColor)
			out ($98),a				; First dot white.
			
			ld a,c
			out ($98),a				; Next dot cursor or background.

			ld b, 16 + 2

			ld a, (ScreenBackgroundColor)
.L3:			out ($98),a
			djnz .L3

			ld a,c
			out ($98),a

			ld a, (OutlineColor)
			out ($98),a

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Sprite separator.

			pop hl
			inc h
			push hl
			call @VPOKEPOS

			ld a, (OutlineColor)
			out ($98),a				; First dot white.

			ld b, 16 + 4

			ld a,c
.L4:			out ($98),a
			djnz .L4

			ld a, (OutlineColor)
			out ($98),a

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Sprite separator.

			pop hl
			inc h

			push hl
			call @VPOKEPOS
			pop hl

			ld b, 16 + 6

			ld a, (OutlineColor)
.L5:			out ($98),a
			djnz .L5

			ld a, (ScreenBackgroundColor)		; //// why it overpset one pixel to the right?
			out ($98),a
								; Vertical separator between selector's rows.
.S16:			push hl
			ld hl,(SelectorCurrentObjectNumber)
			ld c, 10
			call @DIV16_8
			pop hl
			and a					; Remainder = 0.
			jr nz, .EI
								; One time per row.
			inc h
			ld l,0
			ld c, 15*16-1
			ld b, 2
			ld a, (ScreenBackgroundColor)
			call @BLOCKFILL

.EI:			ei
			and a
			ret

.TileVisualOverflow:	scf
			ret

.SpriteMSX2:		di

			ld b, 16

.SMSX2LineLoop:		push hl
			call @VPOKEPOS				; Sets the VDP on bitmap X/Y = hl.
			push bc

			ld a, (OutlineColor)
			out ($98),a				; First dot white.

			ld a, c
			out ($98),a				; Next dot color cursor or background.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.
			ld c, a					; C = background. E = Sprite color.

			ld a, (ix+32)				; Reads the color and EC CC IC attribute.

			bit 7, a
			jr nz, .DonShowThisLine

			call _EditorPickColor
			ld e, a

			ld d, (ix+0)				; Reads the left byte sprite pattern.
			ld b, 8

.SMSX2DotLLoop:		rl d
			ld a, c
			jr nc, .SMSX2DotLJ1
			ld a, e

.SMSX2DotLJ1:		out ($98), a
			djnz .SMSX2DotLLoop

			ld d, (ix+16)				; Reads the right byte sprite pattern.
			ld b, 8

.SMSX2DotRLoop:		rl d
			ld a, c
			jr nc, .SMSX2DotRJ1
			ld a, e

.SMSX2DotRJ1:		out ($98), a
			djnz .SMSX2DotRLoop

.SMSX2NextLine:		pop bc
			pop hl
			inc ix
			inc h

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black.

			ld a,c
			out ($98),a				; Next dot color cursor or background.

			ld a, (OutlineColor)
			out ($98),a				; Next dot white.

			ld a, (ScreenBackgroundColor)
			out ($98),a				; Next dot black (sprite separator).

			djnz .SMSX2LineLoop

			jp .SpriteBottom

.DonShowThisLine:	ld b, 16
			ld a, c

.SMSX2EmptyDotLLoop:	out ($98), a
			djnz .SMSX2EmptyDotLLoop
			jr .SMSX2NextLine

.OutOfTiles:		pop hl
			pop bc

			xor a
			cp h
			ld a, $81				; Both out of sprites & out of visual area.
			ret c
			ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator+16*4-10
			cp l
			ld a, $81
			ret c

			ld h,l
			ld l,b					; hl = top/left where to render the sprite.

			dec l
			dec l
			dec l
			dec h
			dec h
			dec h

			ld b, 16 + 7
			ld c, b
			dec c

			ld a, (ScreenBackgroundColor)

			call @BLOCKFILL

			scf
			ld a,$80				; A bit 7 = 1 Out of sprites.
			ret






_GetsBestSpritePuzzlerXY:ld a, (EditorCurrentlyInUse)
			and a

			ld hl, PuzzlerBottonRightOnSelector16
			ret z
			ld hl, PuzzlerBottonRightOnEditor16
			ret






_RenderSpritePuzzler:	call _GetsBestSpritePuzzlerXY		; out HL = best home position.

			ld c, 64

			push hl
			push bc

			dec h
			dec h
			dec l
			dec l
			inc c
			inc c
			inc c
			inc c
			ld b, c

			ld a, (OutlineSecondaryColor)		; Border.
			call @SQUARE

			pop bc
			pop hl
			push hl
			push bc

			dec h
			dec l
			inc c
			inc c
			ld b, c

			ld a, (ScreenBackgroundColor)		; Inner Border.
			call @SQUARE

			pop bc
			pop hl

			push bc
			push hl
			ld a, (ScreenBackgroundColor)
			ld b, c
			call @BLOCKFILL				; Puzzler background.

			ld a, (EditorCurrentlyInUse)
			and a
			jr nz, .NoPrintHelpStr

			ld a, (OutlineBackGroundColor)
			ld (RenderForeColor),a
			ld a, (ScreenBackgroundColor)
			ld (RenderBackColor),a
			pop de
			ld a, d
			pop bc
			add a, c
			add a, 4
			ld d, a

			ld hl, .PuzHlpStr
			call @STRDRAWZ				; Print help string.
			jr .PrintedHelpStr

.NoPrintHelpStr:	pop de
			pop bc

.PrintedHelpStr:	ld hl, PuzzlerIndexationBuffer		; The puzzler is in use, must redraw the sprites.
			xor a
			ld b,16

.PuzRenderLoop:		push af
			push bc
			push hl

			call _RenderPuzSprite

			pop hl
			pop bc
			pop af

			inc a
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			djnz .PuzRenderLoop
			ret

.PuzHlpStr:		DB "c<L>r.",0






_RenderPuzSprite:	push hl					; in hl = address of current sprite in the puzzler array.
			pop ix					; in a = sprite position. (0 - 15).
			ld e, a
			ld d, 0

			ld a,(ix+0)
			or (ix+1)
			or (ix+2)
			or (ix+3)
			jr z, .UnusedSpritePlane		; If puzzler's sprite is not in use, it must set up Y = 208?, make the sprite to dissapear.

			ld a, (ix+4)				; If the format isn't the same as the Selector, it escapes. It can't draw mixing differents sprites sizes.
			ld b, a
			ld a, (SelectorCurrentFormat)
			cp b
			jr nz, .UnusedSpritePlane

			push de
			ld e,(ix+0)
			ld d,(ix+1)
			ld l,(ix+2)
			ld h,(ix+3)				; Reads the USERAREA address of the sprite.

			ld a, (PuzzlerForceRenderAll)
			and a
			jr nz, .NoBeingEditing

			ld a, (EditorCurrentlyInUse)
			and a
			jr z, .NoBeingEditing

			ld bc,(EditorCursorAddrLow)		; Checks if it is currently being edited.
			ex de,hl
			push hl
			sbc hl, bc
			pop hl
			ex de,hl
			jr nz, .NoBeingEditedThisOne

			ld bc,(EditorCursorAddrHigh)
			push hl
			sbc hl, bc
			pop hl
			jr nz, .NoBeingEditedThisOne
								; This sprite is being edited.
			ld ix, EditorBuffer
			ld a, (EditorCurrentFormat)
			pop hl					; It restores the hl = sprite ordinal number.

			jr .EditorBridge

.NoBeingEditedThisOne:	pop hl					; If is not the one being edited, it does nothing, for saving time.
			ret

.UnusedSpritePlane:	ex de, hl
			add hl, hl
			add hl, hl				; hl = offset for the sprite attribute table.
			ld de, $FA00				; Sprite attribute base address.
			add hl, de

			call @VPOKEPOS

			ld a, 217
			out ($98), a				; Y = 217.

			ei
			ret

.NoBeingEditing:	exx
			ld a, (ix+4)
			call _GETOBJECTSIZE
			ld hl, SelectorBuffer
			call @READ_USERAREA			; Loads in SelectorBuffer the sprite information.
			pop hl					; It restores hl = sprite ordinal number.
			ret c

			ld a,(ix+4)				; Reads the sprite format from the indexator.

.ExternalIN:		ld ix, SelectorBuffer			; Now ix will have the address of the sprite graphics.

.EditorBridge:		push ix
			push hl
			push af
			ld a, (VDPREG8)				; Enable sprites engine.
			and  $FD
			ld b, a
			ld c, 8
			call @WRTVDP
			pop af
			pop hl
			pop ix

			cp FormatID.SpriteMSX1			; HL = sprite ordinal number.
			jp z, .SpriteMSX1
								; Only lefts SpriteMSX1.
			di

			push hl

			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl				; *32.
			ld de, $F000				; BASE address for the sprite pattern.
			add hl, de

			call @VPOKEPOS

			push ix
			pop hl

			ld b, 32

.PatternLoop:		ld a, (hl)
			out ($98), a
			inc hl
			djnz .PatternLoop

			pop hl
			push hl

			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl				; *16.
			ld de, $F800
			add hl, de

			call @VPOKEPOS

			push ix
			pop hl

			ld de, 32
			add hl, de

			ld b, 16

.ColorTableLoop:	ld a, (hl)
			out ($98), a
			inc hl
			djnz .ColorTableLoop

			pop hl
			push hl

			add hl, hl
			add hl, hl				; *4.
			ld de, $FA00
			add hl, de

			call @VPOKEPOS

			call _GetsBestSpritePuzzlerXY
			ld a, (ix + 49)				; It reads the X offset position.
			add a, l
			add a, 32
			ld l, a
			ld a, (ix + 48)				; It reads the Y offset position.
			add a, h
			add a, 32
			ld h, a

			ld a, h
			out ($98), a
			ld a, l
			out ($98), a

			pop hl

			ld a, l
			add a,a
			add a,a					; As sprites is 16x16, it uses *4 pattern indexation.

			out ($98), a				; Set pattern number the same as plane number.

			ei 
			ret

.SpriteMSX1:		di

			push hl

			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl				; *32.
			ld de, $F000				; BASE address for the sprite pattern.
			add hl, de

			call @VPOKEPOS

			push ix
			pop hl

			ld b, 32

.Pattern1Loop:		ld a, (hl)
			out ($98), a
			inc hl
			djnz .Pattern1Loop

			pop hl
			push hl

			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl				; *16.
			ld de, $F800
			add hl, de

			call @VPOKEPOS

			ld a, (ix + 35)				; Reads the color and EC bit (MSX1 format).
			and $8F

			ld b, 16

.Color1TableLoop:	out ($98), a
			inc hl
			djnz .Color1TableLoop

			pop hl
			push hl

			add hl, hl
			add hl, hl				; *4.
			ld de, $FA00
			add hl, de

			call @VPOKEPOS

			call _GetsBestSpritePuzzlerXY
			ld a, (ix + 33)				; It reads the X offset position.
			add a, l
			add a, 32
			ld l, a
			ld a, (ix + 32)				; It reads the Y offset position.
			add a, h
			add a, 32
			ld h, a

			ld a, h
			out ($98), a
			ld a, l
			out ($98), a

			pop hl

			ld a, l
			add a,a
			add a,a					; As sprites is 16x16, it uses *4 pattern indexation.

			out ($98), a				; Set pattern number the same as plane number.

			ei 
			ret






_EditorPickColor:	push af					; In a = color value or palette number.
			ld a, (IsOnPaletteScreenMode)		; MOD (hl).
			and a
			jr nz, .OnPal

			pop af
			ret

.OnPal:			pop af
			and $0F
			push hl
			ld l, a
			rlca
			rlca
			rlca
			rlca
			or l
			pop hl					; It duplicates the palette number like AA BB CC.
			ret






_RunSpriteEditor:	ld a,(EditorCurrentFormat)		; It draws the editor's boxes.
			cp FormatID.SpriteMSX2
			jr nz , .BoxesSprite1
								; Boxes for Sprite2 format.
								; Main box.
			ld hl, 0 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2)
			ld bc, $2444
			ld a, (OutlineSecondaryColor)
			call @SQUARE				; It draws the Editor's box.

			ld hl, 1 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 1)
			ld bc, $2242
			ld a, (ScreenBackgroundColor)
			call @SQUARE

								; Attribute box.
			ld hl, 71 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2)
			ld bc, $2424
			ld a, (OutlineSecondaryColor)
			call @SQUARE

			ld hl, 72 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 1)
			ld bc, $2222
			ld a, (ScreenBackgroundColor)
			call @SQUARE				; It has 3 columns Color box 8x8, EC mark, CC mark, IC mark.

			call .RenderColorPicker

			jr .Redraw

.BoxesSprite1:							; Main box.
			ld hl, 0 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2)
			ld bc, $4444
			ld a, (OutlineSecondaryColor)
			call @SQUARE				; It draws the Editor's box.

			ld hl, 1 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 1)
			ld bc, $4242
			ld a, (ScreenBackgroundColor)
			call @SQUARE

								; Attribute box.
			ld hl, 71 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2)
			ld bc, $0C14
			ld a, (OutlineSecondaryColor)
			call @SQUARE

			ld hl, 72 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 1)
			ld bc, $0A12
			ld a, (ScreenBackgroundColor)
			call @SQUARE				; It has 2 columns Color box 8x8, EC mark.

			call .RenderColorPicker

.Redraw:		call .RenderEditorSprite		; It prints the content of the editor.

			call .RenderAttribContent

			call _RedrawXYBoxes

.SpriteEditorControl:	call .UpgradePuzzler			; On any editing change it must update the sprite being edited if is present in the puzzler.

			call .PrintCursorTileEd

.Inkey:			call @INKEY
			jr c, .Inkey

			call @UPCASE

			push af
			ld bc,(EditorCursorX)
			call .RenderWhatIsPointed
			pop af

			cp 28
			jp z, .Right

			cp 29
			jp z, .Left

			cp 30
			jp z, .Up

			cp 31
			jp z, .Down

			cp 27
			jp z, .Esc				; Escape, back to the tile selector.

			cp 32
			jp z, .Space
			
			cp 13
			jr z, .Return

			cp 'N'
			jp z, .InOutPicker

			cp 9
			jp z, .GoingToMenuAction

			cp 'H'
			jr z, .SLeft
			cp 'J'
			jr z, .SDown
			cp 'U'
			jr z, .SUp
			cp 'K'
			jr z, .SRight

			; Insert more functions here.

			ld b, '0'
			cp '0'
			jr c, .SpriteEditorControl

			cp '9'+1
			jp c, .HitColorDirect

			ld b, 'A'-10
			cp 'A'
			jr c, .SpriteEditorControl

			cp 'F'+1
			jp c, .HitColorDirect

			jr .SpriteEditorControl

.SUp:			call .GetsXYAddr
			ld a, (hl)
			dec a
			cp $BF
			ret z
			ld (hl), a
			jp .Redraw

.SDown:			call .GetsXYAddr
			ld a, (hl)
			inc a
			cp $41
			ret z
			ld (hl), a
			jp .Redraw

.SLeft:			call .GetsXYAddr
			inc hl
			ld a, (hl)
			dec a
			cp $BF
			ret z
			ld (hl), a
			jp .Redraw

.SRight:		call .GetsXYAddr
			inc hl
			ld a, (hl)
			inc a
			cp $41
			ret z
			ld (hl), a
			jp .Redraw

.GetsXYAddr:		ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX2
			jr z, .Spr2
								; It is SpriteMSX1 format.
			ld hl, EditorBuffer + 32
			ret

.Spr2:			LD hl, EditorBuffer + 48
			ret

.Return:		call .EditorDissapear
			jp @EDITORSAVE

.Right:			ld bc,(EditorCursorX)
			ld a,b
			cp $FF
			jr z, .RightPicker
								; Is not in the picker.
			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX2
			ld a, 18
			jr z, .RightSpr2
			ld a, 16

.RightSpr2:		cp c
			jp c, .SpriteEditorControl

			inc c
			ld (EditorCursorX),bc
			jp .SpriteEditorControl

.RightPicker:		inc c
			ld a,c
			and $0F
			ld c,a
			ld (EditorCursorX),bc
			ld (EditorCurrentPickerCursor), a
			jp .SpriteEditorControl

.Left:			ld bc,(EditorCursorX)
			ld a,b
			cp $FF
			jr z, .LeftPicker
								; Is not in the picker.
			ld a,c
			and a
			jp z, .SpriteEditorControl

			dec c
			ld (EditorCursorX),bc
			jp .SpriteEditorControl

.LeftPicker:		dec c
			ld a,c
			and $0F
			ld c,a
			ld (EditorCursorX),bc
			ld (EditorCurrentPickerCursor), a
			jp .SpriteEditorControl

.Down:			ld bc,(EditorCursorX)
			ld a, 15
			cp b
			jr nc, .DownOnTile

			ld a, c
			ld (EditorCurrentPickerCursor), a

			ld bc, $0008

			ld (EditorCursorX),bc
			jp .SpriteEditorControl

.DownOnTile:		ld a, 15
			cp b
			jr z, .DownToPicker

			inc b
			ld (EditorCursorX),bc
			jp .SpriteEditorControl

.DownToPicker:		ld b,$FF
			ld a, (EditorCurrentPickerCursor)
			ld c, a
			ld (EditorCursorX),bc

			jp .SpriteEditorControl
			
.Up:			ld bc,(EditorCursorX)
			ld a, 15
			cp b
			jr nc, .UpOnTile
								; Only left that is on the picker.
			ld a, c
			ld (EditorCurrentPickerCursor), a

			ld bc, $0F08				; In the Middle_X of the tile.
			ld (EditorCursorX),bc
			jp .SpriteEditorControl

.UpOnTile:		ld a, b
			and a
			jr z, .UpToPicker

			dec b
			ld (EditorCursorX),bc
			jp .SpriteEditorControl

.UpToPicker:		ld b, $FF
			ld a, (EditorCurrentPickerCursor)
			ld c, a
			ld (EditorCursorX),bc
			jp .SpriteEditorControl

.InOutPicker:		ld bc,(EditorCursorX)			; Fast way to go in the picker, and gets out.
			ld a, b
			cp $FF
			jr z, .OutPicker
								; Is out from the picker.
			ld (EditorCursorBackUp), bc
			ld b, $FF
			ld a, (EditorCurrentPickerCursor)
			ld c, a
.OutPickerJ1:		ld (EditorCursorX), bc
			jp .SpriteEditorControl

.OutPicker:		ld bc, (EditorCursorBackUp)
			jr .OutPickerJ1

.HitColorDirect:	sub b					; Converts the chart -> binary value.
			ld e, a

.HitColorDirectSpr:	ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX2
			jr z, .HitColorDirectSpr2
								; It is sprite1.
			ld hl, EditorBuffer + 35
			ld a, (hl)
			and $F0
			or e
			ld (hl), a				; Overwrites the color in the color attribute byte.
			jp .Redraw

.HitColorDirectSpr2:	ld hl, EditorBuffer + 32
			
			ld a, (EditorCursorY)
			cp 16
			jp nc, .SpriteEditorControl

			ld c, a
			ld b, 0
			add hl, bc

			ld a, (hl)
			and $F0
			or e
			ld (hl), a				; Overwrites the color in the color line attribute byte.

			jp .Redraw

.Space:			ld bc, (EditorCursorX)			; It is like the primary button hit.

			ld a, 15
			cp b
			jp c, .HitOnPicker			; Because Y only can be 0-15 and $FF.
			cp c
			jp c, .HitOnAttribsChannel
								; THE USER HITs ON THE SPRITE DRAWING!!!.
			ld hl, EditorBuffer
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a					; hl = hl + b.

			ld a, c
			cp 8
			jr c, .SprLeftSide
								; Sprite pattern right side.
			ld a, c
			sub 8
			ld c, a					; Xbit = Xbit - 8.

			ld de, 16
			add hl, de

.SprLeftSide:		ld b,c
			inc b

			ld c,0
			scf

.SprBit:		rr c 
			djnz .SprBit
			
			ld a,c
			cpl
			ld b,a

			ld a, (hl)				; Checks if the bit is currently 0 or 1.
			and c
			jr z, .SprBitSet
								; .SprBitReset.
			ld a,(hl)
			and b
			ld (hl),a				; Turns bit pattern 1 in 0.
			jr .SprBitDrw			

.SprBitSet:		ld a,(hl)
			or c					; Turns bit pattern 0 in 1.
			ld (hl),a

.SprBitDrw:		push af					; Redraws the object where is the cursor.
			ld bc,(EditorCursorX)
			call .RenderWhatIsPointed
			pop af

			jp .SpriteEditorControl			; Returns the control to the keyboard.

.HitOnPicker:		ld a,c
			ld (EditorCurrentLastPickedColor),a

			jp .SpriteEditorControl

.HitOnAttribsChannel:	ld a, c
			cp 16
			jr z, .HitOnAttColor
			cp 17
			jr z, .HitOnAttEC
			cp 18
			jr z, .HitOnAttCC
			cp 19
			jr z, .HitOnAttIC

.HitOnAttEC:		ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX1
			jr z, .HitOnAttECMSX1
								; EC att on SpriteMSX2.
			ld hl, EditorBuffer + 32
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a					; hl = hl + b.

.ECDoChange:		ld a, (hl)
			bit 7, a
			jr z, .ECWasZeroMSX2

			and $7F
			ld (hl), a
			jp .Redraw

.ECWasZeroMSX2:		or $80
			ld (hl), a
			jp .Redraw

.HitOnAttECMSX1:	ld hl, EditorBuffer + 35		
			jr .ECDoChange

.HitOnAttCC:		ld hl, EditorBuffer + 32
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a					; hl = hl + b.

			ld a, (hl)
			bit 6, a
			jr z, .CCWasZero

			and $BF
			ld (hl), a
			jp .Redraw

.CCWasZero:		or $40
			ld (hl), a
			jp .Redraw

.HitOnAttIC:		ld hl, EditorBuffer + 32
			ld a, b
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a					; hl = hl + b.

			ld a, (hl)
			bit 5, a
			jr z, .ICWasZero

			and $DF
			ld (hl), a
			jp .Redraw

.ICWasZero:		or $20
			ld (hl), a
			jp .Redraw

.HitOnAttColor:		ld a, (EditorCurrentLastPickedColor)
			and $0F
			ld e, a

			jp .HitColorDirectSpr

.RenderAttribContent:	ld hl, 73 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 0)

			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX1
			jr z, .AttSpriteMSX1
								; It is MSX2 format.
			ld b, 16			
			ld ix, EditorBuffer + 32

.AttSpr2RowLoop:	push bc
			call .AttSpr2Row
			pop bc
			inc ix
			djnz .AttSpr2RowLoop

			ret

.AttSpriteMSX1:		ld b, 8

.AttSpr1RowYLoop:	push hl
			call @VPOKEPOS

			ld ix, EditorBuffer + 35
			ld a, (ix + 0)
			call _EditorPickColor

			push bc

			ld b, 8

.AttSpr1ColorDotLoop:	out ($98), a
			djnz .AttSpr1ColorDotLoop

			pop bc

			ld a, (OutlineSecondaryColor)		; It draws the EC status.
			ld d, a

			ld a, (ScreenBackgroundColor)
			ld e, a

			ld a, (ix+0)
			rla
			jr nc, .ECNoMark1

			ld a, b
			cp 1
			jr z, .ECNoMark1

			cp 8
			jr nz, .ECCont1

.ECNoMark1:		ld d, e

.ECCont1:		ld a, e
			out ($98), a
			ld a, d
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a
			ld a, e
			out ($98), a

			pop hl
			inc h
			djnz .AttSpr1RowYLoop

			ei
			ret

.AttSpr2Row:		ld b, 2

.AttSpr2RowYLoop:	push hl
			call @VPOKEPOS

			ld a, (ix+0)				; It draws the color.
			call _EditorPickColor

			push bc					; It saves the Y position range 8-1.

			ld b, 8

.AttSpr2ColorDotLoop:	out ($98), a
			djnz .AttSpr2ColorDotLoop

			pop bc					; Restores Y 8-1 value.

			ld a, (OutlineSecondaryColor)		; It draws the EC status.
			ld d, a

			ld a, (ScreenBackgroundColor)
			ld e, a

			ld a, (ix+0)
			rla
			jr nc, .ECNoMark

			ld a, b

			cp 2
			jr nz, .ECCont

.ECNoMark:		ld d, e

.ECCont:		ld a, e
			out ($98), a
			ld a, d
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a
			ld a, e
			out ($98), a

			ld a, (OutlineSecondaryColor)		; It draws the CC status.
			ld d, a

			ld a, (ScreenBackgroundColor)
			ld e, a

			ld a, (ix+0)
			rla
			rla
			jr nc, .CCNoMark

			ld a, b

			cp 2
			jr nz, .CCCont

.CCNoMark:		ld d, e

.CCCont:		ld a, e
			out ($98), a
			ld a, d
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a
			ld a, e
			out ($98), a

			ld a, (OutlineSecondaryColor)		; It draws the IC status.
			ld d, a

			ld a, (ScreenBackgroundColor)
			ld e, a

			ld a, (ix+0)
			and $20
			jr z, .ICNoMark

			ld a, b

			cp 2
			jr nz, .ICCont

.ICNoMark:		ld d, e

.ICCont:		ld a, e
			out ($98), a
			ld a, d
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a nop
			out ($98), a
			ld a, e
			out ($98), a

			pop hl
			inc h
			dec b
			jp nz, .AttSpr2RowYLoop

			ei
			ret

.RenderColorPicker:	ld l,0					; Render the palette picker at the botton.
			ld h,184
			ld a, (OutlineSecondaryColor)
			ld c, a
			ld b, 0
			call @HLINE

			ld iy, RunTileEditor.Pal16
			jp @FarCallToPage1

.RenderEditorSprite:	ld hl, 2 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)
			ld ix, EditorBuffer
			ld b,16

.RenderEditorSpriteRowLoop:
			push bc
			call .RenderEditorSpriteRow
			pop bc
			inc ix
			djnz .RenderEditorSpriteRowLoop
			ret

.RenderEditorSpriteRow:	ld a,(EditorCurrentFormat)		; in ix = EditorBuffer current data address. in/out hl = top/left visual position.
			cp FormatID.SpriteMSX2
			jr z, .RenderEditorSprite2Row
								; Render for MSX1 format.
			ld iy, EditorBuffer
			ld a, (iy + 35)
			call _EditorPickColor
			ld d, a					; D = color for ONEs.

			ld a, (ScreenBackgroundColor)
			ld e, a					; E = color for ZEROEs.

			ld b, 4

.EdSpr1YBucle:		push bc
			push hl
			call @VPOKEPOS
			pop hl

			ld c, (ix + 0)				; LEFT HALF.

			ld b,8

.EdSpr1BitBucle1:	rl c
			ld a,d
			jr c, .EdSpr1BitOnes1
			ld a,e

.EdSpr1BitOnes1:	out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a

			djnz .EdSpr1BitBucle1

			ld c, (ix + 16)				; RIGHT HALF.

			ld b,8

.EdSpr1BitBucle2:	rl c
			ld a,d
			jr c, .EdSpr1BitOnes2
			ld a,e

.EdSpr1BitOnes2:	out ($98),a  nop
			out ($98),a  nop
			out ($98),a  nop
			out ($98),a

			djnz .EdSpr1BitBucle2

			pop bc
			inc h
			djnz .EdSpr1YBucle

			ei
			ret

.RenderEditorSprite2Row:ld a, (ix + 32)				; Reads the color plus EC CC IC.
			call _EditorPickColor
			ld d, a					; D = color for ONEs.

			ld a, (ScreenBackgroundColor)
			ld e, a					; E = color for ZEROEs.

			ld b, 2

.EdSpr2YBucle:		push bc
			push hl
			call @VPOKEPOS
			pop hl

			ld a, (ix + 32)
			rla
			jr c, .EdSpr2IsEC

			ld b, 32				; It sets a margin when EC is 0.
			ld a, e

.EdSpr2LeftMargin:	out ($98), a
			djnz .EdSpr2LeftMargin

.EdSpr2IsEC:		ld c, (ix + 0)				; LEFT HALF.

			ld b,8

.EdSpr2BitBucle1:	rl c
			ld a,d
			jr c, .EdSpr2BitOnes1
			ld a,e

.EdSpr2BitOnes1:	out ($98),a  nop
			out ($98),a

			djnz .EdSpr2BitBucle1

			ld c, (ix + 16)				; RIGHT HALF.

			ld b,8

.EdSpr2BitBucle2:	rl c
			ld a,d
			jr c, .EdSpr2BitOnes2
			ld a,e

.EdSpr2BitOnes2:	out ($98),a  nop
			out ($98),a

			djnz .EdSpr2BitBucle2

			ld a, (ix + 32)
			rla
			jr nc, .EdSpr2IsNotEC

			ld b, 32				; It sets a right margin when EC is 1.
			ld a, e

.EdSpr2RightMargin:	out ($98), a
			djnz .EdSpr2RightMargin

.EdSpr2IsNotEC:		pop bc
			inc h
			djnz .EdSpr2YBucle

			ei
			ret

.RenderWhatIsPointed:	ld a,b						; in b = cursorY, c = cursorX.
			cp $FF
			jp z, .RenderColorPicker

			ld a, 15
			cp b
			ret c						; CursorY can be 0-15 and $FF only.

			ld a, 15
			cp c
			jr nc, .OnTile					; CursorX can be 0-15 for the tile, 16 for the color, 17 for the EC, 18 & 19 for CC & IC (only Spr2 format).

			jp .RenderAttribContent

.OnTile:		ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX1
			jr z, .PointedOnTileMSX1
									; Tile is spriteMSX2.
			ld hl, 2 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)
			ld ix, EditorBuffer
			ld c,b
			xor a
			ld b,16

.PointingOnTileRowLoop:	push af						; As it is MSX2 format and the cursor is bigger than the sprite dot, it must redraw the adyacent rows and/or the inner border of the editor's box.
			push bc
			push hl

			push af
			ld a, c
			and a
			jr z, .RefreshsBorders
			cp 15
			jr z, .RefreshsBorders
			ld a, (EditorCursorX)
			and a
			jr z, .RefreshsBorders
			cp 15
			jr z, .RefreshsBorders
			pop af

			dec a
			cp c
			jr z, .RenderAdyacentRow
			inc a
			inc a
			cp c
			jr z, .RenderAdyacentRow
			dec a
			cp c
			call z, .RenderEditorSpriteRow
			jr .NextRow

.RefreshsBorders:	ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX2
			jr z, .RenderM2Border

			push hl
			ld hl, 16 + 1 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 1)
			ld bc, $2222
			ld a, (ScreenBackgroundColor)
			call @SQUARE
			pop hl
			pop af
			jr .RenderAdyacentRow		

.RenderM2Border:	push hl
			ld hl, 1 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 1)
			ld bc, $2242
			ld a, (ScreenBackgroundColor)
			call @SQUARE
			pop hl
			pop af
.RenderAdyacentRow:	call .RenderEditorSpriteRow

.NextRow:		pop hl
			inc h
			inc h
			pop bc
			inc ix
			pop af
			inc a
			djnz .PointingOnTileRowLoop
			ret

.PointedOnTileMSX1:	ld hl, 2 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)
			ld ix, EditorBuffer
			ld c,b
			xor a
			ld b,16

.PointingOnTileRowLoop1:push af
			push bc
			push hl
			cp c
			call z, .RenderEditorSpriteRow 
			pop hl
			ld a, h
			add a, 4
			ld h, a
			pop bc
			inc ix
			pop af
			inc a
			djnz .PointingOnTileRowLoop1
			ret

.PrintCursorTileEd:	ld a,(EditorCursorY)
			cp $FF						; It Prints the cursor.
			ld b, a
			jp z, .CsOnPicker

			ld a, 15
			cp b
			ret c						; CursorY can be 0-15 and $FF only.

			ld a,(EditorCursorX)
			ld c, a
			ld a, 15
			cp c
			jr nc, .CsOnTile				; CursorX can be 0-15 for the tile, 16 for color att, 17 EC, 18 & 19 are CC & IC (only on spr2).

			ld a, 19
			cp c
			ret c

.CsOnAttribs:		ld hl, 73 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14)

			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX1
			jr z, .CsOnAttSpr1
									; CsOnAttSpr2.
			ld a,(EditorCursorY)
			add a,a
			add a, h					;
			ld h, a

			ld a,(EditorCursorX)
			sub 16
			add a,a
			add a,a
			add a,a
			add a, l
			ld l, a

			call @VPOKEPOS
			ld b, 4

.PrintCsOnAtt2Loop:	ld a, (OutlineCursorColor)
			out ($98), a
			ld a, (ScreenBackgroundColor)
			out ($98), a
			djnz .PrintCsOnAtt2Loop

			ei
			ret

.CsOnAttSpr1:		ld a,(EditorCursorX)
			cp 16
			jr z, .PrintCsOnAttMSX1
			cp 17
			ret nz

.PrintCsOnAttMSX1:	ld a,(EditorCursorX)
			sub 16
			add a,a
			add a,a
			add a,a
			add a, l
			ld l, a

			push hl
			ld bc, $0808
			ld a, (OutlineCursorColor)
			call @SQUARE
			pop hl

			inc h
			inc l
			ld bc, $0606
			ld a, (ScreenBackgroundColor)
			jp @SQUARE

.CsOnTile:		ld hl, 3 + 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 + 1)
			
			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX2
			jr z, .CsOnTileSpr2
									; CsOnTileSpr1.
			ld a,(EditorCursorX)
			add a,a
			add a,a
			add a,l
			dec a
			ld l,a
			ld a,(EditorCursorY)
			add a,a
			add a,a
			add a,h
			dec a
			ld h,a
			inc h
			inc l
			push hl
			call @VPOKEPOS
			ld a, (ScreenBackgroundColor)
			out ($98), a
			pop hl
			dec h
			dec l
			ld bc, $0404
			ld a, (OutlineCursorColor)
			jp @SQUARE

.CsOnTileSpr2:		ld a,(EditorCursorY)
			push hl
			ld hl, EditorBuffer+32
			add a, l
			ld l, a
			ld a, h
			adc a, 0
			ld h, a
			ld a, (hl)
			pop hl
			rla
			jr c, .EC

			ld a, l
			add a,32
			ld l, a

.EC:			ld a,(EditorCursorX)
			add a,a
			add a,l
			dec a
			ld l,a
			ld a,(EditorCursorY)
			add a,a
			add a,h
			dec a
			ld h,a
			push hl
			call @VPOKEPOS
			ld a, (ScreenBackgroundColor)
			out ($98), a
			pop hl
			dec h
			dec l
			ld bc, $0404
			ld a, (OutlineCursorColor)
			jp @SQUARE

.CsOnPicker:		ld a,(EditorCursorX)
			and $0F
			add a,a
			add a,a
			add a,a
			add a,a
			add a,1
			ld l,a
			ld h,185 + 1
			ld bc,$100E
			ld a, (OutlineCursorColor)
			push hl
			call @SQUARE
			pop hl
			inc h
			inc l
			ld bc,$0E0C
			ld a, (ScreenBackgroundColor)
			jp @SQUARE

.Esc:			ld hl, MsgBoxCheckValues
			ld (hl), $FF
			inc hl
			ld (hl), 0
			ld ix, BoxSureCancelEdit
			ld iy, MSGBOX
			call @FarCallToPage1

			call .EditorDissapear

			ld a, $FF
			ld (PuzzlerForceRenderAll), a
			call _RenderSpritePuzzler		; It redraws the puzzler because with some formats it moves to another place when editing.
			xor a
			ld (PuzzlerForceRenderAll), a

			ld a, (MsgBoxCheckValues)
			and a
			ret z
			jp _RunSpriteEditor

.EditorDissapear:	ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2
			jp @CLSLP

.UpgradePuzzler:	ld hl, PuzzlerIndexationBuffer		; The puzzler is in use, must redraw the tiles.
			xor a
			ld b,16

.PuzRenderLoop:		push af
			push bc
			push hl

			call _RenderPuzSprite

			pop hl
			pop bc
			pop af

			inc a
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			djnz .PuzRenderLoop
			ret

.GoingToMenuAction:	ld ix, ActionMenu1Data
			ld iy, MENUPOPUP
			call @FarCallToPage1

			jr c, .ActionMnuEsc

			and a
			jr z, .XMirror

			dec a
			jp z, .YMirror

			dec a
			jp z, .Rotate

			dec a
			jp z, .ShiftLeft

			dec a
			jp z, .ShiftRight

			dec a
			jp z, .ShiftUp

			dec a
			jp z, .ShiftDown

			jr .EscDo

.ActionMnuEsc:		and a
			jp nz, .ActionMnuEscJ1

.EscDo:			ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 14 - 2
			call @CLSLP

			ld a, $FF
			ld (PuzzlerForceRenderAll), a
			call _RenderSpritePuzzler		; It redraws the puzzler because with some formats it moves to another place when editing.
			xor a
			ld (PuzzlerForceRenderAll), a

			jp _RunSpriteEditor

.ActionMnuEscJ1:	cp $01
			jr z, .GoingToMenuAction2

			jp .GoingToMenuAction
	
.GoingToMenuAction2:	ld ix, ActionMenu2SprData
			ld iy, MENUPOPUP
			call @FarCallToPage1

			jr c, .Action2MnuEsc		

			and a
			jp z, .Clear

			dec a
			jp z, .Fill

			dec a
			jp z, .PatternNot

			jr .EscDo

.Action2MnuEsc:		and a
			jr z, .EscDo

			cp $FF
			jr z, .GoingToMenuAction

			jp .GoingToMenuAction2

.XMirror:		ld hl, EditorBuffer
			ld de, EditorBuffer + 16
			ld b,16

.XMYLoop:		push bc

			ld b, 8

			ld a,(hl)
			
.XMXLoop:		rra
			rl c
			djnz .XMXLoop

			ld a, (de)
			ld b, a
			ld a, c
			ld (de),a
			ld a, b

			ld b, 8

.XMX2Loop:		rra
			rl c
			djnz .XMX2Loop

			ld (hl), c

			pop bc
			inc hl
			inc de
			djnz .XMYLoop

.RedrawAndDoMenu1:	call .RenderColorPicker

			call .RenderEditorSprite

			call .RenderAttribContent

			call .UpgradePuzzler

			jp .GoingToMenuAction

.YMirror:		ld hl, EditorBuffer
			ld de, EditorBuffer + 16

			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX1
			ld b, 2
			jr z, .YMChLoop
			ld b, 3

.YMChLoop:		push de
			push hl
			push bc

			ld b,8

.YMYLoop:		dec de
			ld c,(hl)
			ld a,(de)
			ld (hl),a
			ld a,c
			ld (de),a
			inc hl
			djnz .YMYLoop

			pop bc
			pop hl
			pop de

			ld a,16
			add a,l
			ld l,a
			ld a,h
			adc a,0
			ld h,a

			ld a,16
			add a,e
			ld e,a
			ld a,d
			adc a,0
			ld d,a

			djnz .YMChLoop

			jr .RedrawAndDoMenu1

.ShiftRight:		ld hl, EditorBuffer
			ld de, EditorBuffer+16
			ld b,16

.SRYLoop:		ld a,(hl)
			and a
			rra
			ld (hl),a
			ld a,(de)
			rra
			ld (de),a

			inc hl
			inc de

			djnz .SRYLoop

			jp .RedrawAndDoMenu1

.ShiftLeft:		ld hl, EditorBuffer+16
			ld de, EditorBuffer
			ld b,16

.SLYLoop:		ld a,(hl)
			and a
			rla
			ld (hl),a
			ld a,(de)
			rla
			ld (de),a

			inc hl
			inc de

			djnz .SLYLoop

			jp .RedrawAndDoMenu1

.ShiftUp:		ld hl, EditorBuffer+1
			ld de, EditorBuffer
			ld bc, 31

			ldir

			ld hl, EditorBuffer+15
			ld (hl),0

			ld hl, EditorBuffer+31
			ld (hl),0

			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX1
			jp z, .RedrawAndDoMenu1

			ld hl, EditorBuffer+32+1
			ld de, EditorBuffer+32
			ld bc, 15

			ldir

			ld hl, EditorBuffer+47
			ld (hl),0
			
			jp .RedrawAndDoMenu1

.ShiftDown:		ld hl, EditorBuffer+30
			ld de, EditorBuffer+31
			ld bc, 31

			lddr

			ld hl, EditorBuffer+0
			ld (hl),0

			ld hl, EditorBuffer+16
			ld (hl),0

			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX1
			jp z, .RedrawAndDoMenu1

			ld hl, EditorBuffer+46
			ld de, EditorBuffer+47
			ld bc, 15

			lddr

			ld hl, EditorBuffer+32
			ld (hl),0

			jp .RedrawAndDoMenu1

.Rotate:		ld de, UserAreaCpyBuffer
			ld hl, EditorBuffer
			ld bc, 32
			ldir

			ld hl, UserAreaCpyBuffer+31
			ld de, EditorBuffer

			ld c,1					; Sets the bit index.
			ld b,16

.RTXLoop:		ld a, b
			cp 8
			jr nz, .NoLeft

			ld a, l
			sub 16
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a					; Set up left side of the pattern.
			ld c, 1					; Resets the bit index.

.NoLeft:		push bc
			push hl

			ld b,16

.RTYLoop:		push bc
			ld a,(hl)
			dec hl
			ld b,c

.RTFeedBitLoop:		rra
			djnz .RTFeedBitLoop

			exx
			rr d
			rr e
			exx
			pop bc

			djnz .RTYLoop

			exx
			ld a,d
			exx
			ld (de),a
			ld hl, 16
			add hl, de
			exx
			ld a,e
			exx
			ld (hl),a

			inc de

			pop hl
			pop bc			
			inc c
			
			djnz .RTXLoop

			jp .RedrawAndDoMenu1

.Clear:			ld hl, EditorBuffer
			ld de, EditorBuffer+1
			ld bc, 31
			ld (hl),0
			ldir

			inc hl

			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX1
			jr z, .ClearSpr1

			ld a,(EditorCurrentLastPickedColor)
			and $0F
			ld (hl), a
			ld e,l
			ld d,h
			inc de
			ld bc, 15
			ldir		

			jr .RedrawAndDoMenu2

.ClearSpr1:		inc hl
			inc hl
			inc hl
			ld a,(EditorCurrentLastPickedColor)
			and $0F
			ld (hl),a

			jr .RedrawAndDoMenu2

.Fill:			ld hl, EditorBuffer
			ld de, EditorBuffer+1
			ld bc, 31
			ld (hl),$FF
			ldir

			inc hl

			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX1
			jr z, .ClearSpr1

			ld a,(EditorCurrentLastPickedColor)
			and $0F
			ld (hl),a
			ld e,l
			ld d,h
			inc de
			ld bc, 15
			ldir		

			jr .RedrawAndDoMenu2

.PatternNot:		ld hl, EditorBuffer
			ld b, 32

.PNotLoop:		ld a,(hl)
			cpl
			ld (hl),a
			inc hl
			djnz .PNotLoop

.RedrawAndDoMenu2:	call .RenderColorPicker

			call .RenderEditorSprite

			call .RenderAttribContent

			call .UpgradePuzzler

			jp .GoingToMenuAction2






_RedrawXYBoxes:		ld hl, 110 + 1 + (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10 + 1) * 256
			ld bc, $182F
			ld a, (MenuForeColor)
			ld (RenderForeColor), a
			ld a, (MenuBackGroundColor)
			ld (RenderBackColor), a

			call @BLOCKFILL

			ld hl, 110 + (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10) * 256
			ld bc, $1930
			ld a, (MenuBorderColor)
			call @SQUARE

			ld de, 110 + 4 + (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10 + 4) * 256
			ld hl, .XStr
			call @STRDRAWZ

			ld de, 110 + 4 + (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10 + 4 + 10) * 256
			ld hl, .YStr
			call @STRDRAWZ

			ld ix, EditorBuffer

			ld a,(EditorCurrentFormat)
			cp FormatID.SpriteMSX2
			jr z, .Spr2
								; It is SpriteMSX1 format.
			ld c, (IX + 33)
			ld b, (IX + 32)

			jr .Cont

.Spr2:			ld c, (IX + 49)
			ld b, (IX + 48)

.Cont:			push bc					; B = Ypos , C = Xpos.

			ld a, c
			ld hl, 0
			ld d, 0
			rla
			jr nc, .XPositive

			dec hl
			dec d

.XPositive:		ld e, c					; Expand it to 32bits, needed by signedSTR.
			call _SignedSTR

			ld de, 110 + 4 + 6 + 6 + (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10 + 4) * 256
			ld hl, STR_Buffer
			call @STRDRAWZ

			pop bc

			ld a, b
			ld hl, 0
			ld d, 0
			rla
			jr nc, .YPositive

			dec hl
			dec d

.YPositive:		ld e, b					; Expand it to 32bits, needed by signedSTR.
			call _SignedSTR

			ld de, 110 + 4 + 6 + 6 + (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4 * 16 + 4 + 10 + 4 + 10) * 256
			ld hl, STR_Buffer
			jp @STRDRAWZ

.XStr:			DB "X=",0
.YStr:			DB "Y=",0






_PreConfMapVars:	ld (SelectorMapBunchIndex), bc		; Preloaded in the rendering of the map.
								; in BC = bunch index. The reason of this routine is to isolate saving in others variables the results that does another equivalent routine that is a more general purpose.
			push bc					; CF = 1 Error.
			call @GETBUNCH_BASEADDR
			pop bc
			ret c
			
			push hl
			push de
			ld bc, BunchHeader.FormatID
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc

			call @USERAREA_RB
			ld (SelectorMapFormat),a
			pop de
			pop hl
			ret c

			push hl
			push de
			ld bc, BunchHeader.Size
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc

			ld (SelectorMapAddrLow),de
			ld (SelectorMapAddrHigh),hl
			pop de
			pop hl

			ld bc, BunchHeader.Customs + 17
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc

			call @USERAREA_RDW
			ret c

			ld e, c
			ld d, b
			ld (SelectorMapBlocksWidth), de
			ld (SelectorMapBlocksHeight), hl
			ld hl, 0

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr z, .J1
			
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; hlde = hlde * 2.

.J1:			ld (SelectorMapRowSizeLow), de
			ld (SelectorMapRowSizeHigh), hl
			ret






_PreConfIndexatorVars:	ld (SelectorLinkedIndexatorBunchIndex), bc
								; in BC = bunch index. The reason of this routine is to isolate saving in others variables the results that does another equivalent routine that is a more general purpose.
			push bc					; CF = 1 Error.
			call @GETBUNCH_BASEADDR
			pop bc
			ret c

			push bc
			call .Sub
			pop bc
			ret c

			call @GETBUNCH_LINKADDR
			ret c

			call @USERAREA_RDW
			ret c

.Ok:			ld e,c					; in hlbc = bunch size (as readed from its linker).
			ld d,b
			ld bc, BunchHeader.Size
			ex de,hl
			sbc hl,bc
			ex de,hl
			ld bc,0
			sbc hl,bc				; hlde = raw size = bunch size - BunchHeader.Size.

			ld a,(SelectorLinkedIndexatorFormat)
			call _GETOBJECTSIZE			; It outs in BC the object size.

			call @DIV32_16
			ld (SelectorLinkedIndexatorObjectCount),de	; In this program, bunch size is only from 1 up to 65535 objects. so, hl can be ignored.

			ld a,(SelectorLinkedIndexatorFormat)
			ld b, a
			and FormatID.MapIndXTilesDoubler

			ld a, 2
			ld c, 16
			jr z, .J1

			ld a, 4
			ld c, 32

.J1:			ld (SelectorLinkedIndexatorXTilecount), a
			ld a, c
			ld (SelectorLinkedIndexatorWidthVisual), a

			ld a, b
			and FormatID.MapIndYTilesDoubler

			ld a, 2
			ld c, 16
			jr z, .J2

			ld a, 4
			ld c, 32

.J2:			ld (SelectorLinkedIndexatorYTilecount), a
			ld a, c
			ld (SelectorLinkedIndexatorHeightVisual), a
			ret

.Sub:			push hl
			push de

			ld bc, BunchHeader.FormatID
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc

			call @USERAREA_RB
			ld (SelectorLinkedIndexatorFormat),a

			pop de
			pop hl
			ret c

			ld bc, BunchHeader.Size
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc

			ld (SelectorLinkedIndexatorAddrLow),de
			ld (SelectorLinkedIndexatorAddrHigh),hl
			ret






_PreConfIndexatorDirect:ld hl, 0				; Set up variables when is using the MAP linked directly to the tileset (without using tile grouping into metatiles (aka indexation)).
			ld (SelectorLinkedIndexatorBunchIndex), hl
			xor a
			ld (SelectorLinkedIndexatorFormat),a
			ld (SelectorLinkedIndexatorAddrLow), hl
			ld (SelectorLinkedIndexatorAddrHigh), hl

			ld hl, (SelectorLinkedTileObjectCount)
			ld (SelectorLinkedIndexatorObjectCount), hl

			ld a, 1
			ld (SelectorLinkedIndexatorXTilecount), a
			ld (SelectorLinkedIndexatorYTilecount), a

			ld a, (SelectorLinkedTileSize)
			ld (SelectorMetaTileSize), a
			ld (SelectorLinkedIndexatorWidthVisual), a
			ld (SelectorLinkedIndexatorHeightVisual), a
			ret






_PreConfTileVars:	ld (SelectorLinkedTileBunchIndex), bc
								; in BC = bunch index. The reason of this routine is to isolate saving in others variables the results that does another equivalent routine that is a more general purpose.
			push bc					; CF = 1 Error.
			call @GETBUNCH_BASEADDR
			pop bc
			ret c

			push bc
			call .Sub
			pop bc
			ret c

			call @GETBUNCH_LINKADDR
			ret c

			call @USERAREA_RDW
			ret c

.Ok:			ld e,c					; in hlbc = bunch size (as readed from its linker).
			ld d,b
			ld bc, BunchHeader.Size
			ex de,hl
			sbc hl,bc
			ex de,hl
			ld bc,0
			sbc hl,bc				; hlde = raw size = bunch size - BunchHeader.Size.

			ld a,(SelectorLinkedTileFormat)
			call _GETOBJECTSIZE			; It outs in BC the object size.

			call @DIV32_16
			ld (SelectorLinkedTileObjectCount),de	; In this program, bunch size is only from 1 up to 65535 objects. so, hl can be ignored.
			ret

.Sub:			push hl
			push de

			ld bc, BunchHeader.FormatID
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc

			call @USERAREA_RB
			ld (SelectorLinkedTileFormat),a

			ld c,8
			cp FormatID.TileSc2
			jr z, .MTS
			cp FormatID.TileSc5
			jr z, .MTS
			cp FormatID.TileSc8
			jr z, .MTS
			ld c,16
			cp FormatID.TileSc5_16
			jr z, .MTS
			cp FormatID.TileSc8_16
			jr z, .MTS
			ld c,32
			cp FormatID.TileSc5_32			; Unsupported in the console.
			jr z, .MTS
			cp FormatID.TileSc8_32			; Unsupported in the console.
			jr z, .MTS
			ld c, 1

.MTS:			ld a, c
			ld (SelectorLinkedTileSize), a

			pop de
			pop hl
			ret c

			ld bc, BunchHeader.Size
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc

			ld (SelectorLinkedTileBaseAddrLow),de
			ld (SelectorLinkedTileBaseAddrHigh),hl
			ret






_PreAdjustIndexatorVars:ld a, (SelectorLinkedTileSize)		; Added for the support of 16x16 metatiles grouped in 2x2 blocks.
			ld (SelectorMetaTileSize), a		; Needed for setup the correctly the tile size in the tile render routine that belongs to the TileSet console.
			cp 8
			ret z					; If 8x8, nothing to adjust.
			cp 32					; Not supported.
			ret z
								; Tile Size is 16x16.
			ld a, (SelectorLinkedIndexatorWidthVisual)
			add a,a
			ld (SelectorLinkedIndexatorWidthVisual), a

			ld a, (SelectorLinkedIndexatorHeightVisual)
			add a,a
			ld (SelectorLinkedIndexatorHeightVisual), a
			ret






_LoadTileConsoleVariables:
			ld hl, SavedSelectorTileVariables
			ld bc, SavedSelectorTileVariables_End - SavedSelectorTileVariables

			exx
			ld hl, (SelectorBunchStartRawAddrHigh)
			ld de, (SelectorBunchStartRawAddrLow)
			ld bc, BunchHeader.Size - BunchHeader.Status
			ex de, hl
			and a
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc
			exx
			jp @READ_USERAREA






_SaveTileConsoleVariables:
			ld hl, SavedSelectorTileVariables
			ld bc, SavedSelectorTileVariables_End - SavedSelectorTileVariables

			exx
			ld hl, (SelectorBunchStartRawAddrHigh)
			ld de, (SelectorBunchStartRawAddrLow)
			ld bc, BunchHeader.Size - BunchHeader.Status
			ex de, hl
			and a
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc
			exx
			jp @WRITE_USERAREA






_GotoOfSpriteSelector:	ld ix, GotoData
			ld iy, MSGBOX
			call @FarCallToPage1
			jr c, .GotoExiting

			ld hl, MsgBoxBuffer
			call @VAL
			jr nc, .GotoXOk

.GotoErr:		call @BEEP
			jr .GotoExiting

.GotoXOk:		ld hl, (SelectorObjectsCount)		; DE = value inputed.
			sbc hl, de
			jr z, .GotoErr
			jr c, .GotoErr

			ld (SelectorCursorObjectNumber), de

			ld c, 10
			ex de, hl

			push hl
			call @DIV16_8
			pop hl

			ld b, a
			ld a, l
			sub b
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a

			ld (SelectorCurrentScrollTop), hl

.GotoExiting:		ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			call @CLSLP
			jp _SpriteConsole.RenderSpriteSelector






_GotoOfTileSelector:	ld ix, GotoData
			ld iy, MSGBOX
			call @FarCallToPage1
			jr c, .GotoExiting

			ld hl, MsgBoxBuffer
			call @VAL
			jr nc, .GotoXOk

.GotoErr:		call @BEEP
			jr .GotoExiting

.GotoXOk:		ld hl, (SelectorObjectsCount)		; DE = value inputed.
			sbc hl, de
			jr z, .GotoErr
			jr c, .GotoErr

			ld (SelectorCursorObjectNumber), de

			ld iy, GetSelectorTileWidth
			call @FarCallToPage1
			ex de, hl

			push hl
			call @DIV16_8
			pop hl

			ld b, a
			ld a, l
			sub b
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a

			ld (SelectorCurrentScrollTop), hl

.GotoExiting:		ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			call @CLSLP
			ld iy, ConsoleRender.RenderTileSelector
			jp @FarJumpToPage1






_IndexatorConsole:	ld bc, (SelectorBunchIndex)		; It preconfigs special selector variables about current indexator.
			push bc
			call _PreConfIndexatorVars
			pop bc
			ld iy, ConsoleRender.GoMenuBar
			jp c, @FarJumpToPage1
								; Trace down the linking, gets the tile bunch addresses.
			ld iy, GetLinkedBunch			; in BC = bunch index. Out BC = linked bunch index.
			call @FarCallToPage1
			jr nc, .LinkOk

			ld iy, MENUBAR.ErrorLinkage
			call @FarCallToPage1
			ld iy, ConsoleRender.GoMenuBar
			jp @FarJumpToPage1

.LinkOk:		call _PreConfTileVars

			call _PreAdjustIndexatorVars		; If tiles is not the 8x8 standard, it adjusts the indexator variables.

			ld hl, SavedSelectorIndexatorVariables
			ld bc, SavedSelectorIndexatorVariables_End - SavedSelectorIndexatorVariables

			exx
			ld hl, (SelectorLinkedIndexatorAddrHigh)
			ld de, (SelectorLinkedIndexatorAddrLow)
			ld bc, BunchHeader.Size - BunchHeader.Status
			ex de, hl
			and a
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc
			exx
			call @READ_USERAREA

.RedrawALot:		call _PrintsHOTs

.RedrawAll:		ld de, (SelectorLinkedIndexatorScrollTop)

			ld hl, 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)

.RedrawAllLoop:		push hl
			push de
			call .DrawABlock
			pop de
			pop hl

			ld a, (SelectorLinkedIndexatorWidthVisual); It changes the visual position.
			add a,6					; Adds 6 pixels more in width for the enclosure.
			ld b, a

			add a,l
			jr c, .VisualNextRow
			cp 236
			jr nc, .VisualNextRow
			add a,b					; Test if it have enough space left.
			jr c, .VisualNextRow
			cp 236
			jr nc, .VisualNextRow

			sub b
			ld l,a
			jr .VisualOk

.VisualNextRow:		ld l, 0					; CR.

			ld a, (SelectorLinkedIndexatorHeightVisual)
			add a, 6				; Adds 6 pixels more in height for the enclosure.
			ld b, a

			add a, h
			jr c, .MatrixEscape
			cp 172
			jr nc, .MatrixEscape
			add a, b				; Test if it have enough space left.
			jr c, .MatrixEscape
			cp 172
			jr nc, .MatrixEscape
			sub b
			ld h,a

.VisualOk:		inc de					; It increments the object count and checks for the end of the indexator.

			jr .RedrawAllLoop

.MatrixEscape:		ld (SelectorLinkedIndexatorLastObjectDrawn), de
								; Now it needs to redraw the scrollbar.
.ScrollBar:		ld hl, 15*16 + 256*(ConsoleStartLine +BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator + 1)

			ld bc, 256 * (128 + 1) + 8		; It renders the scrollbar border.
			ld a, (OutlineSecondaryColor)		; ScrollBar border color.
			call @SQUARE

			ld de,(SelectorLinkedIndexatorScrollTop); It calculates the scrollbar cursor position.		
			ld hl,0
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x2.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x4.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x8.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x16.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x32.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x64.
			
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; Scale Up 128 times. As we didn't want to work with fractions!!!. And 128px will be the space for scroll bar cursor.

			ld bc,(SelectorLinkedIndexatorObjectCount)
			call @DIV32_16
								; de = cursor Y start offset. hld is zero always as the range would be 0 - 127 as was scaled up 128 times only.
			push de					; Saves the cursor position for later use.
			ld hl, 15*16 + 1 + 256*(ConsoleStartLine+BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator + 2)		; it draws the background space from the start of the scrollbar up to the cursor position - 1.

			ld b,e
			ld a,e
			and a
			ld c, 6
			ld a, (OutlineBackGroundColor)
			CALL nz, @BLOCKFILL
			pop de

			ld hl, 15*16 + 1 + 256*(ConsoleStartLine+BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator + 2)		; it draws the cursor of the scrollbar.
			ld a,e
			add a,h
			ld h,a
			push hl
			push de

			ld de, (SelectorLinkedIndexatorLastObjectDrawn)
			
			ld hl,(SelectorLinkedIndexatorObjectCount); Checks if the ends view is not > than the object count (because here can be unused blocks in the view).
			and a
			sbc hl,de
			jr nc, .NoPassed

			ld de,(SelectorLinkedIndexatorObjectCount)
			dec de

.NoPassed:		ld hl,0
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x2.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x4.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x8.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x16.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x32.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x64.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; Scale Up 128 times. As we didn't want to work with fractions!!!. And 128px will be the space for scroll bar cursor.
			
			ld bc,(SelectorLinkedIndexatorObjectCount)
			call @DIV32_16
								; de = cursor Y end offset. hld is zero always as the range would be 0 - 127 as was scaled up 128 times only.
			pop bc
			ld a,e
			sub c
			jr nz, .CSOk

			inc a					; Minimun cursor size.

.CSOk:			ld b,a
			pop hl
			ld c, 6
			ld a, (OutlineCursorColor)
			push hl
			push bc
			CALL @BLOCKFILL
			pop bc
			pop hl

			ld a,h
			add a,b
			ld h,a

			ld a, 127 + (ConsoleStartLine+BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator + 2)
			sub h
			ld b,a		

			ld a, (OutlineBackGroundColor)
			CALL nz, @BLOCKFILL

.PrintCursor:		ld iy, ConsoleRender.PrintCursorCustom
			ld de, (SelectorLinkedIndexatorCursor)
			call @FarCallToPage1

			ld c, $FF
			call .RedrawWhereCursor

.KeyboardControl:	call @INKEY
			jr c, .KeyboardControl

			call @UPCASE

			push af
			ld c, 0
			call .RedrawWhereCursor
			pop af

			cp 27
			jr z, .Esc
			
			cp 'Q'
			jp z, .FastBS

			cp 9
			jr z, .Tab

			cp 32
			jp z, .Hit

			cp 28
			jr z, .Right

			cp 29
			jp z, .Left

			cp 30
			jp z, .Up

			cp 31
			jp z, .Down
			
			cp '0'
			jr c, .KCJ1

			cp '9'+1
			jp c, .HitHot

.KCJ1:			cp 'G'
			jp z, .Goto

			jr .PrintCursor

.SaveVars:		ld hl, SavedSelectorIndexatorVariables
			ld bc, SavedSelectorIndexatorVariables_End - SavedSelectorIndexatorVariables

			exx
			ld hl, (SelectorLinkedIndexatorAddrHigh)
			ld de, (SelectorLinkedIndexatorAddrLow)
			ld bc, BunchHeader.Size - BunchHeader.Status
			ex de, hl
			and a
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc
			exx
			jp @WRITE_USERAREA

.Esc:			call .SaveVars

			ld iy, ConsoleRender.GoMenuBar
			jp @FarJumpToPage1

.Tab:			call .SaveVars

			ld iy, BunchSelector
			jp @FarJumpToPage1

.Right:			ld hl, (SelectorLinkedIndexatorCursor)
			inc hl
			ld a, l
			or h
			jp z, .PrintCursor

			ld de, (SelectorLinkedIndexatorObjectCount)
			push hl
			sbc hl, de
			pop hl
			jp nc, .PrintCursor

			ld (SelectorLinkedIndexatorCursor), hl
								; Verifies if it is out of view.
			ld de, (SelectorLinkedIndexatorLastObjectDrawn)
			and a
			sbc hl, de
			jp z, .PrintCursor
			jp c, .PrintCursor
								; Is out of the view.
.ScrollDown:		ld hl, (SelectorLinkedIndexatorScrollTop); Moves the SCROLLBAR DOWN, and redraws everything.
			call .VerticalStep
			add hl, bc
			ld (SelectorLinkedIndexatorScrollTop),hl

			ld hl, (SelectorLinkedIndexatorLastObjectDrawn)
			add hl, bc
			ld (SelectorLinkedIndexatorLastObjectDrawn), hl

			ld a, (IsOnPaletteScreenMode)
			and a
			jr nz, .ScDPal

			ld hl, .ScrollDownCommandData16
			ld a, (SelectorLinkedIndexatorHeightVisual)
			cp 16
			jr z, .ScDJ1

			ld hl, .ScrollDownCommandData32
			jr .ScDJ1

.ScDPal:		ld hl, .ScrollDownCommandData16Sc7
			ld a, (SelectorLinkedIndexatorHeightVisual)
			cp 16
			jr z, .ScDJ1

			ld hl, .ScrollDownCommandData32Sc7

.ScDJ1:			call @DoCopy

			call .RedrawLastRow

			jp .ScrollBar

.Left:			ld hl, (SelectorLinkedIndexatorCursor)
			dec hl
			ld a, l
			and h
			cp $FF
			jp z, .PrintCursor

			ld (SelectorLinkedIndexatorCursor), hl
			ld de, (SelectorLinkedIndexatorScrollTop)
			and a
			sbc hl, de
			jp nc, .PrintCursor
								; Is out of the view.
.ScrollUp:		ld hl, (SelectorLinkedIndexatorScrollTop); Moves the SCROLLBAR UP, and redraws everything.
			call .VerticalStep
			sbc hl, bc
			ld (SelectorLinkedIndexatorScrollTop),hl

			ld hl, (SelectorLinkedIndexatorLastObjectDrawn)
			and a
			sbc hl, bc
			ld (SelectorLinkedIndexatorLastObjectDrawn), hl

			ld a, (IsOnPaletteScreenMode)
			and a
			jr nz, .ScUPal

			ld hl, .ScrollUpCommandData16
			ld a, (SelectorLinkedIndexatorHeightVisual)
			cp 16
			jr z, .ScUJ1

			ld hl, .ScrollUpCommandData32
			jr .ScUJ1

.ScUPal:		ld hl, .ScrollUpCommandData16Sc7
			ld a, (SelectorLinkedIndexatorHeightVisual)
			cp 16
			jr z, .ScUJ1

			ld hl, .ScrollUpCommandData32Sc7

.ScUJ1:			call @DoCopy

			call .RedrawFirstRow

			jp .ScrollBar

.VerticalStep:		ld a, (SelectorLinkedIndexatorWidthVisual)
			ld bc, 10
			cp 16
			ret z
			ld bc, 6
			ret

.Up:			ld hl, (SelectorLinkedIndexatorCursor)
			call .VerticalStep
			sbc hl, bc
			jp c, .PrintCursor
			ld (SelectorLinkedIndexatorCursor), hl
			
			ld de, (SelectorLinkedIndexatorScrollTop)
			sbc hl, de
			jp nc, .PrintCursor
			jr .ScrollUp

.Down:			ld hl, (SelectorLinkedIndexatorCursor)
			call .VerticalStep
			add hl, bc

			ld de, (SelectorLinkedIndexatorObjectCount)
			push hl
			sbc hl, de
			pop hl
			jp nc, .PrintCursor

			ld (SelectorLinkedIndexatorCursor), hl

			ld de, (SelectorLinkedIndexatorLastObjectDrawn)
			and a
			sbc hl, de
			jp z, .PrintCursor
			jp c, .PrintCursor			
			jp .ScrollDown

.HitHot:		sub '0'
			add a,a
			ld l, a
			ld h, 0
			ld de, SelectorIndexatorCursorHOT0
			add hl, de
			ld de, (SelectorLinkedIndexatorCursor)
			ld (hl), e
			inc hl
			ld (hl), d

			call _PrintsHOTs

			jp .PrintCursor

.Hit:			ld a, (SelectorLinkedActivityLastDone)
			and a
			jp nz, .SetMap
								; Last activity, the user did a puzzle on the tile bunch.
			ld hl, PuzzlerIndexationBuffer
			ld de, EditorBuffer
								; it build up a block information, extracting it from the puzzler data.
			ld a, (SelectorLinkedIndexatorYTilecount)
			ld b, a

.TileSaveYLoop:		push bc
			push hl

			ld a, (SelectorLinkedIndexatorXTilecount)
			ld b, a

.TileSaveXLoop:		push bc
			inc hl
			inc hl
			inc hl
			inc hl
			inc hl
			ld c, (hl)
			inc hl
			ld b, (hl)
			inc hl
								; BC = tile number.
			ld a, (SelectorLinkedIndexatorFormat)
			and FormatID.MapInd16bitsTileNumber
			jr nz, .TileN16
								; Tiles numbers of 8 bits.
			ld a, c
			ld (de), a
			inc de
			jr .TileSaveExit

.TileN16:		ld a, c
			ld (de), a
			inc de
			ld a, b
			ld (de), a
			inc de

.TileSaveExit:		pop bc
			djnz .TileSaveXLoop

			pop hl
			ld bc, 7*4				; Row size in bytes of the puzzler.
			add hl,bc
			pop bc
			djnz .TileSaveYLoop
								; Now, the block information is in the EditorBuffer.
			ld de, (SelectorLinkedIndexatorCursor)
			ld hl, 0

			ld a, (SelectorLinkedIndexatorFormat)
			call _CalculateRawSize

			ld bc, (SelectorLinkedIndexatorAddrLow)	; hlde = raw address of the cursor object number.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, (SelectorLinkedIndexatorAddrHigh)
			adc hl,bc
								; hlde = in USERAREA address of the cursor block information.
			ld (EditorCursorAddrLow), de
			ld (EditorCursorAddrHigh), hl		; Saves the current address.
			ld a, (SelectorLinkedIndexatorFormat)
			ld (EditorCurrentFormat), a

			call @EDITORSAVE				; It saves permanently the information of the block in the USERAREA.

			ld hl, SelectorIndexatorCursorHOT0
			ld de, (SelectorLinkedIndexatorCursor)		

			ld b, 10

.HotsLoop:		ld a, (hl)
			inc hl
			cp e

			ld a, (hl)
			inc hl
			jr nz, .HotsNoMatch
			cp d
			jr nz, .HotsNoMatch

			call _PrintsHOTs
			jp .PrintCursor

.HotsNoMatch:		djnz .HotsLoop

			jp .PrintCursor

.SetMap:		; //// IF USED RESERVED FOR FUTURE EXPANSION WHEN THE MAP EDITOR GETS DONE!.

			; //// ACTUALY I WILL NOT USE IT, BECAUSE TO HAVE A PALETTE OF 10 PRESELECTED BLOCKS is BETTER.

			; //// BUT LEFT THE LOGIC SPACE FOR OTHERS FUTURE PURPOSES.

			jp .PrintCursor

.RedrawWhereCursor:	ld de, (SelectorLinkedIndexatorScrollTop)	; in C = 0 hide cursor, C <> 0 show cursor.
			
			ld hl, 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)

.RedrawCSLoop:		push bc
			push hl
			push de
			ld a, c
			and a
			jr z, .CursorInvisible

			ld bc, (SelectorLinkedIndexatorCursor)
			ex de,hl
			push hl
			and a
			sbc hl, bc
			pop hl
			ex de,hl
			call z, .DrawABlock
			jr .CScont

.CursorInvisible:	ld bc, (SelectorLinkedIndexatorCursor)
			ex de,hl
			push hl
			and a
			sbc hl, bc
			pop hl
			ex de,hl
			ld a, (OutlineCursorColor)
			push af
			ld a, (ScreenBackgroundColor)
			ld (OutlineCursorColor), a
			call z, .DrawABlock
			pop af
			ld (OutlineCursorColor), a

.CScont:		pop de
			pop hl			
			ld a, (SelectorLinkedIndexatorWidthVisual); It changes the visual position.
			add a,6					; Adds 6 pixels more in width for the enclosure.
			ld b, a

			add a,l
			jr c, .CSVisualNextRow
			cp 236
			jr nc, .CSVisualNextRow
			add a,b					; Test if it have enough space left.
			jr c, .CSVisualNextRow
			cp 236
			jr nc, .CSVisualNextRow

			sub b
			ld l,a
			jr .CSVisualOk

.CSVisualNextRow:	ld l, 0					; CR.

			ld a, (SelectorLinkedIndexatorHeightVisual)
			add a, 6				; Adds 6 pixels more in height for the enclosure.
			ld b, a

			add a, h
			jr c, .CSEscape
			cp 172
			jr nc, .CSEscape
			add a, b				; Test if it have enough space left.
			jr c, .CSEscape
			cp 172
			jr nc, .CSEscape
			sub b
			ld h,a

.CSVisualOk:		inc de					; It increments the object count and checks for the end of the indexator.
			pop bc

			jr .RedrawCSLoop

.CSEscape:		pop bc
			ret

.DrawABlock:		push hl					; in DE = Object number. in HL = visual position.
			ld hl, (SelectorLinkedIndexatorObjectCount)
			and a
			sbc hl,de
			jr z, .OutOfObjects
			jr nc, .ObjectExists

.OutOfObjects:		pop hl					; Objects doesn't exist, it only happens listing metatiles in the indexator console.
			
			ld bc, (SelectorLinkedIndexatorWidthVisual); It reads both, width & height.
			ld a, 4
			add a, c
			ld c, a

			ld a, 4
			add a, b
			ld b, a					; Adds the enclosure space.

			ld a, (ScreenBackgroundColor)		; it blanks the block space, as here is no object to be drawn.
			jp @BLOCKFILL
			
.ObjectExists:		push de					; Saves the object number for later use.

			ld hl, 0
			ld a, (SelectorLinkedIndexatorFormat)
			call _CalculateRawSize
					
			ld bc, (SelectorLinkedIndexatorAddrLow)	; hlde = raw address of the current object number.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, (SelectorLinkedIndexatorAddrHigh)
			adc hl,bc
								; hlde = in USERAREA address of the current block information.
			ld (EditorCursorAddrLow), de		; We uses the editor buffer for saving the block information, because the selector buffer will be used for the tile pattern information.
			ld (EditorCursorAddrHigh), hl		; Saves the current address.
			ld a, (SelectorLinkedIndexatorFormat)
			ld (EditorCurrentFormat), a
			call _EDITORLOAD			; Loads the block information in the 'EditorBuffer' area.
			pop de
			pop hl

			push hl
			ld bc, (SelectorLinkedIndexatorWidthVisual) ; Draws the block enclosure.
			ld a, 4
			add a, c
			ld c, a

			ld a, 4
			add a, b
			ld b, a	

			ld a, (OutlineColor)
			push de
			push bc
			call @SQUARE
			pop bc
			pop de
			pop hl

			inc l
			inc h
			
			push hl
			push bc
			ld bc, (SelectorLinkedIndexatorCursor)
			ex de,hl
			and a
			sbc hl,bc
			ex de,hl
			pop bc

			ld a, (ScreenBackgroundColor)
			jr nz, .NoCursor
			ld a, (OutlineCursorColor)

.NoCursor:		dec b
			dec b
			dec c
			dec c
			call @SQUARE
			pop hl

			inc l
			inc h
								; in HL = visual position for the content of the block.
			ld de, EditorBuffer			; in EditorBuffer = tile numbers that has the block.

			ld a,(SelectorLinkedIndexatorYTilecount)
			ld b, a

.IndYTileLoop:		push bc					; Vertical bucle for tiles in the block.
			push hl					; Saves the visual for know the left start of the block.

			ld a,(SelectorLinkedIndexatorXTilecount)
			ld b, a

.IndXTileLoop:		push bc					; Horizontal bucle for tiles in the block.

			push de					; Saves the in-block information pointer.
			push hl					; Saves the visual position for know the current horizontal position.

			ld a, (SelectorLinkedIndexatorFormat)	; It reads the tile number and loads its pattern in the SelectorBuffer.
			and FormatID.MapInd16bitsTileNumber
			jr nz, .TN16

			ld a, (de)				; 8 bits tile number.
			ld e, a
			ld d, 0
			jr .TL

.TN16:			ld a, (de)				; 16 bits tile number.
			ld c, a
			inc de
			ld a, (de)
			ld d, a
			ld e, c

.TL:			ld hl, 0				; DE = tile number.
			ld a, (SelectorLinkedTileFormat)
			call _CalculateRawSize
					
			ld bc, (SelectorLinkedTileBaseAddrLow)	; hlde = raw address of the wanted tile pattern.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, (SelectorLinkedTileBaseAddrHigh)
			adc hl,bc
								; hlde = in USERAREA address of the current tile pattern.
			ld (SelectorCurrentRawAddrLow), de
			ld (SelectorCurrentRawAddrHigh), hl	; Saves the current address.
			ld a, (SelectorLinkedTileFormat)
			ld (SelectorCurrentFormat), a
			call @SELECTORLOAD			; Loads the tile pattern in the 'SelectorBuffer' area.

			pop hl
			push hl
			ld a,(SelectorLinkedTileFormat)		; It draws the tile.
			ld iy, RenderPuzTile.ExternalIN		; In a = tile format, in hl = TOP/LEFT visual position. (SelectorBuffer) TileData.
			call @FarCallToPage1
			pop hl					; Restores the visual position.

			ld a, (SelectorLinkedTileSize)
			add a, l
			ld l, a					; bitmap X = X + 8.

			pop de
			inc de
			ld a, (SelectorLinkedIndexatorFormat)
			and FormatID.MapInd16bitsTileNumber
			jr z, .TN8
			inc de

.TN8:			pop bc
			djnz .IndXTileLoop

			pop hl
			ld a, (SelectorLinkedTileSize)
			add a, h
			ld h, a

			pop bc
			djnz .IndYTileLoop
			ret

.FastBS:		call .SaveVars

			ld bc, (SelectorMapBlocksWidth)
			ld a, c
			or b
			jr z, .NoMap				; WARNING: It doesn't checks if the map currently exists.

			ld bc, (FastBunchBack)
			ld iy, BunchSelector.Selects
			jp @FarJumpToPage1

.NoMap:			ld bc, (SelectorLinkedTileBunchIndex)

			ld hl, (SelectorLinkedIndexatorBunchIndex)
			ld (FastBunchBack), hl

			ld iy, BunchSelector.Selects
			jp @FarJumpToPage1

.RedrawFirstRow:	ld de, (SelectorLinkedIndexatorScrollTop)

			ld hl, 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)

.RFRLoop:		push hl
			push de
			call .DrawABlock
			pop de
			pop hl

			ld a, (SelectorLinkedIndexatorWidthVisual); It changes the visual position.
			add a,6					; Adds 6 pixels more in width for the enclosure.
			ld b, a

			add a,l
			ret c
			cp 236
			ret nc
			add a,b					; Test if it have enough space left.
			ret c
			cp 236
			ret nc

			sub b
			ld l,a

			inc de					; It increments the object count.
			jr .RFRLoop

.RedrawLastRow:		ld de, (SelectorLinkedIndexatorScrollTop)
			ld c, 0					; Indicates that is not on the last row.

			ld hl, 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)

.RLRLoop:		push hl
			push de
			push bc
			ld a, c
			and a
			call nz, .DrawABlock
			pop bc
			pop de
			pop hl

			ld a, (SelectorLinkedIndexatorWidthVisual); It changes the visual position.
			add a,6					; Adds 6 pixels more in width for the enclosure.
			ld b, a

			add a,l
			jr c, .RLRVisualNextRow
			cp 236
			jr nc, .RLRVisualNextRow
			add a,b					; Test if it have enough space left.
			jr c, .RLRVisualNextRow
			cp 236
			jr nc, .RLRVisualNextRow

			sub b
			ld l,a
			jr .RLRVisualOk

.RLRVisualNextRow:	ld l, 0					; CR.

			ld a, (SelectorLinkedIndexatorHeightVisual)
			add a, 6				; Adds 6 pixels more in height for the enclosure.
			ld b, a

			add a, h
			ret c
			cp 172
			ret nc
			add a, b				; Test if it have enough space left.
			ret c
			cp 172
			ret nc

			push af					; Check if it is the last row.
			add a, b
			jr c, .LastRow
			cp 172
			jr c, .NoLastRow

.LastRow:		dec c

.NoLastRow:		pop af
			sub b
			ld h,a

.RLRVisualOk:		inc de					; It increments the object count and checks for the end of the indexator.
			jr .RLRLoop

.Goto:			ld ix, GotoData
			ld iy, MSGBOX
			call @FarCallToPage1
			jr c, .GotoExiting

			ld hl, MsgBoxBuffer
			call @VAL
			jr nc, .GotoXOk

.GotoErr:		call @BEEP
			jr .GotoExiting

.GotoXOk:		ld hl, (SelectorLinkedIndexatorObjectCount); DE = value inputed.
			sbc hl, de
			jr z, .GotoErr
			jr c, .GotoErr

			ld (SelectorLinkedIndexatorCursor), de

			call .VerticalStep
			ex de, hl

			push hl
			call @DIV16_8
			pop hl

			ld b, a
			ld a, l
			sub b
			ld l, a
			ld a, h
			sbc a, 0
			ld h, a

			ld (SelectorLinkedIndexatorScrollTop), hl

.GotoExiting:		ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			call @CLSLP
			jp .RedrawALot

.ScrollDownCommandData16:	DB 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 22, 0, 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator, 0, 228, 0, 132 - 22, 0, 0, $00,$D0
.ScrollDownCommandData32:	DB 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 38, 0, 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator, 0, 228, 0, 114 - 38, 0, 0, $00,$D0
.ScrollDownCommandData16Sc7:	DB 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 22, 0, 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator, 0, 200, 1, 132 - 22, 0, 0, $00,$D0
.ScrollDownCommandData32Sc7:	DB 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 38, 0, 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator, 0, 200, 1, 114 - 38, 0, 0, $00,$D0

.ScrollUpCommandData16:	DB 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 132 - 22 -1, 0, 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 132 -1, 0, 228, 0, 132 - 22, 0, 0, $08,$D0
.ScrollUpCommandData32:	DB 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 114 - 38 -1, 0, 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 114 -1, 0, 228, 0, 114 - 38, 0, 0, $08,$D0
.ScrollUpCommandData16Sc7:	DB 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 132 - 22 -1, 0, 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 132 -1, 0, 200, 1, 132 - 22, 0, 0, $08,$D0
.ScrollUpCommandData32Sc7:	DB 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 114 - 38 -1, 0, 0, 0, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 114 -1, 0, 200, 1, 114 - 38, 0, 0, $08,$D0






_PrintsHOTs:		ld b, 5
			ld hl, SelectorIndexatorCursorHOT0
			ld c, 4
			ld a,(OutlineSecondaryColor)
			ld (RenderForeColor), a
			ld a,(ScreenBackgroundColor)
			ld (RenderBackColor), a
			ld a, '0'

.L1:			push af
			push bc
			push hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld l, c
			ld h, 164

			push hl
			push af
			ld a, (SelectorMapCallingFromMapConsole)
			and a
			jr z, .Normal1

			ld a, (SelectorMapDirect)
			and a
			jr z, .Normal1
								; Is using Direct Map -> TileSet mapping.
			push de
			push hl
			call .HotEnclosure
			pop hl
			pop de
			inc l
			inc l
			inc h
			inc h
			call _MapConsole.DrawABlock
			jr .Normal1Esc

.Normal1:		call _IndexatorConsole.DrawABlock	; in DE = Object number. in HL = visual position.

.Normal1Esc:		pop af
			pop de

			dec e
			dec e
			dec d
			dec d
			call @CHRDRAW

			pop hl
			inc hl
			inc hl
			pop bc
			ld a, 45
			add a, c
			ld c, a					; Visual X step.
			pop af
			inc a
			djnz .L1

			ld b, 5
			ld c, 24
			ld a, '5'

.L2:			push af
			push bc
			push hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld l, c
			ld h, 176

			push hl
			push af
			ld a, (SelectorMapCallingFromMapConsole)
			and a
			jr z, .Normal2

			ld a, (SelectorMapDirect)
			and a
			jr z, .Normal2
								; Is using Direct Map -> TileSet mapping.
			push de
			push hl
			call .HotEnclosure
			pop hl
			pop de
			inc l
			inc l
			inc h
			inc h
			call _MapConsole.DrawABlock
			jr .Normal2Esc

.Normal2:		call _IndexatorConsole.DrawABlock	; in DE = Object number. in HL = visual position.

.Normal2Esc:		pop af
			pop de

			dec e
			dec e
			dec d
			dec d
			call @CHRDRAW

			pop hl
			inc hl
			inc hl
			pop bc
			ld a, 45
			add a, c
			ld c, a					; Visual X step.
			pop af
			inc a
			djnz .L2
			ret

.HotEnclosure:		push hl
			ld bc, (SelectorLinkedIndexatorWidthVisual) ; Draws the block enclosure for when it is not supplied by the .DrawABlock routine.
			ld a, 4
			add a, c
			ld c, a

			ld a, 4
			add a, b
			ld b, a	

			ld a, (OutlineColor)
			push bc
			call @SQUARE
			pop bc
			pop hl

			inc l
			inc h
			
			ld a, (ScreenBackgroundColor)

			dec b
			dec b
			dec c
			dec c
			jp @SQUARE






_RenumHots:		ld de, (SelectorIndexatorCursorHOT0)

			ld b, 10
			ld hl, SelectorIndexatorCursorHOT0

.Loop:			ld (hl), e
			inc hl
			ld (hl), d
			inc hl

			inc de

			push bc					; If reached the tiles ammount, reverse de countup.
			ld bc, (SelectorLinkedTileObjectCount)
			ex de, hl
			push hl
			and a
			sbc hl, bc
			pop hl
			ex de, hl
			pop bc
			jr c, .NoDec

			dec de

.NoDec:			djnz .Loop
			ret






_CalculateMapMasks:	ld hl, (SelectorLinkedIndexatorObjectCount)
			dec hl

			ld de, 0
			jr .GoIn

.Loop:			and a
			rr h
			rr l

.GoIn:			ld a, l
			or h
			jr z, .Esc

			scf
			rl e
			rl d
			jr .Loop

.Esc:			ld (SelectorMapBlockGraphicsMask), de

			ld a, e
			cpl
			ld e, a
			ld a, d
			cpl
			ld d, a

			ld (SelectorMapBlockAttribsMask), de
			ret






_MapConsole:		ld bc, (SelectorBunchIndex)
			push bc
			call _PreConfMapVars
			pop bc
			jr c, .GoMenu

			ld iy, GetLinkedBunch
			call @FarCallToPage1
			jr nc, .Link1Ok

.NoLink:		ld iy, MENUBAR.ErrorLinkage
			call @FarCallToPage1
.GoMenu:		ld iy, ConsoleRender.GoMenuBar
			jp @FarJumpToPage1

.Link1Ok:		push bc					; Is needed to know if it linked directly to a tileset or uses the indexator.
			ld iy, GetsBunchFormat
			call @FarCallToPage1
			pop bc

			and FormatID.MapIndIDMask
			cp FormatID.MapIndID

			jr z, .LinkToIndexator
								; Is linking directly the MAP to the TileSet.
			ld a, $FF
			ld (SelectorMapDirect), a		; Saves that is using this mode.

			call _PreConfTileVars			; First pick up the tileset information.

			call _PreConfIndexatorDirect

			call _RenumHots

			jr .StartChecks

.LinkToIndexator:	xor a					; When using tile grouping into metatiles (aka indexation).
			ld (SelectorMapDirect), a

			push bc
			call _PreConfIndexatorVars
			pop bc
			jr c, .GoMenu

			ld iy, GetLinkedBunch
			call @FarCallToPage1
			jr c, .NoLink

			call _PreConfTileVars

			call _PreAdjustIndexatorVars		; If tiles is not the 8x8 standard, it adjusts the indexator variables.

.StartChecks:		call _CalculateMapMasks			; It calculates the bit masks for coding block attributes and graphics.

			ld hl, SavedSelectorMapVariables
			ld bc, SavedSelectorMapVariables_End - SavedSelectorMapVariables

			exx
			ld hl, (SelectorMapAddrHigh)
			ld de, (SelectorMapAddrLow)
			ld bc, BunchHeader.Size - BunchHeader.Status
			ex de, hl
			and a
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc
			exx
			call @READ_USERAREA

.Continue:		ld a, $FF
			ld (SelectorMapCallingFromMapConsole), a
			call _PrintsHOTs
			xor a
			ld (SelectorMapCallingFromMapConsole), a

.RedrawAll:		ld de, (SelectorMapScrollTop)		; It calculates the TOP/LEFT block address in the USERAREA.
			ld bc, (SelectorMapBlocksWidth)
			call @Mult32
			ex de, hl
			ld l, c
			ld h, b					; hlde = block ordinal number.

			ld bc, (SelectorMapScrollLeft)
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc
			jp c, .DataError

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr z, .NoDoubler

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; hlde = hlde * 2.
			jp c, .DataError

.NoDoubler:		ld bc,(SelectorMapAddrLow)
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc,(SelectorMapAddrHigh)
			adc hl, bc				; hlde = MapBaseAddress + ((Y * RowSizeWidth) + X) * format. Format can be 8 or 16bits behaving as x1 or x2 respectively.
			jp c, .DataError			; hlde = in userarea current block address.
			
			exx
			ld hl,  256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)
			exx

			push hl
			ld hl, (SelectorMapScrollTop)
			ld (SelectorMapLastRowDrawn), hl
			ld hl, (SelectorMapScrollLeft)
			ld (SelectorMapLastColumnDrawn), hl
			pop hl

.MapYBlockLoop:		push hl
			push de					; Saves the current block address at the current HOME visual position.

.MapXBlockLoop:		push hl
			push de					; Saves the current block address.

			call @USERAREA_RW			; Reads the map.
			jp c, .DataErrorPop4

			ld e, c
			ld d, b

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr nz, .F16b
			ld d, 0					; If 8bits, trims DE.

.F16b:			exx					; DE = block number.
			push hl
			exx 
			pop hl					; Brings up the current visual position.
								; It draws the block!.
			push hl

			ld a, (SelectorMapDrawCustomMode)	; 0 = draw all, 1 = draw column number, 2 = draw row number.
			and a
			jr z, .Draw
			dec a
			jr z, .DrawOnlyColumn
								; Draw only row.
			push hl
			ld bc, (SelectorMapLastRowDrawn)
			ld hl, (SelectorMapDrawCustomNumber)
			sbc hl, bc
			pop hl

			jr nz, .NoDraw
			jr .Draw

.DrawOnlyColumn:	push hl
			ld bc, (SelectorMapLastColumnDrawn)
			ld hl, (SelectorMapDrawCustomNumber)
			sbc hl, bc
			pop hl

			jr nz, .NoDraw
			jr .Draw

.Draw:			call .DrawABlock			; in DE = ObjectNumber, HL = TOP/LEFT visual position.
.NoDraw:		pop hl					; It restores the current visual position.

			ld a, (SelectorLinkedIndexatorWidthVisual)
			add a, l
			jr c, .CRLF
			cp 224
			jr nc, .CRLF

			ld l, a
			push hl
			ld hl, (SelectorMapLastColumnDrawn)	; Count up the last column drawn (for the scrollbar math).
			inc hl
			ld de,(SelectorMapBlocksWidth)		; Checks if it reached the width map limit.
			and a
			sbc hl, de
			jr nc, .CRLFpopHL			; It forces a CRLF if it reached the right map limit.
			add hl, de				; Restores the value.
			ld (SelectorMapLastColumnDrawn), hl
			pop hl
			ld c, $FF				; It indicates later that there wasn't a CRLF.
			jr .NoCRLF

.CRLFpopHL:		pop hl

.CRLF:			ld l, 0
			ld a, (SelectorLinkedIndexatorHeightVisual)
			add a, h
			jp c, .MapCompleted
			ld h, a
			ld a, (SelectorLinkedIndexatorHeightVisual)
			add a, h
			jp c, .MapCompleted
			cp 162					; Checks if the last row will fit.
			jp nc, .MapCompleted

			push hl					; Counts up one row drawn (needed for the scrollbar math).
			ld hl, (SelectorMapLastRowDrawn)
			inc hl
			ld de, (SelectorMapBlocksHeight)
			and a
			sbc hl, de
			jp nc, .MapCompletedPop5
			add hl, de
			ld (SelectorMapLastRowDrawn), hl
			ld hl, (SelectorMapScrollLeft)
			ld (SelectorMapLastColumnDrawn), hl
			pop hl
			ld c, $00				; It indicates later that was a CRLF.

.NoCRLF:		ld a, c
			and a
			jr z, .WasACRLF
								; Was not a CRLF.
			exx
			pop de
			pop hl

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			ld bc, 2
			jr nz, .F16bJ2
			ld bc, 1

.F16bJ2:		ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			jp .MapXBlockLoop

.WasACRLF:		exx
			pop de
			pop hl
			pop de
			pop hl

			ld bc, (SelectorMapRowSizeLow)
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, (SelectorMapRowSizeHigh)
			adc hl, bc
			jp .MapYBlockLoop

.DataErrorPop4:		pop bc
			pop bc
			pop bc
			pop bc

.DataError:		ld ix, BoxErrorBadData
			ld iy, MENUBAR.ErrMsgBox
			call @FarCallToPage1
			ld iy, ConsoleRender.GoMenuBar
			jp @FarJumpToPage1

.DrawABlock:		push de
			push hl					; in DE = Object number. in HL = visual position.
			ld hl, (SelectorMapBlockGraphicsMask)
			ld a, e
			and l
			ld e, a
			ld a, d
			and h
			ld d, a

			ld hl, (SelectorLinkedIndexatorObjectCount)
			and a
			sbc hl, de
			jr z, .OutOfObjects
			jr nc, .ObjectExists

.OutOfObjects:		pop hl
			pop de
			
			ld bc, (SelectorLinkedIndexatorWidthVisual); It reads both, width & height.

			ld a, (ScreenBackgroundColor)		; it blanks the block space, as here is no object to be drawn.
			jp @BLOCKFILL
			
.ObjectExists:		ld a, (SelectorMapDirect)
			and a
			jr z, .UsingIndexator
								; The map is directly pointing out Tile IDs.
			ld hl, 0				; DE = tile number.
			ld a, (SelectorLinkedTileFormat)
			call _CalculateRawSize
					
			ld bc, (SelectorLinkedTileBaseAddrLow)	; hlde = raw address of the wanted tile pattern.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, (SelectorLinkedTileBaseAddrHigh)
			adc hl,bc
								; hlde = in USERAREA address of the current tile pattern.
			ld (SelectorCurrentRawAddrLow), de
			ld (SelectorCurrentRawAddrHigh), hl	; Saves the current address.
			ld a, (SelectorLinkedTileFormat)
			ld (SelectorCurrentFormat), a
			call @SELECTORLOAD			; Loads the tile pattern in the 'SelectorBuffer' area.

			pop hl
			ld a,(SelectorLinkedTileFormat)		; It draws the tile.
			push hl
			ld iy, RenderPuzTile.ExternalIN		; In a = tile format, in hl = TOP/LEFT visual position. (SelectorBuffer) TileData.
			call @FarCallToPage1
			jp .EndDrawingABlock

.UsingIndexator:	ld hl, 0
			ld a, (SelectorLinkedIndexatorFormat)
			call _CalculateRawSize
					
			ld bc, (SelectorLinkedIndexatorAddrLow)	; hlde = raw address of the current object number.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, (SelectorLinkedIndexatorAddrHigh)
			adc hl,bc
								; hlde = in USERAREA address of the current block information.
			ld (EditorCursorAddrLow), de		; We uses the editor buffer for saving the block information, because the selector buffer will be used for the tile pattern information.
			ld (EditorCursorAddrHigh), hl		; Saves the current address.
			ld a, (SelectorLinkedIndexatorFormat)
			ld (EditorCurrentFormat), a
			call _EDITORLOAD			; Loads the block information in the 'EditorBuffer' area.
			pop hl
								; in HL = visual position for the content of the block.
			push hl					; Saves the visual position for a later use in the cursor print.

			ld de, EditorBuffer			; in EditorBuffer = tile numbers that has the block.

			ld a,(SelectorLinkedIndexatorYTilecount)
			ld b, a

.IndYTileLoop:		push bc					; Vertical bucle for tiles in the block.
			push hl					; Saves the visual for know the left start of the block.

			ld a,(SelectorLinkedIndexatorXTilecount)
			ld b, a

.IndXTileLoop:		push bc					; Horizontal bucle for tiles in the block.

			push de					; Saves the in-block information pointer.
			push hl					; Saves the visual position for know the current horizontal position.

			ld a, (SelectorLinkedIndexatorFormat)	; It reads the tile number and loads its pattern in the SelectorBuffer.
			and FormatID.MapInd16bitsTileNumber
			jr nz, .TN16

			ld a, (de)				; 8 bits tile number.
			ld e, a
			ld d, 0
			jr .TL

.TN16:			ld a, (de)				; 16 bits tile number.
			ld c, a
			inc de
			ld a, (de)
			ld d, a
			ld e, c

.TL:			ld hl, 0				; DE = tile number.
			ld a, (SelectorLinkedTileFormat)
			call _CalculateRawSize
					
			ld bc, (SelectorLinkedTileBaseAddrLow)	; hlde = raw address of the wanted tile pattern.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, (SelectorLinkedTileBaseAddrHigh)
			adc hl,bc
								; hlde = in USERAREA address of the current tile pattern.
			ld (SelectorCurrentRawAddrLow), de
			ld (SelectorCurrentRawAddrHigh), hl	; Saves the current address.
			ld a, (SelectorLinkedTileFormat)
			ld (SelectorCurrentFormat), a
			call @SELECTORLOAD			; Loads the tile pattern in the 'SelectorBuffer' area.

			pop hl
			push hl
			ld a,(SelectorLinkedTileFormat)		; It draws the tile.
			ld iy, RenderPuzTile.ExternalIN		; In a = tile format, in hl = TOP/LEFT visual position. (SelectorBuffer) TileData.
			call @FarCallToPage1
			pop hl					; Restores the visual position.

			ld a, (SelectorLinkedTileSize)
			add a, l
			ld l, a					; bitmap X = X + TileSize.

			pop de
			inc de
			ld a, (SelectorLinkedIndexatorFormat)
			and FormatID.MapInd16bitsTileNumber
			jr z, .TN8
			inc de

.TN8:			pop bc
			djnz .IndXTileLoop

			pop hl
			ld a, (SelectorLinkedTileSize)		; bitmap Y = Y + TileSize.
			add a, h
			ld h, a

			pop bc
			djnz .IndYTileLoop

.EndDrawingABlock:	pop bc					; Restores the visual position of the block.
			pop de					; Restores the map block value.

			ld hl, (SelectorMapBlockAttribsMask)
			ld a, e
			and l
			ld e, a
			ld a, d
			and h
			ld d, a

			ld a, e
			or d
			jr z, .NoAttrib
								; There is some block's attribute coded.
			push bc					; BC = visual position.
			inc b					; Prints 4 characters on the blocks visual position offset y + 4 , x + 2
			inc b
			inc b
			inc b
								; Render characters as 4x8, so it almost fits in the 16x16 visual area.
			push bc
			push de
			ld a, d
			rrca
			rrca
			rrca
			rrca
			and $0F
			add a, '0'
			cp '9'+1
			jr c, .HexJ1
			add a, 7

.HexJ1:			ld e, c
			ld d, b
			call @CHRDRAW
			pop de
			pop bc

			ld a, c
			add a, 5
			ld c, a

			push bc
			push de
			ld a, d
			and $0F
			add a, '0'
			cp '9'+1
			jr c, .HexJ2
			add a, 7

.HexJ2:			ld e, c
			ld d, b
			call @CHRDRAW
			pop de
			pop bc

			ld a, c
			add a, 5
			ld c, a

			push bc
			push de
			ld a, e
			rrca
			rrca
			rrca
			rrca
			and $0F
			add a, '0'
			cp '9'+1
			jr c, .HexJ3
			add a, 7

.HexJ3:			ld e, c
			ld d, b
			call @CHRDRAW
			pop de
			pop bc

			ld a, c
			add a, 5
			ld c, a

			ld a, e
			and $0F
			add a, '0'
			cp '9'+1
			jr c, .HexJ4
			add a, 7

.HexJ4:			ld e, c
			ld d, b
			call @CHRDRAW

			pop bc

.NoAttrib:		ld hl, (SelectorMapLastColumnDrawn)
			ld de, (SelectorMapCursorX)
			sbc hl, de
			jr nz, .TestIfCopying

			ld hl, (SelectorMapLastRowDrawn)
			ld de, (SelectorMapCursorY)
			and a
			sbc hl, de
			jr nz, .TestIfCopying

			ld a, (SelectorMapCursorShow)
			and a
			jr z, .TestIfCopying

			ld l, c
			ld h, b
			
			ld a, (SelectorLinkedIndexatorWidthVisual)
			dec a
			ld c, a
			ld a, (SelectorLinkedIndexatorHeightVisual)
			dec a
			ld b, a
			ld a, (OutlineCursorColor)
.DrawCursor:		push hl
			push bc
			call @SQUARE
			pop bc
			pop hl
			inc l
			inc h
			dec c
			dec c
			dec b
			dec b
			ld a, (ScreenBackgroundColor)
			jp @SQUARE

.TestIfCopying:		ld a, (SelectorMapCopyStage)
			and a
			ret z

			dec a
			jr z, .OnlyOneCopy
								; Area Copy.
			ld hl, (SelectorMapLastColumnDrawn)
			ld de, (SelectorMapCopyX)
			sbc hl, de
			ret c
			
			ld hl, (SelectorMapLastColumnDrawn)
			ld de, (SelectorMapCopyStopX)
			sbc hl, de
			ret nc

			ld hl, (SelectorMapLastRowDrawn)
			ld de, (SelectorMapCopyY)
			and a
			sbc hl, de
			ret c

			ld hl, (SelectorMapLastRowDrawn)
			ld de, (SelectorMapCopyStopY)
			sbc hl, de
			ret nc
								; Is selected in the copy operation.
.DrawSelected:		ld l, c
			ld h, b
			
			ld a, (SelectorLinkedIndexatorWidthVisual)
			dec a
			ld c, a
			ld a, (SelectorLinkedIndexatorHeightVisual)
			dec a
			ld b, a
			ld a, (OutlinePrimaryRemarkColor)
			jr .DrawCursor

.OnlyOneCopy:		ld hl, (SelectorMapLastColumnDrawn)
			ld de, (SelectorMapCopyX)
			sbc hl, de
			ret nz

			ld hl, (SelectorMapLastRowDrawn)
			ld de, (SelectorMapCopyY)
			sbc hl, de
			ret nz
								; Is selected.
			jr .DrawSelected

.MapCompletedPop5:	pop bc
.MapCompleted:		pop bc
			pop bc
			pop bc
			pop bc
			xor a
			ld (SelectorMapDrawCustomMode), a	; It resets the last custom redraw command.
								; /// Now it have to redraw the VERTICAL SCROLL BAR ///.
			ld hl, 15*16 + 256*(ConsoleStartLine +BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator + 1)

			ld bc, 256 * (128 + 1) + 8		; It renders the scrollbar border.
			ld a, (OutlineSecondaryColor)		; Scrollbar border color.
			call @SQUARE

			ld de,(SelectorMapScrollTop)		; It calculates the scrollbar cursor position.
			ld hl,0
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x2.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x4.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x8.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x16.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x32.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x64.
			
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; Scale Up 128 times. As we didn't want to work with fractions!!!. And 128px will be the space for scroll bar cursor.

			ld bc,(SelectorMapBlocksHeight)
			dec bc
			call @DIV32_16
								; de = cursor Y start offset. hld is zero always as the range would be 0 - 127 as was scaled up 128 times only.
			push de					; Saves the cursor position for later use.
			ld hl, 15*16 + 1 + 256*(ConsoleStartLine+BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator + 2)		; it draws the background space from the start of the scrollbar up to the cursor position - 1.

			ld b,e
			ld a,e
			and a
			ld c, 6
			ld a, (OutlineBackGroundColor)
			CALL nz, @BLOCKFILL
			pop de

			ld hl, 15*16 + 1 + 256*(ConsoleStartLine+BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator + 2)		; it draws the cursor of the scrollbar.
			ld a,e
			add a,h
			ld h,a
			push hl
			push de

			ld de, (SelectorMapLastRowDrawn)
			ld hl,(SelectorMapBlocksHeight)		; Checks if the ends view is not > than the object count (because here can be unused blocks in the view).
			and a
			sbc hl,de
			jr nc, .NoPassed

			ld de,(SelectorMapBlocksHeight)
			dec de

.NoPassed:		ld hl,0
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x2.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x4.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x8.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x16.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x32.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x64.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; Scale Up 128 times. As we didn't want to work with fractions!!!. And 128px will be the space for scroll bar cursor.
			
			ld bc,(SelectorMapBlocksHeight)
			dec bc
			call @DIV32_16
								; de = cursor Y end offset. hld is zero always as the range would be 0 - 127 as was scaled up 128 times only.
			pop bc
			ld a,e
			sub c
			jr c, .VSJ2
			jr nz, .CSOk

.VSJ2:			ld a, 1					; Minimun cursor size.

.CSOk:			ld b,a
			pop hl
			ld c, 6
			ld a, (OutlineCursorColor)
			push hl
			push bc
			CALL @BLOCKFILL
			pop bc
			pop hl

			ld a,h
			add a,b
			ld h,a

			ld a, 127 + (ConsoleStartLine+BunchLowerSeparator+BunchTitleBarHeight+BunchUpperSeparator + 2)
			sub h
			ld b,a		
			jr c, .VSJ1

			ld a, (OutlineBackGroundColor)
			CALL nz, @BLOCKFILL
								; /// Now it's time for the HORIZONTAL SCROLLBAR. ///
.VSJ1:			ld hl, 64 + 256*(ConsoleStartLine+BunchLowerSeparator + 1)

			ld bc, 256 * 8 + (128 + 1)		; It renders the scrollbar border.
			ld a, (OutlineSecondaryColor)		; ScrollBar border color.
			call @SQUARE

			ld de,(SelectorMapScrollLeft)		; It calculates the scrollbar cursor position.		
			ld hl,0
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x2.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x4.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x8.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x16.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x32.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x64.
			
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; Scale Up 128 times. As we didn't want to work with fractions!!!. And 128px will be the space for scroll bar cursor.

			ld bc,(SelectorMapBlocksWidth)
			dec bc
			call @DIV32_16
								; de = cursor X start offset. hld is zero always as the range would be 0 - 127 as was scaled up 128 times only.
			push de					; Saves the cursor position for later use.
			ld hl, 64 + 1 + 256*(ConsoleStartLine+BunchLowerSeparator + 2)	; it draws the background space from the start of the scrollbar up to the cursor position - 1.

			ld c,e
			ld a,c
			and a
			ld b, 6
			ld a, (OutlineBackGroundColor)
			CALL nz, @BLOCKFILL
			pop de

			ld hl,  64 + 1 + 256*(ConsoleStartLine+BunchLowerSeparator + 2)	; it draws the cursor of the scrollbar.

			ld a,e
			add a,l
			ld l,a
			push hl
			push de

			ld de, (SelectorMapLastColumnDrawn)
			ld hl,(SelectorMapBlocksWidth)		; Checks if the ends view is not > than the object count (because here can be unused blocks in the view).
			and a
			sbc hl,de
			jr nc, .NoPassed2

			ld de,(SelectorMapBlocksWidth)
			dec de

.NoPassed2:		ld hl,0
			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x2.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x4.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x8.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x16.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x32.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; x64.

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; Scale Up 128 times. As we didn't want to work with fractions!!!. And 128px will be the space for scroll bar cursor.
			
			ld bc,(SelectorMapBlocksWidth)
			dec bc
			call @DIV32_16
								; de = cursor X end offset. hld is zero always as the range would be 0 - 127 as was scaled up 128 times only.
			pop bc
			ld a,e
			sub c
			jr c, .HSJ2
			jr nz, .CSOk2

.HSJ2:			ld a, 1					; Minimun cursor size.

.CSOk2:			ld c,a
			pop hl
			ld b, 6
			ld a, (OutlineCursorColor)
			push hl
			push bc
			CALL @BLOCKFILL
			pop bc
			pop hl

			ld a,l
			add a,c
			ld l,a

			ld a, 64 + 1 + 128 - 1
			sub l
			ld c,a
			jr c, .HSJ1

			ld a, (OutlineBackGroundColor)
			CALL nz, @BLOCKFILL

.HSJ1:
.PrintCursor:		ld c, $FF				; It shows the cursor.
			call .PrintWhereCursor
			
			ld de, (SelectorMapCursorX)		; Prints the X position.
			ld hl,0
			call _STR
			ld de, 184 + 256 * 3
			ld hl, STR_Buffer

			ld a, (MenuForeColor)
			ld (RenderForeColor),a
			ld a, (MenuBackGroundColor)
			ld (RenderBackColor),a
			call @STRDRAWZ				; equivalent PRINT STR$(SelectorMapCursorX).

			ld hl, STR_Buffer
			call @STRLEN	
			ld a,5					; 65535 (5 digits) is the maximun that will show ever.
			sub c
			ld b,a
			add a,a
			add a,b
			add a,a					; a = width that lacks to cover.
			ld b,a

			ld a,c
			add a,a
			add a,c
			add a,a					; a = width printed.
			ld l, 184
			add a,l
			ld l,a

			ld c,b
			ld b,8
			ld h, 3
			ld a, (MenuBackGroundColor)
			call @BLOCKFILL

			ld de, (SelectorMapCursorY)		; Prints the Y position.
			ld hl,0
			call _STR
			ld de, 220 + 256 * 3
			ld hl, STR_Buffer
			call @STRDRAWZ

			ld hl, STR_Buffer
			call @STRLEN	
			ld a,5					; 65535 (5 digits) is the maximun that will show ever.
			sub c
			ld b,a
			add a,a
			add a,b
			add a,a					; a = width that lacks to cover.
			ld b,a

			ld a,c
			add a,a
			add a,c
			add a,a					; a = width printed.
			ld l, 220
			add a,l
			ld l,a

			ld c,b
			ld b,8
			ld h, 3
			ld a, (MenuBackGroundColor)
			call @BLOCKFILL

.KeyboardControl:	call @INKEY
			jr c, .KeyboardControl

			call @UPCASE

			push af
			ld c, 0
			call .PrintWhereCursor			; It hides the cursor.
			pop af

			cp 27
			jp z, .Esc

			cp 9
			jp z, .Tab

			cp 'Q'
			jp z, .FastBS

			cp 'D'
			jp z, .AreaRight

			cp 'A'
			jp z, .AreaLeft

			cp 'W'
			jp z, .AreaUp

			cp 'S'
			jp z, .AreaDown

			cp '0'
			jr c, .KCJ1

			cp '9'+1
			jp c, .HitHot

.KCJ1:			cp 32
			jp z, .Hit

			cp 28
			jp z, .Right

			cp 29
			jp z, .Left

			cp 30
			jp z, .Up

			cp 31
			jp z, .Down

			cp 'Z'
			jp z, .HotsFullLeft
			cp 'X'
			jp z, .HotsLeft
			cp 'C'
			jp z, .HotsRight
			cp 'V'
			jp z, .HotsFullRight

			cp 'M'
			jp z, .AttribSet
			
			cp 'N'
			jp z, .MapCopy

			cp 'G'
			jp z, .Goto

			jp .PrintCursor

.SaveMapVars:		ld hl, SavedSelectorMapVariables
			ld bc, SavedSelectorMapVariables_End - SavedSelectorMapVariables

			exx
			ld hl, (SelectorMapAddrHigh)
			ld de, (SelectorMapAddrLow)
			ld bc, BunchHeader.Size - BunchHeader.Status
			ex de, hl
			and a
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc
			exx
			jp @WRITE_USERAREA

.Esc:			call .SaveMapVars

			ld iy, ConsoleRender.GoMenuBar
			jp @FarJumpToPage1

.Tab:			call .SaveMapVars

			ld iy, BunchSelector
			jp @FarJumpToPage1

.Hit:			ld a, (SelectorMapDirect)
			and a
			jp nz, .PrintCursor

			ld bc, (SelectorLinkedIndexatorCursor)	; What blockID it will save on the cursor position?.

.HitExt:		push bc
			ld de, (SelectorMapCursorY)		; It calculates the X/Y map block address in the USERAREA.
			ld bc, (SelectorMapBlocksWidth)
			call @Mult32
			ex de, hl
			ld l, c
			ld h, b					; hlde = block ordinal number.

			ld bc, (SelectorMapCursorX)
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr z, .NoDoubler2

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; hlde = hlde * 2.

			ld bc,(SelectorMapAddrLow)
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc,(SelectorMapAddrHigh)
			adc hl, bc				; hlde = MapBaseAddress + ((Y * RowSizeWidth) + X) * format. Format can be 8 or 16bits behaving as x1 or x2 respectively.

			pop bc
			call @USERAREA_WW
			jp .PrintCursor

.NoDoubler2:		ld bc,(SelectorMapAddrLow)
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc,(SelectorMapAddrHigh)
			adc hl, bc				; hlde = MapBaseAddress + ((Y * RowSizeWidth) + X) * format. Format can be 8 or 16bits behaving as x1 or x2 respectively.

			pop bc
			ld a, c
			call @USERAREA_WB
			jp .PrintCursor

.HotsLeft:		ld a, (SelectorMapDirect)
			and a
			jp z, .PrintCursor

			ld hl, (SelectorIndexatorCursorHOT0)
			ld a, l
			or h
			jp z, .PrintCursor

			dec hl

.HotsScrollJ1:		ld (SelectorIndexatorCursorHOT0), hl
			call _RenumHots

			ld a, $FF
			ld (SelectorMapCallingFromMapConsole), a
			call _PrintsHOTs
			xor a
			ld (SelectorMapCallingFromMapConsole), a
			jp .PrintCursor

.HotsFullLeft:		ld a, (SelectorMapDirect)
			and a
			jp z, .PrintCursor

			ld hl, (SelectorIndexatorCursorHOT0)
			ld bc, 10
			sbc hl, bc
			jr nc, .HotsScrollJ1

			ld hl, 0
			jr .HotsScrollJ1

.HotsRight:		ld a, (SelectorMapDirect)		; Checks if reached the tile count limit.
			and a
			jp z, .PrintCursor

			ld hl, (SelectorIndexatorCursorHOT0)
			ld bc, 10
			add hl, bc
			jp c, .PrintCursor

			ld bc, (SelectorLinkedTileObjectCount)
			sbc hl, bc				; It tests if the new tile number that will be shown exists.
			jp nc, .PrintCursor

			ld hl, (SelectorIndexatorCursorHOT0)
			inc hl
			jr .HotsScrollJ1

.HotsFullRight:		ld a, (SelectorMapDirect)		; Checks if reached the tile count limit.
			and a
			jp z, .PrintCursor

			ld hl, (SelectorIndexatorCursorHOT0)
			ld bc, 19
			add hl, bc
			jp c, .HROverFlow

			ld bc, (SelectorLinkedTileObjectCount)
			sbc hl, bc
			jp nc, .HROverFlow

			ld hl, (SelectorIndexatorCursorHOT0)
			ld bc, 10
			add hl, bc
			jr .HotsScrollJ1

.HROverFlow:		ld hl, (SelectorLinkedTileObjectCount)
			ld bc, 10
			and a
			sbc hl, bc
			jp c, .PrintCursor
			jr .HotsScrollJ1

.Right:			ld hl, (SelectorMapCursorX)
			inc hl
			ld a, l
			or h
			jp z, .PrintCursor

			ld de, (SelectorMapBlocksWidth)
			push hl
			sbc hl, de
			pop hl
			jp nc, .PrintCursor

			ld (SelectorMapCursorX), hl			

			ld de, (SelectorMapLastColumnDrawn)
			and a
			sbc hl, de
			jp z, .PrintCursor
			jp c, .PrintCursor

			ld de, (SelectorMapScrollLeft)
			inc de
			ld (SelectorMapScrollLeft), de

			ld a, 1
			ld (SelectorMapDrawCustomMode), a	; 0 = draw all, 1 = draw column number, 2 = draw row number.

			ld hl, (SelectorMapCursorX)
			ld (SelectorMapDrawCustomNumber), hl

			ld a, (IsOnPaletteScreenMode)
			and a
			ld hl, .DoCopyDataRightx2x2y
			jr z, .RJ1
			ld hl, .DoCopyDataRightx2x2ySc7

.RJ1:			ld a, (SelectorLinkedIndexatorHeightVisual)
			cp 32
			ld b, 1
			jr z, .RZ1
			
			dec b

.RZ1:			ld a, (SelectorLinkedIndexatorWidthVisual)
			cp 32
			set 1, b
			jr z, .RZ2

			res 1, b

.RZ2:			ld a, b

			add a,a
			add a,a
			add a,a
			add a,a
			sub b
			add a,l
			ld l, a
			ld a, h
			adc a, 0
			ld h, a

			call @DoCopy				; Execute a vdp command.

			jp .RedrawAll

.Left:			ld hl, (SelectorMapCursorX)
			dec hl
			ld a, l
			and h
			cp $FF
			jp z, .PrintCursor

			ld (SelectorMapCursorX), hl			

			ld de, (SelectorMapScrollLeft)
			and a
			sbc hl, de
			jp nc, .PrintCursor

			ld de, (SelectorMapScrollLeft)
			dec de
			ld (SelectorMapScrollLeft), de

			ld a, 1
			ld (SelectorMapDrawCustomMode), a	; 0 = draw all, 1 = draw column number, 2 = draw row number.
			ld (SelectorMapDrawCustomNumber), de

			ld a, (IsOnPaletteScreenMode)
			and a
			ld hl, .DoCopyDataLeftx2x2y
			jr z, .LJ1
			ld hl, .DoCopyDataLeftx2x2ySc7

.LJ1:			ld a, (SelectorLinkedIndexatorHeightVisual)
			cp 32
			ld b, 1
			jr z, .LZ1
			
			dec b

.LZ1:			ld a, (SelectorLinkedIndexatorWidthVisual)
			cp 32
			set 1, b
			jr z, .LZ2

			res 1, b

.LZ2:			ld a, b

			add a,a
			add a,a
			add a,a
			add a,a
			sub b
			add a,l
			ld l, a
			ld a, h
			adc a, 0
			ld h, a

			call @DoCopy				; Execute a vdp command.

			jp .RedrawAll

.Up:			ld hl, (SelectorMapCursorY)
			dec hl
			ld a, l
			and h
			cp $FF
			jp z, .PrintCursor

			ld (SelectorMapCursorY), hl			

			ld de, (SelectorMapScrollTop)
			and a
			sbc hl, de
			jp nc, .PrintCursor

			ld de, (SelectorMapScrollTop)
			dec de
			ld (SelectorMapScrollTop), de

			ld a, 2
			ld (SelectorMapDrawCustomMode), a	; 0 = draw all, 1 = draw column number, 2 = draw row number.
			ld (SelectorMapDrawCustomNumber), de

			ld a, (IsOnPaletteScreenMode)
			and a
			ld hl, .DoCopyDataUpx2x2y
			jr z, .UJ1
			ld hl, .DoCopyDataUpx2x2ySc7

.UJ1:			ld a, (SelectorLinkedIndexatorHeightVisual)
			cp 32
			ld b, 1
			jr z, .UZ1
			
			dec b

.UZ1:			ld a, (SelectorLinkedIndexatorWidthVisual)
			cp 32
			set 1, b
			jr z, .UZ2

			res 1, b

.UZ2:			ld a, b

			add a,a
			add a,a
			add a,a
			add a,a
			sub b
			add a,l
			ld l, a
			ld a, h
			adc a, 0
			ld h, a

			call @DoCopy				; Execute a vdp command.

			jp .RedrawAll

.Down:			ld hl, (SelectorMapCursorY)
			inc hl
			ld a, l
			or h
			jp z, .PrintCursor

			ld de, (SelectorMapBlocksHeight)
			push hl
			sbc hl, de
			pop hl
			jp nc, .PrintCursor

			ld (SelectorMapCursorY), hl			

			ld de, (SelectorMapLastRowDrawn)
			and a
			sbc hl, de
			jp z, .PrintCursor
			jp c, .PrintCursor

			ld de, (SelectorMapScrollTop)
			inc de
			ld (SelectorMapScrollTop), de			

			ld a, 2
			ld (SelectorMapDrawCustomMode), a	; 0 = draw all, 1 = draw column number, 2 = draw row number.

			ld hl, (SelectorMapCursorY)
			ld (SelectorMapDrawCustomNumber), hl

			ld a, (IsOnPaletteScreenMode)
			and a
			ld hl, .DoCopyDataDownx2x2y
			jr z, .DJ1
			ld hl, .DoCopyDataDownx2x2ySc7

.DJ1:			ld a, (SelectorLinkedIndexatorHeightVisual)
			cp 32
			ld b, 1
			jr z, .DZ1
			
			dec b

.DZ1:			ld a, (SelectorLinkedIndexatorWidthVisual)
			cp 32
			set 1, b
			jr z, .DZ2

			res 1, b

.DZ2:			ld a, b
			add a,a
			add a,a
			add a,a
			add a,a
			sub b
			add a,l
			ld l, a
			ld a, h
			adc a, 0
			ld h, a

			call @DoCopy				; Execute a vdp command.

			jp .RedrawAll

.PrintWhereCursor:	ld a, c					; in C = 0 hide cursor, C <> 0 show cursor.
			ld (SelectorMapCursorShow), a

			ld de, (SelectorMapCursorY)		; It calculates the X/Y block address in the USERAREA.
			ld bc, (SelectorMapBlocksWidth)
			call @Mult32
			ex de, hl
			ld l, c
			ld h, b					; hlde = block ordinal number.

			ld bc, (SelectorMapCursorX)
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr z, .NoDoubler3

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; hlde = hlde * 2.

.NoDoubler3:		ld bc,(SelectorMapAddrLow)
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc,(SelectorMapAddrHigh)
			adc hl, bc				; hlde = MapBaseAddress + ((Y * RowSizeWidth) + X) * format. Format can be 8 or 16bits behaving as x1 or x2 respectively.

			call @USERAREA_RW			; Reads the map.
			ret c

			ld e, c
			ld d, b

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr nz, .F16b2
			ld d, 0					; If 8bits, trims DE.

.F16b2:			push de					; Saves the indexator's block number.
								; Now is time to calculate the visual position.
			ld hl, (SelectorMapCursorX)
			ld de, (SelectorMapScrollLeft)
			and a
			sbc hl, de
								; l = X offset in blocks.
			ld a, l
			and a
			jr z, .MJ1
			
			ld b, l
			ld a, (SelectorLinkedIndexatorWidthVisual)
			ld c, a
			xor a

.M1:			add a, c
			djnz .M1
			ld l, a

.MJ1:			push hl
			ld hl, (SelectorMapCursorY)
			ld de, (SelectorMapScrollTop)
			and a
			sbc hl, de
								; l = Y offset in blocks.
			ld a, l
			and a
			jr z, .MJ2
			
			ld b, l
			ld a, (SelectorLinkedIndexatorHeightVisual)
			ld c, a
			xor a

.M2:			add a, c
			djnz .M2
			ld l, a

.MJ2:			ex de,hl
			pop hl
			ld a, e
			add a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			ld h, a

			pop de					; Restores the indexator's block number.
								; Now it must match the LastDrawnColumn and Row to trig the cursor detection.
			ld bc, (SelectorMapLastRowDrawn)
			push bc
			ld bc, (SelectorMapLastColumnDrawn)
			push bc

			ld bc, (SelectorMapCursorX)
			ld (SelectorMapLastColumnDrawn), bc
			ld bc, (SelectorMapCursorY)
			ld (SelectorMapLastRowDrawn), bc

			call .DrawABlock			; in DE = Object number. in HL = visual position.

			pop hl
			ld (SelectorMapLastColumnDrawn), hl	; Restores the values.
			pop hl
			ld (SelectorMapLastRowDrawn), hl
			ret

.AreaRight:		ld hl, (SelectorMapLastColumnDrawn)	; It Calculates the screen width in blocks.
			ld de, (SelectorMapScrollLeft)
			and a
			sbc hl,de
								; HL = screen width in blocks - 1. It will be taken as a STEP.
			ld c, l
			ld b, h

			add hl, de				; scroll left = scroll left + screen width - 1.
								; HL = new Scroll Left.
			ld (SelectorMapScrollLeft), hl

			add hl, bc				; checks if the view will complete the screen.
			ld (SelectorMapCursorX), hl
			jr nc, .AROk				; 16bits overflow, where you are in the right edge of the widest map can happen.

			ld hl, (SelectorMapBlocksWidth)
			dec hl
			ld (SelectorMapCursorX), hl
			and a
			sbc hl, bc
			ld (SelectorMapScrollLeft), hl
			jp .RedrawAll

.AROk:			ld de, (SelectorMapBlocksWidth)
			and a
			sbc hl, de
			jp c, .RedrawAll

			dec de
			ld (SelectorMapCursorX), de
			ex de, hl
			sbc hl, bc
			ld (SelectorMapScrollLeft), hl
			jp nc, .RedrawAll			; If the map is too thin can overflow here (less than one screen width).

			ld hl, (SelectorMapBlocksWidth)
			dec hl
			ld (SelectorMapCursorX), hl
			ld hl, 0
			ld (SelectorMapScrollLeft), hl
			jp .RedrawAll

.AreaLeft:		ld hl, (SelectorMapLastColumnDrawn)	; It Calculates the screen width in blocks.
			ld de, (SelectorMapScrollLeft)
			and a
			sbc hl,de
								; HL = screen width in blocks - 1. It will be taken as a STEP.
			ld c, l
			ld b, h

			ld hl, (SelectorMapScrollLeft)
			sbc hl, bc
			jr c, .ALJ2

.ALJ1:			ld (SelectorMapScrollLeft), hl
			ld (SelectorMapCursorX), hl
			jp .RedrawAll

.ALJ2:			ld hl, 0
			jr .ALJ1

.AreaUp:		ld hl, (SelectorMapLastRowDrawn)	; It Calculates the screen height in blocks.
			ld de, (SelectorMapScrollTop)
			and a
			sbc hl,de
								; HL = screen height in blocks - 1. It will be taken as a STEP.
			ld c, l
			ld b, h

			ld hl, (SelectorMapScrollTop)
			sbc hl, bc
			jr c, .AUJ2

.AUJ1:			ld (SelectorMapScrollTop), hl
			ld (SelectorMapCursorY), hl
			jp .RedrawAll

.AUJ2:			ld hl,0
			jr .AUJ1

.AreaDown:		ld hl, (SelectorMapLastRowDrawn)	; It Calculates the screen height in blocks.
			ld de, (SelectorMapScrollTop)
			and a
			sbc hl,de
								; HL = screen height in blocks - 1. It will be taken as a STEP.
			ld c, l
			ld b, h

			add hl, de				; scroll top = scroll top + screen height - 1.
								; HL = new Scroll Top.
			ld (SelectorMapScrollTop), hl

			add hl, bc				; checks if the view will complete the screen.
			ld (SelectorMapCursorY), hl
			jr nc, .ADOk				; 16bits overflow, where you are in the botton edge of the largest map can happen.

			ld hl, (SelectorMapBlocksHeight)
			dec hl
			ld (SelectorMapCursorY), hl
			and a
			sbc hl, bc
			ld (SelectorMapScrollTop), hl
			jp .RedrawAll

.ADOk:			ld de, (SelectorMapBlocksHeight)
			and a
			sbc hl, de
			jp c, .RedrawAll

			dec de
			ld (SelectorMapCursorY), de
			ex de, hl
			sbc hl, bc
			ld (SelectorMapScrollTop), hl
			jp nc, .RedrawAll			; If the map is too thin can overflow here (less than one screen width).

			ld hl, (SelectorMapBlocksHeight)
			dec hl
			ld (SelectorMapCursorY), hl
			ld hl, 0
			ld (SelectorMapScrollTop), hl
			jp .RedrawAll

.HitHot:		sub '0'
			add a,a
			ld l, a
			ld h, 0
			ld de, SelectorIndexatorCursorHOT0
			add hl, de
			ld c,(hl)
			inc hl
			ld b,(hl)
			jp .HitExt

.FastBS:		call .SaveMapVars

			ld hl, (SelectorLinkedIndexatorAddrLow)	; In direct mapping it must be 0.
			ld de, (SelectorLinkedIndexatorAddrHigh)

			ld a, h
			or l
			or d
			or e
			jr nz, .FastBSUsingIndexator
			
			ld bc, (SelectorLinkedTileBunchIndex)

.FastBSJ1:		ld hl, (SelectorMapBunchIndex)
			ld (FastBunchBack), hl

			ld iy, BunchSelector.Selects
			jp @FarJumpToPage1

.FastBSUsingIndexator:	ld bc, (SelectorLinkedIndexatorBunchIndex)
			jr .FastBSJ1

.AttribSet:		ld hl, (SelectorMapBlockAttribsMask)

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr nz, .Map16bits

			ld h, 0

.Map16bits:		ld a, l
			or h
			jp nz, .IsAtt

			call @BEEP
			jp .PrintCursor

.AttErr:		call @BEEP
			jp .RedrawAll

.IsAtt:			ld ix, AttribSetData
			ld iy, MSGBOX
			call @FarCallToPage1
			jp c, .RedrawAll

			ld hl, MsgBoxBuffer

			ld a, (hl)
			call .GetsHexValue
			jr c, .AttErr

			rlca
			rlca
			rlca
			rlca
			ld d, a

			inc hl
			ld a, (hl)
			call .GetsHexValue
			jr c, .AttErr

			or d
			ld d, a

			inc hl
			ld a, (hl)
			call .GetsHexValue
			jr c, .AttErr

			rlca
			rlca
			rlca
			rlca
			ld e, a

			inc hl
			ld a, (hl)
			call .GetsHexValue
			jr c, .AttErr

			or e
			ld e, a
								; DE = Attribute CODE.
			ld hl, (SelectorMapBlockAttribsMask)	; Apply the attrib mask. Avoids the user to setup bits that are for the metatile ID.
			ld a, e
			and l
			ld e, a
			ld a, d
			and h
			ld d, a

			push de
			ld de, (SelectorMapCursorY)		; It calculates the X/Y map block address in the USERAREA.
			ld bc, (SelectorMapBlocksWidth)
			call @Mult32
			ex de, hl
			ld l, c
			ld h, b					; hlde = block ordinal number.

			ld bc, (SelectorMapCursorX)
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr z, .NoDoubler4

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; hlde = hlde * 2.

			ld bc,(SelectorMapAddrLow)
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc,(SelectorMapAddrHigh)
			adc hl, bc				; hlde = MapBaseAddress + ((Y * RowSizeWidth) + X) * format. Format can be 8 or 16bits behaving as x1 or x2 respectively.

			pop bc
			push hl
			push de
			push bc
			call @USERAREA_RW

			ld hl, (SelectorMapBlockGraphicsMask)
			ld a, c
			and l
			ld c, a
			ld a, b
			and h
			ld b, a
								; BC = metatile ID only.
			pop hl
			ld a, c					; Mix metatile ID and Attrib CODE.
			or l
			ld c, a
			ld a, b
			or h
			ld b, a

			pop de
			pop hl
			call @USERAREA_WW
			jp .RedrawAll

.NoDoubler4:		ld bc,(SelectorMapAddrLow)
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc,(SelectorMapAddrHigh)
			adc hl, bc				; hlde = MapBaseAddress + ((Y * RowSizeWidth) + X) * format. Format can be 8 or 16bits behaving as x1 or x2 respectively.

			pop bc					; Attribute ID.
			push hl
			push de
			push bc
			call @USERAREA_RB

			ld hl, (SelectorMapBlockGraphicsMask)
			and l
			ld c, a
								; C = metatile ID only.
			pop hl
			ld a, c					; Mix metatile ID and Attrib CODE.
			or l

			pop de
			pop hl
			call @USERAREA_WB
			jp .RedrawAll

.GetsHexValue:		cp 'a'
			jr c, .NoUpCase

			cp 'f'+1
			ccf
			ret c

			sub $20					; UpCase$().

.NoUpCase:		sub '0'
			ret c

			cp 10
			ccf
			ret nc

			sub 7
			ret c

			cp 10
			ret c					; Escapes if character was between '9' and 'A'.

			cp 16					; Error if character was >'F'.
			ccf
			ret

.Goto:			ld ix, GotoData
			ld iy, MSGBOX
			call @FarCallToPage1
			jp c, .RedrawAll

			ld hl, MsgBoxBuffer
			call @VAL
			jp nc, .GotoXOk

.GotoErr:		call @BEEP
			jp .RedrawAll

.GotoXOk:		ld hl, (SelectorMapBlocksWidth)		; DE = value inputed.
			dec hl
			sbc hl, de
			jr c, .GotoErr

			ld (CreatingWidth), de			; Save temporarily somewhere.

			ld ix, GotoYData
			ld iy, MSGBOX
			call @FarCallToPage1
			jp c, .RedrawAll

			ld hl, MsgBoxBuffer
			call @VAL
			jr c, .GotoErr

			ld hl, (SelectorMapBlocksHeight)	; DE = value inputed.
			dec hl
			sbc hl, de
			jr c, .GotoErr

			ld (SelectorMapCursorY), de
			ld hl,(CreatingWidth)
			ld (SelectorMapCursorX), hl

			ld hl, (SelectorMapLastColumnDrawn)	; It Calculates the screen width in blocks.
			ld de, (SelectorMapScrollLeft)
			and a
			sbc hl,de
			inc hl
			ex de, hl				; DE = screen width.

			ld hl, (SelectorMapBlocksWidth)
			and a
			sbc hl, de				; It calculates the last possible position for the Scroll Left.
			jr nc, .NoSLFix

			ld hl, 0				; Map too small ;)?.

.NoSLFix:		ld de, (SelectorMapCursorX)		; HL = last possible position for scroll left.

			push hl
			sbc hl, de
			pop hl

			ld (SelectorMapScrollLeft), hl
			jr c, .BiggerWasCrsX

			ld (SelectorMapScrollLeft), de

.BiggerWasCrsX:		ld hl, (SelectorMapLastRowDrawn)	; It Calculates the screen heigh in blocks.
			ld de, (SelectorMapScrollTop)
			and a
			sbc hl,de
			inc hl
			ex de, hl

			ld hl, (SelectorMapBlocksHeight)
			and a
			sbc hl, de				; It calculates the last possible position for the Scroll Top.
			jr nc, .NoSTFix

			ld hl, 0				; Map too small ;)?.

.NoSTFix:		ld de, (SelectorMapCursorY)		; HL = last possible position for scroll Top.

			push hl
			sbc hl, de
			pop hl

			ld (SelectorMapScrollTop), hl
			jp c, .RedrawAll

			ld (SelectorMapScrollTop), de
			jp .RedrawAll

.MapCopy:		ld a, (SelectorMapCopyStage)
			and a
			jp z, .CpyStageStart
			dec a
			jp z, .CpyStageEnd
								; Stage Marking Destination.
			ld hl, (SelectorMapCopyStopX)		; It must checks if the destination area don't overflows the map in any way.
			ld de, (SelectorMapCopyX)
			and a
			sbc hl, de				; HL = Source area width.

			ld de, (SelectorMapCursorX)
			add hl, de
			dec hl

			ld de, (SelectorMapBlocksWidth)
			and a
			sbc hl, de
			jp nc, .CSEErr

			ld hl, (SelectorMapCopyStopY)		; It must checks if the destination area don't overflows the map in any way.
			ld de, (SelectorMapCopyY)
			and a
			sbc hl, de				; HL = Source area height.

			ld de, (SelectorMapCursorY)
			add hl, de
			dec hl					; HL = last destination Y.

			ld de, (SelectorMapBlocksHeight)
			and a
			sbc hl, de
			jp nc, .CSEErr
								; Ok the copy operation is safe.
			ld hl, .CopyMenuData
			ld de, UserAreaCpyBuffer
			ld bc, .CopyMenuDataEnd - .CopyMenuData
			ldir

			ld ix, UserAreaCpyBuffer
			ld iy, MENUPOPUP
			call @FarCallToPage1
			jp c, .RedrawAll			; Escapes if the user pressed ESC.

			and a					; Menu COPY or CANCEL?.
			jp nz, .CopyCancel

			ld hl, (SelectorMapCursorY)		; COPY AREA FUNCTION.
			ld (SelectorMapDestinationY), hl
			ld hl, (SelectorMapCursorX)
			ld (SelectorMapDestinationXHome), hl	; As the X loop is the inner loop, it has a variable X"Home".
			ld hl, (SelectorMapCopyX)
			ld (SelectorMapSourceXHome), hl

			ld hl, (SelectorMapDestinationXHome)	; Lets check if X axis must be moved on forward or reverse.
			ld de, (SelectorMapSourceXHome)
			and a
			sbc hl, de
			ld c, 0
			jr c, .NoReverseX
								; X axis on reverse copy.
			inc c					; C bit 0 = 1 reverse on the X axis.
			ld de, (SelectorMapSourceXHome)
			ld hl, (SelectorMapCopyStopX)
			sbc hl, de				; It calculates the width to copy.

			push hl
			ld de, (SelectorMapSourceXHome)
			add hl, de
			dec hl
			ld (SelectorMapSourceXHome), hl
			pop hl

			ld de, (SelectorMapDestinationXHome)
			add hl, de
			dec hl
			ld (SelectorMapDestinationXHome), hl	; As reverse, set up the destination X home on the right of destination area.

			ld hl, (SelectorMapCopyX)
			dec hl
			ld (SelectorMapCopyStopX), hl		; Place the X Stop at the left overflow of the source area.

.NoReverseX:		ld hl, (SelectorMapDestinationY)	; in which vertical way forward or reverse? to perform the copy.
			ld de, (SelectorMapCopyY)
			and a
			sbc hl, de
			ex de, hl
			jr c, .YLoop
								; Reverse on the Y axis.
			set 1, c				; C bit 1 = 1 reverse on the Y axis.

			ld de, (SelectorMapCopyY)
			ld hl, (SelectorMapCopyStopY)
			sbc hl, de				; It calculates the height to copy.

			ld de, (SelectorMapDestinationY)
			add hl, de
			dec hl
			ld (SelectorMapDestinationY), hl	; It reverses the destination Y to the bottom of destination area.

			ld hl, (SelectorMapCopyStopY)
			dec hl					; Current Y = bottom of the source area.

			push hl
			ld hl, (SelectorMapCopyY)
			dec hl
			ld (SelectorMapCopyStopY), hl		; It reverses the stop Y position.
			pop hl

.YLoop:			push hl					; HL = Y source position.
			ld hl, (SelectorMapDestinationXHome)
			ld (SelectorMapDestinationX), hl

			ld hl, (SelectorMapSourceXHome)
			pop de

.XLoop:			push de					; DE = Y source position.
			push bc
			push hl					; HL = X source position.

			push hl					; Reads the map's blocks. in DE = Y position of the block.
			ld bc, (SelectorMapBlocksWidth)
			call @Mult32
			ex de, hl
			ld l, c
			ld h, b					; hlde = block ordinal number.
			pop bc					; in BC = X position of the block.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr z, .NoDoublerCpy

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; hlde = hlde * 2.

.NoDoublerCpy:		ld bc,(SelectorMapAddrLow)
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc,(SelectorMapAddrHigh)
			adc hl, bc				; hlde = MapBaseAddress + ((Y * RowSizeWidth) + X) * format. Format can be 8 or 16bits behaving as x1 or x2 respectively.
								; hlde = in userarea current block address.
			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr nz, .Read16bitsCpy

			call @USERAREA_RB			; Map record = 8bits.
			ld c, a
			jr .WriteCpy

.Read16bitsCpy:		call @USERAREA_RW			; Map record = 16bits.

.WriteCpy:		push bc					; Save the data.

			ld de, (SelectorMapDestinationY)	; Writes the map's blocks. in DE = Y position of the block.
			ld bc, (SelectorMapBlocksWidth)
			call @Mult32
			ex de, hl
			ld l, c
			ld h, b					; hlde = block ordinal number.
			ld bc, (SelectorMapDestinationX)	; in BC = X position of the block.
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc, 0
			adc hl,bc

			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits
			jr z, .NoDoublerCpy2

			ex de,hl
			add hl,hl
			ex de,hl
			adc hl,hl				; hlde = hlde * 2.

.NoDoublerCpy2:		ld bc,(SelectorMapAddrLow)
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc,(SelectorMapAddrHigh)
			adc hl, bc				; hlde = MapBaseAddress + ((Y * RowSizeWidth) + X) * format. Format can be 8 or 16bits behaving as x1 or x2 respectively.
								; hlde = in userarea current block address.
			ld a, (SelectorMapFormat)
			and FormatID.MapScene16Bits

			pop bc					; Restores the data.

			jr nz, .Write16bitsCpy

			ld a, c
			call @USERAREA_WB
			jr .CompleteCpy

.Write16bitsCpy:	call @USERAREA_WW

.CompleteCpy:		pop hl
			pop bc

			ld de, (SelectorMapDestinationX)
			bit 0, c
			inc hl
			inc de
			jr z, .XForward

			dec hl
			dec hl
			dec de
			dec de

.XForward:		ld (SelectorMapDestinationX), de

			push hl
			ld de, (SelectorMapCopyStopX)
			and a
			sbc hl, de
			pop hl
			pop de
			jp nz, .XLoop

			ld hl, (SelectorMapDestinationY)
			bit 1, c
			inc de
			inc hl
			jr z, .YForward

			dec de
			dec de
			dec hl
			dec hl

.YForward:		ld (SelectorMapDestinationY), hl

			push de					; DE = Y source current position.
			ld hl, (SelectorMapCopyStopY)
			sbc hl, de
			pop hl
			jp nz, .YLoop

.CopyCancel:		xor a
			ld (SelectorMapCopyStage), a

			jp .RedrawAll

.CpyStageStart:		ld hl, (SelectorMapCursorX)
			ld (SelectorMapCopyX), hl

			ld hl, (SelectorMapCursorY)
			ld (SelectorMapCopyY), hl

			ld a, 1
			ld (SelectorMapCopyStage), a
			jp .PrintCursor

.CpyStageEnd:		ld hl, (SelectorMapCursorX)
			ld de, (SelectorMapCopyX)
			and a
			sbc hl, de
			jr nc, .CSEOk1

.CSEErr:		call @BEEP
			jp .PrintCursor

.CSEOk1:		ld hl, (SelectorMapCursorX)
			inc hl
			ld (SelectorMapCopyStopX), hl

			ld hl, (SelectorMapCursorY)
			ld de, (SelectorMapCopyY)
			and a
			sbc hl, de
			jr c, .CSEErr

			ld hl, (SelectorMapCursorY)
			inc hl
			ld (SelectorMapCopyStopY), hl

			ld a, 2
			ld (SelectorMapCopyStage), a
			jp .RedrawAll

.CopyMenuData:		DB 80,80,"Copy",0,"Cancel",0,0
.CopyMenuDataEnd:

.DoCopyDataDownx2x2y:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 16,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     14*16,$00,7*16,$00,   0,0,$D0
.DoCopyDataDownx2x4y:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 32,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     14*16,$00,3*32,$00,   0,0,$D0
.DoCopyDataDownx4x2y:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 16,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     7*32,$00,7*16,$00,   0,0,$D0
.DoCopyDataDownx4x4y:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 32,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     7*32,$00,3*32,$00,   0,0,$D0

.DoCopyDataUpx2x2y:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 7*16 -1,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 8*16 -1,$00,     14*16,$00,7*16,$00,   0,$08,$D0
.DoCopyDataUpx2x4y:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 3*32 -1,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4*32 -1,$00,     14*16,$00,3*32,$00,   0,$08,$D0
.DoCopyDataUpx4x2y:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 7*16 -1,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 8*16 -1,$00,      7*32,$00,7*16,$00,   0,$08,$D0
.DoCopyDataUpx4x4y:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 3*32 -1,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4*32 -1,$00,      7*32,$00,3*32,$00,   0,$08,$D0

.DoCopyDataLeftx2x2y:	DB 13*16 -1,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    14*16 -1,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     13*16,$00,8*16,$00,   0,$04,$D0
.DoCopyDataLeftx2x4y:	DB 13*16 -1,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    14*16 -1,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     13*16,$00,4*32,$00,   0,$04,$D0
.DoCopyDataLeftx4x2y:	DB 6*32 -1,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    7*32 -1,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     6*32,$00,8*16,$00,   0,$04,$D0
.DoCopyDataLeftx4x4y:	DB 6*32 -1,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    7*32 -1,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     6*32,$00,4*32,$00,   0,$04,$D0

.DoCopyDataRightx2x2y:	DB 16,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     13*16,$00,8*16,$00,   0,0,$D0
.DoCopyDataRightx2x4y:	DB 16,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     13*16,$00,4*32,$00,   0,0,$D0
.DoCopyDataRightx4x2y:	DB 32,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     6*32,$00,8*16,$00,   0,0,$D0
.DoCopyDataRightx4x4y:	DB 32,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     6*32,$00,4*32,$00,   0,0,$D0

.DoCopyDataDownx2x2ySc7:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 16,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (14*16*2) mod 256,$01,7*16,$00,   0,0,$D0
.DoCopyDataDownx2x4ySc7:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 32,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (14*16*2) mod 256,$01,3*32,$00,   0,0,$D0
.DoCopyDataDownx4x2ySc7:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 16,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (7*32*2) mod 256,$01,7*16,$00,   0,0,$D0
.DoCopyDataDownx4x4ySc7:	DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 32,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (7*32*2) mod 256,$01,3*32,$00,   0,0,$D0

.DoCopyDataUpx2x2ySc7:		DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 7*16 -1,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 8*16 -1,$00,     (14*16*2) mod 256,(14*16*2)/256,7*16,$00,   0,$08,$D0
.DoCopyDataUpx2x4ySc7:		DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 3*32 -1,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4*32 -1,$00,     (14*16*2) mod 256,(14*16*2)/256,3*32,$00,   0,$08,$D0
.DoCopyDataUpx4x2ySc7:		DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 7*16 -1,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 8*16 -1,$00,     (7*32*2) mod 256,(7*32*2)/256,7*16,$00,   0,$08,$D0
.DoCopyDataUpx4x4ySc7:		DB $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 3*32 -1,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator + 4*32 -1,$00,     (7*32*2) mod 256,(7*32*2)/256,3*32,$00,   0,$08,$D0

.DoCopyDataLeftx2x2ySc7:	DB ((13*16 -1)*2) mod 256,((13*16 -1)*2)/256,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    ((14*16 -1)*2) mod 256,((14*16 -1)*2)/256,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (13*16*2) mod 256,(13*16*2)/256,8*16,$00,   0,$04,$D0
.DoCopyDataLeftx2x4ySc7:	DB ((13*16 -1)*2) mod 256,((13*16 -1)*2)/256,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    ((14*16 -1)*2) mod 256,((14*16 -1)*2)/256,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (13*16*2) mod 256,(13*16*2)/256,4*32,$00,   0,$04,$D0
.DoCopyDataLeftx4x2ySc7:	DB ((6*32 -1)*2) mod 256,((6*32 -1)*2)/256,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    ((7*32 -1)*2) mod 256,((7*32 -1)*2)/256,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (6*32*2) mod 256,(6*32*2)/256,8*16,$00,   0,$04,$D0
.DoCopyDataLeftx4x4ySc7:	DB ((6*32 -1)*2) mod 256,((6*32 -1)*2)/256,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    ((7*32 -1)*2) mod 256,((7*32 -1)*2)/256,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (6*32*2) mod 256,(6*32*2)/256,4*32,$00,   0,$04,$D0

.DoCopyDataRightx2x2ySc7:	DB 16*2,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (13*16*2) mod 256,(13*16*2)/256,8*16,$00,   0,0,$D0
.DoCopyDataRightx2x4ySc7:	DB 16*2,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (13*16*2) mod 256,(13*16*2)/256,4*32,$00,   0,0,$D0
.DoCopyDataRightx4x2ySc7:	DB 32*2,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (6*32*2) mod 256,(6*32*2)/256,8*16,$00,   0,0,$D0
.DoCopyDataRightx4x4ySc7:	DB 32*2,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,    $00,$00,ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator,$00,     (6*32*2) mod 256,(6*32*2)/256,4*32,$00,   0,0,$D0






_GetsBunchInfo:		push de					; In ix = Buffer base address, in e = description level. 0 = only names, 1 = names + type, > 1 names + type + raw size and linking.
			push bc
			call @GETBUNCH_BASEADDR
			exx
			pop bc
			pop de
			exx
			ret c
								; hlde = bunch base address.
			push hl
			push de					; Saves the bunch base addr for later use.

			ld b,16					; Maximun name size.

.NameLoop:		push hl
			push de
			call @USERAREA_RB			; MODs (hlde).
			pop de
			pop hl
			jr nc , .Ok2

			pop de					; Error, escapes!.
			pop hl
			ret

.Ok2:			ld (ix+0), a
			inc ix
			and a
			jr z, .NullChr
		
			inc de
			ld a,e
			or d
			jr nz, .J1
			inc hl

.J1:			djnz .NameLoop

			ld (ix+0), 0
			inc ix

.NullChr:		pop de
			pop hl					; Restores the bunch base address.
			exx
			ld a, e
			exx
			and a
			ret z					; Escapes if only want the name.

			ld bc, BunchHeader.FormatID
			ex de,hl
			add hl,bc
			ex de,hl
			ld bc,0
			adc hl,bc				; hlde = original base addr + .FormatID.

			call @USERAREA_RB			; It reads the .FormatID.
			ret c

			ld hl, .StrTSc2				; Adds more description in the list.
			cp FormatID.TileSc2
			jp z, .PrintType
			ld hl, .StrTSc5
			cp FormatID.TileSc5
			jp z, .PrintType
			ld hl, .StrTSc5_16
			cp FormatID.TileSc5_16
			jp z, .PrintType
			ld hl, .StrTSc5_32
			cp FormatID.TileSc5_32
			jp z, .PrintType
			ld hl, .StrTSc8
			cp FormatID.TileSc8
			jp z, .PrintType
			ld hl, .StrTSc8_16
			cp FormatID.TileSc8_16
			jp z, .PrintType
			ld hl, .StrTSc8_32
			cp FormatID.TileSc8_32
			jp z, .PrintType
			ld hl, .StrSSM2
			cp FormatID.SpriteMSX2
			jp z, .PrintType
			ld hl, .StrSSM1
			cp FormatID.SpriteMSX1
			jp z, .PrintType
			ld hl, .StrPSM2
			cp FormatID.PaletteSet
			jp z, .PrintType
			ld hl, .StrImportedImage
			cp FormatID.ImageFileHolder
			jp z, .PrintType
			ld hl, .StrFileHolder
			cp FormatID.FileHolder
			jp z, .PrintType

			ld e,a
			and FormatID.MapIndIDMask
			cp FormatID.MapIndID
			jp z, .Ind

			and FormatID.MapSceneIDMask
			cp FormatID.MapSceneID
			jp z, .Map
			
			jr .MoreDescription			; Unknown format, escapes.

.PrintType:		call .AddType

.MoreDescription:	exx
			ld a, e
			exx
			dec a
			ret z
								; Wants more description.
			exx
			push bc
			call @GETBUNCH_LINKADDR
			jr c, .MDErr

			call @USERAREA_RDW
			jr nc, .MDJ1
	
.MDErr:			pop bc
			ret
								; hlbc = bunch size.
.MDJ1:			ld e, c
			ld d, b

			ld bc, BunchHeader.Size
			ex de, hl
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc
								; hlde = bunch raw size.
			push de
			push hl

			ld hl, .StrRawSize
			call .StringAdd

			pop hl
			pop de

			dec ix					; Overwrites the last nullchar.
			call _STR.Custom

			ld hl, .StrBytes
			call .StringAdd
			pop bc

			call @GETBUNCH_BASEADDR
			ret c

			ld bc, BunchHeader.Customs
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc

			push hl
			push de
			ld hl, .StrLinkedTo
			call .StringAdd
			pop de
			pop hl

			dec ix					; Overwrites the last nullchar.

.NameLoop2:		push hl
			push de
			call @USERAREA_RB			; MODs (hlde).
			pop de
			pop hl
			ret c

			ld (ix+0), a
			inc ix
			and a
			ret z
		
			inc de
			ld a,e
			or d
			jr nz, .NL2J1
			inc hl

.NL2J1:			djnz .NameLoop2

			ld (ix+0), 0
			inc ix
			ret

.Map:			ld hl, .StrCommentOpen
			call .StringAdd

			ld hl, .StrMap
			call .StringAdd

			bit 0,e
			ld hl, .StrMap8B
			jr z, .MapJ1
			ld hl, .StrMap16B

.MapJ1:			call .StringAdd

			ld hl, .StrCommentClose
			call .StringAdd
			jp .MoreDescription

.Ind:			ld hl, .StrCommentOpen
			call .StringAdd

			ld hl, .StrInd
			call .StringAdd

			bit 1,e
			ld a, '2'
			jr z, .J2
			ld a, '4'

.J2:			ld (ix-1), a
			ld (ix+0), 'x'
			inc ix

			bit 0,e
			ld a, '2'
			jr z, .J3
			ld a, '4'

.J3:			ld (ix+0), a
			inc ix
			ld (ix+0), 'y'
			inc ix
			ld (ix+0), 0
			inc ix

			bit 2,e
			ld hl, .StrInd256Tiles
			jr z, .J4
			ld hl, .StrIndMoreTiles

.J4:			call .StringAdd

			bit 3,e
			ld hl, .StrInd256Entry
			jr z, .J5
			ld hl, .StrIndMoreEntry

.J5:			call .StringAdd

			ld hl, .StrCommentClose
			call .StringAdd
			jp .MoreDescription

.AddType:		push hl					; Pointer to type description string.
			ld hl, .StrCommentOpen
			call .StringAdd
			pop hl
			call .StringAdd
			ld hl, .StrCommentClose

.StringAdd:		dec ix					; It overwrites the last nullchar.

.StrLoop:		ld a,(hl)
			ld (ix+0),a
			inc ix
			inc hl
			and a
			jr nz, .StrLoop
			ret

.StrCommentOpen:	DB " ( ", 0
.StrCommentClose:	DB " )", 0
.StrTSc2:		DB "TileSet Sc2", 0
.StrTSc5:		DB "TileSet Sc5 8x8", 0
.StrTSc5_16:		DB "TileSet Sc5 16x16", 0
.StrTSc5_32:		DB "TileSet Sc5 32x32", 0
.StrTSc8:		DB "TileSet Sc8 8x8", 0
.StrTSc8_16:		DB "TileSet Sc8 16x16", 0
.StrTSc8_32:		DB "TileSet Sc8 32x32", 0
.StrSSM2:		DB "SpriteSet >=Sc4", 0
.StrSSM1:		DB "SpriteSet MSX1", 0
.StrPSM2:		DB "PaletteSet", 0
.StrImportedImage:	DB "Image holder", 0
.StrFileHolder:		DB "File holder", 0
.StrInd:		DB "Indexator ", 0
.StrInd256Tiles:	DB " 256t ", 0
.StrIndMoreTiles:	DB " >256t ", 0
.StrInd256Entry:	DB "256e", 0
.StrIndMoreEntry:	DB ">256e", 0
.StrMap:		DB "Map record width ", 0
.StrMap8B:		DB "8bits", 0
.StrMap16B:		DB "16bits", 0
.StrLinkedTo:		DB ", Linked to: ", 0
.StrRawSize:		DB " Raw size ", 0
.StrBytes:		DB " bytes", 0






_ProjectInfo:		ld bc,0

.NextPage:		push bc
			ld de, 256 * (ConsoleStartLine + BunchLowerSeparator)

			push de
			ex de, hl
			ld a, (MenuForeColor)
			ld (RenderForeColor), a
			ld a, (MenuBackGroundColor)
			ld (RenderBackColor), a
			ld bc, 256*192
			call @BLOCKFILL
			pop de
			pop bc

.Loop:			push bc
			push de
			ld ix, UserAreaCpyBuffer
			ld e, 2					; Description level.
			call _GetsBunchInfo
			pop de
			pop bc
			jr c, .FinalData

			push bc
			ld hl, UserAreaCpyBuffer
			call @STRDRAWZ

			ld e, 0
			ld a, d
			add a, 16
			ld d, a					; CRLF x2.
			cp 192
			jr c, .Next

.KB:			push de
			call @INKEY
			pop de
			jr c, .KB

			jr .NextPage

.Next:			pop bc

			inc bc					; bunch index = bunch index + 1.
			jr .Loop

.FinalData:		push de

			call _GETUSERAREA_FREESPACE
								; hlde = freespace in the UserArea.
			ld ix, UserAreaCpyBuffer
			call _STR.Custom

			ld hl, .StrFree
			call .StringAdd
			pop de
			
			ld hl, UserAreaCpyBuffer
			call @STRDRAWZ

.KB2:			call @INKEY
			jr c, .KB2

			ret

.StringAdd:		dec ix					; It overwrites the last nullchar.

.StrLoop:		ld a,(hl)
			ld (ix+0),a
			inc ix
			inc hl
			and a
			jr nz, .StrLoop
			ret

.StrFree:		DB " RAM bytes free.",0






_Files:			ld c, $1A				; Out [CF] = 1, error.
			ld de, DTA
			call @BDOS

			ld hl, FCB				; First it creates the FCB.
			ld de, FCB + 1
			ld bc, 37 - 1				; FCB size = 37 bytes.
			ld (hl),0
			ldir

			ld hl, FCB + 1
			ld de, FCB + 2
			ld bc, 10
			ld (hl), '?'
			ldir

			ld c, $11
			ld de, FCB
			call @BDOS
			and a
			jr z, .NextPage

.Error:			ld a, (DiskErrorCode)			; Error, checks if it is an I/O error to differentiate from an empty directory.
			and a
			ret z

			ld iy, MENUBAR.ErrorDiskError		; It is an I/O error.
			call @FarCallToPage1
			scf
			ret

.NextPage:		ld de, 256 * (ConsoleStartLine + BunchLowerSeparator)			

			push de
			ex de, hl
			ld a, (MenuForeColor)
			ld (RenderForeColor), a
			ld a, (MenuBackGroundColor)
			ld (RenderBackColor), a
			ld bc, 256*192
			call @BLOCKFILL
			pop de

.Loop:			ld hl, DTA + 1
			ld b, 8  				; filename length.
			call @STRDRAW

			ld a, e
			add a, 6
			ld e, a					; Left one space.

			ld hl, DTA + 1 + 8
			ld b, 3  				; filename length.
			call @STRDRAW

			ld e, 0
			ld a, d
			add a, 8
			ld d, a					; CRLF x2.
			cp 192
			jr c, .Next

.KB:			push de
			call @INKEY
			pop de
			jr c, .KB

			cp 27					; Checks if pressed ESC.
			ret z

			push de
			ld c, $12
			ld de, FCB
			call @BDOS
			and a
			pop de
			ret nz

			jr .NextPage

.Next:			push de
			ld c, $12
			ld de, FCB
			call @BDOS
			pop de
			and a
			jr z, .Loop

.End:			ld a, (DiskErrorCode)			; Error, checks if it is an I/O error to differentiate from the end of the directory.
			and a
			jr nz, .Error

			call @INKEY
			jr c, .End
			ret






_SetCompileOptions:	ld ix, UserAreaCpyBuffer
			ld (ix+0), 8
			ld (ix+1), ConsoleStartLine + 18	; Aligning with where appears the "Save ..." menuitem.
			inc ix
			inc ix
			ld iy, ListsBunchs
			call @FarCallToPage1
			ret c
			jr .ListOk

.ErrData:		ld iy, MENUBAR.ErrDataCorrupt
			call @FarCallToPage1
			scf
			ret

.ListOk:		ld ix, UserAreaCpyBuffer
			ld iy, MENUPOPUP
			call @FarCallToPage1
			ret c					; The user pressed ESC.

			ld c, a
			ld b, 0					; BC = Bunch address.

.FromCompileJump:	ld (CreatingBunchID),bc			; Saves the Bunch Index for later access.

			call @GETBUNCH_BASEADDR
			jr c, .ErrData

			push hl
			push de
			ld bc, CompileOpts.Configured		; Test if it has already compile information.
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc

			call @USERAREA_RB
			pop de
			pop hl
			jr c, .ErrData

			and a
			jp z, .NoPreviousConfig
								; It has already information about how to compile it.
			push hl
			push de
			ld bc, CompileOpts.SaveAs
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc

			call @USERAREA_RB
			pop de
			pop hl
			jr c, .ErrData

			push hl
			ld hl, MsgBoxCheckValues
			and a					; A = value readed of the .SaveAs record in the header.
			ld (hl), $FF				; It fills up the optionboxes values of the msgbox.
			jr z, .J1
			ld (hl), 0

.J1:			inc hl
			cp 1
			ld (hl), $FF
			jr z, .J2
			ld (hl), 0

.J2:			inc hl
			cp 2
			ld (hl), $FF
			jr z, .J3
			ld (hl), 0

.J3:			pop hl

			ld a, $FF				; loads the textbox.text property manually.
			ld (MsgBoxDontStartBuffer), a

			ld bc, CompileOpts.Filename
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc

			exx
			ld hl, MsgBoxBuffer
			exx
			ld b, 12

.FillUpNameLoop:	push hl
			push de
			call @USERAREA_RB
			pop de
			pop hl
			jp c, .ErrData

			exx
			ld (hl), a
			inc hl
			exx
			and a
			jr z, .FindsNullChar
			
			inc de
			ld a, e
			or d
			jr nz, .FillUpNameJ1
			inc hl

.FillUpNameJ1:		djnz .FillUpNameLoop

			exx
			ld (hl), 0

.FindsNullChar:		ld ix, BoxCompileOptions		; Presents the MsgBox.
			ld iy, MSGBOX
			call @FarCallToPage1
			ret c
								; The user didn't escaped, to normalize inputs and save inputs in the header.
			ld hl, MsgBoxBuffer
			ld iy, NormalizeFileName
			call @FarCallToPage1
			jr nc, .FNOk

			ld iy, MENUBAR.ErrBadFN
			call @FarCallToPage1
			scf
			ret

.FNOk:			ld hl, MsgBoxCheckValues
			ld b, 0
			ld a, (hl)
			and a
			jr nz, .OptionSaveAs

			inc hl
			inc b
			ld a, (hl)
			and a
			jr nz, .OptionSaveAs

			inc b

.OptionSaveAs:		push bc					; B = SaveAs selection.

			push bc
			ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR
			pop af

			push hl
			push de
			ld bc, CompileOpts.SaveAs
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, 0
			adc hl, bc

			call @USERAREA_WB			; Save the compile as format selection.
			pop de
			pop hl

			push hl
			push de					; Save the bunch base address.

			ld bc, CompileOpts.Filename
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc

			exx
			ld hl, MsgBoxBuffer
			exx
			ld b, 12

.SetUpCompileNameLoop:	exx
			ld a, (hl)
			inc hl
			exx
			push hl
			push de
			call @USERAREA_WB
			pop de
			pop hl

			inc de
			ld a, e
			or d
			jr nz, .SetUpCNJ1
			inc hl

.SetUpCNJ1:		djnz .SetUpCompileNameLoop

			xor a
			call @USERAREA_WB			; write the nullchar in the 13rd position.

			pop de
			pop hl					; Restores the bunch base address.

			push hl
			push de
			ld bc, CompileOpts.Configured		; Test if it has already compile information.
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc

			ld a, $FF
			call @USERAREA_WB			; It points that this bunch has now a configuration.

			pop de					; If the format is for BLOAD, here we needs to check that and asks the base address for the header.
			pop hl

			pop af					; Restore the SaveAs value.

			cp 1					; Checks if it is the bload format.
			scf
			ccf					; Reset CF.
			ret nz
								; ok, it is.
			ld bc, CompileOpts.BSaveStartAddr
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, 0
			adc hl, bc

			push hl
			push de
			call @USERAREA_RW
								; BC = BSAVE start address.
			ld e, c
			ld d, b
			ld hl, 0
			call _STR				; Converts it to text. out string on STR_Buffer.

			ld hl, STR_Buffer
			ld de, MsgBoxBuffer
			
			ld a, $FF				; loads the textbox.text property manually.
			ld (MsgBoxDontStartBuffer), a

.CpyLoop:		ld a, (hl)
			ld (de), a
			inc hl
			inc de
			and a
			jr nz, .CpyLoop

			ld ix, BoxCompileOptions2
			ld iy, MSGBOX
			call @FarCallToPage1
			pop de
			pop hl
			ret c					; Escapes if the user pressed ESC.
								; HLDE address of the .BSaveStartAddr record.
			push hl
			push de
			ld hl, MsgBoxBuffer
			call @VAL
			ld c, e
			ld b, d
			pop de
			pop hl
			jr nc, .ValOk 

			ld iy, MENUBAR.ErrOverFlow
			call @FarCallToPage1
			scf
			ret

.ValOk:			call @USERAREA_WW
			jp c, .ErrData

			and a
			ret

.NoPreviousConfig:	ld hl, MsgBoxCheckValues
			ld (hl), $FF
			inc hl
			ld (hl), 0
			inc hl
			ld (hl), 0
			jp .FindsNullChar			; meaningless label for this jump.






_CompileAll:		ld bc, 0

.Loop:			push bc
			call @GETBUNCH_BASEADDR
			pop bc
			ret c

			push bc
			ld iy, __Compile.GetsIn
			call @FarCallToPage3
			pop bc
			ret c

			inc bc
			jr .Loop






_PuzSort2x2:		ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber),hl
			ld iy , GetObjectRawAddress		; In (SelectorCurrentObjectNumber). Out hlde = address.
			call @FarCallToPage1
			ret c

			ld ix, PuzzlerIndexationBuffer
			ld b, 16

.Loop:			ld a, 14
			cp b
			jr c, .NoSkips
			ld a, 12
			cp b
			jr c, .Skips
			ld a, 10
			cp b
			jr c, .NoSkips
			
.Skips:			xor a
			ld (ix+0),a
			ld (ix+1),a
			ld (ix+2),a
			ld (ix+3),a
			ld (ix+4),a
			ld (ix+5),a
			ld (ix+6),a
			push bc
			jr .Skipped

.NoSkips:		ld (ix+0),e
			ld (ix+1),d
			ld (ix+2),l
			ld (ix+3),h
			ld a,(SelectorCurrentFormat)
			ld (ix+4),a
			push bc
			ld bc, (SelectorCurrentObjectNumber)
			ld (ix+5),c
			ld (ix+6),b
			inc bc
			ld (SelectorCurrentObjectNumber),bc

			call _GETOBJECTSIZE			; In a = format, out BC = object size.
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc				; hlde = hlde + bc.

.Skipped:		ld bc, 7
			add ix, bc
			pop bc

			djnz .Loop
			ret





_PuzSort4x4:		ld hl, (SelectorCursorObjectNumber)
			ld (SelectorCurrentObjectNumber),hl
			ld iy , GetObjectRawAddress		; In (SelectorCurrentObjectNumber). Out hlde = address.
			call @FarCallToPage1
			ret c

			ld ix, PuzzlerIndexationBuffer
			ld b, 16

.Loop:			ld (ix+0),e
			ld (ix+1),d
			ld (ix+2),l
			ld (ix+3),h
			ld a,(SelectorCurrentFormat)
			ld (ix+4),a
			push bc
			ld bc, (SelectorCurrentObjectNumber)
			ld (ix+5),c
			ld (ix+6),b
			inc bc
			ld (SelectorCurrentObjectNumber),bc

			ld bc, 7
			add ix, bc

			call _GETOBJECTSIZE			; In a = format, out BC = object size.
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc				; hlde = hlde + bc.
			pop bc

			djnz .Loop
			ret






_TileEdUp:		call _Finds_EditorInPuzzler
			jp c, @BEEP				; Not found ? BEEP.

			ld a, c
			cp 4
			jp c, @BEEP				; there is no upper tile ? BEEP.

			sub 4

.Sav:			push af
			call @EDITORSAVE
			pop af
			jp _GetPuzTileData






_TileEdDown:		call _Finds_EditorInPuzzler
			jp c, @BEEP				; Not found ? BEEP.

			ld a, c
			cp 12
			jp nc, @BEEP				; there is no bottom tile ? BEEP.

			add a, 4

			jr _TileEdUp.Sav






_TileEdLeft:		call _Finds_EditorInPuzzler
			jp c, @BEEP				; Not found ? BEEP.

			ld a, c
			and 3
			jp z, @BEEP				; there is no left tile ? BEEP.

			ld a, c
			dec a

			jr _TileEdUp.Sav






_TileEdRight:		call _Finds_EditorInPuzzler
			jp c, @BEEP				; Not found ? BEEP.

			ld a, c
			and 3
			cp 3
			jp z, @BEEP				; there is no right tile ? BEEP.

			ld a, c
			inc a

			jr _TileEdUp.Sav






_GetPuzTileData:	ld c, a					; In A = Tile position in the puzzler.
			add a,a
			add a,a
			add a,c
			add a,c
			add a,c
			ld c, a
			ld b, 0
			ld hl, PuzzlerIndexationBuffer
			add hl, bc
			push hl
			pop ix
			ld e,(ix+0)
			ld d,(ix+1)
			ld l,(ix+2)
			ld h,(ix+3)
			ld a, e
			or d
			or l
			or h
			jp z, @BEEP

			ld a,(ix+4)
			ld (EditorCurrentFormat),a
			ld (EditorCursorAddrLow),de
			ld (EditorCursorAddrHigh),hl
			jp _EDITORLOAD






_Finds_EditorInPuzzler:	ld ix, PuzzlerIndexationBuffer		; Looks in the puzzler for the char that is being edited.
			ld bc, 16 * 256				; OUT C = TileLocation (0-15).
			ld de, (EditorCursorAddrLow)		; CF = 1 not found.
			ld hl, (EditorCursorAddrHigh)

.Loop:			ld a, e
			cp (ix+0)
			jr nz, .NoMatch
			ld a, d
			cp (ix+1)
			jr nz, .NoMatch
			ld a, l
			cp (ix+2)
			jr nz, .NoMatch
			ld a, h
			cp (ix+3)
			ret z

.NoMatch:		push bc
			ld bc, 7
			add ix, bc
			pop bc
			inc c
			djnz .Loop

			scf
			ret



; **************************************************
; * STRINGs HANDLING & CHR PRINTING P2             *
; **************************************************






_SignedSTR:		ld ix, STR_Buffer			; in hlde = signed DWORD.
			bit 7, h				; Out STR_Buffer null terminated string.
			jr z, _STR.Custom

			ld (ix+0), '-'
			inc ix
			ld a, e
			cpl
			add a, 1
			ld e, a
			ld a, d
			cpl
			adc a, 0
			ld d, a
			ld a, l
			cpl
			adc a, 0
			ld l, a
			ld a, h
			cpl
			adc a, 0
			ld h, a

			jr _STR.Custom






_STR:			ld ix, STR_Buffer			; in hlde = unsigned DWORD. Out STR_Buffer null terminated string.
.Custom:		exx
			ld c,0					; MOD (ahldebchl'de'bc'ix).
			ld hl, $C465
			ld de, $3600				; hlde = -1.000.000.000
			call .Na1
			ld hl, $FA0A
			ld de, $1F00				; hlde = -100.000.000
			call .Na1
			ld hl, $FF67
			ld de, $6980				; hlde = -10.000.000
			call .Na1
			ld hl, $FFF0
			ld de, $BDC0				; hlde = -1.000.000
			call .Na1
			ld hl, $FFFE
			ld de, $7960				; hlde = -100.000
			call .Na1
			ld hl, $FFFF
			ld de, $D8F0				; hlde = -10.000
			call .Na1
			ld de, $FC18				; hlde = -1.000
			call .Na1
			ld de, $FF9C				; hlde = -100
			call .Na1
			ld de, $FFF6				; hlde = -10
			call .Na1
			ld de, $FFFF				; hlde = -1
			call .Na1

			ld a,c
			and a
			jr nz, .NULL
			
			ld (ix+0),'0'				; The result was 0, and by that reason it didn't print any char.
			inc ix

.NULL:			ld (ix+0), 0				; adds NULL CHAR.
			inc ix
			ret

.Na1:			ld b,'0'-1

.Na2:			inc b					; hlde' = value.

			push de
			exx
			pop bc
			ex de,hl
			add hl,bc
			ex de,hl
			exx
			push hl
			exx
			pop bc
			adc hl,bc
			exx
			jr c, .Na2

			push de
			exx
			pop bc
			ex de,hl
			sbc hl,bc
			ex de,hl
			exx
			push hl
			exx
			pop bc
			sbc hl,bc
			exx
								; b = chr$(digit).
			ld a,c					; c = 0 there wasn't a non zero before.
			and a
			jr nz, .Do			

			ld a,b
			cp '0'
			ret z					; Exclude all left zeroes.

.Do:			ld (ix+0),b
			inc ix
			dec c
			ret






IDEEXTP2_END:



; **************************************************
; * OUTPUT FILE FORMAT: IDEEXTP3.BIN               *
; **************************************************






FNAME "ideextp3.bin"
FORG $0

	DB $FE
	DW $8000
	DW IDEEXTP3_END + $4000 - 1
	DW 0

ORG $4000



; **************************************************
; * IN PAGE 3 ROUTINES                             *
; **************************************************






__BLOAD_HEADER:		ld bc, CompileOpts.BSaveStartAddr	; IN [HLDE] = bunch base address.
			ex de,hl				; IN (CreatingHeight * 256 | CreatingWidth) binary content size.
			add hl, bc				; IN FCB = opened FCB.
			ex de,hl				; OUT CF = 1 error.
			ld bc, 0
			adc hl, bc

			call @USERAREA_RW
								; ATP = BC = value of readed .BSaveStartAddr record.
			ld hl, DTA
			ld (hl), $FE
			inc hl
			ld (hl), c
			inc hl
			ld (hl), b
			inc hl
								; Now it needs to know the bunch size, in way to know the final address.
								; This check don't support length = 0.
			ld de, (CreatingHeight)
			ld a, e
			cp 2
			jr nc, .TooBigForBload
			ld a, d
			or a
			jr nz, .TooBigForBload			; if high word > 1, then it is too big.

			ld a, e
			or a
			jr z, .Good				; if high word = 0, then is good.

			ld de, (CreatingWidth)
			ld a, e					; if high word = 1, and low word <> 0 then it is too big.
			or d
			jr nz, .TooBigForBload

.Good:			ld de, (CreatingWidth)			; if high word = 1, and low word = 0 then it is good, but only if Bsave_Start_Address = 0.
			ld a, e
			or d
			or c
			or b					; is Bsave_Start_Address = 0 and low word = 0?, then is ok.

			dec de
			jr z, .JFFFF				; If size  = 64K, and the bload address = 0, it is valid.
			inc de

			ex de, hl
			add hl, bc
			dec hl
			ex de, hl				; de = length + bsave start address - 1.
			jr c, .MaybeTooBigForBload
								; ATP DE = last address for the bload header.
.JFFFF:			ld (hl), e
			inc hl
			ld (hl), d
			inc hl
			ld (hl), 0
			inc hl
			ld (hl), 0

			ld de, FCB
			ld c, $26
			ld hl, 7
			call @BDOS				; It writes the BLOAD header to the file.
			and a
			ret

.MaybeTooBigForBload:	ld a, e					; As can be that 'CF = 1' is set before than 'dec hl', must be check if the bsave last address = FFFF.
			and d
			cp $FF
			jr z, .JFFFF

.TooBigForBload:	call @BEEP
			ld ix, BoxErrorTooBigForBload
			ld iy, MSGBOX
			call @FarCallToPage1
			scf
			ret






__Compile:		ld ix, UserAreaCpyBuffer		; Named "compile" but is more like an "export" function.
			ld (ix+0), 8				; Single bunch compilation, this allows the user to select the bunch.
			ld (ix+1), ConsoleStartLine + 18	; Aligning with where appears the "Save ..." menuitem.
			inc ix
			inc ix
			ld iy, ListsBunchs
			call @FarCallToPage1
			ret c

			ld ix, UserAreaCpyBuffer
			ld iy, MENUPOPUP
			call @FarCallToPage1
			ret c					; The user pressed ESC.

			ld c, a
			ld b, 0					; BC = Bunch address.

.GetsIn:		ld (CreatingBunchID),bc			; IN [BC] = Bunch index.

			call @GETBUNCH_BASEADDR
			ld iy, _SetCompileOptions.ErrData
			jp c, @FarJumpToPage2

			push hl
			push de
			ld bc, CompileOpts.Configured		; Test if it has already compile information.
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc

			call @USERAREA_RB
			pop de
			pop hl
			ld iy, _SetCompileOptions.ErrData
			jp c, @FarJumpToPage2

			and a
			ld bc, (CreatingBunchID)		; If not configured, it calls the configuration dialogs.
			ld iy, _SetCompileOptions.FromCompileJump
			call z, @FarCallToPage2
			ret c					; Escape if aborted or error.

			ld bc, (CreatingBunchID)		; ATP is guarantee that it has configuration about how the user want the file to be served.
			call @GETBUNCH_BASEADDR

			ld bc, CompileOpts.Filename
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc

			exx
			ld hl, MsgBoxBuffer
			exx
			ld b, 12

.FillUpNameLoop:	push hl
			push de
			call @USERAREA_RB
			pop de
			pop hl
			ld iy, _SetCompileOptions.ErrData
			jp c, @FarJumpToPage2

			exx
			ld (hl), a
			inc hl
			exx
			and a
			jr z, .FindsNullChar
			
			inc de
			ld a, e
			or d
			jr nz, .FillUpNameJ1
			inc hl

.FillUpNameJ1:		djnz .FillUpNameLoop

			exx
			ld (hl), 0

.FindsNullChar:		ld hl, FCB				; First it creates the FCB.
			ld de, FCB + 1
			ld bc, 37 - 1				; FCB size = 37 bytes.
			ld (hl),0
			ldir

			ld hl, MsgBoxBuffer
			ld iy, FCBNameFillUp
			call @FarCallToPage1

			ld de, FCB
			ld c, $16
			call @BDOS
			and a
			jp z, .CreateOk

.DiskErr:		ld iy, MENUBAR.ErrorDiskError
			call @FarCallToPage1
			scf
			ret

.CreateOk:		ld c, $1A
			ld de, DTA
			call @BDOS

			ld hl, FCB + $0E
			ld (hl), 1
			inc hl
			ld (hl), 0				; File Record size = 1.

			ld bc, (CreatingBunchID)		; Gets the bunch raw size.
			call @GETBUNCH_LINKADDR
								; hlde = link address of the given bunch.
			call @USERAREA_RDW			; Reads the link value, that is the bunch size including the bunch header.
			ld e, c					; hlbc = size.
			ld d, b

			ld bc, BunchHeader.Size			
			ex de, hl
			and a
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc
								; ATP hlde = raw source size.
			ld (CreatingWidth), de
			ld (CreatingHeight), hl

			ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			push hl					; Reads the .SaveAs record.
			push de
			ld bc, CompileOpts.SaveAs
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc

			call @USERAREA_RB

			ld (CreatingFormat), a			; Saves the 'SaveAs' value for later use.

			cp 1					; Checks if the format is BLOAD.
			pop de
			pop hl
			jr nz, .FormatIsNotBload

			push hl					; BLOAD EXPORT FORMAT.
			push de

			ld bc, (CreatingBunchID)		; Checks for special cases where the source raw size <> bload's content size, so it needs a custom bload's header.
			ld iy, GetsBunchFormat
			call @FarCallToPage1

			pop de
			pop hl

			cp FormatID.SpriteMSX1
			jp z, .SpriteMSX1

			cp FormatID.SpriteMSX2
			jp z, .SpriteMSX2
			
			call __BLOAD_HEADER
			jr nc, .HeaderDone

.CloseFile:		push af
			ld c, $10
			ld de, FCB
			call @BDOS
			pop af
			ret

.FormatIsNotBload:
.HeaderDone:		ld bc, (CreatingBunchID)		; Checks for special cases like TileSc2 & 256, 512 or 768 tiles, where it must split the pattern channel from the colour channel.
			ld iy, GetsBunchFormat
			call @FarCallToPage1

			cp FormatID.TileSc2
			jr nz, .NoSpecials

			ld bc, (CreatingBunchID)
			ld iy, GetsBunchObjectCount
			call @FarCallToPage1
								; DE = object count.
			ld hl, 256
			and a
			sbc hl, de
			jp z, .SpecialSc2

			ld hl, 256*2
			and a
			sbc hl, de
			jp z, .SpecialSc2

			ld hl, 256*3
			and a
			sbc hl, de
			jp z, .SpecialSc2			; If the format is Screen 2 and tileset is 256,512 or 768 chrs, it will export separating the pattern table from the color table. So, you can use it with BLOAD,S after splitting the file.

.NoSpecials:		ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx
								; hl'de' = raw address in user area of the data to compile.
			ld a, (CreatingFormat)			; It must check if the content will be in BINARY or textual.
			cp 2
			jp z, .TextFormat
								; ATP it will be in binary.
			ld de, (CreatingWidth)
			ld hl, (CreatingHeight)

.CLoop:			ld a, e
			and $80
			or d
			or l
			or h
			jr z, .LastWrite

			exx
			push hl
			push de
			exx
			push hl
			push de
			ld hl, DTA
			ld bc, 128
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop de
			pop hl
			exx
			jp nc, .UAROk

.RUAErr:		call .CloseFile
			ld iy, _SetCompileOptions.ErrData
			call @FarCallToPage2
			scf
			ret

.UAROk:			push hl
			push de
			exx
			push hl
			push de
			ld c, $26
			ld hl, 128
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop de
			pop hl
			and a
			jr z, .FWOk

.CWFErr:		call .CloseFile
			ld iy, MENUBAR.ErrorDiskError
			call @FarCallToPage1
			scf
			ret

.FWOk:			exx
			ld bc, 128
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			ld bc, 128
			ex de,hl
			sbc hl, bc
			ex de,hl
			ld bc, 0
			sbc hl, bc

			jr .CLoop

.LastWrite:		ld a, e
			or a
			jr nz, .NoZip
			
			and a
			jp .CloseFile

.NoZip:			ld hl, DTA
			ld c, a
			ld b, 0
			push de
			call @READ_USERAREA
			pop hl
			jr c, .RUAErr

			ld de, FCB
			ld c, $26
			call @BDOS
			and a
			jr nz, .CWFErr

			jp .CloseFile

.TextFormat:		ld de, (CreatingWidth)			; compiling as text.
			ld hl, (CreatingHeight)

.CLoop2:		ld a, e
			and $E0
			or d
			or l
			or h
			jp z, .LastWrite2

			exx
			push hl
			push de
			exx
			push hl
			push de
			ld hl, EditorBuffer
			ld bc, 32
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop de
			pop hl
			exx
			jp c, .RUAErr

			push hl
			push de

			ld de, DTA
			ld hl, EditorBuffer
			
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 'D'
			ld (de), a
			inc de
			ld a, 'B'
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de

			ld b, 32

.HexLoop:		ld a, '$'				; Used by TNIasm as equivalent of &H.
			ld (de), a
			inc de

			ld a, (hl)
			rrca
			rrca
			rrca
			rrca
			and $0F
			cp $0A
			ld c, '0'
			jr c, .Num
			ld c, 'A'- $0A

.Num:			add a, c
			ld (de), a
			inc de

			ld a, (hl)
			inc hl
			and $0F
			cp $0A
			ld c, '0'
			jr c, .NumL
			ld c, 'A'- $0A

.NumL:			add a, c
			ld (de), a
			inc de

			ld a, ','
			ld (de), a
			inc de

			ld a, ' '
			ld (de), a
			inc de

			djnz .HexLoop

			dec de
			dec de
			ld a, 13				; CR.
			ld (de), a
			inc de
			ld a, 10				; LF.
			ld (de), a
			inc de

			pop de
			pop hl

			push hl
			push de
			exx
			push hl
			push de
			ld c, $26
			ld hl, 166				; Textual line length (3 tabs + "DB" + 1 tab + "$XX, " * 32 + CRLF) - 2 (because the last value has not follow ", ").
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop de
			pop hl
			and a
			jp nz, .CWFErr

			exx
			ld bc, 32
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			ld bc, 32
			ex de, hl
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc

			jp .CLoop2

.LastWrite2:		ld a, e
			or a
			jr nz, .NoZip2
			
			and a
			jp .CloseFile

.NoZip2:		ld hl, EditorBuffer
			ld c, a
			ld b, 0
			push de
			call @READ_USERAREA
			pop hl
			jp c, .RUAErr

			ld b, l

			ld de, DTA
			ld hl, EditorBuffer
			
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 'D'
			ld (de), a
			inc de
			ld a, 'B'
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de

.HexLoop2:		ld a, '$'				; Used by TNIasm as equivalent of &H.
			ld (de), a
			inc de

			ld a, (hl)
			rrca
			rrca
			rrca
			rrca
			and $0F
			cp $0A
			ld c, '0'
			jr c, .Num2
			ld c, 'A'- $0A

.Num2:			add a, c
			ld (de), a
			inc de

			ld a, (hl)
			inc hl
			and $0F
			cp $0A
			ld c, '0'
			jr c, .NumL2
			ld c, 'A'- $0A

.NumL2:			add a, c
			ld (de), a
			inc de

			ld a, ','
			ld (de), a
			inc de

			ld a, ' '
			ld (de), a
			inc de

			djnz .HexLoop2

			dec de
			dec de
			ld a, 13				; CR.
			ld (de), a
			inc de
			ld a, 10				; LF.
			ld (de), a
			inc de
								; it must calculate the size.
			ex de, hl
			ld de, DTA
			and a
			sbc hl, de
								; hl = textual size.
			ld de, FCB
			ld c, $26
			call @BDOS
			and a
			jp nz, .CWFErr

			jp .CloseFile
								; It saves screen2 tiles separating the patterns from the colors table.
.SpecialSc2:		push de					; DE = object count.
			ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			pop bc					; BC = object count.
			ld (CreatingWidth), bc			; Stores a copy for later use.

			ld a, (CreatingFormat)			; It must check if the content will be in BINARY or textual.
			cp 2
			jp z, .TextFormatSpecialSc2
								; ATP it will be in binary with channels separated.
.CLoopSpecialSc2:	ld a, c
			or b
			jr z, .CompletedPatterns

			push bc
			exx
			push hl
			push de
			exx
			ld hl, DTA
			ld bc, 8
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 8
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 16				; Sent 8 bytes to the file, but skips 16bytes (skipping the chroma channel).
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jr .CLoopSpecialSc2

.CompletedPatterns:	ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size + 8		; Skips the pattern.
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			ld bc, (CreatingWidth)

.CLoopSpecialSc2_2:	ld a, c
			or b
			jr z, .CompletedChroma

			push bc
			exx
			push hl
			push de
			exx
			ld hl, DTA
			ld bc, 8
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 8
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 16				; Sent 8 bytes to the file, but skips 16bytes (skipping the pattern channel).
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jr .CLoopSpecialSc2_2

.CompletedChroma:	and a
			jp .CloseFile

.TextFormatSpecialSc2:						; BC = ObjectCount.
.CLoop2SpecialSc2:	ld a, c
			or b
			jp z, .CompletePatterns2

			push bc
			exx
			push hl
			push de
			exx
			ld hl, EditorBuffer
			ld bc, 8
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc

			ld de, DTA
			ld hl, EditorBuffer
			
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 'D'
			ld (de), a
			inc de
			ld a, 'B'
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de

			ld b, 8

.HexLoopSSC2:		ld a, '$'				; Used by TNIasm as equivalent of &H.
			ld (de), a
			inc de

			ld a, (hl)
			rrca
			rrca
			rrca
			rrca
			and $0F
			cp $0A
			ld c, '0'
			jr c, .Num3
			ld c, 'A'- $0A

.Num3:			add a, c
			ld (de), a
			inc de

			ld a, (hl)
			inc hl
			and $0F
			cp $0A
			ld c, '0'
			jr c, .NumL3
			ld c, 'A'- $0A

.NumL3:			add a, c
			ld (de), a
			inc de

			ld a, ','
			ld (de), a
			inc de

			ld a, ' '
			ld (de), a
			inc de

			djnz .HexLoopSSC2

			dec de
			dec de
			ld a, 13				; CR.
			ld (de), a
			inc de
			ld a, 10				; LF.
			ld (de), a
			inc de

			pop bc

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 46				; Textual line length (3 tabs + "DB" + 1 tab + "$XX, " * 8 + CRLF) - 2 (because the last value has not follow ", ").
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 16
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jp .CLoop2SpecialSc2

.CompletePatterns2:	ld hl, DTA
			ld (hl), 13
			inc hl
			ld (hl), 10
			inc hl
			ld (hl), 13
			inc hl
			ld (hl), 10
			inc hl
			ld (hl), 13
			inc hl
			ld (hl), 10
			ld c, $26
			ld hl, 6
			ld de, FCB
			call @BDOS
			and a
			jp nz, .CWFErr

			ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size + 8		; Skips the pattern this time.
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			ld bc, (CreatingWidth)

.CLoop2SpecialSc2_2:	ld a, c
			or b
			jp z, .CompleteChroma2

			push bc
			exx
			push hl
			push de
			exx
			ld hl, EditorBuffer
			ld bc, 8
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc

			ld de, DTA
			ld hl, EditorBuffer
			
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 'D'
			ld (de), a
			inc de
			ld a, 'B'
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de

			ld b, 8

.HexLoopSSC2_2:		ld a, '$'				; Used by TNIasm as equivalent of &H.
			ld (de), a
			inc de

			ld a, (hl)
			rrca
			rrca
			rrca
			rrca
			and $0F
			cp $0A
			ld c, '0'
			jr c, .Num4
			ld c, 'A'- $0A

.Num4:			add a, c
			ld (de), a
			inc de

			ld a, (hl)
			inc hl
			and $0F
			cp $0A
			ld c, '0'
			jr c, .NumL4
			ld c, 'A'- $0A

.NumL4:			add a, c
			ld (de), a
			inc de

			ld a, ','
			ld (de), a
			inc de

			ld a, ' '
			ld (de), a
			inc de

			djnz .HexLoopSSC2_2

			dec de
			dec de
			ld a, 13				; CR.
			ld (de), a
			inc de
			ld a, 10				; LF.
			ld (de), a
			inc de

			pop bc

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 46				; Textual line length (3 tabs + "DB" + 1 tab + "$XX, " * 8 + CRLF) - 2 (because the last value has not follow ", ").
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 16
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jp .CLoop2SpecialSc2_2

.CompleteChroma2:	and a
			jp .CloseFile

.SpriteMSX1:		push hl					; Saves the bunch base address.
			push de

			ld bc, (CreatingBunchID)		; Calculates the bload's content size, based in the object count.
			ld iy, GetsBunchObjectCount
			call @FarCallToPage1
								; DE = object count.
			ld hl, 0

			and a
			rl e
			rl d
			rl l
			rl e
			rl d
			rl l
			rl e
			rl d
			rl l
			rl e
			rl d
			rl l
			rl e
			rl d
			rl l					; hlde = hlde * 32.

			ld (CreatingHeight), hl
			ld (CreatingWidth), de

			pop de
			pop hl					; Restores the bunch base address.

			call __BLOAD_HEADER
			jp c, .CloseFile

			ld bc, (CreatingBunchID)		; Gets the object count again.
			ld iy, GetsBunchObjectCount
			call @FarCallToPage1

			push de					; DE = object count.

			ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			pop bc					; BC = object count.
			ld (CreatingWidth), bc			; Stores a copy for later use.

			ld a, (CreatingFormat)			; It must check if the content will be in BINARY or textual.
			cp 2
			jp z, .TextFormatSpecialSpr1
								; ATP it will be in binary with channels separated.
.CLoopSpecialSpr1:	ld a, c
			or b
			jp z, .CloseFile

			push bc
			exx
			push hl
			push de
			exx
			ld hl, DTA
			ld bc, 32
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 32
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 32 + 4				; Sent 32 bytes to the file, but skips 36bytes (skipping the Sprite Attribute).
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jr .CLoopSpecialSpr1

.TextFormatSpecialSpr1:						; BC = ObjectCount.
.CLoop2SpecialSpr1:	ld a, c
			or b
			jp z, .CloseFile

			push bc
			exx
			push hl
			push de
			exx
			ld hl, EditorBuffer
			ld bc, 32
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc

			ld de, DTA
			ld hl, EditorBuffer
			
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 'D'
			ld (de), a
			inc de
			ld a, 'B'
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de

			ld b, 32

.HexLoopSSpr1:		ld a, '$'				; Used by TNIasm as equivalent of &H.
			ld (de), a
			inc de

			ld a, (hl)
			rrca
			rrca
			rrca
			rrca
			and $0F
			cp $0A
			ld c, '0'
			jr c, .Num3Spr1
			ld c, 'A'- $0A

.Num3Spr1:		add a, c
			ld (de), a
			inc de

			ld a, (hl)
			inc hl
			and $0F
			cp $0A
			ld c, '0'
			jr c, .NumL3Spr1
			ld c, 'A'- $0A

.NumL3Spr1:		add a, c
			ld (de), a
			inc de

			ld a, ','
			ld (de), a
			inc de

			ld a, ' '
			ld (de), a
			inc de

			djnz .HexLoopSSpr1

			dec de
			dec de
			ld a, 13				; CR.
			ld (de), a
			inc de
			ld a, 10				; LF.
			ld (de), a
			inc de

			pop bc

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 166				; Textual line length (3 tabs + "DB" + 1 tab + "$XX, " * 32 + CRLF) - 2 (because the last value has not follow ", ").
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 32 + 4				; Sent 32 bytes to the file, but skips 36bytes (skipping the Sprite Attribute).
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jp .CLoop2SpecialSpr1

.SpriteMSX2:		push hl					; Saves the bunch base address.
			push de

			ld bc, (CreatingBunchID)		; Calculates the bload's content size, based in the object count.
			ld iy, GetsBunchObjectCount
			call @FarCallToPage1
								; DE = object count.
			ld hl, 0

			and a
			rl e
			rl d
			rl l
			rl e
			rl d
			rl l
			rl e
			rl d
			rl l
			rl e
			rl d
			rl l
			push hl
			push de
			rl e
			rl d
			rl l
			pop bc
			ex de, hl
			add hl, bc
			ex de, hl
			pop bc
			adc hl, bc				; hlde = hlde * 48.

			ld (CreatingHeight), hl
			ld (CreatingWidth), de

			pop de
			pop hl					; Restores the bunch base address.

			call __BLOAD_HEADER
			jp c, .CloseFile

			ld bc, (CreatingBunchID)		; Gets the object count again.
			ld iy, GetsBunchObjectCount
			call @FarCallToPage1

			push de					; DE = object count.

			ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			pop bc					; BC = object count.
			ld (CreatingWidth), bc			; Stores a copy for later use.

			ld a, (CreatingFormat)			; It must check if the content will be in BINARY or textual.
			cp 2
			jp z, .TextFormatSpecialSpr2
								; ATP it will be in binary with channels separated.
.CLoopSpecialSpr2:	ld a, c
			or b
			jp z, .BinColorAttSpr2

			push bc
			exx
			push hl
			push de
			exx
			ld hl, DTA
			ld bc, 32
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 32
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 32 + 16 + 2			; Sent 32 bytes to the file, but skips 50bytes (skipping the Sprite color attribute and XY).
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jr .CLoopSpecialSpr2

.BinColorAttSpr2:	ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size + 32		; This time it skips the sprite pattern.
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			ld bc, (CreatingWidth)

.CLoopSpecialColorSpr2:	ld a, c
			or b
			jp z, .CloseFile

			push bc
			exx
			push hl
			push de
			exx
			ld hl, DTA
			ld bc, 16
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 16
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 32 + 16 + 2			; Sent 16 bytes to the file, but skips 50bytes (skipping the Sprite pattern and XY).
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jr .CLoopSpecialColorSpr2

.TextFormatSpecialSpr2:						; BC = ObjectCount.
.CLoop2SpecialSpr2:	ld a, c
			or b
			jp z, .TextPatternCompleteSpr2

			push bc
			exx
			push hl
			push de
			exx
			ld hl, EditorBuffer
			ld bc, 32
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc

			ld de, DTA
			ld hl, EditorBuffer
			
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 'D'
			ld (de), a
			inc de
			ld a, 'B'
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de

			ld b, 32

.HexLoopSSpr2:		ld a, '$'				; Used by TNIasm as equivalent of &H.
			ld (de), a
			inc de

			ld a, (hl)
			rrca
			rrca
			rrca
			rrca
			and $0F
			cp $0A
			ld c, '0'
			jr c, .Num3Spr2
			ld c, 'A'- $0A

.Num3Spr2:		add a, c
			ld (de), a
			inc de

			ld a, (hl)
			inc hl
			and $0F
			cp $0A
			ld c, '0'
			jr c, .NumL3Spr2
			ld c, 'A'- $0A

.NumL3Spr2:		add a, c
			ld (de), a
			inc de

			ld a, ','
			ld (de), a
			inc de

			ld a, ' '
			ld (de), a
			inc de

			djnz .HexLoopSSpr2

			dec de
			dec de
			ld a, 13				; CR.
			ld (de), a
			inc de
			ld a, 10				; LF.
			ld (de), a
			inc de

			pop bc

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 166				; Textual line length (3 tabs + "DB" + 1 tab + "$XX, " * 32 + CRLF) - 2 (because the last value has not follow ", ").
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 32 + 16 + 2			; Sent 32 bytes to the file, but skips 50bytes (skipping the Sprite color Attribute and XY).
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jp .CLoop2SpecialSpr2

.TextPatternCompleteSpr2:ld hl, DTA
			ld (hl), 13
			inc hl
			ld (hl), 10
			inc hl
			ld (hl), 13
			inc hl
			ld (hl), 10
			inc hl
			ld (hl), 13
			inc hl
			ld (hl), 10
			ld c, $26
			ld hl, 6
			ld de, FCB
			call @BDOS
			and a
			jp nz, .CWFErr

			ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size + 32		; Skips the sprite pattern this time.
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			ld bc, (CreatingWidth)

.CLoop2SpecialColorSpr2:ld a, c
			or b
			jp z, .CloseFile

			push bc
			exx
			push hl
			push de
			exx
			ld hl, EditorBuffer
			ld bc, 16
			call @READ_USERAREA
			pop de
			pop hl
			exx
			pop bc
			jp c, .RUAErr

			push bc

			ld de, DTA
			ld hl, EditorBuffer
			
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de
			ld a, 'D'
			ld (de), a
			inc de
			ld a, 'B'
			ld (de), a
			inc de
			ld a, 9					; Tab.
			ld (de), a
			inc de

			ld b, 16

.HexLoopSSpr2_2:	ld a, '$'				; Used by TNIasm as equivalent of &H.
			ld (de), a
			inc de

			ld a, (hl)
			rrca
			rrca
			rrca
			rrca
			and $0F
			cp $0A
			ld c, '0'
			jr c, .Num3Spr2_2
			ld c, 'A'- $0A

.Num3Spr2_2:		add a, c
			ld (de), a
			inc de

			ld a, (hl)
			inc hl
			and $0F
			cp $0A
			ld c, '0'
			jr c, .NumL3Spr2_2
			ld c, 'A'- $0A

.NumL3Spr2_2:		add a, c
			ld (de), a
			inc de

			ld a, ','
			ld (de), a
			inc de

			ld a, ' '
			ld (de), a
			inc de

			djnz .HexLoopSSpr2_2

			dec de
			dec de
			ld a, 13				; CR.
			ld (de), a
			inc de
			ld a, 10				; LF.
			ld (de), a
			inc de

			pop bc

			push bc
			exx
			push hl
			push de
			ld c, $26
			ld hl, 86				; Textual line length (3 tabs + "DB" + 1 tab + "$XX, " * 16 + CRLF) - 2 (because the last value has not follow ", ").
			ld de, FCB
			call @BDOS
			pop de
			pop hl
			exx
			pop bc
			and a
			jp nz, .CWFErr

			exx
			ld bc, 32 + 16 + 2			; Sent 32 bytes to the file, but skips 50bytes (skipping the Sprite pattern and XY).
			ex de,hl
			add hl, bc
			ex de,hl
			ld bc, 0
			adc hl, bc
			exx

			dec bc

			jp .CLoop2SpecialColorSpr2






__ImportBmp:		ld a, FormatID.ImageFileHolder
			ld (CreatingFormat), a
			call __LoadAnyFile
			ret c

			ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size			; Must include the bunch header size.
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, 0
			adc hl, bc				; Now it interprets the bitmapfileheader & bitmapinfoheader and prepare the image console variables.

			push hl					; hlde = BITMAPFILEHEADER address.
			push de
			call @USERAREA_RW

			ld hl, "BM"				; .bmp tag.
			and a
			sbc hl, bc
			pop de
			pop hl
			jr z, .BMTagok

.ErrImgFormat:		ld iy, MENUBAR.ErrUnsupportedImage
			call @FarCallToPage1

			ld bc, (CreatingBunchID)
			ld iy, _BUNCH_DELETE
			jp @FarCallToPage2

.BMTagok:		push hl
			push de					; Saves the BITMAPFILEHEADER address.

			ld bc, BITMAPFILEHEADER.bfOffBits
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, 0
			adc hl, bc

			call @USERAREA_RDW
								; hlbc = value readed.
			pop de
			ex de, hl
			add hl, bc
			ex de, hl
			pop bc
			adc hl, bc
			jr c, .ErrImgFormat
								; hlde = BITMAPFILEHEADER address + BITMAPFILEHEADER.bfOffBits
			ld (ImageUserAreaArrayAddrLow), de
			ld (ImageUserAreaArrayAddrHigh), hl	; Save the unfixed address.

			ld bc, (CreatingBunchID)
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size + BITMAPFILEHEADER.Size
								; Must include the bunch header size.
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, 0
			adc hl, bc				; Now it interprets the bitmapfileheader & bitmapinfoheader and prepare the image console variables.

			exx

			ld hl, DTA				; It copy the BITMAPINFOHEADER structure into a buffer.
			ld bc, BITMAPINFOHEADER.Size
			call @READ_USERAREA

			ld ix, DTA

			ld a, (ix + BITMAPINFOHEADER.biCompression + 1)
			or (ix + BITMAPINFOHEADER.biCompression + 2)
			or (ix + BITMAPINFOHEADER.biCompression + 3)
			jr nz, .ErrImgFormat

			ld a, (ix + BITMAPINFOHEADER.biCompression)
			ld (ImageCompression), a

			cp BI_RGB
			jr z, .EncodingOk
			cp BI_BITFIELDS				; Lets see if we needs to support this one.
			jr z, .EncodingOk

			; // BI_RLE8 not supported yet.
			; // BI_RLE4 not supported yet.

			jr .ErrImgFormat

.EncodingOk:		ld e, (ix + BITMAPINFOHEADER.biWidth + 2); We don't supports images too big.
			ld d, (ix + BITMAPINFOHEADER.biWidth + 3)
			ld a, e
			or d
			jp nz, .ErrImgFormat

			ld l, (ix + BITMAPINFOHEADER.biWidth)
			ld h, (ix + BITMAPINFOHEADER.biWidth + 1)

			ld (ImageWidth), hl			; It stores the bitmap width in pixels.

			ld a, (ix + BITMAPINFOHEADER.biPlanes)
			dec a
			jp nz, .ErrImgFormat

			ld a, (ix + BITMAPINFOHEADER.biPlanes + 1)
			or (ix + BITMAPINFOHEADER.biBitCount + 1)
			and a
			jp nz, .ErrImgFormat

			ld a, (ix + BITMAPINFOHEADER.biBitCount)
			ld b, 2
			cp 16
			jr z, .BitCountOk

			ld b, 3
			cp 24
			jr z, .BitCountOk

			ld b, 4
			cp 32
			jr z, .BitCountOk

			jp .ErrImgFormat

.BitCountOk:		ld a, b					; It saves the bytes per pixel.
			ld (ImageBytesCount), a

			ld c, l
			ld b, h

			ld de, 0
			ld l, e
			ld h, d

.LineSizeCalcLoop:	ex de, hl
			add hl, bc
			ex de, hl
			push bc
			ld bc, 0
			adc hl, bc
			pop bc

			dec a
			jr nz, .LineSizeCalcLoop

			ld a, e					; See if is needed some padding bytes.
			and $03
			jr z, .NoPadding

			ld a, e
			and $FC
			add a, 4
			ld e, a
			ld a, d
			adc a, 0
			ld d, a
			ld a, l
			adc a, 0
			ld l, a
			ld a, h
			adc a, 0
			ld h, a

.NoPadding:		ld (ImageLineSizeLow), de		; Stores the size in bytes for each line of the bitmap.
			ld (ImageLineSizeHigh), hl

			ld e, (ix + BITMAPINFOHEADER.biHeight + 2)
			ld d, (ix + BITMAPINFOHEADER.biHeight + 3)
			ld a, e
			or d
			jr z, .BottomTopStandard

			ld a, e
			and d
			cp $FF
			jp nz, .ErrImgFormat			; Escapes if it is too big, being it positive or negative is the same if is too big.
								; It is Top->Bottom.
			ld l, (ix + BITMAPINFOHEADER.biHeight)
			ld h, (ix + BITMAPINFOHEADER.biHeight + 1)

			ld a, l
			cpl
			ld l, a
			ld a, h
			cpl
			ld h, a
			inc hl
			ld (ImageHeight), hl
			xor a
			ld (ImageIsBottomFirst), a
			jr .Continue

.BottomTopStandard:	ld l, (ix + BITMAPINFOHEADER.biHeight)
			ld h, (ix + BITMAPINFOHEADER.biHeight + 1)
			ld (ImageHeight), hl
			ld a, $FF
			ld (ImageIsBottomFirst), a		; Must invert the array pointer.
								; HL = image height.
			ld c, l
			ld b, h
			dec bc					; is image.height - 1 (at the start of the last line that is the TOP line).

			ld de, (ImageLineSizeLow)
			ld hl, (ImageLineSizeHigh)
			call __Mult3232				; HLDE = BC * HLDE.
			jp c, .ErrImgFormat

			push hl					; Invert the array pointer!.
			ld hl , (ImageUserAreaArrayAddrLow)
			add hl, de
			ex de, hl
			pop bc
			ld hl, (ImageUserAreaArrayAddrHigh)
			adc hl, bc
			jp c, .ErrImgFormat

			ld (ImageUserAreaArrayAddrLow), de
			ld (ImageUserAreaArrayAddrHigh), hl

.Continue:		ld hl, 0
			ld (ImageScrollTop), hl
			ld (ImageScrollLeft), hl

			ld hl, (ImageWidth)
			and a
			rr h
			rr l
			ld (ImageCursorX), hl
			
			ld hl, (ImageHeight)
			and a
			rr h
			rr l
			ld (ImageCursorY), hl

			ld hl, 32
			ld (ImageCursorWidth), hl
			ld (ImageCursorHeight), hl

			ld bc, (CreatingBunchID)		; Save the variables in the bunch.
			call @GETBUNCH_BASEADDR

			ld bc, BunchHeader.Size
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, 0
			adc hl, bc

			ld (SelectorBunchStartRawAddrHigh), hl
			ld (SelectorBunchStartRawAddrLow), de
			call __SaveImageConsoleVariables

			and a
			ret






__LoadAnyFile:		ld iy, _Files				; It shows the disk directory. It allows the user to select any file and loads it in RAM as RAW data.
			call @FarCallToPage2			; IN (CreatingFormat) bunchformat.
			ret c

.LoadMB:		ld hl, FCB				; First it creates the FCB.
			ld de, FCB + 1
			ld bc, 37 - 1				; FCB size = 37 bytes.
			ld (hl),0
			ldir

			ld ix, BoxLoadFilenameData
			ld iy, MSGBOX
			call @FarCallToPage1
			ret c					; The user pressed ESC.

			ld hl, MsgBoxBuffer
			ld iy, NormalizeFileName
			call @FarCallToPage1
			jr nc, .LDOk

			ld iy, MENUBAR.ErrBadFN			; Prints error bad filename.
			call @FarCallToPage1
			jr .LoadMB

.LDOk:			ld hl, MsgBoxBuffer
			ld iy, FindBunchByName			; Checks if the name is not already in use.
			call @FarCallToPage1
			jr c, .LDOk4

			ld iy, MENUBAR.ErrorAlreadyUsed		; Prints error already loaded/in use.
			call @FarCallToPage1
			jr .LoadMB

.LDOk4:			ld hl, MsgBoxBuffer			; Fills the FCB filename field.
			ld iy, FCBNameFillUp
			call @FarCallToPage1

			ld c, $0F				; Opens de file.
			ld de, FCB
			call @BDOS
			and a
			jr z, .LDFound

			ld iy, MENUBAR.ErrorFileNotFound	; Prints the error FILE NOT FOUND.
			call @FarCallToPage1
			jr .LoadMB

.LDFound:		ld de, (FCB + $10)			; It must read the filelength.
			ld hl, (FCB + $12)

			ld (CreatingWidth), de
			ld (CreatingHeight), hl

			ld a, $FF
			ld (CreatingNotZeroing), a
			ld iy, _CreateBunch			; IN [hlde] RAW size.
			call @FarCallToPage2
			ld a, 0
			ld (CreatingNotZeroing), a
			jr nc, .BunchCreated			; File too long (not enough memory).

			ld iy, MENUBAR.ErrorNotEnoughtRAM
			call @FarCallToPage1
			scf

.FileClose:		push af
			ld de, FCB				; File Close.
			ld c, $10
			call @BDOS
			pop af
			ret

.BunchCreated:		ld hl, MsgBoxBuffer			; Finds the bunch just created.
			ld iy, FindBunchByName			; Checks if the name is not already in use.
			call @FarCallToPage1
			jr nc, .BunchFound

.DataCorrupt:		ld iy, MENUBAR.ErrDataCorrupt		; Just created but unable to find it, expect data corruption.
			call @FarCallToPage1
			scf
			jr .FileClose

.BunchFound:		ld (CreatingBunchID), bc		; Saves the bunch index for later use.

			call @GETBUNCH_BASEADDR
			jr c, .DataCorrupt			; Error.

			ld bc, BunchHeader.Size			; Must include the bunch header size.
			ex de, hl
			add hl, bc
			ex de, hl
			ld bc, 0
			adc hl, bc
			exx					; hl'de' = user area destination pointer.

			ld de, (CreatingWidth)			; Gets the bunch's raw size = filelength.
			ld hl, (CreatingHeight)

			call __TransferingForLoad
			jr nc, .FileClose

			ld iy, MENUBAR.ErrorDiskError
			call @FarCallToPage1

			ld bc, (CreatingBunchID)
			ld iy, _BUNCH_DELETE
			call @FarCallToPage2

			scf
			jr .FileClose






__TransferingForLoad:	ld (FCBTransferRemainsLow), de		; in [hl'de'] = Logical UserArea address.
			ld (FCBTransferRemainsHigh), hl		; in [hlde] = size to transfer.
			exx

			call @LogicToRawAddr			; It converts logical address to raw.
			ret c

			ld (FCBTransferRawUserAreaAddrLow), de
			ld (FCBTransferRawUserAreaAddrHigh), hl

			ld hl, 1				; Preparing the FCB for byte random access.
			ld (FCB + $0E), hl			; Record size = 1.
			dec hl
			ld (FCB + $21), hl
			ld (FCB + $23), hl			; Start record number = 0.

.ReadLoop:		call __ChecksIfCompleted
			ret z

			call __CalculatesCurrentTransferSize

			ld hl, (FCBTransferRawUserAreaAddrHigh)
			call @SetSegment			; It sets the page2.
			ret c

			ld c, $1A
			ld de, (FCBTransferRawUserAreaAddrLow)
			call @BDOS

			ld c, $27
			ld de, FCB
			ld hl, (FCBTransferCurrentSize)
			call @BDOS

			and a
			scf
			ret nz

			call __CalculatesNextRawUserAreaAddress
			ret c

			call __CalculatesNextTransferRemains
			ret c

			jr .ReadLoop






__TransferingForSave:	ld (FCBTransferRemainsLow), de		; in [hl'de'] = UserArea address.
			ld (FCBTransferRemainsHigh), hl		; in [hlde] = size to transfer.
			exx

			call @LogicToRawAddr			; It converts logical address to raw.
			ret c

			ld (FCBTransferRawUserAreaAddrLow), de
			ld (FCBTransferRawUserAreaAddrHigh), hl

			ld hl, 1				; Preparing the FCB for byte random access.
			ld (FCB + $0E), hl			; Record size = 1.
			dec hl
			ld (FCB + $21), hl
			ld (FCB + $23), hl			; Start record number = 0.

.WriteLoop:		call __ChecksIfCompleted
			ret z

			call __CalculatesCurrentTransferSize

			ld hl, (FCBTransferRawUserAreaAddrHigh)
			call @SetSegment			; It sets the page2.
			ret c

			ld c, $1A
			ld de, (FCBTransferRawUserAreaAddrLow)
			call @BDOS

			ld c, $26
			ld de, FCB
			ld hl, (FCBTransferCurrentSize)
			call @BDOS

			and a
			scf
			ret nz

			call __CalculatesNextRawUserAreaAddress
			ret c

			call __CalculatesNextTransferRemains
			ret c

			jr .WriteLoop






__CalculatesCurrentTransferSize:
			ld hl, $4000				; MAX = 16K, as transfer will be done only by page2.
			
			ld de, (FCBTransferRemainsHigh)
			ld a, e
			or d
			jr nz, .RemainsTooMuch

			ld de, (FCBTransferRemainsLow)
			ld a, d
			cp $40
			jr nc, .RemainsTooMuch

			ex de, hl

.RemainsTooMuch:	push hl					; hl = that lefts to transfer within the 16K limit.

			ld hl, $C000
			ld de, (FCBTransferRawUserAreaAddrLow)	; This address is in page2 as it is RAW.
			and a
			sbc hl, de				; hl = how many bytes fits in the current page.

			pop de

			push hl
			and a
			sbc hl, de
			pop hl					; CP hl, de.

			jr c, .HLIsSmaller

			ex de, hl

.HLIsSmaller:		ld (FCBTransferCurrentSize), hl
			ret






__CalculatesNextRawUserAreaAddress:				; Out [CF] = 1 if overflow.
			ld hl, (FCBTransferRawUserAreaAddrLow)	; It is always on page2.
			ld de, (FCBTransferCurrentSize)		; It is as big as 16K always.
			add hl, de
			ld a, h
			cp $c0
			jr c, .NoPage2Overflow

			res 6, h				; Back to page2.
			ld (FCBTransferRawUserAreaAddrLow), hl

			ld hl, (FCBTransferRawUserAreaAddrHigh)	; Increases the page number.
			inc hl
			ld (FCBTransferRawUserAreaAddrHigh), hl

			ld a, l
			or h
			ret nz

			scf
			ret

.NoPage2Overflow:	ld (FCBTransferRawUserAreaAddrLow), hl
			and a
			ret






__CalculatesNextTransferRemains:				; out [CF] = 1, error remains overrun.
			ld hl, (FCBTransferRemainsLow)
			ld de, (FCBTransferCurrentSize)

			and a
			sbc hl, de
			ld (FCBTransferRemainsLow), hl

			ret nc

			ld hl, (FCBTransferRemainsHigh)
			ld a, h
			or l
			scf
			ret z

			dec hl
			ld (FCBTransferRemainsHigh), hl
			and a

			ret






__ChecksIfCompleted:	ld hl, (FCBTransferRemainsLow)		; out [ZF] = 1 = completed.
			ld a, h
			or l
			ret nz

			ld hl, (FCBTransferRemainsHigh)
			ld a, h
			or l
			ret






__ImageConsole:		call __LoadImageConsoleVariables

			ld a, (VDPREG8)				; Enable sprites engine.
			and  $FD
			ld b, a
			ld c, 8
			call @WRTVDP

			ld hl, $F000				; Pattern.
			call @VPOKEPOS
			ld hl, .SpritePatterns
			ld b, 32*4
			ld c, $98
			otir

			ld hl, $F800				; Color.
			call @VPOKEPOS
			ld b, 16*4
			ld a, $0f
			
.ColorSet:		out ($98), a
			djnz .ColorSet

.Redraw:		ld bc, (ImageScrollTop)			; Calculates the in user area address of the TOP/LEFT pixel using the scroll position as parameters.
			call __PosOnLine
			jp c, .OutOfImage

			ld bc, (ImageScrollLeft)
			call __PosOnPixel
			jp c, .OutOfImage

			push hl					; Must calculate how many lines to draw.

			ld bc, (ImageScrollTop)
			ld hl, (ImageHeight)
			sbc hl, bc
			ld c, l
			ld b, h

			pop hl

			jp c, .OutOfImage
								; BC = ammount of lines.
			ld a, c
			or b
			jp z, .OutOfImage

			ld a, b
			and a
			jr nz, .ClipY

			ld a, c
			cp 160
			jr c, .NoClipY

.ClipY:			ld bc, 160

.NoClipY:		ld (ImageYCountDown), bc

			push hl

			ld bc, (ImageScrollLeft)
			ld hl, (ImageWidth)

			and a
			sbc hl, bc
			ld c, l
			ld b, h

			pop hl

			jp c, .OutOfImage

			ld a, c
			or b
			jp z, .OutOfImage

			ld a, b
			and a
			jr z, .NoClipX

			ld bc, 256

.NoClipX:		ld (ImageXCount), bc

			push hl
			ld hl, 256
			sbc hl, bc
			ld (ImageXCountLeft), hl		; Right margin size.
			pop hl

			exx
			ld a, (ImageCompression)
			cp BI_RGB
			ld hl, .FetchingTable
			jr z, .Mount
			cp BI_BITFIELDS
			ld hl, .FetchingBFTable
			jr z, .Mount

			jp .OutOfImage

.Mount:			ld a, (ImageBytesCount)			; It mounts the fetching routine.
			add a, a
			add a, a			
			ld e, a
			ld d, 0
			add hl, de
			ld e, (hl)
			inc hl
			ld d, (hl)
			inc hl

			ld a, $C3				; JP instruction.
			ld (JPPixelFetch), a
			ld (JPPixelFetch+1), de

			ld (JPPixelRead), a
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (JPPixelRead+1), de
			exx

			ld ix, 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)
								; hlde = Array in UserArea.
								; ix = visual area.
.ImageLineLoop:		push hl					; Save the current line home position (array address).
			push de

			push hl

			push ix					; Sets PSET(X,Y).
			pop hl
			call @VPOKEPOS

			pop hl			

			call @LogicToRawAddr			; in hlde = plain user area offset address.
			jr c, .LineErr				; out hlde = MSX linear addressing.
			call @SetSegment			; out CF = 1 error.
			jr c, .LineErr

			ld bc, (ImageXCount)

.ImageDotLoop:		push bc
			call JPPixelFetch
			pop bc
			jr c, .LineErr

			dec bc
			ld a, c
			or b
			jr nz, .ImageDotLoop

			ld bc, $0100
			add ix, bc				; Screen next line.

.LineErr:		pop de
			pop hl

			call __ImageNextLine			; Array next line.
			jr c, .OutOfImageRender

			ld bc, (ImageYCountDown)		; Line countdown.
			dec bc
			ld (ImageYCountDown), bc
			ld a, c
			or b
			jr nz, .ImageLineLoop

.OutOfImageRender:	ld h, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			ld a, (ImageXCount)
			ld l, a
			ld a, (ImageXCountLeft)
			and a
			ld c, a
			ld b, 160 - ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			ld a, (ScreenBackgroundColor)
			call nz, @BLOCKFILL			; It renders the right margin if the picture don't cover all the screen.

			push ix
			pop hl

			ld a, 160 + ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			sub h
			jr c, .NoLowerMargin

			ld b, a
			ld l, 0
			ld a, (ImageXCount)
			ld c, a
			ld a, (ScreenBackgroundColor)
			call nz, @BLOCKFILL			; If the picture don't fills all the screen, it render the lower margin.

.NoLowerMargin:		ei
			jr .Continue

.OutOfImage:		ld hl, 256 * (ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)
			ld bc, 256 * (160 - ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator)
			ld a, (ScreenBackgroundColor)
			call @BLOCKFILL				; It blanks all the picture area.

.Continue:		call .PrintCursor

.KB:			call @INKEY
			jr c, .KB

			push af
			call .NoCursor
			pop af

			call @UPCASE

			cp 27
			jp z, .Esc

			; // insert more functions here.

			cp 'Q'
			jr z, .FastBS

			cp 9
			jr z, .Tab

			ld hl, $f3f7				; Keyb repeater.
			ld (hl), 1

			cp 28
			jr z, .Right

			cp 29
			jr z, .Left

			cp 30
			jp z, .Up

			cp 31
			jp z, .Down

			jr .KB

.FastBS:		call __SaveImageConsoleVariables

			ld bc, (FastBunchBack)			; Habría que reveer todo el sistema de fast switching,
			ld iy, BunchSelector.Selects
			jp @FarJumpToPage1

.Tab:			call __SaveImageConsoleVariables

			ld iy, BunchSelector
			jp @FarJumpToPage1

.Right:			ld hl, (ImageCursorX)
			ld de, (ImageCursorWidth)
			add hl, de
			jr c, .Continue

			push hl
			ld de, (ImageWidth)
			sbc hl, de
			pop bc
			jr z, .Continue
			jr nc, .Continue
			
			ld hl, (ImageCursorX)
			inc hl
			inc bc
			ld (ImageCursorX), hl

			ld hl, (ImageSCrollLeft)
			ld de, 256
			add hl, de
			jr c, .Continue

			sbc hl, bc
			jr z, .Continue
			jr nc, .Continue

			ld hl, (ImageSCrollLeft)
			ld de, 128
			add hl, de
			ld (ImageSCrollLeft), hl

			jp .Redraw

.Left:			ld hl, (ImageCursorX)
			ld a, l
			or h
			jp z, .Continue

			dec hl
			ld (ImageCursorX), hl

			ld bc, (ImageScrollLeft)
			sbc hl, bc
			jp nc, .Continue

			ld hl, (ImageScrollLeft)
			ld bc, 128
			and a
			sbc hl, bc
			ld (ImageScrollLeft), hl
			jp nc, .Redraw

			ld hl, 0
			ld (ImageScrollLeft), hl
			jp .Redraw

.Up:			ld hl, (ImageCursorY)
			ld a, l
			or h
			jp z, .Continue

			dec hl
			ld (ImageCursorY), hl

			ld bc, (ImageScrollTop)
			sbc hl, bc
			jp nc, .Continue

			ld hl, (ImageScrollTop)
			ld bc, 80
			and a
			sbc hl, bc
			ld (ImageScrollTop), hl
			jp nc, .Redraw

			ld hl, 0
			ld (ImageScrollTop), hl
			jp .Redraw

.Down:			ld hl, (ImageCursorY)
			ld de, (ImageCursorHeight)
			add hl, de
			jp c, .Continue

			push hl
			ld de, (ImageHeight)
			sbc hl, de
			pop bc
			jp z, .Continue
			jp nc, .Continue
			
			ld hl, (ImageCursorY)
			inc hl
			inc bc
			ld (ImageCursorY), hl

			ld hl, (ImageSCrollTop)
			ld de, 160
			add hl, de
			jp c, .Continue

			sbc hl, bc
			jp z, .Continue
			jp nc, .Continue

			ld hl, (ImageSCrollTop)
			ld de, 80
			add hl, de
			ld (ImageSCrollTop), hl

			jp .Redraw

.Esc:			call __SaveImageConsoleVariables

			ld iy, ConsoleRender.GoMenuBar
			jp @FarJumpToPage1

.PickAddress:		push hl					; IN HL = YX offsets from the cursor.
			ld bc, (ImageCursorY)
			ld a, h
			add a, c
			ld c, a
			ld a, b
			adc a, 0
			ld b, a
			call __PosOnLine
			pop bc
			ret c

			ld a, c
			ld bc, (ImageCursorX)
			add a, c
			ld c, a
			ld a, b
			adc a, 0
			ld b, a
			call __PosOnPixel
			ret c

			call @LogicToRawAddr
			ret c
			jp @SetSegment
			
.2BPPPIXREAD:		call .PickAddress			; IN HL = YX offsets from the cursor.
			ret c					; OUT A = RED LEVEL.
								; OUT B = BLUE LEVEL.
			ld a, (de)				; OUT C = GREEN LEVEL.
			ld b, a					; OUT CF = 1, error.

			call @USERAREA_NEXTBYTE
			ret c

			ld a, (de)
			ld e, b
			ld d, a					; d= 0rrrrrgg e= gggbbbbb

			ld a, e
			and $1F
			add a,a
			add a,a
			add a,a
			ld b, a

			ld a, e
			and $E0
			rr d
			rra
			rr d
			rra
			ld c, a

			ld a, d
			and $1F
			add a,a
			add a,a
			add a,a
			ret

.4BPPPIXREAD:							; 4BPP is the same than 3bpp for just a POINT() function equivalent.
.3BPPPIXREAD:		call .PickAddress			; IN HL = YX offsets from the cursor.
			ret c					; OUT A = RED LEVEL.
								; OUT B = BLUE LEVEL.
			ld a, (de)				; OUT C = GREEN LEVEL.
			ld b, a					; OUT CF = 1, error.

			call @USERAREA_NEXTBYTE
			ret c

			ld a, (de)
			ld c, a

			call @USERAREA_NEXTBYTE
			ret c

			ld a, (de)
			ret

.PrintCursor:		ld hl, $FA00				; Att.
			call @VPOKEPOS

			ld hl, (ImageCursorY)			; Calculates the cursor position in the screen.
			ld bc, (ImageScrollTop)
			and a
			sbc hl, bc
			jr c, .NoCursor
			ld a, h
			and a
			jr nz, .NoCursor

			ld a, ConsoleStartLine + BunchLowerSeparator + BunchTitleBarHeight + BunchUpperSeparator
			add a, l
			jr c, .NoCursor
			cp 160
			jr nc, .NoCursor

			ld d, a

			ld hl, (ImageCursorX)
			ld bc, (ImageScrollLeft)
			and a
			sbc hl, bc
			jr c, .NoCursor
			ld a, h
			and a
			jr nz, .NoCursor

			ld e, l					; DE = start cursor position.

								; Positions LEFT UP cursor delimiter.
			ld a, d
			dec a
			out ($98), a				; Y.

			ld a, e
			out ($98), a				; X.

			xor a					; Pattern.
			out ($98), a
		
			out ($98),a				; Padding.

								; Positions RIGHT UP cursor delimiter.
			ld a, d
			dec a
			out ($98), a				; Y.

			ld a, (ImageCursorWidth)
			add a, e
			sub 16
			ld c, a
			out ($98), a				; X.

			ld a, 1*4				; Pattern.
			out ($98),a

			xor a
			out ($98),a				; Padding.

								; Positions LEFT DOWN cursor delimiter.
			ld a, (ImageCursorHeight)
			add a, d
			sub 16
			ld b, a
			dec a
			out ($98), a				; Y.

			ld a, e
			out ($98), a				; X.

			ld a, 2*4
			out ($98), a				; Pattern.

			xor a
			out ($98),a				; Padding.

								; Positions RIGHT DOWN cursor delimiter.
			ld a, b
			dec a
			out ($98), a				; Y.

			ld a, c
			out ($98), a				; X.

			ld a, 3*4
			out ($98), a				; Pattern.

			xor a
			out ($98),a				; Padding.

			ld b, 28
			jr .NoCursorLoop

.NoCursor:		ld hl, $FA00				; Att.
			call @VPOKEPOS
 
			ld b, 32
			
.NoCursorLoop:		ld a, 216
			out ($98), a
			xor a
			out ($98), a
			nop
			out ($98), a
			nop
			out ($98), a
			djnz .NoCursorLoop

			ei
			ret

.2BPPRGB:		ld a, (de)				; Reads the blue and part of the green.
			ld c, a

			inc de
			bit 6,d
			jr z, .NoSkip10

			call @USERAREA_NEXTBYTE.Int
			ret c

.NoSkip10:		ld a, (de)
			ld b, a

			rl c        	                        ; b= 0rrrrrgg c= gggbbbbb
			rla					; pick up the green.

			rl b					; ignores the 0.
			rl b
			rla
			rl b
			rla
			rl b
			rla					; Feeds the red.

			rl c
			rl c					; ignores the unused gg.

			rl c
			rla
			rl c
			rla					; Feeds the blue.
								; A = GGGRRRBB
			out ($98), a

			inc de
			bit 6,d
			ret z

			jp @USERAREA_NEXTBYTE.Int

.3BPPRGB:		ld a, (de)				; Reads the blue.
			rlca
			rlca
			and $03
			ld c, a					; c= 000000bb

			inc de
			bit 6,d
			jr z, .NoSkip1

			call @USERAREA_NEXTBYTE.Int
			ret c

.NoSkip1:		ld a, (de)				; Reads the green.
			and $E0
			or c
			ld c, a					; c= ggg000bb

			inc de
			bit 6,d
			jr z, .NoSkip2

			call @USERAREA_NEXTBYTE.Int
			ret c

.NoSkip2:		ld a, (de)				; Reads the red.
			rra
			rra
			rra
			and $1C
			or c
								; A = GGGRRRBB
			out ($98), a

			inc de
			bit 6,d
			ret z

			jp @USERAREA_NEXTBYTE.Int

.4BPPRGB:		ld a, (de)				; Reads the blue.
			rlca
			rlca
			and $03
			ld c, a					; c= 000000bb

			inc de
			bit 6,d
			jr z, .NoSkip3

			call @USERAREA_NEXTBYTE.Int
			ret c

.NoSkip3:		ld a, (de)				; Reads the green.
			and $E0
			or c
			ld c, a					; c= ggg000bb

			inc de
			bit 6,d
			jr z, .NoSkip4

			call @USERAREA_NEXTBYTE.Int
			ret c

.NoSkip4:		ld a, (de)				; Reads the red.
			rra
			rra
			rra
			and $1C
			or c
								; A = GGGRRRBB
			out ($98), a

			inc de
			bit 6,d
			jr z, .NoSkip5

			call @USERAREA_NEXTBYTE.Int
			ret c

.NoSkip5:		inc de
			bit 6,d
			ret z

			jp @USERAREA_NEXTBYTE.Int

.FetchingTable:		DW	.Unsupported				; RGB format.
			DW	.Unsupported
			DW	.Unsupported				; 1BPP unsupported.
			DW	.Unsupported
			DW	.2BPPRGB
			DW	.2BPPPIXREAD
			DW	.3BPPRGB
			DW	.3BPPPIXREAD
			DW	.4BPPRGB
			DW	.4BPPPIXREAD

.FetchingBFTable:	DW	.Unsupported				; BitFields format.
			DW	.Unsupported
			DW	.Unsupported
			DW	.Unsupported
			DW	.Unsupported
			DW	.Unsupported
			DW	.Unsupported
			DW	.Unsupported
			DW	.Unsupported
			DW	.Unsupported

.Unsupported:		scf
			ret

.SpritePatterns:	DB $FF, $81, $80, $80, $80, $80, $81, $C3, 0,0,0,0,0,$80,$80,$E0, 7,1,1,0,0,0,0,0,0,0,0,0,0,1,1,7
			DB 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, $FF,1,1,1,1,1,1,1 ,0,0,0,0,0,0,0,0
			DB 0,0,0,0,0,0,0,0, $80,$80,$80,$80,$80,$80,$80,$FF,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
			DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,$FF






__PosOnPixel:		push hl					; In/out hlde = pixel address. (input is at home position, output is at the pointed pixel).
			push de					; In BC = X Pos.
			ld a, (ImageBytesCount)
			ld e, a
			ld d, 0
			call @Mult32				; BCHL = BC*DE.

			pop de
			add hl, de
			ex de, hl
			pop hl
			adc hl, bc
			ret






__PosOnLine:		ld hl, (ImageLineSizeHigh)		; In BC = Y position. Out hlde = home position for the given line.
			ld de, (ImageLineSizeLow)		; Out CF = 1 overflow.
			call __Mult3232				; Out HLDE = BC * HLDE.
			ret c

			push hl
			push de
			ld de, (ImageUserAreaArrayAddrLow)
			ld hl, (ImageUserAreaArrayAddrHigh)

			jr __ImageNextLine.Int






__ImageNextLine:	ld bc, (ImageLineSizeHigh)		; IN/OUT hlde = user area address.
			push bc					; Out CF = 1 overflow.
			ld bc, (ImageLineSizeLow)
			push bc

.Int:			ld a, (ImageIsBottomFirst)		
			and a
			jr nz, .TopFirst

			pop bc
			ex de, hl
			add hl, bc
			ex de, hl
			pop bc
			adc hl, bc
			ret

.TopFirst:		pop bc
			ex de, hl
			sbc hl, bc
			ex de, hl
			pop bc
			sbc hl, bc
			ret






__LoadImageConsoleVariables:
			ld hl, SavedImageVars
			ld bc, SavedImageVars_End - SavedImageVars

			exx
			ld hl, (SelectorBunchStartRawAddrHigh)
			ld de, (SelectorBunchStartRawAddrLow)
			ld bc, BunchHeader.Size - BunchHeader.Status
			ex de, hl
			and a
			sbc hl, bc
			ex de, hl
			ld bc, 0
			sbc hl, bc
			exx
			jp @READ_USERAREA






__SaveImageConsoleVariables:
			ld hl, SavedImageVars
			ld bc, SavedImageVars_End - SavedImageVars

			exx
			ld hl, (SelectorBunchStartRawAddrHigh)
			ld de, (SelectorBunchStartRawAddrLow)
			ld bc, BunchHeader.Size - BunchHeader.Status
			ex de, hl
			and a
			sbc hl, bc
			ex de, hl				; Está mal esto.!
			ld bc, 0
			sbc hl, bc
			exx
			jp @WRITE_USERAREA






__Mult3232:		push de					; HLDE = BC * HLDE.
			push hl
			ld a,c
			ld c,b
			exx
			pop hl					; Saves a copy of the multiplicand.
			pop de
			exx

			ld de, 0				; Initializes the result.
			ld l, e
			ld h, d

			ld b,16

.Mult32_Loop:		ex de, hl
			add hl,hl
			ex de, hl
			adc hl,hl
			ret c

			rla
			rl c
			jr nc, .Mult32_NoAdd

			push bc					; Saves the loop counter and part of the multiplier.

			exx
			push hl					; Grabs a copy of the inputed multiplicand.
			push de
			exx
			pop bc
			ex de, hl		
			add hl, bc
			ex de, hl
			pop bc
			adc hl, bc

			pop bc					; Restores the loop counter and part of the multiplier.
			ret c

.Mult32_NoAdd:		djnz .Mult32_Loop
			ret






__FetchGraphics:	ld hl, 0				; // Routine called from the TileEditor, so it must fills up the EDITOR's graphics buffer.

.Loop:			push hl
			call JPPixelRead			; IN HL = YX offsets from the cursor.
								; OUT A = RED LEVEL.
			pop hl					; OUT B = BLUE LEVEL.
			ret c					; OUT C = GREEN LEVEL.			
								; OUT CF = 1, error.
			push hl

			ld e, a					; E = RED LEVEL.

			ld a, (EditorCurrentFormat)
			ld ix, EditorBuffer

			cp FormatID.TileSc2
			jp z, .FullBack				; *** Unsupported in this version, but wanted for future versions ***.

			cp FormatID.TileSc5
			jp z, .Sc5_8x8
			cp FormatID.TileSc5_16
			jp z, .Sc5_16x16
			cp FormatID.TileSc5_32
			jp z, .Sc5_32x32

			cp FormatID.TileSc8
			jp z, .Sc8_8x8
			cp FormatID.TileSc8_16
			jp z, .Sc8_16x16
			cp FormatID.TileSc8_32
			jp z, .Sc8_32x32

.FullBack:		pop hl

			ld a, (SelectorMetaTileSize)

			inc l
			cp l
			jr nz, .Loop

			ld l, 0

			inc h
			cp h
			jr nz, .Loop

			ret

.Sc8_8x8:		push de
			ld a, h					; IN [ECB] for RGB respectivelly.
			add a, a				; IN [IX] Editor buffer base address.
			add a, a				; IN [HL] for YX offsets respectivelly.
			add a, a

.Sc8_ShortCut:		ld e, a
			ld d, 0
.Sc8_ShortCut2:		add ix, de
			ld e, l
			ld d, 0
			add ix, de
			pop de					; IX = H * 8 + L.

			rl c
			rla
			rl c
			rla
			rl c
			rla

			rl e
			rla
			rl e
			rla
			rl e
			rla

			rl b
			rla
			rl b
			rla					; Goal Sc8 format, A = GGGRRRBB.

			ld (IX+0), a				; PSET() on editor's buffer.

			jp .FullBack

.Sc8_16x16:		push de
			ld a, h					; IN [ECB] for RGB respectivelly.
			add a, a				; IN [IX] Editor buffer base address.
			add a, a				; IN [HL] for YX offsets respectivelly.
			add a, a
			add a, a

			jp .Sc8_ShortCut

.Sc8_32x32:		push de
			ld e, h					; IN [ECB] for RGB respectivelly.
			ld d, 0					; IN [IX] Editor buffer base address.
			ex de, hl				; IN [HL] for YX offsets respectivelly.
			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl				; *32.
			ex de, hl			

			jp .Sc8_ShortCut2

.Sc5_8x8:		push de					; IN [ECB] for RGB respectivelly.
			ld a, h					; IN [IX] Editor buffer base address.
			add a, a				; IN [HL] for YX offsets respectivelly.
			add a, a
			ld e, a
			ld d, 0
			add ix, de
			ld e, l
			rr e					; Sc5 uses the half of the buffer space as it is 4bpp.
			add ix, de
			pop de					; IX = IX + H * 4 + (L / 2).

.Sc5_ShortCut:		push hl					; IN [ECB] for RGB respectivelly.

			call __PalChoice2
			
			pop hl
			ld e, a					; E = Picked palette number.

			bit 0, l
			jr z, .MSN

			ld a, (IX + 0)
			and $F0
			or e
			ld (IX + 0), a
			jp .FullBack

.MSN:			ld a, (IX + 0)
			and $0F
			rl e
			rl e
			rl e
			rl e
			or e
			ld (IX + 0), a
			jp .FullBack

.Sc5_16x16:		push de
			ld a, h
			add a, a
			add a, a
			add a, a
			ld e, a
			ld d, 0
			add ix, de
			ld e, l
			rr e
			add ix, de
			pop de					; IX = IX + H * 8 + (L / 2).

			jp .Sc5_ShortCut

.Sc5_32x32:		push de
			ld e, h
			ld d, 0
			and a
			rl e
			rl e
			rl e
			rl e
			rl d
			add ix, de
			ld e, l
			ld d, 0
			rr e
			add ix, de
			pop de					; IX = IX + H * 16 + (L / 2).

			jp .Sc5_ShortCut






__PalChoice2:		ld hl, CurrentPaletteSetBuffer		; IN [ECB] for RGB respectivelly.
								; OUT [A] = palette picked.
			exx

			ld b, 16				; palette format is = xRRRxBBB
			ld c, 0					;                     xxxxxGGG
			
			ld e, $FF				; Choice qualification $FF = worst. $00 = match perfect.
			ld d, 0					; d = current best choice (palette number).

.PickLoop:		exx

			ld a, b
			exx

			and $E0
			rra
			rra
			rra
			rra
			rra					; A = MSBs from BLUE.
			ld l, a

			exx
			ld a,(hl)				; Reads the current palette.
			exx
			and $07
			sub l					; It return a signed value with the difference.

			call .Normalize				; A = ABS(A).
			ld h, a					; Initialize the current qualification.

			exx

			ld a, e
			exx

			and $E0
			rra
			rra
			rra
			rra
			rra
			ld l, a

			exx
			ld a,(hl)
			exx
			rra
			rra
			rra
			rra
			and $07
			sub l

			call .Normalize
			add a, h				; Sums the qualification.
			ld h,a

			exx

			ld a, c
			exx

			and $E0
			rra
			rra
			rra
			rra
			rra
			ld l, a

			exx
			inc hl
			ld a,(hl)
			inc hl
			exx
			and $07
			sub l

			call .Normalize
			add a, h				; Sums the qualification.

			cp e					; Compares the qualifications to see if the current is better.
			jr nc, .Worst

			ld e, a					; Saves the new qualification.
			ld d, c					; Saves the palette number best qualified.

.Worst:			inc c
			djnz .PickLoop

			ld a, d					; Output the choice.
			and $0F
			ret

.Normalize:		cp $80					; A = ABS(A).
			jr c, .POWER2

			cpl
			inc a

.POWER2:		push de
			push bc
			push hl
			ld h,a
			ld e,a
			ld d,0
			ld l,d
			ld b,8
.Mult8_Loop:
			add hl,hl
			jr nc, .Mult8_NoAdd
			add hl,de
.Mult8_NoAdd:
			djnz .Mult8_Loop
			ld a,l
			pop hl
			pop bc
			pop de
			ret





; ALSO LACKS [TAB] and [Q] key support in the image viewer.





IDEEXTP3_END:



; **************************************************
; * OUTPUT FILE FORMAT: IDE.BIN                    *
; **************************************************






; BSAVE header.

FNAME "ide.bin"
FORG $0

	DB $FE
	DW $C000
	DW ORG_END - 1
	DW @RUN



ORG $C000



; **************************************************
; * PRECONFIGURATION                               *
; **************************************************






StorageStartSegment:	DW 0					; $C000.
StorageStopSegment:	DW 0					; $C002.
RamSlotOR:		DB 0					; Slot value for page1 RAM $C004.
RamSSlotOR:		DB 0					; SSlot value for page1 RAM $C005.
								; WARNING: All these four variables must be setup before executing the program.

CurrentRamSegmentCode:	DW 0					; It stores the current ram segment that is on page 1. $C006.
Unused3:		DW 0					; $C008.



; **************************************************
; * PROGRAM LAUNCHER                               *
; **************************************************






@RUN:			di					; $C00A.
			in a,($a8)				; WARNING: for other OS environments maybe all this must be deleted.
			push af					; Save the original slot status.
			and $f3
			ld b,a
			ld a,(RamSlotOR)
			or b
			out ($a8),a
			ld a,($ffff)
			cpl
			push af					; Save the original subslot status.
			and $f3
			ld b,a
			ld a,(RamSSlotOR)
			or b
			ld ($ffff),a
			ei
			ld iy, EXTRUN
			jp @FarJumpToPage1






@ExitProgram:		ld sp, (StackPointerBackUpForExit)	; It rolls back all the stack.
			di
			pop af
			ld ($ffff), a
			pop af
			out ($a8), a
			ld a, 1
			out ($fe), a
			xor a
			out ($fa), a
			ld a, 2
			out ($fd), a
			xor a
			out ($f9), a
			ei
			ld ($8000), a
			ld ($8001), a
			ld ($8002), a
			ld hl, $8001
			ld ($f676), hl
			ret






@FarCallToPage3:	push hl					; WARNING: this set of routines has a hardcoded RAM segment numbers, change 'ld hl, nnnn' to 'ld hl, (aaaa)' and create few variables to hold numbers, allowing OS to select the RAM segments to use.
			ld hl, (CurrentRamSegmentCode)		; WARNING: This set must be fully transparent.
			ex (sp), hl				; WARNING: If change to other OS environments, @SetSegment and @CHRDRAW needs a fix.
								; WARNING: for other OS environment some BIOSCALL needs a fix, @BIOS_RESET, @WRTVDP, @CHGMOD, @CHGET , @BEEP, @BDOSWRAPPED.
								; WARNING: All the user's memory handling is based on a continuos RAM segments assignament, starting by the RAM segment number indicated by 'StorageStartSegment' and 'StorageStopSegment' indicates wich RAM segment don't belong to the user's memory, so user's memory size is = ('StorageStopSegment' - 'StorageStartSegment'). So both variables must be setup before executing the program.
								; INFO: All the program's codepages are executed on slotting page1, and all the user's memory is handled on slotting page2.
								; INFO: All this permanent code and variables can be on slotting page0 or page3.
			call @FarJumpToPage3			; IN [IY] = Addr.
			
			ex (sp), hl
			ld (CurrentRamSegmentCode), hl

			push af

			ld a, l					; Maybe must be remplace by an OS function call.
			out ($fd),a
			ld a, h
			out ($f9),a

			pop af
			pop hl
			ret






@FarJumpToPage3:	push af					; IY = Addr.
			push hl
			ld hl, 3				; ld hl, ().
			ld (CurrentRamSegmentCode), hl

			ld a, l					; Maybe must be remplace by an OS function call.
			out ($fd),a
			ld a, h
			out ($f9),a

			pop hl
			pop af
			jp (iy)






@FarCallToPage2:	push hl
			ld hl, (CurrentRamSegmentCode)
			ex (sp), hl

			call @FarJumpToPage2			; IY = Addr.
			
			ex (sp), hl
			ld (CurrentRamSegmentCode), hl

			push af

			ld a, l					; Maybe must be remplace by an OS function call.
			out ($fd),a
			ld a, h
			out ($f9),a

			pop af
			pop hl
			ret






@FarJumpToPage2:	push af					; IY = Addr.
			push hl
			ld hl, 2				; ld hl, ().
			ld (CurrentRamSegmentCode), hl

			ld a, l					; Maybe must be remplace by an OS function call.
			out ($fd),a
			ld a, h
			out ($f9),a

			pop hl
			pop af
			jp (iy)






@FarCallToPage1:	push hl
			ld hl, (CurrentRamSegmentCode)
			ex (sp), hl

			call @FarJumpToPage1			; IY = Addr.
			
			ex (sp), hl
			ld (CurrentRamSegmentCode), hl

			push af

			ld a, l					; Maybe must be remplace by an OS function call.
			out ($fd),a
			ld a, h
			out ($f9),a

			pop af
			pop hl
			ret






@FarJumpToPage1:	push af					; IY = Addr.
			push hl
			ld hl, 1				; ld hl, ().
			ld (CurrentRamSegmentCode), hl

			ld a, l					; Maybe must be remplace by an OS function call.
			out ($fd),a
			ld a, h
			out ($f9),a

			pop hl
			pop af
			jp (iy)



; **************************************************
; * LIBRARIES                                      *
; **************************************************



; **************************************************
; * KEYBOARD                                       *
; **************************************************






@INKEY:			ld hl,($F3FA)				; Out A = ASCII , CF = 1, nothing inputed.
			ld de,($F3F8)
			xor a
			sbc hl,de
			scf
			ret z
			call @CHGET
			and a
			ret






@KBCLEAR:		ld hl, ($F3F8)
			ld ($F3FA),hl
			ret



; **************************************************
; * ON BITMAP RENDERS                              *
; **************************************************






@DoCopy:		ld a,32					; In:  HL = pointer to 15-byte VDP command data.
			di					; Out: HL = updated.
			out ($99),a				; Credits for: "Fast DoCopy", by Grauw.
			ld a, 17+128
			out ($99),a
			ld c, $9B

			outi
			outi
			outi
			outi
			outi
			outi
			outi
			outi
			outi
			outi
			outi
			outi
			outi
			outi
			outi
			jp @VDP_Ready






@VPOKEPOS:		xor a					; in hl = vram address, from grauw website. In this IDE we only will work with 64K VRAM.
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






@HERASER:		ld h, a					; in a = Ypos line in bitmap.
			ld a, (ScreenBackgroundColor)
			ld c, 0
			ld l, c
			ld b, 1






@HLINE:			ld a, c					; in hl = top/left in bitmap. in c = color. in b = length (=0 means 256).
			ld c, b
			ld b, 1






@BLOCKFILL:		ld e, a					; in hl = top/left in bitmap. in bc = heigh/width, in a = color.

			ld a,36
			di
			out ($99),a
			ld a, 17+128
			out ($99),a

			ld a, (IsOnPaletteScreenMode)
			and a
			jr z, .Sc8J1

			ld a, l
			rla
			out ($9B), a
			ld a, 0
			rla
			out ($9B), a
			jr .J1

.Sc8J1:			ld a, l
			out ($9B), a
			xor a
			out ($9B), a

.J1:			ld a, h
			out ($9B), a
			xor a
			out ($9B), a

			ld a, c
			and a
			jr nz, .NXOk

			ld a, (IsOnPaletteScreenMode)
			and a
			jr z, .Sc8J3

			xor a
			out ($9B), a
			ld a, 2
			out ($9B), a
			jr .J2

.Sc8J3:			xor a
			out ($9B), a
			inc a
			out ($9B), a
			jr .J2			

.NXOk:			ld a, (IsOnPaletteScreenMode)
			and a
			jr z, .Sc8J2

			ld a, c
			rla
			out ($9B), a
			ld a, 0
			rla
			out ($9B), a
			jr .J2

.Sc8J2:			ld a, c
			out ($9B), a
			xor a
			out ($9B), a

.J2:			ld a, b
			out ($9B), a
			xor a
			out ($9B), a

			ld a, e
			out ($9B), a

			xor a
			out ($9B), a

			ld a, $C0
			out ($9B), a






@VDP_Ready:		ld a,2
			di
			out ($99),a				; select s#2.
			ld a,15+128
			out ($99),a
			in a,($99)
			rra
			ld a,0					; back to s#0, enable ints.
			out ($99),a
			ld a,15+128
			ei
			out ($99),a				; loop if vdp not ready (CE).
			jp c, @VDP_Ready
			ret






@SQUARE:		push hl					; in hl = top/left in bitmap. in bc = Height/Width. in a = color.
			push af					; It don't checks any visual overflow.
			push bc
			ld b,c
			ld c,a
			call @HLINE
			pop bc
			pop af
			pop hl
			push hl
			push af
			push bc
			push af
			ld a,h
			add b
			dec a
			ld h,a
			ld b,c
			pop af
			ld c,a
			call @HLINE
			pop bc
			pop af
			pop hl
			push hl
			push af
			push bc
			ld c,a
			call @VLINE
			pop bc
			pop af
			pop hl
			push af
			ld a,c
			add a,l
			dec a
			ld l,a
			pop af
			ld c,a






@VLINE:			ld a, c					; in hl = top/left in bitmap. in c = color. in b = length (=0 means 256).
			ld c, 1
			jp @BLOCKFILL






@CLSLP:			ld b, a
			ld a, 212
			sub b
			ret c
			ret z
			ld c, 0
			ld h, b
			ld l, c
			ld b, a
			ld a, (ScreenBackgroundColor)
			jp @BLOCKFILL



; **************************************************
; * STRINGs HANDLING & CHR PRINTING                *
; **************************************************






@STRLEN:		ld c,0					; in hl = string NULL TERMINATED address.
								; out c = LEN().
.Loop:			ld a,(hl)				; out hl = next addr from the NULL char.
			inc hl					; MOD (A).
			and a
			ret z

			inc c
			jr .Loop






@STRDRAWZ:		ld a,(hl)				; in de = top/left bitmap address.
			and a					; in hl = string NULL TERMINATED address.
			ret z		  			; out hl = NULL char address.
								; out de = top/left at the end of the printed string.
			push hl					; in RenderForeColor: RenderBackColor.
			push de

			call @CHRDRAW

			pop de
			ld a,e
			add a,6
			ld e,a
			jr c, .CRLF
			cp $FA
			jr c, .NoCR

.CRLF:			ld e,0
			ld a,d
			add a,8
			ld d,a

.NoCR:			pop hl
			inc hl
			jr @STRDRAWZ






@STRDRAW:		ld a,b					; in de = top/left bitmap address.
			and a					; in hl = fixed size string address.
			ret z					; in b = string length.
								; in RenderForeColor: RenderBackColor.
.STRLP:			push bc
			ld a,(hl)
			push hl
			push de

			call @CHRDRAW

			pop de
			ld a,e
			add a,6
			ld e,a
			jr c, .CRLF
			cp $FA
			jr c, .NoCR

.CRLF:			ld e,0
			ld a,d
			add a,8
			ld d,a

.NoCR:			pop hl
			inc hl
			pop bc	
			djnz .STRLP
			ret






@CHRDRAW:		ld l,a					; in de = top/left bitmap address.
			ld h,0					; in A = chr number.
								; in RenderForeColor: RenderBackColor.
			add hl,hl				; WARNING: This routine requires that MSXBIOS is in page0, fix it for others OS environments.
			add hl,hl
			add hl,hl
			ld bc,(4)				; Reads the base addr of the char set table in ROM.
			add hl,bc
								; hl = first byte of the pattern.
			ld b,8					; 8 lines.

.CHRLLP:		push bc

			push hl					; Saves the pattern address.
			push de					; Saves the VRAM pos.

			ld a,(hl)				; reads the current pattern line.

			di

			push af
			ex de,hl
			call @VPOKEPOS
			pop af

			ld de,(RenderForeColor)			; and by continuity reads the BackColor in [d] aswell.
			ld b,6					; Only draws 6 points per line.

.CHRPLP:		rlca
			push af
			ld a,e
			jr c, .CHRPIX
			ld a,d

.CHRPIX:		out ($98),a				; PSET equivalent.
			pop af

			djnz .CHRPLP				; Pixel loop.

			pop de
			inc d					; 1 Pixel move down.
			pop hl
			inc hl					; Next line address from the pattern.

			pop bc
			djnz .CHRLLP				; Line loop.
			ei
			ret






@UPCASE:		cp 'a'
			ret c
			cp 'z'+1
			ret nc
			sub 'a'-'A'
			ret






@VAL:			ld de,0					; in hl = string NULL TERMINATED address.
								; out de = 16bits value. CF = 1 overflow for 16bits.
.Loop:			ld a,(hl)
			inc hl
			and a
			ret z

			cp $30
			jr c, .Loop

			cp $3A
			jr nc, .Loop

			sub $30					; a = a - '0'

			push hl
			ld l, e
			ld h, d
			add hl,hl
			jr c, .Ov
			add hl,hl
			jr c, .Ov
			add hl,hl
			jr c, .Ov
			add hl,de
			jr c, .Ov
			add hl,de
			jr c, .Ov
			ld e,l
			ld d,h					; de = de * 10.
			pop hl

			add a,e
			ld e,a
			ld a,d
			adc a,0
			ld d,a					; de = de + a.
			jr nc, .Loop
			ret

.Ov:			pop hl
			ret



; **************************************************
; * USER MEMORY MANAGEMENT IN BUNCHS LEVEL         *
; **************************************************






@GETBUNCH_BASEADDR:	call @GETBUNCH_LINKADDR			; in BC = Bunch Index. It can't return the freemark bunch.
			ret c					; OUT hlde = Base address of the bunch.
								; OUT (CF) = 1 error.
			ld bc, 4				; MOD (abc).
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc				; hlde = hlde + 4 = base address of the bunch content!.
			ret






@GETBUNCH_LINKADDR:	ld hl,0					; in BC = Bunch Index. It can't return the freemark bunch.
			ld e,l					; OUT hlde = Link address of the bunch.
			ld d,h					; OUT (CF) = 1 error.
								; MOD (abc).
.Loop:			ld a,b
			or c
			jr z, .IsThisOne

			push bc
			push hl
			push de
			call @USERAREA_RDW			; This outs the DWORD in [hlbc].
			pop de					; MOD (ade).
			jr nc, .RdOk

.Err:			pop hl
.Err2:			pop bc
			ret

.RdOk:			ld a,c					; Checks if the DWORD readed is the freemark.
			or b
			or l
			or h
			scf
			jr z, .Err

			ex de,hl
			add hl,bc
			ex de,hl
			pop bc					; Gets high word of old hlde.
			adc hl,bc				; hlde = old hlde + DWORD readed (hlbc).

			jr c, .Err2				; escapes if overflow.

			ld bc,4
			ex de,hl
			add hl,bc
			ex de,hl
			ld c,0
			adc hl,bc				; hlde = hlde + sizeof(DWORD).

			pop bc					; Restores the bunch count down.
			ret c

			dec bc
			jr .Loop

.IsThisOne:		push hl
			push de
			call @USERAREA_RDW			; This outs the DWORD in [hlbc].
			pop de					; MOD (ade).
			jr c, .Err2

			ld a,c					; Checks if the DWORD readed is the freemark.
			or b
			or l
			or h
			pop hl
			ret nz

			scf
			ret



; **************************************************
; * LOW LEVEL MEMORY ACCESS ABSTRACTION            *
; **************************************************






@LogicToRawAddr:	ld a,h					; in hlde = plain user area offset address.
			and $c0					; out hl = RAM segment.
			scf					; out de = RAM address in page2.
			ret nz					; out CF = 1 error.
								; MOD (a).
			rl d
			rl l					; CF < hld < 1
			rl h

			rl d					; CF < hld < 0
			rl l
			rl h

			rrc d					; bits 1,0 moved to bits 7,6 as just needed por page2 access.
			rrc d					; Setup for page2 access.

			push bc

			ld bc,(StorageStartSegment)
			add hl,bc
			jr nc, .Ok

			pop bc
			ret

.Ok:			ld bc,(StorageStopSegment)
			push hl
			sbc hl,bc
			pop hl
			pop bc
			ccf
			ret






@USERAREA_NEXTBYTE:	inc de					; in CF = 0, in/out hl/de MSX RAW segment/address.
			bit 6,d					; MOD (a).
			ret z

.Int:			inc hl					; Next segment.
			ld a,l
			or h
			scf
			ret z					; Escape if overflows.

			ex de,hl
			ld hl,(StorageStopSegment)
			and a
			sbc hl,de
			ex de,hl
			scf
			ret z					; Escapes if ends the storage area.
	
			call @SetSegment
			ret c

			ld de, $8000				; unfortunaly DE is destroyed before.
			ret






@SetSegment:		ld a,l					; in HL = RAM Segment.
			out ($FE),a				; out CF = 1 error.
			ld a,h					; MOD (a).
			out ($FA),a				; WARNING: For others OS environments this must be changed by an OS function call.
			and a					; Only the register [A] can be changed by this function, and CF = 0, if CF = 1 it will means ERROR in higher layers.
			ret






@USERAREA_RB:		call @LogicToRawAddr			; in hlde = plain user area offset address.
			ret c					; out A = dato, CF = 1 error.
			call @SetSegment			; MOD (hlde).
			ret c

			ld a,(de)
			ret






@USERAREA_RW:		call @LogicToRawAddr			; in hlde = plain user area offset address.
			ret c					; out bc = dato.
			call @SetSegment			; out CF = 1 error.
			ret c					; MOD (ahlde).

			ld a,(de)
			ld c,a

			call @USERAREA_NEXTBYTE
			ret c

			ld a,(de)
			ld b,a
			ret






@USERAREA_RDW:		call @LogicToRawAddr			; in hlde = plain user area offset address.
			ret c					; out hlbc = dato.
			call @SetSegment			; out CF = 1 error.
			ret c					; MOD (ade).

			ld a,(de)
			ld c,a

			call @USERAREA_NEXTBYTE
			ret c

			ld a,(de)
			ld b,a

			call @USERAREA_NEXTBYTE
			ret c

			ld a,(de)
			push af

			call @USERAREA_NEXTBYTE
			jr nc, .J1

			pop af
			scf
			ret

.J1:			pop af
			ld l,a
			ld a,(de)
			ld h,a
			ret






@USERAREA_WB:		push af					; in hlde = plain user area offset address.
			call @LogicToRawAddr			; in A = dato.
			jr c, .Err				; out CF = 1 error.
			call @SetSegment			; MOD (hlde).
			jr c, .Err
			pop af

			ld (de),a
			and a
			ret

.Err:			pop de
			ret






@USERAREA_WW:		call @LogicToRawAddr			; in hlde = plain user area offset address.
			ret c					; in  bc = dato.
			call @SetSegment			; out CF = 1 error.
			ret c					; MOD (ahlde).

			ld a,c
			ld (de),a

			call @USERAREA_NEXTBYTE
			ret c

			ld a,b
			ld (de),a
			ret






@USERAREA_WDW:		call @LogicToRawAddr			; in hlde = plain user area offset address.
			ret c					; in hl'bc = dato.
			call @SetSegment			; out CF = 1 error.
			ret c					; MOD (ahldebc).

			ld a,c
			ld (de),a

			call @USERAREA_NEXTBYTE
			ret c

			ld a,b
			ld (de),a

			call @USERAREA_NEXTBYTE
			ret c

			exx
			push hl
			exx
			pop bc

			ld a,c
			ld (de),a

			call @USERAREA_NEXTBYTE
			ret c

			ld a,b
			ld (de),a
			ret






@SELECTORLOAD:		ld de,(SelectorCurrentRawAddrLow)	; out CF = 1 error.
			ld hl,(SelectorCurrentRawAddrHigh)	; MOD (ahldebchl'de'bc').
			exx
			ld a,(SelectorCurrentFormat)
			ld iy, _GETOBJECTSIZE
			call @FarCallToPage2
			ld hl, SelectorBuffer






@READ_USERAREA:		exx					; in hl'de' = source plain user area offset address.
			call @LogicToRawAddr			; in hl = destination buffer base address.
			ret c					; in bc = length.
			call @SetSegment			; out CF = 1 error.
			ret c					; MOD (ahldebchl'de'bc').

			push de
			exx
			ex de,hl
			pop hl					; passes HL = address in page2.

			ld a,b
			or c
			ret z					; Checks for zip copies.

.Loop:			ldi					; (hl) -> (de) -> inc HL inc DE dec BC. P/V = BC = 0.
			ret po

			bit 6,h
			jr z, .Loop

			ld h, $80				; Roll Up pointer.

			exx					; Next segment.
			inc hl
			ld a,h
			or l
			scf
			ret z					; It overflowed.

			ex de,hl
			ld hl,(StorageStopSegment)
			and a
			sbc hl,de
			ex de,hl
			scf
			ret z					; Escapes if ends the storage area.

			call @SetSegment
			ret c

			exx
			jr .Loop






@EDITORSAVE:		ld de,(EditorCursorAddrLow)		; It saves the editing to the USER DATA.
			ld hl,(EditorCursorAddrHigh)		; MOD (ahldebchl'de'bc').
			exx
			ld a,(EditorCurrentFormat)
			ld iy, _GETOBJECTSIZE
			call @FarCallToPage2
			ld hl, EditorBuffer






@WRITE_USERAREA:	exx					; in hl'de' = destination plain user area offset address.
			call @LogicToRawAddr			; in hl = source buffer base address.
			ret c					; in bc = length.
			call @SetSegment			; out CF = 1 error.
			ret c					; MOD (ahldebchl'de'bc').

			push de
			exx
			pop de					; de = address in page2.

			ld a,b
			or c
			ret z					; Checks for zip copies.

.Loop:			ldi					; (hl) -> (de) -> inc HL inc DE dec BC. P/V = BC = 0.
			ret po

			bit 6,d
			jr z, .Loop

			ld d, $80				; Roll up pointer.

			exx					; Next Segment.
			inc hl
			ld a,h
			or l
			scf
			ret z					; It overflowed.

			ex de,hl
			ld hl,(StorageStopSegment)
			and a
			sbc hl,de
			ex de,hl
			scf
			ret z					; Escapes if ends the storage area.

			call @SetSegment
			ret c

			exx
			jr .Loop



; **************************************************
; *  MATH ROUTINES                                 *
; **************************************************






@DIV16_8:		xor	a				; Out A = hl mod c, hl = hl \ c.
			ld	b, 16

.loop:			add	hl, hl
			rla
			cp	c
			jr	c, .Next
			sub	c
			inc	l

.Next:			djnz	.loop

			ret






@DIV32_16:		push bc					; Do hlde = (hlde \ bc), hl'de' = (hlde MOD bc): out hlde = result, out hl'de' = REST, out BC' = divider.
			exx
			ld hl,0
			ld de,0					; Initialize the REST.
			pop bc					; BC' = divider.
			exx

			ld a,h
			ld b,8

			call .L1

			ld h,a					; Saves the result. h bit 7 = garbage (depends on the inputed CF when called the routine).
			ld a,l					; Loads another part of the DIVIDE.
			ld b,8

			call .L1

			ld l,a					; L bit 7 = LSB that is for H register.
			ld a,d
			ld b,8

			call .L1

			ld d,a					; D bit 7 = LSB that is for L register.
			ld a,e
			ld b,8

			call .L1
								; A bit 7 = LSB that is for D register.
			rla					; It pushes the last bit of the result.
			cpl					; Normalize the result.
			ld e,a
			ld a,d
			rla
			cpl
			ld d,a
			ld a,l
			rla
			cpl
			ld l,a
			ld a,h
			rla
			cpl
			ld h,a
								; hlde = result, hl'de' = REST, BC' = divider.
			ret

.L1:			rla					; CF < A < CF. (Move the MSB to CF) and pickup the result bit from CF that pushs in negated.
			exx
			ex de,hl
			adc hl,hl
			ex de,hl
			adc hl,hl				; HL < CF. CF = 0, This ADC has not enough executions to really activate the CF.

			ex de,hl
			sbc hl,bc
			ex de,hl
			push bc
			ld bc,0
			sbc hl,bc
			pop bc					; REST = REST - DIVIDER.
			jr nc, .NoAdd1
								; the rest overflowed?, ok, restore the REST.
			ex de,hl
			add hl,bc
			ex de,hl
			push bc
			ld bc,0
			adc hl,bc				; This will out CF = 1 always, because it already detected an overflow on the previous operation.
			pop bc

.NoAdd1:		exx
			djnz .L1

			ret






@Mult32:		ld a,c					; Thanks grauw. BCHL = BC*DE.
			ld c,b
			ld hl,0
			ld b,16

.Mult32_Loop:		add hl,hl
			rla
			rl c
			jr nc, .Mult32_NoAdd
			add hl,de
			adc a,0
			jp nc, .Mult32_NoAdd
			inc c

.Mult32_NoAdd:		djnz .Mult32_Loop
			ld b,c
			ld c,a
			ret






@M32COMP:		exx					; It unsigned compares HLDE with HL'DE'	(Flags) Z C for <=>.
			push hl					; MOD (bc).
			exx
			pop bc

			and a
			push hl
			sbc hl,bc
			pop hl
			ret nz

			exx
			push de
			exx
			pop bc

			ex de,hl
			push hl
			sbc hl,bc
			pop hl
			ex de,hl
			ret






@M32SUB:		exx					; It unsigned  HLDE = HLDE - HL'DE'  (CF) = 1 if negative.
			push de					; MOD (bc).
			exx
			pop bc
			ex de,hl
			and a
			sbc hl,bc
			ex de,hl
			exx
			push hl
			exx
			pop bc
			sbc hl,bc
			ret



; *****************************************************
; *  DISK ACCESS & ERROR HANDLING (BASIC ENVIRONMENT) *
; *****************************************************






@BDOS:				push af

				xor a
				ld (DiskErrorCode),a		; Resets the error code.

				in a, ($a8)
				ld (BDOSA8Status), a

				ld a, ($FFFF)
				cpl
				ld (BDOSFFFFStatus), a

				pop af

				ld (BDOSStackWrap), sp		; Save the stack return point from an abort.

				jp @BDOSWRAPPED






@DiskErrorHandlerPTR:		DW	@rberr






@rberr:								; in A = Logical drive number (0=A ...), in C = Error
								; b7=1 : Bad FAT.
								; b0=0 : Read action.
								; b0=1 : Write action.
								; b3 b2 b1
								; 0  0  0: Write Protected.
								; 0  0  1: Not Read (disk offline).
								; 0  1  0: CRC error.
								; 0  1  1: Seek error.
								; 1  0  0: Record not found (sector not found).
								; 1  0  1: Write error.
								; 1  1  0: Other.

								; C = 0 Ignore error (bdos function continues and returns to program).
								; C = 1 Retry.
								; C = 2 Abort program.
				push af
				ld a, c
				or $40				; Make sure it is not zero.
				ld (DiskErrorCode),a
				pop af
				ld c, 2				; ABORT!.
				ret






@abort:				ld sp, (BDOSStackWrap)

				ld a, (BDOSA8Status)
				out ($a8), a

				ld a, (BDOSFFFFStatus)
				ld ($FFFF), a

				ld a, $FF			; WARNING: It assumes mapper hasn't changed by the BDOS / DISKROM.
				and a

				ret				; Returns after the original BDOS function call.



ORG_END:



; **************************************************
; * VARIABLES                                      *
; **************************************************






VAR_START:

StackPointerBackUpForExit:	RW	1			; It helps later to exit back to BASIC.

IsOnPaletteScreenMode:		RB	1			; <> 0 Yes!.

VarColorSetStart:
MenuCursorForeColor:		RB	1			; Current color theme.
MenuCursorBackColor:		RB	1
MenuForeColor:			RB	1
MenuBackGroundColor:		RB	1
MenuBorderColor:		RB	1
TextBoxForeColor:		RB	1
TextBoxBackColor:		RB	1
CheckBoxHitTrueColor:		RB	1
CheckBoxBackColor:		RB	1
MsgBoxCursorColor:		RB	1
BunchTitleBarForeColor:		RB	1
BunchTitleBarBackColor:		RB	1
OutlineCursorColor:		RB	1
OutlineColor:			RB	1
OutlineSecondaryColor:		RB	1
OutlineBackGroundColor:		RB	1
OutlinePrimaryRemarkColor:	RB	1
OutlineSecondaryRemarkColor:	RB	1
OutlineRED:			RB	1
OutlineGREEN:			RB	1
OutlineBLUE:			RB	1
ScreenBackgroundColor:		RB	1
VarColorSetEnd:

ColorThemeWasChanged:		RB	1			; <> 0 indicates that the color theme selection was changed, because the current palettes were edited or changed, so, it is a signal to force redraw everything.

RenderForeColor:	 	RB	1			; Both variables used for printing strings on the screen.
RenderBackColor:	 	RB	1
STR_Buffer:			RB 	11			; Used by the equivalent of Str$(number), for convert 32bit absolute numbers in string. The reserved space includes the nullchar.

MPItemsCount:			RB	1			; MenuPopUps, itemsCount.
MPContentWidth:			RB	1
MPContentHeight:		RB	1			; MPContent$$$$$ stores the calculated size for the menu popup.
MPItemIndex:			RB	1			; cursor position in the menu popup.
MBItemIndex:			RB	1			; MenuBar cursor position.
MBItemCount:			RB	1			; ItemsCount in the menubar.
MsgBoxWidth:			RB	1
MsgBoxHeight:			RB	1			; MsgBoxWidth & height, calculated size of the useable surface of the message box window.
MsgBoxTY:			RB	1			; Y visual position where start the TextBox.
MsgBoxTQ:			RB	1			; Y visual position where start the list of checkboxes or optionboxes.
MsgBoxInsert:			RB	1			; FF = the user is inserting (the default is inserting), if the user uses the arrows it will cancel the insertion.
MsgBoxCurPos:			RB	1			; cursor position inside the textbox.
MsgBoxObCur:			RB	1			; it points wich object in the window has the FOCUS, FF = textbox, 0 and up = checkbox or optionbox index.
MsgBoxObCount:			RB	1			; it stores how many checkboxes or optionboxes are created.
MsgBoxTBLeft:			RB	1
MsgBoxTL:			RB	1			; It stores the maximun lenght allowed for the string in the textbox, if = 0 there is no textbox and it will no load the STRING from the inputed data, so the string and its nullchar must not be in the inputed data.
MsgBoxQAddr:			RW	1
MsgBoxAreOptions: 		RB	1			; = 0 are checkboxes, <> 0 are optionboxes.
MsgBoxBuffer:			RB	129			; buffer for the string of the textbox.
MsgBoxCheckValues:		RB	24			; buffer for store the current value of the checkboxes or optionboxes, one byte per checkbox = 0 , <> 0 hitted.
MsgBoxDontStartBuffer:		RB	1			; If <> 0 it prevents that the textbox loads its default content.

CreatingWidth:			RW	1
CreatingHeight:			RW	1			; Width & Height used for bookeeping when creating the bunch of a map scene.
CreatingAmmount:		RW	1			; used for set up the routine that creates a bunch in the userarea.
CreatingFormat:			RB	1
CreatingBunchID:		RW	1
CreatingNotZeroing:		RB	1			; A flag to avoid CreateBunch to sweep with zeros all the memory assigned to the bunch.

LinkingWichBunch:		RW	1			; Used during the linking process.
LinkingToBunch:			RW	1			; The linking allows like: link a tileset to a PaletteSet, link an indexator Map to a tileset, link a map to an indexator, and linking a SpriteSet to a PaletteSet.
LinkingWichFormat:		RB	1			

SelectorBunchName:		RB	17			; Bunch name null terminated string loaded when the user is selecting the current bunch, the selector is indexed by name and not by address because the userarea can get change.
SelectorBunchIndex:		RW	1
SelectorBunchStartRawAddrLow:	RW	1			; if user area changes its storage situation, these variables addresses must be recalculated, using the bunch name.
SelectorBunchStartRawAddrHigh:	RW	1			; Prefixed one time when the selector shows the first time or change when the user want to move to another bunch.
SelectorCurrentFormat:		RB	1			; Each bunch have its own format indication, not only if tiles, also if sprites or others added features.
SelectorMetaTileSize:		RB	1			; It can be 8, 16, or 32, 0 if another format than TileSelector.

EditorCurrentFormat:		RB	1
EditorCursorAddrLow:		RW	1			; Needed for pointing where to 'save' the object edited.
EditorCursorAddrHigh:		RW	1
EditorCurrentlyInUse:		RB	1			; <> 0, the user is editing a tile.

SavedSelectorTileVariables:
SelectorCurrentScrollTop:	Rw	1			; Scroll bar top position (wich is the first object in the selector that must be shown on the first visual position on the current view).
SelectorCursorObjectNumber:	RW	1
PuzzlerIndexationBuffer:	RB	7*16			; Up to 16 tiles indexed in the puzzler, 4 bytes for pointing the RAW address in the userarea, 1 bytes for pointing the format code of the tile + 2 bytes for storing its tile number.

EditorCursorX: 			RB	1			; Cursor X in the matrix editor.
EditorCursorY:			RB	1			; cursor Y in the matrix editor.
EditorCurrentForeColor:		RB	1			; Primary color code or color byte.
EditorCurrentBackColor:		RB	1			; Secondary Color code or color byte.
EditorCurrentLastPickedColor:	RB	1			; It permits to the editor remember wich picked color. In way "to link two separated events" that changes the color selection or chroma channel.
EditorCurrentPickerCursor:	RB	1			; It points where in the picker was the last time the cursor.
EditorCursorBackUp:		RW	1			; Back up of the cursor position when using the FastInOutPicker feature.
SavedSelectorTileVariables_End:

SelectorCurrentObjectNumber:	RW	1			; Used for visuals calculations.
SelectorObjectsCount:		RW	1			; Used to calculate the scope of the scrollbar.
SelectorCurrentRawAddrLow:	RW	1
SelectorCurrentRawAddrHigh:	RW	1			; Used when is rendrawing a given tile.
SelectorStopRawAddrLow:		RW	1
SelectorStopRawAddrHigh:	RW	1			; Used to indicate when the bunch actualy ended, so it will stop redrawing tiles.
SelectorCopyFromFormat:		RB	1			; It points the format of the bunch from where it will copy or exchange.
SelectorCopyFromRawAddrLow:	RW	1			; Source address for the COPY/Exchange operation.
SelectorCopyFromRawAddrHigh:	RW	1
SelectorCopyToFormat:		RB	1			; It points the format of the destination bunch.
SelectorCopyToRawAddrLow:	RW	1
SelectorCopyToRawAddrHigh:	RW	1
SelectorCopyStopRawAddrLow:	RW	1
SelectorCopyStopRawAddrHigh:	RW	1

SelectorLinkedTileBunchIndex:	RW	1			; Preloaded in the rendering of the Indexator or Map.
SelectorLinkedTileBaseAddrLow:	RW	1
SelectorLinkedTileBaseAddrHigh:	RW	1
SelectorLinkedTileObjectCount:	RW	1
SelectorLinkedTileFormat:	RB	1
SelectorLinkedTileSize:		RB	1			; 8 or 16 are valid for using the tile grouping.
SelectorLinkedIndexatorBunchIndex:RW	1

SavedSelectorIndexatorVariables:
SelectorLinkedIndexatorScrollTop:RW	1
SelectorLinkedIndexatorCursor:	RW	1

SelectorIndexatorCursorHOT0:	RW	1			; used to store the more used blocks when mapping.
SelectorIndexatorCursorHOT1:	RW	1
SelectorIndexatorCursorHOT2:	RW	1
SelectorIndexatorCursorHOT3:	RW	1
SelectorIndexatorCursorHOT4:	RW	1
SelectorIndexatorCursorHOT5:	RW	1
SelectorIndexatorCursorHOT6:	RW	1
SelectorIndexatorCursorHOT7:	RW	1
SelectorIndexatorCursorHOT8:	RW	1
SelectorIndexatorCursorHOT9:	RW	1
SavedSelectorIndexatorVariables_End:

SelectorLinkedIndexatorAddrLow:	RW	1
SelectorLinkedIndexatorAddrHigh:RW	1
SelectorLinkedIndexatorObjectCount:RW	1
SelectorLinkedIndexatorXTilecount:RB	1
SelectorLinkedIndexatorYTilecount:RB	1
SelectorLinkedIndexatorWidthVisual:RB	1			; 16 or 32 are valid.
SelectorLinkedIndexatorHeightVisual:RB	1			; 16 or 32 are valid.
SelectorLinkedIndexatorFormat:	RB	1
SelectorLinkedIndexatorLastObjectDrawn:	RW	1
SelectorLinkedActivityLastDone:	RB	1			; = 0 the last thing was a puzzle. <> 0 the last thing was a hit in the map (finally unused).

SelectorMapBunchIndex:		RW	1			; Preloaded in the rendering of the map.
SelectorMapAddrLow:		RW	1
SelectorMapAddrHigh:		RW	1

SavedSelectorMapVariables:
SelectorMapScrollTop:		RW	1
SelectorMapScrollLeft:		RW	1
SelectorMapCursorX:		RW	1
SelectorMapCursorY:		RW	1
SelectorMapCopyX:		RW	1
SelectorMapCopyY:		RW	1
SelectorMapCopyStopX:		RW	1
SelectorMapCopyStopY:		RW	1
SelectorMapCopyStage:		RB	1
SavedSelectorMapVariables_End:

SelectorMapDestinationX:	RW	1
SelectorMapDestinationY:	RW	1
SelectorMapDestinationXHome:	RW	1
SelectorMapSourceXHome:		RW	1

SelectorMapBlocksWidth:		RW	1
SelectorMapBlocksHeight:	RW	1
SelectorMapFormat:		RB	1
SelectorMapRowSizeLow:		RW	1
SelectorMapRowSizeHigh:		RW	1
SelectorMapLastRowDrawn:	RW	1
SelectorMapLastColumnDrawn:	RW	1
SelectorMapCursorShow:		RB	1
SelectorMapDrawCustomMode:	RB	1			; 0 = draw all, 1 = draw column number, 2 = draw row number.
SelectorMapDrawCustomNumber:	RW	1			; Number of column or row to draw.
SelectorMapDirect:		RB	1			; <> 0 is using direct TileSet -> MAP.
SelectorMapCallingFromMapConsole:RB	1			; <> 0 is calling from inside the MAP console.
SelectorMapBlockAttribsMask:	RW	1			; When using 16bits mapping is normal that some bits are unused if the metatile count is not 32768 or more. This variable masks wich bits can be use for others purposes like block attributes.
SelectorMapBlockGraphicsMask:	RW	1			; It masks all bits used for pointing out the metatile ID stored in each map's block.

PuzzlerForceRenderAll:		RB	1			; Overrides the "only render what is being edited" feature.

FastBunchBack:			RW	1			; Needed by the 'Q' key.

FCB:				RB	37			; FCB for save/load bunchs to/from disk.
FCBTransferRemainsLow:		RW	1
FCBTransferRemainsHigh:		RW	1
FCBTransferCurrentSize:		RW	1
FCBTransferRawUserAreaAddrLow:	RW	1
FCBTransferRawUserAreaAddrHigh:	RW	1

DiskErrorHandlerHookUpBackUp:	RW	1			; For BASIC environment.
AbortHandlerHookUpBackUp:	RW	1
DiskErrorCode:			RB	1
BDOSStackWrap:			RW	1
BDOSA8Status:			RB	1
BDOSFFFFStatus:			RB	1

CurrentPaletteSetBuffer:	RW	16			; Current pallete data in use.

UserAreaCpySourceLow:		RW	1
UserAreaCpySourceHigh:		RW	1
UserAreaCpyDestinationLow:	RW	1
UserAreaCpyDestinationHigh:	RW	1
UserAreaCpyLengthLow:		RW	1
UserAreaCpyLengthHigh:		Rw	1

SelectorBuffer:			RB	1024			; 1024 bytes is the maximun object size that the selector can load. (change this reservation if needed more when adding more formats).
EditorBuffer: 			RB	1024

SavedImageVars:
ImageWidth:			RW	1			; Unsigned values.
ImageHeight:			RW	1
ImageUserAreaArrayAddrLow:	RW	1			; It points to the first line address, but if it is 'bottom first', it points at the last line in the array.
ImageUserAreaArrayAddrHigh:	RW	1
ImageLineSizeLow:		RW	1			; Include the padding bytes.
ImageLineSizeHigh:		RW	1
ImageIsBottomFirst:		RB	1			; <> 0 Bottom First.
ImageBytesCount:		RB	1			; bytes per pixel.
ImageCompression:		RB	1
ImageScrollTop:			RW	1
ImageScrollLeft:		RW	1
ImageCursorX:			RW	1
ImageCursorY:			RW	1
ImageCursorWidth:		RW	1
ImageCursorHeight:		RW	1
SavedImageVars_End:

ImageXCount:			RW	1
ImageXCountLeft:		RW	1
ImageYCountDown:		RW	1
JPPixelFetch:			RB	3			; Jump to pixel fetching data routine.

JPPixelRead:			RB	3			; Jump to pixel read.
								; IN HL = YX offsets from the cursor.
								; OUT A = RED LEVEL.
								; OUT B = BLUE LEVEL.
								; OUT C = GREEN LEVEL.			
								; OUT CF = 1, error.

DTA:								; When the files are handled, the UserAreaCpyBuffer is not used.
UserAreaCpyBuffer:		RB	256+64			; Used as a buffer for USERAREA_COPY and by others routines as a general purpose buffer/work area.

VAR_END:


