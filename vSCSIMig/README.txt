#############################################################################################
###########################VIOS操作 2018.4.10#################################
#############################################################################################

#1. 获取VIOS里磁盘对应关系
mkdir /tmp/RootMig3358_V2 2>/dev/null
cd /tmp/RootMig3358_V2
# ftp hereis code to get getlun.sh, this is an internal script

./getlun.sh >getlun.txt
lscfg|grep vhost|sort -k3|awk '{print $2,$3}'|sed 's/U.*-C1//'|sort -nk 2 >vhost.txt
>diskmap.txt
cat vhost.txt| while read line; do
echo $line|read vh cid
#backup devices
bd=`cat getlun.txt|grep DMX|grep -w $vh|awk '{print $2}'|xargs echo`
echo "$cid $vh\t$bd" >>diskmap.txt
done
cat diskmap.txt


#2. 生成制作map的脚本 2018.4.10

cd /tmp/RootMig3358_V2
cat getlun.txt|grep -w 0436|grep hdiskpower|sort -k 3|awk '{print $4}' >disk_0436.txt
# Special Processing, allocate as 3358 disk mappings
cat getlun.txt|grep -w 3358|grep hdiskpower|grep vhost|sort -nk 7|awk '{print $(NF-1), $NF}'|uniq>vhost.txt

paste disk_0436.txt vhost.txt >mappings.txt
>mkmap_0436.sh
#check mappings.txt first
cat mappings.txt | while read line; do
echo $line|read d v i
echo "/usr/ios/cli/ioscli mkvdev -vdev $d -vadapter $v -dev r0436_lpar$i" >>mkmap_0436.sh
done
chmod +x mkmap_0436.sh
cat mkmap_0436.sh



#3. 检查映射后的diskmap
cd /tmp/RootMig3358_V2
./getlun.sh >getlun.txt
lscfg|grep vhost|sort -k3|awk '{print $2,$3}'|sed 's/U.*-C1//'|sort -nk 2 >vhost.txt
>diskmap.txt
cat vhost.txt| while read line; do
echo $line|read vh cid
#backup devices
bd=`cat getlun.txt|grep DMX|grep -w $vh|awk '{print $2}'|xargs echo`
echo "$cid $vh\t$bd" >>diskmap.txt
done
cat diskmap.txt


#############################################################################################
###########################VIOC操作 2018.4.10#################################
#############################################################################################

clear;for i in `lsdev -c disk|grep 'Virtual SCSI'|awk '{print $1}'`; do
SNstr=`odmget -q name="$i" CuAt|grep -p unique_id|grep value|sed -n 's/.*"\([^"]*\)".*/\1/p'`
cnt=`echo $SNstr|wc -c`
if [ $cnt -eq 51 ]; then
SN=`echo $SNstr|cut -b 9-10`
else
SN=`echo $SNstr|cut -b 28-29`
fi
echo $i $SN
done

mkdir /tmp/RootMig3358_V2 2>/dev/null
cd /tmp/RootMig3358_V2
ftp -i -n 10.3.178.49 <<!
get 1_unmirror3358.sh
get 2_mirror0436.sh
get 3_rm3358.sh
bye
!
chmod +x 1_unmirror3358.sh 2_mirror0436.sh 3_rm3358.sh


./1_unmirror3358.sh 
./2_mirror0436.sh
./3_rm3358.sh
#CONFIGURATION MISMATCH的errpt，用如下命令处理
errclear -j DF8A44B0 0

#检查3358磁盘已经不存在
clear;for i in `lsdev -c disk|grep 'Virtual SCSI'|awk '{print $1}'`; do
SNstr=`odmget -q name="$i" CuAt|grep -p unique_id|grep value|sed -n 's/.*"\([^"]*\)".*/\1/p'`
cnt=`echo $SNstr|wc -c`
if [ $cnt -eq 51 ]; then
SN=`echo $SNstr|cut -b 9-10`
else
SN=`echo $SNstr|cut -b 28-29`
fi
echo $i $SN
done

#############################################################################################
###########################VIOS删除映射操作 2018.4.10#################################
#############################################################################################
cd /tmp/RootMig3358_V2
cat getlun.txt
>unmap.sh
for disk in `cat getlun.txt|grep -w 0267|grep vhost|sort -nk 7|awk '{print $4}'`; do
echo "/usr/ios/cli/ioscli rmvdev -vdev $disk" >>unmap.sh
done
chmod +x unmap.sh
cat unmap.sh
