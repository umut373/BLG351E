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

            mov.w    #hash, R10
            mov.w    #split_id, R11

            mov.w    #0d, R12               ; i = 0

mainloop    cmp     #6d, R12                ; while i < 3
            jge     stop

            mov.w    R11, R5
            add.w    R12, R5
            mov.w    0(R5), R4              ; A = split_id[i]

            mov.w    #29d, R5               ; B = 29
            jmp     RPD                     ; R7 = RDP()

store       rla     R7                      ; R7 = R7*2 for indexing 16-bit
store_cont  mov.w   R7, R5
            add.w   R10, R5
            mov.w   0(R5), R6               ; R6 = hash[R7]

            cmp     #0d, R6                 ; check R6 == 0 (is hash[R7] empty?)
            jeq     store_end               ; if empty store split_id[i] in it

            inc.w   R7                      ; else increment R7
            jmp     store_cont              ; check again

store_end   add.w   R10, R7
            mov.w   R4,    0(R7)            ; hash[R7] = split_id[i]

            incd.w  R12                     ; i++
            jmp     mainloop


RPD         mov.w   R5, R6                  ; C = B
            mov.w   R4, R7                  ; D = A

            mov.w   R4, R8
            rra     R8                      ; R8 = A/2

L1          cmp     R6, R8                  ; while C < A/2
            jl      L2
            rla     R6                      ; C = C*2
            jmp     L1

L2          cmp     R5, R7                  ; while B > D
            jl      store                   ; else store

            cmp     R6, R7                  ; compare C with D
            jl      div_C                   ; if C > D skip
            sub.w   R6, R7                  ; else D = D - C

div_C       rra     R6                      ; C = C/2
            jmp     L2



stop        jmp     stop


            .data
hash        .space  58
split_id    .space  6

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
