#include <stdio.h>
#include <string.h>

#define SKIPSPACE(p) while(*p==' '||*p=='\t') p++;

/* #define DEBUG */

struct sAlias {
	char *name;
	char *body;
} *alias;
int aliasMax=0;

struct sMacro {
	char *name;
	char *body;
	int argc;
} *macro;
int macroMax=0;

char *margv[] = { "%%0","%%1","%%2","%%3","%%4","%%5" };
char *directive[] = {
	".macro",".MACRO",".alias",".ALIAS",".include",".INCLUDE"
};
int directiveMax = 6;

char *bufferTail=NULL;
FILE *iFile = stdin;
FILE *oFile = stdout;

int processCalled = 0;
int processLine = 0;
char *processFile = "        .   ";

int prErr(char *);
char *strchg(char *,const char *,const char *);
int ExtractAlias(char *);
int ExtractMacro(char *);
void SetAlias(char *,char *);
void SetMacro(char *,char *);
void ExtractLine(char *);
void ExtractFile(char *);


/* エラー処理 */
int prErr(char *message)
{
	fprintf(stderr,"%s:(%d) error:%s",processFile,processLine,message);
	exit(-1);
}

/* 文字列の置換（str1 中の str2 を str3 に置換） */
char *strchg(char *str1,const char *str2,const char *str3)
{
	char *p,*src;
	int len;

	p=strstr(str1,str2);
	if(p!=NULL) {
		len=strlen(str3); src=p+strlen(str2);
		memmove(p+len,src,strlen(src)+1);
		memcpy(p,str3,len);
	}
	return p;
}


/* エイリアスの存在チェック・展開 */
int ExtractAlias(char *buf)
{
	int i,len,lenMax = 0;
	struct sAlias *hit = NULL;
	
	/* エイリアスの存在チェック */
	for(i=0;i<aliasMax;i++) {
		if(strstr(buf,alias[i].name)!=NULL) {
			len=strlen(alias[i].name);
			if(lenMax<len) {
				lenMax=len;
				hit=&alias[i];
			}
		}
	}
	/* 発見 */
	if(hit!=NULL) {
		strchg(buf,hit->name,hit->body);
		ExtractLine(buf);
		return 1;
	} else return 0;
}

/* マクロの存在チェックと展開 */
int ExtractMacro(char *buf)
{
	char *p,*q;
	int i,j,len,lenMax;
	char tmp[BUFSIZ];
	char argv[16][16];
	struct sMacro *hit;

	/* マクロと一致するかチェック */
	hit=NULL; lenMax=0;
	for(i=0;i<macroMax;i++) {
		p=strstr(buf,macro[i].name);
		len=strlen(macro[i].name);
		if(p!=NULL&&(*(p+len)==' '||*(p+len)=='\t'||*(p+len)=='\n')) {
			if(lenMax<len) { 
				lenMax=len;
				hit=&macro[i];
			}
		}
	}
	/* マクロ発見 */
	if(hit!=NULL) {
		p=strstr(buf,hit->name);
		*p='\0';
		ExtractLine(buf);
		p+=lenMax;
		SKIPSPACE(p);
		i=j=0;
		/* 引数の把握 */
		while(1) {
			while(*p!=','&&*p!='\n') argv[i][j++]=*p++;
			argv[i][j]='\0';
			if(j) i++;
			if(*p=='\n') break;
			p++; j=0;
		}
		if(i!=hit->argc) prErr("引数の数が合いません。");
		
		/* マクロの展開 */
		p=hit->body;
		while(*p!='\0') {
			q=tmp;
			while(*p!='\n') *q++=*p++;
			*p++;
			*q++='\n'; *q='\0';
			for(i=0;i<hit->argc;i++)
				while(strchg(tmp,margv[i],argv[i])!=NULL);
			ExtractLine(tmp);
		}
		return 1;
	} else return 0;
}

/* エイリアスを設定 */
void SetAlias(char *buf,char *p)
{
	int i;

	/* エイリアス名の獲得 */
	SKIPSPACE(p);
	alias[aliasMax].name=bufferTail;
	while(*p!=' '&&*p!='\n') *bufferTail++=*p++;
	*bufferTail++='\0';
	SKIPSPACE(p);
	
	/* 同名のエイリアスを削除 */
	alias[aliasMax].body=bufferTail;
	for(i=0;i<aliasMax;i++)
		if(strcmp(alias[aliasMax].name,alias[i].name)==0)
			alias[i].body=alias[aliasMax].body;
	
	/* エイリアス本体の記憶 */
	while(*p!='\n') *bufferTail++=*p++;
	*bufferTail++='\0';
	aliasMax++;
}


