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
	//Перечисление только для генерации *.eep файла. Значения по умолчанию хранятся в d_eeprom_default
	e_eeprom_init_flag:	  .db	0xAA,	/* Флаг ЕЕПРОМ 										*/\
								0x00,	/* Интервал контрольного сигнала - старший байт		*/\
								0x0A,	/* Интервал контрольного сигнала - младший байт		*/\
								0x00,	/* Длительность контрольного сигнала - старший байт	*/\
								0x03,	/* Длительность контрольного сигнала - младший байт	*/\
								0x00,	/* Длительность аварийного сигнала - старший байт	*/\
								0x01,	/* Длительность аварийного сигнала - младший байт	*/\
								0x69,	/* Коррекция времени задержки в микроконтроллере	*/\
								0x53,	/* Несущая частота - Frequency Band Select			*/\
								0x64,	/* Несущая частота - Nominal Carrier Frequency 1	*/\
								0x00,	/* Несущая частота - Nominal Carrier Frequency 0	*/\
								0x7F,	/* Коррекция частоты кварца	передатчика				*/\
								0x06, 	/* Девиация частоты передатчика						*/\
								0x04,	/* Мощность излучения передатчика					*/\
								0x00, 	/* Предел шкалы акселерометра						*/\
								0x0A	/* Уровень срабатывания акселерометра				*/

	
	
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


	s_d100_2:					.byte 1		//вычисляемое количество тактов для задержки 100 мс
	s_d100_1:					.byte 1
	s_d100_0:					.byte 1

	s_d250_2:					.byte 1		//вычисляемое количество тактов для задержки 250 мс
	s_d250_1:					.byte 1
	s_d250_0:					.byte 1



	.def var13 = r0			//для функции деления
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

	.def fCK2 = r13			//вычисляемая частота тактирования
	.def fCK1 = r14
	.def fCK0 = r15

	.def r_temp = r16		//временная свалка
	.def r_eadr = r17		//адрес еепром
	.def r_cyc = r18		//для циклов
	.def r_spi_hi = r19		//аккумулятор SPI
	.def r_spi_lo = r20		//аккумулятор SPI
	.def lc = r21			//для функции деления


	//R23-R25 - используются в подпрограммах задержки

	//.def	XH	= R27		Интервал следования контрольных сигналов
	//.def	XL	= R26

	//.def	YH	= R29		Длительность контрольных сигналов
	//.def	YL	= R28

	//.def	ZH	= R31		Длительность сигналов сигнализации
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
	//Очистка оперативной памяти (забиваем нулями) 
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


	//Очистка РОН (забиваем нулями)	
	ldi	ZL, 30				
	clr ZH	
_flush_REG:
	dec ZL	
	st Z, ZH		
	brne _flush_REG	
	

	//Стэк
	ldi r_temp, low(RAMEND)			
	out SPL, r_temp


	//Направление портов
	ldi r_temp, (0<<DDB5)|(0<<DDB4)|(1<<DDB3)|(1<<DDB2)|(1<<DDB1)|(1<<DDB0)		
	out DDRB, r_temp


	//Уровень или подтяжка
	ldi r_temp, (1<<PB5)|(0<<PB4)|(1<<PB3)|(1<<PB2)|(0<<PB1)|(0<<PB0)			
	out PORTB, r_temp


	//Уменьшаем аппетиты
	//Выключаем компаратор
	ldi r_temp, (1<<ACD)
	out ACSR, r_temp

	//Выключаем АЦП
	ldi r_temp, (1<<PRADC)
	out PRR, r_temp

	//Разрешаем сон в режиме IDLE
	ldi r_temp, (1<<SE)|(0<<SM1)|(0<<SM0)
	out MCUCR, r_temp


	//Проверка нулевой ячейки еепром на равность флаговому значению 0xAA
	ldi r_eadr, e_eeprom_init_flag
	rcall EEPROM_READ
	cpi r_temp, 0xAA
	breq _eeprom_to_sram


	//Если значение нулевой ячейки еепром не равно 0xAA, значит записываем всю еепром значениями по умолчанию
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


	//Если значение нулевой ячейки еепром равно 0xAA, значит считываем всю еепром в ОЗУ
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
	

	//Пересчитываем константы для задержек в 100 мс и в 250 мс
	//Расчет тактовой частоты, при условии что пользователь подобрал значение s_delay_correction так, чтобы Focn = 0.5 Гц
	lds fCK0, s_delay_correction
	inc fCK0						//Вычисляем Fck согласно формуле Fck=2*N*Focn*(1+OCR), N=1024, Focn = 0.5 Гц; тогда Fck=1024*(1+OCR)
	ldi r_cyc, 10					//10 раз сдвиг влево дает умножение на 1024
