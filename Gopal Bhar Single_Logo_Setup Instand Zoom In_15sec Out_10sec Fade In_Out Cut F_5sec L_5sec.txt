@echo off
setlocal EnableExtensions DisableDelayedExpansion
title GOPAL BHAR PRO - ULTIMATE FAST VIDEO PROCESSOR

REM ==========================================================
REM GOPAL BHAR PRO - UNIVERSAL VIDEO PROCESSOR (ULTIMATE EDITION)
REM H.264 | CRF 18 | Trim Start/End 5s | Fixed Fade In/Out
REM Instant 15s/10s Zoom Cycle | 3% BG Music with 0% Ducking
REM Natural Color + Crisp Sharpness + Theme Border + Pure Logo
REM Speed Optimized (Min 1X-1.3X+ Guaranteed)
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
REM FIND LOGO FILE AUTOMATICALLY
REM ----------------------------------------------------------

set "LOGO="
if exist "%ROOT%\logo.png" set "LOGO=%ROOT%\logo.png"
if exist "%ROOT%\logo.jpg" set "LOGO=%ROOT%\logo.jpg"
if exist "%ROOT%\1000086253.png" set "LOGO=%ROOT%\1000086253.png"

REM ----------------------------------------------------------
REM START PROCESSING
REM ----------------------------------------------------------

echo.
echo ==================================================
echo   GOPAL BHAR PRO ULTIMATE FAST PROCESSOR
echo ==================================================
echo.
if defined LOGO (
    echo Logo detected: %LOGO%
) else (
    echo WARNING: Logo file not found in main folder.
)
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
REM READ VIDEO DURATION, FRAME RATE AND RESOLUTION
REM ----------------------------------------------------------

set "DURFILE=%TEMP%\gb_dur_%RANDOM%_%RANDOM%.txt"
set "FPSFILE=%TEMP%\gb_fps_%RANDOM%_%RANDOM%.txt"
set "DIMFILE=%TEMP%\gb_dim_%RANDOM%_%RANDOM%.txt"
set "AUDCHECK=%TEMP%\gb_aud_%RANDOM%_%RANDOM%.txt"

"%FFPROBE%" -v error -show_entries format=duration -of csv=p=0 "%SOURCE%" > "%DURFILE%" 2>nul
"%FFPROBE%" -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "%SOURCE%" > "%FPSFILE%" 2>nul
"%FFPROBE%" -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "%SOURCE%" > "%DIMFILE%" 2>nul
"%FFPROBE%" -v error -select_streams a:0 -show_entries stream=index -of csv=p=0 "%SOURCE%" > "%AUDCHECK%" 2>nul

set "DUR_RAW="
set "FPS="
set "DIM="
set "HASAUDIO="

if exist "%DURFILE%" set /p DUR_RAW=<"%DURFILE%"
if exist "%FPSFILE%" set /p FPS=<"%FPSFILE%"
if exist "%DIMFILE%" set /p DIM=<"%DIMFILE%"

if exist "%AUDCHECK%" (
    for %%Z in ("%AUDCHECK%") do (
        if %%~zZ GTR 0 set "HASAUDIO=YES"
    )
)

del "%DURFILE%" "%FPSFILE%" "%DIMFILE%" "%AUDCHECK%" 2>nul

if not defined FPS set "FPS=30"
if not defined DIM set "DIM=1920x1080"

REM ----------------------------------------------------------
REM CALCULATE TRIM DURATION (Cut first 5s and last 5s)
REM ----------------------------------------------------------

if not defined DUR_RAW set "DUR_RAW=120"

for /f "tokens=1 delims=." %%A in ("%DUR_RAW%") do set /a TOTAL_SEC=%%A
set /a NEW_DUR=%TOTAL_SEC% - 10

if %NEW_DUR% LSS 5 (
    echo ERROR: Video is too short to cut 5s from start and end. Skipping.
    >>"%LOG%" echo FAILED: Video too short for 5s trim.
    exit /b
)

set /a FADE_OUT_START=%NEW_DUR% - 1

echo Original Duration: %TOTAL_SEC%s ^| New Trimmed Duration: %NEW_DUR%s
echo Frame rate: %FPS%
echo Resolution: %DIM%

REM ----------------------------------------------------------
REM OPTIMIZED INSTANT ZOOM CYCLE, SHARPNESS & BORDER
REM ----------------------------------------------------------

set "EXPR=if(lt(mod(on\,750)\,450)\,1\,1.02)"
set "ZOOM=zoompan=z='%EXPR%':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=%DIM%:fps=30"
set "BORDER=drawbox=x=0:y=0:w=iw:h=ih:color=red@0.8:t=3,drawbox=x=3:y=3:w=iw-6:h=ih-6:color=gold@0.8:t=2"
set "ENHANCE=eq=contrast=1.01:saturation=1.02:brightness=0.001,unsharp=3:3:0.3:3:3:0.0"
set "FADE_V=fade=t=in:st=0:d=0.5,fade=t=out:st=%FADE_OUT_START%:d=0.5"

REM ----------------------------------------------------------
REM WATERMARK & AUDIO FILTER COMPLEX
REM ----------------------------------------------------------

if defined LOGO (
    echo Logo found. Adding transparent watermark to top-left.
    set "VFILTER=[0:v]fps=30,%ZOOM%,%BORDER%,%ENHANCE%[main];[2:v]scale=220:-1[wm];[main][wm]overlay=25:25,%FADE_V%[vout]"
) else (
    echo Logo not found. Skipping watermark.
    set "VFILTER=[0:v]fps=30,%ZOOM%,%BORDER%,%ENHANCE%,%FADE_V%[vout]"
)

set "AFADE=afade=t=in:st=0:d=0.5,afade=t=out:st=%FADE_OUT_START%:d=0.5"

REM ----------------------------------------------------------
REM AUDIO MIXING & ULTRA-FAST ENCODING
REM ----------------------------------------------------------

echo.
echo Starting final video encoding...

if defined LOGO (
    set "INPUTS=-ss 5 -t %NEW_DUR% -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%" -i "%LOGO%""
) else (
    set "INPUTS=-ss 5 -t %NEW_DUR% -i "%SOURCE%" -stream_loop -1 -i "%BGFILE%""
)

if defined HASAUDIO (

    echo Original audio detected. Mixing background music with 0% dialogue ducking.

    "%FFMPEG%" -hide_banner -y %INPUTS% -filter_complex "%VFILTER%;[0:a:0]%AFADE%[orig];[1:a:0]volume=0.03[bg];[bg][orig]sidechaincompress=threshold=0.03:ratio=10:attack=15:release=200[duck];[orig][duck]amix=inputs=2:duration=first:dropout_transition=2:normalize=0[aout]" -map "[vout]" -map "[aout]" -c:v libx264 -preset ultrafast -tune fastdecode -threads 0 -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "%DEST%"

) else (

    echo No original audio detected. Adding background music at 3%.

    "%FFMPEG%" -hide_banner -y %INPUTS% -filter_complex "%VFILTER%;[1:a:0]volume=0.03,%AFADE%[aout]" -map "[vout]" -map "[aout]" -c:v libx264 -preset ultrafast -tune fastdecode -threads 0 -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "%DEST%"

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