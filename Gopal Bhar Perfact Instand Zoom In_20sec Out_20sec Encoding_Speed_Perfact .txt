@echo off
setlocal EnableExtensions DisableDelayedExpansion
title GOPAL BHAR PRO - INSTANT 20S ZOOM VIDEO PROCESSOR

REM ==========================================================
REM GOPAL BHAR PRO - UNIVERSAL VIDEO PROCESSOR
REM H.264 | CRF 18 | Instant 20s Zoom-In & 20s Zoom-Out Cycle
REM Optimized Sharpening & Audio Leveling
REM ==========================================================

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

set "FFMPEG=%ROOT%\FFmpeg\ffmpeg.exe"
set "FFPROBE=%ROOT%\FFmpeg\ffprobe.exe"
set "INPUT=%ROOT%\_input"
set "OUTPUT=%ROOT%\_output"
set "AUDIO=%ROOT%\aud"
set "LOG=%ROOT%\Gopal_Bhar_Processing_Log.txt"

REM ----------------------------------------------------------
REM CHECK REQUIRED FILES AND FOLDERS
REM ----------------------------------------------------------

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

for %%N in (1 2 3 4) do (
    if not exist "%AUDIO%\bg%%N.mp4" (
        echo ERROR: Missing background audio bg%%N.mp4
        pause
        exit /b 1
    )
)

REM ----------------------------------------------------------
REM START PROCESSING
REM ----------------------------------------------------------

echo.
echo ==================================================
echo   GOPAL BHAR PRO INSTANT ZOOM VIDEO PROCESSOR
echo ==================================================
echo.
echo Processing videos one by one...
echo.

> "%LOG%" echo GOPAL BHAR PRO PROCESSING LOG
>>"%LOG%" echo Started: %date% %time%

set /a TOTAL=0

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
echo Total videos found: %TOTAL%
echo Check the _output folder.
echo ==================================================

>>"%LOG%" echo.
>>"%LOG%" echo Finished: %date% %time%
>>"%LOG%" echo Total videos found: %TOTAL%

pause
exit /b 0


REM ==========================================================
REM PROCESS ONE VIDEO
REM ==========================================================

:PROCESS

set "SOURCE=%~1"
set "NAME=%~n1"
set "EXT=%~x1"
set "DEST=%OUTPUT%\%NAME%_%EXT:~1%_processed.mp4"

echo.
echo --------------------------------------------------
echo Processing: %~nx1
echo --------------------------------------------------

>>"%LOG%" echo.
>>"%LOG%" echo Processing: %~nx1

REM ----------------------------------------------------------
REM RANDOM BACKGROUND MUSIC
REM ----------------------------------------------------------

set /a BGNUM=%RANDOM% %% 4 + 1
set "BGFILE=%AUDIO%\bg%BGNUM%.mp4"

echo Selected background: bg%BGNUM%.mp4

REM ----------------------------------------------------------
REM READ VIDEO FRAME RATE AND RESOLUTION
REM ----------------------------------------------------------

set "FPSFILE=%TEMP%\gb_fps_%RANDOM%_%RANDOM%.txt"
set "DIMFILE=%TEMP%\gb_dim_%RANDOM%_%RANDOM%.txt"
set "AUDCHECK=%TEMP%\gb_aud_%RANDOM%_%RANDOM%.txt"

"%FFPROBE%" -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "%SOURCE%" > "%FPSFILE%" 2>nul
"%FFPROBE%" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "%SOURCE%" > "%DIMFILE%" 2>nul
"%FFPROBE%" -v error -select_streams a:0 -show_entries stream=index -of csv=p=0 "%SOURCE%" > "%AUDCHECK%" 2>nul

set "FPS="
set "DIM="
set "HASAUDIO="

if exist "%FPSFILE%" set /p FPS=<"%FPSFILE%"
if exist "%DIMFILE%" set /p DIM=<"%DIMFILE%"

if exist "%AUDCHECK%" (
    for %%Z in ("%AUDCHECK%") do (
        if %%~zZ GTR 0 set "HASAUDIO=YES"
    )
)

del "%FPSFILE%" "%DIMFILE%" "%AUDCHECK%" 2>nul

if not defined FPS set "FPS=30"
if not defined DIM set "DIM=1920x1080"

echo Frame rate: %FPS%
echo Resolution: %DIM%

REM ----------------------------------------------------------
REM INSTANT 20s ZOOM CYCLE (20s 0% -> Instant 1.5% Zoom -> 20s 1.5% -> Instant 0% Zoom)
REM CYCLE LENGTH = 40 SECONDS (1200 FRAMES @ 30 FPS)
REM ----------------------------------------------------------

set "EXPR=if(lt(mod(on\,1200)\,600)\,1\,1.015)"
set "ZOOM=zoompan=z='%EXPR%':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=%DIM%:fps=30"
set "ENHANCE=eq=contrast=1.01:saturation=1.02:brightness=0.001,unsharp=3:3:0.3:3:3:0.0"

set "VF=fps=30,%ZOOM%,%ENHANCE%"

REM ----------------------------------------------------------
REM AUDIO MIXING & FAST ENCODING
REM ----------------------------------------------------------

echo.
echo Starting final video encoding...

if defined HASAUDIO (

    echo Original audio detected. Mixing background music with dialogue ducking.

    "%FFMPEG%" -hide_banner -y -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -filter_complex "[1:a:0]volume=0.01[bg];[bg][0:a:0]sidechaincompress=threshold=0.025:ratio=8:attack=15:release=400[duck];[0:a:0][duck]amix=inputs=2:duration=first:dropout_transition=2:normalize=0[aout]" -map 0:v:0 -map "[aout]" -vf "%VF%" -c:v libx264 -preset ultrafast -tune fastdecode -threads 0 -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart -shortest "%DEST%"

) else (

    echo No original audio detected. Adding background music.

    "%FFMPEG%" -hide_banner -y -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -filter_complex "[1:a:0]volume=0.01[aout]" -map 0:v:0 -map "[aout]" -vf "%VF%" -c:v libx264 -preset ultrafast -tune fastdecode -threads 0 -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart -shortest "%DEST%"

)

set "RESULT=%ERRORLEVEL%"

REM ----------------------------------------------------------
REM PROCESS RESULT
REM ----------------------------------------------------------

if not "%RESULT%"=="0" (
    echo.
    echo PROCESSING FAILED: %~nx1
    >>"%LOG%" echo FAILED: %~nx1
) else (
    echo.
    echo SUCCESS: %DEST%
    >>"%LOG%" echo SUCCESS: %DEST%
)

>>"%LOG%" echo Finished: %date% %time%

exit /b