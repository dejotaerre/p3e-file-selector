;===================================================================================================
;
;		DEFINE	INGLES	;SI LA ETIQUETA INGLES EXISTE ENTONCES sjasmplus ENSAMBLA CON
				;MENSAJES EN INGLES
		DEFINE	IN_MF3	IN A,($3F)  ;PAGE IN ROM_MF3 + RAM 8KB
		DEFINE	OUT_MF3	IN A,($BF)  ;PAGE OUT ROM_MF3 + RAM 8KB

;===================================================================================================

UNCOMP_BUFFER:	EQU	$9500		; BUFFER PARA RUNZ80

FILENAME:	DB	"12345678"
		DB	"."
EXTENSION:	DB	"123"
		DB	$FF

USR0:		DB	%00100000	;SI QUEREMOS QUE UN SNAP 48K ARRANQUE
					;EN MODALIDAD "USR 0" DEBEMOS POKEAR
					;AQUI EL VALOR 20h DE LO CONTRARIO SI
					;QUEREMOS BLOQUEAR LA PAGINACION USAMOS
					;EL VALOR 30h (%00110000)

/*
Averiguo si el disco default es A: o B: y NO ES UNA unidad mapeada en la CF,
es decir: si soy un verdadero FLOPPY físico A: o B:

(siendo así debo usar mi RUNZ80, de lo contario si provengo de una unidad IDE
entonces uso IDE_SNAPLOAD del +3e debido a que no se por que IDE_SNAPLOAD no me
funciona en unidades A: o B: físicas)
*/

DO_LOAD_Z80:	LD	A,(LODDRV)
		CP	"A"
		JR	Z,DO_RUNZ80
		CP	"B"
		JR	Z,DO_RUNZ80

PLUS3E_Z80:	LD	HL,$4000
		LD	DE,$4001
		LD	(HL),L
		LD	BC,$1B00 - 1
		LDIR
		LD	IX,Z80ATTRS
		LD	HL,$5800
		LD	DE,179
		CALL	UNCOMPRESS2
		LD	HL,$5008	;imprime el LOGO en 5008h
		LD	(DSF_DIR+1),HL
		CALL	PR_LOGO

		LD	HL,FILENAME
		LD	BC,$0000
		LD	IY,IDE_SNAPLOAD	;SE SUPONE QUE DEBE CARGAR Y EJECUTAR SIN PROBLEMAS
		CALL	P3DOS		;SERIA RARO QUE VUELVA HASTA ACA
					
		DI			;EN CASO DE PROBLEMA (y se supone que aquí no debería
ERR_Z803E:	LD	A,R		;llegar nunca) PERO POR LO MENOS AVISO EN EL BORDE
		AND	$07
		OUT	($FE),A
		JR	ERR_Z803E

;===================================================================================================
; SI NO SOY A: o B: DE UNA UNIDAD FISICA REAL, USO MI UTILIDAD DE CARGA, YA QUE NO PARECE QUE
; IDE_SNAPLOAD SE LLEVE BIEN CON +3e

DO_RUNZ80:	DI			;MODIFICACION (HECHA EN 2002)
		LD	HL,$2000	;AVERIGUA SI HAY UN MF3 EN ESE CASO USA
		IN_MF3			;MEMORIA RAM PARA RECUPERAR "TODA" LA
		LD	(HL),$FF	;PANTALLA EN CASO DE CARGARSE UN Z80 128K
		LD	E,(HL)
		OUT_MF3
		LD	A,E
		CP	$FF
		JR	NZ,NO_MF3
		LD	(MF3),A		;MF3 QUEDA VALIENDO 0 SI NO HAY MF3

NO_MF3:		EI
		LD	SP,UNCOMP_BUFFER-1
		LD	A,(FLAGS3)
		BIT	5,A
		XOR	A		;DESACTIVA RUTINA ALERT DEL P3DOS
		LD	HL,$0000
		LD	IY,DOS_SET_ALERT
		CALL	P3DOS

		LD	A,$07		;prepara el programa de carga del Z80
		LD	(MASKP),A
		LD	(BORDCR),A
		XOR	A
		OUT	($FE),A

		LD	HL,$4000	;borra la pantalla
		LD	DE,$4001
		LD	BC,$1AFF
		LD	(HL),L
		LDIR
		LD	HL,LOADER	;copia el programa cargador en la
		LD	DE,$4000	;pantalla
		LD	BC,$0800	;(un tercio)
		LDIR

		LD	HL,$5AC0	;las dos ultimas lineas de la pantalla
		LD	DE,$5AC1	;quedan con paper 0, ink 7 por si quiero
		LD	(HL),$07	;mostrar algo
		LD	BC,63
		LDIR
		LD	IX,Z80ATTRS	;descomprime los attrs. para...
		LD	HL,$B000
		LD	DE,179
		CALL	UNCOMPRESS2
		LD	HL,$B000	;...ocultar el programa en pantalla
		LD	DE,$5800	;asi por lo menos queda más bonito
		LD	BC,$100
		LDIR

		LD	HL,$5008	;imprime el LOGO en 5008h
		LD	(DSF_DIR+1),HL
		CALL	PR_LOGO

		LD	A,(MF3)		;recupera la variable MF3
		LD	(MULTIFACE3),A

		CALL	OPENFILE	;abre el archivo, prepara +3DOS,
					;y averigua la versión del archivo
					;además imprime tipo de SNAP

		LD	A,(TIPOSNAP)
		AND	A
		JR	Z,RUN_SNAP48K

RUN_SNAP128K:	LD	HL,PATRON_128	;Copiamos la rutina para carga
		LD	DE,SNAP128K	;de SNAPs 128K,+2,+3,etc
		CALL	JUMPBOOT
		JR	START_LOAD

RUN_SNAP48K:	LD	HL,PATRON_48	;Copiamos la rutina para carga
		LD	DE,SNAP48K	;de SNAPs 48K
		CALL	JUMPBOOT
		LD	A,(USR0)
		LD	(REG_LATCH+1),A
		JR	START_LOAD

JUMPBOOT:	DI			; LOCALIZA EL "BOOTEADOR" PARA 48K
		LD	(PUENTE+1),DE	; O 128K Y LO COPIA

		LD	IX,LOADER
		CALL	BUSCAR_STRING
		LD	HL,(BUSC_RUT)
		LD	(START_RUT+1),HL
		PUSH	HL
		POP	IX
		LD	HL,PATRON_FIN
		CALL	BUSCAR_STRING
		LD	BC,(START_RUT+1)
		LD	HL,(BUSC_RUT)
		AND	A
		SBC	HL,BC
		LD	(TAM_RUT+1),HL
		LD	BC,CARGADORES
		ADD	HL,BC
		LD	A,H
		CP	$48		; SI NOS PASAMOS DE 4800 EN PANTALLA
		JR	NC,ERR_TAMPROG	; ES POR QUE EL BOOTEADOR NO ENTRO
		CP	$47
		JR	NZ,START_RUT
		LD	A,L
		CP	$FF
		JR	NZ,START_RUT
ERR_TAMPROG:	LD	A,0
		CALL	ZPRINT_MENERR
		JP	BLOQUEO

START_RUT:	LD	HL,$0000
		PUSH	HL
		LD	DE,CARGADORES
TAM_RUT:	LD	BC,$0000
		LDIR
		POP	HL
		RET

START_LOAD:	EQU	$

		LD	SP,STACK
		CALL	SET_MYINT
		LD	A,$07
		LD	(BANKM),A
		LD	BC,PBANKM
		OUT	(C),A
PUENTE:		JP	$0000

BUSCAR_STRING:	LD	(BUSC_RUT),IX	; BUSCA A PARTIR DE (BUSC_RUT) UN STRING
		LD	(BUSC_DIR),HL	; DETERMINADO POR (BUSC_DIR)
