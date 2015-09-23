#!/usr/bin/env python

import getopt
from lxml import html
import sys

def main(argv):
    try:                                
        opts, args = getopt.getopt(argv, "", ["help", "file=", "ids="])
    except getopt.GetoptError:
      print 'html-rm.py --file=<inputfile> --ids=<id1>,<id2>...'
      sys.exit(2)                     
    for opt, arg in opts:
        if opt == '-h':
            print 'html-rm.py -f <inputfile> <id1> <id2>...'
            sys.exit()
        elif opt == "--file":
            inputfile = arg
        elif opt == "--ids":
            ids = arg.split()
    fhtml = open(inputfile)
    tree = html.fromstring(fhtml.read())
    fhtml.close()
    for id in ids:
        try:
            tree.get_element_by_id(id).drop_tree()
        except KeyError:
            continue
    fhtml = open(inputfile, 'w')
    tree = fhtml.write(html.tostring(tree))
    fhtml.close()

if __name__ == "__main__":
    main(sys.argv[1:])
