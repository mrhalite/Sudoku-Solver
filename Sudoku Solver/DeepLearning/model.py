from keras.layers import Input, Conv2D, MaxPool2D, Dropout, Flatten, Dense
from keras.models import Model, load_model

def loadModel(fileName):
    model = load_model(fileName)
    return model

def createModel_128(inputShape=(128, 128, 3), numClasses=10):
    model = createModel_64(inputShape=inputShape, numClasses=numClasses)
    return model

def createModel_64(inputShape=(64, 64, 3), numClasses=10):
    # input
    x = Input(shape=inputShape, name='x')

    y = Conv2D(8, (3, 3), activation='relu', padding='same')(x)
    y = MaxPool2D(pool_size=(2, 2))(y) # 64 -> 32
    y = Conv2D(16, (3, 3), activation='relu', padding='same')(y)
    y = MaxPool2D(pool_size=(2, 2))(y) # 32 -> 16
    y = Conv2D(32, (3, 3), activation='relu', padding='same')(y)
    y = MaxPool2D(pool_size=(2, 2))(y) # 16 -> 8
    y = Conv2D(64, (3, 3), activation='relu', padding='same')(y)
    y = MaxPool2D(pool_size=(2, 2))(y) # 8 -> 4
    y = Conv2D(128, (3, 3), activation='relu', padding='same')(y)
    y = MaxPool2D(pool_size=(2, 2))(y) # 4 -> 2
    y = Flatten()(y)
    y = Dense(512, activation='relu')(y)
    y = Dense(numClasses, activation='softmax', name='y')(y)

    model = Model(x, y)
    model.summary()
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

    return model
