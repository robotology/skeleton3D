#!/usr/bin/env python

import tensorflow as tf
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
    # Adding a name scope ensures logical grouping of the layers in the graph.
    with tf.name_scope(layer_name):
        # This Variable will hold the state of the weights for the layer
        with tf.name_scope('weights'):
            weights = weight_variable([input_dim, output_dim])
            # variable_summaries(weights)
        with tf.name_scope('biases'):
            biases = bias_variable([output_dim])
            # variable_summaries(biases)
        with tf.name_scope('Wx_plus_b'):
            preactivate = tf.matmul(input_tensor, weights) + biases
            # tf.summary.histogram('pre_activations', preactivate)
        activations = act(preactivate, name='activation')
        # tf.summary.histogram('activations', activations)
        return activations

# Construct model
def model_logistic(x, w, y, b):
    pred = tf.nn.softmax(tf.matmul(x, w) + b) # Softmax
    # pred = nn_layer(x, 6, 3, 'layer1')
    cost = tf.reduce_mean(-tf.reduce_sum(y*tf.log(pred), reduction_indices=1))
    return cost

# Minimize error using cross entropy
# cost = tf.reduce_mean(-tf.reduce_sum(y*tf.log(pred), reduction_indices=1))


def model_linear(x, w, y):
    pred = tf.matmul(x, w) # lr is just X*w so this model line is pretty simple
    cost = tf.square(y - pred)
    return cost


filename_queue_in  = tf.train.string_input_producer(["../matlab/inMatrix.csv"])
filename_queue_out = tf.train.string_input_producer(["../matlab/refMatrix.csv"])

train_dir = './log/'

reader_in = tf.TextLineReader()
reader_out = tf.TextLineReader()
key_in, value_in = reader_in.read(filename_queue_in)
key_out, value_out = reader_out.read(filename_queue_out)


# with tf.Graph().as_default():
    # with tf.name_scope('input'):

    # Default values, in case of empty columns. Also specifies the type of the
    # decoded result.
record_defaults_in = [[1.], [1.], [1.], [1.], [1.], [1.]]
col1, col2, col3, col4, col5, col6 = tf.decode_csv(
    value_in, record_defaults=record_defaults_in)
features = tf.stack([col1, col2, col3, col4, col5, col6])
record_defaults_out = [[1.], [1.], [1.]]
col7, col8, col9 = tf.decode_csv(
    value_out, record_defaults=record_defaults_out)
ref = tf.stack([col7, col8, col9])
col1_shape = col1.get_shape()

X = tf.placeholder(tf.float32, [None, 6]) # create symbolic variables
Y = tf.placeholder(tf.float32, [None, 3])

with tf.name_scope('weights'):
    w = tf.Variable(tf.zeros([6, 3]), name="weights") # create a shared variable (like theano.shared) for the weight matrix
    variable_summaries(w)

with tf.name_scope('bias'):
    b = tf.Variable(tf.zeros([3]), name="bias")
    variable_summaries(b)

with tf.name_scope('loss'):
    cost = model_logistic(X, w, Y, b)
    # variable_summaries(cost)
# y_model = model_linear(X, w)
#
# cost_linear = tf.square(Y - y_model) # use square error for cost function

summary_op = tf.summary.merge_all()
saver = tf.train.Saver()


train_op = tf.train.GradientDescentOptimizer(0.01).minimize(cost) # construct an optimizer to minimize cost and fit line to my data
# train_op = tf.train.GradientDescentOptimizer(0.01).minimize(model_linear(X, w, Y)) # construct an optimizer to minimize cost and fit line to my data
# with tf.Session() as sess:
sess = tf.Session()

summary_writer = tf.summary.FileWriter(train_dir, sess.graph)
# Start populating the filename queue.
coord = tf.train.Coordinator()
threads = tf.train.start_queue_runners(sess=sess, coord=coord)

tf.global_variables_initializer().run(session=sess)

for i in range(1000):
    # Retrieve a single instance:
    example, label = sess.run([features, ref])
    example = example.reshape(1, 6)
    label = label.reshape(1, 3)
    # sess.run(train_op, feed_dict={X: example, Y: label})

    if i % 10 == 0:
        summary_str,_ = sess.run([summary_op, train_op], feed_dict={X: example, Y: label})
        summary_writer.add_summary(summary_str, i)
        saver.save(sess, train_dir, global_step=i)
    else:
        sess.run(train_op, feed_dict={X: example, Y: label})

coord.request_stop()
coord.join(threads)

print('weight: ', sess.run(w))
print('bias: ', sess.run(b))


