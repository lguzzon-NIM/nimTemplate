
import unittest
import os
import osproc
import strutils

import nimTemplateConsts
import nimTemplate

include "../scripts/nim/scriptsEnvVarNames.nimInc"

suite "integration-test suite":
  test "getMessage excecuting the app":
    assert(cHelloWorld == execProcess(getEnv(gcApplicationToTestEnvVarName)).strip())
