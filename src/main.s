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

    ; Load tiles
    ld de, FontTiles
    ld bc, FontTilesEnd - FontTiles
    ld hl, $8800

.copyTile
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .copyTile

    ; Load map
    ld hl, $9800
    ld a, (FontTilesEnd - FontTiles) / 16
    ld b, a
    ld c, $80

.copyNumber
    ld a, c
    ld [hli], a
    inc c
    dec b
    ld a, b
    jr nz, .copyNumber

	; Enable display with background
	ld a, %10000001
	ld [rLCDC], a

.loop
	jr .loop


SECTION "Font", ROM0

FontTiles:
INCBIN "font.bin"
FontTilesEnd:

