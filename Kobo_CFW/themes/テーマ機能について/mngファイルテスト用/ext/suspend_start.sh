#!/bin/sh

sync

PRODUCT=`/bin/kobo_config.sh`;
[ $PRODUCT != trilogy ] && PREFIX=$PRODUCT-

zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
sleep 3

# Start Boot Sequense
/etc/init.d/on-animator.sh &

# 下の数字が「boot.mng」を表示する時間です。
sleep 5

IsClear="ON"

# Stop Boot Sequence
killall on-animator.sh

# DB更新前後で画面を消去するかどうかの判定
if [ -f ${ThemeConfig} ]; then
	source $ThemeConfig

	IsClear=$ClearDisplayDbUpdate
fi

# dbUpdate表示前に画面を真っ白にする
if [ "$IsClear" == "ON" ]; then
	zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
fi

# Start DBUpdate Sequence
/etc/init.d/dbupdate-animator.sh &

# 下の数字が「dbUpdate.mng」を表示する時間です。
sleep 10

# Stop DbUpdate Sequence
killall dbupdate-animator.sh

# dbUpdate表示後に画面を真っ白にする
if [ "$IsClear" == "ON" ]; then
	zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
fi

IsClear="ON"

# DB再構築前後で画面を消去するかどうかの判定
if [ -f ${ThemeConfig} ]; then
	source $ThemeConfig

	IsClear=$ClearDisplayDbRebuild
fi

# dbRebuild表示前に画面を真っ白にする
if [ "$IsClear" == "ON" ]; then
	zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
fi

# Start DBRebuild Sequence
/etc/init.d/rebuild-animator.sh &

# 下の数字が「dbRebuild.mng」を表示する時間です。
sleep 10

# Stop DbRebuild Sequence
killall rebuild-animator.sh

# dbRebuild表示後に画面を真っ白にする
if [ "$IsClear" == "ON" ]; then
	zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
fi

# Restart Boot Sequence

/etc/init.d/on-animator.sh &

# ここで本来であればホーム画面に遷移します
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

# 終了。画面を真っ白に変更
zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
