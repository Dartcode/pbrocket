;===================================================================;
; Name:      PBRocket.pbi
; Purpose:   A sync-tracker, a tool for synchronizing music and 
;            visuals in demoscene productions
; Author:    Den (Denis Castellan - den@majorden.com)
;            https://bitbucket.org/Lush/pbrocket/
; Copyright: (C) 2014 Denis Castellan
;            Ported from GNU Rocket (C) Erik Faye-Lund and Egbert Teeselink
;            https://github.com/kusma/rocket
; License:   See accompanying COPYING file
;===================================================================;
; Usage:
;
; Set this constant in your source file before including PBRocket.pbi:
;
; #RKT_SYNC_PLAYER   -   Switch PBRocket mode. 0 = edit mode, 1 = player mode.
;                        No default, you need to set it or PB Compiler will complain ;)
;
;
; You can also set those constants to change PBRocket's behaviour:
;
; #RKT_INCBIN        -   IncludeBinary track files, default is 0 (load track from disk)
;                        Set to true (1) if you want to IncludeBinary the tracks.
;
; #RKT_ASSERT        -   Enable RKTAssert() macro in non-debug builds, default is false (0)
;                        RKTAssert() will use Debug output in debug mode, a MsgRequester otherwise.
;                        (Normally only used when modifying PBRocket itself)
;                        Feel free to re-use RKTAssert() in your own programs.
;
; #RKT_BUFFER_SIZE   -   Buffer size for incoming network data from Sync Editor.
;                        Default is 51200 (50KB). Increase size If prog crashes :)
;
;===================================================================;
; you can comment out this block if you already InitNetwork() somewhere else.
; It shouldn't hurt to leave it as it is though.

CompilerIf Not #RKT_SYNC_PLAYER
  InitNetwork()
CompilerEndIf

;===================================================================;
;        you shouldn't need to modify anything below this line
;                but feel free to do so if you wish.
;===================================================================;

