#include "coord3d.cu"
#include "coord3d_aligned.cu"
#include <cooperative_groups.h>
#include <cooperative_groups/reduce.h>
#include "cuda_runtime.h"
#include <assert.h>
#include<iostream>
#include <fstream>

#define __HD__ __device__ __host__ 
namespace cg = cooperative_groups;

template <typename T>
void copy_and_append(T* memory, const T* fullerene, size_t N){
    for (size_t i = 0; i < N; i++)
    {
        memory[i] = fullerene[i];
    }
}

template <typename T>
T* synthetic_array(size_t N, const size_t num_molecules, const T* fullerene){
    size_t array_size = N;
    if (sizeof(T) != sizeof(device_coord3d))
    {
        array_size *= 3;
    }
    T* storage_array = new T[array_size*num_molecules];
    for (size_t i = 0; i < num_molecules; i++)
    {
        copy_and_append(&storage_array[array_size*i],fullerene,array_size);
    }
    return storage_array;
}


__device__ void align16(device_coord3d* input, coord3d_a* output, size_t N){
    cg::sync(cg::this_grid());
    output[threadIdx.x] = {input[threadIdx.x].x, input[threadIdx.x].y, input[threadIdx.x].z, 0};
    cg::sync(cg::this_grid());
}

template <typename T>
__device__ void pointerswap(T **r, T **s)
{
    T *pSwap = *r;
    *r = *s;
    *s = pSwap;
    return;
}

#if REDUCTION_METHOD==0
    __device__ device_real_t reduction(device_real_t* sdata, const device_real_t data){
        sdata[threadIdx.x] = data;
        BLOCK_SYNC
        if((Block_Size_Pow_2 > 512)){if (threadIdx.x < 512){sdata[threadIdx.x] += sdata[threadIdx.x + 512];} BLOCK_SYNC}
        if((Block_Size_Pow_2 > 256)){if (threadIdx.x < 256){sdata[threadIdx.x] += sdata[threadIdx.x + 256];} BLOCK_SYNC}
        if((Block_Size_Pow_2 > 128)){if (threadIdx.x < 128){sdata[threadIdx.x] += sdata[threadIdx.x + 128];} BLOCK_SYNC}
        if((Block_Size_Pow_2 > 64)){if (threadIdx.x < 64){sdata[threadIdx.x] += sdata[threadIdx.x + 64];} BLOCK_SYNC}
        if(threadIdx.x < 32){
        if((Block_Size_Pow_2 > 32)){if (threadIdx.x < 32){sdata[threadIdx.x] += sdata[threadIdx.x + 32];} __syncwarp();}
        cg::thread_block_tile<32> tile32 = cg::tiled_partition<32>(cg::this_thread_block());
        sdata[threadIdx.x] = cg::reduce(tile32, sdata[threadIdx.x], cg::plus<device_real_t>());
        }
        BLOCK_SYNC
        device_real_t sum = sdata[0];
        BLOCK_SYNC
        return sum;
    }
#elif REDUCTION_METHOD==1
    __device__ device_real_t reduction(device_real_t* sdata, const device_real_t data){
        sdata[threadIdx.x] = data;
        BLOCK_SYNC
        
        if (threadIdx.x < 512){sdata[threadIdx.x] += sdata[threadIdx.x + 512];} BLOCK_SYNC
        if (threadIdx.x < 256){sdata[threadIdx.x] += sdata[threadIdx.x + 256];} BLOCK_SYNC
        if (threadIdx.x < 128){sdata[threadIdx.x] += sdata[threadIdx.x + 128];} BLOCK_SYNC
        if (threadIdx.x < 64){sdata[threadIdx.x] += sdata[threadIdx.x + 64];} BLOCK_SYNC
        if(threadIdx.x < 32){
        if (threadIdx.x < 32){sdata[threadIdx.x] += sdata[threadIdx.x + 32];} __syncwarp();
        cg::thread_block_tile<32> tile32 = cg::tiled_partition<32>(cg::this_thread_block());
        sdata[threadIdx.x] = cg::reduce(tile32, sdata[threadIdx.x], cg::plus<device_real_t>());
        }
        BLOCK_SYNC
        device_real_t sum = sdata[0];
        BLOCK_SYNC
        return sum;
    }
