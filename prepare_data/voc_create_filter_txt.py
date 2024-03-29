# Modify the output directory on 6/25 by tchen
# Modify the test_drives on 6/25 by tchen
import os.path

if __name__=="__main__":

    """
    This script looks at the xml annotation file and breaks the file into
    - train_filter.txt
    - val_filter.txt 
    """

    # VOCdevkit_dir = "/home/ivanas/here/objdet_training/code_dpm_here/VOCdevkit/"
    # VOCdevkit_dir = "/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit"
    VOCdevkit_dir = "../VOCdevkit"
    annotation_dir = "%s/VOC2008/Annotations/" % VOCdevkit_dir
    txt_file_dir = "%s/VOC2008/ImageSets/Main/" % VOCdevkit_dir
    image_dir = "%s/VOC2008/JPEGImages/" % VOCdevkit_dir

    # trainval_file = open("%s/trainval.txt"%txt_file_dir, 'w')
    # train_file = open("%s/train.txt"%txt_file_dir, 'w')
    # val_file = open("%s/val.txt"%txt_file_dir, 'w')
    train_filter_file = open("%s/train_filter.txt"%txt_file_dir, 'w')
    val_filter_file = open("%s/val_filter.txt"%txt_file_dir, 'w')

    # test_file = open("%s/test.txt"%txt_file_dir, 'w')
    
    # test_drives = {'HT052set3','HT067_1380767737', 'HT024_1377677817_2'}
                   # us  singapore amsterdam
    test_drives = {'HT067_1380767737', 'HT053_1381122097'}
    testfilenum = dict()
    testfilenum['HT067_1380767737'] = 148  # Assign half of the data to testing
    testfilenum['HT053_1381122097'] = 99  # Assign half of the data testing
    # test_drives = 
    # train_drives    

    dirlist = os.listdir(annotation_dir)

    train_percent_data = 0.80   # 80% train DPM, 20% train CNN 
    num_files = len(dirlist)    # train - train_val - test
    num_train_files = int(float(num_files - sum(testfilenum.values())) * train_percent_data)
    # num_train_files = int((718 - 148 - 99)*0.8) 
    num_val_files = num_files - num_train_files
    print "number of training files = [%d]" % num_train_files
    print "number of validation files = [%d]" % num_val_files

    count = 0
    for fname in dirlist:
        filename = fname[0:len(fname)-4]
        if (os.path.exists(os.path.join(image_dir, filename + ".jpg")) == False):
            print "%s does not exist" % os.path.join(image_dir, filename + ".jpg")
            continue


        if ((test_drives.issuperset({fname[0:5]}) \
                or  test_drives.issuperset({fname[0:9]}) \
                or  test_drives.issuperset({fname[0:16]})\
                or  test_drives.issuperset({fname[0:18]})) and (testfilenum[filename[0:16]] > 0)) :
            testfilenum[filename[0:16]] -= 1            
        else:
            if count < num_train_files:
                print "%d : %s" % (count, filename)
                train_filter_file.write('%s\n' % filename)
            else:
                val_filter_file.write('%s\n' % filename)
            count += 1


    train_filter_file.close()
    val_filter_file.close()

