//Copyright Feruz Topalov 2021



/* 				Port Pin Configurations

DDR 	PORT 		PUD 	I/O 		Pull-up 	Comment

0 		0 			X 		Input 		No 			Tri-state (Hi-Z)
0 		1 			0 		Input 		Yes 		Pxn will source current if ext. pulled low.
0 		1 			1 		Input 		No 			Tri-state (Hi-Z)

1 		0 			X 		Output 		No 			Output Low (Sink)
1 		1 			X 		Output 		No 			Output High (Source)

*/

	.include  "C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\Appnotes\tn13Adef.inc"


	.macro m_cs_accel_lo
		cbi PORTB, PB3
	.endm

	.macro m_cs_accel_hi
		sbi PORTB, PB3
	.endm

	.macro m_cs_trans_lo
		cbi PORTB, PB2
	.endm

	.macro m_cs_trans_hi
		sbi PORTB, PB2
	.endm

	.macro m_sck_lo
		cbi PORTB, PB1
	.endm

	.macro m_sck_hi
		sbi PORTB, PB1
	.endm

	.macro m_mosi_lo
		cbi PORTB, PB0
	.endm

	.macro m_mosi_hi
		sbi PORTB, PB0
	.endm






	.eseg
	//������������ ������ ��� ��������� *.eep �����. �������� �� ��������� �������� � d_eeprom_default
	e_eeprom_init_flag:	  .db	0xAA,	/* ���� ������ 										*/\
								0x00,	/* �������� ������������ ������� - ������� ����		*/\
								0x0A,	/* �������� ������������ ������� - ������� ����		*/\
								0x00,	/* ������������ ������������ ������� - ������� ����	*/\
								0x03,	/* ������������ ������������ ������� - ������� ����	*/\
								0x00,	/* ������������ ���������� ������� - ������� ����	*/\
								0x01,	/* ������������ ���������� ������� - ������� ����	*/\
								0x69,	/* ��������� ������� �������� � ����������������	*/\
								0x53,	/* ������� ������� - Frequency Band Select			*/\
								0x64,	/* ������� ������� - Nominal Carrier Frequency 1	*/\
								0x00,	/* ������� ������� - Nominal Carrier Frequency 0	*/\
								0x7F,	/* ��������� ������� ������	�����������				*/\
								0x06, 	/* �������� ������� �����������						*/\
								0x04,	/* �������� ��������� �����������					*/\
								0x00, 	/* ������ ����� �������������						*/\
								0x0A	/* ������� ������������ �������������				*/

	
	
	.dseg

	s_eeprom_init_flag:			.byte 1

	s_cont_int_h:				.byte 1
	s_cont_int_l:				.byte 1
	s_cont_dur_h:				.byte 1	
	s_cont_dur_l:				.byte 1
	s_alarm_dur_h:				.byte 1
	s_alarm_dur_l:				.byte 1
	s_delay_correction:			.byte 1	

	s_carrier_band:				.byte 1
	s_carrier_nom_1:			.byte 1
	s_carrier_nom_0:			.byte 1
	s_freq_correction:			.byte 1

	s_tx_fdev:					.byte 1
	s_tx_power:					.byte 1

	s_accel_scale:				.byte 1
	s_accel_level:				.byte 1


	s_cont_int_pause_h:			.byte 1		// s_cont_int_pause = s_cont_int - s_cont_dur
	s_cont_int_pause_l:			.byte 1	

	s_alarm_pause_h:			.byte 1		// s_alarm_pause = s_cont_int - s_alarm_dur
	s_alarm_pause_l:			.byte 1	


	s_d100_2:					.byte 1		//����������� ���������� ������ ��� �������� 100 ��
	s_d100_1:					.byte 1
	s_d100_0:					.byte 1

	s_d250_2:					.byte 1		//����������� ���������� ������ ��� �������� 250 ��
	s_d250_1:					.byte 1
	s_d250_0:					.byte 1



	.def var13 = r0			//��� ������� �������
	.def var12 = r1
	.def var11 = r2
	.def var10 = r3

	.def var23 = r4
	.def var22 = r5
	.def var21 = r6
	.def var20 = r7

	.def mod3 = r8
	.def mod2 = r9
	.def mod1 = r10
	.def mod0 = r11

	.def fCK2 = r13			//����������� ������� ������������
	.def fCK1 = r14
	.def fCK0 = r15

	.def r_temp = r16		//��������� ������
	.def r_eadr = r17		//����� ������
	.def r_cyc = r18		//��� ������
	.def r_spi_hi = r19		//����������� SPI
	.def r_spi_lo = r20		//����������� SPI
	.def lc = r21			//��� ������� �������


	//R23-R25 - ������������ � ������������� ��������

	//.def	XH	= R27		�������� ���������� ����������� ��������
	//.def	XL	= R26

	//.def	YH	= R29		������������ ����������� ��������
	//.def	YL	= R28

	//.def	ZH	= R31		������������ �������� ������������
	//.def	ZL	= R30


	.cseg
	.org 0

