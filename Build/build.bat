@echo off
chcp 65001 >nul
REM ============================================================================
REM  Build Script
REM ============================================================================

echo.
echo ============================================
echo   Building Calculator
echo ============================================
echo.

REM Change to solution directory
pushd %~dp0\..\StaticLib

REM Set MSBuild path
set MSBuild="C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"

REM Build Calculator project only
echo -Building Calculator...
%MSBuild% "src\Calculator.vcxproj" /t:Rebuild /p:Configuration=Debug /p:Platform=x64 /nodeReuse:False

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
echo   Build Completed Successfully!
echo ============================================

popd
exit /b 0
