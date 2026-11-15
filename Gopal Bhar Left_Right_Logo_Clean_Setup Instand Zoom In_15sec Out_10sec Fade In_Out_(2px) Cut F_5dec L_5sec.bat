@echo off
setlocal EnableExtensions DisableDelayedExpansion
title GOPAL BHAR PRO - CLEAN AND DUAL LOGO SETUP

REM ==========================================================
REM GOPAL BHAR PRO - 100% STABLE & NO-CRASH DUAL LOGO EDITION
REM Right Logo: logo3.png | Left Logo: logo.png
REM ==========================================================

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

set "FFMPEG=%ROOT%\FFmpeg\ffmpeg.exe"
set "FFPROBE=%ROOT%\FFmpeg\ffprobe.exe"
set "INPUT=%ROOT%\_input"
set "OUTPUT=%ROOT%\_output"
set "AUDIO=%ROOT%\aud"
set "LOG=%ROOT%\Gopal_Bhar_Processing_Log.txt"

if not exist "%FFMPEG%" (
    echo ERROR: ffmpeg.exe not found.
    pause
    exit /b 1
)

if not exist "%FFPROBE%" (
    echo ERROR: ffprobe.exe not found.
    pause
    exit /b 1
)

if not exist "%INPUT%" mkdir "%INPUT%"
if not exist "%OUTPUT%" mkdir "%OUTPUT%"
if not exist "%AUDIO%" mkdir "%AUDIO%"

REM ----------------------------------------------------------
REM DETECT LOGOS (RIGHT: logo3.png | LEFT: logo.png)
REM ----------------------------------------------------------

set "LOGO_RIGHT="
set "LOGO_LEFT="

if exist "%ROOT%\logo3.png" set "LOGO_RIGHT=%ROOT%\logo3.png"
if exist "%ROOT%\logo3.jpeg" set "LOGO_RIGHT=%ROOT%\logo3.jpeg"
if exist "%ROOT%\logo3.jpg" set "LOGO_RIGHT=%ROOT%\logo3.jpg"

if exist "%ROOT%\logo.png" set "LOGO_LEFT=%ROOT%\logo.png"
if exist "%ROOT%\logo.jpeg" set "LOGO_LEFT=%ROOT%\logo.jpeg"
if exist "%ROOT%\logo.jpg" set "LOGO_LEFT=%ROOT%\logo.jpg"

echo.
echo ==================================================
echo   GOPAL BHAR PRO PROCESSOR (CRASH FIXED)
echo ==================================================
echo.

> "%LOG%" echo GOPAL BHAR PRO PROCESSING LOG
>>"%LOG%" echo Started: %date% %time%

set /a TOTAL=0

for %%E in (mp4 mkv avi mov wmv flv webm m4v mpg mpeg 3gp ts mts m2ts ogv) do (
    for %%F in ("%INPUT%\*.%%E") do (
        if exist "%%~fF" (
            set /a TOTAL+=1
            call :PROCESS "%%~fF"
        )
    )
)

echo.
echo ==================================================
echo PROCESSING COMPLETED - Total videos: %TOTAL%
echo Check the _output folder.
echo ==================================================

pause
exit /b 0


REM ==========================================================
REM PROCESS SINGLE VIDEO
REM ==========================================================

:PROCESS

set "SOURCE=%~1"
set "NAME=%~n1"
set "EXT=%~x1"
set "DEST=%OUTPUT%\%NAME%_%EXT:~1%_processed.mp4"

echo Processing: %~nx1

set /a BGNUM=%RANDOM% %% 4 + 1
set "BGFILE=%AUDIO%\bg%BGNUM%.mp4"

set "DURFILE=%TEMP%\gb_dur_%RANDOM%.txt"
set "AUDCHECK=%TEMP%\gb_aud_%RANDOM%.txt"

"%FFPROBE%" -v error -show_entries format=duration -of csv=p=0 "%SOURCE%" > "%DURFILE%" 2>nul
"%FFPROBE%" -v error -select_streams a:0 -show_entries stream=index -of csv=p=0 "%SOURCE%" > "%AUDCHECK%" 2>nul

