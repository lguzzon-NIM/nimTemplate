
import strutils 
import ospaths

import scripts/nim/scriptsEnvVarNames
import scripts/nim/scriptsCommons
  
const
  lcTestAppFileNameEnvVarName = "testAppFileName"

mode = if getNimVerbosity() == "0": ScriptMode.Silent else: ScriptMode.Verbose 


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
  switch "path", sourceFolder
  switch "path", scriptFolder
  switch "nimcache", buildCacheTestFolder
  let lFilePath = getEnv(lcTestAppFileNameEnvVarName)
  switch "out", getTestBinaryFilePath(lFilePath)
  setCommand "compile", lFilePath


task compileAndRunTest_OSLinux_OSWindows, "":
  dependsOn compileTest_OSLinux_OSWindows
  exec gcApplicationToTestEnvVarName & "=\"" & getBuildBinaryFile() & "\" wine \"" & getTestBinaryFilePath(getEnv(lcTestAppFileNameEnvVarName)) & "\" 2>/dev/null" 
  setCommand "nop"


task compileAndRunTest, "":
  let lFilePath = getEnv(lcTestAppFileNameEnvVarName)
  switchCommon()
  switch "path", sourceFolder
  switch "path", scriptFolder
  switch "nimcache", buildCacheTestFolder
  switch "out", getTestBinaryFilePath(lFilePath)
  switch "putenv", gcApplicationToTestEnvVarName & "=" & getBuildBinaryFile()
  switch "run"
  setCommand "compile", lFilePath


task test, "test/s the project":
  dependsOn build
  for lFilePath in findTestFiles():
    var lCommandToExec = "compileAndRunTest"
    case hostOS
    of "linux":
      if (getTargetOS() == gcWindowsStr):
        lCommandToExec = "compileAndRunTest_OSLinux_OSWindows"
    selfExecWithDefaults("\"--putenv:" & lcTestAppFileNameEnvVarName & "=" & lFilePath & "\" " & lCommandToExec) 
  setCommand "nop"


task cTest, "clean and test/s the project":
  dependsOn clean test
  setCommand "nop"
  

task buildBinary, "":
  build_create()
  switchCommon()
  setCommand "compile", sourceMainFile


task build, "build the project":
  if not fileExists(getBuildBinaryFile()):
    dependsOn buildBinary
    exec "strip " & getBuildBinaryFile()
    exec "upx --best " & getBuildBinaryFile()
  setCommand "nop"
  

task cBuild, "clean and build the project":
  dependsOn clean build
  setCommand "nop"
  

task run, "run the project ex: nim --putenv:runParams=\"<Parameters>\" run":
  dependsOn build
  let params = if existsEnv("runParams"): " " & getEnv("runParams") else: ""
  let command = (getBuildBinaryFile() & params).strip()
  command.exec()
  setCommand "nop"


task cRun, "clean and run the project ex: nim --putenv:runParams=\"<Parameters>\" run":
  dependsOn clean run
  setCommand "nop"
  
  
task util_TravisEnvMatrix, "generate the complete travis-ci env matrix":
  const 
    lEnvs = @[@[gcGCCVersionToUseEnvVarName,"4.8","4.9","5","6","7"],@[gcNimBranchToUseEnvVarName,"master","devel"],@[gcTargetOSEnvVarName,"linux",gcWindowsStr],@[gcTargetCpuEnvVarName,"amd64","i386"]]
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

