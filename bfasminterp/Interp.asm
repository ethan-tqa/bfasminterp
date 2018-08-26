.code

; Registers RCX, RDX, R8 and R9 are used to pass the first four arguments
; https://msdn.microsoft.com/en-us/library/9z1stfyw.aspx

; https://stackoverflow.com/questions/6421433/address-of-labels-msvc

; C signature: 
; extern "C" int interpret(instruction* instructions, size_t count, int8_t* mem);
; so
; RCX = pointer to instructions
; RDX = instructions count
; R8 = pointer to interpreter memory

; used registers:
; RCX = instruction pointer
; 

printChar PROTO C

interpret proc C
.code
	push rbx		; these are callee saved ?
	push rsi
	push rdi
	push rbp
	push r12
	push r13
	push r14
	push r15

	xor rbx, rbx	; clear these guys
	xor rsi, rsi
	xor rdi, rdi
	xor r14, r14	; store the value of current mem cell, which of course starts at 0s

	lea r15, [jumptable]				; load the address of the table

	jmp lbl_begin	; don't want to increase rsi in the first loop

lbl_interp_loop:	; beginning of new interpreter cycle
	add rcx, 4		; advance the bytecode stream by 4 bytes (1 instruction)

lbl_begin:
	mov rax, [rcx]
	movzx r10, ax
	movzx r11d, word ptr [rcx + 2]
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx

ALIGN 4
lbl_Loop:
	cmp byte ptr [r8], 0
	je lbl_set_loop_ip
	
	add rcx, 4		; advance the bytecode stream by 4 bytes (1 instruction)
	mov rax, [rcx]
	movzx r10, ax
	movzx r11d, word ptr [rcx + 2]
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx

lbl_set_loop_ip:
	mov rax, r11
	shl rax, 2
	add rcx, rax
	
	add rcx, 4		; advance the bytecode stream by 4 bytes (1 instruction)
	mov rax, [rcx]
	movzx r10, ax
	movzx r11d, word ptr [rcx + 2]
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Return:
	cmp byte ptr [r8], 0
	jne lbl_set_return_ip
	
	add rcx, 4		; advance the bytecode stream by 4 bytes (1 instruction)
	mov rax, [rcx]
	movzx r10, ax
	movzx r11d, word ptr [rcx + 2]
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx

lbl_set_return_ip:
	mov rax, r11
	shl rax, 2
	sub rcx, rax
	
	add rcx, 4		; advance the bytecode stream by 4 bytes (1 instruction)
	mov rax, [rcx]
	movzx r10, ax
	movzx r11d, word ptr [rcx + 2]
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Right:
	add r8, r11
	
	add rcx, 4		; advance the bytecode stream by 4 bytes (1 instruction)
	mov rax, [rcx]
	movzx r10, ax
	movzx r11d, word ptr [rcx + 2]
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Left:
	sub r8, r11
	
	add rcx, 4		; advance the bytecode stream by 4 bytes (1 instruction)
	mov rax, [rcx]
	movzx r10, ax
	movzx r11d, word ptr [rcx + 2]
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Add:
	add byte ptr [r8], r11b
	
	add rcx, 4		; advance the bytecode stream by 4 bytes (1 instruction)
	mov rax, [rcx]
	movzx r10, ax
	movzx r11d, word ptr [rcx + 2]
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Minus:
	sub byte ptr [r8], r11b
	
	add rcx, 4		; advance the bytecode stream by 4 bytes (1 instruction)
	mov rax, [rcx]
	movzx r10, ax
	movzx r11d, word ptr [rcx + 2]
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx

lbl_Print:
	push rcx
	push rdx
	push r8
	push r9		; HACK XXX BAD: I currently do not understand why R9 is stomped after calling printChar
	sub rsp, 32
	movzx rcx, byte ptr [r8]
	call printChar
	add rsp, 32
	pop r9
	pop r8
	pop rdx
	pop rcx
	jmp lbl_interp_loop
lbl_Read:
	jmp lbl_interp_loop
lbl_Invalid:
	jmp lbl_interp_loop

jumptable:		; MASM cannot emit relative address in .data, so must put it in .code this way (agner)
	dq lbl_Loop
	dq lbl_Return
	dq lbl_Right
	dq lbl_Left
	dq lbl_Add
	dq lbl_Minus
	dq lbl_Print
	dq lbl_Read
	dq lbl_Invalid
	dq lbl_End

lbl_End:
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	pop rdi
	pop rsi
	pop rbx

	ret
interpret endp
end