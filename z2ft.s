.include "build.inc"
.include "../z2mmc5/mmc5regs.inc"
.include "bhop.inc"

.feature c_comments
.feature org_per_seg

BANK_SIZE = $2000
NUM_PRG_BANKS = $20

SOUND_BANK = $c

NUM_TRACKS = $13
MAX_TRACKS = $80

TITLE_TRACK_IDX = 0
OVERWORLD_TRACK_IDX = 1
BATTLE_TRACK_IDX = 3
ITEM_FANFARE_TRACK_IDX = 4
TOWN_TRACK_IDX = 5
HOUSE_TRACK_IDX = 7
SKILL_FANFARE_TRACK_IDX = 8
PALACE_TRACK_IDX = 9
BOSS_TRACK_IDX = $b
CRYSTAL_FANFARE_TRACK_IDX = $c
GREAT_PALACE_TRACK_IDX = $d
ENDING_TRACK_IDX = $f
CREDITS_TRACK_IDX = $10
GAME_COMPLETE_TRACK_IDX = $11
DARK_LINK_TRACK_IDX = $12

TRACK_FLAG_FANFARE = 1 ; Do not save to previous track if preempted

MUSIC_CMDS_START = $80
BEGIN_OVERWORLD_CMD = $80
RESUME_OVERWORLD_CMD = $81
BEGIN_ENCOUNTER_CMD = $82
RESUME_ENCOUNTER_CMD = $83
STOP_MUSIC_CMD = $84 ; And above

.define NUM_BHOP_TEMPS 6

.define SRC_OFFS(bank, offs) ((BANK_SIZE * (bank)) + (offs) + $10)
.define SRC_BOFFS(bank) SRC_OFFS (bank), 0

.macro inc_bank_part bank_idx, offs, size
	.incbin SRC_ROM, SRC_OFFS bank_idx, offs, size
.endmacro

.macro inc_bank_range bank_idx, start_offs, end_offs
	.incbin SRC_ROM, SRC_OFFS (bank_idx), (start_offs), (end_offs) - (start_offs)
.endmacro

.macro inc_banks start_bank, end_bank, new_start_bank
	.ifnblank new_start_bank
	tgt_bank .set (new_start_bank)
	.else
	tgt_bank .set (start_bank)
	.endif

	.repeat (end_bank) - (start_bank), bank_idx
	.segment .sprintf("BANK%X", bank_idx + tgt_bank)
	;.out .sprintf("BANK%X", bank_idx + tgt_bank)
	.incbin SRC_ROM, SRC_BOFFS bank_idx + (start_bank), BANK_SIZE
	.endrepeat
.endmacro

.macro patch_segment name, size, start_addr, end_addr
	.segment .string(name)

	.import .ident(.sprintf("__%s_SIZE__", .string(name)))
	.assert .ident(.sprintf("__%s_SIZE__", .string(name))) <= (size), lderror, .sprintf("Segment '%s' exceeds size limit of $%x bytes", .string(name), (size))

	.ifnblank start_addr
	.import .ident(.sprintf("__%s_LOAD__", .string(name)))
	.assert .ident(.sprintf("__%s_LOAD__", .string(name))) = (start_addr), lderror, .sprintf("Segment '%s' was not loaded at the correct address %x", .string(name), (start_addr))
	.endif

	.ifnblank end_addr
	.assert (size) = (end_addr) + 1 - (start_addr), error, .sprintf("$%x + 1 - $%x != $%x", (end_addr), (start_addr), (size))
	.endif
.endmacro

.macro patch_call seg_name, target
	patch_segment seg_name, 3
		jsr target
.endmacro

PpuStatus_2002 := $2002

Sq0Duty_4000 := $4000
Sq0Sweep_4001 := $4001
Sq0Timer_4002 := $4002
Sq0Length_4003 := $4003
Sq1Duty_4004 := $4004
Sq1Sweep_4005 := $4005
Sq1Timer_4006 := $4006
Sq1Length_4007 := $4007
TriLinear_4008 := $4008
TriTimer_400A := $400a
TriLength_400B := $400b
NoiseVolume_400C := $400c
NoisePeriod_400E := $400e
NoiseLength_400F := $400f
DmcFreq_4010 := $4010
DmcCounter_4011 := $4011
DmcAddress_4012 := $4012
DmcLength_4013 := $4013
ApuStatus_4015 := $4015

