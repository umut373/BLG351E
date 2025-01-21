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
            bis.b   #040h, &P2IE            ; enable interrupt at P2.6
            and.b   #0BFh, &P2SEL           ; set 0 P2SEL.6
            and.b   #0BFh, &P2SEL2          ; set 0 P2SEL2.6

            bis.b   #040h, &P2IES           ; high-to-low interrupt mode
            clr     &P2IFG                  ; clear the flag
            eint                            ; enable interrupts

            mov.b   #11111111b, &P1DIR
            mov.b   #00000000b, &P1OUT
            bis     #00000001b, &P2DIR
            bis     #00000001b, &P2OUT
            mov.w   #array, R4
            mov.w   #lastElement, R5

Mainloop    mov.b   0(R4), &P1OUT
            call    #Delay

            inc.w   R4
            inc.w   R4

            cmp     R5, R4
            jl      Mainloop

            sub.w   #10d, R4
            jmp     Mainloop


Delay       mov.w   #0Ah,R14                ; Delay to R14
L2          mov.w   #07A00h, R15
L1          dec.w   R15                     ; Decrement R15
            jnz     L1
            dec.w   R14
            jnz     L2
            ret


ISR         dint                            ; disable interrupts
            clr     &P2IFG                  ; clear the flag

            dec.w   R4

            eint                            ; enable interrupts
            reti                            ; return from ISR

array       .byte 00111111b, 00000110b, 01011011b, 01001111b, 01100110b, 01101101b, 01111101b, 00000111b, 01111111b, 01101111b
lastElement
                                            
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
            .sect   ".int03"                ; Port Interrupt Vector
            .short    ISR
