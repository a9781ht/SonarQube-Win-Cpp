@echo off
chcp 65001 >nul
REM ============================================================================
REM  Test Script (Google Test)
REM ============================================================================

echo.
echo ============================================
echo   Building Google Test
echo ============================================
echo.

REM Move to the root directory
pushd %~dp0..

REM Set MSBuild path
set MSBuild="C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"

REM Download nuget.exe if not exists
set NuGet=%~dp0nuget.exe
if not exist "%NuGet%" (
    echo -Downloading nuget.exe...
    powershell -Command "Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile '%NuGet%'"
    if not exist "%NuGet%" (
        echo Failed to download nuget.exe
        popd
        exit /b 1
    )
)

REM Restore NuGet packages (use VS2022 MSBuild to avoid old MSBuild errors)
echo -Restoring NuGet packages...
"%NuGet%" restore StaticLib\StaticLib.sln -PackagesDirectory StaticLib\packages -MSBuildPath "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin"

if %ERRORLEVEL% neq 0 (
    echo.
    echo ============================================
    echo   NuGet Restore FAILED!
    echo ============================================
    popd
    exit /b 1
)

REM Build test project only (MSBuild will auto-build Calculator via ProjectReference)
echo -Building TestCalculator (with dependencies)...
%MSBuild% "StaticLib\test\TestCalculator.vcxproj" /t:Rebuild /p:Configuration=Debug /p:Platform=x64 /nodeReuse:False

if %ERRORLEVEL% neq 0 (
    echo.
    echo ============================================
    echo   Build FAILED!
    echo ============================================
    popd
    exit /b 1
)

echo.
echo ============================================
echo   Running Google Test via vstest.console.exe
echo ============================================
echo.

REM Set NuGet package versions (align with packages.config versions)
set MicrosoftTestPlatformVer=17.14.1
set GoogleTestAdapterVer=0.18.0
set JunitXmlTestLoggerVer=7.1.0
set ReportGeneratorVer=5.4.18

REM Set nuget packages tool paths
set PackagesDir=%CD%\StaticLib\packages
set TestPlatformPath=%PackagesDir%\Microsoft.TestPlatform.%MicrosoftTestPlatformVer%\tools\net462\Common7\IDE\Extensions\TestPlatform
set TestAdapterPath=%PackagesDir%\GoogleTestAdapter.%GoogleTestAdapterVer%\build\_common
set JunitXmlTestLoggerPath=%PackagesDir%\JunitXml.TestLogger.%JunitXmlTestLoggerVer%\build\_common
set ReportGeneratorPath=%PackagesDir%\ReportGenerator.%ReportGeneratorVer%\tools\net47

REM Set test result and test coverage files
set TestResultsDir=%CD%\StaticLib\test\TestResults
if exist "%TestResultsDir%" (rmdir /S /Q "%TestResultsDir%"; mkdir "%TestResultsDir%")

REM Set test output directory
set TestOutputDir=%CD%\StaticLib\test\x64\Debug

REM Copy JunitXml.TestLogger to TestPlatform Extensions
if not exist "%TestPlatformPath%\Extensions\JunitXml.TestLogger.dll" (
    echo -Copying JunitXml.TestLogger to TestPlatform Extensions...
    xcopy "%JunitXmlTestLoggerPath%\*.dll" "%TestPlatformPath%\Extensions" /E /Y /C /I /H >nul
)

REM Run tests
echo -Running tests with Code Coverage...
"%TestPlatformPath%\vstest.console.exe" "%TestOutputDir%\TestCalculator.exe" ^
    /InIsolation /Parallel ^
    /TestAdapterPath:"%TestAdapterPath%" ^
    /Logger:"junit;LogFileName=junit_test_results.xml;MethodFormat=Class;FailureBodyFormat=Verbose" ^
    /Enablecodecoverage ^
    /Collect:"Code Coverage;Format=cobertura" ^
    /ResultsDirectory:"%TestResultsDir%"

set TEST_EXIT_CODE=%ERRORLEVEL%

REM Test results: Convert JUnit format to SonarQube Generic Format (using PowerShell script)
echo -Converting test results to SonarQube format...
powershell -ExecutionPolicy Bypass -File "%~dp0Convert-JUnitToSonar.ps1" ^
    -InputFile "%TestResultsDir%\junit_test_results.xml" ^
    -OutputFile "%TestResultsDir%\sonar_test_results.xml" ^
    -TestFilePath "StaticLib/test/TestCalculator.cpp"
echo   Done.

REM Code coverage: Convert cobertura format to SonarQube Generic Format (using ReportGenerator)
echo -Converting code coverage to SonarQube format...
"%ReportGeneratorPath%\ReportGenerator.exe" ^
    "-reports:%TestResultsDir%\**\*.cobertura.xml" ^
    "-targetdir:%TestResultsDir%" ^
    "-reporttypes:SonarQube;TeamCitySummary" ^
    "-sourcedirs:%CD%" ^
    "-filefilters:+%CD%\**;-*googletest*" ^
    "-verbosity:Warning"
echo   Done.

if %TEST_EXIT_CODE% neq 0 (
    echo.
    echo ============================================
    echo   Some Tests FAILED!
    echo ============================================
    popd
    exit /b 1
)

echo.
echo ============================================
echo   All Tests PASSED!
echo ============================================

popd
exit /b 0
