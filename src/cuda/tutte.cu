#include <cuda.h>
#include <cooperative_groups.h>
#include <cooperative_groups/reduce.h>
#include <cooperative_groups/scan.h>
#include "fullerenes/gpu/kernels.hh"
namespace gpu_kernels{
namespace isomerspace_tutte{
#include "device_includes.cu"

__global__
void tutte_layout_(IsomerBatch B, const size_t iterations){
    DEVICE_TYPEDEFS
    extern __shared__  real_t sharedmem[];
    clear_cache(sharedmem, Block_Size_Pow_2);
    for (int isomer_idx = blockIdx.x; isomer_idx < B.isomer_capacity; isomer_idx+= gridDim.x){
    if (B.statuses[isomer_idx] != IsomerStatus::EMPTY){
    size_t offset = isomer_idx * blockDim.x;

    DeviceCubicGraph FG(&B.cubic_neighbours[offset*3]); 
    real_t* base_pointer        = sharedmem + Block_Size_Pow_2;
    coord2d* xys        = reinterpret_cast<coord2d*>(base_pointer);
    coord2d* newxys     = reinterpret_cast<coord2d*>(base_pointer) + blockDim.x;


    node3 ns            = (reinterpret_cast<node3*>(B.cubic_neighbours) + offset)[threadIdx.x];
    xys[threadIdx.x]    = {real_t(0.0), real_t(0.0)};
    device_node_t outer_face[6];
    device_node_t outer_face_vertex   = 0;
    uint8_t Nface = FG.get_face_oriented(0,FG.cubic_neighbours[0], outer_face);    
    reinterpret_cast<bool*>(sharedmem)[threadIdx.x] =  false; BLOCK_SYNC;
    if(threadIdx.x < Nface){
      outer_face_vertex = outer_face[threadIdx.x];
      reinterpret_cast<bool*>(sharedmem)[outer_face_vertex] =  true; 
    }
    BLOCK_SYNC;
    bool fixed = reinterpret_cast<bool*>(sharedmem)[threadIdx.x];

    if(threadIdx.x < Nface) xys[outer_face_vertex] = {sin(threadIdx.x*(real_t)2.0*real_t(M_PI)/double(Nface)),cos(threadIdx.x*(real_t)2.0*real_t(M_PI)/double(Nface))};
    BLOCK_SYNC
    bool converged          = false;
    real_t max_change       = real_t(0.0);
    if(fixed) newxys[threadIdx.x] = xys[threadIdx.x];
    for (size_t i = 0; i < iterations && !converged; i++)
    {   
        max_change = real_t(0.0);
        BLOCK_SYNC
        coord2d neighbour_sum   = {real_t(0.0),real_t(0.0)};    
        for (uint8_t j = 0; j < 3; j++) neighbour_sum += xys[d_get(ns,j)];

        // Calculate the new position of the point
        if(!fixed) newxys[threadIdx.x] = xys[threadIdx.x]*real_t(0.15) + (neighbour_sum/3)*real_t(0.85);
        real_t neighbour_dist = 0.0f;

        // Calculate the distance between neighbours
        for (uint8_t j = 0; j < 3; j++) neighbour_dist += norm(xys[threadIdx.x] - xys[d_get(ns,j)])/3;
        
        BLOCK_SYNC
        real_t relative_change = 0.0f;

        // Calculate the relative change
        if (neighbour_dist > 0.0f && !fixed){ 
            relative_change = norm(xys[threadIdx.x] - newxys[threadIdx.x])/neighbour_dist;
        }

        // Reduce the relative change to find the maximum change
        real_t iteration_max = reduction_max(sharedmem, relative_change);
        if (iteration_max > max_change) max_change = iteration_max;
        converged = max_change <= 5e-4;

        // Update the position of the point
        xys[threadIdx.x] = newxys[threadIdx.x];
    }
    BLOCK_SYNC
    (reinterpret_cast<coord2d*>(B.xys) + offset )[threadIdx.x] = xys[threadIdx.x];
    }
    }
}

float kernel_time = 0.0;
std::chrono::microseconds time_spent(){
    return std::chrono::microseconds((int) (kernel_time*1000.f));
}

void reset_time(){
    kernel_time = 0.0;
}

cudaError_t tutte_layout(IsomerBatch& B, const size_t max_iterations, const LaunchCtx& ctx, const LaunchPolicy policy){
    cudaSetDevice(B.get_device_id());
    static std::vector<bool> first_call(16, true);
    static cudaEvent_t start[16], stop[16];
    float single_kernel_time = 0.0;
    auto dev = B.get_device_id();
    if(first_call[dev]) {cudaEventCreate(&start[dev]); cudaEventCreate(&stop[dev]);}

    //If launch ploicy is synchronous then wait.
    if(policy == LaunchPolicy::SYNC){ ctx.wait();}
    else if(policy == LaunchPolicy::ASYNC && !first_call[dev]){
        //Records time from previous kernel call
        cudaEventElapsedTime(&single_kernel_time, start[dev], stop[dev]);
        kernel_time += single_kernel_time;
    }
    size_t smem = sizeof(device_coord2d)*B.n_atoms*2 + sizeof(device_real_t)*Block_Size_Pow_2;
    static LaunchDims dims((void*)tutte_layout_, B.n_atoms, smem, B.isomer_capacity);
    dims.update_dims((void*)tutte_layout_, B.n_atoms, smem, B.isomer_capacity);
    void* kargs[]{(void*)&B,(void*)&max_iterations};

    cudaEventRecord(start[dev], ctx.stream);
    cudaError_t error = safeCudaKernelCall((void*)tutte_layout_, dims.get_grid(), dims.get_block(), kargs, smem, ctx.stream);  
    cudaEventRecord(stop[dev], ctx.stream);
    
    if(policy == LaunchPolicy::SYNC) {
        ctx.wait();
        cudaEventElapsedTime(&single_kernel_time, start[dev], stop[dev]);
        kernel_time += single_kernel_time;
    }
    printLastCudaError("Tutte: ");
    first_call[dev] = false;
    return error;
}

}}