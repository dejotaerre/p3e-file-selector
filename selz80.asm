; ZX SPECTRUM +3E 8-BITS w/TAP SUPPORT & FILE BROWSER

		ORG	$7000

LISTCOLS:	EQU	4			; CANTIDAD DE COLS MULTIPLO DE 2
						; ASI QUE EN LA PRACTICA PUEDE
						; SER 2 o 4 POR FILA, POR QUE 8
						; NOMBRES POR FILA NO ENTRAN NI
						; SIQUIERA CON UNA RUTINA DE 64C
						; (revisar para 2 columnas en 32c)

FILAS:		EQU	$14			; CANT MAXIMA DE FILAS (20)

ROW_START:	EQU	$02			; FILA DE COMIENZO DE LOS NOMBRES

S_ATTR:		EQU	$0D			; ATTR PRINCIPALES DEL SELECTOR
S_BORDER:	EQU	$01			; BORDER DEL SELECTOR

B_PAPER_DEF:	EQU	$01			; FONDO AZUL DEL SELECTOR DE ARCHS
B_INK_DEF:	EQU	$05			; TINTA CYAN DEL SELECTOR DE ARCHS
B_BRIGHT_DEF:	EQU	$00			; SIN BRILLO DEL SELECTOR DE ARCHS

S_PAPER_DEF:	EQU	$00			; FONDO NEGRO  PARA LA BARRA DE ESTADO
S_INK_DEF:	EQU	$07			; TINTA BLANCA PARA LA BARRA DE ESTADO
S_BRIGHT_DEF:	EQU	$01			; CON BRILLO   PARA LA BARRA DE ESTADO

PF_PUNT:	EQU	$17			; FILA DEL INDICADOR NUMÉRICO DE ARCHIVOS
PC_PUNT:	EQU	$02			; COL  DEL INDICADOR NUMÉRICO DE ARCHIVOS

/*
PARA-HACER: AVERIGUAR SI ES UN +3E, CASO CONTARIO RETORNAR CON ALGUN ERROR

Aunque bien mirado si haces esto no se podrá usar en un +3 sin ROMs +3E, aunque tampoco tiene mucho
sentido usar esta utilidad cuyo único soporte de almacenamiento es un floppy, ya que el mismo
guardaría con suerte unos 3 o 4 Z80s y con suerte un par de TAPs chicos
*/

START:		LD	(GUARDA_STACK),SP
		LD	SP,MYSTACK

		CALL	INICIAR			; INICIALIZO ESTA UTILIDAD

		CALL	SELEC_ARCH		; SALTO AL BUCLE PRINCIPAL DE SELECCIÓN DE
						; DE ARCHIVOS

RET_SELECT:	CALL	TEST_CAPS
		JR	NZ,NO_CAPS

		LD	A,$01			; DEJO UN 1 EN 23681 SI SE PRESIONÓ ENTER JUNTO A
		LD	(FREE_SYSVAR),A		; CAPS SHIFT
		JR	NEXT_LOAD

NO_CAPS:	CALL	TEST_SHIFT		; DEJO UN 2 EN 23681 SI SE PRESIONÓ ENTER JUNTO A
		JR	NZ,NEXT_LOAD		; SYMBOL SHIFT
		LD	A,$02
		LD	(FREE_SYSVAR),A

NEXT_LOAD:	LD	HL,(DIR_NAME)		; CALCULO LA DIRECCION DE LA EXTENSION DEL
		LD	DE,$0008		; ARCHIVO Y SE LA DEJO AL BUSCADOR DE LAS
		ADD	HL,DE			; RUTINAS DE CARGA
		LD	(LFIND_LOADER+1),HL

FIND_LOADER:	LD	HL,LOADERS		; TABLA DE SALTOS A LOS CARGADORES

LFIND_LOADER:	LD	DE,$0000		; BUCLE PRINCIPAL PARA BUSCAR EN LA TABLA
		LD	A,(HL)
		AND	A
		JP	Z,FREEZE		; ¿LLEGUE AL FINAL DE LA TABLA SIN EXTENSIÓN
						; CONOCIDA?

		LD	B,3			; COMPARO 3 CARACTERES PARA LA EXTENSION
		LD	C,$00			; CUENTO EN "C" LAS COINCIDENCIAS

SIG_EXT_CHAR:	LD	A,(DE)			; COMPARO EXTENSION CON LA TABLA
		CP	(HL)
		JR	NZ,FIND_NEXT_EXT
		INC	C			; SI COINCIDE INCREMENTO COINCIDENCIAS
FIND_NEXT_EXT:	INC	HL			; PASO AL SIGUIENTE CARACTER DE
		INC	DE			; LA TABLA DE EXTENSIONES
		DJNZ	SIG_EXT_CHAR

		LD	E,(HL)			; CARGO EN "DE" DIRECCION DE LA
		INC	HL			; RUTINA DE CARGA
		LD	D,(HL)
		INC	HL

		LD	A,C
		CP	$03			; ¿CUANTOS CHARS COINCIDEN? SI NO SON 3
		JR	NZ,LFIND_LOADER		; PASO A SIGUIENTE EXTENSION DE LA TABLA

		EX	DE,HL
		JP	(HL)			; SALTO A LA RUTINA DE CARGA

; ==================================================================================================

/*
PROBLEMA PARA CARGAR PANTALLA DE HUMPREY.Z80
DEJALO ASI COMO ESTA Y AVERIGUA QUE PASA
*/

LOAD_Z80:	LD	HL,(DIR_NAME)		; COPIO EL NOMBRE SELECCIONADO (8.3)
		LD	DE,FILENAME		; (EL TIPO Z80 ES LO UNICO QUE CARGO
		LD	BC,$0008		; DIRECTO SIN RETORNAR A BASIC)
		LDIR
		LD	A,"."
		LD	(DE),A
		INC	DE
		LD	C,$03
		LDIR
		LD	A,$FF
		LD	(DE),A
		LD	A,(FREE_SYSVAR)
		CP	2			; FUE CON SHIFT?
		JR	Z,MOSTRAR_Z80SCR
		CP	1			; FUE CON CAPS?
		JR	Z,CARGAR_Z80_ALT

; ==================================================================================================

		CALL	CLS_NEGRO		; BORRO PANTALLA EN NEGRO COMPLETO
		JP	DO_LOAD_Z80		; ESTA ETIQUETA ESTA EN runz80.asm

; ==================================================================================================

CARGAR_Z80_ALT:	JP	DO_RUNZ80		; CAPS+ENTER CARGA EL Z80 CON MI RUTINA

; ==================================================================================================

MOSTRAR_Z80SCR:	CALL	BACKUP_SCR		; RESPALDO LA PANTALLA EN 7

		XOR	A
		CALL	CLS_NEGRO2

		CALL	LOAD_Z80_SCR		; CARGO DESDE EL Z80 LA PANTALLA
		CALL	WAIT_KEY		; ESPERO POR UNA TECLA

		LD	A,(BORDCR)		; REESTABLEZCO EL BORDER SEGUN "BORDCR"
		RRCA
		RRCA
		RRCA
		AND	$07
		OUT	($FE),A

		LD	HL,$4000		; COPIO LA PANTALLA EN 49152 PARA QUE
		LD	DE,$C000		; HAGAS LO QUE QUIERAS CON ELLA
		LD	BC,$1B00
		LDIR

		LD	A,12
		LD	BC,$0007		; RETORNO A BASIC CON USR=7
		CALL	PRINT
		JP	RETBAS

; ==================================================================================================

/*
TENGO PROBLEMAS PARA CARGAR LA PANTALLA DE HUMPREY.Z80
DEJALO ASI COMO ESTA, Y AVERIGUA QUE PASA
*/
LOAD_Z80_SCR:	LD	BC,$0601		; abre el archivo con handle #06
		LD	DE,$0002
		LD	HL,FILENAME
		LD	IY,DOS_OPEN
		CALL	P3DOS
		JP	NC,ERR_P3DOS

		LD	HL,$0000		; POSICIONA EN 'EHL' EL ARCH. #06
		LD	DE,$0000		; D=PAGINA ARRIBA
		LD	B,$06			; NRO DE "HANDLE"
		LD	IY,DOS_SET_POSITION
		CALL	P3DOS
		JP	NC,ERR_P3DOS
 
		LD	A,5
		CALL	GOZ80_PAG		; BUSCA LA PAGINA 5 (GENERALMENTE PAG8 EN EL Z80)

		LD	IX,$C000		; DIRECCION DE LOS BYTES COMPRIMIDOS
		LD	HL,$4000		; DIRECCION EN DONDE LOS DESCOMPRIMO
		LD	DE,$1B00		; MAXIMO DE BYTES A DESCOMPRIMIR
		CALL	Z80PAG_UNP

		LD	B,$06			; cierra el archivo...
		LD	IY,DOS_CLOSE
		CALL	P3DOS
		JP	NC,ERR_P3DOS

		RET

/*
MODO DE USO DESDE BASIC:

RETORNOS EN EL REGISTRO BC, o sea la llamada con USR retorna dicho valor:

0 - CANCELADO (se presionó SPACE)

1 - Se seleccionó un archivo TAP cuyo nombre es retornando en el contenido de una variable con el
    nombre N$, dicho de otro modo para cargar el archivo seleccionado:

    LET n$ = "12345678.123"
    LET bc = USR 28671
    IF bc = 1 THEN SPECTRUM n$: LOAD ""

2 - Idem anterior pero se seleccionó el archivo con CAPS+ENTER por si se quiere hacer algo diferente
    ejemplo:

    LET n$ = "12345678.123"
    LET bc = USR 28671
    IF bc = 1 THEN SPECTRUM n$: MERGE ""

3 - Idem anterior pero con SHIFT+ENTER

4 - Se seleccionó un archivo BASIC basado en las extensiones (ver en la etiqueta LOADERS), si es 
    *.BAS, *.B, o sin extensión lo considero un archivo BASIC

5 - Se seleccionó un archivo binario de 6912 bytes de longitud (probablemente una pantalla)

6 - Se seleccionó un archivo binario (to-do: hacer variables para dejar inicio,longitud)

*/
; ==================================================================================================

LOAD_TAP:	CALL	COPY_NAME		; ARCHIVO CON EXTENSION "TAP"
		LD	A,(FREE_SYSVAR)		; RETORNO A BASIC PARA QUE HAGAS
		LD	BC,$0001		; SPECTRUM n$: LOAD ""
		ADD	A,C			; PERO TAMBIEN RETORNA EN BC 2
		LD	C,A			; SI SE SELECCIONO EL ARCHIVO CON
		JR	RETBAS			; SHIFT, Y 3 SI FUE CON CAPS, PARA
						; QUE TENGAS 2 ACCIONES EXTRAS POSIBLES
						; EN TU BASIC CARGADOR

; ==================================================================================================

LOAD_BAS:	CALL	COPY_NAME		; ARCHIVO BASIC RETORNO A BASIC
		LD	BC,$0004		; PARA QUE HAGAS: LOAD n$
		JR	RETBAS

; ==================================================================================================
; 

LOAD_SCR:	CALL	COPY_NAME		; ARCHIVO PANTALLA (CODE xxxxx,6912)
		LD	BC,$0005
RETBAS:		LD	SP,(GUARDA_STACK)
		RET
; ==================================================================================================
; TO-DO: LEER CABECERA Y DECIRLE AL BASIC SI LO SELECCIONADO ES UN binario,
; PERO SI EL TAMAÑO ES 6912 SIGNIFICA QUE ES UN SCREEN$ ENTONCES SALTAR A
; LOAD_SCR (sugerencia: usar 2 vars numéricas para dejar dirección de carga y
; tamaño, y que el programador haga lo que crea necesario con este archivo)

LOAD_BIN:	CALL	COPY_NAME		; ARCHIVO BIN (c/m)
		LD	BC,$0006
		JP	RETBAS

; ==================================================================================================

