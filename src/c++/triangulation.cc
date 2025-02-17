#include <algorithm>
#include "fullerenes/triangulation.hh"
#include "fullerenes/unfold.hh"
#include "fullerenes/buckygen-wrapper.hh"

pair<node_t,node_t> Triangulation::adjacent_tris(const dedge_t& e) const
{
  node_t u  = e.first, v = e.second;
  node_t w1=-1, w2=-1;

  if(is_oriented) {
    w1 = next_on_face(u,v), w2 = next_on_face(v,u);
  } else {
    vector<node_t> ws;
    auto is_in = [](const vector<node_t> &v, node_t x)
      { return find(v.begin(),v.end(),x) != v.end(); };

    for(node_t w: neighbours[u])
      if(is_in(neighbours[w],u) && is_in(neighbours[w],v)) ws.push_back(w);

    if(ws.size() != 2){
      cerr <<  "Error in triangulation: Edge " << edge_t{u,v} << " is adjacent to "<<ws.size()<<" != 2 vertices.\n"
           <<  "ws = " << ws << "+1;\n"
           <<  "neighbours = " << neighbours << "+1;\n";
      abort();
    }
    w1 = ws[0], w2 = ws[1];
  }

  return make_pair(w1,w2);
}

vector<tri_t> Triangulation::compute_faces() const
// Does not assume graph is oriented
// Produces oriented triangles
// TODO: Fails in the presence of separating triangles. Make sure spiral-windup produces oriented graph.
{
  if(is_oriented) return compute_faces_oriented();

  unordered_set<tri_t> triangle_set;

  for(node_t u=0;u<N;u++)
    for(node_t v: neighbours[u]){
      pair<node_t,node_t> ws(adjacent_tris({u,v}));

      triangle_set.insert(tri_t{u,v,ws.first }.sorted());
      triangle_set.insert(tri_t{u,v,ws.second}.sorted());
    }


  vector<tri_t> triangles(triangle_set.begin(),triangle_set.end());
  orient_triangulation(triangles);

  return triangles;
}



void Triangulation::orient_neighbours()
{
  map<dedge_t,node_t> next;

  for(int i=0;i<triangles.size();i++){
    const tri_t& t(triangles[i]);
    next[dedge_t(t[0],t[1])] = t[2];
    next[dedge_t(t[1],t[2])] = t[0];
    next[dedge_t(t[2],t[0])] = t[1];
  }
  for(node_t u=0;u<N;u++){
    int d = neighbours[u].size();

    node_t v = neighbours[u][0];
    for(int i=1;i<d;i++){
      node_t w = next[dedge_t(u,v)];
      neighbours[u][i] = w;
      v = w;
    }
  }
  is_oriented = true;
}

vector<tri_t> Triangulation::compute_faces_oriented() const
{
  //Why is this information stored in a hashmap seems like std::vector is perfectly suitable here.
  unordered_map<dedge_t,bool> dedge_done(2*count_edges());
  vector<tri_t> triangles;
  triangles.reserve(2*(N-2));        // Most common case is cubic dual, but we no longer know it for sure.

  for(node_t u=0;u<N;u++){
    const vector<node_t>& nu(neighbours[u]);
    for(int i=0;i<nu.size();i++){
      const node_t& v(nu[i]);    // Process directed edge u->v
      const dedge_t uv(u,v);

      if(!dedge_done[uv]){
        node_t w = next_on_face(u,v);
	if(w==-1){
	  printf("next_on_face(%d,%d) = prev(%d,%d) = -1\n",u,v,v,u);
	  printf("\tneibhours[%d] = ",u); cout << neighbours[u] << endl;
	  printf("\tneibhours[%d] = ",v); cout << neighbours[v] << endl;	  
	  assert(w != -1);
	}
        //Is This Condition necessary? 
        //since every directed edge is only part of 1 triangle it ought to be sufficient
        //to check dedge_done[{u,v}].
        if(!dedge_done[{v,w}] && !dedge_done[{w,u}]){ 

          triangles.push_back(tri_t(u,v,w));

          dedge_done[{u,v}] = true;
          dedge_done[{v,w}] = true;
          dedge_done[{w,u}] = true;
        }
      }
    }
  }
  return triangles;
}

/*
// Build precalculated lookup tables
//   1. cubic arc -> dual arc   (transverse arc a,i -> u,j)     : Nx3     node_t,uint8_t 
//   2. dual arc  -> cubic arc  (transverse arc u,j -> a,i)     : NfxFmax node_t,uint8_t 
//
// TODO: * Resolve function overlap with cubic_faces() and translate_arcs. This produces faster data structures.
//       * Gather precalculated tables into one data structure (separate from graph itself)
void Triangulation::compute_lookup_tables(const PlanarGraph&            cubic_graph,
					  vector<pair<node_t,uint8_t>>& carc_to_darc,
					  vector<pair<node_t,uint8_t>>& darc_to_carc,
					  vector<uint8_t>&              degrees,
					  int Fmax = 6
					  ) const
{
  size_t Nf = N;		// To remind ourselves that this is the number of faces
  size_t Nc = 2*(N-2);		// This function assumes the triangulation is the dual of a cubic graph 

  assert(triangles.size() == Nc); // Make sure triangles array is initialized before calling
  assert(is_oriented());	  // We don't bother with non-oriented surfaces

  if(Fmax<1) Fmax = max_degree(); // Calculate fmax
  
  carc_to_darc.resize(Nc*3);
  darc_to_carc.resize(Nf*Fmax);
  darc_to_cnode.resize(Nf*Fmax);
  degrees.resize(Nf);
  
  IDCounter tid(triangles);	  // Look up cubic node id by triangle  
  
  for(node_t u=0;u<Nf;u++){
    const vector<node_t>& nu(neighbours[u]);
    degrees[u] = nu.size();
    
    for(int j=0;j<nu.size();j++){
      const node_t& v  = nu[j];    // Process triangulation arc f->g
        node_t wa = next_on_face(u,v); // Third triangle node in CW direction
        node_t wb = next_on_face(v,u); // Third triangle node in CCW direction

	// If either hl or hr fails, triangulation data is corrupted.
	if((wa<0) || (wb<0)){
	  printf("next_on_face(%d,%d) = prev(%d,%d) = -1\n",u,v,v,u);
	  printf("next_on_face(%d,%d) = prev(%d,%d) = -1\n",v,u,u,v);
	  printf("\tneibhours[%d] = ",u); cout << neighbours[u] << endl;
	  printf("\tneibhours[%d] = ",v); cout << neighbours[v] << endl;	  
	  assert((wa<0) || (wb<0));
	}

	tri_t t1 = {u,g,CW}, t2 = {g,u,CCW};

	node_t a = tid(t1.sorted()), b = tid(t2.sorted);
	
	darc_to_cnode[u*Fmax + j] = u; // Triangle/cubic node defined by {u,g,CW}

	// The transverse arc to u->g in the cubic graph is u->v.
	// Now we want to find the index i such that v = cubic_graph.neighbours[u][i].
	int i = cubic_graph.dedge_ix({u,v});
	darc_to_carc[u*Fmax + j] = {a,i};
	carc_to_darc[a*3    + i] = {u,j};
      }
    }
  }
}
*/

