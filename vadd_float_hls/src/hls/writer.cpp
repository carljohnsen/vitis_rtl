#define DATA_WIDTH 32
#define DATA_SIZE 512
#include <string.h>
#include <stdbool.h>
#include <hls_stream.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>

extern "C" {
    void writer(float *out, hls::stream<ap_axiu<DATA_WIDTH, 0, 0, 0>> &inp) {
#pragma HLS INTERFACE m_axi port=out offset=slave bundle=gmem
#pragma HLS INTERFACE axis port=inp depth=16
#pragma HLS INTERFACE s_axilite port=out
#pragma HLS INTERFACE s_axilite port=return
        bool eos = false;
        int i = 0;
        do {
            ap_axiu<DATA_WIDTH, 0, 0, 0> tmp = inp.read();
            out[i] = tmp.data;
            i++;
            eos = tmp.last;
        } while (!eos);
    }
}