LBUSC_BOOT:	LD	A,(HL)
		CP	$FF
		RET	Z
		CP	(IX)
		JR	NZ,NEXT_FBYTE
		INC	IX
		INC	HL
		JR	LBUSC_BOOT

NEXT_FBYTE:	INC	IX
		DB	$DD
		LD	A,H
		AND	A
		JR	Z,NO_EXISTE
		LD	(BUSC_RUT),IX
		LD	HL,(BUSC_DIR)
		JR	LBUSC_BOOT
NO_EXISTE:	LD	A,1
		CALL	ZPRINT_MENERR
		JP	BLOQUEO

; ==================================================================================================

PATRON_128:	DB	"SNAP128K",$FF
PATRON_48:	DB	"SNAP48K",$FF
PATRON_FIN:	DB	"ENDRUNZ80",$FF
BUSC_DIR:	DW	$0000
BUSC_RUT:	DW	$0000

;===================================================================================================
; PREPARA +3DOS, ABRE EL ARCHIVO, E IMPRIME NOMBRE Y TIPO DEL SNAP

OPENFILE:	LD	DE,$0000	; DESACTIVA CACHE Y RAMDISK
		LD	HL,$0000
		LD	IY,DOS_SET_1234
		CALL	P3DOS
		JP	NC,ZERROR_7000H

		LD	DE,$0002	; abre el archivo con handle #06
		LD	BC,$0601
		LD	HL,FILENAME
		LD	IY,DOS_OPEN
		CALL	P3DOS
		JP	NC,ZERROR_7000H

CHECKFILE:	LD	HL,UNCOMP_BUFFER; carga la cabecera del Z80 y comienza
		LD	DE,56		; a averiguar el tipo de SNAP
		LD	BC,$0600
		LD	IY,DOS_READ
		CALL	P3DOS
		JP	NC,ZERROR_7000H

		LD	IX,UNCOMP_BUFFER
		LD	L,(IX+6)
		LD	H,(IX+7)
		LD	A,H
		OR	L
		JR	Z,NO_VER145	; si PC=0 entonces...

		LD	A,6		; es un Z80 V1.45 no
		CALL	ZPRINT_MENTBL	; se acepta
		JR	SNAPMAL

NO_VER145:	LD	A,(IX+34)	; VER AL PRINCIPIO POR IDs
		LD	(TIPOSNAP),A
		LD	HL,L48K
		CP	3
		JR	C,STPRINT	; ID < 3 ==> SNAP 48K

		LD	HL,L128K
		CP	7
		JR	C,STPRINT	; ID < 7 ==> SNAP 128K

		LD	HL,LPLUS3
		CP	7
		JR	Z,STPRINT	; ID = 7 == > SNAP +3 o +2A

		;CP	8
		;JR	Z,???????	; ID = 8 == > QUE SNAP SERA???????

		LD	HL,LPENTAGON
		CP	9
		JR	Z,STPRINT	; ID = 9 == > SNAP PENTAGON

		LD	A,6		; SI LLEGAMOS AQUI ES POR QUE NO SE
		CALL	ZPRINT_MENTBL	; RECONOCIO EL SNAP
		JR	SNAPMAL		; (o sea... no 48K,128K,P3,PENTAGON)

STPRINT:	CALL	ZPRINT_MEN
		LD	A,(LODDRV)
		RST	10H
		LD	A,":"
		RST	10H
		LD	HL,FILENAME
		LD	B,8
LSTPRINT:	LD 	A,(HL)
		CP	$20
		JR	Z,FSTRNAME
		RST	10H
		INC	HL
		DJNZ	LSTPRINT
FSTRNAME:	LD	A,$22
		RST	10H
		LD	A,(TIPOSNAP)
		CP	3
		RET	C
		LD	A,(MF3)
		AND	A
		RET	Z
		LD	A,6
		JP	ZPRINT_MENTBL

SNAPMAL:	LD	B,$06		; NO quizo cargar el SNAP
		LD	IY,DOS_CLOSE	; cierra el archivo...
		CALL	P3DOS
		RST	08H
		DB	$FF		; ...y retorna al BASIC ("0 OK, 0:1")

;===================================================================================================
; RUTINA DE ERROR CUANDO OCURREN EN LA CARGA INICIAL

ZERROR_7000H:	PUSH	AF		; control de errores +3DOS
		LD	HL,$4800
		LD	DE,$4801
		LD	BC,2047
		LD	(HL),$00
		LDIR
		LD	HL,ZMEN_ERR7000H
		CALL	ZPRINT_MEN
		POP	AF
		LD	C,A
		LD	B,$00
		CALL	STACK_BC
		CALL	PR_STACK_BC	; IMPRIME EL NUMERO EN 'BC' USANDO
		RST	08H		; USANDO EL CALCULADOR
		DB	$FF		; ("0 OK, 0:1")

ZMEN_ERR7000H:	DB	22,9,0,"+3DOS ERROR: ",$FF

;===================================================================================================
;RUTINAS DE ROM3 USADAS EN ESTA UTILIDAD

CHOPEN:		EQU	$1601		; ABRIR CANAL
STACK_BC:	EQU	$2D2B		; PONE BC EN EL STACK
PR_STACK_BC:	EQU	$2DE3		; IMPRIME EL STRING EN STACK_BC

;===================================================================================================

ZPRINT_MENERR:	LD	HL,DEV_MESS	; TABLA DE MENSAJES PROPIOS DE
		JR	MSGTBL		; DEPURACION
		
ZPRINT_MENTBL:	LD	HL,HARDMENS	; IMPRIME EL MENSAJE 'A' DE LA TABLA
MSGTBL:		CALL	BUSC_MEN	; 'HARDMENS'

;===================================================================================================

ZPRINT_MEN:	PUSH	HL		; IMPRIME UN MENSAJE A PARTIR DE 'HL
		LD	A,$02		; QUE TERMINA EN FFh
		CALL	CHOPEN
		POP	HL

LZPRINT_MEN:	LD	A,(HL)
		CP	$FF
		RET	Z
		CP	$FE		; CODIGO FEh ABRE EL CANAL #01
		JR	NZ,SIG_MEN
		PUSH	HL
		LD	A,$01
		CALL	CHOPEN
		POP	HL
		JR	NOPRINT

SIG_MEN:	CP	$80
		JR	C,OKPRINT
		PUSH	HL
		LD	HL,TOKEN
		RES	7,A
		CALL	BUSC_MEN
		CALL	LZPRINT_MEN
		POP	HL
		JR	NOPRINT

OKPRINT:	RST	10H

NOPRINT:	INC	HL
		JR	LZPRINT_MEN

;===================================================================================================
; Busca el mensaje 'A' en la tabla 'HL'. Cada mensaje debe estar separado por un FFh
; Retorna en 'HL' la direccion del mensaje

BUSC_MEN:	AND	A
		RET	Z
		LD	B,A
		LD	A,$FF
LBUSC_MEN:	PUSH	BC
		LD	BC,$0000
		CPIR
		POP	BC
		DJNZ	LBUSC_MEN
		RET

;===================================================================================================
; ESTOS MENSAJES SON PARA DEPURACION - NO DEBERIAN VERSE NUNCA

DEV_MESS:	EQU	$

		IFDEF	INGLES	;MENSAJES EN INGLES

			DB	$FE,22,0,0				;0

			DB	"OUT OF SPACE IN 1st SCREEN THIRD"
			DB	$FF

			DB	$FE,22,0,0				;1
			DB	"CAN'T FIND LOADING ROUTINES"
			DB	$FF

		ELSE

			DB	$FE,22,0,0				;0
			DB	"SIN ESPACIO EN 1er TERCIO PANT"
			DB	$FF

			DB	$FE,22,0,0				;1
			DB	"NO ENCUENTRO RUTINAS DE CARGA"
			DB	$FF

		ENDIF
