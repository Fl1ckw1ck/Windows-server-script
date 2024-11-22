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

set /p answer=Have you answered all the forensics questions?[y/n]: 
	if /I {%answer%}=={y} (
		goto :password
	) else (
		echo Please go and answer them.
		pause
		exit
)

:password
set /p answer=Have you set password complexity rec and disabled revearse encryption?[y/n]: 
	if /I {%answer%}=={y} (
		goto :menu
	) else (
		echo Go do that.
		pause
		exit
	)

:menu
	cls
	echo "1)Set user properties 	2)Disable guest "
	echo "3)Set password policy 	4)Set lockout policy"
	echo "5)Enable Firewall 	6)Disable services"
	echo "7)Turn on UAC		8)Remote Desktop Config"
	echo "9)Enable auto update	10)Security options"
	echo "11)Audit the machine	12)Edit groups"
	echo "0)Exit"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	set /p answer= Please choose an option: 
		if "%answer%"=="1" goto :userProp
		if "%answer%"=="2" goto :disGuest
		if "%answer%"=="3" goto :passwdPol
		if "%answer%"=="4" goto :lockout
		if "%answer%"=="5" goto :firewall
		if "%answer%"=="6" goto :services
		if "%answer%"=="7" goto :UAC
		if "%answer%"=="8" goto :remDesk
		if "%answer%"=="9" goto :autoUpdate
		if "%answer%"=="10" goto :secopt
		if "%answer%"=="11" goto :audit
		if "%answer%"=="12" goto :group
		if "%answer%"=="0" exit
	rem turn on screensaver
pause

:userProp
	echo Setting password never expires
	wmic UserAccount set PasswordExpires=True
	wmic UserAccount set PasswordChangeable=True
	wmic UserAccount set PasswordRequired=True

	pause
	goto :menu

:disGuest
rem Disables the guest account
net user Guest | findstr /i "Account active: Yes" >nul
	if %errorlevel%==0 (
		echo Guest account is already disabled.
		pause
		goto :menu
	) else (
		net user guest /active:no
		if %errorlevel%==0 (
		echo Guest account has been disabled.
	) else (
	echo Failed to disable Guest account.
	)
pause
goto :menu
)

:passwdPol
	rem Sets the password policy
	rem Set complexity requirments
	net accounts /minpwlen:10
	net accounts /maxpwage:60
	net accounts /minpwage:1
	net accounts /uniquepw:24
echo Passwd policies set.
pause
goto :menu
	
:lockout
rem Sets the lockout policy
	net accounts /lockoutduration:30
	net accounts /lockoutthreshold:10
	net accounts /lockoutwindow:30
echo Lockout policy set.
pause
goto :menu
	
:firewall
rem Enables firewall and disables msedge rule with consolidated error handling
netsh advfirewall set allprofiles state on >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to enable firewall on all profiles.
) else (
    netsh advfirewall firewall set rule name="msedge" new enable=no >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to disable the msedge firewall rule.
    ) else (
        echo Firewall is now enabled and msedge rule disabled.
    )
)
pause
goto :menu


:services

rem List of services to disable
set services=TlntSvr ftpsvc msftpsvc upnphost SNMPtrap SharedAccess SSDPSRV RemoteRegistry HomeGroupProvider HomeGroupListener

rem Loop through each service and disable it
for %%S in (!services!) do (
    echo Attempting to stop %%S service...
    sc query %%S | findstr /i "STATE" | findstr /i "RUNNING" >nul 2>&1
    if %errorlevel% equ 0 (
        sc stop %%S >nul 2>&1
        if %errorlevel% neq 0 (
            echo Failed to stop %%S service.
        ) else (
            sc config %%S start= disabled >nul 2>&1
            if %errorlevel% neq 0 (
                echo Failed to disable %%S service.
            ) else (
                echo %%S service has been disabled.
            )
        )
    ) else (
        echo %%S service is not running. Attempting to disable...
        sc config %%S start= disabled >nul 2>&1
        if %errorlevel% neq 0 (
            echo Failed to disable %%S service.
        ) else (
            echo %%S service has been disabled.
        )
    )
)

rem Enable Wecsvc service
sc start Wecsvc
if %errorlevel% neq 0 (
    echo Failed to start Wecsvc service.
) else (
    sc config Wecsvc start= auto
    if %errorlevel% neq 0 (
        echo Failed to set Wecsvc service to auto start.
    ) else (
        echo Wecsvc service has been set to auto start.
    )
)
pause
goto :menu

rem Enable Wecsvc service
sc start Wecsvc
if %errorlevel% neq 0 (
    echo Failed to start Wecsvc service.
) else (
    sc config Wecsvc start= auto
    if %errorlevel% neq 0 (
        echo Failed to set Wecsvc service to auto start.
    ) else (
        echo Wecsvc service has been set to auto start.
    )
)
pause
goto :menu

:UAC
rem Enable UAC to maximum setting with error handling
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f
if %errorlevel% neq 0 (
    echo Failed to set EnableLUA to 1.
)

reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f
if %errorlevel% neq 0 (
    echo Failed to set ConsentPromptBehaviorAdmin to 2.
)

reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f
if %errorlevel% neq 0 (
    echo Failed to set PromptOnSecureDesktop to 1.
)
echo UAC has been set to maximum setting.
pause
goto :menu

:autoUpdate
rem Turn on automatic updates
reg add HKLM\SOFTWARE\Microsoft\WINDOWS\CurrentVersion\WindowsUpdate\AutoUpdate /v AUOptions /t REG_DWORD /d 4 /f
if %errorlevel% neq 0 (
    echo Failed to turn on automatic updates.
) else (
    echo Automatic updates have been turned on successfully.
)
pause
goto :menu

