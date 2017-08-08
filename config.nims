
import strutils 
import ospaths

mode = ScriptMode.Verbose

let
  releaseCpuEnvVarName = "nimTargetCPU"
  releaseOSEnvVarName = "nimTargetOS"
  nimVerbosityEnvVarName = "nimVerbosity"
  buildCPU = if existsEnv(releaseCpuEnvVarName): getEnv(releaseCpuEnvVarName) else: hostCPU
  buildOS = if existsEnv(releaseOSEnvVarName): getEnv(releaseOSEnvVarName) else: hostOS
  nimVerbosity = if existsEnv(nimVerbosityEnvVarName): getEnv(nimVerbosityEnvVarName) else: "1"
  binaryFileName = (thisDir().extractFilename & "_" & buildOS & "_" & buildCPU).toExe
  nimFileExt = "nim"
  version       = "1.1.0"

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
    exec "nim " & taskName


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
  exec "nim --listCmd"


task clean, "cleans the project":
  if dirExists buildFolder:
    rmdir buildFolder
  else:
    echo "Nothing to clean"


task test, "tests the project":
  build_create()

  var command = "nim compile"
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

  switch "cpu", buildCPU
  echo "cpu: " & buildCPU

  if ((hostOS=="linux") and ((hostCPU=="amd64") and (buildCPU=="i386"))):
    switch "passC", "-m32"
    switch "passL", "-m32"

  switch "os", buildOS
  echo "os: " & buildOS

  switch "define", "release"
  switch "out", buildBinaryFile

  addAllBuildPaths()

  setCommand "compile", sourcesMainFile

