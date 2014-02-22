;-
;- CONSTANTS
;-

CompilerIf Not Defined(RKT_SYNC_PLAYER, #PB_Constant) : #RKT_SYNC_PLAYER = 0     : CompilerEndIf
CompilerIf Not Defined(RKT_INCBIN, #PB_Constant)      : #RKT_INCBIN = 0          : CompilerEndIf
CompilerIf Not Defined(RKT_BUFFER_IN, #PB_Constant) : #RKT_BUFFER_IN = 51200     : CompilerEndIf
CompilerIf Not Defined(RKT_BUFFER_OUT, #PB_Constant) : #RKT_BUFFER_OUT = 51200   : CompilerEndIf
CompilerIf Not Defined(RKT_ASSERT, #PB_Constant)      : #RKT_ASSERT = 0          : CompilerEndIf

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
  #RKT_GET_TRACK_NAME
  #RKT_HANDSHAKE = 104
EndEnumeration

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
  value.d
  type.i
EndStructure

;- Structure sync_track
Structure sync_track
  *keys.track_key
  num_keys.i
  name.s
  remote.i
EndStructure

;- Structure ptrs (provides an indexing mechanism)
Structure ptrs
  ptr.l[0]
EndStructure

;- Structure sync_data
Structure sync_data
  *tracks.ptrs
  num_tracks.i
  track_offset.i
  selected_track.i
  Array displaytracks.l(0)
EndStructure

;- Structure sync_device
Structure sync_device
  *sdata.sync_data
  *server
  *client
  *outBuffer
  *inBuffer
  current_row.i
  current_track.i
  isConnected.i
  isPlaying.i
  inputval.s
  isDirty.i
EndStructure

;- Structure bookmark
; Structure bookmark
; EndStructure

;-
;-   HELPER PROCEDURES
;-

; to convert "network big-endian" longs to little-endian
Procedure.i SwapEndian(v.l)
  !MOV EAX,DWORD[p.v_v]
  !BSWAP EAX
  ProcedureReturn
EndProcedure



Procedure RKT_set_row(*d.sync_device)
  If *d\isConnected
    PokeB(*d\outBuffer, #RKT_SET_ROW)
    SendNetworkData(*d\client, *d\outBuffer,1)
    PokeL(*d\outBuffer,SwapEndian(*d\current_row))
    SendNetworkData(*d\client, *d\outBuffer,4)
  EndIf
EndProcedure

Procedure RKT_pause(*d.sync_device, flag.i)
  If *d\isConnected
    PokeA(*d\outBuffer, #RKT_PAUSE)
    SendNetworkData(*d\client, *d\outBuffer,1)
    PokeA(*d\outBuffer, flag)
    SendNetworkData(*d\client, *d\outBuffer,1)
  EndIf
EndProcedure

; ; audio_cb device constructor
; Procedure RKT_create_audiocb(*audcb.audio_cb, stream.i, bpm.d, rpb.i)
;   *audcb\stream = stream
;   *audcb\bpm = bpm
;   *audcb\rpb = rpb
;   *audcb\rowrate = (bpm / 60) * rpb
;   *audcb\isPlaying = #True
;   ProcedureReturn *audcb
; EndProcedure

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
  
  If (idx < 0) : idx = -idx - 2 : EndIf
  ProcedureReturn idx
EndProcedure

Procedure.d RKT_get_val(*t.sync_track, row.d)
  Protected.i idx, irow, *tmp.track_key
  
  ; if we have no keys at all, return a constant 0
  If *t\num_keys <= 0 : ProcedureReturn 0 : EndIf
  
  irow = Int(row)
  idx = RKT_key_idx_floor(*t, irow)
  
  ; ; at the edges return the first/last value
  ; If idx < 0 : ProcedureReturn *t\keys\value : EndIf
  
  ; at the lower edge return 0, at the upper edge return the last value
  If idx < 0 : ProcedureReturn 0 : EndIf
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

Procedure RKT_send_del_key(*d.sync_device, *t.sync_track, idx.i)
  PokeB(*d\outBuffer,    #RKT_DELETE_KEY)
  PokeL(*d\outBuffer+1,  SwapEndian(*t\remote))
  PokeL(*d\outBuffer+5,  SwapEndian(idx))
  SendNetworkData(*d\client, *d\outBuffer, 9)  
EndProcedure

Procedure RKT_del_key(*d.sync_device, *tk.sync_track, row.i)
  Protected.i idx, *tmp ;, *tk.sync_track*ky.track_key, *tmp
  
  ;*tk.sync_track = *d\sdata\tracks\ptr[*d\sdata\displaytracks(*d\sdata\selected_track)]
  ;idx = RKT_find_key(*tk, *d\current_row)
  idx = RKT_find_key(*tk,row)
  
  If idx >= 0
    
    MoveMemory(*tk\keys + SizeOf(track_key) * (idx+1), 
               *tk\keys + SizeOf(track_key) * idx, 
               SizeOf(track_key) * (*tk\num_keys - idx -1))
    
    
    If *tk\num_keys > 1
      *tmp = ReAllocateMemory(*tk\keys, SizeOf(track_key) * (*tk\num_keys - 1))
      RKTAssert(*tmp)
      *tk\keys = *tmp
      *tk\num_keys -1    
    Else
      FreeMemory(*tk\keys)
      *tk\keys = #Null
      *tk\num_keys = 0   
    EndIf
    
    
    
    
;    RKTAssert(*tmp)
    
;     *tk\keys = *tmp      
;     *tk\num_keys -1    
    
    If *d\isConnected
      ;RKT_send_del_key(*d, *tk , *d\current_row)
      RKT_send_del_key(*d, *tk , row)
    EndIf
    
  EndIf  
EndProcedure

Procedure RKT_export_tracks(*d.sync_device)
  PokeB(*d\outBuffer,    #RKT_SAVE_TRACKS)
  SendNetworkData(*d\client, *d\outBuffer,1)
EndProcedure

Procedure RKT_send_key(*d.sync_device, *t.sync_track, *key.track_key)
  Protected value.long_to_float
  value\float = *key\value
  PokeB(*d\outBuffer,    #RKT_SET_KEY)
  PokeL(*d\outBuffer+1,  SwapEndian(*t\remote))
  PokeL(*d\outBuffer+5,  SwapEndian(*key\row))
  PokeL(*d\outBuffer+9,  SwapEndian(value\long))
  PokeB(*d\outBuffer+13, *key\type)
  SendNetworkData(*d\client, *d\outBuffer,14) 
EndProcedure

Procedure RKT_set_key(*d.sync_device, *t.sync_track, *key.track_key)
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
  
  If *d\isConnected And *t\remote > -1
    RKT_send_key(*d, *t, *key)
  EndIf
EndProcedure

Procedure RKT_handle_set_key(*sd.sync_device, *s.sync_data, *buffer)
  Protected track.i, index.i, value.long_to_float, type.b, key.track_key
  
  track      = SwapEndian(PeekL(*buffer))
  RKTAssert(track < *sd\sdata\num_tracks)
  
  index      = SwapEndian(PeekL(*buffer+4))
  value\long = SwapEndian(PeekL(*buffer+8))
  type       = PeekB(*buffer+12)
  
  key\row   = index
  key\value = value\float
  key\type  = type
  
  RKT_set_key(*sd, *sd\sdata\tracks\ptr[track], key)      
EndProcedure

Procedure RKT_set_type(*d.sync_device)
  Protected.i idx, *tk.sync_track, *ky.track_key
  
  *tk.sync_track = *d\sdata\tracks\ptr[*d\sdata\selected_track]
  
  idx = RKT_key_idx_floor(*tk, *d\current_row)
  
  If idx >= 0
    
    *ky       = *tk\keys + SizeOf(track_key) * idx
    *ky\type  = Mod(*ky\type + 1, 4)
    
    If *d\isConnected
      RKT_send_key(*d, *tk , *ky)
    EndIf
    
    *d\isDirty = #True
  EndIf  
EndProcedure

Procedure RKT_set_input(*d.sync_device)
  Protected.i idx, *tk.sync_track, *ky.track_key
  Protected key.track_key, type.i = 0
  
  *tk = *d\sdata\tracks\ptr[*d\sdata\displaytracks(*d\sdata\selected_track)]
  
  idx = RKT_find_key(*tk, *d\current_row)
  If idx >= 0
    *ky = *tk\keys + SizeOf(track_key) * idx
    type = *ky\type
  EndIf
    
  key\row = *d\current_row
  key\value = ValD(*d\inputval)
  key\type = type
  
  RKT_set_key(*d, *tk, key)
  ;If *d\isConnected
  ;  RKT_send_key(*d, *tk, key)
  ;EndIf
  *d\inputval = ""
  *d\isDirty = #True
EndProcedure
;-
;- TRACKS PROCEDURES
;-

; Procedure.s RKT_track_path(base.s, name.s)
;   Protected path.s = base + "_" + name + ".track"
;   
;   ProcedureReturn path
; EndProcedure
; 
; 
; Procedure.i RKT_save_track(*t.sync_track, path.s)
;   Protected i.i, file.i, *k.track_key
;   
;   file = CreateFile(#PB_Any, path)
;   RKTAssert(file)
;   
;   WriteQuad(file, *t\num_keys)
;   
;   For i = 0 To *t\num_keys -1
;     *k = *t\keys + SizeOf(track_key) * i
;     WriteInteger(file, *k\row)
;     WriteFloat(file, *k\value)
;     WriteAsciiCharacter(file, *k\type)
;   Next
;   
;   CloseFile(file)
;   
;   ProcedureReturn 0    
; EndProcedure
; 
; 
; Procedure RKT_save_tracks(*d.sync_device)
;   ;     Protected i.i, *tmp.sync_track
;   ;     
;   ;     For i = 0 To *d\sdata\num_tracks -1
;   ;       *tmp = *d\sdata\tracks\ptr[i]
;   ;       RKT_save_track(*tmp, RKT_track_path(*d\base, *tmp\name))
;   ;     Next
; EndProcedure


; send track data to demo
Procedure RKT_send_track_data(*d.sync_device, *t.sync_track)
  Protected i.i, *tmp_key.track_key, num_keys.i = *t\num_keys
  For i = 0 To num_keys -1
    *tmp_key = *t\keys + SizeOf(track_key) * i
    RKT_send_key(*d, *t, *tmp_key)
  Next
EndProcedure    

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
  *t\remote = -1
  
  *tmp = ReAllocateMemory(*sd\tracks, SizeOf(Integer) * (*sd\num_tracks +1))
  RKTAssert(*tmp)
  
  *sd\tracks = *tmp
  *sd\tracks\ptr[*sd\num_tracks] = *t  
  *sd\num_tracks +1 
  ReDim *sd\displaytracks(*sd\num_tracks)
  *sd\displaytracks(*sd\num_tracks) = *sd\num_tracks
  
  ProcedureReturn *sd\num_tracks -1  
EndProcedure

Procedure RKT_get_remote_track(*d.sync_device, name.s)
  Protected idx.i = RKT_find_track(*d\sdata, name), *track.sync_track
  RKTAssert(Len(name) > 0)
  
  If idx >= 0
    *track = *d\sdata\tracks\ptr[idx]
    *track\remote = *d\current_track
    *d\current_track +1
    RKT_send_track_data(*d, *d\sdata\tracks\ptr[idx])
  Else
    idx = RKT_create_track(*d\sdata, name)
    *track = *d\sdata\tracks\ptr[idx]
    *track\remote = *d\current_track
    *d\current_track +1
  EndIf
  PostEvent(#PBRE_EventRefresh)
  ProcedureReturn *track
EndProcedure

Procedure RKT_get_xml_track(*d.sync_device, name.s)
  Protected idx.i = RKT_find_track(*d\sdata, name), *track.sync_track
  RKTAssert(Len(name) > 0)
  
  If idx >= 0
    *track = *d\sdata\tracks\ptr[idx]
    RKT_send_track_data(*d, *d\sdata\tracks\ptr[idx])
  Else
    idx = RKT_create_track(*d\sdata, name)
    *track = *d\sdata\tracks\ptr[idx]
  EndIf
  PostEvent(#PBRE_EventRefresh)
  ProcedureReturn *d\sdata\tracks\ptr[idx]
EndProcedure

;-
;- SYNC DEVICE PROCEDURES
;-


Procedure.i RKT_update(*this.sync_device) ;, row.i, *cb.audio_cb)
  Protected NetEvent, ClientID, MsgLength, msec.l, TrackName.s, i.i
  Static CurrentCommand.i = -1, InWritePtr = 0, InReadPtr = 0, TrackNameLength = 0
  
  NetEvent = NetworkServerEvent()
  
  If NetEvent
    ClientID = EventClient()
    
    Select NetEvent
      Case #PB_NetworkEvent_Connect
        If *this\client = #Null
          *this\client = ClientID
          PostEvent(#PBRE_EventRefresh)
        Else
          CloseNetworkConnection(ClientID)
        EndIf
        
      Case #PB_NetworkEvent_Data
        MsgLength = ReceiveNetworkData(ClientID, *this\inBuffer + InWritePtr, #RKT_BUFFER_IN)
        InWritePtr + MsgLength
      Case #PB_NetworkEvent_Disconnect
        *this\isConnected = #False
        *this\client = #Null
        *this\current_track = 0
        *this\isPlaying = 0
        CurrentCommand = #RKT_NONE
        InWritePtr = 0 : InReadPtr = 0
        PostEvent(#PBRE_EventRefresh)
    EndSelect
  EndIf
  
  ; NO COMMAND
  If CurrentCommand = #RKT_NONE And (InWritePtr - InReadPtr > 0)
    CurrentCommand = PeekA(*this\inBuffer + InReadPtr) : InReadPtr + 1
  EndIf
  
  If Not *this\isConnected
    ; HANDSHAKE
    If CurrentCommand = #RKT_HANDSHAKE And (InWritePtr - InReadPtr >= Len(#RKT_DEMO_GREETING) -1)
      SendNetworkString(ClientID, #RKT_EDITOR_GREETING)
      *this\isConnected = #True
      RKT_pause(*this, #True)
      RKT_set_row(*this)
      InReadPtr + Len(#RKT_DEMO_GREETING) -1 : CurrentCommand = #RKT_NONE
    EndIf
  EndIf
  
  If *this\isConnected
    ; GET TRACK
    If CurrentCommand = #RKT_GET_TRACK
      TrackNameLength = SwapEndian(PeekL(*this\inBuffer+InReadPtr))
      InReadPtr + 4 : CurrentCommand = #RKT_GET_TRACK_NAME
      
    ElseIf CurrentCommand = #RKT_GET_TRACK_NAME And (InWritePtr - InReadPtr >= TrackNameLength)
      TrackName = PeekS(*this\inBuffer+InReadPtr, TrackNameLength, #PB_Ascii)
      RKT_get_remote_track(*this, TrackName)
      InReadPtr + TrackNameLength : CurrentCommand = #RKT_NONE
      
      ; SET ROW
    ElseIf CurrentCommand = #RKT_SET_ROW And (InWritePtr - InReadPtr > 3)
      *this\current_row = SwapEndian(PeekL(*this\inBuffer+InReadPtr))
      InReadPtr + 4 : CurrentCommand = #RKT_NONE
      
    EndIf
  EndIf
  
  
  If InReadPtr = InWritePtr ;And *this\isConnected = 1
    InReadPtr = 0
    InWritePtr = 0
  EndIf
  
EndProcedure

; Procedure RKT_connect_client(*this.sync_device)
;   Protected loop.i = 0
;   SendNetworkString(*this\server, #RKT_DEMO_GREETING, #PB_Ascii)
;   
;   Repeat
;     RKT_update(*this) ;, -1, 0) : Delay(1) : loop +1
;     If *this\isConnected : ProcedureReturn : EndIf
;   Until loop = 5000  ; wait ~5 sec max for handshake
;   
;   MessageRequester("PB Rocket", "Couldn't connect to Rocket Editor!")
;   End
;   *this\server = #False
; EndProcedure

Procedure RKT_create_server(*this.sync_device)
  InitNetwork()
  *this\server = CreateNetworkServer(#PB_Any, 1338, #PB_Network_TCP, "127.0.0.1")
  If *this\server
    *this\outBuffer = AllocateMemory(#RKT_BUFFER_OUT)
    *this\inBuffer = AllocateMemory(#RKT_BUFFER_IN)
  EndIf
EndProcedure

Procedure RKT_create_device(*syncdev.sync_device)
  
  RKT_create_server(*syncdev)
  If Not *syncdev\server : MessageRequester(#requesterTitle, "Couldn't start server!") : End : EndIf
  
  *syncdev\client = #Null
  
  *syncdev\sdata = AllocateMemory(SizeOf(sync_data))
  If Not *syncdev\sdata : End : EndIf
  InitializeStructure(*syncdev\sdata, sync_data)
  *syncdev\sdata\track_offset   = 0
  *syncdev\sdata\selected_track = 0
  *syncdev\sdata\tracks         = #Null
  *syncdev\sdata\num_tracks     = 0
  
  *syncdev\current_row   = 0
  *syncdev\current_track = 0
  *syncdev\isConnected   = 0
  *syncdev\isPlaying     = 0  
  *syncdev\isDirty       = #False
  ProcedureReturn *syncdev  
EndProcedure

Procedure RKT_data_deinit(*d.sync_device)
  Protected i.i, j.i, *tk.sync_track, *key.track_key
  Protected num_remote_tracks.i = 0, Dim remote_tracks.s(0)
  
  For i = 0 To *d\sdata\num_tracks -1
    *tk = *d\sdata\tracks\ptr[i]
    ;*tk = *d\sdata\tracks\ptr[*d\sdata\displaytracks(i)]
    If *d\isConnected And *tk\remote > -1
      ReDim remote_tracks(num_remote_tracks)
      remote_tracks(num_remote_tracks) = *tk\name
      num_remote_tracks +1
      If *tk\keys      
        For j = 0 To *tk\num_keys -1
          *key = *tk\keys + SizeOf(track_key) * j
          RKT_send_del_key(*d, *tk , *key\row)
        Next
        FreeMemory(*tk\keys)
        FreeMemory(*tk)
      EndIf
    EndIf
  Next
  *d\current_row   = 0
  *d\current_track = 0
  *d\sdata\num_tracks = 0
  *d\sdata\track_offset = 0
  *d\sdata\selected_track = 0
  *d\current_track = 0
  FreeArray(*d\sdata\displaytracks())
  Dim *d\sdata\displaytracks(0)
  
  If *d\isConnected And num_remote_tracks > 0
    For i = 0 To num_remote_tracks -1
      RKT_get_remote_track(*d, remote_tracks(i))
    Next
  EndIf
EndProcedure

Procedure RKT_free_device(*this.sync_device)
  
  If *this\isConnected
    CloseNetworkConnection(*this\server)
  EndIf  ;RKT_data_deinit(*this\sdata)
  *this\isConnected = #False
  RKT_data_deinit(*this)
  ClearStructure(*this\sdata, sync_data)
  FreeMemory(*this\sdata)
  FreeMemory(*this\inBuffer)
  FreeMemory(*this\outBuffer)
;  ClearStructure(*this, sync_device)
  
EndProcedure

Procedure RKT_dump(*this.sync_device)
  Protected i.i, j.i, *tmptrack.sync_track, *tmpkey.track_key 
  
  For i = 0 To *this\sdata\num_tracks -1
    *tmptrack = *this\sdata\tracks\ptr[i]
    Debug "Track " + Str(i) + "- address: " + Str(*tmptrack) + " - name: " + *tmptrack\name + " - numkeys: " + Str(*tmptrack\num_keys)
    For j = 0 To *tmptrack\num_keys -1
      Define *tmpkey.track_key = *tmptrack\keys + SizeOf(track_key) * j
      Debug "Index " + Str(j) + " - Row: " + Str(*tmpkey\row) + " - Value: " + StrF(*tmpkey\value) + " - Type: " + StrF(*tmpkey\type)
    Next
  Next
  
EndProcedure

; IDE Options = PureBasic 5.21 LTS (Windows - x86)
; CursorPosition = 621
; FirstLine = 619
; Folding = ------
; EnableUnicode
; EnableXP
; CompileSourceDirectory