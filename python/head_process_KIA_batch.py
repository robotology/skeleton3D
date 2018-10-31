#!/usr/bin/env python

import os
import sys
import numpy as np

import pandas as pd
import matplotlib
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42
import matplotlib.pyplot as plt
import argparse


head_pose_log = 'head_pose/data.log'


def parse_args():
    """Parse input arguments."""
    parser = argparse.ArgumentParser(description='Train and Test Kinematic Structure Learning model')
    parser.add_argument('--dataset', dest='dataset_path', help='Name of the dataset from yarp datadumper',
                        default='data')
    parser.add_argument('--datapath', dest='data_path', help='Path to place where dataset folder is',
                        default='/home/r1-user')

    parser.add_argument('--mode', dest='mode', help='Process mode (single/batch)',
                        default='batch')

    _args = parser.parse_args()

    return _args


def import_datafiles_times(filename):
    data = pd.read_csv(filename, sep=',', header=None).as_matrix()
    data_len = data.shape[0]
    data_vars = data.shape[1]
    print('data_vars: ', data_vars)
    dict = {'files': data[:, 0],
            'times': data[:, 1:7],
            'data_len': data_len}

    return dict


def import_tool_data(filename):
    data = pd.read_csv(filename, sep=' |\t').as_matrix()
    data_len = data.shape[0]
    data_vars = data.shape[1]
    print('data_vars: ', data_vars)
    dict = {'time': data[:, 1],
            'x': data[:, 2],
            'y': data[:, 3],
            'z': data[:, 4],
            'data_len': data_len}

    return dict


def process_head_batch(_args):
    data_filename = os.path.join(os.getcwd(), 'datafiles_times.txt')

    print data_filename

    files_times = import_datafiles_times(data_filename)
    files = files_times['files']
    times = files_times['times']

    print files
    print times

    for i in range(len(files)):
        process_head(_args, dataset=files[i], times=times[i,:])


def process_head(_args, dataset=None, times=None):
    """

    :type times: object
    :type _args: object
    """
    # W: 10 20 40 70 85 100
    # Marta: 10 20 40 60 70 85
    # Vicky: 10 30 45 55 70 85
    # Vicky0:10 25 40 50 70 90
    # Edwin: 10 30 47 60 80 100
    # Pietro: 5 30 47 60 80 90
    # Edoardo:10 30 50 70 90 120
    # Navaab: 10 30 50 65 85 110
    # Eamon: 10 30 50 65 85 110
    # Yisu: 10 30 47 65 80 95
    # Phuong: 10 25 40 65 80 95
    t = [10, 30, 47, 65, 80, 95]

    if dataset is None:
        dataset = _args.dataset_path

    if times is not None:
        t = times

    # clean & preprocess data
    idx0 = 1000
    data_filename = os.path.join(_args.data_path, dataset, head_pose_log)
    print('data_filename: ', data_filename)
    head_data = import_tool_data(data_filename)
    time = np.array(head_data['time'])
    t_rel = time[idx0:] - time[idx0]
    x = np.array(head_data['x'])
    x_rel = x[idx0:] - x[idx0]
    y = np.array(head_data['y'])
    y_rel = y[idx0:] - y[idx0]

    np.set_printoptions(precision=4)
    err = np.empty([6, 3])
    idx = np.where(t_rel > t[0])[0][0]
    print (t_rel[idx])
    print x_rel[idx]*100, y_rel[idx]*100
    err[0, 0] = t_rel[idx]
    err[0, 1] = x_rel[idx]*100
    err[0, 2] = y_rel[idx]*100

    idx = np.where(t_rel > t[1])[0][0]
    print (t_rel[idx])
    print x_rel[idx] * 100, y_rel[idx] * 100, 'err=', (abs(x_rel[idx] * 100) - 21), y_rel[idx] * 100
    err[1, 0] = t_rel[idx]
    err[1, 1] = (abs(x_rel[idx] * 100) - 21)
    err[1, 2] = y_rel[idx]*100

    idx = np.where(t_rel > t[2])[0][0]
    print (t_rel[idx])
    print x_rel[idx] * 100, y_rel[idx] * 100, x_rel[idx] * 100, 'err =', (abs(y_rel[idx] * 100)-33)
    err[2, 0] = t_rel[idx]
    err[2, 1] = x_rel[idx]*100
    err[2, 2] = (abs(y_rel[idx] * 100)-33)

    idx = np.where(t_rel > t[3])[0][0]
    print (t_rel[idx])
    print x_rel[idx] * 100, y_rel[idx] * 100, 'err =', (abs(x_rel[idx] * 100)-22), y_rel[idx] * 100
    err[3, 0] = t_rel[idx]
    err[3, 1] = (abs(x_rel[idx] * 100)-22)
    err[3, 2] = y_rel[idx]*100

    idx = np.where(t_rel > t[4])[0][0]
    print (t_rel[idx])
    print x_rel[idx] * 100, y_rel[idx] * 100, x_rel[idx] * 100, 'err =', (abs(y_rel[idx] * 100)-34)
    err[4, 0] = t_rel[idx]
    err[4, 1] = x_rel[idx]*100
    err[4, 2] = (abs(y_rel[idx] * 100)-34)

    idx = np.where(t_rel > t[5])[0][0]
    print (t_rel[idx])
    print x_rel[idx] * 100, y_rel[idx] * 100
    err[5, 0] = t_rel[idx]
    err[5, 1] = x_rel[idx]*100
    err[5, 2] = y_rel[idx]*100

    print err

    result_path = os.path.join(os.getcwd(), 'results')
    if not os.path.exists(result_path):
        os.mkdir(result_path)
        print("Directory ", result_path, " Created ")
    else:
        print("Directory ", result_path, " already exists")
    filename = os.path.join(result_path, dataset + '_result.csv')
    print filename

    np.savetxt(filename, err, delimiter="\t", fmt='%1.3f')

    ax1 = plt.subplot(2, 1, 1)
    ax1.plot(t_rel, x_rel, label='x')
    ax1.set_ylabel('x (m)', fontsize=18)
    plt.grid(True)

    ax2 = plt.subplot(2, 1, 2)
    ax2.plot(t_rel, y_rel, label='y')
    ax2.set_ylabel('y (m)', fontsize=18)
    plt.grid(True)

    plt.show()


if __name__ == '__main__':
    args = parse_args()
    print(args)
    if args.mode == 'single':
        process_head(args)
    elif args.mode == 'batch':
        process_head_batch(args)