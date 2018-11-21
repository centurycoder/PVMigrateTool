#1. Find disk for VMAX3358£º
mkdir /tmp/RootMig3358_V2 2>/dev/null
cd /tmp/RootMig3358_V2
od="ERROR"
for i in `lsdev -c disk|grep 'Virtual SCSI'|awk '{print $1}'`; do
SNstr=`odmget -q name="$i" CuAt|grep -p unique_id|grep value|sed -n 's/.*"\([^"]*\)".*/\1/p'`
cnt=`echo $SNstr|wc -c`
if [ $cnt -eq 51 ]; then
SN=`echo $SNstr|cut -b 9-10`
else
SN=`echo $SNstr|cut -b 28-29`
fi
if [ $SN == '58' ]; then
od=$i
fi
done
echo "Old disk is: $od"

#2. ensure belongs to rootvg
cnt=`lsvg -p rootvg|grep -w $od|wc -l`
if [ $cnt -ne 1 ]; then
echo "$od not in rootvg, Manual Operation needed!"
exit -1
fi

#3. unmirrorvg
unmirrorvg rootvg $od
lsvg -p rootvg|grep -w $od|awk '{print $3,$4}'|read totalpp freepp
if [ $totalpp -ne $freepp ]; then
	td=`lsvg -p rootvg|grep active|grep -vw "$od"|awk '{print $1}`
	cnt=`lspv -M hdisk0|grep lg_dumplv|wc -l`
	if [ $cnt -ne 0 ]; then # lgdump_problem, migrate to other disk
		echo "About to migrate lg_dumplv from $od to $td ..."
		migratepv -l lg_dumplv $od $td
		lsvg -p rootvg|grep -w $od|awk '{print $3,$4}'|read totalpp freepp
		if [ $totalpp -ne $freepp ]; then
			echo "Unmirror rootvg failed, Manual Operation needed!"
			exit -1
		fi
	fi
fi
echo "$od unmirrored from rootvg successfully"

#4. if unmirror succ£¬then reduce from rootvg
reducevg rootvg $od
cnt=`lsvg -p rootvg|grep -w $od|wc -l`
if [ $cnt -ne 0 ]; then
echo "Reduce rootvg failed, Manual Operation needed!"
exit -1
fi
echo "$od reduced from rootvg successfully"

#5. write old disk name to file£¬for step 3 use
echo "$od" >old_disk.lck
