@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Building libharu as Static Library
echo ========================================

:: Step 1: Delete existing build and dist folders
echo.
echo [1/6] Cleaning existing build and dist folders...
if exist build (
    echo Removing build folder...
    rmdir /s /q build
)
if exist dist (
    echo Removing dist folder...
    rmdir /s /q dist
)
echo Done.

:: Step 2: Create new build and dist folders
echo.
echo [2/6] Creating new build and dist folders...
mkdir build
mkdir dist
echo Done.

:: Step 3: Configure the project with CMake
echo.
echo [3/6] Configuring project with CMake...
cd build
cmake .. ^
    -G "Visual Studio 17 2022" ^
    -A x64 ^
    -DBUILD_SHARED_LIBS=OFF ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX="%~dp0dist" ^
    -DLIBHPDF_EXAMPLES=OFF

if errorlevel 1 (
    echo ERROR: CMake configuration failed!
    cd ..
    exit /b 1
)
echo Done.

:: Step 4: Build the project
echo.
echo [4/6] Building project...
cmake --build . --config Release

if errorlevel 1 (
    echo ERROR: Build failed!
    cd ..
    exit /b 1
)
echo Done.

:: Step 5: Install to dist folder
echo.
echo [5/6] Installing to dist folder...
cmake --install . --config Release

if errorlevel 1 (
    echo ERROR: Installation failed!
    cd ..
    exit /b 1
)

cd ..
echo Done.

:: Step 6: Copy dependency libraries
echo.
echo [6/7] Copying dependency libraries to dist folder...
if exist "build\_deps\zlib-build\Release\zlibstatic.lib" (
    echo Copying zlibstatic.lib...
    copy "build\_deps\zlib-build\Release\zlibstatic.lib" "dist\lib\"
)
if exist "build\_deps\libpng-build\Release\libpng16_static.lib" (
    echo Copying libpng16_static.lib...
    copy "build\_deps\libpng-build\Release\libpng16_static.lib" "dist\lib\"
)
echo Done.

:: Step 7: Extract version numbers and create zip
echo.
echo [7/7] Creating versioned zip file...

:: Extract version numbers from hpdf_version.h
for /f "usebackq tokens=3" %%a in (`findstr /C:"#define HPDF_MAJOR_VERSION " include\hpdf_version.h ^| findstr /V "HPDF_VERSION_ID HPDF_VERSION_TEXT"`) do if not defined MAJOR set MAJOR=%%a
for /f "usebackq tokens=3" %%a in (`findstr /C:"#define HPDF_MINOR_VERSION " include\hpdf_version.h ^| findstr /V "HPDF_VERSION_ID HPDF_VERSION_TEXT"`) do if not defined MINOR set MINOR=%%a
for /f "usebackq tokens=3" %%a in (`findstr /C:"#define HPDF_BUGFIX_VERSION " include\hpdf_version.h ^| findstr /V "HPDF_VERSION_ID HPDF_VERSION_TEXT"`) do if not defined BUGFIX set BUGFIX=%%a

set VERSION=%MAJOR%.%MINOR%.%BUGFIX%
set ZIPNAME=libharu-%VERSION%-static.zip

echo Creating %ZIPNAME%...
powershell -command "Compress-Archive -Path '%~dp0dist\*' -DestinationPath '%~dp0%ZIPNAME%' -Force"

if errorlevel 1 (
    echo ERROR: Zip creation failed!
    exit /b 1
)
echo Done.

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo Static library and headers installed to: %~dp0dist
echo Zip file created: %~dp0%ZIPNAME%
echo.

endlocal