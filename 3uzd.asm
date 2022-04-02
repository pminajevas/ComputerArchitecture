.MODEL small
.STACK 100h
.DATA
        calculatedAddress DW 0000h
        bpIndex DB 00
        opk DB 00h
        address DB 00h
        
        valBX DW 0000h
        valSI DW 0000h
        valDI DW 0000h
        valBP DW 0000h
        valDis1 DW 0000h
        valDis2 DW 0000h

        newLine DB 13, 10, "$"
        infoMessage DB "Author: Paulius Minajevas Vilnius University 1st group. This program calls interrupt before a command and checks whether the command is MOV second variant and prints some info about it.$"
        commandFoundMessage DB "MOV comand was found!$"

        instMov DB "mov$"

        operByte DB "byte ptr$"
        operWord DB "word ptr$"

        ;mod = 00
        disBXSI DB "BX+SI$"
        disBXDI DB "BX+DI$"
        disBPSI DB "BP+SI$"
        disBPDI DB "BP+DI$"
        disSI DB "SI$"
        disDI DB "DI$"
        disBP DB "BP$"
        disBX DB "BX$"

        ;mod = 01, 10
        disBXSIP DB "BX+SI+poslinkis$"
        disBXDIP DB "BX+DI+poslinkis$"
        disBPSIP DB "BP+SI+poslinkis$"
        disBPDIP DB "BP+DI+poslinkis$"
        disSIP DB "SI+poslinkis$"
        disDIP DB "DI+poslinkis$"
        disBPP DB "BP+poslinkis$"
        disBXP DB "BX+poslinkis$"
        
        disValues DW disBXSI, disBXDI, disBPSI, disBPDI, disSI, disDI, disBP, disBX, disBXSIP, disBXDIP, disBPSIP, disBPDIP, disSIP, disDIP, disBPP, disBXP

.CODE
start:
        MOV AX, @data
        MOV DS, AX
        
        MOV AH, 09h
        LEA DX, infoMessage
        INT 21h
        CALL printNewLine

        MOV AX, 0
        MOV ES, AX
        
        PUSH ES:[4]
        PUSH ES:[6]

        MOV WORD PTR ES:[4], OFFSET interrupt
        MOV ES:[6], CS
        
        PUSHF
        PUSHF
        POP AX
        OR AX, 0100h
        PUSH AX
        POPF

        mov ax, bx
        ;INTERRUPTS BEGIN FROM HERE
        add ax, [bx+si+2345]
        add ax, bx
        mov byte ptr [bx+si], 23h
        mov byte ptr [bx+di], 23h
        mov byte ptr [bp+si], 23h
        mov byte ptr [bp+di], 23h
        mov byte ptr [si], 23h
        mov byte ptr [di], 23h
        mov byte ptr [bx], 23h
        mov byte ptr [bx+si+10], 25h
        ;mov word ptr [bx+di+65], 2323h
        ;mov byte ptr [bp+si+65], 23h
        ;mov word ptr [bp+di+65], 2323h
        ;mov byte ptr [si+65], 23h
        ;mov word ptr [di+65], 2323h
        ;mov byte ptr [bp+65], 23h
        ;mov word ptr [bx+65], 2323h
        ;INTERRUPTS END HERE
        POPF
        POP ES:[6]
        POP ES:[4]
        MOV AH, 4Ch
        MOV AL, 0
        INT 21h

PROC interrupt
        PUSH AX
	    PUSH BX
        PUSH DX
	    PUSH BP
	    PUSH ES
	    PUSH DS
        
        MOV AX, @data
        MOV DS, AX
        
        MOV valBX, BX
        MOV valSI, SI
        MOV valDI, DI
        MOV valBP, BP

        MOV BP, SP
        ADD BP, 12
        MOV BX, [BP]
        MOV ES, [BP+2]
        MOV bpIndex, 02h

        MOV DL, [ES:BX]
        MOV opk, DL

        MOV AL, DL
        AND AL, 0FEh
        CMP AL, 0C6h 
        JNE exitInterrupt

        MOV AH, 09h
        LEA DX, commandFoundMessage
        INT 21h
        CALL printSpace

        MOV DL, [ES:BX+1]
        MOV address, DL

        CALL printAddress

        MOV AL, opk
        CALL hexPrintByte
        MOV AL, address
        CALL hexPrintByte

        CALL checkForDisplacement

        MOV AL, opk
        AND AL, 1
        CMP AL, 1
        JE operaWord
        CALL operandByte
        CALL printEndChars1

        CALL calculateDisplacement
        PUSH AX
        CALL hexPrintWord

        CALL printEndChars2
        POP AX
        MOV BX, AX
        MOV AL, [BX]
        CALL hexPrintByte

        JMP operaEnd
    operaWord:
        CALL operandWord
        CALL printEndChars1
       
        CALL calculateDisplacement
        PUSH AX
        CALL hexPrintWord
        
        CALL printEndChars2
        POP AX
        MOV BX, AX
        MOV AX, [BX]
        CALL hexPrintWord
    operaEnd:
        CALL printNewLine

    exitInterrupt:
        POP DS
	    POP ES
	    POP BP
	    POP	DX
	    POP BX
	    POP	AX
    	IRET
