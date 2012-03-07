#include "fullerenegraph.hh"

bool FullereneGraph::this_is_a_fullerene() const {
  for(node_t u=0;u<N;u++)
    if(neighbours[u].size() != 3){ 
      fprintf(stderr,"Graph is not cubic: vertex %d has %d neighbours.\n",u,int(neighbours[u].size())); 
      return false;
    }
    
  Graph::facemap_t faces(compute_faces(7));
  int n_faces = 0;
  for(facemap_t::const_iterator f(faces.begin()); f!=faces.end();f++)
    n_faces += f->second.size();

  const int E = 3*N/2;
  const int F = 2+E-N;
    
  if(E != edge_set.size()){
    fprintf(stderr,"Graph is not planar: wrong number of edges: %d != %d\n",int(edge_set.size()),E);
    return false;
  }

  if(F != n_faces){
    fprintf(stderr,"Graph is not planar: wrong number of faces: %d != %d\n",n_faces,F);
    return false;
  }

  if(faces[5].size() != 12){
    fprintf(stderr,"Graph is not fullerene: wrong number of pentagons: %d != 12\n",int(faces[5].size()));
    return false;
  }

  if(faces[6].size() != (F-12)){
    fprintf(stderr,"Graph is not fullerene: wrong number of hexagons: %d != %d\n",int(faces[6].size()),F-12);
    return false;
  }

  return true;
}


pair<set< face_t>, set<face_t> > FullereneGraph::compute_faces56() const 
{
  set<face_t> pentagons, hexagons;
  for(set<edge_t>::const_iterator e(edge_set.begin()); e!= edge_set.end(); e++){
    const node_t s = e->first, t = e->second;

    const vector<node_t>& ns(neighbours[t]);
    for(unsigned int i=0;i<ns.size();i++)
      if(ns[i] != s) {
	const node_t u = ns[i];
	
	// Assumes fullerene. Remove 6 and return map instead of pair to allow cubic graphs with arbitrary polygons
	face_t face(shortest_cycle(s,t,u,6)); 
	if      (face.size() == 5) pentagons.insert(face);
	else if (face.size() == 6) hexagons.insert(face);
	else {
	  fprintf(stderr,"Graph is not a fullerene: Contains face ");
	  for(unsigned int i=0;i<face.size();i++)
	    fprintf(stderr,"%d ",face[i]);
	  fprintf(stderr,"of size %d\n",int(face.size()));
	}
    }
  }
  return pair< set<face_t>,set<face_t> >(pentagons,hexagons);
}

// Creates the m-point halma-fullerene from the current fullerene C_n with n(1+m)^2 vertices. (I.e. 4,9,16,25,36,... times)
FullereneGraph FullereneGraph::halma_fullerene(const unsigned int m, const bool do_layout) const {
  Graph dual(dual_graph(6));
  vector<face_t> triangles(dual.compute_faces_flat(3));
  map<edge_t,vector<node_t> > edge_nodes;
    
  set<edge_t> edgeset_new;
  node_t v_new = dual.N;

  // Create n new vertices for each edge
  for(set<edge_t>::const_iterator e(dual.edge_set.begin()); e!=dual.edge_set.end(); e++){
    vector<node_t>& nodes(edge_nodes[*e]);
    for(unsigned int i=0;i<m;i++) nodes.push_back(v_new++);
  }

  // For every triangle in the dual, we create and connect a halma-type grid
  for(size_t i=0;i<triangles.size();i++){
    map<edge_t,node_t> grid;
    const face_t T(triangles[i]);
    edge_t e0(T[0],T[1]),e1(T[1],T[2]),e2(T[2],T[0]);
    const vector<node_t>& ns0(edge_nodes[e0]), ns1(edge_nodes[e1]), ns2(edge_nodes[e2]);

    // Insert pentagon vertices
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

  Graph new_dual(v_new, edgeset_new);

  FullereneGraph G(new_dual.dual_graph(3));

  if(do_layout){
    G.layout2d = G.tutte_layout();
    G.spherical_layout = G.spherical_projection(G.layout2d);
  }

  return G;
}


// Creates the next leapfrog fullerene C_{3n} from the current fullerene C_n
FullereneGraph FullereneGraph::leapfrog_fullerene(bool do_layout) const {
  Graph dualfrog(*this);
  vector<face_t> faces(dualfrog.compute_faces_flat(6)); 

  node_t v_new = N;
  for(size_t i=0;i<faces.size();i++){
    const face_t& f(faces[i]);
    for(size_t j=0;j<f.size();j++)
      dualfrog.edge_set.insert(edge_t(v_new,f[j]));
    v_new++;
  }
  dualfrog.update_auxiliaries();

  FullereneGraph frog(dualfrog.dual_graph(3));
  
  if(do_layout){
    frog.layout2d = frog.tutte_layout();
    frog.spherical_layout = frog.spherical_projection(frog.layout2d);
  }

  return frog;
}



node_t FullereneGraph::C20_neighbours[20*3] = {
  13, 14, 15, 
  4, 5, 12, 
  6, 13, 18, 
  7, 14, 19, 
  1, 10, 18, 
  1, 11, 19, 
  2, 10, 15, 
  3, 11, 15, 
  9, 13, 16, 
  8, 14, 17, 
  4, 6, 11, 
  5, 7, 10, 
  1, 16, 17, 
  0, 2, 8, 
  0, 3, 9, 
  0, 6, 7, 
  8, 12, 18, 
  9, 12, 19, 
  2, 4, 16, 
  3, 5, 17
};    
