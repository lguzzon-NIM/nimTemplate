
import unittest

import nimTemplate
import nimTemplate/consts


suite "unit-test suite":
    test "getMessage":
        assert(cHelloWorld == getMessage())
