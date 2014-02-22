EnableExplicit ; you shouldn't do without. Really.
UsePNGImageDecoder()

; First some window stuff
Global WinEvent, Done = #False, StartTime.l
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

; You're obviously going to use some audio so
InitSound()
UseOGGSoundDecoder()

; Define PBRocket's operating mode.
#RKT_SYNC_PLAYER = 0  ; 0 = Edit mode, 1 = Player mode
#RKT_INCBIN = 0       ; Set to true (1) if you want to IncludeBinary the tracks (irrelevant in Edit mode)

; If we want to IncludeBinary the exported track files,
; make sure data is read from the right place
CompilerIf #RKT_INCBIN
  Restore RKT_tracks
CompilerEndIf

; Include the magical stuff
XIncludeFile "../include/PBRocket.pbi"

; Load the audio file. if you "IncludeBinary" the track files,
; you'll probably want to "CatchSound" instead.
Define audiosound = LoadSound(#PB_Any, "demotrack.ogg")
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
RKT_create_device(rocket, "demo", 200)

; Define a variable that will hold the current row numer
; (row numbers are interpolated so we need fractional values)
Define current_row.d

; Create/retrieve tracks and keys
Define *starsSpeed.sync_track = RKT_get_track(rocket, "starsSpeed")  
Define *starsRot.sync_track   = RKT_get_track(rocket, "starsRot")
Define *starsJump.sync_track  = RKT_get_track(rocket, "starsJump")
Define *logoShow.sync_track   = RKT_get_track(rocket, "logoShow")

; Define some variables to hold the row value of each track
Global.d stars_speed, stars_angle, stars_jump, logo_show

CompilerIf Not #RKT_SYNC_PLAYER
  ; In edit mode, PBRocket loads tracks/keys in the main loop
  ; This is done to give it some time because FlipBuffers() slows the process
  rocket\starttime = ElapsedMilliseconds()
CompilerEndIf

; Let's rock and loop
PlaySound(audiosound, #PB_Sound_Loop)

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

; The party's over, now clean up the place:
; Release all allocated memory and destroy device
RKT_free_device(rocket)

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
; CursorPosition = 43
; FirstLine = 24
; Folding = -
; EnableUnicode
; EnableXP
; Executable = C:\Users\Den64\Desktop\pbrocket_demo\demo_noeditor.exe
; DisableDebugger
; CompileSourceDirectory