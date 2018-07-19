import numpy as np

from data import createData, loadData, getBatch
from model import createModel_128, createModel_64

NUM_EPOCH = 10000
NUM_WEIGHTSAVE_PERIOD = 100
BATCH_SIZE = 1024

IMAGE_SIZE = 64

def train(continueTraining=True):
    # load train, truth data
    loadData(imgSize=IMAGE_SIZE)

    # create model
    if IMAGE_SIZE == 128:
        model = createModel_128(inputShape=(IMAGE_SIZE, IMAGE_SIZE, 3), numClasses=10)
    else:
        model = createModel_64(inputShape=(IMAGE_SIZE, IMAGE_SIZE, 3), numClasses=10)
    if continueTraining == True:
        try:
            model.load_weights('weight_{0}.hd5'.format(IMAGE_SIZE))
        except:
            print('Weight load exception.')

    # train
    for epoch in range(NUM_EPOCH):
        print('EPOCH={0} : '.format(epoch), end='')
        x_train, y_true = getBatch(numOfBatch=BATCH_SIZE)
        loss = model.train_on_batch(x_train, y_true)
        print('{0:>6.4f} {1:>6.4f}'.format(loss[0], loss[1]), end='\r')

        if (epoch % NUM_WEIGHTSAVE_PERIOD) == 0:
            model.save('model_{0}.hd5'.format(IMAGE_SIZE))
            model.save_weights('weight_{0}.hd5'.format(IMAGE_SIZE))

if __name__ == '__main__':
    train()
