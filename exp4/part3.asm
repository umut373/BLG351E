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

            push    #array_A                ; push first parameter to stack
            push    #array_B                ; push second parameter to stack
            push    #0d                     ; push third parameter to stack
            push    #4d                     ; push fourth parameter to stack
            call    #dot                    ; call dot(A, B, 0, 4)
            pop     R4                      ; save result to R4 (91)

stop        jmp     stop

;-------------------------------------------------------------------------------
dot         mov.w   8(SP), R4               ; mov first parameter (A) to R4
            mov.w   6(SP), R5               ; mov second parameter (B) to R5
            mov.w   4(SP), R6               ; mov third parameter (i) to R6
            mov.w   2(SP), R7               ; mov fourth parameter (N) to R7

            cmp     R6, R7                  ; if R6 == R7
            jeq     base_case

            push    0(R4)                   ; push A[0] to stack
            push    0(R5)                   ; push B[0] to stack
            call    #Mul                    ; call Mul(A[0], B[0])

            pop     R8                      ; save result to R8
            mov.w   8(SP), R4               ; save R4
            mov.w   6(SP), R5               ; save R5
            mov.w   4(SP), R6               ; save R6
            mov.w   2(SP), R7               ; save R7
            push    R8                      ; save R8 for recursion

            add.w   #2, R4                  ; R4 = A + 1
            add.w   #2, R5                  ; R5 = B + 1
            inc.w   R6                      ; R6 = i + 1

            push    R4                      ; push first parameter (A + 1) to stack
            push    R5                      ; push second parameter (B + 1) to stack
            push    R6                      ; push third parameter (i + 1) to stack
            push    R7                      ; push fourth parameter (N) to stack
            call    #dot                    ; call dot(A+1, B+1, i+1, N)

            pop     R9                      ; save result to R9
            pop     R8                      ; retrive R8

            add.w   R9, R8                  ; R8 = R8 + R9

            pop     R15                     ; save return address to R15
            add     #8d, SP                 ; clear stack
            push    R8                      ; push result to stack
            push    R15                     ; push return address to stack

            ret                             ; return from function

base_case   pop     R15                     ; save return address to R15
            add     #8d, SP                 ; clear stack
            push    #0d                     ; push result to stack
            push    R15                     ; push return address to stack

            ret                             ; return from function

;-------------------------------------------------------------------------------
Add         mov.w   4(SP), R4               ; mov first parameter to R4
            mov.w   2(SP), R5               ; mov second parameter to R5
            add.w   R5, R4                  ; R4 = R4 + R5

            pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack
            push    R4                      ; push result to stack
            push    R15                     ; push return address to stack

            ret                             ; return from function

;-------------------------------------------------------------------------------
Mul         mov.w   4(SP), R4               ; mov first parameter to R4
            mov.w   2(SP), R5               ; mov second parameter to R5

            mov.w   #0d, R8

            call    #twos_comp

            mov.w   #0d, R6      ; i = 0
            mov.w   #0d, R7      ; result = 0

call_add    push    R7           ; push first parameter (result) to stack
            push    R4           ; push second parameter (R4) to stack
            call    #Add         ; call Add(R7, R4)

            pop     R7           ; save result to R7
            mov.w   4(R1), R4    ; save R4
            mov.w   2(R1), R5    ; save R5

            inc.w   R6           ; i++

            call    #twos_comp

            cmp     R5, R6       ; if R6 < R5
            jl      call_add

            pop     R15          ; save return address to R15
            add     #4d, SP      ; clear stack

            cmp     #0d, R8
            jeq     mul_ret

            inv     R7
            add.w   #1d, R7

mul_ret     push    R7           ; push result to stack
            push    R15          ; push return address to stack

            ret                  ; return from function

;-------------------------------------------------------------------------------
twos_comp   cmp     #0d, R5
            jge     twos_ret

            mov.w   #1d, R8
            inv     R5
            add.w   #1d, R5

twos_ret    ret

; Integer arrays ,
array_A     .word   15 , 3 , 7 , 5
array_B     .word   2 , -1, 7 , 3

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
