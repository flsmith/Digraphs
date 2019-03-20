#############################################################################
##
##  isomorph.gi
##  Copyright (C) 2014-18                                James D. Mitchell
##                                                          Wilf A. Wilson
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# This file contains methods using bliss or nauty, for computing isomorphisms,
# automorphisms, and canonical labellings of digraphs.

InstallGlobalFunction(DigraphsUseBliss,
function()
  # Just do nothing if NautyTracesInterface is not available.
  if DIGRAPHS_NautyAvailable then
    Info(InfoWarning,
         1,
         "Using bliss by default for AutomorphismGroup . . .");
    if not DIGRAPHS_UsingBliss then
      InstallMethod(AutomorphismGroup, "for a digraph", [IsDigraph],
      BlissAutomorphismGroup);
      MakeReadWriteGlobal("DIGRAPHS_UsingBliss");
      DIGRAPHS_UsingBliss := true;
      MakeReadOnlyGlobal("DIGRAPHS_UsingBliss");
    fi;
  fi;
end);

InstallGlobalFunction(DigraphsUseNauty,
function()
  if DIGRAPHS_NautyAvailable then
    if DIGRAPHS_UsingBliss then
      InstallMethod(AutomorphismGroup, "for a digraph", [IsDigraph],
      NautyAutomorphismGroup);
      MakeReadWriteGlobal("DIGRAPHS_UsingBliss");
      DIGRAPHS_UsingBliss := false;
      MakeReadOnlyGlobal("DIGRAPHS_UsingBliss");
    fi;
    Info(InfoWarning,
         1,
         "Using nauty by default for AutomorphismGroup . . .");
  else
    Info(InfoWarning,
         1,
         "NautyTracesInterface is not available!");
    Info(InfoWarning,
         1,
         "Using bliss by default for AutomorphismGroup . . .");
  fi;
end);

# Wrappers for the C-level functions

## The argument <colors> should be a coloring of type 1, as described before
## ValidateVertexColouring in isomorph.gd.
##
## Returns a list where the first position is the automorphism group, and the
## second is the canonical labelling.
#BindGlobal("BLISS_DATA",
#function(digraph, colors, calling_function_name)
#  local data;
#  if colors <> false then
#    colors := DIGRAPHS_ValidateVertexColouring(DigraphNrVertices(digraph),
#                                               colors,
#                                               calling_function_name);
#  fi;
#  if IsMultiDigraph(digraph) then
#    data := MULTIDIGRAPH_AUTOMORPHISMS(digraph, colors);
#    if IsEmpty(data[1]) then
#      data[1] := [()];
#    fi;
#    # Note that data[3] cannot ever be empty since there are multiple edges,
#    # and since they are indistinguishable, they can be swapped by an
#    # automorphism.
#    data[1] := DirectProduct(Group(data[1]), Group(data[3]));
#    return data;
#  else
#    data := DIGRAPH_AUTOMORPHISMS(digraph,
#                                  colors,
#                                  fail,
#                                  DIGRAPHS_HasSymmetricPair(digraph,
#                                                            colors,
#                                                            fail));
#    if IsEmpty(data[1]) then
#      data[1] := [()];
#    fi;
#    data[1] := Group(data[1]);
#  fi;
#

BindGlobal("BLISS_DATA",
function(D, vert_colours, edge_colours, calling_function_name)
  local orientation_double, validated, data;
  orientation_double := false;
  if vert_colours <> fail then
    vert_colours := DIGRAPHS_ValidateVertexColouring(DigraphNrVertices(D),
                                               vert_colours,
                                               calling_function_name);
  fi;

  # note that this might change the edge colouring to be valid to feed to the
  # C function, in particular if there is an edge and reverse edge sharing a
  # colour or if there are multiple edges with the same source, range, and
  # colour
  validated := DIGRAPHS_ValidateEdgeColouring(D,
                                              vert_colours,
                                              edge_colours);
  D := validated[1];
  orientation_double := validated[2];

  data := DIGRAPH_AUTOMORPHISMS(D,
                                vert_colours,
                                edge_colours,
                                orientation_double);

  if IsEmpty(data[1]) then
    data[1] := [()];
  fi;
  data[1] := Group(data[1]);

  return data;
end);

BindGlobal("BLISS_DATA_NO_COLORS",
function(D)
  return BLISS_DATA(D, fail, fail, "");
end);

