# p3e-file-selector
Selector de archivos ideado para +3e (incluye Z80Loader)

Para el ensamblado se requiere usar línea de comandos, en caso Linux es "ensambla.sh" y en caso de windows es "ensambla.bat"

Se requiere en el caso de Linux tener ya instalado SJASMPLUS, en caso de windows ya está incluido en la carpeta ./bin

Si estás depurando y/o quieres darles una probada primero, se requiere del emulador FUSE en Linux, en cambio para windows ya hay una "pre-instalación" en la carpeta ./fusew

Si quieres usar otro emulador necesitarás uno que soporte interface "+3e 8bits", pero adicionalmente deberás adaptar "ensambla.sh" o "ensambla.bat" según tu plataforma.

También se hace uso del programa CPCXFS para manipular archivos DSK, los cuales ya se encuentran compilados en la carpeta ./bin tanto sea para Linux en formato x86-64, así como ARM (léase Raspberry PI), pero también el ejecutable para Windows

Adicionalmente se requiere de algún utilitario para crear cabeceras de archivo válidas para +3DOS a partir de un archivo binario, aquí uso el antiquísimo SPECFORM (*) que forma parte de los utilitarios programados por John Elliott, el cual se encuentra en la carpeta ./bin tanto sea para Linux en plataforma x86-64, así como ARM (léase Raspberry PI), pero también el ejecutable para Windows (en el caso de windows posiblemente tu antivirus lo tome como "sospechoso" por lo que deberás estar atento la primera vez que lo ejecutes)

Al final del proceso tendrás una imagen de floppy DSK con este utilitario que deberás ver como hacer llegar su contenido a un +3 REAL, yo en mi caso mi +3e lo uso con una "disquetera" GOTEK, lo que no me significa ningún problema.

(*) Puedes buscar aquí por los fuentes de SPECFORM

https://www.seasip.info/ZX/unix.html

https://github.com/OS2World/APP-EMULATOR-TapTools.git