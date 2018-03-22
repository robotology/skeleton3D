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
                yDebug("[%s] filt: pose of %s is %s",name.c_str(), partName.c_str(), posFilted.toString(3,3).c_str());
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

void    skeleton3D::filtAngles(const Vector &angles, Vector &filteredAngles)
{
    if (init_filters_angle)
    {
        filterAngles = new MedianFilter(filterOrder, angles);
        init_filters_angle = false;
        filteredAngles = filterAngles->output();
    }
    else
    {
        filteredAngles = filterAngles->filt(angles);
        yDebug("[%s] filtAngles: apply median filter for angle",name.c_str());
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
        cmd.addInt(point.x-1);
        cmd.addInt(point.y-1);
        cmd.addInt(3);
        cmd.addInt(3);
        cmd.addInt(1);

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

//                if (norm(tmp)>0.0 & tmp[0]>0.0 & tmp[0]<=5.0)
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
    Bottle *allPeople = bodyPartsInPort.read(false);
    mutexResourcesSkeleton.unlock();
    if (allPeople!=NULL)
    {
//        yInfo("allBodyParts %s",allBodyParts->toString().c_str());
//        yInfo("allBodyParts size %d",allBodyParts->size());
        for (int person=0; person<allPeople->size(); person++)
        {
            if (Bottle *allBodyParts=allPeople->get(person).asList())
            {
//                yInfo("bodyParts %s",bodyParts->toString().c_str());
                map<string,kinectWrapper::Joint> jnts;
                map<string,kinectWrapper::Joint> jntsFiltered;
                confJoints.clear();
                if (Bottle *bodyParts=allBodyParts->get(0).asList())
                {

                    for (int partId=0; partId<bodyParts->size();partId++)
                    {
                        if (partId<mapPartsKinect.size())
                        {
                            if (Bottle *part=bodyParts->get(partId).asList())
                            {
//                                yInfo("part %s",part->toString().c_str());
                                string partName = part->get(0).asString();
                                yDebug("[%s] found part as %s",name.c_str(),partName.c_str());
                                CvPoint partCv;
                                double partConf = part->get(3).asDouble();
                                partCv.x = (int)part->get(1).asDouble();
                                partCv.y = (int)part->get(2).asDouble();

                                //TODO make this better
                                if (hand_with_tool=="right" && partName =="Rwrist")
                                    handCV = partCv;
                                else if (hand_with_tool=="left" && partName =="Lwrist")
                                    handCV = partCv;

                                if (partConf>=partConfThres)// && partName =="Lshoulder")
                                {
                                    partsCV.push_back(partCv);
                                    addJoint(jnts,partCv,mapPartsKinect[partId].c_str());
                                    addConf(part->get(3).asDouble(),mapPartsKinect[partId].c_str());
                                }
//                                else
//                                    yDebug("[%s] ignore part with confidence lower than 0.0001%%",name.c_str());
                            }
                        }
                        else
                            yDebug("[%s] obtainBodyParts: don't deal with face parts!",name.c_str());
                    }
                }

                // Check if a new joint==0.0 in jnts, use the old value from player.skeleton
                if (jnts.size()>=8)
                    for (map<string,kinectWrapper::Joint>::iterator jnt = player.skeleton.begin(); jnt != player.skeleton.end(); jnt++)
                    {
                        if (jnts.find(jnt->first)==jnts.end())    // No specific joint in jnts (get3DPosition return empty)
                        {
                            kinectWrapper::Joint joint = jnt->second;
                            jnts.insert(std::pair<string,kinectWrapper::Joint>(jnt->first,joint));
                        }
                    }

//                computeSpine(jnts);
                extrapolateHand(jnts);

                if (use_part_filter)
                {
                    filt(jnts,jntsFiltered);    // Filt the obtain skeleton with Median Filter, tune by filterOrder. The noise is due to the SFM 3D estimation
                    player.skeleton = jntsFiltered;
                }
                else
                    player.skeleton = jnts;

                ts.update();
            }
            else
            {
                yDebug("[%s] obtainBodyParts wrong format",name.c_str());
                return false;
            }
        }
    }
    else if (use_fake_hand)
    {
        yDebug("[%s] obtainBodyParts: create a fake body %s",name.c_str(),
               fakeHandPos.toString(3,3).c_str());
        map<string, kinectWrapper::Joint> joints;
        kinectWrapper::Joint joint;
        joint.x = fakeHandPos[0];
        joint.y = fakeHandPos[1];
        joint.z = fakeHandPos[2];
        joints.insert(std::pair<string,kinectWrapper::Joint>("handRight",joint));
        addConf(0.9,"handRight");

        Vector posR(fakeHandPos);
        posR[0] += -0.25;
        addJointAndConf(joints,posR,"elbowRight");
        posR[0] += -0.05;                       posR[2] += 0.15;
        addJointAndConf(joints,posR,"shoulderRight");
                                                posR[2] += -0.35;
        addJointAndConf(joints,posR,"hipRight");
        posR[0] += +0.3;    posR[1] += -0.15;   posR[2] += -0.1;
        addJointAndConf(joints,posR,"kneeRight");
                                                posR[2] += -0.35;
        addJointAndConf(joints,posR,"ankleRight");

        Vector posL(fakeHandPos);
        posL[0] += -0.25;   posL[1] += 0.45;
        addJointAndConf(joints,posL,"handLeft");
                            posL[1] += -0.25;
        addJointAndConf(joints,posL,"elbowLeft");
        posL[0] += -0.05;                       posL[2] += 0.15;
        addJointAndConf(joints,posL,"shoulderLeft");
        Vector posC(posL);
                                                posL[2] += -0.35;
        addJointAndConf(joints,posL,"hipLeft");
        posL[0] += +0.3;    posL[1] += +0.15;   posL[2] += -0.1;
        addJointAndConf(joints,posL,"kneeLeft");
                                                posL[2] += -0.35;
        addJointAndConf(joints,posL,"ankleLeft");

                            posC[1] += -0.10;
        addJointAndConf(joints,posC,"shoulderCenter");
                                                posC[2] += 0.1;
        addJointAndConf(joints,posC,"head");

        computeSpine(joints);

        player.skeleton = joints;

        ts.update();
    }
    else
    {
//        yDebug("[%s] obtainBodyParts return empty",name.c_str());
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
        joint.u = (int)point.x;
        joint.v = (int)point.y;
//        yInfo("joint 2D: %d, %d",joint.u, joint.v);
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
    part.addDouble(part_dimension/2.0);                     // RADIUS
    if (use_part_conf)
        part.addDouble(computeValence(partName));
    else
    {
        if (partName == "handRight" | partName == "handLeft")
            part.addDouble(hand_valence);
        else
            part.addDouble(body_valence);                           // Currently hardcoded threat. Make adaptive
    }

    streamedObjs.addList()=part;
}

double  skeleton3D::computeValence(const string &partName)
{
    double conf = confJoints[partName.c_str()];
//    return conf*2.0 - 1.0;
    double threat = body_valence + body_valence*(1-conf) - 1.0;
    yDebug("[%s] %s\t body_valence: %3.3f\t conf: %3.3f\t threat: %3.3f",name.c_str(), partName.c_str(), body_valence, conf, threat);
    return threat;
}

void    skeleton3D::computeSpine(map<string, kinectWrapper::Joint> &jnts)
{
    Vector hipR(3,0.0), hipL(3,0.0), head(3,0.0), spine(3,0.0);
    if (!jnts.empty() && jnts.find("hipRight")!=jnts.end() && jnts.find("hipLeft")!=jnts.end()
            && jnts.find("head")!=jnts.end())
    {
        hipR[0] = jnts.at("hipRight").x;
        hipR[1] = jnts.at("hipRight").y;
        hipR[2] = jnts.at("hipRight").z;

        hipL[0] = jnts.at("hipLeft").x;
        hipL[1] = jnts.at("hipLeft").y;
        hipL[2] = jnts.at("hipLeft").z;

        head[0] = jnts.at("shoulderCenter").x;
        head[1] = jnts.at("shoulderCenter").y;
        head[2] = jnts.at("shoulderCenter").z;

        spine = (head + (hipR+hipL)/2.0)/2.0;
        kinectWrapper::Joint joint;
        joint.x = spine[0];
        joint.y = spine[1];
        joint.z = spine[2];
        jnts.insert(std::pair<string,kinectWrapper::Joint>("spine",joint));

        double conf_hipR, conf_hipL, conf_head, conf_spine;
        conf_hipR = confJoints.at("hipRight");
        conf_hipL = confJoints.at("hipLeft");
        conf_head = confJoints.at("shoulderCenter");
        conf_spine = (conf_head + (conf_hipR + conf_hipL)/2.0)/2.0;

        addConf(conf_spine,"spine");

    }
    else
        yDebug("[%s] computeSpine: can't find a body part", name.c_str());
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
        double segL = norm(dir);
        if (segL>=0.0001)
        {
            if (segL>=segLMax || segL<=segLMin)
                segL = 0.265;
            result = p1 + dir*(segL+ handDim)/norm(dir);
        }
        else
            result = p1 + dir*(0.0001+ handDim)/0.0001;
        yDebug("extrapolatePoint: result = %s",result.toString(3,3).c_str());
        yDebug("forearm = %0.3f, forearm+hand = %0.3f", segL, norm(result-p1));
        return true;
    }
    else
    {
        result.resize(3,0.0);
        return false;
    }
}

bool    skeleton3D::constraintLink(const Vector &p1, const Vector &p2, Vector &result,
                                   const double &segLMin, const double &segLMax, const double &segLNormal)
{
    if (p1.size()==3 && p2.size()==3)
    {
        Vector dir(3,0.0);
        dir = p2-p1;
        double segL = norm(dir);
        if (segL>=0.0001)
        {
            if (segL>=segLMax || segL<=segLMin)
                segL = 0.265;
            result = p1 + dir*(segL)/norm(dir);
        }
        else
            result = p1 + dir*(0.0001)/0.0001;
        yDebug("constraintLink: result = %s",result.toString(3,3).c_str());
        return true;
    }
    else
    {
        result.resize(3,0.0);
        return false;
    }
}

void    skeleton3D::constraintBodyLinks(map<string, kinectWrapper::Joint> &jnts)
{
    if (!jnts.empty())
    {
        constraintOneBodyLink(jnts, "shoulderCenter", "shoulderLeft", 0.15, 0.3, 0.25);
        constraintOneBodyLink(jnts, "shoulderLeft", "elbowLeft", 0.2, 0.35, 0.3);
    }
    else
        yDebug("[%s] constraintBodyParts: no any body part", name.c_str());
}

void    skeleton3D::constraintOneBodyLink(map<string, kinectWrapper::Joint> &jnts,
                                          const string &partName1, const string &partName2,
                                          const double &segLMin, const double &segLMax, const double &segLNormal)
{
    if (jnts.find(partName1.c_str())!=jnts.end() && jnts.find(partName2.c_str())!=jnts.end())
    {
        Vector p1(3,0.0), p2(3,0.0), p2_new(3,0.0);
        p1 = joint2Vector(jnts.at(partName1.c_str()));
        p2 = joint2Vector(jnts.at(partName2.c_str()));
        if (constraintLink(p1, p2, p2_new, segLMin, segLMax, segLNormal))
        {
//            jnts.at(partName2.c_str()).x = p2_new[0];
            assignJointByVec(jnts.at(partName2.c_str()), p2_new);

        }

    }
}

bool    skeleton3D::getPartPose(Agent* a, const string &partName, Vector &pose)
{
    if (pose.size()==3 && a->m_body.m_parts.find(partName.c_str())!=a->m_body.m_parts.end())
    {
        for (int i=0; i<pose.size(); i++)
            pose[i]=a->m_body.m_parts[partName.c_str()][i];
        return true;
    }
    else
        return false;
}

void    skeleton3D::addPartToStream(const Vector &pose, const string &partName, Bottle &streamedObjs)
{
    Bottle part;
    for (int i=0; i<pose.size(); i++)
        part.addDouble(pose[i]);
    part.addDouble(part_dimension/2.0);                         // RADIUS
    if (use_part_conf)
        part.addDouble(computeValence(partName));
    else
    {
        if (partName == "handRight" | partName == "handLeft")
            part.addDouble(hand_valence);
        else
            part.addDouble(body_valence);                           // Currently hardcoded threat. Make adaptive
    }
    streamedObjs.addList()=part;
}

void    skeleton3D::addMidArmsToStream(Bottle &streamedObjs)
{
    Vector midR(3,0.0), midL(3,0.0), handR(3,0.0), handL(3,0.0), elbowR(3,0.0), elbowL(3,0.0);
    getPartPose(partner,"handRight",handR);
    getPartPose(partner,"handLeft",handL);
    getPartPose(partner,"elbowRight",elbowR);
    getPartPose(partner,"elbowLeft",elbowL);

    midR = (handR+elbowR)/2.0;
    midL = (handL+elbowL)/2.0;

    addPartToStream(midR, "elbowRight", streamedObjs);
    addPartToStream(midL, "elbowLeft",streamedObjs);
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
        addPartToStream(partner,"spine",objects);

        if (use_mid_arms)
            addMidArmsToStream(objects);

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

void    skeleton3D::initShowBodySegGui(const string &segmentName, const string &color)
{
    cmdGui.clear();

    cmdGui.addString("trajectory");
    cmdGui.addString(segmentName.c_str());    // trajectory identifier
    cmdGui.addString("");               // trajectory name
    cmdGui.addInt(512);                 // max samples in circular queue
    cmdGui.addDouble(1200.0);             // lifetime of samples
    if (color =="red")             // color
    {
        cmdGui.addInt(255);cmdGui.addInt(0);cmdGui.addInt(0); //red
    }
    else if (color =="green")
    {
        cmdGui.addInt(0);cmdGui.addInt(255);cmdGui.addInt(0); //green
    }
    else if (color =="blue")
    {
        cmdGui.addInt(0);cmdGui.addInt(0);cmdGui.addInt(255); //blue
    }
    else if (color =="purple")
    {
        cmdGui.addInt(255);cmdGui.addInt(0);cmdGui.addInt(255); //purple
    }
    else if (color =="yellow")
    {
        cmdGui.addInt(255);cmdGui.addInt(255);cmdGui.addInt(0); //yellow
    }
    cmdGui.addDouble(1.0);             // alpha [0,1]
    cmdGui.addDouble(5.0);             // line width

    portToGui.write(cmdGui);
}

void    skeleton3D::updateBodySegGui(const vector<Vector> &segment, const string &segmentName)
{
    if (segment.size()>0)
    {
        for (int i=0; i<segment.size(); i++)
        {
            cmdGui.clear();

            cmdGui.addString("addpoint");
            cmdGui.addString(segmentName.c_str());                    // trajectory identifier
            cmdGui.addDouble(1000.0*segment[i][0]);      // posX [mm]
            cmdGui.addDouble(1000.0*segment[i][1]);      // posY [mm]
            cmdGui.addDouble(1000.0*segment[i][2]);      // posZ [mm]

            portToGui.write(cmdGui);
        }
    }
}

void    skeleton3D::deleteBodySegGui(const string &segmentName)
{
    cmdGui.clear();
    cmdGui.addString("delete");
    cmdGui.addString(segmentName.c_str());
    portToGui.write(cmdGui);
}

bool    skeleton3D::drawBodyGui(Agent *a)
{
    deleteBodySegGui("upper");
    deleteBodySegGui("spine");
    if (draw_lower)
        deleteBodySegGui("lower");

    if (a && a->m_present==1.0)
    {
        initShowBodySegGui("upper","blue");
        initShowBodySegGui("spine","red");
        if (draw_lower)
            initShowBodySegGui("lower","purple");
        Vector partPos(3,0.0), hipL(3,0.0), hipR(3,0.0);
        vector<Vector> segmentUpper, segmentSpine, segmentLower;
        for (int i=0; i<7; i++)
        {
//            yDebug("[%s] part name %d: %s",name.c_str(),i,mapPartsGui[i].c_str());
            if (getPartPose(a,mapPartsGui[i].c_str(),partPos))
                segmentUpper.push_back(partPos);
        }
        updateBodySegGui(segmentUpper,"upper");

        if (getPartPose(a,mapPartsGui[13],partPos))         segmentSpine.push_back(partPos);    // head
        if (getPartPose(a,mapPartsGui[3],partPos))          segmentSpine.push_back(partPos);    // shoulderCenter

        if (getPartPose(a,mapPartsGui[9],hipL) && getPartPose(a,mapPartsGui[10],hipR))
        {
            partPos = (hipL+hipR)/2.0;                      segmentSpine.push_back(partPos);    // hipCenter
        }
        updateBodySegGui(segmentSpine,"spine");

        if (draw_lower)
        {
            for (int i=7; i<13; i++)
            {
//                yDebug("[%s] part name %d: %s",name.c_str(),i,mapPartsGui[i].c_str());
                if (getPartPose(a,mapPartsGui[i].c_str(),partPos))
                    segmentLower.push_back(partPos);
            }
            updateBodySegGui(segmentLower,"lower");
        }

        return true;
    }
    else
        return false;
}

bool    skeleton3D::assignJointByVec(kinectWrapper::Joint &jnt, const Vector &pos)
{
    if (pos.size()==3)
    {
        jnt.x = pos[0];
        jnt.y = pos[1];
        jnt.z = pos[2];
        return true;
    }
    else
    {
        return false;
        yWarning("[%s] Joint is assigned with wrong size vector",name.c_str());
    }
}

void    skeleton3D::addJointAndConf(map<string,kinectWrapper::Joint> &joints,
                                    const Vector &pos, const string &partName)
{
    kinectWrapper::Joint joint;
    assignJointByVec(joint, pos);
    joints.insert(std::pair<string,kinectWrapper::Joint>(partName,joint));
    addConf(0.9,partName);
}


bool    skeleton3D::configure(ResourceFinder &rf)
{
    name=rf.check("name",Value("skeleton3D")).asString().c_str();
    std::string SFMrpc = rf.check("depth_rpc",Value("/SFM/rpc")).asString().c_str();
    yDebug("SFMrpc is %s", SFMrpc.c_str());
    period=rf.check("period",Value(0.0)).asDouble();    // as default, update module as soon as receiving new parts from skeleton2D

    radius=rf.check("radius",Value(10.0)).asDouble();
    hand_with_tool=rf.check("hand_with_tool",Value("right")).asString().c_str();

    body_valence = rf.check("body_valence",Value(1.0)).asDouble();      // max = 1.0, min = -1.0
    hand_valence = body_valence;
    part_dimension = rf.check("part_dimension",Value(0.07)).asDouble(); // hard-coded body part dimension

    use_part_conf = rf.check("use_part_conf",Value(1)).asBool();
    partConfThres = rf.check("part_conf",Value(0.1)).asDouble();
    yInfo("[%s] partConfThres = %f",name.c_str(), partConfThres);
    use_fake_hand = rf.check("use_fake_hand",Value(0)).asBool();

    use_mid_arms = rf.check("use_mid_arms",Value(0)).asBool();

    draw_lower = rf.check("draw_lower",Value(0)).asBool();

    if (use_fake_hand)
    {
        fakeHandPos.resize(3,0.0);
        fakeHandPos[0] = -0.3;
        fakeHandPos[1] = 0.05;
        fakeHandPos[2] = 0.05;
    }

    if (use_part_conf)
        yInfo("[%s] Use part confidence as valence", name.c_str());
    else
        yInfo("[%s] Don't use part confidence as valence", name.c_str());

    use_part_filter = rf.check("use_part_filter",Value(1)).asBool();
    if (use_part_filter)
        yInfo("[%s] Use median filters for body parts", name.c_str());
    else
        yInfo("[%s] Don't use median filters for body parts", name.c_str());

    filterOrder = rf.check("filter_order", Value(1)).asInt();
    filterOrderAngles = rf.check("filter_order_angle", Value(7)).asInt();
    yInfo("[%s] order of angle %d",name.c_str(), filterOrderAngles);

    // Connect to /SFM/rpc to obtain 3D estimation
    rpcGet3D.open(("/"+name+"/get3d:rpc").c_str());
//    std::string SFMrpc = "/SFM/rpc";
    connected3D = yarp::os::Network::connect(rpcGet3D.getName().c_str(),SFMrpc);
    if (!connected3D)
        yError("[%s] Unable to connect to SFM rpc port", name.c_str());
    else
        yInfo("[%s] Connected to SFM rpc port", name.c_str());

    // Connect to /skeleton2D/bodyParts:o to get streamed body parts
    bodyPartsInPort.open(("/"+name+"/bodyParts:i").c_str());
//    std::string bodyParts_streaming = "/skeleton2D/bodyParts:o";
//    if (!yarp::os::Network::connect(bodyParts_streaming, bodyPartsInPort.getName().c_str()))
//        yError("[%s] Unable to connect to %s port", name.c_str(),bodyParts_streaming.c_str());
//    else
//        yInfo("[%s] Connected to %s port", name.c_str(), bodyParts_streaming.c_str());

    // Connect to /visuoTactileWrapper/sensManager:i to stream body parts as objects to PPS
    ppsOutPort.open(("/"+name+"/visuoTactileWrapper/objects:o").c_str());
    std::string visuoTactileWrapper_inport = "/visuoTactileWrapper/sensManager:i";
    connectedPPS = yarp::os::Network::connect(ppsOutPort.getName().c_str(), visuoTactileWrapper_inport);
    if (!connectedPPS)
        yError("[%s] Unable to connect to %s port", name.c_str(),visuoTactileWrapper_inport.c_str());
    else
        yInfo("[%s] Connected to %s port", name.c_str(), visuoTactileWrapper_inport.c_str());


    handBlobPort.open(("/"+name+"/handBlobs:o").c_str());
    rpcAskTool.open(("/"+name+"/askTool:rpc").c_str());
    toolClassInPort.open(("/"+name+"/toolClass:i").c_str());

    dThresholdDisparition = rf.check("dThresholdDisparition",Value("3.0")).asDouble();

    // initialise timing in case of misrecognition
    dTimingLastApparition = clock();

    segLMax = 0.35;
    segLMin = 0.20;

    // Median Filter for body part positions
    init_filters = true;
    filterSkeleton.clear();

    init_filters_angle = true;

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
    //TODO check this
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

    rpcPort.open("/"+name+"/rpc");
    attach(rpcPort);

    //**** visualizing human skeleton iCubGui ***************************
    string port2iCubGui = "/" + name + "/gui:o";
    if (!portToGui.open(port2iCubGui.c_str())) {
       yError("[%s] Unable to open port << port2iCubGui << endl", name.c_str());
    }
    std::string portGuiObject = "/iCubGui/objects";     // World frame
    yarp::os::Network::connect(port2iCubGui.c_str(), portGuiObject.c_str());

    cmdGui.clear();
    cmdGui.addString("reset");
    portToGui.write(cmdGui);

    // UDP port to communicate with Ergonometric module
    std::string addr_udp=rf.check("address_udp",Value("192.168.0.62")).asString().c_str();
    int port_udp=rf.check("port_udp",Value(44000)).asInt();

    sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock==-1)
        yError("Cannot open socket");
    else
        yInfo("Opened the socket");

    bzero(&serveraddr, sizeof(serveraddr)); //Initialize to '0'
    serveraddr.sin_family = AF_INET;
    serveraddr.sin_port = htons(port_udp); // Port
    serveraddr.sin_addr.s_addr = inet_addr(addr_udp.c_str()); // Linux PC

    // UDP port to communicate with KUKA module
    std::string addr_udp_kuka=rf.check("address_udp",Value("192.168.0.96")).asString().c_str();
    int port_udp_kuka=rf.check("port_udp",Value(60000)).asInt();

    sockTool = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockTool==-1)
        yError("Cannot open socket for tool");
    else
        yInfo("Opened the socket for tool");

    bzero(&serveraddrTool, sizeof(serveraddrTool)); //Initialize to '0'
    serveraddrTool.sin_family = AF_INET;
    serveraddrTool.sin_port = htons(port_udp_kuka); // Port
    serveraddrTool.sin_addr.s_addr = inet_addr(addr_udp_kuka.c_str()); // Linux PC
    tool_code[0] = 0.0;
    tool_code[1] = 0.0;

    return true;
}

