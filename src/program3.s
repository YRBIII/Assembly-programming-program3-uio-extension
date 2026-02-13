@---------------
@ YungBrinney
@ program_3
@---------------

.global main                       @ make main visible to linker
.syntax unified                    @ use unified ARM syntax
.arm                               @ assemble for ARM mode (not Thumb)

.equ SYS_READ,  3                  @ Linux syscall number: read
.equ SYS_WRITE, 4                  @ Linux syscall number: write
.equ SYS_EXIT,  1                  @ Linux syscall number: exit (not used here)

.section .text                     @ start of code section

main:                              @ program entry label
loop:                              @ infinite loop label

    mov r6, #0                     @ clear digit count register (r6)
    ldr r8, =digitbuf              @ load address of digit buffer into r8

    bl read_input                  @ get input; returns r6=count and digitbuf filled
    bl digits_to_decimal           @ convert digitbuf -> decimal; result stored in r4

    mov r0, r4                     @ move decimal value into r0 (argument)
    bl dec_to_binary               @ convert decimal -> binary digits; result stored in r5

    mov r0, r5                     @ move binary digits number into r0 (argument)
    bl binary_to_decimal           @ convert back to decimal; result returned in r0

    bl print_number                @ print decimal result in r0
    bl newline                     @ print newline character

    b loop                         @ repeat forever

@ -------------------------
@ read up to 3 digits
@ -------------------------
read_input:                        @ function: read/validate 1–3 digits
    push {r4,r5,r7,r8,lr}          @ save registers we will use + return address

start_over:                        @ restart point for bad input
    @ print prompt                 @ comment marker for prompt section
    ldr r1, =prompt                @ r1 = address of prompt string
    mov r2, #18                    @ r2 = length of prompt string (bytes)
    mov r0, #1                     @ r0 = stdout file descriptor (1)
    mov r7, #SYS_WRITE             @ r7 = syscall number for write
    svc 0                          @ call kernel: write(1, prompt, 18)

    mov r6, #0                     @ reset digit counter to 0
    ldr r8, =digitbuf              @ r8 = base address of digit buffer

read_loop:                         @ loop reading characters
    bl read_char                   @ read one byte; returns char in r0
    cmp r0, #10                    @ compare char to '\n' (newline)
    beq done_input                 @ if newline, finish input

    cmp r0, #'0'                   @ check if char < '0'
    blt bad                        @ if below '0', invalid input
    cmp r0, #'9'                   @ check if char > '9'
    bgt bad                        @ if above '9', invalid input

    cmp r6, #3                     @ have we already stored 3 digits?
    beq too_many                   @ if yes and we got another digit, reject

    strb r0, [r8, r6]              @ store digit character into digitbuf[count]
    add r6, r6, #1                 @ count++
    b read_loop                    @ keep reading until newline

done_input:                        @ reached newline
    cmp r6, #0                     @ did user enter nothing?
    beq bad                        @ if 0 digits, treat as invalid

    pop {r4,r5,r7,r8,pc}           @ restore regs and return (pc = return address)

bad:                               @ invalid input path (non-digit or empty)
    bl flush_line                  @ flush remaining chars until newline
    ldr r1, =error_msg             @ r1 = address of invalid message
    mov r2, #26                    @ r2 = length of invalid message
    mov r0, #1                     @ stdout
    mov r7, #SYS_WRITE             @ write syscall
    svc 0                          @ print invalid message
    b start_over                   @ prompt again

too_many:                          @ too many digits path (>3 digits)
    bl flush_line                  @ flush remaining chars until newline
    ldr r1, =toomany_msg           @ r1 = address of too-many message
    mov r2, #28                    @ r2 = length of too-many message
    mov r0, #1                     @ stdout
    mov r7, #SYS_WRITE             @ write syscall
    svc 0                          @ print too-many message
    b start_over                   @ prompt again

