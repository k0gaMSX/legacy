# fMSX: portable MSX emulator *****************************
#                                                         *
#                      pc98gn2.asm                        *
#                                                         *
# This file contains graphic drivers for PC9800 series    *
# normal graphic mode implementations.                    *
#                                                         *
# fMSX   Copyright (C) Marat Fayzullin 1994,1995          *
# fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            *
#     You are not allowed to distribute this software     *
#     commercially. Please, notify me, if you make any    *
#     changes to this file.                               *
#**********************************************************

	.file "pc98gn2.asm"

.macro extract1
	movzbl %bh,%eax
	movl _pattern(,%eax,4),%eax
	andl %ebp,%eax
	orl %eax,%ecx
	rorl $2,%ebp
.endm

.macro extract2 offset
	movl offset(%esi),%ebx
	movl %ebx,640*240+offset(%esi)
	andl $0x0f0f0f0f,%ebx
	movl %ebx,%eax
	roll $12,%eax
	orl %eax,%ebx
.endm

.macro extract3
#	movl (%esi),%eax
#	cmpl 640*240(%esi),%eax
#	jne 8f
#	movl 4(%esi),%eax
#	cmpl 640*240+4(%esi),%eax
#	jne 8f
#	movl 8(%esi),%eax
#	cmpl 640*240+8(%esi),%eax
#	jne 8f
#	movl 12(%esi),%eax
#	cmpl 640*240+12(%esi),%eax
#	je 9f

8:	extract2 0
	movzbl %bh,%eax
	movl _pattern(,%eax,4),%ecx
	andl %ebp,%ecx
	rorl $2,%ebp
	rorl $16,%ebx
	extract1
	extract2 4
	extract1
	rorl $16,%ebx
	extract1

	pushl %ecx
	extract2 8
	movzbl %bh,%eax
	movl _pattern(,%eax,4),%ecx
	andl %ebp,%ecx
	rorl $2,%ebp
	rorl $16,%ebx
	extract1
	extract2 12
	extract1
	rorl $16,%ebx
	extract1
	popl %ebx

	xchgb %cl,%bh
	movw %bx,%es:0xa8000(%edi)
	movw %cx,%es:0xb0000(%edi)
	rorl $16,%ebx
	rorl $16,%ecx
	xchgb %cl,%bh
	movw %bx,%es:0xb8000(%edi)
	movw %cx,%es:0xe0000(%edi)
9:	addl $2,%edi
	addl $16,%esi
.endm

.macro extract4
	movzbl %bh,%eax
	movl _pattern2(,%eax,4),%eax
	andl %ebp,%eax
	orl %eax,%ecx
	rorl $4,%ebp
.endm

.macro extract6
#	incl _rewritescr0
#	movl (%esi),%eax
#	cmpl 640*240(%esi),%eax
#	jne 8f
#	movl 4(%esi),%eax
#	cmpl 640*240+4(%esi),%eax
#	jne 8f
#	movl 8(%esi),%eax
#	cmpl 640*240+8(%esi),%eax
#	jne 8f
#	movl 12(%esi),%eax
#	cmpl 640*240+12(%esi),%eax
#	je 9f

8:
#	incl _rewritescr1
	extract2 0
	movzbl %bh,%eax
	movl _pattern2(,%eax,4),%ecx
	andl %ebp,%ecx
	rorl $4,%ebp
	rorl $16,%ebx
	extract4

	pushl %ecx
	extract2 4
	movzbl %bh,%eax
	movl _pattern2(,%eax,4),%ecx
	andl %ebp,%ecx
	rorl $4,%ebp
	rorl $16,%ebx
	extract4
	popl %ebx

	xchgb %cl,%bh
	movw %bx,%es:0xa8000(%edi)
	movw %cx,%es:0xb0000(%edi)
	rorl $16,%ebx
	rorl $16,%ecx
	xchgb %cl,%bh
	movw %bx,%es:0xb8000(%edi)
	movw %cx,%es:0xe0000(%edi)
