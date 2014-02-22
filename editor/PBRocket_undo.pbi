
Structure undoRedoClass
  *vTable
  currentEntry.i
  lastEntry.i
  maxEntries.i
  *undoBuffer
  *device.sync_device
EndStructure

Structure undo_command
  *track.sync_track
  row.i
  redoAction.s{3}
  redoValue.d
  redoType.i
  undoAction.s{3}
  undoValue.d
  undoType.i
EndStructure

Interface undo_redo
  Store(doAction.undo_command)
  Undo()
  Redo()
  Reset()
EndInterface

Procedure DCI_store(*this.undoRedoClass, *doAction.undo_command)
  Protected *command.undo_command
  If *this\currentEntry = *this\maxEntries
    MoveMemory(*this\undoBuffer + SizeOf(undo_command), *this\undoBuffer, SizeOf(undo_command) * (*this\maxEntries))
    *this\currentEntry -1
  EndIf
  
  *this\currentEntry +1
  *this\lastEntry = *this\currentEntry
  *command = *this\undoBuffer + SizeOf(undo_command) * (*this\currentEntry)
  *command\track = *doAction\track
  *command\row = *doAction\row
  *command\redoAction = *doAction\redoAction
  *command\redoValue = *doAction\redoValue
  *command\redoType = *doAction\redoType    
  *command\undoAction = *doAction\undoAction
  *command\undoValue = *doAction\undoValue
  *command\undoType = *doAction\undoType
EndProcedure

Procedure DCI_undo(*this.undoRedoClass)
  Protected *command.undo_command, key.track_key
  If *this\currentEntry >= 0
    *command = *this\undoBuffer + SizeOf(undo_command) * (*this\currentEntry)
    Select *command\undoAction
      Case "set"
        key\row = *command\row
        Key\value = *command\undoValue
        key\type = *command\undoType
        RKT_set_key(*this\device, *command\track, key)
      Case "del"
        RKT_del_key(*this\device, *command\track, *command\row)
    EndSelect
    *this\currentEntry -1
  EndIf
EndProcedure

Procedure DCI_redo(*this.undoRedoClass)
  Protected *command.undo_command, key.track_key
  If *this\currentEntry < *this\lastEntry 
    *this\currentEntry +1
    *command = *this\undoBuffer + SizeOf(undo_command) * (*this\currentEntry)
    Select *command\redoAction
      Case "set"
        key\row = *command\row
        Key\value = *command\redoValue
        key\type = *command\redoType
        RKT_set_key(*this\device, *command\track, key)
      Case "del"
        RKT_del_key(*this\device, *command\track, *command\row)
    EndSelect
  EndIf
EndProcedure

Procedure DCI_Reset(*this.undoRedoClass)
  *this\currentEntry = -1
  *this\lastEntry = -1
EndProcedure

Procedure PBRE_create_undo_redo(*device.sync_device, maxlevels.i = 500)
  Protected *obj.undoRedoClass
  *obj = AllocateMemory(SizeOf(undoRedoClass))
  If *obj
    *obj\vTable = ?VTable_undoRedoClass
    *obj\currentEntry = -1
    *obj\lastEntry = -1
    *obj\maxEntries = maxlevels-1
    *obj\undoBuffer = AllocateMemory(SizeOf(undo_command) * maxlevels)
    *obj\device = *device
  EndIf
  ProcedureReturn *obj    
EndProcedure

Procedure PBRE_free_undo_redo(*ur.undoRedoClass)
  FreeMemory(*ur\undoBuffer)
EndProcedure

DataSection 
  VTable_undoRedoClass:
  Data.i @DCI_store()
  Data.i @DCI_undo()
  Data.i @DCI_redo()
  Data.i @DCI_reset()
EndDataSection 

; IDE Options = PureBasic 5.21 LTS (Windows - x86)
; CursorPosition = 34
; Folding = --
; EnableUnicode
; EnableXP
; CompileSourceDirectory