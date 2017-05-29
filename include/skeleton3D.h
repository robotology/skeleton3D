#ifndef SKELETON3D_H
#define SKELETON3D_H

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

using namespace std;
using namespace yarp::os;
using namespace yarp::sig;
using namespace yarp::math;
using namespace iCub::ctrl;
using namespace icubclient;

class skeleton3D : public RFModule
{
protected:
    double      period;
    string      name;
    double      body_valence;
    double      part_dimension;
    bool        use_part_conf;

    Stamp       ts;

    RpcServer   rpcPort;                            //!< rpc server to receive user request
    RpcClient   rpcGet3D;                           //!< rpc client port to send requests to SFM
    OPCClient   *opc;                               //!< OPC client object

    BufferedPort<Bottle>    bodyPartsInPort;        //!< buffered port of input of received body parts location in image

    BufferedPort<Bottle>    ppsOutPort;             //!< buffered port of output to send body parts as obstacles to PPS (visuoTactileWrapper)

    Mutex                   mutexResourcesSkeleton;
    Mutex                   mutexResourcesSFM;

    bool                    connected3D;
    bool                    connectedPPS;

    string                  partner_default_name;   //!< string value of default name of partner
    icubclient::Agent*      partner;                //!< human as an agent object
    kinectWrapper::Player   player;
    map<string,double>      confJoints;             //!< confidence of identified skeleton

    double                  dSince;                 //!< double value of timers
    unsigned long           dTimingLastApparition;  //!< time struct of the last appartition of an agent
    double                  dThresholdDisparition;  //!< timing maximal of non-reconnaissance of a agent, after thath we consider the agent as absent


    /**
     * @brief get3DPosition Get the 3D point coordinate in Root frame through SFM
     * @param point A CvPoint for the estimated coordinate of an image pixel.
     * @param x Vector for 3D point coordinate. If SFM return more than one 3D point as result, the coordinate is average of all result
     * @return True if can get 3D point from SFM, False otherwise
     */
    bool    get3DPosition(const CvPoint &point, Vector &x);

    bool    obtainBodyParts(deque<CvPoint> &partsCV);

    void    addJoint(map<string,kinectWrapper::Joint> &joints, const CvPoint &point, const string &partName);

    void    addConf(const double &conf, const string &partName);

    bool    streamPartsToPPS();

    void    addPartToStream(Agent* a, const string &partName, Bottle &streamedObj);

    double  computeValence(const string &partName);

    void    extrapolateHand(map<string,kinectWrapper::Joint> &jnts);

    bool    extrapolatePoint(const Vector &p1, const Vector &p2, Vector &result);

    bool    configure(ResourceFinder &rf);
    bool    interruptModule();
    bool    close();
    bool    attach(RpcServer &source);
    double  getPeriod();
    bool    updateModule();
public:


};

#endif // SKELETON3D_H
