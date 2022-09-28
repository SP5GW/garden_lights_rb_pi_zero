#!/usr/bin/python3

import RPi.GPIO as GPIO
import time


# Define pin GPIO21 to control relay coil 
buzzer_ctrl_pin = 21

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

def BuzzerSound():
    GPIO.setup(buzzer_ctrl_pin,GPIO.OUT)
    for y in range (3):
        for x in range(3):
            GPIO.output(buzzer_ctrl_pin,GPIO.HIGH)
            time.sleep(0.01)
            GPIO.output(buzzer_ctrl_pin,GPIO.LOW)
            time.sleep(0.01)
        time.sleep(0.5)
        
        
BuzzerSound()