#elif REDUCTION_METHOD==2
    __device__ device_real_t reduction(device_real_t *sdata, const device_real_t data){
        sdata[threadIdx.x] = data;
        cg::thread_block block = cg::this_thread_block();
        BLOCK_SYNC
        cg::thread_block_tile<32> tile32 = cg::tiled_partition<32>(block);
        sdata[threadIdx.x] = cg::reduce(tile32, sdata[threadIdx.x], cg::plus<device_real_t>());
        BLOCK_SYNC

        device_real_t beta = 0.0;
        if (block.thread_rank() == 0) {
            beta  = 0;
            for (uint16_t i = 0; i < block.size(); i += tile32.size()) {
                beta  += sdata[i];
            }
            sdata[0] = beta;
        }
        BLOCK_SYNC
        device_real_t sum = sdata[0];
        BLOCK_SYNC
        return sum;
    }
#endif



__device__ device_real_t reduction_max(device_real_t* sdata, const device_real_t data){
    sdata[threadIdx.x] = data;
    cg::thread_block block = cg::this_thread_block();
    cg::sync(block);
    
    if((Block_Size_Pow_2 > 512)){if (threadIdx.x < 512){sdata[threadIdx.x] = max(sdata[threadIdx.x + 512],sdata[threadIdx.x]);} cg::sync(block);}
    if((Block_Size_Pow_2 > 256)){if (threadIdx.x < 256){sdata[threadIdx.x] = max(sdata[threadIdx.x + 256],sdata[threadIdx.x]);} cg::sync(block);}
    if((Block_Size_Pow_2 > 128)){if (threadIdx.x < 128){sdata[threadIdx.x] = max(sdata[threadIdx.x + 128],sdata[threadIdx.x]);} cg::sync(block);}
    if((Block_Size_Pow_2 > 64)){if (threadIdx.x < 64){sdata[threadIdx.x] = max(sdata[threadIdx.x + 64],sdata[threadIdx.x]);} cg::sync(block);}
    if(threadIdx.x < 32){
    if((Block_Size_Pow_2 > 32)){if (threadIdx.x < 32){sdata[threadIdx.x] = max(sdata[threadIdx.x + 32],sdata[threadIdx.x]);} __syncwarp();}
    cg::thread_block_tile<32> tile32 = cg::tiled_partition<32>(block);
    sdata[threadIdx.x] = cg::reduce(tile32, sdata[threadIdx.x], cg::greater<device_real_t>()); 
    }
    cg::sync(block);
    device_real_t max = sdata[0];
    cg::sync(block);
    return max;
}

__device__ half reduction(half *sdata){

    cg::thread_block block = cg::this_thread_block();
    cg::sync(block);
    cg::thread_block_tile<32> tile32 = cg::tiled_partition<32>(block);
    sdata[threadIdx.x] = cg::reduce(tile32, sdata[threadIdx.x], cg::plus<half>());
    cg::sync(block);

    half beta = 0.0;
    if (block.thread_rank() == 0) {
        beta  = 0;
        for (uint16_t i = 0; i < block.size(); i += tile32.size()) {
            beta  += sdata[i];
        }
        sdata[0] = beta;
    }
    cg::sync(block);
    return sdata[0];
}




__HD__ void print(const device_coord3d& ab){
    printf("[%.8e, %.8e, %.8e]\n",ab.x,ab.y,ab.z);
}
__device__ void print(const half4& ab){
    print_coord(ab);
}

__device__ void print(const half2& ab){
    printf("[%.16e, %.16e] \n", __half2float(ab.x), __half2float(ab.y));
}

__HD__ void print(device_real_t a){
    printf("[%.16e]\n", a);
}

__HD__ void print(bool b){
    printf("[%d]\n",int(b));
}

__HD__ void print(int a){
    printf("[%d]\n",a);
}

__device__ void print(const ushort3& a){
    printf("[%d, %d, %d]\n",a.x,a.y,a.z);
}

__device__ void print(const uchar3& a){
    printf("[%d, %d, %d]\n",a.x,a.y,a.z);
}

__device__ void print(const uint3& a){
    printf("[%d, %d, %d]\n",a.x,a.y,a.z);
}

template <typename T>
__device__ void print_single(T data){
    if (threadIdx.x + blockIdx.x == 0) {
        print(data);
    }
}

template <typename T>
__device__ void sequential_print(T* data){
    for (size_t i = 0; i < blockDim.x; i++)
    {
        if (threadIdx.x == i)
        {
            print(data[i]);
        }
        cg::sync(cg::this_thread_block());
    }
}

