

 		        *** Knightmare Gold v2.0.0 Readme ***
  	             *** (c)2006  Amusement Factory Software ***

  			      http://www.caetano.eng.br/
			        daniel@caetano.eng.br
			


1.0 - Introdução
================

	Nós da Amusement Factory, A&L Software e Techno Dreams gostaríamos
de agradecer por jogar esta edição especial do 20o. aniversário de Knightmare,
o melhor jogo de 32KB da Konami para a plataforma MSX.
	Também gostaríamos de agradecer à Konami. Sem seu trabalho original,
esta ediçção especial jamais teria visto a luz do dia. :)

	Atenciosamente,

						Daniel Jorge Caetano
						--------------------
 						 Amusement  Factory


2.0 - Atenção!
==============

	Este jogo foi desenvolvido com base no jogo original da Konami.
Todos os direitos sobre personagens e nomes são reservados pela Konami.
Por outro lado, os direitos sobre o Midas Loader (KMG.COM) bem como
as músicas rearranjadas são reservados pela Amusement Factory Software
e pela Techno Dreams.

	A redistribuição deste software *não é* permitida sem expressa
autorização. Este produto não pode ser vendido, nem mesmo incluido em 
coletâneas de software de qualquer tipo.

	O download é livre na página oficial do Knightmare Gold em:
http://www.caetano.eng.br/msxpage/kmg/ .


3.0 - Queimando o CD
====================

	O jogo é completamente funcional sem qualquer tipo de unidade 
de CDROM, mas você estará fadado a ouvir as músicas originais do PSG:
tudo que você precisa para jogar neste modo é colocar um arquivo ROM
do jogo Knightmare original no mesmo diretório que o KMG.COM, usando
o seguinte nome:

	KMARE.ROM
	
	E iniciar o jogo usando KMG.COM.

	Se você deseja ouvir a nova trilhas sonora, você precisará de
um PC para queimar um CD. Você precisa escrever os arquivos do KMG_R2.ZIP 
mais o arquivo KMARE.ROM na primeira trilha do CD, como uma trilha de
dados, e os arquivos K02.MP3 ao K22.MP3 nas trilhas seguintes (trilhas
2 a 22) como trilhas de áudio. O formato do CD deve ser CD-XA. Você pode
usar o Nero ou qualquer outro programa que lhe permita criar CDs no
formato CD-XA.
	Se você não tem o Nero ou quer instruções mais detalhadas, aqui
estão elas (usando MKISOFS e CDRECORD):

	Deszipe este pacote de distribuiçção ( KMG_R2.ZIP ) em um diretório
temporário como:

	C:\KMG\GAMEDATA

	No seu PC. Coloque a cópia da ROM do Knightmare neste diretório.
A listagem do diretório deve ser:

	KMARE.ROM
	KMG.COM
	README.TXT
	README_ENG.TXT

	Crie também o seguinte diretório:

	C:\KMG\GAMEISO

	Baixe todos os arquivos Kxx.MP3 do site, do K02.MP3 ao K22.MP3. 
Estes arquivos precisam ser descomprimidos para o formato WAV e colocados
no diretório C:\KMG\GAMEISO. Use qualquer programa para fazer isso. A
única limitação é que os arquivos precisarão estar em 16bit 44KHz estéreo, 
que é o formato usado por CDs de áudio.
	Assim que todos os arquivos estiverem no lugar, você precisará do
seguinte programa:

	MKISOFS

	Este programa está disponível em todos os sistemas operacionais,
pergunte ao Google. Assim que você baixá-lo e instalá-lo, use os seguintes
comandos:

	C:
	CD\KMG
	MKISOFS -V KMG_R2 -iso-level 3 -RJ -o .\gameiso\k01.iso .\gamedata

	Isto irá criar o arquivo chamado k01.iso no diretório \gameiso.
A listagem do diretório C:\KMG\GAMEISO deve ser:

	K01.ISO
	K02.WAV
	K03.WAV
	K04.WAV
	K05.WAV
	K06.WAV
	K07.WAV
	K08.WAV
	K09.WAV
	K10.WAV
	K11.WAV
	K12.WAV
	K13.WAV
	K14.WAV
	K15.WAV
	K16.WAV
	K17.WAV
	K18.WAV
	K19.WAV
	K20.WAV
	K21.WAV
	K22.WAV

	Agora você precisará do seguinte programa:

	CDRECORD

	Este programa também está disponível em todos os sistemas 
