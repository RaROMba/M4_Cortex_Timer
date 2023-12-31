; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   Peter Raab                               | Datum:  03.09.2021           |
; |--------------------------------------------------------------------------------------|
; | Version:     V1.0            | Projekt:               | Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:     Basisprojekt                                                            |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Aenderungen:                                                                         |
; |     03.09.2021     Peter Raab        Initial version                                 |
; |                                                                                      |
; ========================================================================================

; ------------------------------- includierte Dateien ------------------------------------
    INCLUDE STM32G4xx_REG_ASM.inc

; ------------------------------- exportierte Variablen ------------------------------------


; ------------------------------- importierte Variablen ------------------------------------		
		

; ------------------------------- exportierte Funktionen -----------------------------------		
	EXPORT main
	EXPORT TIM6_IRQHandler
	EXPORT TIM7_IRQHandler
			
; ------------------------------- importierte Funktionen -----------------------------------
	IMPORT up_delay
	IMPORT up_display


; ------------------------------- symbolische Konstanten ------------------------------------


; ------------------------------ Datensection / Variablen -----------------------------------

	AREA MAIN_DATA,   DATA, readonly
Label DCB 0x3F, 0x6, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x7, 0x7F, 0x6F
;            0,   1,    2,    3,    4,    5,    6,   7,    8,    9

	AREA  variables,   DATA, readwrite
counter 	DCB 0x00
moving 		DCB 0x00


; ------------------------------- Codesection / Programm ------------------------------------
	AREA	main_s,code
	
			
; -----------------------------------  Einsprungpunkt - --------------------------------------

main PROC

; Initialisierungen
	
    ; Aktivieren der Ports
    LDR R0, =RCC_AHB2ENR
    LDR R1, [R0]
    LDR R2, =0x00000006
    ORR R1, R2, R1
    STR R1, [R0]
	
    ; Einstellen des Ports A {PA[0:7]}
    LDR R0, =GPIOC_MODER	;davor A
    LDR R1, =0xABFF5555
    STR R1, [R0]
	
    ; Einstellen des Ports C {PC[0:3]}
    LDR R0, =GPIOB_MODER	;davor C
    LDR R1, [R0]
    LDR R2, =0xFFFFFFC0
    AND R1, R2, R1
    STR R1, [R0]
	
	; reset LED
	LDR R12, =GPIOC_ODR		;davor A
	LDR R3, [R12]
	LDR R2, =0x00000000
	STR R2, [R12]

timerdelay

    ldr R4, =RCC_APB1ENR1
    ldr R7, =0x00000430
    str R7, [R4]

    ldr R4, =TIM7_PSC
    ldr R7, =0x0063
    str R7, [R4]

    ldr R4, =TIM7_ARR
    ldr R7, =0x0000063F
    str R7, [R4]

    ldr R4, =TIM7_CR1
	ldr R7, =0x0001
    str R7, [R4]
	
    ldr R4, =TIM6_PSC
    ldr R7, =0x03E7
    str R7, [R4]

    ldr R4, =TIM6_ARR
    ldr R7, =0x0000063F
    str R7, [R4]

    ldr R4, =TIM6_CR1
	ldr R7, =0x0001
	str R7, [R4]
	
    ldr R4, =TIM7_DIER
    ldr R7, = 0x0001
	str R7, [R4]
	
    ldr R4, =TIM6_DIER
    ldr R7, = 0x0001
	str R7, [R4]
	
	ldr R4, = NVIC_ICPR1
	ldr R7, = 0xC00000    		; 004000000 + 00800000
	str R7, [R4]

    ldr R4, = NVIC_ISER1
	ldr R7, = 0x000C00000    		; 004000000 + 00800000
	str R7, [R4]
	

loop
	 ; wiederholter Anwendungscode		
	mov R0, #10        
	bl up_delay					
	LDR R0, =GPIOC_IDR			; Einlesen der Tasten
	LDR R6, [R0] 
	AND R6, R6, #1
	CMP R6, #0					; Taster 1 gedrueckt?
	beq start					; Zeitmessung starten
	b loop						; Loop, bis Bedingung erfuellt ist

