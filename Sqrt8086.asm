Name "Sqrt8086"

org 100h

.MODEL small

.STACK 512d

.DATA

readMsg1 db "Type a number to calculate the SquareRoot of it (Max: 65534):$"
loadingMsg db "Calculating...$"
resultMsg db "Average SquareRoot: $"
stackCacheLevel1 dw 0
stackCacheLevel2 dw 0
inputArray db 6 DUP(?)
precisionFactor dw 100
charLength db 0


.CODE

call read
mov bx, ax

lea dx, loadingMsg
call printS

mov ax, bx
call calcSqrt

call printFloat

call finish

; Saves registers state
saveState:
    pop stackCacheLevel2
    push ax
    push bx
    push cx
    push dx
    push stackCacheLevel2
ret


; Loads registers state    
loadState:
    pop stackCacheLevel2
    pop dx
    pop cx
    pop bx
    pop ax
    push stackCacheLevel2
ret


; Reads a number from Cin with 5 characters max.
;@returns: Number -> AX
read:
    pop stackCacheLevel1
    
    lea dx, readMsg1
    call printS
    
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
    xor cx, cx
    mov cl, charLength
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
    
    push stackCacheLevel1
ret

    
; Calculates the Sqrt of a 16 bit integer
; @args: source -> AX
; @returns: integer result -> AX, decimal result -> BX 
calcSqrt:
    
    pop stackCacheLevel1
    push ax ; Stack = source
    
    ; aprox = (source / 200) + 2
    xor dx, dx
    mov bx, 200
    div bx
    add ax, 2
    mov bx, ax
    
    push ax ; Stack = aprx 
    
    
    ; BX -> aprx 
    ; CX -> source
    calcLoop:
    
        pop bx ; Stack = aprox(current)
        pop cx ; Stack = source
        
        ; If aprx == aprx(cache) it means that the squareroot of source 
        ;   is a floating point number, which is not supported by the 8068
        ;   and thus, can't be calculated precisely.
        pop ax 
        cmp bx, ax
        je fnshAvrgSqrt
        
        ; checking if aprx² == source     
        mov ax, bx ; AX = aprx
        xor dx, dx
        mul bx
        cmp ax, cx
        je fnshSqrt
        
        push bx ; Cache of aprx to be compared in the next loop iteration
        
        ; aprx(BX) = ((source(CX) / aprx) + aprx) / 2
        mov ax, cx ; AX = source
        xor dx, dx
        div bx
        add ax, bx
        shr ax, 1
        mov bx, ax
        
        push cx ; Stack = source
        push bx ; Stack = aprx(current)
        
        ; Stack = aprx * 100
        mov dx, precisionFactor
        mul dx
        push ax
        
        ; aprox = ((source * 100 / aprx) + aprx * 100) / 2
        mov ax, precisionFactor
        mul cx ; source * 100
        
        div bx ; (source * 100 / aprx)
        mov cx, ax
        
        mov ax, precisionFactor
        mul bx
        
        add ax, cx ; (source * 100 / aprx) + aprx * 100)
        adc dx, 0  ; (source * 100 / aprx) + aprx * 100) + Carry
        
        mov cx, 2 
        div cx ; AX = ((source * 100 / aprx) + aprx * 100) / 2
        
        pop bx ; BX = aprx * 100 lower
        
        sub ax, bx ; AX = (((source * 100 / aprx) + aprx * 100) / 2) - aprx * 100
        
        pop bx ; BX = aprx
        pop cx ; CX = source
        pop dx ; DX = aprx(cache)
        
        push ax ; Stack = aprx(decimal)
        push dx
        push cx
        push bx
    
    JMP calcLoop
    
    ; The result is an integer number
    fnshSqrt:
    mov ax, bx ; AX = aprox(Sqrt)
    pop bx
    mov bx, 0 ; BX = Sqrt(decimal)
    push stackCacheLevel1
    ret
    
    ; The result is the lower round of a floating point number
    fnshAvrgSqrt:
    mov ax, bx ; AX = aprox(Sqrt)
    pop bx ; BX = Sqrt(decimal)
    push stackCacheLevel1
    ret

; Prints a String in Cout.
; @args: String pointer -> DX    
printS:

    call printCRLF
    mov ah, 09
    int 21h
    mov dx, 0
ret

; Prints a 16Bit-Integer + 8Bit-Precision(decimal) Number
;@args: Number -> AX, Precision -> BX     
printFloat:

    push bx
    push ax
    
    call printCRLF
    lea dx, resultMsg
    call printS
    
    pop ax
    pop bx
    
    call printNumber
    
    mov ah, 02
    mov dl, 46
    int 21h
    
    mov ax, bx
    call printNumber
    
    fnshprintFloat:
ret
    
; Prints an Integer number.
;@args: Number -> AX
printNumber:

    call saveState

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
    
    call loadState
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
    
    call loadState
    ret
    
    ; 3 digits:
    printThreeDigits:
    
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
    
    call loadState     
    ret

; Printing CRLF (carriage return + line feed)
printCRLF:

    call saveState

    mov ah, 02
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    
    call loadState
    
ret

; Closes the program
finish:
    mov ah, 4Ch
    int 21h