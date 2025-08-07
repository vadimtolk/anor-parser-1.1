global threads
extern sysconf							; extern fn from <libc> to get

section .note.GNU-stack noalloc noexec nowrite progbits

section .text
threads:	mov rdi, 84			 		; _SC_NPROCESSORS_ONLN = 84 
			call sysconf				; read info about threads
			ret
