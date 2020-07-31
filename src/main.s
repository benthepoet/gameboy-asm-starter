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

SECTION "High RAM", HRAM

I: ds 1
J: ds 1
K: ds 1

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

	; Load entities address
	ld hl, Entities

	; Push initial OAM address onto the stack
	ld bc, $fe00
	push bc

	; Set entity length
	ld a, $02
	ldh [I], a

.entityloop

	ld a, [hli]
	ldh [EntityOrigin], a
	ldh [EntityX], a

	ld a, [hli]
	ldh [EntityY], a

	ld a, [hli]
	ldh [EntityArrayX], a
	ld d, a

	ld a, [hli]
	ldh [EntityArrayY], a
	ld e, a

.draw
	; Read tile
	ld a, [hli]
	ldh [EntityTile], a

	; Store the tile address
	ld b, h
	ld c, l

	; Retrieve OAM address
	pop hl

	; Load sprite
	ldh a, [EntityY]
	ld [hli], a

	ldh a, [EntityX]
	ld [hli], a

	ldh a, [EntityTile]
	ld [hli], a

	ld a, %00000000
	ld [hli], a

	; Push the OAM address onto the stack
	push hl

	; Retrieve the tile address
	ld h, b
	ld l, c

	; Increase X by 16
	ldh a, [EntityX]
	add $08
	ldh [EntityX], a

	; Decrement array width counter
	dec d
	ld a, d

	; Draw the next tile
	jr nz, .draw

	; Increase Y by 16
	ldh a, [EntityY]
	add $08
	ldh [EntityY], a

	; Reset array width counter
	ldh a, [EntityArrayX]
	ld d, a

	; Reset X position
	ldh a, [EntityOrigin]
	ldh [EntityX], a

	; Decrement array height counter
	dec e
	ld a, e

	; Draw the next row of tiles
	jr nz, .draw

	; Draw next entity
	ldh a, [I]
	dec a
	ldh [I], a
	jr nz, .entityloop

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

Entities:
	db $10 ; X
	db $20 ; Y
	db $02 ; Array X
	db $03 ; Array Y
	db $00, $02, $01, $03, $04, $06

	db $40 ; X
	db $60 ; Y
	db $02 ; Array X
	db $03 ; Array Y
	db $00, $02, $01, $03, $04, $06
EntitiesEnd: