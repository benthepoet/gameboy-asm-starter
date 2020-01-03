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

	xor a
	ld [rLCDC], a

	ld a, %11100100
	ld [rBGP], a

	xor a
	ld [rSCY], a
	ld [rSCX], a

	ld [rNR52], a

	ld a, %10000001
	ld [rLCDC], a

.loop
	jr .loop