if DIGRAPHS_NautyAvailable then
  BindGlobal("NAUTY_DATA",
  function(D, colors)
    local data;
    if colors <> false then
      colors := DIGRAPHS_ValidateVertexColouring(DigraphNrVertices(D),
                                                 colors);
      colors := NautyColorData(colors);
    fi;
    if DigraphNrVertices(D) = 0 then
      # This circumvents Issue #17 in NautyTracesInterface, whereby a graph
      # with 0 vertices causes a seg fault.
      return [Group(()), ()];
    fi;
    data := NautyDense(DigraphSource(D),
                       DigraphRange(D),
                       DigraphNrVertices(D),
                       not IsSymmetricDigraph(D),
                       colors);
    if IsEmpty(data[1]) then
      data[1] := [()];
    fi;
    data[1] := Group(data[1]);
    data[2] := data[2] ^ -1;
    return data;
  end);

  BindGlobal("NAUTY_DATA_NO_COLORS",
  function(D)
    return NAUTY_DATA(D, false);
  end);
else
  BindGlobal("NAUTY_DATA", ReturnFail);
  BindGlobal("NAUTY_DATA_NO_COLORS", ReturnFail);
fi;

# Canonical labellings

InstallMethod(BlissCanonicalLabelling, "for a digraph",
[IsDigraph],
function(D)
  local data;
  IsValidDigraph(D);
  data := BLISS_DATA_NO_COLORS(D);
  SetBlissAutomorphismGroup(D, data[1]);
  return data[2];
end);

InstallMethod(BlissCanonicalLabelling, "for a digraph and vertex coloring",
[IsDigraph, IsHomogeneousList],
function(D, colors)
  IsValidDigraph(D);
  return BLISS_DATA(D,
                    colors,
                    fail,
                    "BlissCanonicalLabelling")[2];
end);

InstallMethod(NautyCanonicalLabelling, "for a digraph",
[IsDigraph],
function(D)
  local data;
  if not DIGRAPHS_NautyAvailable or IsMultiDigraph(D) then
    Info(InfoWarning, 1, "NautyTracesInterface is not available");
    return fail;
  fi;
  IsValidDigraph(D);
  data := NAUTY_DATA_NO_COLORS(D);
  SetNautyAutomorphismGroup(D, data[1]);
  return data[2];
end);

InstallMethod(NautyCanonicalLabelling,
"for a digraph and vertex coloring",
[IsDigraph, IsHomogeneousList],
function(D, colors)
  if not DIGRAPHS_NautyAvailable or IsMultiDigraph(D) then
    Info(InfoWarning, 1, "NautyTracesInterface is not available");
    return fail;
  fi;
  IsValidDigraph(D);
  return NAUTY_DATA(D, colors)[2];
end);

# Canonical digraphs

InstallMethod(BlissCanonicalDigraph, "for a digraph", [IsDigraph],
function(D)
  if IsMultiDigraph(D) then
    return OnMultiDigraphs(D, BlissCanonicalLabelling(D));
  fi;
  return OnDigraphs(D, BlissCanonicalLabelling(D));
end);

InstallMethod(BlissCanonicalDigraph, "for a digraph and vertex coloring",
[IsDigraph, IsHomogeneousList],
function(D, colors)
  if IsMultiDigraph(D) then
    return OnMultiDigraphs(D, BlissCanonicalLabelling(D, colors));
  fi;
  return OnDigraphs(D, BlissCanonicalLabelling(D, colors));
end);

InstallMethod(NautyCanonicalDigraph, "for a digraph", [IsDigraph],
function(D)
  if not DIGRAPHS_NautyAvailable or IsMultiDigraph(D) then
    Info(InfoWarning, 1, "NautyTracesInterface is not available");
    return fail;
  fi;
  IsValidDigraph(D);
  return OnDigraphs(D, NautyCanonicalLabelling(D));
end);

InstallMethod(NautyCanonicalDigraph, "for a digraph and vertex coloring",
[IsDigraph, IsHomogeneousList],
function(D, colors)
  if not DIGRAPHS_NautyAvailable or IsMultiDigraph(D) then
    Info(InfoWarning, 1, "NautyTracesInterface is not available");
    return fail;
  fi;
  IsValidDigraph(D);
  return OnDigraphs(D, NautyCanonicalLabelling(D, colors));
end);

# Automorphism group

