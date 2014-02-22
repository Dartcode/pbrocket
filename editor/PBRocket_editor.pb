;===================================================================;
; Name:      PBRocket Editor
; Purpose:   A sync-tracker, a tool for synchronizing music and 
;            visuals in demoscene productions, to be used with
;            PBRocket, a .pbi file to include in your demo.
; Author:    Den (Denis Castellan - den@majorden.com)
;            https://bitbucket.org/Lush/pbrocket/
; Copyright: (C) 2014 Denis Castellan
;            Ported from GNU Rocket (C) Erik Faye-Lund and Egbert Teeselink
;            https://github.com/kusma/rocket
; License:   See accompanying COPYING file
;===================================================================;
;
; //TODO
;
; Add Bookmarks handling
;
; Add Selection handling
;
; Add Bias functions
;

EnableExplicit

Enumeration #PB_Event_FirstCustomValue
  #PBRE_EventRedraw
  #PBRE_EventRefresh
  #PBRE_Set_key
  #PBRE_Del_key
  #PBRE_Set_type
  #PBRE_Undo
  #PBRE_Redo
EndEnumeration

Enumeration
  #mainWindow
EndEnumeration

Enumeration
  ;  #TopPanel
  #Canvas_tracks
  ;  #Canvas_status
  ;  #Canvas_2
  
  ;  #StatusBar
  ;  #ToolbarContainer
  ;  #ToolbarContainer2
EndEnumeration

#PBRE_Move_Left = 0
#PBRE_Move_Right = 1
#PBRE_Move_Page_Left = 2
#PBRE_Move_Page_Right = 3

#PBRE_Move_Up = 0
#PBRE_Move_Down = 1
#PBRE_Move_Fast_Up = 2
#PBRE_Move_Fast_Down = 3
#PBRE_Move_Top = 4
#PBRE_Move_Bottom = 5

#mainTitle = "--== The Ultimate Synctracker ==--"
#requesterTitle = "PBRocket Editor"


Structure status_info
  text.s
  color.i
  timer.i
  show.i
EndStructure

Global col_track_bg = $19111A
;Global col_remote_track = $474520
Global col_rpb_bg = $39B23C ; $00ff00
Global col_bpb_bg = $349FCA ; $00ccff
Global col_rows_bg = $2F1F31 ; $352337
Global col_select_bg = $320D37 ; $361C39
Global col_select_outline = $895D8A ; $C0722E
Global col_select_fg = $ffffff
Global col_rows_fg  = $976D9F
Global col_track_fg  = $D3C8D5 ; $D5C6D8

Global Dim interpolation_types.s(3)
interpolation_types(0) = "step  "
interpolation_types(1) = "linear"
interpolation_types(2) = "smooth"
interpolation_types(3) = "ramp  "

Global Dim col_inter_type(3)
col_inter_type(0) = col_track_bg
col_inter_type(1) = $0000D8
col_inter_type(2) = $00D88E
col_inter_type(3) = $D88900

Define inchar.s

