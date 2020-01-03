INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

EntryPoint:
	di
	jp Start

REPT $150 - $104
	db 0
ENDR

SECTION "Game Code", ROM0[$160]

Start:

.waitVBlank
	ld a, [rLY]
	cp 144
	jr c, .waitVBlank

	; Disable display
	xor a
	ld [rLCDC], a

	; Set the palette
	ld a, %11100100
	ld [rBGP], a

	; Reset scroll registers
	xor a
	ld [rSCY], a
	ld [rSCX], a

	; Disable sound
	ld [rNR52], a

	; Enable display with background
	ld a, %10000001
	ld [rLCDC], a

.loop
	jr .loop
