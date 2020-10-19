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
    void reader(float *in_a, float *in_b, int size, hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &out_a, hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &out_b) {
#pragma HLS INTERFACE m_axi port=ina offset=slave bundle=gmem
#pragma HLS INTERFACE m_axi port=inb offset=slave bundle=gmem
#pragma HLS INTERFACE axis port=outa depth=16
#pragma HLS INTERFACE axis port=outb depth=16
#pragma HLS INTERFACE s_axilite port=ina
#pragma HLS INTERFACE s_axilite port=inb
#pragma HLS INTERFACE s_axilite port=size
#pragma HLS INTERFACE s_axilite port=return

        ap_axiu<DATA_WIDTH,0,0,0> tmp_a, tmp_b;
        uni tmp_data_a, tmp_data_b;
        int i = 0;
        for (i = 0; i < size; i++) {
            tmp_data_a.f = in_a[i];
            tmp_data_b.f = in_b[i];
            tmp_a.data = tmp_data_a.u;
            tmp_b.data = tmp_data_b.u;
            tmp_a.last = i == size-1;
            tmp_b.last = i == size-1;
            out_a.write(tmp_a);
            out_b.write(tmp_b);
        }
    }
}
