@echo off
echo ========================================================
echo CONFIGURANDO O ROBO PARA RODAR A CADA 1 HORA...
echo ========================================================
echo.

set "SCRIPT_PATH=%USERPROFILE%\Desktop\monitorar_rios.ps1"

schtasks /create /tn "Robo_Defesa_Civil_Rios" /tr "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT_PATH%\"" /sc hourly /mo 1 /F

echo.
echo ========================================================
echo SUCESSO! A automacao foi configurada.
echo A partir de agora, o Windows vai executar o script 
echo de forma completamente invisivel a cada 1 hora.
echo (Desde que o computador esteja ligado e com internet)
echo ========================================================
pause
