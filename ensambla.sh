#!/bin/bash

#===========================================================================================
#vemos si tenemos lo necesario

arquitectura=$(uname -m)

if [ "$arquitectura" = "x86_64" ]; then
    cpcfscmd=cpcxfs
    sjasmcmd=sjasmplus
elif [ "$arquitectura" = "i686" ]; then
    cpcfscmd=cpcxfs
    sjasmcmd=sjasmplus
elif [ "$arquitectura" = "armv7l" ]; then
    cpcfscmd=cpcxfs_arm
    sjasmcmd=sjasmplus_arm
elif [ "$arquitectura" = "aarch64" ]; then
    cpcfscmd=cpcxfs_arm
    sjasmcmd=sjasmplus_arm
else
    echo "Arquitectura no compatible: $arquitectura con este script"
    exit 1
fi

echo

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

#org 7000h
org=28672

nombre=selz80

$sjasmcmd --lst --lstlab --raw=${nombre}.obj ${nombre}.asm

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

./bin/specform -a ${org} "${nombre}.obj"
rm -f "${nombre}.bin"
mv "${nombre}.obj.zxb" "${nombre}.bin" 

cd bin

# Creo un archivo con los comandos necesarios para crear una imágen de disquete con
# cpcxfs para propósitos de testeos con el emulador FUSE, una vez usado se borra
echo "new -f PCW3 ../selz80.dsk" > makedsk
echo "open -f PCW3 ../selz80.dsk" >> makedsk
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
#echo "put -f QUAZATRO.Z80" >> makedsk
#echo "put -f WHERETIM.TAP" >> makedsk

./$cpcfscmd < makedsk

rm makedsk

cd ..

if ! command -v fuse >/dev/null 2>&1; then

	echo
	echo -e "\e[1;31mADVERTENCIA:\e[0m no encuentro el emulador FUSE, así que no podrás probar el"
	echo "resultado, pero puedes buscar en https://fuse-emulator.sourceforge.net/"
	echo "o bien instalarlo con tu gestor de paquetes favorito"
	echo
	echo "Sin embargo se ha creado una imagen de disquete de nombre \"$nombre.dsk\""
	echo "que contiene este utilitario volcarla en un floppy físico, o bien en"
	echo "un pendrive para usarla desde una unidad GOTEK en tu +3e"
	echo

else

	#TODO pronto, ahora hay que probar con un emulador (FUSE en este caso)

	#fuse_exec="fuse-sdl"
	fuse_exec="fuse"

	# genero los comandos para crear una imagen de disquete para testeos en el emulador
	# junto al binario con esta utilidad y un cargador DISK para testeo
	exec_args="--machine plus3 \
	--simpleide \
	--multiface3 \
	--plus3disk ./selz80.dsk \
	--rom-plus3-0 ./p3t_rom0.rom \
	--rom-plus3-1 ./p3t_rom1.rom \
	--rom-plus3-2 ./p3t_rom2.rom \
	--rom-plus3-3 ./p3t_rom3.rom \
	--rom-multiface3 ./bin/mf3.rom \
	--simpleide-masterfile ./+3e8bits.hdf \
	--graphics-filter tv4x \
	--pal-tv2x \
	--drive-plus3a-type 'Double-sided 80 track' --drive-plus3b-type 'Double-sided 80 track'"

	comando="${fuse_exec} ${exec_args}"

	echo 
	echo
	echo "***********************************************************************************************"
	echo EJECUTANDO:
	echo
	echo $fuse_exec $exec_args
	echo "***********************************************************************************************"

	eval $comando > /dev/null 2>&1

fi

#LIMPIEZA
rm -f "${nombre}.bin"
rm -f "${nombre}.dsk"
rm -f "${nombre}.obj"
rm -f "${nombre}.lst"
