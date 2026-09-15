org 0x7C00
bits 16


%define ENDL 0x0D, 0x0A

;
; FAT12 header
;
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'      ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880             ; 2880 * 512 = 144KB
bdb_media_descriptor_type:  db 0F0h             ; 0F0h = 3.5" floppy
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sector:          dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0
ebr_reserved:               db 0
ebr_signature:              db 29h
ebr_volume_id:              dd 0
ebr_volume_label:           db 'SANZ OS'
ebr_system_id:              db 'FAT12'

;
; Code starts here
;
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


	mov [ebr_drive_number], dl

	mov ax, 1
	mov cl, 1
	mov bx, 0x7E00
	call disk_read


	; print message
	mov si, msg_hello
	call puts

	cli                                     ; disable interrupts, this way we CPU can't get out of "halt" state
	hlt

;
; Error handlers
;

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                                 ; wait for keypress
    jmp 0FFFFh:0                            ;jump to beginning of BIOS, should wait_key_and_reboot

.halt:
    cli                                     ; disable interrupts, this way we CPU can't get out of "halt" state
    hlt


;
; Convert from an LBA address to a CHS address
; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head
;

lba_to_chs:

    push ax
    push dx

    xor dx, dx                          ; dx = 0
    div word [bdb_sectors_per_track]    ; ax = LBA / SectorPerTrack
                                        ; dx = LBA % SectroPerTrack
    inc dx                              ; dx = (LBA % SectroPerTrack + 1) = sector
    mov cx, dx                          ; cx = sector

    xor dx, dx
    div word [bdb_heads]                ; ax = (LBA % SectroPerTrack) / Heads = cylinder
                                        ; dx = (LBA % SectroPerTrack) % Heads = head
    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                          ; restore DL
    pop ax
    ret


;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store/read data
;
disk_read:

    push ax                             ; save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             ; temp save CL (number of sectors to read)
    call lba_to_chs                     ; compute CHS
    pop ax                              ; AL = number of sectors to read

    mov ah, 02h
    mov di, 3                           ; retry count

.retry:
    pusha                               ; save all registers, incase bios modifies any of them
    stc                                 ; set carry flag, incase bios didn't set it
    int 13h                             ; if the carry flag cleared = success
    jnc .done

    ; if it failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.failed:
    jmp floppy_error                    ; if all attempts failed

.done:
    popa


    pop di
    pop dx
    pop cx
    pop bx
    pop ax                              ; restore registers we modified
    ret

;
; Reset disk controller
; Parameters:
;   - dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


msg_hello: db 'Welcome back sanz', ENDL, 0
msg_read_failed: db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0
dw 0xAA55
