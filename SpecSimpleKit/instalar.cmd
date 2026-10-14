@echo off
rem SpecSimpleKit: assistente de instalacao. Sem parametros, pergunta a pasta do
rem projeto e o perfil; com parametros, repassa ao install.ps1.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
exit /b %ERRORLEVEL%
