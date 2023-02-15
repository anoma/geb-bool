module LanguageDef.Syntax

import Library.IdrisUtils
import Library.IdrisCategories
import public LanguageDef.Atom

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
sxfAtom : SExpF atom xty -> atom
sxfAtom (SXF a _ _) = a

public export
sxfConsts : SExpF atom xty -> List Nat
sxfConsts (SXF _ ns _) = ns

public export
sxfSubexprs : SExpF atom xty -> List xty
sxfSubexprs (SXF _ _ xs) = xs

public export
data FrSExpM : Type -> Type -> Type where
  InSXV : ty -> FrSExpM atom ty -- variable
  InSXC : SExpF atom (FrSExpM atom ty) -> FrSExpM atom ty -- compound term

public export
SExp : Type -> Type
SExp atom = FrSExpM atom Void

public export
InSX : SExpF atom (SExp atom) -> SExp atom
InSX = InSXC

public export
InS : atom -> List Nat -> List (SExp atom) -> SExp atom
InS a ns xs = InSX $ SXF a ns xs

public export
InSA : atom -> SExp atom
InSA a = InS a [] []

public export
FrSListM : Type -> Type -> Type
FrSListM atom ty = List (FrSExpM atom ty)

public export
SList : Type -> Type
SList atom = FrSListM atom Void

public export
InSF : atom -> List Nat -> FrSListM atom ty -> FrSExpM atom ty
InSF a ns xs = InSXC $ SXF a ns xs

public export
InSFA : atom -> FrSExpM atom ty
InSFA a = InSF a [] []

public export
data CoSExpCM : Type -> Type -> Type where
  -- Labeled term
  InSXL : ty -> SExpF atom (CoSExpCM atom ty) -> CoSExpCM atom ty

public export
record FrSXLAlg (atom, ty, a, b : Type) where
  constructor FrSXA
  frsubst : ty -> a
  frxalg : atom -> List Nat -> b -> a
  frsxnil : b
  frsxcons : a -> b -> b

public export
record SXLAlg (atom, a, b : Type) where
  constructor SXA
  xalg : atom -> List Nat -> b -> a
  sxnil : b
  sxcons : a -> b -> b

public export
SXLSubstAlgToFr : {0 atom, ty, a, b : Type} ->
  (ty -> a) -> SXLAlg atom a b -> FrSXLAlg atom ty a b
SXLSubstAlgToFr {atom} {ty} {a} {b} subst (SXA xalg sxnil sxcons) =
  FrSXA subst xalg sxnil sxcons

public export
SXLAlgToFr : {0 atom, a, b : Type} -> SXLAlg atom a b -> FrSXLAlg atom Void a b
SXLAlgToFr {atom} {a} {b} = SXLSubstAlgToFr (voidF a)

mutual
  public export
  frsxCata : FrSXLAlg atom ty a b -> FrSExpM atom ty -> a
  frsxCata alg (InSXV v) = alg.frsubst v
  frsxCata alg (InSXC x) = case x of
    SXF a ns xs => alg.frxalg a ns $ frslCata alg xs

  public export
  frslCata : FrSXLAlg atom ty a b -> FrSListM atom ty -> b
  frslCata alg [] = alg.frsxnil
  frslCata alg (x :: xs) = alg.frsxcons (frsxCata alg x) (frslCata alg xs)

public export
sxSubstCata : (ty -> a) -> SXLAlg atom a b -> FrSExpM atom ty -> a
sxSubstCata subst alg = frsxCata (SXLSubstAlgToFr subst alg)

public export
slSubstCata : (ty -> a) -> SXLAlg atom a b -> FrSListM atom ty -> b
slSubstCata subst alg = frslCata (SXLSubstAlgToFr subst alg)

public export
sxCata : SXLAlg atom a b -> SExp atom -> a
sxCata = frsxCata . SXLAlgToFr

