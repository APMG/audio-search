#!/usr/bin/python

import sys
import re

try:
    mlfFile = sys.stdin
except:
    sys.exit("ERROR. Can't read supplied filename.")

scale = 10000000
for line in mlfFile:
  if line.rstrip("\n").endswith(".rec\""):
    filename = line.rstrip("\n")
    line = mlfFile.next()
    print "{\n  \"words\": ["
    while line.rstrip("\n") != ".":
      print "    {"
      startTime = float(line.split('\t')[0])
      endTime = float(line.split('\t')[1])
      word = line.rstrip("\n").split('\t')[2]
      print "      \"time\": \""+ str(startTime/scale) +"\","
      print "      \"duration\": \""+ str((endTime-startTime)/scale) +"\","
      print "      \"word\": \""+ word +"\""
      line = mlfFile.next()
      if line.rstrip("\n") != ".": print "    },"
      else: print "    }"
print "  ]\n}"
