#include <stdio.h>
#include <string.h>

int main(int argc,char **argv)
{
	char a;
	char fName[BUFSIZ];
	FILE *f;
	int nochange=0;
	char *typeName[10] = {
		"KONAMI(SCC)","ASCII 8K","ASCII 16K","","KONAMI","","","8000h","",""
	};

	
	strcpy(fName,argv[1]);
	if(strchr(fName,'.')==NULL) strcat(fName,".rom");
	if(argc==2) nochange=1;
	else if(argc!=3) {
		printf("Usage: chgmap <filename> <mappertype(0-9)>\n");
		printf("mappertype: 0:KOMAMI(SCC)\n");
		printf("            1:ASCII 8K\n");
		printf("            2:ASCII 16K\n");
		printf("            4:KOMAMI\n");
		printf("            7:8000h header\n");
		
		exit(0);
	}
	if((f=fopen(fName,"rb+"))==NULL) {
		printf("%s:ファイルが見つかりません。\n",fName);
		exit(0);
	}
	a=fgetc(f)-'A'; rewind(f);
	printf("%s:メガROMマッパタイプは%d:%sです。\n",fName,a,typeName[a]);
	if(!nochange) {
		a=argv[2][0]-'0';
		if(a<0 || a>9) {
			printf("%d:無効なメガROMマッパタイプです。\n",a);
			exit(0);
		}
		fputc(a+'A',f);
		printf("%s:メガROMマッパタイプを%d:%sに変更しました。\n",
			fName,a,typeName[a]);
	}
	close(f);
	return -1;
}
