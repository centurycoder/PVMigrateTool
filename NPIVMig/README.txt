#HA����step 1
clear
hstname=`hostname`
cnt=`clstat -o|grep -p 'Resource Group'|grep 'Node:'|grep $hstname|wc -l`
if [ $cnt -ne 0 ]; then
./genScripts.sh
fi
ls -l

#HA����step 2
hstname=`hostname`
cnt=`clstat -o|grep -p 'Resource Group'|grep 'Node:'|grep $hstname|wc -l`
if [ $cnt -ne 0 ]; then
./1_rmmirror*.sh
./2_rmpv*.sh
./3_mkpv*.sh
fi


#HA����step
hstname=`hostname`
cnt=`clstat -o|grep -p 'Resource Group'|grep 'Node:'|grep $hstname|wc -l`
if [ $cnt -eq 0 ]; then
./syncSlave.sh
fi

#HA����step 3
hstname=`hostname`
cnt=`clstat -o|grep -p 'Resource Group'|grep 'Node:'|grep $hstname|wc -l`
if [ $cnt -ne 0 ]; then
./4_mkmirror*.sh
fi

#HA����check
clear
hstname=`hostname`
cnt=`clstat -o|grep -p 'Resource Group'|grep 'Node:'|grep $hstname|wc -l`
if [ $cnt -eq 0 ]; then
./getlun.sh
lsvg|grep -v caavg|grep -v rootvg|xargs lsvg -l 
fi
