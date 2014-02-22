EnableExplicit ; you shouldn't do without. Really.
UsePNGImageDecoder()

; First some window stuff
Define WinEvent, Done = #False, StartTime.l
Global ViewPortWidth = 640, ViewPortHeight = 480
Global znear.f = 1, zfar.f = 1000, focalLength.f = 45


; the "demo" stuff
XIncludeFile "starfield.pbi"
Global RocketLogo = LoadImage(#PB_Any, "logo.png")
Define logoX.i = (ViewPortWidth - ImageWidth(RocketLogo))/2
Define logoY.i = (ViewPortHeight - ImageHeight(RocketLogo))/2

#MyWindow = 0

Procedure myWinOpen()
  Protected Flags = #PB_Window_ScreenCentered|#PB_Window_SystemMenu|#PB_Window_TitleBar|#PB_Window_SizeGadget
  
  If OpenWindow(#MyWindow, 0, 0, ViewPortWidth, ViewPortHeight, "PBRocket Demo", Flags )
    InitSprite()
    Define myScreen = OpenWindowedScreen(WindowID(#MyWindow), 0, 0, ViewPortWidth, ViewPortHeight, #True, 0, 0, #PB_Screen_NoSynchronization)
    SetFrameRate(100)    
    AddKeyboardShortcut(#MyWindow, #PB_Shortcut_F2, 12)
    AddKeyboardShortcut(#MyWindow, #PB_Shortcut_F3, 13)
    ProcedureReturn #True
  Else
    ProcedureReturn #False
  EndIf
EndProcedure

If Not myWinOpen() : End : EndIf

InitStars()

; Now the interesting part

; Let's load BASS
XIncludeFile "bass.pbi"
BASS_Init(-1, 44100, 0, WindowID(#MyWindow), 0)

; Define PBRocket's operating mode.
#RKT_SYNC_PLAYER = 0  ; 0 = Edit mode, 1 = Player mode
#RKT_INCBIN = 0       ; Set to true (1) if you want to IncludeBinary the tracks (irrelevant in Edit mode)

; If we want to IncludeBinary the exported track files,
; make sure data is read from the right place
CompilerIf #RKT_INCBIN
  Restore RKT_tracks
CompilerEndIf

; Include the magical stuff
XIncludeFile "../include/PBRocket_BASS.pbi"

; Load the audio file. if you "IncludeBinary" the track files,
; you'll probably want to IncludeBinary the audio file too.
Define audiofile.s = "demotrack.ogg"
Define audiosound.i = BASS_StreamCreateFile(0, @audiofile, 0, 0, #BASS_STREAM_PRESCAN|#BASS_MP3_SETPOS|#BASS_SAMPLE_LOOP)
If Not audiosound
  MessageRequester("Oops", "Audio file not found")
  End
EndIf

; Set the BPM (beats per minute) and RPB (rows per beat)
Define bpm.d = 148.0, rpb.i = 6 

; Define sync device and audio-callback device structures
Define rocket.sync_device, audiocb.audio_cb

; Create the audio-callback and sync devices
RKT_create_audiocb(audiocb, audiosound, bpm, rpb)
RKT_create_device(rocket, "demo")

; Define a variable that will hold the current row numer
; (row numbers are interpolated so we need fractional values)
Define current_row.d

; Create/retrieve tracks and keys
Define *starsSpeed.sync_track = RKT_get_track(rocket, "starsSpeed")  
Define *starsRot.sync_track   = RKT_get_track(rocket, "starsRot")
Define *starsJump.sync_track   = RKT_get_track(rocket, "starsJump")
Define *logoShow.sync_track   = RKT_get_track(rocket, "logoShow")

; Define some variables to hold the row value of each track
Global.d stars_speed, stars_angle, stars_jump, logo_show

CompilerIf Not #RKT_SYNC_PLAYER
  ; In edit mode, PBRocket loads tracks/keys in the main loop
  ; This is done to give it some time because FlipBuffers() slows the process
  rocket\starttime = ElapsedMilliseconds()
CompilerEndIf

; Let's rock and loop
BASS_ChannelPlay(audiosound, #False);

; This will be used inside the main loop for FPS stuff
StartTime = ElapsedMilliseconds()

Repeat
  
  ; Get current row
  current_row = RKT_audio_get_row(audiocb)
  
  ; Update editor if in edit mode
  CompilerIf Not #RKT_SYNC_PLAYER
    RKT_update(rocket, current_row, audiocb)
  CompilerEndIf
  
  ; If initial delay is over
  If rocket\render 
    
    ; Get current key value for your track variables
    stars_speed = RKT_get_val(*starsSpeed, current_row)
    stars_angle = RKT_get_val(*starsRot, current_row)
    stars_jump = RKT_get_val(*starsJump, current_row)
    logo_show = RKT_get_val(*logoShow, current_row)    
    
    ; Quick workaround so flipbuffers() won't block our loop too often
    If ElapsedMilliseconds() - StartTime > (1000 / 60)
      ; Render stuff
      ClearScreen($0)
      StartDrawing(ScreenOutput())
      DrawingMode(#PB_2DDrawing_AlphaBlend)
      DisplayStars(stars_speed, stars_angle, stars_jump)
      If logo_show 
        DrawAlphaImage(ImageID(RocketLogo), logoX, logoY)
      EndIf
      StopDrawing()
      FlipBuffers()
      StartTime = ElapsedMilliseconds()
    EndIf    
    
  EndIf
  
  CompilerIf #RKT_SYNC_PLAYER
    ; Exit the loop if tune has finished playing
    ; (and #BASS_SAMPLE_LOOP wasn't set)
    If BASS_ChannelIsActive(audiosound) = #BASS_ACTIVE_STOPPED
      Done = #True
    EndIf
  CompilerEndIf
  
  ; Check for window events
  WinEvent = WindowEvent()
  If WinEvent
    Select WinEvent
      Case #PB_Event_CloseWindow : Done = 1
    EndSelect
  Else
    Delay(1)    
  EndIf

Until Done ; + "Or SoundStatus(audiosound) = #PB_Sound_Stopped" if you don't loop the audio

If audiosound
  BASS_StreamFree(audiosound)
  BASS_Free()
EndIf

; The party's over, now clean up the place:
; Release all allocated memory and destroy device
RKT_free_device(rocket)

DataSection
  AudioStart:
  IncludeBinary "demotrack.ogg"
  AudioEnd:
EndDataSection

CompilerIf #RKT_INCBIN
  ; If we choose to include the tracks in the final exe
  ; we need to add them here, in the very exact same order they were defined 
  
  DataSection
    RKT_tracks:
    IncludeBinary "demo_starsSpeed.track"
    IncludeBinary "demo_starsRot.track"
    IncludeBinary "demo_starsJump.track"
    IncludeBinary "demo_logoShow.track"
  EndDataSection
CompilerEndIf


; IDE Options = PureBasic 5.21 LTS (Windows - x86)
; CursorPosition = 44
; FirstLine = 24
; Folding = -
; EnableXP
; Executable = ..\test_editor.exe
; CompileSourceDirectory