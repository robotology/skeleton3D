#include "collaboration.h"

bool    collaboration::configure(ResourceFinder &rf)
{
    name=rf.check("name",Value("icubCollaboration")).asString().c_str();
    robot=rf.check("robot",Value("icub")).asString().c_str();
    part=rf.check("part",Value("right_arm")).asString().c_str();
    posTol=rf.check("position_tolerance",Value(0.001)).asDouble();
    if (part == "right_arm")
        _arm = "right";
    else if (part == "left_arm")
        _arm = "left";
    period=rf.check("period",Value(0.0)).asDouble();    // as default, update module as soon as receiving new parts from skeleton2D

    // Workspace
    workspaceX=rf.check("workspaceX",Value(-0.5)).asDouble();
    workspaceY=rf.check("workspaceY",Value(0.3)).asDouble();
    workspaceZ_low=rf.check("workspaceZ_low",Value(-0.1)).asDouble();
    workspaceZ_high=rf.check("workspaceZ_high",Value(0.35)).asDouble();

    // OPC client
    partner_default_name=rf.check("partner_default_name",Value("partner")).asString().c_str();
    string opcName=rf.check("opc",Value("OPC")).asString().c_str();
    opc = new OPCClient(name);

    while (!opc->connect(opcName))
    {
        yInfo()<<"Waiting connection to OPC...";
        Time::delay(1.0);
    }
    opc->checkout();

    // Port to react-Control
    rpcReactCtrl.open(("/"+name+"/reactController/rpc:o").c_str());
    std::string reactCtrlRPC = "/reactController/rpc:i";
    connectedReactCtrl = yarp::os::Network::connect(rpcReactCtrl.getName().c_str(), reactCtrlRPC);
    while (!connectedReactCtrl)
    {
        connectedReactCtrl = yarp::os::Network::connect(rpcReactCtrl.getName().c_str(), reactCtrlRPC);
        yInfo()<<"Waiting connection to reactController...";
        Time::delay(1.0);
    }

    // ARE
    rpcARE.open(("/"+name+"/ARE/cmd:io").c_str());
    std::string actionsRenderingEngineRPC = "/actionsRenderingEngine/cmd:io";
    connectedARE = yarp::os::Network::connect(rpcARE.getName().c_str(), actionsRenderingEngineRPC);
    if (connectedARE)
        yInfo()<<"Connected to ARE!";
    else
        yError() <<"Cannot connect to ARE!";

    // grasping with superquadric
    rpcGraspSQR.open(("/"+name+"/graspProcessor/rpc").c_str());
    std::string graspProcessorRPC = "/graspProcessor/rpc";
    connectedSQR = yarp::os::Network::connect(rpcGraspSQR.getName().c_str(), graspProcessorRPC);
    if (connectedSQR)
        yInfo()<<"Connected to Superquadric!";
    else
        yError() <<"Cannot connect to Superquadric!";

    // grasping with skeleton3D
    rpcSkeleton3D.open(("/"+name+"/skeleton3D/rpc").c_str());
    std::string skeleton3DRPC = "/skeleton3D/rpc";
    if (yarp::os::Network::connect(rpcSkeleton3D.getName().c_str(), skeleton3DRPC))
        yInfo()<<"Connected to skeleton3D!";
    else
        yError() <<"Cannot connect to skeleton3D!";

    // Torso Cartesian Controller

    yarp::os::Property OptT;
    OptT.put("robot",  robot);
    OptT.put("part",   "torso");
    OptT.put("device", "remote_controlboard");
    OptT.put("remote", "/"+robot+"/torso");
    OptT.put("local",  "/"+name +"/torso");
    if (!ddT.open(OptT))
    {
        yError("[collaboration]Could not open torso PolyDriver!");
        return false;
    }

    bool okT = 1;

    if (ddT.isValid())
    {
        okT = okT && ddT.view(iencsT);
        okT = okT && ddT.view(ivelT);
        okT = okT && ddT.view(iposT);
        okT = okT && ddT.view(imodT);
        okT = okT && ddT.view(ilimT);

    }
    iencsT->getAxes(&jntsT);
    encsT = new yarp::sig::Vector(jntsT,0.0);

    if (!okT)
    {
        yError("[collaboration]Problems acquiring torso interfaces!!!!");
        return false;
    }

    // Arm Cartesian Controller: for current pose checking
    Property optArm("(device cartesiancontrollerclient)");
    optArm.put("remote",("/"+robot+"/cartesianController/" + part).c_str());
    optArm.put("local",("/"+name+"/cart_ctrl/"+ part).c_str());

    if ((!ddA.open(optArm)) || (!ddA.view(icartA)))
    {
        yError(" [collaboration]could not open the Arm Cartesian Controller!");
        return false;
    }
    icartA -> storeContext(&contextArm);

    // Arm joint Controller: for grasping
    closedHandPos.resize(9,0.0);
    openHandPos.resize(9,0.0);
    midHandPos.resize(9,0.0);
    handVels.resize(9,0.0);

    Property optArm_joint("(device remote_controlboard)");
    optArm_joint.put("remote",("/"+robot+"/"+part).c_str());
    optArm_joint.put("local",("/"+name+"/arm/"+part).c_str());

    if ((!ddA_joint.open(optArm_joint)))
    {
        yError(" [collaboration]could not open the Arm Joints Controller!");
        return false;
    }

    bool okA = 1;

    if (ddA_joint.isValid())
    {
        okA = okA && ddA_joint.view(iencsA);
//        okA = okA && ddA_joint.view(ivelA);
        okA = okA && ddA_joint.view(iposA);
        okA = okA && ddA_joint.view(imodA);
        okA = okA && ddA_joint.view(ilimA);

    }
    iencsA->getAxes(&jntsA);
    encsA = new yarp::sig::Vector(jntsA,0.0);

    if (!okA)
    {
        yError("[collaboration]Problems acquiring Arm joint interfaces!!!!");
        return false;
    }

    Bottle &bGrasp=rf.findGroup("grasp");
    bGrasp.setMonitor(rf.getMonitor());
    if (!getGraspConfig(bGrasp,openHandPos, midHandPos, closedHandPos, handVels))
    {
        yError ("Error in parameters section 'grasp'");
        return false;
    }

    // Gaze controller
    Property OptGaze;
    OptGaze.put("device","gazecontrollerclient");
    OptGaze.put("remote","/iKinGazeCtrl");
    OptGaze.put("local","/"+name+"/gaze");

    if ((!ddG.open(OptGaze)) || (!ddG.view(igaze)))
    {
        yError(" could not open the Gaze Controller!");
        return false;
    }

    igaze -> storeContext(&contextGaze);
    igaze -> setSaccadesMode(false);
    igaze -> setNeckTrajTime(0.75);
    igaze -> setEyesTrajTime(0.5);

    homeAng.resize(3,0.0);
    homeAng[0]=+0.0;   // azimuth-relative component wrt the current configuration [deg]
    homeAng[1]=-25.0;   // elevation-relative component wrt the current configuration [deg]
    homeAng[2]=+0.0;   // vergence-relative component wrt the current configuration [deg]

    igaze -> lookAtAbsAnglesSync(homeAng);
    igaze -> waitMotionDone(0.1,5.0);

    igaze -> stopControl();

    Vector curAng(3,0.0);
    igaze->getAngles(curAng);
    yDebug("current angle %s",curAng.toString(3,3).c_str());

    // rpc port
    rpcPort.open("/"+name+"/rpc");
    attach(rpcPort);

    // home position for reactCtrl
    homePosL.resize(3, 0.05);
    homePosL[0] = -0.2;
    homePosL[1] = -0.3;

    homePosR.resize(3, 0.05);
    homePosR[0] = -0.2;
    homePosR[1] = +0.3;

    basket.resize(3, 0.0);
    basket[0] = 0.2;
    basket[1] = 0.4;
    basket[2] = 0.05;
    // TODO check this

    isHoldingObject = false;

    return true;
}

