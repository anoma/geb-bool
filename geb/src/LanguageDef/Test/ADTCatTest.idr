module LanguageDef.Test.ADTCatTest

import Test.TestLibrary
import LanguageDef.ADTCat

%default total

---------------
---------------
---- PolyF ----
---------------
---------------

polybool : PolyMu
polybool = Poly1 $+ Poly1

polyfnat : PolyMu
polyfnat = Poly1 $+ PolyI

polyf0 : PolyMu
polyf0 = (polyfnat $. Poly1) $*^ 5

polyf1 : PolyMu
polyf1 = (Poly1 $+ PolyI $*^ 2) $.^ 3

polyf2 : PolyMu
polyf2 = polyf0 $.^ 0

Polyf0f : Type -> Type
Polyf0f = MetaPolyFMetaF polyf0

Polyf1f : Type -> Type
Polyf1f = MetaPolyFMetaF polyf1

Polyf2f : Type -> Type
Polyf2f = MetaPolyFMetaF polyf2

Polyf0t : Type
Polyf0t = ConstComponent polyf0

Polyf1t : Type
Polyf1t = ConstComponent polyf1

Polyf2t : Type
Polyf2t = ConstComponent polyf2

polyf0i : Polyf0t
polyf0i = (Left (), Left (), Right (), Left (), Right ())

polyf2i : Not Polyf2t
polyf2i = id

PolyFreeNat : (0 _ : Type) -> Type
PolyFreeNat = MetaPolyFreeM polyfnat

PolyNat : Type
PolyNat = MetaPolyMu polyfnat

polyFNatT0 : PolyFreeNat Nat
polyFNatT0 = InFVar 7

polyFNatT1 : PolyFreeNat Nat
polyFNatT1 = InFCom $ Left ()

polyFNatT2 : PolyFreeNat Nat
polyFNatT2 = InFCom $ Right $ InFVar 5

polyFNatT3 : PolyFreeNat Nat
polyFNatT3 = InFCom $ Right $ InFCom $ Left ()

polyFNatT4 : PolyFreeNat Nat
polyFNatT4 = InFCom $ Right $ InFCom $ Right $ InFVar 3

polyFNatT5 : PolyFreeNat Nat
polyFNatT5 = InFCom $ Right $ InFCom $ Right $ InFCom $ Left ()

polyFNatT6 : PolyFreeNat Nat
polyFNatT6 = InFCom $ Right $ InFCom $ Right $ InFCom $ Right $ InFCom $ Left ()

polynatT0 : PolyNat
polynatT0 = InFCom $ Left ()

polynatT1 : PolyNat
polynatT1 = InFCom $ Right $ InFCom $ Left ()

polynatT2 : PolyNat
polynatT2 = InFCom $ Right $ InFCom $ Right $ InFCom $ Left ()

polyNatIter : Nat -> PolyMu
polyNatIter = ($.^) polyfnat

polyNatIterFixed : Nat -> PolyMu
polyNatIterFixed n = polyNatIter n $. Poly0

PolyNatIter : Nat -> Type
PolyNatIter = ConstComponent . polyNatIter

pniterT0 : Not $ PolyNatIter 0
pniterT0 = id

pniterT1 : PolyNatIter 1
pniterT1 = ()

pniterT2 : PolyNatIter 2
pniterT2 = Left ()

pniterT3 : PolyNatIter 2
pniterT3 = Right ()

pniterT4 : PolyNatIter 3
pniterT4 = Left ()

pniterT5 : PolyNatIter 3
pniterT5 = Right $ Left ()

pniterT6 : PolyNatIter 3
pniterT6 = Right $ Right ()

pniterT7 : PolyNatIter 4
pniterT7 = Left ()

pniterT8 : PolyNatIter 4
pniterT8 = Right $ Left ()

pniterT9 : PolyNatIter 4
pniterT9 = Right $ Right $ Left ()

pniterT10 : PolyNatIter 4
pniterT10 = Right $ Right $ Right ()

polyfeqT0 : Assertion
polyfeqT0 = Assert $ polyfnat /= polyNatIter 0

polyfeqT1 : Assertion
polyfeqT1 = Assert $ polyfnat == polyNatIter 1

polyfeqT2 : Assertion
polyfeqT2 = Assert $ polyfnat /= polyNatIter 2

polyHomBoolF0 : PolyMu
polyHomBoolF0 = PolyHomObj polybool polyf0

polyCardT0 : Assertion
polyCardT0 = Assert $
  polyTCard polyHomBoolF0 == power (polyTCard polyf0) (polyTCard polybool)

polyHomId4Id : PolyMu
polyHomId4Id = PolyHomObj PolyI (4 $:* PolyI)

twoBits : PolyMu
twoBits = polybool $* polybool

polyHomId4Id' : PolyMu
polyHomId4Id' = PolyHomObj PolyI (twoBits $* PolyI)

polyHom4IdId : PolyMu
polyHom4IdId = PolyHomObj (4 $:* PolyI) PolyI

polyHom4IdId' : PolyMu
polyHom4IdId' = PolyHomObj (twoBits $* PolyI) PolyI

polyDepth3BinTree : PolyMu
polyDepth3BinTree = polyf1

