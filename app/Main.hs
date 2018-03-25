{-|
Module      : Main
Description : Demo program for @aws-easy@ module
Copyright   : (C) Richard Cook, 2018
License     : MIT
Maintainer  : rcook@rcook.org
Stability   : experimental
Portability : portable

This programs lists S3 buckets and puts an item per bucket in DynamoDB.
-}

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

module Main (main) where

import           Control.Monad (void)
import           Data.Foldable (for_)
import qualified Data.HashMap.Strict as HashMap (fromList)
import qualified Data.List.NonEmpty as NonEmpty (fromList)
import           Data.List.Split (chunksOf)
import           Data.Text (Text)
import qualified Data.Text as Text (pack)
import           Network.AWS.DynamoDB
                    ( attributeValue
                    , avS
                    , batchWriteItem
                    , bwiRequestItems
                    , dynamoDB
                    , prItem
                    , putRequest
                    , wrPutRequest
                    , writeRequest
                    )
import           Network.AWS.Easy
import           Network.AWS.S3
                    ( BucketName
                    , bName
                    , lbrsBuckets
                    , listBuckets
                    , s3
                    )
import           Network.AWS.Data (fromText)
import           System.Environment (getEnv)

newtype TableName = TableName Text deriving Show

wrapAWSService 'dynamoDB "DynamoDBService" "DynamoDBSession"
wrapAWSService 's3 "S3Service" "S3Session"

fromRight :: b -> Either a b -> b
fromRight _ (Right value) = value
fromRight value _ = value

mkConfig :: IO AWSConfig
mkConfig = do
    regionStr <- getEnv "AWS_REGION"
    let region = fromRight
                    (error $ "Unknown region " ++ regionStr) $
                    fromText (Text.pack regionStr)
    return $ awsConfig (AWSRegion region)
                & awscCredentials .~ FromEnv
                                        "AWS_ACCESS_KEY_ID"
                                        "AWS_SECRET_ACCESS_KEY"
                                        (Just "AWS_SESSION_TOKEN")
                                        (Just "AWS_REGION")

getS3BucketNames :: S3Session -> IO [BucketName]
getS3BucketNames = withAWS $ do
    response <- send listBuckets
    return $ map (^. bName) (response ^. lbrsBuckets)

putDynamoDBBucketNames :: TableName -> [BucketName] -> DynamoDBSession -> IO ()
putDynamoDBBucketNames (TableName tableName) bucketNames session = for_ (chunksOf 25 bucketNames) go
    where
        go ns = (flip withAWS) session $ do
            void $ send (batchWriteItem & bwiRequestItems .~ requestItems)
            where
                requestItems = HashMap.fromList [ (tableName, writeRequests) ]
                writeRequests = NonEmpty.fromList $
                                    map
                                        (\n ->
                                            writeRequest &
                                                wrPutRequest .~ Just (putRequest & prItem .~ item n))
                                        ns
                item n = HashMap.fromList [ ("value", attributeValue & avS .~ Just (toText n)) ]

main :: IO ()
main = do
    config <- mkConfig

    s3Session <- connect config s3Service
    bucketNames <- getS3BucketNames s3Session

    dynamoDBSession <- connect config dynamoDBService
    putDynamoDBBucketNames
        (TableName "bucket-names")
        bucketNames
        dynamoDBSession
