# run the EXE you did download to download an ISO media
# [/Mediapath=***] ⇒ target folder to download

SQL2019-SSEI-Eval.exe /Action=Download /Mediatype=ISO /Language=en-EN /Mediapath=C:\Users\Administrator /Verbose /Quiet 

# language might need to be changed to en or EN only

Mount-DiskImage C:\Users\Administrator\SQLServer2019-x64-ENU.iso
# Mount the disk image

Get-Volume
# confirm where drive ISO mounted

cd D:\
# replace D with the drive letter assoicated with the mounted ISO

ls
