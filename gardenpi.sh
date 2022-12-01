#!/bin/bash

##################################################################
#                                                                #
# Automated test of gardenpi controller.                         #
#                                                                #
# Author: andrzej mazur                                          #
# Last Change: November, 2022                                    #
# URL: https://github.com/andrzej1973/garden_lights_rb_pi_zero   #
#                                                                #
##################################################################


##################################################################
#                                                                #
# Usage: gardenpi [-l [-d] [-e ip topic]] [-t] [-v] [-V] [-h]    #
# gardenpi command provides basic information about software     #
# running on the controller. It also allows to perform basic     #
# functional test of the gardenpi unit and and configuration of  #
# remote loggging capabilities over rsyslog and kafka            #
#                                                                #
# Supported options:                                             #
#                                                                #
#  -l, --logging                                                 #
#    Configure rsyslog/kafka server ip address and kafka topic   #
#  -t, --test                                                    #
#    Run selftest routine                                        #
#  -v, --verbose                                                 #
#    Increase logging verbosity.                                 #
#  -V, --version                                                 #
#    Show version number and Python version.                     #
#  -h, --help                                                    #
#    Show help message and exit.                                 #
#                                                                #
##################################################################

function SelfTest {

if [ "$(id -u)" -ne 0 ]; then
        echo "Running gardenpi selftest requires root privilages!"
        echo "use: sudo gardenpi --test  instead..."
  exit
fi

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
syslog=0
kafka=0

source gardenpi.conf

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

#if log redirect is configured test it
if [[ $(grep "^# *.* @@" /etc/rsyslog.conf) == "" ]]
then
	echo " "
	echo "===> Step6: RSyslog Connectivity Test <==="
	echo " "


	nc -z -w5 "$logging_server_ip" 514 1> /dev/null 2> /dev/null

	if [ $? -eq 0 ]; then
    		echo "Remote Syslog Server is Up."
    		syslog=1
	else
    		echo "Remote Syslog Server is Not Reachable."
	fi

	echo " "
	echo "===> Step7: Kafka Broker Connectivity Test <==="
	echo " "

	nc -z -w5 "$logging_server_ip" 9092 1> /dev/null 2> /dev/null

	if [ $? -eq 0 ]; then
    		echo "Remote Kafka Broker is Up."
    		kafka=1
	else
    		echo "Remote Kafka Broker is Not Reachable."
	fi
else
	#exlude syslog and kafka from test results summary
	syslog=3
	kafka=3 
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

if [ $syslog -eq 1 ]
then
        echo "Step6: Syslog Test: PASSED"
elif [ $syslog -eq 0 ]
then
        echo "Step6: Syslog Test: FAILED"
else
	#ignore syslog in final healthcheck statement
	syslog=1
fi

if [ $kafka -eq 1 ]
then
        echo "Step7: Kafka Test: PASSED"
elif [ $kafka -eq 0 ]
then
        echo "Step7: Kafka Test: FAILED"
else
	#ignore kafka in final healthcheck statement
	kafka=1
fi


echo " "

systemctl status gardenlightsctrl.service 2>&1 | grep 'active (running)' 1> /dev/null 2> /dev/null 

if [ $? -eq 0 ]
then
        echo "gardenlightctrl service started"
	gservice=1
else
        echo "Failed to start gardenlightctrl service"
fi

echo " "


if [ $i2c -eq 1 ] && [ $rtc -eq 1 ] && [ $relays -eq 1 ] && [ $buzzer -eq 1 ] && [ $gui -eq 1 ] && [ $gservice -eq 1 ] && [ $syslog -eq 1 ] && [ $kafka -eq 1 ]
then
        echo "Your GardenPi Controller is fully functional - enjoy using it!"
else
        echo "Some GardenPi functionality might not be available..."
        echo "Please check documentation for troubleshooting tips."
fi

if [[ "$(grep "^# *.* @@" /etc/rsyslog.conf)" != "" ]]; then
	echo " "
	echo "###############################################################"
	echo "#  log forwarding over syslog or kafka not configured, use:   #"
        echo "#             sudo gardenpi -l -e ip topic                    #"
        echo "#  to configure it.                                           #"
	echo "###############################################################"
	echo " "
fi

echo "exiting gardenpi command..."

} #end of selftest function

function LoggingCfg {
#enable/disable/show remote logging configuration

if [ "$(id -u)" -ne 0 ]; then
        echo "Running gardenpi logging config requires root privilages!"
        echo "use: sudo gardenpi -l server_ip kafka_topic  instead..."
  exit
fi

case $loggingcfg_action in
	--enable | -e)
		if [ $loggingcfg_param -ne 4 ]; then
        		echo "mandatory parameter missing, use:" 
        		echo "sudo gardenpi -l -e server_ip kafka_topic"
			echo "sudo gardenpi -l -d"
			echo "sudo gardenpi -s"
        		exit
		fi

		if [[ "$(ping -q $logging_server_ip -c 1 2>&1 | grep 'Name or service not known')" != "" ]]; then
        		#specified ip address incorrect or not reachable
        		echo "gardenpi -l: ${logging_server_ip}:Name or service not known"
        		exit
		fi

		#find log redirection line in rsyslog.conf file 
		#and replace it with one including remote server ip address
		sed -i '/*.* @@/c\*.* @@'"${logging_server_ip}"':514' /etc/rsyslog.conf

		#find kafka producer configuration line in rsyslog.conf file
		#and replace it with one including broker ip address and topic
		sed -i '/action(type="omkafka"/c\action(type="omkafka" topic="'"${kafka_topic}"\
'" broker=["'"${logging_server_ip}"':9092"] template="ls_json")' /etc/rsyslog.conf

		#apply new parameters to rsyslog service configuration
		systemctl daemon-reload 2>&1
		systemctl restart  syslog.service 2>&1

		#store server ip and topic in config file

		sed -i '/logging_server_ip/c\logging_server_ip='"${logging_server_ip}" "${conf_file_name_path}"
		sed -i '/kafka_topic/c\kafka_topic='"${kafka_topic}" "${conf_file_name_path}"

		exit
		;;
	--disable | -d)
                if [ $loggingcfg_param -ne 2 ]; then
                        echo "too many parameters given" 
                        echo "use: sudo gardenpi -l -d"
                        exit
                fi

		source gardenpi.conf

                #find log redirection line in rsyslog.conf file 
                #and replace it with one including remote server ip address commented out
                sed -i '/*.* @@/c\#*.* @@'"${logging_server_ip}"':514' /etc/rsyslog.conf

                #find kafka producer configuration line in rsyslog.conf file
                #and replace it with one including broker ip address and topic commented out
                sed -i '/action(type="omkafka"/c\#action(type="omkafka" topic="'"${kafka_topic}"\
'" broker=["'"${logging_server_ip}"':9092"] template="ls_json")' /etc/rsyslog.conf

                #apply new parameters to rsyslog service configuration
                systemctl daemon-reload 2>&1
                systemctl restart  syslog.service 2>&1

                #store server ip and topic in config file

                sed -i '/logging_server_ip/c\logging_server_ip=' "${conf_file_name_path}"
                sed -i '/kafka_topic/c\kafka_topic=' "${conf_file_name_path}"

		exit
		;;

        --show | -s)
                if [ $loggingcfg_param -ne 2 ]; then
                        echo "too many parameters given" 
                        echo "use: sudo gardenpi -l -s"
                        exit
                fi

                source "${conf_file_name_path}"

		echo "logging server ip address: ${logging_server_ip}"
		echo "kafka topic: ${kafka_topic}"
                exit
                ;;

	*)
		 echo "mandatory parameters missing" 
                 echo "use: gardenpi --help"
	;;
