#!/bin/sh

sync

PRODUCT=`/bin/kobo_config.sh`;
[ $PRODUCT != trilogy ] && PREFIX=$PRODUCT-

zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
sleep 3

# Start Boot Sequense
/etc/init.d/on-animator.sh &

# ���̐������uboot.mng�v��\�����鎞�Ԃł��B
sleep 5

IsClear="ON"

# Stop Boot Sequence
killall on-animator.sh

# DB�X�V�O��ŉ�ʂ��������邩�ǂ����̔���
if [ -f ${ThemeConfig} ]; then
	source $ThemeConfig

	IsClear=$ClearDisplayDbUpdate
fi

# dbUpdate�\���O�ɉ�ʂ�^�����ɂ���
if [ "$IsClear" == "ON" ]; then
	zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
fi

# Start DBUpdate Sequence
/etc/init.d/dbupdate-animator.sh &

# ���̐������udbUpdate.mng�v��\�����鎞�Ԃł��B
sleep 10

# Stop DbUpdate Sequence
killall dbupdate-animator.sh

# dbUpdate�\����ɉ�ʂ�^�����ɂ���
if [ "$IsClear" == "ON" ]; then
	zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
fi

IsClear="ON"

# DB�č\�z�O��ŉ�ʂ��������邩�ǂ����̔���
if [ -f ${ThemeConfig} ]; then
	source $ThemeConfig

	IsClear=$ClearDisplayDbRebuild
fi

# dbRebuild�\���O�ɉ�ʂ�^�����ɂ���
if [ "$IsClear" == "ON" ]; then
	zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
fi

# Start DBRebuild Sequence
/etc/init.d/rebuild-animator.sh &

# ���̐������udbRebuild.mng�v��\�����鎞�Ԃł��B
sleep 10

# Stop DbRebuild Sequence
killall rebuild-animator.sh

# dbRebuild�\����ɉ�ʂ�^�����ɂ���
if [ "$IsClear" == "ON" ]; then
	zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
fi

# Restart Boot Sequence

/etc/init.d/on-animator.sh &

# �����Ŗ{���ł���΃z�[����ʂɑJ�ڂ��܂�
sleep 5
killall on-animator.sh

# Start Kobo Update Sequence
zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
/etc/init.d/update-animator.sh &

sleep 5

# Stop Kobo Update Sequence
killall update-animator.sh
zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic

# Reboot Sequence
if [ -f /mnt/onboard/.images/rebooting.png ]; then
	/opt/cfw/bin/png2raw-12 -K -ta /mnt/onboard/.images/rebooting.png
else
	zcat /etc/images/$PREFIX\reboot.raw.gz | /usr/local/Kobo/pickel showpic
fi

sleep 5

# �I���B��ʂ�^�����ɕύX
zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
