
import strutils 
import ospaths

mode = ScriptMode.Verbose

let
  targetCpuEnvVarName = "nimTargetCPU"
  targetOSEnvVarName = "nimTargetOS"
  nimVerbosityEnvVarName = "nimVerbosity"
  targetCPU = if existsEnv(targetCpuEnvVarName): getEnv(targetCpuEnvVarName) else: hostCPU
  targetOS = if existsEnv(targetOSEnvVarName): getEnv(targetOSEnvVarName) else: hostOS
  nimVerbosity = if existsEnv(nimVerbosityEnvVarName): getEnv(nimVerbosityEnvVarName) else: "1"
  binaryFileNameNoExt = (thisDir().extractFilename & "_" & targetOS & "_" & targetCPU)
  binaryFileName = if (targetOS == "windows"): binaryFileNameNoExt & ".exe" else: binaryFileNameNoExt
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
  buildTestTargetFolder     = buildTargetFolder / testFolderName
  buildBinaryFile           = buildTargetFolder / binaryFileName




template dependsOn (tasks: untyped) =
  for taskName in astToStr(tasks).split({',', ' '}):
    exec selfExe() & " " & taskName


proc build_create () =
  for folder in @[buildCacheFolder, buildTargetFolder]:
    if not dirExists folder:
      mkdir folder


proc folders (dir: string): seq[string] =
  result = newSeq[string]()
  result.add(dir)
  for child in listDirs(dir):
    result.add(folders(child))


proc findTestFiles (): seq[string] =
  result = newSeq[string]()
  for folder in folders(sourcesTestFolder):
    for file in listFiles(folder):
      if file.endsWith("_test.nim"):
        result.add(file)

proc addAllBuildPaths () =
  switch "path", sourcesMainFolder
  for folder in folders(sourcesMainFolder):
    switch "path", folder
  if existsDir sourcesMainResourcesFolder:
    switch "path", sourcesMainResourcesFolder


proc collectPaths (folder: string): string =
  result = ""
  for child in folders(folder):
    result &= " --path:" & child


task tasks, "list all tasks":
  exec selfExe() & " --listCmd"


task clean, "cleans the project":
  if dirExists buildFolder:
    rmdir buildFolder
  else:
    echo "Nothing to clean"


task test, "tests the project":
  build_create()

  var command = selfExe() & " compile"
  command &= collectPaths(sourcesMainFolder)
  command &= collectPaths(sourcesMainResourcesFolder)
  command &= collectPaths(sourcesTestFolder)
  command &= collectPaths(sourcesTestResourcesFolder)

  command &= " --nimcache:" & buildCacheFolder
  command &= " --out:" & buildTestTargetFolder
  command &= " --verbosity:" & nimVerbosity  
  command &= " --run "

  for file in findTestFiles():
    exec command & file
  rmFile buildTestTargetFolder


task cTest, "clean test the project":
  dependsOn clean test


task build, "builds the project":
  if paramCount() == 2 and paramStr(2) == "release":
    dependsOn test
    switch "define", "release"

  build_create()
  
  switch "verbosity", nimVerbosity
  switch "out", buildBinaryFile
  switch "nimcache", buildCacheFolder

  addAllBuildPaths()
  setCommand "compile", sourcesMainFile


task cBuild, "clean build the project":
  dependsOn clean build


task init, "initialize a project":
  for folder in @[sourcesMainNimFolder, sourcesMainResourcesFolder, sourcesTestNimFolder, sourcesTestResourcesFolder]:
    mkdir folder
  writeFile(sourcesMainFile, "echo \"Hello world\"")


task run, "runs the project":
  dependsOn build

  var command = buildBinaryFile
  for parameterIndex in 2..paramCount():
    command &= ' ' & paramStr(parameterIndex)

  exec command
  setCommand "nop"

task buildReleaseFromEnv, "build release using env vars":
  build_create()

  switch "verbosity", nimVerbosity
  switch "nimcache", buildCacheFolder

  switch "os", targetOS
  echo "os: " & targetOS

  switch "cpu", targetCPU
  echo "cpu: " & targetCPU


  case hostOS
  of "linux":
    if ((hostCPU=="amd64") and (targetCPU=="i386")):
      switch "passC", "-m32"
      switch "passL", "-m32"
  of "windows":
    if ((hostCPU=="amd64") and (targetCPU=="i386")):
      put("i386.windows.gcc.exe", "x86_64-w64-mingw32-gcc")
      put("i386.windows.gcc.linkerexe", "x86_64-w64-mingw32-gcc")
  
  switch "define", "release"
  switch "out", buildBinaryFile

  addAllBuildPaths()

  setCommand "compile", sourcesMainFile


task generateTravisEnvMatrix, "generate the complete travis-ci env matrix":
  let 
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
  
  lGetEnvValue("",0)
  echo lResult

  setCommand "nop"