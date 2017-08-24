
const
  lcisNimble = true

import sets
include "scripts/nim/scriptsIncludes.nimInc"

proc getInstallFiles (): seq[string] =

  proc lGetInstallFiles (aDir:string; aExts:HashSet[string]): seq[string] =
    result = newSeq[string]()
    for lFilePath in listFiles(aDir):
      let lExt = lFilePath.splitFile.ext.toLower
      if lExt in aExts:
        result.add(lFilePath)
    for lChildDirPath in listDirs(aDir):
      result.add(lGetInstallFiles(lChildDirPath, aExts))
    
  result = @["LICENSE", "config.nims", "README.md"]
  result.add(lGetInstallFiles(getSourceDir(), toSet([".nim", ".md"])))
  result.add(lGetInstallFiles(scriptNimDir, toSet([".niminc"])))

# Package
version = "0.0.0"
author = "Luca Guzzon"
description = "nimTemplate [PLEASE CHANGE ME]"
license = "MIT"

skipDirs = @[testDir, buildDir, scriptDir]
installFiles = getInstallFiles()

# Dependencies
requires "nim >= 0.17.0"
