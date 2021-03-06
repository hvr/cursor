{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE RankNTypes #-}

module Cursor.Simple.MapSpec
    ( spec
    ) where

import Test.Hspec
import Test.QuickCheck
import Test.Validity
import Test.Validity.Optics

import Lens.Micro

import Control.Monad

import Cursor.Simple.Map
import Cursor.Simple.Map.Gen ()

spec :: Spec
spec = do
    describe "makeMapCursor" $
        it "produces valid cursors" $
        producesValidsOnValids (makeMapCursor @Double @Rational)
    describe "makeMapCursorWithSelection" $
        it "produces valid cursors" $
        producesValidsOnValids2 (makeMapCursorWithSelection @Double @Rational)
    describe "singletonMapCursorKey" $
        it "produces valid cursors" $
        producesValidsOnValids2
            (singletonMapCursorKey @Double @Rational @Double @Rational)
    describe "singletonMapCursorValue" $
        it "produces valid cursors" $
        producesValidsOnValids2
            (singletonMapCursorValue @Double @Rational @Double @Rational)
    describe "rebuildMapCursor" $ do
        it "produces valid Nonempty lists" $
            producesValidsOnValids (rebuildMapCursor @Double @Rational)
        it "is the inverse of makeMapCursor for integers" $
            inverseFunctions (makeMapCursor @Int @Int) rebuildMapCursor
    describe "mapCursorNonEmptyCursorL" $
        lensSpecOnValid
            (mapCursorNonEmptyCursorL @Double @Rational @Double @Rational)
    describe "mapCursorElemL" $
        lensSpecOnValid (mapCursorElemL @Double @Rational @Double @Rational)
    describe "mapCursorSelectKey" $
        it "produces valid cursors" $
        producesValidsOnValids (mapCursorSelectKey @Double @Rational)
    describe "mapCursorSelectValue" $
        it "produces valid cursors" $
        producesValidsOnValids (mapCursorSelectValue @Double @Rational)
    describe "mapCursorToggleSelected" $
        it "produces valid cursors" $
        producesValidsOnValids (mapCursorToggleSelected @Double @Rational)
    describe "mapCursorSelectPrev" $ do
        it "produces valid cursors" $
            producesValidsOnValids (mapCursorSelectPrev @Double @Rational)
        it "is a movement" $ isMovementM mapCursorSelectPrev
        it "selects the previous element" pending
    describe "mapCursorSelectNext" $ do
        it "produces valid cursors" $
            producesValidsOnValids (mapCursorSelectNext @Double @Rational)
        it "is a movement" $ isMovementM mapCursorSelectNext
        it "selects the next element" pending
    describe "mapCursorSelectFirst" $ do
        it "produces valid cursors" $
            producesValidsOnValids (mapCursorSelectFirst @Double @Rational)
        it "is a movement" $ isMovement mapCursorSelectFirst
        it "is idempotent" $
            idempotentOnValid (mapCursorSelectFirst @Double @Rational)
        it "selects the first element" pending
    describe "mapCursorSelectLast" $ do
        it "produces valid cursors" $
            producesValidsOnValids (mapCursorSelectLast @Double @Rational)
        it "is a movement" $ isMovement mapCursorSelectLast
        it "is idempotent" $
            idempotentOnValid (mapCursorSelectLast @Double @Rational)
        it "selects the last element" pending
    describe "mapCursorSelection" $ do
        it "produces valid ints" $
            producesValidsOnValids
                (mapCursorSelection @Double @Rational @Double @Rational)
        it "returns the index of the currently selected element" pending
    describe "mapCursorSelectIndex" $ do
        it "produces valid cursors" $
            producesValidsOnValids2 (mapCursorSelectIndex @Double @Rational)
        it "is the identity function when given the current selection" $
            forAllValid $ \nec ->
                mapCursorSelectIndex (mapCursorSelection nec) nec `shouldBe`
                Just (nec :: MapCursor Double Rational)
        it "returns selects the element at the given index" pending
    describe "mapCursorInsert" $ do
        it "produces valid cursors" $
            producesValidsOnValids3
                (mapCursorInsert @Double @Rational @Double @Rational)
        it "inserts a character before the cursor" pending
    describe "mapCursorAppend" $ do
        it "produces valid cursors" $
            producesValidsOnValids3
                (mapCursorAppend @Double @Rational @Double @Rational)
        it "inserts a character after the cursor" pending
    describe "mapCursorInsertAndSelectKey" $ do
        it "produces valid cursors" $
            producesValidsOnValids3
                (mapCursorInsertAndSelectKey @Double @Rational)
    describe "mapCursorAppendAndSelectKey" $ do
        it "produces valid cursors" $
            producesValidsOnValids3
                (mapCursorAppendAndSelectKey @Double @Rational)
    describe "mapCursorInsertAndSelectValue" $ do
        it "produces valid cursors" $
            producesValidsOnValids3
                (mapCursorInsertAndSelectValue @Double @Rational)
    describe "mapCursorAppendAndSelectValue" $ do
        it "produces valid cursors" $
            producesValidsOnValids3
                (mapCursorAppendAndSelectValue @Double @Rational)
    describe "mapCursorRemoveElem" $ do
        it "produces valid cursors" $
            producesValidsOnValids (mapCursorRemoveElem @Double @Rational)
        it "removes an element" pending
    describe "mapCursorDeleteElem" $ do
        it "produces valid cursors" $
            producesValidsOnValids (mapCursorDeleteElem @Double @Rational)
        it "deletes an element" pending
    describe "mapCursorSearch" $ do
        it "produces valid cursors when looking for an equal pair" $
            forAllValid $ \(k, v) ->
                producesValidsOnValids $
                mapCursorSearch @Double @Rational (\k_ v_ -> k_ == k && v_ == v)
        it
            "is indeed the right value when it finds a value and is looking for an equal element" $
            forAllValid $ \(k, v) ->
                forAllValid $ \nec ->
                    case mapCursorSearch (\k_ v_ -> k_ == k && v_ == v) nec of
                        Nothing -> pure ()
                        Just e ->
                            rebuildKeyValueCursor (e ^. mapCursorElemL) `shouldBe`
                            (k :: Double, v :: Rational)
    describe "mapCursorSelectOrAdd" $ do
        it "produces valid cursors when looking for an equal element" $
            forAllValid $ \(k, v) ->
                producesValidsOnValids $
                mapCursorSelectOrAdd
                    (\k_ v_ -> k_ == k && v_ == v)
                    (makeKeyValueCursorKey (k :: Double) (v :: Rational))

isMovementM :: (forall k v. MapCursor k v -> Maybe (MapCursor k v)) -> Property
isMovementM func =
    forAllValid $ \lec ->
        case func (lec :: MapCursor Double Double) of
            Nothing -> pure () -- Fine
            Just lec' ->
                let ne = rebuildMapCursor lec
                    ne' = rebuildMapCursor lec'
                 in unless (ne == ne') $
                    expectationFailure $
                    unlines
                        [ "Cursor before:\n" ++ show lec
                        , "Map before:  \n" ++ show ne
                        , "Cursor after: \n" ++ show lec'
                        , "Map after:   \n" ++ show ne'
                        ]

isMovement :: (forall k v. MapCursor k v -> MapCursor k v) -> Property
isMovement func =
    forAllValid $ \lec ->
        rebuildMapCursor (lec :: MapCursor Int Int) `shouldBe`
        rebuildMapCursor (func lec)