InstallMethod(BlissAutomorphismGroup, "for a digraph", [IsDigraph],
function(D)
  local data;
  IsValidDigraph(D);
  data := BLISS_DATA_NO_COLORS(D);
  SetBlissCanonicalLabelling(D, data[2]);
  if not HasDigraphGroup(D) then
    if IsMultiDigraph(D) then
      SetDigraphGroup(D, Range(Projection(data[1], 1)));
    else
      SetDigraphGroup(D, data[1]);
    fi;
  fi;
  return data[1];
end);

InstallMethod(NautyAutomorphismGroup, "for a digraph", [IsDigraph],
function(D)
  local data;
  if not DIGRAPHS_NautyAvailable or IsMultiDigraph(D) then
    Info(InfoWarning, 1, "NautyTracesInterface is not available");
    return fail;
  fi;
  IsValidDigraph(D);

  data := NAUTY_DATA_NO_COLORS(D);
  SetNautyCanonicalLabelling(D, data[2]);
  if not HasDigraphGroup(D) then
    # Multidigraphs not allowed
    SetDigraphGroup(D, data[1]);
  fi;
  return data[1];
end);

InstallMethod(BlissAutomorphismGroup, "for a digraph and vertex coloring",
[IsDigraph, IsHomogeneousList],
function(D, colors)
  return BLISS_DATA(D,
                    colors,
                    fail,
                    "AutomorphismGroup")[1];
end);

InstallMethod(BlissEdgeColouredAutomorphismGroup, "for a digraph",
[IsDigraph, IsHomogeneousList, IsList],
function(digraph, vert_colours, edge_colours)
  return BLISS_DATA(digraph,
                    vert_colours,
                    edge_colours,
                    "AutomorphismGroup")[1];
end);

InstallMethod(NautyAutomorphismGroup, "for a digraph and vertex coloring",
[IsDigraph, IsHomogeneousList],
function(D, colors)
  if not DIGRAPHS_NautyAvailable or IsMultiDigraph(D) then
    Info(InfoWarning, 1, "NautyTracesInterface is not available");
    return fail;
  fi;
  IsValidDigraph(D);
  return NAUTY_DATA(D, colors)[1];
end);

InstallMethod(AutomorphismGroup, "for a digraph", [IsDigraph],
BlissAutomorphismGroup);

InstallMethod(AutomorphismGroup, "for a digraph and vertex coloring",
[IsDigraph, IsHomogeneousList], BlissAutomorphismGroup);

InstallMethod(AutomorphismGroup, "for a digraph, vertex and edge coloring",
[IsDigraph, IsHomogeneousList, IsList], BlissEdgeColouredAutomorphismGroup);

InstallMethod(AutomorphismGroup, "for a multidigraph", [IsMultiDigraph],
BlissAutomorphismGroup);

InstallMethod(AutomorphismGroup, "for a multidigraph and vertex coloring",
[IsMultiDigraph, IsHomogeneousList], BlissAutomorphismGroup);

# Check if two digraphs are isomorphic

InstallMethod(IsIsomorphicDigraph, "for digraphs", [IsDigraph, IsDigraph],
function(C, D)
  local act;

  IsValidDigraph(C, D);
  if C = D then
    return true;
  elif DigraphNrVertices(C) <> DigraphNrVertices(D)
      or DigraphNrEdges(C) <> DigraphNrEdges(D)
      or IsMultiDigraph(C) <> IsMultiDigraph(D) then
    return false;
  fi;  # JDM more!

  if IsMultiDigraph(C) then
    act := OnMultiDigraphs;
  else
    act := OnDigraphs;
  fi;

  if HasBlissCanonicalLabelling(C) and HasBlissCanonicalLabelling(D)
      or not ((HasNautyCanonicalLabelling(C)
               and NautyCanonicalLabelling(C) <> fail)
              or (HasNautyCanonicalLabelling(D)
                  and NautyCanonicalLabelling(D) <> fail)) then
    # Both digraphs either know their bliss canonical labelling or
    # neither know their Nauty canonical labelling.
    return act(C, BlissCanonicalLabelling(C))
           = act(D, BlissCanonicalLabelling(D));
  else
    return act(C, NautyCanonicalLabelling(C))
           = act(D, NautyCanonicalLabelling(D));
  fi;

end);