CompilerIf Not Defined(RKT_SYNC_PLAYER, #PB_Constant) : #RKT_SYNC_PLAYER = 0     : CompilerEndIf
CompilerIf Not Defined(RKT_INCBIN, #PB_Constant)      : #RKT_INCBIN = 0          : CompilerEndIf
CompilerIf Not Defined(RKT_BUFFER_SIZE, #PB_Constant) : #RKT_BUFFER_SIZE = 51200 : CompilerEndIf
CompilerIf Not Defined(RKT_ASSERT, #PB_Constant)      : #RKT_ASSERT = 0          : CompilerEndIf

CompilerIf Not #RKT_SYNC_PLAYER
  
  ; Constants needed by PBRocket device in edit mode
  ; Don't change them or you won't ever, ever connect to editor again
  #RKT_EDITOR_GREETING = "hello, demo!"
  #RKT_DEMO_GREETING = "hello, synctracker!"
  
  ; values of the commands sent by sync_editor
  Enumeration
    #RKT_NONE = -1
    #RKT_SET_KEY
    #RKT_DELETE_KEY
    #RKT_GET_TRACK
    #RKT_SET_ROW
    #RKT_PAUSE
    #RKT_SAVE_TRACKS
    #RKT_HANDSHAKE = 104
  EndEnumeration
CompilerEndIf

; values of the different interpolation modes
Enumeration
  #KEY_STEP
  #KEY_LINEAR
  #KEY_SMOOTH
  #KEY_RAMP
  #KEY_TYPE_COUNT
EndEnumeration

;-
;- MACROS
;-

Macro DQuote
  "
EndMacro

; custom Assert macro so it can be used in non-debug builds
Macro RKTAssert(Expression)
  CompilerIf #PB_Compiler_Debugger
    If Not Expression
      Debug "Assertion failed: " + DQuote#Expression#DQuote
      Debug "File: " + #PB_Compiler_Filename
      Debug "Procedure: " + #PB_Compiler_Procedure
      Debug "Line: " + #PB_Compiler_Line
      End
    EndIf
  CompilerElseIf #RKT_ASSERT
    If Not expression
      MessageRequester("Assertion failed!", "Expression: " + DQuote#Expression#DQuote + #CRLF$ +
                                            "File: " + #PB_Compiler_Filename + #CRLF$ +
                                            "Procedure: " + #PB_Compiler_Procedure + #CRLF$ + 
                                            "Line: " + #PB_Compiler_Line)
      End
    EndIf
  CompilerEndIf
EndMacro

;-
;-   STRUCTURES
;-

;- Structure long_to_float
Structure long_to_float
  StructureUnion
    long.l
    float.f
  EndStructureUnion
EndStructure

;- Structure track_key
Structure track_key
  row.i
  value.f
  type.i
EndStructure

;- Structure sync_track
Structure sync_track
  *keys.track_key
  num_keys.i
  name.s
EndStructure

;- Structure ptrs (provides an indexing mechanism)
Structure ptrs
  ptr.l[0]
EndStructure

;- Structure sync_data
Structure sync_data
  *tracks.ptrs
  num_tracks.i
EndStructure

;- Structure sync_device
Structure sync_device
  base.s
  *sdata.sync_data
  render.i
  CompilerIf Not #RKT_SYNC_PLAYER
    row.i
    starttime.l
    delay.l
    *connection
    *outBuffer
    *inBuffer
    isConnected.i
  CompilerEndIf
EndStructure

;- Structure audio_cb
Structure audio_cb
  stream.i
  bpm.d
  rpb.i
  rowrate.d
  ;  init.i
  isPlaying.i
EndStructure

;-
;-   HELPER PROCEDURES
;-

; to convert "network big-endian" longs to little-endian
Procedure.i SwapEndian(v.l)
  !MOV EAX,DWORD[p.v_v]
  !BSWAP EAX
  ProcedureReturn
EndProcedure

;-
;-   AUDIO_CB PROCEDURES
;-
; if you want to use a different audio lib,
; you'll need to modify these audio_cb procedures

Procedure.d RKT_audio_get_row(*this.audio_cb)
  Protected pos.d = GetSoundPosition(*this\stream, #PB_Sound_Millisecond)
  
  CompilerIf #RKT_SYNC_PLAYER
    ProcedureReturn (pos * *this\rowrate) * 0.001
  CompilerElse
    ; + 0.05 => just a little rounding to match exact editor position
    ProcedureReturn (pos * *this\rowrate) * 0.001 + 0.05
  CompilerEndIf
EndProcedure

Procedure RKT_audio_set_row(*this.audio_cb, row.i)
  Protected pos.l = (row / *this\rowrate) * GetSoundFrequency(*this\stream)
  
  SetSoundPosition(*this\stream, pos, #PB_Sound_Frame)
EndProcedure

Procedure RKT_audio_pause(*this.audio_cb, flag.i)
  If flag
    *this\isPlaying = #False 
    PauseSound(*this\stream)
  Else 
    *this\isPlaying = #True 
    ResumeSound(*this\stream) 
  EndIf
EndProcedure

Procedure RKT_audio_rows(*this.audio_cb)
  ProcedureReturn Round(SoundLength(*this\stream, #PB_Sound_Millisecond) * 0.001, #PB_Round_Up) * *this\rowrate
EndProcedure

Procedure RKT_audio_is_playing(*this.audio_cb)
  ProcedureReturn *this\isPlaying
EndProcedure



; audio_cb device constructor
Procedure RKT_create_audiocb(*audcb.audio_cb, stream.i, bpm.d, rpb.i)
  *audcb\stream = stream
  *audcb\bpm = bpm
  *audcb\rpb = rpb
  *audcb\rowrate = (bpm / 60) * rpb
  *audcb\isPlaying = #False
  ProcedureReturn *audcb
EndProcedure

;-
;-   KEYS PROCEDURES
;-

Procedure.d RKT_key_linear(*lokey.track_key, row.d)
  Protected *hikey.track_key = *lokey + SizeOf(track_key)
  Protected t.d = (row - *lokey\row) / (*hikey\row - *lokey\row)
  
  ProcedureReturn *lokey\value + (*hikey\value - *lokey\value) * t
EndProcedure

Procedure.d RKT_key_smooth(*lokey.track_key, row.d)
  Protected *hikey.track_key = *lokey + SizeOf(track_key)
  Protected t.d = (row - *lokey\row) / (*hikey\row - *lokey\row)
  
  t = t * t * (3 - 2 * t);
  ProcedureReturn *lokey\value + (*hikey\value - *lokey\value) * t
EndProcedure

Procedure.d RKT_key_ramp(*lokey.track_key, row.d)
  Protected *hikey.track_key = *lokey + SizeOf(track_key)
  Protected t.d = (row - *lokey\row) / (*hikey\row - *lokey\row)
  
  t = t * t
  ProcedureReturn *lokey\value + (*hikey\value - *lokey\value) * t
EndProcedure

Procedure.i RKT_find_key(*t.sync_track, pos.i)
  Protected.i mi, lo = 0, hi = *t\num_keys
  Protected *tmp.track_key
  
  While lo < hi
    mi = (lo + hi) / 2
    *tmp = *t\keys + SizeOf(track_key) * mi
    RKTAssert(mi <> hi)
    
    If *tmp\row < pos : lo = mi + 1
    ElseIf *tmp\row > pos : hi = mi
    Else : ProcedureReturn mi
    EndIf
  Wend
  RKTAssert(lo = hi)
  
  ProcedureReturn -lo - 1
EndProcedure

Procedure.i RKT_key_idx_floor(*t.sync_track, row.i)
  Protected idx.i = RKT_find_key(*t, row)
  
  If idx < 0
		idx = - idx - 2;
	EndIf
	 
  ProcedureReturn idx
EndProcedure

Procedure.d RKT_get_val(*t.sync_track, row.d)
  Protected.i idx, irow, *tmp.track_key
  
  ; if we have no keys at all, return a constant 0
  If *t\num_keys <= 0 : ProcedureReturn 0 : EndIf
  
  irow = Int(row)
  idx = RKT_key_idx_floor(*t, irow)
  
  ; at the edges, Return the first/last value
  If idx < 0 : ProcedureReturn *t\keys\value : EndIf
  If idx > *t\num_keys - 2  
    *tmp = *t\keys + SizeOf(track_key) * (*t\num_keys - 1)
    ProcedureReturn *tmp\value
  EndIf
  
  ; interpolate according to key-type
  *tmp = *t\keys + SizeOf(track_key) * (idx)
  Select *tmp\type
    Case #KEY_STEP   : ProcedureReturn *tmp\value
    Case #KEY_LINEAR : ProcedureReturn RKT_key_linear(*tmp, row)
    Case #KEY_SMOOTH : ProcedureReturn RKT_key_smooth(*tmp, row)
    Case #KEY_RAMP   : ProcedureReturn RKT_key_ramp(*tmp, row)
    Default          : ProcedureReturn 0
  EndSelect
EndProcedure

CompilerIf Not #RKT_SYNC_PLAYER
  
  Procedure RKT_del_key(*t.sync_track, pos.i)
    Protected.i i, idx.i, *tmp
    
    idx = RKT_find_key(*t, pos)
    RKTAssert(idx >= 0)
    
    MoveMemory(*t\keys + SizeOf(track_key) * (idx+1), *t\keys + SizeOf(track_key) * idx, SizeOf(track_key) * (*t\num_keys - idx -1))
    If *t\num_keys > 1
      *tmp = ReAllocateMemory(*t\keys, SizeOf(track_key) * (*t\num_keys - 1))
      RKTAssert(*tmp)
      *t\keys = *tmp
      *t\num_keys -1    
    Else
      FreeMemory(*t\keys)
      *t\keys = #Null
      *t\num_keys = 0   
    EndIf
 
  EndProcedure
  
  Procedure RKT_handle_del_key(*d.sync_data, *buffer)
    Protected.i track, index
    
    track = SwapEndian(PeekL(*buffer))
    RKTAssert(track < *d\num_tracks)
    
    index = SwapEndian(PeekL(*buffer+4))
    RKT_del_key(*d\tracks\ptr[track], index)      
  EndProcedure
  
  Procedure RKT_set_key(*t.sync_track, *key.track_key)
    Protected.i i, idx, *tmp.track_key
    
    idx = RKT_find_key(*t, *key\row)
    
    If idx < 0
      idx = -idx - 1
      
      *tmp = ReAllocateMemory(*t\keys, SizeOf(track_key) * (*t\num_keys+1))
      RKTAssert(*tmp)
      
      *t\keys = *tmp
      MoveMemory(*t\keys + SizeOf(track_key) * idx, *t\keys + SizeOf(track_key) * (idx+1), SizeOf(track_key) * (*t\num_keys - idx))
      *t\num_keys + 1
    EndIf
    
    *tmp       = *t\keys + SizeOf(track_key) * idx
    *tmp\row   = *key\row
    *tmp\value = *key\value
    *tmp\type  = *key\type
  EndProcedure
  
  Procedure RKT_handle_set_key(*d.sync_data, *buffer)
    Protected track.i, index.i, value.long_to_float, type.b, key.track_key
    
    track      = SwapEndian(PeekL(*buffer))
    RKTAssert(track < *d\num_tracks)
    
    index      = SwapEndian(PeekL(*buffer+4))
    value\long = SwapEndian(PeekL(*buffer+8))
    type       = PeekB(*buffer+12)
    
    key\row   = index
    key\value = value\float
    key\type  = type
    
    RKT_set_key(*d\tracks\ptr[track], key)      
  EndProcedure
  
CompilerEndIf

;-
;- TRACKS PROCEDURES
;-

Procedure.s RKT_track_path(base.s, name.s)
  Protected path.s = base + "_" + name + ".track"
  
  ProcedureReturn path
EndProcedure

CompilerIf Not #RKT_SYNC_PLAYER
  
  Procedure.i RKT_save_track(*t.sync_track, path.s)
    Protected i.i, file.i, *k.track_key
    
    file = CreateFile(#PB_Any, path)
    RKTAssert(file)
    
    WriteQuad(file, *t\num_keys)
    
    For i = 0 To *t\num_keys -1
      *k = *t\keys + SizeOf(track_key) * i
      WriteInteger(file, *k\row)
      WriteFloat(file, *k\value)
      WriteAsciiCharacter(file, *k\type)
    Next
    
    CloseFile(file)
    
    ProcedureReturn 0    
  EndProcedure
  
  
  Procedure RKT_save_tracks(*d.sync_device)
    Protected i.i, *tmp.sync_track
    
    For i = 0 To *d\sdata\num_tracks -1
      *tmp = *d\sdata\tracks\ptr[i]
      RKT_save_track(*tmp, RKT_track_path(*d\base, *tmp\name))
    Next
  EndProcedure
  
  ; get track data from sync_editor
  Procedure RKT_get_track_data(*this.sync_device, *t.sync_track)
    Protected namelength.i = Len(*t\name)
    
    PokeB(*this\outBuffer,#RKT_GET_TRACK)
    SendNetworkData(*this\connection, *this\outBuffer,1)
    PokeL(*this\outBuffer,SwapEndian(namelength))
    SendNetworkData(*this\connection, *this\outBuffer,4)
    SendNetworkString(*this\connection,*t\name, #PB_Ascii)
  EndProcedure
  
CompilerElse
  
  CompilerIf Not #RKT_INCBIN
    
    ; get track data from file
    Procedure RKT_get_track_data(*this.sync_device, *t.sync_track)
      Protected i.i, file.i, *tmp, *k.track_key
      
      file = ReadFile(#PB_Any, RKT_track_path(*this\base, *t\name))
      RKTAssert(file)      
      
      *t\num_keys = ReadQuad(file)
      *tmp = ReAllocateMemory(*t\keys, SizeOf(track_key) * (*t\num_keys))
      RKTAssert(*tmp)
      
      *t\keys = *tmp
      For i = 0 To *t\num_keys -1
        *k = *t\keys + SizeOf(track_key) * i
        *k\row = ReadInteger(file)
        *k\value = ReadFloat(file)
        *k\type = ReadAsciiCharacter(file)
      Next
      
      CloseFile(file)
    EndProcedure
    
  CompilerElse
    
    ; get track data from DataSection
    Procedure RKT_get_track_data(*this.sync_device, *t.sync_track)
      Protected i.i, *k.track_key, *tmp
      
      Read.q *t\num_keys
      *tmp = ReAllocateMemory(*t\keys, SizeOf(track_key) * (*t\num_keys))
      RKTAssert(*tmp)
      
      *t\keys = *tmp
      For i = 0 To *t\num_keys -1
        *k = *t\keys + SizeOf(track_key) * i
        Read.i *k\row
        Read.f *k\value
        Read.a *k\type
      Next
    EndProcedure
    
  CompilerEndIf
  
CompilerEndIf

Procedure.i RKT_find_track(*sd.sync_data, name.s)
  Protected i.i, *t, *tmp.sync_track
  
  For i = 0 To *sd\num_tracks -1
    *tmp = *sd\tracks\ptr[i]
    If name = *tmp\name
      ProcedureReturn i
    EndIf
  Next
  
  ProcedureReturn -1
EndProcedure

Procedure.i RKT_create_track(*sd.sync_data, name.s)
  Protected ft.i, *t.sync_track, *tmp
  
  ft = RKT_find_track(*sd, name)
  RKTAssert(ft < 0)
  
  *t = AllocateMemory(SizeOf(sync_track))
  RKTAssert(*t)
  
  *t\name = name
  *t\keys = #Null
  *t\num_keys = 0
  
  *tmp = ReAllocateMemory(*sd\tracks, SizeOf(Integer) * (*sd\num_tracks +1))
  RKTAssert(*tmp)
  
  *sd\tracks = *tmp
  *sd\tracks\ptr[*sd\num_tracks] = *t  
  *sd\num_tracks +1 
  
  ProcedureReturn *sd\num_tracks -1  
EndProcedure

Procedure RKT_get_track(*d.sync_device, name.s)
  Protected idx.i = RKT_find_track(*d\sdata, name)
  
  RKTAssert(Len(name) > 0)
  
  If idx >= 0
    ProcedureReturn *d\sdata\tracks\ptr[idx]
  EndIf
  
  idx = RKT_create_track(*d\sdata, name)
  RKT_get_track_data(*d, *d\sdata\tracks\ptr[idx])
  
  ProcedureReturn *d\sdata\tracks\ptr[idx]
EndProcedure

;-
;- SYNC DEVICE PROCEDURES
;-

CompilerIf Not #RKT_SYNC_PLAYER
  
  Procedure.i RKT_update(*this.sync_device, row.i, *cb.audio_cb)
    Protected NetEvent, MsgLength, msec.l
    Static CurrentCommand.i = -1, InWritePtr = 0, InReadPtr = 0
    
    NetEvent = NetworkClientEvent(*this\connection)
    
    If NetEvent
      Select NetEvent
        Case #PB_NetworkEvent_Data
          MsgLength = ReceiveNetworkData(*this\connection, *this\inBuffer + InWritePtr, #RKT_BUFFER_SIZE)
          InWritePtr + MsgLength
        Case #PB_NetworkEvent_Disconnect
          *this\connection = #False
          *this\isConnected = #False
          End
      EndSelect
    EndIf
    
    If Not *this\render
      msec = ElapsedMilliseconds()
      If msec - *this\delay > *this\starttime
        *this\render = #True
      EndIf
    EndIf
    
    ; NO COMMAND
    If CurrentCommand = #RKT_NONE And (InWritePtr - InReadPtr > 0)
      CurrentCommand = PeekA(*this\inBuffer + InReadPtr) : InReadPtr + 1
    EndIf
    
    
    ; HANDSHAKE
    If CurrentCommand = #RKT_HANDSHAKE And (InWritePtr - InReadPtr >= Len(#RKT_EDITOR_GREETING) -1)
      *this\isConnected = #True
      InReadPtr + Len(#RKT_EDITOR_GREETING) -1 : CurrentCommand = #RKT_NONE
      
      ; SET KEY
    ElseIf CurrentCommand = #RKT_SET_KEY And (InWritePtr - InReadPtr > 12)
      RKT_handle_set_key(*this\sdata, *this\inBuffer+InReadPtr)
      InReadPtr + 13 : CurrentCommand = #RKT_NONE
      
      ; DELETE KEY
    ElseIf CurrentCommand = #RKT_DELETE_KEY And (InWritePtr - InReadPtr > 7)
      RKT_handle_del_key(*this\sdata, *this\inBuffer+InReadPtr)
      InReadPtr + 8 : CurrentCommand = #RKT_NONE
      
      ; SET ROW
    ElseIf CurrentCommand = #RKT_SET_ROW And (InWritePtr - InReadPtr > 3)
      If *cb : RKT_audio_set_row(*cb, SwapEndian(PeekL(*this\inBuffer+InReadPtr))) : EndIf
      InReadPtr + 4 : CurrentCommand = #RKT_NONE
      
      ; PAUSE
    ElseIf CurrentCommand = #RKT_PAUSE And (InWritePtr - InReadPtr > 0)
      If *cb : RKT_audio_pause(*cb, PeekB(*this\inBuffer+InReadPtr)) : EndIf 
      InReadPtr + 1 : CurrentCommand = #RKT_NONE
      
      ; SAVE TRACKS
    ElseIf CurrentCommand = #RKT_SAVE_TRACKS
      RKT_save_tracks(*this)
      CurrentCommand = #RKT_NONE
      
    EndIf 
    
    If InReadPtr = InWritePtr And *this\isConnected = 1
      InReadPtr = 0
      InWritePtr = 0
    EndIf
    
    If *cb
      If RKT_audio_is_playing(*cb) And row > -1
        If *this\row <> row
          PokeB(*this\outBuffer,#RKT_SET_ROW)
          SendNetworkData(*this\connection,*this\outBuffer,1)
          PokeL(*this\outBuffer,SwapEndian(row))
          SendNetworkData(*this\connection,*this\outBuffer,4)
          *this\row = row
        EndIf
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure RKT_connect(*this.sync_device)
    Protected loop.i = 0
    
    *this\connection = OpenNetworkConnection("localhost", 1338, #PB_Network_TCP, 1000)
    
    If *this\connection
      *this\outBuffer = AllocateMemory(1000)
      *this\inBuffer = AllocateMemory(#RKT_BUFFER_SIZE)
      SendNetworkString(*this\connection, #RKT_DEMO_GREETING, #PB_Ascii)
      
      Repeat
        RKT_update(*this, -1, 0) : Delay(1) : loop +1
        If *this\isConnected : ProcedureReturn : EndIf
      Until loop = 5000  ; wait ~5 sec max for handshake
    EndIf
    
    MessageRequester("PB Rocket", "Couldn't connect to Rocket Editor!")
    
    End
    
  EndProcedure
  
CompilerEndIf

Procedure RKT_create_device(*syncdev.sync_device, base.s = "sync", delay.i = 1000)
  
  *syncdev\base = base
  *syncdev\sdata = AllocateMemory(SizeOf(sync_data))
  If Not *syncdev\sdata : End : EndIf
  *syncdev\sdata\tracks = #Null
  *syncdev\sdata\num_tracks = 0
  CompilerIf #RKT_SYNC_PLAYER
    *syncdev\render = #True
  CompilerElse
    *syncdev\row = -1
    *syncdev\render = #False
    *syncdev\starttime = ElapsedMilliseconds()
    *syncdev\delay = delay
    *syncdev\isConnected = #False
    RKT_connect(*syncdev)
  CompilerEndIf
  
  ProcedureReturn *syncdev  
EndProcedure

Procedure RKT_data_deinit(*d.sync_data)
  Define i.i, *tmp.sync_track
  
  For i = 0 To *d\num_tracks -1
    *tmp = *d\tracks\ptr[i]
    If *tmp\keys
      FreeMemory(*tmp\keys)
      FreeMemory(*tmp)
    EndIf
  Next
  
  If *d\tracks
    FreeMemory(*d\tracks)
  EndIf
EndProcedure

Procedure RKT_free_device(*this.sync_device)
  
  RKT_data_deinit(*this\sdata)
  FreeMemory(*this\sdata)
  CompilerIf Not #RKT_SYNC_PLAYER
    FreeMemory(*this\inBuffer)
    FreeMemory(*this\outBuffer)
    If *this\isConnected
      CloseNetworkConnection(*this\connection)
    EndIf
  CompilerEndIf
  ClearStructure(*this, sync_device)
EndProcedure

; IDE Options = PureBasic 5.21 LTS (Windows - x86)
; CursorPosition = 473
; FirstLine = 283
; Folding = ------
; EnableXP
; CompileSourceDirectory
; EnablePurifier