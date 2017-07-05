/*
 * Copyright: (C) 2017 iCub Facility - Istituto Italiano di Tecnologia
 * Author: Nguyen Dong Hai Phuong <phuong.nguyen@iit.it>
 * website: www.robotcub.org
 * author website: https://github.com/towardthesea
 *
 * Permission is granted to copy, distribute, and/or modify this program
 * under the terms of the GNU General Public License, version 2 or any
 * later version published by the Free Software Foundation.
 *
 * A copy of the license can be found at
 * http://www.robotcub.org/icub/license/gpl.txt
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
*/
#include <yarp/os/all.h>
#include <yarp/os/RpcServer.h>
#include <yarp/os/ResourceFinder.h>
#include <yarp/os/RFModule.h>
#include <yarp/os/Network.h>
#include "vtCalib.h"

using namespace yarp::os;

int main(int argc, char * argv[])
{
    Network yarp;

    ResourceFinder moduleRF;
    moduleRF.setVerbose(false);
    moduleRF.setDefaultContext("skeleton3D");
    moduleRF.setDefaultConfigFile("visuoTactileCalib.ini");
    moduleRF.configure(argc,argv);

    if (moduleRF.check("help"))
    {
        yInfo(" ");
        yInfo("Options:");
        yInfo("   --context     path:  where to find the called resource (default skeleton3D).");
        yInfo("   --from        from:  the name of the .ini file (default yetAnotherAvoidance.ini).");
        yInfo("   --name        name:  the name of the module (default yetAnotherAvoidance).");
        yInfo(" ");
        return 0;
    }

    if (!yarp.checkNetwork())
    {
        yError("No Network!!!");
        return -1;
    }

    vtCalib calibrator;
    return calibrator.runModule(moduleRF);
}
