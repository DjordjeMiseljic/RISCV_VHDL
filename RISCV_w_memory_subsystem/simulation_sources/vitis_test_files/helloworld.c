/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
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
#include <unistd.h>
#include "platform.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include <inttypes.h>


#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include "assembly.h"

// REGISTERS
#define MEMORY_SIZE				2*1024
#define USR_RISCV_CE 			(XPAR_RISCV_AXI_0_AXIL_S_BASEADDR + 0)
#define USR_MEM_BASE_ADDRESS 	(XPAR_RISCV_AXI_0_AXIL_S_BASEADDR + 4)
#define USR_PC_REG		 		(XPAR_RISCV_AXI_0_AXIL_S_BASEADDR + 8)

int main()
{
	int pc_reg = 0;
	u32 main_memory [MEMORY_SIZE] = {0};
    init_platform();
    // Za svaki slucaj
    Xil_DCacheInvalidateRange((int)main_memory,MEMORY_SIZE);
    Xil_ICacheInvalidateRange((int)main_memory,MEMORY_SIZE);
    Xil_Out32(USR_RISCV_CE, (u32)0);
    pc_reg = Xil_In32(USR_PC_REG);
    printf("\nPC register value initially: %d\n",pc_reg);
   printf("***** STARTING *****\n");
   printf("I: First 32 elements:\n");

   for(int i = 0; i < 32; i++)
   {
	   printf("%x\t", (unsigned int)main_memory[i]);
   }
   printf("\nI: 1024:1024+32: elements:\n");
   for(int i=1024; i<1024+32; i++)
   {
	   printf("%x\t",(unsigned int)main_memory[i]);
   }
    printf("\n");

    size_t assembly_num_el = sizeof(assembly)/sizeof(assembly[0]);
 	for(int i=0; i<assembly_num_el; i++)
 		main_memory[i] = assembly[i];

    printf("***** AFTER INITIALIZATION *****\n");
    printf("I: First 32 elements:\n");
    for(int i = 0; i < 32; i++)
    {
     	printf("%x\t", (unsigned int)main_memory[i]);
    }
    printf("\nI: 1024:1024+32: elements:\n");
  	for(int i=1024; i<1024+32; i++)
 	{
 		printf("%x\t",(unsigned int)main_memory[i]);
 	}
    printf("\n");


    // Initialize transaction
   	printf("\n\nThis is first memory address %p\n",&main_memory[0]);
    Xil_Out32(USR_MEM_BASE_ADDRESS, (u32)&main_memory[0]);
    // Wirte base address of the array to usr_base_address

    Xil_Out32(USR_RISCV_CE, (u32)1);
    pc_reg = Xil_In32(USR_PC_REG);
    sleep(5);
   	printf("\nPC register value: %d\n",pc_reg);

    printf("***** AFTER PROGRAM *****\n");
    printf("I: First 32 elements:\n");
    for(int i = 0; i < 32; i++)
    {
     	printf("%x\t", (unsigned int)main_memory[i]);
    }
    printf("\nI: 1024:1024+32: elements:\n");
  	for(int i=1024; i<1024+32; i++)
 	{
 		printf("%x\t",(unsigned int)main_memory[i]);
 	}
    printf("\n");
/*
    Xil_Out32(USR_RISCV_CE, (u32)1);
    sleep(10); // THIS IS JUST A DELAY
    pc_reg = Xil_In32(USR_PC_REG);
   	printf("\nPC register value after delay: %d\n",pc_reg);
    Xil_Out32(USR_RISCV_CE, (u32)0);
*/
    cleanup_platform();

    return 0;
}