Ctrl1_4016 := $4016

UpdateNativeTitleMusic := $826a
UpdateNativeSound := $9000
UpdateNativeMusic := $9b18
StopNativeTrack := $9b3b
StopTitleTrack := $82cf
UpdateGame := $c2ca
SwitchToBank0 := $ffc5

CurBank8 := $7b2
CurBankA := $7b3

WorldRegionDivYs := $cb32

CurWorldMap := $706
CurZone := $707
CurMapArea := $748
CurTerrain := $563
CurEnemyType := $75a
IsPaused := $ea
EncounterWorldY := $6a3e

TitleTrackToPlay := $ea
TrackToPlay := $eb
ComplexSfxToPlay := $ec
Square2SfxToPlay := $ee

CurNativeTitleTrack := $e8
CurNativeTrack := $7fb
CurTitleSquareSfx := $e9
CurSquare1Sfx := $7ff
CurSquare1Sfx2 := $7df
CurSquare2Sfx := $7fe
CurNoiseSfx := $7fd
CurNoiseSfx2 := $7e0

NO_FT_TRACK_TO_PLAY = $ff


.segment "ZEROPAGE": zeropage
	.org $4c - NUM_BHOP_TEMPS
BhopTemps: .res NUM_BHOP_TEMPS

	.org $4c
Temp: .byte 0

	.org $dc
; Only valid during the title screen
TitleMusicPhase: .byte 0
TitleMusicPhaseFlag: .byte 0
TitlePhaseFramesLeft: .word 0


.segment "VARS"
	.org $76a
IsInit: .byte 0


.segment "HIVARS"
TrackIdxToPlay: .byte 0 ; 0 if none, $80 to stop music

PrevSfxChans: .byte 0 ; MSB indicates that FT track is resuming after being paused
CurSfxChans: .byte 0

; $80 if none
CurTrack: .byte 0
PrevTrack: .byte 0 ; Restored after fanfares
PrevFtTrack: .byte 0 ; Can be paused and resumed if no new FT track plays

PlayingFt: .byte 0
FtEngineBank: .byte 0
CurFtBank: .byte 0

TrackZone: .byte 0
FtTrackToPlay: .byte 0 ; $80 if none
FtBankToPlay: .byte 0
FtAddrToPlay: .word 0

RealCurMapArea: .byte 0

SavedBhopTemps: .res NUM_BHOP_TEMPS

END_HIVARS:


.macro save_bhop_temps
	.repeat NUM_BHOP_TEMPS, i
		lda BhopTemps + i
		sta SavedBhopTemps + i
	.endrepeat
.endmacro

.macro restore_bhop_temps
	.repeat NUM_BHOP_TEMPS, i
		lda SavedBhopTemps + i
		sta BhopTemps + i
	.endrepeat
.endmacro


.segment "HDR"
.incbin SRC_ROM, 0, $10

inc_banks 0, $c
inc_banks $e, $1f

.repeat $40, i
	.segment .sprintf("CHRBANK%X", i)
	.incbin SRC_ROM, (NUM_PRG_BANKS * BANK_SIZE + i * $800 + $10), $800
.endrepeat

patch_call PATCH_CALL_UPDATE_TITLE_MUSIC, UpdateTitleMusic
patch_call PATCH_CALL_UPDATE_GAME_MUSIC, UpdateGameMusic

patch_call PATCH_CALL_SAVE_REAL_MAP_AREA1, SaveRealMapArea	
patch_call PATCH_CALL_SAVE_REAL_MAP_AREA2, SaveRealMapArea2

patch_segment PATCH_SAVE_REAL_MAP_AREA, $10, $a970, $a97f
.proc SaveRealMapArea
	stx CurMapArea
	stx RealCurMapArea
	rts
.endproc ; SaveRealMapArea

.proc SaveRealMapArea2
	sta CurMapArea
	sta RealCurMapArea
	rts
.endproc ; SaveRealMapArea

patch_segment PATCH_HANDLE_NATIVE_TRACK_END, $12, $9b4f, $9b60
.scope
	and #$1
	jsr HandleEndOfTrack
	
	jmp @Continue
	
	.res $a
	
@Continue:
.endscope

.ifndef RANDOMIZER

patch_segment PATCH_CALL_UPDATE_SOUND, 3, $c12f
	; Defer updating sound till after setting up the screen split
	jsr SwitchToBank0
	
