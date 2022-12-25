module LanguageDef.PolyProfunctor

import Library.IdrisUtils
import Library.IdrisCategories
import public LanguageDef.Atom
import public LanguageDef.PolyCat

%default total

-----------------------------------------------------------------
-----------------------------------------------------------------
---- Polynomial functors from arbitrary categories to `Type` ----
-----------------------------------------------------------------
-----------------------------------------------------------------

-----------------------------------------------------------------
---- `Type`-object-dependent objects of arbitrary categories ----
-----------------------------------------------------------------

-- An object of an arbitrary category dependent on a type in `Type`.
-- This may be seen as the directions-map of an arena where the directions
-- may be drawn from an arbitrary category, not just `Type` (the positions
-- are drawn from `Type`).
public export
DirMap : CatSig -> Type -> Type
DirMap dom pos = pos -> catObj dom

public export
TypeArena : CatSig -> Type
TypeArena = DPair Type . DirMap

public export
taPos : {cat : CatSig} -> TypeArena cat -> Type
taPos = DPair.fst

public export
taDir : {cat : CatSig} -> (ar : TypeArena cat) -> taPos {cat} ar -> cat.catObj
taDir = DPair.snd

-- Interpret a dependent object as a covariant polynomial functor.
public export
PolyMap : (cat : CatSig) -> {pos : Type} ->
  DirMap cat pos -> cat.catObj -> Type
PolyMap cat {pos} dir a = (i : pos ** cat.catMorph (dir i) a)

public export
PolyFMap : {cat : CatSig} -> {pos : Type} ->
  (dir : DirMap cat pos) -> {a, b : cat.catObj} ->
  cat.catMorph a b -> PolyMap cat dir a -> PolyMap cat dir b
PolyFMap {cat} {pos} dir {a} {b} f (i ** d) = (i ** cat.catComp f d)

-- Interpret a dependent object as a contravariant polynomial functor --
-- AKA a "Dirichlet functor".  (This means a functor from the opposite
-- category of `cat` to `Type`.)
public export
DirichMap : (cat : CatSig) -> {pos : Type} ->
  DirMap cat pos -> cat.catObj -> Type
DirichMap cat {pos} dir a = (i : pos ** cat.catMorph a (dir i))

public export
DirichFMap : {cat : CatSig} -> {pos : Type} ->
  (dir : DirMap cat pos) -> {a, b : cat.catObj} ->
  cat.catMorph b a -> DirichMap cat dir a -> DirichMap cat dir b
DirichFMap {cat} {pos} dir {a} {b} f (i ** d) = (i ** cat.catComp d f)

---------------------------------------------------------------------------
---- Natural transformations between `Type`-valued polynomial functors ----
---------------------------------------------------------------------------

public export
TAPolyNT : {cat : CatSig} -> (p, q : TypeArena cat) -> Type
TAPolyNT {cat} p q =
  (onPos : taPos p -> taPos q **
   (i : taPos p) -> cat.catMorph (taDir q (onPos i)) (taDir p i))

public export
taPntOnPos : {cat : CatSig} -> {p, q : TypeArena cat} -> TAPolyNT {cat} p q ->
  taPos {cat} p -> taPos {cat} q
taPntOnPos = DPair.fst

public export
taPntOnDir : {cat : CatSig} -> {p, q : TypeArena cat} ->
  (alpha : TAPolyNT {cat} p q) ->
  (i : taPos {cat} p) ->
  cat.catMorph
    (taDir {cat} q (taPntOnPos {cat} {p} {q} alpha i))
    (taDir {cat} p i)
taPntOnDir = DPair.snd

public export
TADirichNT : {cat : CatSig} -> (p, q : TypeArena cat) -> Type
TADirichNT {cat} p q =
  (onPos : taPos p -> taPos q **
   (i : taPos p) -> cat.catMorph (taDir p i) (taDir q (onPos i)))

public export
taDntOnPos : {cat : CatSig} -> {p, q : TypeArena cat} -> TADirichNT {cat} p q ->
  taPos {cat} p -> taPos {cat} q
taDntOnPos = DPair.fst

public export
taDntOnDir : {cat : CatSig} -> {p, q : TypeArena cat} ->
  (alpha : TADirichNT {cat} p q) ->
  (i : taPos {cat} p) ->
  cat.catMorph
    (taDir {cat} p i)
    (taDir {cat} q (taDntOnPos {cat} {p} {q} alpha i))
taDntOnDir = DPair.snd

public export
PolyNTApp : {cat : CatSig} -> {p, q : TypeArena cat} ->
   TAPolyNT {cat} p q -> (a : cat.catObj) ->
  PolyMap cat {pos=(taPos {cat} p)} (taDir {cat} p) a ->
  PolyMap cat {pos=(taPos {cat} q)} (taDir {cat} q) a
PolyNTApp {cat} {p} {q} alpha a (i ** d) =
  (taPntOnPos alpha i ** cat.catComp d (taPntOnDir alpha i))

public export
DirichNTApp : {cat : CatSig} -> {p, q : TypeArena cat} ->
  TADirichNT {cat} p q -> (a : cat.catObj) ->
  DirichMap cat {pos=(taPos {cat} p)} (taDir {cat} p) a ->
  DirichMap cat {pos=(taPos {cat} q)} (taDir {cat} q) a
DirichNTApp {cat} {p} {q} alpha a (i ** d) =
  (taDntOnPos alpha i ** cat.catComp (taDntOnDir alpha i) d)
