{-|
Module      : Network.AWS.Simple.Classes
Description : Service and session type classes
Copyright   : (C) Richard Cook, 2018
License     : MIT
Maintainer  : rcook@rcook.org
Stability   : experimental
Portability : portable

This modules provides service and session type classes for the "AWS via Haskell" project.
-}

{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE TypeFamilies #-}

module Network.AWS.Simple.Classes
    ( ServiceClass(..)
    , SessionClass(..)
    ) where

import           Network.AWS (Service)
import           Network.AWS.Simple.Types

class ServiceClass a where
    type TypedSession a :: *
    rawService :: a -> Service
    wrappedSession :: Session -> TypedSession a

class SessionClass a where
    rawSession :: a -> Session
