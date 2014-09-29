#include "libgraph/triangulation.hh"
#include "libgraph/delaunay.hh"
#include "libgraph/polyhedron.hh"
#include "libgraph/fullerenegraph.hh"

#include <fstream>

Polyhedron fullerene_dual_polyhedron(const Triangulation& dg)
{
  FullereneGraph g(dg.dual_graph());
  g.layout2d = g.tutte_layout();

  vector<coord3d> points = g.zero_order_geometry();
  points = g.optimized_geometry(points);

  vector<coord3d> dual_points(dg.N);

  vector<face_t> faces(dg.N);
  for(int i=0;i<dg.triangles.size();i++)
    for(int j=0;j<3;j++)
      faces[dg.triangles[i][j]].push_back(i);

  for(int i=0;i<faces.size();i++)
    dual_points[i] = faces[i].centroid(points);

  return Polyhedron(dg, dual_points);
}

int main(int ac, char **av) {
  int N;
  vector<int> RSPI(12);
  N = strtol(av[1], 0, 0);
  for (int i = 0; i < 12; i++)
    RSPI[i] = strtol(av[i + 2], 0, 0) - 1;

  string filename = "output/reduce-graph-C"+to_string<int>(N)+".m";
  ofstream output(filename);

  vector<int> spiral(N/2+2, 6);
  for (int i = 0; i < 12; i++)
    spiral[RSPI[i]] = 5;

  cout << "spiral = " << spiral << endl;

  Triangulation T1(spiral);
  cout << "T1 = " << T1 << endl;

  FulleroidDelaunay T(T1);

  cout << "T = " << T << endl;

  output << "T = " << T << ";\n"
	 << "dDist = " << T.distances << ";\n";

  Polyhedron PT = fullerene_dual_polyhedron(T);

  T.remove_flat_vertices();
  output << "rT = " << T << ";\n";

  matrix<double> D = T.surface_distances();
  matrix<int>    Dsqr = T.convex_square_surface_distances();
 
  output << "Dist = " << D << ";\n";
  output << "iDist = Sqrt[" << Dsqr << "];\n";
  
  output.close();
  return 0;
}
