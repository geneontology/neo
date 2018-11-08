#!/usr/bin/env python3

__author__ = 'cjm'

import argparse
import sys
import os
import json

def main():

    parser = argparse.ArgumentParser(description='NEO'
                                                 'NEO Builder',
                                     formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('-i', '--input', type=str, default='datasets.json', required=False,
                        help='Input metadata file')


    args = parser.parse_args()
    f = open(args.input, 'r')
    datasets = json.loads(f.read())
    f.close()
    build(datasets, args)

def build(datasets, args):
    #print("Datasets: "+str(datasets))
    smap = {}
    for d in datasets:
        dn = d['dataset']
        t = d['type']
        # temporary: see https://github.com/geneontology/go-site/issues/595
        if t == 'gpi' and dn != 'wb':
            smap[dn] = d
        elif t == 'gaf':
            if dn not in smap:
                smap[dn] = d
    for (db,obj) in smap.items():
        sp = db ## TODO
        if 'species_code' in obj:
            sp = obj['species_code']
            if sp is None:
                sp = db
        if 'source' not in obj:
            print("No URL: {} {}".format(db, obj))
        url = obj['source']
        toks = url.split("/")
        bn = "mirror/"+toks[-1]
        cmd = "./" + obj['type'] +"2obo.pl"

        extra_args = ""
        if 'isoform' in bn:
            extra_args += " -I"
        target(bn,[],
               "wget --no-check-certificate "+url+" -O $@.tmp && mv $@.tmp $@")
        target("target/neo-"+db+".obo",[bn],
               "gzip -dc "+bn+" | " + cmd + " -s "+ sp + " -n " + db + extra_args + " > $@.tmp && mv $@.tmp $@")
            

def target(tgt,deps,cmd):
    print(tgt+": "+" ".join(deps))
    print("\t"+cmd)
    print("\n")
        

if __name__ == "__main__":
    main()

    
    
