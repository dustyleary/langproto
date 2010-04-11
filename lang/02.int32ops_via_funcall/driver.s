

	.text
	.align	16
	.globl	_add
	.def	 _add;	.scl	2;	.type	32;	.endef
_add:                                                       # @add
LBB1_0:                                                     # %entry
	movl	8(%esp), %eax
	addl	4(%esp), %eax
	ret


	.align	16
	.globl	_sub
	.def	 _sub;	.scl	2;	.type	32;	.endef
_sub:                                                       # @sub
LBB2_0:                                                     # %entry
	movl	4(%esp), %eax
	subl	8(%esp), %eax
	ret


	.align	16
	.globl	_mul
	.def	 _mul;	.scl	2;	.type	32;	.endef
_mul:                                                       # @mul
LBB3_0:                                                     # %entry
	movl	8(%esp), %eax
	imull	4(%esp), %eax
	ret


	.align	16
	.globl	_div
	.def	 _div;	.scl	2;	.type	32;	.endef
_div:                                                       # @div
LBB4_0:                                                     # %entry
	movl	4(%esp), %eax
	cltd
	idivl	8(%esp)
	ret


	.align	16
	.globl	_mod
	.def	 _mod;	.scl	2;	.type	32;	.endef
_mod:                                                       # @mod
LBB5_0:                                                     # %entry
	movl	4(%esp), %eax
	cltd
	idivl	8(%esp)
	movl	%edx, %eax
	ret


	.align	16
	.globl	_bitor
	.def	 _bitor;	.scl	2;	.type	32;	.endef
_bitor:                                                     # @bitor
LBB6_0:                                                     # %entry
	movl	8(%esp), %eax
	orl	4(%esp), %eax
	ret


	.align	16
	.globl	_bitand
	.def	 _bitand;	.scl	2;	.type	32;	.endef
_bitand:                                                    # @bitand
LBB7_0:                                                     # %entry
	movl	8(%esp), %eax
	andl	4(%esp), %eax
	ret


	.align	16
	.globl	_bitxor
	.def	 _bitxor;	.scl	2;	.type	32;	.endef
_bitxor:                                                    # @bitxor
LBB8_0:                                                     # %entry
	movl	8(%esp), %eax
	xorl	4(%esp), %eax
	ret


	.align	16
	.globl	_shl
	.def	 _shl;	.scl	2;	.type	32;	.endef
_shl:                                                       # @shl
LBB9_0:                                                     # %entry
	movb	8(%esp), %cl
	movl	4(%esp), %eax
	shll	%cl, %eax
	ret


	.align	16
	.globl	_shr
	.def	 _shr;	.scl	2;	.type	32;	.endef
_shr:                                                       # @shr
LBB10_0:                                                    # %entry
	movb	8(%esp), %cl
	movl	4(%esp), %eax
	sarl	%cl, %eax
	ret


	.align	16
	.globl	_main
	.def	 _main;	.scl	2;	.type	32;	.endef
_main:                                                      # @main
LBB11_0:                                                    # %entry
	pushl	%ebp
	movl	%esp, %ebp
	subl	$8, %esp
	call	___main
	call	_scheme_entry
	movl	%eax, 4(%esp)
	movl	$L_.str, (%esp)
	call	_printf
	xorl	%eax, %eax
	addl	$8, %esp
	popl	%ebp
	ret
	.def	 _printf;	.scl	2;	.type	32;	.endef
	.def	 _scheme_entry;	.scl	2;	.type	32;	.endef
	.data
L_.str:                                                     # @.str
	.asciz	"%d"

