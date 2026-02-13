
@******************************************************
@ name: uio.s
@
@ description: program to read chars from stdin and
@ render to stdout.  Program has no termination.
@
@******************************************************
.global main @entry point  
.text @ code area
main:	ldr r1,=prompt @prompt character
	mov r2,#1 @print 1 char
        mov r0,#1 @stdio
        mov r7,#4 @write service
        svc 0 @call service
l1:	ldr r1,=inbuff @point at 1st char of buffer
	mov r2,#2 @read one char
	mov r0,#0 @read from stdio
	mov r7,#3 @service for read
	svc 0   @call service
	ldr r1,=inbuff @point at input buff
	mov r2,#2 @buffer includes 2 chars newline
	mov  r0,#1  @stdio
        mov r7, #4 @service number for write
        svc 0 @call service
        b main
.data @data follows 
inbuff:	.space 20 @buffer of 20 bytes
prompt: .ascii ">" @prompt
.end
