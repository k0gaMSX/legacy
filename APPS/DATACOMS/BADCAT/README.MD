# BaDCaT Wifi modem
-----------------
BaDCaT, is a WiFi modem to connect our MSX computers to the Internet. The main goal was to reduce Z80 CPU load as much as possible with the addition of external hardware in the same cartridge for TCP/IP processing. On the other hand to be able to work on MSX1 computers even with low RAM. All this process is carried out 
by an ESP8266 integrated circuit, specifically the ESP12 version with 4MB of flash memory.

The cartridge consists of an UART 16C550C which implements an RS232 port as interface between espressif ESP8266 network processor and the MSX bus. 
It also provides an standard serial port to the MSX. In short, we could say that this cartridge features two working modes:

    * MSX1: both the TCP/IP stack and telnet client run on the cartridge. The computer would only run a terminal program.
    * MSX2 and higher: the TCP/IP stack runs on cartridge and telnet client on the MSX. To do this, the ducasp's telnet version has been modified 
    in order to offer the same functionality with the WiFi modem and UNAPI interfaces. This telnet version is already available on ducasp's Github.

# Technical specifications:

    * MSX1/MSX2 (and higher) compatible.

    * RS232 Serial port up to 115200 bps.

    * RTS/CTS flow control.

    * Fossil driver compatible (without any modification).

    * ESP12 modem based on zimodem, effective speed of 57600 bps.

    * Ducasp's telnet compatible and with all its functionalities (fast ANSI decoding, file downloading...)

    * Possibility of running telnet client on the cartridge itself.

    * OTA Upgradable firmware.

    * Experimental feature: loading roms up to 48KB (thanks to Armando Pérez!)

    * UNAPI firmware/driver available (only for AFE/SMD version) and MSX2
    
## WARNING!: do not change FLOW option in the configuration menu unless you are completely sure of what you are doing! Making this permanent could cause malfunction of the BaDCaT!!

![alt text](https://github.com/andortizg/BaDCaT/blob/master/badcats.jpg?raw=true)


# Disclaimer


Copyright © (2020) Andrés Ortiz. All rights reserved. Redistribution without modification only for personal use is permitted, provided that the following conditions are met:

Redistributions of schematics and gerber files must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in PCB form must reproduce the copyright text, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THE HARDWARE IS PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS HARDWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
