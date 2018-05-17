@echo off
setlocal enabledelayedexpansion
set vncdir="%userprofile%\Desktop\VNC.exe"
REM CHECK FOR EXISTENCE OF CONFIG FILE, IF IT DOES NOT EXIST MAKE A NEW ONE
if exist "%appdata%\Pingsite\conf.txt" (
	for /f "delims=" %%x in (%appdata%\Pingstore\conf.txt) do (set %%x)
) else (
	md %appdata%\Pingsite
	cd %appdata%\Pingsite
	echo showhelp=0 >> conf.txt
	echo showvnc=0 >> conf.txt
	echo adv=0 >> conf.txt
	echo showcont=0 >> conf.txt
	echo showl3=0 >> conf.txt
)
set error=0
set confdir="%appdata%\Pingsite\conf.txt"

:select
cls
echo  ..............................		
echo  ----ENTER THE SITE NUMBER----		
echo  ..............................		
echo.

if %error%==1 (echo  Please enter a valid site number!
echo.)

set /p id=#: 

if %id%==start goto start
REM FORCE SHUTDOWN
if %id%==stop goto stop
REM A WAY TO GET TO CUSTOM IP WITHOUT PUTTING IN A STORE NUMBER
if %id%==bypass goto menu
if %id%==debug (@echo on)
if %id%==debugoff (@echo off)
REM LM DENOTES A SERVER, LOOP THROUGH NSLOOKUP, THE LAST 3 OCTETS IT PICKS UP ARE THE ONES THAT MATTER
REM ALL IP'S START WITH 15, DOES NOT REQUIRE FIRST OCTET
for /f "tokens=2-4 delims=." %%a in ('nslookup lm%id%') do (
set ipa=%%a
set ipb=%%b
set ipc=%%c
)
REM DNS SERVER HAS THESE OCTETS, IF IT STOPS HERE IT'S BECAUSE THE SITE DOES NOT EXIST
if !ipc!==113 (
	if !ipa!==243 (
		set error=1
		goto select
	)
)

set error=0

:menu
cls
echo  ................................
echo  ------Site %id% Main Menu------
echo  ................................
echo  1 - Ping Menu
echo  2 - Printer Menu
echo  3 - VNC Menu
echo  4 - Quickstat
echo  5 - Return to Store Selection
echo  6 - Settings
echo  7 - Homepage
echo  8 - Exit
echo.
set /p device= 
if %device%==1 goto ping
if %device%==2 goto printer
if %device%==3 goto vnc
if %device%==4 goto quickstat
if %device%==5 goto select
if %device%==6 goto settings
if %device%==7 goto homepage
if %device%==8 goto done


goto menu

:ping
cls
echo  ............................
echo  ----Site %id% Ping Menu----
echo  ............................
echo .
echo  These options will ping 10 times.
if %showcont%==1 (echo  To ping continuously, press t and enter)
echo .
echo  1 - Server (lm)
echo  2 - router (rt)
echo  3 - Switch (sw)
echo  4 - Backup
echo  5 - Other Devices
echo  6 - Ping a custom ip
echo  7 - Main Menu
echo .
set /p ping= Ping:  
REM CERTAIN DEVICES HAVE A PREFIX IN THE CUSTOM DNS, OTHERS MUST PING IP DIRECTLY
if %ping%==1 (set dev="lm")
if %ping%==2 (set dev="rt")
if %ping%==3 (set dev="sw")
if %ping%==4 (set dev="sat")
if %ping%==5 goto more
if %ping%==6 goto custom
if %ping%==7 goto menu
if %ping%==t goto cont


cls
echo Now pinging site %id% %dev% 10 times.
ping -n 10 %dev%%id%

goto ping

:more
cls
echo  ............................
echo  ----Store %id% More Menu----
echo  ............................
echo .
echo  1 - PC 1
echo  2 - PC 2
echo  3 - PC 3
echo  4 - PC 4
echo  5 - PC 5
echo  6 - Main PC
echo  7 - Printer 1
echo  8 - Printer 2
echo  9 - Printer 3
echo  10- Back
echo  11- Main Menu
echo  12- Site Select
echo .
set /p more=Dev: 

