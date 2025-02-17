#include "fullerenes/symmetry.hh"
#include "fullerenes/auxiliary.hh"
using namespace std;

//////////////////////////////////////////////////////////////////////
//	      POINT GROUPS FOR FULLEROIDS OF DEGREE <= 6
//////////////////////////////////////////////////////////////////////
// Reference: Deza-2009, Theorem 2.1 (iii)
// For future reference: Theorem 2.2 lists symmetry groups for all triangulations
// of degree <= 6, arranged by signature (p3,p4,p5). 
PointGroup PointGroup::FullereneSymmetries[28] = {
  {C,1},      {C,2},       {C,REF_I},   {C,REF_S},
  {C,3},      {D,2},       {S,4},       {C,2,REF_V},
  {C,2,REF_H},{D,3},       {S,6},       {C,3,REF_V},
  {C,3,REF_H},{D,2,REF_H}, {D,2,REF_D}, {D,5},  
  {D,6},      {D,3,REF_H}, {D,3,REF_D}, {T},  
  {D,5,REF_H},{D,5,REF_D}, {D,6,REF_H}, {D,6,REF_D}, 
  {T,REF_D},  {T,REF_H},   {I},         {I,REF_H}
};

PointGroup::PointGroup(const string& name_) : sym_type(UNKNOWN), n(0), sym_reflection(NONE)
{
  string name(name_);
  const char ts[7] = {'?','C','D','T','S','O','I'};
  const char rs[6] = {' ','v','h','d','i','s'};

  // trim name - TODO: fix
  while(name[0] == ' ') name = name.substr(1);

  for(int st=6;st>0;st--) 
    if(name[0] == ts[st]) sym_type = symmetry_type(st);
  
  if(name.size()  == 1) return;

  size_t idx = 0;
  if(name[1] >= '0' && name[1] <='9')
    n = stol(name.substr(1),&idx,0);
  
  if(name.size() <= idx+1) return;
  
  for(int sr=5;sr>0;sr--)
    if(name[idx+1] == rs[sr]) sym_reflection = symmetry_reflection(sr);
}


string PointGroup::to_string() const {
  const char ts[7] = {'?','C','D','T','S','O','I'};
  const char rs[6] = {' ','v','h','d','i','s'};

  string result;
  result += ts[sym_type];
  if(n>0) result += std::to_string(n);
  if(sym_reflection != NONE) result += rs[sym_reflection];
  return result;
}



//////////////////////////////////////////////////////////////////////
//			PERMUTATION DATA TYPE
//////////////////////////////////////////////////////////////////////
namespace std {
  template<> struct hash<Permutation> { // Vectors of integers smaller than 32 bit
    size_t operator()(const Permutation &v) const {
      return std::hash<vector<int>>()(v);      
    }
  };

}

Permutation Permutation::inverse() const {
  const vector<int> &p(*this);
  vector<int> ip(size());

  for(int i=0;i<size();i++) ip[p[i]] = i;
  return Permutation(ip);
}


Permutation Permutation::identity(int N)
{
  Permutation Id(N);
  for(int i=0;i<N;i++) Id[i] = i;
  return Id;
}

int Permutation::order() const {
  Permutation Id(identity(size())), power(*this), p(*this);

  int order=1;
  while(power != Id){ power = power*p; order++; }
  return order;
}

Permutation Permutation::operator*(const Permutation& q) const {
  assert(size() == q.size());

  const vector<int> &p(*this);
  vector<int> r(size());
  for(int i=0;i<size();i++) r[i] = q[p[i]];

  return Permutation(r);
}

// NB: Removed. This seems identical to vector '=='-operator?
// bool Permutation::operator==(const Permutation& q) const {
//   const vector<int> &p(*this);

//   if(size() != q.size()) return false;
//   for(int i=0;i<size();i++) if(p[i] != q[i]) return false;
//   return true;
// }


//////////////////////////////////////////////////////////////////////
//		  SYMMETRY-DETECTION IMPLEMENTATION
//////////////////////////////////////////////////////////////////////
vector<Permutation> Symmetry::tri_permutation(const vector<Permutation>& Gf) const {
  assert(triangles.size() == (N-2)*2); // Triangulation is cubic dual
  vector<Permutation> Gtri(Gf.size(),Permutation(triangles.size()));
  IDCounter<tri_t> tri_id;
    
  for(int i=0;i<triangles.size();i++) tri_id.insert(triangles[i].sorted());
    
  for(int j=0;j<Gf.size();j++){
    const Permutation& pi = Gf[j];    
    for(int i=0;i<triangles.size();i++){
      const tri_t &t  = triangles[i];
      const tri_t &tp = {pi[t[0]], pi[t[1]], pi[t[2]]}; 
      
      int tp_id = tri_id(tp.sorted());

      Gtri[j][i] = tp_id;

      if(tp_id < 0){
	cout << "SYMMETRY OPERATION DOES NOT MAP TRIANGLE TO EXISTING TRIANGLE.\n";
	cout << "tp_id = " << tp_id << endl;
	cout << "pi["<<j<<"] = " << pi << endl;
	cout << "t = " << t <<endl;
	cout << "tp = " << tp << endl;
	cout << "tp.sorted() = " << tp.sorted() << endl;

	cout << "triangles = " << triangles << endl;
	
	assert(tp_id >= 0);
      }
    }
  }
  return Gtri;
}

