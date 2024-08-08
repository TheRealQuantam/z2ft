@set COMMON_OPTS=FTCFG_PRE=z2 DEMO_CFG_NAME=democfg.json5 
@set OPTS=BASE_ROM=../z2mmc5/z2mmc5.nes PATCH_ROM="Zelda II - The Adventure of Link (USA).nes" GAME_PRE=z2
@set COMPILE_OPTS=
@set LINK_OPTS=
@set GAME_PRE=z2
@set DEMO_PATCH_PRE=z2
@set MMC=3

@call :buildgame
@IF ERRORLEVEL 1 GOTO failure

@set OPTS=BASE_ROM=../z2mmc5/z2mmc5.nes PATCH_ROM=../z2mmc5/z2mmc5.nes GAME_PRE=z2rnd
@set COMPILE_OPTS=-D RANDOMIZER
@set GAME_PRE=z2rnd

@call :buildgame
@IF ERRORLEVEL 1 GOTO failure

@echo.
@echo Success!
@goto :endbuild

:buildgame
make GAME_PRE=%GAME_PRE% DEMO_PATCH_PRE=%DEMO_PATCH_PRE% %COMMON_OPTS% %OPTS% COMPILE_OPTS="%COMPILE_OPTS% -D MMC=%MMC%" LINK_OPTS="%LINK_OPTS%" BHOP_COMPILE_OPTS="-D MMC=%MMC%"
@IF ERRORLEVEL 1 GOTO endbuild

@exit /b

:failure
@echo.
@echo Build error!

:endbuild
@exit /b