template <typename T>
__device__ void sequential_print(T data, size_t fullerene_id){
    if (blockIdx.x == fullerene_id)
    {
    for (size_t i = 0; i < blockDim.x; i++)
    {
        if (threadIdx.x == i)
        {
            print(data);
        }
        cg::sync(cg::this_thread_block());
    }
    }
}

template <typename T>
__host__ void print_array(T* data, size_t N, size_t fullerene_id){
    for (size_t i = 0; i < N; i++)
    {
        print(data[fullerene_id + i]);
    }
}

template <typename T>
__host__ void to_binary(std::string filename,T* data, size_t bytes){
    T* pointer =  data;
    std::fstream myFile (filename, std::fstream::out | std::fstream::in | std::fstream::trunc | std::fstream::binary );

    myFile.write(reinterpret_cast<const char*>(pointer), bytes);
    if(!myFile)
      std::cout<<"error";
    myFile.close();
}

template <typename T>
__device__ void sequential_print(T* data, size_t fullerene_id){
    if (blockIdx.x == fullerene_id)
    {
    for (size_t i = 0; i < blockDim.x; i++)
    {
        if (threadIdx.x == i)
        {
            print(data[i]);
        }
        cg::sync(cg::this_thread_block());
    }
    }
}

template <typename T>
__HD__ void swap_reals(T& a, T& b){
    T temp = a;
    a = b;
    b = temp;
}

void printLastCudaError(std::string message = ""){
    cudaError_t error = cudaGetLastError();
    if(error != cudaSuccess){
        std::cout << "\n" << message << " :\t";
        std::cout << cudaGetErrorString(error);
        printf("\n");
    }
}

__device__ void clear_cache(device_real_t* sdata, size_t N){
    BLOCK_SYNC
    for (size_t index = threadIdx.x; index < N; index+=blockDim.x)
    {
        sdata[index] = (device_real_t)0.0;
    }
    BLOCK_SYNC
}
__device__ device_real_t global_reduction(device_real_t *sdata, device_real_t *gdata, device_real_t data){
    GRID_SYNC
    device_real_t block_sum    = reduction(sdata,data);
    if(threadIdx.x == 0){gdata[blockIdx.x] = block_sum;}
    GRID_SYNC

        if (gridDim.x > 1024 && threadIdx.x == 0 && ((blockIdx.x + 1024) < gridDim.x))   {if (blockIdx.x < 1024) {gdata[blockIdx.x]  += gdata[blockIdx.x + 1024];}} GRID_SYNC
        if (gridDim.x > 512 && threadIdx.x == 0 && ((blockIdx.x + 512) < gridDim.x))    {if (blockIdx.x < 512)  {gdata[blockIdx.x]  += gdata[blockIdx.x + 512];}} GRID_SYNC
        if (gridDim.x > 256 && threadIdx.x == 0 && ((blockIdx.x + 256) < gridDim.x))    {if (blockIdx.x < 256)  {gdata[blockIdx.x]  += gdata[blockIdx.x + 256];}} GRID_SYNC
        if (gridDim.x > 128 && threadIdx.x == 0 && ((blockIdx.x + 128) < gridDim.x))    {if (blockIdx.x < 128)  {gdata[blockIdx.x]  += gdata[blockIdx.x + 128];}} GRID_SYNC
        if (gridDim.x > 64 && threadIdx.x == 0 && ((blockIdx.x + 64) < gridDim.x))     {if (blockIdx.x < 64)   {gdata[blockIdx.x]  += gdata[blockIdx.x + 64];}} GRID_SYNC
        if (gridDim.x > 32 && threadIdx.x == 0 && ((blockIdx.x + 32) < gridDim.x))     {if (blockIdx.x < 32)   {gdata[blockIdx.x]  += gdata[blockIdx.x + 32];}} GRID_SYNC
        if (threadIdx.x < 32)
        {
            cg::thread_block_tile<32> tile32 = cg::tiled_partition<32>(cg::this_thread_block());
            gdata[threadIdx.x] = cg::reduce(tile32, gdata[threadIdx.x], cg::plus<device_real_t>()); 
        }
    GRID_SYNC
    device_real_t sum = (device_real_t)0.0;
    sum = gdata[0];
    GRID_SYNC
    return sum;
}