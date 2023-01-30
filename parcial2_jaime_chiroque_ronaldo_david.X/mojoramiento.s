PROCESSOR 18F57Q84
#include"Config.inc"
#include <xc.inc>
;#include"Retardos_3.inc"

PSECT udata_acs
Contador1: DS 1	    ;Lo que hacemos es reservar 1 bytes en acces RAM 
Contador2: DS 1	    
offset:	    DS	1
counter:    DS	1  
contador_5: DS	1
apaga:	    DS	1
    
PSECT resetVect,class=CODE,reloc=2
resetVect:
    goto Main  
       
PSECT int0,class=CODE,reloc=2
int0:
    BTFSS   PIR1,0,0	; ¿Se ha producido la INT0?
    GOTO    Exit1
    BCF	    PIR1,0,0	; limpiamos el flag de INT0
    GOTO   Inicio
Exit1:
    RETFIE         
  
PSECT ISRVectHigh,class=CODE,reloc=2
ISRVectHigh:
    BTFSC   PIR10,0,0	; ¿Se ha producido la INT2?
    GOTO    reinicia
    BTFSC   PIR6,0,0	; ¿Se ha producido la INT1?
    GOTO    captura    
Exit3:  
    RETFIE  
        
PSECT CODE 
Main:
    CALL    CONFI_OSC,1
    CALL    CONFI_PORT,1
    CALL    CONFI_PPS,1
    CALL    CONFI_INT,1
Inactivo:
    BANKSEL LATF
    BSF	    LATF,3,1	;Led on
    CALL    Delay_250ms,1
    CALL    Delay_250ms,1
    BCF	    LATF,3,1	;Led off
    CALL    Delay_250ms,1
    CALL    Delay_250ms,1
    goto    Inactivo
Inicio:
    MOVLW   5
    MOVWF   contador_5,0	;carga el contador con el numero de offset
    MOVLW   0
    MOVWF   apaga,0	;carga el contador con el numero de offset
    GOTO    reload
; ----- Pasos para implementar Computed_GOTO -----   
; 1.Escribir el byte superior en PCLATU
; 2.Escribir el byte alto en PCLATH
; 3.Escribir el byte bajo en PCL
; NOTA:El offset debe ser multiplicado por "2" para el alineamiento en memoria.
    
Loop: 
    BANKSEL PCLATU
    MOVLW   low highword(TABLE)
    MOVWF   PCLATU,1
    MOVLW   high(TABLE)
    MOVWF   PCLATH,1
    RLNCF   offset,0,0
    CALL    TABLE 
    MOVWF   LATC,0
    CALL    Delay_250ms
    DECFSZ  counter,1,0
    GOTO    Next_seq
    GOTO    Apagado    
Next_seq:
    INCF    offset,1,0
    BTFSS   apaga,1,0   
    GOTO    Loop
    GOTO    Exit1
    
Apagado:
    DECFSZ  contador_5,1,0
    GOTO    reload
    GOTO    Exit1
reload: 
    BSF	    LATF,3,1	;Led on
    MOVLW   10
    MOVWF   counter,0	;carga el contador con el numero de offset
    MOVLW   0x00
    MOVWF   offset,0	;definimos el valor del offset inicial
    GOTO    Loop
    
TABLE:
    ADDWF   PCL,1,0
    RETLW   01111110B	; offset: 0
    RETLW   10111101B	; offset: 1
    RETLW   11011011B	; offset: 2
    RETLW   11100111B	; offset: 3
    RETLW   11111111B	; offset: 4
    RETLW   11100111B	; offset: 5
    RETLW   11011011B	; offset: 6
    RETLW   10111101B	; offset: 7
    RETLW   01111110B	; offset: 8
    RETLW   11111111B	; offset: 9
    
reinicia:
    BCF	    PIR10,0,0	; limpiamos el flag de INT2
    SETF    apaga,0
    SETF    LATC,0
    GOTO    Exit3
    
captura:
    BCF	    PIR6,0,0	; limpiamos el flag de INT1
    SETF    apaga,0
    GOTO    Exit3
    
    
CONFI_OSC:  
    BANKSEL OSCCON1
    MOVLW   0x60	;selecccionamos el bloque del oscilador interno con un div:1
    MOVWF   OSCCON1,1
    MOVLW   0x02	;seleccionamos una frecuencia de 4MHz
    MOVWF   OSCFRQ,1
    RETURN
    