;---INERRUPTS---
rjmp START  ; RESET			
	reti	; EXT_INT0  	
rjmp MOTION ; PCINT0	  
	reti	; TIMER0_OVF  
	reti    ; EE_RDY  	
	reti    ; ANA_COMP  
rjmp ONESEC ; TIMER0_COMPA 	
	reti 	; TIMER0_COMPB	
	reti	; WTD		
	reti 	; ADC  		   
;---------------


START:
	//������� ����������� ������ (�������� ������) 
	ldi ZL, Low(SRAM_START)	
	ldi ZH, High(SRAM_START)
	ldi	YL, Low(RAMEND)	
	ldi	YH, High(RAMEND)
	clr	r_temp
_flush_RAM:		
	st Z+, r_temp		
	cp YL, ZL
	cpc YH, ZH
	brsh _flush_RAM


	//������� ��� (�������� ������)	
	ldi	ZL, 30				
	clr ZH	
_flush_REG:
	dec ZL	
	st Z, ZH		
	brne _flush_REG	
	

	//����
	ldi r_temp, low(RAMEND)			
	out SPL, r_temp


	//����������� ������
	ldi r_temp, (0<<DDB5)|(0<<DDB4)|(1<<DDB3)|(1<<DDB2)|(1<<DDB1)|(1<<DDB0)		
	out DDRB, r_temp


	//������� ��� ��������
	ldi r_temp, (1<<PB5)|(0<<PB4)|(1<<PB3)|(1<<PB2)|(0<<PB1)|(0<<PB0)			
	out PORTB, r_temp


	//��������� ��������
	//��������� ����������
	ldi r_temp, (1<<ACD)
	out ACSR, r_temp

	//��������� ���
	ldi r_temp, (1<<PRADC)
	out PRR, r_temp

	//��������� ��� � ������ IDLE
	ldi r_temp, (1<<SE)|(0<<SM1)|(0<<SM0)
	out MCUCR, r_temp


	//�������� ������� ������ ������ �� �������� ��������� �������� 0xAA
	ldi r_eadr, e_eeprom_init_flag
	rcall EEPROM_READ
	cpi r_temp, 0xAA
	breq _eeprom_to_sram


	//���� �������� ������� ������ ������ �� ����� 0xAA, ������ ���������� ��� ������ ���������� �� ���������
	ldi ZH, High(d_eeprom_default * 2)		
	ldi ZL, Low(d_eeprom_default * 2)
	ldi r_cyc, 32
	ldi r_eadr, 0
_eeprom_write_default:
	lpm r_temp, Z+
	rcall EEPROM_WRITE
	inc r_eadr
	dec r_cyc
	brne _eeprom_write_default


	//���� �������� ������� ������ ������ ����� 0xAA, ������ ��������� ��� ������ � ���
_eeprom_to_sram:
	ldi XH, High(s_eeprom_init_flag)			
	ldi XL, Low(s_eeprom_init_flag)
	ldi r_cyc, 16
	ldi r_eadr, e_eeprom_init_flag
_copy:
	rcall EEPROM_READ
	st X+, r_temp
	inc r_eadr
	dec r_cyc
	brne _copy
	

	//������������� ��������� ��� �������� � 100 �� � � 250 ��
	//������ �������� �������, ��� ������� ��� ������������ �������� �������� s_delay_correction ���, ����� Focn = 0.5 ��
	lds fCK0, s_delay_correction
	inc fCK0						//��������� Fck �������� ������� Fck=2*N*Focn*(1+OCR), N=1024, Focn = 0.5 ��; ����� Fck=1024*(1+OCR)
	ldi r_cyc, 10					//10 ��� ����� ����� ���� ��������� �� 1024
