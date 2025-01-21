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
result      .bss    resultArray, 5           ; Declare a 5-byte buffer for the result

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

Setup       mov     #array, R5
            mov     #resultArray, R10

Mainloop    mov.b   @R5, R6
            inc     R5
            call    #func1
            mov.b   R6, 0(R10)
            inc     R10
            cmp     #lastElement, R5
            jlo     Mainloop
            jmp     finish

func1       dec.b   R6
            mov.b   R6, R7
            call    #func2
            mov.b   R7, R6
            ret

func2       xor.b   #0FFh, R7
            ret

; Integer array
array       .byte   1, 0, 127, 55
lastElement .word   array + 4               ; Point to the last element of the array

finish      nop

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