;===================================================================================================

HARDMENS:	EQU	$

L48K:		DB	$80,"48K",$81,$FF			;0
L128K:		DB	$80,"128K/+2",$81,$FF			;1
LPLUS3:		DB	$80,"+3/+2A",$81,$FF			;2
LPENTAGON:	DB	$80,"PENTAGON",$81,$FF			;3

		; El mensaje #5 puede ser mostrado en caso de
		; detectar un viejo Z80 V1.45

		IFDEF	INGLES			; MENSAJES EN INGLES

			DB	$80,"UNKNOWN",$81,$FF		;4

			DB	$80				;5
			DB	"UNKNOWN Z80 FILE TYPE\r"
			DB	$FF

			DB	$FE,22,1,0			;6
			DB	"MF3 detected - using MF3's RAM"
			DB	$FF

		ELSE				; MENSAJES EN ESPAÑOL

			DB	$80,"DESCONOCIDO",$81,$FF	;4

			DB	22,9,0				;5
			DB	"TIPO DE Z80 DESCONOCIDO"
			DB	$FF 	

			DB	$FE,22,1,0			;6
			DB	"MF3 detectado, usando su RAM"
			DB	$FF

		ENDIF

TOKEN:		DB	22,9,0,"Z80 ",$FF			;7 (0) ($80)
		DB	$0D,$0D,"LOAD ",$22,$FF			;8 (1) ($81)

;===================================================================================================

PR_LOGO:	LD	A,$1A		; LD A,(DE)
		LD	(LSCAN),A
		LD	A,$68
		LD	(LATTR+1),A
		LD	IX,LOGO		; EL LOGO ESTA COMPRIMIDO Y PRIMERO
		LD	HL,$B000	; LO DESCOMPRIME EN B000h
		LD	DE,$1F0
		CALL	UNCOMPRESS2

DSF_DIR:	LD	HL,$400F	; IMPRIME EL LOGO EN (DSF_DIR+1)
		PUSH	HL
		LD	DE,$B000

		LD	B,$05		; FILAS DE ALTO (5*8)
LFILA:		PUSH	HL
		PUSH	BC

		LD	B,$08
LFILA8:		PUSH	HL
		PUSH	BC
		LD	B,17		; ANCHO DEL GRAFICO (columnas)
LSCAN:		LD	A,(DE)
		LD	(HL),A
		CALL	NEXT_COL
		INC	DE
		DJNZ	LSCAN
		POP	BC
		POP	HL
		INC	H
		DJNZ	LFILA8
		POP	BC
		POP	HL
		CALL	NEXT_DSPL
		DJNZ	LFILA
		POP	HL
		LD	A,H		; CALCULA DIR. ATTRS.
		RRCA
		RRCA
		RRCA
		AND	$03
		OR	$58
		LD	H,A
		LD	B,$05
LATTR_F:	PUSH	BC
		PUSH	HL
		LD	B,17		; ANCHO DEL GRAFICO (columnas)
LATTR:		LD	(HL),$68	; PAPEL 5, INK0, BRIGHT 1
		CALL	NEXT_COL
		DJNZ	LATTR
		POP	HL
		LD	BC,$0020
		ADD	HL,BC
		LD	A,H
		CP	$5B
		JR	C,NO_ADJATTR
		LD	H,$58		; DIR. ATTR. SALIO DE LA PANTALLA
NO_ADJATTR:	POP	BC
		DJNZ	LATTR_F
		RET

NEXT_COL:	LD	A,L
		AND	%00011111
		CP	$1F
		JR	Z,F_COL
		INC	L
		RET
F_COL:		LD	A,L
		SUB	$1F
		LD	L,A
		RET

NEXT_DSPL:	LD	A,L
		AND	%11110000
		CP	$E0
		JR	Z,CHANGE_BLQ
		LD	A,L
		ADD	A,$20
		LD	L,A
		RET

CHANGE_BLQ:	LD	A,L
		AND	%00001111
		LD	L,A
		LD	A,H
		AND	%00011000
		JR	Z,SEG_TERCIO
		CP	%00001000
		JR	Z,TER_TERCIO
		LD	H,$40		; DIR. DF. SALIO DE LA PANTALLA
		RET

SEG_TERCIO:	LD	H,$48
		RET

TER_TERCIO:	LD	H,$50
		RET

;===================================================================================================
; RUTINA DESCOMPRESORA METODO 2
; (solo se usa para descomp. el logo y los atributos que ocultan el prog.
; en pantalla)
;===================================================================================================
; IX=Direccion del bloque comprimido
; HL=Direccion en donde poner el bloque descomprimido
; DE=Cantidad de bytes comprimidos

COMP_BLOCK_ID:	EQU	$ED

UNCOMPRESS2:	LD	A,D
		OR	E
		RET	Z
		LD	A,(IX+0)
		CP	COMP_BLOCK_ID
		JR	NZ,B_NOREP
		CP	(IX+1)
		JR	NZ,B_UNICO
		LD	B,(IX+2)
		LD	A,(IX+3)
L_REP2:		LD	(HL),A
		INC	HL
		DJNZ	L_REP2
		INC	IX
		INC	IX
		DEC	DE
		DEC	DE
RET_UNICO:	INC	IX
		DEC	DE
RET_NOREP:	INC	IX
		DEC	DE
		JR	UNCOMPRESS2

B_UNICO:	LD	(HL),COMP_BLOCK_ID
		INC	HL
		LD	A,(IX+1)
		LD	(HL),A
		INC	HL
		JR	RET_UNICO

B_NOREP:	LD	(HL),A
		INC	HL
		JR	RET_NOREP

;===================================================================================================
; LOGO "Z80-Loader" COMPRIMIDO