_mul_by_1024:
	lsl fCK0
	rol fCK1
	rol fCK2
	dec r_cyc
	brne _mul_by_1024

	//������ �������� � 100 ��; ����������� ����� ������� ������� ������������ �� 10; fCK[2:0]/10
	//������� - �������� �������
	clr var13
	mov var12, fCK2
	mov var11, fCK1
	mov var10, fCK0

	//�������� - ��������� 10
	clr var23
	clr var22
	clr var21
	ldi r_temp, 10
	mov var20, r_temp

	//����� � �������� ���������
	rcall DIV32U
	sts s_d100_2, var12
	sts s_d100_1, var11
	sts s_d100_0, var10


	//������ �������� 250 ��; ������� �� 4 (����� ���� � �������, �� � ��� ���� DIV32U, ���� �� ��� �� ����������������)
	//������� - �������� �������
	clr var13
	mov var12, fCK2
	mov var11, fCK1
	mov var10, fCK0

	//�������� - ��������� 4
	clr var23
	clr var22
	clr var21
	ldi r_temp, 4
	mov var20, r_temp

	//����� � �������� ���������
	rcall DIV32U
	sts s_d250_2, var12
	sts s_d250_1, var11
	sts s_d250_0, var10


	//����� ���������� �����������
	ldi r_spi_hi, 0x07|0x80
	ldi r_spi_lo, (1<<7)
	rcall SPI_TRANS


	//����� ���������� �������������
	ldi r_spi_hi, 0x24
	ldi r_spi_lo, (1<<7)
	rcall SPI_ACCEL

	//�������� ����� ������ ���������
	rcall LONG_DELAY_100ms


	//������������� ���������� �����������
	ldi ZH, High(d_si4432_settings * 2)
	ldi ZL, Low(d_si4432_settings * 2)
	ldi r_temp, 8
_trans_init_loop:
	lpm r_spi_hi, Z+
	lpm r_spi_lo, Z+
	rcall SPI_TRANS
	dec r_temp
	brne _trans_init_loop	

	//��������� �������� �����������
	ldi r_spi_hi, 0x6D|0x80
	lds r_spi_lo, s_tx_power
	sbr r_spi_lo, (1<<3)			//������������� ��� lna_sw
	rcall SPI_TRANS

	//��������� ������� ������
	ldi r_spi_hi, 0x09|0x80
	lds r_spi_lo, s_freq_correction
	rcall SPI_TRANS	

	//��������� ������� �����������
	ldi r_spi_hi, 0x75|0x80
	lds r_spi_lo, s_carrier_band
	cbr r_spi_lo, (1<<7)			//���������� �������� ����
	rcall SPI_TRANS

	ldi r_spi_hi, 0x76|0x80
	lds r_spi_lo, s_carrier_nom_1
	rcall SPI_TRANS

	ldi r_spi_hi, 0x77|0x80
	lds r_spi_lo, s_carrier_nom_0
	rcall SPI_TRANS

	//��������� �������� �����������
	ldi r_spi_hi, 0x72|0x80
	lds r_spi_lo, s_tx_fdev
	rcall SPI_TRANS


	//������������� ���������� �������������
	//��������� �������� ����� �������������
	ldi r_spi_hi, 0x23
	lds r_spi_lo, s_accel_scale
	cbr r_spi_lo, 0b1111_1100		//������� ������ ����
	lsl r_spi_lo					//�������� ���� FS[1:0] �� ������ �������
	lsl r_spi_lo
	lsl r_spi_lo
	lsl r_spi_lo
	rcall SPI_ACCEL

	//��������� ������ ������������ �������������
	ldi r_spi_hi, 0x36
	lds r_spi_lo, s_accel_level
	cbr r_spi_lo, (1<<7)			//������� ������ ����
	rcall SPI_ACCEL

	//��������� ��������
	ldi ZH, High(d_lis3dh_settings * 2)
	ldi ZL, Low(d_lis3dh_settings * 2)
	ldi r_temp, 7