CONFI_PORT:
    ;Configuracion del led
    BANKSEL PORTF   
    CLRF    PORTF,1	;PORTF = 0
    CLRF    ANSELF,1	;ANSELF = 0 -- Digital
    BSF     LATF,3,1	;LATF = 0 -- Leds apagado
    BCF     TRISF,3,1	;TRISF = 1 --> salida

    ;Configuracion de INT0(A3)
    BANKSEL PORTA
    CLRF    PORTA,1	;PORTA = 0
    BCF     ANSELA,3,1	;ANSELA = 0 -- Digital
    BSF	    TRISA,3,1	;TRISA = 1 --> entrada
    BSF	    WPUA,3,1	;Activo la reistencia Pull-Up
    
    ;Configuracion de INT1(B4)
    BANKSEL PORTB
    CLRF    PORTB,1	;PORTB = 0
    BCF	    ANSELB,4,1	;ANSELB = 0 -- Digital
    BSF     TRISB,4,1	;TRISB = 1 --> entrada
    BSF	    WPUB,4,1	;Activo la reistencia Pull-Up
    
    ;Configuracion de INT2(F2)
    BANKSEL PORTF
    CLRF    PORTF,1	;PORTF = 0	
    BCF	    ANSELF,2,1	;ANSELF = 0 -- Digital
    BSF	    TRISF,2,1	;TRISF = 1 --> entrada
    BSF	    WPUF,2,1	;Activo la reistencia Pull-Up
    
    ;Configuracion de PORTC
    BANKSEL PORTC   
    SETF|    PORTC,1	;PORTC = 0
    SETF    LATC,1	;LATC = 0 -- Leds apagado
    CLRF    ANSELC,1	;ANSELC = 0 -- Digital
    CLRF    TRISC,1
    RETURN 
    
CONFI_PPS:
    ;Config INT0
    BANKSEL INT0PPS
    MOVLW   0x03
    MOVWF   INT0PPS,1	; INT0 --> RA3  
    ;Config INT1
    BANKSEL INT1PPS
    MOVLW   0x0C 
    MOVWF   INT1PPS,1
    ;Config INT2
    BANKSEL INT2PPS
    MOVLW   0x2A
    MOVWF   INT2PPS,1
    RETURN
    
;   Secuencia para configurar interrupcion:
;    1. Definir prioridades
;    2. Configurar interrupcion
;    3. Limpiar el flag
;    4. Habilitar la interrupcion
;    5. Habilitar las interrupciones globales
CONFI_INT:
    BSF	INTCON0,5,0 ; INTCON0<IPEN> = 0 -- Deshabilitar prioridades
    BANKSEL IPR1
    BCF	IPR1,0,1    ; IPR1<INT0IP> = 0 -- INT0 de BAJA prioridad
    BSF	IPR6,0,1    ; IPR6<INT1IP> = 0 -- INT1 de baja prioridad
    BSF	IPR10,0,1    ;IPR10<INT2IP> = 1 -- INT2 de ALTA prioridad
     ;Config INT0
    BCF	INTCON0,0,0 ; INTCON0<INT0EDG> = 0 -- INT0 por flanco de bajada
    BCF	PIR1,0,0    ; PIR1<INT0IF> = 0 -- limpiamos el flag de interrupcion
    BSF	PIE1,0,0    ; PIE1<INT0IE> = 1 -- habilitamos la interrupcion ext
   
    ;Config INT1
    BCF	INTCON0,1,0 ; INTCON0<INT1EDG> = 0 -- INT1 por flanco de bajada
    BCF	PIR6,0,0    ; PIR6<INT1IF> = 0 -- limpiamos el flag de interrupcion
    BSF	PIE6,0,0    ; PIE6<INT1IE> = 1 -- habilitamos la interrupcion ext1
    
    ;Config INT2
    BCF	INTCON0,2,0 ; INTCON0<INT2EDG> = 0 -- INT2 por flanco de bajada
    BCF	PIR10,0,0    ; PIR10<INT2IF> = 0 -- limpiamos el flag de interrupcion
    BSF	PIE10,0,0    ; PIE10<INT2IE> = 1 -- habilitamos la interrupcion ext1
    
    BSF	INTCON0,7,0 ; INTCON0<GIE/GIEH> = 1 -- habilitamos las interrupciones de forma global
    BSF	INTCON0,6,0 ; INTCON0<GIEL> = 1 -- habilitamos las interrupciones de baja prioridad
    RETURN
    
    
Delay_250ms:                   ;  2TCY---Call
    MOVLW  250                 ;  1TCY ( El valor que le carguemos a "W" es el valor de "k1")
    MOVWF  Contador2,0        ;  1TCY 
Loop_Ext_15:  
    MOVLW  249                ;  k1*TCY.....k=249
    MOVWF  Contador1,0        ;  k1*TCY
Loop_Int_15:
    Nop                       ;  k1*k*TCY
    DECFSZ Contador1,1,0      ;  k1*((k-1) + 3*TCY)
    GOTO   Loop_Int_15        ;  k1((k-1)*2TCY)
    DECFSZ Contador2,1,0      ;  (k1-1) + 3*TCY
    GOTO   Loop_Ext_15        ;  (k1-1)*2TCY
    RETURN                    ;  2*TCY   
END resetVect