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

EntityOrigin: ds 1
EntityX: ds 1
EntityY: ds 1
EntityArrayX: ds 1
EntityArrayY: ds 1
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
	ld hl, Player

	ld a, [hli]
	ld [EntityOrigin], a
	ld [EntityX], a

	ld a, [hli]
	ld [EntityY], a

	ld a, [hli]
	ld [EntityArrayX], a
	ld d, a

	ld a, [hli]
	ld [EntityArrayY], a
	ld e, a

	; Push initial OAM address onto the stack
	ld bc, $fe00
	push bc

.draw
	; Read tile
	ld a, [hli]
	ld [EntityTile], a

	; Store the tile address
	ld b, h
	ld c, l

	; Retrieve OAM address
	pop hl

	; Load sprite
	ld a, [EntityY]
	ld [hli], a

	ld a, [EntityX]
	ld [hli], a

	ld a, [EntityTile]
	ld [hli], a

	ld a, %00000000
	ld [hli], a

	; Push the OAM address onto the stack
	push hl

	; Retrieve the tile address
	ld h, b
	ld l, c

	; Increase X by 16
	ld a, [EntityX]
	add $08
	ld [EntityX], a

	; Decrement array width counter
	dec d
	ld a, d

	; Draw the next tile
	jp nz, .draw

	; Increase Y by 16
	ld a, [EntityY]
	add $08
	ld [EntityY], a

	; Reset array width counter
	ld a, [EntityArrayX]
	ld d, a

	; Reset X position
	ld a, [EntityOrigin]
	ld [EntityX], a

	; Decrement array height counter
	dec e
	ld a, e

	; Draw the next row of tiles
	jp nz, .draw

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
	db $80, $81, $82, $83, $84, $85, $86, $87
GameMapEnd:

SECTION "Entities", ROM0

Player:
	db $10 ; X
	db $20 ; Y
	db $02 ; Array X
	db $03 ; Array Y
	db $00, $02, $01, $03, $04, $06
PlayerEnd:
