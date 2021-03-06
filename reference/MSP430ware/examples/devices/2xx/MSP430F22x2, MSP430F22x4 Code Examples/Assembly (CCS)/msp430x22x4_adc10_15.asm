;*******************************************************************************
;   MSP430F22x4 Demo - ADC10, DTC Sample A10 32x to Flash, Int Ref, DCO
;
;   Description: Use DTC to sample A10 32x, Int reference, and transfer
;   code directly to Flash. Software writes to ADC10SC to trigger sample
;   burst. Timing for Flash programming is important and must meet the device
;   f(FTG) datasheet specification ~ 257kHz - 476kHz
;   Assume default DCO = SMCLK ~1.2MHz.
;   As programmed;
;   Each ADC10 sample & convert = (64+13)*2/SMCLK = 154/SMCLK = 128us
;   Flash write per word = 30/(SMCLK/3) = 90/SMCLK = 75us
;   Enough time is provided between ADC10 conversions for each word moved by
;   the DTC to Flash to program. DTC transfers ADC10 code to Flash 1080h-10BEh.
;   In the Mainloop, the MSP430 waits in LPM0 during conversion and programming,
;   ADC10_ISR(DTC) will force exit from LPM0 in Mainloop on reti.
;
;                MSP430F22x4
;             -----------------
;         /|\|              XIN|-
;          | |                 |
;          --|RST          XOUT|-
;            |                 |
;            |A10              |
;
;  P.Thanigai
;  Texas Instruments Inc.
;  August 2007
;  Built with Code Composer Essentials Version: 2.0
;*******************************************************************************
 .cdecls C,LIST,  "msp430x22x4.h"
                              
;------------------------------------------------------------------------------
            .text                  			; Program reset
;------------------------------------------------------------------------------
RESET       mov.w   #300h,SP                ; Initialize stack pointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupADC10  mov.w   #INCH_10+ADC10DIV_1+ADC10SSEL_3+CONSEQ_2,&ADC10CTL1 ; SMCLK
            mov.w   #SREF_1+ADC10SHT_3+MSC+REFON+ADC10ON+ADC10IE,&ADC10CTL0 ;
            mov.w   #30,&TACCR0             ; Delay to allow Ref to settle
            bis.w   #CCIE,&TACCTL0          ; Compare-mode interrupt.
            mov.w   #TACLR+MC_1+TASSEL_2,&TACTL; up mode, SMCLK
            bis.w   #LPM0+GIE,SR            ; Enter LPM0,enable interrupts
            bic.w   #CCIE,&TACCTL0          ; Disable timer interrupt
            mov.b   #020h,&ADC10DTC1        ; 32 conversions
            mov.w   #FWKEY+FSSEL_2+FN1,&FCTL2  ; SMCLK/3
                                            ;
Mainloop    mov.w   #FWKEY,&FCTL3           ; Lock = 0
            mov.w   #FWKEY+ERASE,&FCTL1     ; Erase bit = 1
            mov.w   #0,&01080h              ; Dummy write to SegB to erase
            bic.w   #ENC,&ADC10CTL0         ;
busy_test   bit     #BUSY,&ADC10CTL1        ; ADC10 core inactive?
            jnz     busy_test               ;
            mov.w   #01080h,&ADC10SA        ; Data buffer start
            mov.w   #FWKEY+WRT,&FCTL1       ; Write bit = 1
            bis.w   #ENC+ADC10SC,&ADC10CTL0 ; Start sampling
            bis.w   #CPUOFF+GIE,SR          ; LPM0, ADC10_ISR will force exit
            mov.w   #FWKEY+LOCK,&FCTL3      ; Lock = 1
            jmp     Mainloop                ; Again, SET BREAKPOINT HERE
                                            ;
;-------------------------------------------------------------------------------
TA0_ISR;    ISR for TACCR0
;-------------------------------------------------------------------------------
            clr.w   &TACTL                  ; clear Timer_A control registers
            bic.w   #LPM0,0(SP)             ; Exit LPM0 on reti
            reti                            ;
;-------------------------------------------------------------------------------
ADC10_ISR;
;-------------------------------------------------------------------------------
            bic.w   #LPM0,0(SP)             ; Exit LPM0 on reti
            reti                            ;
;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET                   ;
            .sect   ".int05"                ; ADC10 Vector
            .short  ADC10_ISR               ;
            .sect   ".int09"                ; Timer_A0 Vector
            .short  TA0_ISR                 ;
            .end