_accel_init_loop:
	lpm r_spi_hi, Z+
	lpm r_spi_lo, Z+
	rcall SPI_ACCEL
	dec r_temp
	brne _accel_init_loop


	//�������� ����� ������������� ���������
	rcall LONG_DELAY_100ms


	//����� � ���� ������� ������������ �������� �� 16 (Fck/16) � ������� �������� 4 ������
	//������ �� ������������ ��������, ��� ����������, ��� ������������ ����� 
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//��������/0
	out TCCR0B, r_temp	

	ldi r_temp, 1												//����� �������� �������
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(0<<COM0A0)|(0<<WGM01)|(1<<WGM00)	//����� 1, ��� ������ � ����
	out TCCR0A, r_temp

	ldi r_temp, (0<<WGM02)|(1<<CS02)|(0<<CS01)|(1<<CS00)		//��������/1024
	out TCCR0B, r_temp

_loop:					//���� �� ������ �������� 16 ������, ����� �� ����� �� ������������ �������
	m_mosi_lo			//2
	nop					//1
	nop					//1
	nop					//1
	nop					//1
	nop					//1
	nop					//1
	m_mosi_hi			//2
	nop					//1
	in r_temp, TIFR0	//1
	sbrc r_temp, TOV0	//2 (��� ��������)
	rjmp pc+2			//2 ����� �� �����
	rjmp _loop			//2


	//PCINT ���������� �� �������������
	ldi r_temp, (1<<PCINT4)			//PCINT4 �����
	out PCMSK, r_temp

	ldi r_temp, (1<<PCIE)			//PCINT ��������
	out GIMSK, r_temp

	ldi r_temp, (1<<PCIF)			//������� ���������� PCINT � ����������������
	out GIFR, r_temp


	//������������� ����������
	lds XH, s_cont_int_h
	lds XL, s_cont_int_l
	lds YH, s_cont_dur_h
	lds YL, s_cont_dur_l

	sub XL, YL						//�������� ����������� ������� ��� ����� ����� ������� ����������� ����������� ������. 
	sbc XH, YH						//�� ��� ��� �� ����������� �������� ����� ������ ����������� � ������� ���������� �������, �� ���� ������� ������������ ������������� �������
	sts s_cont_int_pause_h, XH		//����� ����� ������������ ������� s_cont_int_pause = s_cont_int - s_cont_dur
	sts s_cont_int_pause_l, XL


	lds ZH, s_alarm_dur_h
	lds ZL, s_alarm_dur_L
	lds XH, s_cont_int_h
	lds XL, s_cont_int_l

	sub XL, ZL
	sbc XH, ZH
	sts s_alarm_pause_h, XH			//����� ����� ����� ������� s_alarm_pause = s_cont_int - s_alarm_dur
	sts s_alarm_pause_l, XL


	//��������� ��������� ������������ ��������. 
	//������ rcall �� ���������� ����������, �������������� ������� � ������� ������������ ��������� �������� 1, ��� ����� ��� ������ ���������� ��������� �� ���� � ������ ������������� �������
	//����� ������ rcall ONESEC ���������� ������ SET_TMR_TICK_1s � ���������� ����������
	ldi XH, 0
	ldi XL, 1	

	rcall ONESEC


MAIN:
	sleep						//����
	rjmp MAIN





ONESEC:							//������ ������� ��������� ��� ����������

	sbiw X, 1					//��������� ������� ������������ ���������
	breq _control_alert			//���� �������� ���� �� ���� ��������������� ����������� ��������	
	reti						//���� �� �������� ���� �� �������
	
_control_alert:
	rcall TX_ON					//�������� ����������

_loop_control_sig:				//����� ����������� ��������
	rcall SET_TMR_OFF			//������� 250 �� ��������, ����� ������� �������	
	rcall LONG_DELAY_250ms

	rcall SET_TMR_BUZZ_Fa		//����� ���������� ������ �� 250 �� ������
	rcall LONG_DELAY_250ms

	rcall SET_TMR_BUZZ_Sol
	rcall LONG_DELAY_250ms

	rcall SET_TMR_BUZZ_La		//����� 250 �� * 4 = 1 ������� ������������ �������
	rcall LONG_DELAY_250ms

	sbiw Y, 1					//��������� ���� �� ��������� ����
	brne _loop_control_sig

	rcall SET_TMR_OFF			//��������� ������
	rcall TX_OFF				//���������� ��������

	lds YH, s_cont_dur_h
	lds YL, s_cont_dur_l		//��������� ������� ������������� �������

	lds XH, s_cont_int_pause_h	//��������� ������� ������������ ��������� (����� �������������)
	lds XL, s_cont_int_pause_l

	rcall SET_TMR_TICK_1s		//��������� ������������ �����

	reti






