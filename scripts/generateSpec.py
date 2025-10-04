# Generate a spec json file from either
# - a project directory containing a list of directories in the format 00-name
# - a file consisting of ordered names

import sys
import os
from stat import *
import json

if __name__ == "__main__":
    project = sys.argv[1]
    spec = {
        'participants': {},
        'bgMode': 'fill'}
    if project is None:
        raise Exception("Must provide project directory/name file")
    stat = os.stat(project)
    if S_ISDIR(stat.st_mode):
        for ch in os.listdir(project):
            spec["participants"][ch.split("-")[1]] = {
                'fancyName': '',
                'color': 'white',
                'previousSantas': [],
                'socials': {
                    'twitter': '',
                    'bluesky': '',
                    'pixiv': '',
                    'deviantart': '',
                },
            }
        print(json.dumps(spec, sort_keys=True, indent=4))
    elif S_ISREG(stat.st_mode):
        print("regular file")
    else:
        raise Exception("Invalid file")
