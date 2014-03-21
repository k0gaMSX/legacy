;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@              S Y M S T U D I O   S Y S T E M   L I B R A R Y               @
;@                     - SYMBOS MICRO KERNEL FUNCTIONS -                      @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author: Prodatron / Symbiosis
;Date:   17.05.2007

;The kernel is the heart of SymbOS and controls the core resources of the
;system.
;This library supports you in using the kernel functions regarding processes
;and timers.
;The existance of "AppPrzN" (a byte, where the ID of the applications process
;is stored) and "AppMsgB" (the message buffer, 14 bytes, which are placed in
;the transfer ram area) is required.


Library SyKernel_MTADDP
;******************************************************************************
;*** Name           Multitasking_Add_Process_Command
;*** Input          HL = Stack address (see notes below)
;***                A  = Ram bank (0-15)
;***                E  = Priority (1=highest, 7=lowest)
;*** Output         A  = Process ID
;***                CF = Success status
;***                     0 = OK
;***                     1 = the process couldn't been added, as the maximum
;***                         number of processes (32) has been reached
;*** Destroyed      BC,DE,HL,IX,IY
;*** Description    Adds a new process with a given priority and starts it
;***                immediately.
;***                Application processes usually will be started with priority 4.
;***                Note, that the desktop manager process runs with priority 1,
;***                the system manager process with 2. If you start a process,
;***                which should do some long and intensive calculation, you should
;***                choose a priority greater than 4, so that other applications
;***                will not be disturbed.
;***                The stack must always be placed between #C000 and #FFFF
;***                (transfer ram area). It must contain the start address of the
;***                process (or timer) routine at offset 12 and may contain the
;***                initial values of the registers. You can choose the size of the
;***                stack buffer by yourself, just be sure, that it is large
;***                enough.
;***                At offset 13 there must be a free byte. In this byte the kernel
;***                will write the ID of the process (or timer) after it has been
;***                started.
;*** Example(stack)                ds 128              ;Stack buffer
;***                stack_pointer: dw 0                ;initial value for IY
;***                               dw 0                ;initial value for IX
;***                               dw 0                ;initial value for HL
;***                               dw 0                ;initial value for DE
;***                               dw 0                ;initial value for BC
;***                               dw 0                ;initial value for AF
;***                               dw process_start    ;process start address
;***                process_id:    db 0                ;kernel writes the ID here
;******************************************************************************
        ld c,MSC_KRL_MTADDP
        call SyKernel_Message
        xor a
        cp l
        ld a,h
        ret
EndLib

Library SyKernel_MTDELP
;******************************************************************************
;*** Name           Multitasking_Delete_Process_Command
;*** Input          A  = Process ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Stops an existing process and deletes it.
;******************************************************************************
        ld c,MSC_KRL_MTDELP
        ld l,a
        jp SyKernel_Message
EndLib

Library SyKernel_MTADDT
;******************************************************************************
;*** Name           Multitasking_Add_Timer_Command
;*** Input          HL = Stack address (see notes below)
;***                A  = Ram bank (0-15)
;*** Output         A  = Timer ID
;***                CF = Success status
;***                     0 = OK
;***                     1 = the timer couldn't been added, as the maximum
;***                         number of timers (32) has been reached
;*** Destroyed      BC,DE,HL,IX,IY
;*** Description    Adds a new timer and starts it immediately. Timers will be
;***                called 50 or 60 times per second, depending on the screen vsync
;***                frequency. Please see MSC_KRL_MTADDP for information about the
;***                stack.
;***                PLEASE NOTE: A timer is nothing else than an usual process with
;***                a special priority. That means, that you have to implement a
;***                looping code. Don't use a "RET" at the end of the timer routine
;***                but a "RST #30:JP CODE_START". The code should also be very
;***                short. As the timers have the highest priority, they would
;***                slow down the whole system, if they require too much CPU time.
;******************************************************************************
        ld c,MSC_KRL_MTADDT
        call SyKernel_Message
        xor a
        cp l
        ld a,h
        ret
EndLib

Library SyKernel_MTDELT
;******************************************************************************
;*** Name           Multitasking_Delete_Timer_Command
;*** Input          A  = Timer ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Stops an existing timer and deletes it.
;******************************************************************************
        ld c,MSC_KRL_MTDELT
        ld l,a
        jp SyKernel_Message
