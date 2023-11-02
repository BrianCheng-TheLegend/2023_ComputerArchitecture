#include <stdint.h>
#include <stdbool.h>
#include <inttypes.h>
#include <stdio.h>

typedef uint64_t ticks;
static inline ticks getticks(void)
{
    uint64_t result;
    uint32_t l, h, h2;
    asm volatile(
        "rdcycleh %0\n"
        "rdcycle %1\n"
        "rdcycleh %2\n"
        "sub %0, %0, %2\n"
        "seqz %0, %0\n"
        "sub %0, zero, %0\n"
        "and %1, %1, %0\n"
        : "=r"(h), "=r"(l), "=r"(h2));
    result = (((uint64_t) h) << 32) | ((uint64_t) l);
    return result;
}

static uint64_t fib(uint64_t n)
{
    if (n <= 1)
        return n;
    return fib(n - 1) + fib(n - 2);
}


// test case a: no overflow, predict result is false
uint64_t a_x0 = 0x0000000000000000;
uint64_t a_x1 = 0x0000000000000000;
// test case b: no overflow, predict result is false
uint64_t b_x0 = 0x0000000000000001;
uint64_t b_x1 = 0x0000000000000010;
// test case c: no overflow, but predict result is true
uint64_t c_x0 = 0x0000000000000002;
uint64_t c_x1 = 0x4000000000000000;
// test case d: overflow, and predict result is true
uint64_t d_x0 = 0x0000000000000003;
uint64_t d_x1 = 0x7FFFFFFFFFFFFFFF;


uint16_t count_leading_zeros(uint64_t x)
{
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    x |= (x >> 32);
	
    /* count ones (population count) */
    x -= ((x >> 1) & 0x5555555555555555);
    x = ((x >> 2) & 0x3333333333333333) + (x & 0x3333333333333333);
    x = ((x >> 4) + x) & 0x0f0f0f0f0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);
    x += (x >> 32);
    
    return (64 - (x & 0x7f));
}

bool predict_if_mul_overflow(uint64_t *x0, uint64_t *x1)
{
    int32_t exp_x0 = 63 - (int32_t)count_leading_zeros(*x0);
    int32_t exp_x1 = 63 - (int32_t)count_leading_zeros(*x1);
    if ((exp_x0 + 1) + (exp_x1 + 1) >= 64)
        return true;
    else
        return false;
}

int main()
{
    ticks t0 = getticks();
    printf("%d\n", predict_if_mul_overflow(&a_x0, &a_x1));
    printf("%d\n", predict_if_mul_overflow(&b_x0, &b_x1));
    printf("%d\n", predict_if_mul_overflow(&c_x0, &c_x1));
    printf("%d\n", predict_if_mul_overflow(&d_x0, &d_x1));
    ticks t1 = getticks();
    printf("elapsed cycle: %" PRIu64 "\n", t1 - t0);
    return 0;
}
