#ifndef COLLABORATION_H
#define COLLABORATION_H

#include <string>
#include <deque>
#include <map>
#include <ctime>

#include <yarp/os/all.h>
#include <yarp/sig/all.h>
#include <yarp/math/Math.h>
#include <yarp/math/Rand.h>
#include <iCub/ctrl/filters.h>

#include <icubclient/all.h>
#include "kinectWrapper/kinectWrapper.h"

#include <opencv2/opencv.hpp>

#include "collaboration_IDL.h"

using namespace std;
using namespace yarp::os;
using namespace yarp::sig;
using namespace yarp::math;
using namespace iCub::ctrl;
using namespace icubclient;

class collaboration : public RFModule, public collaboration_IDL
{
protected:
    double      period;
    string      name;

    bool        connectedReactCtrl, connectedARE;

    RpcServer   rpcPort;                            //!< rpc server to receive user request
    OPCClient   *opc;                               //!< OPC client object
    RpcClient   rpcReactCtrl;                       //!< rpc client port to send requests to /reactController/rpc
    RpcClient   rpcARE;                             //!< rpc client port to send requests to /actionsRenderingEngine/cmd:io

    bool    configure(ResourceFinder &rf);
    bool    interruptModule();
    bool    close();
    bool    attach(RpcServer &source);
    double  getPeriod();
    bool    updateModule();

    bool    moveReactPPS(const string &target, const string &arm);

    bool    moveReactPPS(const Vector &pos, const string &arm);

    bool    stopReactPPS();

    bool    takeARE(const string &target, const string &arm);

    /**
     * @brief move move a robot arm with simple cartesian controller
     * @param pos Vector of 3D Cartesian position
     * @return True/False if completing action sucessfully or not
     */
    bool    move(const Vector &pos);

    bool    giveARE(const string &target, const string &arm);

public:
    bool    receive_object(const string &_object)
    {

    }

    bool    move_pos_React(const Vector &_pos)
    {
        return moveReactPPS(_pos,"left");
    }

    bool    hand_over_object(const string &_object)
    {

    }
};

#endif // COLLABORATION_H