COPY_NAME:	LD	A,$4E			;ID DE VARIABLE "N$" EN DONDE VOY
		CALL	BUSC_VAR		;A VOLCAR EL NOMBRE SELECCIONADO (8.3)
		JR	NZ,NO_EXISTE_NP

		INC	HL			;OJO!!! QUE NO CONTROLO SI LA VARIABLE
		INC	HL			;TIENE EL TAMAÑO ADECUADO. DEBE TENER
		INC	HL			;8+1+3 CARACTERES, ejemplo:
		EX	DE,HL			;LET N$="nnnnnnnn.eee"
		LD	HL,(DIR_NAME)
		LD	BC,$0008
		LDIR			
		LD	A,"."		
		LD	(DE),A
		INC	DE
		LD	BC,$0003
		LDIR
		RET

NO_EXISTE_NP:	LD	HL,MSG_ERROR_NP		;RETORNO A BASIC SI NO EXISTE N$
		LD	A,26
		CALL	PRINT
		RST	08H
		DB	$01			;2 Variable not found

; ==================================================================================================
; INICIALIZO ESTA UTILIDAD

INICIAR:	LD	HL,DATE			; COPIO EL AÑO DE ENSAMBLADO
		LD	DE,YEAR			; EN EL TITULO DE LA LINEA DE
		LD	BC,$0004		; DE PRESENTACION
		LDIR

		XOR	A			; RESETEO LA VARIABLE INDICADORA DEL
		LD	(FREE_SYSVAR+1),A	; TIPO DE SELECCION PARA USARSE DESDE BASIC

		LD	HL,$0000		; DESACTIVO RUTINA ALERT
		LD	IY,DOS_SET_ALERT
		CALL	P3DOS

		LD	A,$FF			; PAGINA INICIAL DEL SELECTOR DE
		LD	(PAGINA_ACTUAL),A	; ARCHIVOS

		LD	H,S_BORDER		; COLOR DEL BORDE
		LD	L,S_ATTR		; COLOR DE LOS ATRIBUTOS
		LD	A,H
		OUT	($FE),A
		LD	A,L
		LD	(BORDCR),A
		LD	(MASKP),A
		LD	(COLOR),HL		; SE LO DEJO A PRINT 42c

		LD	HL,MSG_INIT
		JP	PRINT_MSG

; ==================================================================================================

SELEC_ARCH:	XOR	A
		LD	(FREE_SYSVAR),A
		LD	HL,CATBUFFER		; LIMPIO EL BUFFER PARA EL CATALOGO
		LD	DE,CATBUFFER+1		; (NUNCA SE SABE)
		LD	BC,$C000-CATBUFFER
		LD	(HL),$00
		LDIR

		LD	A,$FF			; MAXIMO 256 NOMBRES DE
		LD	(CANT_NOMBRES),A	; ARCHIVOS POR UNIDAD

		LD	B,$FF			; CONTROLA EL RETORNO DE B
						; Y SEGUIR EN LOOP HASTA QUE
						; RETORNE TODO EL CAT
						; (VER MANUAL DOS_CATALOG)
		
		LD	C,$00
		LD	DE,CATBUFFER
		LD	HL,FILEMASK
		LD	IY,DOS_CATALOG		; lee el CATálogo según FILEMASK
		CALL	P3DOS
		JR	C,OK_MASK

ERR_P3DOS:	LD	(NR_ERR_RST8),A
		RST	08H			; CAT encontró un problema
NR_ERR_RST8:	DB	$FF			; y "A" TIENE EL ID DEL ERROR

OK_MASK:	LD	HL,CATBUFFER+13		; POR QUE SUMO 13? (VER MANUAL +3DOS
		LD	DE,BUFFERNAMES		; EN DOS CATALOG 011Eh)
		DEC	B

LFORM_NAME:	LD	A,(HL)
		AND	A
		JR	Z,NO_MAS_ARCHS

		PUSH	BC

		LD	B,$08+$03+$02		; FILENAME 8 CARACTERES + 3 DE EXTENSIÓN
LLEFT_NAME:	LD	A,(HL)			; y +2 QUE CONTIENE EL TAMAÑO
		LD	(DE),A
		INC	DE
		INC	HL
		DJNZ	LLEFT_NAME

		POP	BC

		LD	A,(CANT_NOMBRES)	; voy acumulando la cantidad
		INC	A			; de nombres en la unidad
		LD	(CANT_NOMBRES),A

		DJNZ	LFORM_NAME		; repito al siguiente nombre

NO_MAS_ARCHS:	LD	A,(CANT_NOMBRES)	; fin del catálogo, retorno
		CP	$FF			; con error si no se procesó
		JP	NZ,START_SELECT		; ningún archivo

		RST	08H			; g File does not exist
		DB	34			; (NO HAY NINGUN ARCHIVO según FILEMASK
						; o DICHO DE OTRO MODO... DISCO VACIO)
					
; ==================================================================================================
; IMPRIME LA PAGINA DE ARCHIVOS QUE CORRESPONDE AL ARCHIVO EN (PUNT_NAME)
; ==================================================================================================

PR_PAGE_PUNT:	LD	L,A
		LD	H,0
		LD	C,FILAS*LISTCOLS	; (CADA pag TIENE FILAS*LISTCOLS NOMBRES)
		CALL	DIV_HL_C
		LD	A,(PAGINA_ACTUAL)
		CP	L			; ES LA MISMA PAGINA YA IMPRESA?
		RET	Z
		
		LD	A,L
		LD	(PAGINA_ACTUAL),A
		
		CALL	STATUS_BAR		; LINEA DE ESTADO & AT 23,0
		
		LD	A,(PUNT_NAME)		; SI ESTOY MOSTRANDO UNA PAGINA NUEVA
		LD	(PUNT_ANT),A		; INVALIDO EL PUNTERO ANTERIOR

PR_PAGE:	LD	A,(PAGINA_ACTUAL)
		LD	B,A
		LD	DE,FILAS*LISTCOLS*13	; CADA pag TIENE en BYTES
		LD	HL,$0000		; FILAS*LISTCOLS*((8+3)+2)
		AND	A
		JR	Z,NOMUL
LMULT_NAME:	ADD	HL,DE
		DJNZ	LMULT_NAME

NOMUL:		LD	DE,BUFFERNAMES
		ADD	HL,DE

		LD	B,FILAS			; FILAS
LFILA_N:	PUSH	BC

		LD	B,LISTCOLS		; COLUMNAS