Global Event.i, EventM.i, Quit.i, WinTitle.s = #requesterTitle
Global WinW.i, WinH.i, MainFont = LoadFont(#PB_Any, "Consolas", 9, #PB_Font_Bold)

Global rpb = 4, bpb = 4, row_step = 16 ;, play = #False

Global visible_rows,  visible_tracks
Global row_height,    rows_width,  row_offset,  middle_row, num_rows.i = 128, input_value.s
Global tracks_height, track_width, tracks_left, tracks_top, status_height = 20
Global server_status_x = 0, track_number_x, row_value_x, interpolation_type_x, userinfo_x
Global file_name.s

Global Dim tracks(1)

XIncludeFile "PBRocket_server.pbi"
XIncludeFile "PBRocket_xml.pbi"
XIncludeFile "PBRocket_undo.pbi"

Global status.status_info



; Create the sync device
Global rocket.sync_device
RKT_create_device(rocket)

; create the undo/redo manager
Global undo_manager.undo_redo
undo_manager = PBRE_create_undo_redo(rocket)

Procedure PBRE_set_status(text.s)
  status\text = text
  status\timer = ElapsedMilliseconds() + 3000
  status\show = #True
  status\color = col_rows_fg
EndProcedure

Procedure PBRE_max(l.i, r.i)
  If l > r
    ProcedureReturn l
  EndIf
  ProcedureReturn r
EndProcedure

Procedure PBRE_display_status()
  Protected lapse.f = (status\timer - ElapsedMilliseconds()) / 1000
  Protected r.i, g.i, b.i
  If lapse <= 0
    status\timer = 0
    status\show = #False
    ProcedureReturn
  ElseIf lapse < 1
    r = Int(Red(col_rows_fg)   * lapse)
    g = Int(Green(col_rows_fg) * lapse) 
    b = Int(Blue(col_rows_fg)  * lapse) 
    status\color = RGB(PBRE_max(r, Red(col_track_bg)), PBRE_max(g, Green(col_track_bg)), PBRE_max(b, Blue(col_track_bg)))
  Else
    status\color = col_rows_fg  
  EndIf
  status\show = #True
EndProcedure

Procedure PBRE_set_input(*d.sync_device, action.i)
  Protected idx.i, *key.track_key, command.undo_command;, *t.sync_track
  
  Select action
    Case #PBRE_Set_key
      command\track = *d\sdata\tracks\ptr[*d\sdata\displaytracks(*d\sdata\selected_track)]
      command\row = *d\current_row
      command\redoAction = "set"
      command\redoValue = ValD(*d\inputval)
      idx = RKT_find_key(command\track, command\row)
      If idx >= 0
        *key = command\track\keys + SizeOf(track_key) * idx
        command\redoType = *key\type
        command\undoValue = *key\value
        command\undoType = *key\type
        command\undoAction = "set"
      Else
        command\undoAction = "del"
      EndIf
      undo_manager\Store(command)
      RKT_set_input(*d)
    Case #PBRE_Del_key
      command\track = *d\sdata\tracks\ptr[*d\sdata\displaytracks(*d\sdata\selected_track)]
      command\row = *d\current_row
      command\redoAction = "del"
      idx = RKT_find_key(command\track, command\row)
      If idx >= 0
        *key = command\track\keys + SizeOf(track_key) * idx
        command\undoValue = *key\value
        command\undoType = *key\type
        command\undoAction = "set"
        RKT_del_key(*d, command\track, command\row)
      Else
        command\undoAction = "nil"
      EndIf
      undo_manager\Store(command)
    Case #PBRE_Set_type
      command\track = *d\sdata\tracks\ptr[*d\sdata\displaytracks(*d\sdata\selected_track)]
      command\row = *d\current_row
      command\redoAction = "set"
      idx = RKT_key_idx_floor(command\track, command\row)
      If idx >= 0
        *key = command\track\keys + SizeOf(track_key) * idx
        command\row = *key\row
        command\undoAction = "set"
        command\undoValue = *key\value
        command\undoType = *key\type
        command\redoValue = *key\value
        command\redoType = Mod(*key\type + 1, 4)
        undo_manager\Store(command)
        RKT_set_type(*d)
      EndIf
  EndSelect
EndProcedure

Procedure PBRE_undo_redo(action.i)
  Select action
    Case #PBRE_Undo
    Case #PBRE_Redo
  EndSelect
EndProcedure

Procedure PBRE_remote_export(*d.sync_device)
  If *d\isConnected
    RKT_export_tracks(*d)
    PBRE_set_status("Remote Export command sent")
  EndIf
EndProcedure

Procedure PBRE_save_file_as(*d.sync_device)
  Protected file.s
  If *d\sdata\num_tracks > 0
    file = SaveFileRequester("Save Rocket file...", file_name, "rocket files (*.rocket)|*.rocket|All files (*.*)|*.*", 0)
    If file
      If PBRE_xml_save(*d, file)
        *d\isDirty = #False
        file_name = file
        WinTitle = #requesterTitle + " - " + GetFilePart(file_name)
        PBRE_set_status(GetFilePart(file_name) + " saved")
        SetWindowTitle(#mainWindow, WinTitle)
      EndIf
    EndIf
  Else
    PBRE_set_status("Nothing to save...")
  EndIf
EndProcedure

Procedure PBRE_save_file(*d.sync_device)
  If *d\sdata\num_tracks > 0
    If PBRE_xml_save(*d, file_name)
      *d\isDirty = #False
      PBRE_set_status(GetFilePart(file_name) + " saved")
      SetWindowTitle(#mainWindow, WinTitle)
    EndIf
  Else
    PBRE_set_status("Nothing to save...")
  EndIf
EndProcedure

Procedure PBRE_can_save(*d.sync_device)
  Protected r.i, r2.i
  While *d\isDirty
    r = MessageRequester(#requesterTitle, "Current file has unsaved changes." + Chr(13) +
                                          "Do you want to save those changes now?", #PB_MessageRequester_YesNoCancel)
    If r = #PB_MessageRequester_Yes
      If file_name = ""
        PBRE_save_file_as(*d)
      Else
        If PBRE_xml_save(*d, file_name)
          *d\isDirty = #False
          PBRE_set_status(GetFilePart(file_name) + " saved")
        EndIf
      EndIf
    ElseIf r = #PB_MessageRequester_Cancel
      PBRE_set_status("Action cancelled")
      ProcedureReturn #False
    Else
      *d\isDirty = #False      
      SetWindowTitle(#mainWindow, WinTitle)
    EndIf
  Wend
  SetWindowTitle(#mainWindow, WinTitle)
  ProcedureReturn #True
EndProcedure

Procedure PBRE_load_file(*d.sync_device)
  If PBRE_can_save(*d)
    file_name = OpenFileRequester("Load Rocket file...", "", "rocket files (*.rocket)|*.rocket|All files (*.*)|*.*", 0)
    If file_name <> ""
      If PBRE_xml_load(*d.sync_device, file_name)
        undo_manager\Reset()
        WinTitle = #requesterTitle + " - " + GetFilePart(file_name)
        SetWindowTitle(#mainWindow, WinTitle)
        PBRE_set_status(GetFilePart(file_name) + " loaded")
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure PBRE_new_file(*d.sync_device)
  If PBRE_can_save(rocket)
    RKT_data_deinit(rocket)
    undo_manager\Reset()
    WinTitle = #requesterTitle
    SetWindowTitle(#mainWindow, WinTitle)
  EndIf
EndProcedure

Procedure PBRE_set_row_count(*d)
  If Not rocket\isPlaying
    Protected Win, Quit, Event, EventM, EventG, Can
    Protected Flags = #PB_Window_ScreenCentered|#PB_Window_SystemMenu|#PB_Window_TitleBar
    Protected Label1, Label2, Input1, Input2, Button1
    
    Win = OpenWindow( #PB_Any, 0, 0, 300, 120, #requesterTitle, Flags, WindowID(#mainWindow))
    If Win
      DisableWindow(#mainWindow, 1)
      
      Label1 = TextGadget(#PB_Any, 105, 20, 90, 20, "Number of rows", #PB_Text_Center)
      Input1 = StringGadget(#PB_Any, 105, 40, 90, 20, Str(num_rows), #PB_Text_Center|#PB_String_Numeric)    
      Button1 = ButtonGadget(#PB_Any, 120, 80, 60, 25, "Ok!", #PB_Button_Default)
      SetActiveGadget(Input1)
      AddKeyboardShortcut(win, #PB_Shortcut_Escape, 15)
      AddKeyboardShortcut(win, #PB_Shortcut_Return, 16)
      Repeat
        Event = WindowEvent()
        If Event
          Select Event
            Case #PB_Event_Gadget
              Select EventGadget()
                Case Button1
                  num_rows = Val(GetGadgetText(Input1))
                  PBRE_set_status("Row count set to " + Str(num_rows))
                  Quit = 1
              EndSelect
            Case #PB_Event_Menu
              EventM = EventMenu() 
              Select EventM
                Case 15
                  Quit = 1
                Case 16
                  num_rows = Val(GetGadgetText(Input1))
                  PBRE_set_status("Row count set to " + Str(num_rows))
                  Quit = 1
              EndSelect
            Case #PB_Event_CloseWindow
              Select EventWindow()
                Case Win
                  Quit = 1
              EndSelect
          EndSelect
        EndIf
      Until Quit
      CloseWindow(Win)
      DisableWindow(#mainWindow, 0)
      SetActiveWindow(#mainWindow)
      SetActiveGadget(#Canvas_tracks)
    EndIf
  EndIf
  
EndProcedure

Procedure PBRE_set_rpb()
  Protected Win, Quit, Event, EventM, EventG, Can
  Protected Flags = #PB_Window_ScreenCentered|#PB_Window_SystemMenu|#PB_Window_TitleBar
  Protected Label1, Label2, Input1, Input2, Button1
  
  Win = OpenWindow( #PB_Any, 0, 0, 300, 120, #requesterTitle, Flags, WindowID(#mainWindow))
  If Win
    DisableWindow(#mainWindow, 1)
    
    Label1 = TextGadget(#PB_Any, 30, 20, 90, 20, "Rows per Beat", #PB_Text_Center)
    Input1 = StringGadget(#PB_Any, 30, 40, 90, 20, Str(rpb), #PB_Text_Center|#PB_String_Numeric)
    
    Label2 = TextGadget(#PB_Any, 170, 20, 90, 20, "Beats per Bar", #PB_Text_Center)
    Input2 = StringGadget(#PB_Any, 170, 40, 90, 20, Str(bpb), #PB_Text_Center|#PB_String_Numeric)
    
    Button1 = ButtonGadget(#PB_Any, 120, 80, 60, 25, "Ok!")
    SetActiveGadget(Input1)
    AddKeyboardShortcut(win, #PB_Shortcut_Escape, 15)
    AddKeyboardShortcut(win, #PB_Shortcut_Return, 16)
    Repeat
      Event = WindowEvent()
      If Event
        Select Event
          Case #PB_Event_Gadget
            Select EventGadget()
              Case Button1
                rpb = Val(GetGadgetText(Input1))
                bpb = Val(GetGadgetText(Input2))
                PBRE_set_status("RPB set to " + Str(rpb) + " - BPB set to " + Str(bpb))
                Quit = 1
            EndSelect
          Case #PB_Event_Menu
            EventM = EventMenu() 
            Select EventM
              Case 15
                Quit = 1
              Case 16
                rpb = Val(GetGadgetText(Input1))
                bpb = Val(GetGadgetText(Input2))
                PBRE_set_status("RPB set to " + Str(rpb) + " - BPB set to " + Str(bpb))
                Quit = 1
            EndSelect
          Case #PB_Event_CloseWindow
            Select EventWindow()
              Case Win
                Quit = 1
            EndSelect
        EndSelect
      EndIf
    Until Quit
    CloseWindow(Win)
    DisableWindow(#mainWindow, 0)
    SetActiveWindow(#mainWindow)
    SetActiveGadget(#Canvas_tracks)
  EndIf
EndProcedure

Procedure PBRE_select_row(*d.sync_device, direction.i = 0)
  If *d\inputval <> ""
    PBRE_set_input(*d, #PBRE_Set_key)
  EndIf
  Select direction
    Case #PBRE_Move_Up
      If *d\current_row > 0
        *d\current_row - 1
      EndIf
    Case #PBRE_Move_Down
      If *d\current_row < num_rows-1
        *d\current_row + 1
      EndIf
    Case #PBRE_Move_Fast_Up
      If *d\current_row - row_step >= 0
        *d\current_row - row_step
      Else
        *d\current_row = 0
      EndIf
    Case #PBRE_Move_Fast_Down
      If num_rows > *d\current_row + row_step
        *d\current_row + row_step
      Else
        *d\current_row = num_rows-1
      EndIf
    Case #PBRE_Move_Top
      *d\current_row = 0
    Case #PBRE_Move_Bottom
      *d\current_row = num_rows-1
  EndSelect
  RKT_set_row(rocket)                
EndProcedure

Procedure PBRE_swap_track(*d.sync_device, direction.i = -1)
  Protected tmp.i
  Select direction
    Case #PBRE_Move_Left
      If *d\sdata\selected_track > 0
        tmp = *d\sdata\displaytracks(*d\sdata\selected_track -1)
        *d\sdata\displaytracks(*d\sdata\selected_track -1) = *d\sdata\displaytracks(*d\sdata\selected_track)
        *d\sdata\displaytracks(*d\sdata\selected_track) = tmp
        *d\sdata\selected_track -1
        If *d\sdata\selected_track < *d\sdata\track_offset
          *d\sdata\track_offset = *d\sdata\selected_track
        EndIf
      EndIf
    Case #PBRE_Move_Right
      If *d\sdata\selected_track < *d\sdata\num_tracks -1
        tmp = *d\sdata\displaytracks(*d\sdata\selected_track +1)
        *d\sdata\displaytracks(*d\sdata\selected_track +1) = *d\sdata\displaytracks(*d\sdata\selected_track)
        *d\sdata\displaytracks(*d\sdata\selected_track) = tmp
        *d\sdata\selected_track +1
        If *d\sdata\selected_track > *d\sdata\track_offset + visible_tracks -1
          *d\sdata\track_offset = *d\sdata\track_offset +1
        EndIf
      EndIf
  EndSelect
  
EndProcedure

Procedure PBRE_select_track(*d.sync_device, direction.i = -1)
  If *d\sdata\num_tracks > 0
    Select direction
      Case #PBRE_Move_Left
        If *d\sdata\selected_track > 0
          If *d\inputval <> ""
            PBRE_set_input(*d, #PBRE_Set_key)
          EndIf
          *d\sdata\selected_track -1
          If *d\sdata\selected_track < *d\sdata\track_offset
            *d\sdata\track_offset = *d\sdata\selected_track
          EndIf
        EndIf
      Case #PBRE_Move_Right
        If *d\sdata\selected_track < *d\sdata\num_tracks -1
          If *d\inputval <> ""
            PBRE_set_input(*d, #PBRE_Set_key)
          EndIf
          *d\sdata\selected_track +1
          If *d\sdata\selected_track > *d\sdata\track_offset + visible_tracks -1
            *d\sdata\track_offset = *d\sdata\track_offset +1
          EndIf
        EndIf
      Case #PBRE_Move_Page_Left
        If *d\sdata\track_offset - visible_tracks >= 0
          If *d\inputval <> ""
            PBRE_set_input(*d, #PBRE_Set_key)
          EndIf
          *d\sdata\track_offset - visible_tracks
          *d\sdata\selected_track = *d\sdata\track_offset
        Else
          *d\sdata\track_offset = 0
          *d\sdata\selected_track = 0
        EndIf
      Case #PBRE_Move_Page_Right
        If *d\sdata\track_offset + visible_tracks < *d\sdata\num_tracks - visible_tracks
          If *d\inputval <> ""
            PBRE_set_input(*d, #PBRE_Set_key)
          EndIf
          *d\sdata\track_offset + visible_tracks
          *d\sdata\selected_track + visible_tracks
        Else
          *d\sdata\track_offset = *d\sdata\num_tracks - visible_tracks
          *d\sdata\selected_track = *d\sdata\track_offset
        EndIf
      Default
        If *d\sdata\track_offset > *d\sdata\num_tracks - visible_tracks
          *d\sdata\track_offset = *d\sdata\num_tracks - visible_tracks
        EndIf
        If *d\sdata\selected_track > *d\sdata\track_offset + visible_tracks -1
          If *d\sdata\selected_track > *d\sdata\track_offset + visible_tracks -1
            *d\sdata\track_offset = *d\sdata\track_offset +1
          EndIf
        EndIf
    EndSelect
  EndIf
  
EndProcedure

Procedure PBRE_refresh_canvas(*d.sync_device)
  visible_tracks = Round((WinW - (tracks_left)) / track_width, #PB_Round_Down)
  If *d\current_row >= num_rows
    *d\current_row = num_rows -1
  EndIf
  If *d\sdata\num_tracks < visible_tracks
    visible_tracks = *d\sdata\num_tracks
  EndIf
  PBRE_select_track(*d)
  visible_rows = (GadgetHeight(#Canvas_tracks) - status_height - tracks_top) / row_height
  row_offset = visible_rows / 2
  middle_row = row_offset * row_height
  tracks_height = GadgetHeight(#Canvas_tracks)
  PostEvent(#PBRE_EventRedraw)
EndProcedure

Procedure PBRE_resize_gadgets()
  ResizeGadget(#Canvas_tracks, #PB_Ignore, #PB_Ignore, WinW + track_width, WinH)
  WindowBounds(#mainWindow, track_width * 4 + tracks_left, row_height * 8 +4, #PB_Ignore, #PB_Ignore)
  PostEvent(#PBRE_EventRefresh)
EndProcedure

Procedure PBRE_init_canvas()
  Protected i
  StartDrawing(CanvasOutput(#Canvas_tracks))
  DrawingFont(FontID(MainFont))
  row_height = TextHeight("0")
  rows_width = TextWidth("000000h") + 20
  tracks_left = rows_width + 10
  tracks_top = row_height * 2 + 2
  track_width = TextWidth("00000000000000") + 20
  status_height = row_height +2
  server_status_x = 0
  track_number_x = TextWidth(" Connected ")
  row_value_x = TextWidth(" Connected | Track: 000 ")
  interpolation_type_x = TextWidth(" Connected | Track: 000 | Value: 0000.00000000000")
  userinfo_x = TextWidth(" Connected | Track: 000 | Value: 0000.00000000000| Type: Linear | ")
  StopDrawing()
  SetActiveGadget(#Canvas_tracks)
  PBRE_resize_gadgets()
EndProcedure

Procedure PBRE_draw_values(*d.sync_device)
  Protected tmprow, tmpcol, tmpbg, track, *tmptrack.sync_track, main_title_x.i
  Protected row, keyindex, keyfloor, *tmp_key.track_key, server_info.s
  Protected xpos, ypos, rowval.s, infoval.s, infotype.i, tmpval.d

  
  If StartDrawing(CanvasOutput(#Canvas_tracks))
    DrawingFont(FontID(MainFont))
    
    ; numbers background  
    Box(0, tracks_top, rows_width, tracks_height - status_height, col_rows_bg)
    
    ; tracks background
    Box(rows_width, tracks_top-1, WinW + track_width, tracks_height - status_height, col_track_bg)
    
    ; top line
    Box(0, 0, WinW + track_width, row_height, col_track_bg) 
    main_title_x = (WinW - TextWidth(#mainTitle)) / 2
    DrawText(main_title_x, 0, #mainTitle, col_rows_fg, col_track_bg)
    LineXY(0, row_height -1, WinW + track_width, row_height -1, col_rows_bg)
    
    ; tracks titles
    Box(0, row_height, WinW + track_width, row_height+1, col_track_bg) 
    For track = 0 To visible_tracks -1
      *tmptrack = *d\sdata\tracks\ptr[*d\sdata\displaytracks(*d\sdata\track_offset + track)]
      If track = (*d\sdata\selected_track - *d\sdata\track_offset)
        tmpbg = col_select_bg
      Else
        tmpbg = col_track_bg
      EndIf
      If *tmptrack\remote > -1
        tmpcol = col_bpb_bg
      Else
        tmpcol = col_track_fg
      EndIf
      DrawText(track_width * track + tracks_left, row_height, LSet(*tmptrack\name, 16), tmpcol, tmpbg)
    Next
    LineXY(0, row_height * 2, WinW + track_width, row_height * 2, col_rows_bg)
    
    ; status line
    Box(0, tracks_height - status_height, WinW + track_width, status_height, col_track_bg) 
    LineXY(0, tracks_height - status_height, WinW + track_width, tracks_height - status_height, col_rows_bg)
    
    ; selected value "cursor" background
    If visible_tracks > 0
      Box(track_width * (*d\sdata\selected_track - *d\sdata\track_offset) + tracks_left -2, 
          middle_row + tracks_top, track_width -8, row_height, col_select_bg) 
    EndIf
    
    ypos = tracks_top
    For row = 0 To visible_rows-1
      tmprow = *d\current_row - row_offset + row
      If rpb > 0
        If Mod(tmprow, bpb*rpb) = 0 And bpb > 0
          tmpcol = col_rpb_bg
        ElseIf Mod(tmprow, rpb) = 0 And rpb > 0
          tmpcol = col_bpb_bg
        Else 
          tmpcol = col_track_fg
        EndIf
      Else
        tmpcol = col_track_fg
      EndIf
      
      
      If tmprow >= 0 And tmprow < num_rows
        
        ; Draw row numbers
        DrawText(10, row_height * row + tracks_top, RSet(Str(*d\current_row - row_offset + row), 7, "0"), tmpcol, col_rows_bg)
        
        xpos = tracks_left
        For track = 0 To visible_tracks-1
          *tmptrack = *d\sdata\tracks\ptr[*d\sdata\displaytracks(*d\sdata\track_offset + track)]
          
          ; compute key data
          keyindex = RKT_find_key(*tmptrack, tmprow)
          keyfloor = - keyindex - 2
          rowval = " ····" : infoval = "0" : infotype = 0 : tmpval = 0
          
          If keyfloor <> -1 
            If keyindex >= 0
              *tmp_key.track_key = *tmptrack\keys + SizeOf(track_key) * (keyindex)
              tmpval = RKT_get_val(*tmptrack, tmprow)
              If tmpval < 0
                rowval = StrD(RKT_get_val(*tmptrack, tmprow),2)
              Else
                rowval = " " + StrD(RKT_get_val(*tmptrack, tmprow),2)
              EndIf
            Else
              *tmp_key.track_key = *tmptrack\keys + SizeOf(track_key) * (keyfloor)
            EndIf
            infoval = StrD(RKT_get_val(*tmptrack, tmprow))
            infotype = *tmp_key\type
            If *tmp_key\type > 0
              Box(xpos + track_width - 15, ypos, 2, row_height, col_inter_type(*tmp_key\type))
            EndIf
          EndIf
          
          ; if current key is under cursor
          If tmprow = *d\current_row And track = (*d\sdata\selected_track - *d\sdata\track_offset)
            tmpbg = col_select_bg
            If rocket\inputval <> ""
              If Left(rocket\inputval, 1) = "-"
                rowval = Right(rocket\inputval, 12)
              Else 
                rowval = Right(" " + rocket\inputval, 12)
              EndIf
            EndIf
            
            ; Status bar
            DrawText(track_number_x, tracks_height - status_height + 1, "| Track: " + RSet(Str(*d\sdata\selected_track), 3, "0"), col_rows_fg, col_track_bg )
            DrawText(row_value_x, tracks_height - status_height + 1, "| Value: " + infoval, col_rows_fg, col_track_bg )
            DrawText(interpolation_type_x, tracks_height - status_height + 1, "| Type: "  + interpolation_types(infotype) + " |", col_rows_fg, col_track_bg )
            If status\show
              DrawText(userinfo_x, tracks_height - status_height + 1, status\text, status\color, col_track_bg )
            EndIf
          Else
            tmpbg = col_track_bg
          EndIf
          
          ; draw key data
          DrawText(xpos, ypos, rowval, tmpcol, tmpbg )
          xpos + track_width
        Next  
      EndIf
      ypos + row_height
    Next
    
    ; selected value "cursor" outline
    If visible_tracks > 0
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(track_width * (*d\sdata\selected_track - *d\sdata\track_offset) + tracks_left - 4, 
          middle_row - 2  + tracks_top, track_width -4, row_height+4, col_select_outline) 
      DrawingMode(#PB_2DDrawing_Default)
    EndIf
    
    ; server status info
    If *d\isConnected
      server_info =   " Connected"
    Else
      If *d\server
        server_info = " Listening"
      Else
        server_info = " No Server"
      EndIf
    EndIf
    DrawText(server_status_x, tracks_height - status_height + 1, server_info, col_rows_fg, col_track_bg )
    If status\show
      DrawText(userinfo_x, tracks_height - status_height + 1, status\text, status\color, col_track_bg )
    EndIf
    
    StopDrawing()
    
  EndIf
EndProcedure

Procedure PBRE_main_window_open()
  Protected Flags = #PB_Window_ScreenCentered|#PB_Window_SystemMenu|#PB_Window_TitleBar|
                    #PB_Window_MaximizeGadget|#PB_Window_MinimizeGadget|#PB_Window_SizeGadget
  
  If OpenWindow( #mainWindow, 0, 0, 800, 640, #requesterTitle, Flags )
    WinW = WindowWidth(#mainWindow)
    WinH = WindowHeight(#mainWindow)
    SetWindowColor(#mainWindow, col_track_bg )
    
    ; file controls
    AddKeyboardShortcut(0, #PB_Shortcut_F1, 10)                         ; Help
    AddKeyboardShortcut(0, #PB_Shortcut_F2, 11)                         ; Set row count
    AddKeyboardShortcut(0, #PB_Shortcut_F3, 12)                         ; Set rpb/bpb
    AddKeyboardShortcut(0, #PB_Shortcut_Control|#PB_Shortcut_O, 13)     ; Open .rocket file
    AddKeyboardShortcut(0, #PB_Shortcut_F5, 13)                         ; Open .rocket file
    AddKeyboardShortcut(0, #PB_Shortcut_Control|#PB_Shortcut_N, 14)     ; New
    AddKeyboardShortcut(0, #PB_Shortcut_F6, 14)                         ; New
    AddKeyboardShortcut(0, #PB_Shortcut_Control|#PB_Shortcut_Shift|#PB_Shortcut_S, 15)   ; Save As
    AddKeyboardShortcut(0, #PB_Shortcut_F7, 15)                         ; Save As
    AddKeyboardShortcut(0, #PB_Shortcut_Control|#PB_Shortcut_S, 16)     ; Save
    AddKeyboardShortcut(0, #PB_Shortcut_F8, 16)                         ; Save
    AddKeyboardShortcut(0, #PB_Shortcut_Control|#PB_Shortcut_E, 17)     ; Remote Export
    AddKeyboardShortcut(0, #PB_Shortcut_F9, 17)                         ; Remote Export
    
    ; navigation controls
    AddKeyboardShortcut(0, #PB_Shortcut_Up, 100)
    AddKeyboardShortcut(0, #PB_Shortcut_Down, 101)
    
    AddKeyboardShortcut(0, #PB_Shortcut_Left, 102)
    AddKeyboardShortcut(0, #PB_Shortcut_Shift|#PB_Shortcut_Tab, 102)
    AddKeyboardShortcut(0, #PB_Shortcut_Right, 103)
    AddKeyboardShortcut(0, #PB_Shortcut_Tab, 103)
    AddKeyboardShortcut(0, #PB_Shortcut_Alt|#PB_Shortcut_Left, 104)
    AddKeyboardShortcut(0, #PB_Shortcut_Alt|#PB_Shortcut_Right, 105)
    
    AddKeyboardShortcut(0, #PB_Shortcut_Alt|#PB_Shortcut_Up, 106)
    AddKeyboardShortcut(0, #PB_Shortcut_PageUp, 106)
    AddKeyboardShortcut(0, #PB_Shortcut_PageDown, 107)
    AddKeyboardShortcut(0, #PB_Shortcut_Alt|#PB_Shortcut_Down, 107)
    AddKeyboardShortcut(0, #PB_Shortcut_Home, 108)
    AddKeyboardShortcut(0, #PB_Shortcut_End, 109)
    AddKeyboardShortcut(0, #PB_Shortcut_Delete, 110)
    AddKeyboardShortcut(0, #PB_Shortcut_Space, 111)
    
    ; swap tracks
    AddKeyboardShortcut(0, #PB_Shortcut_Control|#PB_Shortcut_Left, 112)
    AddKeyboardShortcut(0, #PB_Shortcut_Control|#PB_Shortcut_Right, 113)
    
    ; value input controls
    AddKeyboardShortcut(0, #PB_Shortcut_Back, 30)
    AddKeyboardShortcut(0, #PB_Shortcut_Return, 33)
    AddKeyboardShortcut(0, #PB_Shortcut_I, 32)
    
    ; undo / redo
    AddKeyboardShortcut(0, #PB_Shortcut_Control|#PB_Shortcut_Z, 34)
    AddKeyboardShortcut(0, #PB_Shortcut_Control|#PB_Shortcut_Y, 35)
    
    CanvasGadget(#Canvas_tracks, 0, 0, WinW, WinH, #PB_Canvas_Keyboard)
    
    ;SmartWindowRefresh(#mainWindow, 1)
    
    ProcedureReturn #True
  Else
    ProcedureReturn #False
  EndIf
EndProcedure

If Not PBRE_main_window_open() : MessageRequester(#requesterTitle, "Couldn't open window") : End : EndIf

PBRE_init_canvas()
PBRE_draw_values(rocket)

;- Main loop
;{
Define renderDelay = ElapsedMilliseconds()
Define rowDelay = ElapsedMilliseconds()

Repeat
  
  RKT_update(rocket)
  
  If rocket\isDirty : SetWindowTitle(#mainWindow, WinTitle + " - modified") : EndIf
  If status\show : PBRE_display_status() : EndIf
  
  If ElapsedMilliseconds() - renderDelay >= 1000/25
    renderDelay = ElapsedMilliseconds()
    PBRE_refresh_canvas(rocket)
  EndIf
  
  Event = WindowEvent()
  If Event
    Select Event
      Case #PBRE_EventRefresh       : PBRE_refresh_canvas(rocket)     
      Case #PBRE_EventRedraw        : PBRE_draw_values(rocket)
      Case #PB_Event_MaximizeWindow : PBRE_resize_gadgets()
      Case #PB_Event_RestoreWindow  : PBRE_refresh_canvas(rocket)     
      Case #PB_Event_SizeWindow 
        If GetWindowState(#mainWindow) = #PB_Window_Normal Or GetWindowState(#mainWindow) = #PB_Window_Maximize
          WinW = WindowWidth(#mainWindow)
          WinH = WindowHeight(#mainWindow)
        EndIf
        PBRE_resize_gadgets()
        
      Case #PB_Event_Menu
        EventM = EventMenu() 
        Select EventM
            
            ;- Program functions
            
          Case 111
            If rocket\isConnected
              If rocket\isPlaying
                RKT_pause(rocket, #True)
                rocket\isPlaying = 0
              Else
                RKT_pause(rocket, #False)
                rocket\isPlaying = 1
              EndIf
            EndIf
            
          Case 10 : MessageRequester(#requesterTitle, "So you need help, huh?")
          Case 11 : PBRE_set_row_count(rocket)
          Case 12 : PBRE_set_rpb()
          Case 13 : PBRE_load_file(rocket)
          Case 14 : PBRE_new_file(rocket)
          Case 15 : PBRE_save_file_as(rocket)
          Case 16 : PBRE_save_file(rocket)
          Case 17 : PBRE_remote_export(rocket)
            
            ;- Row navigation
            
          Case 100 : If Not rocket\isPlaying : PBRE_select_row(rocket, #PBRE_Move_Up)        : EndIf
          Case 101 : If Not rocket\isPlaying : PBRE_select_row(rocket, #PBRE_Move_Down)      : EndIf
          Case 106 : If Not rocket\isPlaying : PBRE_select_row(rocket, #PBRE_Move_Fast_Up)   : EndIf
          Case 107 : If Not rocket\isPlaying : PBRE_select_row(rocket, #PBRE_Move_Fast_Down) : EndIf
          Case 108 : If Not rocket\isPlaying : PBRE_select_row(rocket, #PBRE_Move_Top)       : EndIf
          Case 109 : If Not rocket\isPlaying : PBRE_select_row(rocket, #PBRE_Move_Bottom)    : EndIf
            
            ; Track navigation
            
          Case 102 : PBRE_select_track(rocket, #PBRE_Move_Left)
          Case 103 : PBRE_select_track(rocket, #PBRE_Move_Right)
          Case 104 : PBRE_select_track(rocket, #PBRE_Move_Page_Left)
          Case 105 : PBRE_select_track(rocket, #PBRE_Move_Page_Right)
          Case 110 : PBRE_set_input(rocket, #PBRE_Del_key)
          Case 112 : PBRE_swap_track(rocket, #PBRE_Move_Left)
          Case 113 : PBRE_swap_track(rocket, #PBRE_Move_Right)
            
            
            ; Value input
            
          Case 33 : If rocket\inputval <> "" : PBRE_set_input(rocket, #PBRE_Set_key) : EndIf
          Case 30 : rocket\inputval = Left(rocket\inputval, Len(rocket\inputval)-1)
          Case 32 : PBRE_set_input(rocket, #PBRE_Set_type)
          Case 34 : undo_manager\Undo()
          Case 35 : undo_manager\Redo()
            
        EndSelect
        
      Case #PB_Event_Gadget
        Define EventType.i = EventType()
        If Not rocket\isPlaying
          Select EventType
            Case #PB_EventType_Input
              inchar = Chr(GetGadgetAttribute(#Canvas_tracks, #PB_Canvas_Input))
              If inchar = "-" And rocket\inputval = ""
                rocket\inputval = inchar
              EndIf
              If inchar = "." And Not FindString(rocket\inputval, ".")
                rocket\inputval + inchar
              EndIf
              If FindString("0123456789", inchar)
                rocket\inputval + inchar
              EndIf
            Case #PB_EventType_MouseWheel
              Define Delta.i = GetGadgetAttribute(#Canvas_tracks, #PB_Canvas_WheelDelta)
              If Delta < 0
                If rocket\current_row < num_rows + delta
                  rocket\current_row - delta
                Else
                  rocket\current_row = num_rows -1
                EndIf
              Else
                If rocket\current_row >= delta
                  rocket\current_row - delta
                Else
                  rocket\current_row = 0
                EndIf
              EndIf
              RKT_set_row(rocket)
          EndSelect
        EndIf
      Case #PB_Event_CloseWindow
        Select EventWindow()
          Case #mainWindow
            If PBRE_can_save(rocket)
              Quit = 1
            EndIf
        EndSelect
    EndSelect
  Else
    Delay(1)
  EndIf
Until Quit = 1
;}

RKT_free_device(rocket)
PBRE_free_undo_redo(undo_manager)


; IDE Options = PureBasic 5.21 LTS (Windows - x86)
; CursorPosition = 307
; FirstLine = 233
; Folding = Jjg6
; EnableUnicode
; EnableXP
; SubSystem = OpenGL
; CompileSourceDirectory