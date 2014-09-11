import os
from os import path
import sys
import argparse

import common


def detected_boxes(data_directory, detection_type,
                   capture_ids, strict=False):

    for capture_id in capture_ids:
        box_filename = path.join(data_directory, "%06d" % capture_id,
                                 "detected_%s.txt" % detection_type)

        boxes = []
        try:
            with open(box_filename) as box_file:
                for line in box_file:
                    if len(line.strip().split()) == 4:
                        (x0, x1, y0, y1) = map(int, line.strip().split()[:4])
                        boxes.append((x0, y0, x1, y1))
                    elif  len(line.strip().split()) > 4:
                        (x0, x1, y0, y1) = map(int, line.strip().split()[:4])
                        scores = [float(x) for x in (line.strip().split()[4:])]
                        coor = [x0, y0, x1, y1]
                        boxes.append((coor+scores))
                       #boxes.append((x0, y0, x1, y1,scores))

        except IOError:
            if strict:
                raise
            else:
                print >> sys.stderr, ("Warning: couldn't read %s" %
                                      box_filename)

        yield (capture_id, boxes)


def find_capture_ids(data_directory):
    capture_ids = []
    dir_list = os.listdir(data_directory)
    for filename in dir_list:
        try:
            capture_ids.append(int(filename))
        except Exception:
            continue

    return capture_ids


parser = argparse.ArgumentParser(add_help=False)
parser.add_argument("data_directory",
                    help=("directory containing all panorama data"))


if __name__ == "__main__":

    my_parser = argparse.ArgumentParser(
            parents=[common.capture_spec_parser, parser])

    my_parser.add_argument("detection_type",
                           choices=["faces", "plates", "people", "cars"])

    my_parser.add_argument("--header-format", default="{capture_id:06d}",
                           help=("format string for header field (default "
                                 "is \"{capture_id:06d}\" for "
                                 "000001, 000002, etc.)"))

    args = my_parser.parse_args()

    capture_ids = common.get_capture_ids(**args.__dict__)
    if capture_ids is None:
        capture_ids = find_capture_ids(args.data_directory)

    for (capture_id, boxes) in detected_boxes(args.data_directory,
                                              args.detection_type,
                                              capture_ids):
        for box in boxes:
            print (args.header_format.format(capture_id=capture_id) +
                   " " + " ".join(map(str, box)))
