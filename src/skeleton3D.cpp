#include <cmath>
#include <limits>
#include <sstream>
#include <cstdio>
#include <cstdarg>
#include <algorithm>
#include <set>
#include "skeleton3D.h"


void    skeleton3D::filt(map<string,kinectWrapper::Joint> &joints, map<string,kinectWrapper::Joint> &jointsFiltered)
{
    if (init_filters)
    {
        jointsFiltered = joints;
        for(map<string,kinectWrapper::Joint>::iterator jnt = joints.begin() ;
            jnt != joints.end() ; jnt++)
        {
            string partName = jnt->first;
            Vector pos(3,0.0);
            pos[0] = jnt->second.x;
            pos[1] = jnt->second.y;
            pos[2] = jnt->second.z;
            MedianFilter filterPos(filterOrder,pos);
            filterSkeleton.insert(std::pair<string,MedianFilter>(partName,filterPos));
        }
        init_filters = false;
    }
    else
    {
        for(map<string,kinectWrapper::Joint>::iterator jnt = joints.begin() ;
            jnt != joints.end() ; jnt++)
        {
            string partName = jnt->first;
            if (!filterSkeleton.empty() && filterSkeleton.find(partName.c_str())!=filterSkeleton.end())
            {
                Vector pos(3,0.0), posFilted(3,0.0);
                kinectWrapper::Joint jntFilted;
                pos[0] = jnt->second.x;
                pos[1] = jnt->second.y;
                pos[2] = jnt->second.z;

                posFilted = filterSkeleton.at(partName.c_str()).filt(pos);
                jntFilted.x = posFilted[0];
                jntFilted.y = posFilted[1];
                jntFilted.z = posFilted[2];
                jointsFiltered.insert(std::pair<string,kinectWrapper::Joint>(partName.c_str(),jntFilted));
                yDebug("[%s] filt: apply median filter for %s",name.c_str(), partName.c_str());
            }
            else
            {
                Vector pos(3,0.0);
                pos[0] = jnt->second.x;
                pos[1] = jnt->second.y;
                pos[2] = jnt->second.z;
                MedianFilter filterPos(filterOrder,pos);
                filterSkeleton.insert(std::pair<string,MedianFilter>(partName,filterPos));
            }
        }
    }
}

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
            map<string,kinectWrapper::Joint> jntsFiltered;
            confJoints.clear();
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

                addConf(part->get(4).asDouble(),"handRight");
                addConf(part->get(5).asDouble(),"handLeft");
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

                addConf(part->get(4).asDouble(),"elbowRight");
                addConf(part->get(5).asDouble(),"elbowLeft");
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

                addConf(part->get(4).asDouble(),"shoulderRight");
                addConf(part->get(5).asDouble(),"shoulderLeft");
            }
            if (Bottle *part=bodyParts->find("head").asList())
            {
                yDebug("[skeleton3D] part found head");
                CvPoint head;
                head.x = part->get(0).asInt();
                head.y = part->get(1).asInt();
                partsCV.push_back(head);

                addJoint(jnts,head,"head");

                addConf(part->get(2).asDouble(),"head");
            }

            extrapolateHand(jnts);
            filt(jnts,jntsFiltered);    // Filt the obtain skeleton with Median Filter, tune by filterOrder. The noise is due to the SFM 3D estimation
            player.skeleton = jntsFiltered;

            ts.update();
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

void    skeleton3D::addConf(const double &conf, const string &partName)
{
    confJoints.insert(std::pair<string,double>(partName,conf));
}

void    skeleton3D::addPartToStream(Agent* a, const string &partName, Bottle &streamedObjs)
{
    Bottle part;
    part.addDouble(a->m_body.m_parts[partName.c_str()][0]); // X
    part.addDouble(a->m_body.m_parts[partName.c_str()][1]); // Y
    part.addDouble(a->m_body.m_parts[partName.c_str()][2]); // Z
    part.addDouble(part_dimension);                         // RADIUS
    if (use_part_conf)
        part.addDouble(computeValence(partName));
    else
        part.addDouble(body_valence);                           // Currently hardcoded threat. Make adaptive
    streamedObjs.addList()=part;
}

double  skeleton3D::computeValence(const string &partName)
{
    double conf = confJoints[partName.c_str()];
    return conf*2.0 - 1.0;
}

