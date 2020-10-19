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
    void adder(hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &in_a, hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &in_b, hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &out) {
#pragma HLS INTERFACE axis port=ina depth=16
#pragma HLS INTERFACE axis port=inb depth=16
#pragma HLS INTERFACE axis port=out depth=16
#pragma HLS INTERFACE s_axilite port=return
        ap_axiu<DATA_WIDTH,0,0,0> tmp_a, tmp_b, tmp_c;
        uni a, b, c;
        auto eos = false;
        do {
            tmp_a = in_a.read();
            tmp_b = in_b.read();
            a.u = tmp_a.data;
            b.u = tmp_b.data;
            c.f = a.f + b.f;
            tmp_c.data = c.u;
            tmp_c.last = tmp_a.last;
            eos = tmp_a.last;
            out.write(tmp_c);
        } while (!eos);
    }
}