operacionais. Pergunte ao Google. Assim que você baixá-lo e instalá-lo,
coloque um CD-R virgem no drive e digite os seguintes comandos:

	C:
	CD\KMG\GAMEISO
	CDRECORD dev=x,y,z speed=4 fs=8192k -v -pad -multi -xa k01.iso k02.wav k03.wav k04.wav k05.wav k06.wav k07.wav k08.wav k09.wav k10.wav k11.wav k12.wav k13.wav k14.wav k15.wav k16.wav k17.wav k18.wav k19.wav k20.wav k21.wav k22.wav
	
	Lembre-se de substituir x,y,z com os valores corretos para o seu
gravador de CD. Para descobrir os valores corretos, use os seguintes comandos:

	CDRECORD -scanbus |more

	Normalmente os valores corretos são similares a 0,1,0.

	Esta ação gravará as trilhas no seu CD-R. Assim que o CDRecord
terminar, você pode pegar seu CD e rodá-lo no MSX. Lembre-se de carregar
o MSXCDEX antes de mudar para o drive de CD e rodar KMG.COM. :)



4.0 - Mais Informações
======================

	Para mais informações, visite o site oficial:

	http://www.caetano.eng.br/msxpage/kmg/

	Lá você poderá encontrar as últimas versões e correções para o jogo,
bem como músicas e manual do jogo.

	Este produto é distribuído sem a obtenção de qualquer tipo de lucro.
Os autores *não são* obrigados a prover suporte, mas o farão na medida do
possível.
	Se precisar de suporte, envie um e-mail para:

	daniel@caetano.eng.br

	Com o texto "KMG - Suporte" no campo "assunto".



5.0 - Equipe
============

	Programa original
		Konami Software, (c) 1986

	Versão CD-ROM
		A&L Software, (c) 2003-2005

	Versão MSX2
		Amusement Factory Software, (c) 2004-2006

	Reprogramação de Áudio
		Adriano C. R. da Cunha (UZIXman)
		Daniel J. Caetano (Fudeba)

	Reprogramação Geral/Gráfica
		Daniel J. Caetano (Fudeba)

	Geração do CD-ROM Original
		Carlos Eduardo M. Andrade
		Daniel J. Caetano (Fudeba)

	"Argumento Gráfico"
		José Lúcio Gama (SLotman)
		Giovanni dos Reis Nunes (PlainSpooky)
		Daniel J. Caetano (Fudeba)

	Arranjos Musicais para CD
		Pablo Vasques Bravo-Villalba (Parn)

	Arte e Conversão da Tela de Abertura
		Cláudio Massao Kawata (Cyberknight)
		José Lúcio Gama (SLotman)
		Daniel J. Caetano (Fudeba)

	Arte do Logo Konami
		José Lúcio Gama (SLotman)
		Daniel J. Caetano (Fudeba)

	Palheta Básica de Cores (Cool Colors)
		Fábio Ricardo Schmidlin (FRS)

	Palheta Dinâmica
		Daniel J. Caetano (Fudeba)

	Nome do Carregador
		Felipe Bergo (yopparai)

	Manual Original
		Konami Software, (c) 1986

	Digitalização do Manual
		Sandy Pleyte

	Manual Gold
		Daniel J. Caetano (Fudeba)
	
	Revisão do Manual Gold
		Pablo Vasques Bravo-Villalba (Parn)
		Adriano C. R. da Cunha (UZIXman)
		Patr¡cia Arima (Morwen)
		Dante T. Nishida (atom)

	Beta-Testing
		José Lúcio Gama (SLotman)
		Adriano C. R. da Cunha (UZIXman)
		Dante T. Nishida (atom)
		Leandro Pereira (acidx)
		Carlos Eduardo M. Andrade

	Página na Internet
		Daniel J. Caetano (Fudeba)
	
	Página em Inglês
		Diego Ribeiro
		Fabiano Colella
		Daniel J. Caetano (Fudeba)