InstallMethod(IsIsomorphicDigraph, "for digraphs and homogeneous lists",
[IsDigraph, IsDigraph, IsHomogeneousList, IsHomogeneousList],
function(C, D, c1, c2)
  local m, colour1, n, colour2, max, class_sizes, act, i;
  IsValidDigraph(C, D);
  m := DigraphNrVertices(C);
  colour1 := DIGRAPHS_ValidateVertexColouring(m, c1);
  n := DigraphNrVertices(D);
  colour2 := DIGRAPHS_ValidateVertexColouring(n, c2);

  max := Maximum(colour1);
  if max <> Maximum(colour2) then
    return false;
  fi;

  # check some invariants
  if m <> n
      or DigraphNrEdges(C) <> DigraphNrEdges(D)
      or IsMultiDigraph(C) <> IsMultiDigraph(D) then
    return false;
  fi;  # JDM more!

  class_sizes := ListWithIdenticalEntries(max, 0);
  for i in DigraphVertices(C) do
    class_sizes[colour1[i]] := class_sizes[colour1[i]] + 1;
    class_sizes[colour2[i]] := class_sizes[colour2[i]] - 1;
  od;
  if not ForAll(class_sizes, x -> x = 0) then
    return false;
  elif C = D and colour1 = colour2 then
    return true;
  fi;

  if IsMultiDigraph(C) then
    act := OnMultiDigraphs;
  else
    act := OnDigraphs;
  fi;

  if DIGRAPHS_UsingBliss or IsMultiDigraph(C) then
    return act(C, BlissCanonicalLabelling(C, colour1))
           = act(D, BlissCanonicalLabelling(D, colour2));
  else
    return act(C, NautyCanonicalLabelling(C, colour1))
           = act(D, NautyCanonicalLabelling(D, colour2));
  fi;
end);

# Isomorphisms between digraphs

InstallMethod(IsomorphismDigraphs, "for digraphs", [IsDigraph, IsDigraph],
function(C, D)
  local label1, label2;
  IsValidDigraph(C, D);

  if not IsIsomorphicDigraph(C, D) then
    return fail;
  elif IsMultiDigraph(C) then
    if C = D then
      return [(), ()];
    fi;
    label1 := BlissCanonicalLabelling(C);
    label2 := BlissCanonicalLabelling(D);
    return [label1[1] / label2[1], label1[2] / label2[2]];
  elif C = D then
    return ();
  fi;

  if HasBlissCanonicalLabelling(C) and HasBlissCanonicalLabelling(D)
      or not ((HasNautyCanonicalLabelling(C)
               and NautyCanonicalLabelling(C) <> fail)
              or (HasNautyCanonicalLabelling(D)
                  and NautyCanonicalLabelling(D) <> fail)) then
    # Both digraphs either know their bliss canonical labelling or
    # neither know their Nauty canonical labelling.
    return BlissCanonicalLabelling(C) / BlissCanonicalLabelling(D);
  else
    return NautyCanonicalLabelling(C) / NautyCanonicalLabelling(D);
  fi;
end);

InstallMethod(IsomorphismDigraphs, "for digraphs and homogeneous lists",
[IsDigraph, IsDigraph, IsHomogeneousList, IsHomogeneousList],
function(C, D, c1, c2)
  local m, colour1, n, colour2, max, class_sizes, label1, label2, i;
  IsValidDigraph(C, D);

  m := DigraphNrVertices(C);
  colour1 := DIGRAPHS_ValidateVertexColouring(m, c1);
  n := DigraphNrVertices(D);
  colour2 := DIGRAPHS_ValidateVertexColouring(n, c2);

  max := Maximum(colour1);
  if max <> Maximum(colour2) then
    return fail;
  fi;

  # check some invariants
  if m <> n
      or DigraphNrEdges(C) <> DigraphNrEdges(D)
      or IsMultiDigraph(C) <> IsMultiDigraph(D) then
    return fail;
  fi;

  class_sizes := ListWithIdenticalEntries(max, 0);
  for i in DigraphVertices(C) do
    class_sizes[colour1[i]] := class_sizes[colour1[i]] + 1;
    class_sizes[colour2[i]] := class_sizes[colour2[i]] - 1;
  od;
  if not ForAll(class_sizes, x -> x = 0) then
    return fail;
  elif C = D and colour1 = colour2 then
    if IsMultiDigraph(C) then
      return [(), ()];
    fi;
    return ();
  fi;

  if DIGRAPHS_UsingBliss or IsMultiDigraph(C) then
    label1 := BlissCanonicalLabelling(C, colour1);
    label2 := BlissCanonicalLabelling(D, colour2);
  else
    label1 := NautyCanonicalLabelling(C, colour1);
    label2 := NautyCanonicalLabelling(D, colour2);
  fi;

  if IsMultiDigraph(C) then
    if OnMultiDigraphs(C, label1) <> OnMultiDigraphs(D, label2) then
      return fail;
    fi;
    return [label1[1] / label2[1], label1[2] / label2[2]];
  fi;

  if OnDigraphs(C, label1) <> OnDigraphs(D, label2) then
    return fail;
  fi;
  return label1 / label2;
end);

