#!/bin/bash

#===========================================================================================
#vemos si tenemos lo necesario

if ! command -v sjasmplus >/dev/null 2>&1; then
		echo
		echo "SJASMPLUS no está instalado en el sistema, no se puede ensamblar"
		echo "(https://github.com/z00m128/sjasmplus.git)"
		echo
		exit 1
fi

if [ ! -e "./bin/specform" ]; then
		echo
		echo "No encuentro SPECFORM en ./bin (lo necesito para crear cabeceras"
		echo "+3DOS a partir de un binario en bruto) voy a tratar de compilarlo"
		echo "y esperemos lo mejor"
		echo
		echo "**NOTA** SPECFORM es parte de una colección de utilitarios de John Elliott"
		echo "que puedes descargar sus fuentes desde: http://www.seasip.info/ZX/unix.html"
		echo

		cd bin
		gcc -o specform specform.c
		cd ..

		if [ ! -e "./bin/specform" ]; then
			echo "Sigo sin encontar specform, no puedo continuar"
			exit 1
		fi
fi

#org 7000h
org=28672

nombre=selz80

sjasmplus --nologo --lst --lstlab --raw=${nombre}.obj ${nombre}.asm

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

./cpcxfs < commands

cd ..

if ! command -v fuse >/dev/null 2>&1; then

	echo
	echo
	echo "ADVERTENCIA: no encuentro el emulador FUSE, así que no podrás probar"
	echo "el resultado, puede buscar en https://fuse-emulator.sourceforge.net/"
	echo "o bien descargarlo desde tu gestor de paquetes favorito"
	echo

else

	#TODO pronto, ahora hay que probar con un emulador (FUSE en este caso)

	#fusexec="fuse-sdl"
	fusexec="fuse"

	# argumentos para fuse con el propósito de un testeo rápido
	#--snapshot file
	#--tape file
	exec_args="--machine plus3 \
	--simpleide \
	--multiface3 \
	--plus3disk ./selz80.dsk \
	--rom-plus3-0 ./p3t_rom0.rom \
	--rom-plus3-1 ./p3t_rom1.rom \
	--rom-plus3-2 ./p3t_rom2.rom \
	--rom-plus3-3 ./p3t_rom3.rom \
	--simpleide-masterfile ./+3e8bits.hdf \
	--graphics-filter tv4x \
	--pal-tv2x \
	--drive-plus3a-type 'Double-sided 80 track' --drive-plus3b-type 'Double-sided 80 track'"

	comando="${fusexec} ${exec_args}"

	echo 
	echo
	echo "***********************************************************************************************"
	echo EJECUTANDO:
	echo
	echo $fusexec $exec_args
	echo "***********************************************************************************************"

	eval $comando > /dev/null 2>&1

fi

#LIMPIEZA
#rm -f "${nombre}.bin"
#rm -f "${nombre}.dsk"
#rm -f "${nombre}.obj"
#rm -f "${nombre}.lst"
