import os
import numpy as np
from PIL import Image, ImageDraw
from keras.utils import np_utils

IMAGE_SIZE = 128

dataDir = './data'

train_data = []
truth_data = []

def createData(imgSize=IMAGE_SIZE):
    global train_data, truth_data

    print('Create data: ', end='')
    for i in range(10):
        subDir = 'Sample0{0:02d}'.format(i+1)
        imgDir = os.path.abspath(os.path.join(dataDir, subDir))
        fileList = [f for f in os.listdir(imgDir) if f.endswith('.png')]
        print(i, end='')
        for f in fileList:
            fn = os.path.join(imgDir, f)
            img = Image.open(fn)
            img = img.resize((imgSize, imgSize), Image.ANTIALIAS)
            img = img.convert('RGB')
            data = img.getdata()
            raw = np.array(data, dtype=np.uint8).reshape((imgSize, imgSize, 3))
            train_data.append(raw)
            truth_data.append(i)
    print('')

    train_data = np.array(train_data, dtype=np.uint8).reshape((len(train_data), imgSize, imgSize, 3))
    train_data.tofile('train_data_{0}.dat'.format(imgSize))
    truth_data = np.array(truth_data, dtype=np.int32)
    truth_data.tofile('truth_data_{0}.dat'.format(imgSize))

    return train_data

def loadData(imgSize=IMAGE_SIZE):
    global train_data, truth_data

    train_data = np.fromfile('train_data_{0}.dat'.format(imgSize), dtype=np.uint8).reshape((-1, imgSize, imgSize, 3)) / 255.0
    truth_data = np.fromfile('truth_data_{0}.dat'.format(imgSize), dtype=np.int32)

    td2 = np.fromfile(os.path.abspath('../sudoku_num/train_data_{0}.dat'.format(imgSize)), dtype=np.uint8).reshape((-1, imgSize, imgSize, 3)) / 255.0
    tr2 = np.fromfile(os.path.abspath('../sudoku_num/truth_data_{0}.dat'.format(imgSize)), dtype=np.int32)

    train_data = np.concatenate((train_data, td2), axis=0)
    truth_data = np.concatenate((truth_data, tr2), axis=0)

def getBatch(numOfBatch=128):
    global train_data, truth_data

    randomIndexes = np.random.choice(range(train_data.shape[0]), size=numOfBatch, replace=False)
    x_train = train_data[randomIndexes]
    y_true = truth_data[randomIndexes]
    y_true = np_utils.to_categorical(y_true)

    return x_train, y_true

def loadTestData(inputFileName, normalize=True, imgSize=IMAGE_SIZE):
    img = Image.open(inputFileName)
    img = img.resize((imgSize, imgSize), Image.ANTIALIAS)
    img = img.convert('RGB')
    data = img.getdata()
    raw = np.array(data, dtype=np.uint8).reshape((imgSize, imgSize, 3))
    if normalize == True:
        raw = raw / 255.0
    x_test = []
    x_test.append(raw)
    x_test = np.array(x_test).reshape((1, imgSize, imgSize, 3))
    return x_test