_mul_by_1024:
	lsl fCK0
	rol fCK1
	rol fCK2
	dec r_cyc
	brne _mul_by_1024

	//Расчет задержки в 100 мс; выполняется путем деления частоты тактирования на 10; fCK[2:0]/10
	//делимое - тактовая частота
	clr var13
	mov var12, fCK2
	mov var11, fCK1
	mov var10, fCK0

	//делитель - константа 10
	clr var23
	clr var22
	clr var21
	ldi r_temp, 10
	mov var20, r_temp

	//делим и забираем результат
	rcall DIV32U
	sts s_d100_2, var12
	sts s_d100_1, var11
	sts s_d100_0, var10


	//Расчет задержки 250 мс; деление на 4 (можно было и сдвигом, но у нас есть DIV32U, хуле бы нам не повыпендриваться)
	//делимое - тактовая частота
	clr var13
	mov var12, fCK2
	mov var11, fCK1
	mov var10, fCK0

	//делитель - константа 4
	clr var23
	clr var22
	clr var21
	ldi r_temp, 4
	mov var20, r_temp

	//делим и забираем результат
	rcall DIV32U
	sts s_d250_2, var12
	sts s_d250_1, var11
	sts s_d250_0, var10


	//Сброс микросхемы передатчика
	ldi r_spi_hi, 0x07|0x80
	ldi r_spi_lo, (1<<7)
	rcall SPI_TRANS


	//Сброс микросхемы акселерометра
	ldi r_spi_hi, 0x24
	ldi r_spi_lo, (1<<7)
	rcall SPI_ACCEL

	//Задержка после сброса микросхем
	rcall LONG_DELAY_100ms


	//Инициализация микросхемы передатчика
	ldi ZH, High(d_si4432_settings * 2)
	ldi ZL, Low(d_si4432_settings * 2)
	ldi r_temp, 8
_trans_init_loop:
	lpm r_spi_hi, Z+
	lpm r_spi_lo, Z+
	rcall SPI_TRANS
	dec r_temp
	brne _trans_init_loop	

	//Настройка мощности передатчика
	ldi r_spi_hi, 0x6D|0x80
	lds r_spi_lo, s_tx_power
	sbr r_spi_lo, (1<<3)			//устанавливаем бит lna_sw
	rcall SPI_TRANS

	//Настройка частоты кварца
	ldi r_spi_hi, 0x09|0x80
	lds r_spi_lo, s_freq_correction
	rcall SPI_TRANS	

	//Настройка частоты передатчика
	ldi r_spi_hi, 0x75|0x80
	lds r_spi_lo, s_carrier_band
	cbr r_spi_lo, (1<<7)			//сбрасываем ненужные биты
	rcall SPI_TRANS

	ldi r_spi_hi, 0x76|0x80
	lds r_spi_lo, s_carrier_nom_1
	rcall SPI_TRANS

	ldi r_spi_hi, 0x77|0x80
	lds r_spi_lo, s_carrier_nom_0
	rcall SPI_TRANS

	//Настройка девиации передатчика
	ldi r_spi_hi, 0x72|0x80
	lds r_spi_lo, s_tx_fdev
	rcall SPI_TRANS


	//Инициализация микросхемы акселерометра
	//Настройка пределов шкалы акселерометра
	ldi r_spi_hi, 0x23
	lds r_spi_lo, s_accel_scale
	cbr r_spi_lo, 0b1111_1100		//сбросим лишние биты
	lsl r_spi_lo					//сдвигаем биты FS[1:0] на нужную позицию
	lsl r_spi_lo
	lsl r_spi_lo
	lsl r_spi_lo
	rcall SPI_ACCEL

	//Настройка уровня срабатывания акселерометра
	ldi r_spi_hi, 0x36
	lds r_spi_lo, s_accel_level
	cbr r_spi_lo, (1<<7)			//сбросим лишние биты
	rcall SPI_ACCEL

	//Остальные регистры
	ldi ZH, High(d_lis3dh_settings * 2)
	ldi ZL, Low(d_lis3dh_settings * 2)
	ldi r_temp, 7
_accel_init_loop:
	lpm r_spi_hi, Z+
	lpm r_spi_lo, Z+
	rcall SPI_ACCEL
	dec r_temp
	brne _accel_init_loop


	//Задержка после инициализации микросхем
	rcall LONG_DELAY_100ms


	//Вывод в порт частоты тактирования деленной на 16 (Fck/16) в течении примерно 4 секунд
	//Таймер на максимальный интервал, без прерывания, без переключения порта 
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//Тактовая/0
	out TCCR0B, r_temp	

	ldi r_temp, 1												//Сброс счетчика таймера
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(0<<COM0A0)|(0<<WGM01)|(1<<WGM00)	//Режим 1, без выхода в порт
	out TCCR0A, r_temp

	ldi r_temp, (0<<WGM02)|(1<<CS02)|(0<<CS01)|(1<<CS00)		//Тактовая/1024
	out TCCR0B, r_temp

_loop:					//Цикл на меандр периодом 16 тактов, выход из цикла по переполнению таймера
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
	sbrc r_temp, TOV0	//2 (при пропуске)
	rjmp pc+2			//2 выход из цикла
	rjmp _loop			//2


	//PCINT прерывание от акселерометра
	ldi r_temp, (1<<PCINT4)			//PCINT4 маска
	out PCMSK, r_temp

	ldi r_temp, (1<<PCIE)			//PCINT включить
	out GIMSK, r_temp

	ldi r_temp, (1<<PCIF)			//Очищаем прерывание PCINT в микроконтроллере
	out GIFR, r_temp


	//Инициализация переменных
	lds XH, s_cont_int_h
	lds XL, s_cont_int_l
	lds YH, s_cont_dur_h
	lds YL, s_cont_dur_l

	sub XL, YL						//Интервал конрольного сигнала это время через которое запускается контрольный сигнал. 
	sbc XH, YH						//Но так как мы отсчитываем интервал между концом предыдущего и началом следующего сигнала, то надо вычесть длительность интервального сигнала
	sts s_cont_int_pause_h, XH		//Пауза после контрольного сигнала s_cont_int_pause = s_cont_int - s_cont_dur
	sts s_cont_int_pause_l, XL


	lds ZH, s_alarm_dur_h
	lds ZL, s_alarm_dur_L
	lds XH, s_cont_int_h
	lds XL, s_cont_int_l

	sub XL, ZL
	sbc XH, ZH
	sts s_alarm_pause_h, XH			//Пауза после аларм сигнала s_alarm_pause = s_cont_int - s_alarm_dur
	sts s_alarm_pause_l, XL


	//Начальное извещение интервальным сигналом. 
	//Делаем rcall на обработчик прерывания, предварительно записав в счетчик контрольного интервала значение 1, тем самым при вызове произойдет декремент до нуля и запуск интервального сигнала
	//После вызова rcall ONESEC происходит запуск SET_TMR_TICK_1s и разрешение прерываний
	ldi XH, 0
	ldi XL, 1	

	rcall ONESEC


MAIN:
	sleep						//спим
	rjmp MAIN





ONESEC:							//каждую секунду возникает это прерывание

	sbiw X, 1					//уменьшаем счетчик контрольного интервала
	breq _control_alert			//если достигли нуля то пора сигнализировать контрольным сигналом	
	reti						//если не достигли нуля то выходим
	
_control_alert:
	rcall TX_ON					//включаем передатчик

