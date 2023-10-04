;==============================================================
;==============================================================
;
;
;　　　　USB JoyPad & Mouse Driver USBJOY ver.1.3e+z1
;
;　　　　　　　　Copyright (C)2006-2009 by ぷらすちっく/あく蔵
;                          (C)2013 by tantan
;
;==============================================================
;==============================================================

.68000

;--------------------------------------------------------------
; リリース時は全て０でアセンブル
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

tsr_top:	; この位置からメモリに常駐します

		.dc.b	'$USBJOY$'	; 常駐判定用の文字列

		.align	4
old_mouse_vct:
		.dc.l	0		; 常駐前の受信キャラクタ有効(マウス１バイト入力)
old_joy_vct:
		.dc.l	0		; 常駐前のIOCS _JOYGETのアドレス
old_int:
		.dc.l	0		; 常駐前の$FBのアドレス
int_count:
		.dc.l	0		; 割り込み回数カウンタ
host_usb_speed:
		.dc.b	0		; 接続したUSB機器の速度

;-----------------------------------------------------------
; USB関連ワーク
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
		.dc.b	0	; 送受信パケットサイズ

usb_packet_size_old:
		.dc.b	0	; 送受信パケットサイズ

usb_rest_size:
		.dc.b	0	; ＩＮ転送データ転送残りバイト数取得用変数

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
		.dc.w	0	; NAKの最大リトライ回数

retry_nak_count:
		.dc.w	0	; NAKのリトライ回数

usb_interrupt_count:
		.dc.b	0	; インタラプト転送の周期計測用カウンタ

usb_interrupt_flg:
		.dc.b	0	; インタラプト転送開始フラグ

usb_report_id:
		.dc.b	$ff	; リポートＩＤのバイト位置($ffなら未使用)

old_mouse_button_status:
		.dc.b	0	; 前回のマウスボタンの状態

mouse_dpi_half_flg:
		.dc.b	0	; dpiを半分にするフラグ

;-----------------------------------------------------------
; オプションフラグ
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
; セットアップパケット関連のデータ(USBJOYで必要なのは５つ)
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
		.ds.b	32	; セットアップパケット表示用のワーク
.endif

;-----------------------------------------------------------
; メッセージ関連のデータ
;-----------------------------------------------------------
		.even
msg_sl811hst_rev:
		.dc.b	'SL811HST USB Chip Revision.1.'
chip_revision:
		.dc.b	'2',cr,lf,0

;-----------------------------------------------------------
; 取得したディスクリプタを格納するワーク
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

;以下はジョイパッド・マウスの場合のみ

		.ds.b	5		; 9Byte
Class:		.ds.b	1		; <- この位置は必ずlong境界
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
EndPointAddr:   .ds.b	1		; IN/OUT判定用
MaxPacketSizeL:	.ds.b	1		; 
MaxPacketSizeH:	.ds.b	1		; 
bInterval	.ds.b	1		; 

EndPoint2:
		.ds.b	7		; 7Byte ZUIKIパッドはEndPointが2つある
; ---------------------------

		.align	4
Buf_Work:
		.ds.b	16		; 16Byte

;-----------------------------------------------------------------------------
; ジョイスティック１の代わりにＵＳＢに接続されたジョイパッドからのデータを返す
;-----------------------------------------------------------------------------

		.even
usb_joy_vct:
		cmpi.w	#1,d1				; d1.w = ジョイスティック番号
		bhi	joy_err_exit			; ０でも１でもない場合
		beq	joy1				; １の場合
	joy0:
		move.l	a0,-(sp)

		move.w	d1,d0				; 
		lsl.w	#3,d0				; 

		lea.l	joy_data0(pc),a0		; 
		lea.l	(a0,d0.w),a0			; 

		clr.l	d0				; 戻り値を初期化
		move.b	(a0),d0				; 

		tst.b	auto_flg			; シンクロ連射オプションが指定されているか？
		bne	@f				; 

		btst.l	#4,d0				; 連射ボタンが押されているか？
		bne	1f				; 押されていない場合
		bclr.l	#5,d0
	1:
		btst.l	#7,d0				; 連射ボタンが押されているか？
		bne	1f				; 押されていない場合
		bclr.l	#6,d0
	1:
		or.b	#%10010000,d0
		move.l	(sp)+,a0
		rts
	@@:
		btst.l	#4,d0				; 連射ボタンが押されているか？
		beq	1f				; 押されている場合
		move.w	#$0020,auto_int_cnt_a(a0)	; 押されていなければシンクロカウンタをクリアしておく
		bra.b	4f				; 
	1:
		cmpi.b	#$01,auto_flg			; -a1オプションが指定されているか？
		beq	2f
		add.b	#1,auto_int_cnt_a(a0)		; シンクロカウンタ＋１

	; このあとのバージョンで自己書換の対象
		btst.b	#$00,auto_int_cnt_a(a0)		; $0828,$0002,$0001
		beq	3f
	2:
		bchg.b	#5,auto_data_a(a0)
	3:
		andi.b	#%1101_1111,d0
		or.b	auto_data_a(a0),d0
	4:
		btst.l	#7,d0				; 連射ボタンが押されているか？
		beq	1f				; 押されている場合
		move.w	#$0040,auto_int_cnt_b(a0)	; 押されていなければシンクロカウンタをクリアしておく
		bra.b	4f				; 
	1:
		cmpi.b	#$01,auto_flg			; -a1オプションが指定されているか？
		beq	2f
		add.b	#1,auto_int_cnt_b(a0)		; シンクロカウンタ＋１

	; このあとのバージョンで自己書換の対象
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

		clr.l	d0				; 戻り値を初期化
		move.b	$00e9a003,d0			; ジョイスティックポート２のデータを取得
		rts
joy_err_exit:
		clr.l	d0				; 戻り値を初期化
		rts

		.even
joy_data0:
		.dc.b	$ff	; インタラプト転送で取得されたジョイパッドのデータが編集後格納されているワーク
		.dc.b	$00,$00,$00,$00,$00,$00,$00
joy_data1:
		.dc.b	$ff	; インタラプト転送で取得されたジョイパッドのデータが編集後格納されているワーク
		.dc.b	$00,$00,$00,$00,$00,$00,$00
auto_flg:
		.dc.b	$00

		.even

; ■インタラプトＩＮ転送
_GetInterrupt:
		move.b	usb_length,usb_total_size

		move.b	usb_payload,d0
		cmp.b	usb_total_size,d0		; total_size < payload
		bcc	1f
		move.b	usb_payload,usb_packet_size	; 取得バイト数 = payload
		bra.b	2f
	1:
		move.b	usb_total_size,usb_packet_size	; 取得バイト数 = payload
	2:
		jbsr	_USB_int

		rts

; ■コンフィギュレーション設定
_SetConfiguration:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		lea.l	cset_config(pc),a0		; 
		move.l	a0,usb_packet_address		; 送信パケットアドレス

		move.b	#8,usb_packet_size		; データの転送長(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK または ERRならば終了

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

		;move.b	usb_length,usb_total_size
		move.b	#0,usb_total_size

		jbsr	_USB_in

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
		jbsr	print_rest_size
	9:
		rts

; ■デバイスアドレス設定
_SetDeviceAddress:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		lea.l	cset_address(pc),a0		; 
		move.l	a0,usb_packet_address		; 送信パケットアドレス

		move.b	#8,usb_packet_size		; データの転送長(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK または ERRならば終了

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

	;	move.b	usb_length,usb_total_size
		move.b	#0,usb_total_size

		jbsr	_USB_in

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
		jbsr	print_rest_size
	9:
		rts

; ■コンフィギュレーション取得
_GetConfiguration:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		move.b	usb_length,config_size		; 取得したいデータのバイト数をセット

		lea.l	cget_config(pc),a0
		move.l	a0,usb_packet_address		; 送信パケットアドレス

		move.b	#8,usb_packet_size		; データの転送長(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK または ERRならば終了

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

		move.b	usb_length,usb_total_size

		jbsr	_USB_in
		bne	9f				; NAK または ERRならば終了

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
		jbsr	print_rest_size
	.if (CNF_DESCRIPTOR_PRINT=1)
		jbsr	print_CnfDescriptor
	.endif
	;---------------------------------------------------------------------
		move.b	#0,usb_packet_size		; データの転送長(1byte)
		;move.b	#0,usb_total_size

		jbsr	_USB_out
		bne	9f				; NAK または ERRならば終了

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
	9:
		rts

; ■デバイスディスクリプタ取得
_GetDeviceDescriptor:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		move.b	usb_length,desc_dev_count	; 取得したいデータのバイト数をセット

		lea.l	cget_desc_dev(pc),a0		; 
		move.l	a0,usb_packet_address		; 送信パケットアドレス

		move.b	#8,usb_packet_size		; データの転送長(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK または ERRならば終了

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

		move.b	usb_length,usb_total_size

		jbsr	_USB_in
		bne	9f				; NAK または ERRならば終了

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
		jbsr	print_rest_size
	.if (STD_DESCRIPTOR_PRINT=1)
		jbsr	print_StdDescriptor		; ディスクリプタの表示
	.endif
	;---------------------------------------------------------------------
		move.b	#0,usb_packet_size		; データの転送長(1byte)
		;move.b	#0,usb_total_size

		jbsr	_USB_out
		bne	9f				; NAK または ERRならば終了

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
	9:
		rts

; ■プロトコル設定
;---------------------------------------------------------------------
;	SETUP	DATA0
;	IN	DATA1
_SetProtocol:
	;---------------------------------------------------------------------
		move.b	#DATA0_WR,usb_wr_cmd

		move.b	usb_protocol,set_protocol_value	; 

		lea.l	cset_protocol(pc),a0		; 
		move.l	a0,usb_packet_address		; 送信パケットアドレス

		move.b	#8,usb_packet_size		; データの転送長(1byte)

		jbsr	_USB_setup
		bne	9f				; NAK または ERRならば終了

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
	.if (SETUP_PACKET_PRINT=1)
		jbsr	print_setup_packet
	.endif
	;---------------------------------------------------------------------
		move.b	#DATA1_RD,usb_rd_cmd

		move.b	#0,usb_packet_size		; データの転送長(1byte)

		jbsr	_USB_in

		jbsr	print_return_code
		jbsr	print_last_status		; 最終ステータスレジスタの表示
	9:
		rts

_USB_setup:

	; ■ＳＥＴＵＰコマンド

.if (SOF_PRINT=1)
	_StrPrint	' SOF = '
		move.l	int_count,d0
		jbsr	hex_print_w
	_StrPrint	' : CMD = SETUP : ADR = '
		move.b	usb_addr,d0
		jbsr	hex_print_b_sp
.endif
		move.w	retry_nak_max_count,d7		; NAKの最大リトライ回数をセット
	@@:
		move.b	#CMD_SETUP,usb_send_cmd		; コマンド = SETUPコマンド
		jbsr	wait_command			; コマンド終了待ち

		btst.b	#STS_ACK,usb_last_statusA	; ACKが返ってきたか？
		bne	SETUP_ACK			; 返ってきた場合

		btst.b	#STS_NAK,usb_last_statusA	; NAKが返ってきたか？
		beq	SETUP_ERR			; ACKもNAKも返ってこなかった場合

		dbra	d7,@b

	;_StrPrint	' SETUP:最大リトライ回数を越えました',13,10

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

	; ■ＩＮコマンド

.if (SOF_PRINT=1)
	_StrPrint	' SOF = '
		move.l	int_count,d0
		jbsr	hex_print_w
	_StrPrint	' : CMD = IN    : ADR = '
		move.b	usb_addr,d0
		jbsr	hex_print_b_sp
.endif
		move.b	#CMD_IN,usb_send_cmd		; コマンド = INコマンド
		jbsr	wait_command			; コマンド終了待ち

		btst.b	#STS_ACK,usb_last_statusA	; ACKが返ってきたか？
		bne	IN_ACK				; 返ってきた場合

		btst.b	#STS_NAK,usb_last_statusA	; NAKが返ってきたか？
		beq	IN_ERR				; ACKもNAKも返ってこなかった場合
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

	; ■ＩＮＴコマンド

		move.b	#CMD_INT,usb_send_cmd		; コマンド = INTERRUPTコマンド
		jbsr	_Intr_1ms_sub

		btst.b	#STS_ACK,usb_last_statusA	; ACKが返ってきたか？
		bne	IN2_ACK				; 返ってきた場合

		btst.b	#STS_NAK,usb_last_statusA	; NAKが返ってきたか？
		beq	IN2_ERR				; ACKもNAKも返ってこなかった場合
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

	; ■ＯＵＴコマンド

.if (SOF_PRINT=1)
	_StrPrint	' SOF = '
		move.l	int_count,d0
		jbsr	hex_print_w
	_StrPrint	' : CMD = OUT   : ADR = '
		move.b	usb_addr,d0
		jbsr	hex_print_b_sp
.endif
		move.w	retry_nak_max_count,d7		; NAKの最大リトライ回数をセット
	@@:
		move.b	#CMD_OUT,usb_send_cmd		; コマンド = SETUPコマンド
		jbsr	wait_command			; コマンド終了待ち

		btst.b	#STS_ACK,usb_last_statusA	; ACKが返ってきたか？
		bne	OUT_ACK				; 返ってきた場合

		btst.b	#STS_NAK,usb_last_statusA	; NAKが返ってきたか？
		beq	OUT_ERR				; ACKもNAKも返ってこなかった場合

		dbra	d7,@b

	;_StrPrint	' OUT:最大リトライ回数を越えました',13,10

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
; SL811HST１ｍｓ割り込みルーチン
;--------------------------------------
		.even
_Intr_1ms:

;		ori.w	#$0700,sr			; 割り込みマスクに変更(ver.1.0)

		movem.l	d0-d7/a0-a6,-(sp)

;		; 割り込みマスクの設定			; 割り込みマスクを削除(1.1a)
;		lea.l	$E88012,a4			; 
;		move.l	(a4),d4				; 割り込み中にd4の値が変わることはありえません
;		move.b	#%11000000,1(a4)		; X68000側の割り込みマスクの設定
;		move.b	#%01000000,3(a4)		; X68000側の割り込みマスクの設定

		lea.l	SL811HST_ADDR,a5		; 割り込み中はクロック削減のためにレジスタa5とa6でSL811のレジスタをアクセスします
		lea.l	SL811HST_DATA,a6		; 割り込み中にa5とa6の値が変わることはありえません

		move.b	#$06,SL811_ADDR_REG
		move.b	#$00,SL811_DATA_REG

		bsr	_Intr_1ms_sub

		addq.l	#1,int_count			; 割り込みの回数カウンタ(ただ表示するだけで基本的に不要なもの)

	;インタラプト転送開始フラグが許可されているか？
		tst.b	usb_interrupt_flg		; 
		beq	@f				; 
		subi.b	#1,usb_interrupt_count		; 
		bne	@f				; 
		move.b	bInterval,usb_interrupt_count	; インタラプト転送割り込み周期をセット

	;	↓どうせ変わらないのでクロック削減
	;	move.b	#$01,usb_addr			; アドレス = 1
	;	move.b	#$01,usb_endp			; エンドポイント = 1
	;	move.b	MaxPacketSizeL,usb_length	; データ転送長 = ?

		lea.l	Buf_Work(pc),a0			; 
		move.l	a0,usb_buf_address		; データを読み込むアドレス

		move.w	#0,retry_nak_max_count		; NAKの最大リトライ回数をセット

		jbsr	_GetInterrupt			; インタラプト転送ルーチン
		tst.b	d0				; 
		.dc.w	$6100
branch_address:
		.dc.w	mouse_data_conv-branch_address	; 自己書換
	@@:
		move.b	#REG_INT_STATUS,SL811HST_ADDR	; 割り込みステータスレジスタ
		move.b	#$FF,SL811HST_DATA		; 全割り込みフラグリセット

		move.b	#$06,SL811_ADDR_REG
		move.b	#$10,SL811_DATA_REG

;		move.l	d4,(a4)				; X68000の割り込みマスクを元に戻す

		movem.l	(sp)+,d0-d7/a0-a6

		rte

;--------------------------------------
; SL811HST１ｍｓ割り込みルーチンサブ
;--------------------------------------
		.even
_Intr_1ms_sub:
		cmpi.b	#CMD_IN,usb_send_cmd		; コマンド = INコマンド
		bne	9f
	1:
		move.w	retry_nak_max_count,retry_nak_count	; NAKのリトライ回数をセット
	2:
		move.b	usb_payload,d0
		cmp.b	usb_total_size,d0		; total_size < payload
		bcc	3f
		move.b	usb_payload,usb_packet_size	; 取得バイト数 = payload
		bra.b	4f
	3:
		move.b	usb_total_size,usb_packet_size	; 取得バイト数 = payload
	4:
		jbsr	_Intr_1ms_sub_main

		btst.b	#STS_ACK,usb_last_statusA	; ACKが返ってきたか？
		bne	RET_ACK				; 返ってきた場合

		btst.b	#STS_NAK,usb_last_statusA	; NAKが返ってきたか？
		bne	RET_NAK				; 返ってきた場合
		bra.b	RET_ERR
	RET_ACK:
		bchg.b	#6,usb_rd_cmd			; DATA0/DATA1トグル
		tst.b	usb_total_size
		bne	1b
		clr.b	usb_send_cmd			; コマンドクリア
		rts
	RET_NAK:
		subi.w	#1,retry_nak_count
		bne	2b
	RET_ERR:
		clr.b	usb_send_cmd			; コマンドクリア
		rts

	9:
		jbsr	_Intr_1ms_sub_main
		clr.b	usb_send_cmd			; コマンドクリア
		rts

;-------------------------------------------------
; SL811HST１ｍｓ割り込みルーチンサブルーチンメイン
;-------------------------------------------------
		.even
_Intr_1ms_sub_main:

		tst.b	usb_send_cmd			; コマンドパケットが発行されているか？
		beq	_Intr_1ms_exit_nopacket		; されていなければ終了

		GET_INT_TIME_START

		cmpi.b	#CMD_SETUP,usb_send_cmd
		bne	CHK_CMD_IN

		; ■SETUPパケットをSL811HSTのメモリに転送
			move.b	#EP0BUF,SL811_ADDR_REG

			move.l	usb_packet_address,a0
			movea.l	#SL811HST_DATA,a1

			move.w	#8-1,d7
		@@:	move.b	(a0)+,(a1)
			dbra	d7,@b

		; ■セットアップパケットの内容を表示したい時だけアセンブル
.if (SETUP_PACKET_PRINT=1)
			lea.l	print_packet_work(pc),a0	; 
			move.b	#EP0BUF,SL811_ADDR_REG		; SL811HSTメモリアドレス
			move.w	#8-1,d7				; 
		@@:
			move.b	SL811_DATA_REG,(a0)+		; 
			dbra	d7,@b				; 
