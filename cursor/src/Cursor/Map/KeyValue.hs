{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE TypeFamilies #-}

module Cursor.Map.KeyValue
    ( KeyValueCursor(..)
    , makeKeyValueCursorKey
    , makeKeyValueCursorValue
    , rebuildKeyValueCursor
    , keyValueCursorSelection
    , mapKeyValueCursor
    , keyValueCursorSelectKey
    , keyValueCursorSelectValue
    , keyValueCursorToggleSelected
    , KeyValueToggle(..)
    ) where

import GHC.Generics (Generic)

import Data.Validity

data KeyValueCursor kc vc k v
    = KeyValueCursorKey kc
                        v
    | KeyValueCursorValue k
                          vc
    deriving (Show, Eq, Generic)

instance (Validity kc, Validity vc, Validity k, Validity v) =>
         Validity (KeyValueCursor kc vc k v)

makeKeyValueCursorKey :: kc -> v -> KeyValueCursor kc vc k v
makeKeyValueCursorKey = KeyValueCursorKey

makeKeyValueCursorValue :: k -> vc -> KeyValueCursor kc vc k v
makeKeyValueCursorValue = KeyValueCursorValue

rebuildKeyValueCursor ::
       (kc -> k) -> (vc -> v) -> KeyValueCursor kc vc k v -> (k, v)
rebuildKeyValueCursor f _ (KeyValueCursorKey kc v) = (f kc, v)
rebuildKeyValueCursor _ g (KeyValueCursorValue k vc) = (k, g vc)

keyValueCursorSelection :: KeyValueCursor kc vc k v -> KeyValueToggle
keyValueCursorSelection (KeyValueCursorKey _ _) = KeySelected
keyValueCursorSelection (KeyValueCursorValue _ _) = ValueSelected

mapKeyValueCursor ::
       (kc -> lc)
    -> (vc -> wc)
    -> (k -> l)
    -> (v -> w)
    -> KeyValueCursor kc vc k v
    -> KeyValueCursor lc wc l w
mapKeyValueCursor a b c d kvc =
    case kvc of
        KeyValueCursorKey kc v -> KeyValueCursorKey (a kc) (d v)
        KeyValueCursorValue k vc -> KeyValueCursorValue (c k) (b vc)

keyValueCursorSelectKey ::
       (k -> kc)
    -> (vc -> v)
    -> KeyValueCursor kc vc k v
    -> KeyValueCursor kc vc k v
keyValueCursorSelectKey g h kvc =
    case kvc of
        KeyValueCursorValue k vc -> KeyValueCursorKey (g k) (h vc)
        _ -> kvc

keyValueCursorSelectValue ::
       (kc -> k)
    -> (v -> vc)
    -> KeyValueCursor kc vc k v
    -> KeyValueCursor kc vc k v
keyValueCursorSelectValue f i kvc =
    case kvc of
        KeyValueCursorKey kc v -> KeyValueCursorValue (f kc) (i v)
        _ -> kvc

keyValueCursorToggleSelected ::
       (kc -> k)
    -> (k -> kc)
    -> (vc -> v)
    -> (v -> vc)
    -> KeyValueCursor kc vc k v
    -> KeyValueCursor kc vc k v
keyValueCursorToggleSelected f g h i kvc =
    case kvc of
        KeyValueCursorKey kc v -> KeyValueCursorValue (f kc) (i v)
        KeyValueCursorValue k vc -> KeyValueCursorKey (g k) (h vc)

data KeyValueToggle
    = KeySelected
    | ValueSelected
    deriving (Show, Eq, Generic)

instance Validity KeyValueToggle
