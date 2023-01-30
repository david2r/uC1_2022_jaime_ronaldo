;--------------------------------
    ;@author:   JAIME CHIROQUE RONALDO DAVID
    ;@grupo:    G-6
    ;@file:     Ejercicio_2_parcial_2
    ;@brief:    Este codigo es ejemplo de como funcionan las interrupciones 
	;primero definimos el programa principl en este caso es un toggle de  
	;led de 500ms de la placa(RF3), cuando pulsas la la interrupción  
	;INT0(RA3) inicia una secuencia de leds, si presionas INT1(RB4) 
	;detienes la secuencia y capta los valores en que se quedo y vuelve  
	;al programa principal, mientras que INT2(RF2)reinicia la secuencia   
	;y apaga los leds y vuelve al progrma principal, y si no pulsas INT1 O
	; INT2, entonces durante 5 repeticiones  de la secuencia de leds, 
	;acaba la secuencia y vuvle al programa principal.
    ;@date:     29/01/2023
    ;Frecuencia a trabajar : 4MHz
    ;TCY = 1us
    ;----------------------------

PROCESSOR 18F57Q84
#include"Config.inc"
#include <xc.inc>

PSECT udata_acs
Contador1: DS 1	    ;var. para dilay
Contador2: DS 1	    ;var. para dilay
offset:	    DS	1   ;var. para el buscador de la tabla 
counter:    DS	1   ;var. para el buscador de la tabla
contador_5: DS	1   ;var. para el numero de conteo de la secuencia 
apaga:	    DS	1   ;var. para salir de la INT0 al precionar INT1-INT2
    
PSECT resetVect,class=CODE,reloc=2
resetVect:
    goto Main  
       
PSECT int0,class=CODE,reloc=2
int0:
    BTFSS   PIR1,0,0	; ¿Se ha producido la INT0?
    GOTO    Exit1	; continua sin hacer nada
    BCF	    PIR1,0,0	; limpiamos el flag de INT0
    GOTO   Inicio	; se va a iniciar la secuencia de leds
Exit1:
    RETFIE		;retorna sin hacer nada 
  
PSECT ISRVectHigh,class=CODE,reloc=2
ISRVectHigh:
    BTFSC   PIR10,0,0	; ¿Se ha producido la INT2?
    GOTO    reinicia	; apga los leds y regresa al programa principal
    BTFSC   PIR6,0,0	; ¿Se ha producido la INT1?
    GOTO    captura     ; se detiene y regresa al programa principal
Exit3:  
    RETFIE  
        
PSECT CODE 
Main:
    CALL    CONFI_OSC,1	;configuración del osciloscopio 
    CALL    CONFI_PORT,1 ;configuración de puertos
    CALL    CONFI_PPS,1	 ;configuras los puertos de las inetrrupciones
    CALL    CONFI_INT,1	 ;configuras las interrupciones 
 ;; toggle de 500ms del led de la placa
Inactivo:
    BANKSEL LATF
    BSF	    LATF,3,1	    ; prende el Led 
    CALL    Delay_250ms,1   ;retardo
    CALL    Delay_250ms,1   ;retardo
    BCF	    LATF,3,1	    ;apaga el Led
    CALL    Delay_250ms,1   ;retardo
    CALL    Delay_250ms,1   ;retardo
    goto    Inactivo	    ;vuelve al loop para hacer lo mismo 
Inicio:
    MOVLW   5
    MOVWF   contador_5,0	;carga el contador con el numero de offset
    MOVLW   0
    MOVWF   apaga,0	;carga el contador con el numero de offset
    GOTO    reload
    
Loop: 
    BANKSEL PCLATU	       ; Llamamos a PCLATU
    MOVLW   low highword(TABLE); Cargar el byte superior (CPU)
    MOVWF   PCLATU,1	       ; (W)->PCLATU,Escribir el byte superior a PCLATU
    MOVLW   high(TABLE)	    ; (W -->high(Table), cargar el byte alto (PCH)
    MOVWF   PCLATH,1	    ; (W)-->PCLATH, Escribir el byte alto en PCLATH
    RLNCF   offset,0,0	    ; Rota el Ofsset(0)al bit siguiente,
    CALL    TABLE	    ; Llamamos a la subrutina Table
    MOVWF   LATC,0	    ; (W)-->LATC
    CALL    Delay_250ms
    DECFSZ  counter,1,0	    ;decrementa el contador del buscador
    GOTO    Next_seq	    ;salta a incrementar el offset 
    GOTO    Apagado	    ;salta a decrementar la el conteo de 5 
Next_seq:
    INCF    offset,1,0	    ; Incrementa en uno mas al Ofsset
    BTFSS   apaga,1,0	    ; si apaga=1, entonces hace un salto
    GOTO    Loop	    ; se va a la subrutina Loop
    GOTO    Exit1	    ; se va a la subrutina Exit1 
    
Apagado:
    DECFSZ  contador_5,1,0  ;si se ya dio una vuelta decrementa
    GOTO    reload	    ;como no es cero entones sigue la secuencia
    GOTO    Exit1	    ;contador_5 es igual a cero termina la interrup.
reload: 
    BSF	    LATF,3,1	;Led on
    MOVLW   10		;los diez valores de la tabla 
    MOVWF   counter,0	;carga el contador con el numero de offset
    MOVLW   0x00	;inicializamos el offset en cero
    MOVWF   offset,0	;definimos el valor del offset inicial
    GOTO    Loop
    
TABLE:
    ADDWF   PCL,1,0
    RETLW   10000001B	; offset: 0
    RETLW   01000010B	; offset: 1
    RETLW   00100100B	; offset: 2
    RETLW   00011000B	; offset: 3
    RETLW   00000000B	; offset: 4
    RETLW   00011000B	; offset: 5
    RETLW   00100100B	; offset: 6
    RETLW   01000010B	; offset: 7
    RETLW   10000001B	; offset: 8
    RETLW   00000000B	; offset: 9
    
reinicia:
    BCF	    PIR10,0,0	; limpiamos el flag de INT2
    SETF    apaga,0   ;cargamos 1 para que pueda vover al prog. principal  
    CLRF    LATC,0    ;apagamos lo leds
    GOTO    Exit3     ;salimos de esta interrupción 
    
captura:
    BCF	    PIR6,0,0	; limpiamos el flag de INT1
    SETF    apaga,0	;cargamos 1 para que pueda vover al prog. principal
    GOTO    Exit3	;salimos de esta interrupción 
    
    
CONFI_OSC:  
    BANKSEL OSCCON1
    MOVLW   0x60	;selecccionamos el bloque del osc. interno con un div:1
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
    CLRF    PORTC,1	;PORTC = 0
    CLRF    LATC,1	;LATC = 0 -- Leds apagado
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
    MOVWF   INT1PPS,1	; INT1 --> RB4
    ;Config INT2
    BANKSEL INT2PPS
    MOVLW   0x2A
    MOVWF   INT2PPS,1	; INT2 --> RF2
    RETURN
    
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
    
    BSF	INTCON0,7,0 ; INTCON0<GIE/GIEH> = 1 -- habilitamos de forma global
    BSF	INTCON0,6,0 ; INTCON0<GIEL> = 1 -- habilitamos de baja prioridad
    RETURN
    
;;retardo de 250mili segundos   
Delay_250ms:                   ;  2TCY---Call
    MOVLW  250                ;  1TCY ( El valor que le carguemos a "W" )
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