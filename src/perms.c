#include "src/perms.h"

static UIntS perm_buf[MAXVERTS]; //TODO remove this

void set_perms_degree (UIntS deg_arg) {
  deg = deg_arg;
}

PermColl* new_perm_coll (UIntS upper_bound) {
  PermColl* coll;
  Perm*   gens;

  gens = malloc(upper_bound * sizeof(Perm));
  coll->gens = gens;
  coll->nr_gens = 0;
  coll->deg = deg;
  coll->alloc_size = upper_bound;
  return coll;
}

// the generator is now controlled by the PermColl
PermColl* add_perm_coll (PermColl* coll, Perm gen) {

  assert(coll->nr_gens <= coll->alloc_size);

  if (coll->nr_gens == coll->alloc_size) {
    coll->gens = realloc(coll->gens, (coll->nr_gens + 1) * sizeof(Perm));
    (coll->alloc_size)++;
  }
  coll->gens[(coll->nr_gens)++] = gen;
  return coll;
}

PermColl* copy_perm_coll (PermColl* coll) {
  PermColl* out;
  UIntS     nr;
 
  nr = coll->nr_gens;
  out = new_perm_coll(nr);
  out->nr_gens = nr;
  memcpy( (void *) out->gens, coll->gens, nr * sizeof(Perm) );

  return out;
}

void free_perm_coll (PermColl* coll) {
  unsigned int i;
  
  if (coll->gens != NULL) {
    for (i = 0; i < coll->nr_gens; i++) {
      if (coll->gens[i] != NULL) {
        free(coll->gens[i]);
      }
    }
    free(coll->gens);
  }
  coll->nr_gens = 0;
  coll->alloc_size = 0;
}

extern Perm new_perm () {
  return malloc(deg * sizeof(UIntS));
}

 Perm id_perm () {
  UIntS i;
  Perm id = new_perm();
  for (i = 0; i < deg; i++) {
    id[i] = i;
  }
  return id;
}

 bool is_one (Perm x) {
  UIntS i;

  for (i = 0; i < deg; i++) {
    if (x[i] != i) {
      return false;
    }
  }
  return true;
}

 bool eq_perms (Perm x, Perm y) {
  UIntS i;

  for (i = 0; i < deg; i++) {
    if (x[i] != y[i]) {
      return false;
    }
  }
  return true;
}

 Perm prod_perms (Perm const x, Perm const y) {
  UIntS i;
  Perm z = new_perm();

  for (i = 0; i < deg; i++) {
    z[i] = y[x[i]];
  }
  return z;
}
// TODO remove 
 Perm quo_perms (Perm const x, Perm const y) {
  UIntS i;

  // invert y into the buf
  for (i = 0; i < deg; i++) {
    perm_buf[y[i]] = i;
  }
  return prod_perms(x, perm_buf);
}

// changes the lhs
// TODO remove
 void quo_perms_in_place (Perm x, Perm const y) {
  UIntS i;

  // invert y into the buf
  for (i = 0; i < deg; i++) {
    perm_buf[y[i]] = i;
  }

  for (i = 0; i < deg; i++) {
    x[i] = perm_buf[x[i]];
  }
}

 void prod_perms_in_place (Perm x, Perm const y) {
  UIntS i;

  for (i = 0; i < deg; i++) {
    x[i] = y[x[i]];
  }
}

 Perm invert_perm (Perm const x) {
  UIntS i;

  Perm y = new_perm();
  for (i = 0; i < deg; i++) {
    y[x[i]] = i;
  }
  return y;
}

/* UIntS* print_perm (perm x) {
  UIntS i;

  Pr("(", 0L, 0L);
  for (i = 0; i < deg; i++) {
    Pr("x[%d]=%d,", (Int) i, (Int) x[i]);
  }
  Pr(")\n", 0L, 0L);

}*/

/* UIntS IMAGE_PERM (UIntS const pt, Obj const perm) {

  if (TUIntL_OBJ(perm) == T_PERM2) {
    return (UIntS) IMAGE(pt, ADDR_PERM2(perm), DEG_PERM2(perm));
  } else if (TUIntL_OBJ(perm) == T_PERM4) {
    return (UIntS) IMAGE(pt, ADDR_PERM4(perm), DEG_PERM4(perm));
  } else {
    ErrorQuit("orbit_stab_chain: expected a perm, didn't get one", 0L, 0L);
  }
  return 0; // keep compiler happy!
}*/

/* UIntS LargestMovedPointPermCollOld (Obj const gens) {
  Obj           gen;
  UIntS  i, j;
  UInt2*        ptr2;
  UInt4*        ptr4;
  Int           nrgens = LEN_PLIST(gens);
  UIntS  max = 0;

  if (! IS_PLIST(gens)) {
    ErrorQuit("LargestMovedPointPermColl: expected a plist, didn't get one", 0L, 0L);
  }

  // get the largest moved point + 1
  for (i = 1; i <= (UIntS) nrgens; i++) {
    gen = ELM_PLIST(gens, i);
    if (TUIntL_OBJ(gen) == T_PERM2) {
      j = DEG_PERM2(gen);
      ptr2 = ADDR_PERM2(gen);
      while (j > max && ptr2[j - 1] == j - 1){
        j--;
      }
      if (j > max) {
        max = j;
      }
    } else if (TUIntL_OBJ(gen) == T_PERM4) {
      j = DEG_PERM4(gen);
      ptr4 = ADDR_PERM4(gen);
      while (j > max && ptr4[j - 1] == j - 1){
        j--;
      }
      if (j > max) {
        max = j;
      }
    } else {
      ErrorQuit("LargestMovedPointPermColl: expected a perm, didn't get one", 0L, 0L);
    }
  }

  return max;
}*/

/* UIntS largest_moved_point ( perm* const gens, UIntS const nrgens ) {
  perm          gen;
  UIntS  max = 0, i, j;

  for (i = 0; i < nrgens; i++) {
    gen = gens[i];
    j = deg;
    while ( j > max && gen[j - 1] == j - 1 ) {
      j--;
    }
    if (j > max) {
      max = j;
    }
  }
  return max;
}*/

