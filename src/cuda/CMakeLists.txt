enable_language(CXX CUDA)

set_source_files_properties(tutte.cu PROPERTIES COMPILE_FLAGS "--std c++17 --use_fast_math --fmad true --ftz true --maxrregcount=40 -lineinfo -Xptxas -v --resource-usage -gencode arch=compute_86,code=sm_86  -I /opt/nvidia/hpc_sdk/Linux_x86_64/2022/cuda/11.8/include/")
set_source_files_properties(dualise.cu PROPERTIES COMPILE_FLAGS "--std c++17 --use_fast_math --fmad true --ftz true --maxrregcount=40 -lineinfo -Xptxas -v --resource-usage -gencode arch=compute_86,code=sm_86  -I /opt/nvidia/hpc_sdk/Linux_x86_64/2022/cuda/11.8/include/")
set_source_files_properties(benchmark_functions.cu PROPERTIES COMPILE_FLAGS "--std c++17 --use_fast_math --fmad true --ftz true --maxrregcount=40 -lineinfo -Xptxas -v --resource-usage -gencode arch=compute_86,code=sm_86  -I /opt/nvidia/hpc_sdk/Linux_x86_64/2022/cuda/11.8/include/")
set_source_files_properties(isomer_queue.cu PROPERTIES COMPILE_FLAGS "--std c++17 --use_fast_math --fmad true --ftz true --maxrregcount=40 -lineinfo -Xptxas -v --resource-usage -gencode arch=compute_86,code=sm_86  -I /opt/nvidia/hpc_sdk/Linux_x86_64/2022/cuda/11.8/include/")
add_library(fullerenes_cuda_lib SHARED isomer_queue.cu cu_array.cu misc_cuda.cu forcefield.cu tutte.cu spherical_projection.cu dualise.cu benchmark_functions.cu)
set_property(TARGET fullerenes_cuda_lib PROPERTY CUDA_ARCHITECTURES "86")
#set_target_properties(fullerenes_cuda_lib PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
#set_target_properties(fullerenes_cuda_lib PROPERTIES POSITION_INDEPENDENT_CODE ON)
#set_target_properties(fullerenes_cuda_lib PROPERTIES CUDA_RESOLVE_DEVICE_SYMBOLS ON)

