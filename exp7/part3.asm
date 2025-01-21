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
            bis.b   #00001110b, &P2DIR      ; set P2.1, P2.2 and P2.3 as OUTPUT
            bic.b   #00100000b, &P2DIR      ; set P2.5 as INPUT
            mov.b   #00000000b, &P1OUT      ; clear outputs of P1
            bic.b   #00001110b, &P2OUT      ; clear outputs of P2

            bis.b   #00100000b, &P2IE       ; enable interrupt at P2.5
            and.b   #11011111b, &P2SEL      ; set 0 P2SEL.5
            and.b   #11011111b, &P2SEL2     ; set 0 P2SEL.5

            bis.b   #00100000b, &P2IES      ; high-to-low interrupt mode
            clr     &P2IFG                  ; clear the flag
            eint                            ; enable interrupts

            mov.w   #5d, R7

;-------------------------------------------------------------------------------
Stop        jmp     Stop

;--------------------------------------------------------------------------------------------------
ISR         dint                            ; disable interrupts
            clr     &P2IFG                  ; clear the flag

            mov.w   #random_nums, R9

L1          push    R7                      ; push seed (R10) into stack
            call    #NumGen                 ; call NumGen(R10)
            pop     R7

            push    R7
            push    #8d
            call    #Mod
            pop     R8

            mov.b   R8, 0(R9)
            inc     R9

            add     #uniform, R8
            mov.b   0(R8), R10
            inc     R10
            mov.b   R10, 0(R8)

            cmp     #lastElement, R9
            jl      L1


            eint                            ; enable interrupts
            reti

;-------------------------------------------------------------------------------
Mod         mov     4(SP), R4               ; mov first parameter to R4
            mov     2(SP), R5               ; mov second parameter to R5

            cmp     R5, R4                  ; if R4 < R5
            jl      Mod_ret                 ; return

Mod_L1      cmp     R5, R4                  ; while R4 >= R5
            jl      Mod_ret

            sub     R5, R4                  ; R4 = R4 - R4
            jmp     Mod_L1


Mod_ret     pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack
            push    R4                      ; return R4 (R4 mod R5)
            push    R15                     ; push return address to stack

            ret

;-------------------------------------------------------------------------------
Mul         mov     4(SP), R4               ; mov first parameter to R4
            mov     2(SP), R5               ; mov second parameter to R5

            mov     #0d, R6                 ; result = 0

Mul_L1      cmp     #0d, R5                 ; if R5 = 0
            jeq     Mul_ret                 ; return

            add     R4, R6                  ; R6 = R6 + R4
            dec     R5                      ; R5 = R5 - 1

            jmp     Mul_L1

Mul_ret     pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack
            push    R6                      ; return result
            push    R15                     ; push return address to stack

            ret

;-------------------------------------------------------------------------------
NumGen      mov     2(SP), R4               ; mov first parameter to R4

            push    R4                      ; push R4 to stack as first param
            push    R4                      ; push R4 to stack as second param
            call    #Mul                    ; call Mul(R4, R4)

            push    #13d                    ; push 13 (q) to stack as first param
            push    #11d                    ; push 11 (p) to stack as second param
            call    #Mul                    ; call Mul(13, 11)

            call    #Mod                    ; call Mod(power(s,2), M)
            pop     R4                      ; R4 = power(s,2) mod M

            pop     R15                     ; save return address to R15
            add     #2d, SP                 ; clear stack
            push    R4                      ; return result (next number in sequnece)
            push    R15                     ; push return address to stack

            ret

;-------------------------------------------------------------------------------
            .data
random_nums .space  128
lastElement

uniform     .space  8

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
            .short  ISR
