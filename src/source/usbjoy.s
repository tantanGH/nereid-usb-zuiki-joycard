;==============================================================
;==============================================================
;
;
;�@�@�@�@USB JoyPad & Mouse Driver USBJOY ver.1.3e+z1
;
;�@�@�@�@�@�@�@�@Copyright (C)2006-2009 by �Ղ炷������/������
;                          (C)2013 by tantan
;
;==============================================================
;==============================================================

.68000

;--------------------------------------------------------------
; �����[�X���͑S�ĂO�ŃA�Z���u��
;--------------------------------------------------------------

SOF_PRINT		.equ	0
SETUP_PACKET_PRINT	.equ	0
STD_DESCRIPTOR_PRINT	.equ	0
CNF_DESCRIPTOR_PRINT	.equ	0
STATUS_PRINT		.equ	0
EOP_PRINT		.equ	0
INT_TIME_PRINT		.equ	0
LAST_STATUS_PRINT	.equ	0
REST_SIZE_PRINT		.equ	0
RETURN_CODE_PRINT	.equ	0
ISR_PRINT		.equ	0
STR_PRINT2_PRINT	.equ	0
PATH_FILENAME_PRINT	.equ	0

*--------------------------------------------------------------

	.include usbjoy.mac
	.include doscall.mac
	.include iocscall.mac

		.even
*--------------------------------------------------------------
		.text

tsr_top:	; ���̈ʒu���烁�����ɏ풓���܂�

		.dc.b	'$USBJOY$'	; �풓����p�̕�����

		.align	4
old_mouse_vct:
		.dc.l	0		; �풓�O�̎�M�L�����N�^�L��(�}�E�X�P�o�C�g����)
old_joy_vct:
		.dc.l	0		; �풓�O��IOCS _JOYGET�̃A�h���X
old_int:
		.dc.l	0		; �풓�O��$FB�̃A�h���X
int_count:
		.dc.l	0		; ���荞�݉񐔃J�E���^
host_usb_speed:
		.dc.b	0		; �ڑ�����USB�@��̑��x

;-----------------------------------------------------------
; USB�֘A���[�N
;-----------------------------------------------------------
		.align	4
usb_buf_address:
		.dc.l	0
usb_packet_address:
		.dc.l	0
usb_send_cmd:
		.dc.b	0
usb_endp:
		.dc.b	0
usb_addr:
		.dc.b	0
usb_length:
		.dc.b	0
usb_payload:
		.dc.b	0
usb_protocol:
		.dc.b	0

usb_wr_cmd:
		.dc.b	0
usb_rd_cmd:
		.dc.b	0

usb_packet_size:
		.dc.b	0	; ����M�p�P�b�g�T�C�Y

usb_packet_size_old:
		.dc.b	0	; ����M�p�P�b�g�T�C�Y

usb_rest_size:
		.dc.b	0	; �h�m�]���f�[�^�]���c��o�C�g���擾�p�ϐ�

usb_total_size:
		.dc.b	0	; 

usb_last_status:
		.dc.b	0	; 

usb_last_statusA:
		.dc.b	0	; 


.if (INT_TIME_PRINT=1)
int_start_count:
		.dc.b	0	; 
int_ontheway_countA:
		.dc.b	0	; 
int_ontheway_countB:
		.dc.b	0	; 
int_end_count:
		.dc.b	0	; 
.endif

		.even
retry_nak_max_count:
		.dc.w	0	; NAK�̍ő僊�g���C��

retry_nak_count:
		.dc.w	0	; NAK�̃��g���C��

usb_interrupt_count:
		.dc.b	0	; �C���^���v�g�]���̎����v���p�J�E���^

usb_interrupt_flg:
		.dc.b	0	; �C���^���v�g�]���J�n�t���O

