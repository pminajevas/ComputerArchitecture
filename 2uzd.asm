.MODEL small
.STACK 256h
.DATA
        helpMsg0 DB "You need to provide input file name (no longer than 8 symbols) with extension and then followed with space and the number (no bigger than 255) which determines the number of characteres in each new file created$"
        helpMsg1 DB "Incorrect file name. You need to provide input file name (no longer than 8 symbols) with extension and then followed with space and the number (no bigger than 255) which determines the number of characteres in each new file created$"
        helpMsg2 DB "You entered too big of a number. You need to provide input file name (no longer than 8 symbols) with extension and then followed with space and the number (no bigger than 255) which determines the number of characteres in each new file created$"
        helpMsg3 DB "Too many output files. Change the number that determines how many characteres to write or use smaller input file$"
        errorMsg DB "Error while working with files$"
        inputFile DB 13 DUP (0)
        outputFile DB 13 DUP (0)
        outputFileNameLength DW 0000h
        charsRead DW 0000h
        fileHandlerRead DW 0000h
        fileHandlerWrite DW 0000h
        dataBuffer DB 255 DUP (?)
        outputFileExtensionHundreds DB "0"
        outputFileExtensionTens DB "0"
        outputFileExtensionOnes DB "1"
.CODE
start:
        ;Loading data adress into DS
        MOV AX, @DATA
        MOV DS, AX
        ;Checking if there are parameteres
        MOV CL, ES:[80h]
        CMP CL, 00h
        JNE continue1
        MOV AL, 00h
        CALL printHelp
    continue1:    
        ;Checking for help symbol (/?)
        MOV BX, 0081h
searchingForHelp:    
        CMP ES:[BX], '?/'
        JNE continue2
        MOV AL, 00h
        CALL printHelp
    continue2: 
        INC BX
        DEC CX
        JNE searchingForHelp 
        ;Getting input file name and putting it into buffer also adding output file name beggining to buffer
        MOV BX, 82h
        LEA DI, outputFile
        LEA SI, inputFile
        ;Using al as a flag to check if extension comma was found
        MOV AL, 00h
        MOV CX, 0Dh       
getInputFileName:
        MOV DL, ES:[BX]
        INC BX
        ;If space found jump to getting the number
        CMP DL, 20h
        JE getSizePrep
        MOV DS:[SI], DL
        INC SI
        ;Checking the AL as a flag, if "01h" output file name already gotten
        CMP AL, 01h
        JE continueReading
        MOV DS:[DI], DL
        INC DI
        INC outputFileNameLength
        ;Checking for dot if found setting AL as a flag to true
        CMP DL, '.'
        JNE continueReading
        MOV AL, 01h
continueReading:
        DEC CX
        ;Checking if the name isn't too long
        CMP CX, 00h
        JNE continue3
        MOV AL, 01h
        CALL printHelp
    continue3: 
        JMP getInputFileName
getSizePrep:
        ;Calculating the ammount of numbers entered in parameteres
        MOV DI, 81h
        MOV AL, ES:[80h]
        MOV AH, 00h
        ADD DI, AX
        SUB DI, BX
        ;If no numbers entered print help
        CMP DI, 0000h
        JNE continue4
        MOV AL, 00h
        CALL printHelp
    continue4: 
        ;If more than 3 numbers entered print help
        CMP DI, 0003h
        JBE continue5
        MOV AL, 00h
        CALL printHelp
    continue5: 
        MOV SI, 0000h
getSize:
        ;Converting the number from decimal to hexadecimal
        MOV DL, ES:[BX]
        INC BX
        CMP DL, 0Dh
        JE files
        ;Checking if user entered decimal numbers not other characters
        CMP DL, '0'
        JAE checkIsNumber
        MOV AL, 00h
        CALL printHelp
checkIsNumber:
        CMP DL, '9'
        JBE isNumber
        MOV AL, 00h
        CALL printHelp
isNumber:
        ;If number entered correctly convertion starts
        PUSH DI
        SUB DL, 30h
        DEC DI
        CMP DI, 0000h
        JE addition
multiplication:
        ;Multiplying the digit by 10
        MOV AL, 10
        MUL DL
        JNO noOverflow
        MOV AL, 02h
        CALL printHelp
