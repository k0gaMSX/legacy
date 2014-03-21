;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@              S Y M S T U D I O   S Y S T E M   L I B R A R Y               @
;@                    - SYMBOS DESKTOP MANAGER FUNCTIONS -                    @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author: Prodatron / Symbiosis
;Date:   26.08.2007

;The desktop manager is responsible for all actions, which are taking place on
;the video screen. Especially the handling of the application windows is done
;by the desktop manager.
;This library supports you in using the desktop manager functions.
;The existance of "AppPrzN" (a byte, where the ID of the applications process
;is stored) and "AppMsgB" (the message buffer, 14 bytes, which are placed in
;the transfer ram area) is required.


Library SyDesktop_WINOPN
;******************************************************************************
;*** Name           Window_Open_Command
;*** Input          A  = Window data record ram bank (0-15)
;***                DE = Window data record address (#C000-#FFFF)
;*** Output         A  = Window ID (only, if CF=0)
;***                CF = Success status
;***                     0 = OK
;***                     1 = window couldn't be opened, as the maximum number
;***                         of windows (32) has been reached
;*** Destroyed      BC,DE,HL,IX,IY
;*** Description    Opens a new window. Its data record must be placed in the
;***                transfer ram area (between #c000 and #ffff).
;***                For more information about the window data record see the
;***                chapter "desktop manager data records".
;***                For more information about the transfer ram memory types see
;***                the "applications" chapter.
;******************************************************************************
        ld b,a
        db #dd:ld l,e
        db #dd:ld h,d
        ld a,(AppPrzN)      ;register window for the application process
        ld (ix+3),a
        ld a,b
        ld c,MSC_DSK_WINOPN
        call SyDesktop_SendMessage
SyWOpn1 call SyDesktop_WaitMessage
        cp MSR_DSK_WOPNER
        scf
        ret z               ;return with set carry flag, if window couldn't be opened
        cp MSR_DSK_WOPNOK
        jr nz,SyWOpn1       ;different message than "open ok" -> continue waiting
        ld a,(iy+4)         ;get window ID and return with cleared carry flag
        ret
EndLib

Library SyDesktop_WINMEN
;******************************************************************************
;*** Name           Window_Redraw_Menu_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the menu bar of a window. If you changed your menus you
;***                should call this command to update the screen display.
;******************************************************************************
        ld c,MSC_DSK_WINMEN
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WININH
;******************************************************************************
;*** Name           Window_Redraw_Content_Command
;*** Input          A  = Window ID
;***                E  = -1, control ID or negative number of controls
;***                     000 - 239 -> the control with the specified ID will be
;***                                  redrawed.
;***                     240 - 254 -> redraws -P2 controls, starting from
;***                                  control P3. As an example, if P2 is -3
;***                                  (253) and P3 is 5, the controls 5, 6 and 7
;***                                  will be redrawed.
;***                     255       -> redraws all controls inside the window
;***                                  content.
;***                - if E is between 240 and 254:
;***                D = ID of the first control, which should be redrawed.
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws one, all or a specified number of controls inside the
;***                window content. This command is very important, if you make
;***                changes and want to display them.
;***                This command is identical with MSC_DSK_WINDIN with the
;***                exception, that it only works, if the window has focus. Because
;***                of this, it is a little bit faster, as the desktop manager
;***                doesn't need to take care about other windows, which could hide
;***                some parts of the window.
;******************************************************************************
        ld c,MSC_DSK_WININH
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINTOL
;******************************************************************************
;*** Name           Window_Redraw_Toolbar_Command
;*** Input          A  = Window ID
;***                E  = -1, control ID or negative number of controls
;***                     000 - 239 -> the control with the specified ID will be
;***                                  redrawed.
;***                     240 - 254 -> redraws -P2 controls, starting from
;***                                  control P3. As an example, if P2 is -3
;***                                  (253) and P3 is 5, the controls 5, 6 and 7
;***                                  will be redrawed.
;***                     255       -> redraws all controls inside the window
;***                                  toolbar.
;***                - if E is between 240 and 254:
;***                D = ID of the first control, which should be redrawed.
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws one, all or a specified number of controls inside the
;***                window toolbar. Use this command to update the screen display,
;***                if you made changes in the toolbar.
;******************************************************************************
        ld c,MSC_DSK_WINTOL
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINTIT
;******************************************************************************
;*** Name           Window_Redraw_Title_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the title bar of a window. Use this command to update
;***                the screen display, if you changed the text of the window
;***                title.
;******************************************************************************
        ld c,MSC_DSK_WINTIT
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINSTA
;******************************************************************************
;*** Name           Window_Redraw_Statusbar_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the status bar of a window. Use this command to update
;***                the screen display, if you changed the text of the status bar.
;******************************************************************************
        ld c,MSC_DSK_WINSTA
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINMVX
;******************************************************************************
;*** Name           Window_Set_ContentX_Command
;*** Input          A  = Window ID
;***                DE = new X offset of the visible window content
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    If the size of the window content is larger than the visible
;***                part, you can scroll its X offset with this command. The
;***                command works also, if the window is not resizeable by the
;***                user.
;******************************************************************************
        ld c,MSC_DSK_WINMVX
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINMVY
;******************************************************************************
;*** Name           Window_Set_ContentY_Command
;*** Input          A  = Window ID
;***                DE = new Y offset of the visible window content
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    If the size of the window content is larger than the visible
;***                part, you can scroll its Y offset with this command. The
;***                command works also, if the window is not resizeable by the
;***                user.
;******************************************************************************
        ld c,MSC_DSK_WINMVY
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINTOP
;******************************************************************************
;*** Name           Window_Focus_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Takes the window to the front position on the screen.
;******************************************************************************
        ld c,MSC_DSK_WINTOP
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINMAX
;******************************************************************************
;*** Name           Window_Size_Maximize_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is minimized or restored
;*** Description    Maximizes a window. A maximized window has a special status,
;***                where it can't be moved to another screen position.
;******************************************************************************
        ld c,MSC_DSK_WINMAX
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINMIN
;******************************************************************************
;*** Name           Window_Size_Minimize_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is maximized or restored
;*** Description    Minimizes a window. It will disappear from the screen and can
;***                only be accessed by the user via the task bar.
;******************************************************************************
        ld c,MSC_DSK_WINMIN
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINMID
;******************************************************************************
;*** Name           Window_Size_Restore_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is maximized or minimized
;*** Description    Restores the window or the size of the window, if it was
;***                minimized or maximized before.
;******************************************************************************
        ld c,MSC_DSK_WINMID
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINMOV
;******************************************************************************
;*** Name           Window_Set_Position_Command
;*** Input          A  = Window ID
;***                DE = new X window position
;***                HL = new Y window position
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is not maximized
;*** Description    Moves the window to another position on the screen. This will
;***                not work, if the window is maximized.
;******************************************************************************
        ld c,MSC_DSK_WINMOV
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINSIZ
;******************************************************************************
;*** Name           Window_Set_Size_Command
;*** Input          A  = Window ID
;***                DE = new window width
;***                HL = new window height
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Resizes a window. This command will always work, even if the
;***                window is not resizeable by the user.
;***                Please note, that the size always refers to the visible content
;***                of the window, not to the whole window including the control
;***                elements. So with title bar, scroll bars etc. a window can have
;***                a bigger size on the screen.
;******************************************************************************
        ld c,MSC_DSK_WINSIZ
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINCLS
;******************************************************************************
;*** Name           Window_Close_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Closes the window. The desktop manager will remove it from the
;***                screen.
;******************************************************************************
        ld c,MSC_DSK_WINCLS
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINDIN
;******************************************************************************
;*** Name           Window_Redraw_ContentExtended_Command
;*** Input          A  = Window ID
;***                E  = -1, control ID or negative number of controls
;***                     000 - 239 -> the control with the specified ID will be
;***                                  redrawed.
;***                     240 - 254 -> redraws -P2 controls, starting from
;***                                  control P3. As an example, if P2 is -3
;***                                  (253) and P3 is 5, the controls 5, 6 and 7
;***                                  will be redrawed.
;***                     255       -> redraws all controls inside the window
;***                                  content.
;***                - if E is between 240 and 254:
;***                D = ID of the first control, which should be redrawed.
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Redraws one, all or a specified number of controls inside the
;***                window content. This command is identical with MSC_DSK_WININH
;***                with the exception, that it always works but with less speed.
;***                For more information see MSC_DSK_WININH.
;******************************************************************************
        ld c,MSC_DSK_WINDIN
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINSLD
;******************************************************************************
;*** Name           Window_Redraw_Slider_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the two slider of the window, with which the user can
;***                scroll the content. Sliders will only be displayed, if the
;***                window is resizeable.
;***                Usally you should use MSC_DSK_WINMVX and MSC_DSK_WINMVY to
;***                scroll the content of the window. These commands will update
;***                the sliders by themself.
;***                If you manipulate the content position in the window data
;***                record by yourself, you can use this command to update the
;***                screen display.
;******************************************************************************
        ld c,MSC_DSK_WINSLD
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINPIN
;******************************************************************************
;*** Name           Window_Redraw_ContentArea_Command
;*** Input          A  = Window ID
;***                E  = -1, control ID or negative number of controls
;***                     000 - 239 -> the control with the specified ID will be
;***                                  redrawed.
;***                     240 - 254 -> redraws -P2 controls, starting from
;***                                  control P3. As an example, if P2 is -3
;***                                  (253) and P3 is 5, the controls 5, 6 and 7
;***                                  will be redrawed.
;***                     255       -> redraws all controls inside the window
;***                                  content.
;***                HL = Area X begin inside the window content
;***                BC = Area Y begin
;***                IX = Area X length
;***                IY = Area Y length
;***                - if E is between 240 and 254:
;***                D = ID of the first control, which should be redrawed.
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    This command works like MSC_DSK_WINDIN, but it updates only a
;***                specified area inside the window content. Changes outside the
;***                area won't be updated. This command is especially useful for
;***                updating large graphics, if only a part of the graphic should
;***                be updated, and you don't want to loose performance with
;***                updating the other parts of it, too.
;***                For more information see MSC_DSK_WINDIN and MSC_DSK_WININH.
;******************************************************************************
        ld (AppMsgB+06),bc
        ld (AppMsgB+08),ix
        ld (AppMsgB+10),iy
        ld c,MSC_DSK_WINPIN
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_WINSIN
;******************************************************************************
;*** Name           Window_Redraw_SubControl_Command
;*** Input          A  = Window ID
;***                E  = control collection ID
;***                D  = ID of the sub control inside the control collection
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    This command works like MSC_DSK_WINDIN, but it updates only one
;***                sub control inside a control collection. This command currently
;***                doesn't support the redrawing of multiple sub controls.
;***                For additional information see also MSC_DSK_WINDIN.
;******************************************************************************
        ld c,MSC_DSK_WINSIN
        jp SyDesktop_SendMessage
EndLib

Library SyDesktop_MODGET
;******************************************************************************
;*** Name           DesktopService_ScreenModeGet
;*** Input          -
;*** Output         E  = Screen mode
;***                     0 = 160 x 200, 16 colours
;***                     1 = 320 x 200,  4 colours (standard mode)
;***                     2 = 640 x 200,  2 colours
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Returns the current screen resolution and number of possible
;***                colours.
;******************************************************************************
        ld a,DSK_SRV_MODGET
        jp SyDesktop_Service
EndLib

Library SyDesktop_MODSET
;******************************************************************************
;*** Name           DesktopService_ScreenModeSet
;*** Input          E  = Screen mode
;***                     0 = 160 x 200, 16 colours
;***                     1 = 320 x 200,  4 colours (standard mode)
;***                     2 = 640 x 200,  2 colours
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sets the screen resolution and number of possible colours.
;******************************************************************************
        ld a,DSK_SRV_MODSET
        jp SyDesktop_Service
EndLib

Library SyDesktop_COLGET
;******************************************************************************
;*** Name           DesktopService_ColourGet
;*** Input          E  = Colour number (0-15)
;*** Output         D  = Bit[0-3] blue  component (0-15)
;***                     Bit[4-7] green component (0-15)
;***                L  = Bit[0-3] red   component (0-15)
;*** Destroyed      AF,BC,E,H,IX,IY
;*** Description    Returns the definition of a colours. Please note, that you
;***                always have a range of 4096, even if the computer is not a CPC
;***                PLUS, as the system recalculates the colour for standard CPCs
;***                (factor 5,33 for each component).
;******************************************************************************
        ld a,DSK_SRV_COLGET
        jp SyDesktop_Service
EndLib

Library SyDesktop_COLSET
;******************************************************************************
;*** Name           DesktopService_ColourSet
;*** Input          E  = Colour number (0-15)
;***                D  = Bit[0-3] blue  component (0-15)
;***                     Bit[4-7] green component (0-15)
;***                L  = Bit[0-3] red   component (0-15)
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Defines one colour. Please note, that you always have a range
;***                of 4096, even if the computer is not a CPC PLUS, as the system
;***                recalculates the colour for standard CPCs (factor 5,33 for each
;***                component).
;******************************************************************************
        ld a,DSK_SRV_COLSET
        jp SyDesktop_Service
EndLib

Library SyDesktop_DSKBGR
;******************************************************************************
;*** Name           DesktopService_RedrawBackground
;*** Input          -
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Redraws the desktop background.
;******************************************************************************
        ld a,DSK_SRV_DSKBGR
        jp SyDesktop_Service
EndLib

Library SyDesktop_DSKPLT
;******************************************************************************
;*** Name           DesktopService_RedrawComplete
;*** Input          -
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Redraws the complete screen. The background, the task bar and
;***                all windows will be updated.
;******************************************************************************
        ld a,DSK_SRV_DSKPLT
        jp SyDesktop_Service
EndLib


;### SUB ROUTINES #############################################################

Library SyDesktop_Service
;******************************************************************************
;*** Input          A     = Function
;***                DE,HL = additional parameters
;*** Output         DE,HL = returned parameters
;*** Destroyed      AF,BC,IX,IY
;*** Description    Sends a service request message to the desktop manager,
;***                waits for the answer and returns with the result
;******************************************************************************
        ld c,MSC_DSK_DSKSRV
        ld (SyDSrvN),a
        push af
        call SyDesktop_SendMessage
        pop af
        cp 1
        jr z,SyDSrv1
        cp 3
        jr z,SyDSrv1
        cp 5
        ret nz
SyDSrv1 call SyDesktop_WaitMessage
        cp MSR_DSK_DSKSRV
        jr nz,SyDSrv1
        ld a,(SyDSrvN)
        cp (iy+1)
        jr nz,SyDSrv1
        ld e,(iy+2)
        ld d,(iy+3)
        ld l,(iy+4)
        ld h,(iy+5)
        ret
SyDSrvN db 0
EndLib

Library SyDesktop_SendMessage
;******************************************************************************
;*** Input          C  = Command
;***                A  = Window ID
;***                DE,HL = additional parameters
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the desktop manager, which includes the
;***                window ID and additional parameters
;******************************************************************************
        ld iy,AppMsgB
        ld (iy+0),c
        ld (iy+1),a
        ld (iy+2),e
        ld (iy+3),d
        ld (iy+4),l
        ld (iy+5),h
        db #dd:ld h,2       ;2 is the number of the desktop manager process
        ld a,(AppPrzN)
        db #dd:ld l,a
        rst #10
        ret
EndLib

Library SyDesktop_WaitMessage
;******************************************************************************
;*** Input          -
;*** Output         IY = message buffer
;***                A  = first byte in the Message buffer (IY+0)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the desktop manager, which includes the
;***                window ID and additional parameters
;******************************************************************************
        ld iy,AppMsgB
SyDWMs1 db #dd:ld h,2       ;2 is the number of the desktop manager process
        ld a,(AppPrzN)
        db #dd:ld l,a
        rst #08             ;wait for a desktop manager message
        db #dd:dec l
        jr nz,SyDWMs1
        ld a,(iy+0)
        ret
EndLib