if %more% leq 9 goto evenmore
if %more%==10 goto ping
if %more%==11 goto menu
if %more%==12 goto select


goto more

:evenmore
if %more%==6 (
	cls
	echo Main PC
	set /a c=1
	set /a ipd=%ipc%+!c!
	ping -n 10 15.%ipa%.%ipb%.!ipd!
	goto ping
)

if %more%==7 (
	cls
	echo Printer 1
	set /a c=2
	set /a ipd=%ipc%+!c!
	ping -n 10 15.%ipa%.%ipb%.!ipd!
	goto ping
)

if %more%==8 (
	cls
	echo Printer 2
	set /a c=4
	set /a ipd=%ipc%+!c!
	ping -n 10 15.%ipa%.%ipb%.!ipd!
	goto ping
)

if %more%==9 (
	cls
	echo Printer 3
	set /a c=3
	set /a ipd=%ipc%+!c!
	ping -n 10 15.%ipa%.%ipb%.!ipd!
	goto ping
)

REM MOST SITES HAVE 3 PC'S, SOME HAVE UP TO 15. 5 IS A HAPPY MEDIUM
if %more% leq 5 (
	cls
	echo PC %more%
	set /a c=%more%
	set /a ipd=%ipc%+!c!+4
	ping -n 10 15.%ipa%.%ipb%.!ipd!
	goto ping
)

goto menu

:quickstat
REM PING ONCE, LOOK IF LOST PACKETS= 1 OR 0, 1 DENOTES A TIMEOUT, 0 DENOTES SUCCESS
REM THIS IS BY FAR THE LONGEST PROCESS BECAUSE IT HAS TO WAIT FOR A TIMEOUT ON EVERY DEVICE THAT IS NOT UP
REM UNFORTUNATELY, THERE IS REALLY NOT A BETTER WAY TO DO IT
cls
echo ...........................................................
echo ----Please Wait While I Gather The Required Information----
echo ...........................................................
REM BACKUP
set idu_up=0
for /f "tokens=10 delims= " %%m in ('ping -n 1 sat%id% ^| findstr /c:"Lost"') do (
set idu_up=%%m
)

REM router
set pry_up=0
for /f "tokens=10 delims= " %%m in ('ping -n 1 rt%id% ^| findstr /c:"Lost"') do (
set pry_up=%%m

)

if %pry_up%==1 (
goto failure)

if %pry_up%==0 (
for /f "tokens=9 delims= " %%m in ('ping -n 1 rt%id% ^| findstr /c:"Average"') do (
	set pry_ping=%%m)
)


REM SWITCH
set sw_up=0
for /f "tokens=10 delims= " %%m in ('ping -n 1 sw%id% ^| findstr /c:"Lost"') do (
set sw_up=%%m
) 

REM SERVER
set serv_up=0
for /f "tokens=10 delims= " %%m in ('ping -n 1 lm%id% ^| findstr /c:"Lost"') do (
set serv_up=%%m
)

REM MAIN PC
set mgr_up=0
set /a ipf=%ipc%+1
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set mgr_up=%%m
)

REM PRINTER 1
set l1_up=0
set /a ipf=%ipc%+2
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set l1_up=%%m
)

REM PRINTER 2
set l2_up=0
set /a ipf=%ipc%+4
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set l2_up=%%m
)

REM PRINTER 3
set l3_up=0
set /a ipf=%ipc%+3
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set l3_up=%%m
)

REM PC1
set t1_up=0
set /a ipf=%ipc%+5
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set t1_up=%%m
)

REM PC2
set t2_up=0
set /a ipf=%ipc%+6
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set t2_up=%%m
)

REM PC3
set t3_up=0
set /a ipf=%ipc%+7
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set t3_up=%%m
)

REM PC4
set t4_up=0
set /a ipf=%ipc%+8
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set t4_up=%%m
)

REM PC5
set t5_up=0
set /a ipf=%ipc%+9
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set t5_up=%%m
)

