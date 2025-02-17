#ifndef CUDA_IO_H
#define CUDA_IO_H
#include <cuda_runtime.h>
#include "launch_ctx.hh"
#include <chrono>
#include <queue>
#include "fullerenes/gpu/isomer_batch.hh"

namespace cuda_io{
    cudaError_t output_to_queue(std::queue<std::tuple<Polyhedron, size_t, IsomerStatus>>& queue, IsomerBatch& batch, const bool copy_2d_layout = true);
    cudaError_t copy(IsomerBatch& target, const IsomerBatch& source, const LaunchCtx& ctx = LaunchCtx(), const LaunchPolicy policy = LaunchPolicy::SYNC, const std::pair<int,int>& lhs_range = {-1,-1}, const std::pair<int,int>& rhs_range = {-1,-1});
    cudaError_t resize(IsomerBatch& batch, size_t new_capacity, const LaunchCtx& ctx = LaunchCtx(), const LaunchPolicy policy = LaunchPolicy::SYNC, int front = -1, int back = -1);
    cudaError_t reset_convergence_statuses(IsomerBatch& batch, const LaunchCtx& ctx = LaunchCtx(), const LaunchPolicy policy = LaunchPolicy::SYNC);
    std::tuple<int, device_real_t, device_real_t> compare_isomer_arrays(device_real_t* a, device_real_t* b, int n_isomers, int n_elements_per_isomer, device_real_t rtol = 0.0, bool verbose = false, device_real_t zero_threshold = 1e-8);
    void is_close(const IsomerBatch& a, const IsomerBatch& b, device_real_t tol = 0.0, bool verbose = false);
    int count_batch_status(const IsomerBatch& input, const IsomerStatus status);
    
    //Returns the average number of iterations of isomers in the batch that are not empty.
    double average_iterations(const IsomerBatch& input);
    void sort(IsomerBatch& batch, const BatchMember key = IDS, const SortOrder order = ASCENDING);
    
    template <typename T>  
    T mean(std::vector<T>& input);
    std::chrono::nanoseconds sdev(std::vector<std::chrono::nanoseconds>& input);

}
#endif