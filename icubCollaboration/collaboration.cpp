#include "collaboration.h"

bool    collaboration::configure(ResourceFinder &rf)
{
    name=rf.check("name",Value("icubCollaboration")).asString().c_str();
    robot=rf.check("robot",Value("icub")).asString().c_str();
    period=rf.check("period",Value(0.0)).asDouble();    // as default, update module as soon as receiving new parts from skeleton2D

    // Workspace
    workspaceX=rf.check("workspaceX",Value(-0.4)).asDouble();
    workspaceY=rf.check("workspaceY",Value(0.25)).asDouble();
    workspaceZ_low=rf.check("workspaceZ_low",Value(-0.1)).asDouble();
    workspaceZ_high=rf.check("workspaceZ_high",Value(0.2)).asDouble();

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

    // TODO: Cartesian Controller

    yarp::os::Property OptT;
    OptT.put("robot",  robot);
    OptT.put("part",   "torso");
    OptT.put("device", "remote_controlboard");
    OptT.put("remote", "/"+robot+"/torso");
    OptT.put("local",  "/"+name +"/torso");
    if (!ddT.open(OptT))
    {
        yError("[reactCtrlThread]Could not open torso PolyDriver!");
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
        yError("[reactCtrlThread]Problems acquiring torso interfaces!!!!");
        return false;
    }

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
    homeAng[1]=-20.0;   // elevation-relative component wrt the current configuration [deg]
    homeAng[2]=+0.0;   // vergence-relative component wrt the current configuration [deg]

    igaze -> lookAtAbsAnglesSync(homeAng);
    igaze -> waitMotionDone(0.1,5.0);

    Vector curAng(3,0.0);
    igaze->getAngles(curAng);
    yDebug("current angle %s",curAng.toString(3,3).c_str());

    // rpc port
    rpcPort.open("/"+name+"/rpc");
    attach(rpcPort);

    // home position for reactCtrl
    homePosL.resize(3, 0.05);
    homePosL[0] = -0.2;
    homePosL[1] = -0.2;

    homePosR.resize(3, 0.05);
    homePosR[0] = -0.2;
    homePosR[1] = +0.2;

    basket.resize(3, 0.0);
    // TODO set this

    return true;
}

bool    collaboration::interruptModule()
{
    yDebug("[%s] Interupt module",name.c_str());

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
    return true;
}

bool    collaboration::moveReactPPS(const string &target, const string &arm)
{
    // get object pos with name <-- target
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

    Vector offset(3,0.0);
    offset[0] += 0.05; // 5cm closer to robot

    Vector targetPos = o->m_ego_position;
    if (checkPosReachable(targetPos+offset, arm))
        return moveReactPPS(targetPos+offset, arm);
    else
    {
        yDebug("%s is unreachable", (targetPos+offset).toString(3,3).c_str());
        return false;
    }
}

bool    collaboration::moveReactPPS(const Vector &pos, const string &arm)
{
    // TODO: arm to decide which hand

    yDebug () << "ReactCtrl::set_xd start";
    Bottle cmd, bPos, rep;
    cmd.addString("set_xd");
    for (int8_t i=0; i<pos.size(); i++)
        bPos.addDouble(pos[i]);
    cmd.addList() = bPos;

    yDebug("Command sent to ReactCtrl: %s",cmd.toString().c_str());
    if (rpcReactCtrl.write(cmd, rep))
        return rep.get(0).asBool();
    else
        return false;
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

    Vector targetPos = o->m_ego_position;
    // TODO: check if use takeARE or graspARE
    if (checkPosReachable(targetPos, arm))
        return takeARE(targetPos, arm);
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

    Vector rpy(3,0.0);
    rpy[1] = -25.0*M_PI/180.0;
    Vector rot = dcm2axis(rpy2dcm(rpy));
    for (int8_t i=0; i<rot.size(); i++)
        target.addDouble(rot[i]);

    cmd.addList() = target;
    cmd.addString(arm.c_str());
    cmd.addString("still");

    yDebug("Command sent to ARE: %s",cmd.toString().c_str());
    if (rpcARE.write(cmd, rep))
        ret = (rep.get(0).asVocab()==Vocab::encode("ack"));

    yDebug() << "[graspARE] Reply from ARE: " << rep.toString();
    return ret;

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
    yDebug("targetPos = %s",pos.toString(3,3).c_str());
    yDebug("workspace x= %f, y=%f, z=[%f, %f]", workspaceX, workspaceY, workspaceZ_low, workspaceZ_high);

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

    yDebug("Command sent to ARE: %s",cmd.toString().c_str());

    if (rpcARE.write(cmd, rep))
        ret = (rep.get(0).asVocab()==Vocab::encode("ack"));

    yDebug() << "[takeARE] Reply from ARE: " << rep.toString();
    return ret;
}

bool    collaboration::checkPosReachable(const Vector &pos, const string &arm)
{
    bool ok = (pos[0] >= workspaceX); //workspaceX is negative
    ok = ok && (pos[2] <= workspaceZ_high) && (pos[2] >= workspaceZ_low);
    if (arm=="left")
    {
        ok = ok && (pos[1] >= -workspaceY);
    }
    else if (arm=="right")
    {
        ok = ok && (pos[1] <=  workspaceY);
    }
    else
        return false;
    return ok;
}
