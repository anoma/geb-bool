module LanguageDef.Syntax

import Library.IdrisUtils
import Library.IdrisCategories

%default total

----------------------------------
----------------------------------
---- General syntax utilities ----
----------------------------------
----------------------------------

public export
INDENT_DEPTH : Nat
INDENT_DEPTH = 2

public export
indentLines : List String -> List String
indentLines = map (indent INDENT_DEPTH)

public export
showLines : (a -> List String) -> a -> String
showLines sh = trim . unlines . sh

----------------------
----------------------
---- Binary trees ----
----------------------
----------------------

public export
data BTExpF : Type -> Type -> Type where
  BTA : atom -> BTExpF atom btty
  BTP : btty -> btty -> BTExpF atom btty

public export
data BTExp : Type -> Type where
  InBT : BTExpF atom (BTExp atom) -> BTExp atom

public export
InBTA : atom -> BTExp atom
InBTA = InBT . BTA

public export
InBTP : BTExp atom -> BTExp atom -> BTExp atom
InBTP = InBT .* BTP

public export
BTAlg : Type -> Type -> Type
BTAlg atom a = BTExpF atom a -> a

public export
btCata : BTAlg atom a -> BTExp atom -> a
btCata alg (InBT e) = alg $ case e of
  BTA a => BTA a
  BTP x y => BTP (btCata alg x) (btCata alg y)

public export
BTShowLinesAlg : Show atom => BTAlg atom (List String)
BTShowLinesAlg (BTA a) = [show a]
BTShowLinesAlg (BTP x y) = ["::"] ++ indentLines x ++ indentLines y

public export
btLines : Show atom => BTExp atom -> List String
btLines = btCata BTShowLinesAlg

public export
Show atom => Show (BTExp atom) where
  show = showLines btLines

-----------------------
-----------------------
---- S-expressions ----
-----------------------
-----------------------

public export
data SExpF : Type -> Type -> Type where
  SXF : atom -> List Nat -> List xty -> SExpF atom xty

public export
data SExp : Type -> Type where
  InSX : SExpF atom (SExp atom) -> SExp atom

public export
InS : atom -> List Nat -> List (SExp atom) -> SExp atom
InS a ns xs = InSX $ SXF a ns xs

public export
SList : Type -> Type
SList = List . SExp

public export
record SXLAlg (atom, a, b : Type) where
  constructor SXA
  xalg : atom -> List Nat -> b -> a
  sxnil : b
  sxcons : a -> b -> b

mutual
  public export
  sxCata : SXLAlg atom a b -> SExp atom -> a
  sxCata alg (InSX x) = case x of
    SXF a ns xs => alg.xalg a ns $ slCata alg xs

  public export
  slCata : SXLAlg atom a b -> SList atom -> b
  slCata alg [] = alg.sxnil
  slCata alg (x :: xs) = alg.sxcons (sxCata alg x) (slCata alg xs)

public export
SExpAlg : Type -> Type -> Type
SExpAlg atom a = SExpF atom a -> a

public export
sexpCata : SExpAlg atom a -> SExp atom -> a
sexpCata alg = sxCata (SXA (\x, ns, l => alg $ SXF x ns l) [] (::))

public export
slistCata : SExpAlg atom a -> SList atom -> List a
slistCata alg = slCata (SXA (\x, ns, l => alg $ SXF x ns l) [] (::))

public export
slcPreservesLen : (alg : SExpAlg atom a) -> (l : SList atom) ->
  length (slistCata alg l) = length l
slcPreservesLen alg [] = Refl
slcPreservesLen alg (x :: l) = cong S (slcPreservesLen alg l)

-------------------
---- Utilities ----
-------------------

public export
SExpLinesAlg : Show atom => SXLAlg atom (List String) (List String)
SExpLinesAlg =
  SXA
    (\a, ns, xs => (show a ++ " : " ++ show ns) :: indentLines xs)
    []
    (++)

