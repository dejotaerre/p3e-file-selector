@echo off
echo.

set org=28672
set nombre=selz80
set fuse_exec=fusew\fuse

.\bin\sjasmplus --lst --lstlab --raw=%nombre%.obj %nombre%.asm

if errorlevel 1 goto err_ensamblado
goto next_test

:err_ensamblado

echo.
echo "**************************"
echo "* Ensamblado incorrecto! *"
echo "**************************"
echo.
goto fin

:next_test
if exist %nombre%.bin del %nombre%.bin
if exist %nombre%.dsk del %nombre%.dsk

REM USO "specform" para crear una cabecera +3DOS a partir del archivo binario compilado por SJASMPLUS
REM fue compilado para Windows 32 bits - buscar fuentes en https://www.seasip.info/ZX/unix.html del paquete
REM TAPTOOLS, (también en https://github.com/OS2World/APP-EMULATOR-TapTools.git) por si necesitas 
REM recompilarlo para usarlo en MSDOS 
REM (NOTA "anecdótica": he comprobado que algunos antivirus creen que SPECFORM es un virus, y nada mas lejos
REM de la realidad..., es un falso positivo, ya que solo escribe un archivo en disco con la cabecera para
REM volcarla en una imágen de disquete DSK, así que estate atento si esto ocurre para quitar de cuarentena
REM a este pobre y buen utitilatario)

.\bin\specform -a %org% %nombre%.obj
ren %nombre%.obj.zxb %nombre%.bin

echo.

cd bin

REM genero en un archivo los comandos para crear una imagen de disquete para testeos en el emulador junto
REM al binario de esta utilidad, con un cargador DISK para testeo, usando CPCXFS
echo new -f PCW3 ..\selz80.dsk > makedsk
echo open -f PCW3 ..\selz80.dsk >> makedsk
echo put -f ..\disk DISK >> makedsk
echo put -f ..\selz80.bin SELZ80.BIN >> makedsk
echo cd dskfiles >> makedsk
echo put -f ADDAMS.Z80 >> makedsk
echo put -f ALIENH.Z80 >> makedsk
echo put -f BATMAN.Z80 >> makedsk
echo put -f GBERET.Z80 >> makedsk
echo put -f HOH.Z80 >> makedsk
echo put -f MPOINT.Z80 >> makedsk
echo put -f PROFANAT.Z80 >> makedsk
echo put -f RENEGAD2.Z80 >> makedsk
echo put -f HYPERSPO.TAP >> makedsk
echo put -f JETPAC.TAP >> makedsk
echo put -f MANIC.TAP >> makedsk
echo put -f WECLEMAN.TAP >> makedsk
rem echo put -f QUAZATRO.Z80" >> makedsk
rem echo "put -f WHERETIM.TAP" >> makedsk

REM USO CPCXFS para crear un DSK de testeo, está compilado para Windows 32bits, si vas
REM a usar este BAT para testear en MSDOS vas a tener que descargar sus fuentes y 
REM compilarlo, sin contar que tendrás que hacer mismo con SJASMPLUS y SPECFORM
REM (no doy garantias que todo esto funcione en un ambiente MSDOS real, en el mejor de
REM los casos solo podrás ensamblar las ROMs nada mas)

cpcxfsw < makedsk

if exist makedsk del makedsk

cd ..

REM Hago una variable de entorno con los parámetros necesarios para ejecutar y testear
REM esta utilidad
set fuse_opciones=--machine plus3
set fuse_opciones=%fuse_opciones% --simpleide
set fuse_opciones=%fuse_opciones% --multiface3
set fuse_opciones=%fuse_opciones% --plus3disk selz80.dsk
set fuse_opciones=%fuse_opciones% --rom-plus3-0 ..\p3t_rom0.rom
set fuse_opciones=%fuse_opciones% --rom-plus3-1 ..\p3t_rom1.rom
set fuse_opciones=%fuse_opciones% --rom-plus3-2 ..\p3t_rom2.rom
set fuse_opciones=%fuse_opciones% --rom-plus3-3 ..\p3t_rom3.rom
set fuse_opciones=%fuse_opciones% --rom-multiface3 ..\roms\mf3.rom
set fuse_opciones=%fuse_opciones% --simpleide-masterfile +3e8bits.hdf
set fuse_opciones=%fuse_opciones% --graphics-filter tv4x 
set fuse_opciones=%fuse_opciones% --pal-tv2x
set fuse_opciones=%fuse_opciones% --drive-plus3a-type "Double-sided 80 track"
set fuse_opciones=%fuse_opciones% --drive-plus3b-type "Double-sided 80 track"

echo.
echo "***********************************************************************************************"
echo EJECUTANDO:
echo %fuse_exec% %fuse_opciones%
echo "***********************************************************************************************"

REM Está todo pronto, ahora hay que probar con un emulador (FUSE en este caso)
%fuse_exec% %fuse_opciones%

REM LIMPIEZA de archivos no necesarios posterior al testeo
if exist %nombre%.bin del %nombre%.bin
REM if exist %nombre%.dsk del %nombre%.dsk
if exist %nombre%.lst del %nombre%.lst
if exist %nombre%.obj del %nombre%.obj

:fin
echo.
pause