// TODO: dedge_t -> arc_t everywhere
//       dedge   -> arc   everywhere
//       cubic nodes: a,b,c,...
//       dual  nodes: u,v,w,...
unordered_map<dedge_t,dedge_t> Triangulation::arc_translation() const
{
  // TODO: Common metadata, calculate once
  IDCounter<tri_t> tri_numbers;
  unordered_map<dedge_t,dedge_t> arc_translate(triangles.size()*3);

  if(triangles.size() != (N-2)*2){
    cout << "triangles = " << triangles << endl;
    assert(triangles.size() == (N-2)*2);
  }
  
  // Dual arcs
  for(node_t u=0;u<N;u++)
    for(node_t v: neighbours[u]){
      node_t wa = next_on_face(u,v), wb = next_on_face(v,u);
      tri_t  Ta = {u,v,wa}, Tb = {v,u,wb};
      node_t  a = tri_numbers(Ta.sorted()), b = tri_numbers(Tb.sorted());

      arc_translate[{u,v}] = {a,b};
    }
  return arc_translate;
}


// TODO: Factor out tri_numbers to do only once?
PlanarGraph Triangulation::dual_graph() const
{
  IDCounter<tri_t> tri_numbers;

  //assert(triangles.size() == (N-2)*2);
  if(triangles.size() != (N-2)*2){
    cout << "triangles = " << triangles << endl;
    assert(triangles.size() == (N-2)*2);
  }
  for(int i=0;i<triangles.size();i++) tri_numbers.insert(triangles[i].sorted());

  neighbours_t A(triangles.size(),vector<node_t>(3));

  for(node_t U=0;U<triangles.size();U++){
    const tri_t& t(triangles[U]);

    for(int i=0;i<3;i++){
      const node_t& u(t[i]), v(t[(i+1)%3]);
      node_t w(prev(u,v)); // TODO: CCW for buckygen -- will this give problems elsewhere?
      // TODO: Should this not be prev(v,u)? Or next(v,u)?

      A[U][i] = tri_numbers(tri_t(u,v,w).sorted());

      if(A[U][i] < 0){
          cerr << "Triangle " << tri_t(u,v,w).sorted() << " (opposite " << t << ") not found!\n";
          abort();
      }
    }
  }
  //  cerr << "A = " << A << endl;
  Graph G(A,true);
  // G must be consistently oriented, or something went wrong.
  // assert(G.is_consistently_oriented());
  return PlanarGraph(G);
};


vector<face_t> Triangulation::cubic_faces() const
{
  vector<face_t> dfaces(N);

  IDCounter<tri_t> tri_numbers;
  for(int i=0;i<triangles.size();i++) tri_numbers.insert(triangles[i].sorted());

  for(node_t u=0;u<N;u++){
    const vector<node_t> &nu(neighbours[u]);
    face_t f(nu.size());
    for(int i=0;i<nu.size();i++){
      node_t v=nu[i], w = nu[(i+1)%nu.size()]; // next_on_face(u,v);
      f[i] = tri_numbers(tri_t(u,v,w).sorted());
    }
    dfaces[u] = f;
  }
  return dfaces;
}


// Takes full spiral string, e.g. 566764366348665
// where the degrees are 3 or larger
// each neighbour list is oriented CCW (and the boundary is CW)
// the indices of the jumps start counting at 0
// best-effort means, additional trailing vertices in the spiral string are caught/discarded, implying that wrong spirals may not be caught
Triangulation::Triangulation(const vector<int>& spiral_string, const jumplist_t& j, const bool best_effort):
  PlanarGraph(spiral_string.size())
{
  jumplist_t jumps = j; // we need a local copy to remove elements
  // cerr << "best-effort: " << best_effort << endl;
  // cerr << "S: " << spiral_string << endl;
  // cerr << "J: " << j << endl;
  // cerr << "N: " << N << endl;

  // open_valencies is a list with one entry per node that has been added to
  // the spiral but is not fully saturated yet.  The entry contains the number
  // of the node and the number of open valencies
  list<pair<node_t,int> > open_valencies;

  // set up first two nodes
  open_valencies.push_back(make_pair(0,spiral_string[0]-1));
  open_valencies.push_back(make_pair(1,spiral_string[1]-1));
  insert_edge({0,1});

  // iterate over atoms
  // k=0, k=1 have been done already
  int N_final;
  if(best_effort) N_final = N;
  else N_final = N-1; // omit the last one because it requires special treatment
  for (int k=2; k<N_final; ++k){
    int pre_used_valencies=0;
    // cerr << "step " << k << "/" << N-1 << endl;

    // should a cyclic shift be applied before adding the next atom?
    if(jumps.size() != 0 && k == jumps.front().first){
      // perform cyclic shift on open_valencies
      for(int i = jumps.front().second; i>0; --i){ // 0 is no jump
        open_valencies.push_back(open_valencies.front());
        open_valencies.pop_front();
      }
      // jumps.pop_front();
      jumps.erase(jumps.begin());
    }

    //       How-to: insert_edge({u,v}, succ_uv,succ_vu)
    //               inserts v in u's neighbour list right *before* succ_uv, and
    //               inserts u in v's neighbour list right *before* succ_vu (-1 means at end).
    // connect k and <first>
    auto connect_forward = [&](const node_t suc_vu){
      const node_t suc_uv = open_valencies.back().first; // last node in open_valencies
      insert_edge({k, open_valencies.front().first}, suc_uv, suc_vu);
      --open_valencies.front().second;
      ++pre_used_valencies;
      // cerr << "cf" << endl;
      // cerr << open_valencies << endl;
    };

    // connect k and <last>
    auto connect_backward = [&](const node_t suc_uv){
      const node_t suc_vu = std::prev(open_valencies.end(), 2)->first; // second to last node in open_valencies
      insert_edge({k,open_valencies.back().first}, suc_uv, suc_vu);
      --open_valencies.back().second;
      ++pre_used_valencies;
      // cerr << "cb" << endl;
      // cerr << open_valencies << endl;
    };

    connect_forward(open_valencies.back().first); // suc_uv is not a neighbour yet, but appending at the end of the list is fine
    connect_backward(open_valencies.front().first); // suc_vu is not a neighbour yet, but appending at the end of the list is fine

    // do the remaining connect forwards
    while(open_valencies.front().second==0){
      if(best_effort && open_valencies.size()==2 && open_valencies.back().second==0){
        // cerr << "leaving from rem cf" << endl;
        break; // We're done adding vertices
      }
      const node_t suc_vu = open_valencies.front().first;
      open_valencies.pop_front();
      connect_forward(suc_vu);
    }

    // do the remaining connect backwards
    while(open_valencies.back().second==0){
      if(best_effort && open_valencies.size()==2 && open_valencies.front().second==0){
        // cerr << "leaving from rem cb" << endl;
        break; // We're done adding vertices
      }
      const node_t suc_uv = open_valencies.back().first;
      open_valencies.pop_back();
      connect_backward(suc_uv);
    }

    // add node to spiral
    open_valencies.push_back(make_pair(k,spiral_string[k]-pre_used_valencies));

    if(spiral_string[k] - pre_used_valencies < 1){//the current atom is saturated (which may only happen for the last one)
      if(best_effort){
        if(spiral_string[k] != pre_used_valencies){
          cerr << spiral_string[k] << ", " << pre_used_valencies << endl;
          cerr << "something's b0rked" << endl;
          abort();
        }
        for(auto ov: open_valencies){
          if(ov.second != 0){
            cerr << ov << endl;
            cerr << "something's b0rked" << endl;
            abort();
          }
        }
        break; // We're done adding vertices
      }
      cerr << "Cage closed but faces left (or otherwise invalid spiral)" << endl;
      abort();
    }
  } // iterate over atoms

  // make sure we left the spiral in a sane state
  // open_valencies must be either spiral.back() times '1' at this stage
  if(!best_effort){
    if(open_valencies.size() != spiral_string.back()){
      cerr << "Cage not closed but no faces left (or otherwise invalid spiral), wrong number of faces left" << endl;
      cerr << "Incomplete triangulation = " << *this << "\n";
      abort();
    }
    for(list<pair<node_t,int> >::iterator it = open_valencies.begin(); it!=open_valencies.end(); ++it){
      if(it->second!=1){
        cerr << "Cage not closed but no faces left (or otherwise invalid spiral), more than one valency left for at least one face" << endl;
      abort();
      }
    }

    // add remaining edges, we don't care about the valency list at this stage
    // get a vector of nodes of the final hole, for easier orientation
    vector<node_t> last_nodes;
    for(auto n: open_valencies) last_nodes.push_back(n.first);
    for(int i=0; i<spiral_string.back(); ++i){
      const node_t suc_uv=last_nodes[(i+1)%last_nodes.size()];
      const node_t suc_vu=last_nodes[(i-1+last_nodes.size())%last_nodes.size()];
      insert_edge({N-1, last_nodes[i]}, suc_uv, suc_vu); // suc_uv is not a neighbour (except for the last edge), but appending at the end of the list is fine
    }
  }else{
    remove_isolated_vertices();
  }

  is_oriented = true;
  update(is_oriented);
}


Triangulation Triangulation::GCtransform(const unsigned k, const unsigned l) const
{
  if(l==0) return halma_transform(k-1);

  Unfolding u(*this);
  Unfolding gcu(u*Eisenstein(k,l));
  Folding gcf(gcu);
  Triangulation t(gcf.fold());
   return t;
}

// TODO: Get rid of maps, edge-sets, etc. Simplify and make faster.
//       Keep orientation.
Triangulation Triangulation::halma_transform(int m) const {
  if(m<0) return Triangulation(*this);

  map<edge_t,vector<node_t> > edge_nodes;

  set<edge_t> edgeset_new;
  node_t v_new = N;

  // Create n new vertices for each edge
  vector<edge_t> dual_edges = undirected_edges();

  for(const auto &e: dual_edges){
    vector<node_t>& nodes(edge_nodes[e]);
    for(unsigned int i=0;i<m;i++) nodes.push_back(v_new++);
  }

  // For every triangle in the dual, we create and connect a halma-type grid
  for(size_t i=0;i<triangles.size();i++){
    map<edge_t,node_t> grid;
    const face_t& T(triangles[i]);
    edge_t e0(T[0],T[1]),e1(T[1],T[2]),e2(T[2],T[0]);
    const vector<node_t>& ns0(edge_nodes[e0]), ns1(edge_nodes[e1]), ns2(edge_nodes[e2]);
    // Insert original vertices
    grid[edge_t(0,0)]     = T[0];
    grid[edge_t(m+1,0)]   = T[1];
    grid[edge_t(m+1,m+1)] = T[2];
    // Insert new edge vertices
    for(size_t j=0;j<m;j++){
      grid[edge_t(0,j+1)]   = ns0[j];
      grid[edge_t(j+1,m+1)] = ns1[j];
      grid[edge_t(j+1,j+1)] = ns2[j];
    }
    // Create and insert inner vertices
    for(int j=1;j<m;j++)
      for(int k=j+1;k<=m;k++)
        grid[edge_t(j,k)] = v_new++;

    // Connect the vertices in the grid
    for(int j=0;j<=m;j++)
      for(int k=j+1;k<=m+1;k++){
        node_t v(grid[edge_t(j,k)]), down(grid[edge_t(j+1,k)]),
          left(grid[edge_t(j,k-1)]);

        edgeset_new.insert(edge_t(v,down));
        edgeset_new.insert(edge_t(v,left));
        edgeset_new.insert(edge_t(left,down));
      }
  }

  return Triangulation(Graph(edgeset_new),false);
}


// *********************************************************************
//                 SPIRAL STUFF
// *********************************************************************


bool Triangulation::get_spiral(const node_t f1, const node_t f2, const node_t f3,
                               vector<int> &spiral, jumplist_t& jumps, vector<node_t>& permutation,
                               const bool general) const {
  return get_spiral_implementation(f1,f2,f3,spiral,jumps,permutation,general);
}

void remove_node(const node_t u, Graph &remaining_graph){
  remaining_graph.N--;
  vector<node_t>& nu(remaining_graph.neighbours[u]);

  //remove u from all neighbour lists and erase all neighbours from the u-list
  for(int i=0;i<nu.size();i++){        // O(1) since neighbour count is bounded by max degree
    const node_t& v = nu[i];
    vector<node_t>& nv(remaining_graph.neighbours[v]);

    for(int j=0;j<nv.size();j++){ // O(1) since neighbour count is bounded by max degree
      if(nv[j] == u){
        nv.erase(nv.begin()+j);        // Previous method destroyed orientation
        break;
      }
    }
  }
  nu.clear();
}

// jumps start to count at 0
// perform a general spiral search and return the spiral and the jump positions + their length
// TODO: Add jumps to S0.
// TODO: Make GSpiral data type
// TODO: if S0 is given, no need to test for connectedness at every step - jump positions are predetermined.
//       Pass J0 and jump according to J0
// TODO: return GSpiral
bool Triangulation::get_spiral_implementation(const node_t f1, const node_t f2, const node_t f3, vector<int> &spiral,
                                              jumplist_t& jumps, vector<node_t> &permutation,
                                              const bool general, const vector<int>& S0, const jumplist_t &J0) const {
  // TODO: If S0 and J0 are specified, we are finding symmetry group permutations and should follow (S0,J0).
  //       Currently J0 is ignored, but J0 should control jumps in this case.

  //this routine expects empty containers pentagon_indices and jumps.  we make sure they *are* empty
  spiral.clear();
  jumps.clear();
  permutation.clear();

  // TODO: Static allocation everywhere. Simplify function.
  permutation.resize(N);
  spiral.resize(N);

  PlanarGraph remaining_graph(Graph(neighbours,true)); // remaining_graph consists of all nodes that haven't been added to the result yet
  vector<int> valencies(N, 0); // valencies is the N-tuple consisting of the valencies for each node
  int last_vertex=-1; // we'd like to know the number of the last vertex

  // open_valencies is a list with one entry per node that has been added to
  // the spiral but is not fully saturated yet.  The entry contains the number
  // of the node and the number of open valencies
  list<pair<node_t,int> > open_valencies;

  int pre_used_valencies=0; // number of valencies removed from the last vertex *before* it is added to the spiral
  int jump_state=0; // the number of cyclic shifts of length 1 in the current series.

  //init of the valency-list and the set of nodes in the remaining graph
  for(node_t u=0; u<remaining_graph.N; u++){
    valencies[u] = remaining_graph.neighbours[u].size();
  }

  bool
    CW  = prev(f1,f2) == f3,
    CCW = next(f1,f2) == f3;

  // check if starting nodes are a valid spiral start.
  // TODO: Input f1,f2 and bool CW instead to only allow valid spiral starts.
    if(!(CW || CCW)){
    // TODO: Set a global verbosity level; Usually we don't want to look at all this stuff.
    // cerr << "The requested nodes are not connected." << endl;
    return false;
  }

  auto connect_forward = [&](){
    --open_valencies.front().second;
    ++pre_used_valencies;
  };
  auto connect_backward = [&](){
    --open_valencies.back().second;
    ++pre_used_valencies;
  };

  // add the first three (defining) nodes
  // first node
  spiral[0] = valencies[f1];
  permutation[0] = f1;
  remove_node(f1, remaining_graph);
  open_valencies.push_back(make_pair(f1,valencies[f1]));

  // second node
  spiral[1] = valencies[f2];
  permutation[1] = f2;
  remove_node(f2, remaining_graph);
  connect_backward();
  open_valencies.push_back(make_pair(f2,valencies[f2]-1));

  // third node
  spiral[2] = valencies[f3];
  permutation[2] = f3;
  remove_node(f3, remaining_graph);
  connect_backward();
  connect_forward();
  open_valencies.push_back(make_pair(f3,valencies[f3]-2));

  if(!S0.empty() && (spiral[0] != S0[0] || spiral[1] != S0[1] || spiral[2] != S0[2])) return false;

  // iterate over all nodes (of the initial graph) but not by their respective number
  // starting at 3 because we added 3 already
  for(int i=3; i<N-1; ++i){
    pre_used_valencies=0;
    // find *the* node in *this (not the remaining_graph), that is connected to open_valencies.back() und open_valencies.front()
    // we can't search in the remaining_graph because there are some edges deleted already
    node_t u = open_valencies.back().first, w = open_valencies.front().first;
    node_t v = CCW? prev(u,w) : next(u,w); // TODO: What is the rationale here?
    //    cout << "u->v: " << u << " -> " << v << endl;
    if(v == -1) return false; // non-general spiral failed

    if(general){
      bool is_cut_vertex = remaining_graph.is_cut_vertex(v);
      // cout << "connected? " << !is_cut_vertex << endl;

      if(is_cut_vertex){//further cyclic rotation required
        //perform cyclic shift on open_valencies
        open_valencies.push_back(open_valencies.front());
        open_valencies.pop_front();
        //        cout << "open valencies = " << open_valencies << endl;
        //there was no atom added, so 'i' must not be incremented
        --i;
        ++jump_state;
        continue;
      } else if(jump_state!=0){//end of cyclic rotation
        //        cout << "//end of cyclic rotation\n";
        jumps.push_back(make_pair(i,jump_state));
        jump_state=0;
      }
    }

    // record the number of the last vertex, as the neighbour of the second to last one
    // this only needs to be done when remaining_graph.N==2, but writing this value each cycle should be cheaper than testing something each cycle
    // if(remaining_graph.N==2)
    last_vertex=remaining_graph.neighbours[v][0];

    //remove all edges of which *j is part from the remaining graph
    remove_node(v, remaining_graph);

    connect_forward();
    while (open_valencies.front().second==0){
      open_valencies.pop_front();
      connect_forward();
    }

    connect_backward();
    while (open_valencies.back().second==0){
      open_valencies.pop_back();
      connect_backward();
    }

    spiral[i] = valencies[v];
    permutation[i] = v;
    if(!S0.empty() && spiral[i] != S0[i]) return false;

    if(valencies[v]-pre_used_valencies < 1) return false;
    open_valencies.push_back(make_pair(v,valencies[v]-pre_used_valencies));
    if(open_valencies.back().second < 1) return false; //i.e., the spiral is stuck. This can only happen if the spiral missed a jump
  }

  // make sure we left the loop in a sane state
  // this probably requires some proper error handling: throw and catch and so on ...
  if(remaining_graph.N != 1){
    // cerr << "more than one node left ... exiting." << endl;
    return false;
  }
  const int last_valency = valencies[last_vertex];
  if(open_valencies.size() != last_valency){
    // cerr << "wrong number of nodes with open valencies: " << open_valencies.size() << " ... exiting." << endl;
    return false;
  }
  for(list<pair<node_t,int> >::const_iterator it=open_valencies.begin(); it!=open_valencies.end(); ++it){
    if(it->second != 1){
      // cerr << "number of open valencies is not 1 (but it should be) ... exiting." << endl;
      return false;
    }
  }

  spiral[N-1] = last_valency;
  permutation[N-1] = last_vertex;
  return true;
}

void Triangulation::get_all_spirals(vector<vector<int>>& spirals, vector<jumplist_t>& jumps,
                     vector<vector<node_t>>& permutations,
                     const bool only_special, const bool general) const
{
  vector<node_t> node_starts;

  vector<int> spiral(N);
  jumplist_t  jump;
  vector<node_t> permutation;

  // Prefer special nodes. TODO: Automatic renumber in order of degrees.
  for(node_t u=0;u<N;u++) if(neighbours[u].size() != 6) node_starts.push_back(u);
  for(node_t u=0;u<N;u++)
    if(!only_special && neighbours[u].size() == 6) node_starts.push_back(u);

  for(int i=0; i<node_starts.size(); i++){ // Looks like O(N^3), is O(N)
    const node_t u=node_starts[i];
    const vector<node_t>& nu(neighbours[u]);

    for(int j=0;j<nu.size();j++){
      node_t v=nu[j], w[2];
      w[0] = prev(u,v);
      w[1] = next(u,v);

      for(int k=0;k<2;k++){
        if(get_spiral(u,v,w[k],spiral,jump,permutation,general)){
          spirals.push_back(spiral);
          jumps.push_back(jump);
          permutations.push_back(permutation);
        }
      }
    }
  }
}


bool Triangulation::get_spiral(vector<int>& spiral, jumplist_t& jumps, const bool only_rarest_special, const bool general) const
{
  vector<vector<node_t>> permutations;
  bool success = get_spiral(spiral,jumps,permutations,only_rarest_special,general);
  return success;
}

general_spiral Triangulation::get_general_spiral(const bool only_rarest_special) const
{
  general_spiral gs;
  bool success = get_spiral(gs.spiral,gs.jumps,only_rarest_special,true);
  assert(success); 		// General spirals should *always* succeed
  return gs;
}

// perform the canonical general spiral search and the spiral and the jump positions + their length
// special_only is a switch to search for spirals starting at non-hexagons only
bool Triangulation::get_spiral(vector<int> &spiral, jumplist_t &jumps, vector<vector<node_t>>& permutations, const bool only_rarest_special, const bool general) const
{
  permutations.clear();
  vector<node_t> node_starts;

  if(only_rarest_special){
    int max_face_size=0;
    for(node_t u=0;u<N;u++) if(neighbours[u].size()>max_face_size) max_face_size=neighbours[u].size();
    //cerr << max_face_size << endl;

    vector<int> face_counts(max_face_size,0);
    for(node_t u=0;u<N;u++) face_counts[neighbours[u].size()-1]++;
    //cerr << face_counts << endl;

    // Find rarest non-hexagon face size
    pair<int,int> fewest_face(0,INT_MAX); // size, number
    for(int i=0; i<max_face_size; i++){
      //cerr << face_counts[i] << fewest_face << endl;
      if((i+1 != 6) && face_counts[i]>0 && face_counts[i]<fewest_face.second){
        fewest_face.first=i+1;
        fewest_face.second=face_counts[i];
      }
    }
    //cerr << fewest_face << endl;

    for(node_t u=0;u<N;u++)
      if(neighbours[u].size() == fewest_face.first) node_starts.push_back(u);
    //cerr << node_starts << endl;
  }
  else 
    for(node_t u=0;u<N;u++) node_starts.push_back(u);

  vector<int> spiral_tmp(N),permutation_tmp(N);
  jumplist_t jumps_tmp;
  spiral = vector<int>(1,INT_MAX); // so it gets overwritten
  jumps = jumplist_t(100,make_pair(0,0)); // so it gets overwritten

  //cerr << "spiralstarts = " << node_starts << ";\n";
  
  // TODO: Write this way neater.
  bool found_one = false;
  for(int i=0; i<node_starts.size(); i++){
    const node_t u=node_starts[i];

    // Get regular spiral if it exists
    for(node_t v: neighbours[u]){
      node_t w[2];
      w[0] = prev(v,u);
      w[1] = next(v,u);

      for(int k=0;k<2;k++){        // Looks like O(N^3), is O(N) (or O(1) if only_rarest_special is set)
        // NB: general -> false to only do general if all originals fail
        //     That's much faster on average, but gives bigger variation in times.
        if(!get_spiral(u,v,w[k],spiral_tmp,jumps_tmp,permutation_tmp,false))
          continue;

        found_one = true;

        // store the shortest / lexicographically smallest (general) spiral
        if(general_spiral{jumps_tmp,spiral_tmp} < general_spiral{jumps,spiral}){
          jumps       = jumps_tmp;
          spiral      = spiral_tmp;
          permutations.clear();
        } 
        permutations.push_back(permutation_tmp);
      }
    }
  }

  // If no regular spiral exists, go for the smallest general one
  if(general && !found_one){
    for(int i=0; i<node_starts.size(); i++){
      const node_t u=node_starts[i];

      // Get regular spiral if it exists
      for(node_t v: neighbours[u]){
          node_t w[2];
          w[0] = prev(v,u);
          w[1] = next(v,u);

        for(int k=0;k<2;k++){        // Looks like O(N^3), is O(N) (or O(1) if only_rarest_special is set)
          if(!get_spiral(u,v,w[k],spiral_tmp,jumps_tmp,permutation_tmp,true)){
            cerr << "General spiral failed -- this should never happen!\n";
            abort();
          }
          found_one = true;

          // store the shortest / lexicographically smallest (general) spiral
          if(general_spiral{jumps_tmp,spiral_tmp} < general_spiral{jumps,spiral}){
            //    cerr << general_spiral{jumps_tmp,spiral_tmp} << " < " << general_spiral{jumps,spiral} << "\n";
            jumps       = jumps_tmp;
            spiral      = spiral_tmp;
            permutations.clear();
          } else {
           //    cerr << general_spiral{jumps_tmp,spiral_tmp} << " >= " << general_spiral{jumps,spiral} << "\n";    
          }
          permutations.push_back(permutation_tmp);
        }
      }
    }
  }
  
  if(spiral.size()!=N) return false;

  return true;
}


void Triangulation::symmetry_information(int N_generators, Graph& coxeter_diagram, vector<int>& coxeter_labels) const
{
  vector<vector<int>> spirals;
  vector<vector<node_t>> permutations;
  vector<jumplist_t>    jumps;

  get_all_spirals(spirals,jumps,permutations,true,true);

  // // Now get the spiral corresponding to this triangulation
  // // TODO: define S,J,P
  // get_spiral(0,1,2,S,J,P,true);
  // vector< int > group_actions; // Referring to the 'permutations' array.
  // for(int i=0;i<spirals.size();i++)
  //   if(J == jumps[i] && S == spirals[i]) group_actions.push_back(i);

  // Since finite point groups are Coxeter groups, they are generated
  // by a set of involutions. But... not every involution is a generator! What do?

  // Stuff for symmetry:
  //- Multiplication table can be represented as a directed graph.
  //-- Given any spanning tree, the leafs generate the group
  //-- Point groups are generated by involutions. Can we build up a spanning tree ending in involutions only?

}

vector<int> draw_path(int major, int minor)
{
  if(minor == 0) return {{major}};

  int slope = major/minor, slope_remainder = major%minor, slope_accumulator = 0;

  vector<int> paths(minor+1,0), runs(minor);

  for(int i=0; i<minor; i++){
    slope_accumulator += slope_remainder;

    paths[i+1] = paths[i] + slope + (slope_accumulator != 0);

    if((i+1<minor) && (slope_accumulator >= minor || slope_remainder == 0)){
      paths[i+1]++;
      slope_accumulator %= minor;
    }

    runs[i]    = paths[i+1]-paths[i];
  }

  //  cout << make_pair(major,minor) << " runlengths is " << runs << endl;

  return runs;
}




// Given start node u0 and adjacent face F_i, lay down triangles along the the straight
// line to Eisenstein number (a,b), and report what the final node is.
//
// Assumes a,b >= 1.
// TODO: Add special cases for (a,0) and (b,0) to make more general.
// TODO: Better name.
node_t Triangulation::end_of_the_line(node_t u0, int i, int a, int b) const
{
  node_t q,r,s,t;                // Current square

  auto go_north = [&](){
    const node_t S(s), T(t); // From old square
    q = S; r = T; s = next(S,T); t = next(s,r);
  };

  auto go_east = [&](){
    const node_t R(r), T(t); // From old square
    q = R; s = T; r = next(s,q); t = next(s,r);
  };

  // Square one
  q = u0;                         // (0,0)
  r = neighbours[u0][i];        // (1,0)
  s = next(q,r);        // (0,1)
  t = next(s,r);        // (1,1)

  // Special cases for axis-aligned paths
  if(a==0 && b==0) return q;
  if(a==0){ for(int i=0;i<b;i++) go_north(); return r; }  
  if(b==0){ for(int i=0;i<a;i++) go_east();  return s; }
      
  // Otherwise, draw the line
  vector<int> runlengths = draw_path(max(a,b), min(a,b));

  for(int i=0;i<runlengths.size();i++){
    int L = runlengths[i];

    if(a>=b){                        // a is major axis
      for(int j=0;j<L-1;j++)    go_east();
      if(i+1<runlengths.size()) go_north();
    } else {                        // b is major axis
      for(int j=0;j<L-1;j++)    go_north();
      if(i+1<runlengths.size()) go_east();
    }
  }

  return t;                        // End node is upper right corner.
}

// Returns:
// For each run-length, returns the following:
// t0--t1--t2--t3  -> [r0,t0, r1,t1, r2,t2, r3,t3] 
// | \ |  \ | \ |
// r0--r1--r2--r3
// The complete result is a vector of these vertex sequences.
// They are connected as follows when a>b
//        tt0--tt1-- ...
//          | \ |
// t0--t1--t2--t3--- ...
// | \ |  \ | \ |
// r0--r1--r2--r3
// I.e., always sharing an edge to the north, and when a<b
//     .. ..
//     | \ |
// s---t---tt
// | \ | \ | 
// s---t---tt
// | \ |
// s---t
// i.e., always sharing an edge to the East.
//   s---t
//  / \ /
// q---r
vector<vector<node_t>> Triangulation::quads_of_the_line(node_t u0, int i, int a, int b) const
{
  node_t q,r,s,t;                // Current square

  auto go_north = [&](){
    const node_t S(s), T(t); // From old square
    q = S; r = T; s = next(S,T); t = next(s,r);
  };

  auto go_east = [&](){
    const node_t R(r), T(t); // From old square
    q = R; s = T; r = next(s,q); t = next(s,r);
  };

  // Square one
  q = u0;                         // (0,0)
  r = neighbours[u0][i];          // (1,0)
  s = next(q,r);                  // (0,1)
  t = next(s,r);                  // (1,1)

  // Otherwise, draw the line
  vector<int>            runlengths = draw_path(max(a,b), min(a,b));
  vector<vector<node_t>> quad_runs(runlengths.size());
  
  for(int i=0;i<runlengths.size();i++){
    int L = runlengths[i];
    vector<node_t> quad_run(2*L+2);
    
    if(a>=b){                        // a is major axis
      quad_run[0] = q; quad_run[1] = s;
      quad_run[2] = r; quad_run[3] = t;
      for(int j=0;j<L-1;j++)    {
	go_east();
	quad_run[2*(j+2)+0] = r;
	quad_run[2*(j+2)+1] = t;
      }

      quad_runs[i] = quad_run;      
      go_north();

    } else {                        // b is major axis
      quad_run[0] = q; quad_run[2] = s; 
      quad_run[1] = r; quad_run[3] = t;
      for(int j=0;j<L-1;j++) {
	go_north();
	quad_run[2*(j+2)+0] = s;
	quad_run[2*(j+2)+1] = t;	
      }

      quad_runs[i] = quad_run;      
      go_east();
    }
  }

  //  {
    //    node_t t = end_of_the_line(u0,i,a,b);
    //    printf("quads_of_the_line(%d,%d,(%d,%d)) -> %d: ",u0,i,a,b,t);
    //    cout << quad_runs << endl;
  //  }
  return quad_runs;                        // End node is upper right corner.
}

matrix<int> Triangulation::pentagon_distance_mtx() const {
  vector<int> pentagon_indices(12);
  for(int u=0, i=0;u<N;u++) if(neighbours[u].size() == 5) pentagon_indices[i++] = u;  
  return all_pairs_shortest_paths(pentagon_indices);
}


// TODO: Do we need to do Dijkstra on sqrt(H) after all?
matrix<Triangulation::simple_geodesic>
Triangulation::simple_geodesics(vector<node_t> nodes,
				bool calculate_self_geodesics) const
{
  if(nodes.empty()){
    nodes.resize(N);
    for(int i=0;i<N;i++) nodes[i] = i;
  }

  vector<int> nodes_inverse(N,-1);
  for(node_t U=0;U<nodes.size();U++){
    node_t     u = nodes[U];
    nodes_inverse[u] = U;
  }

  // Initialize H to graph distances, which are upper bound to surface distances,
  matrix<int>             H(nodes.size(),nodes.size(),all_pairs_shortest_paths(nodes));
  matrix<simple_geodesic> G(nodes.size(),nodes.size());

  vector<int> M(nodes.size(),0);	// M[u] = max_v(d_g(u,v)) is upper bound to surface distance from u
  for(node_t U=0; U<nodes.size();U++)
    for(node_t V=0;V<nodes.size();V++){
      M[U]   = max(M[U], H(U,V));
      H(U,V) = INT_MAX;
    }
  //  for(int i=0;i<H.size();i++) H[i] *= H[i];     // Work with square distances, which are all integers

  if(calculate_self_geodesics) for(node_t U=0;U<nodes.size();U++){
      H(U,U) = INT_MAX; // Initialize diagonal to infinity -- we want shortest self-geodesics, i.e. circling 2pi of curvature
      M[U] *= 2;        // To capture self-geodesics, we need to look twice as far (there and back again)
    }

  // Work with square distances, which are all integers (after setting M)
  for(int i=0;i<H.size();i++) H[i] *= H[i];     
  
  //  cout << "M = " << M << endl;

  for(node_t u: nodes){
    for(int i=0;i<neighbours[u].size();i++){
      node_t U  = nodes_inverse[u];

      for(int a=1; a<M[U]; a++){	
	for(int b=0; a*a + a*b + b*b < M[U]*M[U]; b++){
	  const node_t v = end_of_the_line(u,i,a,b);

	  if(nodes_inverse[v] != -1){ // Endpoint v is in nodes
	    node_t V = nodes_inverse[v];
	    int d_sqr = a*a + a*b + b*b;
	    if(d_sqr < H(U,V)){
	      //	      cout << u << "->" << vector<int>{{a,b,d_sqr}} << "->" << v <<endl;
	      H(U,V) = d_sqr;
	      G(U,V) = simple_geodesic(a,b,i);
	    }
	  }
	}
      }
    }
  }
  //  cout << "Hend = " << H << endl;    
  return G;
}

matrix<int> Triangulation::simple_square_surface_distances(vector<node_t> nodes,
							   bool calculate_self_geodesics) const
{
  if(nodes.empty()){ nodes.resize(N); for(int i=0;i<N;i++) nodes[i] = i;  } // If no node list is given, calculate all distances
  
  vector<int> nodes_inverse(N,-1);
  for(int i=0;i<nodes.size();i++){
    node_t     u = nodes[i];
    nodes_inverse[u] = i;
  }
  //  cout << "nodes = " << nodes << endl;
  //  cout << "nodes_inverse = " << nodes_inverse << endl;  
  

  // Initialize H to graph distances, which are upper bound to surface distances:
  // 3/4 d_g^2 <= d_surface^2 <= d_g^2
  matrix<int>             H(nodes.size(),nodes.size(),all_pairs_shortest_paths(nodes));


  // M[u] = max_v(d_g(u,v)) is upper bound to surface distance from u  
  vector<int> M(nodes.size(),0);	// M[u] = max_v(d_g(u,v)) is upper bound to surface distance from u
  for(node_t U=0; U<nodes.size();U++)
    for(node_t V=0;V<nodes.size();V++)
      M[U] = max(M[U], H(U,V));

  //  cout << "M = " << M << endl;

  // Work with square distances, which are all integers  
  for(int i=0;i<H.size();i++) H[i] *= H[i];     

  //  cout << "H = " << H << endl;

  if(calculate_self_geodesics) for(node_t U=0;U<nodes.size();U++){
      H(U,U) = INT_MAX; // Initialize diagonal to infinity -- we want shortest self-geodesics, i.e. circling 2pi of curvature
      M[U] *= 2;        // To capture self-geodesics, we need to look twice as far (there and back again)
    }  

  // Note: All Eisenstein numbers of the form (a,0) or (0,b) yield same lengths
  //       as graph distance, and are hence covered by initial step. So start from 1.
  //       M is upper bound for distance, so only need to do a^2+ab+b^2 strictly less than M.
  for(node_t u: nodes){
    node_t U = nodes_inverse[u];
    const int Mu = M[U];
    
    for(int i=0;i<neighbours[u].size();i++)
      for(int a=1; a<Mu; a++)
	for(int b=1; a*a + a*b + b*b < Mu*Mu; b++){
	  const node_t v = end_of_the_line(u,i,a,b);

	  if(nodes_inverse[v] != -1){ // Endpoint v is in nodes
	    node_t V = nodes_inverse[v];
	    int d_sqr = a*a + a*b + b*b;
	    H(U,V) = min(H(U,V),d_sqr);
	  }
	}
  }
  
  return H;
}



matrix<double> Triangulation::surface_distances(vector<node_t> nodes,
						bool calculate_self_geodesics) const
{
  matrix<double> H(simple_square_surface_distances(nodes,calculate_self_geodesics));
  for(int i=0;i<H.size();i++) H[i] = sqrt(H[i]);

  auto D = H.APSP(false);
  for(int i=0;i<D.size();i++) D[i] *= D[i];  
  return D;
  // bool nonconvex = false;
  // for(node_t u=0;u<N;u++) if(neighbours[u].size() > 6) nonconvex = true;

  // if(nonconvex) return H.APSP();
  // else return H;
}

Triangulation Triangulation::sort_nodes() const
{
  vector< pair<int,int> > degrees(N);

  for(int u=0;u<N;u++) degrees[u] = make_pair(degree(u), u);

  sort(degrees.begin(), degrees.end());

  vector<int> newname(N), oldname(N);

  int degree, u_old;
  for(node_t u_new=0;u_new<N;u_new++){
    tie(degree,u_old) = degrees[u_new];
    newname[u_old] = u_new;
    oldname[u_new] = u_old;
  }

  neighbours_t new_neighbours(N);
  for(int u=0;u<N;u++)
    for(int i=0;i<neighbours[u].size();i++)
      new_neighbours[newname[u]].push_back(newname[neighbours[u][i]]);

  return Triangulation(new_neighbours);
}

spiral_nomenclature FullereneDual::name(bool rarest_start) const
{
  return spiral_nomenclature(dual_graph(), spiral_nomenclature::FULLERENE,
			     spiral_nomenclature::CUBIC,
			     rarest_start);  
}

// call for one general spiral and extract the pentagon indices
bool FullereneDual::get_rspi(const node_t f1, const node_t f2, const node_t f3, vector<int>& rspi, jumplist_t& jumps, const bool general) const
{
  rspi.resize(12);
  jumps.clear();
  vector<int> spiral;
  vector<node_t> permutation;
  if(!get_spiral(f1, f2, f3, spiral, jumps, permutation, general)) return false;

  for(int i=0,j=0;i<spiral.size();i++)
    if(spiral[i] == 5)
      rspi[j++] = i;

  return true;
}

// call for the canonical general spiral and extract the pentagon indices
bool FullereneDual::get_rspi(vector<int>& rspi, jumplist_t& jumps, const bool general, const bool pentagon_start) const
{
  rspi.resize(12);
  jumps.clear();
  vector<int> spiral;
  if(!get_spiral(spiral, jumps, pentagon_start, general)) return false;

  for(int i=0,j=0;i<spiral.size();i++)
    if(spiral[i] == 5)
      rspi[j++] = i;

  return true;
}

general_spiral FullereneDual::get_rspi(const bool rarest_start) const
{
  general_spiral S;
  get_rspi(S.spiral,S.jumps,true,rarest_start);
  return S;
}

// permutation of vertex numbers (ie, replace v by vertex_numbers[v], to get numbered vertices)
// where permutations are as returned by T.get_spiral(J,S,perm)
// locants are vertices that should have small vertex numbers (as far as permitted by symmetry equivalent canonical spirals)
vector<node_t> Triangulation::vertex_numbers(vector<vector<node_t>> &permutations, const vector<node_t> &locants) const{
  assert(is_triangulation());
  vector<node_t> vertex_numbers(N);
  vector<node_t> vertex_numbers_inv(N,INT_MAX);
  for(int p=0; p<permutations.size(); p++){
    const vector<node_t> &vertex_numbers_tmp=permutations[p];
    // invert
    vector<node_t> vertex_numbers_inv_tmp(N);
    for(int i=0; i<vertex_numbers_tmp.size(); i++) vertex_numbers_inv_tmp[vertex_numbers_tmp[i]] = i;
    // copy to vertex_numbers_inv?
    if(locants.size()==0){
      vertex_numbers_inv = vertex_numbers_inv_tmp;
      break;
    }
    // compare two vectors, but only at chosen positions
    for(int l=0; l<locants.size(); l++){
      if(vertex_numbers_inv_tmp[locants[l]] > vertex_numbers_inv[locants[l]]) break;
      if(vertex_numbers_inv_tmp[locants[l]] < vertex_numbers_inv[locants[l]]){
        vertex_numbers_inv = vertex_numbers_inv_tmp;
        break;
      }
    }
  }
  //invert
  for(int i=0; i<vertex_numbers.size(); i++) vertex_numbers[vertex_numbers_inv[i]] = i;
  return vertex_numbers; 
}

// takes a triangulation, and returns a dual of the inverse leapfrog
// this is easy because we just remove a set of faces
// the resulting planar graph is oriented because the input is oriented und we only remove vertices
PlanarGraph Triangulation::inverse_leapfrog_dual() const
{
  assert(is_oriented);
  PlanarGraph PG(*this);
  set<int> face_vertices, to_do_set;

  // find all vertices with degree < 6 (one could additionally find the vertices with odd degree)
  for(int v=0; v<neighbours.size(); v++){
    if(neighbours[v].size() < 6){
      face_vertices.insert(v);
      to_do_set.insert(v);
    }
  }

  // ... find all face vertices
  while(to_do_set.size() != 0){
    const int u = *(to_do_set.begin());
    to_do_set.erase(to_do_set.begin());

    for(int v: neighbours[u]){
      const int w = next(u,v);
      const int s = face_vertices.size();
      const int x = next(w,v);
      face_vertices.insert(x);
      if(face_vertices.size() != s)
        to_do_set.insert(x);
    }
  }
  // cerr << "faces to remove:" << endl;
  // cerr << face_vertices << endl;

  // check number of face_vertices
  // FIXME, optional

  // remove all face_vertices
  PG.remove_vertices(face_vertices);
  return PG;
}




vector<general_spiral> FullereneDual::isomer_search(const Triangulation::predicate_t& predicate, size_t N, size_t verbose_level,
					    bool IPR, bool only_nontrivial_symmetry, size_t N_chunks, size_t chunk_index)
{
  vector<general_spiral> spirals;
  size_t i=0;
  Graph g;

  // cout << "N_chunks = " << N_chunks << "\n"
  //      << "chunk_index = " << chunk_index << "\n\n";
  
  BuckyGen::buckygen_queue Q = BuckyGen::start(N,IPR,only_nontrivial_symmetry,
					       chunk_index,N_chunks);

  while(BuckyGen::next_fullerene(Q,g)){
    FullereneDual G(g);
    vector<int> rspi;
    jumplist_t jumps;

    i++;
    if(verbose_level>0 && i%verbose_level == 0) fprintf(stderr,"Reached isomer %ld\n",i);

    if(predicate(G)){
      spirals.push_back(FullereneDual(G).get_rspi());
      spiral_nomenclature name(G, spiral_nomenclature::FULLERENE,spiral_nomenclature::TRIANGULATION);
      //      spirals.push_back(name.to_string());
      cerr << name.to_string() << endl;
    }
  }
  BuckyGen::stop(Q);

  if(verbose_level>0) fprintf(stderr,"Generated %ld %d-vertex graphs.\n",i,int(g.neighbours.size()));
  
  return spirals; 
}
