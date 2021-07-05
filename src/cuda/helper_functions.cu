#include "coord3d.cu"
#include "coord3d_aligned.cu"
#include <cooperative_groups.h>
#include <cooperative_groups/reduce.h>
#include "cuda_runtime.h"
#include <assert.h>
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
    if (sizeof(T) != sizeof(coord3d))
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


__device__ void align16(coord3d* input, coord3d_a* output, size_t N){
    cg::sync(cg::this_grid());
    size_t tid = threadIdx.x;
    for (size_t i = 0; i < N; i++)
    {
        output[i] = {input[i].x, input[i].y, input[i].z, 0};
    }
    cg::sync(cg::this_grid());
    
}



//All parameter arrays are indexed by a binary sum, 0,1,2,3,4,...
//Pentagons = 0
//Hexagons = 1
//PPP = 0, {HPP, PHP, PPH} = 1, {PHH, HPH, HHP} = 2, {HHH} = 3
__constant__ real_t optimal_corner_cos_angles[2] = {-0.3090169944, -0.5}; 
__constant__ real_t optimal_bond_lengths[3] = {1.479, 1.458, 1.401}; 
__constant__ real_t optimal_dih_cos_angles[4] = {0.79465455715, 0.87290360705, 0.91394971663, 1}; 

__constant__ real_t angle_forces[2] = {100.0, 100.0}; 
__constant__ real_t bond_forces[3] = {260.0, 390.0, 450.0}; 
__constant__ real_t dih_forces[4] = {35.0, 65.0, 85.0, 270.0}; 



__device__ __host__ struct BookkeepingData{
    const node_t* neighbours;
    const uint8_t* face_right;
    const node_t* next_on_face;
    const node_t* prev_on_face;
    __device__ __host__ BookkeepingData (const node_t* neighbours, const uint8_t* face_right, const node_t* next_on_face, const node_t* prev_on_face) : 
        neighbours(neighbours), face_right(face_right), next_on_face(next_on_face), prev_on_face(prev_on_face) {}
};

__device__ struct Constants{
    const coord3d f_bond;
    const coord3d f_inner_angle;
    const coord3d f_inner_dihedral;
    const coord3d f_outer_angle_m;
    const coord3d f_outer_angle_p;
    const coord3d f_outer_dihedral;

    const coord3d r0;
    const coord3d angle0;
    const coord3d outer_angle_m0;
    const coord3d outer_angle_p0;
    const coord3d inner_dih0;
    const coord3d outer_dih0;
    
    __device__ Constants(const coord3d f_bond, const coord3d f_inner_angle, const coord3d f_inner_dihedral, const coord3d f_outer_angle_m, const coord3d f_outer_angle_p, const coord3d f_outer_dihedral,
                            const coord3d r0, const coord3d angle0, const coord3d outer_angle_m0, const coord3d outer_angle_p0, const coord3d inner_dih0, const coord3d outer_dih0): f_bond(f_bond), f_inner_angle(f_inner_angle),
                            f_inner_dihedral(f_inner_dihedral), f_outer_angle_m(f_outer_angle_m), f_outer_angle_p(f_outer_angle_p), f_outer_dihedral(f_outer_dihedral), r0(r0), angle0(angle0), outer_angle_m0(outer_angle_m0), outer_angle_p0(outer_angle_p0),
                            inner_dih0(inner_dih0), outer_dih0(outer_dih0) {}

};

__device__ Constants compute_constants(BookkeepingData &dat, node_t node_id){
    coord3d r0 ; coord3d angle0 ; coord3d inner_dih0 ; coord3d outer_angle_m0 ; coord3d outer_angle_p0 ; coord3d outer_dih0 ;
    coord3d f_bond ; coord3d f_inner_angle ; coord3d f_inner_dihedral ; coord3d f_outer_angle_m ; coord3d f_outer_angle_p ; coord3d f_outer_dihedral ;
    
    
    for (uint8_t j = 0; j < 3; j++) {
        uint8_t f_r = dat.face_right[node_id * 3 + j] - 5;
        uint8_t f_l = dat.face_right[node_id * 3 + (2 + j)%3] - 5;

        uint8_t face_sum = dat.face_right[node_id * 3] - 5 + dat.face_right[node_id * 3 + 1] - 5 + dat.face_right[node_id * 3 + 2] - 5;
        uint8_t dihedral_face_sum = dat.face_right[dat.neighbours[node_id * 3 + j] * 3]-5 + dat.face_right[dat.neighbours[node_id * 3 + j] * 3 + 1]-5 +  dat.face_right[dat.neighbours[node_id * 3 + j] * 3 + 2]-5;

        //Load equillibirium distance, angles and dihedral angles from face information.
        set(r0,j,optimal_bond_lengths[ f_l + f_r ]);
        set(angle0,j,optimal_corner_cos_angles[ f_r ]);
        set(inner_dih0,j,optimal_dih_cos_angles[ face_sum ]);
        set(outer_angle_m0,j,optimal_corner_cos_angles[ f_l ]);
        set(outer_angle_p0,j,optimal_corner_cos_angles[ f_r ]);
        set(outer_dih0,j,optimal_dih_cos_angles[ dihedral_face_sum ]);

        //Load force constants from neighbouring face information.
        set(f_bond,j,bond_forces[ f_l + f_r ]);
        set(f_inner_angle,j,angle_forces[ f_l ]);
        set(f_inner_dihedral,j,dih_forces[ face_sum]);
        set(f_outer_angle_m,j,angle_forces[ f_r ]);
        set(f_outer_angle_p,j,angle_forces[ f_l ]);
        set(f_outer_dihedral,j,dih_forces[ dihedral_face_sum]);
        
    }
    return Constants::Constants(f_bond,f_inner_angle,f_inner_dihedral, f_outer_angle_m, f_outer_angle_p, f_outer_dihedral, r0, angle0, outer_angle_m0, outer_angle_p0, inner_dih0, outer_dih0);
}

//Reduction method for single block fullerenes.
__device__ void reduction(real_t *sdata, const node_t N){

    cg::thread_block block = cg::this_thread_block();
    cg::sync(block);
    cg::thread_block_tile<32> tile32 = cg::tiled_partition<32>(block);
    sdata[threadIdx.x] = cg::reduce(tile32, sdata[threadIdx.x], cg::plus<real_t>());
    cg::sync(block);

    real_t beta = 0.0;
    if (block.thread_rank() == 0) {
        beta  = 0;
        for (uint16_t i = 0; i < N; i += tile32.size()) {
            beta  += sdata[i];
        }
        sdata[0] = beta;
    }
    cg::sync(block);
}

//Multi purpose reduction algorithm (Small or Large fullerenes).
__device__ void reduction(real_t *sdata, real_t *gdata, const node_t N, const bool single_block_fullerenes){
    cg::thread_block block = cg::this_thread_block();

    cg::sync(block);
    if (((threadIdx.x + blockIdx.x * blockDim.x) >= N) && !single_block_fullerenes)
    {
        sdata[threadIdx.x] = 0;
    }
    cg::sync(block);
    cg::thread_block_tile<32> tile32 = cg::tiled_partition<32>(block);
    sdata[threadIdx.x] = cg::reduce(tile32, sdata[threadIdx.x], cg::plus<real_t>());
    cg::sync(block);
    
    real_t beta = 0.0;
    if (single_block_fullerenes)
    {
        if (block.thread_rank() == 0) {
            for (uint16_t i = 0; i < N; i += tile32.size()) {
                beta  += sdata[i];
            }
            sdata[0] = beta;
        }
        cg::sync(block);
    }
    else 
    {   
        auto grid = cg::this_grid();
        if (block.thread_rank() == 0) 
        {
            for (uint16_t i = 0; i < block.size(); i += tile32.size()) 
            {
                beta  += sdata[i];
            }
            gdata[blockIdx.x] = beta;
        }
        cg::sync(grid);
        beta = 0.0;
        if (grid.thread_rank() == 0)
        {
            for (uint16_t i = 0; i < gridDim.x; i++) 
            {
                beta  += gdata[i];
            }
            gdata[0] = beta;
        }
        cg::sync(grid);
        if (block.thread_rank() == 0) {sdata[0] = gdata[0];}
        cg::sync(grid);
    }
}

template < class T >
size_t optimize_block_size(size_t N, cudaDeviceProp prop, T kernel){
    int maxActiveBlocks;
    size_t best_size = prop.warpSize;
    size_t min_waste = prop.maxThreadsPerMultiProcessor;
    for (size_t blocksize = prop.warpSize*2; blocksize < prop.maxThreadsPerBlock; blocksize +=prop.warpSize)
    {
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(&maxActiveBlocks, kernel, (int)blocksize, (size_t)(sizeof(real_t)*blocksize));
        size_t wasted_threads = N % blocksize  +  blocksize*maxActiveBlocks % prop.maxThreadsPerMultiProcessor;

        if (wasted_threads < min_waste)
        {
            min_waste = wasted_threads;
            best_size = blocksize;
        }
    }
    return best_size;
}


