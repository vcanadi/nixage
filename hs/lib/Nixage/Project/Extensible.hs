{-# LANGUAGE UndecidableInstances #-}

module Nixage.Project.Extensible
  ( Project (..)
  , XProject

  , ExtraDepVersion (..)
  , XHackageDepVersion
  , XSourceDepVersion
  , XXExtraDepVersion
  ) where

import Data.Aeson (FromJSON)
import Data.Map (Map)
import Data.Text (Text)
import GHC.Generics (Generic)
import Universum

import Nixage.Project.Types ( NixHash, NixpkgsVersion, StackageVersion
                            , PackageName, PackageVersion, ExternalSource
                            , PackagePath)


-- | Extensible project specification AST
data Project x = Project
    { pXProject :: !(XProject x)
    , pResolver :: Text
    , pNixpkgs  :: Maybe NixpkgsVersion
    , pStackage :: Maybe StackageVersion
    , pPackages :: Map PackageName PackagePath
    , pExtraDeps :: Map PackageName (ExtraDepVersion x)
    }
  deriving (Generic)

type family XProject x :: *

type family XHackageDepVersion x :: *
type family XSourceDepVersion x :: *
type family XXExtraDepVersion x :: *

-- | Extensible package version specification
data ExtraDepVersion x
    = HackageDepVersion !(XHackageDepVersion x) PackageVersion
    | SourceDepVersion !(XSourceDepVersion x) ExternalSource NixHash (Maybe FilePath)
    | XExtraDepVersion !(XXExtraDepVersion x)
  deriving (Generic)

deriving instance
  ( Eq (XHackageDepVersion x)
  , Eq (XSourceDepVersion x)
  , Eq (XXExtraDepVersion x)
  ) => Eq (ExtraDepVersion x)

