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

            mov.w   #151d, R4              ; A = 151
            mov.w   #8d, R5                ; B = 8

            mov.w   R5, R6                 ; C = B
            mov.w   R4, R7                 ; D = A

            mov.w   R4, R8
            rra     R8                     ; R8 = A/2

L1          cmp     R6, R8                 ; while C < A/2
            jl      L2
            rla     R6                     ; C = C*2
            jmp     L1

L2          cmp     R5, R7                 ; while B > D
            jl      stop                   ; else stop

            cmp     R6, R7                 ; compare C with D
            jl      div_C                  ; if C > D skip
            sub.w   R6, R7                 ; else D = D - C

div_C       rra     R6                     ; C = C/2
            jmp     L2


stop        jmp     stop

                                            
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
