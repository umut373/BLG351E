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

            .data
counter: .byte 0x00

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

            bis.b   #00001111b, &P1DIR      ; set P1.0, P1.1, P1.2 and P1.3 as output
            bic.b   #00000010b, &P2DIR      ; set P2.1 as input
            bic.b   #00001111b, &P1OUT      ; set outputs P1.0, P1.1, P1.2 and P1.3 as low

Mainloop    bit.b   #00000010b, &P2IN       ; check the input P2.1
            jeq     Mainloop                ; wait until input P2.1 is high

            inc.b   counter                 ; increment the counter by 1
            and.b   #0x0F, counter          ; mask the counter with 0x0F so that when counter reaches #16d it will reset

            bic.b   #0x0F, &P1OUT           ; display the value of the counter using LEDs
            bis.b   counter, &P1OUT


Debounce    bit.b   #00000010b, &P2IN       ; wait until the input P2.1 debounces
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
