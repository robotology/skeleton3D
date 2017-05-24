#include <cmath>
#include <limits>
#include <sstream>
#include <cstdio>
#include <cstdarg>
#include <algorithm>
#include <set>
#include "skeleton3D.h"

// Inspired from iol2opc
bool    skeleton3D::get3DPosition(const CvPoint &point, Vector &x)
{
    x.resize(3,0.0);
    if (rpcGet3D.getOutputCount()>0)
    {
        // thanks to SFM we are here
        // safe against borders checking
        // command format: Rect tlx tly w h step
        Bottle cmd,reply;
        cmd.addString("Rect");
        cmd.addInt(point.x-3);
        cmd.addInt(point.y-3);
        cmd.addInt(7);
        cmd.addInt(7);
        cmd.addInt(2);

        mutexResourcesSFM.lock();
        rpcGet3D.write(cmd,reply);
        mutexResourcesSFM.unlock();

        int sz=reply.size();
        if ((sz>0) && ((sz%3)==0))
        {
            Vector tmp(3);
            int cnt=0;

            for (int i=0; i<sz; i+=3)
            {
                tmp[0]=reply.get(i+0).asDouble();
                tmp[1]=reply.get(i+1).asDouble();
                tmp[2]=reply.get(i+2).asDouble();

                if (norm(tmp)>0.0)
                {
                    x+=tmp;
                    cnt++;
                }
            }

            if (cnt>0)
                x/=cnt;
            else
                yWarning("[%s] get3DPosition failed",name.c_str());
        }
        else
            yError("[%s] SFM replied with wrong size",name.c_str());
    }

    return (norm(x)>0.0);
}

bool    skeleton3D::obtainBodyParts(deque<CvPoint> &partsCV)
{
    mutexResourcesSkeleton.lock();
    Bottle *allBodyParts = bodyPartsInPort.read(false);
    mutexResourcesSkeleton.unlock();
    if (allBodyParts!=NULL)
    {
        if (Bottle *bodyParts=allBodyParts->get(0).asList())
        {
            map<string,kinectWrapper::Joint> jnts;
            Vector pos(3,0.0);
            if (Bottle *part=bodyParts->find("hands").asList())
            {
                yDebug("[skeleton3D] part found hands");
                CvPoint hand1, hand2;
                hand1.x = part->get(0).asInt();
                hand1.y = part->get(1).asInt();
                hand2.x = part->get(2).asInt();
                hand2.y = part->get(3).asInt();
                partsCV.push_back(hand1);
                partsCV.push_back(hand2);

                addJoint(jnts,hand1,"handRight");
                addJoint(jnts,hand2,"handLeft");
            }
            if (Bottle *part=bodyParts->find("elbows").asList())
            {
                yDebug("[skeleton3D] part found elbows");
                CvPoint eb1, eb2;
                eb1.x = part->get(0).asInt();
                eb1.y = part->get(1).asInt();
                eb2.x = part->get(2).asInt();
                eb2.y = part->get(3).asInt();
                partsCV.push_back(eb1);
                partsCV.push_back(eb2);

                addJoint(jnts,eb1,"elbowRight");
                addJoint(jnts,eb2,"elbowLeft");
            }
            if (Bottle *part=bodyParts->find("shoulders").asList())
            {
                yDebug("[skeleton3D] part found shoulders");
                CvPoint sh1, sh2;
                sh1.x = part->get(0).asInt();
                sh1.y = part->get(1).asInt();
                sh2.x = part->get(2).asInt();
                sh2.y = part->get(3).asInt();
                partsCV.push_back(sh1);
                partsCV.push_back(sh2);

                addJoint(jnts,sh1,"shoulderRight");
                addJoint(jnts,sh2,"shoulderLeft");
            }
            if (Bottle *part=bodyParts->find("head").asList())
            {
                yDebug("[skeleton3D] part found head");
                CvPoint head;
                head.x = part->get(0).asInt();
                head.y = part->get(1).asInt();
                partsCV.push_back(head);

                addJoint(jnts,head,"head");
            }
            player.skeleton = jnts;
        }
        else
        {
            yDebug("[skeleton3D] obtainBodyParts wrong format");
            return false;
        }
    }
    else
    {
        yDebug("[skeleton3D] obtainBodyParts return empty");
        return false;
    }
    return true;
}

void    skeleton3D::addJoint(map<string, kinectWrapper::Joint> &joints,
                             const CvPoint &point, const string &partName)
{
    Vector pos(3,0.0);
    if (get3DPosition(point,pos))
    {
        kinectWrapper::Joint joint;
        joint.x = pos[0];
        joint.y = pos[1];
        joint.z = pos[2];
        joints.insert(std::pair<string,kinectWrapper::Joint>(partName,joint));
        pos.clear();
    }
}

