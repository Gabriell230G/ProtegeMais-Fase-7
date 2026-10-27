@echo off
REM Atalho para restaurar um backup do banco (Fase 7). Servidor deve estar parado.
REM Uso:  restaurar-backup.cmd data\backups\protege-AAAAMMDD-HHMMSS.zip
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restaurar-backup.ps1" -Arquivo %1
