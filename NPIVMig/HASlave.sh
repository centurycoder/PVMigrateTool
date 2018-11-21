oldSN=$1
if [ -z "$oldSN" ]; then
	oldSN = 0436
fi

echo "1. Check if disk for $oldSN is ready"
lc=`getlun.sh|grep $oldSN|wc -l`
if [ $lc -eq 0 ]; then
echo "Disk for $oldSN not found, about to run cfgmgr!"
cfgmgr -l fscsi0;cfgmgr -l fscsi1;cfgmgr -l fscsi2;cfgmgr -l fscsi3;powermt config;powermt save;powermt display
fi


echo "2. Check if $oldSN disk attr is no_reserve"
for i in `getlun.sh|grep $oldSN|sed -n -e "s/.*\(hdiskpower[0-9]*\).*/\1/p"`; do 
lc=`lsattr -El $i|grep reserve|grep -E -w "no|no_reserve"|wc -l`
if [ $lc -eq 0 ]; then
echo "\n\n\t!!!!! Disk for $oldSN attr is not correct, the script will exit, please run '/usr/lpp/EMC/Symmetrix/bin/emc_reserve_v2.sh',5,1 manually!\n\n"
exit
fi 
done

echo "2. cfgmgr to read PVID set on primary node"
echo "OK to run cfgmgr for $oldSN hdiskpowerX devices? (yes/no)"
read answer
if [ $answer = "yes" ]; then
echo "About to run cfgmgr for $oldSN hdiskpowerX devices:"
for i in `getlun.sh|grep $oldSN|sed -n -e "s/.*\(hdiskpower[0-9]*\).*/\1/p"`; do 
cfgmgr -l $i
done
fi
