
; CP/M program demonstrating 2 button input on the Nabu with
; a Sega Master System controller.

; SMS Controllers wire button 2 to pin 9, which is a paddle input
; pin on the Nabu. Pushing the button causes the Nabu to raise a
; paddle interrupt. The interrupts aren't debounced, and you can
; only guess if they are caused by button up or button down changes.
; But just knowing there was activity is good enough to be useful
; in some games.

BDOS equ $0005

    ; Generate Ascii Hex for a number
    MACRO WRITEHEX target
        ld b, a
        and $0F
        add a, $90
        daa
        adc a, $40
        daa
        ld (target+1), a ; Store the lower ASCII character

        ld a, b
        rrca
        rrca
        rrca
        rrca
        and $0F
        add a, $90
        daa
        adc a, $40
        daa
        ld (target+0), a ; Store the upper character
    ENDM

	ORG $100

    di
    ld a, $ff ; High bits of interrupt vector
    ld i, a
    im 2

    ld hl, input_interrupt
    ld ($ff00 + 4), hl

    ; set up interrupts on PSG ports
    ld a, $07 ; Set reg 7
    out ($41), a
    ld a, $7f ; Port A write, B read, mixers to 0
    out ($40), a
    ld a, $0e ; Select port A.
    out ($41), a
    ld a, $10 ; enable input interrupt
    out ($40), a

    ld c, $9
	ld de, Hello
	call BDOS

    ei
waitLoop:
    halt    
l2: ld a, (todo)
    cp 1
    jr z, button_in
	cp 2
	jr z, paddle_in
    cp 3
    jp z, newline_in
    jr waitLoop

button_in:
    xor a
    ld (todo), a
    ld a, (bstate)
    cp 0
    jr z, bWasUp
bWasDown:
    ld a, (jv)
    bit 4, a
    jr z, bUp
    jr l2
bWasUp:
    ld a, (jv)
    bit 4, a
    jr nz, bDown
    jr l2
bUp:
    WRITEHEX U1Hex

    ld de, B1Up
    ld c, $9
    call BDOS
    ei
    xor a
    ld (bstate), a ; clear button down
    jr l2
bDown:
    WRITEHEX D1Hex

    ld de, B1Down
    ld c, $9
    call BDOS
    ei
    ld a, 1
    ld (bstate), a ; set button down
    jp l2

paddle_in:
	xor a
    ld (todo), a
    ld a, (pv2)     ; Look at the second byte of paddle 1 status
    cp $d8          ; High nibble is always $d, low nibble here is the high nibble of the paddle position
    jp c, pDown
                    ; If >= $80, maybe that indicates the button was released?
	ld a, (pv1)
	WRITEHEX U2Hex
	ld a, (pv2)
	WRITEHEX U2Hex+3
	ld a, (pv3)
	WRITEHEX U2Hex+6
	ld a, (pv4)
	WRITEHEX U2Hex+9
	ld de, B2Up
    jr pDone

pDown:
	ld a, (pv1)
	WRITEHEX D2Hex
	ld a, (pv2)
	WRITEHEX D2Hex+3
	ld a, (pv3)
	WRITEHEX D2Hex+6
	ld a, (pv4)
	WRITEHEX D2Hex+9
	ld de, B2Down

pDone:
    ld c, $9
    call BDOS
    ei
	jp l2

newline_in:
    xor a
    ld (todo), a
    ld de, D1Hex+2
    ld c, $9
    call BDOS
    ei
    jp l2


todo: db 0
bstate: db 0
jv: db 0
pv1: db 0
pv2: db 0
pv3: db 0
pv4: db 0

input_interrupt:
    push af
    in a, ($90)

    cp $80          ; Joystick 1
    jr z, jbutton
    cp $84          ; Paddle 1
    jr z, paddle
    cp $0d          ; Newline
    jr z, newline
    cp $20          ; Space
    jr z, quit

    jr exiti

jbutton:
    in a, ($91)
    bit 1, a
    jr z, jbutton
    in a, ($90)     ; Read joystick status value
    ld (jv), a
    ld a, 1
    ld (todo), a
    jr exiti

paddle:
    push bc
    push hl
    ld hl, pv1
    ld b, 4
ploop:
    in a, ($91)
    bit 1, a
    jr z, ploop
    in a, ($90)     ; Read four paddle status values
    ld (hl), a
	inc hl
	djnz ploop
	ld a, 2
	ld (todo), a
    pop hl
    pop bc
    jr exiti

newline:
    ld a, 3
    ld (todo), a

exiti:
    pop af
    ei
    reti

quit:
    ld c, 0
	call BDOS

Hello:
	DB "Two button input tester for SMS pads on",$0d,$0a,"the Nabu.",$0d,$0a,"$"
B1Down:
    DB "B One down: 80 "
D1Hex:
    DB "00",$0d,$0a,"$"
B1Up:
    DB "B One up:   80 "
U1Hex:
    DB "00",$0d,$0a,"$"
B2Down:
    DB "B Two activity: 84 "
D2Hex:
    DB "00 00 00 00 Down?",$0d,$0a,"$"
B2Up:
    DB "B Two activity: 84 "
U2Hex:
    DB "00 00 00 00 Up?",$0d,$0a,"$"