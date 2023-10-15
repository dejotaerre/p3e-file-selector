; ==================================================================================================
; POSICIONA EL PUNTERO EN LA PAGINA RAM INDICADA POR "A"
; EJ:	LD A,5
;	CALL GOZ80_PAG
;
; RETORNA EN HL LA CANTIDAD DE BYTES A LEER Y A=NRO DE PAGINA RAM

GOZ80_PAG:	LD	(COMP_PAG+1),A
		CALL	GOZ80_FIRSTPAG

		JR	C,BUSCAR_PAG	; EN CAMBIO SI "NC" ES UN Z80 DE 48K QUE TIENE LOS DATOS
		LD	HL,6912		; COMPRIMIDOS A PARTIR DE LA CABECERA DE 30 BYTES, ASI QUE
		JP	LOAD_Z80PAGE	; CARGO 6912 BYTES COMO MINIMO DESDE #06 (lo correcto sería
					; leer todos los bytes que se pueda a partir de los primeros
					; 30 ($1E) bytes)

BUSCAR_PAG:	LD	B,12		; SE PUEDE TENER HASTA 12 PAGINAS TEORICAMENTE HABLANDO VER:
SLBUSC_PAG:	PUSH	BC		; https://worldofspectrum.org/faq/reference/z80format.htm
		CALL	GET_PINFO

COMP_PAG:	CP	$00
		JR	Z,FOUND_PAGE

		PUSH	HL
		CALL	GET_Z80POS
		POP	BC
		ADD	HL,BC
		JR	NC,NO_OVERFLOW
		INC	E
NO_OVERFLOW:	CALL	SETZ80_POS_EHL
		POP	BC
		DJNZ	SLBUSC_PAG
		AND	A		; RETORNO "NZ" SI NO ENCONTRE LA PAGINA
		RET

GET_PINFO:	CALL	SREAD16		; RETORNA HL=CANTIDAD DE BYTES
		PUSH	HL		; COMPRIMIDOS Y A=NRO. PAGINA RAM
		CALL	SREAD08		; EN DONDE SE DEBERIA DESCOMPRIMIR
		POP	HL
		SUB	$03
		AND	$07
		RET

FOUND_PAGE:	POP	BC		; CARGO EN $C000 LA PAGINA COMPRIMIDA
		CALL	LOAD_Z80PAGE	; A PARTIR DE LA POSICION DEL ARCHIVO
		RET			; #06 EN USO

/*

Es tu responsabilidad cerrar #06 al retornar, y también es tu responsabilidad
hacer lo que quieras con esta página comprimida

Mi idea original (en mi demo) es descomprimir y volcar los 6912 bytes comprimidos
a partir de 49152 hacia 16384 para ver la pantalla del Z80, o bien guardarla en
disco..., o bien hacer lo que quieras con ella.

Para ello en la etiqueta Z80PAG_UNP tenés una rutina que descomprime páginas
del Z80 a la que se le entra con 

IX = origen (49152 en este caso a menos que modifiques LOAD_Z80PAGE)
HL = destino (destino de los bytes descomprimidos)
DE = cantidad_bytes_a_descomprimir (si es 0 descomprime los 16K enteros)

EJ: para descomprimir la pantalla

LD IX,$C000
LD HL,$4000
LD DE,$1B00
CALL Z80PAG_UNP

*/

; ==================================================================================================
; POSICIONA EL PUNTERO LUEGO DE LA CABECERA DEL Z80
;
GOZ80_FIRSTPAG:	LD	HL,$001E	; POSICION LUEGO DE LA CABECERA
		CALL	SETZ80_POS_HL

		CALL	SREAD08		; LEVANTO LONGITUD DE LA CABECERA EXTENDIDA
		PUSH	AF
		CALL	SREAD08		; ES SOLO PARA MOVERME AL SIG. BYTE
		POP	AF		; NO ME IMPORTA SU VALOR

		CP	$17		; SNAP V2 (normal)
		JR	Z,OK_Z80_HEADER
		CP	$36
		JR	Z,OK_Z80_HEADER	; SNAP V3 (normal)
		CP	$37
		JR	Z,OK_Z80_HEADER	; SNAP V3 (ext)

		LD	HL,$001E	; REPOCICIONO AL FINAL DE LA CABECERA, YA
		CALL	SETZ80_POS_HL	; QUE NO DETECTÉ CABECERA EXTENDIDA, Y RETORNO
		AND	A		; "NC" PARA INDICAR QUE ES UN SNAP de 48K v2
		RET

OK_Z80_HEADER:	LD	L,A
		LD	H,$00
		LD	BC,$0020	; FIJATE QUE AL HABER LEIDO 2 BYTES MAS ESTOY
		ADD	HL,BC		; POSICIONANDO EN $1E + $02
		CALL	SETZ80_POS_HL
		JP	NC,ERR_P3DOS
		RET

; ==================================================================================================
; POSICIONA EL PUNTERO EN HL DEL ARCHIVO #06
;
SETZ80_POS_HL:	LD	E,$00

