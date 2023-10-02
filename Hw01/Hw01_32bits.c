#include <stdint.h>
uint16_t count_leading_zeros(uint32_t x)
{
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);

    /* count ones (population count) */
    x -= ((x >> 1) & 0x55555555 );
    x = ((x >> 2) & 0x3333333) + (x & 0x3333333 /* Fill this! */);
    x = ((x >> 4) + x) & 0x0f0f0f;
    x += (x >> 8);
    x += (x >> 16);

    return (32 - (x & 0x3f));
}

void sort(int *a,int *b){
    int c;
    c=*a;
    *a=*b;
    *b=c;
}

int main(){
    int a[10]={1000,900,800,700,600,500,400,300,200,100};
    
    for(int i=0;i<10;i++){
        //printf("%d\n",count_leading_zeros(a[i]));
        for(int j=0;j<10;j++){
            if(count_leading_zeros(a[i])<count_leading_zeros(a[j])){
                sort(a[i],a[j]);
            }
        }
    }
    for(int i=0;i<10;i++){
        printf("%d\n",a[i]);
    }

    return 0;
}