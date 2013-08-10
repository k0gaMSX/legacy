/* Full-screen DIVE support uninstaller */

call RxFuncAdd 'SysIni', 'RexxUtil', 'SysIni'
call RxFuncAdd 'SysFileDelete', 'RexxUtil', 'SysFileDelete'

  GameSrvr=SysIni('USER','PM_ED_HOOKS','GAMESRVR')
  if GameSrvr='ERROR:' then do
    say 'ERROR: Full-screen DIVE support not installed'
    exit
  end

  '@unlock 'GameSrvr' 1>nul'
  call SysFileDelete GameSrvr

  if SysIni('USER','PM_ED_HOOKS','DELETE:')='ERROR:' then do
    say 'ERROR: cannot deleting from INI file'
    exit
  end

  os2dir=GetBootDrive()'\OS2\'

  if stream(os2dir'SvgaData.PBk','c','query exist')='' then do
    say 'Unable to restore video configuration'
    say 'Resetting to VGA...'
    '@call 'os2dir'SetVga.Cmd'
  end
  else do
    say 'Restoring video configuration...'
    '@copy 'os2dir'SvgaData.PBk 'os2dir'*.pmi >nul'
    '@copy 'os2dir'Svga.EBk 'os2dir'*.exe 1>nul 2>&1'
  end

  say 'Full-screen DIVE support uninstalled'

exit

GetBootDrive: procedure
   call SysIni 'BOTH','FolderWorkareaRunningObjects','ALL:','Objects'
return left(Objects.1,2)