; ==================================================================================================
; POSICIONA EL PUNTERO EN EHL DEL ARCHIVO #06
;
SETZ80_POS_EHL:	LD	B,$06
		LD	D,$00
		LD	IY,DOS_SET_POSITION
		CALL	P3DOS
		JP	NC,ERR_P3DOS
		RET

; ==================================================================================================
; OBTIENE EL PUNTERO DEL ARCHIVO #06 Y LO RETORNA EN 'EHL'
;
GET_Z80POS:	LD	B,$06
		LD	IY,DOS_GET_POSITION
		CALL	P3DOS
		JP	NC,ERR_P3DOS
		RET

; ==================================================================================================
; RUTINAS DE APOYO PARA LA LECTURA DE LOS SNAPs DESDE DISCO
; (conserva IX)
;
SREAD16:	CALL	SREAD08		; RETORNA EN HL LA PALABRA LEIDA DEL
		PUSH	AF		; ARCHIVO ABIERTO EN #06
		CALL	SREAD08
		LD	H,A
		POP	AF
		LD	L,A
		RET

SREAD08:	LD	BC,$0607	; RETORNA EL "A" EL BYTE LEIDO DEL
		LD	DE,$0001	; ARCHIVO ABIERTO EN #06
		LD	HL,ZBYTE+1	; DIRECCION DE CARGA DEL BYTE
		LD	IY,DOS_READ
		CALL	P3DOS
		JP	NC,ERR_P3DOS
ZBYTE:		LD	A,$00
		RET

; ==================================================================================================
; DESCOMPRIME PANTALLA
; HL = CANTIDAD DE BYTES COMPRIMIDOS A LEER DESDE DISCO
;
LOAD_Z80PAGE:	LD	BC,$0600	; CARGO EN PAG0 EL ARCHIVO ABIERTO
		LD	DE,$C000	; EN #06 A PARTIR DE $C000
		EX	DE,HL
		LD	IY,DOS_READ
		CALL	P3DOS
		JP	NC,ERR_P3DOS
		RET

; ================================================================================================== 
/*
Explicación de cómo es el formato Z80 lo podés encontrar en:
https://worldofspectrum.org/faq/reference/z80format.htm

(a continuación una traducción literal al español del método de comprensión)

"El método de compresión es muy simple: reemplaza repeticiones de al menos cinco bytes 
iguales por un código de cuatro bytes ED ED xx yy, que significa "byte yy repetido xx veces". 

Solo se codifican secuencias de longitud igual o superior a 5. La excepción son las secuencias 
que consisten en ED's; si se encuentran, incluso dos ED's se codifican como ED ED 02 ED. 

Finalmente, cada byte que sigue directamente a un solo ED no se toma en cuenta en un bloque, 
por ejemplo, ED 6*00 no se codifica como ED ED ED 06 00, sino como ED 00 ED ED 05 00

El bloque se termina con un marcador de final, 00 ED ED 00"
*/

BLOCKID:	EQU	$ED		; MARCADOR DE BLOQUES DE BYTES REPETIDOS

Z80PAG_UNP:	LD	A,(IX+0)	; IX=PUNTERO DE LOS BYTES COMPRIMIDOS
		LD	C,A
		CP	BLOCKID
		JR	NZ,BYTE_NOREP	; BYTE NO REPETIDO (PERO QUE NO ES $ED)

		INC	IX		; AVERIGUO SI ES UN BYTE UNICO $ED
		LD	A,(IX+0)
		LD	C,A
		CP	BLOCKID
		JR	NZ,UN_SOLO_ED	; NZ = UNICO BYTE $ED

		INC	IX		; ... ENTONCES SON BYTES REPETIDOS
		LD	B,(IX+0)	; CARGO CANTIDAD DE REPETICIONES EN B
		INC	IX
		LD	C,(IX+0)	; CARGO BYTE A COPIAR EN C
		INC	IX

LOOP_BREP:	LD	(HL),C		; COPIO LAS REPETICIONES
		INC	HL
		DEC	DE
		LD	A,D
		OR	E
		RET	Z
		DJNZ	LOOP_BREP
		JR	Z80PAG_UNP

UN_SOLO_ED:	LD	C,A		; CUANDO ES UN SOLO $ED SEGUIDO
		LD	(HL),BLOCKID	; POR OTRO BYTE
		INC	HL
		DEC	DE
		LD	A,D
		OR	E
		RET	Z
		LD	(HL),C
		INC	HL
		INC	IX
		DEC	DE
		LD	A,D
		OR	E
		RET	Z
		JR	Z80PAG_UNP

BYTE_NOREP:	LD	(HL),C		; CARGO UN BYTE NO REPETIDO SIN SER $ED
		INC	IX
		INC	HL

UNP_NEXT_DE:	DEC	DE
		LD	A,D
		OR	E
		RET	Z
		JR	Z80PAG_UNP