/* マクロを設定 */
void SetMacro(char *buf,char *p)
{
	char argv[16][16];
	int i,j;

	/* マクロ名の設定 */
	SKIPSPACE(p);
	macro[macroMax].name=bufferTail;
	while(*p!=' '&&*p!='\t'&&*p!='\n') *bufferTail++=*p++;
	*bufferTail++='\0';
	SKIPSPACE(p);
	i=j=0;

	/* 引数を把握 */
	while(1) {
		while(*p!=','&&*p!='\n') argv[i][j++]=*p++;
		argv[i][j]='\0';
		if(j) i++;
		if(*p=='\n') break;
		p++; j=0;
	}
	macro[macroMax].argc=i;
	macro[macroMax].body=bufferTail;

	/* 同名のマクロをチェック */
	for(i=0;i<macroMax;i++)
		if(strcmp(macro[macroMax].name,macro[i].name)==0) {
			macro[i].body=macro[macroMax].body;
			macro[i].argc=macro[macroMax].argc;
		}

	/* マクロ本体の記憶 */
	while(1) {
		if(fgets(bufferTail,BUFSIZ,iFile)==NULL)
			prErr(".endmが見つかりません。");
		processLine++;
		if(strstr(bufferTail,".endm")!=NULL||strstr(bufferTail,".ENDM")!=NULL)
			break;
		/* 引数を内部形式に変換 */
		for(i=0;i<macro[macroMax].argc;i++)
			while(strchg(bufferTail,argv[i],margv[i])!=NULL);
		bufferTail+=strlen(bufferTail);
	}
	*bufferTail++='\0';

	/* デバグ用 */
#ifdef DEBUG
	fprintf(stderr,"%d番のﾏｸﾛ %s (引数 %d: "
		,macroMax,macro[macroMax].name,macro[macroMax].argc);
	for(i=0;i<macro[macroMax].argc;i++)
		fprintf(stderr,"%s ",argv[i]);
	fprintf(stderr,") を定義\n--\n%s--\n",macro[macroMax].body);
#endif
	macroMax++;
}


/* 一行を展開 */
void ExtractLine(char *buf)
{
	int i;
	char *p,*q;

	/* 何もない行とコメント行をパスする */
	SKIPSPACE(buf);
	if(*buf=='\n'||*buf=='#'||*buf=='\0') return;
	
	/* aspp の命令が含まれているかどうか調べる */
	for(i=0;i<directiveMax;i++) {
		p=strstr(buf,directive[i]);
		if(p!=NULL) {
			p+=strlen(directive[i]);
			break;
		}
	}
	/* 命令ごとに分岐 */
	switch(i) {
		case 0:
		case 1:
			/* マクロの設定 */
			SetMacro(buf,p);
			break;

		case 2:
		case 3:
			/* エイリアスの設定 */
			SetAlias(buf,p);
			break;

		case 4:
		case 5:
			/* インクルード処理 */
			SKIPSPACE(p);
			if(*p++!='"') prErr("ファイル名が指定されていません。");
			q=p;
			while(*p!='"') p++;
			*p='\0';
			ExtractFile(q);
			break;

		default:
			/* どれにもあてはまらなければインデントして出力 */
			if(!ExtractAlias(buf)&&!ExtractMacro(buf)) {
				p=buf;
				SKIPSPACE(p);
				if((strchr(p,':')==NULL)&&(*p!='.')) fputc('\t',oFile);
				fputs(p,oFile);
			}
			break;
	}
}


/* ファイル単位での処理 */
void ExtractFile(char *fileName)
{
	FILE *file,*tmpFile;
	char buf[BUFSIZ];
	int tmpLine;
	char *tmpFileName;
	
	tmpLine=processLine; processLine=1;
	tmpFileName=processFile; processFile=fileName;
	if(fileName==NULL) {
		fileName="標準入力";
		iFile=stdin;
	} else
		if((file=fopen(fileName,"rt"))==NULL)
			prErr("ファイルが見つかりません。");
	strcpy(processFile,fileName);
	tmpFile=iFile; iFile=file;
	
	/* 展開 */
	while(fgets(buf,BUFSIZ,iFile)!=NULL) {
		ExtractLine(buf);
		processLine++;
	}
	processLine=tmpLine;
	processFile=tmpFileName;
	iFile=tmpFile;
}


int main(int argc,char *argv[])
{
	/* エイリアス・マクロバッファの確保 */
	bufferTail=malloc(1024*1024*sizeof(char));
	if(bufferTail==NULL) prErr("メモリが足りません。");
	alias=(struct sAlias *)bufferTail;
	macro=(struct sMacro *)(bufferTail+64*1024);
	bufferTail+=25*1024;

	/* ファイルを展開 */
	ExtractFile((argc==2)? argv[1]:NULL);
	free(alias);
	return 0;
}

