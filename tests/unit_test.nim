
import unittest
import os
import osproc
import strutils

import nimTemplate
import nimTemplate.consts


suite "unit-test suite":
    test "getMessage":
        assert(cHelloWorld == getMessage())
