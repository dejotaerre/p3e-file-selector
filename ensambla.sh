#!/bin/bash

# OCT-2023 - ADICIONADO SOPORTE PARA ARM (i.e Raspberry PI)

#===========================================================================================

pausar() {
  echo "Presiona Enter para continuar..."
  read -r
}

#===========================================================================================

arquitectura=$(uname -m)

if [ "$arquitectura" = "x86_64" ]; then

    cpcfscmd=cpcxfs
    sjasmcmd=sjasmplus
    specform=specform

elif [ "$arquitectura" = "i686" ]; then

    cpcfscmd=cpcxfs
    sjasmcmd=sjasmplus
    specform=specform

elif [ "$arquitectura" = "armv7l" ]; then

    cpcfscmd=cpcxfs_arm
    sjasmcmd=sjasmplus_arm
    specform=specform_arm

elif [ "$arquitectura" = "aarch64" ]; then

    cpcfscmd=cpcxfs_arm
    sjasmcmd=sjasmplus_arm
    specform=specform_arm

else

    echo "Arquitectura $arquitectura no compatible con este script"
    exit 1

fi

echo

#===========================================================================================
#vemos si tenemos lo necesario

if [ ! -e "./bin/specform" ]; then
	cd bin
	gcc -o specform specform.c
	cd ..
	if [ ! -e "./bin/specform" ]; then
		echo "NO pude compilar SPECFORM (lo necesito para crear cabeceras"
		echo "+3DOS a partir de un binario en bruto)"
		echo
		echo "**NOTA** SPECFORM es parte de una colección de utilitarios de John Elliott"
		echo "que puedes descargar sus fuentes desde: http://www.seasip.info/ZX/unix.html"
		echo
		exit 1
	fi
fi

org=28672 #org 7000h

nombre=selz80

./bin/${sjasmcmd} --lst --lstlab --raw=${nombre}.obj ${nombre}.asm

if [ $? -ne 0 ]; then
	echo
	echo "*************************"
	echo "* ¡Falló el ensamblado! *"
	echo "*************************"
	echo
	exit 1
fi

echo

rm -f "${nombre}.dsk"

./bin/${specform} -a ${org} "${nombre}.obj"
rm -f "${nombre}.bin"
mv "${nombre}.obj.zxb" "${nombre}.bin" 

cd bin

# genero en un archivo los comandos para crear una imagen de disquete para testeos en el emulador junto
# al binario de esta utilidad con un cargador DISK para testeo, usando CPCXFS
if [ -e "../selz80a.dsk" ]; then
    rm "../selz80a.dsk"
fi
if [ -e "../selz80b.dsk" ]; then
    rm "../selz80b.dsk"
fi

echo "new -f PCW3 ../selz80a.dsk" > makedsk
echo "new -f PCW3 ../selz80b.dsk" >> makedsk
echo "open -f PCW3 ../selz80a.dsk" >> makedsk
echo "put -f ../disk DISK" >> makedsk
echo "put -f ../selz80.bin SELZ80.BIN" >> makedsk

echo "cd dskfiles" >> makedsk

echo "put -f ADDAMS.Z80" >> makedsk
echo "put -f ALIENH.Z80" >> makedsk
echo "put -f BATMAN.Z80" >> makedsk
echo "put -f GBERET.Z80" >> makedsk
echo "put -f HOH.Z80" >> makedsk
echo "put -f MPOINT.Z80" >> makedsk
echo "put -f PROFANAT.Z80" >> makedsk
echo "put -f RENEGAD2.Z80" >> makedsk
echo "put -f HYPERSPO.TAP" >> makedsk
echo "put -f JETPAC.TAP" >> makedsk
echo "put -f MANIC.TAP" >> makedsk
echo "put -f WECLEMAN.TAP" >> makedsk
echo "dir" >> makedsk
echo "close" >> makedsk

echo "open -f PCW3 ../../selz80b.dsk" >> makedsk

echo "put -f ../../disk DISK" >> makedsk
echo "put -f ../../selz80.bin SELZ80.BIN" >> makedsk

echo "put -f BEAST.TAP" >> makedsk
echo "put -f MUNCHER.TAP" >> makedsk
echo "put -f BRUCELEE.TAP" >> makedsk
echo "put -f COMANDO.TAP" >> makedsk
echo "put -f DARKMAN.TAP" >> makedsk
echo "put -f FUTBOL.TAP" >> makedsk
echo "put -f QUAZATRO.Z80" >> makedsk
#echo "put -f WHERETIM.TAP" >> makedsk #imposible de cargar por que usa la RAM7 

echo "dir" >> makedsk

echo "close" >> makedsk
echo "exit" >> makedsk

# cuando uso CPCXFS con redirecciones aparecen a veces errores tipo asi: "Redirection of stin/stdout is not allowed!"

# no se por que, pero CPCXFS tiene comportamientos erráticos y aleatorios con la copia con "mput" cuando utilizo
# redirecciones con "cpcxfs < filename" - hubiese preferido hacer "mget -f *.Z80" en vez de hacerlo archivo  por archivo,
# pero parece que si lo hago con "put" no se da ese problema

./$cpcfscmd < makedsk
rm makedsk
cd ..

if ! command -v fuse >/dev/null 2>&1; then

	echo
	echo -e "\e[1;31mADVERTENCIA:\e[0m no encuentro el emulador FUSE, así que no podrás probar el"
	echo "resultado, pero podrás buscar en https://fuse-emulator.sourceforge.net/"
	echo "sus fuentes y compilarlo, o bien instalarlo con tu gestor de paquetes"
	echo "favorito de tu distro (asegúrate que sea la versión 1.6 o superior)"
	echo
	echo -e "Sin embargo se ha creado una imagen de disquete de nombre \e[1;31m\"$nombre.dsk\"\e[0m"
	echo "que contiene este utilitario, junto a un puñado de Z80s y TAPs de testing,"
	echo "para volcarla en un floppy físico real, o bien en un pendrive para usarse"
	echo "desde una unidad GOTEK en tu +3 o +3e"
	echo

else

	#Ya está todo pronto, ahora hay que probar con un emulador (FUSE en este caso)

	#fuse_exec="fuse-sdl"
	fuse_exec="fuse"

	#argumentos para el testeo en FUSE de este utilitario y "mis" ROMs +3e
	fuse_opciones="--machine plus3 \
	--simpleide \
	--multiface3 \
	--plus3disk ./selz80a.dsk \
	--rom-plus3-0 ./p3t_rom0.rom \
	--rom-plus3-1 ./p3t_rom1.rom \
	--rom-plus3-2 ./p3t_rom2.rom \
	--rom-plus3-3 ./p3t_rom3.rom \
	--rom-multiface3 ./bin/mf3.rom \
	--simpleide-masterfile ./+3e8bits.hdf \
	--graphics-filter tv4x \
	--pal-tv2x \
	--drive-plus3a-type 'Double-sided 80 track' \
	--drive-plus3b-type 'Double-sided 80 track'"

	echo 
	echo
	echo "***********************************************************************************************"
	echo EJECUTANDO:
	echo
	echo $fuse_exec $fuse_opciones
	echo "***********************************************************************************************"

	fuse_test="${fuse_exec} ${fuse_opciones}"

	eval $fuse_test > /dev/null 2>&1

fi

#LIMPIEZA
rm -f "${nombre}.dsk"
rm -f "${nombre}.bin"
rm -f "${nombre}.obj"
rm -f "${nombre}.lst"

exit 0
