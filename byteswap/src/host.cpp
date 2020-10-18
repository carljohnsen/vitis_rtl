#include <vector>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "hlslib/xilinx/SDAccel.h"

// 1 MB
#define DATA_SIZE 16384 * 16

int main(int argc, char **argv) {
    // Check the arguments and load them
    if (argc != 2) {
        std::cout << "Usage: " << argv[0] << " <XCLBIN File>" << std::endl;
        return EXIT_FAILURE;
    }
    std::string binary_file = argv[1];

    // Allocate host memory and input data
    srand(time(NULL));
    const int size = DATA_SIZE;
    const int size_bytes = size * sizeof(int);
    std::vector<int> input_data(size), expected_result(size), result(size);
    for (int i = 0; i < size; i++) {
        // Input data
        input_data[i] = i;//rand();

        // Compute the results
        expected_result[i] = 0;
        for (int j = 0; j < 4; j++) {
            expected_result[i] |= ((input_data[i] >> (j*8)) & 0xFF) << ((3-j)*8);
        }
    }

    // Get the context
    hlslib::ocl::Context context;

    // Program the device
    auto program = context.MakeProgram(binary_file);

    // Initialize device memory
    auto gmem = context.MakeBuffer<int, hlslib::ocl::Access::readWrite>(
            hlslib::ocl::MemoryBank::bank0, size);

    // Copy to device
    gmem.CopyFromHost(input_data.begin());

    // Create the kernel
    auto kernel = program.MakeKernel("byteswap", size_bytes, gmem);

    // Execute kernel
    const auto elapsed = kernel.ExecuteTask();

    // Copy back the results
    gmem.CopyToHost(result.begin());

    // Compare the results of the Device to the simulation
    int match = 0;
    for (int i = 0; i < size; i++) {
        if (expected_result[i] != result[i]) {
            printf("Error %d: result %08x != expected %08x\n",
                    i, result[i], expected_result[i]);
            match = 1;
            break;
        }
    }

    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
