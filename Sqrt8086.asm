Name "Sqrt8086"

org 100h

.MODEL small

.STACK 512d

.DATA

readMsg1 db "Type a number to calculate the SquareRoot of it (Max: 65025):$"
readMsg2 db "* Decimal precision is not calculated for numbers greater than 654 *$"
loadingMsg db "Calculating...$"
resultMsg db "Average SquareRoot: $"
source dw 0
aprx dw 0
aprxBuffer dw 0
aprxDec dw 0
aprxDecBuffer dw 0
stackTmp dw 0
inputArray db 6 DUP(?)
charLength dw 0


.CODE

call read
mov source, ax

; Printing loadingMsg
call printCRLF
mov ah, 09
lea dx, loadingMsg
int 21h
mov dx, 0

mov ax, source
call calcSqrt

mov ax, aprx
mov bx, aprxDec
call printSqrt

ret



read:

    pop stackTmp
    
    ; Printing readMsg1
    mov ah, 09
    lea dx, readMsg1
    int 21h
    mov dx, 0
    
    call printCRLF
    
    ; Printing readMsg2
    mov ah, 09
    lea dx, readMsg2
    int 21h
    mov dx, 0
    
    call printCRLF
    
    mov ah, 02
    mov dl, 41
    int 21h
    
    
    
    lea si, inputArray
    mov cx, 6
    readLoop:
    
        mov ah, 01
        int 21h
        
        cmp al, 13
        je fnshRead
        
        mov ah, 0
        sub al, 48
        mov [si], ax
        inc si
        
        inc charLength
        
    Loop readLoop:
    fnshRead:
    
    lea si, inputArray
    mov cx, charLength
    mov dx, 0
    convertLoop:
    
         mov ax, 10
         mul dx ; AX = DX * 10
         
         mov bx, [si]
         mov bh, 0
         inc si
         add ax, bx ; AX = (DX * 10) + BX
         
         mov dx, ax
    
    Loop convertLoop
    fnshConvert:
    mov ax, dx
    
    push stackTmp
ret
    
; Calculates the Sqrt of a 16 bit integer
; @arg: source -> AX
; @returns: integer result -> AX, decimal result -> BX 
calcSqrt:
    
    pop stackTmp
    
    ; aprox = (source / 200) + 2
    mov bx, 200
    xor dx, dx
    div bx
    add ax, 2
    mov aprx, ax 
    
    calcLoop:
        mov dx, source
        mov bx, aprx
        
        ; If aprox == aproxBuffer it means that the squareroot of source 
        ;  is a floating point number, which is not supported by the 8068
        ;  and thus, can't be calculated precisely. 
        cmp bx, aprxBuffer
        je testDecimal
        jmp continueSqrt
        testDecimal:
        cmp ax, aprxDecBuffer
        je fnshAvrgSqrt
        continueSqrt:
        mov aprxBuffer, bx
        mov aprxDecBuffer, ax
        
        ; checking if aprox² == source     
        mov ax, bx
        xor dx, dx
        mul bx
        cmp ax, source
        je fnshSqrt
        
        ; aprox = ((source / aprox) + aprox) / 2       
        mov ax, source
        mov bx, aprx
        xor dx, dx
        div bx
        add ax, aprx
        shr ax, 1
        mov aprx, ax
        
        mov dx, 100
        mul dx
        push ax
        
        ; aprox = ((source * 100 / aprx) + aprx * 100) / 2
        mov ax, source
        mov dx, 100
        mul dx ; source * 100
        
        xor dx, dx ; DX = 0
        div bx ; (source * 100 / aprox)
        mov cx, ax
        
        mov ax, 100
        xor dx, dx
        mul bx ; (aprx * 100)
        
        add ax, cx ; (source * 100 / aprx) + aprx * 100)
        shr ax, 1 ; ((source * 100 / aprx) + aprx * 100) / 2
        
        pop cx ; CX = aprx (current) * 100
        sub ax, cx ; (((source * 100 / aprx) + aprx * 100) / 2) - aprx * 100
        
        mov aprxDec, ax
    
    JMP calcLoop
    
    ; The result is an integer number
    fnshSqrt:
    mov bx, 0
    mov aprxDec, 0
    
    ; The result is the lower round of a floating point number
    fnshAvrgSqrt:
    
    
    
    push stackTmp

ret
    
printSqrt:

    push bx
    push ax
    
    call printCRLF
    
    mov ah, 09
    lea dx, resultMsg
    int 21h
    mov dx, 0
    
    pop ax
    pop bx
    
    call printNumber
    
    cmp source, 655
    jae fnshPrintSqrt
    
    mov ah, 02
    mov dl, 46
    int 21h
    
    mov ax, bx
    call printNumber
    
    fnshPrintSqrt:
    ret
    

printNumber:

    cmp ax, 100
    jae printThreeDigits
    cmp ax, 10
    jae printTwoDigits
    
    ; 1 digit:
    printOneDigit:
    
    mov ah, 02
    mov dl, al
    add dl, 48
    int 21h
    ret
    
    ; 2 digits:
    printTwoDigits:
    aam
    add ah, 48
    add al, 48
    
    mov cx, ax
    mov ah, 02
    
    mov dl, ch
    int 21h
    
    
    
    mov dl, cl
    int 21h
    ret
    
    ; 3 digits:
    printThreeDigits:
    push bx
    
    aam
    mov dh, al
    mov al, ah
    mov ah, 0
    aam
    
    add ah, 48
    add al, 48
    add dh, 48
    
    mov cx, ax
    mov ah, 02
    
    mov dl, ch
    int 21h
    
    mov dl, cl
    int 21h
    
    mov dl, dh
    int 21h
    
    pop bx     
    ret

; Printing CRLF (carriage return + line feed)
printCRLF:

    mov ah, 02
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    ret