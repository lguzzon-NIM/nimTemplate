
import strutils 
import ospaths

import scriptsEnvVarNames

const
    gcWindowsStr*             = "windows"
    nimFileExt                = "nim"
  
    sourceFolderName          = "sources"
    testFolderName            = "tests"
    
    buildFolderName           = "builds"
    cacheFolderName           = "caches"
    targetFolderName          = "targets"
    scriptFolderName          = "scripts"
    
    mainFileName              = "main.nim"
  
    sourceFolder*             = sourceFolderName
    sourceMainFile*           = sourceFolderName / mainFileName
  
    testFolder                = testFolderName
  
    buildFolder*              = buildFolderName
    buildCacheFolder          = buildFolder / cacheFolderName
    buildCacheTestFolder*     = buildCacheFolder / testFolderName
    buildTargetFolder         = buildFolder / targetFolderName
    buildTargetTestFolder*    = buildTargetFolder & "_" & testFolderName
    scriptFolder*             = scriptFolderName / nimFileExt
  
proc getTargetOS* () : string = 
  if existsEnv(gcTargetOSEnvVarName): getEnv(gcTargetOSEnvVarName) else: hostOS

proc getTargetCPU() : string =
   if existsEnv(gcTargetCpuEnvVarName): getEnv(gcTargetCpuEnvVarName) else: hostCPU

proc getNimVerbosity*() : string =
   if existsEnv(gcNimVerbosityEnvVarName): getEnv(gcNimVerbosityEnvVarName) else: "0"

proc getBinaryFileNameNoExt() : string =
   thisDir().extractFilename & "_" & getTargetOS() & "_" & getTargetCPU()

proc getBinaryFileExt() : string =
   if (getTargetOS() == gcWindowsStr): ".exe" else: ""

proc getBinaryFileName() : string =
   if (getTargetOS() == gcWindowsStr): getBinaryFileNameNoExt() & getBinaryFileExt() else: getBinaryFileNameNoExt()

proc getBuildBinaryFile* () : string =
   buildTargetFolder  / getBinaryFileName()

proc splitCmdLine() : tuple[options, command, params: string] =
  var lIndex = 1
  let lCount = paramCount()
  var lResult = ""
  while lIndex <= lCount:
    if paramStr(lIndex)[0] == '-':
      lResult &= " " & "\"" & paramStr(lIndex) & "\""      
      lIndex.inc
    else:
      break
  result.options = lResult.strip()
  if (lIndex <= lCount):
    result.command = paramStr(lIndex).strip()
    lIndex.inc
  lResult = ""
  while lIndex <= lCount:
    lResult &= " "  & paramStr(lIndex) 
    lIndex.inc
  result.params = lResult.strip()


template selfExecWithDefaults* (aCommand: string) = 
  var lCmdLine = splitCmdLine()
  if (getNimVerbosity() == "0") and (not lCmdLine.options.contains("--hint")):
    lCmdLine.options &= " --hints:off"
  selfExec(lCmdLine.options & " " & aCommand.strip() & " " & lCmdLine.params)
  
  
template dependsOn* (tasks: untyped) =
  for taskName in astToStr(tasks).split({',', ' '}):
    selfExecWithDefaults(taskName)


proc build_create* () =
  for folder in @[buildCacheFolder, buildTargetFolder, buildTargetTestFolder]:
    if not dirExists folder:
      mkdir folder


proc folders (aFolderPath: string): seq[string] =
  result = newSeq[string]()
  result.add(aFolderPath)
  for lChildFolderPath in listDirs(aFolderPath):
    result.add(folders(lChildFolderPath))


proc findTestFiles* (): seq[string] =
  result = newSeq[string]()
  for lFolderPath in folders(testFolder):
    for lFilePath in listFiles(lFolderPath):
      if lFilePath.endsWith("_test.nim"):
        result.add(lFilePath)


proc switchCommon* () =
  let lNimVerbosity = getNimVerbosity()
  if splitCmdLine().params == "release":
    switch "define", "release"
  switch "verbosity", lNimVerbosity
  switch "out", getBuildBinaryFile()
  switch "nimcache", buildCacheFolder
  switch "app", "console"
  switch "os", getTargetOS()
  let lTargetCPU = getTargetCPU()
  switch "cpu", lTargetCPU
  if (lNimVerbosity == "0"):
    switch "hints", "off"
  case hostOS
  of "linux":
    if ((hostCPU == "amd64") and (lTargetCPU == "i386")):
      switch "passC", "-m32"
      switch "passL", "-m32"
  of gcWindowsStr:
    discard


proc getTestBinaryFilePath* (aSourcePath:string): string =
  result = buildTargetTestFolder / splitFile(aSourcePath).name & "_" & getTargetOS() & "_" & getTargetCPU() & getBinaryFileExt()