:secopt
echo Changing security options now.
	rem Limit local account use of blank passwords to console
	reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v LimitBlankPasswordUse /t REG_DWORD /d 1 /f

    rem Restrict CD ROM drive
	reg add HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\Winlogon /v AllocateCDRoms /t REG_DWORD /d 1 /f

	rem Disallow remote access to floppie disks (drives/folders)
	reg add HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\Winlogon /v AllocateFloppies /t REG_DWORD /d 1 /f

    rem Auditing access of Global System Objects
	reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v auditbaseobjects /t REG_DWORD /d 1 /f

	rem Auditing Backup and Restore
	reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v fullprivilegeauditing /t REG_DWORD /d 1 /f

	rem Disable Undock without logon
	reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v undockwithoutlogon /t REG_DWORD /d 0 /f

    rem Prevent users from print driver installs
	reg add HKLM\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers /v AddPrinterDrivers /t REG_DWORD /d 1 /f

    rem Disable machine account password changes
	reg add HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v DisablePasswordChange /t REG_DWORD /d 1 /f

    rem Maximum Machine Password Age
	reg add HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v MaximumPasswordAge /t REG_DWORD /d 30 /f

    rem Require Strong Session Key
	reg add HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v RequireStrongKey /t REG_DWORD /d 1 /f

    rem Do not display last user on logon
	reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v dontdisplaylastusername /t REG_DWORD /d 1 /f

    rem Don't require CTRL+ALT+DEL even though it serves no purpose
	reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v DisableCAD /t REG_DWORD /d 0 /f

	rem Disable Domain Credential for local security
	reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v disabledomaincreds /t REG_DWORD /d 1 /f

    rem Require Security Signature Server
    reg add HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters /v RequireSecuritySignature /t REG_DWORD /d 1 /f

    rem Enable Security Signature Server
    reg add HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters /v EnableSecuritySignature /t REG_DWORD /d 1 /f

	rem Require Security Signature Client
	reg add HKLM\SYSTEM\CurrentControlSet\Services\LanManWorkstation\Parameters /v RequireSecuritySignature /t REG_DWORD /d 1 /f 
	
	rem Enable Security Signature Client
    reg add HKLM\SYSTEM\CurrentControlSet\Services\LanManWorkstation\Parameters /v EnableSecuritySignature /t REG_DWORD /d 1 /f

	rem Require Sign/Seal
	reg add HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v RequireSignOrSeal /t REG_DWORD /d 1 /f
	
	rem Sign Channel
	reg add HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v SignSecureChannel /t REG_DWORD /d 1 /f
	
	rem Seal Channel
	reg add HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v SealSecureChannel /t REG_DWORD /d 1 /f

    rem Disable SMB Passwords unencrypted to third party
	reg add HKLM\SYSTEM\CurrentControlSet\services\LanmanWorkstation\Parameters /v EnablePlainTextPassword /t REG_DWORD /d 0 /f

    rem Idle Time Limit - 15 mins
	reg add HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters /v autodisconnect /t REG_DWORD /d 15 /f

    rem Restrict Anonymous Enumeration SAM #1
	reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v restrictanonymous /t REG_DWORD /d 1 /f 
	
	rem Restrict Anonymous Enumeration SAM#2
	reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v restrictanonymoussam /t REG_DWORD /d 1 /f 

    rem Don't Give Anons Everyone Permissions
	reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v everyoneincludesanonymous /t REG_DWORD /d 0 /f

    rem Remotely accessible registry paths cleared
	reg add HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg\AllowedExactPaths /v Machine /t REG_MULTI_SZ /d "" /f
	
	rem Remotely accessible registry paths and sub-paths cleared
	reg add HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg\AllowedPaths /v Machine /t REG_MULTI_SZ /d "" /f

    rem Restict anonymous access to named pipes and shares blank
	reg add HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters /v NullSessionShares /t REG_MULTI_SZ /d "" /f
    reg ADD HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters /v NullSessionPipes /t REG_MULTI_SZ /d "" /f

    rem Allow to use Machine ID for NTLM enabled
	reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v UseMachineId /t REG_DWORD /d 0 /f

	rem Automatic Admin logon disabled
	reg add HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\Winlogon /v AutoAdminLogon /t REG_DWORD /d 0 /f

    rem Disable virtual memory page file
    reg add HKLM\SYSTEM\CurrentControlSet\Control\SessionManager\Memory Management /v PagingFiles /t REG_MULTI_SZ /d "" /f

    rem Enable Installer Detection
    reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableInstallerDetection /t REG_DWORD /d 1 /f

    rem UAC- Switch to secure desktop when prompt for elevation
	reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f

    rem Enables DEP
    bcdedit.exe /set {current} nx AlwaysOn
pause
goto :menu
	
:audit
	echo Auditing the maching now
auditpol /set /category:* /success:enable /failure:enable
if %errorlevel% neq 0 (
    echo Failed to set audit policy.
) else (
    echo Audit policy set successfully for all categories.
)

pause
goto :menu

:group
	cls
	net localgroup
	set /p grp=What group would you like to check?:
	net localgroup !grp!
	set /p answer=Is there a user you would like to add or remove?[add/remove/back]:
	if "%answer%"=="add" (
		set /p userAdd=Please enter the user you would like to add: 
		net localgroup !grp! !userAdd! /add
		echo !userAdd! has been added to !grp!
	)
	if "%answer%"=="remove" (
		set /p userRem=Please enter the user you would like to remove:
		net localgroup !grp! !userRem! /delete
		echo !userRem! has been removed from !grp!
	)
	if "%answer%"=="back" (
		goto :group
	)

	set /p answer=Would you like to go check again?[y/n]
	if /I "%answer%"=="y" (
		goto :group
	)
	if /I "%answer%"=="n" (
		goto :menu
	)
endlocal
