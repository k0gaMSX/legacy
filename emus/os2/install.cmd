/*
 * fMSX/2 installation program (C) 1996 by Alexander Perezhogin
 */

fMSXversion = '1.5 alpha'

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

  call SysCls
  say 'fMSX/2 'fMSXversion' installation program'; say

  if arg()>0 then signal Usage

  bootdrive=GetBootDrive()
  curdir=directory()
  restart=0;

  if \exist('Ssmdd.Sys') then signal InstallWPS
  if \exist('Dive.Dll') then signal InstallWPS

  say 'Installing DIVE...'

  call ReplaceDevice 'Ssmdd.Sys'
  call ReplaceDLL 'Dive.Dll'

  say 'DIVE successfully installed/updated'; say

  if \exist('GSrvInst.Exe') then signal InstallWPS
  if \exist('Svga.Exe') then signal InstallWPS
  if \exist('GameSrvr.Dll') then signal InstallWPS

  if AskYesNo('Install Full-screen DIVE support') then do
    say
    say '    WARNING!!! Install Full-screen DIVE support may cause lockup'
    say 'after shutdown with some video drivers (for example S3 v2.84.13). In'
    say 'this case, go to command line using Recovery Choices, and run'
    say 'UnFSDive.Cmd to remove Full-screen support.'
    say
    if AskYesNo('Continue') then do
      '@GSrvInst.Exe'
      restart=1;
    end
  end
  say
  call SysFileDelete 'GSrvInst.Exe'
  call SysFileDelete 'Svga.Exe'
  call SysFileDelete 'GameSrvr.Dll'

InstallWPS:
  if AskYesNo('Create Workplace Shell object') then do
     if SysCreateObject('WPProgram','fMSX/2 1.5 alpha','<WP_DESKTOP>',,
                        'OBJECTID=<fMSX/2>;EXENAME='curdir'\fMSX.Exe;STARTUPDIR='curdir,'r')=0 then do
       say 'ERROR: cannot create WPS object'
       exit
     end
    say 'Workplace Shell object created.'
  end

  if restart then do
    say; say 'You need to shutdown and reboot so changes make effect.'
  end

  say; say 'ENJOY THE EMULATOR AND LET US KEEP MSX ALIVE :)'
exit

AskYesNo: procedure
parse arg query
  call charout ,query
  call charout ,'? (Yes/No) '
  do forever
    c=translate(SysGetKey('NOECHO'))
    select
      when c='Y' then
        do; say 'Yes'; return 1; end
      when c='N' then
        do; say 'No'; return 0; end
      otherwise
        nop
    end
  end
return

GetBootDrive: procedure
   call SysIni 'BOTH','FolderWorkareaRunningObjects','ALL:','Objects'
return left(Objects.1,2)

ReplaceDLL: procedure expose bootdrive restart
parse arg DLLname
  if ReplaceSysFile('\MMOS2\DLL\','\OS2\DLL\',DLLname)\='' then restart=1
  call SysFileDelete DLLname
return

ReplaceDevice: procedure expose bootdrive restart
parse upper arg DevName
  config=bootdrive'\CONFIG.SYS'
  call stream config,'c','open read'
  if result\= 'READY:' then do
    say 'ERROR: cannot open CONFIG.SYS'
    exit
  end
  DevPath=''
  do while stream(config,'s')='READY'
    line=translate(linein(config))
    if compare('DEVICE=',line)<8 then iterate
    device=substr(line,8)
    if filespec('n',device)\=DevName then iterate
    DevPath=filespec('p',device)
    leave
  end
  call stream config,'c','close'
  if DevPath\='' then do
    if ReplaceSysFile(DevPath,,DevName)\='' then restart=1
  end
  else do
    say DevPath
    call ReplaceSysFile '\OS2\BOOT\',,DevName
    if \restart then do
      '@copy 'config' 'bootdrive'\*.OLD >nul'
      say 'CONFIG.SYS changed. Original saved as CONFIG.OLD'
    end
    call stream config,'c','open write'
    call stream config,'c','seek <0'
    if \restart then
      call lineout config,'REM --- Added by fMSX/2 Install'
    call lineout config,'DEVICE=D:\OS2\BOOT\'DevName
    restart=1
  end
  call SysFileDelete DevName
return

ReplaceSysFile: procedure expose bootdrive
parse arg dir1,dir2,name
  if filespec('d',dir1)='' then dir1=bootdrive||dir1
  if dir2='' then dir2=dir1
  if filespec('d',dir2)='' then dir2=bootdrive||dir2
  do 1
    to=dir1
    if \exist(to||name) then do
      to=dir2
      if \exist(to||name) then leave
    end
  end
  if datetime(to||name)>=datetime(name) then
    if \AskYesNo(to||name' is same or newer. Overwrite') then return ''
  '@unlock 'to||name' >nul'
  '@copy 'name' 'to' >nul'
  return to||name
return

exist: procedure
parse arg name
return stream(name,'c','query exist')\=''

datetime: procedure
parse arg name
  parse value stream(name,'c','query datetime') with mm'-'dd'-'yy'  'hh':'mn':'ss
return yy||mm||dd||hh||mm||ss

Usage:
  say 'Usage:'
  say '   Install'
  exit