patch_call PATCH_NEW_CALL_UPDATE_SOUND, CallUpdateSound

patch_segment PATCH_CALL_UPDATE_SOUND_JUMP_STUB, $23, $d3a7, $d3c9
.proc CallUpdateSound
	; $21 bytes
	lda #(SOUND_BANK | PRG_BANK_ROM)
	sta PrgBank8Reg
	ora #$1
	sta PrgBankAReg
	
	jsr UpdateSound
	
	lda CurBank8
	sta PrgBank8Reg
	lda CurBankA
	sta PrgBankAReg
	
	lda PpuStatus_2002
	
	rts
.endproc ; CallUpdateSound

	.res 6

.endif ; !defined(RANDOMIZER)
	
patch_segment PATCH_READ_ZONE1, 3, $9b24
	lda TrackZone
	
patch_segment PATCH_READ_ZONE2, 3, $9b80
	lda TrackZone
	
patch_segment PATCH_READ_TITLE_PHASE1, 2, $a787
	lda TitleMusicPhaseFlag
	
patch_segment PATCH_READ_TITLE_PHASE2, 2, $a778
	lda TitleMusicPhaseFlag
	
patch_segment PATCH_SET_OLD_KASUTO_TRACK, 3, $cf1b
	lda #$1
	
	
patch_segment PATCH_RESTART_LAST_BOSS_TRACK, 9, $988e, $9896
	lda CurTrack
	bpl :+
	
	lda #$40
	sta $eb
	
:
	
	
.segment "BANKC_LOW"
	inc_bank_part SOUND_BANK, 0, $78c
	
	; $874 bytes available
	
UpdateSound:
	jmp UpdateSoundBody
	
; Need to replace the original so that music-stopping SFX can be captured before they're processed
.proc UpdateSoundBody
	lda TrackToPlay
	bne @CallUpdate
	
	lda ComplexSfxToPlay
	and #$1 ; Death
	ora Square2SfxToPlay
	and #$7 ; Death, falling, entering/exiting enemy encounter, 
	beq @CallUpdate
	
	ldx #$0
	stx PlayingFt ; Soft stop play
	dex
	stx CurTrack
	stx PrevTrack
	
@CallUpdate:
	jmp UpdateNativeSound
	
.endproc ; UpdateSoundBody

.proc UpdateTitleMusic
	lda IsInit
	bne @AlreadyInit
	
@Initialize:
	sta PlayingFt

	sta TrackIdxToPlay
	sta PrevSfxChans
	sta CurSfxChans
	;sta CurFtBank
	sta global_attenuation
	
	sta TitleMusicPhase
	sta TitleMusicPhaseFlag
	
	lda #NO_FT_TRACK_TO_PLAY
	sta CurTrack
	sta PrevTrack
	sta PrevFtTrack
	sta FtTrackToPlay
	
	sta IsInit
	
@AlreadyInit:
	lda TitleTrackToPlay
	beq @NoTrackToPlay
	
	pha

	; Always stop the previous track before starting a new one
	lda #$0
	sta PlayingFt
	sta TitleTrackToPlay
	sta TitleMusicPhase
	sta TitleMusicPhaseFlag

	lda #$80
	sta CurTrack
	sta PrevTrack

	jsr StopTitleTrack
	
	pla
	
	lsr a
	bcc @NoTrackToPlay
	
@BeginTrack:
	lda #(TITLE_TRACK_IDX + 1)
	jsr BeginTrack
	sta TitleTrackToPlay
	
	lda #$1
	sta TitleMusicPhase
	sta TitleMusicPhaseFlag
	
	asl a
	tax
	lda @FramesPerTitleSegment - 2, x
	sta TitlePhaseFramesLeft
	lda @FramesPerTitleSegment - 1, x
	sta TitlePhaseFramesLeft + 1
	
	bpl @TitlePhaseDone
	
@NoTrackToPlay:
	lda TitleMusicPhase
	beq @TitlePhaseDone
	
	lda TitlePhaseFramesLeft
	sec
	sbc #$1
	sta TitlePhaseFramesLeft
	bcs @TitlePhaseDone
	
	dec TitlePhaseFramesLeft + 1
	bpl @TitlePhaseDone
	
	asl TitleMusicPhaseFlag
	inc TitleMusicPhase
	
	lda TitleMusicPhase
	cmp #$6
	bcc @NoLoop
	
	lda #$2
	sta TitleMusicPhase
	sta TitleMusicPhaseFlag
	
