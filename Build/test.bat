@echo off
chcp 65001 >nul
REM ============================================================================
REM  Test Script (Google Test)
REM ============================================================================

echo.
echo ============================================
echo   Building and Running Google Test
echo ============================================
echo.

REM Change to solution directory
pushd %~dp0\..\StaticLib

REM Set MSBuild path
set MSBuild="C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
set NuGet=%~dp0nuget.exe

REM Download nuget.exe if not exists
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
"%NuGet%" restore StaticLib.sln -PackagesDirectory packages -MSBuildPath "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin"

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
%MSBuild% "test\TestCalculator.vcxproj" /t:Rebuild /p:Configuration=Debug /p:Platform=x64 /nodeReuse:False

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
echo   Running Tests
echo ============================================
echo.

REM Run tests
test\x64\Debug\TestCalculator.exe --gtest_output=xml:test_results.xml

if %ERRORLEVEL% neq 0 (
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