interrupt ENDP

PROC printAddress
        PUSH AX
        PUSH DX
        
        MOV AX, ES
        CALL hexPrintWord
        
        MOV AH, 02h
        MOV DL, ':'
        INT 21h
        
        MOV AX, [BP]
        CALL hexPrintWord
        CALL printSpace
        
        POP DX
        POP AX
        RET
printAddress ENDP

PROC hexPrintWord
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX

        MOV CX, 4
        MOV DX, 0

    pushWordNumber:
        MOV BX, 16
        DIV BX
        PUSH DX

        MOV DX, 0
        DEC CX
        JNZ pushWordNumber

        MOV CX, 4
    printingWord:
        POP DX

        CMP DX, 10
        JB wordNumber

        ADD DX, 55
        JMP continuePrintingWord
    wordNumber:
        ADD DX, 48
    continuePrintingWord:
        MOV AH, 02h
        INT 21h

        DEC CX
        JNZ printingWord

        POP DX
        POP CX
        POP BX
        POP AX
        RET
hexPrintWord ENDP

PROC hexPrintByte
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX

        MOV CX, 2
        MOV DX, 0

    pushByteNumber:
        MOV BX, 16
        DIV BX
        PUSH DX

        MOV DX, 0
        DEC CX
        JNZ pushByteNumber

        MOV CX, 2
    printingByte:
        POP DX

        CMP DX, 10
        JB byteNumber

        ADD DX, 55
        JMP continuePrintingByte
    byteNumber:
        ADD DX, 48
    continuePrintingByte:
        MOV AH, 02h
        INT 21h

        DEC CX
        JNZ printingByte

        POP DX
        POP CX
        POP BX
        POP AX
        RET        
hexPrintByte ENDP

PROC printSpace
        PUSH AX
        PUSH DX

        MOV AX, 0200h
        MOV DL, ' '
        INT 21h

        POP DX
        POP AX
        RET
printSpace ENDP

PROC printNewLine
        PUSH AX
        PUSH DX

        MOV AH, 09h
        LEA DX, newLine
        INT 21h

        POP DX
        POP AX
        RET
printNewLine ENDP

PROC checkForDisplacement

        MOV AL, address
        AND AL, 0C0h -> 1100 0000
        CMP AL, 40h
        JE printDisp1
        CMP AL, 80h
        JE printDisp2
        ADD BX, 2h
        RET
    printDisp1:
        MOV AL, [ES:BX+2]
        MOV AH, 00h
        MOV valDis1, AX
        CALL hexPrintByte
        ADD BX, 3h
        RET
    printDisp2:
        MOV AL, [ES:BX+2]
        MOV AH, 00h
        MOV valDis1, AX
        CALL hexPrintByte

        MOV AL, [ES:BX+3]
        MOV valDis2, AX
        CALL hexPrintByte
        ADD BX, 4h
        RET
checkForDisplacement ENDP

PROC operandByte
        MOV AL, [ES:BX]
        PUSH BX
        CALL hexPrintByte
        CALL printSpace
        
        LEA DX, instMov
        CALL printString
        CALL printSpace
        
        LEA DX, operByte
        CALL printString
        CALL printSpace

        MOV AH, 02h
        MOV DL, '['
        INT 21h
        
        CALL calculateOffset
        MOV BX, offset disValues
        MOV DX, [BX+DI]
        CALL printString
        
        MOV AH, 02h
        MOV DL, ']'
        INT 21h
        
        MOV DL, ','
        INT 21h
        CALL printSpace

        POP BX
        MOV AL, [ES:BX]
        CALL hexPrintByte
        
        MOV AH, 02h
        MOV DL, 'h'
        INT 21h

        RET
operandByte ENDP

PROC operandWord
        MOV AL, [ES:BX]
        INC BX
        CALL hexPrintByte
        MOV AL, [ES:BX]
        PUSH BX
        CALL hexPrintByte
        CALL printSpace

        LEA DX, instMov
        CALL printString
        CALL printSpace
        
        LEA DX, operWord
        CALL printString
        CALL printSpace
        
        MOV AH, 02h
        MOV DL, '['
        INT 21h
        
        CALL calculateOffset
        MOV BX, offset disValues
        MOV DX, [BX+DI]
        CALL printString
        
        MOV AH, 02h
        MOV DL, ']'
        INT 21h
        
        MOV DL, ','
        INT 21h
        CALL printSpace
        
        POP BX
        MOV DL, [ES:BX]
        DEC BX
        MOV AL, DL
        CALL hexPrintByte
        
        MOV DL, [ES:BX]
        MOV AL, DL
        CALL hexPrintByte
        
        MOV AH, 02h
        MOV DL, 'h'
        INT 21h

        RET
