PSECT udata_acs
offset: DS 1	    
    
PSECT code 
   MOVLW    0x03  ; definimos el valor del offset   
   MOVWF   offset,0
   BANKSEL PCLATU
    
   
   MOVLW    low highword(Table)
   MOVWF    PCLATU,0
   MOVLW    high(Table)
   MOVWF    PCLATH,0 
   RLNCF    offset,0,0
;   MOVLW   0x02
;   MULWF   offset,a
;   MOVF    PRODL,w
   CALL     Table
   GOTO     Main
Table:    
    ADDWF   PCL,1,0
    RETLW   01000000B  ; offset:0---(0)
    RETLW   01111001B  ; offset:1---(1)
    RETLW   00100100B  ; offset:2---(2)
    RETLW   00110000B  ; offset:3---(3)
    RETLW   00011001B  ; ofsset:4---(4)
    RETLW   00010010B  ; offset:5---(5)
    RETLW   00000010B  ; offset:6---(6)
    RETLW   01111000B  ; offset:7---(7)
    RETLW   00000000B  ; offset:8---(8)
    RETLW   00011000B  ; ofsset:9---(9)