bool    collaboration::interruptModule()
{
    yDebug("[%s] Interupt module",name.c_str());

    homeARE();
    yDebug("[%s] Remove partner", name.c_str());
    opc->checkout();
    opc->interrupt();
    rpcPort.interrupt();
    rpcARE.interrupt();
    rpcReactCtrl.interrupt();

    return true;
}

bool    collaboration::close()
{
    yDebug("[%s] closing module",name.c_str());
    rpcPort.close();
    opc->close();
    rpcARE.close();
    rpcReactCtrl.close();

    yInfo("Closing gaze controller..");
    Vector ang(3,0.0);
    igaze -> lookAtAbsAngles(ang);
    igaze -> restoreContext(contextGaze);
    igaze -> stopControl();
    ddG.close();

    delete encsT; encsT = NULL;
    ddT.close();

    delete encsA; encsA = NULL;
    ddA.close();
    ddA_joint.close();

    return true;
}

bool    collaboration::attach(RpcServer &source)
{
    return this->yarp().attachAsServer(source);
//    return true;
}
double  collaboration::getPeriod()
{
    return period;
}

bool    collaboration::updateModule()
{
    // add update the object position when robot is holding it: after receiving from human and grasping from table
    // TODO: if (holdObject) opc->commit(obj);
//    if (isHoldingObject)
//    {
//        Vector x_cur(3,0.0), o_cur(4,0.0);
//        if (icartA->getPose(x_cur, o_cur))
//            updateHoldingObj(x_cur, o_cur);
//    }
    return true;
}

