#include <sys/stat.h>
#include <limits.h>
#include <chrono>
#include <iostream>
#include <iomanip>
#include <thread>
#include <future>
#include "fullerenes/buckygen-wrapper.hh"
#include "fullerenes/triangulation.hh"
#include "fullerenes/polyhedron.hh"
#include "fullerenes/gpu/isomerspace_X0.hh"
#include "numeric"

using namespace std;
using namespace std::chrono;

#define TEST_SAMPLES 2000

bool is_equal(const vector<coord3d>& a, const vector<coord3d> &b){
    bool result = true;
    double epsilon = 1e-4;
    result &= (a.size() == b.size());
    for (size_t i = 0; i < a.size(); i++)
    {
        result &= fabs(a[i][0] - b[i][0]) < epsilon;
        result &= fabs(a[i][1] - b[i][1]) < epsilon;
        result &= fabs(a[i][2] - b[i][2]) < epsilon;
        if(!result) {
            cout << a[i] << " vs " << b[i] << std::endl;
            break;
        };
    }
    return result;
}

int main(int ac, char **argv)
{
    if(ac<2){
    fprintf(stderr,"Syntax: %s <N:int> [output_dir] [IPR:0|1] [only_nontrivial:0|1]\n",argv[0]);
    return -1;
    }
    int N                = strtol(argv[1],0,0);     // Argument 1: Number of vertices N

    string output_dir     = ac>=3? argv[2] : "output";    // Argument 2: directory to output files to
    int IPR               = ac>=4? strtol(argv[3],0,0):0; // Argument 3: Only generate IPR fullerenes?
    int only_nontrivial   = ac>=5? strtol(argv[4],0,0):0; // Argument 4: Only generate fullerenes with nontrivial symmetry group?
    int n_best_candidates = ac>=6? strtol(argv[5],0,0):100; // Argument 5: How many best fullerne candidates do you want to store? 

    IsomerspaceX0 X0_kernel   = IsomerspaceX0(N);
    FullereneDual dualG;
    BuckyGen::buckygen_queue Q = BuckyGen::start(N,IPR,only_nontrivial);  
    size_t I = 0;
    bool more_to_generate = true;
    queue<Polyhedron> fullerene_graphs;


    for (I; I < TEST_SAMPLES && more_to_generate; I++)
    {
        more_to_generate &= BuckyGen::next_fullerene(Q,dualG);
        if (!more_to_generate){break;}
        dualG.update();   		        // Update triangles
        FullereneGraph   G = dualG.dual_graph();  // Construct fullerene graph
        G.layout2d = G.tutte_layout();
        X0_kernel.insert_isomer(G,I);
        vector<coord3d> X0 = G.zero_order_geometry();
        fullerene_graphs.push(Polyhedron(G,X0));
    }
    X0_kernel.update_batch();
    while (X0_kernel.get_batch_size()!=0 || !X0_kernel.insert_queue.empty())
    {
        X0_kernel.zero_order_geometry();
        X0_kernel.check_batch();
        X0_kernel.update_batch();
    }


    while (!X0_kernel.output_queue.empty())
    {   
        if(!is_equal(fullerene_graphs.front().points, X0_kernel.output_queue.front().second.points)){
            cout << "Isomer " << X0_kernel.output_queue.front().first << " Failed" << std::endl;
            //cout << fullerene_graphs.front().points << std::endl;
            //cout << X0_kernel.output_queue.front().second.points << std::endl;
            //cout << fullerene_graphs.front().multiple_source_shortest_paths(fullerene_graphs.front().find_outer_face()) << std::endl;
            //cout << fullerene_graphs.front().spherical_projection() << std::endl;
            assert(false);
        }
        cout << "Isomer: " << X0_kernel.output_queue.front().first << " Succeeded" << std::endl;
        
        
        X0_kernel.output_queue.pop(); fullerene_graphs.pop();
    }

}