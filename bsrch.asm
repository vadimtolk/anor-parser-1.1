global bsrch

section .text
bsrch:	mov rsi, qword [rsp + 8]; rsi = drname's 1st byte's address
		mov r15, rdi			; save buf to r15

		mov rcx, qword [rsp + 16]; rcx = hashlen
		mov rbx, rcx			; copy it to rbx
		xor r8, r8				; zero-index (1st byte)
		mov r9,  qword [rsp + 24]	; last-index (last byte)
		xor r10, r10			; move-index in hashs

lp:		mov rax, r9				;------------------------------------------ 
		add rax, r8				; rax = (last + end) / 2 [without resude] |
		shr rax, 1				;------------------------------------------
		mov r10, rax			; save index
		mul rbx					; rax-index *= 10 (offset to get moving which equal hashlen)
		mov r13, rsi			; save rsi state (still point to 1st byte)
		add rsi, rax			; 'move' rsi to middle-hash
		repe cmpsb				; compare it
		je equ					; if after comparement ZF == 0 => hashs are equal
		lahf					; load flags to AH (save state)
		cmp r9, r8				; set flags as result of compatement of curr/last indexes 
		jle fail				; if after "repe cmpsb" r9 <= r8 --> last unchecked hash not equal inputed hash
		sahf					; set flags again to know current <>=? inputed
		ja srcabv				; if someone rsi's byte > rdi's byte crope from right side 

		; else crope from left side
		mov r8, r10
		inc r8
		mov rsi, r13			; return to rsi his state  <-|          
		mov rdi, r15			; return to rdi his state  <-|--(after cmpsb)
		mov rcx, rbx			; return to rcx his state  <-|          
		jmp lp					; next iter

srcabv:	mov r9, r10
		dec r9					; except pivot
		mov rsi, r13			; like 31-34 str
		mov rdi, r15
		mov rcx, rbx
		jmp lp

equ:	mov rax, r10			; return index (aka token)
		ret

fail:	xor rax, rax			; return -1
		not rax
		ret
