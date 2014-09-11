#!/usr/bin/env python2

from __future__ import division

import argparse

import numpy

from os import walk 

import process_export
import db_export
import common

import os
import colorsys
import sys
import cv2

threshold_dft = 0.4
threshold_lower_dft = 0.4
min_size_dft = 64
op_th_dft = -0.75;  #roc operating point threshold
op_th_dft_validation = 0.2;  #roc operating point threshold

def main():

    # ----------  Input all the arguments  ----------- % 
    parser = argparse.ArgumentParser(
        parents=[common.capture_spec_parser,
                 db_export.parser,
                 process_export.parser],
        add_help=False)

    parser.add_argument("detection_type", choices=['faces', 'plates'])

    my_parser = argparse.ArgumentParser(
            parents=[parser])

    my_parser.add_argument("--threshold", type=float,
                           default=threshold_dft,
                           help=("overlap threshold (fraction) "
                                 "for a hit"))

    my_parser.add_argument("--min-size", type=int,
                           default=min_size_dft,
                           help=("minimum labeled box size in pixels"))

    my_parser.add_argument("--op-th", type=float,
                           default=op_th_dft,
                           help=("roc operating threshold"))

    my_parser.add_argument("--scaling", type=float,
                           default=1, help=("rescaling of bounding boxes"))

    my_parser.add_argument("--min", type=float,
                           default=-1.2, help=("Mininum score"))

    my_parser.add_argument("--max", type=float,
                           default=0.4, help=("Maximum score"))

    # For training discriminative classifiers
    my_parser.add_argument("--threshold-lower", type=float,
                           default=threshold_lower_dft, help=("lower bound of overlap (FP)"))


    my_parser.add_argument("--save", default=True, help=("save detected boxes"))
    my_parser.add_argument("--train", type=float, default=0, help=("training"))

    args = my_parser.parse_args()  

    # detection type and parent box type
    detection_type = args.detection_type
    label_type = ""    
    parent_type = ""
    
    if (args.train == 1):
        capture_ids = read_capture_ids('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/ImageSets/Main/trainval.txt', args.db_filename[-20:-4])
    else: 
        capture_ids = read_capture_ids('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/ImageSets/Main/test.txt', args.db_filename[-20:-4])    

    (detected_boxes_dict_in, labeled_boxes_dict) = get_boxes_simplified(
        args.db_filename, args.data_directory, capture_ids,
        label_type, detection_type, parent_type,
        args.x_stride, args.y_offset, args.scaling)
    labeled_boxes_dict_all = labeled_boxes_dict

    # score_th = numpy.arange(-12, 4, 1)/10.0;
    score_th = numpy.arange(args.min, args.max, float(args.max - args.min)/16); 
    score_th = numpy.append(score_th, args.op_th)
    score_th.sort()
    score_th_v = 0; 
    num_tp = numpy.zeros(score_th.size)
    num_fn = numpy.zeros(score_th.size)
    num_fp = numpy.zeros(score_th.size)
    recall = numpy.zeros(score_th.size)
    precision = numpy.zeros(score_th.size)
    fpr       = numpy.zeros(score_th.size)
    pixel_fpr = numpy.zeros(score_th.size)
    driveid = (args.db_filename.split('/'))[-1][:-4]

    # Save for score dictionary
    keys = detected_boxes_dict_in.keys()
    keys.sort()
    score_dict = dict()
    # score_min = -1.2
    
    for capture_id in keys:
        for box in detected_boxes_dict_in[capture_id]:
            # if float(box[4]) > score_min:
            if float(box[4]) >= args.min-0.1:  # -0.1 here for possible overflow
                   score_dict["{:s} {:s} {:s} {:s} ".format(*box)] = box[4]

    for i in range(score_th.size):
            (detected_boxes_dict) = get_boxes_with_score_above_th(detected_boxes_dict_in,
                                                                  score_th[i],
                                                                  score_th_v)
        
            (tp, fn, tp_db, fp_db) = evaluate_detections_all(detected_boxes_dict,
                    labeled_boxes_dict,
                    labeled_boxes_dict_all,
                    args.data_directory,
                    args.detection_type,
                    args.threshold, 
                    args.threshold_lower)

            if (i == 0) and (args.save):

                labelfname = args.data_directory[0:-36] + driveid + '/' + args.data_directory[-36:-32] + '_' + detection_type + '_TP' + '.txt' 
                labelfile = file(labelfname, "w")
                save_detected_boxes(driveid, labelfname, tp_db, args.scaling, score_dict) 
                labelfname = args.data_directory[0:-36] + driveid + '/' + args.data_directory[-36:-32] + '_' + detection_type + '_FP' + '.txt' 
                save_detected_boxes(driveid, labelfname, fp_db, args.scaling, score_dict)         
        

            fname=args.data_directory[:-9]+'/'+args.detection_type+\
                    '_per_raster_thval'+str(score_th_v)+ \
                    'th_' + str(score_th[i]) +'.txt'
            (num_tp[i], num_fn[i], num_fp[i],  area_fa) = privacy_evaluation_summary(
                    tp, fn, tp_db, fp_db, fname, detected_boxes_dict.keys(), args.min_size);

            recall[i]   = num_tp[i] / (num_tp[i] + num_fn[i]) * 100.0
            precision[i] = num_tp[i] / (num_tp[i] + num_fp[i]) * 100.0
            fpr[i]      = num_fp[i] / (num_tp[i] + num_fn[i])
            pixel_fpr[i]= area_fa/len(labeled_boxes_dict.keys())/(4096*8192)*100.0

            fname = args.data_directory[0:-36] + driveid + '/' + args.data_directory[-36:-32] + '_' + detection_type + '_roc' + '.txt' 

            names =numpy.array(['#threshold',  'recall[%]', 'FPR', 'pixel FPR[%]', 'precision[%]', 'TP', 'FN', 'FP']);
            table_data =numpy.array([score_th, recall, fpr, pixel_fpr, precision,  num_tp, num_fn, num_fp])
            save_roc_file(fname, names, table_data.transpose(), args, score_th_v)


    f = open(fname, 'r')
    print(f.read())
    f.close()


# --------------------------------------------------------------------------
# Hits, misses and false alarms counting
# -------------------------------------------------------------------------
def privacy_evaluation_summary(tp, fn, tp_db, fp,
                               fname, keys,
                               min_size=min_size_dft):

    num_tp = 0
    num_fn = 0
    num_fp = 0
    area_fa = 0;

    keys.sort()
    for capture_id in keys:

        # object box stats
        ntp = sum(1 for t in tp[capture_id] if area(t) >= min_size)
        nfn = sum(1 for t in fn[capture_id] if area(t) >= min_size)
        nfp = len(fp[capture_id])

        fa_area = sum(area(t) for t in fp[capture_id])
        area_fa += fa_area;

        num_tp += ntp
        num_fn += nfn
        num_fp += nfp

    return (num_tp, num_fn, num_fp, area_fa)



def evaluate_detections_all(detected_boxes_dict,
                            labeled_boxes_dict,
                            labeled_boxes_dict_all,
                            data_directory, detection_type,
                            threshold=threshold_dft, 
                            threshold_lower=threshold_lower_dft):

    detection_capture_ids = set(detected_boxes_dict.keys())
    label_capture_ids = set(labeled_boxes_dict.keys())
    label_capture_ids_all = set(labeled_boxes_dict_all.keys())

    if label_capture_ids ^ detection_capture_ids:
        raise ValueError("Detection and label capture-ID-sets differ")

    true_positives = {}
    false_negatives = {}
    true_positives_db = {}
    false_positives = {}

    for capture_id in label_capture_ids:
        
        fname = []
        fnameL = []

        (tp, fn, tp_db, fp) = evaluate_detections_one_capture(
                detected_boxes_dict[capture_id],
                labeled_boxes_dict[capture_id],
                fname, fnameL,
                threshold, threshold_lower)

        true_positives[capture_id] = tp
        false_negatives[capture_id] = fn
        true_positives_db[capture_id] = tp_db
        false_positives[capture_id] = fp

    return (true_positives, false_negatives, true_positives_db, false_positives)


def evaluate_detections_one_capture(detected_boxes, labeled_boxes,
                                    fname, fnameL,
                                    threshold=threshold_dft, 
                                    threshold_lower=threshold_lower_dft):

    detected_boxes = numpy.array(detected_boxes)
    labeled_boxes = numpy.array(labeled_boxes, dtype=int)


    # get the coordinates only
    if len(detected_boxes)>0:
        detected_boxes_coor  = detected_boxes[:,:4].astype(int)
    else:
        detected_boxes_coor = numpy.array([], dtype=int)

    detected_boxes_coor = detected_boxes_coor.reshape(-1,2,2)
    labeled_boxes = labeled_boxes.reshape(-1,2,2)

    labeled_sizes = area(labeled_boxes)


    overlaps = compute_all_box_overlaps(detected_boxes_coor, labeled_boxes)
    hit = overlaps/labeled_sizes.astype(float) >= threshold

    is_true_positive = numpy.logical_or.reduce(hit, axis=0)

    # The separate clauses are needed due to a bug in numpy that
    # prevents an array of length zero from being indexed *at all* (even
    # by an empty list)
    if len(labeled_boxes) > 0:
        true_positives = labeled_boxes[is_true_positive]
        false_negatives = labeled_boxes[is_true_positive ^ True]
    else:
        true_positives = labeled_boxes
        false_negatives = labeled_boxes

    is_false_positive = numpy.logical_or.reduce(hit, axis=1) ^ True

    if len(detected_boxes) > 0:
        true_positives_db = detected_boxes_coor[is_false_positive ^ True]
    else:
        false_positives = detected_boxes_coor
        true_positives_db  = detected_boxes_coor

    # Get FP with possibly different threshold
    hit = overlaps/labeled_sizes.astype(float) >= threshold_lower
    is_false_positive = numpy.logical_or.reduce(hit, axis=1) ^ True    

    if len(detected_boxes) > 0:
        false_positives = detected_boxes_coor[is_false_positive]
    else:
        false_positives = detected_boxes_coor

    # save detected boxes as labeled
    if len(fname)>0:
        if len(detected_boxes)>0:
            labels = numpy.ones((len(detected_boxes),1))
            labels[is_false_positive]=-1
            detected_boxes = numpy.concatenate((labels, detected_boxes),axis=1)

        rfile= file( fname, "w" )
        for row in detected_boxes:
            data = tuple("{0:.0f}".format(el) for el in row[:5])+\
                tuple("{0:.2f}".format(el) for el in row[5:])
            rfile.write("\t".join(data))
            rfile.write("\n")
        rfile.close()

        if len(labeled_boxes)>0:
            rfile= file( fnameL, "w" )
            for row in labeled_boxes:
                row=numpy.concatenate((numpy.array([1]),row.flatten()),axis=1)
                data = tuple("{0:.0f}".format(el) for el in row[:5])+\
                    tuple("{0:.2f}".format(el) for el in row[5:])
                rfile.write("\t".join(data))
                rfile.write("\n")
            rfile.close()

    # true_positives    - labeled boxes, marked as hits
    # false_negatives   - labeled boxes, marked as missed
    # true_positives_db - detected boxes, marked as hits
    # false_negatives   - detected boxes, marked as false alarms
    return (true_positives, false_negatives, true_positives_db,  false_positives)


def compute_all_box_overlaps(boxes_A, boxes_B):
    '''
    Given two arrays of boxes (shape (m, 2, 2) and (n, 2, 2)), compute
    the overlap size of each pair in the cartesian product.  The return
    value has shape (m, n).

    '''

    dim = (numpy.minimum(boxes_A[:,None,1,:], boxes_B[None,:,1,:]) -
           numpy.maximum(boxes_A[:,None,0,:], boxes_B[None,:,0,:]))

    numpy.maximum(dim, 0, dim)

    return dim.prod(axis=2)


def area(box):
    '''
    Return the area of a box [(x0, y0), (x1, y1)].

    Vectorized.

    '''
    box.reshape(-1,2,2)
    area = numpy.diff(box, axis=-2).prod(axis=-1)
    return area.reshape(area.shape[:-1])

def reduce_to_intersection(dict_A, dict_B):
    '''
    Given two dicts, remove all entries whose keys are not common to
    both.

    '''
    keys_A = set(dict_A.iterkeys())
    keys_B = set(dict_B.iterkeys())


    keys = keys_A & keys_B
    del_A = keys_A ^ keys
    del_B = keys_B ^ keys

    for key in del_A:
        del dict_A[key]

    for key in del_B:
        del dict_B[key]
#-----------------------------------------------------------------
# Load detection with desired threshold
#------------------------------------------------------------------

def get_boxes_with_score_above_th(detected_boxes_dict,
                                   threshold_d,
                                   threshold_v):

    keys = detected_boxes_dict.keys()
    keys.sort()

    detected_boxes_dict_out = dict()

    for capture_id in keys:
        detected_boxes_dict_out[capture_id] = []
        boxes_out = []
        for box in detected_boxes_dict[capture_id]:
            if float(box[4])>= threshold_d:
                boxes_out.append(box)

        for box in boxes_out:
            detected_boxes_dict_out[capture_id].append(box)

    return detected_boxes_dict_out

# --------------------------------------------------------------------------
# Load detected boxes and labeled boxes data
# -------------------------------------------------------------------------

def read_capture_ids(test_fname, test):
    f = open(test_fname, 'r')
    capture_ids = [] 
    for line in f: 
        if (line[0:16] == test):
           capture_ids.append(int(line[-7:-1])) 
    
    return capture_ids

def get_boxes_simplified(db_filename, data_directory, capture_ids,
                         label_type, detection_type, parent_type,
                         x_stride=db_export.x_stride_dft,
                         y_offset=db_export.y_offset_dft, scale=1):
    
    driveid = db_filename[-20:-4]

    detected_boxes_dict = load_detected_boxes(driveid, data_directory, scale, capture_ids)
    labeled_boxes_dict = boxes_from_txt(db_filename, label_type)    

    reduce_to_intersection(detected_boxes_dict, labeled_boxes_dict)

    return detected_boxes_dict, labeled_boxes_dict


