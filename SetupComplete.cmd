
SET RootFolder=C:\VmwareTools
SET x86Install=VMware-tools-10.2.5-8068406-i386.exe
SET x64Install=VMware-tools-10.2.5-8068406-x86_64.exe

:CheckOS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
%RootFolder%\%x64Install% /S /v "/qn REBOOT=R ADDLOCAL=ALL REMOVE=Hgfs"
GOTO END

:32BIT
%RootFolder%\%x86Install% /S /v "/qn REBOOT=R ADDLOCAL=ALL REMOVE=Hgfs"
GOTO END

:END
CD\
RD /S /Q %RootFolder%