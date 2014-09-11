# Modified on 6/25 by tchen, Line 166, 172

from __future__ import division

import numpy
import os
import colorsys
import sys
import cv2

#sys.path.append("/home/ivanas/here/lidar/privacy_evaluation/")
import argparse
import process_export
import db_export
import common

def expand_box(box,  scale_x, scale_y, max_x, max_y,):
    width = box[2]-box[0]
    height = box[3] - box[1]
    center_x = box[0] + width/2.0
    center_y = box[1] + height/2.0
    boxn = box;
    boxn[0] = max(0, center_x - width/2.0*scale_x)
    boxn[2] = min(max_x,  center_x + width/2.0*+scale_x)

    boxn[1] = max(0, center_y - height/2.0*scale_y)
    boxn[3] = min(max_y, center_y + height/2.0*scale_y)

    return boxn

def prepare_data(labeled_boxes_dict,
                 label_type,
                 data_directory,
                 labeled_rasters_dir,
                 annotations_dir,
                 capture_ids):

    keys = labeled_boxes_dict.keys()
    keys.sort()
    k = 0;
    for capture_id in keys:
        input_filename = os.path.join(data_directory,
                                      "%06d" % capture_id,
                                      "raster.jpg")

        output_filename = os.path.join(labeled_rasters_dir,
                                      args.drive_id +"_%06d.jpg" % capture_id)
        output_filename_ann =os.path.join(annotations_dir,
                                      args.drive_id +"_%06d_labels.txt" % capture_id)

        print input_filename
        # crop image and save
        image = cv2.imread(input_filename)
        (height, width, nch) = image.shape
        pano_start_y = 1980
        pano_end_y = 3300
        pano_start_x = 0
        pano_end_x = width

        # save cropped image
        image_seg = image[pano_start_y:pano_end_y, pano_start_x:pano_end_x,:]
        ret = cv2.imwrite(output_filename, image_seg)

        (height_seg, width_seg, nch) = image_seg.shape

        # update bounding box and save
        f = open(output_filename_ann, 'w+');
        for box in labeled_boxes_dict[capture_id]:
            # legacy functions expect ((x0,y0),(x1,y1)) box format
            boxt = list(box)

            if  boxt[2]-boxt[0]>16 and boxt[3]-boxt[1]>8:
                if boxt[3]-boxt[1]<16:
                    scale = 16/(boxt[3]-boxt[1])
                    boxtt = expand_box(boxt,  scale, scale, width-1 , height-1)
                    boxn = list(boxtt)
                else:
                    boxn = list(box)

                boxn[0] =  boxn[0] - pano_start_x
                boxn[1] =  boxn[1] - pano_start_y
                boxn[2] =  boxn[2] - pano_start_x
                boxn[3] =  boxn[3] - pano_start_y
                if  boxn[2]>=width_seg or boxn[3]>=height_seg:
                    #print " Cropping area too small! Format (x0, y0, x1, y1)."
                    print " Cropped area: %d %d %d %d" %(pano_start_x, pano_start_y, pano_end_x, pano_end_y)
                    print " Labeled box: %d %d %d %d\n"%(boxn[0], boxn[1], boxn[2], boxn[3])
                    k = k + 1
                else:
                     # +1 because of matlab indexing convention
                    f.write('%d %d %d %d\n' % (boxn[0]+1, boxn[1]+1,boxn[2]+1,boxn[3]+1))

        f.close()


    return k







def get_boxes_simplified(db_filename, data_directory, capture_ids,
                         label_type1, lable_type2,
                         x_stride=db_export.x_stride_dft,
                         y_offset=db_export.y_offset_dft):
    '''
    Simple work flow for finding all the labeled boxes
    given a data directory and database file.

    '''

    labeled_boxes_dict_all = db_export.boxes_from_db(
        db_filename, label_type1,
        x_stride, y_offset,
        capture_ids)

    labeled_boxes_dict_clear = db_export.boxes_from_db(
        db_filename, label_type2,
        x_stride, y_offset,
        capture_ids)

    #print labeled_boxes_dict_all
    #print labeled_boxes_dict_clear

    return labeled_boxes_dict_all, labeled_boxes_dict_clear


parser = argparse.ArgumentParser(
        parents=[common.capture_spec_parser,
                 db_export.parser,
                 process_export.parser],
        add_help=False)


#
parser.add_argument("drive_id", help="drive_id")
parser.add_argument("object_type", choices=['faces', 'plates'])  # not used now

if __name__ == "__main__":
    my_parser = argparse.ArgumentParser(
            parents=[parser])


    my_parser.add_argument("--label-type1")
    my_parser.add_argument("--label-type2")
    #my_parser.add_argument("--drive-id")



    args = my_parser.parse_args()



    label_type1 = args.label_type1
    if not label_type1:
        label_type1 = 'clear_plates'

    label_type2 = args.label_type2
    if not label_type2:
        label_type2 = 'all_plates'


    # output dir
    # labeled_rasters_dir = '/home/ivanas/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/JPEGImages/'
    labeled_rasters_dir = '/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/JPEGImages/'
    if os.path.isdir(labeled_rasters_dir) is False:
            os.mkdir(labeled_rasters_dir)



    # annotations_dir = '/home/ivanas/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/Annotations_txt/'
    annotations_dir = '/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/Annotations_txt/'
    if os.path.isdir(annotations_dir) is False:
            os.mkdir(annotations_dir)


    # read db
    capture_ids = common.get_capture_ids(**args.__dict__)
    print capture_ids
    (labeled_boxes_dict_type1, labeled_boxes_dict_type2) = get_boxes_simplified(
            args.db_filename, args.data_directory, capture_ids,
            label_type1, label_type2,
            args.x_stride, args.y_offset)



    if 1:
       (num_cropped_out_labeles) = prepare_data(labeled_boxes_dict_type1,
                                               label_type1,
                                               args.data_directory,
                                               labeled_rasters_dir,
                                               annotations_dir,
                                               capture_ids)


    print "Number of cropped out labels (due to raster cropping): %d" % num_cropped_out_labeles

