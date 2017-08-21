
import strutils 
import ospaths

import sources/test/nim/envVarNames

let
  targetCPU = if existsEnv(gcTargetCpuEnvVarName): getEnv(gcTargetCpuEnvVarName) else: hostCPU
  targetOS = if existsEnv(gcTargetOSEnvVarName): getEnv(gcTargetOSEnvVarName) else: hostOS
  nimVerbosity = if existsEnv(gcNimVerbosityEnvVarName): getEnv(gcNimVerbosityEnvVarName) else: "0"
  binaryFileNameNoExt = (thisDir().extractFilename & "_" & targetOS & "_" & targetCPU)
  binaryFileExt = if (targetOS == "windows"): ".exe" else: ""
  binaryFileName = if (targetOS == "windows"): binaryFileNameNoExt & binaryFileExt else: binaryFileNameNoExt
  nimFileExt = "nim"

  sourcesFolderName =  "sources"
  resourcesFolderName =  "re" & sourcesFolderName
  mainFolderName = "main"
  testFolderName = "test"
  nimFolderName = nimFileExt
  buildFolderName = "build"
  cacheFolderName = "cache"
  targetFolderName = "target"

  mainFileName  = mainFolderName

  sourcesFolder               = thisDir() / sourcesFolderName
  sourcesMainFolder           = sourcesFolder / mainFolderName
  sourcesMainNimFolder        = sourcesMainFolder / nimFolderName
  sourcesMainResourcesFolder  = sourcesMainFolder / resourcesFolderName
  sourcesTestFolder           = sourcesFolder / testFolderName
  sourcesTestNimFolder        = sourcesTestFolder / nimFolderName
  sourcesTestResourcesFolder  = sourcesTestFolder / resourcesFolderName
  sourcesMainFile             = sourcesMainNimFolder / mainFileName.changeFileExt(nimFileExt)

  buildFolder               = thisDir() / buildFolderName
  buildCacheFolder          = buildFolder / cacheFolderName
  buildTargetFolder         = buildFolder / targetFolderName
  buildTestTargetFolder     = buildCacheFolder / testFolderName
  buildBinaryFile           = buildTargetFolder / binaryFileName

mode = if existsEnv(gcNimVerbosityEnvVarName) and not(getEnv(gcNimVerbosityEnvVarName)=="0"): ScriptMode.Verbose else: ScriptMode.Silent 

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


template selfExecWithDefaults(aCommand: string) = 
  var lCmdLine = splitCmdLine()
  if (nimVerbosity=="0") and (not lCmdLine.options.contains("--hint")):
    lCmdLine.options &= " --hints:off"
  selfExec(lCmdLine.options & " " & aCommand.strip() & " " & lCmdLine.params)
  
  
template dependsOn (tasks: untyped) =
  for taskName in astToStr(tasks).split({',', ' '}):
    selfExecWithDefaults(taskName)


proc build_create () =
  for folder in @[buildCacheFolder, buildTargetFolder]:
    if not dirExists folder:
      mkdir folder


proc folders (aFolderPath: string): seq[string] =
  result = newSeq[string]()
  result.add(aFolderPath)
  for lChildFolderPath in listDirs(aFolderPath):
    result.add(folders(lChildFolderPath))


proc findTestFiles (): seq[string] =
  result = newSeq[string]()
  for lFolderPath in folders(sourcesTestFolder):
    for lFilePath in listFiles(lFolderPath):
      if lFilePath.endsWith("_test.nim"):
        result.add(lFilePath)


proc switchPathFromFolders (aFolderPath: string) =
  switch "path", aFolderPath
  for lChildPath in folders(aFolderPath):
    switch "path", lChildPath
        
        
proc switchPathBuild () =
  switchPathFromFolders(sourcesMainFolder)
  switchPathFromFolders(sourcesMainResourcesFolder)


proc switchCommon() =
  if splitCmdLine().params == "release":
    switch "define", "release"
  switch "verbosity", nimVerbosity
  switch "out", buildBinaryFile
  switch "nimcache", buildCacheFolder
  switch "app", "console"
  switch "os", targetOS
  switch "cpu", targetCPU
  if (nimVerbosity=="0"):
    switch "hints", "off"
  case hostOS
  of "linux":
    if ((hostCPU=="amd64") and (targetCPU=="i386")):
      switch "passC", "-m32"
      switch "passL", "-m32"
  of "windows":
    discard
  switchPathBuild()


