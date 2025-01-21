;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

            push    #30d                    ; push first parameter to stack
            push    #3d                     ; push second parameter to stack
            call    #Add                    ; call Add(30, 3)
            pop     R4                      ; save result to R4 (33)

            push    #30d                    ; push first parameter to stack
            push    #3d                     ; push second parameter to stack
            call    #Sub                    ; call Sub(30, 3)
            pop     R4                      ; save result to R4 (27)

            push    #30d                    ; push first parameter to stack
            push    #3d                     ; push second parameter to stack
            call    #Mul                    ; call Mul(30, 3)
            pop     R4                      ; save result to R4 (90)

            push    #30d                    ; push first parameter to stack
            push    #3d                     ; push second parameter to stack
            call    #Div                    ; call Div(30, 3)
            pop     R4                      ; save result to R4 (10)

stop        jmp     stop

;-------------------------------------------------------------------------------
Add         mov.w   4(SP), R4               ; mov first parameter to R4
            mov.w   2(SP), R5               ; mov second parameter to R5
            add.w   R5, R4                  ; R4 = R4 + R5

            pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack
            push    R4                      ; push result to stack
            push    R15                     ; push return address to stack

            ret                             ; return from function

;-------------------------------------------------------------------------------
Sub         mov.w   4(SP), R4               ; mov first parameter to R4
            mov.w   2(SP), R5               ; mov second parameter to R5
            sub.w   R5, R4                  ; R4 = R4 - R5

            pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack
            push    R4                      ; push result to stack
            push    R15                     ; push return address to stack

            ret                             ; return from function

;-------------------------------------------------------------------------------
Mul         mov.w   4(SP), R4               ; mov first parameter to R4
            mov.w   2(SP), R5               ; mov second parameter to R5

            mov.w   #0d, R8

            call    #twos_comp

            mov.w   #0d, R6                 ; i = 0
            mov.w   #0d, R7                 ; result = 0

call_add    push    R7                      ; push first parameter (result) to stack
            push    R4                      ; push second parameter (R4) to stack
            call    #Add                    ; call Add(R7, R4)

            pop     R7                      ; save result to R7
            mov.w   4(R1), R4               ; save R4
            mov.w   2(R1), R5               ; save R5

            inc.w   R6                      ; i++
            
            call    #twos_comp

            cmp     R5, R6                  ; if R6 < R5
            jl      call_add

            pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack

            cmp     #0d, R8
            jeq     mul_ret

            inv     R7
            add.w   #1d, R7

mul_ret     push    R7                      ; push result to stack
            push    R15                     ; push return address to stack

            ret                             ; return from function

;-------------------------------------------------------------------------------
twos_comp   cmp     #0d, R5
            jge     ret_twos

            mov.w   #1d, R8
            inv     R5
            add.w   #1d, R5

ret_twos    ret

;-------------------------------------------------------------------------------
Div         mov.w   4(SP), R4               ; mov first parameter to R4
            mov.w   2(SP), R5               ; mov second parameter to R5

            mov.w   R4,   R6                ; temp = R4
            mov.w   #0d, R7                 ; result = 0

call_sub    push    R6                      ; push first parameter (temp) to stack
            push    R5                      ; push second parameter (R5) to stack
            call    #Sub                    ; call Sub(R6, R5)

            pop     R6                      ; save result to R6
            mov.w   4(R1), R4               ; save R4
            mov.w   2(R1), R5               ; save R5

            inc.w   R7                      ; result++

            cmp     #0d, R6                 ; if R6 == 0
            jeq     Sub_ret

            cmp     R5, R6                  ; if R6 >= R5
            jge     call_sub

Sub_ret     pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack
            push    R7                      ; push result to stack
            push    R15                     ; push return address to stack

            ret                             ; return from function

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