@NoLoop:
	asl a
	tax
	lda @FramesPerTitleSegment - 2, x
	sta TitlePhaseFramesLeft
	lda @FramesPerTitleSegment - 1, x
	sta TitlePhaseFramesLeft + 1
	
@TitlePhaseDone:
	lda PlayingFt
	bne @PlayingFt
	
	jsr UpdateNativeTitleMusic
	
	rts
	
@PlayingFt:
	lda #$0
	ldx CurTitleSquareSfx
	beq @NoSfx
	
	lda #$3
	
@NoSfx:
	sta CurSfxChans
	
	jsr CallUpdateFtMusic
	
	rts
	
@FramesPerTitleSegment:
	.word $1ff - 1, $3fe - 1, $1ff - 1, $3fe - 1, $3fe - 1
.endproc ; UpdateTitleMusic

.proc UpdateGameMusic
	; NMI does NOT save X and Y for you
	txa
	pha
	tya
	pha
	
@CheckForTrack:
	lda TrackToPlay
	beq @CheckForTrackIdx
	
	jsr DecodeTrackIdx
	sta TrackIdxToPlay
	
@CheckForTrackIdx:
	lda TrackIdxToPlay
	beq @UpdateMusic
	
@RecheckIdxToPlay:
	pha

	lda #$0
	sta PlayingFt
	sta TrackToPlay
	sta TrackIdxToPlay
	
	jsr StopNativeTrack
	
	pla
	
@BeginTrack:
	jsr BeginTrack
	sta TrackToPlay
	
@UpdateMusic:
	lda PlayingFt
	bne @UpdateFt
	
@PlayingNative:
	jsr UpdateNativeMusic

	jmp @AfterUpdate
	
@UpdateFt:
	; Update the channel mask
	lda IsPaused
	beq @NotPaused
	
	lda #$ff
	sta CurSfxChans
	
	bne @CallUpdate
	
@NotPaused:
	lda #$0
	sta CurSfxChans
	
	lda CurNoiseSfx
	ora CurNoiseSfx2
	cmp #$1
	rol CurSfxChans

	lda CurNoiseSfx
	and #$a
	cmp #$1
	rol CurSfxChans
	
	lda CurSquare2Sfx
	cmp #$1
	rol CurSfxChans
	
	lda CurSquare1Sfx
	ora CurSquare1Sfx2
	cmp #$1
	rol CurSfxChans

@CallUpdate:
	jsr CallUpdateFtMusic
	
@AfterUpdate:
	lda TrackIdxToPlay
	bne @RecheckIdxToPlay
	
	pla
	tay
	pla
	tax
	
	rts
.endproc ; UpdateGameMusic

.proc DecodeTrackIdx
	beq @Done
	
	pha
	
	and #$f
	beq @CheckHighNibble
	
@CheckLowNibble:
	pla 
	
	tax
	lda @MaskToIdxTbl, x
	
	bpl @HaveIdx
	
@CheckHighNibble:
	pla
	
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda @MaskToIdxTbl, x
	
	clc
	adc #$4
	
@HaveIdx:
	sta Temp
	
	lda CurZone ;;; IS THIS SAFE OR DOES IT NEED TO BE SET IN INTRO??
	asl a
	asl a
	asl a
	ora Temp
	tax
	lda GameTrackIdxMap, x
	bmi @Done
	
@NormalTrack:
	clc
	adc #$1
	
@Done:
	rts
	
; Index of lowest bit set in a nibble or $ff if none
@MaskToIdxTbl: .byt $ff, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
.endproc ; DecodeTrackIdx

.proc BeginTrack
	cmp #$0
	beq @Done
	bpl @IsTrack
	
	jmp @IsCommand
	
@IsTrack:
	sec
	sbc #$1
	
@IsTrack0:
	cmp PrevFtTrack
	beq @RestoreFtTrack
	
	asl a
	tax
	
	ldy TrackMap + 1, x
	bmi @StopMusic
	
	pha
	
	ldx CurTrack
	bmi @NoSaveCurTrack
	
	lda TrackFlags, x
	and #TRACK_FLAG_FANFARE
	bne @NoSaveCurTrack
	
@SaveCurTrack:
	stx PrevTrack
	
@NoSaveCurTrack:
	pla
	tax
	
	lsr a
	sta CurTrack