set "DUR_RAW="
set "HASAUDIO="

if exist "%DURFILE%" set /p DUR_RAW=<"%DURFILE%"
if exist "%AUDCHECK%" (
    for %%Z in ("%AUDCHECK%") do (
        if %%~zZ GTR 0 set "HASAUDIO=YES"
    )
)

del "%DURFILE%" "%AUDCHECK%" 2>nul

if not defined DUR_RAW set "DUR_RAW=120"
for /f "tokens=1 delims=." %%A in ("%DUR_RAW%") do set /a TOTAL_SEC=%%A
set /a NEW_DUR=%TOTAL_SEC% - 10

if %NEW_DUR% LSS 5 (
    echo Skipped: Video too short.
    exit /b
)

set /a FADE_OUT_START=%NEW_DUR% - 1

set "ZOOM=zoompan=z='if(lt(mod(on\,750)\,450)\,1\,1.01)':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1920x1080:fps=30"
set "BORDER=drawbox=x=0:y=0:w=iw:h=ih:color=red@0.8:t=3,drawbox=x=3:y=3:w=iw-6:h=ih-6:color=gold@0.8:t=2"
set "ENHANCE=eq=contrast=1.03:saturation=1.05:brightness=0.0,unsharp=5:5:0.5:3:3:0.0"
set "FADE_V=fade=t=in:st=0:d=0.5,fade=t=out:st=%FADE_OUT_START%:d=0.5"
set "AFADE=afade=t=in:st=0:d=0.5,afade=t=out:st=%FADE_OUT_START%:d=0.5"

REM SAFE IN-LINE FILTERS SETUP
set "INPUT_CMD=-ss 5 -t %NEW_DUR% -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%""

if defined LOGO_RIGHT if defined LOGO_LEFT (
    set "INPUT_CMD=-ss 5 -t %NEW_DUR% -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -i "%LOGO_RIGHT%" -i "%LOGO_LEFT%""
    set "VF_CMD=[0:v]fps=30,%ZOOM%,%BORDER%,%ENHANCE%[main];[2:v]scale=270:-1[wm_r];[3:v]scale=280:-1[wm_l];[main][wm_r]overlay=main_w-overlay_w-95:22[tmp];[tmp][wm_l]overlay=85:25,%FADE_V%[vout]"
) else if defined LOGO_RIGHT (
    set "INPUT_CMD=-ss 5 -t %NEW_DUR% -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -i "%LOGO_RIGHT%""
    set "VF_CMD=[0:v]fps=30,%ZOOM%,%BORDER%,%ENHANCE%[main];[2:v]scale=270:-1[wm_r];[main][wm_r]overlay=main_w-overlay_w-95:22,%FADE_V%[vout]"
) else if defined LOGO_LEFT (
    set "INPUT_CMD=-ss 5 -t %NEW_DUR% -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -i "%LOGO_LEFT%""
    set "VF_CMD=[0:v]fps=30,%ZOOM%,%BORDER%,%ENHANCE%[main];[2:v]scale=280:-1[wm_l];[main][wm_l]overlay=85:25,%FADE_V%[vout]"
) else (
    set "VF_CMD=[0:v]fps=30,%ZOOM%,%BORDER%,%ENHANCE%,%FADE_V%[vout]"
)

if defined HASAUDIO (
    set "AF_CMD=[0:a:0]volume=1.05,%AFADE%,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[orig];[1:a:0]volume=0.03,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[bg];[bg][orig]sidechaincompress=threshold=0.03:ratio=10:attack=15:release=200[duck];[orig][duck]amix=inputs=2:duration=first:normalize=0[aout]"
) else (
    set "AF_CMD=[1:a:0]volume=0.03,%AFADE%,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[aout]"
)

"%FFMPEG%" -hide_banner -y %INPUT_CMD% -filter_complex "%VF_CMD%;%AF_CMD%" -map "[vout]" -map "[aout]" -c:v libx264 -preset ultrafast -tune fastdecode -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "%DEST%"

exit /b