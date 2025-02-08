Zelda II FamiTracker Patch
v0.1

By Justin Olbrantz (Quantam)

The z2ft patch adds FamiTracker Module playback support to Zelda II: The Adventure of Link (US), both making it far easier to compose and import custom music for hacks and providing a more powerful sound engine. This engine is added on top of the original sound engine and both FT format music and the original tracks may be used in a single hack. Additionally, z2ft switches the mapper to MMC5.

This conversion also contains a demo hack that may be played by non-romhackers who seek a change in soundscape from the original game.

Basic Features:
- Support for FamiTracker Modules as implemented by bhop (https://github.com/zeta0134/bhop)
	- Supports basic FT features including channel volume, instruments, volume/pitch/arpeggio/mode envelopes, true tempo, grooves, etc.
	- Supports effects 0 (arpeggio), 1/2 (pitch slide), 3 (portamento), 4 (vibrato), 7 (tremolo), A (volume slide), B (go to order), C (halt), D (go to row in next order), F (speed/tempo), G (note delay), L (delayed release), P (fine pitch), Q/R (pitch slide to note), S (delayed cut), V (mode)
	- Supports all base (2A03) channels excluding DPCM
	- Does NOT support other expansion chips, linear pitch mode, hi-pitch envelopes, or effects E (old-style volume), EE (toggle hardware envelope/length counter), E (length counter), H/I (hardware sweep), M (delayed volume), S (set linear counter), T (delayed transpose), Y (DPCM sample offset), Z (DPCM delta counter)
	- Support for saving the track states of the last 2 FT tracks played and will resume if the same track is played again, e.g. if the caves of Death Mountain all use the same track the current positions of the overworld and cave tracks will be maintained from cave to cave.
- Expanded capacity
	- Expands the PRG-ROM size to 256 KB, almost half of which is available for music and other hacks
	- Increases the maximum number of tracks from 17 to 127
- Additional features
	- Multi-bank support for FT music, allowing for up to 128 KB of music data and up to 8 KB per track
	- Supports unique tracks for all map locations and many enemy encounter conditions
	- Incorporates the z2mmc5 patch which converts the game to MMC5 and switches screen splitting to use the scanline IRQ to reduce CPU usage
	- MMC5 provides numerous powerful features to makers of derivative hacks
	- Incorporates z2lagpatch to reduce CPU usage. Between z2mmc5 and z2lagpatch, z2ft should be less laggy than vanilla Z2 even when playing FT music.

HOW IT WORKS

The basic principle of operation of z2ft is simple. z2ft runs both the original sound engine and bhop in parallel, mixing the output based on which engine is playing and which channels are currently in use by sound effects (which always use the native sound engine).

Under the hood, z2ft adds a second track table: the track map table. This table specifies 4 key pieces of information: what ROM bank the track is in and where, which track index within that module the track is, and which engine to use to play it. The details are not relevant to most users, so it won't be described further.

CAVEATS

- The most important caveat of z2ft is that it is an MMC5 ROM, which is not well supported by low-end hardware, primarily limiting hardware use to the Everdrive line.

- MMC5 sound and DPCM are not currently supported.

- The increase in PRG-ROM size results in the CHR-ROM being in a different location in the file. Some Z2 hacking tools may not be able to handle this. Additionally, at least 1 Z2 hacking tool (Z2Edit) is unable to handle it because the common bank remains in the same place, not moving to the end of PRG-ROM as would be required for non-MMC5 mappers.

- FT format fanfares (e.g. item acquired) and changing which track numbers are fanfares are not currently supported.

REQUIREMENTS

Zelda II - The Adventure of Link (USA):
ROM CRC32 BA322865 / MD5 88C0493FB1146834836C0FF4F3E06E45
File CRC32 E3C788B0 / MD5 764D36FA8A2450834DA5E8194281035A

The makeftrom utility (https://www.romhacking.net/utilities/1800/) is used to import music. Note that some of the z2ft files (in particular the .ftcfg files) are required by makeftrom to produce z2ft ROMs.

Additionally, while the easiest way to patch is to simply use the online patcher for the romhack site if available, offline patching can be done with a BPS patching utility such as beat, Floating IPS, and others.

PATCHING

z2ft contains two patches: z2ft.bps and z2ftdemo.bps, applied to the US Zelda II ROM. z2ft.bps produces z2ft.nes, which is the base that will be used for further hacking, including importing music via makeftrom. z2ftdemo.bps produces a playable demo that replaces many of the game's tracks with assorted different music; this demo 1. includes the changes from z2ft.bps, and 2. cannot be used for further hacking as makeftrom cannot be run on a file that already has imported music.

COMPATIBILITY

Care must be taken when combining z2ft with other, non-music changes.

Because MMC5 does not require the common bank (MMC1 bank 7) to be at the end of the ROM, the common bank remains in its original location.

z2mmc5, z2lagpatch, and z2ft use the following memory ranges that were previously free:
- 46-4c are used as NMI temporaries. It should be safe to use them for other NMI temporary purposes.
- 6c7-6c8
- 76a
- 7b2-7b3
- 66c0-695f
- 69e0-69ff

They use the following ROM ranges that were previously free:
- 2980-298f
- 1879c-18bcb
- 18c10-1900f
- 19e10-1a00f
- 1feba-1fedf
- 3e010-4000f is the FT code bank

As well, they free up the following ranges:
- 1ff80-1ffbf (40)
- 20010-3e00f (though makeftrom will by default use these banks for music)

Finally, they substantially modify the following ranges in a way that may break compatibility:
- 1d4c2-1d4dd
- 1f28f-1f2c3
- 1ffc1-2000f (though the addresses of the mapper functions in this range remain unchanged)

PRODUCING DERIVATIVE HACKS

z2ft is intended to be incorporated into other, larger hacks. For exact details see license.txt, but in general all that's required is a credit in your hack's readme or wherever else the hack's credits are displayed (e.g. if your hack modifies the game's credits sequence to include the hack's creators, include a z2ft credit as well).

Importing tracks is done through the aforementioned makeftrom utility, and is documented in the makeftrom manual. What is necessary is the Z2-specific list of track names that can be assigned using makeftrom:
Title
Overworld
Battle
ItemFanfare
Town
House
SkillFanfare
Palace
Boss
CrystalFanfare
GreatPalace
Ending
Credits
GameComplete
LastBoss

Additionally, tracks 12-7e are not used in Z2 but can be used for encounter tracks or any other purpose that may be hacked into the game. These tracks have generic names e.g. Track12 and Track7e.
		
Side-scrolling locations on the overworld may have unique tracks assigned to them via the now poorly named boss_track_map feature of makeftrom. Note that tracks are assigned on a per overworld location bases, NOT a per side-scrolling area basis. This is necessary because of how Z2 shares some side-scrolling areas between multiple unrelated overworld locations (e.g. how Bagu's Cabin and King's Tomb share locations with towns), but means that all sides of an area with multiple entrances need to have the same music assigned to them.

The list of overworld location names is as follows. In parentheses are the names as they appear on the included map from nesmaps.com. Many locations are invalid in Z2, as noted, but hacks may give them meaning. The "FourthArea" locations do not exist in Z2, but the Z2 Randomizer adds a 4th continent so as to separate Death Mountain and Maze Island into their own continents, whereas in Z2 they shared a continent.
NorthCastle ("North Castle")
TrophyCave ("Desert Cave")
WestArea02 ("Secret 1")
WestArea03 ("Cave 1")
WestArea04 ("Secret 5")
WestArea05 ("Secret 2")
WestArea06 ("Trap 6")
WestArea07 ("Trap 1")
WestArea08 ("Secret 4")
WestArea09 ("Secret 10")
WestArea0a ("Parapa Cave")
WestArea0b (invalid)
WestArea0c ("Northwestern Cave Entrance")
WestArea0d ("Northwestern Cave Exit")
WestArea0e ("Cave 2")
WestArea0f ("Cave 4")
WestArea10 ("Cave 3")
WestArea11 ("Island Palace Tunnel Entrance")
WestArea12 ("Island Palace Tunnel Exit")
WestArea13 ("Trap 2")
WestArea14 ("Trap 3")
WestArea15 ("Trap 9A")
WestArea16 ("Trap 9B")
WestArea17 ("Secret 3")
WestArea18 ("Secret 8")
WestArea19 ("Secret 6")
WestArea1a ("Trap 4")
WestArea1b ("Trap 5")
WestArea1c ("Trap 8")
WestArea1d ("Trap 7")
WestArea1e ("Secret 7")
WestArea1f (invalid)
WestArea20 ("Secret 9")
WestArea21 (invalid)
WestArea22 (invalid)
WestArea23 (invalid)
WestArea24 (invalid)
WestArea25 (invalid)
WestArea26 (invalid)
WestArea27 (invalid)
WestArea28 (invalid)
WestArea29 (invalid)
WestArea2a (invalid)
WestArea2b (invalid)
KingsTomb ("King's Tomb")
RauruTown ("Rauru Town")
WestArea2e (invalid)
RutoTown ("Ruto Town")
SariaTownSouth ("Saria Town South")
SariaTownNorth ("Saria Town North")
BagusHouse ("Bagu's Home")
MidoTown ("Mido Town")
Palace1 ("Parapa Palace")
Palace2 ("Midoro Palace")
Palace3 ("Island Palace")
WestArea37 (invalid)
WestArea38 (invalid)
WestArea39 (invalid)
WestArea3a (invalid)
WestArea3b (invalid)
WestArea3c (invalid)
WestArea3d (invalid)
WestArea3e (invalid)
WestArea3f (invalid)
DmArea00 ("DM 1B")
DmArea01 ("DM 1A")
DmArea02 ("DM 6A")
DmArea03 ("DM 6B")
DmArea04 ("DM 7A")
DmArea05 ("DM 7B")
DmArea06 ("DM 2A")
DmArea07 ("DM 2B")
DmArea08 ("DM 3B")
DmArea09 ("DM 3A")
DmArea0a ("DM 10A")
DmArea0b ("DM 10B")
DmArea0c ("DM 4A")
DmArea0d ("DM 4B")
DmArea0e ("DM 11A")
DmArea0f ("DM 11B")
DmArea10 ("DM 12A")
DmArea11 ("DM 12B")
DmArea12 ("DM 5B")
DmArea13 ("DM 5A")
DmArea14 ("DM 13B")
DmArea15 ("DM 13A")
DmArea16 ("DM 14A")
DmArea17 ("DM 14B")
DmArea18 ("DM 15B")
DmArea19 ("DM 15A")
DmArea1a ("DM 16A")
DmArea1b ("DM 16B")
HammerCave ("Spectacle Cave")
DmArea1d ("DM 9A")
DmArea1e ("DM 9B")
DmArea1f ("DM 9C")
DmArea20 ("DM 9D")
DmArea21 ("DM 8C")
DmArea22 ("DM 8D")
DmArea23 ("DM 8A")
DmArea24 ("DM 8B")
DmArea25 ("MI 3")
DmArea26 ("MI 2")
DmArea27 ("MI 4")
DmArea28 (invalid)
DmArea29 (invalid)
DmArea2a (invalid)
DmArea2b (invalid)
DmArea2c (invalid)
DmArea2d (invalid)
DmArea2e (invalid)
DmArea2f (invalid)
DmArea30 (invalid)
DmArea31 (invalid)
DmArea32 (invalid)
DmArea33 (invalid)
Palace4 ("Maze Palace")
DmArea35 (invalid)
DmArea36 (invalid)
ChildCave ("MI 1")
DmArea38 ("Spectacle Rock")
DmArea39 ("MI 5")
DmArea3a ("MI 9")
DmArea3b ("MI 6")
DmArea3c ("MI 7")
DmArea3d ("MI 8")
DmArea3e (invalid)
DmArea3f (invalid)
EastArea00 ("Secret 11")
EastArea01 ("Secret 18")
EastArea02 ("Trap 12")
EastArea03 ("Trap 13")
EastArea04 ("Trap 14")
EastArea05 ("Trap 17")
EastArea06 ("Trap 15")
EastArea07 ("Trap 16")
EastArea08 ("Trap 11")
EastArea09 ("Trap 10")
EastArea0a ("Secret 16")
EastArea0b ("Northeastern Cave Entrance")
EastArea0c ("Northeastern Cave Exit")
EastArea0d ("Cave 5")
EastArea0e ("Cave 6")
EastArea0f ("Kasuto Cave Entrance")
EastArea10 ("Kasuto Cave Exit")
EastArea11 ("Cave 8 Entrance")
EastArea12 ("Cave 8 Exit")
EastArea13 ("Cave 7 Exit")
EastArea14 ("Cave 7 Entrance")
EastArea15 ("Secret 17")
EastArea16 ("Secret 21")
EastArea17 ("Secret 13")
EastArea18 ("Secret 14")
EastArea19 ("Secret 15")
EastArea1a ("Secret 19")
EastArea1b ("Secret 12")
EastArea1c ("Secret 21")
EastArea1d ("Secret 20")
EastArea1e ("Trap 20")
EastArea1f ("Trap 19")
EastArea20 ("Trap 18")
EastArea21 (invalid)
EastArea22 (invalid)
EastArea23 (invalid)
EastArea24 (invalid)
EastArea25 (invalid)
EastArea26 (invalid)
EastArea27 (invalid)
EastArea28 (invalid)
EastArea29 (invalid)
EastArea2a (invalid)
EastArea2b (invalid)
EastArea2c (invalid)
NabooruTown ("Nabooru Town")
EastArea2e (invalid)
DaruniaTown ("Darunia Town")
EastArea30 (invalid)
NewKasutoTown ("Hidden Town of Kasuto")
EastArea32 (invalid)
OldKasutoTown ("Deserted Town of Kasuto")
Palace5 ("Palace on the Sea")
Palace6 ("Three-Eye Rock Palace")
GreatPalace ("Great Palace")
EastArea37 (invalid)
EastArea38 (invalid)
EastArea39 (invalid)
EastArea3a (invalid)
EastArea3b (invalid)
EastArea3c (invalid)
EastArea3d (invalid)
EastArea3e (invalid)
EastArea3f (invalid)
FourthArea00
FourthArea01
FourthArea02
FourthArea03
FourthArea04
FourthArea05
FourthArea06
FourthArea07
FourthArea08
FourthArea09
FourthArea0a
FourthArea0b
FourthArea0c
FourthArea0d
FourthArea0e
FourthArea0f
FourthArea10
FourthArea11
FourthArea12
FourthArea13
FourthArea14
FourthArea15
FourthArea16
FourthArea17
FourthArea18
FourthArea19
FourthArea1a
FourthArea1b
FourthArea1c
FourthArea1d
FourthArea1e
FourthArea1f
FourthArea20
FourthArea21
FourthArea22
FourthArea23
FourthArea24
FourthArea25
FourthArea26
FourthArea27
FourthArea28
FourthArea29
FourthArea2a
FourthArea2b
FourthArea2c
FourthArea2d
FourthArea2e
FourthArea2f
FourthArea30
FourthArea31
FourthArea32
FourthArea33
FourthArea34
FourthArea35
FourthArea36
FourthArea37
FourthArea38
FourthArea39
FourthArea3a
FourthArea3b
FourthArea3c
FourthArea3d
FourthArea3e
FourthArea3f

Finally, random overworld enemy encounters can have music assigned to them by several different categories of the form ["North"/"South"][Continent][Terrain]["Fairy"/"Small"/"Big"]:
Enemy encounters:
NorthWestDesertFairy
NorthWestDesertSmall
NorthWestDesertBig
NorthWestGrassFairy
NorthWestGrassSmall
NorthWestGrassBig
NorthWestForestFairy
NorthWestForestSmall
NorthWestForestBig
NorthWestSwampFairy
NorthWestSwampSmall
NorthWestSwampBig
NorthWestGraveFairy
NorthWestGraveSmall
NorthWestGraveBig
NorthWestRoadFairy
NorthWestRoadSmall
NorthWestRoadBig
NorthWestLavaFairy
NorthWestLavaSmall
NorthWestLavaBig
NorthWestMountFairy
NorthWestMountSmall
NorthWestMountBig
SouthWestDesertFairy
SouthWestDesertSmall
SouthWestDesertBig
SouthWestGrassFairy
SouthWestGrassSmall
SouthWestGrassBig
SouthWestForestFairy
SouthWestForestSmall
SouthWestForestBig
SouthWestSwampFairy
SouthWestSwampSmall
SouthWestSwampBig
SouthWestGraveFairy
SouthWestGraveSmall
SouthWestGraveBig
SouthWestRoadFairy
SouthWestRoadSmall
SouthWestRoadBig
SouthWestLavaFairy
SouthWestLavaSmall
SouthWestLavaBig
SouthWestMountFairy
SouthWestMountSmall
SouthWestMountBig
NorthDmDesertFairy
NorthDmDesertSmall
NorthDmDesertBig
NorthDmGrassFairy
NorthDmGrassSmall
NorthDmGrassBig
NorthDmForestFairy
NorthDmForestSmall
NorthDmForestBig
NorthDmSwampFairy
NorthDmSwampSmall
NorthDmSwampBig
NorthDmGraveFairy
NorthDmGraveSmall
NorthDmGraveBig
NorthDmRoadFairy
NorthDmRoadSmall
NorthDmRoadBig
NorthDmLavaFairy
NorthDmLavaSmall
NorthDmLavaBig
NorthDmMountFairy
NorthDmMountSmall
NorthDmMountBig
SouthDmDesertFairy
SouthDmDesertSmall
SouthDmDesertBig
SouthDmGrassFairy
SouthDmGrassSmall
SouthDmGrassBig
SouthDmForestFairy
SouthDmForestSmall
SouthDmForestBig
SouthDmSwampFairy
SouthDmSwampSmall
SouthDmSwampBig
SouthDmGraveFairy
SouthDmGraveSmall
SouthDmGraveBig
SouthDmRoadFairy
SouthDmRoadSmall
SouthDmRoadBig
SouthDmLavaFairy
SouthDmLavaSmall
SouthDmLavaBig
SouthDmMountFairy
SouthDmMountSmall
SouthDmMountBig
NorthEastDesertFairy
NorthEastDesertSmall
NorthEastDesertBig
NorthEastGrassFairy
NorthEastGrassSmall
NorthEastGrassBig
NorthEastForestFairy
NorthEastForestSmall
NorthEastForestBig
NorthEastSwampFairy
NorthEastSwampSmall
NorthEastSwampBig
NorthEastGraveFairy
NorthEastGraveSmall
NorthEastGraveBig
NorthEastRoadFairy
NorthEastRoadSmall
NorthEastRoadBig
NorthEastLavaFairy
NorthEastLavaSmall
NorthEastLavaBig
NorthEastMountFairy
NorthEastMountSmall
NorthEastMountBig
SouthEastDesertFairy
SouthEastDesertSmall
SouthEastDesertBig
SouthEastGrassFairy
SouthEastGrassSmall
SouthEastGrassBig
SouthEastForestFairy
SouthEastForestSmall
SouthEastForestBig
SouthEastSwampFairy
SouthEastSwampSmall
SouthEastSwampBig
SouthEastGraveFairy
SouthEastGraveSmall
SouthEastGraveBig
SouthEastRoadFairy
SouthEastRoadSmall
SouthEastRoadBig
SouthEastLavaFairy
SouthEastLavaSmall
SouthEastLavaBig
SouthEastMountFairy
SouthEastMountSmall
SouthEastMountBig
NorthFourthDesertFairy
NorthFourthDesertSmall
NorthFourthDesertBig
NorthFourthGrassFairy
NorthFourthGrassSmall
NorthFourthGrassBig
NorthFourthForestFairy
NorthFourthForestSmall
NorthFourthForestBig
NorthFourthSwampFairy
NorthFourthSwampSmall
NorthFourthSwampBig
NorthFourthGraveFairy
NorthFourthGraveSmall
NorthFourthGraveBig
NorthFourthRoadFairy
NorthFourthRoadSmall
NorthFourthRoadBig
NorthFourthLavaFairy
NorthFourthLavaSmall
NorthFourthLavaBig
NorthFourthMountFairy
NorthFourthMountSmall
NorthFourthMountBig
SouthFourthDesertFairy
SouthFourthDesertSmall
SouthFourthDesertBig
SouthFourthGrassFairy
SouthFourthGrassSmall
SouthFourthGrassBig
SouthFourthForestFairy
SouthFourthForestSmall
SouthFourthForestBig
SouthFourthSwampFairy
SouthFourthSwampSmall
SouthFourthSwampBig
SouthFourthGraveFairy
SouthFourthGraveSmall
SouthFourthGraveBig
SouthFourthRoadFairy
SouthFourthRoadSmall
SouthFourthRoadBig
SouthFourthLavaFairy
SouthFourthLavaSmall
SouthFourthLavaBig
SouthFourthMountFairy
SouthFourthMountSmall
SouthFourthMountBig

BUGS

- Bugs or incomplete features may exist in bhop. The most noticeable known issue is that bhop does not currently implement pitch effects (e.g. pitch slide) on the noise channel. This causes some drum sounds to sound incorrect, e.g. in some of the C2 tracks in mm4ftdemo.

CREDITS

Research, reverse-engineering, and programming: Justin Olbrantz (Quantam)
Music used by the demo: List to be written.

Thanks to the NesDev for the occasional piece of information or advice.

LINKS

z2ft GitHub Repository: https://github.com/TheRealQuantam/z2ft
makeftrom: https://archive.org/details/makeftrom
makeftrom Tutorial (also has discussions): https://github.com/TheRealQuantam/makeftromtutorial
NES FamiTracker Conversions Discord: https://discord.gg/cEtUnFgdVy