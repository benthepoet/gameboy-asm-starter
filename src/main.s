INCLUDE "hardware.inc"

SECTION "VBlank IRQ", ROM0[$40]

VBlankIRQ:
	; Set VBlank flag
	ld a, $01
	ldh [hVBlankEnabled], a
    reti

SECTION "Header", ROM0[$100]

EntryPoint:
	di
	jp Start

REPT $150 - $104
	db 0
ENDR

SECTION "High RAM", HRAM

hVBlankEnabled: ds 1

hEntityX: ds 1
hEntityNext: ds 2
hEntityFlags: ds 1

hFrameX: ds 1
hFrameY: ds 1
hFrameWidth: ds 1
hFrameTile: ds 1

SECTION "Game Code", ROM0[$150]

Start:

.waitVBlank

	; Wait for VBlank start
	ld a, [rLY]
	cp 144
	jr c, .waitVBlank

	; Clear VBlank flag
	xor a
	ldh [hVBlankEnabled], a

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

	; Skip if not VBlank interrupt
	ldh a, [hVBlankEnabled]
	or a
	jr z, .loop

	call ReadJoypad
	call DrawEntities

	; Reset VBlank flag
	xor a
	ldh [hVBlankEnabled], a

	jr .loop

ReadJoypad:
	ret

DrawMetaMap:
    ld hl, MetaMap
    ld bc, MetaMapEnd - MetaMap

.loop
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, .loop

    ret

DrawEntities:
	; Load entities pointer
	ld hl, Entities

	; Push initial OAM poiner onto the stack
	ld bc, $fe00
	push bc

.entityloop

	ld a, [hli]
	ldh [hEntityX], a
	ldh [hFrameX], a

	ld a, [hli]
	ldh [hFrameY], a

	ld a, [hli]
	ldh [hEntityNext + 1], a

	ld a, [hli]
	ldh [hEntityNext], a

	; Load frame pointer
	ld a, [hli]
	ld c, a

	ld a, [hli]
	ld b, a

	; Read frame width
	ld a, [bc]
	inc bc
	ldh [hFrameWidth], a
	ld d, a

	; Read frame height
	ld a, [bc]
	inc bc
	ld e, a

	; Retrieve OAM pointer
	pop hl

.draw
	; Read tile and advance pointer
	ld a, [bc]
	inc bc
	ldh [hFrameTile], a

	; Write Sprite Y
	ldh a, [hFrameY]
	ld [hli], a

	; Write Sprite X
	ldh a, [hFrameX]
	ld [hli], a

	; Increase X by 8
	add $08
	ldh [hFrameX], a

	; Write Sprite Tile
	ldh a, [hFrameTile]
	ld [hli], a

	; Write Sprite Flags
	ld a, %00000000
	ld [hli], a

	; Decrement array width counter
	dec d
	ld a, d

	; Draw the next tile
	jr nz, .draw

	; Increase Y by 8
	ldh a, [hFrameY]
	add $08
	ldh [hFrameY], a

	; Reset array width counter
	ldh a, [hFrameWidth]
	ld d, a

	; Reset X position
	ldh a, [hEntityX]
	ldh [hFrameX], a

	; Decrement array height counter
	dec e
	ld a, e

	; Draw the next row of tiles
	jr nz, .draw

	; Push OAM pointer onto stack
	push hl ;

	; Read next entity pointer
	ldh a, [hEntityNext]
	ld h, a

	ldh a, [hEntityNext + 1]
	ld l, a

	; Loop if the next pointer isn't zero
	ld a, h
	or l
	jr nz, .entityloop

	; Clear the stack
	pop hl

	ret

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

MetaMap:
    db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
REPT $07
    db $01, $00, $00, $00, $00, $00, $00, $00, $00, $01
ENDR
    db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
MetaMapEnd:

SECTION "Frames", ROM0
PlayerIdle:
	db $02, $03 ; W, H
	db $00, $02, $01, $03, $04, $06

SECTION "Entities", ROM0

Entities:
Entity1:
	db $10 ; X
	db $20 ; Y
	dw Entity2 ; Next
	dw PlayerIdle ; Frame

Entity2:
	db $40 ; X
	db $60 ; Y
	dw $0000 ; Next
	dw PlayerIdle ; Frame
EntitiesEnd:
