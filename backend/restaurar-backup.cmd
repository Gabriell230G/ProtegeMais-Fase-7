@echo off
REM Restaura um backup do banco (Fase 7). A API precisa estar parada.
REM Uso:  restaurar-backup.cmd data\backups\protege-AAAAMMDD-HHMMSS-mmm.zip
if "%~1"=="" (
  echo Uso: restaurar-backup.cmd data\backups\protege-AAAAMMDD-HHMMSS-mmm.zip
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restaurar-backup.ps1" -Arquivo "%~1"