@ -------------------------
@ read one char
@ -------------------------
read_char:                         @ function: reads one byte from stdin
    push {r1,r2,r7,lr}             @ save regs used in this function
    ldr r1, =inchar                @ r1 = address of 1-byte input storage
    mov r2, #1                     @ r2 = number of bytes to read (1)
    mov r0, #0                     @ r0 = stdin file descriptor (0)
    mov r7, #SYS_READ              @ r7 = syscall number for read
    svc 0                          @ call kernel: read(0, inchar, 1)
    ldr r1, =inchar                @ reload address of inchar
    ldrb r0, [r1]                  @ load the byte into r0
    pop {r1,r2,r7,pc}              @ restore regs and return

flush_line:                        @ function: consume chars until newline
    push {lr}                      @ save return address
flush_loop:                        @ loop label
    bl read_char                   @ read a char into r0
    cmp r0, #10                    @ is it newline?
    bne flush_loop                 @ if not newline, keep flushing
    pop {pc}                       @ return after newline found

@ -------------------------
@ convert digits to decimal
@ -------------------------
digits_to_decimal:                 @ function: digitbuf + count -> decimal
    push {r1,r2,r7,r8,lr}          @ save working regs + return

    mov r4, #0                     @ r4 will hold decimal value (start at 0)
    mov r7, #0                     @ r7 = index i = 0
    ldr r8, =digitbuf              @ r8 = base address of digitbuf

d_loop:                            @ loop over digits
    cmp r7, r6                     @ compare i to count
    beq d_done                     @ if i == count, finish

    ldrb r0, [r8, r7]              @ r0 = digitbuf[i] (ASCII)
    sub r0,   r0, #'0'               @ convert ASCII '0'..'9' to 0..9

    mov r1, r4                     @ r1 = current value
    mov r2, #10                    @ r2 = 10
    mul r4, r1, r2                 @ r4 = r4 * 10
    add r4, r4, r0                 @ r4 = r4 + digit

    add r7, r7, #1                 @ i++
    b d_loop                       @ repeat

d_done:                            @ done converting
    pop {r1,r2,r7,r8,pc}           @ restore regs and return (r4 holds decimal)

@ -------------------------
@ decimal -> binary digits
@ example: 13 -> 1101
@ -------------------------
dec_to_binary:                     @ function: decimal in r0 -> binary digits in r5
    push {r1,r2,r3,r6,lr}          @ save regs used in this routine

    mov r5, #0                     @ r5 = result binary digits number
    mov r6, #1                     @ r6 = place value (1,10,100,...)
    mov r1, r0                     @ r1 = working copy of decimal input

    cmp r1, #0                     @ check if input is 0
    bne b_loop                     @ if not zero, go do loop
    mov r5, #0                     @ if 0, binary digits number is 0
    pop {r1,r2,r3,r6,pc}           @ return

b_loop:                            @ build binary digits from LSB to MSB
    and r2, r1, #1                 @ r2 = r1 & 1 (current bit)
    mul r3, r2, r6                 @ r3 = bit * place
    add r5, r5, r3                 @ add into result

    mov r3, #10                    @ r3 = 10
    mul r6, r3, r6                 @ place *= 10 (next digit position)

    mov r1, r1, lsr #1             @ r1 >>= 1 (next bit)
    cmp r1, #0                     @ done when working value reaches 0
    bne b_loop                     @ loop if more bits

    pop {r1,r2,r3,r6,pc}           @ return with r5 holding binary digits number

@ -------------------------
@ binary digits -> decimal
@ -------------------------
binary_to_decimal:                 @ function: binary digits in r0 -> decimal in r0
    push {r1,r2,r3,r4,lr}          @ save regs used

    mov r1, r0                     @ r1 = working copy of binary digits number
    mov r2, #0                     @ r2 = decimal result (start 0)
    mov r3, #1                     @ r3 = power of 2 (1,2,4,...)

