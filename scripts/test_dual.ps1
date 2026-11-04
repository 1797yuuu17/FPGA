param([string]$Test='all',[string]$Vsim='vsim')
$ErrorActionPreference='Stop'
$dualRoot=Split-Path $PSScriptRoot -Parent
$dualTests=if($Test -eq 'all'){@('tb_dual_audio','tb_dual_recording','tb_usb_recorder','tb_usb_recording_song','tb_usb_recorder_long')}else{@($Test)}
New-Item -ItemType Directory -Force (Join-Path $dualRoot 'reports/dual_audio') | Out-Null
Push-Location (Join-Path $dualRoot 'dual_audio')
try {foreach($dualTest in $dualTests){
 & $Vsim -c -l "../reports/dual_audio/$dualTest.log" -do "set TEST $dualTest; do sim/run.do"
 if($LASTEXITCODE -ne 0 -or !(Select-String -LiteralPath "../reports/dual_audio/$dualTest.log" -SimpleMatch "PASS $dualTest" -Quiet)){throw "FAIL $dualTest"}
}}finally{Pop-Location}
