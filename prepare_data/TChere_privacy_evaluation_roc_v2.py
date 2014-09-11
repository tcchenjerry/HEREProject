#!/usr/bin/env python2

from __future__ import division

import argparse

import numpy

# Usage: python ../VOCdevkit/VOC2008/Annotations_txt/HT053_1381122097.txt ../VOCdevkit/results/VOC2008/comp_3_part_4_structure_5_3/box1_comp_3_part_4_structure_5_3.txt plates

# from privacy_evaluation import process_export
# from privacy_evaluation import db_export
# from privacy_evaluation import common

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


    my_parser.add_argument("--scaling", type=float,
                           default=1, help=("rescaling of bounding boxes"))

    my_parser.add_argument("--save", type=float,
                           default=1, help=("rescaling of bounding boxes"))

    # For training the classifier
    my_parser.add_argument("--threshold-lower", type=float,
                           default=threshold_lower_dft, help=("lower bound of overlap (FP)"))

    my_parser.add_argument("--threshold", type=float,
                           default=threshold_dft,
                           help=("overlap threshold (fraction) "
                                 "for a hit"))

    my_parser.add_argument("--op-th", type=float,
                           default=op_th_dft,
                           help=("roc operating threshold"))

    my_parser.add_argument("--op-th-validation", type=float,
                           default=op_th_dft_validation,
                           help=("roc operating threshold, validation"))

    my_parser.add_argument("--min-size", type=int,
                           default=min_size_dft,
                           help=("minimum labeled box size in pixels"))

    my_parser.add_argument("--save_detected", default=True)

    my_parser.add_argument("--label-type")

    # agruments for color labeling of hits/ misses / false alarms
    my_parser.add_argument("--b-label-raster",
                           default=False)

    my_parser.add_argument("--data-to-label-directory",
                           help=("directory of clean or blurred rasters to label/crop"))

    # arguments for saving hits/ misses / false alarms
    # hits / misses / flase alarms will be cropped
    # from the "--rasters-to-label-directory"
    my_parser.add_argument("--b-save-boxes",
                           default=False)
    my_parser.add_argument("--b-crop-labeled-raster",
                           default=False)


    args = my_parser.parse_args()  

    # detection type and parent box type
    detection_type = args.detection_type
    parent_map = {'faces':'people', 'plates':'cars'}
    parent_type = parent_map[detection_type]
    label_type = args.label_type
    if not label_type:
        label_type = 'clear_'+detection_type
    if not args.data_to_label_directory:
        data_to_label_directory = args.data_directory;

    # read labels and detections
    capture_ids = common.get_capture_ids(**args.__dict__)

    (detected_boxes_dict_in, detected_parent_boxes_dict, labeled_boxes_dict) = get_boxes_simplified(
        args.db_filename, args.data_directory, capture_ids,
        label_type, detection_type, parent_type,
        args.x_stride, args.y_offset, 1/args.scaling)
    labeled_boxes_dict_all = labeled_boxes_dict
    '''
    (dmmy2, dmmy1, labeled_boxes_dict_all) = get_boxes_simplified(
        args.db_filename, args.data_directory, capture_ids,
        'all', detection_type, parent_type,
        args.x_stride, args.y_offset,1)
    '''

    #print detected_boxes_dict_in

    # run for a number of thresholds to generate ROC curve

    score_th = numpy.arange(-12, 4, 1)/10.0;
    score_th = numpy.append(score_th, args.op_th)
    score_th.sort()

    # Commented on 6/31 by tchen, since not using different threshold for validation
    # score_th_v = numpy.arange(0, 6 , 1)/10.0;
    # score_th_v = score_th_v if numpy.any(score_th_v == args.op_th_validation) \
    #        else numpy.append(score_th_v, args.op_th_validation)
    # score_th_v.sort()
    score_th_v = numpy.arange(0, 1 , 1); 
    num_tp = numpy.zeros(score_th.size)
    num_fn = numpy.zeros(score_th.size)
    num_fp = numpy.zeros(score_th.size)
    recall = numpy.zeros(score_th.size)
    precision = numpy.zeros(score_th.size)
    fpr       = numpy.zeros(score_th.size)
    pixel_fpr = numpy.zeros(score_th.size)

    # Save for score dictionary, added by tchen
    keys = detected_boxes_dict_in.keys()
    keys.sort()
    score_dict = dict()
    score_min = -1.2
    
    for capture_id in keys:
        for box in detected_boxes_dict_in[capture_id]:
            if float(box[4]) > score_min:
                   score_dict["{:s} {:s} {:s} {:s} ".format(*box)] = box[4]

    for j in range(score_th_v.size):
        for i in range(score_th.size):

            # get detected boxes with score above the threshold
            (detected_boxes_dict) = get_boxes_with_score_above_th(detected_boxes_dict_in,
                                                                  score_th[i],
                                                                  score_th_v[j])


            # split labled boxes into hits (tp) and misses(fn)
             # split detected boxes into hits(tp_db) and false_alarms(fp_db)
            b_save_detected_txt = False
            ## Not sure why/when to set this to true
            #if score_th[i] == args.op_th:
            #    b_save_detected_txt = True


            (tp, fn, tp_db, fp_db) = evaluate_detections_all(detected_boxes_dict,
                    labeled_boxes_dict,
                    labeled_boxes_dict_all,
                    args.data_directory,
                    args.detection_type,
                    b_save_detected_txt,
                    args.threshold, 
                    args.threshold_lower)

            # Save label for TP/FP, added by tchen on 7/10
            # add scaling on 7/21
 
            if (i == 0) and (args.save_detected): 
                # driveid = args.db_filename[-20:-4]
                driveid = (args.db_filename.split('/'))[-1][:-4]
                # labelfname = args.data_directory[0:-36] + driveid + '/' + args.data_directory[-36:-32] + '_' + detection_type + '_TP' + '.txt' 
                directory = args.data_directory.split('/')
                for i in range(0, len(directory)-1): 
 
                    
                labelfile = file(labelfname, "w")
                save_detected_boxes(driveid, labelfname, tp_db, args.scaling) 

                labelfname = args.data_directory[0:-36] + driveid + '/' + args.data_directory[-36:-32] + '_' + detection_type + '_FP' + '.txt' 
                save_detected_boxes(driveid, labelfname, fp_db, args.scaling) 
                
                '''
                for capture_id in tp_db:
                    for bbox in tp_db[capture_id]:
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

                labelfname = args.data_directory[0:-36] + driveid + '/' + args.data_directory[-36:-32] + '_' + detection_type + '_FP' + '.txt' 
                labelfile = file(labelfname, "w")
                for capture_id in fp_db:
                    for bbox in fp_db[capture_id]:
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
                '''

            # get ROC stats
            fname=args.data_directory[:-9]+'/'+args.detection_type+\
                    '_per_raster_thval'+str(score_th_v[j])+ \
                    'th_' + str(score_th[i]) +'.txt'
            (num_tp[i], num_fn[i], num_fp[i],  area_fa) = privacy_evaluation_summary(
                    tp, fn, tp_db, fp_db, fname, detected_boxes_dict.keys(), args.min_size);


            recall[i]   = num_tp[i] / (num_tp[i] + num_fn[i]) * 100.0
            precision[i] = num_tp[i] / (num_tp[i] + num_fp[i]) * 100.0
            fpr[i]      = num_fp[i] / (num_tp[i] + num_fn[i])
            pixel_fpr[i]= area_fa/len(labeled_boxes_dict.keys())/(4096*8192)*100.0


            # label /crop/ save
            if     args.b_save_boxes  \
               and score_th[i] == args.op_th  \
               and score_th_v[j] == args.op_th_validation:
                   save_detections(data_to_label_directory, args.data_directory, detected_boxes_dict.keys(),
                           tp, fn, tp_db, fp_db, args.b_crop_labeled_raster)


            if     args.b_label_raster   \
               and score_th[i] == args.op_th   \
               and score_th_v[j] == args.op_th_validation:
                   save_labeled_raster(data_to_label_directory,
                           args.data_directory,
                           detected_boxes_dict.keys(),
                               [args.op_th, args.op_th_validation],
                               tp, fn, tp_db, fp_db)



            # save ROC stats in file
            # fname=args.data_directory[:-36]+'/'+detection_type+'_roc_validation_th_' + str(score_th_v[j]) +'.txt'
            driveid = args.db_filename[-20:-4]
            fname = args.data_directory[0:-36] + driveid + '/' + args.data_directory[-36:-32] + '_' + detection_type + '_roc' + '.txt' 
            # fname=args.data_directory[:-4]+'_'+detection_type+'_roc'+'.txt'
            names =numpy.array(['#threshold',  'recall[%]', 'FPR', 'pixel FPR[%]', 'precision[%]', 'TP', 'FN', 'FP']);
            table_data =numpy.array([score_th, recall, fpr, pixel_fpr, precision,  num_tp, num_fn, num_fp])
            save_roc_file(fname, names, table_data.transpose(), args, score_th_v[j])


        # print on screen if desired
        if 1 or score_th_v[j] == args.op_th_validation:
            f = open(fname, 'r')
            print(f.read())
            f.close()