bool    collaboration::moveReactPPS(const string &target, const string &arm, const double &timeout,
                                    const bool &isTargetHuman)
{
    Vector targetPos(3,0.0);
    // get object pos with name <-- target
    if (!isTargetHuman)
    {
        Entity* e = opc->getEntity(target, true);
        Object *o;
        if(e) {
            o = dynamic_cast<Object*>(e);
        }
        else {
            yError() << target << " is not an Entity";
            return false;
        }
        if(!o) {
            yError() << "Could not cast" << e->name() << "to Object";
            return false;
        }

        o->m_value = -1.0;
        targetPos = o->m_ego_position;
        opc->commit(o);
    }
    else
    {
        Entity* e = opc->getEntity(partner_default_name, true);
        Agent* a;
        if(e) {
            a = dynamic_cast<Agent*>(e);
        }
        else {
            yError() << target << " is not an Entity";
            return false;
        }
        if(!a) {
            yError() << "Could not cast" << e->name() << "to Agent";
            return false;
        }
        targetPos = a->m_body.m_parts[target.c_str()];
    }


    Vector offset(3,0.0);
    offset[0] += 0.05; // 5cm closer to robot
    if (arm=="right")
        offset[1] +=0.05;   //5cm on the right
    else if (arm=="left")
        offset[1] -=0.05;   //5cm on the left

    if (checkPosReachable(targetPos+offset, arm))
        return moveReactPPS(targetPos+offset, arm, timeout);
    else
    {
        yDebug("%s is unreachable", (targetPos+offset).toString(3,3).c_str());
        return false;
    }
}

bool    collaboration::moveReactPPS(const Vector &pos, const string &arm, const double &timeout)
{
    // TODO: arm to decide which hand
    bool ok=false, done=false, completed=false;

    yDebug () << "ReactCtrl::set_xd start with " << arm.c_str();
    Bottle cmd, bPos, rep;
    cmd.addString("set_xd");
    for (int8_t i=0; i<pos.size(); i++)
        bPos.addDouble(pos[i]);
    cmd.addList() = bPos;

    yDebug("Command sent to ReactCtrl: %s",cmd.toString().c_str());
    if (rpcReactCtrl.write(cmd, rep))
        ok = rep.get(0).asBool();

    double checkTime, start=Time::now();
    while (ok && !done)
    {
        Vector x_cur(3,0.0), o_cur(4,0.0);
        if (icartA->getPose(x_cur, o_cur) && isHoldingObject)
            updateHoldingObj(x_cur, o_cur);
        Time::delay(period);
        checkTime = Time::now();
        completed = (norm(x_cur-pos)<=posTol);
        done =  completed || ((checkTime-start)>=timeout);
        if (done)
        {
            yDebug("xf= %s; x_cur= %s",pos.toString(3,3).c_str(),x_cur.toString(3,3).c_str());
            yDebug("checktime %f",checkTime-start);
        }
    }
    if (checkTime-start+1.0<=timeout)
        Time::delay(1.0);
    stop_React();

    return (ok);
}

