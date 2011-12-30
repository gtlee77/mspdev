//******************************************************************************
//  MSP430x41x2 Demo - Timer_A, Toggle P5.1, CCR0 Cont. Mode ISR, DCO SMCLK
//
//  Description: Toggle P5.1 using software and TA_0 ISR. Toggles every
//  50000 SMCLK cycles. SMCLK provides clock source for TACLK.
//  During the TA_0 ISR, P5.1 is toggled and 50000 clock cycles are added to
//  CCR0. TA_0 ISR is triggered every 50000 cycles. CPU is normally off and
//  used only during TA_ISR.
//  ACLK = n/a, MCLK = SMCLK = TACLK = default DCO
//
//         MSP430x41x2
//         ---------------
//     /|\|            XIN|-
//      | |               |
//      --|RST        XOUT|-
//        |               |
//        |           P5.1|-->LED
//
//  P. Thanigai
//  Texas Instruments Inc.
//  January 2009
//  Built with CCE Version: 3.1 and IAR Embedded Workbench Version: 4.11
//*****************************************************************************

#include  <msp430x41x2.h>

void main(void)
{
  WDTCTL = WDTPW + WDTHOLD;                 // Stop WDT
  P5DIR |= 0x02;                            // P5.1 output
  CCTL0 = CCIE;                             // CCR0 interrupt enabled
  CCR0 = 50000;
  TACTL = TASSEL_2 + MC_2;                  // SMCLK, continuous mode
  __bis_SR_register(LPM0_bits + GIE);       // Enter LPM0 w/ interrupt
}

// Timer A0 interrupt service routine
#pragma vector=TIMER0_A0_VECTOR
__interrupt void Timer_A (void)
{
  P5OUT ^= 0x02;                            // Toggle P5.1
  CCR0 += 50000;                            // Add Offset to CCR0
}