# Given a non-negative integer <n> and a homogeneous list <partition>,
# this global function tests whether <partition> is a valid partition
# of the list [1 .. n]. A valid partition of [1 .. n] is either:
#
# 1. A list of length <n> consisting of a numbers, such that the set of these
#    numbers is [1 .. m] for some m <= n.
# 2. A list of non-empty disjoint lists whose union is [1 .. n].
#
# If <partition> is a valid partition of [1 .. n] then this global function
# returns the partition, in form 1 (converting it to this form if necessary).
# If <partition> is invalid, then the function returns <fail>.

InstallGlobalFunction(DIGRAPHS_ValidateVertexColouring,
function(n, partition)
  local colours, i, missing, seen, x;

  if not IsInt(n) or n < 0 then
    ErrorNoReturn("the 1st argument <n> must be a non-negative integer,");
  elif not IsHomogeneousList(partition) then
    ErrorNoReturn("the 2nd argument <partition> must be a homogeneous list,");
  elif n = 0 then
    if IsEmpty(partition) then
      return partition;
    fi;
    ErrorNoReturn("the only valid partition of the vertices of the digraph ",
                  "with 0 vertices is the empty list,");
  elif not IsEmpty(partition) then
    if IsPosInt(partition[1]) and Length(partition) = n then
      # <partition> seems to be a list of colours
      colours := [];
      for i in partition do
        if not IsPosInt(i) then
          ErrorNoReturn("the 2nd argument <partition> does not define a ",
                        "colouring of the vertices [1 .. ", n, "], since it ",
                        "contains the element ", i, ", which is not a ",
                        "positive integer,");
        elif i > n then
          ErrorNoReturn("the 2nd argument <partition> does not define ",
                        "a colouring of the vertices [1 .. ", n, "], since ",
                        "it contains the integer ", i,
                        ", which is greater than ", n, ",");
        fi;
        AddSet(colours, i);
      od;
      i := Length(colours);
      missing := Difference([1 .. i], colours);
      if not IsEmpty(missing) then
        ErrorNoReturn("the 2nd argument <partition> does not define a ",
                      "colouring ",
                      "of the vertices [1 .. ", n, "], since it contains the ",
                      "colour ", colours[i], ", but it lacks the colour ",
                      missing[1], ". A colouring must use precisely the ",
                      "colours [1 .. m], for some positive integer m <= ", n,
                      ",");
      fi;
      return partition;
    elif IsList(partition[1]) then
      seen := BlistList([1 .. n], []);
      colours := EmptyPlist(n);
      for i in [1 .. Length(partition)] do
        # guaranteed to be non-empty since <partition> is homogeneous
        for x in partition[i] do
          if not IsPosInt(x) or x > n then
            ErrorNoReturn("the 2nd argument <partition> does not define a ",
                          "colouring of the vertices [1 .. ", n, "], since ",
                          "the entry in position ", i, " contains ", x,
                          " which is not an integer in the range [1 .. ", n,
                          "],");
          elif seen[x] then
            ErrorNoReturn("the 2nd argument <partition> does not define a ",
                          "colouring of the vertices [1 .. ", n, "], since ",
                          "it contains the vertex ", x, " more than once,");
          fi;
          seen[x] := true;
          colours[x] := i;
        od;
      od;
      i := First([1 .. n], x -> not seen[x]);
      if i <> fail then
        ErrorNoReturn("the 2nd argument <partition> does not define a ",
                      "colouring of the vertices [1 .. ", n, "], since ",
                      "it does not assign a colour to the vertex ", i, ",");
      fi;
      return colours;
    fi;
  fi;
  ErrorNoReturn("the 2nd argument <partition> does not define a ",
                "colouring of the vertices [1 .. ", n, "]. The 2nd ",
                "argument must have one of the following forms: ",
                "1. a list of length ", n, " consisting of ",
                "every integer in the range [1 .. m], for some m <= ", n,
                "; or 2. a list of non-empty disjoint lists ",
                "whose union is [1 .. ", n, "].");
end);

