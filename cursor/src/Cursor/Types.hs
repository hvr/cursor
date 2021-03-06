{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RankNTypes #-}

module Cursor.Types where

import GHC.Generics (Generic)

import Data.Validity

import Data.Functor.Compose

import Control.Applicative

import Lens.Micro

data DeleteOrUpdate a
    = Deleted
    | Updated a
    deriving (Show, Eq, Generic)

instance Validity a => Validity (DeleteOrUpdate a)

instance Functor DeleteOrUpdate where
    fmap _ Deleted = Deleted
    fmap f (Updated a) = Updated (f a)

instance Applicative DeleteOrUpdate where
    pure = Updated
    Deleted <*> _ = Deleted
    _ <*> Deleted = Deleted
    (Updated f) <*> (Updated a) = Updated (f a)

instance Alternative DeleteOrUpdate where
    empty = Deleted
    Updated a <|> _ = Updated a
    Deleted <|> doua = doua

joinDeletes ::
       Maybe (DeleteOrUpdate a) -> Maybe (DeleteOrUpdate a) -> DeleteOrUpdate a
joinDeletes m1 m2 =
    case (m1, m2) of
        (Nothing, Nothing) -> Deleted
        (Nothing, Just a) -> a
        (Just a, _) -> a

joinDeletes3 ::
       Maybe (DeleteOrUpdate a)
    -> Maybe (DeleteOrUpdate a)
    -> Maybe (DeleteOrUpdate a)
    -> DeleteOrUpdate a
joinDeletes3 m1 m2 m3 =
    case (m1, m2, m3) of
        (Nothing, Nothing, Nothing) -> Deleted
        (Nothing, Nothing, Just a) -> a
        (Nothing, Just a, _) -> a
        (Just a, _, _) -> a

joinPossibleDeletes ::
       Maybe (DeleteOrUpdate a)
    -> Maybe (DeleteOrUpdate a)
    -> Maybe (DeleteOrUpdate a)
joinPossibleDeletes d1 d2 = getCompose $ Compose d1 <|> Compose d2

focusPossibleDeleteOrUpdate ::
       Lens' b a
    -> (a -> Maybe (DeleteOrUpdate a))
    -> b
    -> Maybe (DeleteOrUpdate b)
focusPossibleDeleteOrUpdate l func = getCompose . l (Compose . func)
