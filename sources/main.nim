
import mainConsts

proc getMessage*: string =
    result = cHelloWorld

when isMainModule: 
    echo getMessage()