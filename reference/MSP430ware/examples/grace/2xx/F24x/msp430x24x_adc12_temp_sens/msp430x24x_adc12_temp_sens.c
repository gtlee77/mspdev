//******************************************************************************
//  MSP430x24x Demo - ADC12, Sample A10 Temp and Convert to oC and oF
//
//  Description: A single sample is made on A10 with reference to internal
//  1.5V Vref. Software sets ADC12SC to start sample and conversion - ADC12SC
//  automatically cleared at EOC. ADC12 internal oscillator times sample
//  and conversion. In Mainloop MSP430 waits in LPM0 to save power until
//  ADC10 conversion complete, ADC12_ISR will force exit from any LPMx in
//  Mainloop on reti.
//  ACLK = n/a, MCLK = SMCLK = default DCO ~1.045Mhz, ADC12CLK = ADC12OSC
//
//  Uncalibrated temperature measured from device to devive will vary do to
//  slope and offset variance from device to device - please see datasheet.
//
//                MSP430F249
//             -----------------
//         /|\|              XIN|-
//          | |                 |
//          --|RST          XOUT|-
//            |                 |
//            |A10              |
//******************************************************************************
/*
 * ======== Standard MSP430 includes ========
 */
#include <msp430.h>

/*
 * ======== Grace related includes ========
 */
#include <ti/mcu/msp430/csl/CSL.h>

/*
 *  ======== main ========
 */

int long temp;
int long IntDegF;
int long IntDegC;

void main(int argc, char *argv[])
{
    CSL_init();

    while(1)
    {
      ADC12CTL0 |= ADC12SC;                   // Sampling and conversion start
      _BIS_SR(CPUOFF + GIE);                  // LPM0 with interrupts enabled

  //  oF = ((x/4096)*1500mV)-923mV)*1/1.97mV = x*761/4096 - 468
  //  IntDegF = (ADC12MEM0 - 2519)* 761/4096
      IntDegF = (temp - 2519) * 761;
      IntDegF = IntDegF / 4096;

  //  oC = ((x/4096)*1500mV)-986mV)*1/3.55mV = x*423/4096 - 278
  //  IntDegC = (ADC12MEM0 - 2692)* 423/4096
      IntDegC = (temp - 2692) * 423;
      IntDegC = IntDegC / 4096;

      _NOP();                                 // << SET BREAKPOINT HERE
    }
}

void ADC12_ISR(void)
{
    temp = ADC12MEM0;                       // Move results, IFG is cleared
}