def load_detected_boxes(driveid, data_directory, scale, capture_ids):
    
    f = open(data_directory)
    all_boxes = {}
    for capture in capture_ids:   # Initialize the array to be the same size. 
        all_boxes[str(capture).zfill(6)] = []    

    for line in f:
        words = line[:-1].split()
        if (words[0] == driveid):
           # if words[1] not in all_boxes:
           #     all_boxes[words[1]] = []

	   xc = (int(words[3]) + int(words[5]))/2
	   yc = (int(words[4]) + int(words[6]))/2
	   xwid = xc - int(words[3])
	   ywid = yc - int(words[4])
	   x0 = int(max(xc-scale*xwid, 1))
	   y0 = int(max(yc-scale*ywid, 1))
	   x1 = int(min(xc+scale*xwid, 8192))
	   y1 = int(min(yc+scale*ywid, 1320))           
           
           all_boxes[words[1]].append((str(x0), str(y0), str(x1), str(y1), words[2]))
    
    return all_boxes


def boxes_from_txt(db_filename, detection_type=None, capture_ids=None):

    all_boxes = {}
    f = open (db_filename, 'r')  

    for line in f:
        words = line[:-1].split()
        capture_id = words[0]
        x0 = int(words[1])
        y0 = int(words[2])
        x1 = int(words[3])
        y1 = int(words[4])
        if capture_id not in all_boxes:
            all_boxes[capture_id] = []
        all_boxes[capture_id].append((x0,y0,x1,y1))

    return all_boxes


#--------------------------------------------------------------------------------
#   SAVE
#--------------------------------------------------------------------------------
def save_detected_boxes(driveid, labelfname, printdict, scale, score_dict):
    labelfile = file(labelfname, "w")
    for capture_id in printdict:
        for bbox in printdict[capture_id]:
                labelfile.write(capture_id + " ")
                tmpstr = ""
                for row in bbox:  
                    tmpstr = tmpstr + str("{:0.0f} {:0.0f} ".format(*row))
                words = tmpstr[:-1].split()
		xc = (int(words[0]) + int(words[2]))/2
		yc = (int(words[1]) + int(words[3]))/2
		xwid = xc - int(words[0])
		ywid = yc - int(words[1])
		x0 = int(max(xc-scale*xwid, 1))
		y0 = int(max(yc-scale*ywid, 1))
		x1 = int(min(xc+scale*xwid, 8192))
		y1 = int(min(yc+scale*ywid, 1320))                
                tmpstr = str(x0)+" "+str(y0)+" "+str(x1)+" "+ str(y1)+" " + score_dict[tmpstr]
                labelfile.write(tmpstr)
                labelfile.write("\n") 

    labelfile.close()  


def save_roc_file(fname,  names, table_data, args, op_th_v):
    line="#"+"-"*150+"\n"

    rfile= file( fname, "w" )
    rfile.write(line)
    rfile.write("# Data  : " + args.data_directory+"\n")
    rfile.write("# Labels: " + args.db_filename+"\n")
    rfile.write("# Type  : " + args.detection_type+"\n")
    rfile.write("# Validation thrshold:" + str(op_th_v) +"\n")
    rfile.write("# Number of labels: %d \n"% (table_data[1,5]+ table_data[1,6]))

    rfile.write(line)
    rfile.write( "{: >16} {: >16} {: >16} {: >16} {: >16} {: >16} {: >16} {: >16}".format(*names))
    rfile.write("\n")
    rfile.write(line)


    for row in table_data:
        rfile.write("{:16.2f} {:16.2f} {:16.2f} {:16.2f} {:16.2f} {:16.0f} {:16.0f} {:16.0f} ".format(*row))
        rfile.write("\n")


    rfile.write("# LEGEND:\n")
    rfile.write(line),
    rfile.write("# Detection rule: the label box covered by at least %2.1f%%\n"% (args.threshold*100))
    rfile.write("# True positives,  i.e. hits:         TP\n")
    rfile.write("# False negatives, i.e. misses:       FN\n")
    rfile.write("# False positives, i.e. false alarms: FP\n")
    rfile.write("# Recall:                             TP/(TP+FN)\n")
    rfile.write("# Precision:                          TP/(TP+FP)\n")
    rfile.write("# FPR (false positive rate):          FP/(TP+FN)\n")
    rfile.write("# Pixel FPR (upper bound, does not discount box overlap) : (# false positive pixels) / (# pixels in raster)\n")


    rfile.close()



if __name__ == '__main__':
    main()

