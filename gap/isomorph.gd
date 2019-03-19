#############################################################################
##
##  isomorph.gd
##  Copyright (C) 2014-18                                James D. Mitchell
##                                                          Wilf A. Wilson
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

DeclareAttribute("AutomorphismGroup", IsDigraph);
DeclareOperation("AutomorphismGroup", [IsDigraph, IsHomogeneousList]);
DeclareOperation("AutomorphismGroup",
                 [IsDigraph, IsHomogeneousList, IsList]);

DeclareAttribute("BlissAutomorphismGroup", IsDigraph);
DeclareOperation("BlissAutomorphismGroup", [IsDigraph, IsHomogeneousList]);
DeclareOperation("BlissEdgeColouredAutomorphismGroup",
                 [IsDigraph, IsHomogeneousList, IsList]);

DeclareAttribute("NautyAutomorphismGroup", IsDigraph);
DeclareOperation("NautyAutomorphismGroup", [IsDigraph, IsHomogeneousList]);

DeclareAttribute("BlissCanonicalLabelling", IsDigraph);
DeclareOperation("BlissCanonicalLabelling", [IsDigraph, IsHomogeneousList]);

DeclareAttribute("NautyCanonicalLabelling", IsDigraph);
DeclareOperation("NautyCanonicalLabelling", [IsDigraph, IsHomogeneousList]);

DeclareAttribute("BlissCanonicalDigraph", IsDigraph);
DeclareOperation("BlissCanonicalDigraph", [IsDigraph, IsHomogeneousList]);

DeclareAttribute("NautyCanonicalDigraph", IsDigraph);
DeclareOperation("NautyCanonicalDigraph", [IsDigraph, IsHomogeneousList]);

DeclareOperation("IsIsomorphicDigraph", [IsDigraph, IsDigraph]);
DeclareOperation("IsIsomorphicDigraph",
                 [IsDigraph, IsDigraph, IsHomogeneousList, IsHomogeneousList]);
DeclareOperation("IsomorphismDigraphs", [IsDigraph, IsDigraph]);
DeclareOperation("IsomorphismDigraphs",
                 [IsDigraph, IsDigraph, IsHomogeneousList, IsHomogeneousList]);

DeclareGlobalFunction("DigraphsUseBliss");
DeclareGlobalFunction("DigraphsUseNauty");

BindGlobal("DIGRAPHS_UsingBliss", true);

DeclareGlobalFunction("DIGRAPHS_ValidateVertexColouring");
DeclareGlobalFunction("DIGRAPHS_ValidateEdgeColouring");

DeclareOperation("IsDigraphAutomorphism", [IsDigraph, IsPerm]);
DeclareOperation("IsDigraphIsomorphism", [IsDigraph, IsDigraph, IsPerm]);
DeclareOperation("IsDigraphAutomorphism", [IsDigraph, IsTransformation]);
DeclareOperation("IsDigraphIsomorphism",
                 [IsDigraph, IsDigraph, IsTransformation]);
