GRAPHICS UTILS

In this main X-UTILS directory you will find a few programs that help to create the level data.
Let me explain step by step. But before I do that, just keep in mind that you need the full
hardware configuration in order to be able to use the progs properly. To make the graphs of course
you do not need the Moonsound music module. However, you need a Turbo-R with at least 512 kb memory,
a harddisc, of course a Graphics9000, and to be able to edit the graphs you need two monitors (one
connected to the Turbo-R normal graphics mode and one connected to the Graphics9000).

1) Create your graphics with AGE or any other program that saves the graph-data as .GE5

2) Once you have finished your graphs, try to put everything together in as few .GE5 pages as possible. 
You then need to use the INSGRP.COM program in order to reduce your graphs into 8x8 blocks, which will optimize
your graph as much as possible (this will only work properly, if your graphics is already well positioned within 
an 8x8 grid - this means always work within 8x8, 16x16, 32x32, 64x64, or also 16x64, or 64x32 etc...). Pay
attention, that your reduced graphs always fit on 1 page (screen). This needs to be done with Plane A graphs (foreground)
as well as with Plane B graphs (background)

3) Next, you can start editing your levels. For this you need the program EDIT.COM, and of course the two monitors!!!
If you want to use your own graphics, you have to change / edit the EDIT.INI file. Just open the INI-File and
have a look a the content and then you will understand how it works. Once you have set up the INI-File properly
you can run the EDIT.COM program. Initially you will see the screen where you can choose, which level you want
to edit (of course this depends on your settings in the INI-File). When the screen is opened, you can copy the
graphics from one monitor / screen to the level-screen (second monitor). In order to understand how the editor 
works, you just have to check the instructions on the help-screen (I cannot remember how to open it though, just try F1, 
SELECT or any other button, until the help screen pops up). For further help, try to open an existing, already edited
foreground or background and see for the format! Once you have finished, don't forget to save you data. While
editing the levels, you can always save and exit and test-scroll the level with the program PLAY.COM. Pretty easy,
but helps a lot to get the feeling of the level itself.

4) When you have finished your Plane A and Plane B graphs, as well as the Sprites graphs for one level, you can go
to the next step. Finally, you only need to cut some data from the graph in order to be able to use it with our 
existing Game-Code. If you code your own program, you probably do not need to use this program to create .CUT files.
However, if you use our own existing game-code, you need to use MAP-CUT.COM in order to cut the maps to the
right file size.

5) There is a program to create the color palette for the game (for the .P32 file). Just check the progs in the
X-UTILS folder and hopefully you will find out how it works - I have personally never used it.

6) Now your level graphics are ready to use. You just need to open the XTAZY-Programcode (the .GEN files) and replace
the level file names with the ones you have created, then also replace the music file names with the ones you want
to use for your level etc... The big part is to place the sprites within the level and to tell how each sprite
has to behave. Unfortunately we never had an editor able of doing this job (although MICHI made an editor I 
personally have never seen, and I doubt it is completely finished). So just check the code, and you will understand
how to tell the sprites how to react and how to move and how to position them. Good luck. To play the level, just
start the LOADER.COM file (of course all the necessary level-data and progs need to be in the same directory). 
Just check our Level1 and you will understand what it needs.

I am sorry if my help is only very limited. But I was only the coordinator and editor of the game, and this project
was running a few years ago now. I can barely remember a few things. I would find out with time, but time is what
I don't have at the moment. So please don't ask me any technical question, because I simply cannot answer them
anymore or at all. Nevertheless, I wish everyone good luck with this - now open source - data, and hopefully
one day X-TAZY will be available.

Cheers
Andre Kuepfer