
Some notes on building the game on Ubuntu, Windows, and Mac OS X.


Building game on Ubuntu
-----------------------

Required software packages.

build-essential		(depends on gcc and libc-dev)
libsdl1.2-dev		(SDL)
libsdl-image1.2-dev	(SDL_image)
libsdl-mixer-dev	(SDL_mixer >= 1.2.10)
mesa-common-dev		(OpenGL)
readline-dev		(By default, Lua requires this command line editing
			 library when compiling on Linux. Not really necessary,
			 and luaconf.h can be modified to not use it)

Build Lua & game:
	$ make PROJECT=demo

Run:
	$ cd demo
	$ ./demo


Getting SDL headers on Windows
------------------------------

Download the Mingw32 development version of SDL:
	http://www.libsdl.org/release/SDL-devel-1.2.15-mingw32.tar.gz

Download SDL_image source:
	http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12.zip
from which the header file SDL_image.h goes into SDL-root/include/SDL. The
rest can be discarded.

Download SDL_mixer source:
	http://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.12.zip
Copy SDl_mixer.h from the extracted folder into SDL-root/include/SDL. The rest
can be discarded.


Building game for Mac OS X >= 10.6 using MacPorts
-------------------------------------------------

Install Xcode to get development tools.
Install MacPorts app.

Install SDL, SDL_image, and SDL_mixer:
        $ sudo port install libsdl
        $ sudo port install libsdl_image
        $ sudo port install libsdl_mixer

Build Lua:
        $ cd lua-5.1 && make clean && make macosx

Build game:
        $ make PROJECT=demo

Run it:
        $ cd demo && ./demo-macosx

