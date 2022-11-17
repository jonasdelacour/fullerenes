#include "fullerenes/buckygen-wrapper.hh"
#include "fullerenes/triangulation.hh"
#include "fullerenes/polyhedron.hh"
#include "fullerenes/gpu/cuda_definitions.h"
#include <chrono>
#include <fstream>
#include "filesystem"
#include "random"
#include "numeric"
#include "fullerenes/gpu/batch_queue.hh"
#include "fullerenes/gpu/cuda_io.hh"
#include "fullerenes/gpu/kernels.hh"

const std::unordered_map<size_t,size_t> num_fullerenes = {{20,1},{22,0},{24,1},{26,1},{28,2},{30,3},{32,6},{34,6},{36,15},{38,17},{40,40},{42,45},{44,89},{46,116},{48,199},{50,271},{52,437},{54,580},{56,924},{58,1205},{60,1812},{62,2385},{64,3465},{66,4478},{68,6332},{70,8149},{72,11190},{74,14246},{76,19151},{78,24109},{80,31924},{82,39718},{84,51592},{86,63761},{88,81738},{90,99918},{92,126409},{94,153493},{96,191839},{98,231017},{100,285914},{102,341658},{104,419013},{106,497529},{108,604217},{110,713319},{112,860161},{114,1008444},{116,1207119},{118,1408553},{120,1674171},{122,1942929},{124,2295721},{126,2650866},{128,3114236},{130,3580637},{132,4182071},{134,4787715},{136,5566949},{138,6344698},{140,7341204},{142,8339033},{144,9604411},{146,10867631},{148,12469092},{150,14059174},{152,16066025},{154,18060979},{156,20558767},{158,23037594},{160,26142839},{162,29202543},{164,33022573},{166,36798433},{168,41478344},{170,46088157},{172,51809031},{174,57417264},{176,64353269},{178,71163452},{180,79538751},{182,87738311},{184,97841183},{186,107679717},{188,119761075},{190,131561744},{192,145976674},{194,159999462},{196,177175687},{198,193814658},{200,214127742},{202,233846463},{204,257815889},{206,281006325},{208,309273526},{210,336500830},{212,369580714},{214,401535955},{216,440216206},{218,477420176},{220,522599564},{222,565900181},{224,618309598},{226,668662698},{228,729414880},{230,787556069},{232,857934016},{234,925042498},{236,1006016526},{238,1083451816},{240,1176632247},{242,1265323971},{244,1372440782},{246,1474111053},{248,1596482232},{250,1712934069},{252,1852762875},{254,1985250572},{256,2144943655},{258,2295793276},{260,2477017558},{262,2648697036},{264,2854536850},{266,3048609900},{268,3282202941},{270,3501931260},{272,3765465341},{274,4014007928},{276,4311652376},{278,4591045471},{280,4926987377},{282,5241548270},{284,5618445787},{286,5972426835},{288,6395981131},{290,6791769082},{292,7267283603},{294,7710782991},{296,8241719706},{298,8738236515},{300,9332065811},{302,9884604767},{304,10548218751},{306,11164542762},{308,11902015724},{310,12588998862},{312,13410330482},{314,14171344797},{316,15085164571},{318,15930619304},{320,16942010457},{322,17880232383},{324,19002055537},{326,20037346408},{328,21280571390},{330,22426253115},{332,23796620378},{334,25063227406},{336,26577912084},{338,27970034826},{340,29642262229},{342,31177474996},{344,33014225318},{346,34705254287},{348,36728266430},{350,38580626759},{352,40806395661},{354,42842199753},{356,45278616586},{358,47513679057},{360,50189039868},{362,52628839448},{364,55562506886},{366,58236270451},{368,61437700788},{370,64363670678},{372,67868149215},{374,71052718441},{376,74884539987},{378,78364039771},{380,82532990559},{382,86329680991},{384,90881152117},{386,95001297565},{388,99963147805},{390,104453597992},{392,109837310021},{394,114722988623},{396,120585261143},{398,125873325588},{400,132247999328}};
using namespace chrono;
using namespace chrono_literals;

int main(int argc, char** argv){
    const size_t N                = argc>1 ? strtol(argv[1],0,0): 20; // Argument 1: Number of Vertices
    auto N_runs = 50000;

    ofstream out_file("ForcefieldOpt_" + to_string(N) + ".txt");
    ofstream out_file_std("ForcefieldOpt_STD_" + to_string(N) + ".txt");
    if (N == 22) return 1;
    BuckyGen::buckygen_queue Q = BuckyGen::start(N,false,false);  
    auto sample_size = min(gpu_kernels::isomerspace_forcefield::optimal_batch_size(N,0),(int)num_fullerenes.find(N)->second);
    
    IsomerBatch batch0(N,sample_size,DEVICE_BUFFER);
    IsomerBatch batch1(N,sample_size,DEVICE_BUFFER);
    IsomerBatch batch2(N,sample_size,DEVICE_BUFFER, 1);
    LaunchCtx device1(1);
    LaunchCtx device0(0);
    cuda_io::IsomerQueue isomer_q(N);
    cuda_io::IsomerQueue IsomerQ(N);
    //Pre allocate the device queue such that it doesn't happen during benchmarking
    isomer_q.resize(2*sample_size);
    auto Nf = N/2 + 2;
    Graph G;
    G.neighbours = neighbours_t(Nf, std::vector<node_t>(6));
    G.N = Nf;
    bool more_to_generate = true;

    auto T0 = high_resolution_clock::now();
    auto T_FF    = std::vector<std::chrono::nanoseconds>(N_runs);
    
    auto path = "isomerspace_samples/dual_layout_" + to_string(N) + "_seed_42";
    ifstream isomer_sample(path,std::ios::binary);
    auto fsize = std::filesystem::file_size(path);
    std::vector<device_node_t> input_buffer(fsize/sizeof(device_node_t));
    auto available_samples = fsize / (Nf*6*sizeof(device_node_t));
    isomer_sample.read(reinterpret_cast<char*>(input_buffer.data()), Nf*6*sizeof(device_node_t)*available_samples);

    std::vector<int> random_IDs(available_samples);
    std::iota(random_IDs.begin(), random_IDs.end(), 0);
    std::shuffle(random_IDs.begin(), random_IDs.end(), std::mt19937{42});
    std::vector<int> id_subset(random_IDs.begin(), random_IDs.begin()+sample_size);




    for (int i = 0; i < sample_size; ++i){
        for (size_t j = 0; j < Nf; j++){
            G.neighbours[j].clear();
            for (size_t k = 0; k < 6; k++) {
                auto u = input_buffer[id_subset[i]*Nf*6 + j*6 +k];
                if(u != UINT16_MAX) G.neighbours[j].push_back(u);
            }
        }
            auto Tstart = high_resolution_clock::now(); 
        isomer_q.insert(G,i);
    }

    isomer_q.refill_batch(batch1);
    gpu_kernels::isomerspace_dual::cubic_layout(batch1);
    gpu_kernels::isomerspace_tutte::tutte_layout(batch1);
    gpu_kernels::isomerspace_X0::zero_order_geometry(batch1,4.0);
    cuda_io::reset_convergence_statuses(batch1);
    IsomerQ.insert(batch1);
    IsomerQ.refill_batch(batch0);
    cuda_io::copy(batch2,batch0);
    for (int l = 0; l < N_runs; l++){
        //cuda_io::reset_convergence_statuses(batch0,device0);
        cuda_io::reset_convergence_statuses(batch2,device1);
        auto T1 = high_resolution_clock::now();
            //gpu_kernels::isomerspace_forcefield::optimize_batch<BUSTER>(batch0,N*5,N*5,device0,LaunchPolicy::ASYNC);
            gpu_kernels::isomerspace_forcefield::optimize_batch<BUSTER>(batch2,N*5,N*5,device1,LaunchPolicy::ASYNC);
            device1.wait(); //device0.wait(); 
        T_FF[l] = high_resolution_clock::now() - T1;
        out_file << N << ", "<< sample_size << ", " << (high_resolution_clock::now()-T0)/1us << ", " << T_FF[l]/1us << "\n";
        if (l%100 == 0){
            std::cout << N << ", "<< sample_size << ", " << (high_resolution_clock::now()-T0)/1us << ", " << T_FF[l]/1us << "\n";
        }
    }
    using namespace cuda_io;
    out_file << N << ", "<< sample_size << ", " << mean(T_FF)/1ns;
    out_file_std << N << ", "<< sample_size << ", " << sdev(T_FF)/1ns;
LaunchCtx::clear_allocations();
}