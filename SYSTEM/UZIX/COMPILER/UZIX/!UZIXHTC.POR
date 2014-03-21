Compilador Hitech-C direcionado para o UZIX
===========================================
Documento escrito por Adriano C. R. da Cunha
Última atualização: 23/08/2001

	Este pacote contém todos os arquivos de cabeçalho, bibliotecas e
arquivos executáveis do compilador necessários para compilar uma aplicação
em C para o sistema operacional UZIX. Além disso, o manual do Hitech-C
está incluído.
	Verifique o site do UZIX para informações sobre compilação
de aplicações do UZIX em MSXDOS, MSDOS, Linux ou outro sistema
operacional.
	Os arquivos executáveis neste pacote são a versão CP/M do
compilador Hitech-C, vr. 3.09, que é liberada gratuitamente (e também seu
manual) pela empresa que o produziu, Hitech, em seu site
(www.hitech.com.au).

Mapa da meória do UZIX 1.0
--------------------------
                
        0000h   +----------------------------------+
                |  vetores de chamadas de sistema  |
                |  dados do processo para o kernel |
        0100h   +----------------------------------+
                |        código da aplicação       |
                \                                  \
                |   dados estáticos da aplicação   |
                \                                  \
                |     |         heap          |    |
                |     v                       v    |
                \                                  \
                |     ^   pilha da aplicação  ^    |
                |     |argumentos da aplicação|    |
                |       variáveis de ambiente      |
        8000h   +----------------------------------+
                |          kernel do UZIX          |
        F100h   +----------------------------------+
                |    variáveis de sistema do MSX   |
        FFFFh   +----------------------------------+
                
Mapa da meória do UZIX 2.0
--------------------------

        0000h   +----------------------------------+
                |  vetores de chamadas de sistema  |
                |  dados do processo para o kernel |
        0100h   +----------------------------------+
                |        código da aplicação       |
                \                                  \
                |   dados estáticos da aplicação   |
                \                                  \
                |     |         heap          |    |
                |     v                       v    |
                \                                  \
                |     ^   pilha da aplicação  ^    |
                |     |argumentos da aplicação|    |
                |       variáveis de ambiente      |
        C000h   +----------------------------------+
                | parte residente do kernel do UZIX|
        F100h   +----------------------------------+
                |    variáveis de sistema do MSX   |
        FFFFh   +----------------------------------+

Procedimentos gerais para escrever aplicações para o UZIX
---------------------------------------------------------

	Sem muitos conselhos aqui. Em geral, observe o seguinte:

	- escreva sua aplicação em ANSI C;
	- se seu alvo é o UZIX 1.0, sua aplicação não pode ter mais que
