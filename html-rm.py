#!/usr/bin/env python

import getopt
from lxml import html
import sys

def main(argv):
    try:                                
        opts, args = getopt.getopt(argv, "", ["help", "file=", "xpaths="])
    except getopt.GetoptError:
      print 'html-rm.py --file=<inputfile> --xpaths="<xpath1> <xpath2>"'
      sys.exit(2)                     
    for opt, arg in opts:
        if opt == '-h':
            print 'html-rm.py -f <inputfile> <id1> <id2>...'
            sys.exit()
        elif opt == "--file":
            inputfile = arg
        elif opt == "--xpaths":
            xpaths = arg.split()
    fhtml = open(inputfile)
    tree = html.fromstring(fhtml.read())
    fhtml.close()
    for xpath in xpaths:
        for el in tree.xpath(xpath):
            el.drop_tree()
    fhtml = open(inputfile, 'w')
    tree = fhtml.write(html.tostring(tree))
    fhtml.close()

if __name__ == "__main__":
    main(sys.argv[1:])
