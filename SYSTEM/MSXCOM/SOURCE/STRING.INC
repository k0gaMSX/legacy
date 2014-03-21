STR_COMMAND_MSG:
	DB	'The MSX Commander 1.1.04 (C) 2012                        retrocanada76@gmail.com',0

STR_WRONG_DOS_VERSION:
	DB	'This program requires MSX-DOS 2.20 or higher',$0d,$a,'$'

STR_NO_SHELL:
	DB '***Error this program requires the SHELL enviroment',$0a,$0d
	DB '   Add the following line to your AUTOEXEC.BAT',$0a,$0d,$0a,$0d
	DB '   set SHELL=%1\COMMAND2.COM$'
	
STR_PROGRAM:
	DB	'PROGRAM',0
	
STR_MENU_LEFT:
	DB	' Left ',0

STR_MENU_FILE:
	DB	' File ',0

STR_MENU_COMMAND:
	DB	' Command ',0

STR_MENU_OPTIONS:
	DB	' Options ',0

STR_MENU_RIGHT:
	DB	' Right ',0
	
STR_FKEY_HELP:
	DB	'Help  ',0

STR_FKEY_QUIT:
	DB	'Quit ',0

STR_FKEY_USER:
	DB	'User  ',0

STR_FKEY_PULLDN:
	DB	'PullDn',0
	
STR_DELETE_LABEL:
STR_FKEY_DELETE:
	DB	'Delete',0
	
STR_FKEY_COPY:
	DB	'Copy  ',0

STR_COPY_LABEL:
	DB	'Copy',0	
	
STR_FKEY_MKDIR:
	DB	'MkDir ',0

STR_FKEY_RENMOV:
	DB	'RenMov',0
	
STR_FKEY_VIEW:
	DB	'View  ',0

STR_FKEY_EDIT:
	DB	'Edit  ',0
	
STR_OK_BUTTON:
	DB	'[ ','O'+128,'k ]',0

STR_YES_BUTTON:
	DB	'[ ','Y'+128,'es ]',0

STR_CANCEL_BUTTON:
	DB	'[ ','C'+128,'ancel ]',0

STR_NO_BUTTON:
	DB	'[ ','N'+128,'o ]',0
	
STR_ABORT_BUTTON:
	DB	'[ ','A'+128,'bort ]',0

STR_RETRY_BUTTON:
	DB	'[ ','R'+128,'etry ]',0
	
STR_ALL_BUTTON:
	DB	'[ A','l'+128,'l ]',0
				
STR_DRV_LABEL:
	DB	' Change drive ',0

STR_ERROR_LABEL:
	DB	' System Message ',0

STR_INSERT_DISK_MSG:
	DB	'Insert disk on drive '
STR_INSERT_DISK_LETTER:
	DB	'A: and press Ok',0

STR_PATHNAME_TOO_LONG:
	DB	'Pathname too long',0
		
STR_DOS_ABORT_OPERATION:
	DB	'Do you really want to ABORT the process ? ',0
		
STR_CTRL_C:
	DB	' Keep pressed Ctrl-C to stop ',0
	
STR_DOS_ERROR_LABEL:
	DB	' Error accessing drive '
STR_DOS_ERROR_DRIVE:
	DB	'A: ',0
	
STR_COPY_MSG:
	DB ' Copy ',0

STR_MOVE_MSG:
	DB ' Move ',0

STR_DELETE_MSG:
	DB ' Delete ',0

STR_NUMBER_U8:
	DB '  0',0
STR_NUMBER_U16:
	DB '    0',0
STR_NUMBER_U32:
	DB '         0',0
	
STR_DELETE_FILES:
	DB ' selected file(s) ?',0
STR_QUESTION:
	DB ' ?',0	
STR_COPY_FILES:
	DB ' selected file(s) to:',0
STR_TO:
	DB	' to:',0

STR_MKDIR_MSG:
	DB	' Make Directory ',0

STR_FILTER_MSG:
	DB	' Filter View ',0

STR_VIEW_MSG:
	DB	' View File ',0