polyDepth3BinTreeFixed : PolyMu
polyDepth3BinTreeFixed = polyDepth3BinTree $. Poly0

----------------------------------
----------------------------------
----- Exported test function -----
----------------------------------
----------------------------------

export
adtCatTest : IO ()
adtCatTest = do
  putStrLn ""
  putStrLn "================="
  putStrLn "Begin ADTCatTest:"
  putStrLn "-----------------"
  putStrLn ""
  putStrLn "---------------"
  putStrLn "---- PolyF ----"
  putStrLn "---------------"
  putStrLn $ "polyf0 = " ++ show polyf0
  putStrLn $ "distrib[polyf0] = " ++ show (polyDistrib polyf0)
  putStrLn $ "position-list[polyf0] = " ++ polyPosShow polyf0
  putStrLn $ "poly-list[polyf0] = " ++ show (toPolyShape polyf0)
  putStrLn $ "poly-list[polyf1] = " ++ show (toPolyShape polyf1)
  putStrLn $ "pnitert10 = " ++ show pniterT10
  putStrLn $ "card[polyf0] = " ++ show (polyTCard polyf0)
  putStrLn $ "card[polybool] = " ++ show (polyTCard polybool)
  putStrLn $ "(polybool -> polyf0) = " ++ show polyHomBoolF0
  putStrLn $ "card[polybool -> polyf0] = " ++ show (polyTCard polyHomBoolF0)
  putStrLn $ "(id -> 4 * id) = " ++ show polyHomId4Id
  putStrLn $ "(id -> (2 * 2) * id) = " ++ show polyHomId4Id'
  putStrLn $ "(4 * id -> id) = " ++ show polyHom4IdId
  putStrLn $ "((2 * 2) * id -> id) = " ++ show polyHom4IdId'
  putStrLn $ "polyDepth3BT = " ++ show (toPolyShape polyDepth3BinTree)
  putStrLn $ "card[polyDepth3BT,0] = " ++ show (polyTCard polyDepth3BinTree)
  putStrLn $ "depth4Nat = " ++ show (polyNatIter 4)
  putStrLn $ "card[depth4Nat] = " ++ show (polyTCard (polyNatIter 4))
  putStrLn $ "card[depth4Nat -> polyDepth3BT] = " ++
    show (polyTCard $ PolyHomObj (polyNatIter 4) (polyDepth3BinTree))
  putStrLn $ "card[polyDepth3BT -> depth4Nat] = " ++
    show (polyTCard $ PolyHomObj (polyDepth3BinTree) (polyNatIter 4))
  putStrLn $ "hom[polyDepth3BT -> depth4Nat] = " ++
    showPolyShape (PolyHomObj (polyDepth3BinTree) (polyNatIter 4))
  putStrLn $ "polyDepth3BTFixed = " ++ show polyDepth3BinTreeFixed
  putStrLn $ "card[polyDepth3BTFixed,0] = "
    ++ show (polyTCard polyDepth3BinTreeFixed)
  putStrLn $ "depth4NatFixed = " ++ show (polyNatIterFixed 4)
  putStrLn $ "card[depth4NatFixed] = " ++ show (polyTCard (polyNatIterFixed 4))
  putStrLn $ "card[depth4NatFixed -> polyDepth3BTFixed] = " ++
    show (polyTCard $ PolyHomObj (polyNatIterFixed 4) (polyDepth3BinTreeFixed))
  putStrLn $ "card[polyDepth3BTFixed -> depth4NatFixed] = " ++
    show (polyTCard $ PolyHomObj (polyDepth3BinTreeFixed) (polyNatIterFixed 4))
  putStrLn $ "first compose = " ++ show ((4 $:* PolyI) $. (PolyI $+ Poly1))
  putStrLn $ "second compose = " ++
    show ((twoBits $* PolyI) $. (PolyI $+ Poly1))
  putStrLn $ "exercise 5.8.3 first part unformatted = " ++
    show (((PolyI $* PolyI) $. (PolyI $*^ 3 $+ Poly1)))
  putStrLn $ "exercise 5.8.3 first part distributed = " ++
    show (polyDistrib (((PolyI $* PolyI) $. (PolyI $*^ 3 $+ Poly1))))
  putStrLn $ "exercise 5.8.3 first part = " ++
    show (toPolyShape (((PolyI $* PolyI) $. (PolyI $*^ 3 $+ Poly1))))
  putStrLn $ "exercise 5.8.3 second part = " ++
    show (toPolyShape (((PolyI) $. (PolyI $*^ 3 $+ Poly1))))
  putStrLn $ "exercise 5.8.3 composite unformatted = " ++
    show (((PolyI $* PolyI $+ PolyI) $. (PolyI $*^ 3 $+ Poly1)))
  putStrLn $ "exercise 5.8.3 composite distributed = " ++
    show (polyDistrib (((PolyI $* PolyI $+ PolyI) $. (PolyI $*^ 3 $+ Poly1))))
  putStrLn $ "exercise 5.8.3 composite = " ++
    show (toPolyShape (((PolyI $* PolyI $+ PolyI) $. (PolyI $*^ 3 $+ Poly1))))
  putStrLn ""
  putStrLn "---------------"
  putStrLn "End ADTCatTest."
  putStrLn "==============="
  pure ()
