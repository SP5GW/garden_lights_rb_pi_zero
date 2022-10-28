#!/bin/bash

################################################################
#                                                              #
# Automated test of gardenpi controller.                       #
#                                                              #
# Author: andrzej mazur                                        #
# Last Change: October, 2022                                   #
# URL: https://github.com/andrzej1973/garden_lights_rb_pi_zero #
#                                                              #
################################################################


################################################################
#                                                              #
# Usage: gardenpi [OPTIONS]                                    #
# gardenpi command provides basic information about software   #
# running on the controller. It also allows to perform basic   #
# functional test of the gardenpi unit.                        #
#                                                              #
# Supported options:                                           #
#                                                              #
#  -t, --test                                                  #
#    Run selftest routine                                      #
#  -v, --verbose                                               #
#    Increase logging verbosity.                               #
#  -V, --version                                               #
#    Show version number and Python version.                   #
#  -h, --help                                                  #
#    Show help message and exit.                               #
#                                                              #
################################################################

function SelfTest {

echo "Starting GardenPi Controller self test..."
echo "During test execution gardenlightctrl service will be stopped"

i2c=0
rtc=0
relays=0
buzzer=0
promne="" 
prom=""
graf=""
web=""
gui=1
gservice=0

echo " "
echo "==> Step1: i2c Bus Test <==="
echo " "

if [ $flag_verbose -eq 1 ];then
	i2cdetect -y 1 | grep -iz --color "UU" 

	echo " "
	echo "i2c functions corretly if text:"
	echo ">>>UU<<<"
	echo "is shown on above priontout from i2cdetect command"
	echo " " 
fi

i2cdetect -y 1 2>&1 | grep 'UU' 1> /dev/null 2> /dev/null

if [ $? -eq 0 ]
then
        echo "i2c Interface is UP"
	i2c=1
else
        echo "i2c Interface is Down"
fi

echo " "
echo "==> Step2: DS3231 RTC Test <==="
echo " "

if [ $flag_verbose -eq 1 ];then
	hwclock -rv | grep -iz --color "Time read from Hardware Clock:"
	
	echo "RTC Module functions correctly if text:"
	echo ">>>Time read from Hardware Clock:<<<"
	echo "is seen on above priontout from hwclock command."
	echo " " 
fi

hwclock -rv | grep "Time read from Hardware Clock:" 1> /dev/null 2> /dev/null

if [ $? -eq 0 ]
then
        echo "RTC Module is OK"
        rtc=1
else
        echo "RTC Module is Down"
fi

echo " "
echo "==> Step3: Relay Module Test <==="
echo " "

systemctl stop gardenlightsctrl.service --quiet

echo 18 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio18/direction
echo 23 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio23/direction

echo "Relay: REL1 and REL2 indicators will be turned on"
echo "for 3 seconds..."
echo " "
echo 0 > /sys/class/gpio/gpio18/value
echo 0 > /sys/class/gpio/gpio23/value
sleep 3
echo 1 > /sys/class/gpio/gpio18/value
echo 1 > /sys/class/gpio/gpio23/value

echo 18 > /sys/class/gpio/unexport
echo 23 > /sys/class/gpio/unexport

read -p "Were REL1 and REL2 turned on for 3 sec?  (y/n) " yn

case $yn in 
        y ) relays=1;;
        Y ) relays=1;;
        * ) break;;
esac

echo " "
echo "===> Step4: Buzzer Test <==="
echo " "
echo "Set volume knob in 50% position"
echo "Three beeps will be heart in less than 6sec"
echo " "

systemctl start gardenlightsctrl.service --quiet
sleep 7

read -p "Were beeps heart?  (y/n) " yn

case $yn in 
        y ) buzzer=1;;
        Y ) buzzer=1;;
        * ) break;;
esac

echo " "
echo "===> Step5: GUI Accessibility Test <==="
echo " "

