/*--------------------------------------------------------------------
 * Project 8: AXI4-Lite BRAM-backed Slave — Read/Write Verification
 *--------------------------------------------------------------------*/
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include <stdint.h>

/*--------------------------------------------------------------------
 * BRAM slave base address and geometry
 * VERIFY against your Address Editor assignment before running
 *--------------------------------------------------------------------*/
#define BRAM_BASE       0x40800000UL   /* update if your Address Editor differs */
#define BRAM_NUM_WORDS  64
#define BRAM_WORD(i)    (BRAM_BASE + ((uint32_t)(i) * 4U))

#define BRAM_WRITE(i, val)  Xil_Out32(BRAM_WORD(i), (val))
#define BRAM_READ(i)        Xil_In32(BRAM_WORD(i))

/*--------------------------------------------------------------------
 * Function prototypes
 *--------------------------------------------------------------------*/
static void fill_pattern(void);
static int  verify_pattern(void);
static void dump_first_n(int n);

/*====================================================================
 * MAIN
 *====================================================================*/
int main(void)
{
    xil_printf("\r\n");
    xil_printf("=============================================\r\n");
    xil_printf(" Project 8: AXI4-Lite BRAM-backed Slave      \r\n");
    xil_printf("=============================================\r\n\r\n");

    /*------------------------------------------------------------------
     * Step 1: Confirm the memory reads back zero at reset
     * (Your VHDL initializes mem to all-zero, so this should hold
     *  true on a fresh bitstream load / power-on)
     *------------------------------------------------------------------*/
    xil_printf("[INIT] Checking reset state (expect all zero):\r\n");
    dump_first_n(4);

    /*------------------------------------------------------------------
     * Step 2: Write a known, easily-recognizable pattern to every word
     *------------------------------------------------------------------*/
    xil_printf("\r\n[WRITE] Writing pattern to all %d words...\r\n",
               BRAM_NUM_WORDS);
    fill_pattern();
    xil_printf("[WRITE] Done.\r\n");

    xil_printf("\r\n[DUMP] First few words after write:\r\n");
    dump_first_n(4);

    /*------------------------------------------------------------------
     * Step 3: Read back and verify every word matches
     *------------------------------------------------------------------*/
    xil_printf("\r\n[VERIFY] Reading back and checking all %d words...\r\n",
               BRAM_NUM_WORDS);
    int status = verify_pattern();

    if (status == 0) {
        xil_printf("\r\n[PASS] All %d words verified correctly!\r\n",
                   BRAM_NUM_WORDS);
    } else {
        xil_printf("\r\n[FAIL] %d mismatch(es) detected — see above.\r\n",
                   status);
    }

    /*------------------------------------------------------------------
     * Step 4: Overwrite a single word and confirm only that word changed
     * (sanity check that addressing/indexing is correct, not just that
     *  a sequential fill-then-read-back happens to look right)
     *------------------------------------------------------------------*/
    xil_printf("\r\n[SPOT CHECK] Overwriting word 10 with 0xCAFEBABE...\r\n");
    BRAM_WRITE(10, 0xCAFEBABEUL);

    uint32_t w9  = BRAM_READ(9);
    uint32_t w10 = BRAM_READ(10);
    uint32_t w11 = BRAM_READ(11);

    xil_printf("  word[9]  = 0x%08X (expect unchanged pattern value)\r\n",
               (unsigned int)w9);
    xil_printf("  word[10] = 0x%08X (expect 0xCAFEBABE)\r\n",
               (unsigned int)w10);
    xil_printf("  word[11] = 0x%08X (expect unchanged pattern value)\r\n",
               (unsigned int)w11);

    if (w10 == 0xCAFEBABEUL) {
        xil_printf("[PASS] Spot-write landed on the correct word only.\r\n");
    } else {
        xil_printf("[FAIL] word[10] did not update as expected.\r\n");
    }

    xil_printf("\r\n=============================================\r\n");
    xil_printf(" Project 8 test complete\r\n");
    xil_printf("=============================================\r\n");

    return (status == 0) ? XST_SUCCESS : XST_FAILURE;
}

/*====================================================================
 * Helpers
 *====================================================================*/

/* Write i*i into word i — easy to eyeball, easy to spot an off-by-one
 * or wrong-index bug (values are all distinct and monotonically related
 * to their index, unlike e.g. a constant or a simple ramp which can
 * mask an addressing bug more easily) */
static void fill_pattern(void)
{
    for (uint32_t i = 0; i < BRAM_NUM_WORDS; i++) {
        BRAM_WRITE(i, i * i);
    }
}

static int verify_pattern(void)
{
    int errors = 0;

    for (uint32_t i = 0; i < BRAM_NUM_WORDS; i++) {
        uint32_t expected = i * i;
        uint32_t got = BRAM_READ(i);

        if (got != expected) {
            xil_printf("  [%2u] Expected=0x%08X Got=0x%08X\r\n",
                       (unsigned int)i,
                       (unsigned int)expected,
                       (unsigned int)got);
            errors++;
            if (errors >= 8) {
                xil_printf("  ... (stopping after 8 errors)\r\n");
                break;
            }
        }
    }

    return errors;
}

static void dump_first_n(int n)
{
    for (int i = 0; i < n; i++) {
        xil_printf("  word[%d] = 0x%08X\r\n", i, (unsigned int)BRAM_READ(i));
    }
}
