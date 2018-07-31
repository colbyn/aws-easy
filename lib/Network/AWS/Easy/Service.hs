{-|
Module      : Network.AWS.Easy.Service
Description : Configuring and making client connections to AWS services
Copyright   : (C) Richard Cook, 2018
License     : MIT
Maintainer  : rcook@rcook.org
Stability   : experimental
Portability : portable

This module provides support for configuring and making client connections to AWS services using @amazonka@.
-}

{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module Network.AWS.Easy.Service
    ( AWSConfig
    , Endpoint(..)
    , HostName
    , Logging(..)
    , Port
    , awscCredentials
    , awscEndpoint
    , awscLogging
    , awsConfig
    , connect
    , withAWS
    ) where

import           Control.Lens ((<&>), makeLenses, set)
import           Control.Monad.Trans.AWS
                    ( AWST'
                    , reconfigure
                    , runAWST
                    , within
                    )
import           Control.Monad.Trans.Resource
                    ( ResourceT
                    )
import           Data.ByteString (ByteString)
import           Network.AWS
                    ( Credentials(..)
                    , Env
                    , LogLevel(..)
                    , Region(..)
                    , Service
                    , envLogger
                    , newEnv
                    , newLogger
                    , runResourceT
                    , setEndpoint
                    )
import           Network.AWS.Easy.Classes
import           Network.AWS.Easy.Types
import           System.IO (stdout)
import           Control.Monad.Trans.Control (MonadBaseControl)
import           Control.Monad.IO.Unlift (MonadUnliftIO)

type HostName = ByteString

type Port = Int

data Logging = LoggingEnabled | LoggingDisabled

data Endpoint = AWSRegion Region | Local HostName Port

data AWSConfig = AWSConfig
    { _awscEndpoint :: Endpoint
    , _awscLogging :: Logging
    , _awscCredentials :: Credentials
    }
makeLenses ''AWSConfig

awsConfig :: Endpoint -> AWSConfig
awsConfig endpoint = AWSConfig endpoint LoggingDisabled Discover

connect :: forall a . ServiceClass a => AWSConfig -> a -> IO (TypedSession a)
connect (AWSConfig endpoint logging credentials) service = do
    let serviceRaw = rawService service
    e <- mkEnv logging credentials
    let (r, s) = regionService endpoint serviceRaw
    session' <- return $ Session e r s
    let session = wrappedSession @a session'
    return session

mkEnv :: Logging -> Credentials -> IO Env
-- Standard discovery mechanism for credentials, log to standard output
mkEnv LoggingEnabled c = do
    logger <- newLogger Debug stdout
    newEnv c <&> set envLogger logger
-- Standard discovery mechanism for credentials, no logging
mkEnv LoggingDisabled c = newEnv c

regionService :: Endpoint -> Service -> (Region, Service)
-- Run against a DynamoDB instance running on AWS in specified region
regionService (AWSRegion region) s = (region, s)
-- Run against a local DynamoDB instance on a given host and port
regionService (Local hostName port) s = (NorthVirginia, setEndpoint False hostName port s)

withAWS :: (MonadBaseControl IO m, MonadUnliftIO m, SessionClass b) =>
    AWST' Env (ResourceT m) a
    -> b
    -> m a
withAWS action session =
    let Session{..} = rawSession session
    in
        runResourceT . runAWST _sEnv . within _sRegion $ do
            reconfigure _sService action
