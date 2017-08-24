
import unittest
import os
import osproc
import strutils

import nimTemplateConsts
import nimTemplate


suite "unit-test suite":
    test "getMessage":
        assert(cHelloWorld == getMessage())
