#!/usr/bin/env python
"""
Training code for mapping visual space information to motor space
Using tf_queue for reading csv dataset files ==> There is no Placeholder for data input coz
tf_queue loads data to graph by itself

"""

import os
import tensorflow as tf
from tensorflow.python.tools import freeze_graph
import numpy as np


def variable_summaries(var):
    """Attach a lot of summaries to a Tensor (for TensorBoard visualization)."""
    with tf.name_scope('summaries'):
        mean = tf.reduce_mean(var)
        tf.summary.scalar('mean', mean)
        with tf.name_scope('stddev'):
            stddev = tf.sqrt(tf.reduce_mean(tf.square(var - mean)))
        tf.summary.scalar('stddev', stddev)
        tf.summary.scalar('max', tf.reduce_max(var))
        tf.summary.scalar('min', tf.reduce_min(var))
        tf.summary.histogram('histogram', var)


def weight_variable(shape):
    initial = tf.truncated_normal(shape, stddev=0.1)
    return tf.Variable(initial)


def bias_variable(shape):
    initial = tf.constant(0.1, shape=shape)
    return tf.Variable(initial)


def nn_layer(input_tensor, input_dim, output_dim, layer_name, act=tf.nn.relu):
    """Reusable code for making a simple neural net layer.

    It does a matrix multiply, bias add, and then uses relu to nonlinearize.
    It also sets up name scoping so that the resultant graph is easy to read,
    and adds a number of summary ops.
    """
    input_tensor = tf.reshape(tensor=input_tensor, shape=[1, input_dim], name='input')
    # Adding a name scope ensures logical grouping of the layers in the graph.
    with tf.name_scope(layer_name):
        # This Variable will hold the state of the weights for the layer
        with tf.name_scope('weights'):
            weights = weight_variable([input_dim, output_dim])
            variable_summaries(weights)
        with tf.name_scope('biases'):
            biases = bias_variable([output_dim])
            variable_summaries(biases)
        with tf.name_scope('Wx_plus_b'):
            preactivate = tf.matmul(input_tensor, weights) + biases
            tf.summary.histogram('pre_activations', preactivate)
        activations = act(preactivate, name='activation')
        tf.summary.histogram('activations', activations)
        return activations

filename_queue_in  = tf.train.string_input_producer(["../matlab/inMatrix.csv"])
filename_queue_out = tf.train.string_input_producer(["../matlab/refMatrix.csv"])

train_dir = './log/'
model_dir = './model/'
checkpoint_prefix = os.path.join(train_dir, 'saved_checkpoint')
graph_name = 'mapping_graph.pb'

reader_in = tf.TextLineReader()
reader_out = tf.TextLineReader()
key_in, value_in = reader_in.read(filename_queue_in)
key_out, value_out = reader_out.read(filename_queue_out)

# Default values, in case of empty columns. Also specifies the type of the
# decoded result.
record_defaults_in = [[1.], [1.], [1.], [1.], [1.], [1.]]
col1, col2, col3, col4, col5, col6 = tf.decode_csv(
    value_in, record_defaults=record_defaults_in)
# features = tf.stack([col1, col2, col3, col4, col5, col6], name='input_features')
features = tf.stack([col1, col2, col3], name='input_features')
record_defaults_out = [[1.], [1.], [1.]]
col7, col8, col9 = tf.decode_csv(
    value_out, record_defaults=record_defaults_out)
ref = tf.stack([col7, col8, col9])
col1_shape = col1.get_shape()

# layer1 = nn_layer(features, 6, 10, 'layer1')
layer1 = nn_layer(features, 3, 10, 'layer1')
layer2 = nn_layer(layer1, 10, 10, 'layer2')
layer3 = nn_layer(layer2, 10, 3, 'layer3', tf.identity)

# layer1 = nn_layer(features, 6, 3, 'layer1')
with tf.name_scope('pred'):
    pred = layer3
    variable_summaries(pred)
with tf.name_scope('loss'):
    squared_deltas = tf.square(ref - pred)
    loss = tf.reduce_sum(squared_deltas)
    variable_summaries(loss)

summary_op = tf.summary.merge_all()
saver = tf.train.Saver()

train_op = tf.train.GradientDescentOptimizer(0.01).minimize(loss) # construct an optimizer to minimize cost and fit line to my data
sess = tf.Session()

summary_writer = tf.summary.FileWriter(train_dir, sess.graph)
# Start populating the filename queue.
coord = tf.train.Coordinator()
threads = tf.train.start_queue_runners(sess=sess, coord=coord)

tf.global_variables_initializer().run(session=sess)


tf.train.write_graph(sess.graph_def, model_dir, graph_name)

for i in range(1001):
    if i % 10 == 0:
        summary_str, _ = sess.run([summary_op, train_op])
        summary_writer.add_summary(summary_str, i)
        saver.save(sess, checkpoint_prefix, global_step=i)
    else:
        sess.run(train_op)
summary_writer.close()

coord.request_stop()
coord.join(threads)

# print('weight: ', sess.run(w))
# print('bias: ', sess.run(b))

x_test = np.array([-0.32063, 0.050248, 0.10134, -0.66542, 0.064199, 0.052125])
elbow = x_test[3:]
# y_test = sess.run(pred, feed_dict={features: x_test})
y_test = sess.run(pred, feed_dict={features: x_test[:3]})
print('y_test= {:s}'.format(y_test))

touch = y_test.reshape(3)

print('elbow= {:s}'.format(elbow))
print('touch= {:s}'.format(touch))

v = elbow-touch
hand = touch + v*0.035/np.linalg.norm(v)
print('v= {:s}'.format(v))
print('length= {:0.3f}'.format(np.linalg.norm(v)))
print('hand= {:s}'.format(hand))