LCOL_N:		PUSH	BC

		LD	B,8
LP_NAME:	LD	A,(HL)
		CALL	PRINT
		INC	HL
		DJNZ	LP_NAME

		INC	HL			; (salto extensión)
		INC	HL
		INC	HL

		INC	HL			; (salto tamaño)
		INC	HL

		POP	BC
		LD	A,(HL)
		AND	A
		JR	Z,EXIT_NOMBRES
		
		LD	A,B
		CP	$01
		JR	Z,NOESP_COL

		LD	A,32			; variar cant de espacios si es necesario
		CALL	PRINT			; para una página diferente a 4 archivos
		CALL	PRINT			; por linea, por ej: en una pagina de 2
						; archivos por linea en 32c estaría bien
						; un solo espacio y no 2 como caso de 42c
						; para evitar coliciones
NOESP_COL:	DJNZ	LCOL_N
		
FIN_NOMRES:	POP	BC
		LD	A,B
		CP	$01
		JR	Z,NOENTER
		LD	A,13
		CALL	PRINT
NOENTER:	DJNZ	LFILA_N
		RET

EXIT_NOMBRES:	POP	BC
		RET

; ==================================================================================================
; MUESTRO LA EXTENSION DEL ARCHIVO SELECCIONADO EN LA BARRA DE ESTADO Y HL QUEDA POSICIONADO EN
; DONDE ESTÁ EL TAMAÑO DE ARCHIVO, (DE Y BC SE CONSERVAN)
; ==================================================================================================

PR_FILE_EXT:	PUSH	BC
		PUSH	DE

		PUSH	HL
		LD	DE,(FILA)
		LD	HL,POSEXT
		CALL	PRINT_MSG
		LD	HL,COLORSPUNT
		CALL	PRINT

		LD	A,"("
		CALL	PRINT

		POP	HL

		LD	B,3
LPR_EXT:	LD	A,(HL)
		CALL	PRINT
		INC	HL
		DJNZ	LPR_EXT
		PUSH	HL			; HL QUEDA POSICIONADO LUEGO DE LA EXTENSION EN
		LD	A,")"			; DONDE ESTA EL TAMAÑO EN K QUE DEVOLVIO DOS_CATALOG
		CALL	PRINT

		LD	HL,RCOLORS_BRW		; REESTABLESCO COLORES DEL BROWSER
		CALL	PRINT_MSG

		LD	(FILA),DE
		
		POP	HL
		POP	DE
		POP	BC
		RET

; ==================================================================================================
; MUESTRO TAMAÑO EN KB DEL ARCHIVO SELECCIONADO EN LA BARRA DE ESTADO
; ==================================================================================================

PR_FILE_SIZE:	LD	E,(HL)
		INC	HL
		LD	D,(HL)

		LD	HL,POSSIZE
		CALL	PRINT_MSG
		LD	HL,COLORSPUNT
		CALL	PRINT_MSG

		LD	A,14		;MUESTRO EL NÚMERO DEL TAMAÑO CARGADO EN HL
		EX	DE,HL
		CALL	PRINT

		LD	HL,KB_MSG	;MUESTRO LA LETRA "K" Y ALGUNOS ESPACIOS
		CALL	PRINT_MSG

		LD	HL,RCOLORS_BRW
		CALL	PRINT_MSG

		RET

; ==================================================================================================
; DESTACA EL ARCHIVO (PUNT_NAME) Y "DES"-DESTACA EL ARCHIVO (PUNT_ANT)
; ==================================================================================================
		
MARCAR_ACTUAL:	XOR	A			;PRIMERO DESMARCO
		LD	(INV_NOMBRE+1),A	;EL ARCH. ANTERIOR
		LD	A,(PUNT_ANT)		;CON VIDEO "NORMAL"
		CALL	DO_MARCAR

		LD	A,1			;MARCO ARCH. ACTUAL
		LD	(INV_NOMBRE+1),A	;CON VIDEO "INVERSO"
		LD	A,(PUNT_NAME)
		LD	(PUNT_ANT),A
		CALL	DO_MARCAR

		CALL	PR_FILE_EXT		;MUESTRO EXTENSION EN
		JP	PR_FILE_SIZE		;BARRA DE ESTADO Y
						;TAMAÑO EN Ks

; ==================================================================================================
; HAGO EL DESTAQUE DEL ARCHIVO SELECCIONADO CON VIDEO INVERSO Y SE LO QUITO AL ANTERIOR
; ==================================================================================================

DO_MARCAR:	PUSH	AF
		LD	HL,$0000
		LD	DE,FILAS*LISTCOLS

		LD	A,(PAGINA_ACTUAL)
		AND	A
		JR	Z,NOMULT_OFFSET
		LD	B,A
LMUL_OFFSET:	ADD	HL,DE
		DJNZ	LMUL_OFFSET

NOMULT_OFFSET:	POP	AF
		PUSH	AF
		LD	E,A
		LD	D,$00
		AND	A
		EX	DE,HL
		
		SBC	HL,DE			; HL CONTIENE UN No. ENTRE 0 Y 95 
						; que viene siendo el offset de 
						; archivo dentro de la pagina en
						; curso - de aca voy a sacar la
						; fila y columna que debo usar

		LD	A,L
		AND	%00000011
		LD	C,A
		AND	A
		JR	Z,NOMULTCOL
		XOR	A
		LD	B,10			; MULTIPLICO COL * 10
LMULTCOL:	ADD	A,C
		DJNZ	LMULTCOL
		LD	C,A
NOMULTCOL:	LD	A,L
		AND	%11111100
		RRCA
		RRCA
		LD	B,A			; B CONTIENE LA FILA Y C LA COLUMNA
		
		POP	AF			; RECUPERO PUNTERO
		LD	D,A
		LD	E,8+3+2			; (8.3) FILENAME+EXTENSION +2 TAMAÑO
		CALL	MULT_DxE		; MULTIPLICO PUNTERO POR 13
		LD	DE,BUFFERNAMES
		ADD	HL,DE			; FINALMENTE TENGO EN HL LA DIR DEL
						; NOMBRE EN B LA FILA Y EN C LA COLUMNA
						; EN DONDE IMPRIMIR EL NOMBRE

		LD	(DIR_NAME),HL		; DEJO EN DIR_NAME LA DIRECCION DEL
						; NOMBRE SELECCIONADO *!!!
				
		LD	A,22			; CONTROL AT
		CALL	PRINT
		LD	A,ROW_START
		ADD 	A,B
		CALL	PRINT			; FILA
		LD	A,C
		CALL	PRINT			; COLUMNA
		LD	A,20	
		CALL	PRINT			; CONTROL INVERSE

