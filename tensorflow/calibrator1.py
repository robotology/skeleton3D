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
batch_size = 1
use_elbow = True
INITIAL_LEARNING_RATE = 0.1
NUM_EPOCHS_PER_DECAY = 1000.0      # Epochs after which learning rate decays.
LEARNING_RATE_DECAY_FACTOR = 0.1  # Learning rate decay factor.
NUM_EXAMPLES_PER_EPOCH_FOR_TRAIN = 10000

reader_in = tf.TextLineReader()
reader_out = tf.TextLineReader()
key_in, value_in = reader_in.read(filename_queue_in)
key_out, value_out = reader_out.read(filename_queue_out)

# Default values, in case of empty columns. Also specifies the type of the
# decoded result.
record_defaults_in = [[1.], [1.], [1.], [1.], [1.], [1.]]
col1, col2, col3, col4, col5, col6 = tf.decode_csv(
    value_in, record_defaults=record_defaults_in)
if use_elbow:
    features = tf.stack([col1, col2, col3, col4, col5, col6], name='input_features')
else:
    features = tf.stack([col1, col2, col3], name='input_features')
record_defaults_out = [[1.], [1.], [1.]]
col7, col8, col9 = tf.decode_csv(
    value_out, record_defaults=record_defaults_out)
ref = tf.stack([col7, col8, col9])
col1_shape = col1.get_shape()

min_after_dequeue = 15000
capacity = min_after_dequeue + 3 * batch_size
example_batch, label_batch = tf.train.shuffle_batch(
    [features, ref], batch_size=batch_size, capacity=capacity,
    min_after_dequeue=min_after_dequeue, name='shuffle')

# with tf.name_scope('example'):
#     example = example_batch
# with tf.name_scope('label'):
#     label = label_batch

example = tf.identity(example_batch, name='example')
label = tf.identity(label_batch, name='label')

# Model
if use_elbow:
    layer1 = nn_layer(example, 6, 10, 'layer1')
else:
    layer1 = nn_layer(example, 3, 10, 'layer1')
layer2 = nn_layer(layer1, 10, 10, 'layer2')
layer3 = nn_layer(layer2, 10, 3, 'layer3', tf.identity)

# layer1 = nn_layer(features, 6, 3, 'layer1')
with tf.name_scope('pred'):
    pred = layer3
    variable_summaries(pred)
with tf.name_scope('loss'):
    squared_deltas = tf.square(label - pred)
    # loss = tf.reduce_sum(squared_deltas)
    loss = tf.reduce_mean(squared_deltas)
    tf.summary.scalar('loss', loss)
    # variable_summaries(loss)

num_batches_per_epoch = NUM_EXAMPLES_PER_EPOCH_FOR_TRAIN / batch_size
# decay_steps = int(num_batches_per_epoch * NUM_EPOCHS_PER_DECAY)
decay_steps = int(NUM_EPOCHS_PER_DECAY)

global_step = tf.contrib.framework.get_or_create_global_step()
# Decay the learning rate exponentially based on the number of steps.
with tf.name_scope('learning_rate'):
    lr = tf.train.exponential_decay(INITIAL_LEARNING_RATE,
                                    global_step,
                                    decay_steps,
                                    LEARNING_RATE_DECAY_FACTOR,
                                    staircase=True)
    tf.summary.scalar('rate', lr)

summary_op = tf.summary.merge_all()
saver = tf.train.Saver()

# train_op = tf.train.GradientDescentOptimizer(lr).minimize(loss, global_step) # construct an optimizer to minimize cost and fit line to my data
# train_op = tf.train.AdamOptimizer(0.1).minimize(loss, global_step) # construct an optimizer to minimize cost and fit line to my data
train_op = tf.train.AdadeltaOptimizer(0.1).minimize(loss, global_step) # construct an optimizer to minimize cost and fit line to my data
sess = tf.Session()

summary_writer = tf.summary.FileWriter(train_dir, sess.graph)

# Start populating the filename queue.
coord = tf.train.Coordinator()
threads = tf.train.start_queue_runners(sess=sess, coord=coord)

tf.global_variables_initializer().run(session=sess)

tf.train.write_graph(sess.graph_def, model_dir, graph_name)

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
for global_step in range(prev_step, NUM_EXAMPLES_PER_EPOCH_FOR_TRAIN+1):
    if global_step % 10 == 0:
        summary_str, _ = sess.run([summary_op, train_op])
        summary_writer.add_summary(summary_str, global_step)
        saver.save(sess, checkpoint_prefix, global_step=global_step)
        if global_step % 50 == 0:
            print('step= {:d}: loss= {:0.6f}'.format(global_step, sess.run(loss)))
    else:
        sess.run(train_op)
summary_writer.close()

coord.request_stop()
coord.join(threads)

# print('weight: ', sess.run(w))
# print('bias: ', sess.run(b))

x_test = np.array([-0.32063, 0.050248, 0.10134, -0.66542, 0.064199, 0.052125])
elbow = x_test[3:]
if use_elbow:
    y_test = sess.run(pred, feed_dict={features: x_test})
else:
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


