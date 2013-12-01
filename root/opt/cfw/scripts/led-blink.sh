#!/bin/sh

LED_DEV=/sys/devices/platform/pmic_light.1/lit
CH_R=3
CH_G=4
CH_B=5
#
CUR_OFF=0
CUR_ON=1
DC_OFF=0
DC_ON=1

#BP=[0-3] :  0=1/256s 1=1/8s 2=1s 3=2s 
BP_DEFAULT=0

led_ctrl() {
	echo ch  $1 > $LED_DEV
	echo cur $2 > $LED_DEV
	echo bp  $3 > $LED_DEV
	echo dc  $4 > $LED_DEV
}

#$1 = ch
led_off() {
	led_ctrl $1 $CUR_OFF $BP_DEFAULT $DC_OFF
}

led_off_all() {
	led_off $CH_R
	led_off $CH_G
	led_off $CH_B
}

#$1 = color $2 = bp
led_on() {
	BP=$2
	R_ON=`expr \( $1 / 1 \) % 2`
	G_ON=`expr \( $1 / 2 \) % 2`
	B_ON=`expr \( $1 / 4 \) % 2`

	if [ $R_ON -eq 1 ]; then
		led_ctrl $CH_R $CUR_ON $BP $DC_ON
	else
		led_off $CH_R
	fi

	if [ $G_ON -eq 1 ]; then
		led_ctrl $CH_G $CUR_ON $BP $DC_ON
	else
		led_off $CH_G
	fi

	if [ $B_ON -eq 1 ]; then
		led_ctrl $CH_B $CUR_ON $BP $DC_ON
	else
		led_off $CH_B
	fi
}

if [ "$1" = "OFF" ]; then
	led_off_all
else
	BP=$BP_DEFAULT
	if [ "$2" != "" ]; then
		BP=$2
	fi
	led_on $1 $BP
fi
