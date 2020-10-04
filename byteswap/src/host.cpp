#include <vector>
#include <iostream>
#include "hlslib/xilinx/SDAccel.h"

#define DATA_SIZE 256

int main(int argc, char **argv) {
    // Check the arguments and load them
    if (argc != 2) {
        std::cout << "Usage: " << argv[0] << " <XCLBIN File>" << std::endl;
        return EXIT_FAILURE;
    }
    std::string binary_file = argv[1];

    // Allocate host memory and input data
    const auto size = DATA_SIZE;
    std::vector<int> input_data(size), expected_result(size), result(size);
    for (int i = 0; i < size; i++) {
        // Input data
        input_data[i] = i;

        // Compute the results
        expected_result[i] = 0;
        for (int j = 0; j < 4; i++) {
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
    auto kernel = program.MakeKernel("byteswap", gmem);

    // Execute kernel
    const auto elapsed = kernel.ExecuteTask();

    // Copy back the results
    gmem.CopyToHost(result.begin());

    // Compare the results of the Device to the simulation
    int match = 0;
    for (int i = 0; i < size; i++) {
        if (expected_result[i] != result[i]) {
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << "i = " << i << " Software result = " << expected_result[i]
                      << " Device result = " << result[i] << std::endl;
            match = 1;
        }
    }

    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