.endif
		;---------------------------------------------------------

		; ■データ転送用のデータが格納されているポインタをセット

			move.b	#REG_BASE_ADR_A,SL811_ADDR_REG	; USB-Aホストベースアドレスレジスタ($01)
			move.b	#EP0BUF,SL811_DATA_REG		; SL811HST内メモリースタート位置

		; ■データの転送長をセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_XLEN_A,SL811_ADDR_REG	; USB-Aホストベースデータ長レジスタ($02)
			move.b	usb_packet_size,SL811_DATA_REG	; データの転送長(1byte)

		; ■パケットID ＆ エンドポイントをセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_PID_ENDP_A,SL811_ADDR_REG	; USB-AのパケットID(上位4bit)とエンドポイントレジスタ(下位4bit)($03)
			move.b	usb_endp,d0			; エンドポイント = $0?
			ori.b	#PID_SETUP,d0			; パケットID = PID_SETUP($D0)
			move.b	d0,SL811_DATA_REG		; 

		; ■USBアドレスをセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_ADDR_A,SL811_ADDR_REG	; USB-Aホストアドレスレジスタ($04)
			move.b	usb_addr,SL811_DATA_REG		; USBアドレス = $??(0～127)

		; ■全割り込みステータスクリア
			move.b	#$0d,SL811_ADDR_REG		; 割り込みステータスレジスタ
			move.b	#$ff,SL811_DATA_REG		; 全割り込みステータスクリア

		; ■EOP(Alive)を送信(ハブにロースピードデバイスを接続している時のみ)
		;	bsr	eop

		; ■OUT方向、エンドポイントへの転送許可、転送許可(0000_0111b)
			move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-Aホストコントロールレジスタ
			move.b	usb_wr_cmd,SL811_DATA_REG	; 転送許可

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

		; ■データ転送用のデータが格納されているポインタをセット
			move.b	#REG_BASE_ADR_A,SL811_ADDR_REG	; USB-Aホストベースアドレスレジスタ($01)
			move.b	#EP0BUF,SL811_DATA_REG		; SL811HST内メモリースタート位置

		; ■データの転送長をセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_XLEN_A,SL811_ADDR_REG	; USB-Aホストベースデータ長レジスタ($02)
			move.b	usb_packet_size,SL811_DATA_REG	; データの転送長(1byte)

		; ■パケットID ＆ エンドポイントをセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_PID_ENDP_A,SL811_ADDR_REG	; USB-AのパケットID(上位4bit)とエンドポイントレジスタ(下位4bit)
			move.b	usb_endp,d0			; エンドポイント = $0?
			ori.b	#PID_IN,d0			; パケットID = PID_IN($90)
			move.b	d0,SL811_DATA_REG		; 

		; ■USBアドレスをセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_ADDR_A,SL811_ADDR_REG	; USB-Aホストアドレスレジスタ
			move.b	usb_addr,SL811_DATA_REG		; USBアドレス = $??(0～127)

		; ■EOP(Alive)を送信(ハブにロースピードデバイスを接続している時のみ)
		;	bsr	eop

		; ■全割り込みステータスクリア
			move.b	#$0d,SL811_ADDR_REG		; 割り込みステータスレジスタ
			move.b	#$ff,SL811_DATA_REG		; 全割り込みステータスクリア

		; ■IN方向、エンドポイントへの転送許可、転送許可(0010_0011b)
	;		move.b	usb_rd_cmd,d0
	;		tst.b	host_usb_speed			; ロースピード(host_usb_speed = SPEED_LOW(0))か？
	;		beq	in_low
	;	;	or.b	#$20,d0				; fullの場合はSOFに同期してデータを転送
	;	in_low:
	;		move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-Aホストコントロールレジスタ
	;		move.b	d0,SL811_DATA_REG		; 転送許可

			move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-Aホストコントロールレジスタ
			move.b	usb_rd_cmd,SL811_DATA_REG	; 転送許可

		;---------------------------------------------------------
		; ■受信が終了したかをチェック

		GET_INT_TIME_OTWA

			jbsr	_Intr_1ms_check_stastus1

		GET_INT_TIME_OTWB

		;---------------------------------------------------------
		; ■正常に受信できたかをチェック

			jbsr	_Intr_1ms_check_stastus2

			move.b	#REG_CNT_A,SL811_ADDR_REG	; USB-Aデータ転送残りバイト数
			move.b	SL811_DATA_REG,usb_rest_size	; データ転送残りバイト数取得

			btst.b	#0,usb_last_statusA		; エラーではないことを確認
			beq	1f
			tst.b	usb_rest_size			; エラーがなく残り転送バイト数が０ならばバッファにデータ転送
			bne	1f

			move.b	usb_packet_size,d0		; もともと受信サイズが０ならば転送なし
			beq	1f
			sub.b	d0,usb_total_size

			movea.l	usb_buf_address,a0		; デバイスディスクリプタを読み込むアドレス
			move.b	#EP0BUF,SL811_ADDR_REG		; SL811HSTメモリアドレス
			clr.w	d7
			move.b	usb_packet_size,d7
			subq.w	#1,d7
		in_get_:
			move.b	SL811_DATA_REG,(a0)+
			dbra	d7,in_get_
			move.l	a0,usb_buf_address		; デバイスディスクリプタを読み込むアドレス
	1:
		GET_INT_TIME_END

			rts

	CHK_CMD_INT:

		cmpi.b	#CMD_INT,usb_send_cmd
		bne	CHK_CMD_OUT

		;---------------------------------------------------------

		; ■データ転送用のデータが格納されているポインタをセット
			move.b	#REG_BASE_ADR_A,SL811_ADDR_REG	; USB-Aホストベースアドレスレジスタ($01)
			move.b	#EP0BUF,SL811_DATA_REG		; SL811HST内メモリースタート位置

		; ■データの転送長をセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_XLEN_A,SL811_ADDR_REG	; USB-Aホストベースデータ長レジスタ($02)
			move.b	usb_packet_size,SL811_DATA_REG	; データの転送長(1byte)

		; ■パケットID ＆ エンドポイントをセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_PID_ENDP_A,SL811_ADDR_REG	; USB-AのパケットID(上位4bit)とエンドポイントレジスタ(下位4bit)($03)
			move.b	usb_endp,d0			; エンドポイント = $0?
			ori.b	#PID_IN,d0			; パケットID = PID_IN($90)
			move.b	d0,SL811_DATA_REG		; 

		; ■USBアドレスをセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_ADDR_A,SL811_ADDR_REG	; USB-Aホストアドレスレジスタ($04)
			move.b	usb_addr,SL811_DATA_REG		; USBアドレス = $??(0～127)

		; ■EOP(Alive)を送信(ハブにロースピードデバイスを接続している時のみ)
		;	bsr	eop

		; ■全割り込みステータスクリア
			move.b	#$0d,SL811_ADDR_REG		; 割り込みステータスレジスタ
			move.b	#$ff,SL811_DATA_REG		; 全割り込みステータスクリア

		; ■IN方向、エンドポイントへの転送許可、転送許可(0010_0011b)
	;		move.b	usb_rd_cmd,d0
	;		tst.b	host_usb_speed			; ロースピード(host_usb_speed = SPEED_LOW(0))か？
	;		beq	in_low2
	;;		or.b	#$20,d0				; fullの場合はSOFに同期してデータを転送
	;	in_low2:
	;		move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-Aホストコントロールレジスタ
	;		move.b	d0,SL811_DATA_REG		; 転送許可

			move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-Aホストコントロールレジスタ
			move.b	usb_rd_cmd,SL811_DATA_REG	; 転送許可

		;---------------------------------------------------------
		; ■受信が終了したかをチェック

		GET_INT_TIME_OTWA

			jbsr	_Intr_1ms_check_stastus1

		GET_INT_TIME_OTWB

		;---------------------------------------------------------
		; ■正常に受信できたかをチェック

			jbsr	_Intr_1ms_check_stastus2

			move.b	#REG_CNT_A,SL811_ADDR_REG	; USB-Aデータ転送残りバイト数
			move.b	SL811_DATA_REG,usb_rest_size	; データ転送残りバイト数取得

			btst.b	#0,usb_last_statusA		; エラーではないことを確認
			beq	1f
		;	tst.b	usb_rest_size			; エラーがなく残り転送バイト数が０ならばバッファにデータ転送
		;	bne	1f

			move.b	usb_packet_size,d0		; もともと受信サイズが０ならば転送なし
			beq	1f
			sub.b	d0,usb_total_size

			movea.l	usb_buf_address,a0		; デバイスディスクリプタを読み込むアドレス
			move.b	#EP0BUF,SL811_ADDR_REG		; SL811HSTメモリアドレス
			clr.w	d7
			move.b	usb_packet_size,d7
			subq.w	#1,d7
		in_get2:
			move.b	SL811_DATA_REG,(a0)+
			dbra	d7,in_get2
			move.l	a0,usb_buf_address		; デバイスディスクリプタを読み込むアドレス
	1:
		GET_INT_TIME_END

			rts

	CHK_CMD_OUT:

		cmpi.b	#CMD_OUT,usb_send_cmd
		bne	CHK_CMD_OTHER

		;---------------------------------------------------------

		; ■データ転送用のデータが格納されているポインタをセット
			move.b	#REG_BASE_ADR_A,SL811_ADDR_REG	; USB-Aホストベースアドレスレジスタ($01)
			move.b	#EP0BUF,SL811_DATA_REG		; SL811HST内メモリースタート位置

		; ■データの転送長をセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_XLEN_A,SL811_ADDR_REG	; USB-Aホストベースデータ長レジスタ($02)
			move.b	usb_packet_size,SL811_DATA_REG	; データの転送長(1byte)

		; ■パケットID ＆ エンドポイントをセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_PID_ENDP_A,SL811_ADDR_REG	; USB-AのパケットID(上位4bit)とエンドポイントレジスタ(下位4bit)($03)
			move.b	usb_endp,d0			; エンドポイント = $0?
			ori.b	#PID_OUT,d0			; パケットID = PID_OUT($10)
			move.b	d0,SL811_DATA_REG		; 

		; ■USBアドレスをセット
		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#REG_ADDR_A,SL811_ADDR_REG	; USB-Aホストアドレスレジスタ($04)
			move.b	usb_addr,SL811_DATA_REG		; USBアドレス = $??(0～127)

		; ■全割り込みステータスクリア
			move.b	#$0d,SL811_ADDR_REG		; 割り込みステータスレジスタ
			move.b	#$ff,SL811_DATA_REG		; 全割り込みステータスクリア

		; ■EOP(Alive)を送信(ハブにロースピードデバイスを接続している時のみ)
			bsr	eop

		; ■OUT方向、エンドポイントへの転送許可、転送許可(0000_0111b)
			move.b	#REG_CTRL_A,SL811_ADDR_REG	; USB-Aホストコントロールレジスタ
			move.b	usb_wr_cmd,SL811_DATA_REG	; 転送許可

		GET_INT_TIME_OTWA

			jbsr	_Intr_1ms_check_stastus1

		GET_INT_TIME_OTWB

			jbsr	_Intr_1ms_check_stastus2

		GET_INT_TIME_END

			rts

	CHK_CMD_OTHER:

		; ここに来ることはプログラムミス以外にありえません

		rts

