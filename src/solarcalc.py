#!/usr/bin/python3

#sudo apt-get install python3-pip

import datetime
import time
import tzlocal # pip3 install tzlocal 
import astral # pip3 install astral
from astral.sun import sun
import pause # pip3 install pause
import RPi.GPIO as GPIO
from threading import Thread
import signal
import os
import logging
import sys

#Set debug to True in order to log all messages!
LOG_ALL = False
#Set log_to_file flag to False in order to print logs on stdout
LOG_TO_FILE = False

#Global variable informing button handling thread about state of main thread
thread_exit = False

# Define pin GPIO15 to control button1
button_ctrl_pin = 15

# Define pin GPIO18 to control relay coil 
relay_ctrl_pin1 = 18
# Define pin GPIO14 to control relay coil 
relay_ctrl_pin2 = 23 #originally 14

# Define pin GPIO21 to control buzzer 
buzzer_ctrl_pin = 21

# Sunset lights on/off status (timer controlled)
glb_sunset_lights_on = False

# Define default location of your lights control box
current_location_name = "Otwock"
current_location_region = "Poland"
current_location_latitude = "52°06′N"
current_location_longitude = "21°15′E"

#create two log file handlers, one for actual log file and another for stdout
stdout_handler = logging.StreamHandler(sys.stdout)

if LOG_TO_FILE == True:
    #extract file name from filename.extension
    idx=os.path.split(os.path.basename(__file__))[1].find('.')
    file_name_wo_extension=os.path.split(os.path.basename(__file__))[1][:idx]
    log_file = os.path.dirname(os.path.realpath(__file__)) + "/" + file_name_wo_extension + ".log"
    file_handler = logging.FileHandler(filename=log_file)
    hndls = [file_handler]
    print ("Program logs are stored in: ", log_file)
else:
    hndls = [stdout_handler]
        
#configure logger module
#levels: DEBUG,INFO,WARNING,ERROR,CRITICAL
#LOG_ALL = TRUE means that all log messages are printed out
#LOG_ALL = FALSE means that DEBUG logs are not printed

if LOG_ALL == True:
    logging.basicConfig(level = logging.DEBUG,format = '%(asctime)s:%(threadName)s:%(filename)s:%(lineno)s:%(levelname)s:%(message)s', handlers=hndls)
else:
    logging.basicConfig(level = logging.INFO,format = '%(asctime)s:%(threadName)s:%(filename)s:%(lineno)s:%(levelname)s:%(message)s', handlers=hndls)


def handleSIGTERM(signum, frame):
    global thread_exit
    global relay_ctrl_pin1
    global relay_ctrl_pin2
    print("Exiting the program, SIGTERM received...")
    thread_exit = True
    thread.join()
    GPIO.output(relay_ctrl_pin1,GPIO.HIGH) #turn off the relay1
    GPIO.output(relay_ctrl_pin2,GPIO.HIGH) #turn off the relay2
    exit(0)

# Define a function for button handling thread
def ButtonHandlingThread(button1_gpio_ctrl_pin):
    global thread_exit
    global relay_ctrl_pin1
    global relay_ctrl_pin2
    global glb_sunset_lights_on
    button_1 = False
    button_1_old = False
    loop_duration = 0.1 #in seconds
    counter_on = 0
    counter_off = 0
    counter_relay2_on_delay = 0
    counter_shutdown = 0 
    shutdown_window = 0
    shutdown_window_inc = 0
    
    logging.info('Starting Button Handling Thread!')
    while (True):
        if thread_exit == True:
            break
        time.sleep(loop_duration) # this sleep is to help ignoring button rebouncing 
        if GPIO.input(button1_gpio_ctrl_pin) == False:
            counter_off = 0
            if counter_on < 10:
                counter_on = counter_on + 1
            else:
                #logging.debug('Button1 = on')
                button_1 = True 
        else:
            counter_on = 0
            if counter_off < 10:
                counter_off = counter_off + 1
            else:
                #logging.debug('Button1 = off')
                button_1 = False
        if button_1 != button_1_old:
            if button_1:
                logging.debug('Button1 toggled to on!')
                logging.debug('    >shutdown_window: %s, loop_duration: %s, shutdown_window_inc: %s, counter_shutdown: %s',str(shutdown_window), str(loop_duration),str(shutdown_window_inc),str(counter_shutdown))             

                if shutdown_window <= (60 / loop_duration): #1min window to turn on/off button 5 times
                    shutdown_window_inc = 1
                    counter_shutdown = counter_shutdown + 1
                else:
                    shutdown_window_inc = 0
                    shutdown_window = 0
                    counter_shutdown = 0
                    
                logging.debug('   >>shutdown_window: %s, loop_duration: %s, shutdown_window_inc: %s, counter_shutdown: %s',str(shutdown_window), str(loop_duration),str(shutdown_window_inc),str(counter_shutdown))  

                if counter_shutdown >= 5: #shutdown system if button is pressed 5 times within 1min
                    logging.info('Light switch toggled on/off 5x in 1min - initiating system shutdown !!!')
                    counter_shutdown = 0
                    os.system("sudo shutdown -h now")
            else:
                logging.debug('Button1 toggled to off!')
                
            button_1_old = button_1
            
        if glb_sunset_lights_on == True or button_1 == True:
            #Turn on relay 1
            GPIO.output(relay_ctrl_pin1,GPIO.LOW)
        else:
            #Turn off relay 1
            GPIO.output(relay_ctrl_pin1,GPIO.HIGH) 
         
        if glb_sunset_lights_on == True and counter_relay2_on_delay >= 100:
            #Turn on relay 2
            GPIO.output(relay_ctrl_pin2,GPIO.LOW)
        elif glb_sunset_lights_on == True:
            counter_relay2_on_delay = counter_relay2_on_delay + 1
        else:
            #Turn off relay 2
            GPIO.output(relay_ctrl_pin2,GPIO.HIGH)
            counter_relay2_on_delay = 0

        if shutdown_window > (180 / loop_duration): # window in sec / loop_duration (i.e. duration of one loop)
            logging.debug('More then 3min elapsed from last light switch on/off toggle - shutdown window has been reset...')
            logging.debug('  >shutdown_window: %s, shutdown_window_max: %f', shutdown_window, 180 / loop_duration)
            shutdown_window_inc = 0
            shutdown_window = 0
            counter_shutdown = 0

        shutdown_window = shutdown_window + shutdown_window_inc
        #logging.debug('shutdown_window_inc =%s, shutdown_window = %s',shutdown_window_inc, shutdown_window)