REM PC6
set t6_up=0
set /a ipf=%ipc%+10
for /f "tokens=10 delims= " %%m in ('ping -n 1 15.%ipa%.%ipb%.%ipf% ^| findstr /c:"Lost"') do (
set t6_up=%%m
)

for /F "tokens=2" %%i in ('date /t') do set mydate=%%i
set mytime=%time%
REM READOUT
REM TAKE ALL THE VARIABLES AND PRINT THEM OUT
cls
echo  ........................................
echo  ----Here is your snapshot of devices----
echo  ........................................
echo.
echo  Site %id%, taken at %time%
if %idu_up%==1 (
echo  backup is down) else (
echo  backup is up)

if %pry_up%==1 (
echo  router is down) else (
echo  router is up
echo  The ping time is %pry_ping%
)

if %sw_up%==1 (
echo  Switch is down) else (
echo  Switch is up
)

if %serv_up%==1 (
echo  Server is down) else (
echo  Server is up
) 

if %mgr_up%==1 (
echo  Main PC is down) else (
echo  Main PC is up
) 

if %l1_up%==1 (
echo  Printer 1 is down) else (
echo  Printer 1 is up
) 

if %l2_up%==1 (
echo  Printer 2 is down) else (
echo  Printer 2 is up
) 

if %l3_up%==1 (
echo  Printer 3 is down) else (
echo  Printer 3 is up
) 

if %t1_up%==1 (
echo  PC1 is down) else (
echo  PC1 is up
) 

if %t2_up%==1 (
echo  PC2 is down) else (
echo  PC2 is up
) 

if %t3_up%==1 (
echo  PC3 is down) else (
echo  PC3 is up
) 

if %t4_up%==1 (
echo  PC4 is down) else (
echo  PC4 is up
)

if %t5_up%==1 (
echo  PC5 is down) else (
echo  PC5 is up
)

if %t6_up%==1 (
echo  PC6 is down) else (
echo  PC6 is up
)

pause

goto menu

:failure
if %idu_up%==1 (
echo The backup is down, and the router is down. It is possible that this site has no backup, but it is more likely that the site has no power. Call site to check.) else (
echo The backup is up, but the router is down. I recommend restarting the router to start, or open a ticket to hardware.)
pause
goto menu

:page
echo LOC.site >> %userprofile%\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites
"C:\Program Files (x86)\Internet Explorer\iexplore.exe" LOC.site
goto menu
REM NONE OF THESE ARE PRACTICAL, MORE FOR PRACTICE MAKING A CONFIG FILE. PRACTICAL STUFF WAS REMOVED FOR PROPRIETARY REASONS
:settings
cls 
echo  ...................
echo  ------SETTINGS-----
echo  ...................
echo.
echo  When changing a setting: enter the number; press enter. 
echo  Then enter either a 0 for off or a 1 for on.
echo  If you do not enter a 0 or a 1, don't expect things to work right.
echo.
echo  1 - Show VNC IP and Names !showvnc!
echo  2 - Show continuous ping !showcont!
echo  3 - Enable Printer 3 in printer menu !showl3!
echo  6 - Save and Exit
echo . 
set /p setting= Setting: 

if %setting%==1 (set /p showvnc=0/1 
				goto settings)
if %setting%==2 (set /p showcont=0/1 
				goto settings)
if %setting%==3 (set /p showl3=0/1 
				goto settings)
if %setting%==6 (

	echo showvnc=!showvnc! > %confdir%
	echo adv=!adv! >> %confdir%
	echo showcont=!showcont! >> %confdir%
	echo showl3=!showl3! >> %confdir%
	goto menu
)

goto settings