esac

} #end of loggingcfg function


####Main body of the script###

#global flags
flag_verbose=0
flag_selftest=0
flag_loggingcfg=0

loggingcfg_param=1
logging_server_ip=""
kafka_topic=""

this_file_name=$(basename "${0%.sh}")
this_file_path=$(dirname $(readlink -f $0))

conf_file_name_path="${this_file_path}/${this_file_name}.conf"

#echo $this_file_name
#echo $this_file_path

while [ ! $# -eq 0 ]
do
        case "$1" in
                --version | -V)
                        echo "gardenpi version 4.1"
                        exit
                        ;;
                --help | -h)
			echo "Usage: gardenpi [-l [-d] [-e ip topic]] [-t] [-v] [-V] [-h]"
                        echo "gardenpi command provides basic information about software"
			echo "running on this controller. It also allows to perform basic"
                        echo "functional test of the gardenpi unit and configuration of "
			echo "remote loggging capabilities over rsyslog and kafka"
                        echo " "
			echo "Options:"
			echo "  -l, --logging"
			echo "    Configure rsyslog/kafka server ip address and kafka topic"
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
		--logging | -l)
			flag_loggingcfg=1
			;;
                *)
			if [ $flag_loggingcfg -eq 0 ]; then
                        	echo $0": invalid option: "$1
                        	echo "Try:'" $0 "--help' for more information. "
                        	exit
			fi

			if [ $loggingcfg_param -eq 1 ]; then
				loggingcfg_param=2
				loggingcfg_action=$1
			elif [ $loggingcfg_param -eq 2 ]; then
				loggingcfg_param=3
				logging_server_ip=$1
			elif [ $loggingcfg_param -eq 3 ]; then
                                loggingcfg_param=4
                                kafka_topic=$1
			fi
			;;
        esac
        shift
done

if [ $flag_selftest -eq 1 ]; then
	SelfTest
	exit
fi

if [ $flag_loggingcfg -eq 1 ]; then
	LoggingCfg
	exit
fi

cat /etc/motd


