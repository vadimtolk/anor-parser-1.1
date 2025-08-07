global throw

section .data
ln db 0

section .text
throw:		push rdi
			push rsi
			push rdx
	
lp:			cmp qword [rcx], 0
			je next
			inc rcx	
			inc byte [ln]
			jmp lp					
		
next:		mov rax, 77             ; truncate to total len
            movzx rdi, byte [r10]
            movzx rsi, byte [ln]
            syscall
            mov rax, 11             ; munmap
            mov rdi, qword [r8]
            movzx rsi, word [r9]
            syscall
            mov rax, 3              ; close .futhconf
            mov rdi, qword [r10]
            syscall

			pop rdx
			pop rsi

			mov rax, 1
			mov rdi, 1
			syscall

			mov rax, 60
			pop rdi
			syscall