MOTION:							//������ ���������� �� �������������

	rcall TX_ON					//����� �������� ����������

_loop_alarm_sig:

	ldi r_cyc, 5				//����� ���� �� 5 �������� �� 200 ��, ����� 1 �������
_small_loop_alarm_sig:
	rcall SET_TMR_BUZZ_La
	rcall LONG_DELAY_100ms
	rcall SET_TMR_BUZZ_Si
	rcall LONG_DELAY_100ms
	dec r_cyc
	brne _small_loop_alarm_sig

	sbiw Z, 1					//��������� ���� �� ������� ������� ������
	brne _loop_alarm_sig

	rcall SET_TMR_OFF			//��������� �������
	rcall TX_OFF				//���������� ��������

	ldi r_temp, (1<<PCIF)		//������� ���������� � ����������������
	out GIFR, r_temp

	lds ZH, s_alarm_dur_h		//��������� ������� ����� �������
	lds ZL, s_alarm_dur_l		

	lds XH, s_alarm_pause_h		//��������� ������� ��������� �������� (����� ��������)
	lds XL, s_alarm_pause_l		

	rcall SET_TMR_TICK_1s		//��������� ������������ �����			

	reti







SET_TMR_OFF:
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//��������/0
	out TCCR0B, r_temp	

	ldi r_temp, 0												//����� �������� �������
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(0<<COM0A0)|(1<<WGM01)|(0<<WGM00)	//��������� ������ �� ����� 
	out TCCR0A, r_temp
	ret






SET_TMR_TICK_1s:
	//������ �� 1 � ��������, � �����������, ��� ������������ ����� 
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//��������/0
	out TCCR0B, r_temp	

	ldi r_temp, 0												//����� �������� �������
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(0<<COM0A0)|(1<<WGM01)|(0<<WGM00)	//����� CTC, ��� ������ � ����
	out TCCR0A, r_temp

	lds r_temp, s_delay_correction	//���������� � ���� ��������� ����� �������� ���������� ������ �������
	out OCR0A, r_temp

	ldi r_temp, (1<<OCIE0A)			//�������� ���������� OCIE0A
	out TIMSK0, r_temp

	ldi r_temp, (1<<OCF0A)			//������� ����������
	out TIFR0, r_temp

	ldi r_temp, (0<<WGM02)|(1<<CS02)|(0<<CS01)|(1<<CS00)		//��������/1024
	out TCCR0B, r_temp

	ret






SET_TMR_BUZZ_Fa:
	//������ �� ���� ��, ��� ����������, � ������������� �����
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//��������/0
	out TCCR0B, r_temp	

	ldi r_temp, 0
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(0<<WGM00)	
	out TCCR0A, r_temp

	ldi r_temp, 91			
	out OCR0A, r_temp

	ldi r_temp, (0<<OCIE0A)	
	out TIMSK0, r_temp

	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(1<<CS00)		//��������/1
	out TCCR0B, r_temp

	ret






SET_TMR_BUZZ_Sol:
	//������ �� ���� ����, ��� ����������, � ������������� �����
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//��������/0
	out TCCR0B, r_temp	

	ldi r_temp, 0
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(0<<WGM00)
	out TCCR0A, r_temp

	ldi r_temp, 81			
	out OCR0A, r_temp

	ldi r_temp, (0<<OCIE0A)	
	out TIMSK0, r_temp

	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(1<<CS00)		//��������/1
	out TCCR0B, r_temp

	ret







SET_TMR_BUZZ_La:
	//������ �� ���� ��, ��� ����������, � ������������� �����
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//��������/0
	out TCCR0B, r_temp	

	ldi r_temp, 0
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(0<<WGM00)	
	out TCCR0A, r_temp

	ldi r_temp, 72				
	out OCR0A, r_temp

	ldi r_temp, (0<<OCIE0A)		
	out TIMSK0, r_temp

	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(1<<CS00)		//��������/1
	out TCCR0B, r_temp

	ret