InstallGlobalFunction(DIGRAPHS_HasSymmetricPair,
function(graph, vertex_colouring, edge_colouring)
  local n, collected, j, adj, adj_colours, i, edge_mult;
  
  n := DigraphNrVertices(graph);
  if edge_colouring = fail then
    collected := [];
    for i in [1 .. DigraphNrVertices(graph)] do
      Add(collected, Collected(OutNeighbours(graph)[i]));
      for edge_mult in collected[i] do
        j := edge_mult[1];
        if j < i then
          if vertex_colouring <> fail and
             vertex_colouring[i] <> vertex_colouring[j] then 
            continue;
          fi;
          if [i, edge_mult[2]] in collected[j] then
            return true;
          fi;
        fi;
      od;
    od;
    return false;
  fi;

  # TODO: this does not check if the colours on the vertices are different

  adj := OutNeighbours(graph);
  adj_colours := List([1 .. n], 
                      x -> List([1 .. n],
                                y -> edge_colouring[x]{Positions(adj[x], y)}));

  # TODO: document this properly
  return ForAny([1 .. n],
                i -> ForAny(PositionsProperty(adj_colours[i], 
                                              x-> not IsEmpty(x)),
                            j -> i <> j and
                                  adj_colours[i][j] <> adj_colours[j][i]));


end);

InstallGlobalFunction(DIGRAPHS_ValidateEdgeColouring,
function(graph, vert_colouring, edge_colouring)
  local n, colours, m, adji, orientation_double, adj_colours, i, j, k;
  
  # Check: shapes and values from [1 .. something]
  if edge_colouring = fail then
    if IsMultiDigraph(graph) then
      ErrorNoReturn("multidigraphs with two edges with the same source, ",
                    "range, and colour are not allowed");
    else
      return [graph,
              DIGRAPHS_HasSymmetricPair(graph, vert_colouring, fail)];
    fi;
  fi;

  if not IsDigraph(graph) then
    ErrorNoReturn("the 1st argument must be a digraph");
  fi;
  n := DigraphNrVertices(graph);
  if not IsList(edge_colouring) or Length(edge_colouring) <> n then
    ErrorNoReturn("the 2nd argument must be a list of the same shape as ",
                  "OutNeighbours(graph), where graph is the 1st argument");
  fi;
  if ForAny(DigraphVertices(graph), x -> not IsList(edge_colouring[x]) or
                                         (Length(edge_colouring[x]) <>
                                          Length(OutNeighbours(graph)[x]))) then
    ErrorNoReturn("the 2nd argument must be a list of the same shape as ",
                  "OutNeighbours(graph), where graph is the 1st argument");
  fi;

  colours := [];
  for adj_colours in edge_colouring do
    for i in adj_colours do
      if not IsPosInt(i) then
        ErrorNoReturn("the 2nd argument should be a list of lists of ",
                      "positive integers");
      fi;
      AddSet(colours, i);
    od;
  od;
  m := Length(colours);
  if ForAny([1 .. m], i -> i <> colours[i]) then
    ErrorNoReturn("the 2nd argument should be a list of lists whose union ",
                   "is [1 .. number of colours]");
  fi;
  
  # check that no two edges share source, range, colour
  for i in [1 .. n] do
    adji := OutNeighbours(graph)[i];
    for j in [1 .. Length(adji)] do
      for k in [j + 1 .. Length(adji)] do
        if adji[j] = adji[k] and
            edge_colouring[i][j] = edge_colouring[i][k] then
          ErrorNoReturn("multidigraphs with two edges with the same source, ",
                        "range, and colour are not allowed");
        fi;
      od;
    od;
  od;
  
  orientation_double := DIGRAPHS_HasSymmetricPair(graph,
                                                  vert_colouring,
                                                  edge_colouring);
  return [graph, orientation_double];

  # Are there multiple edges with the same source, range, colour? Fix them.
  # For each colour, count how many different multiplicities of multiple edges
  # occur, then replace these multiple edges with a single edge of a new colour

  # if IsMultiDigraph(graph) then
  #   map := List([1 .. m], x -> []);
  #   for i in DigraphVertices(graph) do
  #     adji := OutNeighboursOfVertex(graph, i);
  #     coli := edge_colouring[i];
  #     for x in Collected(List([1 .. Length(adji)], j -> [adji[j], coli[j]])) do
  #       range  := x[1][1];
  #       colour := x[1][2];
  #       mult   := x[2];
  #       if not IsBound(map[colour][mult]) then
  #         map[colour][mult] := [];
  #       fi;
  #       Add(map[colour][mult], [i, range]);
  #     od;
  #   od;

  #   # TODO: what is happening here?
  #   if ForAny(map, x -> Length(x) <> 1) then
  #     new_edge_colouring := List([1 .. n], x -> []);
  #     new_adj_list := List([1 .. n], x -> []);
  #     count := m + 1;
  #     for colour in [1 .. m] do
  #       seen_first := false;
  #       for mult in PositionsProperty(map[colour], x -> IsBound(x)) do
  #         for edge in map[colour][mult] do
  #           Add(new_adj_list[edge[1]], edge[2]);
  #           if seen_first then
  #             Add(new_edge_colouring[edge[1]], count);
  #           else
  #             Add(new_edge_colouring[edge[1]], colour);
  #           fi;
  #         od;
  #         if not seen_first then
  #           count := count + 1;
  #         fi;
  #         seen_first := true;
  #       od;
  #     od;
  #     graph := Digraph(new_adj_list);
  #   else
  #     new_adj_list := OutNeighbours(graph);
  #     new_edge_colouring := edge_colouring;
  #   fi;
  # else
  #   new_adj_list := OutNeighbours(graph);
  #   new_edge_colouring := edge_colouring;
  # fi;

  # Is there an edge and reverse edge with same colour?
  # TODO: this isn't quite what we care about

  #  map_colour_to_count := List([1 .. n], -1);
  #  bigger_adj_cols := List([1 .. n], List([1 .. n], []));
  #  for i in [1 .. n] do
  #    for j in [1 .. Length(new_adj_list)] do
  #      w := new_adj_list[i][j];
  #      colour := new_edge_colouring[i][j];
  #      if w > i then
  #        bigger_adj_cols[i][w][colour] := j;
  #      elif w < i then
  #        if IsBound(bigger_adj_cols[w][i][colour]) then
  #          if map_colour_to_count[colour] = -1 then
  #            map_colour_to_count[colour] := count;
  #            count := count + 1;
  #          fi;
  #          new_edge_colouring[i][j] := map_colour_to_count[colour];
  #        fi;
  #      fi;
  #    od;
  #  od;

  # TODO: we can probably improve this by looking at whether these vertices
  # actually can be swapped - if not, don't bother!

  # adj_colours := List([1 .. n], x -> []);
  # for i in [1 .. n] do
  #   for j in [1 .. Length(new_adj_list[i])] do
  #     w := new_adj_list[i][j];
  #     if not IsBound(adj_colours[i][w]) then
  #       adj_colours[i][w] := [];
  #     fi;
  #     AddSet(adj_colours[i][w], new_edge_colouring[i][j]);
  #   od;
  # od;

end);

