global lexer

extern throw	; <--|
extern rmspc	; <--|
extern hash		; <--|-- extern subprogramms to show linker that these functions declarated and he must find those
extern bsrch	; <--|
extern toint	; <--|

;--------------------------------------- read-only section (constants) -------------------------------------

section .rodata
; filepath
path db ".futhconf", 0
; every hash has his own token which equals his index
hashs:                              
;   drname db "dfkibhdfim"         ; token = 0
    flc db "fciijdcaff"            ; token = 1
;   logttl db "lmipjplhmo"         ; token = 2
;   memttl db "mimpkpliie"         ; token = 3
	vcl db "vkqqrlkaff"            ; token = 4

; specificators
def db "default"
mxav db "max_available"
mnac db "min_availavle"
null db "NULL"

; operator
eqsym db "="

; errors
opnerr_	db "Open error : '.futhconf' not found in current directory", 10
opnelen equ $-opnerr_
ftrerr_ db "Ftruncate error", 10
ftrelen equ $-ftrerr_
mmaperr_ db "Memory mapping error", 10
mmapelen equ $-mmaperr_
srcherr_ db "Syntax error : line is empty", 10
srchelen equ $-srcherr_
fnferr_ db "Field not found", 10
fnfelen equ $-fnferr_
spcerr_ db "Syntax error : '=' expected", 10
spcelen equ $-spcerr_
cperr_ db "Syntax error : ';' expected", 10
cpelen equ $-cperr_

; mmap & ftruncate size (4kb)
sz dw 4096

; ------------------------------------ runtime variables -------------------------------------------------------

section .data
buf times 20 db 0					; string to validate
flg db 1							; equal-symbol flag (0 = ok / !0 = fail)

descr db 0							; opened file's descriptor
fptr dq 0							; file-pointer (rax after mmap)

