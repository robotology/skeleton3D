#include "iCub/vtMappingTF/vtMappingTF.h"

using namespace std;
using namespace tensorflow;

Status vtMappingTF::LoadGraph(const string& graph_file_name,
                 std::unique_ptr<tensorflow::Session>* session) {
  tensorflow::GraphDef graph_def;
  Status load_graph_status =
      ReadBinaryProto(tensorflow::Env::Default(), graph_file_name, &graph_def);
  if (!load_graph_status.ok()) {
    return tensorflow::errors::NotFound("Failed to load compute graph at '",
                                        graph_file_name, "'");
  }
  session->reset(tensorflow::NewSession(tensorflow::SessionOptions()));
  Status session_create_status = (*session)->Create(graph_def);
  if (!session_create_status.ok()) {
    return session_create_status;
  }
  return Status::OK();
}

vtMappingTF::vtMappingTF(const string& _name, const string& _part,
                         const string& _output_layer, const string& _input_layer)
{
    name        = _name;
    part        = _part;

    // First we load and initialize the tensorflow model.
    root_dir    = "/home/pnguyen/icub-workspace/skeleton3D/";
    graph       = "tensorflow/model/output_graph.pb";

    input_layer = _input_layer;
    output_layer = _output_layer;

    string graph_path = tensorflow::io::JoinPath(root_dir, graph);
    Status load_graph_status = LoadGraph(graph_path, &session);
    if (!load_graph_status.ok()) {
        LOG(ERROR) << load_graph_status;
        yError("[%s] [vtMapping]: Fail in loading graph", name.c_str());
//        return -1;
    }
    else
        yInfo("[%s] [vtMapping]: Load graph sucessfully!!", name.c_str());

    handPoseIn.resize(3,0.0);
    elbowPoseIn.resize(3,0.0);
    handPoseOut.resize(3,0.0);
    input = Tensor(DT_FLOAT, TensorShape({6}));

}

bool vtMappingTF::setInput(const yarp::sig::Vector &_handPose, const yarp::sig::Vector &_elbowPose)
{
    if (_handPose[0]<=0.0 && _elbowPose[0]<=0.0 &&
            handPoseIn.size()==_handPose.size() && elbowPoseIn.size() == _elbowPose.size())
    {
        handPoseIn = _handPose;
        elbowPoseIn = _elbowPose;
        for (int i=0; i<3; i++)
            input.vec<float>()(i) = handPoseIn[i];
        for (int i=0; i<3; i++)
            input.vec<float>()(3+i) = elbowPoseIn[i];
        return true;
    }
    else
        return false;
}

bool vtMappingTF::computeMapping()
{
    Status run_status = session->Run({{input_layer, input}},
                                      {output_layer},{},&outputs);
    if (!run_status.ok()) {
        LOG(ERROR) << "Running model failed: " << run_status;
        yError("[%s] [vtMapping]: Running the model failed!!", name.c_str());
        return false;
    }
    else
    {
        yInfo("[%s] [vtMapping]: Running the model OK!!", name.c_str());
        auto output_mat = outputs[0].matrix<float>();
        yInfo("[%s] [vtMapping]: Output of network is: [%f, %f, %f]", name.c_str(),
              output_mat(0,0), output_mat(0,1), output_mat(0,2));
        for (int8_t i=0; i<handPoseOut.size(); i++)
            handPoseOut[i] = output_mat(0,i);
        return true;
    }
}

bool vtMappingTF::getOutput(yarp::sig::Vector &_handPose)
{
    if (_handPose.size() == handPoseOut.size())
    {
        _handPose = handPoseOut;
        return true;
    }
    else
        return false;
}