bool    collaboration::homeARE()
{
    yDebug() << "ARE::home start";

    Bottle cmd, rep;
    bool ret = false;

    cmd.addVocab(Vocab::encode("home"));
    cmd.addString("all");

    yDebug("Command sent to ARE: %s",cmd.toString().c_str());

    if (rpcARE.write(cmd, rep))
        ret = (rep.get(0).asVocab()==Vocab::encode("ack"));

    yDebug() << "[homeARE] Reply from ARE: " << rep.toString();
    return ret;
}

bool    collaboration::stopReactPPS()
{
    yDebug () << "ReactCtrl::stop start";
    Bottle cmd, rep;
    cmd.addString("stop");

    yDebug("Command sent to ReactCtrl: %s",cmd.toString().c_str());
    if (rpcReactCtrl.write(cmd, rep))
        return rep.get(0).asBool();
    else
        return false;
}

bool    collaboration::takeARE(const string &target, const string &arm)
{
    // get object pos with name <-- target
    yDebug() << "ARE::take start";

    Entity* e = opc->getEntity(target, true);
    Object *o;
    if(e) {
        o = dynamic_cast<Object*>(e);
    }
    else {
        yError() << target << " is not an Entity";
        return false;
    }
    if(!o) {
        yError() << "Could not cast" << e->name() << "to Object";
        return false;
    }
    manipulatingObj = o;

    Vector targetPos = o->m_ego_position;
    // TODO: check if use takeARE or graspARE
    if (checkPosReachable(targetPos, arm))
//        return takeARE(targetPos, arm);
//        return graspARE(targetPos, arm);
        return graspRaw(targetPos, arm);
    else
    {
        yDebug("%s is unreachable", targetPos.toString(3,3).c_str());
        return false;
    }
}

bool    collaboration::takeARE(const Vector &pos, const string &arm)
{
    Bottle cmd, target, rep;
    bool ret = false;

    cmd.addVocab(Vocab::encode("take"));
    target.addString("cartesian");
    for (int8_t i=0; i<pos.size(); i++)
        target.addDouble(pos[i]);
    cmd.addList() = target;
    cmd.addString(arm.c_str());
    cmd.addString("side");
    cmd.addString("still");
    cmd.addString("no_head");

    yDebug("Command sent to ARE: %s",cmd.toString().c_str());

    if (rpcARE.write(cmd, rep))
        ret = (rep.get(0).asVocab()==Vocab::encode("ack"));

    yDebug() << "[takeARE] Reply from ARE: " << rep.toString();
    return ret;
}

