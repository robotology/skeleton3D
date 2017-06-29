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

#include "skeleton3D_IDL.h"

using namespace std;
using namespace yarp::os;
using namespace yarp::sig;
using namespace yarp::math;
using namespace iCub::ctrl;
using namespace icubclient;

class skeleton3D : public RFModule, public skeleton3D_IDL
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

    bool                        use_part_filter;    //!< boolean value to define the usage of median filter for body parts
    bool                        init_filters;       //!< boolean value to define if the median filter for body parts have been initialized
    int                         filterOrder;        //!< integer value for order of the median filter of the body parts
    map<string,MedianFilter>    filterSkeleton;     //!< median filter for position of a skeleton

    bool                        fakeHand;


    void    filt(map<string,kinectWrapper::Joint> &joints, map<string,kinectWrapper::Joint> &jointsFiltered);

    /**
     * @brief get3DPosition Get the 3D point coordinate in Root frame through SFM
     * @param point A CvPoint for the estimated coordinate of an image pixel.
     * @param x Vector for 3D point coordinate. If SFM return more than one 3D point as result, the coordinate is average of all result
     * @return True if can get 3D point from SFM, False otherwise
     */
    bool    get3DPosition(const CvPoint &point, Vector &x);

    /**
     * @brief obtainBodyParts Get body parts position and confidence from Tensorflow-based skeleton2D module
     * @param partsCV Set of CvPoint(s) of body parts from skeleton2D module
     * @return True if can obtain the good value from skeleton2D module, False otherwise
     */
    bool    obtainBodyParts(deque<CvPoint> &partsCV);

    /**
     * @brief addJoint Add a joint of skeleton by name to a skeleton
     * @param joints A skeleton by set of joints and equivalent joint name
     * @param point CvPoint of the body part from skeleton2D module
     * @param partName String value of the name of a part
     */
    void    addJoint(map<string,kinectWrapper::Joint> &joints, const CvPoint &point, const string &partName);

    /**
     * @brief addConf Store the received identified confidence rate of a body part
     * @param conf Double value of the confidence rate
     * @param partName String value of the name of a part
     */
    void    addConf(const double &conf, const string &partName);

    /**
     * @brief streamPartsToPPS Send body parts to (PPS) visuoTactileWrapper
     * @return True if send successfully, False otherwise
     */
    bool    streamPartsToPPS();

    /**
     * @brief addPartToStream Accumulate a body part by name to streamed Bottle before sending it to PPS
     * @param a An icubclient Agent, which contains all OPC-related information, e.g skeleton, position, dimensions of parts, valence of parts
     * @param partName String value of the name of a part
     * @param streamedObj A Yarp Bottle to store streamed body parts
     */
    void    addPartToStream(Agent* a, const string &partName, Bottle &streamedObj);

    /**
     * @brief computeValence Compute the body part valence based on the identified confidence rate
     * @param partName String for the name of a body part
     * @return Double value of the body part valence
     */
    double  computeValence(const string &partName);

    /**
     * @brief extrapolateHand Estimate the hand position, known the elbow and wrist position
     * @param jnts A skeleton by set of joints and equivalent joint name
     */
    void    extrapolateHand(map<string,kinectWrapper::Joint> &jnts);

    /**
     * @brief extrapolatePoint Estimate a point position, known 2 other points in the same line
     * @param p1 Yarp Vector of 1st point in the line
     * @param p2 Yarp Vector of 2nd point in the line
     * @param result Estimated position
     * @return True if can estimate the point, False otherwise and size of p1 and/or p2 is wrong
     */
    bool    extrapolatePoint(const Vector &p1, const Vector &p2, Vector &result);

    bool    configure(ResourceFinder &rf);
    bool    interruptModule();
    bool    close();
    bool    attach(RpcServer &source);
    double  getPeriod();
    bool    updateModule();
public:

    /************************************************************************/
    // Thrift methods
    bool set_valence(const double _valence)
    {
        if (_valence<=1.0 && _valence>=-1.0)
        {
            body_valence = _valence;
            return true;
        }
        else
            return false;
    }

    double get_valence()
    {
        return body_valence;
    }

    bool set_filter_order(const int16_t _order)
    {
        if (_order>=0)
        {
            filterOrder = _order;
            return true;
        }
        else
            return false;
    }

    int16_t get_filter_order()
    {
        return filterOrder;
    }

    bool set_threshold_disparition(const double _thr)
    {
        if (_thr>0.0)
        {
            dThresholdDisparition = _thr;
            return true;
        }
        else
            return false;
    }

    double get_threshold_disparition()
    {
        return dThresholdDisparition;
    }

    bool enable_fake_hand()
    {
        fakeHand = true;
        return true;
    }

    bool disable_fake_hand()
    {
        fakeHand = false;
        return true;
    }

    bool enable_part_conf()
    {
        use_part_conf = true;
        return true;
    }

    bool disable_part_conf()
    {
        use_part_conf = false;
        return true;
    }
    std::map<unsigned int, std::string> mapPartsOpenPose {
        {0,  "Nose"},
        {1,  "Neck"},
        {2,  "RShoulder"},
        {3,  "RElbow"},
        {4,  "RWrist"},
        {5,  "LShoulder"},
        {6,  "LElbow"},
        {7,  "LWrist"},
        {8,  "RHip"},
        {9,  "RKnee"},
        {10, "RAnkle"},
        {11, "LHip"},
        {12, "LKnee"},
        {13, "LAnkle"},
        {14, "REye"},
        {15, "LEye"},
        {16, "REar"},
        {17, "LEar"},
        {18, "Background"}
    };
    std::map<unsigned int, std::string> mapPartsKinect {
        {0,  "head"},
        {1,  "shoulderCenter"},
        {2,  "shoulderRight"},
        {3,  "elbowRight"},
        {4,  "handRight"},      // wrist --> hand: use extrapolatePoint later to convert truely
        {5,  "shoulderLeft"},
        {6,  "elbowLeft"},
        {7,  "handLeft"},       // wrist --> hand: use extrapolatePoint later to convert truely
        {8,  "hipRight"},
        {9,  "kneeRight"},
        {10, "ankleRight"},
        {11, "hipLeft"},
        {12, "kneeLeft"},
        {13, "ankleLeft"},
    };
};

#endif // SKELETON3D_H
