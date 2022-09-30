#!/usr/bin/python3

import RPi.GPIO as GPIO
import time


# Define pin GPIO21 to control buzzer 
buzzer_ctrl_pin = 21

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

def BuzzerSound(SoundType):

    GPIO.setup(buzzer_ctrl_pin,GPIO.OUT)
    
    if (SoundType==1):
        #Multiple Beeps
        for y in range (3):
            for x in range(3):
                GPIO.output(buzzer_ctrl_pin,GPIO.HIGH)
                time.sleep(0.01)
                GPIO.output(buzzer_ctrl_pin,GPIO.LOW)
                time.sleep(0.01)
            time.sleep(0.5)
    elif SoundType == 2:
        #Single Beep
            for x in range(8):
                GPIO.output(buzzer_ctrl_pin,GPIO.HIGH)
                time.sleep(0.01)
                GPIO.output(buzzer_ctrl_pin,GPIO.LOW)
                time.sleep(0.01)
    else:
        print('')
        #Undefined sound
        
        
BuzzerSound(1)
time.sleep (5)
BuzzerSound(2)