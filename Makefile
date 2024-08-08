.PHONY: all clean dir run

BUILD_BASE_ROM := $(BASE_ROM)

SRCDIR := $(CURDIR)
STEM := $(notdir $(CURDIR))
BHOPDIR := bhop
BUILDDIR := build\$(GAME_PRE)
CFG_NAME := $(STEM).cfg
ROM_NAME := $(GAME_PRE)ft.nes
DBG_NAME := $(GAME_PRE)ft.dbg
IPS_NAME := $(GAME_PRE)ft.ips
BPS_NAME := $(GAME_PRE)ft.bps

# Assembler files, for building out the banks
ROOT_ASM_FILES := $(wildcard $(SRCDIR)/*.s)
BHOP_ASM_FILES := $(BHOPDIR)/bhop.s
O_FILES := \
  $(patsubst $(SRCDIR)/%.s,$(BUILDDIR)/%.o,$(ROOT_ASM_FILES))  \
  $(patsubst $(BHOPDIR)/%.s,$(BUILDDIR)/%.o,$(BHOP_ASM_FILES))

MAKE_FT_ROM := python ../makeftrom/makeftrom.py
FTCFG_NAME := $(FTCFG_PRE)ft.ftcfg
DEMO_ROM_NAME := $(GAME_PRE)ftdemo.nes
DEMO_DBG_NAME := $(GAME_PRE)ftdemo.dbg
DEMO_IPS_NAME := $(GAME_PRE)ftdemo.ips
DEMO_BPS_NAME := $(GAME_PRE)ftdemo.bps

ifeq ($(DEMO_CFG_NAME),)
DEMO_CFG_NAME := democfg.json5
endif

all: dir $(ROM_NAME) $(IPS_NAME) $(BPS_NAME) $(DEMO_ROM_NAME) $(DEMO_IPS_NAME) $(DEMO_BPS_NAME)

dir:
	-@mkdir -p $(BUILDDIR)

clean:
	-@rm -rf build
	-@rm -f $(ROM_NAME)
	-@rm -f $(DBG_NAME)
	-@rm -f $(IPS_NAME) 
	-@rm -f $(BPS_NAME) 
	-@rm -f $(DEMO_ROM_NAME) 
	-@rm -f $(DEMO_DBG_NAME) 
	-@rm -f $(DEMO_IPS_NAME) 
	-@rm -f $(DEMO_BPS_NAME)

run: dir $(ROM_NAME)
	rusticnes-sdl $(ROM_NAME)

$(IPS_NAME): $(ROM_NAME)
#	Requires Lunar IPS 1.03 from https://fusoya.eludevisibility.org/lips/index.html
	"Lunar IPS.exe" -CreateIPS $@ "$(PATCH_ROM)" $<

$(DELTA_NAME): $(ROM_NAME)
#	Requires xdelta3 from https://www.romhacking.net/utilities/928/ renamed to xdelta3.exe
	xdelta3 -e -9 -I 0 -f -s "$(PATCH_ROM)" $< $@
	
$(BPS_NAME): $(ROM_NAME)
#	Requires flips from https://www.romhacking.net/utilities/1040/
	flips --create --bps-delta-moremem --exact "$(PATCH_ROM)" $< $@
	
$(ROM_NAME): $(CFG_NAME) $(O_FILES)
	ld65 -vm -m $(BUILDDIR)/map.txt -Ln $(BUILDDIR)/labels.txt --dbgfile $(DBG_NAME) -o $@ $(value LINK_OPTS) -C $^

$(BUILDDIR)/%.o: $(SRCDIR)/%.s $(BUILD_BASE_ROM) ../z2mmc5/mmc5regs.inc
	@echo .define SRC_ROM "$(BUILD_BASE_ROM)" > $(BUILDDIR)/build.inc
	ca65 -g -I $(BUILDDIR) -I $(BHOPDIR)/bhop -l $@.lst -o $@ $(value COMPILE_OPTS) $<

$(BUILDDIR)/%.o: $(BHOPDIR)/%.s
	ca65 -g -l $@.lst -o $@ $(value BHOP_COMPILE_OPTS) $<

$(DEMO_ROM_NAME): $(ROM_NAME) $(FTCFG_NAME) $(DEMO_CFG_NAME) 
	$(MAKE_FT_ROM) --ftcfg $(FTCFG_NAME) $(DEMO_CFG_NAME) --input-rom $(ROM_NAME) --output-rom $(DEMO_ROM_NAME) --debug
	copy $(DBG_NAME) $(DEMO_DBG_NAME)
	
$(DEMO_IPS_NAME): $(DEMO_ROM_NAME)
#	Requires Lunar IPS 1.03 from https://fusoya.eludevisibility.org/lips/index.html
	"Lunar IPS.exe" -CreateIPS $@ "$(PATCH_ROM)" $<

$(DEMO_BPS_NAME): $(DEMO_ROM_NAME)
#	Requires flips from https://www.romhacking.net/utilities/1040/
	flips --create --bps-delta-moremem --exact "$(PATCH_ROM)" $< $@