INV_NOMBRE:	LD	A,1
		CALL	PRINT

		LD	B,8			; 8 CARACTERES

LPR_NOMBRESEL:	LD	A,(HL)
		CALL	PRINT
		INC	HL
		DJNZ	LPR_NOMBRESEL
		LD	A,(INV_NOMBRE+1)
		AND	A
		RET	Z
		LD	A,20			; ES necesario reestablecer inv 0
		CALL	PRINT
		XOR	A
		CALL	PRINT
		RET

; ==================================================================================================
; BUSCA LA VARIABLE BASIC CUYO ID VIENE EN 'A'
; SALIDA: SI SE ENCUENTRA. 'Z=TRUE' HL=DIRECCION_VARIABLE
;	  SI NO SE ENCUENTRA. 'NZ=TRUE'
;
BUSC_VAR:	LD	HL,(VARS)
		LD	B,A
		LD	C,$80
LBUSC_VAR:	LD	A,C
		CP	(HL)
		JR	Z,NO_BUSC_VAR
		LD	A,B
		CP	(HL)
		JR	Z,OK_BUSC_VAR
		PUSH	BC
		CALL	FINDNEXT
		POP	BC
		EX	DE,HL
		JR	LBUSC_VAR
NO_BUSC_VAR:	CP	B
		LD	HL,$0000
OK_BUSC_VAR:	PUSH	HL
		POP	BC
		RET

; ==================================================================================================

PRINT_MSG:	LD	A,26			;LLAMO A MI RUTINA DE IMPRESION
		JP	PRINT			;PARA MOSTRAR MSG TERMINADO EN $FF

; ==================================================================================================

PRINT_PUNTERO:	LD	HL,POSPUNT	;POSICIONO PARA IMPRIMIR
		CALL	PRINT_MSG	;EL NRO DE ARCHIVO
		LD	HL,COLORSPUNT	;PONGO LOS COLORES DE LA
		CALL	PRINT_MSG	;BARRA DE ESTADO

		LD	A,(PUNT_NAME)	;LEVANTO EL NR. DE PUNTERO
		INC	A
		LD	L,A
		LD	H,$00
		LD	A,14		;IMPRIMO NR. PUNTERO
		CALL	PRINT

		LD	A,"/"		;IMPRIMO UNA SEPARACION
		CALL	PRINT

		LD	A,(CANT_NOMBRES);LEVANTO CANTIDAD DE ARCHS
		LD	H,$00		;EN EL CATALOGO
		LD	L,A
		INC	L		;+1 POR QUE ARRANCA EN "0"

		LD	A,14		;IMPRIMO LA CANTIDAD DE
		CALL	PRINT		;ARCHS. EN EL CATALOGO
		LD	A,32
		CALL	PRINT

		LD	HL,RCOLORS_BRW	;RESTABLESCO COLORES
		JP	PRINT_MSG

; ==================================================================================================

WAIT_KEY:	LD	(IY-$32),$00	; USO EXPLORACION DE TECLADO
LKEY:		LD	A,(IY-$32)	; DE LA ROM PARA NO COMPLICAR
		AND	A		; (con lo que además tengo todas las ventajas de
		JR	Z,LKEY		; repetición, retardos etc., se podría llamar a
		;PUSH	AF		; la rutina PIP aquí pero no lo justifico, descomentalo
		;LD	D,$00		; si es tu gusto)
		;LD	E,(IY-$01)
		;LD	HL,$0C80	; PONER $00C8 SI TE GUSTA MAS EL CLASICO BIP DE 48K
		;CALL	BEEPER		; EN LUGAR DEL SONIDO +3
		;POP	AF
		RET			

; ==================================================================================================

START_SELECT:	XOR	A
		LD	(PUNT_ANT),A

MAIN_LOOP:	LD	(PUNT_NAME),A
		CALL	PR_PAGE_PUNT	; MUESTRO LA PAGINA ACTUAL
		CALL	MARCAR_ACTUAL	; DESTACO EL SELECCIONADO
		CALL	PRINT_PUNTERO	; MUESTRO NRO. DE ARCHIVO

LOOP_NAVEGADOR:	CALL	WAIT_KEY	; ESPERO UNA TECLA
		AND	%11011111	; TRANSFORMO A MAYUSCULAS
		JP	Z,CANCEL	; [SPACE] (cancela)

		;¿valdrá la pena hacer una tabla de saltos?
		;si no son muchas acciones no lo creo...
		;pero si vas extendiendo esta utilidad
		;podría justificarse

		CP	11		; cursor arriba
		JR	Z,MOVE_UP

		CP	10		; cursor abajo
		JR	Z,MOVE_DOWN

		CP	8		; cursor izquierda
		JR	Z,MOVE_LEFT

		CP	9		; cursor derecha
		JR	Z,MOVE_RIGHT

		CP	4 		; pagina abajo (inc)
		JR	Z,PAGE_DOWN

		CP	5		; pagina arriba (dec)
		JR	Z,PAGE_UP

		CP	13		; [ENTER]
		JR	Z,ACEPTA

		CP	"A"		; MUESTRA AYUDA
		JP	Z,HELP

		JR	LOOP_NAVEGADOR

; ==================================================================================================

MOVE_UP:	LD	A,(PUNT_NAME)
		SUB	LISTCOLS
		JR	C,LOOP_NAVEGADOR
		JR	MAIN_LOOP	; CAMBIO DE PAGINA

; ==================================================================================================

MOVE_DOWN:	LD	A,(CANT_NOMBRES)
		LD	C,A
		INC	C
		LD	A,(PUNT_NAME)
		ADD	A,LISTCOLS
		CP	C
		JR	NC,LOOP_NAVEGADOR
		JR	MAIN_LOOP	; CAMBIO DE PAGINA