STR_RENAME_MSG:
	DB	' Rename File ',0
	
STR_READING:
	DB	'Reading ',0
	
STR_SAVING:
	DB	'Saving ',0

STR_DELETING:
	DB	'Deleting ',0
	
STR_MOVING:
	DB	'Moving ',0

STR_ATTRIBUTING:
	DB	'Attributing ',0
	
STR_DRV_A_BUTTON:
	DB	'[ ','A'+128,' ]',0
STR_DRV_B_BUTTON:
	DB	'[ ','B'+128,' ]',0
STR_DRV_C_BUTTON:
	DB	'[ ','C'+128,' ]',0
STR_DRV_D_BUTTON:
	DB	'[ ','D'+128,' ]',0
STR_DRV_E_BUTTON:
	DB	'[ ','E'+128,' ]',0
STR_DRV_F_BUTTON:
	DB	'[ ','F'+128,' ]',0
STR_DRV_G_BUTTON:
	DB	'[ ','G'+128,' ]',0
STR_DRV_H_BUTTON:
	DB	'[ ','H'+128,' ]',0
	
STR_FKEY1:
	DB	' 1',0
STR_FKEY2:
	DB	' 2',0
STR_FKEY3:
	DB	' 3',0
STR_FKEY4:
	DB	' 4',0
STR_FKEY5:
	DB	' 5',0
STR_FKEY6:
	DB	' 6',0
STR_FKEY7:
	DB	' 7',0
STR_FKEY8:
	DB	' 8',0
STR_FKEY9:
	DB	' 9',0
STR_FKEY10:
	DB	' 10',0
	
STR_USER_MENU_LABEL:
	DB	' User Menu ',0
	
STR_MC_LABEL:
	DB	' The MSX Commander ',0

STR_QUIT_MSG:
	DB	'Do you really want to quit the MSX Commander?',0

STR_PROMPT_MSG:
	DB	'DOS Command Prompt',$0a,$0d,'Type ',$27,'exit',$27,' to return to MSX Commander...',$0a,$0d,$0a,$0d,'$'
	
STR_THIS_DIR:
	DB	'.',0

STR_PREV_DIR:
	DB	'..',0

STR_MENU_SORT_ORDER:
	DB	' Sort view       Ctrl-s ',0
STR_MENU_FILTER:
	DB	' Filter...       Ctrl-f ',0
STR_MENU_DRIVE:
	DB	' Drive...        Ctrl-d ',0
STR_MENU_RESCAN:
	DB	' Rescan          Ctrl-r ',0
STR_MENU_INFO:
	DB	' Info...         Ctrl-i ',0
STR_MENU_LMSEPARATOR:
	DB	' ',$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,' ',0
STR_MENU_FMSEPARATOR:
	DB	' ',$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,' ',0
STR_MENU_USER_MENU:
	DB	' User Menu            F2 ',0
STR_MENU_VIEW:
	DB	' View                 F3 ',0
STR_MENU_EDIT:
	DB	' Edit                 F4 ',0
STR_MENU_COPY:
	DB	' Copy                 F5 ',0 
STR_MENU_ATTR: 
	DB	' Attributes       Ctrl-a ',0
STR_MENU_REN_MOV:
	DB	' Rename/Move          F6 ',0
STR_MENU_MKDIR:
	DB	' Mkdir                F7 ',0
STR_MENU_DELETE:
	DB	' Delete               F8 ',0
STR_MENU_SELECT_GRP:
	DB	' Select Group          + ',0
STR_MENU_UNSELECT_GRP:
	DB	' Unselect Group        - ',0
STR_MENU_REVERSE_SEL:
	DB	' Reverse Selection     * ',0
STR_MENU_EXIT:
	DB	' Exit                F10 ',0
STR_MENU_SWAP:
	DB	' Swap Panels     Ctrl-p ',0
STR_MENU_PROMPT:
	DB	' DOS Command Prompt     ',0	  

STR_MENU_CONFIGURATION:
	DB	' Configuration...       ',0
	
STR_VIEW_HEADER:
	DB	'    Name     ',$16,'   Size  ',$16,'  Timestamp  ',0