operandWord ENDP

PROC calculateOffset
        MOV DI, 0
        MOV BX, [BP]
        MOV DL, [ES:BX+1]
        MOV AL, DL
        AND AL, 0C0h
        CMP AL, 00h
        JE rem00
        CMP AL, 80h
        JE rem10
        CMP AL, 40h
        JE rem10
    rem00:
        JMP continuecalc
    rem10:
        ADD DI, 16
    continueCalc:
        PUSH DX
        MOV AL, 02
        AND DL, 07h
        MUL DL
        MOV AH, 00h
        ADD DI, AX
        POP DX
        RET
calculateOffset ENDP

PROC printString
        PUSH AX
        MOV AH, 09h
        INT 21h
        POP AX
        RET
printString ENDP

PROC printEndChars1
        CALL printSpace
        MOV AH, 02h
        MOV DL, ';'
        INT 21h
        CALL printSpace
        CALL calculateOffset
        MOV BX, offset disValues
        MOV DX, [BX+DI]
        CALL printString
        MOV AH, 02h
        MOV DL, '='
        INT 21h
        RET
printEndChars1 ENDP

PROC printEndChars2
        CALL printSpace
        MOV AH, 02h
        MOV DL, ','
        INT 21h
        CALL printSpace
        MOV AH, 02h
        MOV DL, '['
        INT 21h
        CALL calculateOffset
        MOV BX, offset disValues
        MOV DX, [BX+DI]
        CALL printString
        MOV AH, 02h
        MOV DL, ']'
        INT 21h
        MOV DL, '='
        INT 21h
        RET
printEndChars2 ENDP

PROC calculateDisplacement
            MOV AL, address
            AND AL, 0C0h
            CMP AL, 00
            JE stul1
            CMP AL, 80h
            JE stul2
            CMP AL, 40h
            JE stul2
        stul1:
        MOV AL, address
        AND AL, 07h
        CMP AL, 00h
        JE l1000
        CMP AL, 01h
        JE l1001
        CMP AL, 02h
        JE l1010
        CMP AL, 03h
        JE l1011
        CMP AL, 04h
        JE l1100
        CMP AL, 05h
        JE l1101
        CMP AL, 06h
        JE l1110
        CMP AL, 07h
        JE l1111
    l1000:
    MOV AX, calculatedAddress
    ADD AX, valBX
    ADD AX, valSI
    RET
    l1001:
    MOV AX, calculatedAddress
    ADD AX, valBX
    ADD AX, valDI
    RET
    l1010:
    MOV AX, calculatedAddress
    ADD AX, valBP
    ADD AX, valSI
    RET
    l1011:
    MOV AX, calculatedAddress
    ADD AX, valBP
    ADD AX, valDI
    RET
    l1100:
    MOV AX, calculatedAddress
    ADD AX, valSI
    RET
    l1101:
    MOV AX, calculatedAddress
    ADD AX, valDI
    RET
    l1110:
    MOV AX, calculatedAddress
    ADD AX, valBP
    RET
    l1111:
    MOV AX, calculatedAddress
    ADD AX, valBX
    RET   
        stul2:
        MOV AL, address
        AND AL, 07h
        CMP AL, 00h
        JE l2000
        CMP AL, 01h
        JE l2001
        CMP AL, 02h
        JE l2010
        CMP AL, 03h
        JE l2011
        CMP AL, 04h
        JE l2100
        CMP AL, 05h
        JE l2101
        CMP AL, 06h
        JE l2110
        CMP AL, 07h
        JE jumpend
    l2000:
    MOV AX, calculatedAddress
    ADD AX, valBX
    ADD AX, valSI
    ADD AX, valDis1
    ADD AX, valDis2
    RET
    l2001:
    MOV AX, calculatedAddress
    ADD AX, valBX
    ADD AX, valDI
    ADD AX, valDis1
    ADD AX, valDis2
    RET
    l2010:
    MOV AX, calculatedAddress
    ADD AX, valBP
    ADD AX, valSI
    ADD AX, valDis1
    ADD AX, valDis2
    RET
    l2011:
    MOV AX, calculatedAddress
    ADD AX, valBP
    ADD AX, valDI
    ADD AX, valDis1
    ADD AX, valDis2
    RET
    jumpend:
    JMP l2111
    l2100:
    MOV AX, calculatedAddress
    ADD AX, valSI
    ADD AX, valDis1
    ADD AX, valDis2
    RET
    l2101:
    MOV AX, calculatedAddress
    ADD AX, valDI
    ADD AX, valDis1
    ADD AX, valDis2
    RET
    l2110:
    MOV AX, calculatedAddress
    ADD AX, valBP
    ADD AX, valDis1
    ADD AX, valDis2
    RET
    l2111:
    MOV AX, calculatedAddress
    ADD AX, valBX
    ADD AX, valDis1
    ADD AX, valDis2
    RET
calculateDisplacement ENDP

END start