# --------------------------------------------------------------------------
# Label/crop/save routines
# -------------------------------------------------------------------------
def draw_rect(image, box, color_rgb):
    ((x0, y0), (x1, y1)) = box
    if x0<x1 and y0<y1  and x0>=0 and y0>=0 and x1<8192  and y1<4096 :
        color_bgr = color_rgb[::-1]
        image[[y0, y1-1], x0:x1] = color_bgr
        image[y0:y1, [x0, x1-1]] = color_bgr
        return 1
    else :
        print y0, y1, x0, x1
        return 0

def save_box(image, boxn, fname):
    ((x0, y0), (x1, y1)) = boxn
    if y1-y0 > 8 and  x1-x0 >8 and \
            x0>8 and y0>8 and x0<8192-8 and y1<4096-8:

        patch = image[y0:y1, x0:x1,:];
        ret = cv2.imwrite(fname, patch)

def expand_box(box,  scale_x, scale_y, max_x, max_y,):
    ((x0, y0), (x1, y1)) = box
    width = x1-x0
    height = y1 - y0
    center_x = x0 + width/2.0
    center_y = y0 + height/2.0

    boxn = box;
    boxn[0][0] = max(0, center_x - width/2.0*scale_x)
    boxn[1][0] = min(max_x,  center_x + width/2.0*+scale_x)

    boxn[0][1] = max(0, center_y - height/2.0*scale_y)
    boxn[1][1] = min(max_y, center_y + height/2.0*scale_y)

    return boxn

