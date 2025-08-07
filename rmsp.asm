global rmspc

section .rodata
spc db " "

section .data
cind dq 0								; current index
ind dq 0								; start value index	
tmp db 0								; line len with '\n'
tmp1 db 0								; how many spaces were removed
eqi dq 0								; equal index (would set only if after '=' not space)

section .text
rmspc:		mov rcx, rsi				; command's length + '\n'
			mov byte [tmp], cl			; save len
			mov r12, rdi				; save state of buffer's address
			mov r9b, byte [spc]			; get space symbol

while:		cmp byte [rdi], 0x3b		; if [rdi] == ';'
			je end						; cycle will end
			cmp byte [rdi], r9b			; compare [rdi] with space 
			je equ						; if == goto 'equal' instructions
			cmp byte [rdi], 0x3d		; if curr == '=' chech something
			je chck
cont:		inc rdi						; else get next byte in buff 
			inc qword [cind]			; ++curr-ind
			loop while					; --rcx && jmp while	

chck:		cmp byte [rdi + 1], r9b		; if equ-sym + 1 == space --> it's okay
			je cont						
			push qword [cind]			; but else save to eqi current-index (index of equ-sym)
			pop qword [eqi]				; pop to eqi
			jmp short cont				; and go again

equ:		inc byte [tmp1]				; spaces-removed counter
			mov r11, qword [cind]		; r11 = current index
			mov qword [ind], r11		; index of space = r11
			mov r8, rcx					; save rcx's state to r8
			mov r10, rdi				; and save rdi's state to r10
			mov rsi, rdi				; 
			inc rsi						; get index of symbol after space (for memset)
			dec rcx						; movsb will complete (rcx - 1) times
			rep movsb 					
			mov rcx, r8					; return states of rcx & rdi
			mov rdi, r10				
			jmp short while				; goto while again

end:		cmp qword [eqi], 0			; if eqi != 0
			jnz chgind					; goto chgind
ag:			dec byte [tmp]
			movzx rcx, byte [tmp]		; rcx = index of last sym
			sub cl, byte [tmp1]		    ; rcx - count of other '\n'
			sub rcx, qword [ind]		; rcx - index of space (after movsb index of first byte str-value)
			mov rdi, qword [ind]		; rdi = index of 1st byte str-value
			mov rsi, rcx				; rsi = strlen of value
			mov rax, r12				; move buff's address to rax
			mov qword [cind], 0			; set [cind] 0
			mov byte [tmp1], 0			; set [tmp1] 0
			mov qword [eqi], 0			; this set 0 too :)
			ret							; return rax

chgind:		mov r8, qword [eqi]			; r8 = equ-ind 
			inc r8						; r8 = int of 1st value-sym
			mov qword [ind], r8			; now ind = r8
			jmp short ag				; goto ag
