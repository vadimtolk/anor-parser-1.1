global dump

section .note.GNU-stack noalloc noexec nowrite progbits

section .data
path db "testdir/logs.txt", 0		

section .text
dump:		mov r9, rdi				; get ptr to data (const char* from main.cpp)
			mov r10, rsi			; get size of data (strlen)

			mov rax, 2				; sys_open
			mov rdi, path			; path as 1st arg
			mov rsi, 0o2102			; flags (0_RDWR | O_CREAT | O_APPEND) as 2nd arg
			mov rdx, 0o644			; flags (-rw-r--r--) as 3rd arg
			syscall					; execute it
			test rax, rax			; if rax < 0
			js err					; goto err
			mov r8, rax				; else move to r8 file-descriptor (for writing to logs.txt)
	
			mov rax, 1				; sys_write
			mov rdi, r8				; descriptor 
			mov rsi, r9				; ptr to data
			mov rdx, r10			; size of data
			syscall					
			test rax, rax			; like 18-19 strs
			js err

			mov rax, 3				; sys_close
			mov rdi, r8				; descriptor
			syscall					
			test rax, rax			; like 18-19 strs
			js err

			xor rax, rax			; exit status = 0
			ret						; return rax

err:		mov rax, 1				; exit status = 1
			ret						; return rax