crx dq 0							; current rax (to save it's state)
llen dq 0							; line-lenght (len of parsed line)
sfp dq 0 							; start file-pointer 
crp dq 0							; current-pointer
lsp dq 0							; last stack-pointer (to clear stack after finish)
fsp dq 0							; first stack-pointer (to cmp with lsp [fsp == lsp => stack cleared])
sbp	dq 0							; saved base pointer (to return his state after finish)
ttl dq 0 							; total length of cfg-lines

values:								; struct "values" 
;	drval dq 0						; dirname 
	flcval dq 0						; falloc val
;	lgval dq 0						; log-file name
;	memval dq 0						; mem-file name
	vlcval dq 0						; valloc val

section .text
; ------------------------------------- prepairing to validate input -----------------------------------------

lexer:		mov qword [fsp], rsp	; save rsp
			mov qword [sbp], rbp	; save rbp
			mov rbp, rsp			; copy
			mov rax, 2				; sys_open
			mov rdi, path			; path
			mov rsi, 2				; O_RDWR
			mov rdx, 0o666			; rw-rw-rw
			syscall				
			test rax, rax			; is rax == -1
			js opnerr				; err
			mov byte [descr], al	; save descriptor

			mov rax, 77				; sys_ftruncate
			movzx rdi, byte [descr]	; descriptor
			movzx rsi, word [sz]	; size (size must be % 4096 == 0)
			syscall				
			test rax, rax			; if rax == -1
			js ftrerr				; err

			mov rax, 9				; sys_mmap
			xor rdi, rdi			; byte to allocate = NULL (OS will makes decidion)
			movzx rsi, word [sz]	; size (like 83)
			xor rdx, rdx			; PROT_READ
			inc rdx					
			movzx r8, byte [descr]	; descr
			mov r10, 0x02			; MAP_SHARED	
			xor r9, r9				; offset = NULL
			syscall
			test rax, rax			; rax ?= 0
			js mmaperr				; err
			mov qword [crx], rax	; current rax -> crx
			mov qword [sfp], rax	; start ptr = rax

; ----------------------------------- main loop (while [crx] != '\0') -----------------------------------------

mlp:		mov rax, qword [crx]	; rax = address of first line's byte
			mov r9b, byte [rax]		; r9b = [rax]
			test r9b, r9b			; if r9b == '\0'
			jz final				; all lines handled
			cmp r9b, 10				; if r9b == '\n'
			je emptln				; file is empty (for POSIX ide)
			mov rsi, rax			; src = file
			mov rdi, buf			; dest = buf
			xor rcx, rcx			; rcx aka symbol-counter = 0
			mov r15, values			; r15 = val-struct

prsline:	inc rcx					; ++rcx
			cmp byte [rsi], 0x3d	; if currenct byte == "="
			je stflg				; set equ-symbol flag
agn:		cmp byte [rsi], 0x3b	; if current byte == ';' (terminate-symbol for this ctx) --|
			movsb					; rsi --> rdi && ++rsi && ++ rdi						   |
			je fncalls				; validate parsed line									<--|
			cmp rcx, 20				; if rcx != 20
			jne prsline				; next iter
			jmp cperr				; else "comma&point" not found (all str parsed)

stflg:		dec byte [flg]			; --flg (if flg becomes less than 0 --> err)
			jmp short agn			; goto agn

; ********* calling of extern-functions *********
fncalls:	mov qword [llen], rcx	; line-length = rcx
			inc qword [llen]		; inc it (yet '\n')
			add qword [ttl], rcx	; total len += rcx
			mov r10b, byte [flg]	; r10b = flg
			test r10, r10			; if flg != 0 
			jnz spcerr				; err
			mov rdi, buf			; dest = buf
			mov rsi, rcx			; rsi = line len
			call rmspc				; remove spaces (spaces between commands don't matter)
			mov rdx, rdi			; rdx = index of 1st byte of value
			mov rdi, rax			; rdi = handled buf
			push rdx				; save state
			push rsi				; 
			call hash				; hash parsed field
			mov rdi, rax			; rdi = hash-bufer (in the "hash.asm")
;			push qword 4			; last byte 
			push qword 1			; TEMPORARY!!!
			push qword 10			; hashlen
			push hashs				; hashs to cmp
			call bsrch				; binary search of hash
			add rsp, 24				; rsp down on 3 bytes
			mov rdi, rax			; rdi = token of hash (index of field in 'values')
			test rdi, rdi			; if rdi == -1
			js fnferr				; err
			lea r15, [values + rdi * 8]	; load-effective-address to r15 (values + rdi-offset)
			mov qword [crp], r15	; current-pointer --> currnet cell of 'values' (save state)
			pop rdx					; return state
			pop rdi					; 
			mov rsi, buf			; src = buf
			call toint				; cast string-value to integer (result returned to rax)
			mov r15, qword [crp]	; return state
			mov qword [r15], rax	; current cell = value
			mov rax, qword [crx]	; rax = start of line
			add rax, qword [llen]	; rax += line lenght (now rax point to 1st byte of next line)
			mov qword [crx], rax	; current rax = rax
			inc byte [flg]			; set flg to 1 
			push rdi				; save last sp
			mov rcx, 20				;----------------
			xor rax, rax			;				|
			mov al, 0				;  clear buf	|
			mov rdi, buf			;				|
			rep stosb				;----------------
			pop rdi					; return last sp
			jmp mlp					; goto parse next line

; ****** final handlings (clear stack, ret) ******
final:		mov rcx, qword [llen]	; rcx = len
			test rcx, rcx			; if len == 0
			jz emptln				; file is empty ---> err
			mov qword [lsp], rdi	; last stack-pointer = rdi
			mov rsp, qword [lsp]	; stack-pointer = last stack-pointer
	
cllp:		cmp rsp, qword [fsp]	; while rsp != fsp 
			je rtrn					; goto ret
			mov qword [rsp], 0		; set [rsp] 0
			add rsp, 8				; rsp down to 1 byte
			jmp cllp				; again

rtrn:		mov rax, 77				; truncate to total len
			movzx rdi, byte [descr]	
			mov rsi, qword [ttl]
			inc rsi
			syscall
			mov rax, 11				; munmap
			mov rdi, qword [sfp]
			movzx rsi, word [sz]
			syscall
			mov rax, 3 				; close .futhconf
			mov rdi, qword [descr]
			syscall
			mov rax, values			; rax = pointer to val-strunct
			mov rbp, qword [sbp]	; rbp = saved rbp
			ret						; return 

; ------------------------------- errors and their status (throw exception) ---------------------------
	
opnerr:		mov rdi, 1
			mov rsi, opnerr_
			mov rdx, opnelen
			mov r10, descr
			mov r8, sfp
			mov r9, sz
			mov rcx, qword [sfp]
			call throw

ftrerr:		mov rdi, 2
			mov rsi, ftrerr_
			mov rdx, ftrelen
			mov r10, descr
			mov r8, sfp
			mov r9, sz
			mov rcx, qword [sfp]
			call throw

mmaperr:	mov rdi, 3
			mov rsi, mmaperr_
			mov rdx, mmapelen
			mov r10, descr
			mov r8, sfp
			mov r9, sz
			mov rcx, qword [sfp]
			call throw

srcherr:	mov rdi, 4
			mov rsi, srcherr_
			mov rdx, srchelen
			mov r10, descr
			mov r8, sfp
			mov r9, sz
			mov rcx, qword [sfp]
			call throw

emptln:		mov rdi, 5
			mov rsi, spcerr_
			mov rdx, spcelen
			mov r10, descr
			mov r8, sfp
			mov r9, sz
			mov rcx, qword [sfp]
			call throw 

fnferr:		mov rdi, 6
			mov rsi, fnferr_
			mov rdx, fnfelen
			mov r10, descr
			mov r8, sfp
			mov r9, sz
			mov rcx, qword [sfp]
			call throw

spcerr:		mov rdi, 7
			mov rsi, spcerr_
			mov rdx, spcelen
			mov r10, descr
			mov r8, sfp
			mov r9, sz
			mov rcx, qword [sfp]
			call throw

cperr:		mov rdi, 8
			mov rsi, cperr_
			mov rdx, cpelen
			mov r10, descr
			mov r8, sfp
			mov r9, sz
			mov rcx, qword [sfp]
			call throw