InstallMethod(IsDigraphIsomorphism, "for digraph, digraph, and permutation",
[IsDigraph, IsDigraph, IsPerm],
function(src, ran, x)
  if IsMultiDigraph(src) or IsMultiDigraph(ran) then
    ErrorNoReturn("the 1st and 2nd arguments <src> and <ran> must not have ",
                  "multiple edges,");
  fi;
  IsValidDigraph(src, ran);
  return IsDigraphHomomorphism(src, ran, x)
    and IsDigraphHomomorphism(ran, src, x ^ -1);
end);

InstallMethod(IsDigraphAutomorphism, "for a digraph and a permutation",
[IsDigraph, IsPerm],
function(D, x)
  IsValidDigraph(D);
  return IsDigraphIsomorphism(D, D, x);
end);

InstallMethod(IsDigraphIsomorphism, "for digraph, digraph, and transformation",
[IsDigraph, IsDigraph, IsTransformation],
function(src, ran, x)
  local y;
  IsValidDigraph(src, ran);
  y := AsPermutation(RestrictedTransformation(x, DigraphVertices(src)));
  if y = fail then
    return false;
  fi;
  return IsDigraphIsomorphism(src, ran, y);
end);

InstallMethod(IsDigraphAutomorphism, "for a digraph and a transformation",
[IsDigraph, IsTransformation],
function(D, x)
  IsValidDigraph(D);
  return IsDigraphIsomorphism(D, D, x);
end);