; ==================================================================================================

MOVE_LEFT:	LD	A,(PUNT_NAME)
		AND	A
		JR	Z,LOOP_NAVEGADOR
		DEC	A
		JR	MAIN_LOOP	; CAMBIO DE PAGINA

; ==================================================================================================
		
MOVE_RIGHT:	LD	A,(CANT_NOMBRES)
		LD	C,A
		LD	A,(PUNT_NAME)
		CP	C
		JR	Z,LOOP_NAVEGADOR
		INC	A
		JR	MAIN_LOOP	; CAMBIO DE PAGINA

; ==================================================================================================

PAGE_DOWN:	LD	A,(PAGINA_ACTUAL)
		INC	A
MULT_DOWN:	LD	C,FILAS*LISTCOLS
		LD	B,A
		XOR	A
LMULTPAGE:	ADD	A,C
		DJNZ	LMULTPAGE
		LD	C,A
		LD	A,(CANT_NOMBRES)
		CP	C
		JR	C,LOOP_NAVEGADOR
		LD	A,C
		JP	MAIN_LOOP

; ==================================================================================================

PAGE_UP:	LD	A,(PAGINA_ACTUAL)
		AND	A
		JR	Z,LOOP_NAVEGADOR; YA ESTOY EN LA PRIMERA
		DEC	A
		AND	A
		JP	Z,MAIN_LOOP	; CAMBIO DE PAGINA
		JR	MULT_DOWN

; ==================================================================================================

ACEPTA:		XOR	A		; SELECCIONÓ EL ARCHIVO A CARGAR
		RET			; Y AL SALIR NOS VAMOS A CARGARLO

; ==================================================================================================

CANCEL:		LD	BC,$0000	; RETORNA 0 SI EL USUARIO CANCELÓ
		JP	RETBAS		; (O SEA QUE PRESIONÓ SPACE)
					; RETORNO A BASIC DIRECTAMENTE
					; CON USR=0

; ==================================================================================================
		
CLS_NEGRO:	XOR	A		; BORDE NEGRO
		LD	(BORDCR),A	; COLOR BAJO
CLS_NEGRO2:	OUT	($FE),A
		LD	HL,$4000	; COMIENZO DE LA PANTALLA
		LD	D,H
		LD	E,L
		INC	E		; +1 PARA LDIR
		LD	BC,$1AFF	; TAMAÑO PANTALLA -1
		LD	(HL),L		; BYTE A COPIAR
		LDIR			; Y COPIAR
		HALT
		RET

; ==================================================================================================
; RUTINA DE LLAMADO AL +3DOS (esta rutina se comparte con RUNZ80 para su fase inicial, así que si
; quieres usar RUNZ80 en forma independiente deberás llevarla ahí)

; NOTA: Esta rutina es la típica que viene el manual pero con algunos arreglos para evitar la
; corrupción de IY mientras se está usando +3DOS, sin contar con que deja IY corrupto a su salida,
; ya que en "medio" se podría ejecutar alguna rutina de la ROM BASIC que se encontraría con un valor
; incorrecto en IY (para mas detalle ver en el manual CAPITULO 8 parte 26 rutina DODOS)

P3DOS:		DI
		LD	(CALLDOS+1),IY	; copio la dirección de salto y enseguida restauro IY
		LD	IY,ERR_NR	; <-- 23610
		PUSH	AF
		PUSH	BC
		LD	A,(BANKM)
		OR	%00000111
		RES	4,A
		LD	BC,PBANKM
		LD	(BANKM),A
		OUT	(C),A
		POP	BC
		POP	AF
		EI

CALLDOS:	CALL	$0000

		DI
		PUSH	AF
		PUSH	BC
		LD	A,(BANKM)
		AND	%11111000
		SET	4,A
		LD	BC,PBANKM
		LD	(BANKM),A
		OUT	(C),A
		POP	BC
		POP	AF
		EI
		RET

; ==================================================================================================
; DIVIDIR HL / C

DIV_HL_C:	XOR	A
		LD	B,16
LDIV:		ADD	HL,HL
		RLA
		CP	C
		JR	C,NDIV
		SUB	C
		INC	L
NDIV:		DJNZ	LDIV
		RET

; ==================================================================================================
; MULTIPLICA D*E Y DEJA RESULTADO EN HL

MULT_DxE:	PUSH	AF
		PUSH	BC
		LD	HL,$0000
		LD	A,D
		AND	A
		JR	Z,NOMULT_DE
		LD	B,E
		LD	E,D
		LD	D,L
LMULT_DxE:	ADD	HL,DE
		DJNZ	LMULT_DxE
NOMULT_DE:	POP	BC
		POP	AF
		RET

; ==================================================================================================
; MUESTRO TITULO Y BARRA DE ESTADO

STATUS_BAR:	LD	HL,STR_STATUSBAR1
		CALL	PRINT_MSG
		LD	HL,STR_STATUSBAR2
		JP	PRINT_MSG

; ==================================================================================================
; RETORNA Z SI ESTÁ CAPS PRESIONADA

TEST_CAPS:	LD	A,$FE
		IN	A,($FE)
		BIT	0,A
		RET

; ==================================================================================================
; RETORNA Z SI ESTÁ SHIFT PRESIONADA

TEST_SHIFT:	LD	A,$7F
		IN	A,($FE)
		BIT	1,A
		RET

; ==================================================================================================
; GUARDO UNA COPIA DE LA PANTALLA EN RAM7

BACKUP_SCR:	DI
		LD	A,$07
		LD	BC,PBANKM
		OUT	(C),A
		PUSH	BC
		LD	HL,$4000	;COPIO PANTALLA EN RAM7
		LD	DE,$C000
		LD	BC,$1B00
		LDIR
		LD	A,(BANKM)
		POP	BC
		OUT	(C),A
		EI
		RET

; ==================================================================================================
; RESTAURO UNA COPIA DE LA PANTALLA EN RAM7 EN RAM5

