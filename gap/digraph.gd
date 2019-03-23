#############################################################################
##
##  digraph.gd
##  Copyright (C) 2014                                   James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# Categories
DeclareCategory("IsDigraph", IsObject);
DeclareCategory("IsDigraphWithAdjacencyFunction", IsDigraph);

DeclareSynonym("IsMutableDigraph", IsDigraph and IsMutable);
DeclareCategory("IsImmutableDigraph", IsDigraph);

DeclareGlobalFunction("IsValidDigraph");

# Family
BindGlobal("DigraphFamily", NewFamily("DigraphFamily", IsDigraph));

# Representations
DeclareRepresentation("IsDenseDigraphRep",
                      IsDigraph and IsComponentObjectRep,
                      ["OutNeighbours"]);

# No check constructors
DeclareOperation("ConvertToMutableDigraphNC", [IsRecord]);
DeclareOperation("ConvertToMutableDigraphNC", [IsDenseList]);
DeclareOperation("MutableDigraphNC", [IsRecord]);
DeclareOperation("MutableDigraphNC", [IsDenseList]);

DeclareOperation("ConvertToImmutableDigraphNC", [IsRecord]);
DeclareOperation("ConvertToImmutableDigraphNC", [IsList]);
DeclareOperation("DigraphNC", [IsRecord]);
DeclareOperation("DigraphNC", [IsDenseList]);

# Copies
DeclareOperation("DigraphMutableCopy", [IsDigraph]);
DeclareOperation("DigraphCopy", [IsDigraph]);
DeclareSynonym("DigraphImmutableCopy", DigraphCopy);
DeclareOperation("DigraphCopyIfMutable", [IsDigraph]);
DeclareOperation("DigraphCopyIfImmutable", [IsDigraph]);

# Converter
DeclareOperation("MakeImmutableDigraph", [IsDigraph]);

# Constructors
DeclareOperation("MutableDigraph", [IsRecord]);
DeclareOperation("MutableDigraph", [IsDenseList]);
DeclareOperation("MutableDigraph", [IsList, IsFunction]);
DeclareOperation("MutableDigraph", [IsInt, IsList, IsList]);
DeclareOperation("MutableDigraph", [IsList, IsList, IsList]);

DeclareOperation("Digraph", [IsRecord]);
DeclareOperation("Digraph", [IsList]);
DeclareOperation("Digraph", [IsList, IsFunction]);
DeclareOperation("Digraph", [IsInt, IsList, IsList]);
DeclareOperation("Digraph", [IsList, IsList, IsList]);

# Constructors "by" something . . .
DeclareOperation("MutableDigraphByAdjacencyMatrix", [IsHomogeneousList]);
DeclareOperation("MutableDigraphByAdjacencyMatrixNC", [IsHomogeneousList]);

DeclareOperation("DigraphByAdjacencyMatrix", [IsHomogeneousList]);
DeclareOperation("DigraphByAdjacencyMatrixNC", [IsHomogeneousList]);

DeclareOperation("MutableDigraphByEdges", [IsRectangularTable]);
DeclareOperation("MutableDigraphByEdges", [IsRectangularTable, IsPosInt]);
DeclareOperation("MutableDigraphByEdges", [IsList and IsEmpty]);
DeclareOperation("MutableDigraphByEdges", [IsList and IsEmpty, IsPosInt]);

DeclareOperation("DigraphByEdges", [IsRectangularTable]);
DeclareOperation("DigraphByEdges", [IsRectangularTable, IsPosInt]);
DeclareOperation("DigraphByEdges", [IsList and IsEmpty]);
DeclareOperation("DigraphByEdges", [IsList and IsEmpty, IsPosInt]);

DeclareOperation("MutableDigraphByInNeighbours", [IsList]);
DeclareOperation("MutableDigraphByInNeighboursNC", [IsList]);

DeclareOperation("DigraphByInNeighbours", [IsList]);
DeclareOperation("DigraphByInNeighboursNC", [IsList]);

DeclareSynonym("MutableDigraphByInNeighbors", MutableDigraphByInNeighbours);
DeclareSynonym("DigraphByInNeighbors", DigraphByInNeighbours);

# Converters to and from other types . . .
DeclareOperation("AsMutableDigraph", [IsBinaryRelation]);
DeclareOperation("AsMutableDigraph", [IsTransformation]);
DeclareOperation("AsMutableDigraph", [IsTransformation, IsInt]);

DeclareOperation("AsDigraph", [IsBinaryRelation]);
DeclareOperation("AsDigraph", [IsTransformation]);
DeclareOperation("AsDigraph", [IsTransformation, IsInt]);

DeclareOperation("AsBinaryRelation", [IsDigraph]);
DeclareOperation("AsSemigroup", [IsFunction, IsDigraph]);
DeclareOperation("AsMonoid", [IsFunction, IsDigraph]);

DeclareConstructor("RandomDigraphCons", [IsDigraph, IsInt]);
DeclareConstructor("RandomDigraphCons", [IsDigraph, IsInt, IsRat]);
DeclareConstructor("RandomDigraphCons", [IsDigraph, IsInt, IsFloat]);

DeclareOperation("RandomDigraph", [IsInt]);
DeclareOperation("RandomDigraph", [IsInt, IsRat]);
DeclareOperation("RandomDigraph", [IsInt, IsFloat]);
DeclareOperation("RandomDigraph", [IsFunction, IsInt]);
DeclareOperation("RandomDigraph", [IsFunction, IsInt, IsRat]);
DeclareOperation("RandomDigraph", [IsFunction, IsInt, IsFloat]);

DeclareConstructor("RandomTournamentCons", [IsDigraph, IsInt]);
DeclareOperation("RandomTournament", [IsInt]);
DeclareOperation("RandomTournament", [IsFunction, IsInt]);

# No mutable analogues of the following because we will withdraw multidigraphs
# the not too distant future!
DeclareOperation("RandomMultiDigraph", [IsPosInt]);
DeclareOperation("RandomMultiDigraph", [IsPosInt, IsPosInt]);
