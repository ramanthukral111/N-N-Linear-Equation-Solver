/* 
 * "Small Hello World" example. 
 * 
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example 
 * designs. It requires a STDOUT  device in your system's hardware. 
 *
 * The purpose of this example is to demonstrate the smallest possible Hello 
 * World application, using the Nios II HAL library.  The memory footprint
 * of this hosted application is ~332 bytes by default using the standard 
 * reference design.  For a more fully featured Hello World application
 * example, see the example titled "Hello World".
 *
 * The memory footprint of this example has been reduced by making the
 * following changes to the normal "Hello World" example.
 * Check in the Nios II Software Developers Manual for a more complete 
 * description.
 * 
 * In the SW Application project (small_hello_world):
 *
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 * In System Library project (small_hello_world_syslib):
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 *    - Define the preprocessor option ALT_NO_INSTRUCTION_EMULATION 
 *      This removes software exception handling, which means that you cannot 
 *      run code compiled for Nios II cpu with a hardware multiplier on a core 
 *      without a the multiply unit. Check the Nios II Software Developers 
 *      Manual for more details.
 *
 *  - In the System Library page:
 *    - Set Periodic system timer and Timestamp timer to none
 *      This prevents the automatic inclusion of the timer driver.
 *
 *    - Set Max file descriptors to 4
 *      This reduces the size of the file handle pool.
 *
 *    - Check Main function does not exit
 *    - Uncheck Clean exit (flush buffers)
 *      This removes the unneeded call to exit when main returns, since it
 *      won't.
 *
 *    - Check Don't use C++
 *      This builds without the C++ support code.
 *
 *    - Check Small C library
 *      This uses a reduced functionality C library, which lacks  
 *      support for buffering, file IO, floating point and getch(), etc. 
 *      Check the Nios II Software Developers Manual for a complete list.
 *
 *    - Check Reduced device drivers
 *      This uses reduced functionality drivers if they're available. For the
 *      standard design this means you get polled UART and JTAG UART drivers,
 *      no support for the LCD driver and you lose the ability to program 
 *      CFI compliant flash devices.
 *
 *    - Check Access device drivers directly
 *      This bypasses the device file system to access device drivers directly.
 *      This eliminates the space required for the device file system services.
 *      It also provides a HAL version of libc services that access the drivers
 *      directly, further reducing space. Only a limited number of libc
 *      functions are available in this configuration.
 *
 *    - Use ALT versions of stdio routines:
 *
 *           Function                  Description
 *        ===============  =====================================
 *        alt_printf       Only supports %s, %x, and %c ( < 1 Kbyte)
 *        alt_putstr       Smaller overhead than puts with direct drivers
 *                         Note this function doesn't add a newline.
 *        alt_putchar      Smaller overhead than putchar with direct drivers
 *        alt_getchar      Smaller overhead than getchar with direct drivers
 *
 */

#include "sys/alt_stdio.h"
#include "system.h"
#include "io.h"
#include <stdio.h>
#define MATRIX_WIDTH 8
#include <unistd.h>

int main()
{ 
  alt_putstr("Hello from Nios II!\n");

  /* Event loop never exits. */
  	unsigned int MatrixA[MATRIX_WIDTH][MATRIX_WIDTH] =
  	{
		{0x40C00000 , 0x40800000 , 0x3F800000 , 0xC0400000 , 0xC0000000 , 0xC0400000 , 0x40A00000 , 0x41000000},
		{0xBF800000 , 0x41200000 , 0x40000000 , 0x40800000 , 0x40400000 , 0x3F800000 , 0x41100000 , 0x40000000},
		{0x40800000 , 0x40000000 , 0x41100000 , 0x40A00000 , 0xBF800000 , 0x40000000 , 0xC0A00000 , 0xC0400000},
		{0x40A00000 , 0xC0800000 , 0xC0400000 , 0x41100000 , 0x40800000 , 0x40E00000 , 0x41000000 , 0x40C00000},
		{0x40400000 , 0x40000000 , 0x41000000 , 0x40E00000 , 0x41200000 , 0x40C00000 , 0x40A00000 , 0x3F800000},
		{0xC0A00000 , 0x40A00000 , 0x40800000 , 0x40400000 , 0x3F800000 , 0x40E00000 , 0x40A00000 , 0x41000000},
		{0x40000000 , 0x3F800000 , 0x40A00000 , 0x40C00000 , 0xC1000000 , 0x40A00000 , 0x41300000 , 0x40C00000},
		{0x40000000 , 0x40800000 , 0x40A00000 , 0x40E00000 , 0xC0A00000 , 0x40C00000 , 0x40800000 , 0x40000000}
    };

  	IOWR(LU_MATRIX_EQUATION_SOLVER_0_BASE, 3, 0x0);
	printf ("Matrix A Is \n\n");

  	for(int i = 0; i < MATRIX_WIDTH; i++)
  	{

  		for(int j = 0; j < MATRIX_WIDTH; j++)
  		{
  			IOWR(LU_MATRIX_EQUATION_SOLVER_0_BASE, 1, MatrixA[i][j]);
  			printf (" %x ", MatrixA[i][j]);
  		}

  		printf("\n");
  	}

  	printf ("\n\n Matrix B Is \n\n");

  	unsigned int MatrixB[MATRIX_WIDTH]=
  	{0x3F800000 , 0x40000000 , 0x40400000 , 0x40800000 , 0x40A00000 , 0x40C00000 ,0x40E00000 , 0x41000000};

  	IOWR(LU_MATRIX_EQUATION_SOLVER_0_BASE, 3, 0x0);

	for(int j = 0; j < MATRIX_WIDTH; j++)
	{
		IOWR(LU_MATRIX_EQUATION_SOLVER_0_BASE, 2, MatrixB[j]);
		printf (" %x ", MatrixB[j]);
	}

	IOWR(LU_MATRIX_EQUATION_SOLVER_0_BASE, 3, 0x0);



    printf ("\nWriting 0x1 to control/status register to trigger the operation.\n");
    IOWR(LU_MATRIX_EQUATION_SOLVER_0_BASE, 0, 0x1);

    usleep(100);

    while(IORD(LU_MATRIX_EQUATION_SOLVER_0_BASE, 00) !=0 )
    {
    	usleep(10);
    }

    printf ("\n\n Answer Is \n\n");

    IORD(LU_MATRIX_EQUATION_SOLVER_0_BASE, 3);

    for(int j = 0; j < MATRIX_WIDTH; j++)
    	{
    		MatrixB[j] = IORD(LU_MATRIX_EQUATION_SOLVER_0_BASE, 2);
    		IOWR(LU_MATRIX_EQUATION_SOLVER_0_BASE, 3, 0x1);
    		printf (" %x ", MatrixB[j]);
    	}

  while (1);

  return 0;
}
