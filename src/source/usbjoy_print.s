;****************************************************************
; �@�\	d0.b�Ɋi�[����Ă���l��$����n�܂�16�i�`��($??)�ŕ\������B
;
; ����	d0.b	($00�`$ff)
;
; �Ԓl	�Ȃ�
;****************************************************************
		.even
hex_print_b:
		movem.l	d0-d7/a0-a6,-(sp)

		lea	hex_mojiretsu_b,a0	; 
		lea	hex_table_b(pc),a1	; �e�[�u���̐擪�Ԓn��a1�ɃZ�b�g
		move.b	#'$',(a0)+		; a0�Ԓn�̐擪��'$'���i�[���ăA�h���X���{�P���Ă���

		moveq.l	#2-1,d7			; ���[�v�񐔂��P�i�Q�񕪁j�ɃZ�b�g
@@:		rol.b	#4,d0			; �ŏ��̂S�r�b�g�����ʂS�r�b�g�ɂ���B
		move.l	d0,d1			; �}�X�N��������ƒl���ς���Ă��܂����߁Ad1�ɃR�s�[����
		andi.l	#$0000000f,d1		; ���ʂS�r�b�g�݂̂ɂ���i�O�`�P�T�j

		move.b	(a1,d1.w),(a0)+		; �����ϊ��e�[�u�����g�������ɕϊ�����
		dbra	d7,@b

		lea	hex_mojiretsu_b,a1
		IOCS	_B_PRINT

		movem.l	(sp)+,d0-d7/a0-a6
		rts

		.even
hex_table_b:
		dc.b	"0123456789ABCDEF"
hex_mojiretsu_b:
		ds.b	3
		dc.b	0
;****************************************************************
; �@�\	d0.b�Ɋi�[����Ă���l��16�i�`��($????)�ŕ\������B
;
; ����	d0.b	($0000�`$ffff)
;
; �Ԓl	�Ȃ�
;****************************************************************
		.even
hex_print_w:
		movem.l	d0-d7/a0-a6,-(sp)

		lea	hex_mojiretsu_w,a0	; 
		lea	hex_table_w(pc),a1	; �e�[�u���̐擪�Ԓn��a1�ɃZ�b�g

		moveq.l	#4-1,d7			; ���[�v�񐔂��P�i�S�񕪁j�ɃZ�b�g
@@:		rol.w	#4,d0			; �ŏ��̂S�r�b�g�����ʂS�r�b�g�ɂ���B
		move.l	d0,d1			; �}�X�N��������ƒl���ς���Ă��܂����߁Ad1�ɃR�s�[����
		andi.l	#$0000000f,d1		; ���ʂS�r�b�g�݂̂ɂ���i�O�`�P�T�j

		move.b	(a1,d1.w),(a0)+		; �����ϊ��e�[�u�����g�������ɕϊ�����
		dbra	d7,@b

		lea	hex_mojiretsu_w,a1
		IOCS	_B_PRINT

		movem.l	(sp)+,d0-d7/a0-a6
		rts

		.even
hex_table_w:
		dc.b	"0123456789ABCDEF"
hex_mojiretsu_w:
		ds.b	4
		dc.b	0

;****************************************************************
; �@�\	d0.b�Ɋi�[����Ă���l��$����n�܂�16�i�`��(??_)�ŕ\������B
;
; ����	d0.b	($00�`$ff)
;
; �Ԓl	�Ȃ�
;****************************************************************
		.even
hex_print_b_sp:
		movem.l	d0-d7/a0-a6,-(sp)

		lea	hex_mojiretsu_b_sp,a0	; 
		lea	hex_table_b_sp(pc),a1	; �e�[�u���̐擪�Ԓn��a1�ɃZ�b�g

		moveq.l	#2-1,d7			; ���[�v�񐔂��P�i�Q�񕪁j�ɃZ�b�g
@@:		rol.b	#4,d0			; �ŏ��̂S�r�b�g�����ʂS�r�b�g�ɂ���B
		move.l	d0,d1			; �}�X�N��������ƒl���ς���Ă��܂����߁Ad1�ɃR�s�[����
		andi.l	#$0000000f,d1		; ���ʂS�r�b�g�݂̂ɂ���i�O�`�P�T�j

		move.b	(a1,d1.w),(a0)+		; �����ϊ��e�[�u�����g�������ɕϊ�����
		dbra	d7,@b

		move.b	#' ',(a0)		; �Ō�ɋ󔒂�\������

		lea	hex_mojiretsu_b_sp,a1
		IOCS	_B_PRINT

		movem.l	(sp)+,d0-d7/a0-a6
		rts

		.even
hex_table_b_sp:
		dc.b	"0123456789ABCDEF"
hex_mojiretsu_b_sp:
		ds.b	3
		dc.b	0

;****************************************************************
; �@�\	d0.l�Ɋi�[����Ă���l��10�i�`���ŕ\������i���s�����j
;
; ����	d0.l	(-2147483648�`2147483647)
;
; �Ԓl	�Ȃ�
;****************************************************************
.if (REST_SIZE_PRINT=1)
		.even
num_print:
		movem.l	d0-d7/a0-a6,-(SP)

		lea	num_buffer(pc),a0	; 

		tst.l	d0
		beq	num_zero

		sf.b	num_flg			; �t���O���~�낷
		move.l	#31,d7			; 31bit�ڂ𒲂ׂ�ׂ�31���Z�b�g
		btst.l	d7,d0			; �������}�C�i�X�̒l���H
		beq	@f
		move.b	#'-',(a0)+
		neg.l	d0			; �Q�̕␔�ɂ���
@@:
		moveq	#10-1,d1
		lea	num_tbl,a1
num_loop0:
		clr.b	d2
		move.l	(a1)+,d3
num_loop1:
		or	d3,d3
		sub.l	d3,d0
		bcs	@f
		addq.b	#1,d2
		bra	num_loop1
	@@:
		add.l	d3,d0
		add.b	#'0',d2

		cmpi.b	#'0',d2			; ���̌���'0'���������H
		beq	@f
		st.b	num_flg			; �t���O�𗧂Ă�
		bra.b	1f
	@@:
		tst.b	num_flg			; �t���O�������Ă��邩�H
		beq	2f			; �����Ă��Ȃ�
	1:
		move.b	d2,(a0)+
	2:
		dbra	d1,num_loop0

		clr.b	(a0)

		lea	num_buffer(pc),a1
		IOCS	_B_PRINT

		movem.l	(SP)+,d0-d7/a0-a6
		rts
num_zero:
		move.b	#'0',(a0)+
		clr.b	(a0)

		lea	num_buffer(pc),a1
		IOCS	_B_PRINT

		movem.l	(SP)+,d0-d7/a0-a6
		rts

		.align	4
num_tbl:
		.dc.l	1000000000
		.dc.l	100000000
		.dc.l	10000000
		.dc.l	1000000
		.dc.l	100000
		.dc.l	10000
		.dc.l	1000
		.dc.l	100
		.dc.l	10
		.dc.l	1
num_flg:
		.dc.b	0
num_buffer:
		.dc.b	'0',0
		.ds.b	14
.endif
		.even
