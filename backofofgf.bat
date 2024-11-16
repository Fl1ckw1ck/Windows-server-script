@echo off

:: Clear the screen
cls

:: Check if there are any listening ports on 127.0.0.1
for /f "tokens=2" %%a in ('netstat -an ^| findstr /c:"127.0.0.1"') do (
  set port=%%a
  goto found_port
)

echo No port with 127.0.0.1 found
echo No backdoor detected.
goto end

:found_port
echo Port with 127.0.0.1 found: %port%

:: Use netstat to find connections to the local IP address and the specified port
for /f "tokens=2" %%a in ('netstat -an ^| findstr /c:"%port%"') do (
  set connection=%%a
  goto found_connection
)

echo No connections found to the local IP address and port %port%
goto end

:found_connection
:: Get the executable path
for /f "tokens=2" %%a in ('tasklist ^| findstr /c:"%connection%"') do (
  set executable=%%a
  goto found_executable
)

echo Unable to determine the executable path.
goto end

:found_executable
:: Use wmic to determine which package owns the executable file
for /f "tokens=2" %%a in ('wmic path win32_process where "name='%executable%'" get package ^| findstr /v "Package"') do (
  set package=%%a
  goto found_package
)

echo Unable to determine the package that owns the executable file.
goto end

:found_package
:: Uninstall the package using wmic
wmic path win32_product where "name='%package%'" call uninstall
if %errorlevel% neq 0 (
  echo Error uninstalling package: %errorlevel%
  goto end
)

echo Backdoor detected and removed successfully.

:end
echo Make sure port is closed
netstat -an
if %errorlevel% neq 0 (
  echo Error checking port status: %errorlevel%
  goto end
)