_loop_control_sig:				//пищим контрольным сигналом
	rcall SET_TMR_OFF			//сначала 250 мс молчания, чтобы отрылся шумодав	
	rcall LONG_DELAY_250ms

	rcall SET_TMR_BUZZ_Fa		//затем трёхтоновый сигнал по 250 мс каждый
	rcall LONG_DELAY_250ms

	rcall SET_TMR_BUZZ_Sol
	rcall LONG_DELAY_250ms

	rcall SET_TMR_BUZZ_La		//итого 250 мс * 4 = 1 секунда контрольного сигнала
	rcall LONG_DELAY_250ms

	sbiw Y, 1					//декремент пока не достигнем нуля
	brne _loop_control_sig

	rcall SET_TMR_OFF			//выключаем таймер
	rcall TX_OFF				//прекращаем передачу

	lds YH, s_cont_dur_h
	lds YL, s_cont_dur_l		//обновляем счетчик интервального сигнала

	lds XH, s_cont_int_pause_h	//обновляем счетчик контрольного интервала (после интервального)
	lds XL, s_cont_int_pause_l

	rcall SET_TMR_TICK_1s		//запускаем ежесекундный тамер

	reti






MOTION:							//пришло прерывание от акселерометра

	rcall TX_ON					//сразу включаем передетчик

_loop_alarm_sig:

	ldi r_cyc, 5				//малый цикл на 5 итераций по 200 мс, итого 1 секунда
_small_loop_alarm_sig:
	rcall SET_TMR_BUZZ_La
	rcall LONG_DELAY_100ms
	rcall SET_TMR_BUZZ_Si
	rcall LONG_DELAY_100ms
	dec r_cyc
	brne _small_loop_alarm_sig

	sbiw Z, 1					//декремент пока не отпищим сколько задано
	brne _loop_alarm_sig

	rcall SET_TMR_OFF			//выключаем пищалку
	rcall TX_OFF				//прекращаем передачу

	ldi r_temp, (1<<PCIF)		//очищаем прерывание в микроконтроллере
	out GIFR, r_temp

	lds ZH, s_alarm_dur_h		//обновляем счетчик аларм сигнала
	lds ZL, s_alarm_dur_l		

	lds XH, s_alarm_pause_h		//обновляем счетчик интервала ожидания (после паузного)
	lds XL, s_alarm_pause_l		

	rcall SET_TMR_TICK_1s		//запускаем ежесекундный тамер			

	reti







SET_TMR_OFF:
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//Тактовая/0
	out TCCR0B, r_temp	

	ldi r_temp, 0												//Сброс счетчика таймера
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(0<<COM0A0)|(1<<WGM01)|(0<<WGM00)	//Отключаем таймер от порта 
	out TCCR0A, r_temp
	ret






SET_TMR_TICK_1s:
	//Таймер на 1 с интервал, с прерыванием, без переключения порта 
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//Тактовая/0
	out TCCR0B, r_temp	

	ldi r_temp, 0												//Сброс счетчика таймера
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(0<<COM0A0)|(1<<WGM01)|(0<<WGM00)	//Режим CTC, без выхода в порт
	out TCCR0A, r_temp

	lds r_temp, s_delay_correction	//Сравниваем с этим значением чтобы получать прерывание каждую секунду
	out OCR0A, r_temp

	ldi r_temp, (1<<OCIE0A)			//Включаем прерывание OCIE0A
	out TIMSK0, r_temp

	ldi r_temp, (1<<OCF0A)			//Очищаем прерывание
	out TIFR0, r_temp

	ldi r_temp, (0<<WGM02)|(1<<CS02)|(0<<CS01)|(1<<CS00)		//Тактовая/1024
	out TCCR0B, r_temp

	ret






SET_TMR_BUZZ_Fa:
	//Таймер на ноту ФА, без прерывания, с переключением порта
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//Тактовая/0
	out TCCR0B, r_temp	

	ldi r_temp, 0
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(0<<WGM00)	
	out TCCR0A, r_temp

	ldi r_temp, 91			
	out OCR0A, r_temp

	ldi r_temp, (0<<OCIE0A)	
	out TIMSK0, r_temp

	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(1<<CS00)		//Тактовая/1
	out TCCR0B, r_temp

	ret






SET_TMR_BUZZ_Sol:
	//Таймер на ноту СОЛЬ, без прерывания, с переключением порта
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//Тактовая/0
	out TCCR0B, r_temp	

	ldi r_temp, 0
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(0<<WGM00)
	out TCCR0A, r_temp

	ldi r_temp, 81			
	out OCR0A, r_temp

	ldi r_temp, (0<<OCIE0A)	
	out TIMSK0, r_temp

	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(1<<CS00)		//Тактовая/1
	out TCCR0B, r_temp

	ret