public export
slCata : SXLAlg atom a b -> SList atom -> b
slCata = frslCata . SXLAlgToFr

public export
SExpAlg : Type -> Type -> Type
SExpAlg atom a = SExpF atom a -> a

public export
SExpBoolAlg : Type -> Type
SExpBoolAlg atom = SExpAlg atom Bool

public export
SExpTypeAlg : Type -> Type
SExpTypeAlg atom = SExpAlg atom Type

public export
SExpConsAlg : SExpAlg atom a -> SXLAlg atom a (List a)
SExpConsAlg alg = SXA (\x, ns, l => alg $ SXF x ns l) [] (::)

public export
sexpCata : SExpAlg atom a -> SExp atom -> a
sexpCata = sxCata . SExpConsAlg

public export
frsexpCata : (ty -> a) -> SExpAlg atom a -> FrSExpM atom ty -> a
frsexpCata subst alg = sxSubstCata subst (SExpConsAlg alg)

public export
slistCata : SExpAlg atom a -> SList atom -> List a
slistCata = slCata . SExpConsAlg

public export
frslistCata : (ty -> a) -> SExpAlg atom a -> FrSListM atom ty -> List a
frslistCata subst alg = slSubstCata subst (SExpConsAlg alg)

public export
slcPreservesLen : (alg : SExpAlg atom a) -> (l : SList atom) ->
  length (slistCata alg l) = length l
slcPreservesLen alg [] = Refl
slcPreservesLen alg (x :: l) = cong S (slcPreservesLen alg l)

public export
SExpMaybeAlg : Type -> Type -> Type
SExpMaybeAlg atom a = SExpF atom a -> Maybe a

public export
SExpAlgFromMaybe :
  (SExpF atom a -> Maybe a) -> SXLAlg atom (Maybe a) (Maybe (List a))
SExpAlgFromMaybe alg =
  SXA
    (\x, ns, ml => case ml of
      Just l => alg $ SXF x ns l
      _ => Nothing)
    (Just [])
    (\mx, ml => case (mx, ml) of
      (Just x, Just l) => Just (x :: l)
      _ => Nothing)

public export
sexpMaybeCata : SExpMaybeAlg atom a -> SExp atom -> Maybe a
sexpMaybeCata = sxCata . SExpAlgFromMaybe

public export
frsexpMaybeCata :
  (ty -> Maybe a) -> SExpMaybeAlg atom a -> FrSExpM atom ty -> Maybe a
frsexpMaybeCata subst = sxSubstCata subst . SExpAlgFromMaybe

public export
slistMaybeCata : SExpMaybeAlg atom a -> SList atom -> Maybe (List a)
slistMaybeCata = slCata . SExpAlgFromMaybe

public export
frslistMaybeCata :
  (ty -> Maybe a) -> SExpMaybeAlg atom a -> FrSListM atom ty -> Maybe (List a)
frslistMaybeCata subst = slSubstCata subst . SExpAlgFromMaybe

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
frsexpLines : Show atom => Show ty => FrSExpM atom ty -> List String
frsexpLines = sxSubstCata (\x => [show x]) SExpLinesAlg

public export
Show atom => Show ty => Show (FrSExpM atom ty) where
  show = showLines frsexpLines

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

--------------------------------
---- Pairs of s-expressions ----
--------------------------------

public export
SExpDecEqNTAlg : Type -> Type
SExpDecEqNTAlg atom = NaturalTransformation DecEqPred (DecEqPred . SExpF atom)

