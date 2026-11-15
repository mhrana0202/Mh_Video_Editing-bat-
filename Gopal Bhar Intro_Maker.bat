@echo off
chcp 65001 >nul
mode con: cols=145 lines=35
setlocal EnableExtensions DisableDelayedExpansion
title GOPAL BHAR PRO - SMART ANY-FORMAT INTRO JOINER (HP 840 G2 OPTIMIZED)

REM ==========================================================
REM GOPAL BHAR PRO - SMART ANY-FORMAT INTRO JOINER
REM Auto-matches Resolution, FPS, Audio Codec from _intro & _input
REM High Speed Encoding via Intel QSV / Ultra Fast CPU Fallback
REM ==========================================================

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

set "FFMPEG=%ROOT%\FFmpeg\ffmpeg.exe"
set "FFPROBE=%ROOT%\FFmpeg\ffprobe.exe"
set "INPUT=%ROOT%\_input"
set "OUTPUT=%ROOT%\_output"
set "INTRO_DIR=%ROOT%\_intro"
set "LOG=%ROOT%\Gopal_Bhar_Processing_Log.txt"

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

if not exist "%INPUT%" mkdir "%INPUT%"
if not exist "%OUTPUT%" mkdir "%OUTPUT%"
if not exist "%INTRO_DIR%" mkdir "%INTRO_DIR%"

REM ----------------------------------------------------------
REM FIND INTRO VIDEO FROM _intro FOLDER
REM ----------------------------------------------------------

set "INTRO_FILE="
for %%E in (mp4 mkv avi mov wmv flv webm m4v mpg mpeg 3gp ts mts m2ts ogv) do (
    if not defined INTRO_FILE (
        for %%F in ("%INTRO_DIR%\*.%%E") do (
            if exist "%%~fF" set "INTRO_FILE=%%~fF"
        )
    )
)

if not defined INTRO_FILE (
    echo [ERROR] No intro video found in: "%INTRO_DIR%"
    echo Please place your intro video inside the _intro folder.
    pause
    exit /b 1
)

echo.
echo ==================================================
echo   GOPAL BHAR PRO - SMART INTRO JOINER
echo ==================================================
echo.
echo Found Intro Video : "%INTRO_FILE%"
echo Scanning _input folder...
echo.

> "%LOG%" echo GOPAL BHAR PRO PROCESSING LOG
>>"%LOG%" echo Started: %date% %time%
>>"%LOG%" echo Intro File: "%INTRO_FILE%"

set /a TOTAL=0
set /a SUCCESS_COUNT=0
set /a FAIL_COUNT=0

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
REM PROCESS ONE VIDEO WITH AUTOMATIC RESCALING & AUDIO MATCH
REM ==========================================================

:PROCESS

set "SOURCE=%~1"
set "NAME=%~n1"
set "EXT=%~x1"
set "EXT_CLEAN=%EXT:~1%"
set "DEST=%OUTPUT%\%NAME%_%EXT_CLEAN%_processed.mp4"

echo.
echo --------------------------------------------------
echo Processing and Joining: "%~nx1"
echo --------------------------------------------------

>>"%LOG%" echo.
>>"%LOG%" echo Processing: "%~nx1"

REM Check main video audio stream
set "AUDCHECK=%TEMP%\gb_aud_%RANDOM%_%RANDOM%.txt"
"%FFPROBE%" -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "%SOURCE%" > "%AUDCHECK%" 2>nul

set "HASAUDIO="
if exist "%AUDCHECK%" (
    for %%Z in ("%AUDCHECK%") do (
        if %%~zZ GTR 0 set "HASAUDIO=YES"
    )
)
del "%AUDCHECK%" 2>nul

REM Check intro video audio stream
set "INTRO_AUDCHECK=%TEMP%\gb_intro_aud_%RANDOM%_%RANDOM%.txt"
"%FFPROBE%" -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "%INTRO_FILE%" > "%INTRO_AUDCHECK%" 2>nul

set "INTRO_HASAUDIO="
if exist "%INTRO_AUDCHECK%" (
    for %%Z in ("%INTRO_AUDCHECK%") do (
        if %%~zZ GTR 0 set "INTRO_HASAUDIO=YES"
    )
)
del "%INTRO_AUDCHECK%" 2>nul

REM Define Concatenation Filter Chains
set "V_INTRO=[0:v:0]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1,fps=30[v0]"
set "V_MAIN=[1:v:0]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1,fps=30[v1]"

if defined INTRO_HASAUDIO (
    set "A_INTRO=[0:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a0]"
) else (
    set "A_INTRO=anullsrc=channel_layout=stereo:sample_rate=44100[a0]"
)

if defined HASAUDIO (
    set "A_MAIN=[1:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a1]"
) else (
    set "A_MAIN=anullsrc=channel_layout=stereo:sample_rate=44100[a1]"
)

set "JOIN_CHAIN=%V_INTRO%;%A_INTRO%;%V_MAIN%;%A_MAIN%;[v0][a0][v1][a1]concat=n=2:v=1:a=1[vout][aout]"

REM ----------------------------------------------------------
REM ENCODING (QSV Hardware Mode / CPU Fallback)
REM ----------------------------------------------------------

"%FFMPEG%" -hide_banner -loglevel error -stats -y -threads 0 -i "%INTRO_FILE%" -i "%SOURCE%" -filter_complex "%JOIN_CHAIN%" -map "[vout]" -map "[aout]" -c:v h264_qsv -global_quality 20 -preset faster -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "%DEST%"

set "RESULT=%ERRORLEVEL%"

REM Fallback to Ultrafast CPU Mode if QSV fails
if not "%RESULT%"=="0" (
    echo [NOTICE] QSV Hardware encoding not active. Switching to Ultrafast CPU Mode...

    "%FFMPEG%" -hide_banner -loglevel error -stats -y -threads 0 -i "%INTRO_FILE%" -i "%SOURCE%" -filter_complex "%JOIN_CHAIN%" -map "[vout]" -map "[aout]" -c:v libx264 -preset ultrafast -crf 20 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "%DEST%"
    
    set "RESULT=%ERRORLEVEL%"
)

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