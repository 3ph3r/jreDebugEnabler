@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

goto start

:end
exit /b

:start
set fileCount=0
for /f %%a in ('dir /b "JDK_DIR\jdk-*-windows-i586.exe"') do set /a fileCount+=1

if not %fileCount% == 1 (
  echo JDK installer not found in JDK_DIR folder
  goto end
)

for /f %%a in ('dir /b "JDK_DIR\jdk-*-windows-i586.exe"') do set fileName=%%a

echo JDK installer found: %fileName%
set jreName=%fileName:jdk-=jre%
set jreName=%jreName:-windows-i586.exe=_x86%

echo Preparing folders
rmdir tmp /Q /S
rmdir RESULT /Q /S
mkdir tmp
mkdir RESULT

echo Extracting installer
ResourcesExtract /ExtractBinary 1 /OpenDestFolder 0 /Source JDK_DIR\%fileName% /DestFolder tmp

echo Moving and deleting installer files
for /f %%a in ('dir /b "tmp\*CAB9.bin"') do mv tmp\%%a tmp\_src.zip
for /f %%a in ('dir /b "tmp\*CAB10.bin"') do mv tmp\%%a tmp\_tools.zip
for /f %%a in ('dir /b "tmp\jdk*"') do del tmp\%%a

echo Extracting _src.zip
7z e tmp\_src.zip -otmp >NUL:
del tmp\_src.zip

echo Extracting _tools.zip
7z e tmp\_tools.zip -otmp >NUL:
del tmp\_tools.zip

echo Extracting src folder
7z x tmp\src.zip -otmp\src >NUL:
rmdir tmp\src\com\sun\java\swing\plaf /Q /S

echo Listing files
find tmp\src\ -name *.java > tmp\srcFiles.txt

echo Extracting JDK
7z x tmp\tools.zip -otmp\tools >NUL:
del tmp\tools.zip

echo Extracting tools.jar
tmp\tools\bin\unpack200 -r tmp\tools\lib\tools.pack "tmp\tools\lib\tools.jar"

echo Extracting JRE
for /f %%a in ('dir /b "tmp\tools\jre\lib\*.pack"') do tmp\tools\bin\unpack200 -r tmp\tools\jre\lib\%%a "tmp\tools\jre\lib\%%~na.jar"
for /f %%a in ('dir /b "tmp\tools\jre\lib\ext\*.pack"') do tmp\tools\bin\unpack200 -r tmp\tools\jre\lib\ext\%%a "tmp\tools\jre\lib\ext\%%~na.jar"

echo Compiling rt.jar
mkdir tmp\builtFromSource
tmp\tools\bin\javac -g -d tmp\builtFromSource -J-Xmx512m -cp tmp\tools\jre\lib\rt.jar;tmp\tools\lib\tools.jar @tmp\srcFiles.txt 2>NUL:

echo Extracting rt.jar
7z x tmp\tools\jre\lib\rt.jar -otmp\tools\jre\lib\_rt >NUL:

echo Moving rt.jar classes
for /r tmp\builtFromSource %%a in (*.class) do (
  SET buildPath=%%a
  SET rtPath=!buildPath:builtFromSource=tools\jre\lib\_rt!
  
  if exist "!rtPath!" copy /y "!buildPath!" "!rtPath!" >NUL:
)

echo Creating rt.jar
cd tmp\tools\jre\lib\_rt
7z a -mx0 -tzip rt.jar >NUL:
cd ..\..\..\..\..\

echo Moving rt.jar
copy /y tmp\tools\jre\lib\_rt\rt.jar tmp\tools\jre\lib\rt.jar >NUL:

echo Deleting compiled classes
rmdir tmp\tools\jre\lib\_rt /Q /S

echo Finalizing
mkdir RESULT\%jreName%
move tmp\tools\jre RESULT\%jreName%\ >NUL:
move tmp\src.zip RESULT\%jreName%\ >NUL:

echo Cleaning up tmp folder
rmdir tmp /Q /S
mkdir tmp

echo.
echo Success^^!