_Intr_1ms_exit_nopacket:

		; ■EOP(Alive)を送信(ハブにロースピードデバイスを接続している時のみ)
		bsr	eop

		rts

;■正常に送信できたかチェック１
_Intr_1ms_check_stastus1:

@@:
		move.b	#REG_INT_STATUS,SL811_ADDR_REG	; 割り込みステータスレジスタ
		move.b	SL811_DATA_REG,usb_last_status	; 

		btst.b	#0,usb_last_status
		beq	@b

		clr.b	d0				; 正常終了
		rts

;■正常に送信できたかチェック２
_Intr_1ms_check_stastus2

		move.b	#REG_INT_STAT_A,SL811_ADDR_REG	; USB-Aステータスレジスタ
		move.b	SL811_DATA_REG,usb_last_statusA	; 

		rts

;■EOP(Alive)を送信(ハブにロースピードデバイスを接続している時のみ)
eop:
		; USBJOYでは永遠に不要なので、手をつけず中途半端なコードになっています
		rts

.if (EOP_PRINT=1)
eop2:
		_StrPrint	'*EOP',13,10
.endif
;		tst.b	host_usb_speed			; ロースピード(host_usb_speed = SPEED_LOW(0))か？
;		bne	@f
;
;		move.b	#$05,SL811_ADDR_REG		; コントロールレジスタ１
;		move.b	#$20+$08+$01,SL811_DATA_REG	; ロースピード＆USBリセット＆SOF自動生成
;
;		move.b	#$05,SL811_ADDR_REG		; コントロールレジスタ１
;		move.b	#$20+$00+$01,SL811_DATA_REG	; ロースピード＆通常＆SOF自動生成
;	@@:
;		rts

;---------------------------------------------
; 受信キャラクタ有効(マウス１バイト入力)を殺す
;---------------------------------------------
kill_mouse:
		move.w	d0,-(sp)
		move.w	SCC_DAT_B,d0
		move.w	#$38,SCC_COM_B
		move.w	(sp)+,d0
		rte

;---------------------------------------------------------
; 取得したデータをX68000のマウスのデータフォーマットに変換
;---------------------------------------------------------
		.even
mouse_data_conv:
		beq	@f				; NAK or ERRならばデータを加工
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

		cmpi.b	#5,(a0)				; 右＋中ボタンが同時に押されているか？
		bne	9f				; 
							; 
		cmpi.b	#5,old_mouse_button_status	; 前回も右＋中ボタンの同時押しか？
		beq	9f				; 
							; 
		not.b	mouse_dpi_half_flg		; 
	9:
		move.b	(a0)+,d0

		move.b	d0,old_mouse_button_status

		move.b	d0,(a1)+			; トリガ状態

		move.b	(a0)+,d0

		tst.b	mouse_dpi_half_flg
		beq	9f

		tst.b	d0				; 
		ble	1f				; マイナスと０を弾く
		cmpi.b	#127,d0				; 
		beq	1f				; 127を弾く
		addq.b	#1,d0				; 
	1:
		asr.b	d0
	9:
		move.b	d0,(a1)+			; Ｘ座標

		move.b	(a0),d0

		tst.b	mouse_dpi_half_flg
		beq	9f

		tst.b	d0				; 
		ble	1f				; マイナスと０を弾く
		cmpi.b	#127,d0				; 
		beq	1f				; 127を弾く
		addq.b	#1,d0				; 
	1:
		asr.b	d0
	9:
		move.b	d0,(a1)				; Ｙ座標

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
; 取得したデータをX68000のジョイポートのデータフォーマットに変換(自己書換)
;-------------------------------------------------------------------------
		.even
joy_data_conv:
		bne	9f				; NAK or ERRならば前回のデータを引き継ぐ

		;clr.b	d0				; ここに来た時点で必ずd0 = 0

		lea.l	Buf_Work(pc),a0

		;cmpi.b	#$00,2(a0)			; 左が押されているか？
	left_cmd:	.dc.b	$0c,$28,$00		; 
	left_dat:	.dc.b	$00,$00			; 
	left_pos:	.dc.b	$02			; 
		;bne	1f				; 
		bhi	1f				; 
		ori.b	#JOY_LKEY,d0			; $0000,$000?
	1:
		;cmpi.b	#$ff,2(a0)			; 右が押されているか？
	right_cmd:	.dc.b	$0c,$28,$00		; 
	right_dat:	.dc.b	$ff,$00			; 
	right_pos:	.dc.b	$02			; 
		;bne	2f				; 
		bcs	2f				; 
		ori.b	#JOY_RKEY,d0			; 
	2:
		;cmpi.b	#$00,3(a0)			; 上が押されているか？
	up_cmd:		.dc.b	$0c,$28,$00		; 
	up_dat:		.dc.b	$00,$00			; 
	up_pos:		.dc.b	$03			; 
		;bne	3f				; 
		bhi	3f				; 
		ori.b	#JOY_UKEY,d0			; 
	3:
		;cmpi.b	#$ff,3(a0)			; 下が押されているか？
	down_cmd:	.dc.b	$0c,$28,$00		; 
	down_dat:	.dc.b	$ff,$00			; 
	down_pos:	.dc.b	$03			; 
		;bne	4f				; 
		bcs	4f				; 
		ori.b	#JOY_DKEY,d0			; 
	4:
		;cmpi.b	#$00,1(a0)			; Ａが押されているか？
	a1_cmd:		.dc.b	$0c,$28,$00		; 
	a1_dat:		.dc.b	$01,$00			; 
	a1_pos:		.dc.b	$00			; 
		bcs	5f				; 
		ori.b	#JOY_BTN_A1,d0			; 
	5:
		;cmpi.b	#$00,1(a0)			; Ａが押されているか？
	b1_cmd:		.dc.b	$0c,$28,$00		; 
	b1_dat:		.dc.b	$01,$00			; 
	b1_pos:		.dc.b	$00			; 
		bcs	6f				; 
		ori.b	#JOY_BTN_B1,d0			; 
	6:
		;cmpi.b	#$00,1(a0)			; Ａが押されているか？
	a2_cmd:		.dc.b	$0c,$28,$00		; 
	a2_dat:		.dc.b	$01,$00			; 
	a2_pos:		.dc.b	$00			; 
		bcs	7f				; 
		ori.b	#JOY_BTN_A2,d0			; 
	7:
		;cmpi.b	#$00,1(a0)			; Ａが押されているか？
	b2_cmd:		.dc.b	$0c,$28,$00		; 
	b2_dat:		.dc.b	$01,$00			; 
	b2_pos:		.dc.b	$00			; 
		bcs	8f				; 
		ori.b	#JOY_BTN_B2,d0			; 
	8:
		not.b	d0				; ジョイパッドのデータのビットを反転させます

		tst.b	usb_report_id
		bmi	1f

		;リポートＩＤでどちらのジョイパッドの入力かを調べる
		;cmpi.b	#$02,?(a0)			; 
	rid_cmd:		.dc.b	$0c,$28,$00	; 
	rid_dat:		.dc.b	$02,$00		; 
	rid_pos:		.dc.b	$00		; 
		beq	2f				; 
	1:
		move.b	d0,joy_data0			; IOCS _JOYGETで参照されるワークに格納
		rts
	2:
		move.b	d0,joy_data1			; IOCS _JOYGETで参照されるワークに格納
9:
		rts

tsr_bottom:	; この位置までがメモリに常駐します

;-----------------------------------------------------------
; サブルーチン
;-----------------------------------------------------------
;	CmdNereidResetOff:	リセット解除
;	CmdNereidResetOn:	リセット
;	CmdNereidPowerOn:	５Ｖ供給
;	CmdNereidPowerOff:	５Ｖ停止
;	CmdNereidIntOn:		割り込み許可
;	CmdNereidIntOff:	割り込み禁止

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

;■１ｍｓ割り込み処理終了待ち
wait_command:

	@@:
		tst.b	usb_send_cmd
		bne	@b
		rts

;■SL811HSTのリビジョンの表示
print_revision:
		move.b	#$0E,SL811HST_ADDR		; ハードウェアリビジョンレジスタ
		move.b	SL811HST_DATA,d0		; 

		btst.l	#5,d0
		beq	@f
		move.b	#'5',chip_revision
	@@:
		movem.l	d0/a1,-(sp)

		move.w	#1,d1				; 
		IOCS	_B_COLOR			; 水色(強調)

		lea	msg_sl811hst_rev,a1
		IOCS	_B_PRINT

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; 水色(強調)

		movem.l	(sp)+,d0/a1

		rts

.if (SETUP_PACKET_PRINT=1)
;■ＳＥＴＵＰパケットの表示
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

;■割り込みカウンタの結果表示
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

;■
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

;■残転送バイト数の表示
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

;■最終ステータスレジスタの表示
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

;■ディスクリプタの表示
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

;■ディスクリプタの表示
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

;■パケットデータの表示
print_Buf_Work:
		movem.l	d0/d7/a0,-(sp)

		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; 水色(強調)

		_StrPrint	'packet data : '

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; 白色

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
; 初期化関連
;-----------------------------------------------------------

