
import unittest
import os
import osproc
import strutils

import mainConsts
import main


suite "main unit-test suite":
    test "getMessage":
        assert(cHelloWorld == getMessage())
