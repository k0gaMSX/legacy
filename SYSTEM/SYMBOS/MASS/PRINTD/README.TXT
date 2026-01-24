Printer Daemon v1.2 for SymbOS

By Edoz with help of Trebmint (Quigs Developer) and Prodatron (SymbOS Developer)

Welcome to the Printer Daemon for SymbOS! This daemon is designed to provide seamless and efficient printing capabilities for the SymbOS operating system, a multitasking OS for Z80-based computers.

The Printer Daemon allows users to print text from their SymbOS applications to a variety of supported printers. It supports device-independent printing, ensuring compatibility with different printer models and types.

Features

Efficient Spooling: Manage print jobs efficiently with a robust spooling system.
User-Friendly Interface: Easy to configure and use, with a straightforward setup process.
Standard Text-Based Printing: Based on ESC coding.

Requirements

SymbOS 4.0 or later
Minimum 256KB RAM

Files

README  .TXT		THIS TEXT FILE
PRINTD01.QS2		FILES NEED FOR THE DAEMON TO RUN
PRINTD02.QS2		FILES NEED FOR THE DAEMON TO RUN
PRINTD  .EXE		THE EXECUTABLE
PRINTD  .001		DO NOT DELETE THIS FILE. IT CONTAINS AS EXAMPLE AND TEST PRINT JOB
DRIVER* .DRV		PRINT DRIVER FILES
PRINTD  .INI		SETTING FILE WILL BE CREATED AFTER CONFIGURATION

Compatible printers (check the supported printer list)

Amstrad DMP-2xxx/3xxx
Standard ASCII Printing
Philips VW 0010 / Philips VW 0020 /Philips VW 0030
Philips NMS 1421 / Philips NMS 1431 / Philips NMS 1436
CANON T-22/A
Epson FX

Installation
Download the Printer Daemon package from the official SymbOS website.
Extract the contents to your SymbOS application directory (e.g., C:\SYMBOS\APPS\PRINTD\).
Create a spooler location on your system, by default this is empty but should be set to C:\SYMBOS\APPS\PRINTD\). This is where supported programs can dump their print jobs as .job files. The Printer Daemon will process all job files in this location.

Run the program to configure the daemon for your specific printer. The program will detect all printer driver files located in the application directory. If your printer is connected directly to your machine, select the correct driver for your printer and fill in the spooler location you created in the previous step. Printer options can be used for locally connected printers, but not for remote printers connected via TCP, except for the test page. If you want your printer to run as a network server printer, check the "Set as network server" option in the network tab of the onfiguration.

To connect your system to a network printer, check "Print to server IP" and fill in the IP number of your SymbOS machine that runs the Printer Daemon as a server. If you setup your daemon as a network printer client, you cannot print to your local printer anymore. Please not that also network client printers does need a spooler location.

Configuration

In the status tab, all logs will be shown and cleaned when they get too big.
On the driver tab, you can check "Hide to systray after startup" to minimize the Printer Daemon application after a reboot.

To start the Printer Daemon automatically after a restart, place the Printer Daemon in the autostart of the start menu (by changing the start menu items in the control panel of SymbOS). If you are running the Printer Daemon in combination with the network daemon, please ensure the network daemon is started first. Don't forget to save your settings in the startmenu configuration. To save the settings in the Printer Daemon, just press OK.
To close the Printer Daemon, close the form in the top right. To hide the form, press the OK button. This will always hide the form to the systray of SymbOS. Top open the Printer Daemon again click on the icon in the systray.

!Restart Printer Daemon to activate the Printer Daemon after changing driver, spooler or network settings!

Usage

Once installed, the Printer Daemon will automatically manage print jobs sent from SymbOS spoolers. You can access the daemon’s settings through the SymbOS systray panel to adjust printer preferences and manage the print queue.
Feel free to customize this introduction to better fit your specific implementation and features! If you need more details or have any questions, just let me know.

PrintCodes:

Below you find the list of supported printcodes. Grapical byte print is not supported at the moment but will be added in future.
After every print JOB the Print Daemon will clear the buffer and performs a reset to the printer by default. If you want to change the Feed or use differt fonts, like Elite / Condensed / ETC. it must be set for every printjob. The program that sends the printjob to the daemon should take care about word- wrapping. Almost every Matrix Printer supports only 80 characters per line. ESC(27) and printcode should be send without space as shown below but is to have a clear list.

ESC B	//BoldON
ESC b	//BoldOFF
ESC I	//ItalicON
ESC i	//ItalicOFF
ESC Q	//NearPrintingQualityON
ESC q	//NearPrintingQualityOFF
ESC W	//DoubleSizeON
ESC w	//DoubleSizeOFF
ESC U	//UnderlineON
ESC u	//OnderlineOFF
ESC D	//DoubleStrikeON
ESC d	//DoubleStrikeOFF
ESC 6	//Feed6Inch
ESC 9	//Feed9Inch
ESC R	//Reset
ESC C	//ClearBuffer
ESC X	//PICANormal
ESC Y	//Elite
ESC Z	//Condensed


Drivers

Here is shown how the driver is buidup:
First Character is the SymbOS print code (without ESC code in the driver)
Second character is the First code for each printer model, most of the TIME ESC(27)
Third  Character is the code for the printer model and could exits out of more character depending of the model.
-------------------------------------------------------------
Driver;Printername		Printername			
B;27;;CB			BoldON				
b;27;;Cb			BoldOFF			
I;27;;CI			ItalicON			
i;27;;Ci			ItalicOFF			
Q;27;;!				Near print quality ON		
q;27;"				Near print quality OFF		
W;14;				Double Size ON			
w;15;				Double Size OFF		
U;27;X				Underline ON			
u;27;Y				Underling OFF			
D;27;CD				Double strike			
d;27;Cd				Double strike			
6;27;A				Feed 6 Inch			
9;27;B				Feed 9 Inch			
R;27;@				Reset Printer			
C;24;				Clear Printer Buffer		
X;27;N				Type PICA / Normal		
Y;27;E				Type Elite			
Z;27;Q				Type CONDENSED		
END
---------------------------------------------------------
Building a New Driver

If you want to build a new driver, follow the example below:
Save the text file as printername.drv in the application directory.
Restart the daemon and select your new driver.

Driver Structure

The first character is the SymbOS print code.
The second code is the specific ESC code for the printer followed by the printerscode.SymbOS codes need to be escaped before the code in print job files but not in the driver file. printd.job file is the daemons test page and can be used to make your own printer job files for your application.

Example Driver

A driver should contain all SymbOS print codes. If the printer does not support a specific code, leave it blank. Do not mix the order of codes. Everything should be fixed in the driver; otherwise, the daemon cannot read the driver file.

Belows list is how a driver should look look. 
---------------------------
Driver;Philips NMS 1421
B;27;CB
b;27;Cb
I;27;CI
i;27;Ci
Q;27;!
q;27;"
W;14;
w;15;
U;27;X
u;27;Y
D;27;CD
d;27;Cd
6;27;A
9;27;B
R;27;@
C;24;
X;27;N
Y;27;E
Z;27;Q
END
---------------------------

I hope you will have fun connecting your old Matrix Printer again!

If you have created a new driver or need help or have suggestions please contact me: evanzanten@home.nl

Thanks to everyone that helped development for SymbOS. I hope it works and you have fun using it! Keep the 8-bit alive! Thanks

