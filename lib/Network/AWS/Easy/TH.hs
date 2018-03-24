{-|
Module      : Network.AWS.Easy.TH
Description : Template Haskell helpers for @Network.AWS.Easy@
Copyright   : (C) Richard Cook, 2018
License     : MIT
Maintainer  : rcook@rcook.org
Stability   : experimental
Portability : portable

This module provides Template Haskell helper functions for generating type-safe service/session wrappers for @amazonka@.
-}

{-# LANGUAGE TemplateHaskell #-}

module Network.AWS.Easy.TH
    ( wrapAWSService
    ) where

import           Language.Haskell.TH
import           Network.AWS (Service)
import           Network.AWS.Easy.Classes
import           Network.AWS.Easy.Types

-- |Generates type-safe AWS service and session wrapper types for use with
-- 'AWSViaHaskell.AWSService.connect' and 'AWSViaHaskell.AWSService.withAWS' functions
--
-- Example top-level invocation:
--
-- @
-- {-\# LANGUAGE TemplateHaskell \#-}
-- {-\# LANGUAGE TypeFamilies \#-}
--
-- module MyApp.Services
--     ( DynamoDBService
--     , DynamoDBSession
--     , dynamoDBService
--     ) where
--
-- import Network.AWS.DynamoDB (dynamoDB)
-- import Network.AWS.Easy (wrapAWSService)
--
-- wrapAWSService \'dynamoDB \"DynamoDBService\" \"DynamoDBSession\"
-- @
--
-- This will generate boilerplate like the following:
--
-- @
-- data DynamoDBService = DynamoDBService Service
--
-- data DynamoDBSession = DynamoDBSession Session
--
-- instance ServiceClass DynamoDBService where
--     type TypedSession DynamoDBService = DynamoDBSession
--     rawService (DynamoDBService x) = x
--     wrappedSession = DynamoDBSession
--
-- instance SessionClass DynamoDBSession where
--     rawSession (DynamoDBSession x) = x
--
-- dynamoDBService :: DynamoDBService
-- dynamoDBService = DynamoDBService dynamoDB
-- @
wrapAWSService ::
    Name        -- ^ Name of the amazonka 'Network.AWS.Types.Service' value to wrap
    -> String   -- ^ Name of the service type to generate
    -> String   -- ^ Name of the session type to generate
    -> Q [Dec]  -- ^ Declarations for splicing into source file
wrapAWSService varN serviceTypeName sessionTypeName = do
    serviceVarN <- newName "x"
    sessionVarN <- newName "x"
    let serviceN = mkName serviceTypeName
        sessionN = mkName sessionTypeName
        wrappedVarN = mkName $ nameBase varN ++ "Service"
        serviceD = DataD [] serviceN [] Nothing [NormalC serviceN [(Bang NoSourceUnpackedness NoSourceStrictness, ConT ''Service)]] []
        sessionD = DataD [] sessionN [] Nothing [NormalC sessionN [(Bang NoSourceUnpackedness NoSourceStrictness, ConT ''Session)]] []
        serviceInst = InstanceD
                        Nothing
                        []
                        (AppT (ConT ''ServiceClass) (ConT serviceN))
                        [ TySynInstD ''TypedSession (TySynEqn [ConT serviceN] (ConT sessionN))
                        , FunD 'rawService [Clause [ConP serviceN [VarP serviceVarN]] (NormalB (VarE serviceVarN)) []]
                        , ValD (VarP 'wrappedSession) (NormalB (ConE $ mkName sessionTypeName)) []
                        ]
        sessionInst = InstanceD
                        Nothing
                        []
                        (AppT (ConT ''SessionClass) (ConT sessionN))
                        [ FunD 'rawSession [Clause [ConP sessionN [VarP sessionVarN]] (NormalB (VarE sessionVarN)) []]
                        ]
        sig = SigD wrappedVarN (ConT serviceN)
        var = ValD (VarP wrappedVarN) (NormalB (AppE (ConE serviceN) (VarE $ varN))) []
    pure
        [ serviceD
        , sessionD
        , serviceInst
        , sessionInst
        , sig
        , var
        ]
