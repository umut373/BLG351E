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

            bic.b   #00000001b, &P1DIR      ; set P1.0 as input
            bis.b   #00001100b, &P2DIR      ; set P2.2 and P2.3 as output
            bic.b   #00001100b, &P2OUT      ; set outputs P2.2 and P2.3 as low

            mov.b   #00000000b, R6          ; R6 holds the state, if 0 output P2.2 is high and output P2.3 is low
                                            ; else output P2.2 is low and output P2.3 is high

Mainloop    bit.b   #00000001b, &P1IN       ; check the input P1.0
            jeq     Mainloop                ; wait until input P1.5 is high

            cmp     #0, R6                  ; if the state R6 is not 0
            jnz     State2                  ; go to State2

State1      mov.b   #1d, R6                 ; set the state R6 to 1
            bic.b   #00001000b, &P2OUT      ; turn off P2.3
            bis.b   #00000100b, &P2OUT      ; turn on P2.2
            jmp     Debounce

State2      mov.b   #0d, R6                 ; set the state R6 to 0
            bic.b   #00000100b, &P2OUT      ; turn off P2.2
            bis.b   #00001000b, &P2OUT      ; turn on P2.3
            jmp     Debounce


Debounce    bit.b   #00000001b, &P1IN       ; wait until the input P1.0 debounces
            jeq     Mainloop
            jmp     Debounce

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
