;******************************************************************************
;   MSP430F54xA Demo - Software Toggle P1.0 with 12MHz DCO
;
;   Description: Toggle P1.0 by xor'ing P1.0 inside of a software loop.
;   ACLK is rought out on pin P11.0, SMCLK is brought out on P11.2, and MCLK
;   is brought out on pin P11.1.
;   ACLK = REFO = 32kHz, MCLK = SMCLK = 12MHz
;	PMMCOREV = 1 to support up to 12MHz clock
;
;                 MSP430F5438A
;             -----------------
;         /|\|                 |
;          | |            P11.0|-->ACLK
;          --|RST         P11.1|-->MCLK
;            |            P11.2|-->SMCLK
;            |                 |
;            |             P1.0|-->LED
;
;  	Note: 
;      	In order to run the system at up to 12MHz, VCore must be set at 1.6V 
;		or higher. This is done by invoking function SetVCore(), which requires 
;		2 files, hal_pmm.asm and hal_pmm.h, to be included in the project.
;      	hal_pmm.asm and hal_pmm.h are located in the same folder as the code 
;		example. 
;
;   D. Dang
;   Texas Instruments Inc.
;   December 2009
;   Built with CCS Version: 4.0.2 
;******************************************************************************

    .cdecls C,LIST,"msp430x54xA.h"
    .cdecls C,LIST,"hal_pmm.h"
;-------------------------------------------------------------------------------
            .global _main 
            .text                           ; Assemble to Flash memory
;-------------------------------------------------------------------------------
_main
RESET       mov.w   #0x5C00,SP              ; Initialize stackpointer
            mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
            
            mov.w	#PMMCOREV_1, R12		; Set VCore to 1.6V to support 12MHz clock 
            calla	#SetVCore				
            bis.b   #BIT0,&P1DIR            ; P1.0 output
            bis.b   #0x07,&P11DIR           ; ACLK, MCLK, SMCLK set out to pins
            bis.b   #0x07,&P11SEL           ; P11.0, 1, 2 for debugging purposes
            ; Initialize clocks
            bis.w   #SELREF_2,&UCSCTL3      ; Set DCO FLL reference = REFO
            bis.w   #SELA_2,&UCSCTL4        ; Set ACLK = REFO

            bis.w   #SCG0,SR                ; Disable the FLL control loop
            clr.w   &UCSCTL0                ; Set lowest possible DCOx, MODx
            mov.w   #DCORSEL_5,&UCSCTL1     ; Select range for 24 MHz operation
            mov.w   #FLLD_1 + 366,&UCSCTL2  ; Set DCO multiplier for 12 MHz
                                            ; (N + 1) * FLLRef = Fdco
                                            ; (366 + 1) * 32768 = 12MHz
                                            ; Set FLL Div = fDCOCLK/2
            bic.w   #SCG0,SR                ; Enable the FLL control loop

  ; Worst-case settling time for the DCO when the DCO range bits have been
  ; changed is n x 32 x 32 x f_FLL_reference. See UCS chapter in 5xx UG
  ; for optimization.
  ; 32 x 32 x 12 MHz / 32,768 Hz = 375000 = MCLK cycles for DCO to settle
            mov.w   #0x6E34,R15
            nop
            mov.w   #0x1,R14
delay_L1    add.w   #0xFFFF,R15
            addc.w  #0xFFFF,R14
            jc      delay_L1

            ; Loop until XT1,XT2 & DCO fault flag is cleared
do_while    bic.w   #XT2OFFG + XT1LFOFFG + XT1HFOFFG + DCOFFG,&UCSCTL7
                                            ; Clear XT2,XT1,DCO fault flags
            bic.w   #OFIFG,&SFRIFG1         ; Clear fault flags
            bit.w   #OFIFG,&SFRIFG1         ; Test oscillator fault flag
            jc      do_while

while_loop  xor.b   #BIT0,&P1OUT            ; Flash the LED
            mov.w   #0xFFFF,R4              ; Initialize loop counter R4=65535
delay_loop  dec.w   R4                      ; Decrement loop counter
            jne     delay_loop              ; Loop if loop counter > 0
            jmp     while_loop              ; Infinite while loop

;-------------------------------------------------------------------------------
                  ; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; POR, ext. Reset
            .short  RESET
            .end
