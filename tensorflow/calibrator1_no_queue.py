#!/usr/bin/env python
"""
Training code for mapping visual space information to motor space
Using tf_queue for reading csv dataset files ==> There is no Placeholder for data input coz
tf_queue loads data to graph by itself

"""

import os
import tensorflow as tf
import random
from tensorflow.python.tools import freeze_graph
import numpy as np
import pandas as pd


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


def nn_layer(input_tensor, input_dim, output_dim, layer_name, batch_size=1, act=tf.nn.relu):
    """Reusable code for making a simple neural net layer.

    It does a matrix multiply, bias add, and then uses relu to nonlinearize.
    It also sets up name scoping so that the resultant graph is easy to read,
    and adds a number of summary ops.
    """
    input_tensor = tf.reshape(tensor=input_tensor, shape=[batch_size, input_dim], name='input')
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


def model(_input, _batch_size = 1):
    if use_elbow:
        _layer1 = nn_layer(_input, 6, 10, 'layer1', _batch_size)
    else:
        _layer1 = nn_layer(_input, 3, 10, 'layer1', _batch_size)
    _layer2 = nn_layer(_layer1, 10, 10, 'layer2', _batch_size)
    _layer3 = nn_layer(_layer2, 10, 3, 'layer3', _batch_size, tf.identity)
    return _layer3

train_dir = './log/'
model_dir = './model/'
checkpoint_prefix = os.path.join(train_dir, 'saved_checkpoint')
graph_name = 'mapping_graph.pb'
batch_size = 1
use_elbow = True

NUM_EPOCHS_PER_DECAY = 500.0      # Epochs after which learning rate decays.
NUM_EXAMPLES_PER_EPOCH_FOR_TRAIN = 5000

training_data = pd.read_csv("../matlab/inMatrix_balanced.csv").as_matrix()
training_labels = pd.read_csv("../matlab/refMatrix_balanced.csv").as_matrix()

if not use_elbow:
    training_data = training_data.ix[:, :3]
    print(training_data.shape)

dataset_sz = len(training_data)
testset_sz = int(0.3*dataset_sz)

# with tf.Session() as sess:
# Got problem with free_calibrator
# data_initializer = tf.placeholder(dtype=tf.float32, shape=training_data.shape)
# label_initializer = tf.placeholder(dtype=tf.float32, shape=training_labels.shape)
# input_data = tf.Variable(data_initializer, trainable=False, collections=[], name='input_data')
# input_labels = tf.Variable(label_initializer, trainable=False, collections=[], name='input_labels')

input_data = tf.constant(training_data, dtype=tf.float32, shape=training_data.shape)
input_labels = tf.constant(training_labels, dtype=tf.float32, shape=training_labels.shape)

# create a partition vector
partitions = [0] * dataset_sz
partitions[:testset_sz] = [1] * testset_sz
random.shuffle(partitions)

# partition our data into a test and train set according to our partition vector
train_data, test_data = tf.dynamic_partition(input_data, partitions, 2)
train_labels, test_labels = tf.dynamic_partition(input_labels, partitions, 2)

train_input = tf.train.slice_input_producer(
    [train_data, train_labels], name='train_producer', shuffle=True)
test_input = tf.train.slice_input_producer(
    [test_data, test_labels], name='test_producer', shuffle=True)
# examples, labels = tf.train.batch(
#     [test_data, test_labels], batch_size=batch_size)

example = tf.identity(train_input[0], name='example')
label = tf.identity(train_input[1], name='label')

test_example = tf.identity(test_input[0], name='test_example')
test_label = tf.identity(test_input[1], name='test_label')

# Model
# X = tf.placeholder(tf.float32, [None, training_data.shape[1]], name='example')
# Y = tf.placeholder(tf.float32, [None, 3], name='ref')
output = model(example, 1)

with tf.name_scope('pred'):
    pred = output
    variable_summaries(pred)
with tf.name_scope('loss'):
    squared_deltas = tf.square(label - pred)
    # loss = tf.reduce_sum(squared_deltas)
    loss = tf.reduce_mean(squared_deltas)
    tf.summary.scalar('loss', loss)

num_batches_per_epoch = NUM_EXAMPLES_PER_EPOCH_FOR_TRAIN / batch_size

global_step = tf.contrib.framework.get_or_create_global_step()
summary_op = tf.summary.merge_all()
saver = tf.train.Saver()

# train_op = tf.train.GradientDescentOptimizer(lr).minimize(loss, global_step) # construct an optimizer to minimize cost and fit line to my data
# train_op = tf.train.AdamOptimizer(0.1).minimize(loss, global_step) # construct an optimizer to minimize cost and fit line to my data
train_op = tf.train.AdadeltaOptimizer(0.1).minimize(loss, global_step) # construct an optimizer to minimize cost and fit line to my data
sess = tf.Session()
tf.global_variables_initializer().run(session=sess) # This has to be called before other run

# sess.run(input_data.initializer, feed_dict={data_initializer: training_data})
# sess.run(input_labels.initializer, feed_dict={label_initializer: training_labels})

summary_writer = tf.summary.FileWriter(train_dir, sess.graph)
tf.train.write_graph(sess.graph_def, model_dir, graph_name)

# Start populating the filename queue.
coord = tf.train.Coordinator()
threads = tf.train.start_queue_runners(sess=sess, coord=coord)

# Read the old checkpoint to resume training if possible
ckpt = tf.train.get_checkpoint_state(train_dir)
prev_step = 0
if ckpt and ckpt.model_checkpoint_path:
    prev_step = int(ckpt.model_checkpoint_path.split('/')[-1].split('-')[-1])
    print('prev_step %d' % prev_step)

    saver.restore(sess, ckpt.model_checkpoint_path)
    # global_step = int(ckpt.model_checkpoint_path.split('/')[-1].split('-')[-1])
    print('Found checkpoint')

# Train
for global_step in range(prev_step, (dataset_sz-testset_sz)):
    # ex = example.eval(session=sess)
    # ex = ex.reshape((1, len(ex)))
    # la = label.eval(session=sess)
    # la = la.reshape((1, len(la)))
    if global_step % 10 == 0:
        summary_str, _ = sess.run([summary_op, train_op])
        summary_writer.add_summary(summary_str, global_step)
        saver.save(sess, checkpoint_prefix, global_step=global_step)
        if global_step % 50 == 0:
            print('step= {:d}: loss= {:0.6f}'.format(global_step, sess.run(loss)))
    else:
        sess.run(train_op)
summary_writer.close()

# Test
L = 0
for i in range(testset_sz):
    ex = test_example.eval(session=sess)
    la = test_label.eval(session=sess)
    l = sess.run(loss, feed_dict={example: ex, label: la})
    L += l
    if i % 50 == 0 or i == testset_sz-1:
        print('step= {:d}: loss= {:0.6f}'.format(i, l))
# ex = test_data.eval(session=sess)
# la = test_labels.eval(session=sess)
# l = sess.run(loss, feed_dict={X: ex, Y: la})
print('test loss= {:0.6f}'.format(L/testset_sz))

coord.request_stop()
coord.join(threads)

x_test = np.array([-0.32063, 0.050248, 0.10134, -0.66542, 0.064199, 0.052125])
elbow = x_test[3:]
# x_test = x_test.reshape((1, len(x_test)))
if use_elbow:
    y_test = sess.run(pred, feed_dict={example: x_test})
else:
    y_test = sess.run(pred, feed_dict={example: x_test[:3]})
print('y_test= {:s}'.format(y_test))

# # touch = y_test.reshape(3)
# #
# # print('elbow= {:s}'.format(elbow))
# # print('touch= {:s}'.format(touch))
# #
# # v = elbow-touch
# # hand = touch + v*0.035/np.linalg.norm(v)
# # print('v= {:s}'.format(v))
# # print('length= {:0.3f}'.format(np.linalg.norm(v)))
# # print('hand= {:s}'.format(hand))