@BeginTrack:
	lda TrackMap, x
	bmi @IsFtTrack
	
@IsNativeTrack:
	lda RevTrackZoneMap, y
	sta TrackZone
	
	lda RevTrackFlagMap, y
	bpl @Done
	
	bmi @Return0
	
@IsFtTrack:
	eor #$ff
	ora #PRG_BANK_ROM
	sta FtBankToPlay
	sty FtTrackToPlay
	
	lda #(<.bank(UpdateFtMusic) | PRG_BANK_ROM)
	sta FtEngineBank
	
	lda TrackAddrMap, x
	sta FtAddrToPlay
	lda TrackAddrMap + 1, x
	sta FtAddrToPlay + 1
	
	sta PlayingFt
	
@Return0:
	lda #$0
	
@Done:
	rts
	
@RestoreFtTrack:
	sta CurTrack
	
	lda #NO_FT_TRACK_TO_PLAY
	; sta PrevFtTrack
	sta PrevTrack ;;; TODO: Support FT fanfares?
	
	lda #$8f
	sta PrevSfxChans
	sta PlayingFt
	
	bne @Return0
	
@IsCommand:
	cmp #STOP_MUSIC_CMD
	bcs @StopMusic
	
	jsr GetEncounterTrack
	bmi @Return0
	
	jmp @IsTrack0
	
@StopMusic:
	lda #NO_FT_TRACK_TO_PLAY
	sta CurTrack
	sta PrevTrack
	
	bmi @Return0
.endproc ; BeginTrack

.proc GetEncounterTrack
	pha
	
	cmp #BEGIN_ENCOUNTER_CMD
	bcs @BeginEncounter

@BeginOverworld:
	lda #OVERWORLD_TRACK_IDX
	bne @EncounterCommon
	
@BeginEncounter:
	; If it's a fixed encounter use RealCurMapArea, else it's an enemy encounter
	lda CurMapArea
	cmp #$3e
	bne @FixedEncounter
	
@EnemyEncounter:
	ldx CurWorldMap
	lda EncounterWorldY
	cmp WorldRegionDivYs, x

	lda CurWorldMap
	rol a
	asl a
	asl a
	asl a
	sta Temp
	
	lda CurTerrain
	sec
	sbc #$4
	and #$7
	ora Temp
	sta Temp

	asl a
	clc
	adc Temp
	adc CurEnemyType

	tax
	lda EnemyTrackMap, x

	jmp @EncounterCommon
	
@FixedEncounter:
	lda RealCurMapArea
	sta Temp
	
	lda CurWorldMap
	and #$3
	lsr a
	ror a
	ror a
	ora Temp
	tax
	
	lda EncounterTrackMap, x

@EncounterCommon:
	tay ; Target track
	
	pla ; Command
	
	lsr a ; Resume flag into carry
	bcc @RestartTrack
	
@CheckNativeForResume:
	tya
	asl a
	tax
	
	lda TrackMap, x
	bmi @RestartTrack
	
@IsNativeForResume:
	lda @ResumeTrackIdcs, y
	
	rts
	
@RestartTrack:
	tya
	
	rts
	
; Resume track indices for the given Index
@ResumeTrackIdcs:
	.byte 0, 2, 2, 3, 4, 6, 6, 7
	.byte 8, $a, $a, $b, $c, $e, $e, $f
	.byte $10, $11, $12
.endproc ; GetEncounterTrack

.proc HandleEndOfTrack
	; A is current track & 1
	beq @NotIntroTrack
	
@IsIntroTrack:
	; Advance to loop track
	;;; TODO: Use track flags?
	lda CurTrack
	clc
	adc #$1
	sta CurTrack
	
	lda #$2
	sta CurNativeTrack
	
@Done:
	rts
	
@NotIntroTrack:
	lda CurNativeTrack ;;; TODO: Use TrackFlags
	and #%01001110
	bne @Done

@IsEndOfTrack:	
	lda CurTrack

	; Ensure the finished track isn't copied to PrevTrack by BeginTrack
	ldx #NO_FT_TRACK_TO_PLAY
	stx CurTrack
	
	;;; TODO: Use TrackFlags
	cmp #ITEM_FANFARE_TRACK_IDX
	beq @RestorePrev
	cmp #SKILL_FANFARE_TRACK_IDX
	beq @RestorePrev
	