9:	addl $2,%edi
	addl $8,%esi
.endm

#	macro extract 3 / 6 (with x2 magnification)
#		input registers
#			ebp: pattern mask (0x03030303)
#			esi: data address (0-15 / byte)
#			edi: G-RAM address
#		output registers
#			esi: next data
#			edi: next G-RAM address
#		broken registers
#			eax,ebx,ecx



setup200:
	pushl %eax
	cmpb $1,_csrform
	je 0f
	movb $1,_csrform
	call _setcsrform
0:	movl $0,_lineStep
	movzbl _RefreshLine,%eax
	shrl $2,%eax
	cmpb $41,%al
	jc 0f
	movb $40,%al
0:	imul $320,%eax
	cmpb $0,_width512
	je 1f
	addl %eax,%eax
1:	addl %eax,%esi
	movb _scrHeight,%dl
	popl %eax
	ret

setupinter:
	cmpb $0,_csrform
	je 0f
	movb $0,_csrform
	call _setcsrform
0:	pushl %eax
	movl $80,_lineStep
	movzbl _RefreshLine,%eax
	shrl $2,%eax
	cmpb $41,%al
	jc 0f
	movb $40,%al
0:	imul $320,%eax
	cmpb $0,_width512
	je 1f
	addl %eax,%eax
1:	addl %eax,%esi
	movb $204,%dl
	popl %eax
	ret

write1:
	movl $0xc0c0c0c0,%ebp
0:	movb $40,%dh
1:	extract3
	decb %dh
	jnz 1b
	addl _lineStep,%edi
	decb %dl
	jnz 0b
	ret

write2:
	movl $0xf0f0f0f0,%ebp
0:	movb $40,%dh
1:	extract6
	decb %dh
	jnz 1b
	addl _lineStep,%edi
	decb %dl
	jnz 0b
	ret


.text
	.align 4,0x90
.globl _PutImageN
_PutImageN:
	pushl %ebp
	pushl %esi
	pushl %ebx
	movl 16(%esp),%esi
	pushw %es
	movw _wConvMemSelector, %ax
	movw %ax, %es
	movl $0x00000000,%edi
	cmpb $6,_ScrMode
	je 0f
	cmpb $7,_ScrMode
	je 0f
	cmpb $9,_ScrMode
	je 0f
	movb $0,_width512
	jmp 1f
0:	movb $1,_width512
1:	cmpb $1,_InterLaceMode
	jne 0f
	call setupinter		# if interlaced
	xorb $1,_InterLacePage
	jz 2f
	addl $80,%edi
	jmp 2f
0:	call setup200		# use 200 lines
2:	cmpb $1,_width512
	je 4f
	call write2		# 256 -> 640
	jmp exitPutImage
4:	call write1		# 512 -> 640
	jmp exitPutImage

	.align 4,0x90
exitPutImage:
	movb _pageNo, %al
	outb %al, $0xa4
	xorb $0x01, %al
	movb %al, _pageNo
	outb %al, $0xa6

#	movl _rewritescr0,%eax
#	pushl %eax
#	movl _rewritescr1,%eax
#	pushl %eax
#	pushl $LC0
#	call _printf
#	addl $12,%esp
#	xorl %eax,%eax
#	movl %eax,_rewritescr0
#	movl %eax,_rewritescr1

	popw %es
	popl %ebx
	popl %esi
	popl %ebp
	ret


	.align 4,0x90
_setcsrform:
	movb $0x4b,%al
	outb %al,$0xa2
	movb _csrform,%al
	outb %al,$0xa0
	ret


LC0:
	.ascii "%04d/%04d \0"


.data
_width512:	.byte 0
_lineStep:	.long 0
_csrform:	.byte 0
_pageNo:	.byte 0

#_rewritescr0:	.long 0
#_rewritescr1:	.long 1

.end
