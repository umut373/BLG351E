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
Setup       bis.b   #11111111b, &P1DIR      ; set all P1 pins as OUTPUT
            bis.b   #00001111b, &P2DIR      ; set P2.0, P2.1, P2.2 and P2.3 as OUTPUT
            mov.b   #00000000b, &P1OUT      ; clear outputs of P1
            bic.b   #00001111b, &P2OUT      ; clear outputs of P2

Mainloop    mov     #numbers, R4            ; pointer to numbers
            mov     #displays, R5           ; pointer to displays

L1          bic.b   #00001111b, &P2OUT      ; turn all displays off
            mov.b   @R4+, &P1OUT            ; show corresponding number at the display
            mov.b   @R5+, &P2OUT            ; turn corresponding display on

            cmp     #lastNumber, R4         ; if pointer reaches to end of array
            jge     Mainloop                ; reset

            jmp     L1                      ; else continue


displays    .byte 00000001b, 00000010b, 00000100b, 00001000b

numbers     .byte 00111111b, 00000110b, 01011011b, 01001111b
lastNumber
                                            

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
