
when defined(js):
  discard
else:
  import unittest
  import os
  import osproc
  import strutils

  # import nimTemplate
  import nimTemplate/consts

  include "../scripts/nim/scriptsEnvVarNames.nim"

  suite "integration-test suite":
    test "getMessage excecuting the app":
      assert(cHelloWorld == execProcess(getEnv(gcApplicationToTestEnvVarName)).strip())
