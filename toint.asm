global toint

extern bsrch

section .rodata
nums db "0123456789"

section .data
csp dq 0								; current stack-pointer
lsp dq 0								; last stack-pointer

section .text
toint:		mov qword [csp], rsp		; set csp
			lea rbx, [rsi + rdi]		; rbx = line's address + offset to value
			mov rcx, rdx				; lenght of string-value
			xor r8, r8					; accum
			xor r9, r9					; r9 = 0
			inc r9						; r9 = 1 aka multipler
			mov r10, 10

ilp:		push rbx					; <--|
			push rcx					; <--|
			push r8						; <--|--- save states
			push r9						; <--|
			push r10					; <--|
			mov rdi, rbx				; rdi = rbx
			add rdi, rcx				; + rcx
			dec rdi						; - 1 (count units from right to left)
			push qword 9				; <--|
			push qword 1				; <--|--- args to bsrch
			push nums					; <--|
			call bsrch
a3:			mov r9, qword [rsp + 32]	; ret r9	
			mul r9						; rax * r9
			mov r8, qword [rsp + 40]	; ret r8
			add r8, rax					; r8 += rax
			mov r10, qword [rsp + 24]	; ret r10
			imul r9, r10				; r9 *= 10
			mov rcx, qword [rsp + 48]	; ret rcx
			mov rbx, qword [rsp + 56]	; ret rbx
			loop ilp					; --rcx && next iter

ov:			mov qword [lsp], rsp		; lsp = rsp
			mov rsp, qword [csp]		; rsp = csp
			mov rax, r8					; rax = result
			mov rdi, qword [lsp]		; rdi = lsp
			ret
