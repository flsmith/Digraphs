#include "src/schreier-sims.h"

// Schreier-Sims set up

static Perm * strong_gens[MAXVERTS];      // strong generators
static Perm   transversal[MAXVERTS * MAXVERTS];
static Perm   transversal_inv[MAXVERTS * MAXVERTS];
static bool   first_ever_call = true;
static UIntS  size_strong_gens[MAXVERTS];
static UIntS  orbits[MAXVERTS * MAXVERTS];
static UIntS  size_orbits[MAXVERTS];
static bool   borbits[MAXVERTS * MAXVERTS];
static UIntS  lmp;
static UIntS  base[MAXVERTS];
static UIntS  size_base;

static inline void add_strong_gens (UIntS const pos, Perm const value) {
  size_strong_gens[pos]++;
  strong_gens[pos] = realloc(strong_gens[pos], size_strong_gens[pos] * sizeof(Perm));
  strong_gens[pos][size_strong_gens[pos] - 1] = value;
}

static inline Perm get_strong_gens (UIntS const i, UIntS const j) {
  return strong_gens[i][j];
}

static inline Perm get_transversal (UIntS const i, UIntS const j) {
  return transversal[i * MAXVERTS + j];
}

static inline Perm get_transversal_inv (UIntS const i, UIntS const j) {
  return transversal_inv[i * MAXVERTS + j];
}

static inline void set_transversal (UIntS const i, UIntS const j, 
    Perm const value) {
  transversal[i * MAXVERTS + j] = value;
  transversal_inv[i * MAXVERTS + j] = invert_perm(value);
}

static bool perm_fixes_all_base_points ( Perm const x ) {
  UIntS i;

  for (i = 0; i < size_base; i++) {
    if (x[base[i]] != base[i]) {
      return false;
    }
  }
  return true;
}

static inline void add_base_point (UIntS const pt) {
  base[size_base] = pt;
  size_orbits[size_base] = 1;
  orbits[size_base * MAXVERTS] = pt;
  borbits[size_base * deg + pt] = true;
  set_transversal(size_base, pt, id_perm());
  size_base++;
}

static void remove_base_points (UIntS const depth) {
  UIntS i, j;

  assert( depth <= size_base );

  for (i = depth; i < size_base; i++) {
    size_base--;
    //free(strong_gens[i + 1]);
    size_strong_gens[i + 1] = 0;
    size_orbits[i] = 0;
    
    for (j = 0; j < deg; j++) {//TODO double-check deg!
      borbits[i * deg + j] = false;
    }
  }
}

static inline void first_ever_init () {
  UIntS i;

  first_ever_call = false;

  memset((void *) size_strong_gens, 0, MAXVERTS * sizeof(UIntS));
  memset((void *) size_orbits, 0, MAXVERTS * sizeof(UIntS));
}

static void init_stab_chain () {
  UIntS  i;

  if (first_ever_call) {
    first_ever_init();
  }

  memset((void *) borbits, false, deg * deg * sizeof(bool)); 
  size_base = 0;
}

static void init_endos_base_points() {
  UIntS  i;

  for (i = 0; i < deg - 1; i++) {
    add_base_point(i);
  }
}

static void free_stab_chain () {
  UIntS i;

  memset((void *) size_strong_gens, 0, size_base * sizeof(UIntS));
  memset((void *) size_orbits, 0, size_base * sizeof(UIntS));
}

static void orbit_stab_chain (UIntS const depth, UIntS const init_pt) {
  UIntS i, j, pt, img;
  Perm         x;

  assert( depth <= size_base ); // Should this be strict?

  for (i = 0; i < size_orbits[depth]; i++) {
    pt = orbits[depth * MAXVERTS + i];
    for (j = 0; j < size_strong_gens[depth]; j++) {
      x = get_strong_gens(depth, j);
      img = x[pt];
      if (! borbits[depth * deg + img]) {
        orbits[depth * MAXVERTS + size_orbits[depth]] = img;
        size_orbits[depth]++;
        borbits[depth * deg + img] = true;
        set_transversal(depth, img, prod_perms(get_transversal(depth, pt), x));
      }
    }
  }
}

static void add_gen_orbit_stab_chain (UIntS const depth, Perm const gen) {
  UIntS  i, j, pt, img;
  Perm          x;

  assert( depth <= size_base );

  // apply the new generator to existing points in orbits[depth]
  UIntS nr = size_orbits[depth];
  for (i = 0; i < nr; i++) {
    pt = orbits[depth * MAXVERTS + i];
    img = gen[pt];
    if (! borbits[depth * deg + img]) {
      orbits[depth * MAXVERTS + size_orbits[depth]] = img;
      size_orbits[depth]++;
      borbits[depth * deg + img] = true;
      set_transversal(depth, img, 
        prod_perms(get_transversal(depth, pt), gen));
    }
  }

  for (i = nr; i < size_orbits[depth]; i++) {
    pt = orbits[depth * MAXVERTS + i];
    for (j = 0; j < size_strong_gens[depth]; j++) {
      x = get_strong_gens(depth, j);
      img = x[pt];
      if (! borbits[depth * deg + img]) {
        orbits[depth * MAXVERTS + size_orbits[depth]] = img;
        size_orbits[depth]++;
        borbits[depth * deg + img] = true;
        set_transversal(depth, img, prod_perms(get_transversal(depth, pt), x));
      }
    }
  }
}

