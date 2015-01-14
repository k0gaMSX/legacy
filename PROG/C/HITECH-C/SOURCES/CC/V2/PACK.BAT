rem pack files from CC + VSH to distributable archive
del cc.lzh
lhpack cc.lzh cc.com libdos2.lib vsh1.o vsh2.o vsh3.o redir.obj cc.txt vsh.txt cc.c vshrt.as redir.as makefile pack.bat
