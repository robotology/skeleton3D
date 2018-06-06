#include "collaboration.h"

bool    collaboration::configure(ResourceFinder &rf)
{
    name=rf.check("name",Value("icubCollaboration")).asString().c_str();
    period=rf.check("period",Value(0.0)).asDouble();    // as default, update module as soon as receiving new parts from skeleton2D

    // OPC client
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
        yInfo()<<"Waiting connection to reactController...";
        Time::delay(1.0);
    }

    // ARE
    rpcARE.open(("/"+name+"/ARE/cmd:io").c_str());
    std::string actionsRenderingEngineRPC = "/actionsRenderingEngine/cmd:io";
    connectedARE = yarp::os::Network::connect(rpcARE.getName().c_str(), actionsRenderingEngineRPC);

    // TODO: Cartesian Controller

    // rpc port
    rpcPort.open("/"+name+"/rpc");
    attach(rpcPort);

    return true;
}

bool    collaboration::interruptModule()
{
    yDebug("[%s] Interupt module",name.c_str());

    yDebug("[%s] Remove partner", name.c_str());
    opc->checkout();
    opc->interrupt();
    rpcPort.interrupt();

    return true;
}

bool    collaboration::close()
{
    yDebug("[%s] closing module",name.c_str());
    rpcPort.close();
    opc->close();
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
}

bool    collaboration::moveReactPPS(const Vector &pos, const string &arm)
{
    // TODO: arm to decide which hand

    Bottle cmd, bPos;
    cmd.addString("set_xd");
    for (int8_t i=0; i<pos.size(); i++)
        bPos.addDouble(pos[i]);
    cmd.addList() = bPos;
    return rpcReactCtrl.write(cmd);
}

bool    collaboration::stopReactPPS()
{
    Bottle cmd;
    cmd.addString("stop");
    return rpcReactCtrl.write(cmd);
}
