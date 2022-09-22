#!/usr/bin/python3

import time
import RPi.GPIO as GPIO


# Define pin GPIO18 to control relay coil 
relay_ctrl_pin = 18

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(relay_ctrl_pin,GPIO.OUT)
print("ctrl pin set to low!")
GPIO.output(relay_ctrl_pin,GPIO.LOW) #turn off the relay
time.sleep (3)
GPIO.output(relay_ctrl_pin,GPIO.HIGH)
print("ctrl pin set to high!")
time.sleep (3)
GPIO.output(relay_ctrl_pin,GPIO.LOW) #turn off the relay
print("ctrl pin set to low!")
                                                                                                                                                                 