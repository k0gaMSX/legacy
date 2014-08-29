
~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~

          ?mnmmmmmm:        =mmmmmmnm      m8Immmmmmmmmmnmm   mmmmmmmmm
        mm          m     mm         mm   ?m              m nn         ,m+
       mm   mmmm     m   m~    nmn    mm  m              mmm     m=      m
       m   m    n    m  m,    m  On    m mI  mmmmmmm    m m~  mm,  mm    Zm
       mmmm    m~   7m m     m    m    m,m? mm   m?   nm  m   m     m    mm
            oOm    mm, m    mm   Zm    m   m   $n    n    mmmmm   mm    mm
          mm      ,m  mZ    m    m     m      mn    m           nm     mm
     mnmmn ZZmm     m m     m    m    mm     mn    m          mm     nmmm
    Om   mm   $m    m m     m   m     m     mm    m        8m$    =mmm  mm
    ~m    mm mn     m mm    mnmm     m      n    mm      mm             m
     mm            n   mm          Im      m     m      m              mm
       mn       nmm     $n7      nm=       m    m8      m              m
          :mmm,            ,mmm~            '":"~        '':::::,:,,mmm


~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~=~~=~


Welcome to the README.TXT of this demo, released under the name 3072.



What is it?
===========
3072 is the entry for the 64x48 challenge of the MSX Resource Center.
All demo parts can be influenced by the user.
All demo parts are written by David Heremans.
The music was downloaded from the MSX Resource Center and was composed by
Eric van Hezik and Remco Weijman. Of course it is used with permission of
the authors.
Special thanks to Wouter Vermaelen en Manuel Bilderbeek for testing 
this demo.

Such a strange name?
====================
Really?
Since it was an entry for the 64x48 compo this seemed the most logical name.
You do the math: How much is 64x48?


How do I interact with all these demo parts?
============================================

All interaction can be performed with a regular MSX joystick or by using the
cursor keys, SPACE and the GRPH key.

As a general rule, skipping to the next part is performed by pressing both
fire buttons (or SPACE and GRPH) at the same time.

Below is a simple list of all demo parts and what exactly you can do in them.


INTRO
-----
Simply a nice tube scroller to say hello.

FIRE A: This will stop the scroll while the button is pressed


INTERFERENCE
------------
Actually there is not much to do here. But you can skip to the next part by
pressing both fire buttons so it is at least minimally interactive :-)
As a side note, this part will also try to find out if the demo is running on
an emulator.


TEXT MORPHING
-------------
Using UP, DOWN, LEFT, RIGHT, SPACE you can alter the speed of the color cycling.


RAINDROPS
---------
Once you start using the cursor keys you can draw waves in the water yourself
by pressing SPACE. Use GRPH to toggle the falling of the raindrops while you're
drawing. The longer you press SPACE, the bigger the wave you will cause.
Of course you can move the cursor while you keep SPACE pressed. Due to the
rounding errors in using 8-bit math you can have some diagonal waves that take
an eternity to die out. Just draw some waves in the proximity of these lines
to help them disappear more easily.


3D OBECTS
---------
This is the most interactive part of them all!
(To make up for the lack of it in some other parts.)

FIRE A : Show the next 3D object

UP     : zoom in 
DOWN   : zoom out
LEFT   : adjust turning speed around the first axis 
RIGHT  : adjust turning speed around the first axis

UP+A   : move the object upwards
DOWN+A : move the object downwards
LEFT+A : move the object to the left
RIGHT+A: move the object to the right

UP+B   : adjust turning speed around the second axis 
DOWN+B : adjust turning speed around the second axis 
LEFT+B : adjust turning speed around the third axis 
RIGHT+B: adjust turning speed around the third axis 

UP+A+B   : lower the detail level
DOWN+A+B : increase the detail level
LEFT+A+B : move the scroll text to the left border
RIGHT+A+B: move the scroll text to the right border


ZOOM ROTATOR
------------
A zoom rotator projected on some nice clouds.

UP   : zoom in 
DOWN : zoom out
LEFT : rotate right
RIGHT: rotate left

A+DIRECTION : Move rockets in the desired direction

B+DIRECTION : Make the clouds move in the given direction


FIRE
----
This is much like the water effect. If you wait you'll notice the flaming
texts that will appear. And of course you'll be reminded again of the
interactive nature of this demo part.

FIRE B: if cursor not visible then this will make the next 'burning image' appear

DIRECTION  : show the cursor if not visible yet and move it around.
DIRECTION+A: place a burning point

If you stop moving the cursor it will disappear after a while, and a little 
later the lines you have drawn will fade away.


BUMPMAPPING
-----------
This simple demo effect is still a beauty to behold.

DIRECTION: direct the beam of light

If you stop moving the light it will resume its circular movements after a
while. Note that this part looks much better on a V9958 VDP.


THE END
-------
And before we drop back into the harsh reality of the DOS prompt we say
goodbye.

FIRE A: This will stop the scroll while the button is pressed



Something strange / it doesn't work / known bugs?
==================================================

There are plenty of known issues with this demo. :-(

Most are related to the fact that the custom made BIOS used by this demo
is a development binary made eons ago and its sources are gone up in a cloud
of white smoke towards the eternal bitfields during a HD crash. So this demo
is stuck with the incomplete development version found on some backup disks.

Here is a small list of known issues:
- A MoonSound(tm) is obligatory for this demo.
- Under specific angles/zooms the 3D part sometimes freezes (however, a
  safeguard is created to advance the demo after a freeze of 5 seconds)
- Sometimes the depth sorting of the 3D objects is reversed, cycle through
  the objects to get the same object again and most likely the problem
  will be solved
- Some screensplits aren't that stable.
- There seems to be a problem returning to DOS on some MSX2 machines.
- Special BIOS keys are not disabled and might cause color glitches if used.

If you are an adventurous type and you were planning on replacing the MWM
files on this disk with other music pieces, be warned that if such an MWM
would load an MWK file, the demo can randomly hang during one of the next
disk accesses!