proc getTestBinaryFilePath(aSourcePath:string): string =
  result = buildTestTargetFolder / splitFile(aSourcePath).name & "_" & targetOS & "_" & targetCPU & binaryFileExt


task tasks, "list all tasks":
  selfExecWithDefaults("--listCmd")
  setCommand "nop"
  

task clean, "clean the project":
  if dirExists buildFolder:
    rmdir buildFolder
  else:
    echo "Nothing to clean"
  setCommand "nop"
    

task compileTest_OSLinux_OSWindows, "":
  switchCommon()
  switchPathFromFolders(sourcesTestFolder)
  switchPathFromFolders(sourcesTestResourcesFolder)
  switch "nimcache", buildTestTargetFolder
  let lFilePath = getEnv("compileAndRunTest")
  switch "out", getTestBinaryFilePath(lFilePath)
  setCommand "compile", lFilePath


task compileAndRunTest_OSLinux_OSWindows, "":
  dependsOn compileTest_OSLinux_OSWindows
  exec gcApplicationToTestEnvVarName & "=\"" & buildBinaryFile & "\" wine \"" & getTestBinaryFilePath(getEnv("compileAndRunTest")) & "\" 2>/dev/null" 
  setCommand "nop"


task compileAndRunTest, "":
  let lFilePath = getEnv("compileAndRunTest")
  switchCommon()
  switchPathFromFolders(sourcesTestFolder)
  switchPathFromFolders(sourcesTestResourcesFolder)
  switch "nimcache", buildTestTargetFolder
  switch "out", getTestBinaryFilePath(lFilePath)
  switch "putenv", gcApplicationToTestEnvVarName & "=" & buildBinaryFile
  switch "run"
  setCommand "compile", lFilePath


task test, "test/s the project":
  dependsOn build
  for lFilePath in findTestFiles():
    var lCommandToExec = "compileAndRunTest"
    case hostOS
    of "linux":
      if (targetOS=="windows"):
        lCommandToExec = "compileAndRunTest_OSLinux_OSWindows"
    selfExecWithDefaults("\"--putenv:compileAndRunTest=" & lFilePath & "\" " & lCommandToExec) 
  setCommand "nop"


task cTest, "clean and test/s the project":
  dependsOn clean test
  setCommand "nop"
  

task buildBinary, "":
  build_create()
  switchCommon()
  setCommand "compile", sourcesMainFile


task build, "build the project":
  if not fileExists(buildBinaryFile):
    dependsOn buildBinary
    exec "strip " & buildBinaryFile
    exec "upx --best " & buildBinaryFile
  setCommand "nop"
  

task cBuild, "clean and build the project":
  dependsOn clean build
  setCommand "nop"
  

task run, "run the project ex: nim --putenv:runParams=\"<Parameters>\" run":
  dependsOn build
  let params = if existsEnv("runParams"): " " & getEnv("runParams") else: ""
  let command = (buildBinaryFile & params).strip()
  command.exec()
  setCommand "nop"


task cRun, "clean and run the project ex: nim --putenv:runParams=\"<Parameters>\" run":
  dependsOn clean run
  setCommand "nop"
  
  
task util_TravisEnvMatrix, "generate the complete travis-ci env matrix":
  const 
    lEnvs = @[@[gcGCCVersionToUseEnvVarName,"4.8","4.9","5","6","7"],@[gcNimBranchToUseEnvVarName,"master","devel"],@[gcTargetOSEnvVarName,"linux","windows"],@[gcTargetCpuEnvVarName,"amd64","i386"]]
    lEnvsLow = lEnvs.low
    lEnvsHigh = lEnvs.high
  var  
    lResult = ""

  proc lGetEnvValue(aResult: string, aIndex: int) =
    if aIndex <= lEnvsHigh:
      let lHeader = aResult & " " & lEnvs[aIndex][0] & "="
      for lIndex in 1..lEnvs[aIndex].high:
        lGetEnvValue( lHeader & lEnvs[aIndex][lIndex], aIndex + 1)
    else:
      lResult &= aResult & "\n"
  
  lGetEnvValue("",lEnvsLow)
  echo lResult
  setCommand "nop"

