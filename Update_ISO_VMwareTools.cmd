ECHO off

REM CHECK FOR ELEVATED CMD
net.exe session 1>NUL 2>NUL || goto :NOT_ADMIN
echo ELEVATED CMD OK!
goto ASSIGN_VARS

:NOT_ADMIN
echo ERROR: Please run as a local administrator (elevated)
exit /b 1

:ASSIGN_VARS
SET ROOTPATH=C:\DISM

SET BOOTWIM=%ROOTPATH%\Expanded\sources\boot.wim
SET INSTALLWIM=%ROOTPATH%\Expanded\sources\install.wim
SET MOUNTDIRLOCATION=%ROOTPATH%\Mount
SET W8DRIVERS=%ROOTPATH%\Drivers\pvscsi-Windows8
SET W7DRIVERS=%ROOTPATH%\Drivers\pvscsi-Windows2008
SET VMWARETOOLS=%ROOTPATH%\VMwareTools
SET WINDOWSSCRIPTDESTINATION=%MOUNTDIRLOCATION%\Windows\Setup\Scripts
SET WINDOWSSCRIPTSOURCE=%ROOTPATH%\Setup\Scripts

:CHECKARGUMENTS

IF "%1"=="HELP" GOTO HELP_INFO
IF "%1"=="help" GOTO HELP_INFO
IF "%1"=="Help" GOTO HELP_INFO

IF [%1]==[/?] GOTO BLANK
IF [%2]==[/?] GOTO BLANKIMAGE
IF [%2]==[/?] GOTO BLANKDRIVERS

IF "%2"=="BOOT" GOTO SETBOOTIMAGE
IF "%2"=="INSTALL" GOTO SETINSTALLIMAGE

REM START SETTING VARIABLES

:SETBOOTIMAGE
SET EDITIMAGE=%BOOTWIM%
GOTO SET_DRIVERS

:SETINSTALLIMAGE
SET EDITIMAGE=%INSTALLWIM%
GOTO SET_DRIVERS

:SET_DRIVERS
IF "%3"=="W8" GOTO SETW8DRIVER
IF "%3"=="W7" GOTO SETW7DRIVER

:SETW7DRIVER
SET WDRIVER=%W7DRIVERS%
GOTO MAIN

:SETW8DRIVER
SET WDRIVER=%W8DRIVERS%
GOTO MAIN

:MAIN
IF NOT EXIST %EDITIMAGE% (
	GOTO NOWIMFILE
)


:MOUNTIMAGE
dism.exe /Mount-WIM /WimFile:"%EDITIMAGE%" /index:%1 /MountDir:"%MOUNTDIRLOCATION%"
IF %ERRORLEVEL% NEQ 0 (
	GOTO ERRORMOUNTING
)


:CHECKINDEX
dism /get-imageinfo /imagefile:"%EDITIMAGE%" /index:%1 > nul
IF %ERRORLEVEL% NEQ 0 (
	GOTO NOINDEX
)


:ADDDRIVERS
DISM.exe /image:"%MOUNTDIRLOCATION%" /Add-Driver /driver:"%WDRIVER%" /recurse
IF %ERRORLEVEL% NEQ 0 (
	GOTO ERRORMOUNTING
)


:ADDVMWARETOOLS
IF NOT EXIST %EDITIMAGE% (
	GOTO NOVMWARETOOLS
)
Robocopy %VMWARETOOLS% %MOUNTDIRLOCATION%\VMwareTools /E /R:1 /W:1
rem IF %ERRORLEVEL% NEQ 0 (
rem 	GOTO ERRORADDINGVMWARETOOLS
rem )

:ADDSCRIPT
IF NOT EXIST %WINDOWSSCRIPTSOURCE% (
	GOTO NOWINDOWSSCRIPT
)
Robocopy %WINDOWSSCRIPTSOURCE% %WINDOWSSCRIPTDESTINATION% /E /R:1 /W:1
rem IF %ERRORLEVEL% NEQ 0 (
rem 	GOTO ERRORADDINGSCRIPT
rem )


:COMMIT_IMAGE
dism.exe /Unmount-wim /mountdir:"%MOUNTDIRLOCATION%" /commit
IF %ERRORLEVEL% NEQ 0 (
	GOTO ERRORCOMMITIMAGE
)

GOTO DONE

:NOINDEX
ECHO INDEX %1 NOT FOUND
GOTO DONE


:BLANK
ECHO NO INDEX SUPPLIED, FAILING
GOTO DONE

:BLANKIMAGE
ECHO NO IMAGE SUPPLIED, FAILING
GOTO DONE

:BLANKDRIVERS
ECHO NO DRIVERS SPECIFIED, FAILING
GOTO DONE

:NOWIMFILE
ECHO MISSING WIMFILE
GOTO DONE

:NOVMWARETOOLS
ECHO MISSING VMWARETOOLS SOURCE
GOTO DONE

:NOWINDOWSSCRIPT
ECHO MISSING WINDOWS SCRIPT SOURCE
GOTO DONE

:ERRORMOUNTING
ECHO ERROR MOUNTING IMAGE
GOTO DONE

:ERRORADDINGVMWARETOOLS
ECHO ERROR ADDING VMWARETOOLS
GOTO DONE

:ERRORADDINGSCRIPT
ECHO ERROR ADDING WINDOWS SCRIPT
GOTO DONE

:ERRORCOMMITIMAGE
ECHO ERROR SAVING AND UNMOUNTING IMAGE
GOTO DONE

:ERRORADDINGDRIVERS
ECHO ERROR ADDING DRIVERS
GOTO DONE

:HELP_INFO
ECHO Program takes 3 arguments:
ECHO 1. Image Index (number)
ECHO 2. BOOT or INSTALL image
ECHO 3. W8 or W7 drivers
ECHO 
ECHO Example: Update_ISO_VMwareTools.cmd 6 INSTALL W8
GOTO DONE

:DONE
ECHO Done!