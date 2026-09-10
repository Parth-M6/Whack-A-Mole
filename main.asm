CODE SEGMENT
	ASSUME CS:CODE, DS:CODE, SS:CODE
		ORG 0400H
    
START:

	MOV AX, CS          
    MOV DS, AX
	JMP MAIN
    PORTA   EQU 0FFF8H
    PORTB   EQU 0FFFAH
    PORTC   EQU 0FFFCH
    PORTCON EQU 0FFFEH
    LEDTAB  DB 01H,02H,04H,08H,10H,20H
    SCORE   DB 1 dup(00H)
    RIDX    DB 1 dup(02H)
    RCNT    DB 1 dup(52H)
    
MAIN:
    MOV AL, 82H
	MOV DX, PORTCON
    OUT DX, AL
	
    
    
GAME_LOOP:
    LEA SI,RCNT
    MOV AL,[SI]
    DEC AL
    MOV [SI],AL
    CMP AL,00H
    JE GAME_OVER
    
    MOV AL, [RIDX]
    MOV BL, [RCNT]
    MUL BL
    ADD AL, 07H
    MOV [RIDX], AL
    MOV AH, 00H
    MOV CL, 06H
    DIV CL
    MOV BL, AH
    MOV BH, 00H
    LEA SI, LEDTAB
    ADD SI, BX
    MOV AL, [SI]
    MOV DX, PORTA
    OUT DX, AL
    MOV AH, AL
	
	
    MOV DI, 0FFFFH
	MOV CX, 0001H          ; Outer loop: Set this to 5 for ~1 second timeout


WAIT_OUTER:
    MOV DI, 0AF23H         
WAIT_INNER:
    MOV DX, PORTB     
    IN  AL, DX        
    
    ; Check for noise OR no button pressed
    CMP AL, 0C0H      ; If it's noise...
    JE  IDLE_PROCEED  ; ...treat it as "nothing pressed" and keep timing
    CMP AL, 0FFH      ; If truly nothing is pressed...
    JE  IDLE_PROCEED  ; ...keep timing
    
    ; If we reach here, a button might be pressed
    MOV BL, AL        
    MOV BH, 0FFH      
DLY: 
    DEC BH
    JNZ DLY
    IN  AL, DX        
    CMP AL, BL        ; Debounce check
    JNE WAIT_INNER    ; If unstable, try again
    
    ; If stable and not 0FFH/0C0H, it's a real press
    JMP HIT_CHECK

IDLE_PROCEED:
    DEC DI
    JNZ WAIT_INNER         
    LOOP WAIT_OUTER        
    
    JMP ROUND_END     ; Timeout reached, move to next round
	
HIT_CHECK:
    NOT AL
    AND AL,00111111B
    CMP AL, AH       
    JNE ROUND_END    ; Wrong button? Start new round 
	MOV AH,AL
	
    INC BYTE PTR [SCORE]

    
RELEASE_WAIT:
	
    MOV DX, PORTB     ; PORTB address
    IN  AL, DX          ; First read
    CMP AL,0C0H
    JE RELEASE_WAIT
    MOV BL, AL          ; Store in BL
    MOV CX, 0105H       
DLAY: LOOP DLAY
    IN  AL, DX          ; Second read
    CMP AL, BL          ; Do both reads match?
    JNE RELEASE_WAIT
    NOT AL              ; Invert to match the pressed state
    AND AL, 00111111B
    CMP AL, AH          ; Wait until the SPECIFIC button is released
    JE  RELEASE_WAIT
    
ROUND_END:
    MOV AL, [SCORE]
    AAM              
    MOV CL, 04H
    SHL AH, CL
    OR  AL, AH
	MOV DX,PORTC
    OUT DX, AL
    CALL DELAY
    JMP GAME_LOOP
    
GAME_OVER:
    MOV AL, 00H
    MOV DX, PORTA
    OUT DX, AL
	LEA SI,SCORE
    MOV AL, [SI]
    AAM              ; Useful instruction: AH=Tens, AL=Ones
    MOV CL, 04H
    SHL AH, CL
    OR  AL, AH
	MOV DX,PORTC
    OUT DX, AL
	
    HLT

DELAY PROC NEAR
    MOV BX, 0001H    ; Outer loop: adjust this for more/less time (00FFH is very slow)
DLY_OUTER:
    MOV CX, 0AF23H   ; Inner loop
DLY_INNER:
    LOOP DLY_INNER
    DEC BX
    JNZ DLY_OUTER
    RET
DELAY ENDP

CODE ENDS
END START