32kb, nicluindo código, dados e pilha. Para o UZIX 2.0 sua aplicação não
pode ter mais que 48kb (também incluindo código, dados e pilha). Após
compilar com sucesso sua aplicação, olhe o arquivo de mapa e verifique o
endereço do __Hbss. Se ele estiver muito próximo do final do espaço da
aplicação (7FFFh para o UZIX 1.0 e BFFFh para o UZIX 2.0), tente reduzir o
tamanho do código. Outra informação importante: a pilha, as variáveis de
ambiente e os argumentos da aplicação são colocados no topo do espaço da
aplicação. Se o __Hbss estiver muito próximo deles sua pilha e dados podem
ser misturados. O resultado é um crash do sistema (ou, no melhor caso,
apenas da aplicação). Como regra geral não deixe que o __Hbss seja maior
que 7A00h (para o UZIX 1.0) ou BA00h (para o UZIX 2.0). Fazendo isso você
evitará muitos problemas de pilha;
	- evite criar variáveis locais muit grandes (como 'char
buffer[512]'), pois isso faz com que a pilha abaixe muito. Declare-as como
estáticas. Você irá gastar memória no espaço da aplicação, mas evitará que
a pilha abaixe muito e (talvez) corrompa dados dinâmicos (especialmente no
caso de um programa grande);
	- NUNCA use as instruções DI e EI do Z80;
	- NUNCA use acesso direto ao hardware do MSX;
	- NUNCA acesse dados abaixo de 100h ou acima do espaço da
aplicação ou você provavelmente corromperá o sistema;

Dicas sobre o uso do compilador Hitech-C
----------------------------------------

	O compilador Hitech-C não é perfeito e possui algumas intrigantes
características. Aqui estão algumas dicas sobre o seu uso para compilar
aplicações para o UZIX (e também aplicações para outros sistemas
operacionais). Outras dicas (e soluções de erros) são explicadas no manual
do Hitech-C (em inglês).

* Erro 'out of memory' durante o passo 1

	Se você obteve esse erro em uma chamada de função ou procedimento,
provavelmente ela usa muitos parâmetros (5, 6 ou mesmo mais). Tente
reduzir o número de parâmetros passados: use uma estrutura ou mesmo
coloque alguns parâmetros em variáveis globais.

	Se você recebeu o erro 'Out of memory' em um comando 'if',
provavelmente você tem muitas condições de teste. Tente dividir o 'if' em
dois ou mais 'if' encadeados. Por exemplo, mude

        if (foo == 1 && bar == NULL && foobar != 0 && foofoo == 's' )
        
        para

        if (foo == 1 && bar == NULL) if (foobar != 0 && foofoo == 's')

	Se você obteve o erro 'Out of memory' em outro lugar do seu
código, talvez ele seja muito grande para o Hitech-C. Tente dividí-lo em
duas partes. Compile cada parte e, durante o link, junte-as.

* Erro 'Out of memory' durante otimização

	Não há muito o que fazer aqui. Se seu código tem uma função muit
grande, tente dividí-la em funções menores. Se você realmente não pode
contornar o problema, esqueça a otimização.

* Otimizador trava

	Se você está usando código assembly direto no seu programa,
provavelmente o otimizador do Hitech-C não gostará e irá travar. Tente
reescrever seu código (evite o uso dos códigos JR e RET).
	Se você não sabe qual(is) instrução(oes) está(ão) travando o
otimizador, tente isolar o problema usando construções '#if 0' em seu
fonte. Uma vez que você descobrir qual é o problema, tente reescrever seu
código.
	Se você realmente não pode contornar o problema, esqueça a
otimização.

* 'undefined symbols' durante a etapa de link

	Se você obteve esse erro para símbolos que você tem certeza que
existem na biblioteca, duas coisas podem ter acontecido:

	- você esqueceu de especificar a bilbioteca durante o link

	- a bilbioteca precisa ser religada;

	O primeiro casa é simples, e não merece comentários.
	O segundo caso é mais complicado. O Hitech-C para CP/M tem um
requisito severo para bibliotecas: todos os módulos que as compõem devem
estar ordenados. Todas as referências a um símbolo devem vir ANTES da
definição deste símbolo. Por exemplo, na biblioteca padrão, o fopen.obj
deve vir antes do open.obj, por que fopen.obj chama open.obj. Se a
biblioteca foi ligada na ordem inversa, ao fazer o link da sua aplicação
que usa fopen() você irá receber a mensagem de erro 'undefined
symbol: _open'. O que fazer então? Pegue os fontes da biblioteca e
religue-os na ordem correta (mas, primeiro, descubra o problema!). Se o
problema for nas bibliotecas padrão do UZIX, envie o fonte da sua
aplicação para adrcunha@yahoo.com.br. Eu a irei compilar, encontrar o
problema e corrigir a ordem da biblioteca.

Críticas, adições, erros, dúvidas, comentários, correções, questões
-------------------------------------------------------------------

        Qualquer comentário, adição ou relatório de erros são bem-vindos.
Além disso, se eu escrevi algo errado, correções são também bem-vindas.
Por favor, escreva para adrcunha@yahoo.com.br.

        Página Oficial do UZIX:
        http://uzix.msx.org