reset							; Zeitmessung zurueckgesetzt
	LDR R0, =GPIOC_IDR			
	LDR R6, [R0] 
	AND R6, R6, #1
	CMP R6, #0					
	beq neuStart				; Sprung zum Neustart
	
	LDRB R0, [R4, #0]			; Das 0. Element von Label (R4)
	MOV R1, #0x80				; auf der linken Seite (128)
	BL up_display				; Anzeige der Zahl
	BL timerdelay			    ; Timer-Delay für Zehntelsekunden
	
	LDRB R0, [R4, #0]			
	MOV R1, #0x00				; auf der rechten Seite (0)
	BL up_display				
	BL up_delay					
	B reset						; Keiner Taster? Sprung zum Reset


hochzaehlen					; Die Zahl wird hier hochgezaehlt
	LDR R12, =5				; Hilfszaehler wird zurueckgesetzt
	ADD R10, #1             ; Der Zaehler wird um 1 erhoeht
	CMP R10, #100			; Vergleich, ob die zu anzeigende Zahl den Wert 99 ueberschritten hat
	BEQ neuStart			; Wenn 99  berschritten ist, wird die Zeitmessung von 00 wieder anfangen
	B start					; Danach wird es auf start gesprungen

neuStart					
	LDR R10, =0				; Anzeigende Zaehler zurueckgesetzt
    LDR R12, =5				; Hilfszaehler auch zurueckgesetzt
	B start					; Alles zurueckgesetzt? Sprung auf start
	
start						
	LDR R0, =GPIOC_IDR			
	LDR R6, [R0] 
	AND R6, R6, #2
	CMP R6, #0			
	BEQ stop               ; 2. Taster gedrueckt wird, Zeitmessung gestoppt


	CMP R12, #0			   		
	BEQ hochzaehlen		   ; Zaehler 0 ist, wird die Zahl um 1 erhoeht
	UDIV R8, R10, R11	   ; Aenderung der Zehnerzahl = Zerlegung der zu anzeigenden Zahl durch
	MUL R9, R8, R11		  
	SUB R9, R10, R9
	LDRB R0, [R4, R9]	; R9 enthaelt den Wert
	MOV R1, #0x80		; R9 wird auf der linken Seite angezeigt
	BL up_display		
	BL timerdelay	   ;Timer-Delay für Zehntelsekunden
	
	
	LDRB R0, [R4, R8] 	; R8 enthaelt den Wert
	ADD R0, R0, R1		; R1, wegen rechte Seite (s.o.) 
	MOV R1, #0x00		; Zahl wird auf der rechten Seite angezeigt
	BL up_display		
	BL up_delay			
	
	SUB R12, #1			; R12, 1 substrahiert
	B start				; start, wenn keine Taster gedrueckt ist

stop					
	LDR R0, =GPIOC_IDR	
	LDR R6, [R0] 
	AND R6, R6, #1
	CMP R6, #0			
	BEQ start			; Wenn die 1. Taster gedrueckt, Zeitmessung weiter 
	LDR R0, =GPIOC_IDR	
	LDR R6, [R0] 
	AND R6, R6, #4
	CMP R6, #0					
	BEQ reset			; Wenn die 3. Taster gedrueckt, Zeitmessung stoppen


	LDRB R0, [R4, R9]	; Die Zahl der linken Seite, bei den Stop, wird angezeigt
	MOV R1, #0x80
	BL up_display
	BL timerdelay

	LDRB R0, [R4, R8]  ; Die Zahl der rechten Seite, bei den Stop, wird angezeigt
	ADD R0, R0, R1	   ; R1, wegen rechte Seite (s.o.) 
	MOV R1, #0x00
	BL up_display
	B stop				;  stop, wenn keine Taster gedrueckt ist
		
	ENDP
	
TIM7_IRQHandler PROC

    ldr R13, =	TIM7_SR
    ldr R14, = 0x0104
	str R13, [R14]
	
    ldr R13, = moving 
    add R13, #128
	
	ENDP
	
TIM6_IRQHandler PROC

    ldr R13, =	TIM6_SR
    ldr R14, = 0x0100
	str R13, [R14]
	
	ldr R13, = counter
    ldr R14, = 0x00
	str R13, [R14]	
	
	ENDP 
	
	
	END