EndLib

Library SyKernel_MTSLPP
;******************************************************************************
;*** Name           Multitasking_Sleep_Process_Command
;*** Input          A  = Process ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Puts an existing process into the sleep mode. It is stopped and
;***                does not run anymore, until it receives a message, or until it
;***                will be wacked up again (see MSC_KRL_MTWAKP).
;***                Usually this command is not needed, as a process can put itself
;***                into the sleep mode with the MSGSLP restart (see above).
;******************************************************************************
        ld c,MSC_KRL_MTSLPP
        ld l,a
        jp SyKernel_Message
EndLib

Library SyKernel_MTWAKP
;******************************************************************************
;*** Name           Multitasking_WakeUp_Process_Command
;*** Input          A  = Process ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Wakes up a process, which was sleeping before. A process will
;***                be wacked up, too, when another process is sending a message to
;***                it.
;******************************************************************************
        ld c,MSC_KRL_MTWAKP
        ld l,a
        jp SyKernel_Message
EndLib

Library SyKernel_TMADDT
;******************************************************************************
;*** Name           Timer_Add_Counter_Command
;*** Input          HL = Counter byte address
;***                E  = Counter byte ram bank (0-15)
;***                A  = Process ID
;***                B  = Speed (counter will be increased every x/50 second)
;*** Output         CF = Success status
;***                     0 = OK
;***                     1 = the timer couldn't been added, as the maximum
;***                         number of counter (16) has been reached
;*** Description    Adds a counter for a process. You need to specify a byte
;***                anywhere in the memory. This byte then will be increased every
;***                B/50 seconds. So if you want, that the kernel increases it once
;***                per second, you have to set B to 50.
;***                As an example you could check this byte regulary, and if it has
;***                been changed you call an event routine. This is much easier and
;***                faster than setting up an own timer.
;******************************************************************************
        ld c,MSC_KRL_TMADDT
        call SyKernel_Message
        xor a
        cp l
        ret
EndLib

Library SyKernel_TMDELT
;******************************************************************************
;*** Name           Timer_Delete_Counter_Command
;*** Input          HL = Counter byte address
;***                E  = Counter byte ram bank (0-15)
;*** Output         -
;*** Description    Stops the specified counter. Please note, that this will be
;***                done automatically, if the process should be deleted.
;******************************************************************************
        ld c,MSC_KRL_TMDELT
        jp SyKernel_Message
EndLib

Library SyKernel_TMDELP
;******************************************************************************
;*** Name           Timer_Delete_AllProcessCounters_Command
;*** Input          A  = Process ID
;*** Output         -
;*** Description    Stops all counters of one process. Please note, that this will
;***                be done automatically, if the process should be deleted.
;******************************************************************************
        ld c,MSC_KRL_TMDELP
        ld l,a
        jp SyKernel_Message
EndLib


;### SUB ROUTINES #############################################################

Library SyKernel_Message
;******************************************************************************
;*** Input          C        = Command
;***                HL,E,A,B = Additional parameters
;*** Output         HL       = returned parameters
;*** Destroyed      AF,BC,DE,IX,IY
;*** Description    Sends a message to the kernel, waits for the answer and
;***                returns the result
;******************************************************************************
        ld iy,AppMsgB
        ld (iy+0),c
        ld (iy+1),l
        ld (iy+2),h
        ld (iy+3),e
        ld (iy+4),a
        ld (iy+5),b
        ld a,c
        add 128
        ld (SyKMsgN),a
        db #dd:ld h,1       ;1 is the number of the kernel process
        ld a,(AppPrzN)
        db #dd:ld l,a
        rst #10
SyKMsg1 db #dd:ld h,1       ;1 is the number of the kernel process
        ld a,(AppPrzN)
        db #dd:ld l,a
        rst #08             ;wait for a kernel message
        db #dd:dec l
        jr nz,SyKMsg1
        ld a,(SyKMsgN)
        cp (iy+0)
        jr nz,SyKMsg1
        ld l,(iy+1)
        ld h,(iy+2)
        ret
SyKMsgN db 0
EndLib
