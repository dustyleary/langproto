import os

from driver import myExec

def isTest(filename):
    if not filename.endswith('.py'): return False
    return filename.startswith("test")

tests = [f for f in os.listdir('.') if isTest(f)]

for t in tests:
    print t
    print myExec('python %s' % t)

