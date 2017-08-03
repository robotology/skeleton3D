from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os

from tensorflow.core.framework import graph_pb2
from tensorflow.core.protobuf import saver_pb2
from tensorflow.python.client import session
from tensorflow.python.framework import graph_io
from tensorflow.python.framework import importer
from tensorflow.python.framework import ops
from tensorflow.python.framework import test_util
from tensorflow.python.ops import math_ops
from tensorflow.python.ops import variables
from tensorflow.python.platform import test
from tensorflow.python.tools import freeze_graph
from tensorflow.python.training import saver as saver_lib

train_dir = './log/'
model_dir = './model/'

# We save out the graph to disk, and then call the const conversion
# routine.
checkpoint_state_name = "checkpoint_state"
input_graph_name = "mapping_graph.pb"
output_graph_name = "output_graph.pb"

input_graph_path = os.path.join(model_dir, input_graph_name)
input_saver_def_path = ""
input_binary = False
input_checkpoint_path = os.path.join(train_dir, 'saved_checkpoint') + "-10000"

# Note that we this normally should be only "output_node"!!!
output_node_names = "layer3/activation"
restore_op_name = "save/restore_all"
filename_tensor_name = "save/Const:0"
output_graph_path = os.path.join(model_dir, output_graph_name)
clear_devices = False

freeze_graph.freeze_graph(input_graph_path, input_saver_def_path,
                          input_binary, input_checkpoint_path,
                          output_node_names, restore_op_name,
                          filename_tensor_name, output_graph_path,
                          clear_devices, "")