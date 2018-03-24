{-|
Module      : Network.AWS.Easy.Classes
Description : Service and session type classes
Copyright   : (C) Richard Cook, 2018
License     : MIT
Maintainer  : rcook@rcook.org
Stability   : experimental
Portability : portable

This module provides service and session type classes to support @aws-easy@'s Template Haskell functions.
-}

{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE TypeFamilies #-}

module Network.AWS.Easy.Classes
    ( ServiceClass(..)
    , SessionClass(..)
    ) where

import           Network.AWS (Service)
import           Network.AWS.Easy.Types

class ServiceClass a where
    type TypedSession a :: *
    rawService :: a -> Service
    wrappedSession :: Session -> TypedSession a

class SessionClass a where
    rawSession :: a -> Session
