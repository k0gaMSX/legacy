Õ
_/_/_/_/_/_/    COPY720 v1.0 Disk to Image & Image to Disk     _/_/_/_/_/_/
_/_/_/_/_/             Copyright 2000  by  JAM Soft              _/_/_/_/_/

$
Usage:


    COPY720 <drive:> <pathname>   ---> Creates disk image file from diskette

    COPY720 <pathname> <drive:>   ---> Dumps disk image file onto diskette


    EXAMPLES:

    COPY720 A: GAME.DSK               Dumps A: drive onto GAME.DSK file
    COPY720 G: C:\DISKS\DISK_1.DSK    Dumps G: drive onto DISK_1.DSK in C:\DISKS

    COPY720 DUMP.DAT B:               Writes DUMP.DAT onto floppy B:
    COPY720 F:DEMO.720 H:             Writes DEMO.720 in F: onto floppy H:


$o� x���	� ���� :��� ͈D�[�� � ���x2�,	� *�T]:�o&`/�� ��I:�G�! �� �*�` "�>oӘ�:�GE� 7	� ��%�[�@ �!�� ����[�C�� ���x2�,	� !  "��>oӘ:�GH�! �� ����*�T]:�o&`0�� ��¤*�` "��:�GE� 7	� �	��� 
Error writing disk.
$�	� �  !� ~�(�#���T] [� �8	��"����"�� [� �w#��>2��~�(�� �#�~�A˯2��/:�o&  � :����i��������� :��A2h	b� � V� �Y��y�����>�2�!�"�! "�0:�o&  � :�<_� �~����	� �  Single sided disk!! Use COPY360.COM instead

$�w ���>$w�	� 	� *���T	� E	� *���7	� �Ooops. DOS2 is required!
$Progress: $
Finished.
$Error writing $ not found!
$Drive  : doesn't seem to be a floppy. Continue anyway (y,N)?
$       