RESTORE_SCR:	DI
		LD	BC,PBANKM
		LD	A,$07
		OUT	(C),A
		PUSH	BC
		LD	HL,$C000	;RECUPERO PANTALLA EN RAM7
		LD	DE,$4000
		LD	BC,$1B00
		LDIR
		LD	A,(BANKM)
		POP	BC
		OUT	(C),A
		EI
		RET

; ==================================================================================================
; MUESTRO AYDA

HELP:		CALL	BACKUP_SCR		; GUARDO PANTALLA

		LD	HL,STR_STATUSBAR1	; MUESTRO LA CABECERA
		CALL	PRINT_MSG

		LD	HL,HELP_MSG		; MUESTRO LA AYUDA
		CALL	PRINT_MSG

		CALL	WAIT_KEY		; ESPERO TECLA

		CALL	RESTORE_SCR:		; RESTITUYO PANTALLA

		JP	LOOP_NAVEGADOR		; CONTINUAMOS...

; ==================================================================================================
; TEXTO, COLORES, ETC. PARA LA BARRA DEL TITULO

STR_STATUSBAR1:	DB	28,1,12			; PONGO 42c Y BORRO PANTALLA

		DB	16,S_INK_DEF		; INK PARA STATUS BAR
		DB	17,S_PAPER_DEF		; PAPER PARA STATUS BAR
		DB	19,S_BRIGHT_DEF		; BRIGHT PARA STATUS BAR

		DB	28,0			; MODO 32C
		DB	23,32			; 32 ESPACIOS EN AT 0,0

		DB	22,0,26			; RAINBOW EN 0,26 EN 32C
		DB	29,S_PAPER_DEF

		DB	28,1,22,0,0 		; MODO 42c Y AT 0,0
		DB	"  Z80 SELECTOR +3 - "	; PROGRAM NAME
		DB	"(L) "			; COPYRIGHT SYMBOL + SPACE
YEAR:		DB	"...."			; (se copia fecha ensamblado desde DATE)
		DB	" DJr"			; AUTHORSHIP

		DB	16,B_INK_DEF		; INK
		DB	17,B_PAPER_DEF		; PAPER
		DB	19,B_BRIGHT_DEF		; BRIGHT

		DB	$FF

; ==================================================================================================
; TEXTO, COLORES, ETC. PARA LA BARRA DE ESTADO

STR_STATUSBAR2:	DB	16,S_INK_DEF		; INK PARA STATUS BAR
		DB	17,S_PAPER_DEF		; PAPER PARA STATUS BAR
		DB	19,S_BRIGHT_DEF		; BRIGHT PARA STATUS BAR

		DB	28,0,22,23,0		; MODO 32C Y AT EN 23,0
		DB	23,32			; 32 ESPACIOS EN AT 23,0

		DB	28,1			; MODO 42C
		DB	22,23,34,"(A)yuda"

		DB	16,B_INK_DEF		; INK
		DB	17,B_PAPER_DEF		; PAPER
		DB	19,B_BRIGHT_DEF		; BRIGHT

		DB	22,ROW_START,0		; AT EN ROW_START,0
		DB	$FF

; ==================================================================================================
; RESET E INICIO DE PRINT

MSG_INIT:	DB	28,1,12			; PONGO 42c Y BORRO PANTALLA
		DB	16,B_INK_DEF		; E INCIALIZO
		DB	17,B_PAPER_DEF
		DB	19,B_BRIGHT_DEF
		DB	"Iniciando..."
		DB	$FF

; ==================================================================================================
; TEXTO, COLORES, ETC. PARA LA AYUDA

HELP_MSG:	DB	22,ROW_START,0		; AT EN ROW_START,0

			;REGLETA 42C PARA GUIARME MEJOR

			;0         1         2         3         4
			;012345678901234567890123456789012345678901

		DB	128,129,130,131,"  - (CURSORES) mueve puntero",13
		DB	136,138,32,137,138," - [TV] [IV] pagina arriba/abajo",13;
		DB	135,"     - ENTER selecciona archivo",13
		DB	25,134,42
		DB	"NOTA sobre la carga de TAPs:",13,13

		DB	"ENTER puede combinarse con *CAPS o *SYMBOL",13

		DB	"*SYMBOL retorna al BASIC con USR=2 en vez "
		DB	"de 1, y USR=3 cuando se lo hace con *CAPS "
		DB	"Esto es por si quieres hacer acciones",13
		DB	"diferentes en tu BASIC cargador, aparte de"
		DB	"cargar el juego con SPECTRUM n$: LOAD \"\"",13
		DB	25,134,42

		;	 012345678901234567890123456789012345678901
		DB	"Seleccionar un Z80 con *SHIFT+ENTER hace",13
		DB	"que se muestre la pantalla y retorna a",13
		DB	"BASIC con USR=7 dejando una copia de la",13
		DB	"pantalla en 49152, pero si lo haces con",13
		DB	"*CAPS, se carga el Z80 usando RUNZ80 en",13
		DB	"lugar del cargador interno del +3e",13
		DB	$FF

; ==================================================================================================

POSPUNT:	DB	22,PF_PUNT,PC_PUNT,$FF

POSEXT: 	DB	22,PF_PUNT,PC_PUNT+8,$FF

POSSIZE: 	DB	22,PF_PUNT,PC_PUNT+15,$FF

KB_MSG:		DB	"Kb     ",$FF

COLORSPUNT:	DB	17,S_PAPER_DEF
		DB	16,S_INK_DEF
		DB	19,S_BRIGHT_DEF
		DB	$FF

RCOLORS_BRW:	DB	17,B_PAPER_DEF
		DB	16,B_INK_DEF
		DB	19,B_BRIGHT_DEF
		DB	$FF

; ==================================================================================================

MSG_ERROR_NP:	DB	12,"No existe N$ para volcar el nombre en ella",$FF

; ==================================================================================================

/*
ESTA ES UNA TABLA DE SALTOS PARA INDICAR A QUE RUTINA HAY QUE SALTAR CUANDO SE
SELECCIONA UN ARCHIVO.
ESTE PROGRAMA SELECTOR ESTA BASADO EN LAS EXTENSIONES DEL NOMBRE DE ARCHIVO ASI
QUE AGREGAR AQUI TUS EXENSIONES FAVORITAS Y/O PROPORCIONA UNA RUTINA DE CARGA
TAMBIEN
*/