void    skeleton3D::extrapolateHand(map<string, kinectWrapper::Joint> &jnts)
{
    Vector handR(3,0.0), handL(3,0.0), elbowR(3,0.0), elbowL(3,0.0), handR_new(3,0.0), handL_new(3,0.0);
    if (!jnts.empty() && jnts.find("handRight")!=jnts.end() && jnts.find("handLeft")!=jnts.end()
            && jnts.find("elbowRight")!=jnts.end() && jnts.find("elbowLeft")!=jnts.end())
    {
        handR[0] = jnts.at("handRight").x;
        handR[1] = jnts.at("handRight").y;
        handR[2] = jnts.at("handRight").z;

        handL[0] = jnts.at("handLeft").x;
        handL[1] = jnts.at("handLeft").y;
        handL[2] = jnts.at("handLeft").z;

        elbowR[0] = jnts.at("elbowRight").x;
        elbowR[1] = jnts.at("elbowRight").y;
        elbowR[2] = jnts.at("elbowRight").z;

        elbowL[0] = jnts.at("elbowLeft").x;
        elbowL[1] = jnts.at("elbowLeft").y;
        elbowL[2] = jnts.at("elbowLeft").z;

        if (extrapolatePoint(elbowL,handL,handL_new))
        {
            jnts.at("handLeft").x = handL_new[0];
            jnts.at("handLeft").y = handL_new[1];
            jnts.at("handLeft").z = handL_new[2];
        }
        if (extrapolatePoint(elbowR,handR,handR_new))
        {
            jnts.at("handRight").x = handR_new[0];
            jnts.at("handRight").y = handR_new[1];
            jnts.at("handRight").z = handR_new[2];
        }
    }
    else
        yDebug("[%s] extrapolateHand: can't find a body part", name.c_str());
}

bool    skeleton3D::extrapolatePoint(const Vector &p1, const Vector &p2, Vector &result)
{
    double handDim = 0.05;
    if (p1.size()==3 && p2.size()==3)
    {
        Vector dir(3,0.0);
        dir = p2-p1;
        if (norm(dir)>=0.0001)
            result = p1 + dir*(norm(dir)+ handDim)/norm(dir);
        else
            result = p1 + dir*(0.0001+ handDim)/0.0001;
        yDebug("extrapolatePoint: result = %s",result.toString(3,3).c_str());
        return true;
    }
    else
    {
        result.resize(3,0.0);
        return false;
    }
}

bool    skeleton3D::streamPartsToPPS()
{
    if (partner && partner->m_present==1.0 && connectedPPS)
    {
        Bottle objects;
        addPartToStream(partner,"head",objects);
        addPartToStream(partner,"handRight",objects);
        addPartToStream(partner,"handLeft",objects);
        addPartToStream(partner,"elbowRight",objects);
        addPartToStream(partner,"elbowLeft",objects);
        addPartToStream(partner,"shoulderRight",objects);
        addPartToStream(partner,"shoulderLeft",objects);

        Bottle& output=ppsOutPort.prepare();
        output.clear();
        output.addList()=objects;
        ppsOutPort.setEnvelope(ts);
        ppsOutPort.write();
        return true;
    }
    else
        return false;
}

bool    skeleton3D::configure(ResourceFinder &rf)
{
    name=rf.check("name",Value("skeleton3D")).asString().c_str();
    period=rf.check("period",Value(0.1)).asDouble();

    body_valence = rf.check("body_valence",Value(1.0)).asDouble();      // max = 1.0, min = -1.0
    part_dimension = rf.check("part_dimension",Value(0.05)).asDouble(); // hard-coded body part dimension

    use_part_conf = rf.check("use_part_conf",Value(0)).asBool();
    if (use_part_conf)
        yInfo("[%s] Use part confidence as valence", name.c_str());
    else
        yInfo("[%s] Don't use part confidence as valence", name.c_str());

    filterOrder = rf.check("filter_order", Value(1)).asInt();

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

    // Connect to /visuoTactileWrapper/sensManager:i to stream body parts as objects to PPS
    ppsOutPort.open(("/"+name+"/visuoTactileWrapper/objects:o").c_str());
    std::string visuoTactileWrapper_inport = "/visuoTactileWrapper/sensManager:i";
    connectedPPS = yarp::os::Network::connect(ppsOutPort.getName().c_str(), visuoTactileWrapper_inport);
    if (!connectedPPS)
        yError("[%s] Unable to connect to %s port", name.c_str(),visuoTactileWrapper_inport.c_str());
    else
        yInfo("[%s] Connected to %s port", name.c_str(), visuoTactileWrapper_inport.c_str());


    dThresholdDisparition = rf.check("dThresholdDisparition",Value("3.0")).asDouble();

    // initialise timing in case of misrecognition
    dTimingLastApparition = clock();

    // Median Filter for body part positions
    init_filters = true;


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

    ts.update();

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
    ppsOutPort.interrupt();
    opc->interrupt();
    return true;
}

bool    skeleton3D::close()
{
    yDebug("[%s] closing module",name.c_str());

    rpcPort.close();
    rpcGet3D.close();
    bodyPartsInPort.close();
    ppsOutPort.close();
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
    bool tracked = false;
    tracked = obtainBodyParts(bodyPartsCv);

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
    // check if this skeletton is really tracked
    if (tracked)
    {
        bool reallyTracked = false;
        for(map<string,kinectWrapper::Joint>::iterator jnt = player.skeleton.begin() ;
            jnt != player.skeleton.end() ; jnt++)
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
    }
    else
    {
        if (dSince > dThresholdDisparition)
        {
            opc->checkout();
            partner = opc->addOrRetrieveEntity<Agent>(partner_default_name);
            partner->m_present = 0.0;
            opc->commit(partner);
        }
    }

    if(streamPartsToPPS())
        yInfo("[%s] Streamed body parts as objects to PPS",name.c_str());
    else
        yWarning("[%s] Cannot stream body parts as objects to PPS",name.c_str());

    return true;
}
