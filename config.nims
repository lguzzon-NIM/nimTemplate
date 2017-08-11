
import strutils 
import ospaths

let
  targetCpuEnvVarName = "nimTargetCPU"
  targetOSEnvVarName = "nimTargetOS"
  nimVerbosityEnvVarName = "nimVerbosity"
  targetCPU = if existsEnv(targetCpuEnvVarName): getEnv(targetCpuEnvVarName) else: hostCPU
  targetOS = if existsEnv(targetOSEnvVarName): getEnv(targetOSEnvVarName) else: hostOS
  nimVerbosity = if existsEnv(nimVerbosityEnvVarName): getEnv(nimVerbosityEnvVarName) else: "1"
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

mode = if existsEnv(nimVerbosityEnvVarName) and not(getEnv(nimVerbosityEnvVarName)=="0"): ScriptMode.Verbose else: ScriptMode.Silent 
  
proc paramString():string = 
  result = ""
  if paramCount() > 1:
    result &= paramStr(2)


template dependsOn (tasks: untyped) =
  for taskName in astToStr(tasks).split({',', ' '}):
    selfExec(taskName & " " & paramString())


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
  if ((paramString() == "release") or (existsEnv("paramString") and (getEnv("paramString") == "release"))):
    switch "define", "release"
  switch "verbosity", nimVerbosity
  switch "out", buildBinaryFile
  switch "nimcache", buildCacheFolder
  switch "os", targetOS
  switch "cpu", targetCPU
  case hostOS
  of "linux":
    if ((hostCPU=="amd64") and (targetCPU=="i386")):
      switch "passC", "-m32"
      switch "passL", "-m32"
  of "windows":
    discard
  switchPathBuild()


task tasks, "list all tasks":
  selfExec("--listCmd")
  setCommand "nop"
  

task clean, "cleans the project":
  if dirExists buildFolder:
    rmdir buildFolder
  else:
    echo "Nothing to clean"
  setCommand "nop"
    

task compileAndRunTest, "interal - Compile and run test program":

  let lFilePath = getEnv("compileAndRunTest")
  switchCommon()
  switchPathFromFolders(sourcesTestFolder)
  switchPathFromFolders(sourcesTestResourcesFolder)
  switch "nimcache", buildTestTargetFolder
  switch "out", buildTestTargetFolder / "test" & binaryFileExt
  switch "putenv", "appToTest=" & buildBinaryFile
  switch "run"
  setCommand "compile", lFilePath
  

task test, "tests the project":
  dependsOn build
  for lFilePath in findTestFiles():
    selfExec("\"--putenv:paramString=" & paramString() & "\" " & "\"--putenv:compileAndRunTest=" & lFilePath & "\" " & "compileAndRunTest") 
  setCommand "nop"
  

task cTest, "clean test the project":
  dependsOn clean test


task build, "builds the project":
  build_create()
  switchCommon()
  setCommand "compile", sourcesMainFile


task cBuild, "clean build the project":
  dependsOn clean build
  setCommand "nop"
  

task init, "initialize a project":
  for folder in @[sourcesMainNimFolder, sourcesMainResourcesFolder, sourcesTestNimFolder, sourcesTestResourcesFolder]:
    mkdir folder
  writeFile(sourcesMainFile, "echo \"Hello world\"")
  setCommand "nop"
  

task run, "runs the project":
  dependsOn build
  var command = buildBinaryFile
  for parameterIndex in 2..paramCount():
    command &= ' ' & paramStr(parameterIndex)
  exec command
  setCommand "nop"


task generateTravisEnvMatrix, "generate the complete travis-ci env matrix":
  const 
    lEnvs = @[@["useGCC","4.8","4.9","5","6","7"],@["nim_branch","master","devel"],@[targetOSEnvVarName,"linux","windows"],@[targetCpuEnvVarName,"amd64","i386"]]
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


task params, "debug - show params":
  echo paramString()
  setCommand "nop"
  
  