SET_TMR_BUZZ_Si:
	//������ �� ���� ��, ��� ����������, � ������������� �����
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//��������/0
	out TCCR0B, r_temp	

	ldi r_temp, 0
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(0<<WGM00)	
	out TCCR0A, r_temp

	ldi r_temp, 64				
	out OCR0A, r_temp

	ldi r_temp, (0<<OCIE0A)		
	out TIMSK0, r_temp

	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(1<<CS00)		//��������/1
	out TCCR0B, r_temp

	ret





TX_ON:
	ldi r_spi_hi, 0x07|0x80
	ldi r_spi_lo, 0x08
	rcall SPI_TRANS
	ret



TX_OFF:
	ldi r_spi_hi, 0x07|0x80
	ldi r_spi_lo, 0x00
	rcall SPI_TRANS
	ret






SPI_ACCEL:	
	ldi	r_cyc, 16	
	m_cs_accel_lo	

_spi_accel_loop:
	lsl	r_spi_lo		
	rol	r_spi_hi		
	brcc _lo_accel_mosi
	m_mosi_hi
	m_sck_hi
	m_sck_lo		
	rjmp _spi_accel_end

_lo_accel_mosi:
	m_mosi_lo
	m_sck_hi
	m_sck_lo

_spi_accel_end:			
	dec	r_cyc
	brne _spi_accel_loop
	m_mosi_lo
	m_cs_accel_hi
	ret






SPI_TRANS:	
	ldi	r_cyc, 16	
	m_cs_trans_lo	

_spi_trans_loop:
	lsl	r_spi_lo		
	rol	r_spi_hi		
	brcc _lo_trans_mosi
	m_mosi_hi
	m_sck_hi
	m_sck_lo
	rjmp _spi_trans_end	

_lo_trans_mosi:
	m_mosi_lo
	m_sck_hi
	m_sck_lo
	
_spi_trans_end:			
	dec	r_cyc
	brne _spi_trans_loop
	m_mosi_lo
	m_cs_trans_hi
	ret






EEPROM_READ:					//� r_eadr ������ ����� ������, � r_temp ���������� ��������� ��������
	sbic EECR, EEWE
	rjmp PC-1
	out EEARL, r_eadr
	sbi EECR, EERE
	in r_temp, EEDR
	ret




EEPROM_WRITE:					//� r_eadr ������ ����� ������, � r_temp ������ �������� ������� ���� ��������
	sbic EECR, EEWE
	rjmp PC-1
	out EEDR, r_temp
	out EEARL, r_eadr
	sbi EECR, EEMWE
	sbi EECR, EEWE
	ret






;-----------------------------------------------------------------------------:
; 32bit/32bit Unsigned Division
;
; http://elm-chan.org/docs/avrlib/div32.txt
;
; Register Variables
;  Call:  var1[3:0] = dividend (0x00000000..0xffffffff)
;         var2[3:0] = divisor (0x00000001..0x7fffffff)
;         mod[3:0]  = <don't care>
;         lc        = <don't care> (high register must be allocated)
;
;  Result:var1[3:0] = var1[3:0] / var2[3:0]
;         var2[3:0] = <not changed>
;         mod[3:0]  = var1[3:0] % var2[3:0]
;         lc        = 0
;
; Size  = 26 words
; Clock = 549..677 cycles (+ret)
; Stack = 0 bytes

DIV32U:	clr	mod0		;initialize variables
		clr	mod1		;  mod = 0;
		clr	mod2		;  lc = 32;
		clr	mod3		;
		ldi	lc,32		;/
						;---- calcurating loop
		lsl	var10		;var1 = var1 << 1;
		rol	var11		;
		rol	var12		;
		rol	var13		;/
		rol	mod0		;mod = mod << 1 + carry;
		rol	mod1		;
		rol	mod2		;
		rol	mod3		;/
		cp	mod0,var20	;if (mod => var2) {
		cpc	mod1,var21	; mod -= var2; var1++;
		cpc	mod2,var22	; }
		cpc	mod3,var23	;
		brcs	PC+6	;
		inc	var10		;
		sub	mod0,var20	;
		sbc	mod1,var21	;
		sbc	mod2,var22	;
		sbc	mod3,var23	;/
		dec	lc			;if (--lc > 0)
		brne	PC-19	; continue loop;
		ret






