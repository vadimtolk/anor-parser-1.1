global load_ring

section .note.GNU-stack noalloc noexec nowrite progbits

section .data
conds db "/-\|"
timespec:
	sec dq 0
	nsec dq 200000000
ens db 10
l1 db 27, "[D"

section .text
load_ring:	mov r8, rdx
			mov r9, conds
			mov r12, rdi
			mov r13, rsi
			mov rax, 1
			mov rdi, 1
			mov rsi, r12
			mov rdx, r13
			syscall
			xor r10, r10

o_lp:		add r10, 4
			test r8, r8
			jz short end
i_lp:		test r10, r10
			jz short dec_r8
			mov rax, 1
			mov rdi, 1
			lea rsi, [conds + 4]
			sub rsi, r10
			mov rdx, 1
			syscall
			mov rax, 35
			mov rdi, timespec
			xor rsi, rsi
			syscall
			mov rax, 1
			mov rdi, 1
			mov rsi, l1
			mov rdx, 3
			syscall
			dec r10
			jmp short i_lp

dec_r8:  	dec r8
			jmp short o_lp

end:		ret
