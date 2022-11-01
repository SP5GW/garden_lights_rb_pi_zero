import time
import datetime
import tzlocal


print("UTC Time: ", datetime.datetime.utcnow().ctime())
print("Current timze zone: ", tzlocal.get_localzone_name())
print("Current local time: ", datetime.datetime.now().ctime())


print ("DST defined for active time zone: ", time.daylight) 
        #Value is 0 when DST is not defined for current timezone
        #Value is 1 when DST is defined for current timezone
print ("DST active: ", time.localtime().tm_isdst)
        #Value is 0 when DST is not in effect.
        #Value is 1 when DST is in effect.
        #Value is -1 when DST is unknow.



current_datetime_local = datetime.datetime.now().astimezone()
print (current_datetime_local.ctime())

print(tzlocal.get_localzone().zone)