;■SL811HSTの初期化
init_sl811hst:
		move.w	#240-1,d7			; 
		clr.b	d0				; SL811Hのメモリを初期化
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
; 定義ファイルの読み込み
;-----------------------------------------------------------
GetUsbPadInfo:
		clr.l	d0
		lea.l	WorkBuffer(pc),a0
		move.w	#32768/4,d1
	@@:	move.l	d0,(a0)+
		dbra	d1,@b

		_open	filename,#0			; 
		tst.l	d0				; ファイルがオープンできたか？
		bmi	open_error			; マイナスならばオープンできないのでエラー

		move.w	d0,handle			; ファイルハンドルを格納

		_read	handle,WorkBuffer,#32768+1	; 32768+1バイト読み込み
		move.l	d0,FileSize			; ファイルサイズをしまっておく
		_close	handle				; とりあえずファイルクローズ

		cmpi.l	#32768,FileSize			; 32769バイト以上読み込めたらエラー
		bhi	read_error			; 

		lea	WorkBuffer,a0			;
		cmpi.l	#'USBJ',(a0)+			; 定義ファイルでなければエラー
		bne	header_error			;
		cmpi.l	#'OY13',(a0)+			; 定義ファイルでなければエラー
		bne	header_error			;

	;○最初のピリオドが出てくるまでスキップ
	@@:
		tst.b	(a0)				; 最後までチェックしたか？
		beq	data_error2			; 
		addq.l	#1,a0				; 
		cmpi.b	#$0a,-1(a0)			; 改行コードの次までスキップする
		bne	@b				; 
		cmpi.b	#'.',(a0)			; 行の先頭が最初のピリオドか？
		bne	@b				; 

		_StrPrint2	'最初のピリオド検出.',cr,lf

	;○次の行まで改行
	@@:
		tst.b	(a0)				; 最後までチェックしたか？
		beq	data_error2			; 
		addq.l	#1,a0				; 
		cmpi.b	#$0a,-1(a0)			; 改行コードの次までスキップする
		bne	@b				; 

	get_info_top:

	;○ここから定義データ記述
		lea.l	UsbPadInfo,a1			; 情報を読み込むワークの先頭
		move.w	#10-1,d6			; ワードデータを11回読む
	@@:
		jbsr	get_word_data			; VID～RBTN2取得
		bne	data_error2			; 
		move.w	d0,(a1)+			; 情報をしまう
		jbsr	skipsp				; 
		dbra	d6,@b				; 

		jbsr	get_psize			; PSIZE取得
		bne	data_error2			; 
		move.b	d0,PSIZE			; 情報をしまう
		jbsr	skipsp				; 

		jbsr	get_intr			; INTR取得
		bne	data_error2			; 
		move.b	d0,INTR				; 情報をしまう
		jbsr	skipsp				; 

		jbsr	get_repid			; REPID取得
		bne	data_error2			; 
		subi.b	#1,d0				; 
		move.b	d0,REPID			; 情報をしまう
		jbsr	skipsp				; 

		move.w	VendorID,d0			; 
		rol.w	#8,d0				; エンディアン変換
		swap.w	d0				; 
		move.w	ProductID,d0			; 
		rol.w	#8,d0				; エンディアン変換
		cmp.l	VID,d0				; 
		beq	found_info			; 登録済みのジョイパッドだった場合

	;○次の行まで改行
	@@:
		tst.b	(a0)				; 最後までチェックしたか？
		beq	data_error2			; 
		addq.l	#1,a0				; 
		cmpi.b	#$0a,-1(a0)			; 改行コードの次までスキップする
		bne	@b				; 

		cmpi.b	#'.',(a0)			; 行の先頭が最後のピリオドか？
		beq	undefined_error			; 
		jbra	get_info_top			; 
found_info:
	; 見つかった
		_StrPrint	'対応済みのジョイパッドが接続されています.',cr,lf

		clr.w	d0
		rts
open_error:
		_StrPrint	'定義ファイルがオープンできません.',cr,lf
		bra	@f
read_error:
		_StrPrint	'定義ファイルのサイズが32KByteを越えています.',cr,lf
		bra	@f
header_error:
		_StrPrint	'定義ファイルではありません.',cr,lf
		bra	@f
data_error:
		_StrPrint	'定義ファイルの記述にエラーがあります.',cr,lf
		bra	@f
data_error2:
		_StrPrint	'定義ファイルの記述にエラーがあります.',cr,lf
		bra	@f
psize_error:
		_StrPrint	'定義ファイルのバイト位置指定に、最大パケットサイズよりも大きな値が設定されています.',cr,lf
		bra	@f
bit_error:
		_StrPrint	'定義ファイルのビット位置指定に 0～7 以外の値が設定されています.',cr,lf
		bra	@f
undefined_error:
		_StrPrint	'未対応のジョイパッドが接続されています.',cr,lf
		tst.b	optflg_C	; パケット調査モードの場合はエラーにはしないよん
		beq	@f
		move.w	#$ffff,d0
		rts
	@@:
		move.w	#$01,d0
		rts

;-----------------------------------------------------------
; 定義ファイルの簡易データチェック
;-----------------------------------------------------------
ChkUsbPadInfo:
		lea.l	LKEY,a1
		move.w	#8-1,d7
	1:
		move.w	(a1)+,d0
		bmi	2f

		; デジタル1ビット

		cmpi.b	#8,d0
		bcc	bit_error
	2:
		; アナログ8ビット

		ror.w	#8,d0
		andi.b	#$0f,d0
		cmp.b	MaxPacketSizeL,d0
		bcc	psize_error
	3:
		dbra	d7,1b

		clr.w	d0
		rts

;-----------------------------------------------------------
; 自己書換ルーチン
;-----------------------------------------------------------
WriteUsbPadInfo:
		bmi	8f

		lea.l	LKEY,a0
		lea.l	left_cmd(pc),a1

		move.w	#8-1,d7
	1:
		move.w	(a0)+,d0
		bmi	2f

		; デジタル1ビット自己書換
		move.w	#$0828,0(a1)		; btst.b
		move.w	#$6704,6(a1)		; beq	+4
	2:
		andi.w	#$0fff,d0

		move.b	d0,3(a1)		; ビット位置
		ror.w	#8,d0			; 
		move.b	d0,5(a1)		; バイト位置

		lea.l	12(a1),a1

		dbra	d7,1b

		move.b	usb_report_id,d0
		bmi	8f

		;リポートＩＤ読み込みバイト位置書き替え
		move.b	d0,rid_pos
	8:
		; サブルーチンの分岐アドレスをジョイパッドに書き替える
		move.w	#joy_data_conv-branch_address,branch_address

		cmpi.b	#$02,$0cbc.w		; MPUチェック
		bcs	9f			; 68020未満ならばなにもしない

		moveq.l	#3,d1			; ＭＰＵキャッシュのクリア
		IOCS	_SYS_STAT		; (本当はROMバージョンも考慮すべき)
	9:
		rts

;-----------------------------------------------------------
; 先頭のスペース（＆タブ）をスキップする。
;-----------------------------------------------------------
		.even
@@:
		addq.l	#1,a0		;
skipsp:
		cmpi.b	#$20,(a0)	;スペースか？
		beq	@b
		cmpi.b	#$09,(a0)	;タブか？
		beq	@b
		rts

;-----------------------------------------------------------
; d0.wに２バイト($????)のデータを取得する
;-----------------------------------------------------------
get_word_data:
		clr.l	d0
		move.w	#4-1,d7
	@@:
		move.b	(a0)+,d1		; 文字取得
		jbsr	chk_char_data_0f	; 文字チェック(0～F)
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
; d0.bにパケットサイズ($00～$08)を取得する
;-----------------------------------------------------------
get_psize:
		clr.l	d0
		move.b	(a0)+,d1		; 文字取得
		jbsr	chk_char_data_psize	; 文字チェック(-～8)
		bmi	err_get_psize
		or.b	d1,d0

		clr.b	d1
		rts
err_get_psize:
		move.w	#1,d1
		rts

;-----------------------------------------------------------
; d0.bに割り込み周期($00～$0f)を取得する
;-----------------------------------------------------------
get_intr:
		clr.l	d0
		move.b	(a0)+,d1		; 文字取得
		jbsr	chk_char_data_intr	; 文字チェック(-～f)
		bmi	err_get_intr
		or.b	d1,d0

		clr.b	d1
		rts
err_get_intr:
		move.w	#1,d1
		rts

;---------------------------------------------------------------------
; d0.bにリポートＩＤの位置($00～$08)を取得する(+1された値が取得される)
;---------------------------------------------------------------------
get_repid:
		clr.l	d0
		move.b	(a0)+,d1		; 文字取得
		jbsr	chk_char_data_repid	; 文字チェック(-～7)
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
; コマンドラインオプションのチェック
;==============================================================================================
		.even
option_check:
		movem.l	d0-d7/a0-a6,-(sp)		; レジスタ待避

		lea.l	1(a2),a0			; a0 = コマンドラインの先頭アドレス;
option_check0:
		bsr	Sub_SkipSPACE			; 最初にスペース、タブをスキップ(複数)

		tst.b	(a0)				; 引き数があるか？
		beq	option_check_end

	;オプション取得
		cmpi.b	#'/',(a0)			; スラッシュか？
		beq	Sub_GetOption			; オプションの判別へ
		cmpi.b	#'-',(a0)			; ハイフンか？
		beq	Sub_GetOption			; オプションの判別へ

	;ファイル名取得
		lea.l	filename(pc),a1			; a1 = ファイル名のワークアドレス先頭
		bsr	Sub_GetFileName			; ファイル名の取得へ

option_check_end:
		movem.l	(sp)+,d0-d7/a0-a6		; レジスタ復帰

		rts

;==============================================================================================
;○コマンドラインの先頭のスペース（＆タブ）をスキップするサブルーチン
;==============================================================================================
		.even
	@@:
		lea.l	1(a0),a0			;a0=コマンドラインの先頭アドレス
Sub_SkipSPACE:
		cmpi.b	#$20,(a0)			;スペースか？
		beq	@b
		cmpi.b	#$09,(a0)			;タブか？
		beq	@b
		rts

;==============================================================================================
;○ファイル名の取得
;==============================================================================================
		.even
Sub_GetFileName:
	@@:						;
		tst.b	(a0)				; 文字列の終端コードか？
		beq	@f				;
		cmpi.b	#$20,(a0)			; スペースか？
		beq	@f				;
		cmpi.b	#$09,(a0)			; タブか？
		beq	@f				;
		cmpi.b	#'/',(a0)			; スラッシュか？
		beq	@f				;
		cmpi.b	#'-',(a0)			; ハイフンか？
		beq	@f				;
		move.b	(a0)+,(a1)+			; ファイル名を１文字転送
		bra.b	@b				;
	@@:						;
		clr.b	(a1)				; 文字列終端コードを書き込む

		rts

