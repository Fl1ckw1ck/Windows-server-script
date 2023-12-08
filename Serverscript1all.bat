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
		echo please go and answer them.
		pause
		exit
	)
:password
set /p answer=Have you set password complexity rec and disabled revearse encryption?[y/n]:
	if /I {%answer%}=={y} (
		goto :menu
	) else (
		echo go do that
		pause
		exit
	)

:menu
	cls
	echo "1)Set user properties 	2)Disable guest"
	echo "3)Set password policy 	4)Set lockout policy"
	echo "5)Enable Firewall		6)Windows Services"
	echo "7)Enable auto update 	8)Turn on UAC""
	echo "9)Security options	10)Audit the machine"
	echo "11)Exit"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	set /p answer=Please choose an option:
		if "%answer%"=="1" goto :userProp
		if "%answer%"=="2" goto :disGuest
		if "%answer%"=="3" goto :passwdPol
		if "%answer%"=="4" goto :lockout
		if "%answer%"=="5" goto :firewall
		if "%answer%"=="6" goto :services
		if "%answer%"=="7" goto :autoUpdate
		if "%answer%"=="8" goto :UAC
		if "%answer%"=="9" goto :secOpt
		if "%answer%"=="10" goto :audit
		rem turn on screensaver

		if "%answer%"=="11" exit

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
	net user Guest | findstr Active | findstr Yes
	if %errorlevel%==0 (
		echo Guest account is already disabled.
		pause
		goto :menu
	)
	if %errorlevel%==1 (
		net user guest /active:no
		pause
		goto :menu
	)

:passwdPol
	rem Sets the password policy
	rem Set complexity requirments
	echo Setting pasword policies
	net accounts /minpwlen:10
	net accounts /maxpwage:60
	net accounts /minpwage:1
	net accounts /uniquepw:24

	pause
	goto :menu

:lockout
	rem Sets the lockout policy
	echo Setting the lockout policy
	net accounts /lockoutduration:30
	net accounts /lockoutthreshold:10
	net accounts /lockoutwindow:30

	pause
	goto :menu

:firewall
	rem Enables firewall
	netsh advfirewall set allprofiles state on

	pause
	goto :menu

:services
	echo Windows Services
	sc stop TlntSvr
	sc config TlntSvr start= disabled
	sc stop ftpsvc
	sc config ftpsvc start= disabled
	sc stop msftpsvc
	sc config msftpsvc start= disabled
	sc stop upnphost
	sc config upnphost start= disabled
	sc stop SNMPtrap
	sc config SNMPtrap start= disabed
	sc stop SharedAccess
	sc config SharedAccess start= disabled
	sc stop SSDPSRV
	sc config SSDPSRV start= disabled
	sc stop RemoteRegistry
	sc config RemoteRegistry start= disabled
	sc stop HomeGroupProvider
	sc config HomeGroupProvider start= disabled
	sc stop HomeGroupListener
	sc config HomeGroupListener start= disabled
	sc start Wecsvc
	sc config Wecsvc start= auto

	pause
	goto :menu
:UAC

	rem Enable UAC
	echo Turning on UAC has to be done manually.
	echo Change User Account Control Settings to max

	pause
	goto :menu

:autoUpdate
	rem Turn on automatic updates
	echo Turning on automatic updates
	reg add "HKLM\SOFTWARE\Microsoft\WINDOWS\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 4 /f

	pause
	goto :menu

:secOpt
	echo Changing security options now.

	rem Limit local account use of blank passwords to console
	reg ADD "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 1 /f

	rem Auditing access of Global System Objects
	reg ADD "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v auditbaseobjects /t REG_DWORD /d 0 /f

	rem Auditing Backup and Restore
	reg ADD "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v fullprivilegeauditing /t REG_DWORD /d 0 /f
	
	rem Undock without logon
	reg ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v undockwithoutlogon /t REG_DWORD /d 0 /f

	rem Prevent print driver installs
	reg ADD "HKLM\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers" /v AddPrinterDrivers /t REG_DWORD /d 1 /f

	rem Require Sign/Seal
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v RequireSignOrSeal /t REG_DWORD /d 1 /f

	rem Sign Channel
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v SignSecureChannel /t REG_DWORD /d 1 /f

	rem Seal Channel
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v SealSecureChannel /t REG_DWORD /d 1 /f
	
	rem Disable machine account password changes
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v DisablePasswordChange /t REG_DWORD /d 1 /f
	
	rem Maximum Machine Password Age
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v MaximumPasswordAge /t REG_DWORD /d 30 /f
	
	rem Require Strong Session Key
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\Netlogon\Parameters /v RequireStrongKey /t REG_DWORD /d 1 /f

	rem Do not display last user on logon
	reg ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v dontdisplaylastusername /t REG_DWORD /d 1 /f
	
	rem Require Security Signature - Digitally sign comm (always)
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters /v enablesecuritysignature /t REG_DWORD /d 1 /f

	rem Enable Security Signature - Digitally sign comm (server agrees)
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters /v requiresecuritysignature /t REG_DWORD /d 1 /f
	
	rem SMB Passwords unencrypted to third party
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\LanmanWorkstation\Parameters /v EnablePlainTextPassword /t REG_DWORD /d 0 /f
	
	rem Idle Time Limit - 15 mins
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters /v autodisconnect /t REG_DWORD /d 15 /f
	
	rem Restrict Anonymous Enumeration SAM
	reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v restrictanonymous /t REG_DWORD /d 1 /f

	rem Restrict Anonymous Enumeration SAM and shares
	reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v restrictanonymoussam /t REG_DWORD /d 1 /f
	
	rem Don't Give Anons Everyone Permissions
	reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v everyoneincludesanonymous /t REG_DWORD /d 0 /f
	
	rem Restict anonymous access to named pipes and shares
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters /v NullSessionShares /t REG_MULTI_SZ /d "" /f
	
	rem remotely accessible registry paths 1
	reg ADD HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg\AllowedExactPaths /v Machine /t REG_MULTI_SZ /d "" /f

	rem remotely accessible registry paths and sub-paths 2
	reg ADD HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg\AllowedPaths /v Machine /t REG_MULTI_SZ /d "" /f

	rem Restict anonymous access to named pipes and shares
	reg ADD HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters /v NullSessionShares /t REG_MULTI_SZ /d 1 /f
	
	rem Allow to use Machine ID/computer idenity for NTLM
	reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v UseMachineId /t REG_DWORD /d 1 /f
	
	rem Automatic Admin logon
	reg ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_DWORD /d 0 /f
	
	rem Wipe page file from shutdown
	reg ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f
	
	rem UAC setting (Prompt on Secure Desktop)
	reg ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f

	rem Enables DEP
	bcdedit.exe /set {current} nx AlwaysOn
	pause
	goto :menu

:audit
	echo Auditing the maching now
	auditpol /set /category:* /success:enable
	auditpol /set /category:* /failure:enable

	pause
	goto :menu

endlocal