org 0x7C00
bits 16


%define ENDL 0x0D, 0x0A

start:
	jmp main


; prints a string in the screen
; params:
;    - (ds:si points to string
;
puts:
	; saves registers we will modify
	push si
	push ax

.loop:
	lodsb
	or al,al
	jz .done

	mov ah, 0x0E
	mov bx, 0x000F	; text color white
	int 0x10

	jmp .loop


.done:
	pop ax
	pop si
	ret

main:
	
	;setup data segments
	mov ax, 0	; cannot write to ds/es directly
	mov ds, ax
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7C00	; stack grows downword from where we are loaded in the memory
	
	cld

	; print message
	mov si, msg
	call puts

	hlt

.halt:
	jmp .halt

msg: db 'Welcome back sanz', ENDL, 0

times 510-($-$$) db 0
dw 0xAA55
