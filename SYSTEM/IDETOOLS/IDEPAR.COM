� <2�!� ~� 	������ͱڶ�!8��/(c�08��:8/�A8��I8�a8��i0����@2�ͱ8h�=(��: �ͱ8[�=(���0Oͱ8� (�08��:0��0Gy�O�����0�O�y2�8+�ͱ8����M(�S�y2�ͱ8�!��#~��o� x�8�K���  z2�:�=!!��8,,����:B�&@�$  � 	� �2�,~�&@�$ �!�~�I �,~�D �,~�# �x����7�Ox���O !	�	^,V�S�:����o& "�:�� ~�<2��3o& ~O� ���:�=�A ��Y(�a �O:��y(����*��� n(����w ��w�w�w�w�w�w�6��� f��*�~! �   ͉0�(5��:�  ! ����@��*�:���U o:���� h:�G��!�������~ �~ J�~ݶݶݶ V���~�w�~	�w�~
�w�~��w�~� �w�~� �w�~ ���w��:�� : ���(r����w�w�w*�+�u�t�w>��w��j        
IDEPAR version #4.0 - Aug. 3, 1999 / JDS
Partition changer for the Sunrise MSX ATA-IDE interface

Usage: IDEPAR idedrive[:]=partition [/M or /S]

Defaults: idedrive : current drive
          partition: 0
          device   : same (master/slave) as the idedrive

Examples:
IDEPAR 10     :engage partition 10 on the current drive
IDEPAR B:=5   :engage partition 5 on drive B:
IDEPAR C=2 /S :engage partition 2 of slave device on drive C:
IDEPAR C: /M  :engage partition 0 of master device on drive C:
$Commandline parameter error!
$Not an IDE drive!
$Device not connected!
$Partition not present on CDROM!
$Can't change partition! (locked by external program)
$Error reading partition table!
$Partition does not exist!
$Invalid partition number or table!
$