static void sift_stab_chain (Perm* g, UIntS* depth) {
  UIntS beta;

  assert(*depth == 0);
  
  for (; *depth < size_base; (*depth)++) {
    beta = (*g)[base[*depth]];
    if (! borbits[*depth * deg + beta]) {
      return;
    }
    prod_perms_in_place(*g, get_transversal_inv(*depth, beta));
  }
}

static void schreier_sims_stab_chain ( UIntS const depth ) {

  Perm          x, h, prod;
  bool          escape, y;
  int           i;
  UIntS  j, jj, k, l, m, beta, betax;

  for (i = 0; i < (int) size_base; i++) { 
    for (j = 0; j < size_strong_gens[i]; j++) { 
      x = get_strong_gens(i, j);
      if ( perm_fixes_all_base_points( x ) ) {
        for (k = 0; k < deg; k++) {
          if (k != x[k]) {
            add_base_point(k);
            break;
          }
        }
      }
    }
  }

  for (i = depth + 1; i < (int) size_base + 1; i++) {
    beta = base[i - 1];
    // set up the strong generators
    for (j = 0; j < size_strong_gens[i - 1]; j++) {
      x = get_strong_gens(i - 1, j);
      if (beta == x[beta]) {
        add_strong_gens(i, x);
      }
    }

    // find the orbit of <beta> under strong_gens[i - 1]
    orbit_stab_chain(i - 1, beta);
  }

  i = size_base - 1; // Unsure about this

  while (i >= (int) depth) {
    escape = false;
    for (j = 0; j < size_orbits[i] && !escape; j++) {
      beta = orbits[i * MAXVERTS + j];
      for (m = 0; m < size_strong_gens[i] && !escape; m++) {
        x = get_strong_gens(i, m);
        prod  = prod_perms(get_transversal(i, beta), x );
        betax = x[beta];
        if ( ! eq_perms(prod, get_transversal(i, betax)) ) {
          y = true;
          h = prod_perms(prod, get_transversal_inv(i, betax));
          jj = 0;
          sift_stab_chain(&h, &jj);
          if ( jj < size_base ) {
            y = false;
          } else if ( ! is_one(h) ) { // better method? IsOne(h)?
            y = false;
            for (k = 0; k < deg; k++) {
              if (k != h[k]) {
                add_base_point(k);
                break;
              }
            }
          }
    
          if ( !y ) {
            for (l = i + 1; l <= jj; l++) {
              add_strong_gens(l, h);
              add_gen_orbit_stab_chain(l, h);
              // add generator to <h> to orbit of base[l]
            }
            i = jj;
            escape = true;
          }
        }
      }
    }
    if (! escape) {
      i--;
    }
  }
  
}

extern PermColl point_stabilizer( PermColl const* genscoll, UIntS const pt, PermColl* outgens) {

  UIntS     i, len;
  
  init_stab_chain();

  // put gens into strong_gens[0]
  if (strong_gens[0] != NULL) {
    free(strong_gens[0]);
  }
  len = genscoll->nr_gens;
  strong_gens[0] = malloc(len * sizeof(Perm));
  memcpy(strong_gens[0], genscoll->gens, len * sizeof(Perm));
  size_strong_gens[0] = len;
  
  add_base_point(pt);
  schreier_sims_stab_chain(0);

  // the stabiliser we want is <strong_gens[1]>
  // store these new generators in the correct place in stab_gens that we want
  if ([depth + 1] != NULL) {
    free(stab_gens[depth + 1]);
  }
  len = size_strong_gens[1];  // number of new gens
  ptr = malloc(len * sizeof(Perm));
  memcpy(ptr, strong_gens[1], len * sizeof(Perm)); // set the new gens
  size_stab_gens[depth + 1] = len; // set the nr new gens
  // put everything in the struct

  free_stab_chain();
  return ptr;
}

/*static Obj size_stab_chain () {
  UIntS  i;
  Obj           tot;
  
  tot = INTOBJ_INT(1);
  for (i = 0; i < size_base; i++) {
    tot = ProdInt(tot, INTOBJ_INT((Int) size_orbits[i]));
  }
  return tot;
}

static Obj FuncC_STAB_CHAIN ( Obj self, Obj gens ) {
  Obj           size;
  UIntS  nrgens, i;

  deg = LargestMovedPointPermCollOld(gens);
  lmp = deg;
  init_stab_chain();
  nrgens = (UIntS) LEN_PLIST(gens);
  for (i = 1; i <= nrgens; i++) {
    add_strong_gens(0, as_perm(ELM_PLIST(gens, i)));
  }
  init_endos_base_points();
  schreier_sims_stab_chain(0);
  size = size_stab_chain();
  free_stab_chain();
  return size;
}

static Obj FuncSTAB( Obj self, Obj gens, Obj pt ) {
  UIntS  nrgens, i, len;
  Obj           out;

  deg = LargestMovedPointPermCollOld(gens);
  lmp_stab_gens[0] = deg;
  nrgens = (UIntS) LEN_PLIST(gens);
  size_stab_gens[0] = nrgens;
  stab_gens[0] = realloc( stab_gens[0], nrgens * sizeof(Perm));
  for (i = 0; i < nrgens; i++) {
    stab_gens[0][i] = as_perm(ELM_PLIST(gens, i + 1));
  }
  point_stabilizer( 0, ((UIntS) INT_INTOBJ(pt)) - 1 );
  len = size_stab_gens[1];
  out = NEW_PLIST(T_PLIST, (Int) len);
  SET_LEN_PLIST(out, (Int) len);
  for (i = 0; i < len; i++) {
    SET_ELM_PLIST(out, i + 1, as_PERM4(stab_gens[1][i]));
  }
  CHANGED_BAG(out);
  return out;
}
*/

