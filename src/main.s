INCLUDE "hardware.inc"


SECTION "VBlank IRQ", ROM0[$40]

VBlankIRQ:
    reti

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

	; Set stack pointer
	ld sp, $e000

	; Disable display
	xor a
	ld [rLCDC], a

	; Set the palette
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a

	; Reset scroll registers
	xor a
	ld [rSCY], a
	ld [rSCX], a

	; Disable sound
	ld [rNR52], a

	; Load tiles
	ld de, Tiles
	ld bc, TilesEnd - Tiles
	ld hl, $8000

	call MemCopy

	ld de, Tiles
	ld bc, TilesEnd - Tiles
	ld hl, $8800

	call MemCopy

	; Load game map
	ld de, GameMap
	ld bc, GameMapEnd - GameMap
	ld hl, $9800

	call MemCopy

	; Load sprite
	ld a, $20
	ld [$FE00], a

	ld a, $20
	ld [$FE01], a

	ld a, $02
	ld [$FE02], a

	ld a, %00000000
	ld [$FE03], a

	; Enable display with background
	ld a, %10000011
	ld [rLCDC], a

	; Enable interrupts
	ld a, %00000001
	ld [rIE], a

	ei
	nop

.loop
	halt
	nop

	jr .loop


MemCopy:
.loop
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop

	ret

SECTION "Tiles", ROM0

Tiles:
INCBIN "tiles.bin"
TilesEnd:

SECTION "Game Map", ROM0

GameMap:
	db $81, $80, $82, $84
GameMapEnd:
