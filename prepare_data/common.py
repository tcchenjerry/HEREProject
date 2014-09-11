import argparse


def get_range(*args):
    if not args:
        return []
    elif len(args) == 1:
        return [args[0]]
    elif len(args) == 2:
        return range(*args)
    elif len(args) == 3:
        return range(*args)
    else:
        raise TypeError("Expected 3 or fewer arguments")


def parse_ranges(s):
    return sum((get_range(*map(int, t.split(":")))
                for t in s.split(",")),
               [])


def get_capture_ids(**kwargs):
    '''
    Return capture IDs from command line arguments when called as

        get_capture_ids(**parser.parse_args().__dict__)

    where parser has capture_spec_parser as a parent.  None is returned
    if no captures were specified.

    '''
    if not (kwargs['captures'] or kwargs['capture_id_filenames']):
        return None
    else:
        capture_ids = []
        for capture_spec in kwargs['captures']:
            capture_ids.extend(parse_ranges(capture_spec))

        for capture_id_filename in kwargs['capture_id_filenames']:
            with open(capture_id_filename) as capture_id_file:
                for line in capture_id_file:
                    capture_ids.append(int(line.strip()))

        return capture_ids


capture_spec_parser = argparse.ArgumentParser(add_help=False)

capture_spec_parser.add_argument(
        "--captures",
        action="append", default=[],
        help=("which captures to consider "
              "(example: 0:2,4:10:2 for "
              "[0,1,4,6,8])."))

capture_spec_parser.add_argument(
        "--captures-from-file",
        action="append", default=[],
        dest="capture_id_filenames",
        help=("read capture IDs from a text file "
              "(same format as \"metadata file\" used "
              "for panorama processing)"))
