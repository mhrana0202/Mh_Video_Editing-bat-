@echo off
chcp 65001 >nul
mode con: cols=145 lines=35
setlocal EnableExtensions DisableDelayedExpansion
title GOPAL BHAR PRO - MOJAR KICCHA CROP_3px DUAL LOGO SETUP

REM ==========================================================
REM GOPAL BHAR PRO - ZERO-DRIFT PROCESSOR
REM 3% Crop/Zoom (16:9)
REM Left Logo: logo.png | Right Logo: logo4.png
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
set "LOGO_RIGHT_FILE=%ROOT%\logo4.png"
set "LOGO_LEFT_FILE=%ROOT%\logo.png"
set "LOG=%ROOT%\Gopal_Bhar_Processing_Log.txt"

REM ----------------------------------------------------------
REM 1. RIGHT SIDE CHANNEL LOGO (logo4.png) - UNCHANGED
REM ----------------------------------------------------------
set "RIGHT_LOGO_X=1650"
set "RIGHT_LOGO_Y=40"
set "RIGHT_LOGO_W=200"
set "RIGHT_LOGO_H=190"

REM ----------------------------------------------------------
REM 2. LEFT SIDE CHANNEL LOGO (logo.png) - TOP LEFT (SHIFTED INWARD)
REM Increase LEFT_LOGO_X to move further right, decrease to move left
REM ----------------------------------------------------------
set "LEFT_LOGO_X=40"
set "LEFT_LOGO_Y=30"
set "LEFT_LOGO_W=260"
set "LEFT_LOGO_H=170"

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

if not exist "%LOGO_RIGHT_FILE%" (
    echo [ERROR] Right watermark not found at: "%LOGO_RIGHT_FILE%"
    echo Please place logo4.png in the main folder next to _input and _output.
    pause
    exit /b 1
)

if not exist "%LOGO_LEFT_FILE%" (
    echo [ERROR] Left watermark not found at: "%LOGO_LEFT_FILE%"
    echo Please place logo.png in the main folder next to _input and _output.
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
echo   GOPAL BHAR PRO - MOJAR KICCHA (SHORT VIDEOS) PROCESSOR
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
REM VIDEO FILTER CHAIN (NO DELOGO + RIGHT logo4.png + LEFT logo.png):
REM Input [2:v:0] = logo4.png (Right)
REM Input [3:v:0] = logo.png  (Left)
REM ----------------------------------------------------------

set "VBASE=[0:v:0]setpts=(PTS-STARTPTS)/1.05,scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,crop=iw/1.03:ih/1.03,scale=1920:1080:flags=lanczos,setsar=1,hue=h=2,eq=contrast=1.07:saturation=1.16:brightness=0.015:gamma=1.02,unsharp=5:5:0.75:5:5:0.0[vbase]"
set "VLOGO=[2:v:0]format=rgba,scale=%RIGHT_LOGO_W%:%RIGHT_LOGO_H%:flags=lanczos[wm_r];[3:v:0]format=rgba,scale=%LEFT_LOGO_W%:%LEFT_LOGO_H%:flags=lanczos[wm_l];[vbase][wm_r]overlay=x=%RIGHT_LOGO_X%:y=%RIGHT_LOGO_Y%[v_r];[v_r][wm_l]overlay=x=%LEFT_LOGO_X%:y=%LEFT_LOGO_Y%,fps=30[vout]"

REM ----------------------------------------------------------
REM AUDIO FILTER CHAIN (+3% PITCH + +5% SPEED):
REM ----------------------------------------------------------

echo Starting final video encoding...

if defined HASAUDIO (

    echo Original audio detected. Applying +3%% Pitch, Exact +5%% Sync, and 8%%-to-4%% Ducking...

    "%FFMPEG%" -hide_banner -loglevel error -stats -y -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -i "%LOGO_RIGHT_FILE%" -i "%LOGO_LEFT_FILE%" -filter_complex "%VBASE%;%VLOGO%;[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,asetrate=44100*1.03,aresample=44100,atempo=1.01941748,highpass=f=85,equalizer=f=3000:t=q:w=1.5:g=1.5,asplit=2[voice][sc];[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,volume=0.08[bg];[bg][sc]sidechaincompress=threshold=0.015:ratio=3.0:attack=5:release=250[duck];[voice][duck]amix=inputs=2:duration=first:dropout_transition=0:weights=1 1[aout]" -map "[vout]" -map "[aout]" -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart -shortest "%DEST%"

) else (

    echo No original audio detected. Adding 8%% BG Music...

    "%FFMPEG%" -hide_banner -loglevel error -stats -y -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -i "%LOGO_RIGHT_FILE%" -i "%LOGO_LEFT_FILE%" -filter_complex "%VBASE%;%VLOGO%;[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,volume=0.08[aout]" -map "[vout]" -map "[aout]" -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart -shortest "%DEST%"

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