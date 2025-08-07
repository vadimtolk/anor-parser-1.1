global hash

section .data
hsh times 10 db 0					; hash-buffer (10 bytes)

section .text
hash:		mov rsi, rdi			; rsi = address of 1st-byte of 'field-string' (source)
			mov al, 0x3d			; al = space's ASCII-code 
			xor r8, r8				; r8 = 0 (strlen)
			cld						; close direction (DF = 0) 	

cntlen:		inc r8					; ++r8
			scasb 					; compare 'al' with [rdi]
			jne cntlen				; if (al != [rdi]) continue
			dec r8					; --r8 (we added '=' in last iteration) 
			test r8, r8				; if r8 == 0
			jz lener				; error

			mov rcx, 10				; iterations
			mov rdi, hsh			; rdi = hash-buffer (destination)
			mov r14, rsi

hshlp:		mov r12b, byte [rsi]	; save current symbol from 'field-string' to r12b
			mov r10, r8				; copy strlen to handle iterations
			inc rsi					; next byte of 'field-string'
			mov r13, r14			; save 1st byte of input (to return r13 state after 'inner loop')
inner:		mov al, byte [r13]		; save current symbol in the inner-loop (it sometimes equal r12b)
			add al, r12b			;--------------------------------------------------------------------
			shr al, 1				; some magic transformations (check documentation to get more info) |
			stosb					;--------------------------------------------------------------------
			inc r13					; next byte of hash-buffer
			dec rcx					; --rcx
			jz end					; finish loop right now if 'global' iterations overed
			dec r10					; --r10
			jnz inner				; if r10 != 0 next 'inner' iteration
			jmp hshlp				; else next 'global' iteration

lener:		xor rax, rax			; len-error (nothing wouldn't be return)
			ret

end:		mov rax, hsh			; return hash-buffer's address
			ret
