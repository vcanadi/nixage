module Nixage.Convert.Stack where

import Universum

import Data.Aeson (ToJSON(..), object, (.=), Value(..))
import qualified Data.Map.Strict as M

import Nixage.Project.Types ( PackageName, PackageVersion
                            , ExternalSource(GitSource))
import Nixage.Project.Extensible (ExtraDepVersion (..), Project (..))
import Nixage.Project.Native (AstNixage, ProjectNative)


data StackExtraDepVersion =
      StackHackageDepVersion PackageVersion
    | StackGitDepVersion Text Text (Maybe FilePath) -- git, rev, subdir

data StackCustomSnapshot = StackCustomSnapshot
    { scsName :: Text
    , scsResolver :: Text
    , scsPackages :: Map PackageName StackExtraDepVersion
    }

data StackConfig = StackConfig
    { scStackCustomSnapshot :: StackCustomSnapshot
    , scPackages :: Map PackageName FilePath
    }

instance ToJSON StackCustomSnapshot where
    toJSON (StackCustomSnapshot name resolver packages) =
        object [ "name" .= name
               , "resolver" .= resolver
               , "packages" .= map packageToJson (M.toList packages)
               ]
      where
        packageToJson :: (PackageName, StackExtraDepVersion) -> Value
        packageToJson (packageName, StackHackageDepVersion packageVersion) =
            String $ packageName <> "-" <> packageVersion
        packageToJson (_, StackGitDepVersion url rev subdir) =
            object [ "git"     .= url
                   , "commit"  .= rev
                   , "subdirs" .= [fromMaybe "." subdir]
                   ]

writeStackConfig :: StackConfig -> FilePath -> (Value, Value)
writeStackConfig (StackConfig snapshot packages) snapshotPath =
    (toJSON snapshot, stackYamlBuilder)
  where
    stackYamlBuilder = object
        [ "resolver" .= snapshotPath
        , "packages" .= elems packages
        , "nix" .= nix]

    nix = object
        [ "enable" .= True
        , "shell-file" .= ("stack-shell.nix" :: Text)
        ]

-- | Convert ProjectNative AST to StackConfig
projectNativeToStackConfig :: ProjectNative -> StackConfig
projectNativeToStackConfig (Project () resolver _ _ ps eds) =
    let packages = map toStackExtraDep eds
        snapshot = StackCustomSnapshot "nixage-stack-snapshot" resolver packages
    in StackConfig snapshot ps
  where
    toStackExtraDep :: ExtraDepVersion AstNixage -> StackExtraDepVersion
    toStackExtraDep (HackageDepVersion () v) =
        StackHackageDepVersion v
    toStackExtraDep (SourceDepVersion () (GitSource git rev) _ msd) =
        StackGitDepVersion git rev msd
    toStackExtraDep (XExtraDepVersion v) =
        absurd v
