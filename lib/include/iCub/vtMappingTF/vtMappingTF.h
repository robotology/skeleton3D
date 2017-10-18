/* Copyright (C) 2017 RobotCub Consortium
 * Author:  Phuong Nguyen
 * email:   phuong.nguyen@iit.it
 * website: www.robotcub.org
 * Permission is granted to copy, distribute, and/or modify this program
 * under the terms of the GNU General Public License, version 2 or any
 * later version published by the Free Software Foundation.
 *
 * A copy of the license can be found at
 * http://www.robotcub.org/"+robot+"/license/gpl.txt
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details
*/
#ifndef VTMAPPINGTF_H
#define VTMAPPINGTF_H

#include <yarp/os/all.h>
#include <yarp/sig/all.h>
#include <yarp/math/Math.h>
#include <yarp/math/Rand.h>
#include <iCub/ctrl/filters.h>

#include "tensorflow/cc/ops/const_op.h"
#include "tensorflow/cc/ops/image_ops.h"
#include "tensorflow/cc/ops/standard_ops.h"
#include "tensorflow/cc/ops/io_ops_internal.h"
#include "tensorflow/core/framework/graph.pb.h"
#include "tensorflow/core/framework/tensor.h"
#include "tensorflow/core/graph/default_device.h"
#include "tensorflow/core/graph/graph_def_builder.h"
#include "tensorflow/core/lib/core/errors.h"
#include "tensorflow/core/lib/core/stringpiece.h"
#include "tensorflow/core/lib/core/threadpool.h"
#include "tensorflow/core/lib/io/path.h"
#include "tensorflow/core/lib/strings/stringprintf.h"
#include "tensorflow/core/platform/env.h"
#include "tensorflow/core/platform/init_main.h"
#include "tensorflow/core/platform/logging.h"
#include "tensorflow/core/platform/types.h"
#include "tensorflow/core/public/session.h"
#include "tensorflow/core/util/command_line_flags.h"

using namespace std;

class vtMappingTF
{
protected:
    string                             name;               //!< name of module using vtMapping
    string                             part;               //!< name of robot arm (left/right) to map visual information to
    unique_ptr<tensorflow::Session>    session;            //!< TensorFlow session
    string                             graph;              //!< path to Tensorflow trained graph file (.pb) of the corresponding part
    string                             root_dir;
    string                             input_layer;        //!< name of input layer to the graph
    string                             output_layer;       //!< name of output layer of the graph

    yarp::sig::Vector       handPoseIn;         //!< Yarp Vector of sensed hand pose through visual system
    yarp::sig::Vector       elbowPoseIn;        //!< Yarp Vector of sensed elbow pose through visual system
    tensorflow::Tensor      input;              //!< TensorFlow Tensor of input to contain handPoseIn and elbowPoseIn

    std::vector<tensorflow::Tensor> outputs;    //!< Vector of TensorFlow Tensor of output computation through mapping graph
    yarp::sig::Vector       handPoseOut;        //!< Yarp vecotr of calibrated hand pose

public:
    vtMappingTF(const string& _name, const string& _part,
                const string& _root_dir,
                const string& _output_layer, const string& _input_layer,
                bool _use_elbow);

    tensorflow::Status LoadGraph(const std::string& graph_file_name,
                                 std::unique_ptr<tensorflow::Session>* session);

    bool setInput(const yarp::sig::Vector& _handPose, const yarp::sig::Vector& _elbowPose);

    bool setInput(const yarp::sig::Vector& _handPose);

    bool computeMapping();

    bool getOutput(yarp::sig::Vector& _handPose);
};

#endif // VTMAPPINGTF_H