;==============================================================================================
;○オプションの取得
;==============================================================================================
		.even
Sub_GetOption:
		lea.l	1(a0),a0			; '/' or '-'を１文字飛ばす

		move.b	(a0)+,d0			; １文字読み込み

		cmpi.b	#'A',d0				; 半角大文字のアルファベットならば
		bcs	@f				; 小文字に変換する
		cmpi.b	#'Z',d0				;
		bhi	@f				;
		addi.b	#' ',d0				;
	@@:
		cmpi.b	#'a',d0				; -aオプションが指定されているか？
		beq	option_A			;
		cmpi.b	#'c',d0				; -cオプションが指定されているか？
		beq	option_C			;
		cmpi.b	#'x',d0				; -xオプションが指定されているか？
		beq	option_X			;
; -------- patch +z1 --------
		cmpi.b	#'z',d0				; -zオプションが指定されているか？
		beq	option_Z			;
; ---------------------------
		cmpi.b	#'h',d0				; -hオプションが指定されているか？
		beq	Sub_PrintUsage			;
		bra	Sub_PrintUsage			; それ以外ならばヘルプの表示
option_A:
		;オプションＡ処理
		move.b	(a0)+,d0			; １文字読み込み
		cmpi.b	#'1',d0				; '1'か？
		beq	1f				; それ以外ならばヘルプの表示
		cmpi.b	#'2',d0				; '2'か？
		bne	Sub_PrintUsage			; それ以外ならばヘルプの表示
	1:
		subi.b	#'0',d0
		move.b	d0,auto_flg
		bra	@f
option_C:
		;オプションＣ処理
		move.b	#1,optflg_C
		bra	@f
option_X:
		;オプションＸ処理
		move.b	#1,optflg_X
		bra	@f
; -------- patch +z1 --------
option_Z:
		;オプションＺ処理
		move.b	#1,optflg_Z
		bra	@f
; ---------------------------
		nop
	@@:
		jbra	option_check0			; そうならば次のチェックへ

;==============================================================================================
;○ヘルプの表示 サブルーチン
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
		movem.l	d0/a1,-(sp)			; レジスタ待避

		move.w	#2,d1				; 
		IOCS	_B_COLOR			; 表示文字色を黄色に変更します

		lea	title_msg,a1			; 
		IOCS	_B_PRINT			; タイトルを表示します

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; 表示文字色を白に戻します

		movem.l	(sp)+,d0/a1			; レジスタ復帰

		movem.l	d0-d7/a0-a6,-(sp)		; レジスタ待避

		lea	tsr_top-$80(pc),a0		; 
		lea.l	filename(pc),a1			; 
	@@:						; アドレスfilenameにプロセス管理ポインタから取得したパス名を格納します
		move.b	(a0)+,(a1)+			; 
		bne	@b				; 

		lea	def_filename,a0			; 
		lea	-1(a1),a1			; 
	@@:						; 取得したパスの後ろに定義ファイル名を追加します
		move.b	(a0)+,(a1)+			; 
		bne	@b				; 

.if (PATH_FILENAME_PRINT=1)
		lea.l	filename(pc),a1			; 
		IOCS	_B_PRINT			; パス＋定義ファイル名を表示します(テスト時のみ)
		_StrPrint	cr,lf			; 
.endif

		movem.l	(sp)+,d0-d7/a0-a6		; レジスタ復帰

		clr.l	a1				; 
		IOCS	_B_SUPER			; スーパーバイザモードにする

		; この時点でd0に変更前のsspの内容が入っています

		; ■オプションのチェック
		jbsr	option_check

		; ■常駐しているかチェックします
chck_top:
		movea.l	(a0),a1
		cmpi.l	#0,(a1)				; ０ならば常駐していなかった
		beq	Stay_Mem			; 常駐処理へ
		movea.l	a1,a0				; 
		lea.l	$100(a1),a1			; +256バイト
		lea	tsr_top(pc),a2			; 

		moveq	#8-1,d1				; 
chck_loop:						; 
		cmpm.b	(a1)+,(a2)+			; '$USBJOY$'が見つかったか？
		bne	chck_top			; 見つからなければ次のプロセス管理ポインタを調べるため移動
		dbra	d1,chck_loop			; 

		; a0==常駐部のアドレス

	; ■接続されているのがジョイパッドならば、IOCS_JOYGETを元に戻す
		tst.b	$100+Protocol-tsr_top(a0)	; 
		bne	@f				; 
		movem.l	d0-d1/a1,-(sp)			; レジスタ退避
		move.w	#$013B,d1			; d1 = _JOYGETを置き換える
		movea.l	$100+old_joy_vct-tsr_top(a0),a1	; a1 = 置き換え前のアドレス
		IOCS	_B_INTVCS			; 割り込みハンドラを元に戻す
		movem.l	(sp)+,d0-d1/a1			; レジスタ復帰
	@@:
;---------------------------------------------------------------------------
; 常駐終了前処理
;---------------------------------------------------------------------------
	movem.l	d0-d7/a0-a6,-(sp)

	; 終了処理の最良の方法は不確定

		jbsr	CmdNereidIntOff			; nereid int off
		move.l	#2*20,d1			; 2ms待つ
		jbsr	delay50ns

		move.w	#100,d7
	@@:
		move.b	#REG_INT_STATUS,SL811HST_ADDR	; 割り込みステータスレジスタ
		move.b	#$FF,SL811HST_DATA		; 全割り込みフラグリセット
		dbra	d7,@b

		move.b	#$06,SL811HST_ADDR		; 割り込みイネーブルレジスタ
		move.b	#$00,SL811HST_DATA		; 全タイマ割り込みを禁止

	move.l	#10*20,d1
	jbsr	delay50ns

		jbsr	CmdNereidPowerOff		; nereid power off
		jbsr	CmdNereidResetOn		; nereid reset on

	movem.l	(sp)+,d0-d7/a0-a6
;---------------------------------------------------------------------------
; 常駐終了処理
;---------------------------------------------------------------------------

		movem.l	d0-d1/a1,-(sp)
		move.w	#$FB,d1				; 
		movea.l	$100+old_int-tsr_top(a0),a1	; 
		IOCS	_B_INTVCS			; 割り込みハンドラを元に戻す
		movem.l	(sp)+,d0-d1/a1

;		move.l	$100+old_mouse_vct-tsr_top(a0),$150
;		move.l	$100+old_mouse_vct-tsr_top(a0),$154

		move.l	d0,a1				;
		IOCS	_B_SUPER			; モードをもとに戻す

		add.l	#$10,a0
		move.l	a0,-(sp)
		DOS	_MFREE

		pea	rel_msg
		DOS	_PRINT
exit_prog:
		DOS	_EXIT

;---------------------------------------------------------------------------
; 常駐開始
;---------------------------------------------------------------------------
;		.even
Stay_Mem:
		move.l	d0,a1				;
		IOCS	_B_SUPER			; モードをもとに戻す

		clr.l	a1				; 
		IOCS	_B_SUPER			; スーパーバイザモードにする

;		move.l	($150),old_mouse_vct		; 受信キャラクタ有効(マウス１バイト入力)
;		lea	kill_mouse,a1			;
;		move.l	a1,$150				;
;		move.l	a1,$154				;

	movem.l	d0-d7/a0-a6,-(sp)

		move.w	#$FB,d1				; 
		lea.l	_Intr_1ms(pc),a1		; 
		IOCS	_B_INTVCS			; 割り込みハンドラを _Intr_1ms に設定
		move.l	d0,old_int			; 

		clr.l	int_count			; テスト用カウンタを０に

		clr.b	usb_send_cmd			; 
		clr.b	usb_endp			; 
		clr.b	usb_addr			; 
		clr.b	usb_length			; 
		clr.b	usb_interrupt_flg		; インタラプト転送開始フラグ
		clr.b	usb_interrupt_count		; インタラプト転送カウンタ

		move.b	#DATA0_WR,usb_wr_cmd
		move.b	#DATA0_RD,usb_rd_cmd

		jbsr	CmdNereidIntOff			; nereid int off

		jbsr	CmdNereidResetOff		; nereid reset off

		jbsr	CmdNereidPowerOn		; nereid power on

	move.l	#500*20,d1	; 
	jbsr	delay50ns	; 一部のマウスが未検出になってしまうのでウェイトを追加１

		jbsr	init_sl811hst			; SL811HSTメモリ初期化

		jbsr	print_revision			; ハードウェアリビジョン表示

		move.b	#$0F,SL811HST_ADDR		; SOF上位カウンタ/コントロールレジスタ２
		move.b	#$80+$2E,SL811HST_DATA		; ホスト動作モード＆SOF上位カウンタ６ビット

		move.b	#$05,SL811HST_ADDR		; コントロールレジスタ１
		move.b	#$08,SL811HST_DATA		; ＵＳＢリセット

		move.l	#20*20,d1
		jbsr	delay50ns

		move.b	#$05,SL811HST_ADDR		; コントロールレジスタ１
		move.b	#$00,SL811HST_DATA		; ＵＳＢリセット解除

	move.l	#300*20,d1	; 
	jbsr	delay50ns	; 一部のマウスが未検出になってしまうのでウェイトを追加２

		move.w	#100,d7
	@@:
		move.b	#REG_INT_STATUS,SL811HST_ADDR	; 割り込みステータスレジスタ
		move.b	#$FF,SL811HST_DATA		; 全割り込みフラグリセット
		dbra	d7,@b

		clr.l	d0

		move.b	#REG_INT_STATUS,SL811HST_ADDR	; 割り込みステータスレジスタ
		move.b	SL811HST_DATA,d0		; の内容を d0 に読み込む

		move.b	#$05,SL811HST_ADDR		; コントロールレジスタ１
		move.b	#$08,SL811HST_DATA		; ＵＳＢリセット

	.if (ISR_PRINT=1)
		_StrPrint	'ISR = '
		jbsr	hex_print_b
		_StrPrint	cr,lf
	.endif

		btst.l	#6,d0				; Resume Detection 割り込み上がらなければ
		bne	no_device			; デバイスなしの処理へ飛ぶ

		btst.l	#7,d0				; ISR の $80 が ON なら low speed
		bne	full_speed_device

