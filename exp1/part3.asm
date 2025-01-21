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

SetupP3     mov.b   #11111111b, &P1DIR
            bic.b   #10000000b, &P2DIR
            mov.b   #00000000b, &P1OUT
            mov.b   #00000000b, &P2OUT

            mov.b   #00000001b, R6
            mov.b   #0d, R8

Mainloop1   bit.b   #10000000b, &P2IN
            jnz     Stop

            bis.b   R6, &P1OUT
            inc     R8
            rla     R6

            mov.w   #00500000, R15
L1          dec.w   R15
            jnz     L1

            cmp     #8d, R8
            jeq     SetupP3
            jmp     Mainloop1

Stop        jmp     Stop

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
            