SET_TMR_BUZZ_La:
	//Таймер на ноту ЛЯ, без прерывания, с переключением порта
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//Тактовая/0
	out TCCR0B, r_temp	

	ldi r_temp, 0
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(0<<WGM00)	
	out TCCR0A, r_temp

	ldi r_temp, 72				
	out OCR0A, r_temp

	ldi r_temp, (0<<OCIE0A)		
	out TIMSK0, r_temp

	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(1<<CS00)		//Тактовая/1
	out TCCR0B, r_temp

	ret






SET_TMR_BUZZ_Si:
	//Таймер на ноту СИ, без прерывания, с переключением порта
	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(0<<CS00)		//Тактовая/0
	out TCCR0B, r_temp	

	ldi r_temp, 0
	out TCNT0, r_temp

	ldi r_temp, (0<<COM0A1)|(1<<COM0A0)|(1<<WGM01)|(0<<WGM00)	
	out TCCR0A, r_temp

	ldi r_temp, 64				
	out OCR0A, r_temp

	ldi r_temp, (0<<OCIE0A)		
	out TIMSK0, r_temp

	ldi r_temp, (0<<WGM02)|(0<<CS02)|(0<<CS01)|(1<<CS00)		//Тактовая/1
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






EEPROM_READ:					//в r_eadr кладем адрес ячейки, в r_temp появляется считанное значение
	sbic EECR, EEWE
	rjmp PC-1
	out EEARL, r_eadr
	sbi EECR, EERE
	in r_temp, EEDR
	ret




EEPROM_WRITE:					//в r_eadr кладем адрес ячейки, в r_temp кладем значение которое надо записать
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
//Посчитанные константы для задержки находятся в ОЗУ
//Вызов LONG_DELAY_100ms и возврат обратно занимает ровно столько тактов сколько указано в s_d100_2:s_d100_0
//3 такта rcall и 4 такта ret тоже учтены.
	lds r23, s_d100_0	//подготовительные операции
	lds r24, s_d100_1
	lds r25, s_d100_2
	subi r23, 26		//вот это число регулирует подготовительные операции и добавочные такты (rcall и ret)
	sbci r24, 0
	sbci r25, 0

	subi r23, 5			//а вот отсюда собственно начинается цикл задержки
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
	nop					//эти nop обязательны
	nop					//эти nop обязательны
	ret







LONG_DELAY_250ms:
//Посчитанные константы для задержки находятся в ОЗУ
//Вызов LONG_DELAY_250ms и возврат обратно занимает ровно столько тактов сколько указано в s_d100_2:s_d100_0
//3 такта rcall и 4 такта ret тоже учтены.
	lds r23, s_d250_0	//подготовительные операции
	lds r24, s_d250_1
	lds r25, s_d250_2
	subi r23, 26		//вот это число регулирует подготовительные операции и добавочные такты (rcall и ret)
	sbci r24, 0
	sbci r25, 0

	subi r23, 5			//а вот отсюда собственно начинается цикл задержки
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
	nop					//эти nop обязательны
	nop					//эти nop обязательны
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
						.db		0xAA,	/* Флаг ЕЕПРОМ 										*/\
								0x0E,	/* Интервал контрольного сигнала - старший байт		*/\
								0x10,	/* Интервал контрольного сигнала - младший байт		*/\
								0x00,	/* Длительность контрольного сигнала - старший байт	*/\
								0x03,	/* Длительность контрольного сигнала - младший байт	*/\
								0x00,	/* Длительность аварийного сигнала - старший байт	*/\
								0x01,	/* Длительность аварийного сигнала - младший байт	*/\
								0x7C,	/* Коррекция времени задержки в микроконтроллере	*/\
								0x53,	/* Несущая частота - Frequency Band Select			*/\
								0x64,	/* Несущая частота - Nominal Carrier Frequency 1	*/\
								0x00,	/* Несущая частота - Nominal Carrier Frequency 0	*/\
								0x7F,	/* Коррекция частоты кварца	передатчика				*/\
								0x06, 	/* Девиация частоты передатчика						*/\
								0x04,	/* Мощность излучения передатчика					*/\
								0x00, 	/* Предел шкалы акселерометра						*/\
								0x0A,	/* Уровень срабатывания акселерометра				*/\
								"fiztop@yandex.ru"




