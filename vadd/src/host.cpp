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
    std::vector<int> input_data1(size), input_data2(size), expected_result(size), result(size);
    for (int i = 0; i < size; i++) {
        // Input data
        input_data1[i] = i;
        input_data2[i] = i;

        // Compute the results
        expected_result[i] = input_data1[i] + input_data2[i];
    }

    // Get the context
    hlslib::ocl::Context context;

    // Program the device
    auto program = context.MakeProgram(binary_file);

    // Initialize device memory
    auto buffer_input1 = context.MakeBuffer<int, hlslib::ocl::Access::readWrite>(
            hlslib::ocl::MemoryBank::bank0, size);
    auto buffer_input2 = context.MakeBuffer<int, hlslib::ocl::Access::readWrite>(
            hlslib::ocl::MemoryBank::bank0, size);
    auto buffer_result = context.MakeBuffer<int, hlslib::ocl::Access::readWrite>(
            hlslib::ocl::MemoryBank::bank0, size);

    // Copy to device
    buffer_input1.CopyFromHost(input_data1.begin());
    buffer_input2.CopyFromHost(input_data2.begin());

    // Create the kernel
    auto kernel = program.MakeKernel("krnl_vadd_rtl", buffer_input1, buffer_input2, buffer_result, size);

    // Execute kernel
    const auto elapsed = kernel.ExecuteTask();

    // Copy back the results
    buffer_result.CopyToHost(result.begin());

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
