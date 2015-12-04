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

set version=%jreName:~3,1%
if %version% == 8 (set compileFX=1) else (set compileFX=0)

echo Preparing folders
IF EXIST tmp rmdir tmp /Q /S
IF EXIST RESULT rmdir RESULT /Q /S
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
dir /s /B tmp\src\*.java > tmp\srcFiles.txt

echo Extracting JDK
7z x tmp\tools.zip -otmp\tools >NUL:
del tmp\tools.zip

if %compileFX%==1 (
  echo Extracting javafx-src folder
  mv tmp\tools\javafx-src.zip tmp\javafx-src.zip
  7z x tmp\javafx-src.zip -otmp\javafx-src >NUL:
  rmdir tmp\javafx-src\com\sun\glass /Q /S
  rmdir tmp\javafx-src\com\sun\prism /Q /S
  rmdir tmp\javafx-src\javafx\embed\swt /Q /S
  rm tmp\javafx-src\javafx\scene\chart\AreaChartBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\chart\BarChartBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\chart\BubbleChartBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\chart\LineChartBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\chart\ScatterChartBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\chart\StackedAreaChartBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\chart\StackedBarChartBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\control\TableCellBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\control\cell\CheckBoxTableCellBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\control\cell\ChoiceBoxTableCellBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\control\cell\ComboBoxTableCellBuilder.java 2>NUL:
  rm tmp\javafx-src\javafx\scene\control\cell\TextFieldTableCellBuilder.java 2>NUL:

  echo Listing files
  dir /s /B tmp\javafx-src\*.java > tmp\srcFilesFX.txt
)

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

if %compileFX%==1 (
  echo Compiling jfxrt.jar
  mkdir tmp\builtFromSourceFX
  tmp\tools\bin\javac -g -d tmp\builtFromSourceFX -J-Xmx512m -cp tmp\tools\jre\lib\rt.jar;tmp\tools\lib\tools.jar;tmp\tools\lib\ext\jfxrt.jar;jre8deps.jar @tmp\srcFilesFX.txt 2>NUL:

  echo Extracting jfxrt.jar
  7z x tmp\tools\jre\lib\ext\jfxrt.jar -otmp\tools\jre\lib\ext\_jfxrt >NUL:

  echo Moving jfxrt.jar classes
  for /r tmp\builtFromSourceFX %%a in (*.class) do (
    SET buildPathFX=%%a
    SET jfxrtPath=!buildPathFX:builtFromSourceFX=tools\jre\lib\ext\_jfxrt!
    
    if exist "!jfxrtPath!" copy /y "!buildPathFX!" "!jfxrtPath!" >NUL:
  )

  echo Creating jfxrt.jar
  cd tmp\tools\jre\lib\ext\_jfxrt
  7z a -mx0 -tzip jfxrt.jar >NUL:
  cd ..\..\..\..\..\..\

  echo Moving jfxrt.jar
  copy /y tmp\tools\jre\lib\ext\_jfxrt\jfxrt.jar tmp\tools\jre\lib\ext\jfxrt.jar >NUL:

  echo Deleting compiled classes
  rmdir tmp\tools\jre\lib\ext\_jfxrt /Q /S
)

echo Finalizing
mkdir RESULT\%jreName%
move tmp\tools\jre RESULT\%jreName%\ >NUL:
move tmp\src.zip RESULT\%jreName%\ >NUL:
if %compileFX%==1 move tmp\javafx-src.zip RESULT\%jreName%\ >NUL:

echo Cleaning up tmp folder
rmdir tmp /Q /S
mkdir tmp

echo.
echo Success^^!
