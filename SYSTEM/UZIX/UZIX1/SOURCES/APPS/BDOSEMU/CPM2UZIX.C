/* CPM2UZIX
 * Create a UZIX application from a CPM application using UZIX BDOSemu
 * by A&L Software 1999 <adrcunha@yahoo.com.br>
 *
 * This program is released under GNU GPL license.
 */

#include <stdio.h>
#include <string.h>
#include <io.h>

#define BDOSEMU		"bdosemu.com"
#define BE_SIG		"MOMBASSA"
#define SIGSIZE		8

void main() {
	char cpmprg[40], uzxprg[40], buffer[512], buff[SIGSIZE+1], *p;
	FILE *prgin, *prgemu, *prgout;
	int i,j;
	long sizef, entryp, emusize, cnt;
	unsigned int spacef;

	printf("CPMtoUZIX\nby A&L Soft 1999\n\n");
	printf("CPM program to convert: ");
	scanf("%s",cpmprg);
	printf("Wait, please...\n");
	prgemu = fopen(BDOSEMU, "rb");
	if (prgemu == NULL) {
		printf("Can't open " BDOSEMU ".\n");
		return;
	}
	spacef = 0;
	fseek(prgemu, 0, SEEK_END);
	emusize = ftell(prgemu);
	for (i = 0; i<0x1000; i++) {
		fseek(prgemu, i, SEEK_SET);
		if (fgets(buff, SIGSIZE+1, prgemu) == NULL) {
			printf(BDOSEMU " is corrupted.\n");
			fclose(prgemu);
			return;
		}
		if (!strcmp(buff, BE_SIG)) {
			entryp = i;
			fseek(prgemu, i+SIGSIZE, SEEK_SET);
			fgets(buff, 3, prgemu);
			spacef=buff[0]+256*buff[1];
			break;
		}
	}
	if (spacef == 0) {
		printf(BDOSEMU " is corrupted.\n");
		fclose(prgemu);
		return;
	}
	prgin = fopen(cpmprg, "rb");
	if (prgin == NULL) {
		printf("Error opening CPM program.\n");
		return;
	}
	fseek(prgin, 0, SEEK_END);
	sizef = ftell(prgin);
	if (sizef > spacef) {
		printf("CPM program is too big (max %d bytes).\n",spacef);
		fclose(prgemu);
		fclose(prgin);
		return;
	}
	p = strrchr(cpmprg, '.');
	if (p == NULL)
		strcpy(uzxprg, cpmprg);
	else {
		strncpy(uzxprg, cpmprg, (p-cpmprg));
		uzxprg[p-cpmprg]=0;
	}
	prgout = fopen(uzxprg, "wb+");
	if (prgout == NULL) {
		printf("Error creating UZIX program %s.\n", uzxprg);
		fclose(prgin);
		fclose(prgemu);
		return;
	}
	cnt = 0;
	fseek(prgemu, 0, SEEK_SET);
	fseek(prgout, 0, SEEK_SET);
	while (cnt != emusize) {
		i = read(fileno(prgemu), buffer, 512);
		if (write(fileno(prgout), buffer, i) != i) {
			fclose(prgin);
			fclose(prgout);
			fclose(prgemu);
			printf("Error initializing UZIX program.\n");
			return;
		}
		fflush(prgout);
		cnt += i;
	}
	fseek(prgout, entryp, SEEK_SET);
	fseek(prgin, 0, SEEK_SET);
	cnt = 0;
	while (cnt != sizef) {
		i = read(fileno(prgin), buffer, 512);
		if (write(fileno(prgout), buffer, i) != i) {
			fclose(prgin);
			fclose(prgout);
			fclose(prgemu);
			printf("Error finishing UZIX program.\n");
			return;
		}
		fflush(prgout);
		cnt += i;
	}
	fclose(prgin);
	fclose(prgout);
	fclose(prgemu);
	printf("UZIX program %s created.\n", uzxprg);
}