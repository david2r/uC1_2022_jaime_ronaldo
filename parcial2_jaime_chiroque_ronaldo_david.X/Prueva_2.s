PROCESSOR 18F57Q84
#include"Config.inc"
#include <xc.inc>
#include"Retardos_3.inc"
;PROCESSOR 18F57Q84
;#include "Bit_Config.inc"   // config statements should precede project file includes*/. ;nivel local / nivel proyecto
;#include <xc.inc>   ;nivel global / nivel raiz
;#include "Retardos.inc"
 
PSECT udata_acs
offset:	    DS 1
counter:    DS 1    
    
PSECT resetVect,class=CODE,reloc=2
resetVect:
    goto Main
    
PSECT ISRVect,class=CODE,reloc=2    ;este PSECT es para el bloque de interrupciones
ISRVect:
    BTFSS   PIR1,0,0	;Se ha producido la INT0?
    GOTO    EXIT   
Toggle_Led:
    BCF	    PIR1,0,0	;Limpiamos el flag de la INT0, para no tener reingresos
    BTG	    LATF,3,0	;Toggle led
    CALL    Delay_250ms
    CALL    Delay_250ms
    CALL    Delay_250ms
    BTG	    LATF,3,0	;Toggle led
EXIT:   
    RETFIE     
    
PSECT CODE
Main:
    CALL    CONFI_OSC,1
    CALL    CONFI_PORT,1
    CALL    CONFI_PPS,1
    CALL    CONFI_INT0,1
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
    GOTO    reload 
    
Next_seq:
    INCF    offset,1,0
    GOTO    Loop
    
reload:    
    MOVLW   0x05
    MOVWF   counter,0	;carga el contador con el numero de offset
    MOVLW   0x00
    MOVWF   offset,0	;definimos el valor del offset inicial
    GOTO    Loop
    
TABLE:
    ADDWF   PCL,1,0
    RETLW   00000000B	;offset:0 --- 0
    RETLW   00000001B	;offset:1 --- 1
    RETLW   00000010B	;offset:2 --- 2
    RETLW   00000100B	;offset:3 --- 3
    RETLW   00001000B	;offset:4 --- 4  
    
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
    BSF     LATF,3,1	;LATF = 0 -- Leds apagado
    CLRF    ANSELF,1	;ANSELF = 0 -- Digital
    BCF     TRISF,3,1
    
    ;Configuracion de butom
    BANKSEL PORTA
    CLRF    PORTA,1	
    CLRF    ANSELA,1	;ANSELA = 0 -- Digital
    BSF	    TRISA,3,1	;TRISA = 1 --> entrada
    BSF	    WPUA,3,1	;Activo la reistencia Pull-Up
    
    ;Configuracion de PORTC
    BANKSEL PORTC   
    CLRF    PORTC,1	;PORTC = 0
    CLRF    LATC,1	;LATC = 0 -- Leds apagado
    CLRF    ANSELC,1	;ANSELC = 0 -- Digital
    CLRF    TRISC,1
    RETURN
    
CONFI_PPS:
    BANKSEL INT0PPS
    MOVLW   0x03
    MOVWF   INT0PPS,1	;INT0 --> RA3   
    RETURN
    
; ----- SECUENCIA (configurar interrupcion) -----
; 1.Definir prioridades
; 2.Configurar interrupcion
; 3.Limpiar el flag
; 4.Habilitar la interrupcion
; 5.Habilitar las interrupciones globales
    
CONFI_INT0:
    BCF	    INTCON0,5,0	    ;INTCON0<IPEN> = 0 -- Deshabilitar prioridades
    BCF	    INTCON0,0,0	    ;INTCON0<INT0EDG> = 0 -- INT0 por flanco de bajada
    BCF	    PIR1,0,0	    ;PIR1<INT0IF> = 0 -- Limpiamos el flag de interrupciones
    BSF	    PIE1,0,0	    ;PIE1<INT0IE> = 1 -- Habilitamos la interrupcion externa
    BSF	    INTCON0,7,0	    ;INTCON0<GIE/GIEH> = 1 --Habilitamos las interrupciones de forma global
    RETURN
    
END resetVect