REM ***************************************************************************
REM    package-nightly.cmd
REM    ---------------------
REM    begin                : January 2011
REM    copyright            : (C) 2011 by Juergen E. Fischer
REM    email                : jef at norbit dot de
REM ***************************************************************************
REM *                                                                         *
REM *   This program is free software; you can redistribute it and/or modify  *
REM *   it under the terms of the GNU General Public License as published by  *
REM *   the Free Software Foundation; either version 2 of the License, or     *
REM *   (at your option) any later version.                                   *
REM *                                                                         *
REM ***************************************************************************
@echo off
set GRASS_VERSION=6.4.3RC2

set BUILDDIR=%CD%\build
REM set BUILDDIR=%TEMP%\qgis_unstable
set LOG=%BUILDDIR%\build.log

if not exist "%BUILDDIR%" mkdir %BUILDDIR%
if not exist "%BUILDDIR%" goto error

set VERSION=%1
set PACKAGE=%2
set PACKAGENAME=%3
if "%VERSION%"=="" goto error
if "%PACKAGE%"=="" goto error
if "%PACKAGENAME%"=="" set PACKAGENAME=qgis-dev

path %SYSTEMROOT%\system32;%SYSTEMROOT%;%SYSTEMROOT%\System32\Wbem;%PROGRAMFILES%\CMake 2.8\bin
set PYTHONPATH=

if "%PROGRAMFILES%"=="" set PROGRAMFILES=C:\Programme
set VS90COMNTOOLS=%PROGRAMFILES%\Microsoft Visual Studio 9.0\Common7\Tools\
call "%PROGRAMFILES%\Microsoft Visual Studio 9.0\VC\vcvarsall.bat" x86

if "%OSGEO4W_ROOT%"=="" set OSGEO4W_ROOT=%PROGRAMFILES%\OSGeo4W
if not exist "%OSGEO4W_ROOT%\bin\o4w_env.bat" goto error

call "%OSGEO4W_ROOT%\bin\o4w_env.bat"

set O4W_ROOT=%OSGEO4W_ROOT:\=/%
set LIB_DIR=%O4W_ROOT%

set DEVENV=
if exist "%DevEnvDir%\vcexpress.exe" set DEVENV=vcexpress
if exist "%DevEnvDir%\devenv.exe" set DEVENV=devenv
if "%DEVENV%"=="" goto error

PROMPT qgis%VERSION%$g 

set BUILDCONF=RelWithDebInfo
REM set BUILDCONF=Release


cd ..\..
set SRCDIR=%CD%

if "%BUILDDIR:~1,1%"==":" %BUILDDIR:~0,2%
cd %BUILDDIR%

if exist repackage goto package

if not exist build.log goto build

REM
REM try renaming the logfile to see if it's locked
REM

if exist build.tmp del build.tmp
if exist build.tmp goto error

ren build.log build.tmp
if exist build.log goto locked
if not exist build.tmp goto locked

ren build.tmp build.log
if exist build.tmp goto locked
if not exist build.log goto locked

goto build

:locked
echo Logfile locked
if exist build.tmp del build.tmp
goto error

:build
echo Logging to %LOG%
echo BEGIN: %DATE% %TIME%>>%LOG% 2>&1
if errorlevel 1 goto error

set >buildenv.log

if exist CMakeCache.txt goto skipcmake

echo CMAKE: %DATE% %TIME%>>%LOG% 2>&1
if errorlevel 1 goto error

set LIB=%LIB%;%OSGEO4W_ROOT%\lib
set INCLUDE=%INCLUDE%;%OSGEO4W_ROOT%\include

cmake -G "Visual Studio 9 2008" ^
	-D BUILDNAME="OSGeo4W-Nightly-VC9" ^
	-D SITE="qgis.org" ^
	-D PEDANTIC=TRUE ^
	-D WITH_SPATIALITE=TRUE ^
	-D WITH_MAPSERVER=TRUE ^
	-D WITH_ASTYLE=TRUE ^
	-D WITH_GLOBE=TRUE ^
	-D WITH_TOUCH=TRUE ^
	-D CMAKE_CONFIGURATION_TYPES=%BUILDCONF% ^
	-D GEOS_LIBRARY=%O4W_ROOT%/lib/geos_c_i.lib ^
	-D SQLITE3_LIBRARY=%O4W_ROOT%/lib/sqlite3_i.lib ^
	-D SPATIALITE_LIBRARY=%O4W_ROOT%/lib/spatialite_i.lib ^
	-D PYTHON_EXECUTABLE=%O4W_ROOT%/bin/python.exe ^
	-D PYTHON_INCLUDE_PATH=%O4W_ROOT%/apps/Python27/include ^
	-D PYTHON_LIBRARY=%O4W_ROOT%/apps/Python27/libs/python27.lib ^
	-D SIP_BINARY_PATH=%O4W_ROOT%/apps/Python27/sip.exe ^
	-D GRASS_PREFIX=%O4W_ROOT%/apps/grass/grass-%GRASS_VERSION% ^
	-D QT_BINARY_DIR=%O4W_ROOT%/bin ^
	-D QT_LIBRARY_DIR=%O4W_ROOT%/lib ^
	-D QT_HEADERS_DIR=%O4W_ROOT%/include/qt4 ^
	-D QT_ZLIB_LIBRARY=%O4W_ROOT%/lib/zlib.lib ^
	-D QT_PNG_LIBRARY=%O4W_ROOT%/lib/libpng13.lib ^
	-D QWT_INCLUDE_DIR=%O4W_ROOT%/include/qwt ^
	-D QWT_LIBRARY=%O4W_ROOT%/lib/qwt5.lib ^
	-D CMAKE_INSTALL_PREFIX=%O4W_ROOT%/apps/%PACKAGENAME% ^
	-D CMAKE_CXX_FLAGS_RELWITHDEBINFO="/MD /ZI /Od /D NDEBUG /D QGISDEBUG" ^
	-D FCGI_INCLUDE_DIR=%O4W_ROOT%/include ^
	-D FCGI_LIBRARY=%O4W_ROOT%/lib/libfcgi.lib ^
	%SRCDIR%>>%LOG% 2>&1