low_speed_device:
		_StrPrint	'Low Speed Device Detected.',cr,lf

		move.b	SPEED_LOW,host_usb_speed

			move.b	#$0E,SL811HST_ADDR		; SOF下位カウンタ
			move.b	#$E0,SL811HST_DATA		; 下位カウンタ８ビット

		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#$0F,SL811HST_ADDR		; SOF上位カウンタ/コントロールレジスタ２
			move.b	#$80+$40+$2E,SL811HST_DATA	; ホスト動作モード＆ロースピードモード＆SOF上位カウンタ６ビット

			move.b	#$05,SL811HST_ADDR		; コントロールレジスタ１
			move.b	#$20+01,SL811HST_DATA		; ロースピード＆SOF自動生成(割り込み有効)

			move.w	#100,d7				; 
		@@:						; 
			move.b	#REG_INT_STATUS,SL811HST_ADDR	; 割り込みステータスレジスタ
			move.b	#$FF,SL811HST_DATA		; 全割り込みフラグリセット
			dbra	d7,@b				; 

		bra	@f

full_speed_device:
		_StrPrint	'Full Speed Device Detected.',cr,lf

		move.b	SPEED_FULL,host_usb_speed

			move.b	#$0E,SL811HST_ADDR		; SOF下位カウンタ
			move.b	#$E0,SL811HST_DATA		; 下位カウンタ８ビット

		; 続きなのでアドレスのセットは必要ない↓
		;	move.b	#$0F,SL811HST_ADDR		; SOF上位カウンタ/コントロールレジスタ２
			move.b	#$80+$00+$2E,SL811HST_DATA	; ホスト動作モード＆ハイスピードモード＆SOF上位カウンタ６ビット

			move.b	#$05,SL811HST_ADDR		; コントロールレジスタ１
			move.b	#$00+01,SL811HST_DATA		; フルスピード＆SOF自動生成(割り込み有効)

			move.b	#REG_INT_STATUS,SL811HST_ADDR	; 割り込みステータスレジスタ
			move.b	#$FF,SL811HST_DATA		; 全割り込みフラグリセット

	@@:
			move.b	#$03,SL811HST_ADDR	; USB-Aホスト・パケットID、デバイスエンドポイント
			move.b	#$50,SL811HST_DATA	; $5=SOF:$0=デバイスエンドポイント

			move.b	#$04,SL811HST_ADDR	; USB-Aホスト・デバイスアドレス
			move.b	#$00,SL811HST_DATA	; アドレス＝０

			move.b	#$00,SL811HST_ADDR	; USB-Aホストコントロルレジスタ
			move.b	#$01,SL811HST_DATA	; bit0=1で転送許可：転送が完了するとbit1=0になる

		move.l	#25*20,d1
		jbsr	delay50ns

			move.b	#$06,SL811HST_ADDR	; 割り込みイネーブルレジスタ
			move.b	#$10,SL811HST_DATA	; SOFタイマ割り込み(bit4)のみ許可する

		move.w	#64,retry_nak_max_count	; NAKの最大リトライ回数をセット

		jbsr	CmdNereidIntOn		; ネレイドの割り込み許可

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'■デバイスディスクリプタの仮取得(先頭８バイトのみ取得)',cr,lf

		; ■デバイスディスクリプタの仮取得

		move.b	#$00,usb_addr		; アドレス = 0
		move.b	#$00,usb_endp		; エンドポイント = 0
		move.b	#8,usb_length		; データ転送長 = 8
		move.b	#8,usb_payload		; 仮ペイロード = 8
		lea.l	Buf_StdDescriptor(pc),a0
		move.l	a0,usb_buf_address	; デバイスディスクリプタを読み込むアドレス

		jbsr	_GetDeviceDescriptor	; デバイスディスクリプタ取得
		tst.b	d0
		bne	err_exit

		_StrPrint2	'□正常に取得できました',cr,lf,cr,lf

		lea.l	Buf_StdDescriptor(pc),a0
		move.b	$7(a0),usb_payload	; ペイロード = 8/16/32/64

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'■アドレスの変更(0 -> 1)',cr,lf

		; ■アドレス設定

		move.b	#$01,address_data	; 新アドレス = 1
		move.b	#$00,usb_addr		; アドレス = 0
		move.b	#$00,usb_endp		; エンドポイント = 0
		;move.b	#0,usb_length		; データ転送長 = 0
		lea.l	Buf_StdDescriptor(pc),a0
		move.l	a0,usb_buf_address	; 

		jbsr	_SetDeviceAddress	; デバイスアドレス設定
		tst.b	d0
		bne	err_exit

		_StrPrint2	'□正常に変更できました',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'■デバイスディスクリプタの本取得',cr,lf

		; ■デバイスディスクリプタ本取得

		move.b	#$01,usb_addr		; アドレス = 1
		move.b	#$00,usb_endp		; エンドポイント = 0
		move.b	#18,usb_length		; データ転送長 = 18
		lea.l	Buf_StdDescriptor(pc),a0
		move.l	a0,usb_buf_address	; デバイスディスクリプタを読み込むアドレス

		jbsr	_GetDeviceDescriptor	; デバイスディスクリプタ取得
		tst.b	d0
		bne	err_exit

		_StrPrint2	'□正常に取得できました',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------


		; ■オプションでMicrosoft Xbox 360 系のControllerが指定されているか調べる
		;   (※Windowsでも専用ドライバが必要)

		tst.b	optflg_X
		beq	@f

		; Xbox360専用ルーチンを実行
		move.b	#3,Class		; 
		move.b	#0,SubClass		; 
		move.b	#0,Protocol		; 

		move.b	#8,MaxPacketSizeL	; 
		move.b	#0,MaxPacketSizeH	; 
		move.b	#1,bInterval		; 
		jbra	@@f

	@@:
		_StrPrint2	'■コンフィギュレーションディスクリプタの仮取得',cr,lf

		; ■コンフィギュレーションディスクリプタ仮取得

		move.b	#$01,usb_addr		; アドレス = 1
		move.b	#$00,usb_endp		; エンドポイント = 0
		move.b	#9,usb_length		; データ転送長 = 9
		lea.l	Buf_CnfDescriptor(pc),a0
		move.l	a0,usb_buf_address	; コンフィギュレーションディスクリプタを読み込むアドレス
		jbsr	_GetConfiguration	; コンフィギュレーションディスクリプタ取得
		tst.b	d0
		bne	err_exit

		; 現在対象外のデバイスなら常駐せずに終了
		;(仮取得なのでTotalLengthのみの簡易チェック)

; -------- patch +z1 --------
;		cmpi.b	#34,TotalLengthL	; TotalLengthが34バイトのデバイスのみ対象
;		bne	no_joypad		; 
		cmpi.b	#34,TotalLengthL	; TotalLengthが34バイトのデバイスは対象
		beq	@f
		tst.b	optflg_Z		; -zオプション指定されていなければそれ以外は対象外
		beq	no_joypad
		cmpi.b	#41,TotalLengthL	; -zオプション指定されていればTotalLengthが41バイトのデバイスも対象
		bne	no_joypad		; 
	@@:
; ---------------------------
  	        tst.b	TotalLengthH		; 
		bne	no_joypad		; 

		_StrPrint2	'□正常に取得できました',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'■コンフィギュレーションディスクリプタの取得',cr,lf

		; ■コンフィギュレーションディスクリプタ取得

		move.b	#$01,usb_addr		; アドレス = 1
		move.b	#$00,usb_endp		; エンドポイント = 0
; -------- patch +z1 --------
;		move.b	#34,usb_length		; データ転送長 = 34
		move.b	TotalLengthL,usb_length ; データ転送長 = 34 または 41
; ---------------------------
  	   	lea.l	Buf_CnfDescriptor(pc),a0
		move.l	a0,usb_buf_address	; コンフィギュレーションディスクリプタを読み込むアドレス
		jbsr	_GetConfiguration	; コンフィギュレーションディスクリプタ取得
		tst.b	d0
		bne	err_exit

		; 現在対象外のデバイスなら常駐せずに終了

		move.l	Class,d0
		andi.l	#$ffffff00,d0
		cmpi.l	#$03_00_00_00,d0	; 接続されているHIDは標準的なジョイパッドか？
		beq	@f

		cmpi.l	#$03_01_02_00,d0	; 接続されているHIDは標準的なマウスか？
		bne	no_joypad
@@:
; -------- patch +z1 --------
		tst.b	optflg_Z
		beq	@@f			; -zオプション指定がなければ何もしない
		btst.b	#8,EndPointAddr		; 最初のエンドポイントはINか？
		bne	@f			; 8bit目が1だとIN
		movem.l	a0-a1,-(sp)
		lea.l	EndPoint1,a0		; OUTだった場合は2つ目のエンドポイントの内容をコピーする
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
		move.b	#8,MaxPacketSizeL	; さらにMaxPacketSizeを強制的に8にする(ひどい)
