import json
import argparse

import sqlite3

import common


def boxes_from_db(db_filename, detection_type, x_stride, y_offset,
                  capture_ids=None):
    '''
    Return the training bounding boxes of the specified type from the
    given database file.  The return value is a dictionary

        { capture_id: [(x0, y0, x1, y1), ...], ... }.

    '''
    con = sqlite3.connect(db_filename)
    cur = con.cursor()
    cur.execute("select image_id, boxes from tasks where "
                "status='Complete' and type='%s'" % detection_type)

    all_boxes = {}

    for item in cur:
        db_key = item[0]

        (drive_session_id, capture_id, k) = parse_db_key(db_key)

        if capture_ids is not None and capture_id not in capture_ids:
            continue

        if capture_id not in all_boxes:
            all_boxes[capture_id] = []

        for box in json.loads(item[1]):
            x0 = box['left'] + k*x_stride
            y0 = box['top'] + y_offset
            x1 = box['right'] + k*x_stride
            y1 = box['bottom'] + y_offset

            all_boxes[capture_id].append((x0, y0, x1, y1))

    con.close()

    return all_boxes

def boxes_from_txt_db(db_filename, detection_type=None, capture_ids=None):
    '''
    Return the training bounding boxes of the specified type from the
    given database file.  The return value is a dictionary

        { capture_id: [(x0, y0, x1, y1), ...], ... }.

    '''
    f = open(db_filename, 'r');
    all_boxes = {}

    for line in f:
        words = line[:-1].split()
        drive_session_id = words[0]
        capture_id = int(words[2])
        label_type = words[3]
        label_state = words[18]
        x0 = int(words[10])
        y0 = int(words[11])
        x1 = int(words[12])
        y1 = int(words[13])


        if capture_ids is not None and capture_id not in capture_ids:
            continue
        if detection_type != 'all':
            if label_type != detection_type:
                continue

        if label_state[-2:] != "OK":
            continue

        if capture_id not in all_boxes:
            all_boxes[capture_id] = []

        all_boxes[capture_id].append((x0, y0, x1, y1))

    return all_boxes


def parse_db_key(db_key):
    '''
    Given a database key of the form
        {drive_session_id}_{capture_id}_{k}

    return (drive_session_id, capture_id, k).

    '''
    try:
        fields = db_key.rsplit('_', 2)
        return (fields[0], int(fields[1]), int(fields[2]))
    except Exception:
        raise ValueError("Couldn't parse database key %s" %
                         db_key)


x_stride_dft = 2048
y_offset_dft = 1980

parser = argparse.ArgumentParser(add_help=False)
parser.add_argument("db_filename", metavar="path/to/db.sqlite")
parser.add_argument("--x-stride", type=int, default=x_stride_dft)
parser.add_argument("--y-offset", type=int, default=y_offset_dft)


if __name__ == "__main__":
    my_parser = argparse.ArgumentParser(
            parents=[common.capture_spec_parser, parser])

    my_parser.add_argument("detection_type", choices=['faces', 'plates'])
    my_parser.add_argument("--header-format", default="{capture_id:06d}",
                        help=("format string for header field (default "
                              "is \"{capture_id:06d}\" for "
                              "000001, 000002, etc.)"))

    args = my_parser.parse_args()

    capture_ids = common.get_capture_ids(**args.__dict__)
    if capture_ids is not None:
        capture_ids = set(capture_ids)

    all_boxes = boxes_from_db(args.db_filename, args.detection_type,
                              args.x_stride, args.y_offset,
                              capture_ids)

    for (capture_id, boxes) in all_boxes.iteritems():
        for box in boxes:
            print (args.header_format.format(capture_id=capture_id) +
                   " " + " ".join(map(str, box)))
