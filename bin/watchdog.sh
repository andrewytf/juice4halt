#!/usr/bin/env bash

set -eo pipefail

echo "Starting juice4halt watchdog..."

# remove any triggers from previous shutdowns
rm -f /home/pi/juice4halt/.triggered-shutdown

#create directory for working with GPIO and wait
echo "25" > /sys/class/gpio/export
sleep 0.2s
 
# use the pin as an open-drain output, send a short LOW pulse (= Booting finished, shutdown_script runs, automatic shutdown enabled)
# then change to input and listen
# if a LOW is sent from the J4H then start with the shutdown
 
# set GPIO25 as output and set output to LOW
echo "out" > /sys/class/gpio/gpio25/direction
echo "0" > /sys/class/gpio/gpio25/value
sleep 0.1s
echo "in" > /sys/class/gpio/gpio25/direction
 
#wait until pin rises to HI
sleep 0.1s
 
pinval1="1" # 1st reading
pinval2="1" # 2nd reading
 
#to be resistant to short pulses (e.g. 100ms pulse generated by the rebootj4h script) two readings 200ms apart from each other are required
 
while [ "$pinval1" !=  "0" ] || [ "$pinval2" !=  "0" ]
do
        #reading the value of the input pin
        pinval1=$(cat /sys/class/gpio/gpio25/value)
       
        #wait
        sleep 0.2s
 
	    #reading the value of the input pin again 0.2s later
        pinval2=$(cat /sys/class/gpio/gpio25/value)

done

# set GPIO25 as output and set output to LOW
echo "out" > /sys/class/gpio/gpio25/direction
echo "0" > /sys/class/gpio/gpio25/value
 
# wait for system halt
# after system halted the pin will be automatically switched to input and the level will be pulled up to HI
# a LOW to HI transition signals to the J4H to turn the power off

# set a flag file so that the safe-shutdown script does not communicate over GPIO
touch /home/pi/juice4halt/.triggered-shutdown

echo ""
echo "Juice4halt: Power failure, RPi will now shut down."
sudo halt