:vnc
REM GET THE LAST OCTET, ASK THE USER FOR THE LAST 2/3 NUMBERS FROM DESKTOP
REM OR ASK WHICH PC THEY ARE ON, MOST OF THE TIME THEY HAVE THEM NUMBERED
for /l %%z IN (1, 1, 10) DO (
	set /a ip%%z=%ipc%+%%z+4
)
cls
echo  .......................................
echo  ------SERVER 15.%ipa%.%ipb%.%ipc% VNC MENU------
if %showvnc%==0 (echo  .......................................)
if %showvnc%==1 (echo  ...................\  /................
echo  %id%                \/
echo  PC 1: %ip1%	PC 6: %ip6%
echo  PC 2: %ip2%	PC 7: %ip7%
echo  PC 3: %ip3%	PC 8: %ip8%
echo  PC 4: %ip4%	PC 9: %ip9%
echo  PC 5: %ip5%	PC 10:%ip10%
 )
echo.
echo  Enter the PC number or:
echo  22 - Custom IP
echo  33 - Return to main menu
echo  44 - Return to store selection
echo.
set /p vnc= %id% T:  

if %vnc% leq 20 (
set /a c=%vnc%+4
set /a ipd=%ipc%+!c!
start "" %vncdir% 15.%ipa%.%ipb%.!ipd! -password=%vncpw%
goto vnc)

if %vnc%==22 goto custt
if %vnc%==33 goto menu
if %vnc%==44 goto select
if %vnc%==t goto testt

goto vnc

:custt
cls
echo Enter the ip of the PC you wish to connect to.
set /p custt=:
start "" %vncdir% %custt% -password=%vncpw%
goto vnc

:testt
set /a ipd=%ipc%+100
start "" %vncdir% 15.%ipa%.%ipb%.!ipd! -password=%vncpw%
goto vnc

:custom
echo ................................................
echo -----Enter the ip address you wish to ping-----
echo ................................................
echo Site %id%, server is 15.%ipa%.%ipb%.%ipc%.
set /p ip=:
cls
echo Pinging %ip% 10 times.
ping -n 10 %ip%
goto menu

:printer
cls
echo ........................................................
echo -----Select the printer page you would like to view-----
echo ........................................................
echo.
echo 1 - Back
echo 2 - Printer 1
echo 3 - Printer 2
if %showl3%==1 (echo 4 - Printer 3)
echo.
set /p print=Printer #:

if %print%==2 (
set /a ipe=%ipc%+1
start chrome 15.%ipa%.%ipb%.!ipe!
goto menu)

if %print%==3 (
set /a ipf=%ipc%+2
start chrome 15.%ipa%.%ipb%.!ipf!
goto menu)

if %print%==4 (
set /a ipg=%ipc%+3
start chrome 15.%ipa%.%ipb%.!ipg!
goto menu)


if %print%==1 (
goto menu)

goto printer

:cont
cls
echo ....................................
echo -----Welcome to Continuous Ping-----
echo ....................................
echo .
echo In order to stop cont ping, press CTRL+C, then type N and press enter. 
echo That will bring you back to the main menu.
echo .
echo 1 - Router
echo 2 - Switch
echo 3 - Server
echo 4 - Custom IP
echo 5 - Main Menu
echo .
set /p opt=:  

if %opt%==1 (
cls
ping -t rt%id%
goto menu)

if %opt%==2 (
cls
ping -t sw%id%
goto menu)

if %opt%==3 (
cls
ping -t lm%id%
goto menu)

if %opt%==4 (
cls
echo The Server IP is: 15.%ipa%.%ipb%.%ipc%.
set /p ipz=Enter the ip you wish to ping continuously:
ping -t %ipz%
goto menu)

if %opt%==5 goto menu

goto cont

:start
cls
echo  What program would you like to start?

echo  1 - Service manager
echo  2 - Outlook
echo  3 - Dev
echo  5 - Notepad++
echo  7 - Reddit
echo  8 - Site select

set /p pro=Program: 

if %pro%==2 (start chrome https://outlook.office365.com/owa/)
if %pro%==3 (start putty -load Remote)
if %pro%==5 (start notepad++)
if %pro%==7 (	set /p subreddit=Subreddit? 
				start chrome reddit.com/r/!subreddit!)
if %pro%==8 goto select

goto start

:stop
shutdown /s /t 0 /f

:done
endlocal
