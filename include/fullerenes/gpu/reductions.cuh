#ifndef CUDA_REDUCTIONS
#define CUDA_REDUCTIONS

namespace cg = cooperative_groups;

__device__ device_real_t reduction(device_real_t* sdata, const device_real_t data);

__device__ device_real_t reduction_max(device_real_t* sdata, const device_real_t data);

__device__ device_node_t reduction_max(device_node_t* sdata, const device_node_t data);

__device__ device_real_t global_reduction(device_real_t* sdata, device_real_t* gdata, device_real_t data, bool mask = true);

#endif
