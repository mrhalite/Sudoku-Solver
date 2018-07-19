from optparse import OptionParser

from data import createData, loadData, getBatch, loadTestData
from model import createModel_64, loadModel

import numpy as np

def preparePredict(imgSize=64):
    # load model
    model = loadModel('model_{0}.hd5'.format(imgSize))

    return model
    
def predict(model, input):
    input = input / 255.0
    pred = model.predict(input)
    try:
        nums = np.argmax(pred, axis=1)
    except:
        nums = None
    return nums

def test(inputFileName, imgSize=64):
    # load model
    model = loadModel('model_{0}.hd5'.format(imgSize))

    # load input data
    x_test = loadTestData(inputFileName, imgSize=imgSize)

    # predict
    pred = model.predict(x_test)
    print(pred)

    # show result
    print('Prediction : {0}'.format(pred[0]))
    num = np.argmax(pred[0])
    print('Prediction : {0}'.format(num))

if __name__ == '__main__':
    parser = OptionParser()
    parser.add_option("--input", dest="input", default=None, help="Test input")
    parser.add_option("--imgsize", dest="imgsize", type="int", default=64, help="Image size")
    (options, args) = parser.parse_args()

    test(inputFileName=options.input, imgSize=options.imgsize)
