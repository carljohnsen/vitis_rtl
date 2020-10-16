#define DATA_WIDTH 32
#define DATA_SIZE 512
#include <string.h>
#include <stdbool.h>
#include <hls_stream.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>

extern "C" {
    void vadd_float(hls::stream<ap_axiu<DATA_WIDTH, 0, 0, 0>> &ina, hls::stream<ap_axiu<DATA_WIDTH, 0, 0, 0>> &inb, hls::stream<ap_axiu<DATA_WIDTH, 0, 0, 0>> &out) {
#pragma HLS INTERFACE axis port=ina depth=16
#pragma HLS INTERFACE axis port=inb depth=16
#pragma HLS INTERFACE axis port=out depth=16
#pragma HLS INTERFACE s_axilite port=return
        while (true) {
            ap_axiu<DATA_WIDTH, 0, 0, 0> tmpa = ina.read();
            ap_axiu<DATA_WIDTH, 0, 0, 0> tmpb = inb.read();
            ap_axiu<DATA_WIDTH, 0, 0, 0> tmpout;
            tmpout.data = ((float)tmpa.data) + ((float)tmpb.data);
            tmpout.last = tmpa.last & tmpb.last;
            tmpout.keep = tmpa.keep;
            out.write(tmpout);
        }
    }
}