STR_VIEW_BODY:
	DB	'             ',$16,'         ',$16,'             ',0
STR_VIEW_FOOTER:
	DB	$17,$17,$17,$17,$17,' files ',$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,' bytes ',0 
STR_VIEW_SEP:
	DB	$14,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$17,$13,0
STR_SPACE:
	DB	' ',0
STR_BACKSLASH:
	DB	'\',0

STR_THE_FILE:
	DB	'The file ',0
	
STR_CONFIRM_RO:
	DB	'is READ ONLY. Proceed anyway ?',0

STR_CONFIRM_OVERWRITE:
	DB	'ALREADY exists. Overwrite anyway ?',0
	
STR_MEM_ERROR:
	DB '***Not enough memory to run this program$'
STR_SHELL:
	DB 'SHELL',0
STR_PRESS_ANY_KEY:
	DB	$0d,$0a,$0d,$0a,'Press any key to return to MSX Commander...$',0
STR_ENDLINE:
	DB	$0d,$0a,$0d,$0a,'$',0
	
STR_ERROR_COPY:
	DB	'Error copying ',0

STR_ERROR_DELETE:
	DB	'Error deleting ',0	
	
STR_ERROR_ATTRIBUTE:
	DB	'Error attributing ',0	

STR_ERROR_VIEWING:
	DB	'Error viewing ',0	
	
STR_ERROR_MOVE:
	DB	'Error moving ',0
	
STR_ERROR_COPY_ITSELF:
	DB	'Error file cannot be copied over itself',0	

STR_ERROR_MOVE_ITSELF:
	DB	'Error file cannot be moved over itself',0	

STR_ERROR_PARSING:
	DB	'Error parsing MC.MNU file',0	

STR_NO_EDITOR:
	DB	'Error default EDIT not set in MC.MNU file',0	
	
STR_ERROR_MKDIR:
	DB	'Error creating ',0	

STR_ERROR_RENAME:
	DB	'Error renaming ',0	

STR_SORTING_MSG:
	DB	'S O R T I N G . . .',0
	
	
STR_ATTRIB_LABEL:
	DB	' File Attributes ',0

;STR_ATTRIB_MSG:
;	DB	'Set file attributes for',0
	
STR_RO_ATTRIB:
	DB	'[ ] ','R'+128,'ead only',0
	
STR_ARCHIVE_ATTRIB:
	DB	'[ ] ','A'+128,'rchive',0
	
STR_HIDDEN_ATTRIB:
	DB	'[ ] ','H'+128,'idden',0
	
STR_SYSTEM_ATTRIB:
	DB	'[ ] ','S'+128,'ystem',0
	
STR_ENV_SDRV:
	DB	'SDRV',0
STR_ENV_TDRV:
	DB	'TDRV',0
STR_ENV_SPTH:
	DB	'SPTH',0
STR_ENV_TPTH:
	DB	'TPTH',0
STR_ENV_SFIL:
	DB	'SFIL',0
STR_ENV_TFIL:
	DB	'TFIL',0

STR_FILE:
	DB	'File: ',0
	
STR_INFO_LABEL:
	DB	' Drive Information ',0
STR_INFO_DRIVE:
	DB	'Drive letter...........: A',0
STR_INFO_VOLUME:
	DB	'Volume name............: 123456789ABCD',0
STR_INFO_FILESYSTEM:
	DB	'Filesystem.............: FAT1    ',0
STR_INFO_BYTES_SEC:
	DB	'Bytes per sector.......: 65535',0
STR_INFO_SECS_CLUSTER:
	DB	'Sectors per cluster....: 65535',0
STR_INFO_CLUSTER_SIZE:
	DB	'Cluster size...........: 65535',0
STR_INFO_SIZE:
	DB	'Total size.............: 4294967295',0
STR_INFO_USED:
	DB	'Used size..............: 4294967295',0
STR_INFO_FREE:
	DB	'Free size..............: 4294967295',0
STR_ERROR_INFO:
	DB 	'Error getting info from drive ',0