@@:
; ---------------------------
		; エンドポイント１のパケットサイズが９以上ならば未対応
		cmpi.b	#$08,MaxPacketSizeL
		bhi	no_joypad		

		_StrPrint2	'□正常に取得できました',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#10*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

		_StrPrint2	'■コンフィギュレーション設定',cr,lf

		; ■コンフィギュレーション設定

		move.b	#$01,usb_addr		; アドレス = 1
		move.b	#$00,usb_endp		; エンドポイント = 0
		lea.l	Buf_StdDescriptor(pc),a0
		move.l	a0,usb_buf_address	; 

		jbsr	_SetConfiguration	; コンフィギュレーション設定
		tst.b	d0
		bne	err_exit

		_StrPrint2	'□正常に設定できました',cr,lf,cr,lf

	;---------------------------------------------------------------------
		move.l	#100*20,d1
		jbsr	delay50ns
	;---------------------------------------------------------------------

	; ■接続されているのがジョイパッドならば、プロトコル設定はしない
		tst.b	Protocol
		beq	9f

		_StrPrint2	'■プロトコル設定',cr,lf

		; ■プロトコル設定

		move.b	#$01,usb_addr		; アドレス = 1
		move.b	#$00,usb_endp		; エンドポイント = 0
		move.b	#0,usb_protocol		; プロトコル = 0

		jbsr	_SetProtocol		; プロトコル設定

		; Set Protocolの結果は無視
	9:

	;---------------------------------------------------------------------

	; ■接続されているのがジョイパッド以外ならば、定義ファイルは使用しない
		tst.b	Protocol
		bne	9f

	; ■取得したベンダーＩＤを元に定義ファイルを検索する
		jbsr	GetUsbPadInfo
		bmi	8f
		bne	err_exit

	; ■パケットサイズが指定されていたら(0以外)定義データで上書き
		tst.b	PSIZE
		beq	@f
		move.b	PSIZE,MaxPacketSizeL
	@@:
	; ■インタラプト転送の周期が指定されていたら(0以外)定義データで上書き
		tst.b	INTR
		beq	@f
		move.b	INTR,bInterval
	@@:
	; ■リポートＩＤを格納
		move.b	REPID,usb_report_id
	@@:
		jbsr	ChkUsbPadInfo
		bne	err_exit
	8:
	; ■自己書換
		jbsr	WriteUsbPadInfo
	9:
	;---------------------------------------------------------------------
	movem.l	(sp)+,d0-d7/a0-a6

	; ■接続されているのがジョイパッドならば、IOCS_JOYGETを置き換える
		tst.b	Protocol
		bne	@f

		movem.l	d0-d1/a1,-(sp)
		move.w	#$013B,d1			; d1 = _JOYGETを置き換える
		lea.l	usb_joy_vct(pc),a1		; a1 = 処理アドレス
		IOCS	_B_INTVCS			; 割り込みハンドラを neq_joy_vct に設定
		move.l	d0,old_joy_vct			; 元の割り込みアドレスをしまう
		movem.l	(sp)+,d0-d1/a1
	@@:
		move.l	d0,a1				; 
		IOCS	_B_SUPER			; モードを元に戻す

	; ■常駐メッセージの表示
		tst.b	Protocol			; 
		bne	1f				; 
		pea	stay_msg_joy			; 'ジョイパッドモード常駐しました.'
		bra.b	9f				; 
	1:						; 
		pea	stay_msg_mouse			; 'マウスモードで常駐しました.'
	9:						; 
		DOS	_PRINT				; 

	; ■以下前準備

		move.b	#$01,usb_addr			; アドレス = 1
		move.b	#$01,usb_endp			; エンドポイント = 1
		move.b	MaxPacketSizeL,usb_length	; データ転送長 = ?

		move.b	bInterval,usb_interrupt_count	; インタラプト転送割り込み周期をセット
		move.b	#1,usb_interrupt_flg		; インタラプト転送開始フラグ = 許可

	; ■オプションｃが指定されていたらパケットチェックモード

		tst.b	optflg_C			; 
		beq	@f				; 

		clr.l	a1				; 
		IOCS	_B_SUPER			; スーパーバイザモードにする

	movem.l	d0-d7/a0-a6,-(sp)			; レジスタ退避

		move.b	#2,d1				; 
		IOCS	_B_CLR_ST			; テキスト画面の初期化
	;----------------------------------------------
		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; 水色(強調)

		_StrPrint	'VID   : '		; VIDの表示

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; 白色

		move.w	VendorID,d0			; 
		rol.w	#8,d0				; エンディアン変換
		jbsr	hex_print_w			; 値の表示

		_StrPrint	cr,lf
	;----------------------------------------------
		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; 水色(強調)

		_StrPrint	'PID   : '		; PIDの表示

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; 白色

		move.w	ProductID,d0			; 
		rol.w	#8,d0				; エンディアン変換
		jbsr	hex_print_w			; 値の表示

		_StrPrint	cr,lf
	;----------------------------------------------
		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; 水色(強調)

		_StrPrint	'PSIZE : '		; PSIZEの表示

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; 白色

		clr.w	d0				; 
		move.b	MaxPacketSizeL,d0		; 
		jbsr	hex_print_b_sp			; 値の表示

		_StrPrint	cr,lf
	;----------------------------------------------
		move.w	#1+4,d1				; 
		IOCS	_B_COLOR			; 水色(強調)

		_StrPrint	'INTR  : '		; INTRの表示

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; 白色

		clr.w	d0				; 
		move.b	bInterval,d0			; 
		jbsr	hex_print_b_sp			; 値の表示

		_StrPrint	cr,lf
	;----------------------------------------------
		move.w	#1,d1				; 
		IOCS	_B_COLOR			; 水色(強調)

		move.w	#0,d1				; 
		move.w	#8,d2				; 
		IOCS	_B_LOCATE			; 位置指定

		_StrPrint	'Push ESC to exit.'	; 終了方法の表示

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; 白色

		move.w	#0,d1				; 
		move.w	#4,d2				; 
		IOCS	_B_LOCATE			; 位置指定

		move.w	#2+4,d1				; 
		IOCS	_B_COLOR			; 色黄色

		_StrPrint	'-------------------------------------',cr,lf
		_StrPrint	'              00 01 02 03 04 05 06 07',cr,lf

		move.w	#3,d1				; 
		IOCS	_B_COLOR			; テキスト画面の初期化
	1:
		move.w	#0,d1				; 
		move.w	#6,d2				; 
		IOCS	_B_LOCATE			; 位置指定

		move.l	#10*20,d1			; 10ms待つ
		jbsr	delay50ns			; 

		jbsr	print_Buf_Work			; インタラプト転送されたバッファの内容を表示

		move.w	#0,d1				; 
		move.w	#8,d2				; 
		IOCS	_B_LOCATE			; 位置指定

		btst.b	#1,$800				; 
		bne	program_exit			; ＥＳＣキーが押されたら終了
		bra	1b
	@@:
		move.w	#0,-(sp)			; 終了コード = 0
		move.l	#tsr_bottom-tsr_top,-(sp)	; 常駐バイト数 = tsr_bottom-tsr_top
		DOS	_KEEPPR				; 常駐終了

err_exit:
		jbsr	print_return_code
		_StrPrint	'設定に失敗しました.',cr,lf
		bra	program_exit

no_joypad:
		jbsr	print_return_code
		_StrPrint	'対象外のデバイスが接続されています.',cr,lf

;---------------------------------------------------------------------------
; エラー時などの終了処理
;---------------------------------------------------------------------------

program_exit:

	; 終了処理の最良の方法は不確定

		jbsr	CmdNereidIntOff			; nereid int off
		move.l	#2*20,d1			; 2ms待つ
		jbsr	delay50ns

		move.w	#100,d7
	@@:
		move.b	#REG_INT_STATUS,SL811HST_ADDR	; 割り込みステータスレジスタ
		move.b	#$FF,SL811HST_DATA		; 全割り込みフラグリセット
		dbra	d7,@b

		move.b	#$06,SL811HST_ADDR		; 割り込みイネーブルレジスタ
		move.b	#$00,SL811HST_DATA		; 全タイマ割り込みを禁止

	move.l	#10*20,d1				; 10ms待つ
	jbsr	delay50ns

		jbsr	CmdNereidPowerOff		; nereid power off
		jbsr	CmdNereidResetOn		; nereid reset on

		move.w	#$FB,d1				; 
		movea.l	old_int,a1			; 
		IOCS	_B_INTVCS			; 割り込みハンドラを元に戻す

	movem.l	(sp)+,d0-d7/a0-a6			; レジスタ復帰

;		move.l	old_mouse_vct,$150
;		move.l	old_mouse_vct,$154

		move.l	d0,a1				; 
		IOCS	_B_SUPER			; モードを元に戻す

		_exit
no_device:
		_StrPrint	'デバイスが接続されていません',cr,lf
		jbra	program_exit

		.data
;-----------------------------------------------------------
; メッセージ関連のデータ
;-----------------------------------------------------------
		.even
title_msg:
		.dc.b	'USB JoyPad & Mouse Driver USBJOY ver.1.3e+z1 (C)2006-2009 plastic / akuzo / tantan',13,10,0
stay_msg_joy:
		.dc.b	'ジョイパッドモードで常駐しました.',13,10,0
stay_msg_mouse:
		.dc.b	'マウスモードで常駐しました.',13,10,0
rel_msg:
		.dc.b	'常駐解除しました.',13,10,0
usage_msg:
		.dc.b	'usage : usbjoy [-opt1] [-opt2]･･･',13,10
		.dc.b	'  -a1 : シンクロ連射(1frame毎にボタンのON/OFFを切り替え)',13,10
		.dc.b	'  -a2 : シンクロ連射(2frame毎にボタンのON/OFFを切り替え)',13,10
		.dc.b	'  -c  : エンドポイントからのパケット内容チェックモード',13,10
		.dc.b	'  -h  : ヘルプ表示',13,10
; -------- patch +z1 --------
;		.dc.b	'  -x  : Xbox 360系のコントローラを使用する場合に指定',13,10,0
		.dc.b	'  -x  : Xbox 360系のコントローラを使用する場合に指定',13,10
 	   	.dc.b   '  -z  : ZUIKI X68000 Z JOYCARD を使用する場合に指定',13,10,0
; ---------------------------

		.even
def_filename:
		.dc.b	'usbjoy.def',0	; 定義ファイル名
*---------------------------------------------------------------------------------------
		.bss									
*---------------------------------------------------------------------------------------
filename:
		.ds.b	256		; パス＋定義ファイル名を格納するためのワーク

		.even
handle:
		.ds.w	1		; ファイルハンドルを格納するためのワーク

		.align	4
FileSize:
		.ds.l	1		; 取得したファイルサイズを格納

		.even
WorkBuffer:
		.ds.b	32768+4		; 定義ファイル全体を読み込むためのワーク
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
