;****************************************************************
; 機能	d0.bに格納されている値を$から始まる16進形式($??)で表示する。
;
; 引数	d0.b	($00～$ff)
;
; 返値	なし
;****************************************************************
		.even
hex_print_b:
		movem.l	d0-d7/a0-a6,-(sp)

		lea	hex_mojiretsu_b,a0	; 
		lea	hex_table_b(pc),a1	; テーブルの先頭番地をa1にセット
		move.b	#'$',(a0)+		; a0番地の先頭に'$'を格納してアドレスを＋１しておく

		moveq.l	#2-1,d7			; ループ回数を１（２回分）にセット
@@:		rol.b	#4,d0			; 最初の４ビットを下位４ビットにする。
		move.l	d0,d1			; マスクをかけると値が変わってしまうため、d1にコピーする
		andi.l	#$0000000f,d1		; 下位４ビットのみにする（０～１５）

		move.b	(a1,d1.w),(a0)+		; 文字変換テーブルを使い文字に変換する
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
; 機能	d0.bに格納されている値を16進形式($????)で表示する。
;
; 引数	d0.b	($0000～$ffff)
;
; 返値	なし
;****************************************************************
		.even
hex_print_w:
		movem.l	d0-d7/a0-a6,-(sp)

		lea	hex_mojiretsu_w,a0	; 
		lea	hex_table_w(pc),a1	; テーブルの先頭番地をa1にセット

		moveq.l	#4-1,d7			; ループ回数を１（４回分）にセット
@@:		rol.w	#4,d0			; 最初の４ビットを下位４ビットにする。
		move.l	d0,d1			; マスクをかけると値が変わってしまうため、d1にコピーする
		andi.l	#$0000000f,d1		; 下位４ビットのみにする（０～１５）

		move.b	(a1,d1.w),(a0)+		; 文字変換テーブルを使い文字に変換する
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
; 機能	d0.bに格納されている値を$から始まる16進形式(??_)で表示する。
;
; 引数	d0.b	($00～$ff)
;
; 返値	なし
;****************************************************************
		.even
hex_print_b_sp:
		movem.l	d0-d7/a0-a6,-(sp)

		lea	hex_mojiretsu_b_sp,a0	; 
		lea	hex_table_b_sp(pc),a1	; テーブルの先頭番地をa1にセット

		moveq.l	#2-1,d7			; ループ回数を１（２回分）にセット
@@:		rol.b	#4,d0			; 最初の４ビットを下位４ビットにする。
		move.l	d0,d1			; マスクをかけると値が変わってしまうため、d1にコピーする
		andi.l	#$0000000f,d1		; 下位４ビットのみにする（０～１５）

		move.b	(a1,d1.w),(a0)+		; 文字変換テーブルを使い文字に変換する
		dbra	d7,@b

		move.b	#' ',(a0)		; 最後に空白を表示する

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
; 機能	d0.lに格納されている値を10進形式で表示する（改行無し）
;
; 引数	d0.l	(-2147483648～2147483647)
;
; 返値	なし
;****************************************************************
.if (REST_SIZE_PRINT=1)
		.even
num_print:
		movem.l	d0-d7/a0-a6,-(SP)

		lea	num_buffer(pc),a0	; 

		tst.l	d0
		beq	num_zero

		sf.b	num_flg			; フラグを降ろす
		move.l	#31,d7			; 31bit目を調べる為に31をセット
		btst.l	d7,d0			; 引数がマイナスの値か？
		beq	@f
		move.b	#'-',(a0)+
		neg.l	d0			; ２の補数にする
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

		cmpi.b	#'0',d2			; その桁が'0'だったか？
		beq	@f
		st.b	num_flg			; フラグを立てる
		bra.b	1f
	@@:
		tst.b	num_flg			; フラグが立っているか？
		beq	2f			; 立っていない
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