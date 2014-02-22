Structure Vector
  x.f
  y.f
  z.f
  ;w.f
EndStructure 

Global Dim Stars.Vector(1000)

Procedure RandomPoint(minv.f, maxv.f, t1.f = 0, t2.f = 0)
  Repeat
    Define u.f = Random(maxv - minv) + minv
  Until u < t1 Or u > t2
  ProcedureReturn  u
EndProcedure

Procedure InitStars()
  Global starfieldDepth = zfar / 5
  Define i.i
  For i = 0 To ArraySize(Stars()) - 1
    Stars(i)\x = RandomPoint(-1000, 1000)
    Stars(i)\y = RandomPoint(-1000, 1000)
    Stars(i)\z = RandomPoint(0, starfieldDepth)
  Next
EndProcedure

Procedure DisplayStars(speed.d, angle.d, jump.d)
  Protected i.i, k.f
  Protected tx.f, ty.f, tz.f
  Protected rx.f, ry.f, rz.f
  Protected px.i, py.i, c.f, s.i, tw.i, u.i, pz
  
  SortStructuredArray(Stars(), #PB_Sort_Descending, OffsetOf(Vector\z), TypeOf(Vector\z))
  
  For i = 0 To ArraySize(Stars()) - 1
    Stars(i)\z - speed
    If speed > 0
      If Stars(i)\z <= znear
        Stars(i)\x = RandomPoint(-1000, 1000)
        Stars(i)\y = RandomPoint(-1000, 1000)
        Stars(i)\z = starfieldDepth
      EndIf
    ElseIf speed < 0
      If Stars(i)\z >= starfieldDepth
        Stars(i)\x = RandomPoint(-1000, 1000)
        Stars(i)\y = RandomPoint(-1000, 1000)
        Stars(i)\z = znear
      EndIf
    EndIf
    
    tz = Stars(i)\z
    
    rx = Stars(i)\x
    ry = Stars(i)\y
    rz = Stars(i)\z
    
    ; focal length / object distance
    If rz <> 0 : k = focalLength / rz : Else : k = 50 : EndIf
    
    If rz > znear And rz < starfieldDepth
      px = Int( (Stars(i)\x * Cos(angle) - Stars(i)\y * Sin(angle)) * k + (ViewPortWidth / 2) + 0.5)
      py = Int( (Stars(i)\x * Sin(angle) + Stars(i)\y * Cos(angle)) * k + (ViewPortHeight / 2) + 0.5)
      pz = Int( rz * k + 0.5)
      If px >= 0 And px < ViewPortWidth And py >= 0 And py < ViewPortHeight
        s = Int((1.0 - (rz / starfieldDepth)) * 3.0 + 0.5)
        c = Int((1.0 - ((rz-znear) / (starfieldDepth-znear))) * 200) + 55
        Circle(px, py + jump, s, RGB(c, c, c))
      EndIf
    EndIf
  Next  
EndProcedure

Procedure DeleteStars()
  FreeArray(Stars())
EndProcedure
; IDE Options = PureBasic 5.21 LTS (Windows - x86)
; CursorPosition = 65
; FirstLine = 36
; Folding = -
; EnableUnicode
; EnableXP
; CompileSourceDirectory