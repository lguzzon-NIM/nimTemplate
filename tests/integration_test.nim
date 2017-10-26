
import unittest

when defined(js):
  discard
else:
  import os
  import osproc
  import strutils

  import nimTemplate
  import nimTemplate.consts

  include "../scripts/nim/scriptsEnvVarNames.nimInc"

  suite "integration-test suite":
    test "getMessage excecuting the app":
      assert(cHelloWorld == execProcess(getEnv(gcApplicationToTestEnvVarName)).strip())
