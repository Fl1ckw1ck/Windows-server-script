@echo off
setlocal enabledelayedexpansion
net session
if %errorlevel%==0 (
	echo Admin rights granted!
) else (
    echo Failure, no rights
	pause
    exit
)
cls

:menu
	cls
echo "Backdoor Detection 1"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	set /p answer= Please choose an option: 
		if "%answer%"=="1" goto :Backdoor-Detection
		if "%answer%"=="0" exit
pause

:Backdoor-Detection {
  # Clear the screen
  Clear-Host

  # Check if there are any listening ports on 127.0.0.1
  $ports = Get-NetTCPConnection -State Listen | Where-Object {$_.LocalAddress -eq "127.0.0.1"}

  if ($ports) {
    # Get the port number
    $port = $ports.LocalPort

    Write-Host "Port with 127.0.0.1 found: $port"

    # Use Get-Process to find connections to the local IP address and the specified port
    $connection = Get-Process -Id (Get-NetTCPConnection -State Established -LocalPort $port).OwningProcess

    if ($connection) {
      # Get the executable path
      $executable = $connection.MainModule.FileName

      # Use Get-Package to determine which package owns the executable file
      $package = Get-Package -Name (Get-Item $executable).Name

      if ($package) {
        # Uninstall the package using Uninstall-Package
        Uninstall-Package -Name $package.Name -Force
        Write-Host "Backdoor detected and removed successfully."
      } else {
        Write-Host "Unable to determine the package that owns the executable file."
      }
    } else {
      Write-Host "No connections found to the local IP address and port $port."
    }
  } else {
    Write-Host "No port with 127.0.0.1 found"
    Write-Host "No backdoor detected."
    # Call the menu function (assuming it's defined elsewhere)
    menu
  }

  Write-Host "Make sure port is closed"
  Get-NetTCPConnection -State Listen
  # Call the menu function (assuming it's defined elsewhere)
  menu
}
