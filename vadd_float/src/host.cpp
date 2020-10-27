#include <vector>
#include <iostream>
#include <stdlib.h>
#include <time.h>
#include "hlslib/xilinx/SDAccel.h"

#define KB 256
//#define DATA_SIZE 100 * 1024 * KB
#define DATA_SIZE 16 * KB

int main(int argc, char **argv) {
    // Check the arguments and load them
    if (argc != 2) {
        std::cout << "Usage: " << argv[0] << " <XCLBIN File>" << std::endl;
        return EXIT_FAILURE;
    }
    std::string binary_file = argv[1];

    // Allocate host memory and input data
    srand(time(NULL));
    const auto size = DATA_SIZE;
    std::vector<float> input_a(size), input_b(size), expected_result(size), result(size);
    for (int i = 0; i < size; i++) {
        // Input data
        input_a[i] = (static_cast<float>(rand()) / (static_cast<float>(RAND_MAX))) * 1000.;
        input_b[i] = (static_cast<float>(rand()) / (static_cast<float>(RAND_MAX))) * 1000.;

        // Compute the results
        expected_result[i] = input_a[i] + input_b[i];
    }

    // Get the context
    hlslib::ocl::Context context;

    // Program the device
    auto program = context.MakeProgram(binary_file);

    // Initialize device memory
    auto a = context.MakeBuffer<float, hlslib::ocl::Access::read>(
            hlslib::ocl::MemoryBank::bank0, size);
    auto b = context.MakeBuffer<float, hlslib::ocl::Access::read>(
            hlslib::ocl::MemoryBank::bank1, size);
    auto c = context.MakeBuffer<float, hlslib::ocl::Access::write>(
            hlslib::ocl::MemoryBank::bank2, size);

    // Copy to device
    a.CopyFromHost(input_a.begin());
    b.CopyFromHost(input_b.begin());

    // Create the kernel
    auto kernel = program.MakeKernel("vadd_float", size, a, b, c);

    // Execute kernel
    const auto elapsed = kernel.ExecuteTask();

    // Copy back the results
    c.CopyToHost(result.begin());

    // Compare the results of the Device to the simulation
    int match = 0;
    for (int i = 0; i < size; i++) {
        if (abs(expected_result[i] - result[i]) > .00001) {
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << "i = " << i << " Software result = " << expected_result[i]
                      << " Device result = " << result[i] << std::endl;
            match++;
            if (match >= 16)
                break;
        }
    }

    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
