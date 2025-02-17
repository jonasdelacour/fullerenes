#include <stdlib.h>
#include <fstream>
#include <vector>

#include "libgraph/cubicgraph.hh"
#include "libgraph/fullerenegraph.hh"
#include "libgraph/eisenstein.hh"
#include "libgraph/unfold.hh"
#include "libgraph/triangulation.hh"
#include "libgraph/polyhedron.hh"

using namespace std;

PlanarGraph fold(vector< pair<Eisenstein, node_t> > &outline);

typedef pair<Eisenstein,Eisenstein> dedgecoord_t;




int turn_direction(const Eisenstein& xi,const Eisenstein& xj,const Eisenstein& xk) 
{
  Eisenstein dx1(xj-xi), dx2(xk-xj);
  return sgn(dx2.first * dx1.second - dx2.second * dx1.first);
}


Eisenstein tfm(const Eisenstein& x, const Eisenstein& x0, const Eisenstein& w, const Eisenstein& x0p)
{
  return (x-x0)*w + x0p;
}


PlanarGraph GCTransform(const PlanarGraph& dual, int K=1, int L=0)
{
  Unfolding U(dual);
  Folding F(U*Eisenstein(K,L));
  return F.fold();
}


vector< pair<Eisenstein, node_t> > GCDreduce(const vector< pair<Eisenstein, node_t> > &outline)
{
  vector<Eisenstein> segments(outline.size());

  for(int i=0;i<outline.size();i++) segments[i] = outline[(i+1)%outline.size()].first - outline[i].first;

  cout << "segments  = " << segments << ";\n";

  Eisenstein d(Eisenstein::gcd(segments)); // TODO: Only do GCD between pentagon nodes.

  cout << "GCD = " << d << endl;
  for(int i=0;i<segments.size();i++) segments[i] = segments[i].div(d);

  vector< pair<Eisenstein,node_t> > new_outline(outline);
  for(int i=0;i+1<outline.size();i++) new_outline[i+1].first = new_outline[i].first+segments[i];

  return new_outline;
}


Graph cube()
{
  const int N = 8;
  neighbours_t neighbours(N,vector<node_t>(3));

  for(int i=0; i<4; i++){
    neighbours[i][0] = (i+1)%4;
    neighbours[i][1] = (i-1+4)%4;
    neighbours[i][2] = (i+4)%4 + 4;

    neighbours[i+4][0] = (i+1)%4 + 4;
    neighbours[i+4][1] = (i-1+4)%4 + 4;
    neighbours[i+4][2] = (i+4)%4;
  }
  return Graph(neighbours);
}


Graph tetraeder()
{
  const int N = 4;
  neighbours_t neighbours(N,vector<node_t>(3));

  for(int i=0; i<4; i++){
    neighbours[i][0] = (i+1)%4;
    neighbours[i][1] = (i+2)%4;
    neighbours[i][2] = (i+3)%4;
  }
  cout << neighbours << endl;
  return Graph(neighbours);
}


Graph oct_2()
{
  const int N = 8;
  neighbours_t neighbours(N,vector<node_t>(3));

  neighbours[0][0] = 1;
  neighbours[0][1] = 4;
  neighbours[0][2] = 5;

  neighbours[1][0] = 0;
  neighbours[1][1] = 2;
  neighbours[1][2] = 5;

  neighbours[2][0] = 1;
  neighbours[2][1] = 3;
  neighbours[2][2] = 6;

  neighbours[3][0] = 2;
  neighbours[3][1] = 4;
  neighbours[3][2] = 7;

  neighbours[4][0] = 0;
  neighbours[4][1] = 3;
  neighbours[4][2] = 7;

  neighbours[5][0] = 0;
  neighbours[5][1] = 1;
  neighbours[5][2] = 6;

  neighbours[6][0] = 2;
  neighbours[6][1] = 5;
  neighbours[6][2] = 7;

  neighbours[7][0] = 3;
  neighbours[7][1] = 4;
  neighbours[7][2] = 6;

  return Graph(neighbours);
}

Graph C20()
{
  return FullereneGraph::C20();
}

Graph c32_1(){
  //  C2 
  const int N=32;
  const vector<int> rspi = {0, 1, 2, 3, 4, 6, 11, 13, 14, 15, 16, 17};
  return FullereneGraph(N, rspi);
}

Graph c32_2(){
  // D2 
  const int N=32;
  const vector<int> rspi = {0, 1, 2, 3, 4, 7, 11, 12, 14, 15, 16, 17};
  return FullereneGraph(N, rspi);
}

Graph c32_3(){
  // D3d
  const int N=32;
  const vector<int> rspi = {0, 1, 2, 3, 4, 8, 11, 12, 13, 15, 16, 17};
  return FullereneGraph(N, rspi);
}

Graph c32_4(){
  // C2 
  const int N=32;
  const vector<int> rspi = {0, 1, 2, 3, 6, 9, 10, 11, 13, 14, 16, 17};
  return FullereneGraph(N, rspi);
}

Graph c32_5(){
  // D3h 
  const int N=32;
  const vector<int> rspi = {0, 1, 2, 3, 6, 9, 10, 12, 13, 15, 16, 17};
  return FullereneGraph(N, rspi);
}

Graph c32_6(){
  // D3
  const int N=32;
  const vector<int> rspi = {0, 1, 2, 4, 6, 8, 9, 11, 13, 15, 16, 17};
  return FullereneGraph(N, rspi);
}

Graph c18_1()
{
  const int N = 18;
  neighbours_t neighbours(N,vector<node_t>(3));

  neighbours[0][0] = 1;
  neighbours[0][1] = 2;
  neighbours[0][2] = 17;

  neighbours[1][0] = 0;
  neighbours[1][1] = 3;
  neighbours[1][2] = 7;

  neighbours[2][0] = 0;
  neighbours[2][1] = 4;
  neighbours[2][2] = 10;

  neighbours[3][0] = 1;
  neighbours[3][1] = 4;
  neighbours[3][2] = 5;

  neighbours[4][0] = 2;
  neighbours[4][1] = 3;
  neighbours[4][2] = 6;

  neighbours[5][0] = 3;
  neighbours[5][1] = 6;
  neighbours[5][2] = 8;

  neighbours[6][0] = 4;
  neighbours[6][1] = 5;
  neighbours[6][2] = 9;

  neighbours[7][0] = 1;
  neighbours[7][1] = 8;
  neighbours[7][2] = 15;

  neighbours[8][0] = 5;
  neighbours[8][1] = 7;
  neighbours[8][2] = 11;

  neighbours[9][0] = 6;
  neighbours[9][1] = 10;
  neighbours[9][2] = 12;

  neighbours[10][0] = 2;
  neighbours[10][1] = 9;
  neighbours[10][2] = 16;

  neighbours[11][0] = 8;
  neighbours[11][1] = 12;
  neighbours[11][2] = 13;

  neighbours[12][0] = 9;
  neighbours[12][1] = 11;
  neighbours[12][2] = 14;

  neighbours[13][0] = 11;
  neighbours[13][1] = 14;
  neighbours[13][2] = 15;

  neighbours[14][0] = 12;
  neighbours[14][1] = 13;
  neighbours[14][2] = 16;

  neighbours[15][0] = 7;
  neighbours[15][1] = 13;
  neighbours[15][2] = 17;

  neighbours[16][0] = 10;
  neighbours[16][1] = 14;
  neighbours[16][2] = 17;

  neighbours[17][0] = 0;
  neighbours[17][1] = 15;
  neighbours[17][2] = 16;

  return Graph(neighbours);
}

Graph c48_1(){
  // D6d
  const int N=48;
  const vector<int> rspi = {0, 1,  3,  7,  8, 9, 18, 19, 20, 21, 22, 24};
  return FullereneGraph(N, rspi);
}

Graph c48_2(){
  // D6d
  const int N=48;
  const vector<int> rspi = {0,  1,  3,  6, 10, 14, 18, 19, 22, 23, 24, 25};
  return FullereneGraph(N, rspi);
}

Graph c12_prism()
{
  const int N = 12;
  neighbours_t neighbours(N,vector<node_t>(3));

  for(int i=0; i<6; i++){
    neighbours[i][0] = (i+1)%6;
    neighbours[i][1] = (i-1+6)%6;
    neighbours[i][2] = i+6;

    neighbours[i+6][0] = (i+1)%6+6;
    neighbours[i+6][1] = (i-1+6)%6+6;
    neighbours[i+6][2] = i;
  }
  cout << neighbours << endl;
  return Graph(neighbours);
}

Graph examples[14] = {cube(), tetraeder(), oct_2(), C20(), c32_1(), c32_2(), c32_3(), c32_4(), c32_5(), c32_6(), c18_1(), c48_1(), c48_2(), c12_prism()};



int main(int ac, char **av)
{
  vector<int> rspi(12);
  FullereneGraph::jumplist_t jumps;

  if(ac!=4) {cout << "three arguments required" << endl;}
  const int index = strtol(av[1],0,0) - 1;
  const int K = strtol(av[2],0,0);
  const int L = strtol(av[3],0,0);
  const int trafo = strtol(av[4],0,0);
  if(trafo != 0 && trafo != 1){cerr << "valid transformations are '0' and '1', exiting" << endl; return 1;}
  cout << "index, K, L: " << index << ", " << K << ", " <<  L << ", " <<  trafo << endl;


  PlanarGraph g(examples[index]);
  cout << "planar graph created" << endl;
  cout << g << endl;
  g.layout2d = g.tutte_layout(0,-1,-1,4);
  cout << "layout created" << endl;

  const int N = g.N;
  ofstream output(("output/C"+to_string(N)+"-unfold.m").c_str());

  PlanarGraph dual(g.dual_graph(6));
  cout << "dual graph created" << endl;
  dual.layout2d = dual.tutte_layout();
  cout << "layout created" << endl;

  output << "g = "  << g << ";\n";
  output << "dg = " << dual << ";\n";
//  cout << "Need to place 2x"<<dual.edge_set.size()<<" edges.\n";

  Unfolding unfld(dual,true);

  
  cout << "Placed " << unfld.edgecoords.size() << " edges.\n";

  output << "dedges   = " << get_keys(unfld.edgecoords) << ";\n";
  output << "dedgepos = " << get_values(unfld.edgecoords) << ";\n";
  output << "outline = "  << unfld.outline << ";\n";
  output << "outlinecoords = " << get_keys(unfld.outline) << ";\n";

  Unfolding gct_unfld = unfld * Eisenstein(K,L);
  cout << "outline multiplied" << endl;

  output << "gctoutline = " << get_keys(gct_unfld.outline) << ";\n";
  output.close();

  Folding fld(gct_unfld);
  cout << "folding created" << endl;
  PlanarGraph gctdual = fld.fold();
  cout << "triangulation created" << endl;
  PlanarGraph gct = gctdual.dual_graph(3,false);
  cout << "cubic graph created" << endl;
  cout << "gctdual = " << gctdual << ";\n"
	 << "gct     = " << gct << ";\n";


  gct.layout2d = gct.tutte_layout();
  Polyhedron P0 = Polyhedron(gct,gct.zero_order_geometry(),6);

  int finalN = N * (K*K + K*L + L*L);
  if(trafo==0){
    finalN *= 3;
  }else if(trafo==1){
    finalN *= 2;
  }
      
  string basename("gaudi-"+to_string(finalN));
  {
    ofstream mol2(("output/"+basename+"-P0.mol2").c_str());
    mol2 << P0.to_mol2();
    mol2.close();
  }

  Polyhedron P(P0);

  bool optimise_angles = true;
  set<edge_t> es=gct.undirected_edges();
  set<edge_t> long_edges;
  map<edge_t, double> lengths;
  facemap_t faces=gct.compute_faces(6);


// find long edges
  cout << "faces-3: " << faces[3] << endl;
  cout << "faces-4: " << faces[4] << endl;
  cout << "faces-5: " << faces[5] << endl;
  set<node_t> marked_nodes;
  // the easy part: all small faces
  for(int i=3; i<6; i++){
    for(set<face_t>::iterator it=faces[i].begin(), to=faces[i].end(); it!=to; it++){
      for(int j=0; j<i; j++){
        long_edges.insert(edge_t((*it)[j], (*it)[(j+1)%i]));
        es.erase(         edge_t((*it)[j], (*it)[(j+1)%i]));
        marked_nodes.insert((*it)[j]);
      }
    }
  }
  // the harder part:  additional hexagons, such that each vertex is part of one 'marked' face
  bool face_found_in_this_iteration = true;
  while(face_found_in_this_iteration){
    face_found_in_this_iteration = false;
    for(set<face_t>::iterator it=faces[6].begin(), to=faces[6].end(); it!=to; it++){
      bool face_relevant = true;
      // check if any node of this face is marked
      for(int j=0; j<6; j++){
        if(marked_nodes.find((*it)[j]) != marked_nodes.end()){
          face_relevant = false; break;
        }
      }
      if(!face_relevant) continue;
           
      // check if any node of this face shares an edge with a marked node
      face_relevant = false;
      for(int j=0; j<6; j++){
        for(int k=0; k<3; k++){
          if(marked_nodes.find(P.neighbours[(*it)[j]][k]) != marked_nodes.end()){
            face_relevant = true;
          }    
        }
      }

      if(face_relevant){
        for(int j=0; j<6; j++){
          long_edges.insert(edge_t((*it)[j], (*it)[(j+1)%6]));
          es.erase(edge_t((*it)[j], (*it)[(j+1)%6]));
          marked_nodes.insert((*it)[j]);
        }
        face_found_in_this_iteration = true;
      }
    }
  }
  
  cout << "marked nodes: " << marked_nodes << endl;
  cout << "long edges: " << long_edges << endl;
  cout << "normal edges: " << es << endl;

  // depending on whether the beta or gamma analogon is required, we switch edge lists
  if(trafo==1){
    set<edge_t> tmp = long_edges;
    long_edges = es;
    es = tmp;
    cout << "gamma graphyne chosen, edges swapped." << endl;
  }else{
    cout << "beta graphyne chosen." << endl;
  }
    


// optimise cubic graph with long edges
  const double normal_edge_length=1.393;
  const double long_edge_single=1.452;
  const double long_edge_triple=1.242;
  const double long_edge_total=2*long_edge_single + long_edge_triple;
  for(set<edge_t>::iterator it=es.begin(), to=es.end(); it!=to; it++){
    lengths.insert(make_pair(*it, normal_edge_length));
  }
  for(set<edge_t>::iterator it=long_edges.begin(), to=long_edges.end(); it!=to; it++){
    lengths.insert(make_pair(*it, long_edge_total));
  }
  P.optimise_other(optimise_angles, lengths);
  {
    ofstream mol2(("output/"+basename+".mol2").c_str());
    mol2 << P.to_turbomole();
    mol2.close();
  }

// replace long edges, don't reoptimise
  for (set<edge_t>::iterator it=long_edges.begin(), to=long_edges.end(); it!=to; it++){
    //cout << "edge to zap: " << *it << endl;
    edge_t to_zap(*it);
    //cout << "edge to zap: " << to_zap << endl;
    //vector<int>& n1 = P.neighbours[it->first];
    //vector<int>& n2 = P.neighbours[it->second];
    //cout << n1 << ", " << n2 <<  endl;
    P.remove_edge(to_zap);
    //cout << "neighbours : " << P.neighbours << endl;
    //cout << n1 << ", " << n2 <<  endl;
    P.N += 2;
    P.neighbours.resize(P.N);
    //cout << "neighbours : " << P.neighbours << endl;
    //cout << "trying to insert : " << edge_t(to_zap.first,P.N-2) << edge_t(to_zap.second,P.N-1) << edge_t(P.N-2,P.N-1) << endl;
    P.neighbours[to_zap.first].push_back(P.N-2);
    P.neighbours[P.N-2].push_back(to_zap.first);
    P.neighbours[to_zap.second].push_back(P.N-1);
    P.neighbours[P.N-1].push_back(to_zap.second);
    P.neighbours[P.N-2].push_back(P.N-1);
    P.neighbours[P.N-1].push_back(P.N-2);
    //cout << "neighbours : " << P.neighbours << endl;
    
    const coord3d c1=P.points[it->first];
    const coord3d c2=P.points[it->second];
    coord3d dc = c2-c1;
    //cout << "c1, c2, dc: " << c1 << c2 << dc << endl;
    P.points.push_back(c1 + dc*(long_edge_single/long_edge_total)); 
    P.points.push_back(c2 - dc*(long_edge_single/long_edge_total)); 
    //cout << "new point connected to c1: " << c1 + dc*(long_edge_single/long_edge_total) << endl;
    //cout << "new point connected to c2: " << c2 - dc*(long_edge_single/long_edge_total) << endl;
    //cout << "size: " << P.points.size() << endl;
    //cout << "neighbours : " << P.neighbours << endl;
    //cout << "-----" << endl;
  }

// write output
  cout << "P: " << P << endl;  
  {
    ofstream mol2(("output/"+basename+".mol2").c_str());
    mol2 << P.to_mol2();
    mol2.close();
  }
  {
    ofstream mol2(("output/"+basename+".coord").c_str());
    mol2 << P.to_turbomole();
    mol2.close();
  }
  {
    ofstream mol2(("output/"+basename+".xyz").c_str());
    mol2 << P.to_xyz();
    mol2.close();
  }

  return 0;
}
