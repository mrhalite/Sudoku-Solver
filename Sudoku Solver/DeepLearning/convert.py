# 참조 - https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml

from optparse import OptionParser
import coremltools
import os
from model import createModel_128, createModel_64

def convert(inputModel=None):
    if inputModel == None:
        print('No model was specified.')
        return
    
    fn, ext = os.path.splitext(inputModel)

    ''' create model and convert
    # model = createModel_64(inputShape=(64, 64, 3), numClasses=10)
    # coreml_model = coremltools.converters.keras.convert(model)
    '''
    
    # load saved model and convert
    coreml_model = coremltools.converters.keras.convert(
        inputModel,
        input_names=['x'],
        output_names=['y'],
        image_input_names=['x'],
        image_scale=1/255.0
    )
    coreml_model.save(fn + '.mlmodel')

    '''
    # minimize model
    coreml_model_fp16_spec = coremltools.utils.convert_neural_network_spec_weights_to_fp16(coreml_model)
    coreml_model_fp16_spec.save(fn + '_fp16.mlmodel')
    coremltools.utils.save_spec(coreml_model_fp16_spec, fn + '_fp16.mlmodel')
    '''

if __name__ == '__main__':
    parser = OptionParser()
    parser.add_option("--input", dest="input", default=None)
    (options, args) = parser.parse_args()

    convert(options.input)
