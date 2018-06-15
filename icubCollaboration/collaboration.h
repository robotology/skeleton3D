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
    string      part;
    string      _arm;
    double      posTol;

    bool        connectedReactCtrl, connectedARE;
    int8_t      running_mode;

    RpcServer   rpcPort;                            //!< rpc server to receive user request
    OPCClient   *opc;                               //!< OPC client object
    RpcClient   rpcReactCtrl;                       //!< rpc client port to send requests to /reactController/rpc
    RpcClient   rpcARE;                             //!< rpc client port to send requests to /actionsRenderingEngine/cmd:io
    string      partner_default_name;

    Vector      homePosL, homePosR, basket;
    double      workspaceX, workspaceY, workspaceZ_low, workspaceZ_high;

    bool                    isHoldingObject;                    //!< bool variable to show if object is holding, assume that a sucessful grasp action means robot holding the object
    icubclient::Object      *manipulatingObj;


    // Interfaces for the torso
    yarp::dev::PolyDriver           ddT;
    yarp::dev::PolyDriver           ddG; // gaze  controller  driver
    yarp::dev::PolyDriver           ddA; // arm  controller  driver
    yarp::dev::IEncoders            *iencsT;
    yarp::dev::IVelocityControl     *ivelT;
    yarp::dev::IPositionControl     *iposT;
    yarp::dev::IControlMode         *imodT;
    yarp::dev::IControlLimits       *ilimT;
    yarp::sig::Vector               *encsT;
    int jntsT;

    // Arm interface
    yarp::dev::ICartesianControl    *icartA;
    int                             contextArm;

    // Gaze interface
    yarp::dev::IGazeControl         *igaze;
    yarp::dev::IPositionControl     *iposG;
    int                             contextGaze;
    Vector                          homeAng;

    bool    configure(ResourceFinder &rf);
    bool    interruptModule();
    bool    close();
    bool    attach(RpcServer &source);
    double  getPeriod();
    bool    updateModule();

    bool    moveReactPPS(const string &target, const string &arm, const double &timeout=10.,
                         const bool &isTargetHuman = false);

    bool    moveReactPPS(const Vector &pos, const string &arm, const double &timeout=10.);

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

    bool    lookAtHome(const Vector &ang, const double &timeout);

    /**
     * @brief updateHoldingObj update the position of the object hold by robot hand
     * @param x_EE End-effector position
     * @param o_EE End-effector orientation in axis-angle format
     * @return True/False if completing action sucessfully or not
     */
    bool    updateHoldingObj(const Vector &x_EE, const Vector &o_EE);

public:

    /**
     * @brief receive_object whole procedure to receive an object from human
     * @param _object
     * @return
     */
    bool    receive_object(const string &_object)
    {
        running_mode = MODE_RECEIVE;
        string arm = _arm;
        Vector homePos(3,0.0);
        if (arm=="left")
            homePos = homePosL;
        else if (arm=="right")
            homePos = homePosR;
        else
            return false;

        bool ok = moveReactPPS(_object, arm);
        isHoldingObject = takeARE(_object, arm);
        ok = ok && isHoldingObject;

        Time::delay(0.5);
        lookAtHome(homeAng,5.0);

        ok = ok && moveReactPPS(homePos, arm);
        lookAtHome(homeAng,5.0);

        ok = ok && dropARE(basket, arm);
        if (ok)
        {
            manipulatingObj->m_ego_position = basket;
            manipulatingObj->m_value = 0.0;
            opc->commit(manipulatingObj);
            isHoldingObject = false;
        }


        Time::delay(0.5);
        ok = ok && home_ARE();

        lookAtHome(homeAng,5.0);
        running_mode = MODE_IDLE;
        return ok;
    }

    bool    move_pos_React(const Vector &_pos, const double _timeout)
    {
        return moveReactPPS(_pos,_arm, _timeout);
    }

    /**
     * @brief hand_over_object whole procedure to give an object to human
     * @param _object
     * @return
     */
    bool    hand_over_object(const string &_object, const string &_human_part)
    {
        running_mode = MODE_GIVE;
        string arm = _arm;
        Vector homePos(3,0.0);
        if (arm=="left")
            homePos = homePosL;
        else if (arm=="right")
            homePos = homePosR;
        else
            return false;

        // TODO grasp on table
        // isHoldingObject = graspOnTable(_object, arm);

        Time::delay(0.5);
        lookAtHome(homeAng,5.0);
        // TODO: reduce the valence of _human_part to receive object

        bool ok = isHoldingObject && moveReactPPS(_object, arm, 10.0, true);   //move to near empty hand
        ok = ok && giveARE(_human_part, arm);       //give to empty hand

        if (ok)
            isHoldingObject = false;

        Time::delay(0.5);
        lookAtHome(homeAng,5.0);
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

    bool    set_posTol(const double _tol)
    {
        if (_tol>0.0)
        {
            posTol = _tol;
            return true;
        }
        else
            return false;

    }

    double    get_posTol()
    {
        return posTol;
    }

    bool    set_homeAng(const Vector &_angs)
    {
        if (_angs.size()==3)
        {
            homeAng = _angs;
            return true;
        }
        else
            return false;
    }
};

#endif // COLLABORATION_H
