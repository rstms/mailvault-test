@ECHO OFF
set CONTAINER=rstms/mailvault:latest
set VOLUME=-v mailvault:/mailvault
set DOCKER_RUN=docker run --rm -i %VOLUME% %CONTAINER%
GOTO :%1 
IF %ERRORLEVEL% neq 0 goto :error
:error
echo Unknown command: %1
:help
echo. 
echo Usage:  %~n0 COMMAND
echo.
echo   Where COMMAND is: 
echo     ls                 list files in mailvault volume
echo     cat FILE           print volume file to stdout
echo     rm FILE            remove file from volume
echo     get FILE           copy file from volume to local
echo     put FILE           copy file from local to volume
echo     encrypt FILE KEY   encrypt volume file with volume key file
echo     decrypt FILE KEY   decrypt volume file with volume key file
echo     key                output random key string
echo.
goto :eof

:key
%DOCKER_RUN% sh -c "dd if=/dev/random bs=32 count=1 2>/dev/null | base64"
goto :eof

:ls
%DOCKER_RUN% ls -alh /mailvault
goto :eof

:cat
%DOCKER_RUN% cat /mailvault/%2
goto :eof

:rm
%DOCKER_RUN% rm /mailvault/%2
goto :eof

:get
docker create %VOLUME% --name mailvault-helper %CONTAINER% >NUL
docker cp mailvault-helper:/mailvault/%2 %2
docker rm mailvault-helper >NUL
goto :eof

:put
docker create %VOLUME% --name mailvault-helper %CONTAINER% >NUL
docker cp %2 mailvault-helper:/mailvault/%2
docker rm mailvault-helper >NUL
%DOCKER_RUN% chmod 0600 /mailvault/%2
goto :eof

:encrypt
:decrypt
%DOCKER_RUN% ansible-vault %1 --vault-password-file /mailvault/%3 /mailvault/%2
goto :eof
