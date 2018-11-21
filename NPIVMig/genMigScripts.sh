oldSN=$1
newSN=$2

if [ -z "$oldSN" -o -z "$newSN" ]; then
oldSN=3358
newSN=0436
fi

mkdir /tmp/DataMig3358
cd /tmp/DataMig3358

./getlun.sh >getlun.txt

echo "1. Determine which VG to deal"
vgs=`cat getlun.txt|grep DMX| awk '$2 ~ /'$oldSN'/{print}'|grep -v caavg_private|grep -v hb|awk '{print $(NF-1)}'|sort -u|grep -v '-'|xargs echo`
echo "About to migrating vgs: $vgs"

for vg in `echo "$vgs"`; do
	# get all target PV for all vg, each a file
	echo "2. Generating rmmirror and rmpv script for vg: $vg ..."
	>oldPV_$vg.txt
	for i in `cat getlun.txt|grep DMX|grep -w $vg| awk '$2 ~ /'$oldSN'/{print}'|sed -n -e "s/.*\(hdiskpower[0-9]*\).*/\1/p"`; do 
	size=`bootinfo -s $i`;
	if [ $size -gt 100000 ]; then
		echo $i >>oldPV_$vg.txt
	fi
	done
	# generate unmirror command for all vg, each a file
	
	pvs=`cat oldPV_$vg.txt|xargs echo`
	echo "/usr/es/sbin/cluster/cspoc/cli_unmirrorvg '$vg' '$pvs'" > 1_rmmirror_$vg.sh
	echo "/usr/es/sbin/cluster/cspoc/cli_reducevg '$vg' '$pvs'" > 2_rmpv_$vg.sh
	chmod +x 1_rmmirror_$vg.sh 2_rmpv_$vg.sh
done


#generate script for adding new disk
echo "1. Check if disk for $newSN is ready"
lc=`cat getlun.txt|grep DMX| awk '$2 ~ /'$newSN'/{print}'|wc -l`
if [ $lc -eq 0 ]; then
	echo "Disk for $newSN not found, about to run cfgmgr!"
	cfgmgr -l fscsi0;cfgmgr -l fscsi1;cfgmgr -l fscsi2;cfgmgr -l fscsi3;powermt config;powermt save;powermt display
fi

echo "2. Check if $newSN disk attr is no_reserve"
for i in `cat getlun.txt|grep DMX|awk '$2 ~ /'$newSN'/{print}'|sed -n -e "s/.*\(hdiskpower[0-9]*\).*/\1/p"`; do 
	lc=`lsattr -El $i|grep reserve|grep -E -w "no|no_reserve"|wc -l`
	if [ $lc -eq 0 ]; then
		echo "\n\n\t!!!!! Disk for $newSN attr is not correct, the script will exit, please run '/usr/lpp/EMC/Symmetrix/bin/emc_reserve_v2.sh',5,1 manually!\n\n"
		exit
	fi 
done

echo "3. generate candidate PVs..."
lspv >lspv.txt
>newPVAll.txt
for i in `cat getlun.txt|grep DMX|awk '$2 ~ /'$newSN'/{print}'|sort -k 3|sed -n -e "s/.*\(hdiskpower[0-9]*\).*/\1/p"`; do 
	size=`bootinfo -s $i`;
	lc=`cat lspv.txt|grep -w $i|awk '{print $3}'|grep 'None'|wc -l`
	if [ $size -gt 100000 -a $lc -ne 0 ]; then
		echo $i >>newPVAll.txt
	fi
done

start=1
for vg in `echo "$vgs"`; do
	cnt=`cat oldPV_$vg.txt|wc -l`
	let end=start+cnt-1
	cat newPVAll.txt|sed -n "${start},${end}p" >newPV_$vg.txt
	let start=end+1
	
	newcnt=`cat newPV_$vg.txt|wc -l`
	if [ $newcnt -ne $cnt ]; then
		echo "Disk is not enough, exiting..."
		exit
	fi
	
	>3_mkpv_$vg.sh
	for i in `cat newPV_$vg.txt`; do
		echo "chdev -a pv=yes -l $i" >>3_mkpv_$vg.sh
	done
	chmod +x 3_mkpv_$vg.sh
	
	pvs=`cat newPV_$vg.txt|xargs echo`
	echo "# !!! !!! Make Sure PVID is ok on standby !!!" > 4_mkmirror_$vg.sh
	echo "/usr/es/sbin/cluster/cspoc/cli_extendvg '$vg' '$pvs'" >> 4_mkmirror_$vg.sh
	echo "/usr/es/sbin/cluster/cspoc/cli_mirrorvg -c '2' -S '$vg' '$pvs'" >> 4_mkmirror_$vg.sh
	chmod +x 4_mkmirror_$vg.sh
done

