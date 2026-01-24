# UNAPI driver for BaDCaT wifi modem (Only for AFE/SMD version and MSX2 computers!)
Based on the work of Alexander Nihirash ( @nihirash ) and his Nifi firmware

- bdcfg : Configuration and firmware utility
- bcunapi : UNAPI driver. Once loaded, you can use BaDCaT wifi modem as standard UNAPI network interface

# How to use:

1. Run dbcfg to setup your AP (option 1).
2. Only for Nextor <2.11 : it is necessary to load ramhelpr: ramhelpr i
3. Run bcunapi unapi driver to load it into RAM
4. Now you can use UNAPI applications!
  
***I strongly recommend to use the VERY nice MSX-HUB tool (or HUBG graphical interface) from ducaSP to install programs.***

  
# Limitations

- Passive TCP not yet implemented. FTP based on passive connections is not working.
- ICMP not yet implemented. PING command is not working.
- Experimental functionality of ROM loading from BaDCaT does not work with the UNAPI firmware


# Update procedure

## From non-unapi version: 
***Be sure that you have the SMD/AFE version before updating. Otherwise, you will brick your BaDCaT!. You can check it using the bdcfg tool.***
**Ensure you have good WiFi signal !

1. In AT+CONFIG menu, use the the repository <badcatrepo.ddns.net>  -> [REPO] option
2. In command mode: at&u=2.0
3. Wait for BaDCaT reboot

## From unapi version:
1. Use bdcfg tool, option 2 to download the file badcat-2.0.bin from the repository: http://badcatrepo.ddns.net
(or file badcat-1.5.bin if you can return to the non-unapi version).
3. Use option 3 to write the flash with the new firmware.


### If you like to improve the firmware/driver or to add new features, contact me!
badcatelectronics@gmail.com

