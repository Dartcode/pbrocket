Procedure PBRE_xml_save(*d.sync_device, file.s)
  Protected xml, mainNode, tracks, track, key, bookmarks, bookmark
  Protected *tmp_track.sync_track, *tmp_key.track_key, i,j
  
  xml = CreateXML(#PB_Any) 
  mainNode = CreateXMLNode(RootXMLNode(xml)) 
  SetXMLNodeName(mainNode, "sync")
  SetXMLAttribute(mainNode, "rows", Str(num_rows))
  SetXMLAttribute(mainNode, "rpb", Str(rpb))
  SetXMLAttribute(mainNode, "bpb", Str(bpb))
  
  ; Create first xml node (in main node)
  tracks = CreateXMLNode(mainNode) 
  SetXMLNodeName(tracks, "tracks") 
  
  For i = 0 To *d\sdata\num_tracks -1
    *tmp_track = *d\sdata\tracks\ptr[*d\sdata\displaytracks(i)]
    track = CreateXMLNode(tracks)
    SetXMLNodeName(track, "track")
    SetXMLAttribute(track, "name", *tmp_track\name)
    
    For j = 0 To *tmp_track\num_keys -1
      *tmp_key = *tmp_track\keys + SizeOf(track_key) * j
      key = CreateXMLNode(track)
      SetXMLNodeName(key, "key")
      SetXMLAttribute(key, "row", Str(*tmp_key\row))
      SetXMLAttribute(key, "value", StrD(*tmp_key\value))
      SetXMLAttribute(key, "interpolation", Str(*tmp_key\type))
    Next
  Next
  
  bookmarks = CreateXMLNode(mainNode) 
  SetXMLNodeName(bookmarks, "bookmarks") 
  
  ;   For i 0 To Nb of bookmarks -1
  ;     bookmark = CreateXMLNode(RootXMLNode(xml))
  ;     SetXMLNodeName(bookmark, "bookmark")
  ;     SetXMLAttribute(bookmark, "row", Str(row_number)) 
  ;   Next
  
  FormatXML(xml, #PB_XML_ReFormat, 2)
  If SaveXML(xml, file)
    ProcedureReturn 1
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

Procedure PBRE_xml_parse(*CurrentNode, CurrentSublevel, *d.sync_device, *track.sync_track)
  Protected *child_node, node_name.s
  
  If XMLNodeType(*CurrentNode) = #PB_XML_Normal
    
    node_name = GetXMLNodeName(*CurrentNode)
    
    If node_name = "key"
      Define value.long_to_float, k.track_key
      If ExamineXMLAttributes(*CurrentNode)
        While NextXMLAttribute(*CurrentNode)
          Select XMLAttributeName(*CurrentNode)
            Case "row"
              k\row = Val(XMLAttributeValue(*CurrentNode))
            Case "value"
              value\float = ValD(XMLAttributeValue(*CurrentNode))
              k\value = value\float
            Case "interpolation"
              k\type = Val(XMLAttributeValue(*CurrentNode))
          EndSelect  
        Wend
        RKT_set_key(*d, *track, k)
      EndIf
    ElseIf node_name = "track"
      If ExamineXMLAttributes(*CurrentNode)
        While NextXMLAttribute(*CurrentNode)
          If XMLAttributeName(*CurrentNode) = "name"
            Define name.s = XMLAttributeValue(*CurrentNode)
          EndIf
        Wend
        *track = RKT_get_xml_track(*d, name)
      EndIf
    ElseIf node_name = "sync"
      If ExamineXMLAttributes(*CurrentNode)
        While NextXMLAttribute(*CurrentNode)
          Select XMLAttributeName(*CurrentNode)
            Case "rows"
              num_rows = Val(XMLAttributeValue(*CurrentNode))
            Case "rpb"
              rpb = Val(XMLAttributeValue(*CurrentNode))
            Case "bpb"
              bpb = Val(XMLAttributeValue(*CurrentNode))
          EndSelect  
        Wend
      EndIf
    EndIf
    
    *child_node = ChildXMLNode(*CurrentNode)
    
    While *child_node <> 0
      PBRE_xml_parse(*child_node, CurrentSublevel + 1, *d, *track)      
      *child_node = NextXMLNode(*child_node)
    Wend        
    
  EndIf
  
EndProcedure


Procedure PBRE_xml_load(*d.sync_device, file_name.s)
  Protected Message$, *main_node
    If LoadXML(0, file_name)
      If XMLStatus(0) <> #PB_XML_Success
        Message$ = "Error in the Rocket file:" + Chr(13)
        Message$ + "Message: " + XMLError(0) + Chr(13)
        Message$ + "Line: " + Str(XMLErrorLine(0)) + "   Character: " + Str(XMLErrorPosition(0))
        MessageRequester("Error", Message$)
      EndIf
      
      *main_node = MainXMLNode(0)      
      If *main_node
        RKT_data_deinit(*d)
        PBRE_xml_parse(*main_node, 0, *d, 0)
        ProcedureReturn 1
      Else
        ProcedureReturn 0
      EndIf     
    Else
      MessageRequester("Error", "The file cannot be opened.")
    EndIf
EndProcedure

; IDE Options = PureBasic 5.21 LTS (Windows - x86)
; CursorPosition = 64
; FirstLine = 45
; Folding = -
; EnableUnicode
; EnableXP
; CompileSourceDirectory