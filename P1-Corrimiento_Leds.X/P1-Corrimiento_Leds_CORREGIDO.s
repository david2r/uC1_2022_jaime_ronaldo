;_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
;    
;FILE:  P1-Corrimiento_Leds
;BRIEF: Este codigo permite el corrimiento de leds conectados al puerto C, con
	;un retardo de 500 ms en un numero de corrimientos pares
	;y un retardo de 250ms en un numero de corrimientos impares.
	;El corrimiento inicia cuando se presiona el pulsador de la placa
	;una vez y se detiene cuando se vuelve a presionar.
;Frecuencia a trabajar = 4MHz
;TCY = 1us
;DATE:  22/01/2023
;AUTOR: Ronaldo David Jaime Chiroque 
;_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
PROCESSOR 18F57Q84
#include"Config.inc"
#include <xc.inc>
#include"Retardos.inc"
PSECT inicio, class=CODE, reloc=2
inicio: 
    GOTO Main

PSECT CODE
Main:
  CALL    CONFI_OSC,1
  CALL    CONFI_PORT,1
  
 Inicio: 
    BTFSC   PORTA,3,0	    ;Inicia si se preciona el pulsador.
    GOTO    APAGADO	    ;leds apagados hta que se precione el pulsador
    
 corrimiento_impar:	    
    MOVLW   1		    ;cargamos 1 a W
    MOVWF   0x502,a	    ;movemos al regitro para poderle hacer la rotación y no se pierda   
 LOOP:
    BSF     LATE,0,1	    ;Enciende led que indica corrimiento impar 
    BCF     LATE,1,0	    ;Apaga led que indica par 
    BANKSEL PORTC
    MOVF    0X502,w,a	    ;0x502 --> w
    MOVWF   PORTC,1 
    CALL    Delay_250ms,1   ;retardo de 1/4 segundo
    RLNCF   0x502,f,a	    ;00000010	
    BTFSC   PORTA,3,0	    ;verificamos si es esta precionado el pulsador
    GOTO    VERIFICA
    GOTO    PARE_1
    
 VERIFICA:
     ;verificamos si prendieron todos lo leds para altar al corriento par
    BTFSS   0x502,7,a
    GOTO    LOOP	    ;continua en impar 
    MOVF    0X502,w,a	    ;0x502 --> w
    MOVWF   PORTC,1	    ;Lee el octavo led para luego saltar a par
    CALL    Delay_250ms,1
    CALL    Delay_250ms,1
    MOVLW   1		    ;le cargamos el valor de uno para volver a iniciar 
    MOVWF   0x502,a	    ;lo guardamo en el mismo regitro que venimops utilizando
    GOTO    corrimiento_par
    
 corrimiento_par:
    BCF     LATE,0,1	    ;Apaga led que indica corrimiento impar 
    BSF     LATE,1,0	    ;Enciende led que indica corrimiento par 
    BANKSEL PORTC
    MOVF    0X502,w,a	    ;0x502 --> w
    MOVWF   PORTC,1	    ;Leemos el acumulador 
    CALL    Delay_250ms,1   
    CALL    Delay_250ms,1   ;retardo de 1/2 segundo
    RLNCF   0x502,f,a	    ;rotamos para encender el siguiente led 	
    BTFSC   PORTA,3,0	    ;verificamos si es esta precionado el pulsador 
    GOTO    VERIFICA_1	    
    GOTO    PARE_2	    ;saltamos a detener la simulación 
   
 VERIFICA_1:
    ;verificamos si prendieron todos lo leds para altar al corriento impar 
    BTFSS   0x502,7,a
    GOTO    corrimiento_par ;continua en par
    MOVF    0X502,w,a	    ;0x502 --> w
    MOVWF   PORTC,1	    ;Lee el octavo led para luego saltar a impar
    CALL    Delay_250ms,1   
    GOTO    corrimiento_impar  

 APAGADO:
    CLRF    PORTC,1	    ;Leds apagados
    GOTO    Inicio	    ;volvemos a verificaar si se preciono el el pulsador
    
 PARE_1:
  ;Hacemo este retardo para poder captar el pulso y no continuar con el corrimiento
    CALL    Delay_250ms
    CALL    Delay_250ms
    CAPTURA:
    RRNCF   0x502,w,a
    MOVF    0x502,f,a	    ;0x502 --> w
    BANKSEL PORTC
    MOVWF   PORTC,1	    ;Leemos lo que se quedo guardado en el regitro utilizado
    BSF     LATE,0,1	    ;como e la captura de los pares mantenemos encendido el RE0
    BTFSC   PORTA,3,0	    ;verificamos si es esta precionado el pulsador
    GOTO    CAPTURA
    GOTO    VERIFICA
    
 PARE_2:
  ;Hacemo este retardo para poder captar el pulso y no continuar con el corrimiento
    CALL    Delay_250ms
    CALL    Delay_250ms
    CAPTURA_2:
    RRNCF   0x502,w,a
    MOVF    0X502,f,a	    ;0x502 --> w
    BANKSEL PORTC	    
    MOVWF   PORTC,1	    ;Leemos lo que se quedo guardado en el regitro utilizado
    BSF     LATE,1,0	    ;como e la captura de los pares mantenemos encendido el RE1
    BTFSC   PORTA,3,0	    ;verificamos si es esta precionado el pulsador
    GOTO    CAPTURA_2
    GOTO    VERIFICA_1
    
 CONFI_OSC:
    ;CONFIGURACION DEL OSCILADOR INTERNO A UNA FRECUENCIA DE 4MHZ
    BANKSEL OSCCON1
    MOVLW   0x60	;selecccionamos el bloque del oscilador interno con un div:1
    MOVWF   OSCCON1,1
    MOVLW   0x02	;seleccionamos una frecuencia de 4MHz
    MOVWF   OSCFRQ,1
    RETURN
    
 CONFI_PORT:
    ;Configuracion de puertos para los leds de corrimiento
    BANKSEL PORTC   
    CLRF    PORTC,1	;PORTC = 0
    CLRF    LATC,1	;LATC = 0 -- Leds off
    CLRF    ANSELC,1	;ANSELC<7:0> = 0 -- digital
    CLRF    TRISC,1	;TRISC<0:7> = 0 -- salida
    ;Configuracion de leds para visualizar cuando se da el corrimiento par o impar.
    BANKSEL PORTE   
    CLRF    PORTE,1	;PORTE = 0
    BCF     LATE,0,1	;LATE = 1 -- Leds off
    BCF     LATE,1,1
    CLRF    ANSELE,1	;ANSELC<7:0> = 0 -- digital
    CLRF    TRISE,1	;TRISA<0:7> = 0 -- salida
    ;Configuracion de butom
    BANKSEL PORTA
    CLRF    PORTA,1	
    CLRF    ANSELA,1	;ANSELA<7:0> = 0 -- digital
    BSF	    TRISA,3,1	;TRISA<3> = 1 -- entrada
    BSF	    WPUA,3,1	;Activo la reistencia Pull-Up
    RETURN  
   
END inicio  
