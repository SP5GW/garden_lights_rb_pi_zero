#!/usr/bin/python3

import RPi.GPIO as GPIO
import time


# Define pin GPIO21 to control buzzer 
buzzer_ctrl_pin = 21

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

def BuzzerSound(SoundType,Repeat):

    GPIO.setup(buzzer_ctrl_pin,GPIO.OUT)
    
    if (SoundType==1):
        #Multiple Short Beeps
        for y in range (Repeat):
            for x in range(3):
                GPIO.output(buzzer_ctrl_pin,GPIO.HIGH)
                time.sleep(0.01)
                GPIO.output(buzzer_ctrl_pin,GPIO.LOW)
                time.sleep(0.01)
            time.sleep(0.5)
    elif SoundType == 2:
        #Single Long Beep
        #Repeat parameter ignored
            time.sleep(0.5)
            for x in range(10):
                GPIO.output(buzzer_ctrl_pin,GPIO.HIGH)
                time.sleep(0.01)
                GPIO.output(buzzer_ctrl_pin,GPIO.LOW)
                time.sleep(0.01)
    else:
        print('')
        #Undefined sound
        
#play 3 Short Beeps        
BuzzerSound(1,3)
time.sleep (5)
#play 1 Long Beep
BuzzerSound(2,0)