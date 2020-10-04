/**********
Copyright (c) 2020, Xilinx, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**********/
//#include "xcl2.hpp"
#define CL_HPP_1_2_DEFAULT_BUILD
#define CL_HPP_TARGET_OPENCL_VERSION 120
#define CL_HPP_MINIMUM_OPENCL_VERSION 120
#define CL_HPP_ENABLE_PROGRAM_CONSTRUCTION_FROM_ARRAY_COMPATIBILITY 1
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS
#define OCL_CHECK(error, call) \
    call; \
    if (error != CL_SUCCESS) { \
        printf("%s:%d Error calling " #call ", error code is: %d\n", __FILE__, __LINE__, error); \
        exit(EXIT_FAILURE); \
    }

#include <vector>
#include <climits>
#include <sys/stat.h>
#include <CL/cl2.hpp>
#include <CL/cl_ext_xilinx.h>
#include <fstream>
#include <iostream>

#define DATA_SIZE 256

template <typename T> struct aligned_allocator {
  using value_type = T;

  aligned_allocator() {}

  aligned_allocator(const aligned_allocator &) {}

  template <typename U> aligned_allocator(const aligned_allocator<U> &) {}

  T *allocate(std::size_t num) {
    void *ptr = nullptr;

#if defined(_WINDOWS)
    {
      ptr = _aligned_malloc(num * sizeof(T), 4096);
      if (ptr == NULL) {
        std::cout << "Failed to allocate memory" << std::endl;
        exit(EXIT_FAILURE);
      }
    }
#else
    {
      if (posix_memalign(&ptr, 4096, num * sizeof(T)))
        throw std::bad_alloc();
    }
#endif
    return reinterpret_cast<T *>(ptr);
  }
  void deallocate(T *p, std::size_t num) {
#if defined(_WINDOWS)
    _aligned_free(p);
#else
    free(p);
#endif
  }
};


std::vector<cl::Device> get_devices(const std::string &vendor_name) {
  size_t i;
  cl_int err;
  std::vector<cl::Platform> platforms;
  OCL_CHECK(err, err = cl::Platform::get(&platforms));
  cl::Platform platform;
  for (i = 0; i < platforms.size(); i++) {
    platform = platforms[i];
    OCL_CHECK(err, std::string platformName =
                       platform.getInfo<CL_PLATFORM_NAME>(&err));
    if (platformName == vendor_name) {
      std::cout << "Found Platform" << std::endl;
      std::cout << "Platform Name: " << platformName.c_str() << std::endl;
      break;
    }
  }
  if (i == platforms.size()) {
    std::cout << "Error: Failed to find Xilinx platform" << std::endl;
    exit(EXIT_FAILURE);
  }
  // Getting ACCELERATOR Devices and selecting 1st such device
  std::vector<cl::Device> devices;
  OCL_CHECK(err,
            err = platform.getDevices(CL_DEVICE_TYPE_ACCELERATOR, &devices));
  return devices;
}

std::vector<cl::Device> get_xil_devices() { return get_devices("Xilinx"); }

std::vector<unsigned char>
read_binary_file(const std::string &xclbin_file_name) {
  std::cout << "INFO: Reading " << xclbin_file_name << std::endl;
  FILE *fp;
  if ((fp = fopen(xclbin_file_name.c_str(), "r")) == NULL) {
    printf("ERROR: %s xclbin not available please build\n",
           xclbin_file_name.c_str());
    exit(EXIT_FAILURE);
  }
  // Loading XCL Bin into char buffer
  std::cout << "Loading: '" << xclbin_file_name.c_str() << "'\n";
  std::ifstream bin_file(xclbin_file_name.c_str(), std::ifstream::binary);
  bin_file.seekg(0, bin_file.end);
  auto nb = bin_file.tellg();
  bin_file.seekg(0, bin_file.beg);
  std::vector<unsigned char> buf;
  buf.resize(nb);
  bin_file.read(reinterpret_cast<char *>(buf.data()), nb);
  return buf;
}

int main(int argc, char **argv) {
  if (argc != 2) {
    std::cout << "Usage: " << argv[0] << " <XCLBIN File>" << std::endl;
    return EXIT_FAILURE;
  }

  std::string binaryFile = argv[1];

  cl_int err;
  cl::CommandQueue q;
  cl::Context context;
  cl::Kernel krnl_vadd;
  auto size = DATA_SIZE;
  // Allocate Memory in Host Memory
  auto vector_size_bytes = sizeof(int) * size;
  std::vector<int, aligned_allocator<int>> source_input1(size);
  std::vector<int, aligned_allocator<int>> source_hw_results(size);
  std::vector<int, aligned_allocator<int>> source_sw_results(size);

  // Create the test data and Software Result
  for (int i = 0; i < size; i++) {
    source_input1[i] = i;
    char[4] tmp;
    for (int j = 0; j < 4; i++) {
        tmp[j] = ((char*)source_input1[i])[3-j];
    }
    source_sw_results[i] = *((int*)tmp);
    source_sw_results[i] = source_input1[i] + source_input2[i];
    source_hw_results[i] = 0;
  }

  // OPENCL HOST CODE AREA START
  // Create Program and Kernel
  auto devices = get_xil_devices();

  // read_binary_file() is a utility API which will load the binaryFile
  // and will return the pointer to file buffer.
  auto fileBuf = read_binary_file(binaryFile);
  cl::Program::Binaries bins{{fileBuf.data(), fileBuf.size()}};
  bool valid_device = false;
  for (unsigned int i = 0; i < devices.size(); i++) {
    auto device = devices[i];
    // Creating Context and Command Queue for selected Device
    OCL_CHECK(err, context = cl::Context(device, NULL, NULL, NULL, &err));
    OCL_CHECK(err, q = cl::CommandQueue(context, device,
                                        CL_QUEUE_PROFILING_ENABLE, &err));

    std::cout << "Trying to program device[" << i
              << "]: " << device.getInfo<CL_DEVICE_NAME>() << std::endl;
    cl::Program program(context, {device}, bins, NULL, &err);
    if (err != CL_SUCCESS) {
      std::cout << "Failed to program device[" << i << "] with xclbin file!\n";
    } else {
      std::cout << "Device[" << i << "]: program successful!\n";
      OCL_CHECK(err, krnl_vadd = cl::Kernel(program, "krnl_vadd_rtl", &err));
      valid_device = true;
      break; // we break because we found a valid device
    }
  }
  if (!valid_device) {
    std::cout << "Failed to program any device found, exit!\n";
    exit(EXIT_FAILURE);
  }

  // Allocate Buffer in Global Memory
  OCL_CHECK(
      err, cl::Buffer buffer_r1(context, CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,
                                vector_size_bytes, source_input1.data(), &err));
  OCL_CHECK(err, cl::Buffer buffer_w(
                     context, CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY,
                     vector_size_bytes, source_hw_results.data(), &err));

  // Set the Kernel Arguments
  OCL_CHECK(err, err = krnl_vadd.setArg(0, buffer_r1));
  OCL_CHECK(err, err = krnl_vadd.setArg(1, buffer_w));
  OCL_CHECK(err, err = krnl_vadd.setArg(2, size));

  // Copy input data to device global memory
  OCL_CHECK(err, err = q.enqueueMigrateMemObjects({buffer_r1},
                                                  0 /* 0 means from host*/));

  // Launch the Kernel
  OCL_CHECK(err, err = q.enqueueTask(krnl_vadd));

  // Copy Result from Device Global Memory to Host Local Memory
  OCL_CHECK(err, err = q.enqueueMigrateMemObjects({buffer_w},
                                                  CL_MIGRATE_MEM_OBJECT_HOST));
  OCL_CHECK(err, err = q.finish());

  // OPENCL HOST CODE AREA END

  // Compare the results of the Device to the simulation
  int match = 0;
  for (int i = 0; i < size; i++) {
    if (source_hw_results[i] != source_sw_results[i]) {
      std::cout << "Error: Result mismatch" << std::endl;
      std::cout << "i = " << i << " Software result = " << source_sw_results[i]
                << " Device result = " << source_hw_results[i] << std::endl;
      match = 1;
      break;
    }
  }

  std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
  return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
