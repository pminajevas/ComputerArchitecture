.model small

.stack 100h

.DATA
    msgText DB "Enter text:$"       
    newline DB 10, 13, "$"          ;Nauja eilute 
    inputBuf DB 100, 0, 100 DUP(0)  ;Buferio parametrai
          
.CODE
 Strt:
    
    MOV ax,@data                ;Datos inicializavimas
    MOV ds,ax
        
    MOV ah, 09h                 ;Atspausdina zinute
    MOV dx,OFFSET msgText
    INT 21h
                                                                     
    MOV ah,0Ah                  ;Stringo ivedimas
    MOV dx,OFFSET inputBuf 
    INT 21h 
    
    MOV ah,09h                  ;Nauja eilute
    MOV dx, OFFSET newline
    INT 21h 
                                
    MOV si, dx                  ;Indekso radimas
    ADD si, 2

 Repeat:                        ;Loop'as randantis                                 
    LODSB                       ;ir spausdinantis ' ' vietas
    OR al,al
    
    JZ Exit                     ;Jei tuscias al iseina
    MOV dl,al                            
    CMP al,' '
    JE Print                    ;Tikrina ar al reiksme tarpas
    MOV al,'1'                  ;Jei al tarpas soka i spausdinima
 LoopNumber:
    CMP dl, al
    JE Print
    INC al
    CMP al,'9'
    JE SHORT Repeat
    JMP LoopNumber
    
 Print:
    MOV ax,si                   ;Tarpo vietos skaiciavimas
    SUB ax, OFFSET inputBuf
    SUB ax, 2h
    AAM
    ADD ax, 3030h 
    
    PUSH ax                     
    MOV dl, ah
    CMP dl, '0'                 ;Tikrina ar yra desimciu
    
    JE NoZero                   ;Jei nera soka prie vienetu
                                
    MOV ah, 02h                 ;Desimciu isvedimas
    INT 21h   
    MOV ax,si
     
 NoZero:
    POP dx
    MOV ah, 02h                 ;Vienetu isvedimas
    INT 21h
        
                                ;Tarpo spausdinimas
    MOV ah, 02h
    MOV dl, 20h
    INT 21h
    
    
    JMP Repeat                  ;Soka atgal i ciklo pradzia
                     
 Exit:    
    MOV ax,04C00h               ;Programos pabaiga
    INT 21h
    
                      
END Strt