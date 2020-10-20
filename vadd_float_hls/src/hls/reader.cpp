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
    void reader(float *inp, int size, hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &out) {
#pragma HLS INTERFACE m_axi port=inp offset=slave bundle=gmem
#pragma HLS INTERFACE axis port=out depth=16
#pragma HLS INTERFACE s_axilite port=inp
#pragma HLS INTERFACE s_axilite port=size
#pragma HLS INTERFACE s_axilite port=return

        ap_axiu<DATA_WIDTH,0,0,0> tmp;
        uni tmp_data;
        int i = 0;
        for (i = 0; i < size; i++) {
            tmp_data.f = inp[i];
            tmp.data = tmp_data.u;
            tmp.last = i == size-1;
            out.write(tmp);
        }
    }
}
