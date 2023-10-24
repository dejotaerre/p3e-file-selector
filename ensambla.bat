@echo off
echo.

set org=28672
set nombre=selz80
set fuse_exec=fusew\fuse

.\bin\sjasmplus --lst --lstlab --raw=%nombre%.obj %nombre%.asm

if errorlevel 1 (
	echo.
	echo "**************************"
	echo "* Ensamblado incorrecto! *"
	echo "**************************"
	echo.
	exit 1
)

if exist %nombre%.bin del %nombre%.bin
if exist %nombre%.dsk del %nombre%.dsk

.\bin\specform -a %org% %nombre%.obj
ren %nombre%.obj.zxb %nombre%.bin

cd bin

REM genero en un archivo los comandos para crear una imagen de disquete para testeos en el emulador junto
REM al binario de esta utilidad con un cargador DISK para testeo, usando CPCXFS
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

cpcxfsw < makedsk

del makedsk
cd ..

rem Hago una variable de entorno con los parámetros necesarios para ejecutar y testear
rem esta utilidad
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
echo.
echo "***********************************************************************************************"
echo EJECUTANDO:
echo %fuse_exec% %fuse_opciones%
echo "***********************************************************************************************"

rem TODO pronto, ahora hay que probar con un emulador (FUSE en este caso)
%fuse_exec% %fuse_opciones%

rem LIMPIEZA
if exist %nombre%.bin del %nombre%.bin
if exist %nombre%.dsk del %nombre%.dsk
if exist %nombre%.lst del %nombre%.lst
if exist %nombre%.obj del %nombre%.obj
