
import unittest
import os
import osproc
import strutils

import mainConsts
import main

include "../scripts/nim/scriptsEnvVarNames.inc"

suite "main integration-test suite":
  test "getMessage excecuting the app":
    assert(cHelloWorld == execProcess(getEnv(gcApplicationToTestEnvVarName)).strip())
