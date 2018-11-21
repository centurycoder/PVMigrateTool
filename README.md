# PVMigrateTool
Shell scripts to migrate data storage for AIX LVMs.

NPIVMig：
	If your storage array is mapped to AIX LPARs using NPIV, and your VG is LVM mirrored , then this script can be used to migrate data from one storage to another.

vSCSIMig:
	If rootvg of your LPAR is vSCSI device, and you want to change underline storage, then this script can be used.