LONG_DELAY_100ms:
//����������� ��������� ��� �������� ��������� � ���
//����� LONG_DELAY_100ms � ������� ������� �������� ����� ������� ������ ������� ������� � s_d100_2:s_d100_0
//3 ����� rcall � 4 ����� ret ���� ������.
	lds r23, s_d100_0	//���������������� ��������
	lds r24, s_d100_1
	lds r25, s_d100_2
	subi r23, 26		//��� ��� ����� ���������� ���������������� �������� � ���������� ����� (rcall � ret)
	sbci r24, 0
	sbci r25, 0

	subi r23, 5			//� ��� ������ ���������� ���������� ���� ��������
	sbci r24, 0
	sbci r25, 0
	brcc pc - 3
	cpi r23, 0xFB
	brcs pc + 8
	breq pc + 7
	cpi r23, 0xFD
	brcs pc + 6
	breq pc + 5
	cpi r23, 0xFF
	brcs pc + 4
	breq pc + 3
	nop					//��� nop �����������
	nop					//��� nop �����������
	ret







LONG_DELAY_250ms:
//����������� ��������� ��� �������� ��������� � ���
//����� LONG_DELAY_250ms � ������� ������� �������� ����� ������� ������ ������� ������� � s_d100_2:s_d100_0
//3 ����� rcall � 4 ����� ret ���� ������.
	lds r23, s_d250_0	//���������������� ��������
	lds r24, s_d250_1
	lds r25, s_d250_2
	subi r23, 26		//��� ��� ����� ���������� ���������������� �������� � ���������� ����� (rcall � ret)
	sbci r24, 0
	sbci r25, 0

	subi r23, 5			//� ��� ������ ���������� ���������� ���� ��������
	sbci r24, 0
	sbci r25, 0
	brcc pc - 3
	cpi r23, 0xFB
	brcs pc + 8
	breq pc + 7
	cpi r23, 0xFD
	brcs pc + 6
	breq pc + 5
	cpi r23, 0xFF
	brcs pc + 4
	breq pc + 3
	nop					//��� nop �����������
	nop					//��� nop �����������
	ret






d_lis3dh_settings:
						.db		0x20|0x00,	0x5F,	/* CTRL_REG1 100Hz LP	*/\
								0x21|0x00,	0x0A,	/* CTRL_REG2			*/\
								0x22|0x00,	0x00,	/* CTRL_REG3			*/\
								0x25|0x00,	0x20,	/* CTRL_REG6			*/\
								0x37|0x00,	0x00,	/* INT2_DURATION		*/\
								0x26|0x80,	0x00,	/* REFERENCE Read		*/\
								0x34|0x00,	0x2A	/* INT2_CFG				*/




d_si4432_settings:
						.db		0x07|0x80,	0x00,	/* Op Mode and Func Contr 1		*/\
								0x05|0x80,	0x00,	/* Interrupt Enable 1			*/\
								0x06|0x80,	0x00,	/* Interrupt Enable 2			*/\
								0x03|0x00,	0x00,	/* Interrupt/Status 1 Read		*/\
								0x04|0x00,	0x00,	/* Interrupt/Status 2 Read		*/\
								0x0B|0x80,	0x12,	/* GPIO Configuration 0			*/\
								0x0C|0x80,	0x15,	/* GPIO Configuration 1			*/\
								0x71|0x80,	0x12	/* Modulation Mode Control 2	*/






d_eeprom_default:
						.db		0xAA,	/* ���� ������ 										*/\
								0x0E,	/* �������� ������������ ������� - ������� ����		*/\
								0x10,	/* �������� ������������ ������� - ������� ����		*/\
								0x00,	/* ������������ ������������ ������� - ������� ����	*/\
								0x03,	/* ������������ ������������ ������� - ������� ����	*/\
								0x00,	/* ������������ ���������� ������� - ������� ����	*/\
								0x01,	/* ������������ ���������� ������� - ������� ����	*/\
								0x7C,	/* ��������� ������� �������� � ����������������	*/\
								0x53,	/* ������� ������� - Frequency Band Select			*/\
								0x64,	/* ������� ������� - Nominal Carrier Frequency 1	*/\
								0x00,	/* ������� ������� - Nominal Carrier Frequency 0	*/\
								0x7F,	/* ��������� ������� ������	�����������				*/\
								0x06, 	/* �������� ������� �����������						*/\
								0x04,	/* �������� ��������� �����������					*/\
								0x00, 	/* ������ ����� �������������						*/\
								0x0A,	/* ������� ������������ �������������				*/\
								"fiztop@yandex.ru"




