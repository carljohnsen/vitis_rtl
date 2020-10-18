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
    void adder(hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &ina, hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &inb, hls::stream<ap_axiu<DATA_WIDTH,0,0,0>> &out) {
#pragma HLS INTERFACE axis port=ina depth=16
#pragma HLS INTERFACE axis port=inb depth=16
#pragma HLS INTERFACE axis port=out depth=16
#pragma HLS INTERFACE s_axilite port=return
        ap_axiu<DATA_WIDTH,0,0,0> tmp;
        auto eos = false;
        do {
            ap_axiu<DATA_WIDTH,0,0,0> a = ina.read();
            ap_axiu<DATA_WIDTH,0,0,0> b = inb.read();
            uni af;
            af.u = a.data;
            uni bf;
            bf.u= b.data;
            uni cf;
            cf.f = af.f + bf.f;
            ap_uint<DATA_WIDTH> c = cf.u;
            tmp.data = c;
            tmp.last = a.last;
            eos = a.last;
            out.write(tmp);
        } while (!eos);
    }
}