bool    skeleton3D::configure(ResourceFinder &rf)
{
    name=rf.check("name",Value("skeleton3D")).asString().c_str();
    period=rf.check("period",Value(0.1)).asDouble();

    // Connect to /SFM/rpc to obtain 3D estimation
    rpcGet3D.open(("/"+name+"/get3d:rpc").c_str());
    std::string SFMrpc = "/SFM/rpc";
    connected3D = yarp::os::Network::connect(rpcGet3D.getName().c_str(),SFMrpc);
    if (!connected3D)
        yError("[%s] Unable to connect to SFM rpc port", name.c_str());
    else
        yInfo("[%s] Connected to SFM rpc port", name.c_str());

    // Connect to /skeleton2D/bodyParts:o to get streamed body parts
    bodyPartsInPort.open(("/"+name+"/bodyParts:i").c_str());
    std::string bodyParts_streaming = "/skeleton2D/bodyParts:o";
    if (!yarp::os::Network::connect(bodyParts_streaming, bodyPartsInPort.getName().c_str()))
        yError("[%s] Unable to connect to %s port", name.c_str(),bodyParts_streaming.c_str());
    else
        yInfo("[%s] Connected to %s port", name.c_str(), bodyParts_streaming.c_str());

    // Open the OPC Client
    partner_default_name=rf.check("partner_default_name",Value("partner")).asString().c_str();

    string opcName=rf.check("opc",Value("OPC")).asString().c_str();
    opc = new OPCClient(name);
    dSince = 0.0;
    while (!opc->connect(opcName))
    {
        yInfo()<<"Waiting connection to OPC...";
        Time::delay(1.0);
    }
    opc->checkout();

    list<shared_ptr<Entity>> entityList = opc->EntitiesCacheCopy();
    for(auto e : entityList) {
        if(e->entity_type() == ICUBCLIENT_OPC_ENTITY_AGENT && e->name() != "icub") {
            partner_default_name = e->name();
        }
    }

    partner = opc->addOrRetrieveEntity<Agent>(partner_default_name);
    partner->m_present = 0.0;
    opc->commit(partner);

//    rpcPort.open("/"+name+"/rpc");
//    attach(rpcPort);

    return true;
}

bool    skeleton3D::interruptModule()
{
    yDebug("[%s] Interupt module",name.c_str());

    rpcPort.interrupt();
    rpcGet3D.interrupt();
    bodyPartsInPort.interrupt();
    opc->interrupt();
    return true;
}

bool    skeleton3D::close()
{
    yDebug("[%s] closing module",name.c_str());

    rpcPort.close();
    rpcGet3D.close();
    bodyPartsInPort.close();
    opc->close();
    return true;
}

bool    skeleton3D::attach(RpcServer &source)
{
//    return this->yarp().attachAsServer(source);
    return true;
}

double  skeleton3D::getPeriod()
{
    return period;
}

bool    skeleton3D::updateModule()
{
    deque<CvPoint> bodyPartsCv;
    // Obtain body part from a Tensorflow-based module
    obtainBodyParts(bodyPartsCv);

    // Get the 3D pose of CvPoint of body parts

    if (bodyPartsCv.size()>=0 && connected3D)
    {
        for (int8_t i=0; i<bodyPartsCv.size(); i++)
        {
            Vector pos(3,0.0);
            get3DPosition(bodyPartsCv[i], pos);
            yInfo("[%s] 3D pose of CvPoint [%d, %d] from SFM is: %s",
                  name.c_str(), bodyPartsCv[i].x, bodyPartsCv[i].y, pos.toString(3,3).c_str());
        }
    }

    // Update OPC or conduct actions
    //check if this skeletton is really tracked
    bool reallyTracked = false;
    for(map<string,kinectWrapper::Joint>::iterator jnt = player.skeleton.begin() ; jnt != player.skeleton.end() ; jnt++)
    {
        if (jnt->second.x != 0 && jnt->second.y != 0 && jnt->second.z != 0)
        {
            reallyTracked = true;
            break;
        }
    }
    if (reallyTracked)
    {
        dSince = (clock() - dTimingLastApparition) / (double) CLOCKS_PER_SEC;
        yInfo("skeleton is tracked ==> update OPC");
        opc->checkout();
        partner = opc->addOrRetrieveEntity<Agent>(partner_default_name);
        partner->m_present = 1.0;

        // reset the timing.
        dTimingLastApparition = clock();

        for (map<string,kinectWrapper::Joint>::iterator jnt = player.skeleton.begin(); jnt != player.skeleton.end(); jnt++)
        {
            Vector pos(3,0.0);
            pos[0] = jnt->second.x;
            pos[1] = jnt->second.y;
            pos[2] = jnt->second.z;
            if (jnt->first == ICUBCLIENT_OPC_BODY_PART_TYPE_HEAD)
            {
                partner->m_ego_position = pos;
            }
            partner->m_body.m_parts[jnt->first] = pos;
        }
        opc->commit(partner);
    }

    bodyPartsCv.clear();
    return true;
}