noOverflow:
        MOV DL, AL
        DEC DI
        JNE multiplication
        MOV DH, 00h
        ADD SI, DX
        POP DI
        DEC DI
        JMP getSize
addition:
        ;If its the last number no multiplicaiton needed, addind the value to SI
        MOV DH, 00h
        ADD SI, DX
        ;Checking if entered number isn't bigger than 255
        CMP SI, 00FFh
        JBE files
        MOV AL, 02h
        CALL printHelp

files:
        ;Input file open for reading
        MOV AH, 3Dh
        MOV AL, 00h
        LEA DX, inputFile
        INT 21h
        ;If error openning file print error message
        JC printError
        MOV fileHandlerRead, AX
reading:
        ;Reading the input file
        MOV AH, 3Fh
        MOV BX, fileHandlerRead
        MOV CX, SI
        LEA DX, dataBuffer
        INT 21h
        ;If error occured print error message
        JC printError
        MOV charsRead, AX
        ;Checking if there are any characters left, else finish program
        CMP AX, 0000h
        JE exit
        ;Adding number extension to output file
        CALL outputFileNameExtension
        INC outputFileExtensionOnes
        CMP outputFileExtensionOnes, 3Ah
        JE addTens
        JMP writing
addTens:
        SUB outputFileExtensionOnes, 0Ah
        INC outputFileExtensionTens
        CMP outputFileExtensionTens, 3Ah
        JE addHundreds
        JMP writing
addHundreds:
        SUB outputFileExtensionTens, 0Ah
        INC outputFileExtensionHundreds
        CMP outputFileExtensionHundreds, 3Ah
        JNE writing
        ;If too many output files created print instructions
        MOV AL, 03h
        CALL printHelp
writing:
        ;Creating output file
        MOV AH, 3Ch
        MOV CX, 0000h
        LEA DX, outputFile
        INT 21h
        JC printError
        MOV fileHandlerWrite, AX
        ;Writing to outputfile
        MOV AH, 40h
        MOV BX, fileHandlerWrite
        MOV CX, charsRead
        LEA DX, dataBuffer
        INT 21h
        JC printError
        ;Write file close
        CALL writeFileClose
        JMP reading
printError:
        ;Printing error message
        LEA DX, errorMsg
        MOV AH, 09h
        INT 21h
exit:
        ;Closing all opened files and exiting the program
        MOV BX, fileHandlerWrite
        CMP BX, 0000h
        JE skipOutputFile
        CALL writeFileClose
skipOutputFile:
        MOV BX, fileHandlerRead
        CMP BX, 0000h
        JE skipInputFile
        MOV fileHandlerRead, 0000h
        MOV AH, 3Eh
        INT 21h
        JC printError
skipInputFile:
        MOV AX, 4C00h
        INT 21h

writeFileClose PROC
        ;Procedure that closes output files
        MOV AH, 3Eh
        MOV BX, fileHandlerWrite
        MOV fileHandlerWrite, 0000h
        INT 21h
        JC printError
        RET
writeFileClose ENDP

printHelp PROC
        ;Procedure that prints different help messages based on al value
        MOV AH, 09h
        CMP AL, 00h
        JE printHelpMessage0
        CMP AL, 01h
        JE printHelpMessage1
        CMP AL, 02h
        JE printHelpMessage2
        CMP AL, 03h
        JE printHelpMessage3
printHelpMessage0:
        LEA DX, helpMsg0
        INT 21h
        JMP exit
printHelpMessage1:
        LEA DX, helpMsg1
        INT 21h
        JMP exit
printHelpMessage2:
        LEA DX, helpMsg2
        INT 21h
        JMP exit
printHelpMessage3:
        LEA DX, helpMsg3
        INT 21h
        JMP exit
printHelp ENDP

outputFileNameExtension PROC
        ;Procedure that add the correct extension to output file names
        LEA BX, outputFile
        ADD BX, outputFileNameLength
        MOV AL, outputFileExtensionHundreds
        MOV BYTE PTR [BX], AL
        MOV AL, outputFileExtensionTens
        MOV BYTE PTR [BX+1], AL
        MOV AL, outputFileExtensionOnes
        MOV BYTE PTR [BX+2], AL
        RET
outputFileNameExtension ENDP

END start