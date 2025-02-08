rem @echo off

mkdir release

for %%f in (z2ft.bps z2ftdemo.bps democfg.json5 z2ft.ftcfg license.txt readme.txt) do copy %%f release

pause