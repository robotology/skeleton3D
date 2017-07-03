/* Copyright (C) 2017 RobotCub Consortium
 * Author:  Phuong Nguyen, Alessandro Roncone
 * email:   phuong.nguyen@iit.it, alessandro.roncone@iit.it
 * Inspired from demoAvoidance of Alessandro Roncone (alessandro.roncone@iit.it)
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

#include <stdio.h>
#include <string>
#include <cctype>
#include <algorithm>
#include <map>

#include <yarp/os/all.h>
#include <yarp/dev/all.h>
#include <yarp/sig/all.h>
#include <yarp/math/Math.h>

#include <iCub/ctrl/math.h>
#include <iCub/skinDynLib/common.h>

#define PPS_AVOIDANCE_RADIUS        0.4     // [m]  0.2 (demoAvoidance) --> 0.4 to adapt with new RF
#define PPS_AVOIDANCE_VELOCITY      0.10    // [m/s]
#define PPS_AVOIDANCE_PERSISTENCE   0.3     // [s]
#define PPS_AVOIDANCE_TIMEOUT       1.0     // [s]

using namespace std;
using namespace yarp::os;
using namespace yarp::dev;
using namespace yarp::sig;
using namespace yarp::math;
using namespace iCub::ctrl;


//*************************************
class Avoidance: public RFModule,
                 public PortReader
{
protected:
    string      name;
    double      period;
    double      trajTime;

    PolyDriver  driverCartL,driverCartR;
    PolyDriver  driverJointL,driverJointR;
    int         contextL,contextR;
    Port        dataPort;
    double      motionGain;

    bool        useLeftArm;
    bool        useRightArm;

    Vector      x0_L, x0_R;     //!< origin position of left, right arms
    Vector      o0;             //!< origin orientation of left, right arms
    string      armReach;       //!< chosen arm to reach an object
    Vector      xReach;         //!< reaching position
    Vector      oReach;         //!< reaching orientation
    bool        askedReach;     //!< flag of reach command
    bool        askedReachPose; //!< flag of reach a pose command
    bool        askedHome;      //!< flag of home command

    double      valence;        //!< body_valence like skeleton3D

    bool        elbow_set;
    double      elbow_height,elbow_weight;

    RpcServer   rpcSrvr;

    Mutex       mutex;
    struct Data {
        ICartesianControl *iarm;
        Vector point, dir;
        Vector home_x, home_o;
        double mag;
        double persistence, timeout;
        Data(): point(3,0.0), dir(3,0.0),
                home_x(3,0.0), home_o(4,0.0),
                mag(0.0),
                persistence(0.0), timeout(-1.0) { }
    };
    map<string,Data> data;

    //********************************************
    bool read(ConnectionReader &connection)
    {
        Bottle in;
        in.read(connection);

        if (in.size()>=1)
        {
            Bottle input;
            input=*(in.get(0).asList());

            if (input.size()>=7)
            {
                yDebug("[%s] got command (%s)",name.c_str(),input.toString().c_str());
                string arm=iCub::skinDynLib::SkinPart_s[input.get(0).asInt()];

                if (arm == "r_hand" || arm == "r_forearm")
                {
                    arm = "right";
                }
                else if (arm == "l_hand" || arm == "l_forearm")
                {
                    arm = "left";
                }

                transform(arm.begin(),arm.end(),arm.begin(),::tolower);
                mutex.lock();
                map<string,Data>::iterator it=data.find(arm);
                if (it!=data.end())
                {
                    Data &d=it->second;
                    d.point[0]=input.get(7).asDouble();
                    d.point[1]=input.get(8).asDouble();
                    d.point[2]=input.get(9).asDouble();
                    d.dir[0]=input.get(10).asDouble();
                    d.dir[1]=input.get(11).asDouble();
                    d.dir[2]=input.get(12).asDouble();
                    d.mag = input.get(13).asDouble();
                    d.persistence=PPS_AVOIDANCE_PERSISTENCE;
                    d.timeout=PPS_AVOIDANCE_TIMEOUT;
                }
                mutex.unlock();
            }
        }

        return true;
    }

    //********************************************
    void manageArm(Data &d)
    {
        if (d.persistence>0.0)
        {
            Vector x,o;
            d.iarm->getPose(x,o);
            if (norm(x-d.home_x)>d.mag*PPS_AVOIDANCE_RADIUS)
                d.iarm->stopControl();
            else
                d.iarm->setTaskVelocities((motionGain*PPS_AVOIDANCE_VELOCITY/norm(d.dir))*d.dir,Vector(4,0.0));

            d.persistence=std::max(d.persistence-getPeriod(),0.0);
            if (d.persistence==0.0)
                d.iarm->stopControl();
        }
        else if (d.timeout>0.0)
        {
            d.timeout=std::max(d.timeout-getPeriod(),0.0);
        }
        else if (d.timeout==0.0)
        {
            d.iarm->goToPose(d.home_x,d.home_o);
            d.timeout=-1.0;
        }
    }

    void changeElbowHeight(yarp::dev::ICartesianControl *iCartCtrl)
    {
        if (elbow_set)
        {
            Bottle tweakOptions;
            Bottle &optTask2=tweakOptions.addList();
            optTask2.addString("task_2");
            Bottle &plTask2=optTask2.addList();
            plTask2.addInt(6);
            Bottle &posPart=plTask2.addList();
            posPart.addDouble(0.0);
            posPart.addDouble(0.0);
            posPart.addDouble(elbow_height);
            Bottle &weightsPart=plTask2.addList();
            weightsPart.addDouble(0.0);
            weightsPart.addDouble(0.0);
            weightsPart.addDouble(elbow_weight);
            iCartCtrl->tweakSet(tweakOptions);
        }
    }

public:
    bool respond(const Bottle &command, Bottle &reply)
    {
        int ack =Vocab::encode("ack");
        int nack=Vocab::encode("nack");

        if (command.size()>0)
        {
            if (command.get(0).asString() == "get")
            {
                if (command.get(1).asString() == "motionGain")
                {
                    reply.addVocab(ack);
                    reply.addDouble(motionGain);
                }
                if (command.get(1).asString() == "body_valence")
                {
                    reply.addVocab(ack);
                    reply.addDouble(valence);
                }
                else if (command.get(1).asString() == "home")
                {
                    reply.addVocab(ack);
                    reply.addString("left: ");
                    reply.addString(data["left"].home_x.toString(3,3).c_str());
                    reply.addString("right: ");
                    reply.addString(data["right"].home_x.toString(3,3).c_str());
                }
                else
                {
                    reply.addVocab(nack);
                }
            }
            else if (command.get(0).asString() == "set")
            {
                if (command.get(1).asString() == "motionGain")
                {
                    reply.addVocab(ack);
                    motionGain = command.get(2).asDouble();
                    reply.addDouble(motionGain);
                }
                else if (command.get(1).asString() == "body_valence")
                {
                    reply.addVocab(ack);
                    valence = command.get(2).asDouble();
                    reply.addDouble(valence);
                }
                else if (command.get(1).asString() == "behavior")
                {
                    if (command.get(2).asString() == "avoidance")
                    {
                        reply.addVocab(ack);
                        motionGain = -1.0;
                        reply.addDouble(motionGain);
                    }
                    else if (command.get(2).asString() == "catching")
                    {
                        reply.addVocab(ack);
                        motionGain = 1.0;
                        reply.addDouble(motionGain);
                    }
                    else
                    {
                        reply.addVocab(nack);
                    }
                }
                else
                {
                    reply.addVocab(nack);
                }
            }
            else if (command.get(0).asString() == "reach")
            {
                if (command.size()==5)
                {
                    armReach = command.get(1).asString();
                    if (armReach == "left" || armReach == "right")
                    {
                        for (uint8_t i=0; i<xReach.size(); i++)
                            xReach[i] = command.get(i+2).asDouble();
                        data[armReach.c_str()].home_x = xReach;
//                        data[armReach.c_str()].persistence=PPS_AVOIDANCE_PERSISTENCE;
//                        data[armReach.c_str()].timeout=PPS_AVOIDANCE_TIMEOUT;
                        askedReach = true;
                        yDebug("[%s] REACH (%s) by %s arm",name.c_str(), xReach.toString(3,3).c_str(), armReach.c_str());
                        reply.addVocab(ack);
                    }
                    else
                        reply.addVocab(nack);
                }
                else
                    reply.addVocab(nack);
            }
            else if (command.get(0).asString() == "reach_pose")
            {
                if (command.size()==9)
                {
                    armReach = command.get(1).asString();
                    if (armReach == "left" || armReach == "right")
                    {
                        for (uint8_t i=0; i<xReach.size(); i++)
                            xReach[i] = command.get(i+2).asDouble();
                        for (uint8_t i=0; i<oReach.size(); i++)
                            oReach[i] = command.get(i+5).asDouble();
                        oReach[3] = oReach[3]*M_PI/180.0;
                        data[armReach.c_str()].home_x = xReach;
                        data[armReach.c_str()].home_o = oReach;
                        askedReachPose = true;
                        yDebug("[%s] REACH A POSE (%s) (%s) by %s arm",name.c_str(), xReach.toString(3,3).c_str(), oReach.toString(3,3).c_str(), armReach.c_str());
                        reply.addVocab(ack);
                    }
                    else
                        reply.addVocab(nack);
                }
                else
                    reply.addVocab(nack);
            }
            else if (command.get(0).asString() == "home")
            {
                data["left"].home_x = x0_L;
                data["right"].home_x = x0_R;
                data["left"].home_o = o0;
                data["right"].home_o = o0;
                askedHome = true;
                reply.addVocab(ack);
            }
            else if (command.get(0).asString() == "help")
            {
                reply.addVocab(Vocab::encode("many"));
                reply.addString("Available commands are:");
                reply.addString("[reach] <arm_string> x y z - "
                                "reach a position of (x,y,z) by left/right arm, <arm_string> = left/right");
                reply.addString("[set] motionGain <gain_double>");
                reply.addString("[get] motionGain - Return the setting value of motionGain");
                reply.addString("[get] home - Return the setting values of home position");
                reply.addString("help - produces this help.");
                reply.addVocab(ack);
            }
            else
                reply.addVocab(nack);
        }

        return true;
    }

    //********************************************
    bool configure(ResourceFinder &rf)
    {
        name    =rf.check("name",Value("yetAnotherAvoidance")).asString().c_str();
        period  =rf.check("period",Value(0.05)).asDouble();
        trajTime=rf.check("trajTime",Value(0.9)).asDouble();

        valence=rf.check("body_valence",Value(1.0)).asDouble();

        elbow_set=rf.check("elbow_set",Value(1)).asBool();
        if (elbow_set)
        {
            if (Bottle *pB=rf.find("elbow_set").asList())
            {
                elbow_height=pB->get(0).asDouble();
                elbow_weight=pB->get(1).asDouble();
            }
            else
            {
                elbow_height=0.4;
                elbow_weight=30.0;
            }
        }

        if (rf.check("noLeftArm") && rf.check("noRightArm"))
        {
            yError("[%s] no arm has been selected. Closing.",name.c_str());
            return false;
        }

        useLeftArm  = false;
        useRightArm = false;

        string robot=rf.check("robot",Value("icub")).asString().c_str();
        motionGain = -0.5;
        if (rf.check("catching"))
        {
            motionGain = 0.5;
        }
        if (motionGain > 0.0)
        {
            yWarning("[%s] motionGain set to catching",name.c_str());
        }

        bool autoConnect=rf.check("autoConnect",Value(0)).asBool();
        if (autoConnect)
        {
            yWarning("[%s] Autoconnect mode set to ON",name.c_str());
        }

        bool stiff=rf.check("stiff");
        if (stiff)
        {
            yInfo("[%s] Stiff Mode enabled.",name.c_str());
        }

        Matrix R(4,4);
        R(0,0)=-1.0; R(2,1)=-1.0; R(1,2)=-1.0; R(3,3)=1.0;

        x0_L.resize(3,0.0);
        x0_L[0]=-0.30;
        x0_L[1]=-0.20;
        x0_L[2]=+0.05;

        x0_R.resize(3,0.0);
        x0_R[0]=-0.30;
        x0_R[1]=+0.20;
        x0_R[2]=+0.05;

        o0 = dcm2axis(R);

        xReach.resize(3,0.0);
        oReach.resize(4,0.0);
        askedReach = false;
        askedReachPose = false;
        askedHome  = false;

        if (!rf.check("noLeftArm"))
        {
            useLeftArm=true;

            data["left"]=Data();
            data["left"].home_x = x0_L;
            data["left"].home_o = o0;

            Property optionCartL;
            optionCartL.put("device","cartesiancontrollerclient");
            optionCartL.put("remote","/"+robot+"/cartesianController/left_arm");
            optionCartL.put("local",("/"+name+"/cart/left_arm").c_str());
            if (!driverCartL.open(optionCartL))
            {
                close();
                return false;
            }

            Property optionJointL;
            optionJointL.put("device","remote_controlboard");
            optionJointL.put("remote","/"+robot+"/left_arm");
            optionJointL.put("local",("/"+name+"/joint/left_arm").c_str());
            if (!driverJointL.open(optionJointL))
            {
                close();
                return false;
            }

            driverCartL.view(data["left"].iarm);
            data["left"].iarm->storeContext(&contextL);

            Vector dof;
            data["left"].iarm->getDOF(dof);
            dof=0.0; dof[3]=dof[4]=dof[5]=dof[6]=1.0;
            data["left"].iarm->setDOF(dof,dof);
            data["left"].iarm->setTrajTime(trajTime);

            data["left"].iarm->goToPoseSync(data["left"].home_x,data["left"].home_o);
            data["left"].iarm->waitMotionDone();

            IInteractionMode  *imode; driverJointL.view(imode);
            IImpedanceControl *iimp;  driverJointL.view(iimp);

            if (!stiff)
            {
                imode->setInteractionMode(0,VOCAB_IM_COMPLIANT); iimp->setImpedance(0,0.4,0.03);
                imode->setInteractionMode(1,VOCAB_IM_COMPLIANT); iimp->setImpedance(1,0.4,0.03);
                imode->setInteractionMode(2,VOCAB_IM_COMPLIANT); iimp->setImpedance(2,0.4,0.03);
                imode->setInteractionMode(3,VOCAB_IM_COMPLIANT); iimp->setImpedance(3,0.2,0.01);
                imode->setInteractionMode(4,VOCAB_IM_COMPLIANT); iimp->setImpedance(4,0.2,0.0);
            }
        }

        if (!rf.check("noRightArm"))
        {
            useRightArm = true;

            data["right"]=Data();
            data["right"].home_x = x0_R;
            data["right"].home_o = o0;

            Property optionCartR;
            optionCartR.put("device","cartesiancontrollerclient");
            optionCartR.put("remote","/"+robot+"/cartesianController/right_arm");
            optionCartR.put("local",("/"+name+"/cart/right_arm").c_str());
            if (!driverCartR.open(optionCartR))
            {
                close();
                return false;
            }

            Property optionJointR;
            optionJointR.put("device","remote_controlboard");
            optionJointR.put("remote","/"+robot+"/right_arm");
            optionJointR.put("local",("/"+name+"/joint/right_arm").c_str());
            if (!driverJointR.open(optionJointR))
            {
                close();
                return false;
            }

            driverCartR.view(data["right"].iarm);
            data["right"].iarm->storeContext(&contextR);

            Vector dof;
            data["right"].iarm->getDOF(dof);
            dof=0.0; dof[3]=dof[4]=dof[5]=dof[6]=1.0;
            data["right"].iarm->setDOF(dof,dof);
            data["right"].iarm->setTrajTime(trajTime);

            data["right"].iarm->goToPoseSync(data["right"].home_x,data["right"].home_o);
            data["right"].iarm->waitMotionDone();


            IInteractionMode  *imode; driverJointR.view(imode);
            IImpedanceControl *iimp;  driverJointR.view(iimp);

            if (!stiff)
            {
                imode->setInteractionMode(0,VOCAB_IM_COMPLIANT); iimp->setImpedance(0,0.4,0.03);
                imode->setInteractionMode(1,VOCAB_IM_COMPLIANT); iimp->setImpedance(1,0.4,0.03);
                imode->setInteractionMode(2,VOCAB_IM_COMPLIANT); iimp->setImpedance(2,0.4,0.03);
                imode->setInteractionMode(3,VOCAB_IM_COMPLIANT); iimp->setImpedance(3,0.2,0.01);
                imode->setInteractionMode(4,VOCAB_IM_COMPLIANT); iimp->setImpedance(4,0.2,0.0);
            }
        }

        dataPort.open(("/"+name+"/data:i").c_str());
        dataPort.setReader(*this);

        if (autoConnect)
        {
            Network::connect("/visuoTactileRF/pps_events_aggreg:o",("/"+name+"/data:i").c_str());
        }

        rpcSrvr.open(("/"+name+"/rpc:i").c_str());
        attach(rpcSrvr);
        return true;
    }

    //********************************************
    bool updateModule()
    {
        mutex.lock();
        if (askedReach)
        {
            yDebug("[%s] goToPose (%s) by %s arm",name.c_str(), data[armReach.c_str()].home_x.toString(3,3).c_str(), armReach.c_str());
            changeElbowHeight(data[armReach.c_str()].iarm);
            data[armReach.c_str()].iarm->goToPose(data[armReach.c_str()].home_x,data[armReach.c_str()].home_o);
            askedReach = false;
        }
        else if (askedReachPose)
        {
            yDebug("[%s] goToPose (%s) (%s) by %s arm",name.c_str(), data[armReach.c_str()].home_x.toString(3,3).c_str(), data[armReach.c_str()].home_o.toString(3,3).c_str(),  armReach.c_str());
            changeElbowHeight(data[armReach.c_str()].iarm);
            data[armReach.c_str()].iarm->goToPose(data[armReach.c_str()].home_x,data[armReach.c_str()].home_o);
            askedReachPose = false;
        }
        else if (askedHome)
        {
            yDebug("[%s] homing", name.c_str());
            changeElbowHeight(data["left"].iarm);
            changeElbowHeight(data["right"].iarm);
            data["left"].iarm->goToPose(data["left"].home_x,data["left"].home_o);
            data["right"].iarm->goToPose(data["right"].home_x,data["right"].home_o);
            askedHome = false;
        }

        if (useLeftArm)
        {
            manageArm(data["left"]);
        }

        if (useRightArm)
        {
            manageArm(data["right"]);
        }
        mutex.unlock();
        return true;
    }

    //********************************************
    double getPeriod()
    {
        return period;
    }

    //********************************************
    bool close()
    {
        yInfo("[%s] Closing module..",name.c_str());

        dataPort.close();

        if (useLeftArm)
        {
            if (driverCartL.isValid())
            {
                data["left"].iarm->stopControl();
                data["left"].iarm->restoreContext(contextL);
                driverCartL.close();
            }

            if (driverJointL.isValid())
            {
                IInteractionMode *imode;
                driverJointL.view(imode);
                for (int j=0; j<5; j++)
                    imode->setInteractionMode(j,VOCAB_IM_STIFF);

                driverJointL.close();
            }
        }

        if (useRightArm)
        {
            if (driverCartR.isValid())
            {
                data["right"].iarm->stopControl();
                data["right"].iarm->restoreContext(contextR);
                driverCartR.close();
            }

            if (driverJointR.isValid())
            {
                IInteractionMode *imode;
                driverJointR.view(imode);
                for (int j=0; j<5; j++)
                    imode->setInteractionMode(j,VOCAB_IM_STIFF);

                driverJointR.close();
            }
        }

        return true;
    }
};


//********************************************
int main(int argc, char * argv[])
{
    Network yarp;

    ResourceFinder moduleRF;
    moduleRF.setVerbose(false);
    moduleRF.setDefaultContext("skeleton3D");
    moduleRF.setDefaultConfigFile("yetAnotherAvoidance.ini");
    moduleRF.configure(argc,argv);

    if (moduleRF.check("help"))
    {
        yInfo(" ");
        yInfo("Options:");
        yInfo("   --context     path:  where to find the called resource (default skeleton3D).");
        yInfo("   --from        from:  the name of the .ini file (default yetAnotherAvoidance.ini).");
        yInfo("   --name        name:  the name of the module (default yetAnotherAvoidance).");
        yInfo("   --autoConnect flag:  if to auto connect the ports or not. Default no.");
        yInfo("   --catching    flag:  if enabled, the robot will catch the target instead of avoiding it.");
        yInfo("   --stiff       flag:  if enabled, the robot will perform movements in stiff mode instead of compliant.");
        yInfo("   --noLeftArm   flag:  if enabled, the robot will perform movements without the left arm.");
        yInfo("   --noRightArm  flag:  if enabled, the robot will perform movements without the rihgt arm.");
        yInfo(" ");
        return 0;
    }

    if (!yarp.checkNetwork())
    {
        yError("No Network!!!");
        return -1;
    }

    Avoidance module;
    return module.runModule(moduleRF);
}


