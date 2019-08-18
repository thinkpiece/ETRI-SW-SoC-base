/*
 *  cnnip_test_main.c
 *  ETRI <SW-SoC AI Deep Learning HW Accelerator RTL Design> course material
 *
 *  first draft by Junyoung Park
 */
// default cnnip functions
#include "cnnip.h"

// send data over UART
#include "xil_printf.h"

// information about AXI peripherals
#include "xparameters.h"

// xilinx io functions
#include "xil_io.h"

// c standard libraries
#include <stdio.h>
#include <stdlib.h>

// generate random numbers
int generate_random_array( int length, int seed, u32* array )
{
	srand(seed);
	int i=0;
	for (i=0; i<length; i++)
	{
		array[i] = rand();
	}
	return 0;
}

// issue write command signals according to the given array, then compare all the values
// between memory and the given array
int memory_test_random_write_read( UINTPTR base, UINTPTR offset, int length, u32* answers )
{
	int i=0;

	// write array numbers
	for (i=0; i<length; i++)
	{
		CNNIP_mWriteReg(base + offset, i<<2, answers[i]);
	}

	// read and compare the numbers
	for (i = 0; i < length; i++)
	{
		volatile u32 value = CNNIP_mReadReg(base + offset, i<<2);
		if (value != answers[i])
		{
			xil_printf("\rwrite/read error at i=%x, wrote %x but get %x...\n", i, answers[i], value);
			xil_printf("\r----- test was terminated due to the previous error -----\n");
			return -1;
		}
	}

	return 0;
}

// ---------------------------------------------------------------------------
int main()
{
	u32 cnnip_base = XPAR_CNNIP_0_S00_AXI_BASEADDR;

	xil_printf("----- test start -----\n\r");

	// local variables
	u32 answers[256];

	// memory read/write test for block memory 0
	generate_random_array(256, 0, answers);
	if (memory_test_random_write_read(cnnip_base, 0x1000, 256, answers) == -1)
	{
		xil_printf("----- block memory 0 write/read test failed -----\n\r");
		return 0;
	}
	xil_printf("----- passed block memory 0 test -----\n\r");

	// memory read/write test for block memory 1
	generate_random_array(256, 1, answers);
	if (memory_test_random_write_read(cnnip_base, 0x2000, 256, answers) == -1)
	{
		xil_printf("----- block memory 1 write/read test failed -----\n\r");
		return 0;
	}
	xil_printf("----- passed block memory 1 test -----\n\r");

	// memory read/write test for block memory 1
	generate_random_array(256, 2, answers);
	if (memory_test_random_write_read(cnnip_base, 0x3000, 256, answers) == -1)
	{
		xil_printf("----- block memory 2 write/read test failed -----\n\r");
		return 0;
	}
	xil_printf("----- passed block memory 2 test -----\n\r");



	return 0;
}