bool    skeleton3D::interruptModule()
{
    yDebug("[%s] Interupt module",name.c_str());

    yDebug("[%s] Remove partner", name.c_str());
    opc->checkout();
    partner = opc->addOrRetrieveEntity<Agent>(partner_default_name);
    partner->m_present=0.0;
    opc->commit(partner);
    opc->removeEntity(partner->opc_id());
    delete partner;
    opc->interrupt();
    rpcPort.interrupt();
    rpcGet3D.interrupt();
    bodyPartsInPort.interrupt();
    ppsOutPort.interrupt();
    handBlobPort.interrupt();               yDebug("check 12");
    rpcAskTool.interrupt();                 yDebug("check 13");

    deleteBodySegGui("upper");
    deleteBodySegGui("spine");
    deleteBodySegGui("lower");
    portToGui.interrupt();
    return true;
}

bool    skeleton3D::close()
{
    yDebug("[%s] closing module",name.c_str());
    rpcPort.close();
    rpcGet3D.close();
    bodyPartsInPort.close();
    ppsOutPort.close();
    portToGui.close();
    handBlobPort.close();
    rpcAskTool.close();
    opc->close();
    delete filterAngles;

//    udp_sender.~udp_client();


    return true;
}

bool    skeleton3D::attach(RpcServer &source)
{
    return this->yarp().attachAsServer(source);
//    return true;
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
//    if (bodyPartsCv.size()>=0 && connected3D)
//    {
//        for (int8_t i=0; i<bodyPartsCv.size(); i++)
//        {
//            Vector pos(3,0.0);
//            get3DPosition(bodyPartsCv[i], pos);
//            yInfo("[%s] 3D pose of CvPoint [%d, %d] from SFM is: %s",
//                  name.c_str(), bodyPartsCv[i].x, bodyPartsCv[i].y, pos.toString(3,3).c_str());
//        }
//    }

    // Update OPC or conduct actions
    // check if this skeletton is really tracked
    if (tracked)
    {
        bool reallyTracked = false;
        if (!use_fake_hand)
        {
            for(map<string,kinectWrapper::Joint>::iterator jnt = player.skeleton.begin() ;
                jnt != player.skeleton.end() ; jnt++)
            {
                if (jnt->second.x != 0 && jnt->second.y != 0 && jnt->second.z != 0)
                {
                    reallyTracked = true;
                    break;
                }
            }
        }
        else
            reallyTracked = true;
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

            drawBodyGui(partner);
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

    if (tracked)
    {
        // send pose to UDP server
        Vector allJoints;
        for (int i=0; i<mapPartsUdp.size(); i++)
        {
            Vector pos(3,0.0);
            if (player.skeleton.find(mapPartsUdp[i].c_str())!=player.skeleton.end())
            {
                pos = joint2Vector(player.skeleton.at(mapPartsUdp[i].c_str()));
            }
            for (int i=0; i<pos.size(); i++)
                allJoints.push_back(pos[i]);
        }

        Vector allAngles = computeAllBodyAngles();
        Vector allAngles_filtered(allAngles.size(),0.0);
        filtAngles(allAngles,allAngles_filtered);
        yDebug("filtered angles: %s", allAngles_filtered.toString(3,3).c_str());

        Vector sendUDP(49,0.0);
        sendUDP.setSubvector(0,allJoints);
        sendUDP.setSubvector(39,allAngles_filtered);
        float SendData[49];


        for (int8_t i=0; i<sendUDP.size(); i++)
            SendData[i] = (float)sendUDP[i];

        int retval = sendto(sock,SendData,sizeof(SendData),0,(sockaddr*)&serveraddr,sizeof(serveraddr));

        if (retval<0)
            yError("problem in sending UDP!!!");
        else
            yDebug("pose package (size %d) sent: %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf", retval,
                   SendData[39], SendData[40], SendData[41], SendData[42], SendData[43],
                   SendData[44], SendData[45], SendData[46], SendData[47], SendData[48]);

    //    if(streamPartsToPPS())
    //        yInfo("[%s] Streamed body parts as objects to PPS",name.c_str());
    //    else
    //        yWarning("[%s] Cannot stream body parts as objects to PPS",name.c_str());

        // Tool recoginition
        Vector blob(4,0.0);
        bool hasToolBlob=false;
        if (hand_with_tool=="right")
        {
            if (allAngles[8]>=10.0 || allAngles[9]>=30.0)
            {
                hasToolBlob = cropHandBlob("handRight", blob);
            }
        }
        else if (hand_with_tool=="left")
        {
            if (allAngles[3]>=10.0 || allAngles[4]>=30.0)
            {
                hasToolBlob = cropHandBlob("handLeft", blob);
            }
        }

        if (hasToolBlob)
        {
            // send to recognition pipeline: blob is in Vector of double
            yDebug("tool recognition");
            Bottle blobBottle;
            for (int8_t i=0; i<blob.size(); i++)
                blobBottle.addDouble(blob[i]);

            Bottle& output = handBlobPort.prepare();
            output.clear();
            output.addList()=blobBottle;
            handBlobPort.write();

            // read from /onTheFlyRecognition/human:io
            string toolLabel="";

            Bottle *toolClassIn = toolClassInPort.read(false);
            if (toolClassIn!=NULL)
            {
                toolLabel = toolClassIn->get(0).asString();
                yDebug("Recognize tool label is: %s",toolLabel.c_str());
            }
            if (toolLabel=="drill") // drill is 1
            {
                tool_code[0] = 1.0;
            }
            else if(toolLabel=="polisher") //polisher is 2
            {
                tool_code[0] = 2.0;
            }

//            if (dSince>dThresholdDisparition)
//                if (askToolLabel(toolLabel))
//                {

//                }
        }
    //    else
    //        yWarning("no hand with tool!");


        // y-coordinate of the head
        if (player.skeleton.find("head")!=player.skeleton.end())
        {
            Vector posHead(3,0.0);
            posHead = joint2Vector(player.skeleton.at("head"));
            yDebug("head position %s", posHead.toString(3,3).c_str());
            tool_code[1] = posHead[1];

        }

        // sendUDP to KUKA
        int retval_tool = sendto(sockTool,tool_code,sizeof(tool_code),0,(sockaddr*)&serveraddrTool,sizeof(serveraddrTool));

        if (retval_tool<0)
            yError("problem in sending UDP to KUKA!!!");
        else
            yDebug("tool package (size %d) sent: %lf %lf", retval_tool, tool_code[0],tool_code[1]);
    }

    return true;
}

double  skeleton3D::angleAtJoint(const Vector &v1, const Vector &v2)
{
    return acos(dot(v1,v2)/(norm(v1)*norm(v2)))*180.0/M_PI;
}

Vector  skeleton3D::vectorBetweenJnts(const Vector &jnt1, const Vector &jnt2)
{
    return jnt2-jnt1;
}

Vector  skeleton3D::joint2Vector(const kinectWrapper::Joint &joint)
{
    Vector jnt(3,0.0);
    jnt[0] = joint.x;
    jnt[1] = joint.y;
    jnt[2] = joint.z;

    return jnt;
}

bool    skeleton3D::cropHandBlob(const string &hand, Vector &blob)
{
    if (player.skeleton.find(hand.c_str())!=player.skeleton.end())
    {
        Vector pose2d(2,0.0);
        kinectWrapper::Joint jnt= player.skeleton.at(hand.c_str());
//        pose2d[0] = (double)jnt.u;
//        pose2d[1] = (double)jnt.v;
        pose2d[0] = handCV.x;
        pose2d[1] = handCV.y;
//        yDebug("cropHandBlob: pose 2d is %s", pose2d.toString(3,1).c_str());
        blob[0] = pose2d[0] - radius;   //top-left.x
        blob[1] = pose2d[1] - radius;   //top-left.y
        blob[2] = pose2d[0] + radius;   //bottom-right.x
        blob[3] = pose2d[1] + radius;   //bottom-right.y
        yDebug("blob is: [%s]",blob.toString(3,1).c_str());
        return true;
    }
    else
        return false;

}

bool    skeleton3D::askToolLabel(string &label)
{
    yDebug("askToolLabel");
    if (rpcAskTool.getOutputCount()>0)
    {
        Bottle cmd,reply;
//        cmd.addString("what");
        cmd.addVocab(Vocab::encode("what"));
        yDebug("check 1");
//        cmd.addInt(0);

        mutexResourcesTool.lock();
        rpcAskTool.write(cmd,reply);
        mutexResourcesTool.unlock();

        int sz=reply.size();
        yDebug("check sz reply: %d",sz);
        if (sz>0)
        {
            label = reply.get(0).asString();
            yInfo("[%s] Tool is %s", name.c_str(), label.c_str());
            return true;
        }
        else
        {
            yError("[%s] No tool recognize",name.c_str());
            return false;
        }
    }
    else
        return false;
}

Vector  skeleton3D::computeAllBodyAngles()
{
    Vector allAngles(10,0.0);
    yInfo("compute angle 1");
    allAngles[0] = computeBodyAngle("hipLeft", "kneeLeft", "shoulderLeft");
    yInfo("compute angle 2");
    allAngles[1] = computeBodyAngle("kneeLeft", "ankleLeft", "hipLeft");
    yInfo("compute angle 7");
    allAngles[6] = computeBodyAngle("shoulderLeft","hipLeft", "elbowLeft");
    yInfo("compute angle 8");
    allAngles[7] = computeBodyAngle("elbowLeft" ,"handLeft" ,"shoulderLeft");

    allAngles[2] = computeFootAngle("ankleLeft", "kneeLeft");

    // Right part of the body
    yInfo("compute angle 4");
    allAngles[3] = computeBodyAngle("hipRight", "kneeRight", "shoulderRight");
    yInfo("compute angle 5");
    allAngles[4] = computeBodyAngle("kneeRight", "ankleRight", "hipRight");
    yInfo("compute angle 9");
    allAngles[8] = computeBodyAngle("shoulderRight","hipRight", "elbowRight");
    yInfo("compute angle 10");
    allAngles[9] = computeBodyAngle("elbowRight" ,"handRight" ,"shoulderRight");

    allAngles[5] = computeFootAngle("ankleRight", "kneeRight");

    yInfo("angles: %s", allAngles.toString(3,3).c_str());
    return allAngles;
}

double  skeleton3D::computeBodyAngle(const string &partName1, const string &partName2, const string &partName3)
{
    Vector jnt1(3,0.0), jnt2(3,0.0), jnt3(3,0.0);
    if (player.skeleton.find(partName1.c_str())!=player.skeleton.end())
        yInfo("found %s", partName1.c_str());
    if (player.skeleton.find(partName2.c_str())!=player.skeleton.end())
        yInfo("found %s", partName2.c_str());
    if (player.skeleton.find(partName3.c_str())!=player.skeleton.end())
        yInfo("found %s", partName3.c_str());
    if (player.skeleton.find(partName1.c_str())!=player.skeleton.end() &&
            player.skeleton.find(partName2.c_str())!=player.skeleton.end() &&
            player.skeleton.find(partName3.c_str())!=player.skeleton.end())
    {
        yInfo("computeBodyAngle: found %s %s %s", partName1.c_str(), partName2.c_str(), partName3.c_str());
        jnt1 = joint2Vector(player.skeleton.at(partName1.c_str()));
        jnt2 = joint2Vector(player.skeleton.at(partName2.c_str()));
        jnt3 = joint2Vector(player.skeleton.at(partName3.c_str()));
        Vector link12 = vectorBetweenJnts(jnt1, jnt2);
        Vector link13 = vectorBetweenJnts(jnt1, jnt3);

        //TODO check this
//        link12[1]=0;    link13[1]=0;

        return angleAtJoint(link12,link13);
    }
    else
        return 0.0;

}

double  skeleton3D::computeFootAngle(const string &partName1, const string &partName2)
{
    Vector jnt1(3,0.0), jnt2(3,0.0), jnt3(3,0.0);
    if (player.skeleton.find(partName1.c_str())!=player.skeleton.end() &&
            player.skeleton.find(partName2.c_str())!=player.skeleton.end())
    {
        jnt1 = joint2Vector(player.skeleton.at(partName1.c_str()));
        jnt2 = joint2Vector(player.skeleton.at(partName2.c_str()));
        jnt3 = jnt1;
        jnt3[0] -=0.1;
        yInfo("joints: %s, %s, %s", jnt1.toString(3,3).c_str(),
              jnt2.toString(3,3).c_str(), jnt3.toString(3,3).c_str());
        Vector link12 = vectorBetweenJnts(jnt1, jnt2);
        Vector link13 = vectorBetweenJnts(jnt1, jnt3);

        //TODO check this
//        link12[1]=0;    link13[1]=0;

        return angleAtJoint(link12,link13);
    }
    else
        return 0.0;

}
