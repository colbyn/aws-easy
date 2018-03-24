{-|
Module      : Network.AWS.Easy.Types
Description : Support types
Copyright   : (C) Richard Cook, 2018
License     : MIT
Maintainer  : rcook@rcook.org
Stability   : experimental
Portability : portable

This module provides support types for @aws-easy@.
-}

{-# LANGUAGE TemplateHaskell #-}

module Network.AWS.Easy.Types
    ( Session(..)
    , sEnv
    , sRegion
    , sService
    ) where

import           Control.Lens (makeLenses)
import           Network.AWS (Env, Region, Service)

data Session = Session
    { _sEnv :: Env
    , _sRegion :: Region
    , _sService :: Service
    }
makeLenses ''Session
