@echo off

set Version=輸入你的軟體版本
set ScannerVersion=6.1.0.4477

REM download build-wrapper and scanner
echo.
echo -download build-wrapper
curl -SL --output %USERPROFILE%\build-wrapper-win-x86.zip %SONAR_HOST_URL%/static/cpp/build-wrapper-win-x86.zip
echo -download scanner
curl -SL --output %USERPROFILE%\sonar-scanner-cli-%ScannerVersion%-windows-x64.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-%ScannerVersion%-windows-x64.zip

REM extract zip
echo.
echo -extract build-wrapper
7z x -y -o"%USERPROFILE%\" "%USERPROFILE%\build-wrapper-win-x86.zip"
echo -extract scanner
7z x -y -o"%USERPROFILE%\" "%USERPROFILE%\sonar-scanner-cli-%ScannerVersion%-windows-x64.zip"

REM add to PATH
echo.
echo -add build-wrapper file path into environment variable
set PATH=%PATH%;%USERPROFILE%\build-wrapper-win-x86
echo -add scanner file path into environment variable
set PATH=%PATH%;%USERPROFILE%\sonar-scanner-%ScannerVersion%-windows-x64\bin

REM define New Code
rem master/main branch
if %CI_COMMIT_BRANCH% == %CI_DEFAULT_BRANCH% (
    set newcode="sonar.projectVersion=%Version%"
    goto sonar
)
rem release beanch
echo %CI_COMMIT_BRANCH%|findstr /r "^輸入你的release分支前綴_">nul
if %Errorlevel% EQU 0 (
    set newcode="sonar.projectVersion=%Version%"
    goto sonar
)
rem feature branch
set newcode="sonar.newCode.referenceBranch=%NewCodeRefBranch%"
goto sonar

:sonar
REM start to build
echo.
echo ==== SonarQube build ====
build-wrapper-win-x86-64 --out-dir .\SonarQube build.bat

REM start to scan
echo.
echo ==== SonarQube scan ====
pushd ..
cmd /c sonar-scanner -D"sonar.cfamily.compile-commands=Build\SonarQube\compile_commands.json" -D"sonar.projectKey=%SONARQUBE_PROJECT_KEY%" -D"sonar.host.url=%SONAR_HOST_URL%" -D"sonar.token=%SONAR_TOKEN%" -D%newcode%
if %Errorlevel% NEQ 0 exit 1
popd

REM clean up
echo.
echo -clean up
del /q /f %USERPROFILE%\build-wrapper-win-x86.zip
del /q /f %USERPROFILE%\sonar-scanner-cli-%ScannerVersion%-windows-x64.zip
rd /q /s %USERPROFILE%\build-wrapper-win-x86
rd /q /s %USERPROFILE%\sonar-scanner-%ScannerVersion%-windows-x64
