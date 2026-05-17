/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xgpio.h"
#include "xparameters.h"
#include "sleep.h"

#define LED_CHANNEL 1
#define BUTTONS_CHANNEL 1
XGpio Gpio, GpioButtons;

int main()
{
    init_platform();

    print("Hello World\n\r");

    u32 dataRead, dataReadMasked;

    int status = XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_LEDS_DEVICE_ID);

    if (status != XST_SUCCESS) {
            xil_printf("GPIO Init Failed\r\n");
            return XST_FAILURE;
    }
    int status2 = XGpio_Initialize(&GpioButtons, XPAR_AXI_GPIO_BUTTONS_DEVICE_ID);

    if (status2 != XST_SUCCESS) {
            xil_printf("GPIO Init 2 Failed\r\n");
            return XST_FAILURE;
    }

    XGpio_SetDataDirection(&Gpio, LED_CHANNEL, 0x0000);
    XGpio_SetDataDirection(&GpioButtons, BUTTONS_CHANNEL, 0x0001);

    while(1){
    	/*XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, 0x0001);
    	sleep(1);
    	XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, 0x0000);
    	sleep(1);
    	Xil_Out32(XPAR_GPIO_0_BASEADDR, dataReadMasked);
    	*/
    	dataRead = XGpio_DiscreteRead(&GpioButtons, BUTTONS_CHANNEL);
    	dataReadMasked = dataRead & 0x000F;
    	XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, dataReadMasked);
    	sleep(0.1);


    }

    cleanup_platform();
    return 0;
}