public export
sexpLines : Show atom => SExp atom -> List String
sexpLines = sxCata SExpLinesAlg

public export
Show atom => Show (SExp atom) where
  show = showLines sexpLines

public export
data SExpToBtAtom : Type -> Type where
  SBAtom : atom -> SExpToBtAtom atom
  SBNil : SExpToBtAtom atom
  SBNat : Nat -> SExpToBtAtom atom

public export
Show atom => Show (SExpToBtAtom atom) where
  show (SBAtom a) = show a
  show SBNil = "[]"
  show (SBNat n) = show n

-------------------------------------------------
---- S-expression <-> binary-tree conversion ----
-------------------------------------------------

mutual
  public export
  SExpToBtAlg : SExpAlg atom (BTExp $ SExpToBtAtom atom)
  SExpToBtAlg (SXF a ns xs) =
    InBTP (InBTA $ SBAtom a) $ InBTP (NatListToBtAlg ns) (SListToBtAlg xs)

  public export
  NatListToBtAlg : List Nat -> BTExp (SExpToBtAtom atom)
  NatListToBtAlg [] = InBTA SBNil
  NatListToBtAlg (n :: ns) = InBTP (InBTA $ SBNat n) (NatListToBtAlg ns)

  public export
  SListToBtAlg : List (BTExp $ SExpToBtAtom atom) -> BTExp (SExpToBtAtom atom)
  SListToBtAlg [] = InBTA SBNil
  SListToBtAlg (x :: xs) = InBTP x (SListToBtAlg xs)

public export
sexpToBt : SExp atom -> BTExp $ SExpToBtAtom atom
sexpToBt = sexpCata SExpToBtAlg

mutual
  public export
  btToSexp : BTExp (SExpToBtAtom atom) -> Maybe (SExp atom)
  btToSexp (InBT x) = case x of
    BTA a => case a of
      SBAtom a' => Just $ InS a' [] []
      SBNil => Nothing
      SBNat n => Nothing
    BTP (InBT y) (InBT z) => case y of
      BTA a => case a of
        SBAtom a' => case z of
          BTP y' z' => case (btToNatList y', btToSexpList z') of
            (Just ns, Just xs) => Just $ InS a' ns xs
            _ => Nothing
          _ => Nothing
        _ => Nothing
      BTP y z => Nothing

  public export
  btToNatList : BTExp (SExpToBtAtom atom) -> Maybe (List Nat)
  btToNatList (InBT x) = case x of
    BTA a => case a of
      SBNil => Just []
      _ => Nothing
    BTP y z => case y of
      InBT (BTA (SBNat n)) => case btToNatList z of
        Just ns => Just $ n :: ns
        Nothing => Nothing
      _ => Nothing

  public export
  btToSexpList : BTExp (SExpToBtAtom atom) -> Maybe (List $ SExp atom)
  btToSexpList (InBT x) = case x of
    BTA a => case a of
      SBNil => Just []
      _ => Nothing
    BTP y z => case (btToSexp y, btToSexpList z) of
      (Just x, Just xs) => Just $ x :: xs
      _ => Nothing

-------------------------------
-------------------------------
---- Refined s-expressions ----
-------------------------------
-------------------------------

-- S-expressions whose lists of constants and sub-expressions are of
-- lengths determined by their atoms.  (Each atom can be said to have
-- an arity.)
public export
record SArity (atom : Type) where
  constructor SAr
  natAr : atom -> Nat
  expAr : atom -> Nat

public export
CheckSExpArAlg: SArity atom -> SExpAlg atom Bool
CheckSExpArAlg ar (SXF a ns xs) =
  all id xs && length ns == ar.natAr a && length xs == ar.expAr a

public export
checkSExpAr : SArity atom -> SExp atom -> Bool
checkSExpAr ar = sexpCata (CheckSExpArAlg ar)

