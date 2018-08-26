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
	sub rsp, 32		; shadow space?

	xor rsi, rsi	; "program counter", which instruction we are at
	mov rdi, r8		; "memory pointer", where we are pointing to in the interpreter memory
	xor r14, r14	; store the value of current mem cell, which of course starts at 0

	lea r15, [jumptable]				; load the address of the table
	mov r13, rcx	; base address of instruction array

lbl_interp_loop:	; beginning of new interpreter cycle
	movzx r10, word ptr [r13 + rsi*4]
	movzx r11, word ptr [r13 + rsi*4 + 2]
	inc rsi			; advance to the next instruction
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx

ALIGN 4
lbl_Loop:
	cmp byte ptr [rdi], 0
	je lbl_set_loop_ip
	movzx r10, word ptr [r13 + rsi*4]
	movzx r11, word ptr [r13 + rsi*4 + 2]
	inc rsi			; advance to the next instruction
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx

lbl_set_loop_ip:
	mov rax, r11
	add rsi, rax
	movzx r10, word ptr [r13 + rsi*4]
	movzx r11, word ptr [r13 + rsi*4 + 2]
	inc rsi			; advance to the next instruction
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Return:
	cmp byte ptr [rdi], 0
	jne lbl_set_return_ip
	movzx r10, word ptr [r13 + rsi*4]
	movzx r11, word ptr [r13 + rsi*4 + 2]
	inc rsi			; advance to the next instruction
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx

lbl_set_return_ip:
	mov rax, r11
	sub rsi, rax
	movzx r10, word ptr [r13 + rsi*4]
	movzx r11, word ptr [r13 + rsi*4 + 2]
	inc rsi			; advance to the next instruction
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Right:
	add rdi, r11
	movzx r10, word ptr [r13 + rsi*4]
	movzx r11, word ptr [r13 + rsi*4 + 2]
	inc rsi			; advance to the next instruction
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Left:
	sub rdi, r11
	movzx r10, word ptr [r13 + rsi*4]
	movzx r11, word ptr [r13 + rsi*4 + 2]
	inc rsi			; advance to the next instruction
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Add:
	add byte ptr [rdi], r11b
	movzx r10, word ptr [r13 + rsi*4]
	movzx r11, word ptr [r13 + rsi*4 + 2]
	inc rsi			; advance to the next instruction
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx
	
ALIGN 4
lbl_Minus:
	sub byte ptr [rdi], r11b
	movzx r10, word ptr [r13 + rsi*4]
	movzx r11, word ptr [r13 + rsi*4 + 2]
	inc rsi			; advance to the next instruction
	mov rbx, qword ptr [r15 + r10 * 8]	; add the offset
	jmp rbx

lbl_Print:
	movzx rcx, byte ptr [rdi]
	call printChar
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
	add rsp, 32
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