
import unittest
import os
import osproc
import strutils

import nimTemplateConsts
import nimTemplate

include "../scripts/nim/scriptsEnvVarNames.inc"

suite "integration-test suite":
  test "getMessage excecuting the app":
    assert(cHelloWorld == execProcess(getEnv(gcApplicationToTestEnvVarName)).strip())