usb_report_id:
		.dc.b	$ff	; ���|�[�g�h�c�̃o�C�g�ʒu($ff�Ȃ疢�g�p)

old_mouse_button_status:
		.dc.b	0	; �O��̃}�E�X�{�^���̏��

mouse_dpi_half_flg:
		.dc.b	0	; dpi�𔼕��ɂ���t���O

;-----------------------------------------------------------
; �I�v�V�����t���O
;-----------------------------------------------------------
optflg_C:
		.dc.b	0
optflg_X:
		.dc.b	0
; -------- patch +z1 --------
optflg_Z:
		.dc.b	0
; ---------------------------

;-----------------------------------------------------------
; �Z�b�g�A�b�v�p�P�b�g�֘A�̃f�[�^(USBJOY�ŕK�v�Ȃ̂͂T��)
;-----------------------------------------------------------
		.even
cget_desc_dev:
		.dc.b	$80,$06,$00,$01,$00,$00
	desc_dev_count:
		.dc.b	$08,$00			; GET_DESCRIPTOR

cset_address:
		.dc.b	$00,$05
	address_data:
		.dc.b	$00,$00,$00,$00,$00,$00	; SET_ADDRESS

cget_config:
		.dc.b	$80,$06,$00,$02,$00,$00
	config_size:
		.dc.b	$FF,$00			; GET_CONFIG

cset_config:
		.dc.b	$00,$09
	config_data:
		.dc.b	$01,$00,$00,$00,$00,$00	; SET_CONFIG

cset_protocol:
		.dc.b	$21,$0b
	set_protocol_value:
		.dc.b	$01,$00,$00,$00,$00,$00	; SET_PROTOCOL

		.even

.if (SETUP_PACKET_PRINT=1)
print_packet_work:
		.ds.b	32	; �Z�b�g�A�b�v�p�P�b�g�\���p�̃��[�N
.endif

;-----------------------------------------------------------
; ���b�Z�[�W�֘A�̃f�[�^
;-----------------------------------------------------------
		.even
msg_sl811hst_rev:
		.dc.b	'SL811HST USB Chip Revision.1.'
chip_revision:
		.dc.b	'2',cr,lf,0

;-----------------------------------------------------------
; �擾�����f�B�X�N���v�^���i�[���郏�[�N
;-----------------------------------------------------------

		.align	4
Buf_StdDescriptor:
		.ds.b	7		; 18Byte
MaxPacketSize:	.ds.b	1		; 
VendorID:	.ds.w	1		; 
ProductID:	.ds.w	1		; 
		.ds.b	6		; 

Buf_CnfDescriptor:
		.ds.b	1		; 9Byte
		.ds.b	1		; 
TotalLengthL:	.ds.b	1		; 
TotalLengthH:	.ds.b	1		; 
		.ds.b	5		; 

;�ȉ��̓W���C�p�b�h�E�}�E�X�̏ꍇ�̂�

		.ds.b	5		; 9Byte
Class:		.ds.b	1		; <- ���̈ʒu�͕K��long���E
SubClass:	.ds.b	1		; 
Protocol:	.ds.b	1		; 
		.ds.b	1		; 

		.ds.b	6		; 9Byte
DescType	.ds.b	1		; 
DescLengthL	.ds.b	1		; 
DescLengthH	.ds.b	1		; 

; -------- patch +z1 --------
;		.ds.b	4		; 7Byte
;MaxPacketSizeL:	.ds.b	1		; 
;MaxPacketSizeH:	.ds.b	1		; 
;bInterval	.ds.b	1		; 

EndPoint1:
		.ds.b	3		; 7Byte
EndPointAddr:   .ds.b	1		; IN/OUT����p
MaxPacketSizeL:	.ds.b	1		; 
MaxPacketSizeH:	.ds.b	1		; 
bInterval	.ds.b	1		; 

EndPoint2:
		.ds.b	7		; 7Byte ZUIKI�p�b�h��EndPoint��2����
; ---------------------------

		.align	4
Buf_Work:
		.ds.b	16		; 16Byte

;-----------------------------------------------------------------------------
; �W���C�X�e�B�b�N�P�̑���ɂt�r�a�ɐڑ����ꂽ�W���C�p�b�h����̃f�[�^��Ԃ�
;-----------------------------------------------------------------------------

		.even
usb_joy_vct:
		cmpi.w	#1,d1				; d1.w = �W���C�X�e�B�b�N�ԍ�
		bhi	joy_err_exit			; �O�ł��P�ł��Ȃ��ꍇ
		beq	joy1				; �P�̏ꍇ
	joy0:
		move.l	a0,-(sp)

		move.w	d1,d0				; 
		lsl.w	#3,d0				; 

		lea.l	joy_data0(pc),a0		; 
		lea.l	(a0,d0.w),a0			; 

		clr.l	d0				; �߂�l��������
		move.b	(a0),d0				; 

		tst.b	auto_flg			; �V���N���A�˃I�v�V�������w�肳��Ă��邩�H
		bne	@f				; 

		btst.l	#4,d0				; �A�˃{�^����������Ă��邩�H
		bne	1f				; ������Ă��Ȃ��ꍇ
		bclr.l	#5,d0
	1:
		btst.l	#7,d0				; �A�˃{�^����������Ă��邩�H
		bne	1f				; ������Ă��Ȃ��ꍇ
		bclr.l	#6,d0
	1:
		or.b	#%10010000,d0
		move.l	(sp)+,a0
		rts
	@@:
		btst.l	#4,d0				; �A�˃{�^����������Ă��邩�H
		beq	1f				; ������Ă���ꍇ
		move.w	#$0020,auto_int_cnt_a(a0)	; ������Ă��Ȃ���΃V���N���J�E���^���N���A���Ă���
		bra.b	4f				; 
	1:
		cmpi.b	#$01,auto_flg			; -a1�I�v�V�������w�肳��Ă��邩�H
		beq	2f
		add.b	#1,auto_int_cnt_a(a0)		; �V���N���J�E���^�{�P

	; ���̂��Ƃ̃o�[�W�����Ŏ��ȏ����̑Ώ�
		btst.b	#$00,auto_int_cnt_a(a0)		; $0828,$0002,$0001
		beq	3f
	2:
		bchg.b	#5,auto_data_a(a0)
	3:
		andi.b	#%1101_1111,d0
		or.b	auto_data_a(a0),d0
	4:
		btst.l	#7,d0				; �A�˃{�^����������Ă��邩�H
		beq	1f				; ������Ă���ꍇ
		move.w	#$0040,auto_int_cnt_b(a0)	; ������Ă��Ȃ���΃V���N���J�E���^���N���A���Ă���
		bra.b	4f				; 
	1:
		cmpi.b	#$01,auto_flg			; -a1�I�v�V�������w�肳��Ă��邩�H
		beq	2f
		add.b	#1,auto_int_cnt_b(a0)		; �V���N���J�E���^�{�P

	; ���̂��Ƃ̃o�[�W�����Ŏ��ȏ����̑Ώ�
		btst.b	#$00,auto_int_cnt_b(a0)		; $0828,$0002,$0001
		beq	3f
	2:
		bchg.b	#6,auto_data_b(a0)
	3:
		andi.b	#%1011_1111,d0
		or.b	auto_data_b(a0),d0
	4:
		or.b	#%10010000,d0
		move.l	(sp)+,a0
		rts
	joy1:
		tst.b	usb_report_id
		bpl	joy0

		clr.l	d0				; �߂�l��������
		move.b	$00e9a003,d0			; �W���C�X�e�B�b�N�|�[�g�Q�̃f�[�^���擾
		rts
joy_err_exit:
		clr.l	d0				; �߂�l��������
		rts

		.even
joy_data0:
		.dc.b	$ff	; �C���^���v�g�]���Ŏ擾���ꂽ�W���C�p�b�h�̃f�[�^���ҏW��i�[����Ă��郏�[�N
		.dc.b	$00,$00,$00,$00,$00,$00,$00
joy_data1:
		.dc.b	$ff	; �C���^���v�g�]���Ŏ擾���ꂽ�W���C�p�b�h�̃f�[�^���ҏW��i�[����Ă��郏�[�N
		.dc.b	$00,$00,$00,$00,$00,$00,$00
auto_flg:
		.dc.b	$00

		.even

; ���C���^���v�g�h�m�]��
_GetInterrupt:
		move.b	usb_length,usb_total_size

		move.b	usb_payload,d0
		cmp.b	usb_total_size,d0		; total_size < payload
		bcc	1f
		move.b	usb_payload,usb_packet_size	; �擾�o�C�g�� = payload
		bra.b	2f
	1:
		move.b	usb_total_size,usb_packet_size	; �擾�o�C�g�� = payload
	2:
		jbsr	_USB_int

		rts

; ���R���t�B�M�����[�V�����ݒ�
_SetConfiguration:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		lea.l	cset_config(pc),a0		; 
		move.l	a0,usb_packet_address		; ���M�p�P�b�g�A�h���X

		move.b	#8,usb_packet_size		; �f�[�^�̓]����(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK �܂��� ERR�Ȃ�ΏI��

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

		;move.b	usb_length,usb_total_size
		move.b	#0,usb_total_size

		jbsr	_USB_in

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
		jbsr	print_rest_size
	9:
		rts

; ���f�o�C�X�A�h���X�ݒ�
_SetDeviceAddress:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		lea.l	cset_address(pc),a0		; 
		move.l	a0,usb_packet_address		; ���M�p�P�b�g�A�h���X

		move.b	#8,usb_packet_size		; �f�[�^�̓]����(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK �܂��� ERR�Ȃ�ΏI��

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

	;	move.b	usb_length,usb_total_size
		move.b	#0,usb_total_size

		jbsr	_USB_in

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
		jbsr	print_rest_size
	9:
		rts

; ���R���t�B�M�����[�V�����擾
_GetConfiguration:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		move.b	usb_length,config_size		; �擾�������f�[�^�̃o�C�g�����Z�b�g

		lea.l	cget_config(pc),a0
		move.l	a0,usb_packet_address		; ���M�p�P�b�g�A�h���X

		move.b	#8,usb_packet_size		; �f�[�^�̓]����(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK �܂��� ERR�Ȃ�ΏI��

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

		move.b	usb_length,usb_total_size

		jbsr	_USB_in
		bne	9f				; NAK �܂��� ERR�Ȃ�ΏI��

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
		jbsr	print_rest_size
	.if (CNF_DESCRIPTOR_PRINT=1)
		jbsr	print_CnfDescriptor
	.endif
	;---------------------------------------------------------------------
		move.b	#0,usb_packet_size		; �f�[�^�̓]����(1byte)
		;move.b	#0,usb_total_size

		jbsr	_USB_out
		bne	9f				; NAK �܂��� ERR�Ȃ�ΏI��

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
	9:
		rts

; ���f�o�C�X�f�B�X�N���v�^�擾
_GetDeviceDescriptor:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		move.b	usb_length,desc_dev_count	; �擾�������f�[�^�̃o�C�g�����Z�b�g

		lea.l	cget_desc_dev(pc),a0		; 
		move.l	a0,usb_packet_address		; ���M�p�P�b�g�A�h���X

		move.b	#8,usb_packet_size		; �f�[�^�̓]����(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK �܂��� ERR�Ȃ�ΏI��

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

		move.b	usb_length,usb_total_size

		jbsr	_USB_in
		bne	9f				; NAK �܂��� ERR�Ȃ�ΏI��

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
		jbsr	print_rest_size
	.if (STD_DESCRIPTOR_PRINT=1)
		jbsr	print_StdDescriptor		; �f�B�X�N���v�^�̕\��
	.endif
	;---------------------------------------------------------------------
		move.b	#0,usb_packet_size		; �f�[�^�̓]����(1byte)
		;move.b	#0,usb_total_size

		jbsr	_USB_out
		bne	9f				; NAK �܂��� ERR�Ȃ�ΏI��

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
	9:
		rts

; ���v���g�R���ݒ�
;---------------------------------------------------------------------
;	SETUP	DATA0
;	IN	DATA1
_SetProtocol:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		move.b	usb_protocol,set_protocol_value	; 

		lea.l	cset_protocol(pc),a0		; 
		move.l	a0,usb_packet_address		; ���M�p�P�b�g�A�h���X

		move.b	#8,usb_packet_size		; �f�[�^�̓]����(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK �܂��� ERR�Ȃ�ΏI��

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

		move.b	#0,usb_packet_size		; �f�[�^�̓]����(1byte)

		jbsr	_USB_in

		jbsr	print_return_code
		jbsr	print_last_status		; �ŏI�X�e�[�^�X���W�X�^�̕\��
	9:
		rts

_USB_setup:

	; ���r�d�s�t�o�R�}���h

.if (SOF_PRINT=1)
	_StrPrint	' SOF = '
		move.l	int_count,d0
		jbsr	hex_print_w
	_StrPrint	' : CMD = SETUP : ADR = '
		move.b	usb_addr,d0
		jbsr	hex_print_b_sp
.endif
		move.w	retry_nak_max_count,d7		; NAK�̍ő僊�g���C�񐔂��Z�b�g
	@@:
		move.b	#CMD_SETUP,usb_send_cmd		; �R�}���h = SETUP�R�}���h
		jbsr	wait_command			; �R�}���h�I���҂�

		btst.b	#STS_ACK,usb_last_statusA	; ACK���Ԃ��Ă������H
		bne	SETUP_ACK			; �Ԃ��Ă����ꍇ

		btst.b	#STS_NAK,usb_last_statusA	; NAK���Ԃ��Ă������H
		beq	SETUP_ERR			; ACK��NAK���Ԃ��Ă��Ȃ������ꍇ

		dbra	d7,@b

	;_StrPrint	' SETUP:�ő僊�g���C�񐔂��z���܂���',13,10

	SETUP_NAK:
		move.b	#1,d0
		rts
	SETUP_ERR:
		move.b	#$FF,d0
		rts
	SETUP_ACK:
		bchg.b	#6,usb_wr_cmd
		clr.b	d0
		rts

_USB_in:

	; ���h�m�R�}���h

.if (SOF_PRINT=1)
	_StrPrint	' SOF = '
		move.l	int_count,d0
		jbsr	hex_print_w
	_StrPrint	' : CMD = IN    : ADR = '
		move.b	usb_addr,d0
		jbsr	hex_print_b_sp
.endif
		move.b	#CMD_IN,usb_send_cmd		; �R�}���h = IN�R�}���h
		jbsr	wait_command			; �R�}���h�I���҂�

		btst.b	#STS_ACK,usb_last_statusA	; ACK���Ԃ��Ă������H
		bne	IN_ACK				; �Ԃ��Ă����ꍇ

		btst.b	#STS_NAK,usb_last_statusA	; NAK���Ԃ��Ă������H
		beq	IN_ERR				; ACK��NAK���Ԃ��Ă��Ȃ������ꍇ
	IN_NAK:
		move.b	#1,d0
		rts
	IN_ERR:
		move.b	#$FF,d0
		rts
	IN_ACK:
	;	bchg.b	#6,usb_rd_cmd
		clr.b	d0
		rts

_USB_int:

	; ���h�m�s�R�}���h

		move.b	#CMD_INT,usb_send_cmd		; �R�}���h = INTERRUPT�R�}���h
		jbsr	_Intr_1ms_sub

		btst.b	#STS_ACK,usb_last_statusA	; ACK���Ԃ��Ă������H
		bne	IN2_ACK				; �Ԃ��Ă����ꍇ

		btst.b	#STS_NAK,usb_last_statusA	; NAK���Ԃ��Ă������H
		beq	IN2_ERR				; ACK��NAK���Ԃ��Ă��Ȃ������ꍇ
	IN2_NAK:
		move.b	#1,d0
		rts
	IN2_ERR:
		move.b	#$FF,d0
		rts
	IN2_ACK:
		bchg.b	#6,usb_rd_cmd
		clr.b	d0
		rts

_USB_out:

	; ���n�t�s�R�}���h

.if (SOF_PRINT=1)
	_StrPrint	' SOF = '
		move.l	int_count,d0
		jbsr	hex_print_w
	_StrPrint	' : CMD = OUT   : ADR = '
		move.b	usb_addr,d0
		jbsr	hex_print_b_sp
.endif
		move.w	retry_nak_max_count,d7		; NAK�̍ő僊�g���C�񐔂��Z�b�g
	@@:
		move.b	#CMD_OUT,usb_send_cmd		; �R�}���h = SETUP�R�}���h
		jbsr	wait_command			; �R�}���h�I���҂�

		btst.b	#STS_ACK,usb_last_statusA	; ACK���Ԃ��Ă������H
		bne	OUT_ACK				; �Ԃ��Ă����ꍇ

		btst.b	#STS_NAK,usb_last_statusA	; NAK���Ԃ��Ă������H
		beq	OUT_ERR				; ACK��NAK���Ԃ��Ă��Ȃ������ꍇ

		dbra	d7,@b

	;_StrPrint	' OUT:�ő僊�g���C�񐔂��z���܂���',13,10

	OUT_NAK:
		move.b	#1,d0
		rts
	OUT_ERR:
		move.b	#$FF,d0
		rts
	OUT_ACK:
;		bchg.b	#6,usb_wr_cmd
		clr.b	d0
		rts

;--------------------------------------
; SL811HST�P�������荞�݃��[�`��
;--------------------------------------
		.even
_Intr_1ms:

;		ori.w	#$0700,sr			; ���荞�݃}�X�N�ɕύX(ver.1.0)

		movem.l	d0-d7/a0-a6,-(sp)

;		; ���荞�݃}�X�N�̐ݒ�			; ���荞�݃}�X�N���폜(1.1a)
;		lea.l	$E88012,a4			; 
;		move.l	(a4),d4				; ���荞�ݒ���d4�̒l���ς�邱�Ƃ͂��肦�܂���
;		move.b	#%11000000,1(a4)		; X68000���̊��荞�݃}�X�N�̐ݒ�
;		move.b	#%01000000,3(a4)		; X68000���̊��荞�݃}�X�N�̐ݒ�

		lea.l	SL811HST_ADDR,a5		; ���荞�ݒ��̓N���b�N�팸�̂��߂Ƀ��W�X�^a5��a6��SL811�̃��W�X�^���A�N�Z�X���܂�
		lea.l	SL811HST_DATA,a6		; ���荞�ݒ���a5��a6�̒l���ς�邱�Ƃ͂��肦�܂���

		move.b	#$06,SL811_ADDR_REG
		move.b	#$00,SL811_DATA_REG

		bsr	_Intr_1ms_sub

		addq.l	#1,int_count			; ���荞�݂̉񐔃J�E���^(�����\�����邾���Ŋ�{�I�ɕs�v�Ȃ���)

	;�C���^���v�g�]���J�n�t���O��������Ă��邩�H
		tst.b	usb_interrupt_flg		; 
		beq	@f				; 
		subi.b	#1,usb_interrupt_count		; 
		bne	@f				; 
		move.b	bInterval,usb_interrupt_count	; �C���^���v�g�]�����荞�ݎ������Z�b�g

	;	���ǂ����ς��Ȃ��̂ŃN���b�N�팸
	;	move.b	#$01,usb_addr			; �A�h���X = 1
	;	move.b	#$01,usb_endp			; �G���h�|�C���g = 1
	;	move.b	MaxPacketSizeL,usb_length	; �f�[�^�]���� = ?

		lea.l	Buf_Work(pc),a0			; 
		move.l	a0,usb_buf_address		; �f�[�^��ǂݍ��ރA�h���X

		move.w	#0,retry_nak_max_count		; NAK�̍ő僊�g���C�񐔂��Z�b�g

		jbsr	_GetInterrupt			; �C���^���v�g�]�����[�`��
		tst.b	d0				; 
		.dc.w	$6100
branch_address:
		.dc.w	mouse_data_conv-branch_address	; ���ȏ���
	@@:
		move.b	#REG_INT_STATUS,SL811HST_ADDR	; ���荞�݃X�e�[�^�X���W�X�^
		move.b	#$FF,SL811HST_DATA		; �S���荞�݃t���O���Z�b�g

		move.b	#$06,SL811_ADDR_REG
		move.b	#$10,SL811_DATA_REG

;		move.l	d4,(a4)				; X68000�̊��荞�݃}�X�N�����ɖ߂�

		movem.l	(sp)+,d0-d7/a0-a6

		rte

;--------------------------------------
; SL811HST�P�������荞�݃��[�`���T�u
;--------------------------------------
		.even
_Intr_1ms_sub:
		cmpi.b	#CMD_IN,usb_send_cmd		; �R�}���h = IN�R�}���h
		bne	9f
	1:
		move.w	retry_nak_max_count,retry_nak_count	; NAK�̃��g���C�񐔂��Z�b�g
	2:
		move.b	usb_payload,d0
		cmp.b	usb_total_size,d0		; total_size < payload
		bcc	3f
		move.b	usb_payload,usb_packet_size	; �擾�o�C�g�� = payload
		bra.b	4f
	3:
		move.b	usb_total_size,usb_packet_size	; �擾�o�C�g�� = payload
	4:
		jbsr	_Intr_1ms_sub_main

		btst.b	#STS_ACK,usb_last_statusA	; ACK���Ԃ��Ă������H
		bne	RET_ACK				; �Ԃ��Ă����ꍇ

		btst.b	#STS_NAK,usb_last_statusA	; NAK���Ԃ��Ă������H
		bne	RET_NAK				; �Ԃ��Ă����ꍇ
		bra.b	RET_ERR
	RET_ACK:
		bchg.b	#6,usb_rd_cmd			; DATA0/DATA1�g�O��
		tst.b	usb_total_size
		bne	1b
		clr.b	usb_send_cmd			; �R�}���h�N���A
		rts
	RET_NAK:
		subi.w	#1,retry_nak_count
		bne	2b
	RET_ERR:
		clr.b	usb_send_cmd			; �R�}���h�N���A
		rts

	9:
		jbsr	_Intr_1ms_sub_main
		clr.b	usb_send_cmd			; �R�}���h�N���A
		rts

;-------------------------------------------------
; SL811HST�P�������荞�݃��[�`���T�u���[�`�����C��
;-------------------------------------------------
		.even
_Intr_1ms_sub_main:

		tst.b	usb_send_cmd			; �R�}���h�p�P�b�g�����s����Ă��邩�H
		beq	_Intr_1ms_exit_nopacket		; ����Ă��Ȃ���ΏI��

		GET_INT_TIME_START

		cmpi.b	#CMD_SETUP,usb_send_cmd
		bne	CHK_CMD_IN

		; ��SETUP�p�P�b�g��SL811HST�̃������ɓ]��
			move.b	#EP0BUF,SL811_ADDR_REG

			move.l	usb_packet_address,a0
			movea.l	#SL811HST_DATA,a1

			move.w	#8-1,d7
		@@:	move.b	(a0)+,(a1)
			dbra	d7,@b

		; ���Z�b�g�A�b�v�p�P�b�g�̓��e��\���������������A�Z���u��
.if (SETUP_PACKET_PRINT=1)
			lea.l	print_packet_work(pc),a0	; 
			move.b	#EP0BUF,SL811_ADDR_REG		; SL811HST�������A�h���X
			move.w	#8-1,d7				; 
		@@:
			move.b	SL811_DATA_REG,(a0)+		; 
			dbra	d7,@b				; 
.endif
		;---------------------------------------------------------

		; ���f�[�^�]���p�̃f�[�^���i�[����Ă���|�C���^���Z�b�g

			move.b	#REG_BASE_ADR_A,SL811_ADDR_REG	; USB-A�z�X�g�x�[�X�A�h���X���W�X�^($01)
			move.b	#EP0BUF,SL811_DATA_REG		; SL811HST���������[�X�^�[�g�ʒu

		; ���f�[�^�̓]�������Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_XLEN_A,SL811_ADDR_REG	; USB-A�z�X�g�x�[�X�f�[�^�����W�X�^($02)
			move.b	usb_packet_size,SL811_DATA_REG	; �f�[�^�̓]����(1byte)

		; ���p�P�b�gID �� �G���h�|�C���g���Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_PID_ENDP_A,SL811_ADDR_REG	; USB-A�̃p�P�b�gID(���4bit)�ƃG���h�|�C���g���W�X�^(����4bit)($03)
			move.b	usb_endp,d0			; �G���h�|�C���g = $0?
			ori.b	#PID_SETUP,d0			; �p�P�b�gID = PID_SETUP($D0)
			move.b	d0,SL811_DATA_REG		; 

		; ��USB�A�h���X���Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_ADDR_A,SL811_ADDR_REG	; USB-A�z�X�g�A�h���X���W�X�^($04)
			move.b	usb_addr,SL811_DATA_REG		; USB�A�h���X = $??(0�`127)

		; ���S���荞�݃X�e�[�^�X�N���A
			move.b	#$0d,SL811_ADDR_REG		; ���荞�݃X�e�[�^�X���W�X�^
			move.b	#$ff,SL811_DATA_REG		; �S���荞�݃X�e�[�^�X�N���A

		; ��EOP(Alive)�𑗐M(�n�u�Ƀ��[�X�s�[�h�f�o�C�X��ڑ����Ă��鎞�̂�)
		;	bsr	eop

		; ��OUT�����A�G���h�|�C���g�ւ̓]�����A�]������(0000_0111b)
			move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-A�z�X�g�R���g���[�����W�X�^
			move.b	usb_wr_cmd,SL811_DATA_REG	; �]������

		GET_INT_TIME_OTWA

			jbsr	_Intr_1ms_check_stastus1

		GET_INT_TIME_OTWB

			jbsr	_Intr_1ms_check_stastus2

		GET_INT_TIME_END

			rts
	CHK_CMD_IN:

		cmpi.b	#CMD_IN,usb_send_cmd
		bne	CHK_CMD_INT

		;---------------------------------------------------------

		; ���f�[�^�]���p�̃f�[�^���i�[����Ă���|�C���^���Z�b�g
			move.b	#REG_BASE_ADR_A,SL811_ADDR_REG	; USB-A�z�X�g�x�[�X�A�h���X���W�X�^($01)
			move.b	#EP0BUF,SL811_DATA_REG		; SL811HST���������[�X�^�[�g�ʒu

		; ���f�[�^�̓]�������Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_XLEN_A,SL811_ADDR_REG	; USB-A�z�X�g�x�[�X�f�[�^�����W�X�^($02)
			move.b	usb_packet_size,SL811_DATA_REG	; �f�[�^�̓]����(1byte)

		; ���p�P�b�gID �� �G���h�|�C���g���Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_PID_ENDP_A,SL811_ADDR_REG	; USB-A�̃p�P�b�gID(���4bit)�ƃG���h�|�C���g���W�X�^(����4bit)
			move.b	usb_endp,d0			; �G���h�|�C���g = $0?
			ori.b	#PID_IN,d0			; �p�P�b�gID = PID_IN($90)
			move.b	d0,SL811_DATA_REG		; 

		; ��USB�A�h���X���Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_ADDR_A,SL811_ADDR_REG	; USB-A�z�X�g�A�h���X���W�X�^
			move.b	usb_addr,SL811_DATA_REG		; USB�A�h���X = $??(0�`127)

		; ��EOP(Alive)�𑗐M(�n�u�Ƀ��[�X�s�[�h�f�o�C�X��ڑ����Ă��鎞�̂�)
		;	bsr	eop

		; ���S���荞�݃X�e�[�^�X�N���A
			move.b	#$0d,SL811_ADDR_REG		; ���荞�݃X�e�[�^�X���W�X�^
			move.b	#$ff,SL811_DATA_REG		; �S���荞�݃X�e�[�^�X�N���A

		; ��IN�����A�G���h�|�C���g�ւ̓]�����A�]������(0010_0011b)
	;		move.b	usb_rd_cmd,d0
	;		tst.b	host_usb_speed			; ���[�X�s�[�h(host_usb_speed = SPEED_LOW(0))���H
	;		beq	in_low
	;	;	or.b	#$20,d0				; full�̏ꍇ��SOF�ɓ������ăf�[�^��]��
	;	in_low:
	;		move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-A�z�X�g�R���g���[�����W�X�^
	;		move.b	d0,SL811_DATA_REG		; �]������

			move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-A�z�X�g�R���g���[�����W�X�^
			move.b	usb_rd_cmd,SL811_DATA_REG	; �]������

		;---------------------------------------------------------
		; ����M���I�����������`�F�b�N

		GET_INT_TIME_OTWA

			jbsr	_Intr_1ms_check_stastus1

		GET_INT_TIME_OTWB

		;---------------------------------------------------------
		; ������Ɏ�M�ł��������`�F�b�N

			jbsr	_Intr_1ms_check_stastus2

			move.b	#REG_CNT_A,SL811_ADDR_REG	; USB-A�f�[�^�]���c��o�C�g��
			move.b	SL811_DATA_REG,usb_rest_size	; �f�[�^�]���c��o�C�g���擾

			btst.b	#0,usb_last_statusA		; �G���[�ł͂Ȃ����Ƃ��m�F
			beq	1f
			tst.b	usb_rest_size			; �G���[���Ȃ��c��]���o�C�g�����O�Ȃ�΃o�b�t�@�Ƀf�[�^�]��
			bne	1f

			move.b	usb_packet_size,d0		; ���Ƃ��Ǝ�M�T�C�Y���O�Ȃ�Γ]���Ȃ�
			beq	1f
			sub.b	d0,usb_total_size

			movea.l	usb_buf_address,a0		; �f�o�C�X�f�B�X�N���v�^��ǂݍ��ރA�h���X
			move.b	#EP0BUF,SL811_ADDR_REG		; SL811HST�������A�h���X
			clr.w	d7
			move.b	usb_packet_size,d7
			subq.w	#1,d7
		in_get_:
			move.b	SL811_DATA_REG,(a0)+
			dbra	d7,in_get_
			move.l	a0,usb_buf_address		; �f�o�C�X�f�B�X�N���v�^��ǂݍ��ރA�h���X
	1:
		GET_INT_TIME_END

			rts

	CHK_CMD_INT:

		cmpi.b	#CMD_INT,usb_send_cmd
		bne	CHK_CMD_OUT

		;---------------------------------------------------------

		; ���f�[�^�]���p�̃f�[�^���i�[����Ă���|�C���^���Z�b�g
			move.b	#REG_BASE_ADR_A,SL811_ADDR_REG	; USB-A�z�X�g�x�[�X�A�h���X���W�X�^($01)
			move.b	#EP0BUF,SL811_DATA_REG		; SL811HST���������[�X�^�[�g�ʒu

		; ���f�[�^�̓]�������Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_XLEN_A,SL811_ADDR_REG	; USB-A�z�X�g�x�[�X�f�[�^�����W�X�^($02)
			move.b	usb_packet_size,SL811_DATA_REG	; �f�[�^�̓]����(1byte)

		; ���p�P�b�gID �� �G���h�|�C���g���Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_PID_ENDP_A,SL811_ADDR_REG	; USB-A�̃p�P�b�gID(���4bit)�ƃG���h�|�C���g���W�X�^(����4bit)($03)
			move.b	usb_endp,d0			; �G���h�|�C���g = $0?
			ori.b	#PID_IN,d0			; �p�P�b�gID = PID_IN($90)
			move.b	d0,SL811_DATA_REG		; 

		; ��USB�A�h���X���Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_ADDR_A,SL811_ADDR_REG	; USB-A�z�X�g�A�h���X���W�X�^($04)
			move.b	usb_addr,SL811_DATA_REG		; USB�A�h���X = $??(0�`127)

		; ��EOP(Alive)�𑗐M(�n�u�Ƀ��[�X�s�[�h�f�o�C�X��ڑ����Ă��鎞�̂�)
		;	bsr	eop

		; ���S���荞�݃X�e�[�^�X�N���A
			move.b	#$0d,SL811_ADDR_REG		; ���荞�݃X�e�[�^�X���W�X�^
			move.b	#$ff,SL811_DATA_REG		; �S���荞�݃X�e�[�^�X�N���A

		; ��IN�����A�G���h�|�C���g�ւ̓]�����A�]������(0010_0011b)
	;		move.b	usb_rd_cmd,d0
	;		tst.b	host_usb_speed			; ���[�X�s�[�h(host_usb_speed = SPEED_LOW(0))���H
	;		beq	in_low2
	;;		or.b	#$20,d0				; full�̏ꍇ��SOF�ɓ������ăf�[�^��]��
	;	in_low2:
	;		move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-A�z�X�g�R���g���[�����W�X�^
	;		move.b	d0,SL811_DATA_REG		; �]������

			move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-A�z�X�g�R���g���[�����W�X�^
			move.b	usb_rd_cmd,SL811_DATA_REG	; �]������

		;---------------------------------------------------------
		; ����M���I�����������`�F�b�N

		GET_INT_TIME_OTWA

			jbsr	_Intr_1ms_check_stastus1

		GET_INT_TIME_OTWB

		;---------------------------------------------------------
		; ������Ɏ�M�ł��������`�F�b�N

			jbsr	_Intr_1ms_check_stastus2

			move.b	#REG_CNT_A,SL811_ADDR_REG	; USB-A�f�[�^�]���c��o�C�g��
			move.b	SL811_DATA_REG,usb_rest_size	; �f�[�^�]���c��o�C�g���擾

			btst.b	#0,usb_last_statusA		; �G���[�ł͂Ȃ����Ƃ��m�F
			beq	1f
		;	tst.b	usb_rest_size			; �G���[���Ȃ��c��]���o�C�g�����O�Ȃ�΃o�b�t�@�Ƀf�[�^�]��
		;	bne	1f

			move.b	usb_packet_size,d0		; ���Ƃ��Ǝ�M�T�C�Y���O�Ȃ�Γ]���Ȃ�
			beq	1f
			sub.b	d0,usb_total_size

			movea.l	usb_buf_address,a0		; �f�o�C�X�f�B�X�N���v�^��ǂݍ��ރA�h���X
			move.b	#EP0BUF,SL811_ADDR_REG		; SL811HST�������A�h���X
			clr.w	d7
			move.b	usb_packet_size,d7
			subq.w	#1,d7
		in_get2:
			move.b	SL811_DATA_REG,(a0)+
			dbra	d7,in_get2
			move.l	a0,usb_buf_address		; �f�o�C�X�f�B�X�N���v�^��ǂݍ��ރA�h���X
	1:
		GET_INT_TIME_END

			rts

	CHK_CMD_OUT:

		cmpi.b	#CMD_OUT,usb_send_cmd
		bne	CHK_CMD_OTHER

		;---------------------------------------------------------

		; ���f�[�^�]���p�̃f�[�^���i�[����Ă���|�C���^���Z�b�g
			move.b	#REG_BASE_ADR_A,SL811_ADDR_REG	; USB-A�z�X�g�x�[�X�A�h���X���W�X�^($01)
			move.b	#EP0BUF,SL811_DATA_REG		; SL811HST���������[�X�^�[�g�ʒu

		; ���f�[�^�̓]�������Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_XLEN_A,SL811_ADDR_REG	; USB-A�z�X�g�x�[�X�f�[�^�����W�X�^($02)
			move.b	usb_packet_size,SL811_DATA_REG	; �f�[�^�̓]����(1byte)

		; ���p�P�b�gID �� �G���h�|�C���g���Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_PID_ENDP_A,SL811_ADDR_REG	; USB-A�̃p�P�b�gID(���4bit)�ƃG���h�|�C���g���W�X�^(����4bit)($03)
			move.b	usb_endp,d0			; �G���h�|�C���g = $0?
			ori.b	#PID_OUT,d0			; �p�P�b�gID = PID_OUT($10)
			move.b	d0,SL811_DATA_REG		; 

		; ��USB�A�h���X���Z�b�g
		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#REG_ADDR_A,SL811_ADDR_REG	; USB-A�z�X�g�A�h���X���W�X�^($04)
			move.b	usb_addr,SL811_DATA_REG		; USB�A�h���X = $??(0�`127)

		; ���S���荞�݃X�e�[�^�X�N���A
			move.b	#$0d,SL811_ADDR_REG		; ���荞�݃X�e�[�^�X���W�X�^
			move.b	#$ff,SL811_DATA_REG		; �S���荞�݃X�e�[�^�X�N���A

		; ��EOP(Alive)�𑗐M(�n�u�Ƀ��[�X�s�[�h�f�o�C�X��ڑ����Ă��鎞�̂�)
			bsr	eop

		; ��OUT�����A�G���h�|�C���g�ւ̓]�����A�]������(0000_0111b)
			move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-A�z�X�g�R���g���[�����W�X�^
			move.b	usb_wr_cmd,SL811_DATA_REG	; �]������

		GET_INT_TIME_OTWA

			jbsr	_Intr_1ms_check_stastus1

		GET_INT_TIME_OTWB

			jbsr	_Intr_1ms_check_stastus2

		GET_INT_TIME_END

			rts

	CHK_CMD_OTHER:

		; �����ɗ��邱�Ƃ̓v���O�����~�X�ȊO�ɂ��肦�܂���

		rts

_Intr_1ms_exit_nopacket:

		; ��EOP(Alive)�𑗐M(�n�u�Ƀ��[�X�s�[�h�f�o�C�X��ڑ����Ă��鎞�̂�)
		bsr	eop

		rts

;������ɑ��M�ł������`�F�b�N�P
_Intr_1ms_check_stastus1:

@@:
		move.b	#REG_INT_STATUS,SL811_ADDR_REG	; ���荞�݃X�e�[�^�X���W�X�^
		move.b	SL811_DATA_REG,usb_last_status	; 

		btst.b	#0,usb_last_status
		beq	@b

		clr.b	d0				; ����I��
		rts

;������ɑ��M�ł������`�F�b�N�Q
_Intr_1ms_check_stastus2

		move.b	#REG_INT_STAT_A,SL811_ADDR_REG	; USB-A�X�e�[�^�X���W�X�^
		move.b	SL811_DATA_REG,usb_last_statusA	; 

		rts

;��EOP(Alive)�𑗐M(�n�u�Ƀ��[�X�s�[�h�f�o�C�X��ڑ����Ă��鎞�̂�)
eop:
		; USBJOY�ł͉i���ɕs�v�Ȃ̂ŁA����������r���[�ȃR�[�h�ɂȂ��Ă��܂�
		rts

.if (EOP_PRINT=1)
eop2:
		_StrPrint	'*EOP',13,10
.endif
;		tst.b	host_usb_speed			; ���[�X�s�[�h(host_usb_speed = SPEED_LOW(0))���H
;		bne	@f
;
;		move.b	#$05,SL811_ADDR_REG		; �R���g���[�����W�X�^�P
;		move.b	#$20+$08+$01,SL811_DATA_REG	; ���[�X�s�[�h��USB���Z�b�g��SOF��������
;
;		move.b	#$05,SL811_ADDR_REG		; �R���g���[�����W�X�^�P
;		move.b	#$20+$00+$01,SL811_DATA_REG	; ���[�X�s�[�h���ʏ큕SOF��������
;	@@:
;		rts

;---------------------------------------------
; ��M�L�����N�^�L��(�}�E�X�P�o�C�g����)���E��
;---------------------------------------------
kill_mouse:
		move.w	d0,-(sp)
		move.w	SCC_DAT_B,d0
		move.w	#$38,SCC_COM_B
		move.w	(sp)+,d0
		rte

;---------------------------------------------------------
; �擾�����f�[�^��X68000�̃}�E�X�̃f�[�^�t�H�[�}�b�g�ɕϊ�
;---------------------------------------------------------
		.even
mouse_data_conv:
		beq	@f				; NAK or ERR�Ȃ�΃f�[�^�����H
		lea	Buf_Work(pc),a0
		andi.l	#$FF000000,(a0)
	@@:
		ori.w	#$0700,sr
		bset.b	#$05,$933.w
		movem.l	d0-d1/a0-a1,-(sp)

		lea	$930.w,a1
		move.l	a1,$92c.w
		move.w	#3,$92a.w

		btst.b	#7,$bbf.w
		bne	mouse_exit
		bset.b	#7,$bbf.w
		bset.b	#6,$933.w

		lea.l	Buf_Work(pc),a0

		cmpi.b	#5,(a0)				; �E�{���{�^���������ɉ�����Ă��邩�H
		bne	9f				; 
							; 
		cmpi.b	#5,old_mouse_button_status	; �O����E�{���{�^���̓����������H
		beq	9f				; 
							; 
		not.b	mouse_dpi_half_flg		; 
	9:
		move.b	(a0)+,d0

		move.b	d0,old_mouse_button_status

		move.b	d0,(a1)+			; �g���K���

		move.b	(a0)+,d0

		tst.b	mouse_dpi_half_flg
		beq	9f

		tst.b	d0				; 
		ble	1f				; �}�C�i�X�ƂO��e��
		cmpi.b	#127,d0				; 
		beq	1f				; 127��e��
		addq.b	#1,d0				; 
	1:
		asr.b	d0
	9:
		move.b	d0,(a1)+			; �w���W

		move.b	(a0),d0

		tst.b	mouse_dpi_half_flg
		beq	9f

		tst.b	d0				; 
		ble	1f				; �}�C�i�X�ƂO��e��
		cmpi.b	#127,d0				; 
		beq	1f				; 127��e��
		addq.b	#1,d0				; 
	1:
		asr.b	d0
	9:
		move.b	d0,(a1)				; �x���W

		lea	$930.w,a1
		lea	$cb1.w,a0
		move.b	(a1)+,(a0)+
		move.b	(a1)+,(a0)+
		move.b	(a1),(a0)

		lea	$cb1.w,a1
		move.w	$10(sp),d0
		or.w	#$2000,d0
		move.w	d0,sr

		movea.l	$934.w,a0
		jsr	(a0)

		movea.l	$938.w,a0
		jsr	(a0)

		bclr.b	#7,$bbf.w
mouse_exit:
		movem.l	(sp)+,d0-d1/a0-a1
		rts

;-------------------------------------------------------------------------
; �擾�����f�[�^��X68000�̃W���C�|�[�g�̃f�[�^�t�H�[�}�b�g�ɕϊ�(���ȏ���)
;-------------------------------------------------------------------------
		.even
joy_data_conv:
		bne	9f				; NAK or ERR�Ȃ�ΑO��̃f�[�^�������p��

		;clr.b	d0				; �����ɗ������_�ŕK��d0 = 0

		lea.l	Buf_Work(pc),a0

		;cmpi.b	#$00,2(a0)			; ����������Ă��邩�H
	left_cmd:	.dc.b	$0c,$28,$00		; 
	left_dat:	.dc.b	$00,$00			; 
	left_pos:	.dc.b	$02			; 
		;bne	1f				; 
		bhi	1f				; 
		ori.b	#JOY_LKEY,d0			; $0000,$000?
	1:
		;cmpi.b	#$ff,2(a0)			; �E��������Ă��邩�H
	right_cmd:	.dc.b	$0c,$28,$00		; 
	right_dat:	.dc.b	$ff,$00			; 
	right_pos:	.dc.b	$02			; 
		;bne	2f				; 
		bcs	2f				; 
		ori.b	#JOY_RKEY,d0			; 
	2:
		;cmpi.b	#$00,3(a0)			; �オ������Ă��邩�H
	up_cmd:		.dc.b	$0c,$28,$00		; 
	up_dat:		.dc.b	$00,$00			; 
	up_pos:		.dc.b	$03			; 
		;bne	3f				; 
		bhi	3f				; 
		ori.b	#JOY_UKEY,d0			; 
	3:
		;cmpi.b	#$ff,3(a0)			; ����������Ă��邩�H
	down_cmd:	.dc.b	$0c,$28,$00		; 
	down_dat:	.dc.b	$ff,$00			; 
	down_pos:	.dc.b	$03			; 
		;bne	4f				; 
		bcs	4f				; 
		ori.b	#JOY_DKEY,d0			; 
	4:
		;cmpi.b	#$00,1(a0)			; �`��������Ă��邩�H
	a1_cmd:		.dc.b	$0c,$28,$00		; 
	a1_dat:		.dc.b	$01,$00			; 
	a1_pos:		.dc.b	$00			; 
		bcs	5f				; 
		ori.b	#JOY_BTN_A1,d0			; 
	5:
		;cmpi.b	#$00,1(a0)			; �`��������Ă��邩�H
	b1_cmd:		.dc.b	$0c,$28,$00		; 
	b1_dat:		.dc.b	$01,$00			; 
	b1_pos:		.dc.b	$00			; 
		bcs	6f				; 
		ori.b	#JOY_BTN_B1,d0			; 
	6:
		;cmpi.b	#$00,1(a0)			; �`��������Ă��邩�H
	a2_cmd:		.dc.b	$0c,$28,$00		; 
	a2_dat:		.dc.b	$01,$00			; 
	a2_pos:		.dc.b	$00			; 
		bcs	7f				; 
		ori.b	#JOY_BTN_A2,d0			; 
	7:
		;cmpi.b	#$00,1(a0)			; �`��������Ă��邩�H
	b2_cmd:		.dc.b	$0c,$28,$00		; 
	b2_dat:		.dc.b	$01,$00			; 
	b2_pos:		.dc.b	$00			; 
		bcs	8f				; 
		ori.b	#JOY_BTN_B2,d0			; 
	8:
		not.b	d0				; �W���C�p�b�h�̃f�[�^�̃r�b�g�𔽓]�����܂�

		tst.b	usb_report_id
		bmi	1f

		;���|�[�g�h�c�łǂ���̃W���C�p�b�h�̓��͂��𒲂ׂ�
		;cmpi.b	#$02,?(a0)			; 
	rid_cmd:		.dc.b	$0c,$28,$00	; 
	rid_dat:		.dc.b	$02,$00		; 
	rid_pos:		.dc.b	$00		; 
		beq	2f				; 
	1:
		move.b	d0,joy_data0			; IOCS _JOYGET�ŎQ�Ƃ���郏�[�N�Ɋi�[
		rts
	2:
		move.b	d0,joy_data1			; IOCS _JOYGET�ŎQ�Ƃ���郏�[�N�Ɋi�[
9:
		rts

tsr_bottom:	; ���̈ʒu�܂ł��������ɏ풓���܂�

;-----------------------------------------------------------
; �T�u���[�`��
;-----------------------------------------------------------
;	CmdNereidResetOff:	���Z�b�g����
;	CmdNereidResetOn:	���Z�b�g
;	CmdNereidPowerOn:	�T�u����
;	CmdNereidPowerOff:	�T�u��~
;	CmdNereidIntOn:		���荞�݋���
;	CmdNereidIntOff:	���荞�݋֎~

		.even
CmdNereidResetOff:
		ori.b	#NEREID_USB_ENA,NEREID_CTRL	; ori.b		#$01,$00ece3f1
		rts

CmdNereidResetOn:
		andi.b	#NEREID_USB_DSA,NEREID_CTRL	; andi.b	#$FE,$00ece3f1
		rts

CmdNereidPowerOn:
		ori.b	#NEREID_USB_PON,NEREID_CTRL	; ori.b		#$02,$00ece3f1
		rts

CmdNereidPowerOff:
		andi.b	#NEREID_USB_POF,NEREID_CTRL	; andi.b	#$FD,$00ece3f1
		rts

CmdNereidIntOn:
		ori.b	#NEREID_USB_ION,NEREID_CTRL	; ori.b		#$04,$00ece3f1
		rts

CmdNereidIntOff:
		andi.b	#NEREID_USB_IOF,NEREID_CTRL	; andi.b	#$FB,$00ece3f1
		rts

;���P�������荞�ݏ����I���҂�
wait_command:

	@@:
		tst.b	usb_send_cmd
		bne	@b
		rts

;��SL811HST�̃��r�W�����̕\��
print_revision:
		move.b	#$0E,SL811HST_ADDR		; �n�[�h�E�F�A���r�W�������W�X�^
		move.b	SL811HST_DATA,d0		; 

		btst.l	#5,d0
		beq	@f
		move.b	#'5',chip_revision
	@@:
		movem.l	d0/a1,-(sp)

		move.w	#1,d1				; 
		IOCS	_B_COLOR			; ���F(����)

		lea	msg_sl811hst_rev,a1
		IOCS	_B_PRINT

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; ���F(����)

		movem.l	(sp)+,d0/a1

		rts

.if (SETUP_PACKET_PRINT=1)
;���r�d�s�t�o�p�P�b�g�̕\��
print_setup_packet:
;		movem.l	d0-d7/a0-a6,-(sp)
		movem.l	d0/d7/a0,-(sp)

	_StrPrint	'  SETUP PACKET  = '
		lea.l	print_packet_work(pc),a0
		move.w	#8-1,d7
	@@:
		move.b	(a0)+,d0
		jbsr	hex_print_b_sp
		dbra	d7,@b

	_StrPrint	13,10

;		movem.l	(sp)+,d0-d7/a0-a6
		movem.l	(sp)+,d0/d7/a0

		rts
.endif

;�����荞�݃J�E���^�̌��ʕ\��
print_int_count:
	.if (INT_TIME_PRINT=1)

		move.l	d0,-(sp)
	_StrPrint	' Start = '
		move.b	int_start_count,d0
		jbsr	hex_print_b
	_StrPrint	' : OTW_A = '
		move.b	int_ontheway_countA,d0
		jbsr	hex_print_b
	_StrPrint	' : OTW_B = '
		move.b	int_ontheway_countB,d0
		jbsr	hex_print_b
	_StrPrint	' : End = '
		move.b	int_end_count,d0
		jbsr	hex_print_b
	_StrPrint	cr,lf
		move.l	(sp)+,d0
	.else

	_StrPrint	cr,lf

	.endif
		rts

;��
print_return_code:
	.if (RETURN_CODE_PRINT=1)
		tst.b	d0
		bne	@f

		_StrPrint	' RC = ACK',cr,lf
		rts
	@@:
		cmpi.b	#1,d0
		bne	@f
		_StrPrint	' RC = NAK',cr,lf
		rts
	@@:
		_StrPrint	' RC = ERR',cr,lf
	.endif
		rts

;���c�]���o�C�g���̕\��
print_rest_size:
	.if (REST_SIZE_PRINT=1)
		move.l	d0,-(sp)

		_StrPrint	' usb_rest_size = '
		clr.l	d0
		move.b	usb_rest_size,d0
		jbsr	num_print
		_StrPrint	cr,lf

		move.l	(sp)+,d0
	.endif
		rts

;���ŏI�X�e�[�^�X���W�X�^�̕\��
print_last_status:
	.if (LAST_STATUS_PRINT=1)
		move.l	d0,-(sp)

		_StrPrint	' usb_last_status = '
		move.b	usb_last_status,d0
		jbsr	hex_print_b
		_StrPrint	' : usb_last_statusA = '
		move.b	usb_last_statusA,d0
		jbsr	hex_print_b
		_StrPrint	cr,lf

		move.l	(sp)+,d0
	.endif
		rts

;���f�B�X�N���v�^�̕\��
print_StdDescriptor:
		movem.l	d0/d7/a0,-(sp)

		_StrPrint	'  StdDescriptor = '

		lea.l	Buf_StdDescriptor(pc),a0
		clr.w	d7
		move.b	usb_length,d7
		subq.w	#1,d7
	;	move.w	#18-1,d7
	@@:
		move.b	(a0)+,d0
		jbsr	hex_print_b_sp
		dbra	d7,@b

		_StrPrint	13,10

		movem.l	(sp)+,d0/d7/a0
		rts

;���f�B�X�N���v�^�̕\��
print_CnfDescriptor:
		movem.l	d0/d7/a0,-(sp)

		_StrPrint	' CnfDescriptor = '

		lea.l	Buf_CnfDescriptor(pc),a0
		clr.w	d7
		move.b	usb_length,d7
		subq.w	#1,d7
	;	move.w	#34-1,d7
	@@:
		move.b	(a0)+,d0
		jbsr	hex_print_b_sp
		dbra	d7,@b

		_StrPrint	13,10

		movem.l	(sp)+,d0/d7/a0
		rts

;���p�P�b�g�f�[�^�̕\��
print_Buf_Work:
		movem.l	d0/d7/a0,-(sp)

		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; ���F(����)

		_StrPrint	'packet data : '

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; ���F

		lea.l	Buf_Work(pc),a0
		clr.w	d7
		move.b	usb_length,d7
		subq.w	#1,d7
	@@:
		move.b	(a0)+,d0
		jbsr	hex_print_b_sp
		dbra	d7,@b

		movem.l	(sp)+,d0/d7/a0
		rts

;-----------------------------------------------------------
; �������֘A
;-----------------------------------------------------------

;��SL811HST�̏�����
init_sl811hst:
		move.w	#240-1,d7			; 
		clr.b	d0				; SL811H�̃�������������
		move.b	#$10,SL811HST_ADDR		; 
	@@:
		move.b	d0,SL811HST_DATA
		dbra	d7,@b

		rts

delay50ns:
		movem.l	d0-d1/a0,-(sp)
		lea	($00e88023),a0

		move.b	(a0),d0
delay_wait1:	cmp.b	(a0),d0
		beq	delay_wait1

delay_loop:
		subq.b	#1,d0
		bne	delay_wait2
		moveq	#200,d0
delay_wait2:	cmp.b	(a0),d0
		beq	delay_wait2
		subq.l	#1,d1
		bgt	delay_loop

		movem.l	(sp)+,d0-d1/a0
		rts

;-----------------------------------------------------------
; ��`�t�@�C���̓ǂݍ���
;-----------------------------------------------------------
GetUsbPadInfo:
		clr.l	d0
		lea.l	WorkBuffer(pc),a0
		move.w	#32768/4,d1
	@@:	move.l	d0,(a0)+
		dbra	d1,@b

		_open	filename,#0			; 
		tst.l	d0				; �t�@�C�����I�[�v���ł������H
		bmi	open_error			; �}�C�i�X�Ȃ�΃I�[�v���ł��Ȃ��̂ŃG���[

		move.w	d0,handle			; �t�@�C���n���h�����i�[

		_read	handle,WorkBuffer,#32768+1	; 32768+1�o�C�g�ǂݍ���
		move.l	d0,FileSize			; �t�@�C���T�C�Y�����܂��Ă���
		_close	handle				; �Ƃ肠�����t�@�C���N���[�Y

		cmpi.l	#32768,FileSize			; 32769�o�C�g�ȏ�ǂݍ��߂���G���[
		bhi	read_error			; 

		lea	WorkBuffer,a0			;
		cmpi.l	#'USBJ',(a0)+			; ��`�t�@�C���łȂ���΃G���[
		bne	header_error			;
		cmpi.l	#'OY13',(a0)+			; ��`�t�@�C���łȂ���΃G���[
		bne	header_error			;

	;���ŏ��̃s���I�h���o�Ă���܂ŃX�L�b�v
	@@:
		tst.b	(a0)				; �Ō�܂Ń`�F�b�N�������H
		beq	data_error2			; 
		addq.l	#1,a0				; 
		cmpi.b	#$0a,-1(a0)			; ���s�R�[�h�̎��܂ŃX�L�b�v����
		bne	@b				; 
		cmpi.b	#'.',(a0)			; �s�̐擪���ŏ��̃s���I�h���H
		bne	@b				; 

		_StrPrint2	'�ŏ��̃s���I�h���o.',cr,lf

	;�����̍s�܂ŉ��s
	@@:
		tst.b	(a0)				; �Ō�܂Ń`�F�b�N�������H
		beq	data_error2			; 
		addq.l	#1,a0				; 
		cmpi.b	#$0a,-1(a0)			; ���s�R�[�h�̎��܂ŃX�L�b�v����
		bne	@b				; 

	get_info_top:

	;�����������`�f�[�^�L�q
		lea.l	UsbPadInfo,a1			; ����ǂݍ��ރ��[�N�̐擪
		move.w	#10-1,d6			; ���[�h�f�[�^��11��ǂ�
	@@:
		jbsr	get_word_data			; VID�`RBTN2�擾
		bne	data_error2			; 
		move.w	d0,(a1)+			; �������܂�
		jbsr	skipsp				; 
		dbra	d6,@b				; 

		jbsr	get_psize			; PSIZE�擾
		bne	data_error2			; 
		move.b	d0,PSIZE			; �������܂�
		jbsr	skipsp				; 

		jbsr	get_intr			; INTR�擾
		bne	data_error2			; 
		move.b	d0,INTR				; �������܂�
		jbsr	skipsp				; 

		jbsr	get_repid			; REPID�擾
		bne	data_error2			; 
		subi.b	#1,d0				; 
		move.b	d0,REPID			; �������܂�
		jbsr	skipsp				; 

		move.w	VendorID,d0			; 
		rol.w	#8,d0				; �G���f�B�A���ϊ�
		swap.w	d0				; 
		move.w	ProductID,d0			; 
		rol.w	#8,d0				; �G���f�B�A���ϊ�
		cmp.l	VID,d0				; 
		beq	found_info			; �o�^�ς݂̃W���C�p�b�h�������ꍇ

	;�����̍s�܂ŉ��s
	@@:
		tst.b	(a0)				; �Ō�܂Ń`�F�b�N�������H
		beq	data_error2			; 
		addq.l	#1,a0				; 
		cmpi.b	#$0a,-1(a0)			; ���s�R�[�h�̎��܂ŃX�L�b�v����
		bne	@b				; 

		cmpi.b	#'.',(a0)			; �s�̐擪���Ō�̃s���I�h���H
		beq	undefined_error			; 
		jbra	get_info_top			; 
found_info:
	; ��������
		_StrPrint	'�Ή��ς݂̃W���C�p�b�h���ڑ�����Ă��܂�.',cr,lf

		clr.w	d0
		rts
open_error:
		_StrPrint	'��`�t�@�C�����I�[�v���ł��܂���.',cr,lf
		bra	@f
read_error:
		_StrPrint	'��`�t�@�C���̃T�C�Y��32KByte���z���Ă��܂�.',cr,lf
		bra	@f
header_error:
		_StrPrint	'��`�t�@�C���ł͂���܂���.',cr,lf
		bra	@f
data_error:
		_StrPrint	'��`�t�@�C���̋L�q�ɃG���[������܂�.',cr,lf
		bra	@f
data_error2:
		_StrPrint	'��`�t�@�C���̋L�q�ɃG���[������܂�.',cr,lf
		bra	@f
psize_error:
		_StrPrint	'��`�t�@�C���̃o�C�g�ʒu�w��ɁA�ő�p�P�b�g�T�C�Y�����傫�Ȓl���ݒ肳��Ă��܂�.',cr,lf
		bra	@f
bit_error:
		_StrPrint	'��`�t�@�C���̃r�b�g�ʒu�w��� 0�`7 �ȊO�̒l���ݒ肳��Ă��܂�.',cr,lf
		bra	@f
undefined_error:
		_StrPrint	'���Ή��̃W���C�p�b�h���ڑ�����Ă��܂�.',cr,lf
		tst.b	optflg_C	; �p�P�b�g�������[�h�̏ꍇ�̓G���[�ɂ͂��Ȃ����
		beq	@f
		move.w	#$ffff,d0
		rts
	@@:
		move.w	#$01,d0
		rts

;-----------------------------------------------------------
; ��`�t�@�C���̊ȈՃf�[�^�`�F�b�N
;-----------------------------------------------------------
ChkUsbPadInfo:
		lea.l	LKEY,a1
		move.w	#8-1,d7
	1:
		move.w	(a1)+,d0
		bmi	2f

		; �f�W�^��1�r�b�g

		cmpi.b	#8,d0
		bcc	bit_error
	2:
		; �A�i���O8�r�b�g

		ror.w	#8,d0
		andi.b	#$0f,d0
		cmp.b	MaxPacketSizeL,d0
		bcc	psize_error
	3:
		dbra	d7,1b

		clr.w	d0
		rts

;-----------------------------------------------------------
; ���ȏ������[�`��
;-----------------------------------------------------------
WriteUsbPadInfo:
		bmi	8f

		lea.l	LKEY,a0
		lea.l	left_cmd(pc),a1

		move.w	#8-1,d7
	1:
		move.w	(a0)+,d0
		bmi	2f

		; �f�W�^��1�r�b�g���ȏ���
		move.w	#$0828,0(a1)		; btst.b
		move.w	#$6704,6(a1)		; beq	+4
	2:
		andi.w	#$0fff,d0

		move.b	d0,3(a1)		; �r�b�g�ʒu
		ror.w	#8,d0			; 
		move.b	d0,5(a1)		; �o�C�g�ʒu

		lea.l	12(a1),a1

		dbra	d7,1b

		move.b	usb_report_id,d0
		bmi	8f

		;���|�[�g�h�c�ǂݍ��݃o�C�g�ʒu�����ւ�
		move.b	d0,rid_pos
	8:
		; �T�u���[�`���̕���A�h���X���W���C�p�b�h�ɏ����ւ���
		move.w	#joy_data_conv-branch_address,branch_address

		cmpi.b	#$02,$0cbc.w		; MPU�`�F�b�N
		bcs	9f			; 68020�����Ȃ�΂Ȃɂ����Ȃ�

		moveq.l	#3,d1			; �l�o�t�L���b�V���̃N���A
		IOCS	_SYS_STAT		; (�{����ROM�o�[�W�������l�����ׂ�)
	9:
		rts

;-----------------------------------------------------------
; �擪�̃X�y�[�X�i���^�u�j���X�L�b�v����B
;-----------------------------------------------------------
		.even
@@:
		addq.l	#1,a0		;
skipsp:
		cmpi.b	#$20,(a0)	;�X�y�[�X���H
		beq	@b
		cmpi.b	#$09,(a0)	;�^�u���H
		beq	@b
		rts

;-----------------------------------------------------------
; d0.w�ɂQ�o�C�g($????)�̃f�[�^���擾����
;-----------------------------------------------------------
get_word_data:
		clr.l	d0
		move.w	#4-1,d7
	@@:
		move.b	(a0)+,d1		; �����擾
		jbsr	chk_char_data_0f	; �����`�F�b�N(0�`F)
		bmi	err_word_data
		lsl.w	#4,d0
		or.b	d1,d0
		dbra	d7,@b

		clr.b	d1
		rts
err_word_data:
		move.w	#1,d1
		rts

;-----------------------------------------------------------
; d0.b�Ƀp�P�b�g�T�C�Y($00�`$08)���擾����
;-----------------------------------------------------------
get_psize:
		clr.l	d0
		move.b	(a0)+,d1		; �����擾
		jbsr	chk_char_data_psize	; �����`�F�b�N(-�`8)
		bmi	err_get_psize
		or.b	d1,d0

		clr.b	d1
		rts
err_get_psize:
		move.w	#1,d1
		rts

;-----------------------------------------------------------
; d0.b�Ɋ��荞�ݎ���($00�`$0f)���擾����
;-----------------------------------------------------------
get_intr:
		clr.l	d0
		move.b	(a0)+,d1		; �����擾
		jbsr	chk_char_data_intr	; �����`�F�b�N(-�`f)
		bmi	err_get_intr
		or.b	d1,d0

		clr.b	d1
		rts
err_get_intr:
		move.w	#1,d1
		rts

;---------------------------------------------------------------------
; d0.b�Ƀ��|�[�g�h�c�̈ʒu($00�`$08)���擾����(+1���ꂽ�l���擾�����)
;---------------------------------------------------------------------
get_repid:
		clr.l	d0
		move.b	(a0)+,d1		; �����擾
		jbsr	chk_char_data_repid	; �����`�F�b�N(-�`7)
		bmi	err_get_repid
		or.b	d1,d0

		clr.b	d1
		rts
err_get_repid:
		move.w	#1,d1
		rts

chk_char_data_0f:
		lea.l	chk_char_str_0f(pc),a2
	@@:
		move.b	(a2)+,d2
		beq	@f
		cmp.b	d1,d2
		bne	@b
	@@:
		move.b	22(a2),d1
		rts

chk_char_data_psize:
		lea.l	chk_char_str_psize(pc),a2
	@@:
		move.b	(a2)+,d2
		beq	@f
		cmp.b	d1,d2
		bne	@b
	@@:
		move.b	9(a2),d1
		rts

chk_char_data_intr:
		lea.l	chk_char_str_intr(pc),a2
	@@:
		move.b	(a2)+,d2
		beq	@f
		cmp.b	d1,d2
		bne	@b
	@@:
		move.b	22(a2),d1
		rts

chk_char_data_repid:
		lea.l	chk_char_str_repid(pc),a2
	@@:
		move.b	(a2)+,d2
		beq	@f
		cmp.b	d1,d2
		bne	@b
	@@:
		move.b	9(a2),d1
		rts

		.even
chk_char_str_0f:
		.dc.b	'0123456789ABCDEFabcdef',0
		.dc.b	$00,$01,$02,$03,$04,$05,$06,$07,$08,$09
		.dc.b	$0A,$0B,$0C,$0D,$0E,$0F
		.dc.b	$0A,$0B,$0C,$0D,$0E,$0F
		.dc.b	$FF
chk_char_str_psize:
		.dc.b	'-12345678',0
		.dc.b	$00,$01,$02,$03,$04,$05,$06,$07,$08
		.dc.b	$FF
chk_char_str_intr:
		.dc.b	'-123456789ABCDEFabcdef',0
		.dc.b	$00,$01,$02,$03,$04,$05,$06,$07,$08,$09
		.dc.b	$0A,$0B,$0C,$0D,$0E,$0F
		.dc.b	$0A,$0B,$0C,$0D,$0E,$0F
		.dc.b	$FF
chk_char_str_repid:
		.dc.b	'-01234567',0
		.dc.b	$00,$01,$02,$03,$04,$05,$06,$07,$08
		.dc.b	$FF

;==============================================================================================
; �R�}���h���C���I�v�V�����̃`�F�b�N
;==============================================================================================
		.even
option_check:
		movem.l	d0-d7/a0-a6,-(sp)		; ���W�X�^�Ҕ�

		lea.l	1(a2),a0			; a0 = �R�}���h���C���̐擪�A�h���X;
option_check0:
		bsr	Sub_SkipSPACE			; �ŏ��ɃX�y�[�X�A�^�u���X�L�b�v(����)

		tst.b	(a0)				; �����������邩�H
		beq	option_check_end

	;�I�v�V�����擾
		cmpi.b	#'/',(a0)			; �X���b�V�����H
		beq	Sub_GetOption			; �I�v�V�����̔��ʂ�
		cmpi.b	#'-',(a0)			; �n�C�t�����H
		beq	Sub_GetOption			; �I�v�V�����̔��ʂ�

	;�t�@�C�����擾
		lea.l	filename(pc),a1			; a1 = �t�@�C�����̃��[�N�A�h���X�擪
		bsr	Sub_GetFileName			; �t�@�C�����̎擾��

option_check_end:
		movem.l	(sp)+,d0-d7/a0-a6		; ���W�X�^���A

		rts

;==============================================================================================
;���R�}���h���C���̐擪�̃X�y�[�X�i���^�u�j���X�L�b�v����T�u���[�`��
;==============================================================================================
		.even
	@@:
		lea.l	1(a0),a0			;a0=�R�}���h���C���̐擪�A�h���X
Sub_SkipSPACE:
		cmpi.b	#$20,(a0)			;�X�y�[�X���H
		beq	@b
		cmpi.b	#$09,(a0)			;�^�u���H
		beq	@b
		rts

;==============================================================================================
;���t�@�C�����̎擾
;==============================================================================================
		.even
Sub_GetFileName:
	@@:						;
		tst.b	(a0)				; ������̏I�[�R�[�h���H
		beq	@f				;
		cmpi.b	#$20,(a0)			; �X�y�[�X���H
		beq	@f				;
		cmpi.b	#$09,(a0)			; �^�u���H
		beq	@f				;
		cmpi.b	#'/',(a0)			; �X���b�V�����H
		beq	@f				;
		cmpi.b	#'-',(a0)			; �n�C�t�����H
		beq	@f				;
		move.b	(a0)+,(a1)+			; �t�@�C�������P�����]��
		bra.b	@b				;
	@@:						;
		clr.b	(a1)				; ������I�[�R�[�h����������

		rts

;==============================================================================================
;���I�v�V�����̎擾
;==============================================================================================
		.even
Sub_GetOption:
		lea.l	1(a0),a0			; '/' or '-'���P������΂�

		move.b	(a0)+,d0			; �P�����ǂݍ���

		cmpi.b	#'A',d0				; ���p�啶���̃A���t�@�x�b�g�Ȃ��
		bcs	@f				; �������ɕϊ�����
		cmpi.b	#'Z',d0				;
		bhi	@f				;
		addi.b	#' ',d0				;
	@@:
		cmpi.b	#'a',d0				; -a�I�v�V�������w�肳��Ă��邩�H
		beq	option_A			;
		cmpi.b	#'c',d0				; -c�I�v�V�������w�肳��Ă��邩�H
		beq	option_C			;
		cmpi.b	#'x',d0				; -x�I�v�V�������w�肳��Ă��邩�H
		beq	option_X			;
; -------- patch +z1 --------
		cmpi.b	#'z',d0				; -z�I�v�V�������w�肳��Ă��邩�H
		beq	option_Z			;
; ---------------------------
		cmpi.b	#'h',d0				; -h�I�v�V�������w�肳��Ă��邩�H
		beq	Sub_PrintUsage			;
		bra	Sub_PrintUsage			; ����ȊO�Ȃ�΃w���v�̕\��
option_A:
		;�I�v�V�����`����
		move.b	(a0)+,d0			; �P�����ǂݍ���
		cmpi.b	#'1',d0				; '1'���H
		beq	1f				; ����ȊO�Ȃ�΃w���v�̕\��
		cmpi.b	#'2',d0				; '2'���H
		bne	Sub_PrintUsage			; ����ȊO�Ȃ�΃w���v�̕\��
	1:
		subi.b	#'0',d0
		move.b	d0,auto_flg
		bra	@f
option_C:
		;�I�v�V�����b����
		move.b	#1,optflg_C
		bra	@f
option_X:
		;�I�v�V�����w����
		move.b	#1,optflg_X
		bra	@f
; -------- patch +z1 --------
option_Z:
		;�I�v�V�����y����
		move.b	#1,optflg_Z
		bra	@f
; ---------------------------
		nop
	@@:
		jbra	option_check0			; �����Ȃ�Ύ��̃`�F�b�N��

;==============================================================================================
;���w���v�̕\�� �T�u���[�`��
;==============================================================================================
		.even
Sub_PrintUsage:
		movem.l	d0/a1,-(sp)
		lea	usage_msg,a1
		IOCS	_B_PRINT
		movem.l	(sp)+,d0/a1

		_exit

		.text
;---------------------------------------------------------------------------------------

		.include usbjoy_print.s

*--------------------------------------------------------------
		.even
Startup:
		movem.l	d0/a1,-(sp)			; ���W�X�^�Ҕ�

		move.w	#2,d1				; 
		IOCS	_B_COLOR			; �\�������F�����F�ɕύX���܂�

		lea	title_msg,a1			; 
		IOCS	_B_PRINT			; �^�C�g����\�����܂�

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; �\�������F�𔒂ɖ߂��܂�

		movem.l	(sp)+,d0/a1			; ���W�X�^���A

		movem.l	d0-d7/a0-a6,-(sp)		; ���W�X�^�Ҕ�

		lea	tsr_top-$80(pc),a0		; 
		lea.l	filename(pc),a1			; 
	@@:						; �A�h���Xfilename�Ƀv���Z�X�Ǘ��|�C���^����擾�����p�X�����i�[���܂�
		move.b	(a0)+,(a1)+			; 
		bne	@b				; 

		lea	def_filename,a0			; 
		lea	-1(a1),a1			; 
	@@:						; �擾�����p�X�̌��ɒ�`�t�@�C������ǉ����܂�
		move.b	(a0)+,(a1)+			; 
		bne	@b				; 

.if (PATH_FILENAME_PRINT=1)
		lea.l	filename(pc),a1			; 
		IOCS	_B_PRINT			; �p�X�{��`�t�@�C������\�����܂�(�e�X�g���̂�)
		_StrPrint	cr,lf			; 
.endif

		movem.l	(sp)+,d0-d7/a0-a6		; ���W�X�^���A

		clr.l	a1				; 
		IOCS	_B_SUPER			; �X�[�p�[�o�C�U���[�h�ɂ���

		; ���̎��_��d0�ɕύX�O��ssp�̓��e�������Ă��܂�

		; ���I�v�V�����̃`�F�b�N
		jbsr	option_check

		; ���풓���Ă��邩�`�F�b�N���܂�
chck_top:
		movea.l	(a0),a1
		cmpi.l	#0,(a1)				; �O�Ȃ�Ώ풓���Ă��Ȃ�����
		beq	Stay_Mem			; �풓������
		movea.l	a1,a0				; 
		lea.l	$100(a1),a1			; +256�o�C�g
		lea	tsr_top(pc),a2			; 

		moveq	#8-1,d1				; 
chck_loop:						; 
		cmpm.b	(a1)+,(a2)+			; '$USBJOY$'�������������H
		bne	chck_top			; ������Ȃ���Ύ��̃v���Z�X�Ǘ��|�C���^�𒲂ׂ邽�߈ړ�
		dbra	d1,chck_loop			; 

		; a0==�풓���̃A�h���X

	; ���ڑ�����Ă���̂��W���C�p�b�h�Ȃ�΁AIOCS_JOYGET�����ɖ߂�
		tst.b	$100+Protocol-tsr_top(a0)	; 
		bne	@f				; 
		movem.l	d0-d1/a1,-(sp)			; ���W�X�^�ޔ�
		move.w	#$013B,d1			; d1 = _JOYGET��u��������
		movea.l	$100+old_joy_vct-tsr_top(a0),a1	; a1 = �u�������O�̃A�h���X
		IOCS	_B_INTVCS			; ���荞�݃n���h�������ɖ߂�
		movem.l	(sp)+,d0-d1/a1			; ���W�X�^���A
	@@:
;---------------------------------------------------------------------------
; �풓�I���O����
;---------------------------------------------------------------------------
	movem.l	d0-d7/a0-a6,-(sp)

	; �I�������̍ŗǂ̕��@�͕s�m��

		jbsr	CmdNereidIntOff			; nereid int off
		move.l	#2*20,d1			; 2ms�҂�
		jbsr	delay50ns

		move.w	#100,d7
	@@:
		move.b	#REG_INT_STATUS,SL811HST_ADDR	; ���荞�݃X�e�[�^�X���W�X�^
		move.b	#$FF,SL811HST_DATA		; �S���荞�݃t���O���Z�b�g
		dbra	d7,@b

		move.b	#$06,SL811HST_ADDR		; ���荞�݃C�l�[�u�����W�X�^
		move.b	#$00,SL811HST_DATA		; �S�^�C�}���荞�݂��֎~

	move.l	#10*20,d1
	jbsr	delay50ns

		jbsr	CmdNereidPowerOff		; nereid power off
		jbsr	CmdNereidResetOn		; nereid reset on

	movem.l	(sp)+,d0-d7/a0-a6
;---------------------------------------------------------------------------
; �풓�I������
;---------------------------------------------------------------------------

		movem.l	d0-d1/a1,-(sp)
		move.w	#$FB,d1				; 
		movea.l	$100+old_int-tsr_top(a0),a1	; 
		IOCS	_B_INTVCS			; ���荞�݃n���h�������ɖ߂�
		movem.l	(sp)+,d0-d1/a1

;		move.l	$100+old_mouse_vct-tsr_top(a0),$150
;		move.l	$100+old_mouse_vct-tsr_top(a0),$154

		move.l	d0,a1				;
		IOCS	_B_SUPER			; ���[�h�����Ƃɖ߂�

		add.l	#$10,a0
		move.l	a0,-(sp)
		DOS	_MFREE

		pea	rel_msg
		DOS	_PRINT
exit_prog:
		DOS	_EXIT

;---------------------------------------------------------------------------
; �풓�J�n
;---------------------------------------------------------------------------
;		.even
Stay_Mem:
		move.l	d0,a1				;
		IOCS	_B_SUPER			; ���[�h�����Ƃɖ߂�

		clr.l	a1				; 
		IOCS	_B_SUPER			; �X�[�p�[�o�C�U���[�h�ɂ���

;		move.l	($150),old_mouse_vct		; ��M�L�����N�^�L��(�}�E�X�P�o�C�g����)
;		lea	kill_mouse,a1			;
;		move.l	a1,$150				;
;		move.l	a1,$154				;

	movem.l	d0-d7/a0-a6,-(sp)

		move.w	#$FB,d1				; 
		lea.l	_Intr_1ms(pc),a1		; 
		IOCS	_B_INTVCS			; ���荞�݃n���h���� _Intr_1ms �ɐݒ�
		move.l	d0,old_int			; 

		clr.l	int_count			; �e�X�g�p�J�E���^���O��

		clr.b	usb_send_cmd			; 
		clr.b	usb_endp			; 
		clr.b	usb_addr			; 
		clr.b	usb_length			; 
		clr.b	usb_interrupt_flg		; �C���^���v�g�]���J�n�t���O
		clr.b	usb_interrupt_count		; �C���^���v�g�]���J�E���^

		move.b	#DATA0_WR,usb_wr_cmd
		move.b	#DATA0_RD,usb_rd_cmd

		jbsr	CmdNereidIntOff			; nereid int off

		jbsr	CmdNereidResetOff		; nereid reset off

		jbsr	CmdNereidPowerOn		; nereid power on

	move.l	#500*20,d1	; 
	jbsr	delay50ns	; �ꕔ�̃}�E�X�������o�ɂȂ��Ă��܂��̂ŃE�F�C�g��ǉ��P

		jbsr	init_sl811hst			; SL811HST������������

		jbsr	print_revision			; �n�[�h�E�F�A���r�W�����\��

		move.b	#$0F,SL811HST_ADDR		; SOF��ʃJ�E���^/�R���g���[�����W�X�^�Q
		move.b	#$80+$2E,SL811HST_DATA		; �z�X�g���샂�[�h��SOF��ʃJ�E���^�U�r�b�g

		move.b	#$05,SL811HST_ADDR		; �R���g���[�����W�X�^�P
		move.b	#$08,SL811HST_DATA		; �t�r�a���Z�b�g

		move.l	#20*20,d1
		jbsr	delay50ns

		move.b	#$05,SL811HST_ADDR		; �R���g���[�����W�X�^�P
		move.b	#$00,SL811HST_DATA		; �t�r�a���Z�b�g����

	move.l	#300*20,d1	; 
	jbsr	delay50ns	; �ꕔ�̃}�E�X�������o�ɂȂ��Ă��܂��̂ŃE�F�C�g��ǉ��Q

		move.w	#100,d7
	@@:
		move.b	#REG_INT_STATUS,SL811HST_ADDR	; ���荞�݃X�e�[�^�X���W�X�^
		move.b	#$FF,SL811HST_DATA		; �S���荞�݃t���O���Z�b�g
		dbra	d7,@b

		clr.l	d0

		move.b	#REG_INT_STATUS,SL811HST_ADDR	; ���荞�݃X�e�[�^�X���W�X�^
		move.b	SL811HST_DATA,d0		; �̓��e�� d0 �ɓǂݍ���

		move.b	#$05,SL811HST_ADDR		; �R���g���[�����W�X�^�P
		move.b	#$08,SL811HST_DATA		; �t�r�a���Z�b�g

	.if (ISR_PRINT=1)
		_StrPrint	'ISR = '
		jbsr	hex_print_b
		_StrPrint	cr,lf
	.endif

		btst.l	#6,d0				; Resume Detection ���荞�ݏオ��Ȃ����
		bne	no_device			; �f�o�C�X�Ȃ��̏����֔��

		btst.l	#7,d0				; ISR �� $80 �� ON �Ȃ� low speed
		bne	full_speed_device

low_speed_device:
		_StrPrint	'Low Speed Device Detected.',cr,lf

		move.b	SPEED_LOW,host_usb_speed

			move.b	#$0E,SL811HST_ADDR		; SOF���ʃJ�E���^
			move.b	#$E0,SL811HST_DATA		; ���ʃJ�E���^�W�r�b�g

		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#$0F,SL811HST_ADDR		; SOF��ʃJ�E���^/�R���g���[�����W�X�^�Q
			move.b	#$80+$40+$2E,SL811HST_DATA	; �z�X�g���샂�[�h�����[�X�s�[�h���[�h��SOF��ʃJ�E���^�U�r�b�g

			move.b	#$05,SL811HST_ADDR		; �R���g���[�����W�X�^�P
			move.b	#$20+01,SL811HST_DATA		; ���[�X�s�[�h��SOF��������(���荞�ݗL��)

			move.w	#100,d7				; 
		@@:						; 
			move.b	#REG_INT_STATUS,SL811HST_ADDR	; ���荞�݃X�e�[�^�X���W�X�^
			move.b	#$FF,SL811HST_DATA		; �S���荞�݃t���O���Z�b�g
			dbra	d7,@b				; 

		bra	@f

full_speed_device:
		_StrPrint	'Full Speed Device Detected.',cr,lf

		move.b	SPEED_FULL,host_usb_speed

			move.b	#$0E,SL811HST_ADDR		; SOF���ʃJ�E���^
			move.b	#$E0,SL811HST_DATA		; ���ʃJ�E���^�W�r�b�g

		; �����Ȃ̂ŃA�h���X�̃Z�b�g�͕K�v�Ȃ���
		;	move.b	#$0F,SL811HST_ADDR		; SOF��ʃJ�E���^/�R���g���[�����W�X�^�Q
			move.b	#$80+$00+$2E,SL811HST_DATA	; �z�X�g���샂�[�h���n�C�X�s�[�h���[�h��SOF��ʃJ�E���^�U�r�b�g

			move.b	#$05,SL811HST_ADDR		; �R���g���[�����W�X�^�P
			move.b	#$00+01,SL811HST_DATA		; �t���X�s�[�h��SOF��������(���荞�ݗL��)

			move.b	#REG_INT_STATUS,SL811HST_ADDR	; ���荞�݃X�e�[�^�X���W�X�^
			move.b	#$FF,SL811HST_DATA		; �S���荞�݃t���O���Z�b�g

	@@:
			move.b	#$03,SL811HST_ADDR	; USB-A�z�X�g�E�p�P�b�gID�A�f�o�C�X�G���h�|�C���g
			move.b	#$50,SL811HST_DATA	; $5=SOF:$0=�f�o�C�X�G���h�|�C���g

			move.b	#$04,SL811HST_ADDR	; USB-A�z�X�g�E�f�o�C�X�A�h���X
			move.b	#$00,SL811HST_DATA	; �A�h���X���O

			move.b	#$00,SL811HST_ADDR	; USB-A�z�X�g�R���g�������W�X�^
			move.b	#$01,SL811HST_DATA	; bit0=1�œ]�����F�]�������������bit1=0�ɂȂ�

		move.l	#25*20,d1
		jbsr	delay50ns

			move.b	#$06,SL811HST_ADDR	; ���荞�݃C�l�[�u�����W�X�^
			move.b	#$10,SL811HST_DATA	; SOF�^�C�}���荞��(bit4)�̂݋�����

		move.w	#64,retry_nak_max_count	; NAK�̍ő僊�g���C�񐔂��Z�b�g

		jbsr	CmdNereidIntOn		; �l���C�h�̊��荞�݋���

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'���f�o�C�X�f�B�X�N���v�^�̉��擾(�擪�W�o�C�g�̂ݎ擾)',cr,lf

		; ���f�o�C�X�f�B�X�N���v�^�̉��擾

		move.b	#$00,usb_addr		; �A�h���X = 0
		move.b	#$00,usb_endp		; �G���h�|�C���g = 0
		move.b	#8,usb_length		; �f�[�^�]���� = 8
		move.b	#8,usb_payload		; ���y�C���[�h = 8
		lea.l	Buf_StdDescriptor(pc),a0
		move.l	a0,usb_buf_address	; �f�o�C�X�f�B�X�N���v�^��ǂݍ��ރA�h���X

		jbsr	_GetDeviceDescriptor	; �f�o�C�X�f�B�X�N���v�^�擾
		tst.b	d0
		bne	err_exit

		_StrPrint2	'������Ɏ擾�ł��܂���',cr,lf,cr,lf

		lea.l	Buf_StdDescriptor(pc),a0
		move.b	$7(a0),usb_payload	; �y�C���[�h = 8/16/32/64

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'���A�h���X�̕ύX(0 -> 1)',cr,lf

		; ���A�h���X�ݒ�

		move.b	#$01,address_data	; �V�A�h���X = 1
		move.b	#$00,usb_addr		; �A�h���X = 0
		move.b	#$00,usb_endp		; �G���h�|�C���g = 0
		;move.b	#0,usb_length		; �f�[�^�]���� = 0
		lea.l	Buf_StdDescriptor(pc),a0
		move.l	a0,usb_buf_address	; 

		jbsr	_SetDeviceAddress	; �f�o�C�X�A�h���X�ݒ�
		tst.b	d0
		bne	err_exit

		_StrPrint2	'������ɕύX�ł��܂���',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'���f�o�C�X�f�B�X�N���v�^�̖{�擾',cr,lf

		; ���f�o�C�X�f�B�X�N���v�^�{�擾

		move.b	#$01,usb_addr		; �A�h���X = 1
		move.b	#$00,usb_endp		; �G���h�|�C���g = 0
		move.b	#18,usb_length		; �f�[�^�]���� = 18
		lea.l	Buf_StdDescriptor(pc),a0
		move.l	a0,usb_buf_address	; �f�o�C�X�f�B�X�N���v�^��ǂݍ��ރA�h���X

		jbsr	_GetDeviceDescriptor	; �f�o�C�X�f�B�X�N���v�^�擾
		tst.b	d0
		bne	err_exit

		_StrPrint2	'������Ɏ擾�ł��܂���',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------


		; ���I�v�V������Microsoft Xbox 360 �n��Controller���w�肳��Ă��邩���ׂ�
		;   (��Windows�ł���p�h���C�o���K�v)

		tst.b	optflg_X
		beq	@f

		; Xbox360��p���[�`�������s
		move.b	#3,Class		; 
		move.b	#0,SubClass		; 
		move.b	#0,Protocol		; 

		move.b	#8,MaxPacketSizeL	; 
		move.b	#0,MaxPacketSizeH	; 
		move.b	#1,bInterval		; 
		jbra	@@f

	@@:
		_StrPrint2	'���R���t�B�M�����[�V�����f�B�X�N���v�^�̉��擾',cr,lf

		; ���R���t�B�M�����[�V�����f�B�X�N���v�^���擾

		move.b	#$01,usb_addr		; �A�h���X = 1
		move.b	#$00,usb_endp		; �G���h�|�C���g = 0
		move.b	#9,usb_length		; �f�[�^�]���� = 9
		lea.l	Buf_CnfDescriptor(pc),a0
		move.l	a0,usb_buf_address	; �R���t�B�M�����[�V�����f�B�X�N���v�^��ǂݍ��ރA�h���X
		jbsr	_GetConfiguration	; �R���t�B�M�����[�V�����f�B�X�N���v�^�擾
		tst.b	d0
		bne	err_exit

		; ���ݑΏۊO�̃f�o�C�X�Ȃ�풓�����ɏI��
		;(���擾�Ȃ̂�TotalLength�݂̂̊ȈՃ`�F�b�N)

; -------- patch +z1 --------
;		cmpi.b	#34,TotalLengthL	; TotalLength��34�o�C�g�̃f�o�C�X�̂ݑΏ�
;		bne	no_joypad		; 
		cmpi.b	#34,TotalLengthL	; TotalLength��34�o�C�g�̃f�o�C�X�͑Ώ�
		beq	@f
		tst.b	optflg_Z		; -z�I�v�V�����w�肳��Ă��Ȃ���΂���ȊO�͑ΏۊO
		beq	no_joypad
		cmpi.b	#41,TotalLengthL	; -z�I�v�V�����w�肳��Ă����TotalLength��41�o�C�g�̃f�o�C�X���Ώ�
		bne	no_joypad		; 
	@@:
; ---------------------------
  	        tst.b	TotalLengthH		; 
		bne	no_joypad		; 

		_StrPrint2	'������Ɏ擾�ł��܂���',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'���R���t�B�M�����[�V�����f�B�X�N���v�^�̎擾',cr,lf

		; ���R���t�B�M�����[�V�����f�B�X�N���v�^�擾

		move.b	#$01,usb_addr		; �A�h���X = 1
		move.b	#$00,usb_endp		; �G���h�|�C���g = 0
; -------- patch +z1 --------
;		move.b	#34,usb_length		; �f�[�^�]���� = 34
		move.b	TotalLengthL,usb_length ; �f�[�^�]���� = 34 �܂��� 41
; ---------------------------
  	   	lea.l	Buf_CnfDescriptor(pc),a0
		move.l	a0,usb_buf_address	; �R���t�B�M�����[�V�����f�B�X�N���v�^��ǂݍ��ރA�h���X
		jbsr	_GetConfiguration	; �R���t�B�M�����[�V�����f�B�X�N���v�^�擾
		tst.b	d0
		bne	err_exit

		; ���ݑΏۊO�̃f�o�C�X�Ȃ�풓�����ɏI��

		move.l	Class,d0
		andi.l	#$ffffff00,d0
		cmpi.l	#$03_00_00_00,d0	; �ڑ�����Ă���HID�͕W���I�ȃW���C�p�b�h���H
		beq	@f

		cmpi.l	#$03_01_02_00,d0	; �ڑ�����Ă���HID�͕W���I�ȃ}�E�X���H
		bne	no_joypad
@@:
; -------- patch +z1 --------
		tst.b	optflg_Z
		beq	@@f			; -z�I�v�V�����w�肪�Ȃ���Ή������Ȃ�
		btst.b	#8,EndPointAddr		; �ŏ��̃G���h�|�C���g��IN���H
		bne	@f			; 8bit�ڂ�1����IN
		movem.l	a0-a1,-(sp)
		lea.l	EndPoint1,a0		; OUT�������ꍇ��2�ڂ̃G���h�|�C���g�̓��e���R�s�[����
		lea.l	EndPoint2,a1
		move.b	(a1)+,(a0)+	
		move.b	(a1)+,(a0)+	
		move.b	(a1)+,(a0)+	
		move.b	(a1)+,(a0)+	
		move.b	(a1)+,(a0)+	
		move.b	(a1)+,(a0)+	
		move.b	(a1)+,(a0)+
		movem.l	(sp)+,a0-a1
@@:
		move.b	#8,MaxPacketSizeL	; �����MaxPacketSize�������I��8�ɂ���(�Ђǂ�)
@@:
; ---------------------------
		; �G���h�|�C���g�P�̃p�P�b�g�T�C�Y���X�ȏ�Ȃ�Ζ��Ή�
		cmpi.b	#$08,MaxPacketSizeL
		bhi	no_joypad		

		_StrPrint2	'������Ɏ擾�ł��܂���',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'���R���t�B�M�����[�V�����ݒ�',cr,lf

		; ���R���t�B�M�����[�V�����ݒ�

		move.b	#$01,usb_addr		; �A�h���X = 1
		move.b	#$00,usb_endp		; �G���h�|�C���g = 0
		lea.l	Buf_StdDescriptor(pc),a0
		move.l	a0,usb_buf_address	; 

		jbsr	_SetConfiguration	; �R���t�B�M�����[�V�����ݒ�
		tst.b	d0
		bne	err_exit

		_StrPrint2	'������ɐݒ�ł��܂���',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#100*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

	; ���ڑ�����Ă���̂��W���C�p�b�h�Ȃ�΁A�v���g�R���ݒ�͂��Ȃ�
		tst.b	Protocol
		beq	9f

		_StrPrint2	'���v���g�R���ݒ�',cr,lf

		; ���v���g�R���ݒ�

		move.b	#$01,usb_addr		; �A�h���X = 1
		move.b	#$00,usb_endp		; �G���h�|�C���g = 0
		move.b	#0,usb_protocol		; �v���g�R�� = 0

		jbsr	_SetProtocol		; �v���g�R���ݒ�

		; Set Protocol�̌��ʂ͖���
	9:

	;---------------------------------------------------------------------

	; ���ڑ�����Ă���̂��W���C�p�b�h�ȊO�Ȃ�΁A��`�t�@�C���͎g�p���Ȃ�
		tst.b	Protocol
		bne	9f

	; ���擾�����x���_�[�h�c�����ɒ�`�t�@�C������������
		jbsr	GetUsbPadInfo
		bmi	8f
		bne	err_exit

	; ���p�P�b�g�T�C�Y���w�肳��Ă�����(0�ȊO)��`�f�[�^�ŏ㏑��
		tst.b	PSIZE
		beq	@f
		move.b	PSIZE,MaxPacketSizeL
	@@:
	; ���C���^���v�g�]���̎������w�肳��Ă�����(0�ȊO)��`�f�[�^�ŏ㏑��
		tst.b	INTR
		beq	@f
		move.b	INTR,bInterval
	@@:
	; �����|�[�g�h�c���i�[
		move.b	REPID,usb_report_id
	@@:
		jbsr	ChkUsbPadInfo
		bne	err_exit
	8:
	; �����ȏ���
		jbsr	WriteUsbPadInfo
	9:
	;---------------------------------------------------------------------
	movem.l	(sp)+,d0-d7/a0-a6

	; ���ڑ�����Ă���̂��W���C�p�b�h�Ȃ�΁AIOCS_JOYGET��u��������
		tst.b	Protocol
		bne	@f

		movem.l	d0-d1/a1,-(sp)
		move.w	#$013B,d1			; d1 = _JOYGET��u��������
		lea.l	usb_joy_vct(pc),a1		; a1 = �����A�h���X
		IOCS	_B_INTVCS			; ���荞�݃n���h���� neq_joy_vct �ɐݒ�
		move.l	d0,old_joy_vct			; ���̊��荞�݃A�h���X�����܂�
		movem.l	(sp)+,d0-d1/a1
	@@:
		move.l	d0,a1				; 
		IOCS	_B_SUPER			; ���[�h�����ɖ߂�

	; ���풓���b�Z�[�W�̕\��
		tst.b	Protocol			; 
		bne	1f				; 
		pea	stay_msg_joy			; '�W���C�p�b�h���[�h�풓���܂���.'
		bra.b	9f				; 
	1:						; 
		pea	stay_msg_mouse			; '�}�E�X���[�h�ŏ풓���܂���.'
	9:						; 
		DOS	_PRINT				; 

	; ���ȉ��O����

		move.b	#$01,usb_addr			; �A�h���X = 1
		move.b	#$01,usb_endp			; �G���h�|�C���g = 1
		move.b	MaxPacketSizeL,usb_length	; �f�[�^�]���� = ?

		move.b	bInterval,usb_interrupt_count	; �C���^���v�g�]�����荞�ݎ������Z�b�g
		move.b	#1,usb_interrupt_flg		; �C���^���v�g�]���J�n�t���O = ����

	; ���I�v�V���������w�肳��Ă�����p�P�b�g�`�F�b�N���[�h

		tst.b	optflg_C			; 
		beq	@f				; 

		clr.l	a1				; 
		IOCS	_B_SUPER			; �X�[�p�[�o�C�U���[�h�ɂ���

	movem.l	d0-d7/a0-a6,-(sp)			; ���W�X�^�ޔ�

		move.b	#2,d1				; 
		IOCS	_B_CLR_ST			; �e�L�X�g��ʂ̏�����
	;----------------------------------------------
		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; ���F(����)

		_StrPrint	'VID   : '		; VID�̕\��

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; ���F

		move.w	VendorID,d0			; 
		rol.w	#8,d0				; �G���f�B�A���ϊ�
		jbsr	hex_print_w			; �l�̕\��

		_StrPrint	cr,lf
	;----------------------------------------------
		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; ���F(����)

		_StrPrint	'PID   : '		; PID�̕\��

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; ���F

		move.w	ProductID,d0			; 
		rol.w	#8,d0				; �G���f�B�A���ϊ�
		jbsr	hex_print_w			; �l�̕\��

		_StrPrint	cr,lf
	;----------------------------------------------
		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; ���F(����)

		_StrPrint	'PSIZE : '		; PSIZE�̕\��

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; ���F

		clr.w	d0				; 
		move.b	MaxPacketSizeL,d0		; 
		jbsr	hex_print_b_sp			; �l�̕\��

		_StrPrint	cr,lf
	;----------------------------------------------
		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; ���F(����)

		_StrPrint	'INTR  : '		; INTR�̕\��

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; ���F

		clr.w	d0				; 
		move.b	bInterval,d0			; 
		jbsr	hex_print_b_sp			; �l�̕\��

		_StrPrint	cr,lf
	;----------------------------------------------
		move.w	#1,d1				; 
		IOCS	_B_COLOR			; ���F(����)

		move.w	#0,d1				; 
		move.w	#8,d2				; 
		IOCS	_B_LOCATE			; �ʒu�w��

		_StrPrint	'Push ESC to exit.'	; �I�����@�̕\��

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; ���F

		move.w	#0,d1				; 
		move.w	#4,d2				; 
		IOCS	_B_LOCATE			; �ʒu�w��

		move.w	#2+4,d1				; 
		IOCS	_B_COLOR			; �F���F

		_StrPrint	'-------------------------------------',cr,lf
		_StrPrint	'              00 01 02 03 04 05 06 07',cr,lf

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; �e�L�X�g��ʂ̏�����
	1:
		move.w	#0,d1				; 
		move.w	#6,d2				; 
		IOCS	_B_LOCATE			; �ʒu�w��

		move.l	#10*20,d1			; 10ms�҂�
		jbsr	delay50ns			; 

		jbsr	print_Buf_Work			; �C���^���v�g�]�����ꂽ�o�b�t�@�̓��e��\��

		move.w	#0,d1				; 
		move.w	#8,d2				; 
		IOCS	_B_LOCATE			; �ʒu�w��

		btst.b	#1,$800				; 
		bne	program_exit			; �d�r�b�L�[�������ꂽ��I��
		bra	1b
	@@:
		move.w	#0,-(sp)			; �I���R�[�h = 0
		move.l	#tsr_bottom-tsr_top,-(sp)	; �풓�o�C�g�� = tsr_bottom-tsr_top
		DOS	_KEEPPR				; �풓�I��

err_exit:
		jbsr	print_return_code
		_StrPrint	'�ݒ�Ɏ��s���܂���.',cr,lf
		bra	program_exit

no_joypad:
		jbsr	print_return_code
		_StrPrint	'�ΏۊO�̃f�o�C�X���ڑ�����Ă��܂�.',cr,lf

;---------------------------------------------------------------------------
; �G���[���Ȃǂ̏I������
;---------------------------------------------------------------------------

program_exit:

	; �I�������̍ŗǂ̕��@�͕s�m��

		jbsr	CmdNereidIntOff			; nereid int off
		move.l	#2*20,d1			; 2ms�҂�
		jbsr	delay50ns

		move.w	#100,d7
	@@:
		move.b	#REG_INT_STATUS,SL811HST_ADDR	; ���荞�݃X�e�[�^�X���W�X�^
		move.b	#$FF,SL811HST_DATA		; �S���荞�݃t���O���Z�b�g
		dbra	d7,@b

		move.b	#$06,SL811HST_ADDR		; ���荞�݃C�l�[�u�����W�X�^
		move.b	#$00,SL811HST_DATA		; �S�^�C�}���荞�݂��֎~

	move.l	#10*20,d1				; 10ms�҂�
	jbsr	delay50ns

		jbsr	CmdNereidPowerOff		; nereid power off
		jbsr	CmdNereidResetOn		; nereid reset on

		move.w	#$FB,d1				; 
		movea.l	old_int,a1			; 
		IOCS	_B_INTVCS			; ���荞�݃n���h�������ɖ߂�

	movem.l	(sp)+,d0-d7/a0-a6			; ���W�X�^���A

;		move.l	old_mouse_vct,$150
;		move.l	old_mouse_vct,$154

		move.l	d0,a1				; 
		IOCS	_B_SUPER			; ���[�h�����ɖ߂�

		_exit
no_device:
		_StrPrint	'�f�o�C�X���ڑ�����Ă��܂���',cr,lf
		jbra	program_exit

		.data
;-----------------------------------------------------------
; ���b�Z�[�W�֘A�̃f�[�^
;-----------------------------------------------------------
		.even
title_msg:
		.dc.b	'USB JoyPad & Mouse Driver USBJOY ver.1.3e+z1 (C)2006-2009 plastic / akuzo / tantan',13,10,0
stay_msg_joy:
		.dc.b	'�W���C�p�b�h���[�h�ŏ풓���܂���.',13,10,0
stay_msg_mouse:
		.dc.b	'�}�E�X���[�h�ŏ풓���܂���.',13,10,0
rel_msg:
		.dc.b	'�풓�������܂���.',13,10,0
usage_msg:
		.dc.b	'usage : usbjoy [-opt1] [-opt2]���',13,10
		.dc.b	'  -a1 : �V���N���A��(1frame���Ƀ{�^����ON/OFF��؂�ւ�)',13,10
		.dc.b	'  -a2 : �V���N���A��(2frame���Ƀ{�^����ON/OFF��؂�ւ�)',13,10
		.dc.b	'  -c  : �G���h�|�C���g����̃p�P�b�g���e�`�F�b�N���[�h',13,10
		.dc.b	'  -h  : �w���v�\��',13,10
; -------- patch +z1 --------
;		.dc.b	'  -x  : Xbox 360�n�̃R���g���[�����g�p����ꍇ�Ɏw��',13,10,0
		.dc.b	'  -x  : Xbox 360�n�̃R���g���[�����g�p����ꍇ�Ɏw��',13,10
 	   	.dc.b   '  -z  : ZUIKI X68000 Z JOYCARD ���g�p����ꍇ�Ɏw��',13,10,0
; ---------------------------

		.even
def_filename:
		.dc.b	'usbjoy.def',0	; ��`�t�@�C����
*---------------------------------------------------------------------------------------
		.bss									
*---------------------------------------------------------------------------------------
filename:
		.ds.b	256		; �p�X�{��`�t�@�C�������i�[���邽�߂̃��[�N

		.even
handle:
		.ds.w	1		; �t�@�C���n���h�����i�[���邽�߂̃��[�N

		.align	4
FileSize:
		.ds.l	1		; �擾�����t�@�C���T�C�Y���i�[

		.even
WorkBuffer:
		.ds.b	32768+4		; ��`�t�@�C���S�̂�ǂݍ��ނ��߂̃��[�N
		.even
UsbPadInfo:
VID:		.ds.w	1		;
PID:		.ds.w	1		;
LKEY:		.ds.w	1		;
RKEY:		.ds.w	1		;
UKEY:		.ds.w	1		;
DKEY:		.ds.w	1		;
LBTN1:		.ds.w	1		;
RBTN1:		.ds.w	1		;
LBTN2:		.ds.w	1		;
RBTN2:		.ds.w	1		;
PSIZE:		.ds.b	1		;
INTR:		.ds.b	1		;
REPID:		.ds.b	1		;

end		Startup

