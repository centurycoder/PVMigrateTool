#1. get old disk to remove
cd /tmp/RootMig3358_V2

od=`cat old_disk.lck`
cnt=`lspv|grep -w $od|grep -w None|wc -l`
if [ $cnt -eq 0 ]; then
echo "Old disk $od judged as in another VG, Manual Operation needed!"
exit -1
fi

SNstr=`odmget -q name="$od" CuAt|grep -p unique_id|grep value|sed -n 's/.*"\([^"]*\)".*/\1/p'`
cnt=`echo $SNstr|wc -c`
if [ $cnt -eq 51 ]; then
SN=`echo $SNstr|cut -b 9-10`
else
SN=`echo $SNstr|cut -b 28-29`
fi
if [ $SN != '58' ]; then
echo "Old disk $od SN is not 3358, Manual Operation needed!"
exit -1
fi


#2. remove action
rmdev -dl $od
cnt=`lsdev -c disk|grep 'Virtual SCSI'|grep -w $od|wc -l`
if [ $cnt -ne 0 ]; then
echo "rmdev for $od failed, Manual Operation needed!"
exit -1
fi
echo "$od removed successfully"
