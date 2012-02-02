@ECHO OFF
:BEGIN
CLS
@ECHO WAIT 180 sec
ping 127.0.0.1 -n 180 >nul
@ECHO UN POUR LES GOUVERNER TOUS :)
CALL C:\Ruby192\bin\setrbvars.bat
START "Rails Console Production" "C:\web applications\projectone\doc\console_prod.bat"
START "Rails Server Production" "C:\web applications\projectone\doc\serveur_prod.bat"
START "Rails Jobs Production" "C:\web applications\projectone\doc\jobs_prod.bat"
@ECHO ET DANS LES TENEBRES LES EXECUTER
:END