bool    collaboration::graspARE(const Vector &pos, const string &arm)
{
    Bottle cmd, target, rep;
    bool ret = false;

    cmd.addVocab(Vocab::encode("grasp"));
    target.addString("cartesian");
    for (int8_t i=0; i<pos.size(); i++)
        target.addDouble(pos[i]);

//    Vector rpy(3,0.0);
//    rpy[0] = 77.0*M_PI/180.0;
//    rpy[0] = -4.0*M_PI/180.0;
//    rpy[2] = 170.0*M_PI/180.0;
//    Vector rot = dcm2axis(rpy2dcm(rpy));
    Matrix R(3,3);
    // pose x-axis y-axis z-axis: palm inward, pointing forward
    R(0,0)=-1.0; R(0,1)= 0.0; R(0,2)= 0.0; // x-coordinate
    R(1,0)= 0.0; R(1,1)= 0.0; R(1,2)=-1.0; // y-coordinate
    R(2,0)= 0.0; R(2,1)=-1.0; R(2,2)= 0.0; // z-coordinate

    if (arm=="left")
        R(1,2) = 1.0;

    Vector rot = dcm2axis(R);
    yDebug("grasp rot=%s", rot.toString(3,3).c_str());
    for (int8_t i=0; i<rot.size(); i++)
        target.addDouble(rot[i]);

    cmd.addList() = target;
    cmd.addString(arm.c_str());
    cmd.addString("still");
    cmd.addString("no_head");

    yDebug("Command sent to ARE: %s",cmd.toString().c_str());
    if (rpcARE.write(cmd, rep))
        ret = (rep.get(0).asVocab()==Vocab::encode("ack"));

    yDebug() << "[graspARE] Reply from ARE: " << rep.toString();
    return ret;

}

bool    collaboration::graspRaw(const Vector &pos, const string &arm)
{
//    return (reachArm(pos,arm) && (closeHand(arm,10.0)));
    icartA->storeContext(&contextReactCtrl);
    bool ok = reachArm(pos, arm, 5.0);
    if (ok)
    {
        yDebug("[graspRaw] Done reaching. Let wait for 1s...");
        Time::delay(1.0);
        ok = closeHand(arm,6.0);
        icartA->restoreContext(contextReactCtrl);
        icartA->deleteContext(contextReactCtrl);
        return ok;
    }
    else
    {
        yError("[graspRaw] Failed in reaching");
        icartA->restoreContext(contextReactCtrl);
        icartA->deleteContext(contextReactCtrl);
        return ok;
    }
}

bool    collaboration::reachArm(const Vector &pos, const string &arm, const double &timeout)
{
    // TODO: use param arm
    Matrix R(3,3);
    // pose x-axis y-axis z-axis: palm inward, pointing forward
    R(0,0)=-1.0; R(0,1)= 0.0; R(0,2)= 0.0; // x-coordinate
    R(1,0)= 0.0; R(1,1)= 0.0; R(1,2)=-1.0; // y-coordinate
    R(2,0)= 0.0; R(2,1)=-1.0; R(2,2)= 0.0; // z-coordinate

    if (arm=="left")
        R(1,2) = 1.0;

    Vector rot = dcm2axis(R);
    icartA->restoreContext(contextArm);
    icartA->setTrackingMode(false);
    icartA->setTrajTime(1.0);
    icartA->setInTargetTol(0.01);
    icartA->goToPose(pos,rot);
//    icartA->waitMotionDone(0.1,timeout);

    bool done = false;

    double t0=Time::now();
    while (!done && (Time::now()-t0<timeout))
    {
        icartA->checkMotionDone(&done);
        Time::delay(0.1);
    }
    icartA->stopControl();
    return done;
}

bool    collaboration::moveFingers(const int &action, const string &arm, const double &timeout)
{
    // TODO: use param arm
    Vector *pos=NULL;

    switch (action)
    {
    case OPENHAND:
        pos = &openHandPos;
        break;
    case CLOSEHAND:
        pos = &closedHandPos;
        break;
    default:
        return false;
    }
    for (size_t j=0; j<handVels.length(); j++)
        imodA->setControlMode(7+j,VOCAB_CM_POSITION);

    bool done = moveFingersToWp(midHandPos, timeout/2.0);
    if (!done)
    {
        yError("Cannot finish move fingers to mid position!");
//        return false;
    }
    Time::delay(0.5);
    return moveFingersToWp(*pos, timeout/2.0);
}

bool    collaboration::moveFingersToWp(const Vector &Wp, const double &timeout)
{
    yDebug("Move fingers to [%s]!!",Wp.toString(3,1).c_str());
    if (Wp.size()==handVels.size())
    {
        for (size_t j=0; j<handVels.length(); j++)
        {
            int k=7+j;
            iposA->setRefSpeed(k,handVels[j]);
            iposA->positionMove(k,Wp[j]);
        }
        bool done = false;

        double t0=Time::now();
        while (!done && (Time::now()-t0<timeout))
        {
            iposA->checkMotionDone(&done);
            Time::delay(0.1);
        }
        return done;
        }
    else
        return false;
}

