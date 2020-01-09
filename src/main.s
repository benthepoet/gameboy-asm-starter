INCLUDE "hardware.inc"

SECTION "Working RAM", WRAM0

FrameCount:
	ds 1

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
    ld de, FontTiles
    ld bc, FontTilesEnd - FontTiles
    ld hl, $8000

	call MemCopy

    ld de, FontTiles
    ld bc, FontTilesEnd - FontTiles
    ld hl, $8800

    call MemCopy

    ; Load map
    ld hl, $9800
    ld b, (FontTilesEnd - FontTiles) / 16
    ld c, $80

.copyNumber
    ld a, c
    ld [hli], a
    inc c
    dec b
    ld a, b
    jr nz, .copyNumber

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

	ld hl, FrameCount
	ld a, 0
;	ld [hl], a

    ei
    nop

.loop
    halt
    nop

	ld hl, $FE00
	inc [hl]

	inc hl
	inc [hl]

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

SECTION "Font", ROM0

FontTiles:
INCBIN "font.bin"
FontTilesEnd:

