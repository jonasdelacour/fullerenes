add_library(fullerenes SHARED
  graph.cc
  cubicgraph.cc
  planargraph.cc
  fullerenegraph.cc
  triangulation.cc
  polyhedron.cc
  spiralc.cc
  planargraph-io.cc
  polyhedron-io.cc
  fold.cc
  unfold.cc
  geometryc.cc
  graph_fortran.cc
  layout.cc
  polyhedron-optimize.cc
  eisenstein.cc
  ../contrib/mgmres.cc
)

target_link_libraries(fullerenes buckygen fortran_opt gfortran)
