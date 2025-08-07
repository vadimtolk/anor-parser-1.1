global falloc

section .note.GNU-stack noalloc noexec nowrite progbits

section .data
dirname db "testdir", 0
fileref db "testdir/memory.bin", 0 
filesize dq 0
msg db "Allocating of your MBYTES to testdir/memory.bin ..."
len equ $-msg

section .text
falloc:		shl rdi, 20						; mbytes value * 2^20 (get bytes)
			mov rsi, rdi					; copy to rsi
			shr rsi, 31						; rsi / 2^31 (check max size)
			mov qword [filesize], rdi		; else write 8 bytes which started from filesize's address to memory

			mov rax, 21						; sys_access
			mov rdi, dirname				; path of dir (relative)
			xor rsi, rsi					; is "testdir" here?
			syscall							
			test rax, rax					; if rax == 0
			jz next							; goto next (else make "testdir")

			mov rax, 83						; sys_mkdir
			mov rdi, dirname				; path of dir
			mov rsi, 0o755					; flags -rwxr-xr-x
			syscall
			test rax, rax					; if rax < 0
			js dir_err						; dir wasn't created (smth went wrong)

next:		mov rax, 2						; sys_open
			mov rdi, fileref				; path of file
			mov rsi, 0o2 | 0o100			; flags O_RDWR | 0_CREAT
			mov rdx, 0o644					; flags -rw-r--r--
			syscall	
			test rax, rax					; if rax < 0
			js near op_err					; file wasn't open
			mov r8, rax						; else move to r8 descriptor of file

			mov rax, 77						; sys_ftuncate
			mov rdi, r8						; descriptor
			mov rsi, qword [filesize]		; make large our file (for correctly sys_mmap)
			syscall		
			test rax, rax					; if rax < 0
			js ftunct_err					; file didn't become large

			mov rax, 9						; sys_mmap (r8 = descriptor)
			xor rdi, rdi					; start-address = NULL
			mov rsi, qword [filesize]		; size
			mov rdx, 0x3					; flags PROT_READ | PROT_WRITE
			mov r10, 0x1					; flag MAP_SHARED
			xor r9, r9						; offset = NULL
			syscall
			test rax, rax					; if rax < 0
			js mmap_err						; mmap wasn't
			mov r12, rax					; else move to r12 first-byte address of written "memory.bin" to RAM
	
			mov rax, 1						; console log
			mov rdi, 1
			mov rsi, msg
			mov rdx, len
			syscall

			mov rdi, r12					; rdi = r12
			mov rcx, qword [filesize]		; rcx = size
			mov al, " "						; symbol to fill our "memory.bin"'s bytes 
			rep stosb						; do it while rcx != 0
		
			mov rdi, r12					; first-byte pointer
			mov rsi, qword [filesize]		; size
			mov rax, 11						; sys_munmap
			syscall			
			test rax, rax					; if rax < 0
			js mmap_err						; munmap wasn't

			mov rax, 3						; sys_close
			mov rdi, r8						; descriptor
			syscall
			test rax, rax					; if rax < 0
			js cls_err						; file wasn't close

			xor rax, rax
			ret

;------------------------------------------ errors with own exit-status ----------------------------------------
op_err:		mov rax, 1
			ret

dir_err:	mov rax, 2
			ret

ftunct_err: mov rax, 3
			ret

mmap_err: 	mov rax, 4
			ret

cls_err:	mov rax, 5
			ret
