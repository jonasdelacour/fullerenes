#include <csignal>
#include <sys/stat.h>
#include <limits.h>
#include <chrono>
#include <filesystem>
#include <iostream>
#include <iomanip>
#include <thread>
#include <future>
#include "fullerenes/buckygen-wrapper.hh"
#include "fullerenes/triangulation.hh"
#include "fullerenes/polyhedron.hh"
#include "fullerenes/progress_bar.hh"
#include "fullerenes/gpu/benchmark_functions.hh"

using namespace std;
using namespace std::chrono;
#include "fullerenes/gpu/isomer_queue.hh"
#include "fullerenes/gpu/cuda_io.hh"
#include "fullerenes/gpu/kernels.hh"

const std::unordered_map<size_t,size_t> num_fullerenes = {{20,1},{22,0},{24,1},{26,1},{28,2},{30,3},{32,6},{34,6},{36,15},{38,17},{40,40},{42,45},{44,89},{46,116},{48,199},{50,271},{52,437},{54,580},{56,924},{58,1205},{60,1812},{62,2385},{64,3465},{66,4478},{68,6332},{70,8149},{72,11190},{74,14246},{76,19151},{78,24109},{80,31924},{82,39718},{84,51592},{86,63761},{88,81738},{90,99918},{92,126409},{94,153493},{96,191839},{98,231017},{100,285914},{102,341658},{104,419013},{106,497529},{108,604217},{110,713319},{112,860161},{114,1008444},{116,1207119},{118,1408553},{120,1674171},{122,1942929},{124,2295721},{126,2650866},{128,3114236},{130,3580637},{132,4182071},{134,4787715},{136,5566949},{138,6344698},{140,7341204},{142,8339033},{144,9604411},{146,10867631},{148,12469092},{150,14059174},{152,16066025},{154,18060979},{156,20558767},{158,23037594},{160,26142839},{162,29202543},{164,33022573},{166,36798433},{168,41478344},{170,46088157},{172,51809031},{174,57417264},{176,64353269},{178,71163452},{180,79538751},{182,87738311},{184,97841183},{186,107679717},{188,119761075},{190,131561744},{192,145976674},{194,159999462},{196,177175687},{198,193814658},{200,214127742},{202,233846463},{204,257815889},{206,281006325},{208,309273526},{210,336500830},{212,369580714},{214,401535955},{216,440216206},{218,477420176},{220,522599564},{222,565900181},{224,618309598},{226,668662698},{228,729414880},{230,787556069},{232,857934016},{234,925042498},{236,1006016526},{238,1083451816},{240,1176632247},{242,1265323971},{244,1372440782},{246,1474111053},{248,1596482232},{250,1712934069},{252,1852762875},{254,1985250572},{256,2144943655},{258,2295793276},{260,2477017558},{262,2648697036},{264,2854536850},{266,3048609900},{268,3282202941},{270,3501931260},{272,3765465341},{274,4014007928},{276,4311652376},{278,4591045471},{280,4926987377},{282,5241548270},{284,5618445787},{286,5972426835},{288,6395981131},{290,6791769082},{292,7267283603},{294,7710782991},{296,8241719706},{298,8738236515},{300,9332065811},{302,9884604767},{304,10548218751},{306,11164542762},{308,11902015724},{310,12588998862},{312,13410330482},{314,14171344797},{316,15085164571},{318,15930619304},{320,16942010457},{322,17880232383},{324,19002055537},{326,20037346408},{328,21280571390},{330,22426253115},{332,23796620378},{334,25063227406},{336,26577912084},{338,27970034826},{340,29642262229},{342,31177474996},{344,33014225318},{346,34705254287},{348,36728266430},{350,38580626759},{352,40806395661},{354,42842199753},{356,45278616586},{358,47513679057},{360,50189039868},{362,52628839448},{364,55562506886},{366,58236270451},{368,61437700788},{370,64363670678},{372,67868149215},{374,71052718441},{376,74884539987},{378,78364039771},{380,82532990559},{382,86329680991},{384,90881152117},{386,95001297565},{388,99963147805},{390,104453597992},{392,109837310021},{394,114722988623},{396,120585261143},{398,125873325588},{400,132247999328}};
const std::unordered_map<size_t,size_t> num_IPR_fullerenes = {{20,0},{22,0},{24,0},{26,0},{28,0},{30,0},{32,0},{34,0},{36,0},{38,0},{40,0},{42,0},{44,0},{46,0},{48,0},{50,0},{52,0},{54,0},{56,0},{58,0},{60,1},{62,0},{64,0},{66,0},{68,0},{70,1},{72,1},{74,1},{76,2},{78,5},{80,7},{82,9},{84,24},{86,19},{88,35},{90,46},{92,86},{94,134},{96,187},{98,259},{100,450},{102,616},{104,823},{106,1233},{108,1799},{110,2355},{112,3342},{114,4468},{116,6063},{118,8148},{120,10774},{122,13977},{124,18769},{126,23589},{128,30683},{130,39393},{132,49878},{134,62372},{136,79362},{138,98541},{140,121354},{142,151201},{144,186611},{146,225245},{148,277930},{150,335569},{152,404667},{154,489646},{156,586264},{158,697720},{160,836497},{162,989495},{164,1170157},{166,1382953},{168,1628029},{170,1902265},{172,2234133},{174,2601868},{176,3024383},{178,3516365},{180,4071832},{182,4690880},{184,5424777},{186,6229550},{188,7144091},{190,8187581},{192,9364975},{194,10659863},{196,12163298},{198,13809901},{200,15655672},{202,17749388},{204,20070486},{206,22606939},{208,25536557},{210,28700677},{212,32230861},{214,36173081},{216,40536922},{218,45278722},{220,50651799},{222,56463948},{224,62887775},{226,69995887},{228,77831323},{230,86238206},{232,95758929},{234,105965373},{236,117166528},{238,129476607},{240,142960479},{242,157402781},{244,173577766},{246,190809628},{248,209715141},{250,230272559},{252,252745513},{254,276599787},{256,303235792},{258,331516984},{260,362302637},{262,395600325},{264,431894257},{266,470256444},{268,512858451},{270,557745670},{272,606668511},{274,659140287},{276,716217922},{278,776165188},{280,842498881},{282,912274540},{284,987874095},{286,1068507788},{288,1156161307},{290,1247686189},{292,1348832364},{294,1454359806},{296,1568768524},{298,1690214836},{300,1821766896},{302,1958581588},{304,2109271290},{306,2266138871},{308,2435848971},{310,2614544391},{312,2808510141},{314,3009120113},{316,3229731630},{318,3458148016},{320,3704939275},{322,3964153268},{324,4244706701},{326,4533465777},{328,4850870260},{330,5178120469},{332,5531727283},{334,5900369830},{336,6299880577},{338,6709574675},{340,7158963073},{342,7620446934},{344,8118481242},{346,8636262789},{348,9196920285},{350,9768511147},{352,10396040696},{354,11037658075},{356,11730538496},{358,12446446419},{360,13221751502},{362,14010515381},{364,14874753568},{366,15754940959},{368,16705334454},{370,17683643273},{372,18744292915},{374,19816289281},{376,20992425825},{378,22186413139},{380,23475079272},{382,24795898388},{384,26227197453},{386,27670862550},{388,29254036711},{390,30852950986},{392,32581366295},{394,34345173894},{396,36259212641},{398,38179777473},{400,40286153024}};
using namespace gpu_kernels;

void signal_callback_handler(int signum)
{
  LaunchCtx::clear_allocations();
  exit(signum);
}


int main(int ac, char **argv)
{
  signal(SIGINT, signal_callback_handler);
  if(ac<2){
    fprintf(stderr,"Syntax: %s <N:int> [output_dir] [IPR:0|1] [only_nontrivial:0|1]\n",argv[0]);
    return -1;
  }
  const size_t N                = strtol(argv[1],0,0);     // Argument 1: Number of vertices N

  string output_dir     = ac>=3? argv[2] : "output";    // Argument 2: directory to output files to
  int IPR               = ac>=4? strtol(argv[3],0,0):0; // Argument 3: Only generate IPR fullerenes?
  int only_nontrivial   = ac>=5? strtol(argv[4],0,0):0; // Argument 4: Only generate fullerenes with nontrivial symmetry group?
  int n_best_candidates = ac>=6? strtol(argv[5],0,0):100; // Argument 5: How many best fullerne candidates do you want to store? 

  // Make sure output directory exists
  mkdir(output_dir.c_str(),0777);
  int n_fullerenes = IPR > 0 ? num_IPR_fullerenes.find(N)->second : num_fullerenes.find(N)->second;
  int Nd = LaunchCtx::get_device_count();
  auto batch_size = isomerspace_forcefield::optimal_batch_size(N,0)*16;

  IsomerBatch B0s[Nd] = {IsomerBatch(N,batch_size,DEVICE_BUFFER,0), IsomerBatch(N, batch_size, DEVICE_BUFFER,1)};
  IsomerBatch B1s[Nd] = {IsomerBatch(N,batch_size,DEVICE_BUFFER,0), IsomerBatch(N, batch_size, DEVICE_BUFFER,1)};

  cuda_io::IsomerQueue Q0s[Nd] = {cuda_io::IsomerQueue(N,0), cuda_io::IsomerQueue(N,1)};
  cuda_io::IsomerQueue Q1s[Nd] = {cuda_io::IsomerQueue(N,0), cuda_io::IsomerQueue(N,1)};
  cuda_io::IsomerQueue Q2s[Nd] = {cuda_io::IsomerQueue(N,0), cuda_io::IsomerQueue(N,1)};

  for (int i = 0; i < Nd; i++) {Q0s[i].resize(batch_size*4); Q1s[i].resize(batch_size*4); Q2s[i].resize(batch_size*4);}

  LaunchCtx gen_ctxs[Nd] = {LaunchCtx(0),LaunchCtx(1)};
  LaunchCtx opt_ctxs[Nd] = {LaunchCtx(0),LaunchCtx(1)};

  BuckyGen::buckygen_queue BuckyQ = BuckyGen::start(N,IPR,only_nontrivial);  
  ProgressBar progress_bar = ProgressBar('#',30);
  
  
  int I=0;			// Global isomer number at start of batch
  int num_finished = 0,
      num_converged = 0,
      num_failed =0;
  Graph G;
  auto Nf = N/2 + 2;
  G.neighbours = neighbours_t(Nf, std::vector<node_t>(6));
  G.N = Nf;

  auto T0 = steady_clock::now();
  auto
    Tgen    = steady_clock::now()-T0,
    Tupdate = steady_clock::now()-T0,
    Tqueue  = steady_clock::now()-T0,
    Tdual   = steady_clock::now()-T0,    
    Ttutte  = steady_clock::now()-T0,
    TX0     = steady_clock::now()-T0,
    Tcopy   = steady_clock::now()-T0,
    Topt    = steady_clock::now()-T0,
    Tfile   = steady_clock::now()-T0,
    Toutq   = steady_clock::now()-T0,
    Tinq    = steady_clock::now()-T0,
    Tinit_geom = steady_clock::now()-T0;

  auto generate_isomers = [&](int M){
    if(I == n_fullerenes) return false;
    for (int i = 0; i < M; i++){
        if (I < n_fullerenes){
              auto ID = cuda_benchmark::random_isomer("isomerspace_samples/dual_layout_"+to_string(N)+"_seed_42", G);
              //BuckyGen::next_fullerene(BuckyQ, G);
              Q0s[I%Nd].insert(G,I, gen_ctxs[I%Nd], LaunchPolicy::ASYNC);
            I++;
        }
    }
    gen_ctxs[0].wait(); gen_ctxs[1].wait(); 
    return true;
  };

  auto opt_routine = [&](){
    for (int i = 0; i < Nd; i++){
      Q1s[i].refill_batch(B1s[i], opt_ctxs[i], LaunchPolicy::ASYNC);
      isomerspace_forcefield::optimise<PEDERSEN>(B1s[i], ceil(0.5*N), 5*N, opt_ctxs[i], LaunchPolicy::ASYNC);
      Q2s[i].push(B1s[i], opt_ctxs[i], LaunchPolicy::ASYNC);}
      for (int i = 0; i < Nd; i++){
        opt_ctxs[i].wait();
        num_finished += Q2s[i].get_size();
        Q2s[i].clear();
      }
  };

  auto loop_iters = 0;
  auto Tstart = steady_clock::now();
  auto n0 = 0;
  while(num_finished < n_fullerenes){
      auto T0 = steady_clock::now();
      for (int i = 0; i < Nd; i++){
          if(Q0s[i].get_size() > 0){
            Q0s[i].refill_batch(B0s[i], gen_ctxs[i], LaunchPolicy::ASYNC);
            isomerspace_dual::dualise(B0s[i], gen_ctxs[i], LaunchPolicy::ASYNC);
            isomerspace_tutte::tutte_layout(B0s[i], 10000000, gen_ctxs[i], LaunchPolicy::ASYNC);
            isomerspace_X0::zero_order_geometry(B0s[i], 4.0f, gen_ctxs[i], LaunchPolicy::ASYNC);
            Q1s[i].insert(B0s[i], gen_ctxs[i], LaunchPolicy::ASYNC);
          }
      }
      for(int j = 0; j < Nd; j++){
        gen_ctxs[j].wait();
      }
      auto T1 = steady_clock::now(); Tinit_geom += T1-T0;
      auto handle = std::async(std::launch::async, generate_isomers, 2*batch_size);
      auto T2 = steady_clock::now();
      while(Q1s[0].get_size() > B1s[0].capacity() && Q1s[1].get_size() > B1s[1].capacity()){
          opt_routine();
      }
      auto T3 = steady_clock::now(); Topt += T3-T2;
      handle.wait();
      auto T4 = steady_clock::now(); Tgen += T4-T3;
      while(I == n_fullerenes && num_finished < n_fullerenes && Q0s[0].get_size() == 0 && Q0s[1].get_size() == 0){
          opt_routine();
      }
      auto T5 = steady_clock::now(); Topt += T5-T4;
      if(loop_iters % 3 == 0){
        auto Titer = steady_clock::now() - Tstart;
        Tstart = steady_clock::now();
        auto Tff   = isomerspace_forcefield::time_spent()/Nd;
        Tqueue = Topt - Tff;
        Ttutte = isomerspace_tutte::time_spent()/Nd;
        TX0    = isomerspace_X0::time_spent()/Nd;
        Tdual  = isomerspace_dual::time_spent()/Nd;
        auto TOverhead = Tinit_geom - Tdual - Ttutte - TX0;
        progress_bar.update_progress((float)num_finished/(float)num_fullerenes.find(N)->second, "Pace: " + to_string((Titer/1us) / max((num_finished - n0),1)) + " us/isomer       ", {{"Gen          ", Tgen},{"Init Overhead", TOverhead},{"Opt          ", Topt},{"Dual         ", Tdual},{"Tutte        ", Ttutte},{"X0           ", TX0},{"FF Overhead  ", Tqueue}});
        n0 = num_finished;
      }
      loop_iters++;
  }

  
    
  
    //progress_bar.update_progress((float)num_finished/(float)num_fullerenes.find(N)->second);
    

  //cout << endl << "Finished: " << num_finished << "Failed: , " << num_failed << ", " << num_converged << endl;
  auto Ttot = steady_clock::now() - T0;

  
  
  auto TgeomOverhead = Tinit_geom - Tdual - Ttutte - TX0;
  auto Tsum = Tgen + Tupdate + Tdual + Ttutte + TX0 + Tcopy + Topt + Tfile + Toutq + Tinq + TgeomOverhead;
  //std::cout << std::endl;

  cout << "\n\n\n\n\n\n\n\n";
  cout << "Time spent on non:\n"
    "\tTotal Time                     = " << (Ttot/1ms)       << " ms\n"
    "\tTime Unaccounted For           = " << (Ttot-Tsum)/1ms  << " ms\n"
    "\tGeometry Overhead              = " << (TgeomOverhead)/1ms << " ms\n"
    "\tDevice queue                   = " << (Tqueue)/1ms     << " ms\n"
    "\tGenerating graphs              = " << (Tgen/1ms)       << " ms\n"
    "\tDualizing                      = " << (Tdual/1ms)      << " ms\n"
    "\tTutte embedding                = " << (Ttutte/1ms)     << " ms\n"
    "\tInitial geometry               = " << (TX0/1ms)        << " ms\n"
    "\tFF Optimization                = " << (Topt/1ms)       << " ms\n";
  //

  return 0;
}