def crop_and_save_boxes(boxes, image,  dir, capture_id,
                   expand_rx, expand_ry):
    id  = 1;
    for box in boxes:
        if expand_rx == 1 and expand_ry == 1:
            boxn = box;
        else:
            boxn = expand_box(box, expand_rx, expand_ry, image.shape[1], image.shape[0])

        fname = dir + "%05d_%04d.png" % (capture_id, id)
        save_box(image, boxn, fname)
        id = id+1;

def label_raster(boxes, image, clr):
    num  = 0;
    for box in boxes:
        num = num + draw_rect(image, box, clr)
    return num


def save_detections(data_directory, save_directory, keys,
                    tp, fn, tp_db, fp_db,
                    b_crop_labeled_raster):

    hits_dir = save_directory+"/hits/"
    miss_dir = save_directory+"/missed/"
    fas_dir  = save_directory+"/false_alarms/"

    if os.path.isdir(hits_dir) is False:
        os.mkdir(hits_dir)

    if os.path.isdir(miss_dir) is False:
        os.mkdir(save_directory+"/missed/")

    if os.path.isdir(fas_dir) is False:
        os.mkdir(fas_dir)

    keys.sort()
    for capture_id in keys:
        image_fname =os.path.join(data_directory,
                                  "%06d" % capture_id,
                                  "raster.jpg")
        if os.path.exists(image_fname) is False:
            continue;

        image  = cv2.imread(image_fname)

        if b_crop_labeled_raster is True:
            label_raster(tp_db[capture_id], image,  (0, 255, 0));  # hits         - green
            label_raster(fn[capture_id], image,  (255, 0, 0));     # missed       - red
            label_raster(fp_db[capture_id], image,  (0, 255, 255));   # false alarms - blue

        # Save detected boxes marked as hits
        crop_and_save_boxes(tp_db[capture_id], image,
                            hits_dir, capture_id, 1.0 , 1.0)

        # Draw/save labeled boxes marked missed
        crop_and_save_boxes(fn[capture_id], image,
                            miss_dir, capture_id, 1.0 , 1.0)

        # Draw/save labeled boxes marked false alarms
        crop_and_save_boxes(fp_db[capture_id], image,
                            fas_dir,  capture_id, 1.0 , 1.0)