LOGO:		DB	$ED,$ED,$11,$FF,$80,$ED,$ED,$0F
		DB	$00,$01,$BF,$ED,$ED,$0F,$FF,$FD
		DB	$A0,$ED,$ED,$0F,$00,$05,$AF,$ED
		DB	$ED,$0F,$FF,$F5,$A8,$ED,$ED,$0F
		DB	$00,$15,$A8,$ED,$ED,$0F,$00,$15
		DB	$A8,$ED,$ED,$0F,$00,$15,$A8,$3F
		DB	$FF,$FF,$01,$FF,$80,$3F,$F8,$00
		DB	$03,$FF,$FF,$FF,$FE,$00,$15,$A8
		DB	$00,$00,$01,$80,$00,$40,$00,$02
		DB	$ED,$ED,$06,$00,$0C,$15,$A8,$3F
		DB	$FF,$FF,$8F,$FF,$E0,$FF,$FF,$00
		DB	$0F,$FF,$FF,$FF,$F9,$12,$15,$A8
		DB	$00,$00,$03,$80,$00,$20,$03,$80
		DB	$80,$00,$00,$00,$00,$01,$04,$15
		DB	$A8,$00,$01,$FF,$1F,$FF,$F1,$FF
		DB	$FF,$80,$3F,$FF,$FF,$FF,$E7,$C2
		DB	$15,$A8,$00,$00,$0E,$00,$FC,$18
		DB	$07,$00,$C0,$00,$00,$00,$00,$01
		DB	$12,$15,$A8,$00,$07,$FC,$1F,$C7
		DB	$F9,$FE,$3F,$C0,$FF,$FF,$FF,$FF
		DB	$81,$0C,$15,$A8,$00,$00,$38,$01
		DB	$80,$18,$06,$00,$C0,$ED,$ED,$06
		DB	$00,$15,$A8,$00,$1F,$F0,$1F,$C3
		DB	$F9,$FE,$3F,$C0,$ED,$ED,$06,$00
		DB	$15,$A8,$00,$00,$E0,$00,$C0,$30
		DB	$06,$00,$C0,$ED,$ED,$06,$00,$15
		DB	$A8,$00,$7F,$C0,$0F,$FF,$F1,$FE
		DB	$3F,$C0,$ED,$ED,$06,$00,$15,$A8
		DB	$00,$03,$80,$00,$00,$30,$06,$00
		DB	$C0,$ED,$ED,$06,$00,$15,$A8,$01
		DB	$FF,$00,$0F,$FF,$F1,$FE,$3F,$C0
		DB	$C0,$00,$00,$06,$00,$00,$15,$A8
		DB	$00,$0E,$00,$00,$00,$18,$06,$00
		DB	$C0,$C0,$00,$00,$06,$00,$00,$15
		DB	$A8,$07,$FC,$00,$1F,$FF,$F9,$FE
		DB	$3F,$C0,$C0,$00,$00,$06,$00,$00
		DB	$15,$A8,$00,$38,$00,$00,$FC,$18
		DB	$06,$00,$C0,$C3,$C1,$F0,$76,$1C
		DB	$54,$15,$A8,$1F,$F0,$00,$1F,$C7
		DB	$F9,$FE,$3F,$C0,$C7,$E3,$F8,$FE
		DB	$3E,$3E,$15,$A8,$00,$E0,$00,$01
		DB	$80,$18,$06,$00,$C0,$CE,$73,$19
		DB	$CE,$63,$38,$15,$A8,$7F,$C0,$00
		DB	$1F,$81,$F9,$FE,$3F,$C0,$CC,$30
		DB	$79,$86,$7F,$30,$15,$A8,$01,$80
		DB	$00,$00,$C0,$38,$00,$01,$C0,$CC
		DB	$31,$F9,$86,$7F,$30,$15,$A8,$7F
		DB	$FF,$FF,$0F,$FF,$F0,$FF,$FF,$80
		DB	$CC,$33,$99,$86,$60,$30,$15,$A8
		DB	$00,$00,$01,$80,$00,$70,$00,$07
		DB	$80,$CE,$73,$19,$CE,$73,$30,$15
		DB	$A8,$7F,$FF,$FF,$83,$FF,$E0,$3F
		DB	$FF,$00,$C7,$E3,$F8,$FE,$3E,$30
		DB	$15,$A8,$3F,$FF,$FF,$81,$FF,$C0
		DB	$1F,$FE,$00,$C3,$C1,$EC,$76,$1C
		DB	$30,$15,$A8,$1F,$FF,$FF,$80,$FF
		DB	$00,$07,$F8,$ED,$ED,$07,$00,$15
		DB	$A8,$ED,$ED,$0F,$00,$15,$A8,$ED
		DB	$ED,$0F,$00,$15,$AF,$ED,$ED,$0F
		DB	$FF,$F5,$A0,$ED,$ED,$0F,$00,$05
		DB	$BF,$ED,$ED,$0F,$FF,$FD,$80,$ED
		DB	$ED,$0F,$00,$01,$ED,$ED,$11,$FF

;===================================================================================================
; ATTRS DE LA PANTALLA QUE FORMAN LA PALABRA Z80, ESTOS ATRIBUTOS SON USADOS PARA OCULTAR EL 
; PROGRAMA CARGADOR QUE VA EN EL 1ER TERCIO DE LA PANTALLA

Z80ATTRS:   	DB	$00,$ED,$ED,$0A,$12,$00,$00,$ED
		DB	$ED,$07,$12,$00,$00,$00,$00,$ED
		DB	$ED,$05,$12,$00,$00,$00,$00,$ED
		DB	$ED,$0A,$12,$00,$ED,$ED,$09,$12
		DB	$00,$ED,$ED,$09,$12,$ED,$ED,$09
		DB	$00,$12,$12,$12,$00,$12,$12,$ED
		DB	$ED,$05,$00,$12,$12,$00,$12,$12
		DB	$ED,$ED,$05,$00,$12,$12,$ED,$ED 
		DB	$06,$00,$12,$12,$12,$12,$00,$00
		DB	$00,$00,$ED,$ED,$07,$12,$00,$00
		DB	$12,$12,$ED,$ED,$05,$00,$12,$12
		DB	$00,$00,$00,$00,$12,$12,$12,$12
		DB	$ED,$ED,$06,$00,$ED,$ED,$07,$12
		DB	$00,$00,$12,$12,$ED,$ED,$05,$00
		DB	$12,$12,$00,$00,$12,$12,$12,$ED
		DB	$ED,$08,$00,$12,$12,$ED,$ED,$05
		DB	$00,$12,$12,$00,$12,$12,$ED,$ED
		DB	$05,$00,$12,$12,$00,$00,$ED,$ED
		DB	$0A,$12,$00,$ED,$ED,$09,$12,$00
		DB	$ED,$ED,$09,$12,$00,$00,$ED,$ED
		DB	$0A,$12,$00,$00,$ED,$ED,$07,$12
		DB	$00,$00,$00,$00,$ED,$ED,$05,$12
		DB	$00,$00,$00

MF3:		DB	$00

LOADER:		EQU	$

;===================================================================================================
		ORG	$4000
;===================================================================================================

BOOT48K:	LDIR
		LD	BC,PBANKM			; $DB $BF NOP
		OUT	(C),A				; NOP NOP
BOOT128K:
RDE:		LD	DE,$0000
RBC:		LD	BC,$0000
RAF:		LD	HL,$0000
		PUSH	HL
RHL:		LD	HL,$0000
RREF:		LD	A,$00
		LD	R,A
		POP	AF				; REFRESH+1
INT:		DB	$00	;DI=F3 , EI=FB		; REFRESH+1
RPC:		JP	$0000				; REFRESH+1

;===================================================================================================
; LEE LOS REGISTROS Y MODIFICA LAS RUTINAS "SET_REG" Y "BOOT128K" PARA QUE
; ASIGNEN SUS VALORES LUEGO DE CARGAR Y DESCOMPRIMIR EL SNAP, TAMBIEN LEE
; LOS VALORES DE LOS REGISTROS DEL AY-3-8912
;
; (los comentarios en inglés son tomados del TECHINFO.TXT de G.A.Lunter)
;
READ_REG:	LD	HL,$0000
		CALL	SETPOS
		JP	NC,P3DOSERROR
		LD	HL,$0000
		LD	(RPC+1),HL

		CALL	READ16		; AF
		LD	A,H
		LD	H,L
		LD	L,A
		LD	(RAF+1),HL
		CALL	READ16		; BC
		LD	(RBC+1),HL
		CALL	READ16		; HL
		LD	(RHL+1),HL
		CALL	READ16		; PC (V1.45)
		LD	(RPC+1),HL
		CALL	READ16		; SP
		LD	(RSP),HL
		CALL	READ08	;I
		LD	(RINT+1),A
		CALL	READ08		; R
		AND	%01111111
		LD	H,A
		PUSH	HL
		CALL	READ08		; Bit 0 : Bit 7 of the R-register
					; Bit 1-3: Border colour
		POP	HL
		LD	L,A
		BIT	0,A
		JR	Z,RES0_REF
		SET	7,H
		JR	SET_REF
RES0_REF:	RES	7,H
SET_REF:	LD	A,H
		DEC	A		; COMPENSA EL INCREMENTO DESPUES DE
		DEC	A		; EJECUTAR BOOT48K o BOOT128K
		DEC	A
		LD	(RREF+1),A
		LD	A,L
		RRCA
		AND	$07
		LD	(ZBORDE+1),A
		CALL	READ16		; DE
		LD	(RDE+1),HL
		CALL	READ16		; BC'
		LD	(ALTBC+1),HL
		CALL	READ16		; DE'
		LD	(ALTDE+1),HL
		CALL	READ16		; HL'
		LD	(ALTHL+1),HL
		CALL	READ16		; AF'
		LD	A,H
		LD	H,L
		LD	L,A
		LD	(ALTAF+1),HL
		CALL	READ16		; IY
		LD	(RIY+2),HL
		CALL	READ16		; IX
		LD	(RIX+2),HL
		CALL	READ08		; EI/DI
		AND	A
		LD	A,$F3
		JR	Z,SET_INT
		LD	A,$FB
SET_INT:	LD	(INT),A
		CALL	READ08		; IFF2 (not particularly important...)
		CALL	READ08		; Bit 0-1: Interrupt mode (0, 1 or 2)
		AND	%00000011
		AND	A
		JR	Z,SET_IM0
		CP	$01
		JR	Z,SET_IM1
		LD	A,$5E
		JR	PUT_INT
SET_IM1:	LD	A,$56
		JR	PUT_INT
SET_IM0:	LD	A,$46
PUT_INT:	LD	(IM_MODE),A
		LD	HL,(RPC+1)
		LD	A,H
		OR	L
		RET	NZ
		CALL	READ16		; Length of additional header block
		CALL	READ16		; PC
		LD	(RPC+1),HL

		LD	HL,35
		CALL	SETPOS
		JP	NC,P3DOSERROR
		CALL	READ08		; in 128 mode, contains last OUT to 7ffd
		LD	(LAST_7FFD),A
		CALL	READ16		; dummy
		CALL	READ08		; Last OUT to fffd (soundchip reg nr)
		LD	(LAST_FFFD),A
		LD	B,16
		LD	HL,AY_REGS
LSTORE_AY:	PUSH	BC
		PUSH	HL
		CALL	READ08		; *16 Contents of the sound chip regs
		POP	HL
		POP	BC
		LD	(HL),A
		INC	HL
		DJNZ	LSTORE_AY
		
		LD	A,(TIPOSNAP)
		CP	7
		RET	NZ		; ENTONCES ES UN Z80 +3 o +2A
		LD	HL,$0056	; SE PROCEDE A RECUPERAR EL
		CALL	SETPOS		; ULTIMO DATO ENVIADO AL PUERTO
		JP	NC,P3DOSERROR	; 1FFDh
		CALL	READ08
		LD	(LAST_1FFD),A
		RET

LAST_FFFD:	DB	$00

;===================================================================================================
; LANZADOR FINAL QUE VA A PARTIR DE $4000

SET_REG:	DI			; CARGA LOS REGISTROS PRELIMINARES QUE
		EXX			; NO SE USAN BOOT48K o BOOT128K.
ALTHL:		LD	HL,$0000
ALTDE:		LD	DE,$0000	; ESTA RUTINA ES MODIFICADA POR READ_REG
ALTBC:		LD	BC,$0000
		EXX
RIX:		LD	IX,$0000	; +2
RIY:		LD	IY,$0000	; +2
ALTAF:		LD	HL,$0000
		EX	AF,AF'
		PUSH	HL
		POP	AF
		EX	AF,AF'
		DB	$ED		; (EDxx) = IM x
IM_MODE:	DB	$00		; MODO: 0=46, 1=56, 2=5E
RINT:		LD	A,$00
		LD	I,A
ZBORDE:		LD	A,$00
		OUT	($FE),A
		RET

;===================================================================================================
;
GET_TAMPAG:	CALL	READ16		; RETORNA HL=CANTIDAD DE BYTES
		PUSH	HL		; COMPRIMIDOS Y A=NRO. PAGINA RAM
		CALL	READ08		; EN DONDE SE DEBERIA DESCOMPRIMIR
		POP	HL
		LD	(PAG_FILE),A
		SUB	$03
		AND	$07
		RET

;===================================================================================================
; POSICIONA EL PUNTERO LUEGO DE LA CABECERA

GO_FIRSTPAG:	LD	HL,$001E
		CALL	SETPOS
		JP	NC,P3DOSERROR
		CALL	READ08
		PUSH	AF
		CALL	READ08
		LD	H,A
		POP	AF
		LD	L,A
		LD	BC,$0020
		ADD	HL,BC
		CALL	SETPOS
		JP	NC,P3DOSERROR
		RET

;===================================================================================================
; POSICIONA EL PUNTERO DEL ARCHIVO EN LA PAGINA INDICADA POR 'A'
; EL PUNTERO QUEDA POSICIONADO EN EL PRIMER BYTE "COMPRIMIDO"
; RETORNA EN "HL" EL TAMAÑO DE LA PAGINA COMPRIMIDA

GOTO_PAG:	PUSH	AF
		CALL	GO_FIRSTPAG
		POP	AF
		LD	(COMPARA_PAG+1),A
		LD	B,A
LBUSC_PAG5:	PUSH	BC
		CALL	GET_TAMPAG
		PUSH	HL
		CALL	GETPOS
		POP	BC
		ADD	HL,BC
		JR	NC,NO_OVERF
		INC	E
NO_OVERF:	CALL	SETPOS_EHL
		JP	NC,P3DOSERROR
		POP	BC
		DJNZ	LBUSC_PAG5
		CALL	GET_TAMPAG
COMPARA_PAG:	CP	$00
		JP	NZ,ERRSNAP
		RET

;===================================================================================================
; DESCOMPRIME UNA PAGINA QUE YA ESTÁ A PARTIR DE C000h
;
; HL = CANTIDAD DE BYTES A LEER (COMPRIMIDOS)
; A  = PAGINA DE RAM EN DONDE SE DESCOMPRIME EL BLOQUE
;
UNP_PAG:	LD	(COUNT),HL
		PUSH	AF
		LD	B,$06
		LD	C,A
		LD	DE,$C000
		LD	(CPOS),DE
		EX	DE,HL
		CALL	DOS_READ
		JP	NC,P3DOSERROR
		POP	AF
		LD	BC,PBANKM
SCREEN2_A:	OR	%00000000
		OUT	(C),A

UNP_PAG2:	LD	DE,$FFFF	; ENTRADA ALTERNATIVA PARA DESCOMPRIMIR
		LD	BC,(COUNT)	; PAGINA 7
		LD	HL,$C000
		ADD	HL,BC
		DEC	HL
		LDDR
		INC	DE
		LD	(ORIGEN),DE

		LD	IX,DESCOMP_BUFF	; DIRECCION PREBUFFER DE DESCOMPRESION
		LD	HL,$0000
		LD	(CTRL_BUFFER),HL

BUCL_UNP:	CALL	GETBYTE
		CP	$ED
		JR	NZ,NOREP	; BYTE NO REPETIDO
		CALL	GETBYTE
		CP	$ED
		JR	NZ,UNICO	; UNICO EDh seguido por otro byte
		CALL	GETBYTE		; CANTIDAD DE VECES QUE ESTA REPETIDO

		LD	B,A
		CALL	GETBYTE		; VALOR DEL BYTE REPETIDO
LREPEAT_B:	CALL	PUTBYTE		; DESCOMPRIME LOS BYTES REPETIDOS
		INC	IX
		DJNZ	LREPEAT_B

TEST_END:	LD	HL,(COUNT)
		LD	A,H
		OR	L
		JR	NZ,BUCL_UNP

		XOR	A		; TERMINA Y VUELVE A DEJAR PAGINA 7
		OUT	($FE),A
		LD	HL,$FEFF
		LD	DE,$FFFF
		LD	BC,16383
		LDDR
		LD	HL,DESCOMP_BUFF
		LD	DE,$C000
		LD	BC,$100
		LDIR
		LD	BC,PBANKM
SCREEN2_B:	LD	A,$07
		OUT	(C),A
		RET

UNICO:		PUSH	AF		; UNICO EDh seguido por otro byte
		LD	A,$ED
		CALL	PUTBYTE
		POP	AF
		INC	IX
NOREP:		CALL	PUTBYTE		; BYTE UNICO
		INC	IX
		JR	TEST_END

GETBYTE:	LD	HL,(ORIGEN)
		LD	A,(HL)
		AND	$07
		OUT	($FE),A		; SE HACE UN "JUEGITO" CON LOS BYTES
		LD	A,(HL)		; DESCOMPRIMIDOS PARA QUE EL USUARIO
		INC	HL		; "VEA" QUE TODO VA MARCHANDO BIEN
		LD	(ORIGEN),HL
		LD	HL,(COUNT)
		DEC	HL
		LD	(COUNT),HL
		RET

PUTBYTE:	PUSH	AF		; CONTROL DEL PREBUFFER PARA EVITAR
		LD	HL,(CTRL_BUFFER); SOLAPAMIENTOS EN LA DESCOMPRESION
		LD	A,H
		CP	$01		; SE METEN 256 EN UN BUFFER INTERNO
		JR	Z,PUT_RAM	; Y LUEGO SE CONTINUA DESDE...
		POP	AF
		PUSH	AF
		LD	(IX+0),A
		INC	HL
		LD	(CTRL_BUFFER),HL
		LD	A,H
		CP	$01
		JR	NZ,NO_PREBUF
		LD	IX,$BFFF	; ... C000h HASTA FEFFh, luego al
NO_PREBUF:	POP	AF		; final de las descompresion se
		RET			; junta todo.

PUT_RAM:	POP	AF
		PUSH	AF		; SE EVITA AQUI UN POSIBLE DESBORDE
		DB	$DD		; SI Ix>FEFF (síntoma de que el SNAP
		LD	A,H		; podría estar corrupto)
		CP	$FF
		JP	Z,ERRSNAP
		POP	AF
		LD	(IX+0),A
		RET

;===================================================================================================
; RUTINAS DE APOYO PARA LA LECTURA DE BYTES INDIVIDUALES DE LOS SNAPs DESDE DISCO
;
READ16:		PUSH	IX		; RETORNA EN HL LA PALABRA LEIDA DEL
		CALL	READ08		; ARCHIVO ABIERTO EN 06h
		PUSH	AF
		CALL	READ08
		LD	H,A
		POP	AF
		LD	L,A
		POP	IX
		RET

READ08:		PUSH	IX		; RETORNA EL "A" EL BYTE LEIDO DEL
		LD	BC,$0607	; ARCHIVO ABIERTO EN 06h
		LD	DE,$0001
		LD	HL,BYTER+1
		CALL	DOS_READ
		JR	NC,P3DOSERROR
BYTER:		LD	A,$00
		POP	IX
		RET

;===================================================================================================

SETPOS:		LD	E,$00		; POSICIONA EN 'HL' EL ARCH. #06
SETPOS_EHL:	LD	B,$06		; POSICIONA EN 'EHL' EL ARCH. #06
		LD	D,$00
		JP	DOS_SET_POSITION

;===================================================================================================

GETPOS:		LD	B,$06			; RETORNA EN 'EHL' LA 
		JP	DOS_GET_POSITION	; POSICION DEL ARCHIVO #06

;===================================================================================================

ERRSNAP:	LD	A,$FF

P3DOSERROR:	DI			; 'CUELGA' EL PROGRAMA PARA INDICAR
		PUSH	AF		; ERROR EN +3DOS
		LD	A,$04
		LD	BC,PBANKM
		OUT	(C),A
		CALL	DD_L_OFFMOTOR
		LD	A,$10
		LD	BC,PBANKM
		OUT	(C),A
		LD	A,$01
		CALL	CHOPEN
		POP	AF
		PUSH	AF
		CP	$FF
		JR	NZ,ERRP3DOS
		LD	HL,MESSERRSNAP
		JR	LMESSERR

ERRP3DOS:	LD	HL,MESSERR
LMESSERR:	CALL	PR_MEN
		POP	AF
		LD	L,A
		LD	H,$00
		CP	$FF
		JR	NZ,GENUINO_P3DOS
		LD	A,(PAG_FILE)
		LD	L,A
		LD	H,$00
GENUINO_P3DOS:	CALL	NUMBER2

BLOQUEO:	LD	BC,309
		EI
		HALT
		DI
		LD	D,$00
		LD	HL,$0128
ERRW:		DEC	BC
		LD	A,B
		OR	C
		JR	NZ,ERRW
ERROR1A:	LD	A,D
		INC	A
		AND	$07
		OUT	($FE),A
		LD	D,A
		PUSH	HL
		POP	BC
ERROR2A:	DEC	BC
		LD	A,B
		OR	C
		JR	NZ,ERROR2A
		JR	ERROR1A

NUMBER2:	LD	DE,10		; IMPRIME UN NRO. <= 99
		CALL	DIVID1
NUMBER1:	LD	C,L
		JR	DIVID2
DIVID1:		AND	A
		LD	C,0
LCALC2:		SBC	HL,DE
		JR	C,DIVID2
		INC	C
		JR	LCALC2
DIVID2:		ADD	HL,DE
		LD	A,$30
		ADD	A,C
		RST	10H
		RET

PR_MEN:		LD	A,(HL)
		CP	$FF
		RET	Z
		RST	10H
		INC	HL
		JR	PR_MEN

PRHEX:		LD	A,H
		CALL	PRHEX_LEFT
		LD	A,H
		CALL	PRHEX_RIGHT
		LD	A,L
		CALL	PRHEX_LEFT
		LD	A,L
		CALL	PRHEX_RIGHT
		RET

PRHEX_LEFT:	AND	%11110000
		SRL	A
		SRL	A
		SRL	A
		SRL	A
CONT_DIGITX:	CP	$0A
		JR	NC,SUMA_A
		ADD	A,$30
		RST	10H
		RET
SUMA_A:		ADD	A,$37
		RST	10H
		RET

PRHEX_RIGHT:	AND	%00001111
		JR	CONT_DIGITX

MESSERR:	DB	22,1,0,"+3DOS ERR:"
		DB	$FF
MESSERRSNAP:	DB	22,1,0,"ERR Z80 format, PAG:"
		DB	$FF
MSGAT:		DB	22,0,0,$FF

;===================================================================================================
; PARA QUE NO MOLESTE LA RUTINA DE LECTURA DEL TECLADO O EL MOTOR DEL DRIVE
; (corrompería parte del prog. cargado al alterar las vars. del sistema)

INTERRUP:	RETI

SET_MYINT:	DI
		LD	HL,INTERRUP
		LD	($47FF),HL
		LD	A,$47
		LD	I,A
		IM	2
		RET

;===================================================================================================

AY_REGS:	DB	$00,$00,$00,$00	; aqui se guardan momentáneamente los
		DB	$00,$00,$00,$00	; registros del AY-3-8912 para ser
		DB	$00,$00,$00,$00	; recuperados antes de lanzar el Z80
		DB	$00,$00,$00,$00

TIPOSNAP:	DB	$00
CPOS:		DW	$0000
COUNT:		DW	$0000
ORIGEN:		DW	$0000
P7_TAM:		DW	$0000
LAST_7FFD:	DB	$00
LAST_1FFD:	DB	$04
PAG_FILE:	DB	$00
CTRL_BUFFER:	DW	$0000
RSP:		DW	$0000
MULTIFACE3:	DB	$00

		BLOCK	160,$00		; TAMAÑO DEL STACK AUN NO PUDE
STACK		EQU	$		; DETERMINAR EL TAMAÑO MINIMO
					; (2023) PERO 160 BYTES SON NECESARIOS
					; PARA EL +3e CUANDO CARGA DESDE OTRA
					; COSA QUE NO SEA A:

BUFF_IMP:	BLOCK	$100,$00	; RESERVO 256b PARA GUARDAR (5B00-5BFF)
					; ESTO ES UN DESPERDICIO PERO
					; LAMENTABLEMENTE ES NECESARIO PORQUE
					; +3DOS PUEDE LLEGAR A CORROMPER ESTA
					; ZONA UNA VEZ CARGADA LA PAG 5

DESCOMP_BUFF:	BLOCK	$100,$00	; RESERVO 256 PARA EL BUFFER
					; DE DESCOMPRESION

;===================================================================================================
; PUERTOS DE SWITCHEO DE MEMORIA +3

PBANK678:	EQU	$1FFD	; PUERTO CONF. DE PAGINAS RAM (2)

;===================================================================================================

CARGADORES:	EQU	$

; ==========================================================================
; COMIENZA LA CARGA DE UN SNAP 128K
; ==========================================================================

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		ORG	CARGADORES ;!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

		DB	"SNAP128K"

SNAP128K:	CALL	READ_REG	; LEE REGISTROS DEL SNAP DESDE EL ARCH.
		LD	A,5
		CALL	GOTO_PAG	; BUSCA LA PAGINA 8 (DEL ARCHIVO RAM5)
		LD	A,6
		CALL	UNP_PAG		; Y LA DESCOMPRIME EN LA PAGINA 6
		LD	A,$06
		LD	BC,PBANKM
		OUT	(C),A

		LD	A,(MULTIFACE3)	; SI HAY MF3 HACE UNA COPIA DEL PRIMER
		AND	A		; TERCIO DEL SCREEN$ DEL Z80 EN
		JR	Z,NO_COPYSCR	; "SU" MEMORIA DE ESTE MODO PODEMOS
		IN_MF3			; AL FINAL RECUPERAR "TODA" LA MEMORIA
		LD	HL,$C000	; 128K
		LD	DE,$2000
		LD	BC,$1B00
		LDIR
		OUT_MF3
		LD	A,$07
		LD	BC,PBANKM
		OUT	(C),A
		JR	M_SCREEN0

NO_COPYSCR:	LD	HL,$C000
		LD	DE,$8000
		LD	BC,$1B00
		LDIR
		LD	A,$0F		; PONE LA PANTALLA EN SCREEN2
		LD	BC,PBANKM	; el motivo de esto es poder ver
		OUT	(C),A		; la pantalla completa mientras se
		LD	HL,$8000	; carga el juego, ya que podr¡a haber
		LD	DE,$C000	; en ella alg£n men£ o un mensaje que
		LD	BC,$1B00	; necesitemos saber para usar el juego
		LDIR			; (SI ES QUE NO HAY MF3)
		LD	A,%00001111
		LD	(BANKM),A
		LD	(SCREEN2_B+1),A
		LD	(SCREEN2_D+1),A
		LD	A,%00001000
		LD	(SCREEN2_A+1),A
		LD	A,%00001110
		LD	(SCREEN2_C+1),A

M_SCREEN0:	CALL	GO_FIRSTPAG
		XOR	A		; CARGA Y DESCOMPRIME PAGINAS:
LPAG_01234:	PUSH	AF		; 0,1,2,3, y 4
		CALL	GET_TAMPAG
		LD	C,A
		POP	AF
		CP	C
		JP	NZ,ERRSNAP
		PUSH	AF
		CALL	UNP_PAG
		POP	AF
		INC	A
		CP	5
		JR	NZ,LPAG_01234

		CALL	GET_TAMPAG	; DESCOMPRIME PAGINA 8 (DEL ARCHIVO QUE
		CP	5		; CORRESPONDE A LA PAGINA 5 DE LA RAM)
		JP	NZ,ERRSNAP
		LD	A,6		; EN PAGINA 6 DE RAM (aunque ya estaba
		CALL	UNP_PAG		; descomprimida, pero por las dudas)

SCREEN2_C:	LD	A,$06
		LD	BC,PBANKM
		OUT	(C),A

		LD	HL,$C000+$801	; PARTE DE LA PANTALLA QUE SE
		LD	DE,$4000+$801	; PUEDE USAR SIN PELIGRO
		LD	BC,$0FFF+$300	; TERCIOS 2 y 3 + ATRIBUTOS
		LDIR			; MENOS UN BYTE PARA NO ALTERAR 4800h
					; (vector int)

		LD	HL,$DB00       	; GUARDA "BUFFER IMPRESORA"
		LD	DE,BUFF_IMP	; PORQUE TODAVIA HAY QUE USAR +3DOS
		LD	BC,$0100
		LDIR

		LD	HL,$C000+$1C00	; COPIAR DESDE DC00h en 5C00h
		LD	DE,$4000+$1C00	; DE PAGINA 5
		LD	BC,$4000-$1C00
		LDIR

SCREEN2_D:	LD	A,$07
		LD	BC,PBANKM
		OUT	(C),A

		CALL	GET_TAMPAG	; DESCOMPRIME PAGINA 9 (DEL ARCHIVO)
		CP	6		; EN PAGINA 6 DE RAM (CORRECTO)
		JP	NZ,ERRSNAP
		CALL	UNP_PAG

		CALL	GET_TAMPAG
		CP	7
		JP	NZ,ERRSNAP
		LD	(P7_TAM),HL

		LD	A,$07
		LD	(SCREEN2_B+1),A
		LD	(BANKM),A
		LD	BC,PBANKM
		OUT	(C),A
		LD	A,%00000000
		LD	(SCREEN2_A+1),A

; ==========================================================================

		; ADICION -> 2023
		;
		; EN ÉPOCAS DEL +3e TUVE QUE REVISAR LAS "ZONAS SEGURAS"
		; ESO ES POR QUE LAS ROMS DEL +3e USAN EN FORMA MAS INTENSA
		; LA MEMORIA DE LA PAG7, Y TAMBIEN EL ESPACIO NECESARIO PARA
		; EL STACK

		; NOTA PARA +3e:

		; Cuando se accede a unidades que no sean las físicas A: o B:
		; el +3e hace un uso mucho mas intenso de la RAM7 que no debe
		; ser corrompida mientras accedemos a las unidades.

		; En un +3 normal encontré muchas zonas de RAM7 que no se usan
		; en donde iba cargando trozos de lo que iba entrando desde el
		; disco y si no era suficiente hechaba mano de la pantalla
		; entre 4801 y 57FF, luego juntaba todos los trozos en la RAM7 
		; mediante LDIRs y descomprimía, con lo que me aseguraba de 
		; recuperar la "casi totalidad" de la RAM7. (también parece ser
		; que usa mas stack cuando carga de C: o D: etc)

		; Lamentablemente en un +3e la única zona segura en RAM7 son los
		; primeros 6912 bytes a partir de #C000, así que solo puedo
		; recuperar 6912 bytes mas 4096 bytes (de la pantalla), siendo un
		; total de 11008 bytes, y si esto no fuera suficiente para cargar
		; toda la página comprimida del Z80, las chances de que el Z80
		; no funcione son altas.

		LD	BC,$0607	; LEE POR PARTES LA PAGINA 10
		LD	DE,$1B00	; (DEL ARCHIVO) EN LAS ZONAS QUE SE
		LD	HL,$C000	; PUEDEN USAR SIN PELIGRO DE LA PAGINA
		CALL	DOS_READ	; 7 (C000h - DAFFh) - en un +3e parece
		JR	NC,OK_LOAD_P7	; ser que esta es la única segura

		LD	BC,$0607	; SI LAS ZONAS ANTERIORES NO FUERON
		LD	DE,4096-1	; SUFICIENTES ENTONCES SE HECHA MANO
		LD	HL,$4801	; DE LA PANTLLA EN PAGINA 5 (NO QUEDA
		CALL	DOS_READ	; DE OTRA)
		JR	OK_LOAD_P7

		;JR	NC,OK_LOAD_P7	; descomentar y comentar la línea
					; anterior, si queremos controlar
					; falta de espacio para CARGAR RAM7

