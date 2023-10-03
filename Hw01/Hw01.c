#include<stdio.h>

float fp32_to_bf16(float x)                 
{
    float y = x;
    int *p = (int *) &y;
    unsigned int exp = *p & 0x7F800000;
    unsigned int man = *p & 0x007FFFFF;
    if (exp == 0 && man == 0) /* zero */
        return x;
    if (exp == 0x7F800000) /* infinity or NaN */
        return x;

    /* Normalized number */
    /* round to nearest */
    float r = x;
    int *pr = (int *) &r;
    *pr &= 0xFF800000;  /* r has the same exp as x */
    r /= 256;
    y = x + r;

    *p &= 0xFFFF0000;

    return y;
}

// encoder : encode two bfloat number in one memory
int encoder(int *a,int *b){
    int c=0;
    c=*a+(*b>>16);
    *a=0;
    *b=0;
    return c;
}
// decoder : decode one memory number in two bfloat
void decoder(int c ,int *n1,int *n2){
    *n1=c&0xffff0000;
    *n2=(c&0x0000ffff)<<16;
}


int main(){
    // definition of num1 and transfer it to bfloat
    float num1=12.123;
    int *np1=(int *) &num1;
    num1=fp32_to_bf16(num1);
    // definition of num2 and transfer it to bfloat
    float num2=45.568;
    int *np2=(int *) &num2;
    num2=fp32_to_bf16(num2);

    int add=0;
    // // show num1 binary form and it's value
    // printf("0x%x\n",*np1);
    // printf("%f\n",num1);
    // // show num2 binary form and it's value
    // printf("0x%x\n",*np2);
    // printf("%f\n",num2);
    // add two number together and print the binary form
    add=encoder(np1,np2);
    // printf("0x%x\n",add);
    // // check if num1 and num2 are 0
    // printf("0x%x\n",*np1);
    // printf("0x%x\n",*np2);
    // decode these two nuber to np1 and np2
    decoder(add,np1,np2);
    // // check if num1 and num2 are expect number
    // printf("0x%x\n",*np1);
    // printf("%f\n",num1);
    // printf("0x%x\n",*np2);
    // printf("%f\n",num2);

    return 0;
}