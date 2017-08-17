
import unittest
import os
import osproc
import strutils

import envVarNames

import consts
import main

suite "main integration-test suite":
    test "getMessage excecuting the app":
        assert(cHelloWorld == execProcess(getEnv(gcApplicationToTestEnvVarName)).strip())
