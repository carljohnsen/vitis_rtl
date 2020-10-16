#define DATA_WIDTH 32
#define DATA_SIZE 512
#include <string.h>
#include <stdbool.h>
#include <hls_stream.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>

typedef union {
    unsigned int u;
    float f;
} uni;

extern "C" {
    void reader(float *ina, float *inb, int size, hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &outa, hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &outb) {
#pragma HLS INTERFACE m_axi port=ina offset=slave bundle=gmem
#pragma HLS INTERFACE m_axi port=inb offset=slave bundle=gmem
#pragma HLS INTERFACE axis port=outa depth=16
#pragma HLS INTERFACE axis port=outb depth=16
#pragma HLS INTERFACE s_axilite port=ina
#pragma HLS INTERFACE s_axilite port=inb
#pragma HLS INTERFACE s_axilite port=size
#pragma HLS INTERFACE s_axilite port=return

        ap_axiu<DATA_WIDTH,0,0,0> tmpa;
        ap_axiu<DATA_WIDTH,0,0,0> tmpb;
        int i = 0;
        for (i = 0; i < size; i++) {
            uni a;
            a.f = ina[i];
            uni b;
            b.f = inb[i];
            tmpa.data = a.u;
            tmpb.data = b.u;
            tmpa.last = i == size-1;
            tmpb.last = i == size-1;
            outa.write(tmpa);
            outb.write(tmpb);
        }
    }
}