vector<Permutation> Symmetry::edge_permutation(const vector<Permutation>& Gf) const
{
  vector<Permutation> Gedge(Gf.size(),Permutation(edge_id.size()));
    
  for(int j=0;j<Gf.size();j++){
    for(const auto &ei: edge_id){
      edge_t e = ei.first;
      int    i = ei.second;
      
      Gedge[j][i] = edge_id({Gf[j][e.first],Gf[j][e.second]});
    }
  }
  return Gedge;
}

vector<Permutation> Symmetry::dedge_permutation(const vector<Permutation>& Gf) const {

  vector<Permutation> Gedge(Gf.size(),Permutation(dedge_id.size()));
    
  for(int j=0;j<Gf.size();j++){
    for(const auto &ei: dedge_id){
      dedge_t e = ei.first;
      int     i = ei.second;
      
      Gedge[j][i] = dedge_id({Gf[j][e.first],Gf[j][e.second]});
    }
  }
  return Gedge;
}

vector<Permutation> Symmetry::permutation_representation() const
{
  vector<Permutation> pi;

  for(node_t u=0;u<N;u++){
    if(degree(u) == S0[0]) // u has same degree as vertex 1: possible spiral start
      for(const node_t &v: neighbours[u]){
	if(degree(v) == S0[1]){ // v has same degree as vertex 2: still possible spiral start
	  vector<int> spiral,permutation;
	  jumplist_t  jumps;

	  node_t wCCW = next(u,v), wCW = prev(u,v);

	  if(degree(wCCW) == S0[2] && get_spiral_implementation(u,v,wCCW,spiral,jumps,permutation,true,S0,J0)){
	    // cout << "Found CCW symmetry:\n"
	    // 	 << S0     << " = \n"
	    // 	 << spiral << "\n"
	    // 	 << "pi = " << permutation << "\n";
	    pi.push_back(permutation);
	  }
	  if(degree(wCW)  == S0[2] && get_spiral_implementation(u,v,wCW,spiral,jumps,permutation,true,S0,J0)){
	    // cout << "Found CW symmetry:\n"
	    // 	 << S0     << " = \n"
	    // 	 << spiral << "\n"
	    // 	 << "pi = " << permutation << "\n";
	    
	    pi.push_back(permutation);
	  }
	}
      }
  }
  return pi;
}

vector<int> Symmetry::site_symmetry_counts(const vector<Permutation>& pi) const
{
  vector<int> m(12); 		// Probably needs to be changed for more general point groups
  int order = pi.size(), M = pi[0].size();

  vector<bool> seen(M,false);
  for(int i=0;i<M;i++){	// Calculate length and site-symmetry group order of every orbit. Iterate through all sites, but skip seen one to only do each orbit once.
    if(seen[i]) continue;
    seen[i] = true;
      
    int orbit_length = 1;
    for(int j=1;j<order;j++){ 
      int I = pi[j][i];
      assert(I<M);
      assert(I>0);
      if(seen[I]) continue;
      seen[I] = true;
      orbit_length++;
    }	
    int site_order = order/orbit_length; 
    assert(site_order <= 12); // Only holds for fullerenes?
    m[site_order-1]++;
  }
  return m;
}

vector<int> Symmetry::involutions() const // Returns the involutions *except* from the identity
{
  Permutation Id(Permutation::identity(N));
  vector<int> result;
  for(int i=0;i<G.size();i++) 
    if(G[i]*G[i] == Id && G[i] != Id) result.push_back(i);
  return result;
}

vector< vector<int> > Symmetry::multiplication_table() const 
{
  IDCounter<Permutation> pid;

  for(int i=0;i<G.size();i++) pid.insert(G[i]);

  vector< vector<int> > table(G.size(), vector<int>(G.size()));

  for(int i=0;i<G.size();i++)
    for(int j=0;j<G.size();j++)
      table[i][j] = pid(G[i]*G[j]);
    
  return table;
}

vector<int> Symmetry::fixpoints(const Permutation& pi) const {
  vector<int> fp;
  for(int i=0;i<N;i++) if(pi[i] == i) fp.push_back(i);
  return fp;
}


vector<int> Symmetry::group_fixpoints(const vector<Permutation>& G) const { 
  vector<int> fp;
  for(int i=0;i<N;i++){
    bool fixed = true;
    for(int j=0;j<G.size();j++) if(G[j][i] != i) fixed = false;
    if(fixed) fp.push_back(i);
  }
  return fp;
}


bool Symmetry::reverses_orientation(const Permutation& pi) const 
{
  Triangulation piG(neighbours,true);

  for(node_t u=0;u<N;u++){
    const vector<node_t>& nu(neighbours[u]);
    for(int i=0;i<nu.size();i++) piG.neighbours[pi[u]][i] = pi[nu[i]];
  }
  if(piG.next(0,1) == 2) return false;
  if(piG.prev(0,1) != 2){
    fprintf(stderr,"G.next(0,1) == {%d,%d} (CW,CCW)\n",
	    prev(0,1),
	    next(0,1));
    fprintf(stderr,"pi(G).next(0,1) == {%d,%d} (CW,CCW)\n",
	    piG.prev(0,1),
	    piG.next(0,1));
    cout << "pi(G).neighbours[0] = " << piG.neighbours[0] << ";\n"
	 << "pi(G).neighbours[1] = " << piG.neighbours[1] << ";\n";
    abort();
  }
  return true;
}


PointGroup Symmetry::point_group() const
{
  vector<int> 
    mF = site_symmetry_counts(G),
    mV = site_symmetry_counts(Gtri),
    mE = site_symmetry_counts(Gedge);

  vector<int> mS(13,0);
  for(int i=0;i<12;i++) mS[i+1] = mF[i] + mV[i] + mE[i];
  
  switch(G.size()){
  case 1:
    return PointGroup("C1");

  case 2:
    switch(mS[2]){
    case 0: 
      return PointGroup("Ci");
    case 2:
      return PointGroup("C2");
    default:
      if(mS[2]>2) 
	return PointGroup("Cs");
    }
    break;
  case 3:
    return PointGroup("C3");

  case 4: 
    switch(mS[4]){
    case 0:
      switch(mS[2]){
      case 1:
	return PointGroup("S4");
      case 3: 
	return PointGroup("D2");
      default:
	if(mS[2]>3) return PointGroup("C2h");
      }
      break;
    case 2:
      return PointGroup("C2v");
    default:
      break;
    }
    break;
  case 5:  // No fullerene groups of order 5 -- fill out for fulleroids
    break;

  case 6:
    switch(mS[6]){
    case 0:
      switch(mS[2]){
      case 0:
	return PointGroup("S6");
      case 2:
	return PointGroup("D3");
      default:
	if(mS[2]>2) return PointGroup("C3h");	
      }
      break;
    case 2:
      return PointGroup("C3v");
    default:
      break;
    }
    break;

  case 7:  // No fullerene groups of order 7 -- fill out for fulleroids
    break;

  case 8:
    switch(mS[4]){
    case 1: 
      return PointGroup("D2d");
    case 3:
      return PointGroup("D2h");
    default:
      break;
    }
    break;

  case 10:
    return PointGroup("D5");

  case 12:
    switch(mS[6]){
    case 0:
      return PointGroup("T");
    case 1:
      switch(mS[4]){
      case 0:
	switch(mS[2]){
	case 2:
	  return PointGroup("D6");
	default:
	  if(mS[2]>2) return PointGroup("D3d");
	}
	break;
      case 2:
	return PointGroup("D3h");
      default:
	break;
      }     
    default:
      break;
    }
    break;

  case 20:
    switch(mS[4]){
    case 0:
      return PointGroup("D5d");
    case 2:
      return PointGroup("D5h");
    default:
      break;
    }
    break;

  case 24:
    switch(mS[12]){
    case 0:
      switch(mS[6]){
      case 0:
	return PointGroup("Th");
      case 2:
	return PointGroup("Td");
      default:
	break;
      }
      break;
    case 1:
      switch(mS[4]){
      case 0:
	return PointGroup("D6d");
      case 2:
	return PointGroup("D6h");
      default:
	break;
      }
    default:
      break;
    }
    break;
    
  case 60:
    return PointGroup("I");

  case 120:
    return PointGroup("Ih");

  default:
    break;
  }

  return PointGroup();
}


vector< pair<int,int> > Symmetry::NMR_pattern() const
{
  vector<int>  mV = site_symmetry_counts(Gtri);
  vector< pair<int,int> > NMR;
  
  // F&M
  int order = G.size();
  for(int K=6;K>=1;K--)
    if(mV[K-1] != 0) NMR.push_back(make_pair(mV[K-1],order/K));
  
  return NMR;
}


vector<vector<node_t>> Symmetry::equivalence_classes(const vector<Permutation>& G) const {
  size_t N = G[0].size();
  Graph E(N);

  for(auto &pi: G)
    for(node_t u=0;u<N;u++) E.insert_edge({u,pi[u]});

  return E.connected_components();
}
