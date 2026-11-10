@echo off
chcp 65001 >nul
mode con: cols=145 lines=35
setlocal EnableExtensions DisableDelayedExpansion
title NAT BOLTU PRO - SPEED TRIM LOGO (REMOVE) ANTI-COPYRIGHT MASTER

REM ==========================================================
REM GOPAL BHAR PRO - AUTO TRIM & ZERO-DRIFT PROCESSOR
REM Trim First 7s & Last 5s | 3% Crop/Zoom (16:9) | Custom logo2.png
REM Exact +5% Synced Speed | +3% Pitch Shift | Visual Hash Shift
REM Fixed 30 FPS | 8% BG Music (4% on Dialogue)
REM ==========================================================

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

set "FFMPEG=%ROOT%\FFmpeg\ffmpeg.exe"
set "FFPROBE=%ROOT%\FFmpeg\ffprobe.exe"
set "INPUT=%ROOT%\_input"
set "OUTPUT=%ROOT%\_output"
set "AUDIO=%ROOT%\aud"
set "LOGO_FILE=%ROOT%\logo2.png"
set "LOG=%ROOT%\Gopal_Bhar_Processing_Log.txt"

REM ----------------------------------------------------------
REM TRIM SETTINGS (Seconds to cut from Start & End)
REM ----------------------------------------------------------
set "CUT_START=7"
set "CUT_END=5"

REM ----------------------------------------------------------
REM 1. BACKGROUND DELOGO COORDINATES (DO NOT CHANGE)
REM ----------------------------------------------------------
set "DELOGO_X=1580"
set "DELOGO_Y=90"
set "DELOGO_W=210"
set "DELOGO_H=180"

REM ----------------------------------------------------------
REM 2. YOUR CHANNEL LOGO (logo2.png) CUSTOM SIZE & POSITION
REM Change these 4 numbers anytime to resize/move your logo:
REM Tip: Set MY_LOGO_H=-1 to keep original logo aspect ratio!
REM ----------------------------------------------------------
set "MY_LOGO_X=1560"
set "MY_LOGO_Y=50"
set "MY_LOGO_W=250"
set "MY_LOGO_H=210"

REM ----------------------------------------------------------
REM CHECK REQUIRED FILES AND FOLDERS
REM ----------------------------------------------------------

if not exist "%FFMPEG%" (
    echo [ERROR] ffmpeg.exe not found at: "%FFMPEG%"
    pause
    exit /b 1
)

if not exist "%FFPROBE%" (
    echo [ERROR] ffprobe.exe not found at: "%FFPROBE%"
    pause
    exit /b 1
)

if not exist "%LOGO_FILE%" (
    echo [ERROR] Channel watermark not found at: "%LOGO_FILE%"
    echo Please place logo2.png in the main folder next to _input and _output.
    pause
    exit /b 1
)

if not exist "%INPUT%" mkdir "%INPUT%"
if not exist "%OUTPUT%" mkdir "%OUTPUT%"
if not exist "%AUDIO%" mkdir "%AUDIO%"

for %%N in (1 2 3 4) do (
    if not exist "%AUDIO%\bg%%N.mp4" (
        echo [ERROR] Missing background audio: "%AUDIO%\bg%%N.mp4"
        pause
        exit /b 1
    )
)

REM ----------------------------------------------------------
REM START PROCESSING
REM ----------------------------------------------------------

echo.
echo ==================================================
echo   GOPAL BHAR PRO - AUTO TRIM 16:9 PROCESSOR
echo ==================================================
echo.
echo Scanning _input folder...
echo.

> "%LOG%" echo GOPAL BHAR PRO PROCESSING LOG
>>"%LOG%" echo Started: %date% %time%

set /a TOTAL=0
set /a SUCCESS_COUNT=0
set /a FAIL_COUNT=0

REM ----------------------------------------------------------
REM SUPPORTED VIDEO FORMATS
REM ----------------------------------------------------------

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
echo PROCESSING COMPLETED
echo Total videos found : %TOTAL%
echo Successful         : %SUCCESS_COUNT%
echo Failed             : %FAIL_COUNT%
echo Check the _output folder.
echo ==================================================

>>"%LOG%" echo.
>>"%LOG%" echo Finished: %date% %time%
>>"%LOG%" echo Total: %TOTAL% ^| Success: %SUCCESS_COUNT% ^| Failed: %FAIL_COUNT%

pause
exit /b 0


REM ==========================================================
REM PROCESS ONE VIDEO
REM ==========================================================

:PROCESS

set "SOURCE=%~1"
set "NAME=%~n1"
set "EXT=%~x1"
set "EXT_CLEAN=%EXT:~1%"
set "DEST=%OUTPUT%\%NAME%_%EXT_CLEAN%_processed.mp4"

echo.
echo --------------------------------------------------
echo Processing: "%~nx1"
echo --------------------------------------------------

>>"%LOG%" echo.
>>"%LOG%" echo Processing: "%~nx1"

REM ----------------------------------------------------------
REM GET EXACT VIDEO DURATION & CALCULATE TRIM END POINT
REM ----------------------------------------------------------

set "DURFILE=%TEMP%\gb_dur_%RANDOM%_%RANDOM%.txt"
"%FFPROBE%" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "%SOURCE%" > "%DURFILE%" 2>nul

