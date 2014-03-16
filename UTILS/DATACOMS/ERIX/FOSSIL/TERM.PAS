PROGRAM DEMO_RSdriver;

{	This small demonstration program is provided as-is.	}
{	There is no guarantee or whatever that ensures this	}
{	program will work.					}
{								}
{	For information you could try to sent an email to:	}
{			erikmaas@wish.net			}
{			erik.maas@tip.nl			}

{$I FOSLIB.INC}
{
PROCEDURE ChPut (Ch:char);
FUNCTION ToetsDruk:boolean;
FUNCTION ScanKey:char;
FUNCTION TestDriver:boolean;
PROCEDURE Fossil (FosFunc:byte);
PROCEDURE SendString (MyString:Str80);
PROCEDURE InitRS232;
PROCEDURE DeInitRS232;
PROCEDURE SendChar (karakter:Char);
PROCEDURE SendByte (mybyte:byte);
FUNCTION RXready:boolean;
FUNCTION RecByte:byte;
FUNCTION RecChar:char;
PROCEDURE Hook_ChPut (on,echo:boolean);
PROCEDURE Hook_KeyBoard (on:boolean);
PROCEDURE Set_Speed (rx,tx:byte);
PROCEDURE SendCRLF;
}

VAR Toets:char;

BEGIN
     IF TestDriver=TRUE THEN
     BEGIN
          Write(char(12));
          Set_Speed (6,6); {9600 baud}
          InitRS232;
          Toets:=char(0);
          REPEAT
                IF ToetsDruk=TRUE THEN
                BEGIN
                     Toets:=ScanKey;
                     SendChar(Toets);
                END;
                IF RXready THEN ChPut (RecChar);
          UNTIL Toets=char(27);
          DeInitRS232;

          Write(char(12));
     END
     ELSE WriteLn ('*** RS232 driver not found!',char(7));

END.

