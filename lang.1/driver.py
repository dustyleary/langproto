import os.path
import subprocess
import sys

import compiler
import sexpr

def myExec(cmdline):
    try:
        p = subprocess.Popen(cmdline, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except Exception:
        print '='*20
        print cmdline
        raise
    out,err = p.communicate()
    if p.returncode != 0:
        print '='*20
        print cmdline
        print 'stdout' + '-'*14
        print out
        print 'stderr' + '-'*14
        print err
        print '='*20
        raise Exception("command failed")
    return out
 
def llvmTargetInfo():
    f = open(".temp.c", 'wt')
    f.close()
    result = myExec('llvm-gcc --emit-llvm -S .temp.c -o -')
    os.unlink(".temp.c")
    return result

def runProgram(program):
    sexprs = sexpr.parse(program)
    asm = compiler.compile(sexprs)
    llvmPrelude = llvmTargetInfo()
    f = open("out.ll", 'wt')
    f.write(llvmPrelude)
    f.write(asm)
    f.close()
    outName = 'out'
    if sys.platform == 'win32':
        outName += '.exe'
    while os.path.exists(outName):
        os.unlink(outName)
    myExec("llvmc driver.c out.ll -o out")
    if sys.platform == 'win32':
        return myExec("out")
    else:
        return myExec("./out")

def testCase(expect, program):
    output = runProgram(program)
    if output != expect:
        print "FAIL"
        print "expected:",expect
        print "received:",output
        print "program:",program
        sys.exit(1)
    print "PASS"

