
import unittest

import consts
import main


suite "main test suite":
    echo "main test suite"

    test "getMessage":
        assert(cHelloWorld == getMessage(),"getMessage test")
