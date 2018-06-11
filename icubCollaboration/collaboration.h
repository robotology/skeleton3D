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

#define MODE_RECEIVE    1
#define MODE_GIVE       2
#define MODE_IDLE       0

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
    string      robot;

    bool        connectedReactCtrl, connectedARE;
    int8_t      running_mode;

    RpcServer   rpcPort;                            //!< rpc server to receive user request
    OPCClient   *opc;                               //!< OPC client object
    RpcClient   rpcReactCtrl;                       //!< rpc client port to send requests to /reactController/rpc
    RpcClient   rpcARE;                             //!< rpc client port to send requests to /actionsRenderingEngine/cmd:io
    string      partner_default_name;

    Vector      homePosL, homePosR, basket;
    double      workspaceX, workspaceY, workspaceZ_low, workspaceZ_high;


    // Interfaces for the torso
    yarp::dev::PolyDriver           ddT;
    yarp::dev::PolyDriver           ddG; // gaze  controller  driver
    yarp::dev::IEncoders            *iencsT;
    yarp::dev::IVelocityControl     *ivelT;
    yarp::dev::IPositionControl     *iposT;
    yarp::dev::IControlMode         *imodT;
    yarp::dev::IControlLimits       *ilimT;
    yarp::sig::Vector               *encsT;
    int jntsT;

    // Gaze interface
    yarp::dev::IGazeControl         *igaze;
    yarp::dev::IPositionControl     *iposG;
    int contextGaze;
    Vector                          homeAng;

    bool    configure(ResourceFinder &rf);
    bool    interruptModule();
    bool    close();
    bool    attach(RpcServer &source);
    double  getPeriod();
    bool    updateModule();

    bool    moveReactPPS(const string &target, const string &arm);

    bool    moveReactPPS(const Vector &pos, const string &arm);

    bool    homeARE();

    bool    stopReactPPS();

    bool    takeARE(const string &target, const string &arm);

    bool    takeARE(const Vector &pos, const string &arm);

    bool    graspARE(const Vector &pos, const string &arm);

    /**
     * @brief move move a robot arm with simple cartesian controller
     * @param pos Vector of 3D Cartesian position
     * @return True/False if completing action sucessfully or not
     */
    bool    move(const Vector &pos, const string &arm);

    bool    giveARE(const string &target, const string &arm);

    bool    giveARE(const Vector &pos, const string &arm);

    bool    dropARE(const Vector &pos, const string &arm);

    bool    checkPosReachable(const Vector &pos, const string &arm);

public:

    /**
     * @brief receive_object whole procedure to receive an object from human
     * @param _object
     * @return
     */
    bool    receive_object(const string &_object)
    {
        running_mode = MODE_RECEIVE;
        string arm = "right";
        Vector homePos(3,0.0);
        if (arm=="left")
            homePos = homePosL;
        else if (arm=="right")
            homePos = homePosR;
        else
            return false;

        bool ok = moveReactPPS(_object, arm);
        ok = ok && takeARE(_object, arm);
        ok = ok && moveReactPPS(homePos, arm);
//        ok = ok && move(basket, arm);
        running_mode = MODE_IDLE;
        return ok;
    }

    bool    move_pos_React(const Vector &_pos)
    {
        return moveReactPPS(_pos,"left");
    }

    /**
     * @brief hand_over_object whole procedure to give an object to human
     * @param _object
     * @return
     */
    bool    hand_over_object(const string &_object)
    {
        running_mode = MODE_GIVE;
        string arm = "right";
        Vector homePos(3,0.0);
        if (arm=="left")
            homePos = homePosL;
        else if (arm=="right")
            homePos = homePosR;
        else
            return false;

        // TODO grasp on table
        // ok = graspOnTable(_object, arm);

        bool ok = moveReactPPS(_object, arm);   //move to near empty hand
        ok = ok && giveARE(_object, arm);       //give to empty hand
        ok = ok && moveReactPPS(homePos, arm);

        running_mode = MODE_IDLE;
        return ok;
    }

    bool    take_pos_ARE(const Vector &_pos, const string &_arm)
    {
        return takeARE(_pos,_arm);
    }

    bool    drop_pos_ARE(const Vector &_pos, const string &_arm)
    {
        return dropARE(_pos,_arm);
    }

    bool    grasp_pos_ARE(const Vector &_pos, const string &_arm)
    {
        return graspARE(_pos, _arm);
    }

    bool    give_human_ARE(const string &_partH, const string &_armR)
    {
        return giveARE(_partH, _armR);
    }

    bool    stop_React()
    {
        return stopReactPPS();
    }

    bool    home_ARE()
    {
        return homeARE();
    }

    bool    move_torso(const Vector &_ang)
    {
        Vector ang = _ang;
        for (int8_t i=0; i<3; i++)
            imodT->setControlMode(i, VOCAB_CM_POSITION);
        return iposT->positionMove(ang.data());
    }
};

#endif // COLLABORATION_H