set "RAW_DUR="
if exist "%DURFILE%" set /p RAW_DUR=<"%DURFILE%"
del "%DURFILE%" 2>nul

if not defined RAW_DUR (
    echo [ERROR] Could not read video duration: "%~nx1"
    set /a FAIL_COUNT+=1
    >>"%LOG%" echo FAILED ^(Duration Read Error^): "%~nx1"
    exit /b
)

for /f "tokens=1 delims=." %%D in ("%RAW_DUR%") do set /a DUR_INT=%%D

set /a TRIM_END=%DUR_INT% - %CUT_END%
set /a MIN_REQ=%CUT_START% + 5

if %TRIM_END% LEQ %MIN_REQ% (
    echo [ERROR] Video too short ^(%DUR_INT%s^) to cut %CUT_START%s start and %CUT_END%s end.
    set /a FAIL_COUNT+=1
    >>"%LOG%" echo FAILED ^(Video Too Short^): "%~nx1"
    exit /b
)

echo Original Duration: %DUR_INT%s ^| Keeping: %CUT_START%s to %TRIM_END%s

REM ----------------------------------------------------------
REM RANDOM BACKGROUND MUSIC
REM ----------------------------------------------------------

set /a BGNUM=%RANDOM% %% 4 + 1
set "BGFILE=%AUDIO%\bg%BGNUM%.mp4"

echo Selected background: bg%BGNUM%.mp4

REM ----------------------------------------------------------
REM CHECK AUDIO STREAM SAFELY
REM ----------------------------------------------------------

set "AUDCHECK=%TEMP%\gb_aud_%RANDOM%_%RANDOM%.txt"
"%FFPROBE%" -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "%SOURCE%" > "%AUDCHECK%" 2>nul

set "HASAUDIO="
if exist "%AUDCHECK%" (
    for %%Z in ("%AUDCHECK%") do (
        if %%~zZ GTR 0 set "HASAUDIO=YES"
    )
)
del "%AUDCHECK%" 2>nul

REM ----------------------------------------------------------
REM VIDEO FILTER CHAIN (FIXED DELOGO + CUSTOM MY_LOGO SIZE):
REM ----------------------------------------------------------

set "VBASE=[0:v:0]trim=start=%CUT_START%:end=%TRIM_END%,setpts=(PTS-STARTPTS)/1.05,scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,crop=iw/1.03:ih/1.03,scale=1920:1080:flags=lanczos,setsar=1,delogo=x=%DELOGO_X%:y=%DELOGO_Y%:w=%DELOGO_W%:h=%DELOGO_H%,hue=h=2,eq=contrast=1.07:saturation=1.16:brightness=0.015:gamma=1.02,unsharp=5:5:0.75:5:5:0.0[vbase]"
set "VLOGO=[2:v:0]scale=%MY_LOGO_W%:%MY_LOGO_H%:flags=lanczos[wm];[vbase][wm]overlay=x=%MY_LOGO_X%:y=%MY_LOGO_Y%,fps=30[vout]"

REM ----------------------------------------------------------
REM AUDIO FILTER CHAIN (EXACT SAME TRIM + +3% PITCH + +5% SPEED):
REM ----------------------------------------------------------

echo Starting final video encoding...

if defined HASAUDIO (

    echo Original audio detected. Trimming, applying +3%% Pitch, Exact +5%% Sync, and 8%%-to-4%% Ducking...

    "%FFMPEG%" -hide_banner -loglevel error -stats -y -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -i "%LOGO_FILE%" -filter_complex "%VBASE%;%VLOGO%;[0:a:0]atrim=start=%CUT_START%:end=%TRIM_END%,asetpts=PTS-STARTPTS,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,asetrate=44100*1.03,aresample=44100,atempo=1.01941748,highpass=f=85,equalizer=f=3000:t=q:w=1.5:g=1.5,asplit=2[voice][sc];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,volume=0.08[bg];[bg][sc]sidechaincompress=threshold=0.015:ratio=3.0:attack=5:release=250[duck];[voice][duck]amix=inputs=2:duration=first:dropout_transition=0:weights=1 1[aout]" -map "[vout]" -map "[aout]" -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "%DEST%"

) else (

    echo No original audio detected. Trimming and adding 8%% BG Music...

    "%FFMPEG%" -hide_banner -loglevel error -stats -y -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -i "%LOGO_FILE%" -filter_complex "%VBASE%;%VLOGO%;[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,volume=0.08[aout]" -map "[vout]" -map "[aout]" -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart -shortest "%DEST%"

)

set "RESULT=%ERRORLEVEL%"

REM ----------------------------------------------------------
REM PROCESS RESULT
REM ----------------------------------------------------------

if not "%RESULT%"=="0" (
    set /a FAIL_COUNT+=1
    echo.
    echo [ERROR] PROCESSING FAILED: "%~nx1"
    >>"%LOG%" echo FAILED: "%~nx1"
) else (
    set /a SUCCESS_COUNT+=1
    echo.
    echo [OK] SUCCESS: "%DEST%"
    >>"%LOG%" echo SUCCESS: "%~nx1"
)

>>"%LOG%" echo Finished: %date% %time%

exit /b