bool    collaboration::closeHand(const string &arm, const double &timeout)
{
    yDebug("Closing hand!!");
    return moveFingers(CLOSEHAND, arm, timeout);
}

bool    collaboration::openHand(const string &arm, const double &timeout)
{
    yDebug("Opening hand!!");
    return moveFingers(OPENHAND, arm, timeout);
}

bool    collaboration::getGraspConfig(const Bottle &b, Vector &openPos, Vector &midPos,
                                      Vector &closedPos, Vector &vels)
{
    bool ret = true;

    if (b.check("open_hand","Getting openHand pos"))
    {
        Bottle &grp=b.findGroup("open_hand");
        int sz=grp.size()-1;
        int len=sz>9?9:sz;

        for (int i=0; i<len; i++)
            openPos[i]=grp.get(1+i).asDouble();
    }
    else
    {
        yError("Missing 'open_hand' parameter");
        ret = false;
    }

    if (b.check("mid_hand","Getting midHand pos"))
    {
        Bottle &grp=b.findGroup("mid_hand");
        int sz=grp.size()-1;
        int len=sz>9?9:sz;

        for (int i=0; i<len; i++)
            midPos[i]=grp.get(1+i).asDouble();
    }
    else
    {
        yError("Missing 'mid_hand' parameter");
        ret = false;
    }

    if (b.check("close_hand","Getting closeHand pos"))
    {
        Bottle &grp=b.findGroup("close_hand");
        int sz=grp.size()-1;
        int len=sz>9?9:sz;

        for (int i=0; i<len; i++)
            closedPos[i]=grp.get(1+i).asDouble();
    }
    else
    {
        yError("Missing 'close_hand' parameter");
        ret = false;
    }
    if (b.check("vels_hand","Getting hand vels"))
    {
        Bottle &grp=b.findGroup("vels_hand");
        int sz=grp.size()-1;
        int len=sz>9?9:sz;

        for (int i=0; i<len; i++)
            vels[i]=grp.get(1+i).asDouble();
    }
    else
    {
        yError("Missing 'vels_hand' parameter");
        ret = false;
    }
    return ret;
}

bool    collaboration::graspOnTable(const string &target, const string &arm)
{
    if (connectedSQR)
    {
        Bottle cmd, rep;
        bool ret = false;

        cmd.addString("grasp_pose");
        cmd.addString(target.c_str());
        cmd.addString(arm.c_str());

        yDebug("Command sent to graspProcessor: %s",cmd.toString().c_str());

        if (rpcGraspSQR.write(cmd, rep))
            ret = (rep.get(0).asVocab()==Vocab::encode("ack"));

        yDebug() << "[graspOnTable] Reply from graspProcessor: " << rep.toString();
        return ret;
    }
    else
        return false;
}


bool    collaboration::giveARE(const string &target, const string &arm)
{
    // target should be human empty hand :)
    yDebug() << "ARE::give start";

    Entity* e = opc->getEntity(partner_default_name, true);
    Agent* a;
    if(e) {
        a = dynamic_cast<Agent*>(e);
    }
    else {
        yError() << target << " is not an Entity";
        return false;
    }
    if(!a) {
        yError() << "Could not cast" << e->name() << "to Agent";
        return false;
    }
    Vector pos = a->m_body.m_parts[target.c_str()];
    pos[0] = max(pos[0], -0.35);
    pos[2] = 0.2;
    if (pos[1]>=0)
        pos[1] = min(pos[1], 0.1);
    else
        pos[1] = max(pos[1], -0.3);


    Vector offset(3,0.0);
    offset[0] += 0.05; // 5cm closer to robot

    if (checkPosReachable(pos+offset, arm))
        return giveARE(pos+offset, arm);
    else
    {
        yDebug("%s is unreachable", (pos+offset).toString(3,3).c_str());
        return false;
    }
}