#Define buzzer melody
def BuzzerSound():
    GPIO.setup(buzzer_ctrl_pin,GPIO.OUT)
    for y in range (3):
        for x in range(3):
            GPIO.output(buzzer_ctrl_pin,GPIO.HIGH)
            time.sleep(0.01)
            GPIO.output(buzzer_ctrl_pin,GPIO.LOW)
            time.sleep(0.01)
        time.sleep(0.5)

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(relay_ctrl_pin1,GPIO.OUT)
GPIO.output(relay_ctrl_pin1,GPIO.HIGH) #turn off the relay1
GPIO.setup(relay_ctrl_pin2,GPIO.OUT)
GPIO.output(relay_ctrl_pin2,GPIO.HIGH) #turn off the relay2

signal.signal(signal.SIGTERM, handleSIGTERM)

current_datetime_local = datetime.datetime.now().astimezone()
current_time_zone = tzlocal.get_localzone().zone
current_datetime_utc = datetime.datetime.utcnow()


#Start button handling thread
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(button_ctrl_pin,GPIO.IN)

thread = Thread(target = ButtonHandlingThread, name = "ButtonHndlThread", args = (button_ctrl_pin,))
thread.start()


next_sunset_datetime_local = current_datetime_local

logging.info (' ')

logging.info ('Platform local time is now: %s', str(current_datetime_local.ctime()))
logging.info ('Platform universal time is now: %s', str(current_datetime_utc.ctime()))

'Play a sound to indicate gardenpi is up and booted!'
BuzzerSound()

logging.info (' ')

while True: #endless loop

    current_location = astral.LocationInfo(current_location_name, current_location_region,current_time_zone, current_location_latitude, current_location_longitude)

    s = sun(current_location.observer, next_sunset_datetime_local.date(), tzinfo=current_time_zone)

    current_location_dawn = s["dawn"]
    current_location_sunrise = s["sunrise"]
    current_location_noon = s["noon"]
    current_location_sunset = s["sunset"]
    current_location_dusk = s["dusk"]

    #print ("Sun information for: " + current_location_name + "," + current_location_region + "(" + current_location_latitude + "," + current_location_longitude + "), on " + str(next_sunset_datetime_local.strftime("%m/%d/%Y")) + ":") 

    logging.info('Sun information for: %s,%s(%s,%s) on %s:',current_location_name,current_location_region,current_location_latitude,current_location_longitude,str(next_sunset_datetime_local.strftime("%m/%d/%Y")))

    #current_location_sunset = datetime.datetime(2021,6,28,20,20) # for test only

    logging.info ('  sunrise: %s', current_location_sunrise.strftime ("%H:%M %Z"))
    logging.info ('  sunset: %s', current_location_sunset.strftime("%H:%M %Z"))


    logging.info (' ')

    time_offset_lights_on = datetime.timedelta(minutes=30) #offset = 30
    time_offset_lights_off = time_offset_lights_on + datetime.timedelta(hours=2) #offset hours = 2 or 3

    current_location_lights_on = current_location_sunset + time_offset_lights_on
    current_location_lights_off = current_location_sunset + time_offset_lights_off
    current_location_lights_off = current_location_lights_off.astimezone()
    
    logging.info('Lights will be switched on at:  %s', current_location_lights_on.strftime("%H:%M %Z"))
    logging.info('Lights will be switched off at: %s', current_location_lights_off.strftime("%H:%M %Z"))

    logging.info(' ')
    logging.info('Waiting until the time when lights will be switched on!')
    pause.until(current_location_lights_on)
    glb_sunset_lights_on = True
    logging.info('Lights has been switched on!')
    pause.until(current_location_lights_off)
    glb_sunset_lights_on = False
    logging.info('Lights has been switched off!')
    
    logging.info(' ')

    #midnight datetime calculated for the day when last switch on/off cycle started at
    today_midnight_datetime = datetime.datetime.combine(current_datetime_local.date(),datetime.time(23,59))
    today_midnight_datetime = today_midnight_datetime.astimezone()
    
    #current date refreshed after last switch on/off cycle has finished
    current_datetime_local = datetime.datetime.now().astimezone()
    
    logging.info('current_datetime_local =  %s',str(current_datetime_local))
    logging.info('today_midnight_datetime =  %s',str(today_midnight_datetime))
    logging.info('current_location_lights_off = %s',str(current_location_lights_off))


    if current_datetime_local <= today_midnight_datetime:
        logging.info('Lights were alrady switched on/off after sunset - making calculations for tommorow')
        next_sunset_datetime_local = current_datetime_local + datetime.timedelta(days=1)
        next_sunset_datetime_local = datetime.datetime.combine(next_sunset_datetime_local.date(),datetime.time(0,5))
        logging.info(  '%s', str(next_sunset_datetime_local))
    else:
        logging.info('Making calculations for todays sunrise/sunset...')
        next_sunset_datetime_local = current_datetime_local
    logging.info(' ')

thread_exit = True
thread.join()
