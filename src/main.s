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

SECTION "Working RAM", WRAM0

EntityX: ds 1
EntityY: ds 1
EntityTile: ds 1
EntityFlags: ds 1

SECTION "Game Code", ROM0[$150]

Start:

.waitVBlank

	ld a, [rLY]
	cp 144
	jr c, .waitVBlank

	; Set stack pointer
	ld sp, $fffe

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

	; Load player address
	; Load sprite address
	; Load X, Y into RAM
	; Load Array X, Y into registers
	; MemCopy from RAM to OAM

	ld hl, Player

	ld a, [hli]
	ld [EntityX], a

	ld a, [hli]
	ld [EntityY], a


	ld a, [hli]
	ld d, a

	ld a, [hli]
	ld e, a

.drawtile
	; Load sprite
	ld a, [EntityY]
	ld [$FE00], a

	ld a, [EntityX]
	ld [$FE01], a

	ld a, [hli]
	ld [$FE02], a

	ld a, %00000000
	ld [$FE03], a

	dec d
	ld a, d

	ld a, [EntityX]
	ld [EntityX], a

	jp nz, .drawtile

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

DrawEntity:
	

SECTION "Tiles", ROM0

Tiles:
INCBIN "tiles.bin"
TilesEnd:

SECTION "Game Map", ROM0

GameMap:
	db $80, $81, $82, $83, $84, $85, $86, $87
GameMapEnd:

SECTION "Entities", ROM0

Player:
	db $10 ; X
	db $20 ; Y
	db $02 ; Array X
	db $02 ; Array Y
	db $00, $01, $02, $03
PlayerEnd:
