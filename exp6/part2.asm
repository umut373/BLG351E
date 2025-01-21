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
            bic.b   #01110000b, &P2DIR      ; set P2.4, P2.5 and P2.6 as INPUT
            mov.b   #00000000b, &P1OUT      ; clear outputs of P1
            bic.b   #00001111b, &P2OUT      ; clear outputs of P2

            mov     #displays, R6           ; pointer to displays
            mov     #numbers, R7            ; pointer to numbers

Timer       bis     #0204h, &TA0CTL         ; reset timer and set clock source as SMCLK
            mov     #028F6h, &TA0CCR0       ; set value to compare (set for 10ms period)
            mov     #0010h, &TA0CCTL0       ; set the mode to compare and enable interrupt

Interrupt   bis.b   #01110000b, &P2IE       ; enable interrupt at P2.4, P2.5 and P2.6
            and.b   #10001111b, &P2SEL      ; set 0 P2SEL.4, P2SEL.5 and P2SEL.6
            and.b   #10001111b, &P2SEL2     ; set 0 P2SEL.4, P2SEL.5 and P2SEL.6

            bis.b   #01110000b, &P2IES      ; high-to-low interrupt mode
            clr     &P2IFG                  ; clear the flag
            eint                            ; enable interrupts

;--------------------------------------------------------------------------------------------------
Mainloop    mov     #numbers, R10           ; pointer to numbers
            mov     #displays, R11          ; pointer to displays

L1          bic.b   #00001111b, &P2OUT      ; turn all displays off
            mov.b   @R10+, &P1OUT           ; show corresponding number at the display
            mov.b   @R11+, &P2OUT           ; turn corresponding display on

            cmp     #lastNumber, R10        ; if pointer reaches to end of array
            jge     Mainloop                ; reset

            jmp     L1                      ; else continue

;--------------------------------------------------------------------------------------------------
TISR        dint                            ; disable interrupts
            bic     #0001h, &TA0CCTL0       ; clear timer interrupt flag

            mov     &centiseconds, R8        ; increment centiseconds
            inc.b   R8

            cmp     #100d, R8               ; if centiseconds is 100
            jge     centi_ovf               ; reset centiseconds and increment seconds

            mov     R8, &centiseconds       ; else save centiseconds and return
            call    #BCD_centiS
            jmp     TISR_ret

centi_ovf   mov     #0d, &centiseconds      ; set centiseconds to 0
            call    #BCD_centiS

            mov     &seconds, R8            ; increment seconds
            inc.b   R8

            cmp     #100d, R8               ; if seconds is 100
            jge     sec_ovf                 ; reset seconds

            mov     R8, &seconds            ; else save seconds and return
            call    #BCD_second
            jmp     TISR_ret

sec_ovf     mov     #0d, &seconds           ; set seconds to 0
            call    #BCD_second

TISR_ret    eint                            ; enable interrupts
            reti                            ; return from interrupt

;--------------------------------------------------------------------------------------------------
ISR         dint                            ; disable interrupts

            bit.b   #00100000b, &P2IFG      ; if reset button has been pressed
            jnz     reset                   ; jump to reset

            bit.b   #01000000b, &P2IFG      ; if stop button has been pressed
            jnz     check_save              ; check start button for save best time

            jmp     start                   ; otherwise, must be start button has been pressed

check_save  bit.b   #00010000b, &P2IFG      ; if also start button has been pressed
            jnz     save                    ; jump to save

            jmp     stop                    ; else jump to stop

reset       bis     #0004h, &TA0CCTL0       ; reset timer

            mov     #0d, &seconds           ; set centiseconds to 0
            mov     #0d, &centiseconds      ; set seconds to 0

            call    #BCD_second
            call    #BCD_centiS

            jmp     ISR_ret

stop        mov     #0200h, &TA0CTL         ; stop timer
            jmp     ISR_ret

start       mov     #0210h, &TA0CTL         ; start timer
            jmp     ISR_ret

save        mov     &bestSeconds, R8        ; save best seconds to R8
            mov     &bestCSeconds, R9       ; save best centiseconds to R9

            cmp     &seconds, R8            ; if current seconds > best seconds
            jl      new_best                ; save current time

            jnz     ISR_ret

            cmp     &centiseconds, R9       ; if current centiseconds > best centiseconds
            jl      new_best                ; save current time

            jmp     ISR_ret

new_best    mov     &seconds, R8            ; save current seconds as best seconds
            mov     R8, &bestSeconds

            mov     &centiseconds, R9       ; save current centiseconds as best centiseconds
            mov     R9, &bestCSeconds

ISR_ret     clr     &P2IFG                  ; clear the flag
            eint                            ; enable interrupts
            reti                            ; return from interrupt

;--------------------------------------------------------------------------------------------------
BCD_second  push    &seconds                ; push seconds to stack
            push    #10d                    ; push 10 to stack
            call    #Div                    ; call Div(seconds, 10)

            pop     R4                      ; save division to R4
            pop     R5                      ; save remainder to R5

            add     #array, R4              ; indexing to BCD-digitd of divison
            add     #array, R5              ; indexing to BCD-digitd of remainder

            mov.b   0(R4), 0(R7)            ; save BCD-digitd of divison to numbers[0]
            mov.b   0(R5), 1(R7)            ; save BCD-digitd of remainder to numbers[1]

            ret                             ; return from function

;--------------------------------------------------------------------------------------------------
BCD_centiS  push    &centiseconds           ; push centiseconds to stack
            push    #10d                    ; push 10 to stack
            call    #Div                    ; call Div(centiseconds, 10)

            pop     R4                      ; save division to R4
            pop     R5                      ; save remainder to R5

            add     #array, R4              ; indexing to BCD-digitd of divison
            add     #array, R5              ; indexing to BCD-digitd of remainder

            mov.b   0(R4), 2(R7)            ; save BCD-digitd of divison to numbers[2]
            mov.b   0(R5), 3(R7)            ; save BCD-digitd of remainder to numbers[3]

            ret                             ; return from function

;--------------------------------------------------------------------------------------------------
Sub         mov     4(SP), R4               ; mov first parameter to R4
            mov     2(SP), R5               ; mov second parameter to R5
            sub     R5, R4                  ; R4 = R4 - R5

            pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack
            push    R4                      ; push result to stack
            push    R15                     ; push return address to stack

            ret                             ; return from function

;--------------------------------------------------------------------------------------------------
Div         mov     4(SP), R4               ; mov first parameter to R4
            mov     2(SP), R5               ; mov second parameter to R5

            mov     R4, R8                  ; temp = R4
            mov     #0d, R9                 ; result = 0

call_sub    push    R8                      ; push first parameter (temp) to stack
            push    R5                      ; push second parameter (R5) to stack
            call    #Sub                    ; call Sub(R8, R5)

            pop     R8                      ; save result to R8
            mov     4(SP), R4               ; save R4
            mov     2(SP), R5               ; save R5

            cmp     #0d, R8                 ; if result < 0
            jl      Div_ret                 ; return

            inc     R9                      ; result++

            cmp     #0d, R8                 ; if R8 == 0
            jeq     Div_ret

            cmp     R5, R8                  ; if R8 >= R5
            jge     call_sub

Div_ret     pop     R15                     ; save return address to R15
            add     #4d, SP                 ; clear stack
            cmp     #0d, R8                 ; if result >= 0
            jge     cont                    ; continue

            add    R5, R8                   ; else add divider to result

cont        push    R8                      ; push remainder to stack
            push    R9                      ; push result to stack
            push    R15                     ; push return address to stack

            ret                             ; return from function

;--------------------------------------------------------------------------------------------------
displays    .byte 00000001b, 00000010b, 00000100b, 00001000b

array       .byte 00111111b, 00000110b, 01011011b, 01001111b, 01100110b, 01101101b, 01111101b, 00000111b, 01111111b, 01101111b

;--------------------------------------------------------------------------------------------------
            .data
seconds         .word   00h
centiseconds    .word   00h

bestSeconds     .word   00h
bestCSeconds    .word   00h

numbers         .byte 00111111b, 00111111b, 00111111b, 00111111b
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
            .sect   ".int09"                 ; Timer Interrupt Vector
            .short  TISR
            .sect   ".int03"                ; Port Interrupt Vector
            .short  ISR
