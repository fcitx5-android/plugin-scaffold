{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ViewPatterns #-}
{-# OPTIONS_GHC -Wall #-}

module Main where

import Data.Text (Text)
import Data.Text qualified as T
import Development.Shake hiding ((~>))
import Development.Shake.Config
import Development.Shake.FilePath
import Text.Mustache

main :: IO ()
main = shakeArgs shakeOptions $ do
  usingConfigFile "build.cfg"
  fileRule
  want $
    ("out" </>)
      <$> [
            -- gradle wrapper
            "gradle/wrapper/gradle-wrapper.jar",
            "gradle/wrapper/gradle-wrapper.properties",
            "gradlew",
            "gradlew.bat",
            -- project gradle
            "gradle.properties",
            "build.gradle.kts",
            "settings.gradle.kts",
            -- project gitignore
            ".gitignore",
            "README.md",
            -- nix
            "flake.nix",
            "shell.nix",
            -- app gradle
            "app/build.gradle.kts",
            -- app gitignore
            "app/.gitignore",
            -- app manifest
            "app/src/main/AndroidManifest.xml",
            -- app res
            "app/src/main/res/values/strings.xml",
            "app/src/main/res/xml/plugin.xml",
            -- app assets
            "app/src/main/assets/README.md"
          ]
  phony "clean" $ removeFilesAfter "out" ["//*"]

fileRule :: Rules ()
fileRule =
  "out//*" %> \out -> do
    let fp = dropDirectory1 out
    cfg <- getProjectConfig
    let templateFile = "templates" </> fp <.> "mustache"
    hasTemplate <- doesFileExist templateFile
    if hasTemplate
      then
        readFile' templateFile >>= \content -> case compileTemplate templateFile (T.pack content) of
          Right template -> case checkedSubstitute template cfg of
            ([], result) -> writeFile' out (T.unpack result)
            (err, _) -> fail $ "Failed to substitute template: " <> show err
          Left err -> fail $ "Failed to compile template: " <> show err
      else copyFile' ("fixtures" </> fp) out

getProjectConfig :: Action ProjectConfig
getProjectConfig =
  ProjectConfig
    <$> getConfig' "project_name"
    <*> getConfig' "aboutlibraries_version"
    <*> getConfig' "main_version"
    <*> getConfig' "desugarJDKLibs_version"
    <*> getConfig' "kotlin_version"
    <*> getConfig' "android_version"
    <*> getConfig' "build_version_name"
    <*> (read . T.unpack <$> getConfig' "version_code")
    <*> getConfig' "build_commit_hash"
    <*> getConfig' "package_name"
    <*> getConfig' "app_name_debug"
    <*> getConfig' "app_name_release"
    <*> getConfig' "plugin_description"
    <*> getConfig' "plugin_api_version"
    <*> ( getConfig "plugin_domain" >>= \case
            Just (T.pack -> x) | not $ T.null x -> pure $ pure x
            _ -> pure mempty
        )
  where
    getConfig' key =
      getConfig key >>= \case
        Just x -> pure $ T.pack x
        _ -> fail $ "Missing " <> key <> " in config"

data ProjectConfig = ProjectConfig
  { projectName :: Text,
    aboutlibrariesVersion :: Text,
    mainVersion :: Text,
    desugarJDKLibsVersion :: Text,
    kotlinVersion :: Text,
    androidVersion :: Text,
    buildVersionName :: Text,
    versionCode :: Int,
    buildCommitHash :: Text,
    packageName :: Text,
    appNameDebug :: Text,
    appNameRelease :: Text,
    pluginDescription :: Text,
    pluginAPIVersion :: Text,
    pluginDomain :: Maybe Text
  }
  deriving (Show, Eq)

instance ToMustache ProjectConfig where
  toMustache ProjectConfig {..} =
    object $
      [ "project_name" ~> projectName,
        "aboutlibraries_version" ~> aboutlibrariesVersion,
        "main_version" ~> mainVersion,
        "desugarJDKLibs_version" ~> desugarJDKLibsVersion,
        "kotlin_version" ~> kotlinVersion,
        "android_version" ~> androidVersion,
        "build_version_name" ~> buildVersionName,
        "version_code" ~> versionCode,
        "build_commit_hash" ~> buildCommitHash,
        "package_name" ~> packageName,
        "app_name_debug" ~> appNameDebug,
        "app_name_release" ~> appNameRelease,
        "plugin_description" ~> pluginDescription,
        "plugin_api_version" ~> pluginAPIVersion
      ]
        <> maybe
          ["has_domain" ~> False]
          (\domain -> ["has_domain" ~> True, "plugin_domain" ~> domain])
          pluginDomain
