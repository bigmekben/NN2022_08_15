 ; base code taken from Nerdy Nights Week 3: https://nerdy-nights.nes.science/scraper/files/background.zip

 .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  
; as of following along to the beginning of Week 5 "multiple sprites...controllers..."

;;;;;;;;;;;;;;;

    
  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


setupPalettes:
; Per Nerdy Nights, "the palettes start at PPU address $3F00 and $3F10."
  LDA $2002
  LDA #$3F
  STA $2006
  LDA #$10
  STA $2006
;write4PaletteColors:
;; using the default colors from default YY-CHR.NET instead of values in Nerdy Nights
;  LDA #$0C
;  STA $2007
;  LDA #$14
;  STA $2007
;  LDA #$23
;  STA $2007
;  LDA #$37
;  STA $2007
  LDX #$00
LoadPalettesLoop:
  LDA PaletteData, x
  STA $2007
  INX
  CPX #$20
  BNE LoadPalettesLoop
  
  LDX #$00
PrepareSpritesLoop:
  LDA SpriteData, x
  STA $0200, x
  INX
  CPX #$10
  BNE PrepareSpritesLoop
  ; next thing to think of is, how to write to the y and x bytes for each
  ; sprite during the NMI?
  ; simplest way is probably:
  ; 1. NMI assumes the sprite coords are correct, 
  ;		in the sprite table that begins at $0200.
  ; 2. Physics and input routines work together to update the y and x coords
  ;		of the sprite.  It stores the (x, y) in main RAM, not in the sprite table; 
  ;	3. After reading input and calculating physics, from that single set of 
  ;		(x, y) in RAM, updates 8 byte locations sprite table that begins at $0200. 
  
  LDA #%10000000
  STA $2000
  LDA #%00010000
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop
  
PaletteData:
; (values copied from default new file in YY-CHR, not from Nerdy Nights code listing)
; BACKGROUND
  .db $0C, $14, $23, $37,   $0F, $1C, $2B, $39,  $0F, $06, $15, $36,  $0F, $13, $23, $33
; SPRITES
  .db $0F, $1C, $15, $14,   $0F, $02, $38, $3C,  $0F, $1C, $15, $14,  $0F, $02, $38, $3C

SpriteData:
; top left of ball
  .db $80, $04, $03, $80
; top right of ball
  .db $80, $05, $03, $88
; bottom left of ball
  .db $88, $14, $03, $80
; bottom right of ball
  .db $88, $15, $03, $88


NMI:
  LDA #$00
  STA $2003
  LDA #$02
  STA $4014
  RTI
 
;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "NewFile.chr"   ;includes 8KB graphics file from SMB1