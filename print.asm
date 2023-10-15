;		.TITLE "Rutina para imprimir en 32,42,51,64,85 columnas"

/*
poner explicaciones que esta rutina es una version recortada a partir
de mi utilidad "TOTAL PRINT" y solo soporta modos 32/42 cols que es
todo lo que necesito para mi +3SELECTOR
*/

;------------------------------------------------------------------------
;                               CUT HERE
;------------------------------------------------------------------------

PRINT:		PUSH	AF
		PUSH	BC
		PUSH	DE
		PUSH	HL
		LD	(CHAR),A

PUNTOENT:	JP	XPRINT

XPRINT:		CP	32
		JP	C,CONTROL

NOCTR:		LD	A,(FILA)
		CP	24
		JR	C,NO_SCROLL
		LD	A,23
		LD	(FILA),A
		CALL	SCROLL
NO_SCROLL:	LD	A,(FILA)
		LD	B,A
		LD	C,$00

JUMP_PRINT:	JP	OKT32

OKT32:		CALL	GETP31
		JP	PRN32

OKT42:		CALL	CHRGETPOS
		JP	PRN42

ENDPRINT:	LD	A,(COL)
		INC	A
		LD	(COL),A
		LD	E,A
		LD	A,(MAXCOL)
		CP	E
		JR	NC,QUIT
		XOR	A
		LD	(COL),A
		LD	A,(FILA)
		INC	A
		LD	(FILA),A
QUIT:		POP	HL
		POP	DE
		POP	BC
		POP	AF
CHINT:		RET

;SALTA AL CODIGO DE CONTROL = A
CONTROL:	ADD	A,A
		LD	E,A
		LD	D,$00
		LD	HL,C_CONTROL
		ADD	HL,DE
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		EX	DE,HL
		JP	(HL)

;OBTIENE LA DIRECCION EN PANTALLA
;B=FILA (COL)=COLUMNA
GETP31:		LD	A,(COL)
		LD	C,A
;IDEM PERO B=FILA C=COLUMNA
CHRGETPOS:	LD	A,B
		AND	$F8
		ADD	A,$40
		LD	H,A
		LD	A,B
		AND	7
		RRCA
		RRCA
		RRCA
		ADD	A,C
		LD	L,A
		LD	(POSPAN),HL
		RET

;OBTIENE LA POSICION DEL ATRIBUTO A
;PARTIR DE LA DIRECCION PANTALLA
GETATT:		LD	HL,(POSPAN)
		LD	A,H
		RRCA
		RRCA
		RRCA
		AND	$03
		OR	$58
		LD	D,A
		LD	E,L
		LD	(POSATT),DE
		RET

;IMPRESION 32 COLUMNAS
PRN32:		CALL	GETCHR
		LD	HL,(POSPAN)
		LD	DE,CHRBUFFER
		LD	B,$08
LPRN32:		LD	A,(DE)
		LD	(HL),A
		INC	H
		INC	DE
		INC	DE
		DJNZ	LPRN32
SET_ATTR:	CALL	GETATT
		LD	A,(COLOR)
		LD	(DE),A
		JP	ENDPRINT

;LLAMA A "LAS RUTINAS" DE IMPRESION EN 42 COLUMNAS SEGUN LA
;TABLA POSC42 INDEXADA POR LOS 2 PRIMEROS BITS DE (COL)
PRN42:		LD	A,(COL)
		AND	%00000011
		ADD	A,A
		LD	HL,POSC42
		JR	CONTPRN

;RUTINA DE SALTO COMPARTIDA A LAS "DIFERENTES"
;RUTINAS DE IMPRESION
CONTPRN:	LD	E,A
		LD	D,$00
		ADD	HL,DE
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		EX	DE,HL
		JP	(HL)

;LLAMA A DIFERENTES RUTINAS PARA METER EL CARACTER A
;IMPRIMIR EN UN CHRBUFFER DE 16 BYTES
GETCHR:		LD	A,(CHAR)
		LD	L,A
		LD	H,$00	
		ADD	HL,HL	;*2
		ADD	HL,HL	;*4
		ADD	HL,HL	;*8
XFONT:		LD	DE,FONT32
		DEC	D
		ADD	HL,DE
		LD	DE,CHRBUFFER
		EX	DE,HL
		LD	B,$08
LOOP_CHR1:	LD	A,(DE)
XMASK1:		AND	%11111111
I_CPL:		NOP
XMASK2:		AND	%11111111
		LD	(HL),A
		INC	HL
		LD	(HL),$00
		INC	HL
		INC	DE
		DJNZ	LOOP_CHR1
		RET

;RUTINA DE ROTACION DEL CHRBUFFER CON EL CARACTER
;A IMPRIMIR, DEPENDIENDO DE LAS NECESIDADES DE
;LAS RUTINAS DE IMPRESION
;A=NUMERO DE ROTACIONES

ROTAR:		LD	B,$08
		LD	HL,CHRBUFFER
ROT1:		PUSH	BC
		LD	B,A
ROT2:		SRL	(HL)
		INC	HL
		RR	(HL)
		DEC	HL
		DJNZ	ROT2
		INC	HL
		INC	HL
		POP	BC
		DJNZ	ROT1
		RET

;==================================================================

DOSATT:		LD	A,(COLOR)
		LD	(DE),A
		INC	DE
		LD	(DE),A
		JP	ENDPRINT

;==================================================================

POS0_42:	CALL	GETCHR
		CALL	OFFSET_TO42
		LD	HL,(POSPAN)
		ADD	A,L
		LD	L,A
		LD	(POSPAN),HL
		LD	DE,CHRBUFFER
		LD	B,$08
		EX	DE,HL
LPUT0_42:	LD	A,(DE)
		AND	%00000011
		OR	(HL)
		LD	(DE),A
		INC	D
		INC	HL
		INC	HL
		DJNZ	LPUT0_42
		JP	SATT_42

POS1_42:	CALL	GETCHR
		LD	A,6
		CALL	ROTAR
		CALL	OFFSET_TO42
		LD	HL,(POSPAN)
		ADD	A,L
		LD	L,A
		LD	(POSPAN),HL
		LD	DE,CHRBUFFER
		LD	B,$08
		EX	DE,HL
LPUT1_42:	LD	A,(DE)
		AND	%11111100
		OR	(HL)
		LD	(DE),A
		INC	DE
		LD	A,(DE)
		AND	%00001111
		INC	HL
		OR	(HL)
		LD	(DE),A
		INC	HL
		DEC	DE
		INC	D
		DJNZ	LPUT1_42
		JR	SATT_42

POS2_42:	CALL	GETCHR
		LD	A,4
		CALL	ROTAR
		CALL	OFFSET_TO42
		LD	HL,(POSPAN)
		ADD	A,L
		INC	A
		LD	L,A
		LD	(POSPAN),HL
		LD	DE,CHRBUFFER
		LD	B,$08
		EX	DE,HL
LPUT2_42:	LD	A,(DE)
		AND	%11110000
		OR	(HL)
		LD	(DE),A
		INC	DE
		LD	A,(DE)
		AND	%00111111
		INC	HL
		OR	(HL)
		LD	(DE),A
		INC	HL
		DEC	DE
		INC	D
		DJNZ	LPUT2_42
		JR	SATT_42

POS3_42:	CALL	GETCHR
		LD	A,2
		CALL	ROTAR
		CALL	OFFSET_TO42
		LD	HL,(POSPAN)
		ADD	A,L
		INC	A
		INC	A
		LD	L,A
		LD	(POSPAN),HL
		LD	DE,CHRBUFFER
		LD	B,$08
		EX	DE,HL
LPUT3_42:	LD	A,(DE)
		AND	%11000000
		OR	(HL)
		LD	(DE),A
		INC	D
		INC	HL
		INC	HL
		DJNZ	LPUT3_42
SATT_42:	CALL	GETATT
		LD	A,(COL)
		AND	%00000011
		CP	1
		JP	Z,DOSATT
		CP	2
		JP	Z,DOSATT
		LD	A,(COLOR)
		LD	(DE),A
		JP	ENDPRINT

OFFSET_TO42:	LD	A,(COL)
		AND	%00111100
		SRL	A
		SRL	A
		LD	C,A
		ADD	A,A	;*2
		ADD	A,C	;(*3)
		RET

;==================================================================
;CONTROL SCROLL (4) - HACE SCROLL DE 1 FILA HACIA ARRIBA

XSCROLL:	CALL	SCROLL
		JP	QUIT

SCROLL:		LD	DE,$4000
		LD	HL,$4020
		LD	B,23
LSCROLL:	PUSH	BC
		PUSH	HL
		PUSH	DE
		LD	B,$08
LXSCROLL:	PUSH	DE
		PUSH	HL
		PUSH	BC
		LD	BC,$0020
		LDIR
		POP	BC
		POP	HL
		POP	DE
		INC	D
		INC	H
		DJNZ	LXSCROLL
		POP	HL
		LD	BC,$0020
		LD	A,L
		CP	$E0
		JR	C,NO_CHBLQ1
		LD	A,H
		ADD	HL,BC
		LD	H,A
		LD	BC,$0800
NO_CHBLQ1:	ADD	HL,BC
		EX	DE,HL
		POP	HL
		LD	BC,$0020
		LD	A,L
		CP	$E0
		JR	C,NO_CHBLQ2
		LD	A,H
		ADD	HL,BC
		LD	H,A
		LD	BC,$0800
NO_CHBLQ2:	ADD	HL,BC
		POP	BC
		DJNZ	LSCROLL
		EX	DE,HL
		LD	B,$08
LBORRA:		PUSH	BC
		PUSH	HL
		LD	D,H
		LD	E,$E1
		LD	BC,$001F
		LD	(HL),B
		LDIR
		POP	HL
		POP	BC
		INC	H
		DJNZ	LBORRA
		LD	HL,$5820
		LD	DE,$5800
		LD	BC,$02E0
		LDIR
		LD	A,(COLOR)
		PUSH	DE
		POP	HL
		INC	DE
		LD	(HL),A
		LD	BC,$001F
		LDIR
		RET

;==================================================================
;CONTROL LINEFEED (10)

LF:		LD	A,(FILA)
		CP	23
		JR	NC,GOSCROLL
		INC	A
OKSCR:		LD	(FILA),A
		JP	QUIT
GOSCROLL:	CALL	SCROLL
		LD	A,23
		JR	OKSCR

;==================================================================
;CONTROL BACKLINE (11)

UP:		LD	A,(FILA)
		AND	A
		JR	Z,SUP
		DEC	A
		LD	(FILA),A
SUP:		JP	QUIT

;==================================================================
;CONTROL CLEAR SCREEN (12)

CLS		LD	HL,$4000
		LD	E,L
		LD	D,H
		INC	E
		LD	(HL),L
		LD	BC,6143
		LDIR
		LD	HL,$5800
		LD	E,L
		LD	D,H
		INC	E
		LD	A,(COLOR)
		LD	(HL),A
		LD	BC,767
		LDIR
		LD	A,(BORATT)
		OUT	($FE),A
		XOR	A
		LD	(FILA),A
		LD	(COL),A
		JP	QUIT

;==================================================================
;CONTROL "CONTROL" (13)

CR:		XOR	A
		LD	(COL),A
		LD	A,(CRLF)
		AND	A
		JR	Z,LF
		JP	QUIT

;==================================================================
;CONTROL "NUMERO" (14) -IMPRIME EL NUMERO EN DECIMAL DE LO QUE VALE
;HL, SIN PADDINGS NI CEROS AL PRINCIPIO, O SEA... SI HL=123 IMPRIME
;123 TAL CUAL Y NO "___123" o "000123"

NUMERO:		POP	HL
		PUSH	HL
		LD	A,H
		OR	L
		JR	NZ,NZ_NUMERO

		LD	A,"0"			;HL=0? ENTONCES IMPRIMO
		CALL	PRINT			;UN "0" Y ME VUELVO
		JP	QUIT

NZ_NUMERO:	XOR	A
		LD	(PRIMER_CERO+1),A
		POP	HL
		POP	DE
		PUSH	DE
		PUSH	HL
		CALL	PRNUM_16B
		JP	QUIT

PRNUM_16B:	LD	DE,10000
		CALL	DIVIDIR
		LD	DE,1000
		CALL	DIVIDIR
		LD	DE,100
		CALL	DIVIDIR
		LD	DE,10
		CALL	DIVIDIR
		LD	C,L
		JR	DIVIDIR2

DIVIDIR:	AND	A
		LD	C,0
LINECALC2:	SBC	HL,DE
		JR	C,DIVIDIR2
		INC	C
		JR	LINECALC2

DIVIDIR2:	ADD	HL,DE
		LD	A,"0"
		ADD	A,C
		LD	C,A
		CP	"0"
		JR	NZ,OK_PRNUMERO
PRIMER_CERO:	LD	A,$00
		AND	A
		RET	Z

OK_PRNUMERO:	LD	A,$FF
		LD	(PRIMER_CERO+1),A
		LD	A,C
		CALL	PRINT
		RET

;==================================================================
;CONTROL INK (16)

INK:		LD	HL,INK1
		LD	(PUNTOENT+1),HL
		JP	QUIT
INK1:		AND	%00000111
		LD	C,A
		LD	A,(COLOR)
		AND	%11111000
		OR	C
		LD	(COLOR),A
RETBRK:		LD	HL,XPRINT
		LD	(PUNTOENT+1),HL
		JP	QUIT

;==================================================================
;CONTROL PAPER (17)

PAPER:		LD	HL,PAPER1
		LD	(PUNTOENT+1),HL
		JP	QUIT
PAPER1:		AND	%00000111
		RLCA
		RLCA
		RLCA
		LD	C,A
		LD	A,(COLOR)
		AND	%11000111
		OR	C
		LD	(COLOR),A
		JR	RETBRK

;==================================================================
;CONTROL FLASH (18)

FLASH:		LD	HL,FLA
		LD	(PUNTOENT+1),HL
		JP	QUIT
FLA:		AND	%00000001
		AND	A
		JR	Z,NOFLA
		LD	A,(COLOR)
		SET	7,A
		LD	(COLOR),A
		JR	RETBRK
NOFLA:		LD	A,(COLOR)
		RES	7,A
		LD	(COLOR),A
		JR	RETBRK

;==================================================================
;CONTROL BRIGHT (19)

BRIGHT:		LD	HL,BRI
		LD	(PUNTOENT+1),HL
		JP	QUIT
BRI:		AND	%00000001
		AND	A
		JR	Z,NOBRI
		LD	A,(COLOR)
		SET	6,A
		LD	(COLOR),A
		JP	RETBRK
NOBRI:		LD	A,(COLOR)
		RES	6,A
		LD	(COLOR),A
		JP	RETBRK

;==================================================================
;CONTROL INVERSE (20)

INVERSE:	LD	HL,INV1
		LD	(PUNTOENT+1),HL
		JP	QUIT
INV1:		AND	%00000001
		LD	(CTRINV),A
		AND	A
		JR	Z,NO_CPL
		LD	A,$2F
NO_CPL:		LD	(I_CPL),A
		JP	RETBRK

; ==========================================================================
;CONTROL AT (22)

AT:		LD	HL,PARAM1
		LD	(PUNTOENT+1),HL
		JP	QUIT
PARAM1:		CP	24
		JR	NC,SP1
		LD	(FILA),A
SP1:		LD	HL,PARAM2
		LD	(PUNTOENT+1),HL
		JP	QUIT
PARAM2:		LD	E,A
		LD	A,(MAXCOL)
		LD	D,A
		LD	A,E
		CP	D
		JR	NC,SP2
		LD	(COL),A
SP2:		JP	RETBRK

; ==========================================================================
;CONTROL SPACE (23) - REPETIR "A" ESPACIOS

SPACE:		LD	HL,SPACES
		LD	(PUNTOENT+1),HL
		JP	QUIT
SPACES:		LD	HL,XPRINT
		LD	(PUNTOENT+1),HL
		LD	B,A
		LD	A,$20
LSPC:		CALL	PRINT
		DJNZ	LSPC
		JP	QUIT

; ==========================================================================
;CONTROL REPEAT (25) - REPETIR "A" ASCII

REPEAT:		LD	HL,GETTOREP
		LD	(PUNTOENT+1),HL
		JP	QUIT
GETTOREP:	LD	(AUXA),A
		LD	HL,GETREP
		LD	(PUNTOENT+1),HL
		JP	QUIT
GETREP:		LD	B,A
		LD	A,(AUXA)
		CALL	RESBREAK
LREPEAT:	CALL	PRINT
		DJNZ	LREPEAT
		JP	QUIT

; ==========================================================================
;CONTROL PRMENS (26) - IMPRIME UN MENSAJE EN HL QUE TERMINA EN $FF

PRMENS:		POP	HL
		PUSH	HL
		CALL	PRMSG
		JP	QUIT

PRMSG:		LD	A,(HL)
		CP	$FF
		RET	Z
		CALL	PRINT
		INC	HL
		JR	PRMSG

; ==========================================================================
;CONTROL CHANGEMODE (28) - CAMBIA MODO DE IMPRESION (AQUI LIMITADO A 32,42)
;(VER "TOTAL PRINT" PARA LOS MODOS DE 32,36,42,51,64,85 cols)

CHANGEMODE:	LD	HL,ALT_CHM
		LD	(PUNTOENT+1),HL
		JP	QUIT

ALT_CHM:	LD	HL,MODOS
		LD	C,A
		LD	B,$00
		ADD	HL,BC
		LD	A,(HL)
		LD	(MAXCOL),A
		CP	41
		JR	Z,PUTC42

PUTC32:		LD	A,31
		LD	(MAXCOL),A
		LD	A,%11111111
		LD	DE,FONT32
		LD	HL,OKT32
		LD	C,$00
		JP	SET_GETCHR

PUTC42:		LD	A,%11111100
		LD	DE,FONT42
		LD	HL,OKT42

SET_GETCHR:	LD	(XMASK1+1),A
		LD	(XMASK2+1),A
		LD	(XFONT+1),DE
		LD	(JUMP_PRINT+1),HL
		LD	A,C
		LD	(LASTMODE),A
		JP	RETBRK

; ==========================================================================
; CONTROL RAINBOW (29)

ZRAINBOW:	LD	HL,BRAINBOW
		LD	(PUNTOENT+1),HL
		JP	QUIT

BRAINBOW:	LD	HL,XPRINT
		LD	(PUNTOENT+1),HL
		LD	(RAINBOWC+1),A
		LD	(RAINBOWC+23),A
		LD	A,(COLOR)
		LD	(ML3+1),A
		LD	A,(LASTMODE)
		LD	(ML4+1),A
		LD	A,28
		CALL	PRINT
		XOR	A
		CALL	PRINT
		LD	HL,RAINBOWC
		LD	B,25
LBRAINBOW:	LD	A,(HL)
		CP	$FF
		JR	NZ,OK_RAINBOW
		PUSH	HL
		LD	HL,(XFONT+1)
		PUSH	HL
		LD	HL,RAINBOWCHR
		LD	(XFONT+1),HL
		LD	A,32
		CALL	PRINT
		POP	HL
		LD	(XFONT+1),HL
		POP	HL
		JP	OK_ERAINBOW

OK_RAINBOW:	CALL	PRINT

OK_ERAINBOW:	INC	HL
		DJNZ	LBRAINBOW

ML3:		LD	A,$00
		LD	(COLOR),A
		LD	A,28
		CALL	PRINT
ML4:		LD	A,$00
		CALL	PRINT
		JP	QUIT

; ==========================================================================

RESBREAK:	LD	HL,XPRINT
SETBREAK:	LD	(PUNTOENT+1),HL
		RET

; ==========================================================================

RAINBOWC:	DB	17,7,16,2,255	;PAPER 7 INK 2
		DB	17,2,16,6,255	;PAPER 2 INK 6
		DB	17,6,16,4,255	;PAPER 6 INK 4
		DB	17,4,16,5,255	;PAPER 4 INK 5
		DB	17,5,16,7,255	;PAPER 5 INK 7

; ==========================================================================

RAINBOWCHR:	DB	%00000001	; ░░░░░░░█
		DB	%00000011	; ░░░░░░██
		DB	%00000111	; ░░░░░███
		DB	%00001111	; ░░░░████
		DB	%00011111	; ░░░█████
		DB	%00111111	; ░░██████
		DB	%01111111	; ░███████
		DB	%11111111	; ████████

; ==========================================================================

POSC42:		DW	POS0_42
		DW	POS1_42
		DW	POS2_42
		DW	POS3_42

; ==========================================================================

C_CONTROL:	DW	QUIT		; 00	;QUITE TODO Y SOLO DEJE LO QUE
		DW	QUIT		; 01 	;ENTIENDO ESENCIAL PARA ESTA
		DW	QUIT		; 02 	;UTILIDAD DESDE MI PROGRAMA
		DW	QUIT		; 03 	;"TOTAL PRINT"
		DW	XSCROLL		; 04
		DW	QUIT		; 05
		DW	QUIT		; 06
		DW	QUIT		; 07
		DW	QUIT		; 08
		DW	QUIT		; 09
		DW	LF		; 10
		DW	UP		; 11
		DW	CLS		; 12
		DW	CR		; 13
		DW	NUMERO		; 14
		DW	QUIT		; 15
		DW	INK		; 16
		DW	PAPER		; 17
		DW	FLASH		; 18
		DW	BRIGHT		; 19	;SUGUIERO USARLO SOLO EN 32C
		DW	INVERSE		; 20	;INVIERTA MASCARA - NO USA ATTR
		DW	QUIT		; 21
		DW	AT		; 22
		DW	SPACE		; 23
		DW	QUIT		; 24
		DW	REPEAT		; 25
		DW	PRMENS		; 26
		DW	QUIT		; 27
		DW	CHANGEMODE	; 28
		DW	ZRAINBOW	; 29
		DW	QUIT		; 30
		DW	QUIT		; 31

; ==========================================================================

MODOS:		DB	31,41		; SOLO DEJE 32c Y 42c

; ==========================================================================

CHAR:		DB	$00
FILA:		DB	$00
COL:		DB	$00
MAXCOL:		DB	31
LASTMODE:	DB	$00
POSPAN:		DW	$0000
POSATT:		DW	$0000
COLOR:		DB	56 		; COME EN 23695
BORATT:		DB	7
CTRINV:		DB	$00
CRLF:		DB	$00
AUXA:		DB	$00

; ==========================================================================

CHRBUFFER:	DW	$00,$00,$00,$00
		DW	$00,$00,$00,$00

		INCLUDE	"font.asm"	; FUENTE 42 COLUMNAS IGUAL A LA
					; ORIGINAL PERO EN MATRIZ DE 6x8

		INCLUDE	"font_ext.asm"	; FUENTE 42 COLUMNAS CON OTROS
					; CARACTERES EN MATRIZ DE 6x8
