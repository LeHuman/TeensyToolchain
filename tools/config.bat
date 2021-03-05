@echo off

set DEBUG=0
set NOEMOJI=0
set NOCOLOR=0

for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if not "%version%" == "10.0" (
    echo Warning, only tested on Windows 10
    echo Disabling text formatting
    echo.
    set NOEMOJI=1
    set NOCOLOR=1
)

if "%NOCOLOR%"=="1" goto :SET_NOCOLOR
chcp 65001 >NUL
set ASCII27=
set A_RESET=%ASCII27%[0m
set A_BOLD=%ASCII27%[1m
set A_UNDER=%ASCII27%[4m
set A_BLACK=%ASCII27%[30m
set A_RED=%ASCII27%[31m
set A_GREEN=%ASCII27%[32m
set A_YELLOW=%ASCII27%[33m
set A_BLUE=%ASCII27%[34m
set A_MAGENTA=%ASCII27%[35m
set A_CYAN=%ASCII27%[36m
set A_WHITE=%ASCII27%[37m
goto :END_SET_NOCOLOR

:SET_NOCOLOR
set A_RESET=
set A_BOLD=
set A_UNDER=
set A_BLACK=
set A_RED=
set A_GREEN=
set A_YELLOW=
set A_BLUE=
set A_MAGENTA=
set A_CYAN=
set A_WHITE=
:END_SET_NOCOLOR

if "%NOEMOJI%"=="1" goto :SET_NOEMOJI
chcp 65001 >NUL
set E_CHECK=✔︝
set E_EHCKS=❌
set E_EHCK2=✖
set E_FINIS=🝕
set E_PREBL=🧰
set E_SPEED=🝎︝
set E_STOPD=⛔
set E_UPLOD=🔌
set E_UPRUN=⚡
set E_WAITN=❳
set E_CLEAN=🧹
set E_CLNDB=🧼🧽
set E_GEARN=⚙︝
goto :END_SET_NOEMOJI

:SET_NOEMOJI
set E_CHECK=
set E_EHCKS=
set E_EHCK2=
set E_FINIS=
set E_PREBL=
set E_SPEED=
set E_STOPD=
set E_UPLOD=
set E_UPRUN=
set E_WAITN=
set E_CLEAN=
set E_CLNDB=
set E_GEARN=
:END_SET_NOEMOJI

set call_path="%CD%"
set tool_path="%~dp0%"
set tool_path=%tool_path:"=%
set only_config=0
set new_build_dir=0
set skip_prebuild=0

set option="%1"
set COM_PORT="%2"
set COM_ARG=%COM_PORT:"=%

if "%DEBUG%"=="1" (
    echo option %option%
    echo COM_PORT %COM_PORT%
    echo COM_ARG %COM_ARG%
    echo call_path %call_path%
    echo tool_path %tool_path%
)

if %option%=="" (
    goto :HELP_STR
) 

if [%2]==[] goto :SKIP_PRE_CHECK

if %COM_ARG%==-s (
    set skip_prebuild=1
)
:SKIP_PRE_CHECK

if not exist build (
    mkdir build
    set new_build_dir=1
)

if not exist build/build.ninja (
    set no_ninja_script=1
)

shift
set CMAKE_PARAMS=%1

:CMAKE_LOOP
shift
if [%1]==[] goto :CMAKE_AFTERLOOP
set CMAKE_PARAMS=%CMAKE_PARAMS% %1
goto :CMAKE_LOOP
:CMAKE_AFTERLOOP
set CMAKE_PARAMS=%CMAKE_PARAMS:\"=%

if "%DEBUG%"=="1" (
    echo %CMAKE_PARAMS%
)

if %option%=="build" (
    echo %A_BOLD%%A_UNDER%Build Project%A_RESET%
    echo.
    goto :BUILD
)
if %option%=="upload" (
    echo %A_BOLD%%A_UNDER%Upload Binary%A_RESET% %E_UPRUN%
    echo.
    goto :UPLOAD
)
if %option%=="config" (
    echo %A_BOLD%%A_UNDER%Configure Project%A_RESET%
    echo.
    set only_config=1
    goto :END_CLEAN
)
if %option%=="clean" (
    if "%no_ninja_script%"=="1" (
        echo %A_BOLD%%A_RED%Project is invalid%A_RESET% %E_STOPD%
        echo Consider running config or hard_clean
        start /wait exit /b 1
        goto :END_SCRIPT
    )
    cd build
    echo %A_BOLD%%A_UNDER%Cleaning%A_RESET% %E_CLEAN%
    "%tool_path%ninja.exe" clean
    if errorlevel 1 echo %A_BOLD%%A_RED%Error cleaning up build files%A_RESET% %E_STOPD%
    goto :END_SCRIPT
)
if %option%=="hard_clean" (
    if "%new_build_dir%"=="1" (
        set only_config=1
        goto :END_CLEAN
    )
    echo %A_BOLD%%A_UNDER%Hard Cleaning%A_RESET% %E_CLNDB%
    set only_config=1
    goto :BUILD_CLEAN
)

if "%DEBUG%"=="1" (
    echo No valid option found
)

:HELP_STR

echo.
echo %A_UNDER%%A_BOLD%Valid options%A_RESET%
echo.
echo    %A_BOLD%build%A_RESET%              : Build project, configuring if necessary
echo    %A_BOLD%upload%A_RESET% [%A_YELLOW%com_port%A_RESET%]  : Upload binary file to a connected teensy
echo    %A_BOLD%clean%A_RESET%              : Cleanup build files
echo    %A_BOLD%hard_clean%A_RESET%         : Refresh project to a clean state, can pass
echo                         extra variables to auto config cmake
echo    %A_BOLD%config%A_RESET%             : Reconfigure cmake project, can pass any
echo                         extra variables for cmake
echo %A_UNDER%%A_BOLD%Valid flags%A_RESET%
echo.
echo    %A_BOLD%-s%A_RESET%                 : Skip any %A_MAGENTA%`Pre_Build`%A_RESET% script that exists
echo.
echo %A_UNDER%%A_BOLD%Prebuild Script%A_RESET%
echo.
echo If a script is named %A_MAGENTA%`Pre_Build`%A_RESET% and is at the root of a project
echo it will be run before configuring CMake
echo It can be a %A_CYAN%`.bat`%A_RESET%, %A_CYAN%`.ps1`%A_RESET%, or %A_CYAN%`.py`%A_RESET%
echo Only one is run, prefering the file type is that order

exit /b 0

:BUILD

if "%no_ninja_script%"=="1" goto :BUILD_CLEAN
if "%new_build_dir%"=="1" goto :END_CLEAN


goto :FINISH_CLEAN_SECTION
:BUILD_CLEAN
rmdir /Q /S build
timeout /t 1 /nobreak >NUL
mkdir build
timeout /t 1 /nobreak >NUL
:END_CLEAN

if "%skip_prebuild%"=="1" (
    echo %A_YELLOW%Skipping Pre_Build script%A_RESET%
    goto :__NO_PREBUILD
)

if exist Pre_Build.bat (
    echo %A_CYAN%%A_BOLD%Running Pre-Build Batch Script%A_RESET% %E_PREBL%
    echo.
    Start Pre_Build.bat
    goto :__END_PREBUILD
)
if exist Pre_Build.ps1 ( 
    echo %A_CYAN%%A_BOLD%Running Pre-Build PowerShell Script%A_RESET% %E_PREBL%
    echo.
    powershell.exe .\Pre_Build.ps1
    goto :__END_PREBUILD
)
if exist Pre_Build.py ( 
    echo %A_CYAN%%A_BOLD%Running Pre-Build Python Script%A_RESET% %E_PREBL%
    echo.
    Python.exe Pre_Build.py
    goto :__END_PREBUILD
)
goto :__NO_PREBUILD
:__END_PREBUILD
if errorlevel 1 (
    echo %A_BOLD%%A_RED%Pre_Build script failed%A_RESET% %E_STOPD%
    goto :END_SCRIPT
)
:__NO_PREBUILD

cd build
echo.
echo %A_BOLD%Configuring CMake project%A_RESET% %E_GEARN%

if "%DEBUG%"=="1" (
    echo %CMAKE_PARAMS%
)

cmake .. -G Ninja %CMAKE_PARAMS%
if errorlevel 1 (
    echo %A_BOLD%%A_RED%Failed to configure cmake%A_RESET% %E_STOPD%
    goto :END_SCRIPT
)
if "%only_config%"=="1" goto :END_SCRIPT
cd ".."
:FINISH_CLEAN_SECTION

if "%skip_prebuild%"=="1" (
    echo %A_YELLOW%Skipping Pre_Build script%A_RESET%
    goto :NO_PREBUILD
)

if exist Pre_Build.bat (
    echo %A_CYAN%%A_BOLD%Running Pre-Build Batch Script%A_RESET% %E_PREBL%
    echo.
    Start Pre_Build.bat
    goto :END_PREBUILD
)
if exist Pre_Build.ps1 ( 
    echo %A_CYAN%%A_BOLD%Running Pre-Build PowerShell Script%A_RESET% %E_PREBL%
    echo.
    powershell.exe .\Pre_Build.ps1
    goto :END_PREBUILD
)
if exist Pre_Build.py ( 
    echo %A_CYAN%%A_BOLD%Running Pre-Build Python Script%A_RESET% %E_PREBL%
    echo.
    Python.exe Pre_Build.py
    goto :END_PREBUILD
)
goto :NO_PREBUILD
:END_PREBUILD
if errorlevel 1 (
    echo %A_BOLD%%A_RED%Pre_Build script failed%A_RESET% %E_STOPD%
    goto :END_SCRIPT
)
:NO_PREBUILD

cd build
echo.
echo %A_CYAN%%A_BOLD%Building%A_RESET% %E_WAITN%

"%tool_path%ninja.exe" -j16
if errorlevel 1 (
    echo %A_BOLD%%A_RED%Ninja failed to build%A_RESET% %E_STOPD%
    goto :END_SCRIPT
)
echo.
echo %A_BOLD%%A_GREEN%Build Finished%A_RESET% %E_FINIS%
cd ".."
for /f "tokens=2 delims==" %%a in ('type build\CMakeCache.txt^|find "FINAL_OUTPUT_FILE:INTERNAL="') do (
    set FINAL_OUTPUT_FILE=%%a & goto :CONTINUEB
)
:CONTINUEB

if not exist "%FINAL_OUTPUT_FILE%" (
    goto :BINARY_DOES_NOT_EXIST
) else (
    echo.
    echo %A_BOLD%%A_BLUE%Ready to Upload%A_RESET% %E_UPLOD%
)
goto :END_SCRIPT

:UPLOAD

if not exist build\CMakeCache.txt (
    echo %A_BOLD%%A_RED%CMake has not been configured%A_RESET% %E_STOPD%
    start /wait exit /b 1
    goto :END_SCRIPT
)

for /f "tokens=2 delims==" %%a in ('type build\CMakeCache.txt^|find "TEENSY_CORE_NAME:INTERNAL="') do (
    set TEENSY_CORE_NAME=%%a & goto :CONTINUE0
)
:CONTINUE0
for /f "tokens=2 delims==" %%a in ('type build\CMakeCache.txt^|find "FINAL_OUTPUT_FILE:INTERNAL="') do (
    set FINAL_OUTPUT_FILE=%%a & goto :CONTINUE1
)
:CONTINUE1

if not exist "%FINAL_OUTPUT_FILE%" (
:BINARY_DOES_NOT_EXIST
    echo %A_BOLD%%A_RED%Final binary file was not found%A_RESET% %E_STOPD%
    start /wait exit /b 1
    goto :END_SCRIPT
)

if "%COM_PORT%"=="" (
    echo %A_YELLOW%Warning! no port defined, unable to auto reboot%A_RESET%
    set no_auto_reboot=1
)

if "%no_auto_reboot%"=="" ( 
    "%tool_path%ComMonitor.exe" %COM_PORT% 134 -c --priority
    timeout /t 1 > NUL
)

"%tool_path%teensy_loader_cli.exe" -mmcu=%TEENSY_CORE_NAME% -v %FINAL_OUTPUT_FILE%

if errorlevel 1 (
    echo %A_RED%Failed to upload once %E_EHCK2%%A_RESET%
    "%tool_path%teensy_loader_cli.exe" -mmcu=%TEENSY_CORE_NAME% -v %FINAL_OUTPUT_FILE%
    if errorlevel 1 (
        echo %A_BOLD%%A_RED%Failed to upload%A_RESET% %E_STOPD%
        if "%DEBUG%"=="1" (
            echo COM Name %COM_ARG%
            mode %COM_ARG%
        )
        mode %COM_ARG% | find "Illegal device name" > nul && start /wait exit /b 1 || goto :END_SCRIPT
        echo %A_YELLOW%%A_UNDER%Is the teensy connected?%A_RESET%
        goto :END_SCRIPT
    )
)

echo %A_GREEN%Good to go %E_CHECK%%A_RESET%
goto :END_SCRIPT

:END_SCRIPT
if errorlevel 1 (
    echo.
    echo %A_BOLD%%A_RED%Task Failed%A_RESET% %E_EHCKS%
    echo.
    cd %call_path%
    exit /b 1
) else (
    echo.
    echo %A_BOLD%%A_GREEN%Task Succeeded%A_RESET% %E_CHECK%
    cd %call_path%
    exit /b 0
)
