
const
  lcisNimble = true

import sets
include "scripts/nim/scriptsIncludes.inc"

proc getInstallFiles (): seq[string] =
  let lExts = toSet([".nim", ".md"])

  proc lGetInstallFiles (aDir:string): seq[string] =
    result = newSeq[string]()
    for lFilePath in listFiles(aDir):
      let lExt = lFilePath.splitFile.ext.toLower
      if lExt in lExts:
        result.add(lFilePath)
    for lChildDirPath in listDirs(aDir):
      result.add(lGetInstallFiles(lChildDirPath))
    
  result = @[scriptDir/"nim"/"scriptsIncludes.inc",scriptDir/"nim"/"scriptsEnvVarNames.inc", "LICENSE", "config.nims", "README.md"]
  result.add(lGetInstallFiles(getSourceDir()))

# Package
version = "0.0.0"
author = "Luca Guzzon"
description = "nimTemplate [PLEASE CHANGE ME]"
license = "MIT"

skipDirs = @[testDir, buildDir, scriptDir]
installFiles = getInstallFiles()

# Dependencies
requires "nim >= 0.17.0"
