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

            mov     #0d, R10                ; x = 0
            mov     #0d, R11                ; w = 0

;-------------------------------------------------------------------------------
Mainloop    mov     #numbers, R12           ; pointer to numbers
            mov     #displays, R13          ; pointer to displays

L1          bic.b   #00001111b, &P2OUT      ; turn all displays off
            mov.b   @R12+, &P1OUT           ; show corresponding number at the display
            mov.b   @R13+, &P2OUT           ; turn corresponding display on

            cmp     #lastNumber, R12        ; if pointer reaches to end of array
            jge     Mainloop                ; reset

            jmp     L1                      ; else continue

;--------------------------------------------------------------------------------------------------
ISR         dint                            ; disable interrupts
            clr     &P2IFG                  ; clear the flag

            push    #1d                     ; push seed into stack as first parameter
            call    #MSWS                   ; call MSWS(seed), generate random val according to seed
            call    #Display                ; display MSWS(seed) in 7-segment display

            eint                            ; enable interrupts
            reti

;-------------------------------------------------------------------------------
Mod         mov     4(SP), R4               ; mov first parameter to R4
            mov     2(SP), R5               ; mov second parameter to R5

            cmp     R5, R4                  ; if R4 < R5
            jl      Mod_ret                 ; return

Mod_L1      cmp     R5, R4                  ; while R4 >= R5
            jl      Mod_ret

            sub     R5, R4                  ; R4 = R4 - R5
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
MSWS        mov     2(SP), R4               ; mov first parameter to R4

            push    R10                     ; push R10 (x) as first parameter
            push    R10                     ; push R10 (x) as second parameter
            call    #Mul                    ; call Mul(x, x) = square(x)
            pop     R10                     ; x = square(x)

            mov     2(SP), R4

            add     R4, R11                 ; w = w + seed
            add     R11, R10                ; x = x + w

            and     #00FFh, R10

            mov     R10, R5
            rla     R5
            rla     R5
            rla     R5
            rla     R5                      ; R5 = x << 4
            mov     R10, R6
            rra     R6
            rra     R6
            rra     R6
            rra     R6                      ; R6 = x >> 4

            bis     R6, R5                  ; R5 = (x << 4) | (x >> 4)

            push    R5                      ; push R5 to stack as first parameter
            push    #128d                   ; push 128 to stack as second parameter
            call    #Mod                    ; call Mod(R5, 128)
            pop     R5                      ; R5 = R5 mod 128, random number between 0-128

            pop     R15                     ; save return address to R15
            add     #2d, SP                 ; clear stack
            push    R5                      ; return R5
            push    R15                     ; push return address to stack
            ret

;-------------------------------------------------------------------------------
Div         mov     4(SP), R4               ; mov first parameter to R4
            mov     2(SP), R5               ; mov second parameter to R5

            mov     #0d, R6                 ; result = 0

Div_L1      cmp     R5, R4                  ; while R4 >= R5
            jl      Div_ret

            sub     R5, R4                  ; R4 = R4 - R5
            inc     R6                      ; R6 = R6 + 1
            jmp     Div_L1

Div_ret     pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack
            push    R4                      ; return remainder
            push    R6                      ; return division
            push    R15                     ; push return address to stack
            ret

;-------------------------------------------------------------------------------
BCD         mov     2(SP), R4               ; mov first parameter to R4

            mov     #0d, R7
            mov     #0d, R8
            mov     #0d, R9

            push    R4                      ; push R4 to stack as first parameter
            push    #10d                    ; push 10 to stack as second parameter
            call    #Div                    ; call Div(R4, 10)
            pop     R5                      ; save division to R5
            pop     R6                      ; save remainder to R6

            add     #array, R6
            mov.b   0(R6), R9               ; R9 = array[R6]

            cmp     #10d, R5                ; if R5 (division) > 10
            jge     div_again               ; divide R5

            add     #array, R5
            mov.b   0(R5), R8               ; else R8 = array[R5]

            mov.b   &array, R7              ; R7 = array[0]

            jmp     BCD_ret                 ; return

div_again   push    R5                      ; push R5 to stack as first parameter
            push    #10d                    ; push 10 to stack as second parameter
            call    #Div                    ; call Div(R5, 10)
            pop     R5                      ; save division to R5
            pop     R6                      ; save remainder to R6

            add     #array, R6
            mov.b   0(R6), R8               ; R8 = array[R6]

            add     #array, R5
            mov.b   0(R5), R7               ; R7 = array[R5]

BCD_ret     pop     R15                     ; save return address to R15
            add     #2d, SP                 ; clear stack
            push.b  R7                      ; return first display value (hundreds place)
            push.b  R8                      ; return second display value (tens place)
            push.b  R9                      ; return third display value (ones place)
            push    R15                     ; push return address to stack
            ret

;-------------------------------------------------------------------------------
Display     mov     2(SP), R4               ; mov first parameter to R4

            push    R4                      ; push R4 to stack as parameter
            call    #BCD                    ; call BCD(R4), find binary coded values of R4
            mov     #numbers, R5
            pop.b   2(R5)                   ; save ones place to numbers[2]
            pop.b   1(R5)                   ; save tens place to numbers[1]
            pop.b   0(R5)                   ; save hundreds place to number[0]

            pop     R15                     ; save return address to R15
            add     #2d, SP                 ; clear stack
            push    R15                     ; push return address to stack
            ret

;--------------------------------------------------------------------------------------------------
displays    .byte 00000010b, 00000100b, 00001000b

array       .byte 00111111b, 00000110b, 01011011b, 01001111b, 01100110b, 01101101b, 01111101b, 00000111b, 01111111b, 01101111b

;--------------------------------------------------------------------------------------------------
            .data
numbers     .byte 00111111b, 00111111b, 00111111b
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
            .sect   ".int03"                ; Port Interrupt Vector
            .short  ISR
            
