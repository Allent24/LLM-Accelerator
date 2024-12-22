/*******************************************************************************
 * Copyright 2019 Microchip FPGA Embedded Systems Solutions.
 *
 * SPDX-License-Identifier: MIT
 *
 * @file u54_1.c
 *
 * @author Microchip FPGA Embedded Systems Solutions
 *
 * @brief Application code running on U54_1.
 * PolarFire SoC MSS RTC Time example project
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include "mpfs_hal/mss_hal.h"
#include "drivers/mss/mss_mmuart/mss_uart.h"
#include "drivers/mss/mss_rtc/mss_rtc.h"
#include "inc/uart_mapping.h"
#include <math.h>
extern struct mss_uart_instance* p_uartmap_u54_1;
int *sample;
float* sample2;
//int src,imm;
int src = 0;

/* Constant used for setting RTC control register. */
#define BIT_SET 0x00010000U

/* 1MHz clock is RTC clock source. */
#define RTC_PERIPH_PRESCALER              (1000000u - 1u)

/* Constant used for setting RTC control register. */
#define BIT_SET 0x00010000U

/* 1MHz clock is RTC clock source. */
#define RTC_PERIPH_PRESCALER              (1000000u - 1u)

uint8_t display_buffer[100];

/******************************************************************************
 *  Greeting messages displayed over the UART.
 */
const uint8_t g_greeting_msg[] =
        "\r\n\r\n\t  ******* PolarFire SoC RTC Time Example *******\n\n\n\r\
The example project demonstrate the RTC time mode. The UART\r\n\
message will be displayed at each second. \r\n\n\n\
";

/* Main function for the hart1(U54_1 processor).
 * Application code running on hart1 is placed here.
 */

//Returns a float with the dot product of a and b.
int8_t doDotProduct(int8_t a[], int8_t b[],int8_t len){
    //Reset result
    int8_t result;
    int8_t count;
    int8_t temp;
    int8_t h = 5;
    int8_t g = 7;
    asm volatile("LI %0,0"
        : "=r"(result)
                  );
    asm volatile("LI %0,0"
            : "=r"(count)
                      );

    asm volatile (

        //"1:\n"              // Code to run in loop
            "LI %5 , 5\n"
//            "LI %2, 0\n"        // Load temp with 0 at beginning
//            "MUL %2, %3, %4\n"  // Do the multiplication of a and b, store in temp
//            "ADD %5, %2, %5\n"  // Add temp to result
//            "ADDI %0, %0, 1\n"  // Increase count by 1

        //"BGE %0, %1, 2f\n"  // Branch if count > len
        //"J 1b\n"
        //"2:\n"              // Code when loop ends
            "NOP\n"             // No operation
        : "+r"(result)       // Output operand
        : "r"(count),"r"(len), "r"(temp), "r"(h), "r"(g), "r"(result)  // Input operands
        : "memory"          // Clobbered registers
    );



    return result;
}

void u54_1(void)
{
    mss_rtc_calender_t calendar_count;

    /* Clear pending software interrupt in case there was any.
       Enable only the software interrupt so that the E51 core can bring this
       core out of WFI by raising a software interrupt. */
    clear_soft_interrupt();
    set_csr(mie, MIP_MSIP);

#if (IMAGE_LOADED_BY_BOOTLOADER == 0)
    /*Put this hart into WFI.*/
    do
    {
        __asm("wfi");
    }while(0 == (read_csr(mip) & MIP_MSIP));

    /* The hart is out of WFI, clear the SW interrupt. Hear onwards Application
     * can enable and use any interrupts as required */
    clear_soft_interrupt();
#endif

    PLIC_init();
    __enable_irq();

    PLIC_SetPriority(RTC_WAKEUP_PLIC, 2);

    (void)mss_config_clk_rst(MSS_PERIPH_MMUART_U54_1, (uint8_t) MPFS_HAL_LAST_HART, PERIPHERAL_ON);
    (void)mss_config_clk_rst(MSS_PERIPH_RTC, (uint8_t) MPFS_HAL_LAST_HART, PERIPHERAL_ON);

    MSS_UART_init(p_uartmap_u54_1,
            MSS_UART_115200_BAUD,
            MSS_UART_DATA_8_BITS | MSS_UART_NO_PARITY | MSS_UART_ONE_STOP_BIT
    );

    MSS_UART_polled_tx_string(p_uartmap_u54_1, g_greeting_msg);

    SYSREG->RTC_CLOCK_CR &= ~BIT_SET;
    SYSREG->RTC_CLOCK_CR = LIBERO_SETTING_MSS_EXT_SGMII_REF_CLK / LIBERO_SETTING_MSS_RTC_TOGGLE_CLK;
    SYSREG->RTC_CLOCK_CR |= BIT_SET;

    /* Initialize RTC. */
    MSS_RTC_init(MSS_RTC_LO_BASE, MSS_RTC_CALENDAR_MODE, RTC_PERIPH_PRESCALER );

    /* Enable RTC to start incrementing. */
    MSS_RTC_start();

    for (;;)
    {
        volatile uint32_t rtc_count_updated;

        /* Update displayed time if value read from RTC changed since last read.*/
        rtc_count_updated = MSS_RTC_get_update_flag();
        if(rtc_count_updated)
        {
            // Allocate memory for 8 integers
            sample = (int*) malloc(8 * sizeof(int));
            sample2 = (float*) malloc(8*sizeof(float));
            if (sample == NULL){
                MSS_UART_polled_tx_string(p_uartmap_u54_1,
                    (const uint8_t*)"Memory allocation failed!\r\n");
                continue;
            }

            // Fill the array with random numbers between 0 and 99
            for(int i = 0; i < 8; i++){
                //sample[i] = rand() % 100;
//                imm = rand() % 100;
//                asm (
//                    "add %0, %1, %2"
//                    : "=r" (src)
//                    : "r"(src), "r"(imm));
//                    sample[i] = src;
//
//                asm("MUL %0, %1, %2"
//                    : "=r"(src)
//                    : "r"(src), "r"(i)    );


                //IMM=5 for multiplication
                asm(
                    "LI %0,0"
                    : "=r"(src)
                               );
            }
//            int8_t a[8] = {1,2,3,4,5,6,7,8};
//            int8_t b[8] = {8,7,6,5,4,3,2,1};
            int8_t a[8] = {0,0,0,0,1,1,1,1};
            int8_t b[8] = {8,7,6,5,4,3,2,1};
            int8_t size = sizeof(a)/sizeof(a[0]);
            int8_t dotProd = doDotProduct(a,b,size);


            // Print array values and memory address
            for(int j = 0; j < 8; j++){
                snprintf((char *)display_buffer, sizeof(display_buffer),
                          "A[%d] = %d\r\n", j, a[j]);
                MSS_UART_polled_tx_string(p_uartmap_u54_1, display_buffer);
                snprintf((char *)display_buffer, sizeof(display_buffer),
                                          "B[%d] = %d\r\n", j, b[j]);
                                MSS_UART_polled_tx_string(p_uartmap_u54_1, display_buffer);
            }

            snprintf((char *)display_buffer, sizeof(display_buffer),
                     "Array A memory address: %p\r\n", (void*)a);
            MSS_UART_polled_tx_string(p_uartmap_u54_1, display_buffer);

            snprintf((char *)display_buffer, sizeof(display_buffer),
                                 "Array B memory address: %p\r\n", (void*)b);
                        MSS_UART_polled_tx_string(p_uartmap_u54_1, display_buffer);

            snprintf((char *)display_buffer, sizeof(display_buffer),
                                 "Dot Product of A and B: %d\r\n", dotProd);
                       MSS_UART_polled_tx_string(p_uartmap_u54_1, display_buffer);
            // Free allocated memory
            free(sample);

            MSS_RTC_get_calendar_count(&calendar_count);
            MSS_RTC_clear_update_flag();
        }
    }
    /* never return */
}