LOADERS:	DB	"Z80"
		DW	LOAD_Z80

		DB	"TAP"
		DW	LOAD_TAP

		DB	"BAS"			;RUTINA DE CARGA PARA PROGRAMAS
		DW	LOAD_BAS		;BASIC, LAS EXTENSIONES COMUNES
		DB	"B  "			;SON ".BAS" O ".B" PERO TAMBIEN
		DW	LOAD_BAS		;SIN EXTENSION, EJ: "DISK"
		DB	"   "
		DW	LOAD_BAS

		DB	"BIN"			;EN LO PERSONAL SIEMPRE USO ".BIN"
		DW	LOAD_BIN		;PARA INDICAR UN ARCHIVO BINARIO,
		DB	"O  "			;PERO HE VISTO QUE MUCHOS USUARIOS
		DW	LOAD_BIN		;USAN EXTENSIONES COMO:
		DB	"C  "			;".o",".b",".cod",".c" y muchas
		DW	LOAD_BIN		;otras, asi que agrega aquí tu
		DB	"COD"			;favorita o las que creas que faltan
		DW	LOAD_BIN

		DB	"SCR"			;EXTENSIONES USUALES PARA INDICAR
		DW	LOAD_SCR		;QUE EL ARCHIVO CONTIENE UNA PANTALLA
		DB	"$  "			;(CODE 16384,6912)
		DW	LOAD_SCR

		DB	$00

; ==================================================================================================
; RUTINA QUE USO PARA CONGELAR Y DEPURAR ALGO, NO ES USADA PERO ME VIENE BIEN CUANDO NECESITO HACER
; ALGUNA PARADA PARA ANALIZAR REGISTROS EN UN EMULADOR

FREEZE:		DI
		LD	BC,309
		LD	D,$00
		LD	HL,$0128
RETARDO1:	DEC	BC
		LD	A,B
		OR	C
		JR	NZ,RETARDO1
SIG_CAMBIO_R:	LD	A,D
		INC	A
		AND	$07
		OUT	($FE),A
		LD	D,A
		PUSH	HL
		POP	BC
RETARDO2:	DEC	BC
		LD	A,B
		OR	C
		JR	NZ,RETARDO2
		JR	SIG_CAMBIO_R

; ==================================================================================================

PUNT_NAME:		DB	$00
PUNT_ANT:		DB	$00
LINEA:			DB	$00
CANT_NOMBRES:		DB	$00
PAGINA_ACTUAL:		DB	$FF
DIR_NAME:		DW	$0000
GUARDA_STACK:		DW	$0000
FILEMASK:		DB	"*.*",$FF	; máscara a leer en CAT (antes era solo *.Z80)
DATE:			DB	__DATE__	; fecha de ensamblado puesto por SJASMPLUS

; ==================================================================================================
; RUTINAS DE LA ROM +3DOS NECESARIAS PARA ESTA UTILIDAD

DOS_SET_ALERT:		EQU	$014E		; RUTINA DE ALERTA (RIC's errors)
DOS_CATALOG:		EQU	$011E		; CATALOGO DEL DISCO
DOS_OPEN:		EQU	$0106		; ABRIR ARCHIVO
DOS_READ:		EQU	$0112		; LEER ARCHIVO
DOS_CLOSE:		EQU	$0109		; CERRAR ARCHIVO
DOS_SET_1234:		EQU	$013F		; DESACTIVAR CACHE
DD_L_OFFMOTOR:		EQU	$019C		; APAGAR MOTOR
DOS_GET_POSITION:	EQU	$0133		; RETORNA POS DEL ARCH. INDICADO
DOS_SET_POSITION:	EQU	$0136		; SETEA LA POS AL ARCH. INDICADO
IDE_SNAPLOAD:		EQU	$00FD		; CARGA Z80 INTERNA

; ==================================================================================================
; RUTINAS DE LA ROM "BASIC" NECESARIAS PARA ESTA UTILIDAD

BEEPER:			EQU	$03B5
FINDNEXT:		EQU	$19B8

; ==================================================================================================
; VARIABLES DEL SISTEMA NECESARIAS

BORDCR:			EQU	$5C48		; COLOR BORDE
MASKP:			EQU	$5C8D		; COLORES PERMANENTES
FLAGS3:			EQU	$5B66		; INFO SI EXISTE B:
BANKM:			EQU	$5B5C		; GUARDA CONF. DE PAGINAS RAM
ERR_NR:			EQU	$5C3A		; VALOR IY POR DEFECTO
LODDRV:			EQU	$5B79		; DRIVE POR DEFECTO
VARS:			EQU	$5C4B		; ESPACIO DE VARIABLES
FREE_SYSVAR:		EQU	$5C81		; VARIABLE DEL SISTEMA SIN USO

; ==================================================================================================
; PUERTOS DE SWITCHEO DE MEMORIA

PBANKM:			EQU	$7FFD		; PUERTO CONF. DE PAGINAS RAM (1)

; ==================================================================================================
; ESPACIOS INTERMEDIOS DE MEMORIA PARA ALMACENAMIENTOS VARIOS

			DS	127
MYSTACK:		DB	00		; CONTENGO MI PROPIO STACK (128b)

CATBUFFER:		EQU	$9500		; BUFFER PARA EL CATALOGO DE
BUFFERNAMES:		EQU	CATBUFFER+$1000	; DISCO PARA LOS NOMBRES 8.3

; ==================================================================================================
; INCLUDES:

			INCLUDE	"print.asm"	; RUTINA MINIMA DE IMPRESION EN 42c
						; (ver mi utilidad "TOTAL PRINT")

			INCLUDE	"selz80_mn.asm"	; Rutinas mínimas de apoyo para lectura
						; de un Z80 en esta utilidad. (son copias
						; de las presentes en runz80m.asm)

			INCLUDE	"runz80m.asm"	; LANZADOR de Z80s mio iniciado en 1998
						; usado si el origen es un floppy físico

; ==================================================================================================
; AUTORÍA - COPYLEFT - PERO POR FAVOR NO LO REMUEVAS EN LO POSIBLE

		DB	"(L) DJr - V0.97b",$FF