bd_loop:                           @ process each binary digit
    cmp r1, #0                     @ if no digits left, finish
    beq bd_done                    @ exit loop

    @ get last digit               @ comment
    mov r4, r1                     @ r4 = temp copy
    mov r0, #10                    @ r0 = 10 (divisor)

    @ manual divide by 10          @ compute quotient in r5 and remainder in r4
    mov r5, #0                     @ r5 = quotient counter
div_loop:                          @ repeated subtraction division
    cmp r4, r0                     @ compare temp to 10
    blt div_done                   @ if temp < 10, remainder found
    sub r4, r4, r0                 @ temp -= 10
    add r5, r5, #1                 @ quotient++
    b div_loop                     @ continue subtracting

div_done:                          @ division finished
    mov r1, r5                     @ r1 = quotient (remove last digit from number)

    mul r4, r3, r4                 @ remainder(bit) * power_of_2
    add r2, r2, r4                 @ add to decimal result

    add r3, r3, r3                 @ power_of_2 *= 2
    b bd_loop                      @ continue with next digit

bd_done:                           @ done converting
    mov r0, r2                     @ move final decimal result to r0
    pop {r1,r2,r3,r4,pc}           @ return

@ -------------------------
@ print number
@ -------------------------
print_number:                      @ function: print unsigned number in r0
    push {r1,r2,r3,r4,r5,r7,lr}    @ save regs used

    ldr r5, =outbuf_end            @ r5 points to end of output buffer
    mov r4, r0                     @ r4 = number to print

    cmp r4, #0                     @ check if number is 0
    bne p_loop                     @ if not zero, do conversion loop

    sub r5, r5, #1                 @ move back one byte
    mov r1, #'0'                   @ ASCII '0'
    strb r1, [r5]                  @ store '0' in buffer
    b p_write                      @ go print it

p_loop:                            @ convert number to ASCII digits
    mov r2, #10                    @ r2 = 10 (divisor)
    mov r3, #0                     @ r3 = quotient counter

p_div:                             @ repeated subtraction divide by 10
    cmp r4, r2                     @ compare value with 10
    blt p_done                     @ if value < 10, remainder found
    sub r4, r4, r2                 @ value -= 10
    add r3, r3, #1                 @ quotient++
    b p_div                        @ keep dividing

p_done:                            @ have remainder in r4 and quotient in r3
    add r4, r4, #'0'               @ remainder -> ASCII digit
    sub r5, r5, #1                 @ move back in buffer
    strb r4, [r5]                  @ store digit
    mov r4, r3                     @ r4 = quotient (continue)
    cmp r4, #0                     @ done when quotient is 0
    bne p_loop                     @ loop if more digits

p_write:                           @ write buffer to stdout
    ldr r1, =outbuf_end            @ r1 = end of buffer
    sub r2, r1, r5                 @ r2 = number of bytes to write
    mov r1, r5                     @ r1 = start of digits in buffer
    mov r0, #1                     @ stdout fd
    mov r7, #SYS_WRITE             @ write syscall
    svc 0                          @ write(1, r1, r2)

    pop {r1,r2,r3,r4,r5,r7,pc}     @ restore regs and return

newline:                           @ function: print newline
    push {r1,r2,r7,lr}             @ save regs
    ldr r1, =nl                    @ r1 = address of "\n"
    mov r2, #1                     @ r2 = length 1
    mov r0, #1                     @ stdout
    mov r7, #SYS_WRITE             @ write syscall
    svc 0                          @ write newline
    pop {r1,r2,r7,pc}              @ return

.section .data                     @ start of data section

prompt:     .ascii "Enter 1-3 digits: "          @ prompt string
error_msg:  .ascii "Invalid input. Try again.\n" @ invalid input message
nl:         .ascii "\n"                          @ newline string
toomany_msg:.ascii "Too many digits. Try again.\n" @ too many digits message

inchar:     .byte 0                 @ 1-byte input buffer for read_char
digitbuf:   .space 4                @ buffer for up to 3 digits + spare byte
outbuf:     .space 16               @ buffer for printing numbers
outbuf_end:                          @ label marking end of outbuf