public export
sexpDecEqNTAlg : DecEqPred atom -> SExpDecEqNTAlg atom
sexpDecEqNTAlg deqatom a deqa (SXF e ns xs) (SXF e' ns' xs') =
  case deqatom e e' of
    Yes Refl => case decEq ns ns' of
      Yes Refl => case decEq xs xs' of
        Yes Refl => Yes Refl
        No neq => No $ \eq => case eq of Refl => neq Refl
      No neq => No $ \eq => case eq of Refl => neq Refl
    No neq => No $ \eq => case eq of Refl => neq Refl
  where
    DecEq a where
      decEq = deqa

mutual
  public export
  sexpDecEq : {atom : Type} -> DecEq ty =>
    DecEqPred atom -> DecEqPred (FrSExpM atom ty)
  sexpDecEq deq (InSXV v) (InSXV v') =
    case decEq v v' of
      Yes Refl => Yes Refl
      No neq => No $ \Refl => neq Refl
  sexpDecEq deq (InSXV _) (InSXC _) = No $ \eq => case eq of Refl impossible
  sexpDecEq deq (InSXC _) (InSXV _) = No $ \eq => case eq of Refl impossible
  sexpDecEq deq (InSXC (SXF a ns xs)) (InSXC (SXF a' ns' xs')) =
    case deq a a' of
      Yes Refl => case decEq ns ns' of
        Yes Refl => case slistDecEq deq xs xs' of
          Yes Refl => Yes Refl
          No neq => No $ \eq => case eq of Refl => neq Refl
        No neq => No $ \eq => case eq of Refl => neq Refl
      No neq => No $ \eq => case eq of Refl => neq Refl

  public export
  slistDecEq : {atom : Type} -> DecEq ty =>
    DecEqPred atom -> DecEqPred (FrSListM atom ty)
  slistDecEq deq [] [] = Yes Refl
  slistDecEq deq [] (x :: xs) = No $ \eq => case eq of Refl impossible
  slistDecEq deq (x :: xs) [] = No $ \eq => case eq of Refl impossible
  slistDecEq deq (x :: xs) (x' :: xs') =
    case sexpDecEq deq x x' of
      Yes Refl => case slistDecEq deq xs xs' of
        Yes Refl => Yes Refl
        No neq => No $ \eq => case eq of Refl => neq Refl
      No neq => No $ \eq => case eq of Refl => neq Refl

public export
(atom : Type) => DecEq atom => DecEq ty => DecEq (FrSExpM atom ty) where
  decEq = sexpDecEq decEq

--------------------------
---- Monad operations ----
--------------------------

public export
sexpReturn : atom -> SExp atom
sexpReturn a = InS a [] []

public export
SExpJoinAlg : SExpAlg (SExp atom) (SExp atom)
SExpJoinAlg (SXF (InSXC (SXF a ns xs)) ns' xs') = InS a (ns ++ ns') (xs ++ xs')

public export
sexpJoin : SExp (SExp atom) -> SExp atom
sexpJoin = sexpCata SExpJoinAlg

-------------------------------
-------------------------------
---- Refined s-expressions ----
-------------------------------
-------------------------------

---------------------------------------------
---- General induction for s-expressions ----
---------------------------------------------

public export
SExpGenBoolAlg : SExpBoolAlg atom -> SExpBoolAlg atom
SExpGenBoolAlg alg x = all id (sxfSubexprs x) && alg x

public export
sexpGenBoolCata : SExpBoolAlg atom -> SExp atom -> Bool
sexpGenBoolCata = sexpCata . SExpGenBoolAlg

public export
slistGenBoolCataL : SExpBoolAlg atom -> SList atom -> List Bool
slistGenBoolCataL = slistCata . SExpGenBoolAlg

public export
slistGenBoolCata : SExpBoolAlg atom -> SList atom -> Bool
slistGenBoolCata alg l = all id (slistGenBoolCataL alg l)

public export
SExpGenTypeAlg : SExpTypeAlg atom -> SExpTypeAlg atom
SExpGenTypeAlg alg x = (HList $ sxfSubexprs x, alg x)

public export
sexpGenTypeCata : SExpTypeAlg atom -> SExp atom -> Type
sexpGenTypeCata = sexpCata . SExpGenTypeAlg

public export
slistGenTypeCataL : SExpTypeAlg atom -> SList atom -> List Type
slistGenTypeCataL = slistCata . SExpGenTypeAlg

public export
slistGenTypeCata : SExpTypeAlg atom -> SList atom -> Type
slistGenTypeCata alg l = HList (slistGenTypeCataL alg l)

public export
SExpDepAlg : {atom : Type} ->
  SExpTypeAlg atom -> SExpMaybeAlg atom (SExp atom) -> Type
SExpDepAlg alg paramAlg =
  (a : atom) -> (ns : List Nat) -> (xs : SList atom) ->
  (0 _ : slistGenTypeCata alg xs) ->
  (params : SList atom) ->
  (0 _ : slistMaybeCata paramAlg xs = Just params) ->
  Maybe (alg (SXF a ns (slistGenTypeCataL alg xs)))

mutual
  public export
  sexpGenTypeDec : {atom : Type} ->
    (alg : SExpTypeAlg atom) ->
    (paramAlg : SExpMaybeAlg atom (SExp atom)) ->
    (step : SExpDepAlg alg paramAlg) ->
    (x : SExp atom) ->
    Maybe (sexpGenTypeCata alg x)
  sexpGenTypeDec alg paramAlg step (InSXC (SXF a ns xs)) with
    (slistGenTypeDec alg paramAlg step xs, slistMaybeCata paramAlg xs) proof prf
      sexpGenTypeDec alg paramAlg step (InSXC (SXF a ns xs))
        | (Just vxs, Just params) =
          case step a ns xs vxs params (sndEq prf) of
            Just ty => Just (vxs, ty)
            _ => Nothing
      sexpGenTypeDec alg paramAlg step (InSXC (SXF a ns xs))
        | _ = Nothing

  public export
  slistGenTypeDec : {atom : Type} ->
    (alg : SExpTypeAlg atom) ->
    (paramAlg : SExpMaybeAlg atom (SExp atom)) ->
    (step : SExpDepAlg alg paramAlg) ->
    (l : SList atom) ->
    Maybe (slistGenTypeCata alg l)
  slistGenTypeDec alg paramAlg step [] = Just HNil
  slistGenTypeDec alg paramAlg step (x :: xs) =
    case
      (sexpGenTypeDec alg paramAlg step x,
       slistGenTypeDec alg paramAlg step xs) of
        (Just v, Just vs) => Just (HCons v vs)
        _ => Nothing

---------------------------
---- Per-atom algebras ----
---------------------------

public export
SExpAtomAlg : Type -> Type -> Type
SExpAtomAlg atom a = List Nat -> List a -> a

public export
SExpAlgFromAtoms : (atom -> SExpAtomAlg atom a) -> SExpAlg atom a
SExpAlgFromAtoms alg (SXF a ns xs) = alg a ns xs

-----------------
---- Arities ----
-----------------

-- Test whether the first list is bounded by the second list:  that is,
-- whether the lists have the same lengths, and each element of the first
-- list is strictly less than the corresponding element of the second list.
public export
listBounded : List Nat -> List Nat -> Bool
listBounded [] [] = True
listBounded [] (_ :: _) = False
listBounded (_ :: _) [] = False
listBounded (x :: xs) (y :: ys) = x < y && listBounded xs ys

-- S-expressions whose lists of constants and sub-expressions are of
-- lengths determined by their atoms.  (Each atom can be said to have
-- an arity.)
public export
record SArity (atom : Type) where
  constructor SAr
  natBounds : atom -> List Nat
  expAr : atom -> Nat

public export
CheckSExpLenAlg : SArity atom -> SExpBoolAlg atom
CheckSExpLenAlg ar (SXF a ns xs) =
  listBounded ns (ar.natBounds a) && length xs == ar.expAr a

public export
CheckSExpArAlg: SArity atom -> SExpBoolAlg atom
CheckSExpArAlg = SExpGenBoolAlg . CheckSExpLenAlg

public export
checkSExpAr : SArity atom -> SExp atom -> Bool
checkSExpAr = sexpGenBoolCata . CheckSExpLenAlg

public export
ValidSExpLenAlg : SArity atom -> SExpTypeAlg atom
ValidSExpLenAlg ar (SXF a ns xs) =
  (IsTrue (listBounded ns (ar.natBounds a)), length xs = ar.expAr a)

public export
ValidSExpArAlg: SArity atom -> SExpTypeAlg atom
ValidSExpArAlg = SExpGenTypeAlg . ValidSExpLenAlg

public export
ValidSExpAr : SArity atom -> SExp atom -> Type
ValidSExpAr = sexpGenTypeCata . ValidSExpLenAlg

public export
ValidSListArL : SArity atom -> SList atom -> List Type
ValidSListArL = slistGenTypeCataL . ValidSExpLenAlg

public export
ValidSListAr : SArity atom -> SList atom -> Type
ValidSListAr = slistGenTypeCata . ValidSExpLenAlg

public export
ValidSExpDepAlg :
  (ar : SArity atom) -> SExpDepAlg (ValidSExpLenAlg ar) (Just . InSX)
ValidSExpDepAlg ar a ns xs tys params paramseq =
  case
    (decEq (listBounded ns (ar.natBounds a)) True,
     decEq (length xs) (ar.expAr a)) of
      (Yes nseq, Yes xseq) =>
        Just (nseq, trans (slcPreservesLen (ValidSExpArAlg ar) xs) xseq)
      _ =>
        Nothing

public export
validSExpAr : {atom : Type} ->
  (ar : SArity atom) -> (x : SExp atom) -> (Maybe . ValidSExpAr ar) x
validSExpAr ar =
  sexpGenTypeDec (ValidSExpLenAlg ar) (Just . InSX) (ValidSExpDepAlg ar)

--------------------------
---- Mutual recursion ----
--------------------------

public export
record MutRecSExpFam (atom : Type) (tys : Type) where
  constructor MRSFam
  mrfAssign : atom -> tys
  mrfBounds : atom -> List Nat
  mrfDirTy : atom -> List tys

public export
CheckMRSFAlg : Eq tys => MutRecSExpFam atom tys -> SExpMaybeAlg atom atom
CheckMRSFAlg (MRSFam assign bounds dirTy) (SXF a ns xs) =
  if listBounded ns (bounds a) && map assign xs == dirTy a
  then
    Just a
  else
    Nothing

public export
checkMRSF : Eq tys => MutRecSExpFam atom tys -> SExp atom -> Bool
checkMRSF fam = isJust . sexpMaybeCata (CheckMRSFAlg fam)

-------------------------------------------------
---- S-expressions as terms of type families ----
-------------------------------------------------

public export
record SExpParamSig (tys : Type) where
  constructor SExpParams
  sfParam : tys -> Maybe tys
  sfOrder : tys -> Nat
  0 sfParamOrdered :
    (ty : tys) -> (j : IsJustTrue (sfParam ty)) ->
    LT (sfOrder $ fromIsJust {x=(sfParam ty)} j) (sfOrder ty)

public export
record SExpFam (atom, tys : Type) where
  constructor SFam
  sfSig : SExpParamSig tys
  sfMRF : MutRecSExpFam atom tys

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

------------------------------------
---- Geb-specific s-expressions ----
------------------------------------

public export
NExp : Type
NExp = SExp Nat

public export
NList : Type
NList = SList Nat

public export
GExp : Type
GExp = SExp GebAtom

public export
FrGExp : Type -> Type
FrGExp = FrSExpM GebAtom

public export
GList : Type
GList = SList GebAtom

public export
FrGList : Type -> Type
FrGList = FrSListM GebAtom

public export
GBtAtom : Type
GBtAtom = SExpToBtAtom GebAtom

public export
GBTExp : Type
GBTExp = BTExp GBtAtom
