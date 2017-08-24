
import nimTemplateConsts


proc getMessage*: string =
    result = cHelloWorld

when isMainModule: 
    echo getMessage()