public export
ValidSExpArAlg: SArity atom -> SExpAlg atom Type
ValidSExpArAlg ar (SXF a ns xs) =
  (HList xs, length ns = ar.natAr a, length xs = ar.expAr a)

public export
ValidSExpAr : SArity atom -> SExp atom -> Type
ValidSExpAr ar = sexpCata (ValidSExpArAlg ar)

public export
ValidSListArL : SArity atom -> SList atom -> List Type
ValidSListArL ar = slistCata (ValidSExpArAlg ar)

public export
ValidSListAr : SArity atom -> SList atom -> Type
ValidSListAr ar l = HList (ValidSListArL ar l)

mutual
  public export
  validSExpAr :
    (ar : SArity atom) -> (x : SExp atom) -> (Maybe . ValidSExpAr ar) x
  validSExpAr ar (InSX (SXF a ns xs)) =
    case
      (validSListAr ar xs,
       decEq (length ns) (ar.natAr a),
       decEq (length xs) (ar.expAr a))
        of
      (Just vxs, Yes vnl, Yes vxl) =>
        Just (vxs, vnl, trans (slcPreservesLen (ValidSExpArAlg ar) xs) vxl)
      _ => Nothing

  public export
  validSListAr :
    (ar : SArity atom) -> (l : SList atom) -> (Maybe . ValidSListAr ar) l
  validSListAr ar [] = Just HNil
  validSListAr ar (x :: xs) =
    case (validSExpAr ar x, validSListAr ar xs) of
      (Just v, Just vs) => Just (HCons v vs)
      _ => Nothing

-----------------
-----------------
---- Symbols ----
-----------------
-----------------

public export
record SymSet where
  constructor SS
  slType : Type
  slSize : Nat
  slEnc : FinDecEncoding slType slSize
  slShow : slType -> String

public export
Show SymSet where
  show (SS ty sz enc sh) = let _ = MkShow sh in show (finFToVect (fst enc))

public export
FinSS : Nat -> SymSet
FinSS n = SS (Fin n) n (FinIdDecEncoding n) show

public export
VoidSS : SymSet
VoidSS = FinSS 0

--------------------
--------------------
---- Namespaces ----
--------------------
--------------------

public export
record Namespace where
  constructor NS
  nsLocalSym : SymSet
  nsSubSym : SymSet
  nsSub : Vect nsSubSym.slSize Namespace

public export
FinNS : (nloc : Nat) -> {nsub : Nat} -> Vect nsub Namespace -> Namespace
FinNS nloc {nsub} = NS (FinSS nloc) (FinSS nsub)

public export
VoidNS : Namespace
VoidNS = FinNS 0 []

mutual
  public export
  nsLines : Namespace -> List String
  nsLines (NS ls ss sub) =
    ("loc: " ++ show ls ++ "; sub: " ++ show ss) ::
     indentLines (nsVectLines sub)

  public export
  nsVectLines : {n : Nat} -> Vect n Namespace -> List String
  nsVectLines [] = []
  nsVectLines (ns :: v) = nsLines ns ++ nsVectLines v

public export
Show Namespace where
  show = showLines nsLines

public export
numSub : Namespace -> Nat
numSub = slSize . nsSubSym

public export
LeafNS : SymSet -> Namespace
LeafNS ss = NS ss VoidSS []

public export
data Subspace : Namespace -> Type where
  This : {ns : Namespace} -> Subspace ns
  Child : {ns : Namespace} ->
    (i : ns.nsSubSym.slType) ->
    Subspace (index (fst (snd ns.nsSubSym.slEnc i)) ns.nsSub) ->
    Subspace ns

public export
(ns : Namespace) => Show (Subspace ns) where
  show {ns} sub = "/" ++ showSub sub where
    showSub : {ns : Namespace} -> Subspace ns -> String
    showSub {ns} This = ""
    showSub {ns} (Child i sub) = slShow ns.nsSubSym i ++ "/" ++ showSub sub
