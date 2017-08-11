
import unittest
import os
import osproc
import strutils

import consts
import main


suite "main integration-test suite":
    test "getMessage excecuting the app":
        assert(cHelloWorld == execProcess(getEnv("appToTest")).strip())
