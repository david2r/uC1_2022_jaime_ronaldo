;_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
;    
;FILE:  P3-Display_7SEG
;BRIEF: Ete codigo implementar un contador ascendente/descendente de 0 a 99
	;utilizando display de 7 segmentos y decodificador de BCD a 7 segmentos
	;7447.s impares. El corrimiento inicia cuando se presiona el pulsador
	;de la placa una vez y se detiene cuando se vuelve a presionar.
;Frecuencia a trabajar = 4MHz
;TCY = 1us
;DATE:  14/01/2023
;AUTOR: Ronaldo David Jaime Chiroque 
;_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
PROCESSOR 18F57Q84
#include"Config_bits.inc"
#include <xc.inc>
#include"Retardos_3.inc"
    
PSECT inicio, class=CODE, reloc=2
inicio: 
    GOTO Main

PSECT CODE
Main:
   CALL CONFI_OSCC,1
   CALL CONFI_PORT,1
   
   
OPEN:
    BTFSC   PORTA,3,0; si preionamos PORA=0
    GOTO    ASCENDENTE
     ;PORtA=0-> salta para encender
DESCENDENTE:
    MOVLW   0		;Definimos el valor inicial en 0 
    MOVWF   0x502,a	;Unidades
    MOVLW   0		;Definimos el valor inicial en 0
    MOVWF   0x503,a	;Decenas
  VERIFICA_2:
    
    BTFSS   STATUS,4,a	    ;Verifica si el valor es negativo
    GOTO    CONTINUA_9_0    ;Como no e negativo lo continua decrementando las unidades
    BTFSS   0x502,4,a	    ;Verifica si el valor de 0-1 es 255
    GOTO    CONTINUA_9_0    ;Continua decrementando las unidades
    BTFSS   0x502,7,a
    GOTO    CONTINUA_9_0
    DECF    0x503,1,0	    ;Decrementa en uno la decenas
    MOVLW   9		    ;cargamos el valor de nueve a las unidades
    MOVWF   0x502,a	    ;Unidades
    BTFSS   0x503,4,a	    ;verifica i las decenas esta en 0-1=255
    GOTO    CONTINUA_9_0    ;salta a decrementar las unidades
    BTFSS   0x503,7,a	    ;verifica i las decenas esta en 0-1=255
    GOTO    CONTINUA_9_0    ;salta a decrementar las unidades
    MOVLW   9		;continua des el 99 
    MOVWF   0x502,a	; 
    MOVLW   9		;Definimos el valor del offset 
    MOVWF   0x503,a	;Decenas
    GOTO    VERIFICA_2
    
 CONTINUA_9_0: 
  MOVF	    0X502,w,a	; Mueve el valor de las unidade (regitro) al acumulador 
  MOVWF	    PORTB,0	;lee lo del acumulador
  MOVF	  0X503,w,a	;movemos las decenas al acumulador 	
  MOVWF	  PORTD,0	;leemo el acumulador 
  BTFSC   PORTA,3,0	;verificamoss si sigue presionado el boton
  GOTO    VERIFICA	;si ya no esta presionado entonces se va a corrimiento ascendente
  CALL    Delay_250ms,1 
  CALL    Delay_250ms,1
  CALL    Delay_250ms,1
  CALL    Delay_250ms,1 ;hacemos 4 retardos de 250ms para que tarde 1 segundo
  BTFSC   PORTA,3,0; si preionamos PORA=0
  GOTO    VERIFICA
  DECF    0x502,f,a
  GOTO    VERIFICA_2
   
ASCENDENTE:
    MOVLW   0		  ;Definimos el valor inicial en 0 
    MOVWF   0x502,a	  ;Unidades
    MOVLW   0		  ;Definimos el valor del offset 
    MOVWF   0x503,a	  ;Decenas
  VERIFICA:  
    BTFSS   0x502,1,a	  ;verifica si el valor de las unidades es 10
    GOTO    CONTINUA_0_9  ;sino es 10 continua contando las unidade
    BTFSS   0x502,3,a	  ;verifica i el valor es 10
    GOTO    CONTINUA_0_9  ;sino es 10 continua contando las unidade
    INCF    0x503,1,0	  ;incrementa en uno a la unidades  
    CLRF    0x502,a	  ;limpia las unides para q empiese de cero
    BTFSS   0x503,1,a	  ;verifica si el valor de las decenas es 10
    GOTO    CONTINUA_0_9  ;sino es 10 continua contando las unidade y se mantiene ls decenas
    BTFSS   0x503,3,a
    GOTO    CONTINUA_0_9
    CLRF    0x503,a	  ;como las decenas llegaron a 10 vas a limpiar todo
    CLRF    0x502,a	  ;limpia la unidades para volver a iniciar en cero
    GOTO    VERIFICA	  ;alta a verificar de nuevo si es 10
    
 CONTINUA_0_9: 
  MOVF	    0X502,w,a	; Mueve el valor de las unidade (regitro) al acumulador
  MOVWF	    PORTB,0	;lee lo del acumulador (unidades)

  MOVF	  0X503,w,a	;movemos las decenas al acumulador
  MOVWF	  PORTD,0	;lee lo del acumulador (decenas)
  BTFSS   PORTA,3,0	; si preionamos PORA=0
  GOTO    VERIFICA_2	;si se presiona entonces se va a corrimiento ascendente
  CALL    Delay_250ms,1
  CALL    Delay_250ms,1
  CALL    Delay_250ms,1
  CALL    Delay_250ms,1 ;hacemos 4 retardos de 250ms para que tarde 1 segundo
  BTFSS   PORTA,3,0; si preionamos PORA=0
  GOTO    VERIFICA_2
    
   INCREMENTO:
    INCF    0x502,f,a
    GOTO    VERIFICA
    
  CONFI_OSCC:  
    BANKSEL OSCCON1
    MOVLW   0x60 
    MOVWF   OSCCON1,1
    MOVLW   0x02 
    MOVWF   OSCFRQ,1
   RETURN
    
  CONFI_PORT:
    ; Conf. de puertos para los leds de corrimiento
    BANKSEL PORTB   
    CLRF    PORTB,1	;PORTC=0
    CLRF    LATB,1	;LATC=0, Leds apagado
    CLRF    ANSELB,1	;ANSELC=0, Digital
    CLRF    TRISB,1
    ; Conf. de puertos para los leds de corrimiento
    BANKSEL PORTD   
    CLRF    PORTD,1	;PORTC=0
    CLRF    LATD,1	;LATC=0, Leds apagado
    CLRF    ANSELD,1	;ANSELC=0, Digital
    CLRF    TRISD,1
    ;confi butom
    CLRF    PORTA,1	;
    CLRF    ANSELA,1	;ANSELA=0, Digital
    BSF	    TRISA,3,1	; TRISA=1 -> entrada
    BSF	    WPUA,3,1	;Activo la reistencia Pull-Up
   RETURN
   
END inicio