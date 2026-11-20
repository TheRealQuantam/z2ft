.macpack common

.segment "BHOP_ZEROPAGE" :mem $0046 :size $0006 :bss :fill
.segment "BHOP_RAM" :mem $6800 :size $011d :bss :define
.segment "BHOP_PRG" :bank $1f :mem $8000 :size $1800 :off $3e010

.segment "ZEROPAGE" :mem $0000 :size $0100 :bss :fill
.segment "VARS" :mem $0100 :size $0700 :bss :fill
.segment "HIVARS" :mem $69e0 :size $0017 :bss :fill
.segment "FT_SAVE_BUFFER" :mem $66c0 :size $0140 :bss :fill

.segment "BANKC_LOW" :bank $0c :mem $878c :size $0442 :off $1879c
.segment "ENEMY_TRACK_TABLES" :bank $0c :mem $8c00 :size $0200 :off $18c10
.segment "BANKC_HIGH" :bank $0c :mem $9e00 :size $0200 :off $19e10
.segment "BANKD" :bank $0d :mem $ac09 :size $0015 :off $1ac19
.segment "BANK1F" :bank $1f :mem $8000 :size $00b1 :off $3e010

.segment "PATCH_CALL_UPDATE_TITLE_MUSIC" :bank $0c :mem $800d :size $0003 :off $1801d :define
.segment "PATCH_CALL_UPDATE_GAME_MUSIC" :bank $0c :mem $901f :size $0003 :off $1902f :define
.segment "PATCH_CHECK_NOISE_SFX" :bank $0c :mem $95db :size $000b :off $195eb :define
.segment "PATCH_READ_ZONE1" :bank $0c :mem $9b24 :size $0003 :off $19b34 :define
.segment "PATCH_READ_ZONE2" :bank $0c :mem $9b80 :size $0003 :off $19b90 :define
.segment "PATCH_HANDLE_NATIVE_TRACK_END" :bank $0c :mem $9b4f :size $0012 :off $19b5f :define
.segment "PATCH_SET_OLD_KASUTO_TRACK" :bank $0e :mem $cf1b :size $0002 :off $1cf2b :define
.segment "PATCH_READ_TITLE_PHASE1" :bank $0b :mem $a787 :size $0002 :off $16797 :define
.segment "PATCH_READ_TITLE_PHASE2" :bank $0b :mem $a778 :size $0002 :off $16788 :define
.segment "PATCH_RESTART_LAST_BOSS_TRACK" :bank $0a :mem $988e :size $0009 :off $1589e :define
.segment "PATCH_OW_LAG_REDUCTION_1" :bank $0f :mem $e001 :size $0003 :off $1e011 :define
.segment "PATCH_SS_LAG_REDUCTION_1" :bank $0f :mem $f27f :size $002f :off $1f28f :define
.segment "PATCH_SS_LAG_REDUCTION_2" :bank $0f :mem $feaa :size $0023 :off $1feba :define
.segment "PATCH_SS_LAG_REDUCTION_3" :bank $0f :mem $ffdc :size $000c :off $1ffec :define
FREE "BHOP_RAM" [$6800, $691d)
FREE "BHOP_PRG" [$80b1, $9800)
