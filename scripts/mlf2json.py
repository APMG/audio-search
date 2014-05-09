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
      startTime = float(re.split('\t| ', line)[0])
      endTime = float(re.split('\t| ', line)[1])
      word = re.split('\t| ', line)[2]
      print "      \"time\": \""+ str(startTime/scale) +"\","
      print "      \"duration\": \""+ str((endTime-startTime)/scale) +"\","
      print "      \"word\": \""+ word.strip("\"") +"\""
      line = mlfFile.next()
      if line.rstrip("\n") != ".": print "    },"
      else: print "    }"
print "  ]\n}"