def save_labeled_raster(data_directory, save_directory, keys,
                        op_th,
                        tp, fn, tp_db, fp_db):

    keys.sort()
    for capture_id in keys:
        image_fname =os.path.join(data_directory,
                                  "%06d" % capture_id,
                                  "raster.jpg")
        if os.path.exists(image_fname) is False:
            continue;


        image = cv2.imread(image_fname)


        num_tp =label_raster(tp_db[capture_id], image, (0, 255, 0)); #hits - green
        num_fn =label_raster(fn[capture_id], image, (255, 0, 0)); #missed - red
        num_fp =label_raster(fp_db[capture_id], image, (0, 255, 255)); #false alarms - blue
        num_xx =label_raster(tp[capture_id], image, (255, 255, 0)); #hits, as labeled - yellow



        text = "obj_hit = %d, obj miss = %d, obj false = %d, op_th_det =%.2f, op_th_val = %.2f " \
                % (num_xx, num_fn, num_fp, op_th[0], op_th[1] )

        cv2.putText(image, text, (3500,100), cv2.FONT_HERSHEY_SIMPLEX,
                    3, (0,0,0),thickness=4);

        if data_directory == save_directory:
            save_filename = os.path.join(save_directory,
                                         "%06d" % capture_id,
                                         "raster_labeled.jpg")
        else:
            save_filename = os.path.join(save_directory,
                                         "%06d" % capture_id,
                                         "raster.jpg")
        print save_filename
        ret = cv2.imwrite(save_filename, image)

# --------------------------------------------------------------------------
# Hits, misses and false alarms counting
# -------------------------------------------------------------------------
def privacy_evaluation_summary(tp, fn, tp_db, fp,
                               fname, keys,
                               min_size=min_size_dft):
    '''
    Count true positives, false negatives, and false positives for a set
    of captures. min_size is the minimum number of pixels in a labeled
    box for it to be considered.

    '''
    # Don't save the raster files
    # rfile= file( fname, "w" )
    # rfile.write( "#" + "-"*70 +"#\n" )
    # names =["#Capture ID", "TP(#hits) ", "FN(#miss)", "FA(#fa)", "pixel FPR[%]"]
    # rfile.write("{: >12} {: >12} {: >12} {: >12} {: >16} ".format(*names))
    # rfile.write( "\n#" + "-"*70 +"#\n" )

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

        # record
        #data = numpy.array([capture_id, ntp, nfn, nfp, fa_area/(4096*8192/100)])
        #rfile.write("{:s} {:s} {:s} {:s} {:s} ".format(*data))
        # rfile.write("{:12.0f} {:12.0f} {:12.0f} {:12.0f} {:16.2f} ".format(*data))
        #rfile.write("\n")

    #rfile.close()
    return (num_tp, num_fn, num_fp, area_fa)




def evaluate_detections_all(detected_boxes_dict,
                            labeled_boxes_dict,
                            labeled_boxes_dict_all,
                            data_directory, detection_type,
                            b_save_detected_txt,
                            threshold=threshold_dft,
                            threshold_lower=threshold_lower_dft):
    '''
    Compute true positives, false negatives, and false positives for a
    set of captures.  detected_boxes_dict and labeled_boxes_dict must
    have the same set of keys.

    '''
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
        if b_save_detected_txt is True:
            fname = data_directory+"/%s"%(capture_id) +'/detected_'+ detection_type+'_labeled.txt'
            fnameL= data_directory+"/%s"%(capture_id) +'/labeled_'+ detection_type+'.txt'
             
            # fname = data_directory+"/%06d"%(capture_id) +'/detected_'+ detection_type+'_labeled.txt'
            # fnameL= data_directory+"/%06d"%(capture_id) +'/labeled_'+ detection_type+'.txt'

        else:
            fname=[]
            fnameL=[]

        (tp, fn, tp_db, fp_tmp) = evaluate_detections_one_capture(
                detected_boxes_dict[capture_id],
                labeled_boxes_dict[capture_id],
                fname, fnameL,
                threshold)

        (tp_tmp, fn_tmp, tp_db_tmp, fp) = evaluate_detections_one_capture(
                detected_boxes_dict[capture_id],
                labeled_boxes_dict_all[capture_id],
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
    '''
    Compute true positives, false negatives, and false positives.
    `threshold' is what fraction of a labeled box must be detected
    in order for it to count as a true positive.

    The return value is
        (true_positives, false_negatives, false_positives).

    '''


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

    # For getting different FP
    hit = overlaps/labeled_sizes.astype(float) >= threshold_lower

    is_false_positive = numpy.logical_or.reduce(hit, axis=1) ^ True

    if len(detected_boxes) > 0:
        false_positives = detected_boxes_coor[is_false_positive]
        true_positives_db = detected_boxes_coor[is_false_positive ^ True]
    else:
        false_positives = detected_boxes_coor
        true_positives_db  = detected_boxes_coor


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
'''
Modified by tchen on 6/30: 
No parent score (i.e. no box[5])
'''
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
            if float(box[4])> threshold_d:
                boxes_out.append(box)
                #if len(box)>5:
                #    if box[5] > threshold_v:
                #        boxes_out.append(box)
                # else:
                   # boxes_out.append(box)


        # some development code - intentionally disabled
        for box in boxes_out:
            detected_boxes_dict_out[capture_id].append(box)

    return detected_boxes_dict_out
# --------------------------------------------------------------------------
# Load detected boxes and labeled boxes data
# -------------------------------------------------------------------------
def get_boxes_simplified(db_filename, data_directory, capture_ids,
                         label_type, detection_type, parent_type,
                         x_stride=db_export.x_stride_dft,
                         y_offset=db_export.y_offset_dft, scale=1):
    '''
    Simple work flow for finding all the detected and labeled boxes
    given a data directory and database file.

    '''
    '''
    Modified codes for loading "detected_boxes_dic", "labeled_boxes_dic" on 6/30 by tchen. 
    
    detected_boxes_dic : @ Ln 640

    labeled_boxes_dic : boxes_from_txt() @ Ln 650
    '''
    if detection_type is None:
        detection_type = label_type
    
    # Now don't need "label_capture_ids", by tchen on 6/30
    label_capture_ids = None    

    '''
    if capture_ids is not None:
        detection_capture_ids = capture_ids
        label_capture_ids = capture_ids
    else:
        detection_capture_ids = process_export.find_capture_ids(
                data_directory)
        label_capture_ids = None
    '''
    
    # Added load_detected_boxes function by tchen on 6/30 
    # driveid = "HT068_1380264747"
    driveid = db_filename[-20:-4]
    detected_boxes_dict = load_detected_boxes(driveid, data_directory, scale)
    # detected_boxes_dict = dict(load_detected_boxes(driveid, data_directory)) 
    detected_parent_boxes_dict = detected_boxes_dict
    '''
    detected_boxes_dict = dict(process_export.detected_boxes(
            data_directory, detection_type,
            detection_capture_ids))

    detected_parent_boxes_dict = dict(process_export.detected_boxes(
            data_directory, parent_type,
            detection_capture_ids))
    '''
    if 1:
        if db_filename[-3:] == "txt":
            labeled_boxes_dict = boxes_from_txt(
                db_filename, label_type, label_capture_ids)
        else:
            labeled_boxes_dict = db_export.boxes_from_db(
                    db_filename, label_type,
                    x_stride, y_offset,
                    label_capture_ids)

    # a development option to read clear_lables and all_labels
    if 0:
        labeled_boxes_dict = db_export.boxes_from_db(
            db_filename, 'all_plates',
            x_stride, y_offset,
            label_capture_ids)
        labeled_boxes_dict
        tmpdict = db_export.boxes_from_db(
            db_filename, 'clear_plates',
            x_stride, y_offset,
            label_capture_ids)

        for key in tmpdict:
            if key in labeled_boxes_dict:
                labeled_boxes_dict[key] += tmpdict[key]
            else:
                labeled_boxes_dict[key] =  tmpdict[key]

    if capture_ids is None:
        reduce_to_intersection(detected_boxes_dict,
                              labeled_boxes_dict)
    return detected_boxes_dict,detected_parent_boxes_dict, labeled_boxes_dict

# Added by tchen on 6/30
def load_detected_boxes(driveid, data_directory,scale):
    '''
    "data_directory" here is a .txt file with all the detection results. 
    Return the detected bbox.
    The file format of the detection result is:
    [driveid captureid score x0 y0 x1 y1] 
    '''
    
    f = open(data_directory)
    all_boxes = {}
    for line in f:
        words = line[:-1].split()
        if (words[0] == driveid):
           if words[1] not in all_boxes:
               all_boxes[words[1]] = []

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
    '''
    Return the training bounding boxes of the specified type from the
    given database file.  The return value is a dictionary

        { capture_id: [(x0, y0, x1, y1), ...], ... }.

    '''
    '''
    Modified on 6/29 by tchen 
    '''
    
    all_boxes = {}

    # for capture_id in all_captures:
    # for f in listdir(db_filename)
        # Check the drive id
    
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
def save_detected_boxes(driveid, labelfname, printdict, scale):
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