curl -v localhost:9100  2>&1 | grep 'Connected' 1> /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
	echo "Prometheus Node Exporter is Up"
else
	echo "Prometheus Node Exporter is Down"
	gui=0
fi

curl -v localhost:9090 2>&1 | grep 'Connected' 1> /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
        echo "Prometheus Server is Up"
else
        echo "Prometheus Server is Down"
        gui=0
fi

curl -v localhost:3000 2>&1 | grep 'Connected' 1> /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
        echo "Grafana Server is Up"
else
        echo "Grafana Server is Down"
        gui=0
fi

curl -v localhost:80 2>&1 | grep 'Connected' 1> /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
        echo "Port redirect 3000:80 OK"
else
        echo "Port redicrect 30000:80 NOK"
        gui=0
fi


echo " "
echo "===> Test Results Summary: <==="
echo " "

if [ $i2c -eq 1 ]
then
        echo "Step1: i2c Bus Test: PASSED"
else
        echo "Step1: i2c Bus Test: FAILED"
fi

if [ $rtc -eq 1 ]
then
	echo "Step2: DS3231 RTC Test: PASSED"
else
	echo "Step2: DS3231 RTC Test: FAILED"
fi

if [ $relays -eq 1 ]
then
        echo "Step3: Relay Module Test: PASSED"
else
        echo "Step3: Relay Module Test: FAILED"
fi

if [ $buzzer -eq 1 ]
then
        echo "Step4: Buzzer Test: PASSED"
else
        echo "Step4: Buzzer Test: FAILED"
fi

if [ $gui -eq 1 ]
then
        echo "Step5: GUI Test: PASSED"
else
        echo "Step5: GUI Test: FAILED"
fi

echo " "

systemctl status gardenlightsctrl.service 2>&1 | grep 'active (running)' 1> /dev/null 2> /dev/null 
#systemctl status NetworkManager-dispatcher.service 2>&1 | grep 'active (running)' 1> /dev/null 2> /dev/null

if [ $? -eq 0 ]
then
        echo "gardenlightctrl service started"
	gservice=1
else
        echo "Failed to start gardenlightctrl service"
fi

echo " "


if [ $i2c -eq 1 ] && [ $rtc -eq 1 ] && [ $relays -eq 1 ] && [ $buzzer -eq 1 ] && [ $gui -eq 1 ] && [ $gservice -eq 1 ]
then
        echo "Your GardenPi Controller is fully functional - enjoy using it!"
else
        echo "Some GardenPi functionality might not be available..."
        echo "Please check documentation for troubleshooting tips."
fi

echo "exiting" $0 " script..."

} #end of selftest function


####Main body of the script###

if [ "$(id -u)" -ne 0 ]; then
	echo "Running gardenpi selftest requires root privilages!"
	echo "use: $"$0" instead..."
  exit
fi

#global flags
flag_verbose=0
flag_selftest=0

while [ ! $# -eq 0 ]
do
        case "$1" in
                --version | -V)
                        echo "gardenpi version 3.0"
                        exit
                        ;;
                --help | -h)
                        echo "gardenpi command provides basic information about software"
			echo "running on this controller. It also allows to perform basic"
                        echo "functional test of the gardenpi unit."
                        echo " "
			echo "Options:"
			echo "  -t, --test"
			echo "    Run selftest routine"
			echo "  -v, --verbose"
			echo "    Increase logging verbosity"
			echo "  -V, --version"
			echo "    Show version number and Python version"
			echo "  -h, --help"
			echo "    Show help message and exit"
                        exit
			;;
		--test | -t)
			flag_selftest=1
			;;
                --verbose | -v)
                        flag_verbose=1
                        ;;
                *)
                        echo $0": invalid option: "$1
                        echo "Try:'" $0 "--help' for more information. "
                        exit
			;;
        esac
        shift
done

if [ $flag_selftest -eq 1 ]; then
	SelfTest
	exit
fi

flag_selftestcat /etc/motd