if errorlevel 1 goto error

REM bail out if python or grass was not found
grep -Eq "^(Python not being built|Could not find GRASS)" %LOG%
if not errorlevel 1 goto error

:skipcmake

echo ZERO_CHECK: %DATE% %TIME%>>%LOG% 2>&1
%DEVENV% qgis%VERSION%.sln /Project ZERO_CHECK /Build %BUILDCONF% /Out %LOG%>>%LOG% 2>&1
if errorlevel 1 goto error

echo ALL_BUILD: %DATE% %TIME%>>%LOG% 2>&1
%DEVENV% qgis%VERSION%.sln /Project ALL_BUILD /Build %BUILDCONF% /Out %LOG%>>%LOG% 2>&1
if errorlevel 1 goto error

echo RUN_TESTS: %DATE% %TIME%>>%LOG% 2>&1
%DEVENV% qgis%VERSION%.sln /Project Nightly /Build %BUILDCONF% /Out %LOG%>>%LOG% 2>&1
REM if errorlevel 1 echo "TESTS WERE NOT SUCCESSFUL."

echo INSTALL: %DATE% %TIME%>>%LOG% 2>&1
%DEVENV% qgis%VERSION%.sln /Project INSTALL /Build %BUILDCONF% /Out %LOG%>>%LOG% 2>&1
if errorlevel 1 goto error

:package
echo PACKAGE: %DATE% %TIME%>>%LOG% 2>&1

cd ..
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' postinstall-dev.bat >%OSGEO4W_ROOT%\etc\postinstall\%PACKAGENAME%.bat
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' preremove-desktop.bat >%OSGEO4W_ROOT%\etc\preremove\%PACKAGENAME%.bat
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' qgis.bat.tmpl >%OSGEO4W_ROOT%\bin\%PACKAGENAME%.bat.tmpl
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' browser.bat.tmpl >%OSGEO4W_ROOT%\bin\%PACKAGENAME%-browser.bat.tmpl
sed -e 's/@package@/%PACKAGENAME%/g' -e 's/@version@/%VERSION%/g' -e 's/@grassversion@/%GRASS_VERSION%/g' qgis.reg.tmpl >%OSGEO4W_ROOT%\apps\%PACKAGENAME%\bin\qgis.reg.tmpl

REM sed -e 's/%OSGEO4W_ROOT:\=\\\\\\\\%/@osgeo4w@/' %OSGEO4W_ROOT%\apps\%PACKAGENAME%\python\qgis\qgisconfig.py >%OSGEO4W_ROOT%\apps\%PACKAGENAME%\python\qgis\qgisconfig.py.tmpl
REM if errorlevel 1 goto error

REM del %OSGEO4W_ROOT%\apps\%PACKAGENAME%\python\qgis\qgisconfig.py

touch exclude

move %OSGEO4W_ROOT%\apps\%PACKAGENAME%\bin\qgis.exe %OSGEO4W_ROOT%\bin\%PACKAGENAME%.exe
move %OSGEO4W_ROOT%\apps\%PACKAGENAME%\bin\qbrowser.exe %OSGEO4W_ROOT%\bin\%PACKAGENAME%-browser.exe

tar -C %OSGEO4W_ROOT% -cjf %PACKAGENAME%-%VERSION%-%PACKAGE%.tar.bz2 ^
	--exclude-from exclude ^
	apps/%PACKAGENAME% ^
	bin/%PACKAGENAME%.exe ^
	bin/%PACKAGENAME%-browser.exe ^
	bin/%PACKAGENAME%.bat.tmpl ^
	bin/%PACKAGENAME%-browser.bat.tmpl ^
	etc/postinstall/%PACKAGENAME%.bat ^
	etc/preremove/%PACKAGENAME%.bat ^
	>>%LOG% 2>&1
if errorlevel 1 goto error

goto end

:error
echo BUILD ERROR %ERRORLEVEL%: %DATE% %TIME%
echo BUILD ERROR %ERRORLEVEL%: %DATE% %TIME%>>%LOG% 2>&1
if exist %PACKAGENAME%-%VERSION%-%PACKAGE%.tar.bz2 del %PACKAGENAME%-%VERSION%-%PACKAGE%.tar.bz2

:end
echo FINISHED: %DATE% %TIME% >>%LOG% 2>&1