@StopMusic:
	ldx #NO_FT_TRACK_TO_PLAY
	bmi @Common
	
@RestorePrev:
	;;; Should TrackIdxToPlay be set to $ff or 0 if no prev track??
	ldx PrevTrack
	bmi @Common
	
	inx
	
@Common:
	stx TrackIdxToPlay
	lda #$0
	
	rts
.endproc ; HandleEndOfTrack

; Maps from zone:track indices to global track indices/commands
GameTrackIdxMap: 
	; Overworld
	.byte BEGIN_OVERWORLD_CMD ; 1
	.byte RESUME_OVERWORLD_CMD ; 2
	.res 2, BEGIN_ENCOUNTER_CMD ; 4
	.byte ITEM_FANFARE_TRACK_IDX ; 10
	.res 3, STOP_MUSIC_CMD ; 20
	
.repeat 2
	; Town
	.byte BEGIN_ENCOUNTER_CMD ; 1
	.res 2, RESUME_ENCOUNTER_CMD ; 2
	.byte HOUSE_TRACK_IDX ; 8
	.byte SKILL_FANFARE_TRACK_IDX ; 10
	.res 3, STOP_MUSIC_CMD ; 20
.endrepeat

.repeat 2
	; Palace
	.byte BEGIN_ENCOUNTER_CMD ; 1
	.res 2, RESUME_ENCOUNTER_CMD ; 2
	.byte BOSS_TRACK_IDX ; 8
	.byte ITEM_FANFARE_TRACK_IDX ; 10
	.byte STOP_MUSIC_CMD ; 20
	.byte CRYSTAL_FANFARE_TRACK_IDX ; 40
	.byte STOP_MUSIC_CMD ; 80
.endrepeat

.repeat 2
	; Great Palace and ending
	.byte BEGIN_ENCOUNTER_CMD ; 1
	.byte RESUME_ENCOUNTER_CMD ; 2
	.byte ENDING_TRACK_IDX ; 4
	.byte CREDITS_TRACK_IDX ; 8
	.byte ITEM_FANFARE_TRACK_IDX ; 10
	.byte GAME_COMPLETE_TRACK_IDX ; 20
	.byte DARK_LINK_TRACK_IDX ; 40
	.byte STOP_MUSIC_CMD ; 80
.endrepeat
	
; Maps from global to zone track indices
RevTrackFlagMap:
	.byt 1, 1, 2, 4, $10, 1, 2, 8
	.byt $10, 1, 2, 8, $40, 1, 2, 4
	.byt 8, $20, $40
	
; Maps from global track indices to zones
RevTrackZoneMap:
	.byt 0, 0, 0, 0, 0, 1, 1, 1
	.byt 1, 3, 3, 3, 3, 5, 5, 5
	.byt 5, 5, 5
	
TrackFlags:
	.res 4, 0
	.byte TRACK_FLAG_FANFARE ; 4 (item fanfare)
	.res 3, 0
	.byte TRACK_FLAG_FANFARE ; 8 (skill fanfare)
	.res 2, 0
	.byte TRACK_FLAG_FANFARE ; b (boss)
	.byte TRACK_FLAG_FANFARE ; c (crystal fanfare)
	.res 4, 0
	.byte TRACK_FLAG_FANFARE ; 11 (game complete fanfare)
	.byte TRACK_FLAG_FANFARE ; 12 (Dark Link)
	.res MAX_TRACKS - $13, 0

BANKC_LOW_FREE_SPACE:


.segment "ENEMY_TRACK_TABLES"
EncounterTrackMap:
	; West Hyrule
	.byte OVERWORLD_TRACK_IDX ; 0: North Palace
	.res $2b, BATTLE_TRACK_IDX
	.res 8, TOWN_TRACK_IDX ; (2c)2d, (2e)2f, 30/31, (32?)33: Towns
	.res 3, PALACE_TRACK_IDX ; 34, 35, 36: Palaces
	.res 9, BATTLE_TRACK_IDX
	
	; Death Mountain / Maze Island
	.res $34, BATTLE_TRACK_IDX
	.byte PALACE_TRACK_IDX ; 34: Palace 4
	.res $b, BATTLE_TRACK_IDX
	
	; East Hyrule
	.res $2c, BATTLE_TRACK_IDX
	.res 6, TOWN_TRACK_IDX ; (2c?)2d, (2e)2f, (30?)31: Towns
	.res 2, HOUSE_TRACK_IDX ; Old Kasuto (32/33) has house music
	.res 2, PALACE_TRACK_IDX ; 34, 35: Palaces
	.byte GREAT_PALACE_TRACK_IDX ; 36: Great Palace
	.res 9, BATTLE_TRACK_IDX
	
	; Fourth map
	.res $40, BATTLE_TRACK_IDX
	
