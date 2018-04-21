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
//                yDebug("[%s] filt: apply median filter for %s",name.c_str(), partName.c_str());
//                yDebug("[%s] filt: pose of %s is %s",name.c_str(), partName.c_str(), posFilted.toString(3,3).c_str());
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
//        yDebug("[%s] filtAngles: apply median filter for angle",name.c_str());
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
        cmd.addInt(2);
        cmd.addInt(2);
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

    return (norm(x)>=0.0);
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
//                bool ignoreSkeleton = false;
                if (Bottle *bodyParts=allBodyParts->get(0).asList())
                {
                    Bottle neck = bodyParts->findGroup("Neck");
                    Bottle shR = bodyParts->findGroup("RShoulder");
//                    yDebug("neck: %s",neck.toString().c_str());
                    // first check to make make sure the skeleton is the one working with robot
                    if (!neck.isNull())
                    {
                        CvPoint neckCv;
                        Vector neck3D(3,0.0);
                        neckCv.x = (int)neck.get(1).asDouble();
                        neckCv.y = (int)neck.get(2).asDouble();
                        if (get3DPosition(neckCv, neck3D))
                        {
                            yDebug("found neck. neck3D = %s!!!", neck3D.toString(3,3).c_str());
                            if (neck3D[0]<workspaceX_min || neck3D[0]>=workspaceX || neck3D[1]>=workspaceY || neck3D[1]<=-workspaceY ||
                                    (neck3D[0] == 0.0 && neck3D[1] == 0.0 && neck3D[2] == 0.0))
                            {
                                yWarning("ignore this skeleton!");
                                goto endOneSkeleton;
                            }
                        }
                        else
                        {
                            yWarning("No neck3D, ignore this skeleton!");
                            goto endOneSkeleton;
                        }
                    }
                    // double check
                    if (!shR.isNull())
                    {
                        CvPoint shoulderCv;
                        Vector shoulder3D(3,0.0);
                        shoulderCv.x = (int)shR.get(1).asDouble();
                        shoulderCv.y = (int)shR.get(2).asDouble();
                        if (get3DPosition(shoulderCv, shoulder3D))
                        {
                            yDebug("found shoulder. shoulder3D = %s!!!", shoulder3D.toString(3,3).c_str());
                            if (shoulder3D[0]<workspaceX_min ||shoulder3D[0]>=workspaceX || shoulder3D[1]>=workspaceY || shoulder3D[1]<=-workspaceY ||
                                    (shoulder3D[0] == 0.0 && shoulder3D[1] == 0.0 && shoulder3D[2] == 0.0))
                            {
                                yWarning("ignore this skeleton!");
                                goto endOneSkeleton;
                            }
                        }
                        else
                        {
                            yWarning("No shoulder3D, ignore this skeleton!");
                            goto endOneSkeleton;
                        }
                    }
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

                                //TODO make this better use for training tool
                                if (tool_training)
                                {
                                    if (hand_with_tool=="right" && (partName =="RWrist" || partName =="Rwrist"))
                                        handCV = partCv;
                                    else if (hand_with_tool=="left" && (partName =="LWrist" || partName =="Lwrist"))
                                        handCV = partCv;
                                }

                                if (partName =="RWrist" || partName =="Rwrist")
                                    handCV_right = partCv;
                                else if (partName =="LWrist" || partName =="Lwrist")
                                    handCV_left = partCv;

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
//                        else
//                            yDebug("[%s] obtainBodyParts: don't deal with face parts!",name.c_str());
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
                constraintBodyLinks(jnts);
                constraintHip(jnts);

                if (use_part_filter)
                {
                    filt(jnts,jntsFiltered);    // Filt the obtain skeleton with Median Filter, tune by filterOrder. The noise is due to the SFM 3D estimation
                    player.skeleton = jntsFiltered;
                }
                else
                    player.skeleton = jnts;

                ts.update();
                endOneSkeleton: ;
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
                segL = segLNormal;
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
        constraintOneBodyLink(jnts, "shoulderCenter", "shoulderRight", 0.15, 0.3, 0.25);
        constraintOneBodyLink(jnts, "shoulderRight", "elbowRight", 0.2, 0.35, 0.3);

        constraintOneBodyLink(jnts, "shoulderLeft", "hipLeft", 0.45, 0.65, 0.55);
        constraintOneBodyLink(jnts, "shoulderRight", "hipRight", 0.45, 0.65, 0.55);

        constraintOneBodyLink(jnts, "hipLeft", "kneeLeft", 0.4, 0.55, 0.48);
        constraintOneBodyLink(jnts, "hipRight", "kneeRight", 0.4, 0.55, 0.48);

        constraintOneBodyLink(jnts, "kneeLeft", "ankleLeft", 0.4, 0.55, 0.48);
        constraintOneBodyLink(jnts, "kneeRight", "ankleRight", 0.4, 0.55, 0.48);
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

void    skeleton3D::constraintHip(map<string, kinectWrapper::Joint> &jnts)
{
    if (!jnts.empty() && jnts.find("hipLeft")!=jnts.end() && jnts.find("hipRight")!=jnts.end() &&
            jnts.find("shoulderLeft")!=jnts.end() && jnts.find("shoulderRight")!=jnts.end() &&
            jnts.find("handLeft")!=jnts.end())
    {
        Vector hipR(3,0.0), hipL(3,0.0), shR(3,0.0), shL(3,0.0), hL_new(3,0.0), hR_new(3,0.0), handL(3,0.0);
        hipL = joint2Vector(jnts.at("hipLeft"));
        hipR = joint2Vector(jnts.at("hipRight"));
        shL = joint2Vector(jnts.at("shoulderLeft"));
        shR = joint2Vector(jnts.at("shoulderRight"));
        handL = joint2Vector(jnts.at("handLeft"));

        double hipLength = norm(hipL-hipR);
        double handL2hipL = norm(hipL-handL);
        double handL2hipR = norm(hipR-handL);
        yDebug("constraintHip condition: hipLength = %f, hLx-shLx=%f, hand2hipL = %f",
               hipLength, abs(hipL[0]-shL[0]), handL2hipL);
        if (((hipLength>0.32 || hipLength<0.23) &&
             (abs(hipL[0]-shL[0])>0.15 || abs(hipR[0]-shR[0])>0.15) &&
             (handL2hipL<0.2 || handL2hipR<0.2)))// || hL[0]<handL[0])
        {
            yWarning("constraintHip");
            hL_new = shL;
            hL_new[2] -= 0.55;
//            hL_new[2] = hipR[2];
            hR_new = shR;
            hR_new[2] -= 0.55;
            assignJointByVec(jnts.at("hipLeft"), hL_new);
            assignJointByVec(jnts.at("hipRight"), hR_new);
            yDebug("hL=%s; hL_new=%s",hipL.toString(3,3).c_str(), hL_new.toString(3,3).c_str() );
            yDebug("hR=%s; hR_new=%s",hipR.toString(3,3).c_str(), hR_new.toString(3,3).c_str() );
        }
    }
    else
        yDebug("[%s] constraintHip: no any body part", name.c_str());
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

    radius=rf.check("radius",Value(5.0)).asDouble();
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

    workspaceX = rf.check("workspace_x",Value(2.1)).asDouble();
    workspaceX_min = rf.check("workspace_x_min",Value(0.45)).asDouble();
    yInfo("workspace_x_min = %f", workspaceX_min);
    workspaceY = rf.check("workspace_y",Value(1.5)).asDouble();

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

    handBlobPort_left.open(("/"+name+"/handBlobs_left:o").c_str());
    toolClassInPort_left.open(("/"+name+"/toolClass_left:i").c_str());

    dThresholdDisparition = rf.check("dThresholdDisparition",Value("3.0")).asDouble();

    // initialise timing in case of misrecognition
    dTimingLastApparition = clock();
    tool_lastClock = clock();

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
    tool_timer = 0.0;
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
    tool_code[0] = 100.0;
    tool_code[1] = 0.0;
    tool_code[2] = 200.0;

    toolLabelR="";      toolLabelL="";
    hasToolR = false;   hasToolL = false;

    counterToolL = 0; counterToolR = 0;
    counterHand = 0, counterDrill = 0; counterPolisher = 0;
    sendData49 = 0.0;   sendData51 = 0.0;
    tool_training = false;

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
    handBlobPort.interrupt();
    toolClassInPort.interrupt();
    toolClassInPort_left.interrupt();
    handBlobPort_left.interrupt();          yDebug("check 12");
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
    toolClassInPort.close();
    toolClassInPort_left.close();
    handBlobPort_left.close();
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

//    if (tracked)
//    {
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
//        yDebug("filtered angles: %s", allAngles_filtered.toString(3,3).c_str());

        Vector sendUDP(49,0.0);
        sendUDP.setSubvector(0,allJoints);
        sendUDP.setSubvector(39,allAngles_filtered);
//        sendUDP.setSubvector(39,allAngles);
        float SendData[52];


        for (int8_t i=0; i<sendUDP.size(); i++)
            SendData[i] = (float)sendUDP[i];

        //Tool recognition
        if (!tool_training)
        {
            tool_timer = (clock() - tool_lastClock) / (double)CLOCKS_PER_SEC;

//            if (allAngles[8]>=10.0 || allAngles[9]>=30.0)
//            {
                hasToolR = toolRecognition("handRight", toolLabelR);
                if (hasToolR)
                    hasToolL = false;
//            }
//            if (allAngles[3]>=10.0 || allAngles[4]>=30.0)
//            {
                hasToolL = toolRecognition("handLeft", toolLabelL);
                if (hasToolL)
                    hasToolR = false;
//            }

            if (toolLabelL=="drill" || toolLabelR=="drill") // drill is 2
            {
//                    tool_code[0] = 102.0;
                counterDrill++;
            }
            else if(toolLabelL=="polisher" || toolLabelR=="polisher") //polisher is 1
            {
//                    tool_code[0] = 101.0;
                counterPolisher++;
            }
            else if(toolLabelL=="hand" || toolLabelR=="hand") //hand is 0
            {
                counterHand++;
            }
            else
            {
//                    tool_code[0] = 100.0;
            }
//            yDebug("Recognize tool label is: right - %s, left - %s",toolLabelR.c_str(), toolLabelL.c_str());
        }
        else
        {
            // Tool training
            Vector blob(4,0.0);
            bool hasToolBlob=false;
//            hasToolL = false;   hasToolR = false;
//            toolLabelL = "";    toolLabelR = "";
            if (hand_with_tool=="right")
            {
//                if (allAngles[8]>=10.0 || allAngles[9]>=30.0)
//                {
                    hasToolBlob = cropHandBlob("handRight", blob);
//                }
            }
            else if (hand_with_tool=="left")
            {
//                if (allAngles[3]>=10.0 || allAngles[4]>=30.0)
//                {
                    hasToolBlob = cropHandBlob("handLeft", blob);
//                }
            }

            if (hasToolBlob)
            {
                // send to recognition pipeline: blob is in Vector of double
//                yDebug("tool recognition");
                Bottle blobBottle;
                for (int8_t i=0; i<blob.size(); i++)
                    blobBottle.addDouble(blob[i]);

                Bottle& output = handBlobPort.prepare();
                output.clear();
                output.addList()=blobBottle;
                handBlobPort.write();

                // read from /onTheFlyRecognition/human:io
                string toolLabel="";
                toolLabelL = "";    toolLabelR = "";
                Bottle *toolClassIn = toolClassInPort.read(false);
                if (toolClassIn!=NULL)
                {
                    toolLabel = toolClassIn->get(0).asString();
//                    yDebug("Recognize tool label is: %s",toolLabel.c_str());
                }   //yDebug("Recognize tool label is: %s",toolLabel.c_str());
                if (hand_with_tool=="right")
                {
                    toolLabelR = toolLabel;
                    if (toolLabel =="drill" || toolLabel == "polisher")
                    {
                        hasToolR = true;
                        hasToolL = false;
                    }
                }
                else if (hand_with_tool=="left")
                {
                    toolLabelL = toolLabel;
                    if (toolLabel =="drill" || toolLabel == "polisher")
                    {
                        hasToolL = true;
                        hasToolR = false;
                    }
                }

                if (toolLabel=="drill") // drill is 1
                {
                    tool_code[0] = 101.0;
                }
                else if(toolLabel=="polisher") //polisher is 2
                {
                    tool_code[0] = 102.0;
                }
                else
                    tool_code[0] = 100.0;

            }
//            yDebug("Recognize tool label is: right - %s, left - %s",toolLabelR.c_str(), toolLabelL.c_str());
        }

        // y-coordinate of the head
        if (player.skeleton.find("head")!=player.skeleton.end())
        {
            Vector posHead(3,0.0);
            posHead = joint2Vector(player.skeleton.at("head"));
            tool_code[1] = posHead[1];

        }

        // tool in which hand
        if (!hasToolL && !hasToolR)
        {
            tool_code[2] = 200.0;
//            yWarning("Empty hand!");
        }

        else if (hasToolL && !hasToolR)
        {
            tool_code[2] = 201.0;
            counterToolL++; // reduce identification fluctuation
//            SendData[49] = 1.0;
        }
        else if (!hasToolL && hasToolR)
        {
            tool_code[2] = 202.0;
            counterToolR++; // reduce identification fluctuation
//            SendData[49] = 0.0;
        }

        if (toolLabelL == "drill" || toolLabelL == "polisher" || toolLabelR == "drill" || toolLabelR == "polisher")
        {
            SendData[50] = 1.0;
        }
        else //if (toolLabelL == "" && toolLabelL == "" && toolLabelR == "" && toolLabelR == "")
            SendData[50] = 0.0;

        if (tool_timer>=0.5)
        {
            if (counterToolL>counterToolR)
                SendData[49] = 1.0;
            else
                SendData[49] = 0.0;

            unsigned int counterTool = max(max(counterDrill, counterHand), max(counterDrill,counterPolisher));
//            yInfo("counter value: all %u, drill %u, hand %u, polisher %u", counterTool, counterDrill, counterHand, counterPolisher);
            if (counterTool == counterDrill)
            {
                tool_code[0] = 101.0;
                SendData[51] = 0.0;
            }
            else if (counterTool == counterPolisher)
            {
                tool_code[0] = 102.0;
                SendData[51] = 1.0;
            }
            else if (counterTool == counterHand)
                tool_code[0] = 100.0;

            sendData49 = SendData[49];
            sendData51 = SendData[51];
            tool_lastClock = clock();
            counterToolL = 0;
            counterToolR = 0;
            counterHand = 0;
            counterDrill = 0;
            counterPolisher = 0;
        }
        else
        {
            SendData[49] = sendData49;
            SendData[51] = sendData51;
        }
//        SendData[51] = 1.0;
//        yDebug("tool_timer %f(s), SendData[49]=%lf",tool_timer, SendData[49]);
        // sendUDP to Egornometric
        int retval = sendto(sock,SendData,sizeof(SendData),0,(sockaddr*)&serveraddr,sizeof(serveraddr));

        if (retval<0)
            yError("problem in sending UDP!!!");
//        else
//            yDebug("pose package (size %d) sent: %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf", retval,
//                   SendData[39], SendData[40], SendData[41], SendData[42], SendData[43],
//                   SendData[44], SendData[45], SendData[46], SendData[47], SendData[48]);
//            yDebug("hip angles (size %d) sent: %lf %lf ", retval,
//                   SendData[39], SendData[42]);

        else
                    yDebug("tool content to Ergo (size %d) sent: %lf %lf %lf", retval,
                           SendData[49], SendData[50], SendData[51]);

        // sendUDP to KUKA
        int retval_tool = sendto(sockTool,tool_code,sizeof(tool_code),0,(sockaddr*)&serveraddrTool,sizeof(serveraddrTool));

        if (retval_tool<0)
            yError("problem in sending UDP to KUKA!!!");
//        else
//            yDebug("tool package (size %d) sent: %lf %lf %lf", retval_tool, tool_code[0],tool_code[1], tool_code[2]);
//    }

    return true;
}

double  skeleton3D::angleAtJoint(const Vector &v1, const Vector &v2, const double &direction)
{
    double angle = (acos(dot(v1,v2)/(norm(v1)*norm(v2))))*180.0/M_PI;
    Vector vn(3,0.0);
    vn[1] = direction;
//    if (dot(vn,cross(v1,v2))<0)
//        angle = -angle;
    return angle;
}

double  skeleton3D::angleAtJointTan(const Vector &v1, const Vector &v2, const double &direction)
{
    Vector vn(3,0.0);
    vn[1] = direction;
//    vn[0] = -1.0;
//    vn[2] = -1.0;
    return (atan2(dot(cross(v1,v2),vn/norm(vn)),dot(v1,v2)))*180.0/M_PI;
}

double  skeleton3D::angleAtJointTan(const Vector &v1, const Vector &v2, const Vector &direction)
{
    Vector vn = direction;
    return (atan2(dot(cross(v1,v2),vn/norm(vn)),dot(v1,v2)))*180.0/M_PI;
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
//        kinectWrapper::Joint jnt= player.skeleton.at(hand.c_str());
//        pose2d[0] = (double)jnt.u;
//        pose2d[1] = (double)jnt.v;
        // use for training tool
//        pose2d[0] = handCV.x;
//        pose2d[1] = handCV.y;

        if (hand == "handRight")
        {
            pose2d[0] = handCV_right.x;
            pose2d[1] = handCV_right.y;
        }
        else if (hand == "handLeft")
        {
            pose2d[0] = handCV_left.x;
            pose2d[1] = handCV_left.y;
        }

        blob[0] = pose2d[0] - radius;   //top-left.x
        blob[1] = pose2d[1] - radius;   //top-left.y
        blob[2] = pose2d[0] + radius;   //bottom-right.x
        blob[3] = pose2d[1] + radius;   //bottom-right.y
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
        cmd.addVocab(Vocab::encode("what"));
        yDebug("check 1");

//        mutexResourcesTool.lock();
        rpcAskTool.write(cmd,reply);
//        mutexResourcesTool.unlock();

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

bool    skeleton3D::toolRecognition(const string &hand, string &toolLabel)
{
    Vector blob(4,0.0);
    bool hasToolBlob=false;
    hasToolBlob = cropHandBlob(hand.c_str(), blob);

    if (hasToolBlob)
    {
        // send to recognition pipeline: blob is in Vector of double
//        yDebug("tool recognition");
        Bottle blobBottle;
        for (int8_t i=0; i<blob.size(); i++)
            blobBottle.addDouble(blob[i]);

        if (hand=="handRight")
        {
            Bottle& output = handBlobPort.prepare();
            output.clear();
            output.addList()=blobBottle;
            handBlobPort.write();

            Bottle *toolClassIn = toolClassInPort.read(false);
            if (toolClassIn!=NULL)
            {
                toolLabel = toolClassIn->get(0).asString();
//                yDebug("Recognize tool label in %s is: %s",hand.c_str(), toolLabel.c_str());
//                if (toolLabel=="drill") // drill is 1
//                {
//                    tool_code[0] = 102.0;
//                }
//                else if(toolLabel=="polisher") //polisher is 2
//                {
//                    tool_code[0] = 101.0;
//                }
//                else
//                {
//                    tool_code[0] = 100.0;
//                    return false;
//                }
                if (toolLabel=="drill" || toolLabel=="polisher")
                    return true;
                else
                    return false;
            }
            else
                return false;
        }
        else if (hand=="handLeft")
        {
            Bottle& output = handBlobPort_left.prepare();
            output.clear();
            output.addList()=blobBottle;
            handBlobPort_left.write();
            Bottle *toolClassIn = toolClassInPort_left.read(false);
            if (toolClassIn!=NULL)
            {
                toolLabel = toolClassIn->get(0).asString();
//                yDebug("Recognize tool label in %s is: %s",hand.c_str(), toolLabel.c_str());
                if (toolLabel=="drill" || toolLabel=="polisher")
                    return true;
                else
                    return false;
            }
            else
                return false;
        }
        else
            return false;
    }
    else
        return false;
}

Vector  skeleton3D::computeAllBodyAngles()
{
    Vector allAngles(10,0.0);
    double angHip = 0.0, angKnee = 0.0, angAnkle = 0.0;
    computeLowerBodyMeanAngles(angHip,angKnee,angAnkle);

//    yInfo("compute angle 1");
//    allAngles[0] = computeBodyAngle("hipLeft", "kneeLeft", "shoulderCenter", 1.0);
    allAngles[0] = angHip;
//    yInfo("compute angle 2");
//    allAngles[1] = abs(computeBodyAngle("kneeLeft", "ankleLeft", "hipLeft", 1.0));
//    constraintNegAngle(allAngles[1], -170.0);
    allAngles[1] = angKnee;

//    yInfo("compute angle 7");
    allAngles[6] = computeBodyAngle("shoulderLeft","hipLeft", "elbowLeft", 1.0);
//    yInfo("compute angle 8");
    allAngles[7] = computeBodyAngle("elbowLeft" ,"handLeft" ,"shoulderLeft", 1.0);
    constraintNegAngle(allAngles[7], -179.0);
    if (allAngles[7]<=0.0)
        allAngles[7] =179.0;

//    allAngles[2] = abs(computeFootAngle("ankleLeft", "kneeLeft", -1.0));
    allAngles[2] = angAnkle;

    // Right part of the body
//    yInfo("compute angle 4");
//    allAngles[3] = computeBodyAngle("hipRight", "kneeRight", "shoulderCenter", 1.0);
    constraintNegAngle(allAngles[3], -170.0);
    allAngles[3] = angHip;
//    yInfo("compute angle 5");
//    allAngles[4] = abs(computeBodyAngle("kneeRight", "ankleRight", "hipRight", 1.0));
    allAngles[4] = angKnee;
//    yInfo("compute angle 9");
    allAngles[8] = computeBodyAngle("shoulderRight","hipRight", "elbowRight", 1.0);
//    yInfo("compute angle 10");
    allAngles[9] = computeBodyAngle("elbowRight" ,"handRight" ,"shoulderRight", 1.0);
    constraintNegAngle(allAngles[9], -179.0);
    if (allAngles[9]<=0.0)
        allAngles[9] =179.0;

//    allAngles[5] = abs(computeFootAngle("ankleRight", "kneeRight", -1.0));
    allAngles[5] = angAnkle;

//    yInfo("angles: %s", allAngles.toString(3,3).c_str());

    // constraint hip angles
    if (allAngles[0]<0)
        allAngles[0] = min(-160.0, allAngles[0]);

    if (allAngles[3]<0)
        allAngles[3] = min(-160.0, allAngles[3]);


//    yInfo("constraint angles: %s", allAngles.toString(3,3).c_str());
    return allAngles;
}

void  skeleton3D::computeLowerBodyMeanAngles(double &angleHip,
                                             double &angleKnee,
                                             double &angleAnkle)
{
    if (player.skeleton.find("shoulderLeft")!=player.skeleton.end() &&
            player.skeleton.find("shoulderRight")!=player.skeleton.end() &&
            player.skeleton.find("hipLeft")!=player.skeleton.end() &&
            player.skeleton.find("hipRight")!=player.skeleton.end() &&
            player.skeleton.find("kneeLeft")!=player.skeleton.end() &&
            player.skeleton.find("kneeRight")!=player.skeleton.end() &&
            player.skeleton.find("ankleLeft")!=player.skeleton.end() &&
            player.skeleton.find("ankleRight")!=player.skeleton.end())
    {
        Vector hipR(3,0.0), hipL(3,0.0), shR(3,0.0), shL(3,0.0),
                kL(3,0.0), kR(3,0.0), akL(3,0.0), akR(3,0.0);
        hipL = joint2Vector(player.skeleton.at("hipLeft"));
        hipR = joint2Vector(player.skeleton.at("hipRight"));
        shL = joint2Vector(player.skeleton.at("shoulderLeft"));
        shR = joint2Vector(player.skeleton.at("shoulderRight"));
        kL = joint2Vector(player.skeleton.at("kneeLeft"));
        kR = joint2Vector(player.skeleton.at("kneeRight"));
        akL = joint2Vector(player.skeleton.at("ankleLeft"));
        akR = joint2Vector(player.skeleton.at("ankleRight"));
        Vector hip = (hipL+hipR)/2.0;
        Vector sh = (shL+shR)/2.0;
        Vector knee = (kL+kR)/2.0;
        Vector ankle = (akL+akR)/2.0;
        hip[1] = 0.0;
        sh[1] = 0.0;
        knee[1] = 0.0;
        ankle[1] = 0.0;
        Vector toe = ankle;
        toe[0]  -= 0.1;

        angleHip = computeBodyAngle(hip, sh, knee, -1.0);
        angleKnee = computeBodyAngle(knee, hip, ankle, 1.0);
        if (angleKnee<0.0)
            angleKnee = min(angleKnee, -170.0);
        angleAnkle = abs(computeBodyAngle(ankle, knee, toe, -1.0));

    }
}

void    skeleton3D::constraintNegAngle(double &angle, const double &maxValue)
{
    if (angle<0.0)
        angle = min(angle, maxValue);
}

double  skeleton3D::computeBodyAngle(const string &partName1, const string &partName2,
                                     const string &partName3, const double &direction)
{
    Vector jnt1(3,0.0), jnt2(3,0.0), jnt3(3,0.0);
    if (player.skeleton.find(partName1.c_str())!=player.skeleton.end() &&
            player.skeleton.find(partName2.c_str())!=player.skeleton.end() &&
            player.skeleton.find(partName3.c_str())!=player.skeleton.end())
    {
//        yInfo("computeBodyAngle: found %s %s %s", partName1.c_str(), partName2.c_str(), partName3.c_str());
        jnt1 = joint2Vector(player.skeleton.at(partName1.c_str()));
        jnt2 = joint2Vector(player.skeleton.at(partName2.c_str()));
        jnt3 = joint2Vector(player.skeleton.at(partName3.c_str()));

        Vector yRefJoint(3,0.0);
        bool useYRef=false;
        if (partName1=="hipRight" || partName1=="kneeRight" ||
                partName1=="shoulderRight" || partName1=="elbowRight")
        {
            yRefJoint = joint2Vector(player.skeleton.at("shoulderRight"));
            useYRef = true;
        }
        else if (partName1=="hipLeft" || partName1=="kneeLeft" ||
                 partName1=="shoulderLeft" || partName1=="elbowLeft")
        {
            yRefJoint = joint2Vector(player.skeleton.at("shoulderLeft"));
            useYRef = true;
        }

        if (useYRef)
        {
            jnt1[1] = 0.0;//yRefJoint[1];
            jnt2[1] = 0.0;//yRefJoint[1];
            jnt3[1] = 0.0;//yRefJoint[1];
        }

        Vector link12 = jnt2-jnt1;
        Vector link13 = jnt3-jnt1;

        Vector dir = jnt1;
        dir[1] += direction;

        double angle = angleAtJointTan(link12, link13, dir);
//        double angle = angleAtJointTan(link12, link13, direction);

//        double angle = angleAtJoint(link12,link13);
        if (partName1=="hipRight" || partName1=="hipLeft")
        {
            // 1: hip, 2: knee, 3: shoulder
            if ((partName1=="hipRight" || partName1=="hipLeft") && angle<-165.0)
                angle =min(-180.0,angle-10.0);   //offset
        }
        return angle;
//        else if (partName1=="shoulderRight" || partName1=="shoulderLeft")
//        {
//            // 1: shoulder, 2: hip, 3: elbow
//            if ((jnt1[0]+jnt2[0])/2.0+0.05>jnt3[0])
//                return angle;
//            else
//                return -angle;
//        }
//        else
//            return angle;   //angleAtJoint(link12,link13);
    }
    else
        return 0.0;

}

double  skeleton3D::computeBodyAngle(const Vector &jnt1, const Vector &jnt2, const Vector &jnt3, const double &direction)
{
    Vector link12 = jnt2-jnt1;
    Vector link13 = jnt3-jnt1;

    Vector dir = jnt1;
    dir[1] += direction;
    return angleAtJointTan(link12, link13, direction);
}

double  skeleton3D::computeFootAngle(const string &partName1, const string &partName2,
                                     const double &direction)
{
    Vector jnt1(3,0.0), jnt2(3,0.0), jnt3(3,0.0);
    if (player.skeleton.find(partName1.c_str())!=player.skeleton.end() &&
            player.skeleton.find(partName2.c_str())!=player.skeleton.end())
    {
        jnt1 = joint2Vector(player.skeleton.at(partName1.c_str()));
        jnt2 = joint2Vector(player.skeleton.at(partName2.c_str()));
        jnt3 = jnt1;
        jnt3[0] -=0.1;
//        jnt3  = jnt2;
//        jnt3[2] = jnt1[2];
//        yInfo("joints: %s, %s, %s", jnt1.toString(3,3).c_str(),
//              jnt2.toString(3,3).c_str(), jnt3.toString(3,3).c_str());
//        Vector link12 = vectorBetweenJnts(jnt1, jnt2);
//        Vector link13 = vectorBetweenJnts(jnt1, jnt3);

        Vector yRefJoint(3,0.0);
        bool useYRef=false;
        if (partName1=="ankleRight")
        {
            yRefJoint = joint2Vector(player.skeleton.at("shoulderRight"));
            useYRef = true;
        }
        else if (partName1=="ankleLeft")
        {
            yRefJoint = joint2Vector(player.skeleton.at("shoulderLeft"));
            useYRef = true;
        }

        if (useYRef)
        {
            jnt1[1] = 0.0;  //yRefJoint[1];
            jnt2[1] = 0.0;  //yRefJoint[1];
            jnt3[1] = 0.0;  //yRefJoint[1];
        }

        Vector link12 = jnt2-jnt1;
        Vector link13 = jnt3-jnt1;

        //TODO check this
//        link12[1]=0;    link13[1]=0;

        return (angleAtJoint(link12,link13, direction));
    }
    else
        return 0.0;

}
