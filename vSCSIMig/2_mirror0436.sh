
#1. 获取rootvg的基本信息，判断确认它没有单份镜像跨多块盘的情况：
#2. 获取新的3358盘，按照顺序它有以下几个特征：1) vSCSI 2）LUNID=82 3)不在rootvg中

#0. 防范那些有多块盘的问题
cd /tmp/RootMig3358_V2

cnt=`lsvg -p rootvg|grep active|wc -l`
if [ $cnt -ne 1 ]; then
echo "More than 1 disks are found in rootvg, Manual Operation needed!"
exit -1
fi

#1. cfgmgr to find 0436 disk
nd="ERROR"
lsdev -c disk|grep 'Virtual SCSI'|awk '{print $1}'|sort >disksBefore
cfgmgr -l vscsi0; cfgmgr -l vscsi1;
lsdev -c disk|grep 'Virtual SCSI'|awk '{print $1}'|sort >disksAfter
cnt=`diff disksBefore disksAfter|grep '>'|wc -l`
if [ $cnt -ne 1 ]; then
echo "More than 2 new disks are found, Manual Operation needed!"
exit -1
fi
nd=`diff disksBefore disksAfter|grep '>'|awk '{print $2}'`
echo "New disk is: $nd"

#2. make sure disk storage serail is 0436，and not belongs to any VG:
SNstr=`odmget -q name="$nd" CuAt|grep -p unique_id|grep value|sed -n 's/.*"\([^"]*\)".*/\1/p'`
cnt=`echo $SNstr|wc -c`
if [ $cnt -eq 51 ]; then
SN=`echo $SNstr|cut -b 9-10`
else
SN=`echo $SNstr|cut -b 28-29`
fi
if [ $SN != '36' ]; then
echo "Serial Number for new disk not correct, Manual Operation needed!"
exit -1
fi
cnt=`lspv|grep -w $nd|grep -w None|wc -l`
if [ $cnt -eq 0 ]; then
echo "Disk already in another VG, Manual Operation needed!"
exit -1
fi

#3. extend new disk to rootvg
chdev -l $nd -a hcheck_interval=60
extendvg rootvg $nd
cnt=`lsvg -p rootvg|grep -w "$nd"|wc -l`
if [ $cnt -eq 0 ]; then
echo "Failed to extend $nd to rootvg, Manual Operation needed!"
exit -1
fi
echo "Extend rootvg with $nd successfully"

#4. make rootvg mirror
mirrorvg -S rootvg $nd
pvcnt=`lsvg -l rootvg|grep -w '/tmp'|awk '{print $5}'`
if [ $pvcnt -ne 2 ]; then
echo "Failed to mirrovg with $nd, Manual Operation needed!"
exit -1
fi
echo "Mirrorvg with $nd successfully"

#5. bootlist
bosboot -ad $nd
lsvg -p rootvg|grep active|awk '{print $1}'|xargs echo|xargs bootlist -m normal
bootlist -m normal -o
echo "Root mig for this LPAR finished successfully"