EnemyTrackMap:
	; Index format: mmBttt * 3 + E
	; m: Overworld map (706)
	; B: Bottom of map below dividing line (6a3e >= cb32[706])
	; t: Terrain type - 4
	; E: Enemy type (75a, 0-2)
	.res $c0, BATTLE_TRACK_IDX
	
BossTrackMap:
	; Main bosses
	.res 6, BOSS_TRACK_IDX
	.byte DARK_LINK_TRACK_IDX
	
	; Not yet used
	.res $39, BOSS_TRACK_IDX
	
ENEMY_TRACK_TABLES_FREE_SPACE:


.segment "BANKC_HIGH"	
	inc_bank_part SOUND_BANK, $1000, $da8
	
	; $258 bytes available
	.res $58, $ff
	
TrackMap:
.repeat NUM_TRACKS, i
	.byt 0, i
.endrepeat

	.res (MAX_TRACKS - NUM_TRACKS) * 2, $ff

TrackAddrMap: 
.repeat MAX_TRACKS
	.word $a000
.endrepeat

BANK_C_HIGH_FREE_SPACE:


.segment "BANKD"
	inc_bank_part (SOUND_BANK + 1), 0, $c09
	
	; $13f7 bytes available
	
	; This MUST be in bank $d as it's a trampoline from c -> c
.proc CallUpdateFtMusic
	; $f / $15 bytes
	; FT track is playing
	lda FtEngineBank
.ifdef RANDOMIZER
	sta CurBank8
.endif
	sta PrgBank8Reg

	jsr UpdateFtMusic
	
	lda #(SOUND_BANK | PRG_BANK_ROM)
.ifdef RANDOMIZER
	sta CurBank8
.endif
	sta PrgBank8Reg
	
	rts
.endproc ; CallUpdateFtMusic

BANKD_FREE_SPACE:


.segment "BANK1F"
.proc UpdateFtMusic
	; FT track is playing
	
	save_bhop_temps
	
	; If there's a track to play, play it
	lda FtTrackToPlay
	bmi @NoTrackToPlay
	
@BeginTrack:
	ldx CurTrack
	stx PrevFtTrack
	
	ldx FtBankToPlay
	stx CurFtBank
.ifdef RANDOMIZER
	stx CurBankA
.endif
	stx PrgBankAReg
	
	ldx FtAddrToPlay
	ldy FtAddrToPlay + 1
	jsr bhop_init
	
	lda #NO_FT_TRACK_TO_PLAY
	sta FtTrackToPlay
	
@NoTrackToPlay:
	lda CurFtBank
.ifdef RANDOMIZER
	sta CurBankA
.endif
	sta PrgBankAReg
	
	lda PrevSfxChans
	bpl @NoResumeFt
	
	; PrevSfxChans must be $8f
	jsr bhop_mute_channels
	
@NoResumeFt:
	lda CurSfxChans
	cmp PrevSfxChans
	beq @DoneWithMutes
	
	eor #$f
	and PrevSfxChans
	beq @NoUnmutes
	
	; To prevent things like length counter effects, stop all unmuting channels
	pha
	
	eor #$f
	sta ApuStatus_4015
	lda #$f
	sta ApuStatus_4015

	pla
	
	jsr bhop_unmute_channels
	
@NoUnmutes:
	lda PrevSfxChans
	eor #$ff
	and CurSfxChans
	beq @DoneWithMutes
	
	jsr bhop_mute_channels
	
@DoneWithMutes:
	lda CurSfxChans
	sta PrevSfxChans
	
	bmi @IsPaused
	
	jsr bhop_play
	
@IsPaused:
	restore_bhop_temps
	
	lda #((SOUND_BANK + 1) | PRG_BANK_ROM)
.ifdef RANDOMIZER
	sta CurBankA
.endif
	sta PrgBankAReg
	
	rts
.endproc ; UpdateFtMusic


.segment "BANK1F_CODA"
	.incbin SRC_ROM, SRC_OFFS($1f, $1f00), $100