bool    collaboration::giveARE(const Vector &pos, const string &arm)
{
    Bottle cmd, target, rep;
    bool ret = false;

    cmd.addVocab(Vocab::encode("give"));
    target.addString("cartesian");
    for (int8_t i=0; i<pos.size(); i++)
        target.addDouble(pos[i]);
    cmd.addList() = target;
    cmd.addString(arm.c_str());
    cmd.addString("side");
    cmd.addString("still");
    cmd.addString("no_head");

    yDebug("Command sent to ARE: %s",cmd.toString().c_str());

    if (rpcARE.write(cmd, rep))
        ret = (rep.get(0).asVocab()==Vocab::encode("ack"));

    yDebug() << "[giveARE] Reply from ARE: " << rep.toString();
    return ret;
}

bool    collaboration::dropARE(const Vector &pos, const string &arm)
{
    Bottle cmd, target, rep;
    bool ret = false;

    cmd.addVocab(Vocab::encode("drop"));
    cmd.addString("over");
    target.addString("cartesian");
    for (int8_t i=0; i<pos.size(); i++)
        target.addDouble(pos[i]);
    cmd.addList() = target;
    cmd.addString(arm.c_str());
    cmd.addString("still");


    yDebug("Command sent to ARE: %s",cmd.toString().c_str());

    if (rpcARE.write(cmd, rep))
        ret = (rep.get(0).asVocab()==Vocab::encode("ack"));

    yDebug() << "[dropARE] Reply from ARE: " << rep.toString();
    return ret;
}

bool    collaboration::checkPosReachable(const Vector &pos, const string &arm)
{
    bool ok = (pos[0] >= workspaceX); //workspaceX is negative
    ok = ok && (pos[2] <= workspaceZ_high) && (pos[2] >= workspaceZ_low);
    if (arm=="left")
    {
        ok = ok && (pos[1] >= -workspaceY) && (pos[1] <=  0.5*workspaceY);
    }
    else if (arm=="right")
    {
        ok = ok && (pos[1] >= -0.5*workspaceY) && (pos[1] <=  workspaceY);
    }
    else
        return false;
    yDebug("targetPos = %s",pos.toString(3,3).c_str());
    yDebug("workspace x= %f, y=%f, z=[%f, %f]", workspaceX, workspaceY, workspaceZ_low, workspaceZ_high);
    return ok;
}

bool    collaboration::lookAtHome(const Vector &ang, const double &timeout)
{
    igaze -> restoreContext(contextGaze);
    igaze -> lookAtAbsAnglesSync(ang);
    igaze -> waitMotionDone(0.1,timeout);

    igaze -> stopControl();
}

bool    collaboration::updateHoldingObj(const Vector &x_EE, const Vector &o_EE)
{
    Vector x_obj(3,0.0);
    Matrix H_e0=zeros(4,4), H_oe=eye(4), H_o0(4,4);
    H_e0 = axis2dcm(o_EE);
    H_e0.setSubcol(x_EE,0,3);

    H_oe(2,3) = manipulatingObj->m_dimensions[2];

    H_o0 = H_oe*H_e0;
    x_obj = H_o0.subcol(0,3,3);
    manipulatingObj->m_ego_position = x_obj;
    manipulatingObj->m_value = -1.0;
    opc->commit(manipulatingObj);
}

bool    collaboration::setHumanValence(const double &valence, const string &_human_part)
{
    Bottle cmd, rep;
    bool ret = false;

    cmd.addString("set_valence_hand");
    cmd.addDouble(valence);
    cmd.addString(_human_part.c_str());

    yDebug("Command sent to skeleton3D: %s",cmd.toString().c_str());

    if (rpcSkeleton3D.write(cmd, rep))
        ret = (rep.get(0).asBool());

    yDebug() << "[reduceHumanValence] Reply from skeleton3D: " << rep.toString();
    return ret;
}