MUY_GRANDE_P7:	LD	A,R		; no se puede cargar toda la RAM7
		AND	$07
		OUT	($FE),A
		JR	MUY_GRANDE_P7

; ==========================================================================

OK_LOAD_P7:	DI			; DESHABILITO INTERRUPCIONES Y APAGA
		CALL	DD_L_OFFMOTOR	; EL MOTOR DEL DRIVE DE LO CONTRARIO
					; SIGUE GIRANDO ETERNAMENTE SI ES
					; UNA DISQUETERA FISICA

		LD 	HL,$4801
		LD 	DE,$C000 + $1B00
		LD 	BC,4096-1
		LDIR

		LD	HL,(P7_TAM)	; AHORA QUE ESTA TODO JUNTO SE DESCOMPRIME
		LD	(COUNT),HL
		LD	HL,$C000
		LD	(CPOS),HL
		CALL	UNP_PAG2

		LD	HL,AY_REGS	; SE LEEN LOS REGISTROS DEL AY-3-8912
		XOR	A		; RECUPERADOS POR "READ_REG"
LSET_REG_AY:	PUSH	AF
		LD	BC,$FFFD
		OUT	(C),A
		LD	BC,$BFFD
		LD	A,(HL)
		OUT	(C),A
		POP	AF
		INC	HL
		INC	A
		CP	16
		JR	NZ,LSET_REG_AY
		LD	BC,$FFFD
		LD	A,(LAST_FFFD)
		OUT	(C),A

		LD	HL,BUFF_IMP	; RECUPERA 5B00h - 5BFFh
		LD	DE,$5B00
		LD	BC,$0100
		LDIR

		LD	BC,PBANK678	; SE PONE EL PORT 1FFD A SU
		LD	A,(LAST_1FFD)	; VALOR ESTANDAR O EL INDICADO
		OUT	(C),A		; POR EL Z80

		LD	BC,PBANKM
		LD	A,(LAST_7FFD)
		OUT	(C),A

		CALL	SET_REG		; SE CARGAN LOS REGISTROS

		LD	A,(MULTIFACE3)
		AND	A
		JR	Z,BOOT_SIN_MF3

		IN_MF3
		LD	HL,$B0ED	; LDIR
		LD	($4000),HL
		LD	HL,$BFDB	; IN A,(BFh)
		LD	($2000+2),HL
		LD	HL,BOOT128K	; SE COPIA EN 2000h DE LA RAM DEL MF3
		LD	DE,$2000+4	; EL BOOTSTRAP POR QUE SI NO AL HACER
		LD	BC,RPC-BOOT128K+3; EL LDIR EL PROGRAMA SE PERDERIA
		LDIR
		LD	HL,$2002
		LD	DE,$4002
		LD	BC,$1B00-2
		LD	SP,(RSP)
		JP	$4000

BOOT_SIN_MF3:	LD	SP,(RSP)
		JP	BOOT128K	; SE LANZA EL JUEGO

		DB	"ENDRUNZ80"

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		ORG	CARGADORES ;!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

; ==========================================================================
; COMIENZA LA CARGA DE UN SNAP 48K
; ==========================================================================
;
; ESTA RUTINA SUFRIO LA MODIFICACION DE SELECCIONAR QUE PAGINA SE
; CARGA Y EN DONDE... ES DECIR, LAS VA COLOCANDO DEPENDIENDO DEL NRO.
; DE ID DE PAGINA QUE VAYA ENTRANDO, PORQUE DIFERENTES EMULADORES
; LAS ALMACENAN EN DISTINTO ORDEN

		DB	"SNAP48K"

SNAP48K:	CALL	READ_REG	; SE CARGAN LOS VALORES DE LOS
					; REGISTROS
		CALL	GO_FIRSTPAG
		LD	B,$03		; 3*16k de paginas (49152 bytes RAM)
BUCL_48K:	PUSH	BC
		CALL	GET_TAMPAG
		CP	$05		; PAGINA FISICA 5 (PANTALLA)
		JR	Z,DESC_SCREEN
		CP	$01		; PAGINA FISICA 2 ($8000-$BFFF)
		JR	Z,DESC_8000
		CP	$02		; PAGINA FISICA 0 ($C000-$FFFF)
		JR	Z,DESC_C000
		JP	ERRSNAP

DESC_8000:	LD	A,$02		; SE CARGA EN PAGINA 2 DE RAM
		CALL	UNP_PAG
		JR	NEXT_L48K

DESC_C000:	XOR	A		; SE CARGA EN PAGINA 0 DE RAM
		CALL	UNP_PAG
		JR	NEXT_L48K

DESC_SCREEN:	LD	A,$06		; PAGINA 5 (PERO LA PONE DE MOMENTO
		CALL	UNP_PAG		; EN LA 6 YA QUE EN LA 5 ESTA ESTE
NEXT_L48K:	POP	BC		; PROGRAMA TODAVIA)
		DJNZ	BUCL_48K

FIN_LOAD48K:	DI
		LD	A,$06
		LD	BC,PBANKM
		OUT	(C),A
		LD	HL,$DB00	; SE RECUPERA DESDE 5C00h A 7FFFh
		LD	DE,$5B00	; EN PAGINA 5
		LD	BC,$4000-$1B00
		LDIR
		XOR	A
		LD	BC,PBANKM
		OUT	(C),A

		LD	A,$06		; SE COPIA EN C000h DE PAGINA 6
		LD	BC,PBANKM	; EL BOOTSTRAP POR QUE SI NO AL
		OUT	(C),A		; HACER EL LDIR EN BOOT48K EL PROGRAMA
		LD	HL,BOOT48K	; SE PERDERIA
		LD	DE,$C000
		LD	BC,RPC-BOOT48K+3
		LDIR

		CALL	SET_REG		; SE CARGAN LOS REGISTROS

		LD	A,(IM_MODE)	; ESTE ES UN ARREGLO ESPECIAL SOLO PARA
		CP	$5E		; LANZAR JUEGOS DE 48K EN EL PLUS3
		JR	NZ,REG_INT_OK	; CUANDO EL REGISTRO I TIENE UN VALOR
		LD	A,(RINT+1)	; MENOR A 40h SE LE DA EL VALOR 3Bh
		CP	$40		; PORQUE (3BFFh)=FFFFh (esta es una
		JR	NC,REG_INT_OK	; fuente de muchas incompatibilidades
		LD	A,$3B		; de juegos 48K en el +3,+2A y +2B)
		LD	I,A

REG_INT_OK:	LD	SP,(RSP)
		LD	A,%00000100
		LD	BC,$1FFD
		OUT	(C),A
		LD	HL,$C000
		LD	DE,$4000
		LD	BC,$1B00

REG_LATCH:	LD	A,$00
		JP	BOOT48K		; SE LANZA EL JUEGO (HL, DE, BC)
					; YA LLEVAN LOS VALORES ADECUADOS PARA
					; EL LDIR EN BOOT48K, Y EL REGISTRO A
					; LLEVA EL VALOR A PONER EN EL PUERTO
					; 7FFD (USUALMENTE 30H) PERO PUEDE SER
					; TAMBIEN 10H (VER ETIQUETA USR0)

		DB	"ENDRUNZ80",$00	; NO REMOVER!! ES PARA ENCONTRAR EL FINAL
					; DE LAS RUTINAS DE CARGA 48K/128K