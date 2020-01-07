INCLUDE "hardware.inc"


SECTION "Header", ROM0[$100]

EntryPoint:
	di
	jp Start

REPT $150 - $104
	db 0
ENDR


SECTION "Game Code", ROM0[$150]

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

    ; Load tile
    ld de, FontTiles
    ld bc, FontTilesEnd - FontTiles
    ld hl, $8800

.copyTiles
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .copyTiles

    ; Load map
    ld hl, $9800
    ld b, $0A
    ld c, $80

.copyNumbers
    ld a, c
    ld [hli], a
    inc c
    dec b
    ld a, b
    jr nz, .copyNumbers

	; Enable display with background
	ld a, %10000001
	ld [rLCDC], a

.loop
	jr .loop


SECTION "Font", ROM0

FontTiles:
INCBIN "font.bin"
FontTilesEnd:
