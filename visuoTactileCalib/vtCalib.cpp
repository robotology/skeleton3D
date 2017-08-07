#include "vtCalib.h"

#define RESP_GAIN_FOR_SKINGUI 100 //To amplify PPS activations from <0,1> to <0,100>
#define PPS_AGGREG_ACT_THRESHOLD 0.2 //Threshold for aggregated events per skin part

bool    vtCalib::detectContact(iCub::skinDynLib::skinContactList *_sCL, int &idx,
                               std::vector <unsigned int> &idv)
{
    // Search for a suitable contact. It has this requirements:
    //   1. it has to be higher than SKIN_THRES
    //   2. more than two taxels should be active for that contact (in order to avoid spikes)
    //   3. it should be in the proper skinpart (forearms and hands)
    //   4. it should activate one of the taxels used by the module
    //      (e.g. the fingers will not be considered)
    for(iCub::skinDynLib::skinContactList::iterator it=_sCL->begin(); it!=_sCL->end(); it++)
    {
        idv.clear();
        if( it -> getPressure() > SKIN_THRES && (it -> getTaxelList()).size() > 2 )
        {
            for (int i = 0; i < iCubSkinSize; i++)
            {
                if (SkinPart_s[it -> getSkinPart()] == iCubSkin[i].name)
                {
                    idx = i;
                    std::vector <unsigned int> txlList = it -> getTaxelList();

                    bool itHasBeenTouched = false;

                    getRepresentativeTaxels(txlList, idx, idv);

                    if (idv.size()>0)
                    {
                        itHasBeenTouched = true;
                    }

                    if (itHasBeenTouched)
                    {
                        if (verbosity>=1)
                        {
                            printMessage(1,"Contact! Skin part: %s\tTaxels' ID: ",iCubSkin[i].name.c_str());
                            for (size_t i = 0; i < idv.size(); i++)
                                printf("\t%i",idv[i]);

                            printf("\n");
                        }
                        yInfo("Contact! Skin part: %s\t Taxels' ID: ",iCubSkin[i].name.c_str());
                        for (size_t j=0; j<idv.size(); j++)
                        {
                            yDebug("iCubSkin[%i].taxels.size() = %lu",i,iCubSkin[i].taxels.size());
                            for (size_t k=0; k<iCubSkin[i].taxels.size(); k++)
                                if (iCubSkin[i].taxels[k]->getID() == idv[j])
                                {
                                    Vector contact(3,0.0);
                                    contact = iCubSkin[i].taxels[k]->getWRFPosition();
                                    yInfo("\t%i, WRFPos %s ", idv[j], contact.toString().c_str());
                                    contactPts.push_back(contact);
                                }
                        }

                        return true;
                    }
                }
            }
        }
    }
    return false;
}

bool    vtCalib::setTaxelPosesFromFile(const string filePath, skinPartPWE &sP)
{
    string line;
    ifstream posFile;
    yarp::sig::Vector taxelPos(3,0.0);
    yarp::sig::Vector taxelNrm(3,0.0);
    yarp::sig::Vector taxelPosNrm(6,0.0);

    string filename = strrchr(filePath.c_str(), '/');
    filename = filename.c_str() ? filename.c_str() + 1 : filePath.c_str();

    // Assign the name and version of the skinPart according to the filename (hardcoded)
    if      (filename == "left_forearm_mesh.txt")    { sP.setName(SkinPart_s[SKIN_LEFT_FOREARM]);  sP.setVersion("V1");   }
    else if (filename == "left_forearm_nomesh.txt")  { sP.setName(SkinPart_s[SKIN_LEFT_FOREARM]);  sP.setVersion("V1");   }
    else if (filename == "left_forearm_V2.txt")      { sP.setName(SkinPart_s[SKIN_LEFT_FOREARM]);  sP.setVersion("V2");   }
    else if (filename == "right_forearm_mesh.txt")   { sP.setName(SkinPart_s[SKIN_RIGHT_FOREARM]); sP.setVersion("V1");   }
    else if (filename == "right_forearm_nomesh.txt") { sP.setName(SkinPart_s[SKIN_RIGHT_FOREARM]); sP.setVersion("V1");   }
    else if (filename == "right_forearm_V2.txt")     { sP.setName(SkinPart_s[SKIN_RIGHT_FOREARM]); sP.setVersion("V2");   }
    else if (filename == "left_hand_V2_1.txt")       { sP.setName(SkinPart_s[SKIN_LEFT_HAND]);     sP.setVersion("V2.1"); }
    else if (filename == "right_hand_V2_1.txt")      { sP.setName(SkinPart_s[SKIN_RIGHT_HAND]);    sP.setVersion("V2.1"); }
    else
    {
        yError("[%s] Unexpected skin part file name: %s.\n",name.c_str(),filename.c_str());
        return false;
    }
    //filename = filename.substr(0, filename.find_last_of("_"));

    yarp::os::ResourceFinder rf;
    rf.setVerbose(false);
    rf.setDefaultContext("skinGui");            //overridden by --context parameter
    rf.setDefaultConfigFile(filePath.c_str()); //overridden by --from parameter
    if (!rf.configure(0,NULL))
    {
        yError("[%s] ResourceFinder was not configured correctly! Filename:",name.c_str());
        yError("%s",filename.c_str());
        return false;
    }
    rf.setVerbose(true);

    yarp::os::Bottle &calibration = rf.findGroup("calibration");
    if (calibration.isNull())
    {
        yError("[%s::setTaxelPosesFromFile] No calibration group found!",name.c_str());
        return false;
    }
//        printMessage(6,"[%s::setTaxelPosesFromFile] found %i taxels (not all of them are valid taxels).\n", name.c_str(),calibration.size()-1);

    sP.spatial_sampling = "triangle";
    // First item of the bottle is "calibration", so we should not use it
    int j = 0; //this will be for the taxel IDs
    for (int i = 1; i < calibration.size(); i++)
    {
        taxelPosNrm = vectorFromBottle(*(calibration.get(i).asList()),0,6);
        taxelPos = taxelPosNrm.subVector(0,2);
        taxelNrm = taxelPosNrm.subVector(3,5);
        j = i-1;   //! note that i == line in the calibration group of .txt file;  taxel_ID (j) == line nr (i) - 1
//            printMessage(10,"[vtRFThread::setTaxelPosesFromFile] reading %i th row: taxelPos: %s\n", i,taxelPos.toString(3,3).c_str());

        if (sP.name == SkinPart_s[SKIN_LEFT_FOREARM] || sP.name == SkinPart_s[SKIN_RIGHT_FOREARM])
        {
            // the taxels at the centers of respective triangles  -
            // e.g. first triangle of forearm arm is at lines 1-12, center at line 4, taxelID = 3
            if(  (j==3) || (j==15)  ||  (j==27) ||  (j==39) ||  (j==51) ||  (j==63) ||  (j==75) ||  (j==87) ||
                (j==99) || (j==111) || (j==123) || (j==135) || (j==147) || (j==159) || (j==171) || (j==183) || //end of full lower patch
                ((j==195) && (sP.version=="V2")) || (j==207) || ((j==231) && (sP.version=="V2")) || ((j==255) && (sP.version=="V1")) ||
                ((j==267) && (sP.version=="V2")) || (j==291) || (j==303) || ((j==315) && (sP.version=="V1")) || (j==339) || (j==351) )

            // if(  (j==3) ||  (j==39) || (j==207) || (j==255) || (j==291)) // Taxels that are evenly distributed throughout the forearm
                                                                         // in order to cover it as much as we can
            // if(  (j==3) ||  (j==15) ||  (j==27) || (j==183)) // taxels that are in the big patch but closest to the little patch (internally)
                                                                // 27 is proximal, 15 next, 3 next, 183 most distal
            // if((j==135) || (j==147) || (j==159) || (j==171))  // this is the second column, farther away from the stitch
                                                                 // 159 is most proximal, 147 is next, 135 next,  171 most distal
            // if((j==87) || (j==75)  || (j==39)|| (j==51)) // taxels that are in the big patch and closest to the little patch (externally)
            //                                              // 87 most proximal, 75 then, 39 then, 51 distal

            // if((j==27)  || (j==15)  || (j==3)   || (j==183) ||              // taxels used for the experimentations on the PLOS paper
            //    (j==135) || (j==147) || (j==159) || (j==171) ||
            //    (j==87)  || (j==75)  || (j==39)  || (j==51))

            // if((j==27)  || (j==15)  || (j==3)   || (j==183) ||              // taxels used for the experimentations on the IROS paper
            //    (j==87)  || (j==75)  || (j==39)  || (j==51))
            {
                sP.size++;
                if (modality=="1D")
                {
                    sP.taxels.push_back(new TaxelPWE1D(taxelPos,taxelNrm,j));
                }
                else
                {
                    sP.taxels.push_back(new TaxelPWE2D(taxelPos,taxelNrm,j));
                }
            }
            else
            {
                sP.size++;
            }
        }
        else if (sP.name == SkinPart_s[SKIN_LEFT_HAND])
        { //we want to represent the 48 taxels of the palm (ignoring fingertips) with 5 taxels -
         // manually marking 5 regions of the palm and selecting their "centroids" as the representatives
            if((j==99) || (j==101) || (j==109) || (j==122) || (j==134))
            {
                sP.size++;
                if (modality=="1D")
                {
                    sP.taxels.push_back(new TaxelPWE1D(taxelPos,taxelNrm,j));
                }
                else
                {
                    sP.taxels.push_back(new TaxelPWE2D(taxelPos,taxelNrm,j));
                }
            }
            else
            {
                sP.size++;
            }
        }
        else if (sP.name == SkinPart_s[SKIN_RIGHT_HAND])
        { //right hand has different taxel nr.s than left hand
            if((j==101) || (j==103) || (j==118) || (j==137) || (j==124))
            {
                sP.size++;
                if (modality=="1D")
                {
                    sP.taxels.push_back(new TaxelPWE1D(taxelPos,taxelNrm,j));
                }
                else
                {
                    sP.taxels.push_back(new TaxelPWE2D(taxelPos,taxelNrm,j));
                }
            }
            else
            {
                sP.size++;
            }
        }
    }

    initRepresentativeTaxels(sP);

    return true;
}

void    vtCalib::initRepresentativeTaxels(skinPart &sP)
{
    printMessage(6,"[%s::initRepresentativeTaxels] Initializing representative taxels for %s, version %s\n",name.c_str(),sP.name.c_str(),sP.version.c_str());
    int j=0; //here j will start from 0 and correspond to taxel ID
    list<unsigned int> taxels_list;
    if (sP.name == SkinPart_s[SKIN_LEFT_FOREARM] || sP.name == SkinPart_s[SKIN_RIGHT_FOREARM])
    {
        for (j=0;j<sP.size;j++)
        {
            //4th taxel of each 12, but with ID 3, j starting from 0 here, is the triangle midpoint
            sP.taxel2Repr.push_back(((j/12)*12)+3); //initialize all 384 taxels with triangle center as the representative
            //fill a map of lists here somehow
        }

        // set to -1 the taxel2Repr for all the taxels that don't exist
        if (sP.version == "V1")
        {
            for (j=192;j<=203;j++)
            {
                sP.taxel2Repr[j]=-1; //these taxels don't exist
            }
        }
        for (j=216;j<=227;j++)
        {
            sP.taxel2Repr[j]=-1; //these taxels don't exist
        }
        if (sP.version == "V1")
        {
            for (j=228;j<=239;j++)
            {
                sP.taxel2Repr[j]=-1; //these taxels don't exist
            }
        }
        for (j=240;j<=251;j++)
        {
            sP.taxel2Repr[j]=-1; //these taxels don't exist
        }
        if (sP.version == "V2")
        {
            for (j=252;j<=263;j++)
            {
                sP.taxel2Repr[j]=-1; //these taxels don't exist
            }
        }
        if (sP.version == "V1")
        {
            for (j=264;j<=275;j++)
            {
                sP.taxel2Repr[j]=-1; //these taxels don't exist
            }
        }
        for (j=276;j<=287;j++)
        {
            sP.taxel2Repr[j]=-1; //these taxels don't exist
        }
        if (sP.version == "V2")
        {
            for (j=312;j<=323;j++)
            {
                sP.taxel2Repr[j]=-1; //these taxels don't exist
            }
        }
        for (j=324;j<=335;j++)
        {
            sP.taxel2Repr[j]=-1; //these taxels don't exist
        }
        for (j=360;j<=383;j++)
        {
            sP.taxel2Repr[j]=-1; //these taxels don't exist
        }

        // Set up the inverse - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        for(j=0;j<=11;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[3] = taxels_list;

        taxels_list.clear();
        for(j=12;j<=23;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[15] = taxels_list;

        taxels_list.clear();
        for(j=24;j<=35;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[27] = taxels_list;

        taxels_list.clear();
        for(j=36;j<=47;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[39] = taxels_list;

        taxels_list.clear();
        for(j=48;j<=59;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[51] = taxels_list;

        taxels_list.clear();
        for(j=60;j<=71;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[63] = taxels_list;

        taxels_list.clear();
        for(j=72;j<=83;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[75] = taxels_list;

        taxels_list.clear();
        for(j=84;j<=95;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[87] = taxels_list;

        taxels_list.clear();
        for(j=96;j<=107;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[99] = taxels_list;

        taxels_list.clear();
        for(j=108;j<=119;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[111] = taxels_list;

        taxels_list.clear();
        for(j=120;j<=131;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[123] = taxels_list;

        taxels_list.clear();
        for(j=132;j<=143;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[135] = taxels_list;

        taxels_list.clear();
        for(j=144;j<=155;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[147] = taxels_list;

        taxels_list.clear();
        for(j=156;j<=167;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[159] = taxels_list;

        taxels_list.clear();
        for(j=168;j<=179;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[171] = taxels_list;

        taxels_list.clear();
        for(j=180;j<=191;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[183] = taxels_list;
        //up to here - lower (full) patch on forearm

        //from here - upper patch with many dummy positions on the port - incomplete patch
        if (sP.version == "V2")
        {
            taxels_list.clear();
            for(j=192;j<=203;j++)
            {
                taxels_list.push_back(j);
            }
            sP.repr2TaxelList[195] = taxels_list;
        }

        taxels_list.clear();
        for(j=204;j<=215;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[207] = taxels_list;

        if (sP.version == "V2")
        {
            taxels_list.clear();
            for(j=228;j<=237;j++)
            {
                taxels_list.push_back(j);
            }
            sP.repr2TaxelList[231] = taxels_list;
        }

        if (sP.version == "V1")
        {
            taxels_list.clear();
            for(j=252;j<=263;j++)
            {
                taxels_list.push_back(j);
            }
            sP.repr2TaxelList[255] = taxels_list;
        }

        if (sP.version == "V2")
        {
            taxels_list.clear();
            for(j=264;j<=275;j++)
            {
                taxels_list.push_back(j);
            }
            sP.repr2TaxelList[267] = taxels_list;
        }

        taxels_list.clear();
        for(j=288;j<=299;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[291] = taxels_list;

        taxels_list.clear();
        for(j=300;j<=311;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[303] = taxels_list;

        if (sP.version == "V1")
        {
            taxels_list.clear();
            for(j=312;j<=323;j++)
            {
                taxels_list.push_back(j);
            }
            sP.repr2TaxelList[315] = taxels_list;
        }

        taxels_list.clear();
        for(j=336;j<=347;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[339] = taxels_list;

        taxels_list.clear();
        for(j=348;j<=359;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[351] = taxels_list;
    }
    else if(sP.name == SkinPart_s[SKIN_LEFT_HAND])
    {
        for(j=0;j<sP.size;j++)
        {
            // Fill all the 192 with -1 - half of the taxels don't exist,
            // and for fingertips we don't have positions either
            sP.taxel2Repr.push_back(-1);
        }

        // Upper left area of the palm - at thumb
        for (j=121;j<=128;j++)
        {
            sP.taxel2Repr[j] = 122;
        }
        sP.taxel2Repr[131] = 122; //thermal pad

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        for(j=121;j<=128;j++)
        {
            taxels_list.push_back(j);
        }
        taxels_list.push_back(131);
        sP.repr2TaxelList[122] = taxels_list;

        // Upper center of the palm
        for (j=96;j<=99;j++)
        {
            sP.taxel2Repr[j] = 99;
        }
        sP.taxel2Repr[102] = 99;
        sP.taxel2Repr[103] = 99;
        sP.taxel2Repr[120] = 99;
        sP.taxel2Repr[129] = 99;
        sP.taxel2Repr[130] = 99;

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        for(j=96;j<=99;j++)
        {
            taxels_list.push_back(j);
        }
        taxels_list.push_back(102);
        taxels_list.push_back(103);
        taxels_list.push_back(120);
        taxels_list.push_back(129);
        taxels_list.push_back(130);
        sP.repr2TaxelList[99] = taxels_list;

        // Upper right of the palm (away from the thumb)
        sP.taxel2Repr[100] = 101;
        sP.taxel2Repr[101] = 101;
        for (j=104;j<=107;j++)
        {
            sP.taxel2Repr[j] = 101; //N.B. 107 is thermal pad
        }
        sP.taxel2Repr[113] = 101;
        sP.taxel2Repr[116] = 101;
        sP.taxel2Repr[117] = 101;

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        taxels_list.push_back(100);
        taxels_list.push_back(101);
        for(j=104;j<=107;j++)
        {
            taxels_list.push_back(j);
        }
        taxels_list.push_back(113);
        taxels_list.push_back(116);
        taxels_list.push_back(117);
        sP.repr2TaxelList[101] = taxels_list;

        // Center area of the palm
        for(j=108;j<=112;j++)
        {
            sP.taxel2Repr[j] = 109;
        }
        sP.taxel2Repr[114] = 109;
        sP.taxel2Repr[115] = 109;
        sP.taxel2Repr[118] = 109;
        sP.taxel2Repr[142] = 109;
        sP.taxel2Repr[143] = 109;

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        for(j=108;j<=112;j++)
        {
            taxels_list.push_back(j);
        }
        taxels_list.push_back(114);
        taxels_list.push_back(115);
        taxels_list.push_back(118);
        taxels_list.push_back(142);
        taxels_list.push_back(143);
        sP.repr2TaxelList[109] = taxels_list;

        // Lower part of the palm
        sP.taxel2Repr[119] = 134; // this one is thermal pad
        for(j=132;j<=141;j++)
        {
            sP.taxel2Repr[j] = 134;
        }

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        taxels_list.push_back(119);
        for(j=132;j<=141;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[134] = taxels_list;
    }
    else if(sP.name == SkinPart_s[SKIN_RIGHT_HAND])
    {
       for(j=0;j<sP.size;j++)
       {
          sP.taxel2Repr.push_back(-1); //let's fill all the 192 with -1 - half of the taxels don't exist and for fingertips,
          //we don't have positions either
       }
       //upper left area - away from thumb on this hand
        sP.taxel2Repr[96] = 101;
        sP.taxel2Repr[97] = 101;
        sP.taxel2Repr[98] = 101;
        sP.taxel2Repr[100] = 101;
        sP.taxel2Repr[101] = 101;
        sP.taxel2Repr[107] = 101; //thermal pad
        sP.taxel2Repr[110] = 101;
        sP.taxel2Repr[111] = 101;
        sP.taxel2Repr[112] = 101;

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        taxels_list.push_back(96);
        taxels_list.push_back(97);
        taxels_list.push_back(98);
        taxels_list.push_back(100);
        taxels_list.push_back(101);
        taxels_list.push_back(107);
        taxels_list.push_back(110);
        taxels_list.push_back(111);
        taxels_list.push_back(112);
        sP.repr2TaxelList[101] = taxels_list;

        //upper center of the palm
        sP.taxel2Repr[99] = 103;
        for(j=102;j<=106;j++)
        {
           sP.taxel2Repr[j] = 103;
        }
        sP.taxel2Repr[127] = 103;
        sP.taxel2Repr[129] = 103;
        sP.taxel2Repr[130] = 103;

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        taxels_list.push_back(99);
        for(j=102;j<=106;j++)
        {
            taxels_list.push_back(j);
        }
        taxels_list.push_back(127);
        taxels_list.push_back(129);
        taxels_list.push_back(130);
        sP.repr2TaxelList[103] = taxels_list;


        //upper right center of the palm - at thumb
        for(j=120;j<=126;j++)
        {
           sP.taxel2Repr[j] = 124;
        }
        sP.taxel2Repr[128] = 124;
        sP.taxel2Repr[131] = 124; //thermal pad

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        for(j=120;j<=126;j++)
        {
            taxels_list.push_back(j);
        }
        taxels_list.push_back(128);
        taxels_list.push_back(131);
        sP.repr2TaxelList[124] = taxels_list;


        //center of palm
        sP.taxel2Repr[108] = 118;
        sP.taxel2Repr[109] = 118;
        for(j=113;j<=118;j++)
        {
            sP.taxel2Repr[j] = 118;
        }
        sP.taxel2Repr[142] = 118;
        sP.taxel2Repr[143] = 118;

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        taxels_list.push_back(108);
        taxels_list.push_back(109);
        for(j=113;j<=118;j++)
        {
            taxels_list.push_back(j);
        }
        taxels_list.push_back(142);
        taxels_list.push_back(143);
        sP.repr2TaxelList[118] = taxels_list;

        //lower palm
        sP.taxel2Repr[119] = 137; //thermal pad
        for(j=132;j<=141;j++)
        {
            sP.taxel2Repr[j] = 137; //139 is another thermal pad
        }

        // Set up the mapping in the other direction - from every representative taxel to list of taxels it is representing
        taxels_list.clear();
        taxels_list.push_back(119);
        for(j=132;j<=141;j++)
        {
            taxels_list.push_back(j);
        }
        sP.repr2TaxelList[137] = taxels_list;
    }
}

bool    vtCalib::getRepresentativeTaxels(const std::vector<unsigned int> IDv, const int IDx, std::vector<unsigned int> &v)
{
    //unordered_set would be better, but that is only experimentally supported by some compilers.
    std::set<unsigned int> rep_taxel_IDs_set;

    if (iCubSkin[IDx].taxel2Repr.empty())
    {
        v = IDv; //we simply copy the activated taxels
        return false;
    }
    else
    {
        for (std::vector<unsigned int>::const_iterator it = IDv.begin() ; it != IDv.end(); ++it)
        {
            if (iCubSkin[IDx].taxel2Repr[*it] == -1)
            {
                yWarning("[%s] taxel %u activated, but representative taxel undefined - ignoring.",iCubSkin[IDx].name.c_str(),*it);
            }
            else
            {
                rep_taxel_IDs_set.insert(iCubSkin[IDx].taxel2Repr[*it]); //add all the representatives that were activated to the set
            }
        }

        for (std::set<unsigned int>::const_iterator itr = rep_taxel_IDs_set.begin(); itr != rep_taxel_IDs_set.end(); ++itr)
        {
            v.push_back(*itr); //add the representative taxels that were activated to the output taxel ID vector
        }

        if (v.empty())
        {
            yWarning("Representative taxels' vector is empty! Skipping.");
            return false;
        }

        if (verbosity>=4)
        {
            printMessage(4,"Representative taxels on skin part %d: ",IDx);
            for(std::vector<unsigned int>::const_iterator it = v.begin() ; it != v.end(); ++it)
            {
                printf("%d ",*it);
            }
            printf("\n");
        }
    }

    return true;
}

bool    vtCalib::readEncodersAndUpdateArmChains()
{
   Vector q1(jntsT+jntsAR,0.0);
   Vector q2(jntsT+jntsAL,0.0);

   iencsT->getEncoders(encsT->data());
   qT[0]=(*encsT)[2]; //reshuffling from motor to iKin order (yaw, roll, pitch)
   qT[1]=(*encsT)[1];
   qT[2]=(*encsT)[0];

   if (armsRF.check("rightHand") || armsRF.check("rightForeArm") ||
        (!armsRF.check("rightHand") && !armsRF.check("rightForeArm") && !armsRF.check("leftHand") && !armsRF.check("leftForeArm")))
   {
        iencsR->getEncoders(encsR->data());
        qR=encsR->subVector(0,jntsAR-1);
        q1.setSubvector(0,qT);
        q1.setSubvector(jntsT,qR);
        armR -> setAng(q1*CTRL_DEG2RAD);
   }
   if (armsRF.check("leftHand") || armsRF.check("leftForeArm") ||
           (!armsRF.check("rightHand") && !armsRF.check("rightForeArm") && !armsRF.check("leftHand") && !armsRF.check("leftForeArm")))
   {
        iencsL->getEncoders(encsL->data());
        qL=encsL->subVector(0,jntsAL-1);
        q2.setSubvector(0,qT);
        q2.setSubvector(jntsT,qL);
        armL -> setAng(q2*CTRL_DEG2RAD);
   }

   return true;
}

Vector  vtCalib::locateTaxel(const yarp::sig::Vector &_pos, const string &part)
{
    yarp::sig::Vector pos=_pos;
    yarp::sig::Vector WRFpos(4,0.0);
    Matrix T = eye(4);

//        printMessage(7,"locateTaxel(): Pos local frame: %s, skin part name: %s\n",_pos.toString(3,3).c_str(),part.c_str());
    if (!((part == SkinPart_s[SKIN_LEFT_FOREARM]) || (part == SkinPart_s[SKIN_LEFT_HAND]) ||
         (part == SkinPart_s[SKIN_RIGHT_FOREARM]) || (part == SkinPart_s[SKIN_RIGHT_HAND])))
        yError("[%s] locateTaxel() failed - unknown skinPart!\n",name.c_str());

    if      (part == SkinPart_s[SKIN_LEFT_FOREARM] ) { T = armL -> getH(3+4, true); } // torso + up to elbow
    else if (part == SkinPart_s[SKIN_RIGHT_FOREARM]) { T = armR -> getH(3+4, true); } // torso + up to elbow
    else if (part == SkinPart_s[SKIN_LEFT_HAND])     { T = armL -> getH(3+6, true); } // torso + up to wrist
    else if (part == SkinPart_s[SKIN_RIGHT_HAND])    { T = armR -> getH(3+6, true); } // torso + up to wrist
    else    {  yError("[%s] locateTaxel() failed!\n",name.c_str()); }

//        printMessage(8,"    T Matrix: \n %s \n ",T.toString(3,3).c_str());
    pos.push_back(1);
    WRFpos = T * pos;
    WRFpos.pop_back();

    return WRFpos;
}

int     vtCalib::printMessage(const int l, const char *f, ...) const
{
    if (verbosity>=l)
    {
        fprintf(stdout,"[%s] ",name.c_str());

        va_list ap;
        va_start(ap,f);
        int ret=vfprintf(stdout,f,ap);
        va_end(ap);

        return ret;
    }
    else
        return -1;
}

void    vtCalib::vector2bottle(const std::vector<Vector> &vec, yarp::os::Bottle &b)
{
    for (int16_t i=0; i<vec.size(); i++)
    {
        for (int8_t j=0; j<vec[i].size(); j++)
            b.addDouble(vec[i][j]);
    }
}

bool    vtCalib::obtainSkeleton3DParts(vector<Vector> &partsPos)
{
    mutexResourcesSkeleton.lock();
    Bottle          *partsBottle     = skeleton3DPortIn.read(false);
    mutexResourcesSkeleton.unlock();

    if (partsBottle!=NULL)
    {
        if (Bottle *allParts = partsBottle->get(0).asList())
        {
            for (int8_t i=0; i<allParts->size(); i++)
            {
                Vector pos(3,0.0);
                yInfo("allParts->get(%i): %s ",i,allParts->get(i).asList()->toString().c_str());
                if (Bottle *part=allParts->get(i).asList())
                    for (int8_t j=0; j<pos.size();j++)
                    {
                        pos[j]=part->get(j).asDouble();
                    }
                partsPos.push_back(pos);
            }
        }
        else
        {
            yWarning("[%s] obtainSkeleton3DParts: receive wrong format",name.c_str());
            return false;
        }
    }
    else
    {
        yWarning("[%s] obtainSkeleton3DParts: empty message",name.c_str());
        return false;
    }
    return true;
}

bool    vtCalib::extractClosestPart2Touch(Vector &partPos)
{
    if (contactPts.size()>0 && partKeypoints.size()>0)
    {
        Vector touchPoint(3,0.0);
        for (int8_t i=0; i<contactPts.size(); i++)
        {
            touchPoint += contactPts[i];
        }
        touchPoint /=contactPts.size();

        double minDist = norm(partKeypoints[0]-touchPoint);
        partPos = partKeypoints[0];
        for (int8_t i=0; i<partKeypoints.size(); i++)
        {
            double dist = norm(partKeypoints[i]-touchPoint);
            if (dist<minDist)
            {
                partPos = partKeypoints[i];
                minDist = dist;
                yInfo("[%s] extractClosestPart2Touch: closest distance = %3.3f",name.c_str(),dist);
            }
        }
        if (minDist<=0.25)
            return true;
        else
        {
            yWarning("[%s] extractClosestPart2Touch: minDist = %3.3f, too far!!!",name.c_str(),minDist);
            partPos.zero();
            return false;
        }
    }
    else
        return false;
}

bool    vtCalib::obtainHandsFromOPC(std::vector<Vector> &handsPos)
{
    opc->checkout();
    partner = opc->addOrRetrieveEntity<Agent>(partner_default_name);
    if (partner && partner->m_present == 1.0)
    {
        Vector posR(3,0.0), posL(3,0.0);
        posR = obtainPartFromOPC(partner,"handRight");
        posL = obtainPartFromOPC(partner,"handLeft");
        handsPos.push_back(posR);
        handsPos.push_back(posL);
        yInfo("[%s] obtainHansFromOPC: got hands (%s), (%s)",
              name.c_str(),posR.toString(3,3).c_str(),posL.toString(3,3).c_str());
        return true;
    }
    else
        return false;
}

Vector  vtCalib::obtainPartFromOPC(Agent *a, const string &partName)
{
    Vector partPos(3,0.0);
    for (int8_t i=0; i<partPos.size(); i++)
        partPos[i] = a->m_body.m_parts[partName.c_str()][i];
    return partPos;
}

//********************************************
bool    vtCalib::configure(ResourceFinder &rf)
{
    name        =rf.check("name",Value("visuoTactileCalib")).asString().c_str();
    robot       =rf.check("robot",Value("icub")).asString().c_str();
    period      =rf.check("period",Value(0.0)).asDouble();
    modality    =rf.check("modality",Value("1D")).asString().c_str();

    verbosity = 0;

    stress = 0.0;

    use_vtMappingTF = rf.check("use_vtMappingTF",Value(0)).asBool();
    use_elbow       = rf.check("use_elbow",Value(0)).asBool();
    conf_thres      = rf.check("conf_thres",Value(0.5)).asDouble();
    root_dir        = rf.check("root_dir",Value("/home/pnguyen/icub-workspace/skeleton3D/")).asString().c_str();
    yDebug("root_dir: %s", root_dir.c_str());

    if(robot == "icub")
        arm_version = 2.0;
    else //icubSim
        arm_version = 1.0;

    /********** Open ports ***************/
    eventsPort.open(("/"+name+"/events:i").c_str());
    skinGuiPortForearmL.open(("/"+name+"/skinGuiForearmL:o").c_str());
    skinGuiPortForearmR.open(("/"+name+"/skinGuiForearmR:o").c_str());
    skinGuiPortHandL.open(("/"+name+"/skinGuiHandL:o").c_str());
    skinGuiPortHandR.open(("/"+name+"/skinGuiHandR:o").c_str());
    skinPortIn.open(("/"+name+"/skin_events:i").c_str());

    ppsEventsPortOut.open(("/"+name+"/pps_events_aggreg:o").c_str());

    if (Network::connect("/skinManager/skin_events:o",("/"+name+"/skin_events:i").c_str()))
        yInfo("[%s] Connected /skinManager/skin_events:o to %s successful",name.c_str(), skinPortIn.getName().c_str());
    else
        yWarning("[%s] Cannot connect /skinManager/skin_events:o to %s!!!",name.c_str(), skinPortIn.getName().c_str());

    skeleton3DPortIn.open(("/"+name+"/skeleton3D_parts:i").c_str());
    if (Network::connect("/skeleton3D/visuoTactileWrapper/objects:o",("/"+name+"/skeleton3D_parts:i").c_str()))
        yInfo("[%s] Connected /skeleton3D/visuoTactileWrapper/objects:o to %s successful",name.c_str(), skeleton3DPortIn.getName().c_str());
    else
        yWarning("[%s] Cannot connect /skeleton3D/visuoTactileWrapper/objects:o to %s!!!",name.c_str(), skeleton3DPortIn.getName().c_str());

    contactDumperPortOut.open(("/"+name+"/contactPtsDumper:o").c_str());
    partPoseDumperPortOut.open(("/"+name+"/touchPartPose:o").c_str());


    /********** vtMappingTF ***************/
    if (use_vtMappingTF)
    {
        vtMapRight = new vtMappingTF(name,"right", root_dir, "layer3/activation", "example", use_elbow);
        vtMapLeft = new vtMappingTF(name,"left", root_dir, "layer3/activation",  "example", use_elbow);
    }

    /********** OPC Client ***************/
    partner_default_name=rf.check("partner_default_name",Value("partner")).asString().c_str();

    string opcName=rf.check("opc",Value("OPC")).asString().c_str();
    opc = new OPCClient(name);
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

    //******************* ARMS, EYEWRAPPERS ******************

    std::ostringstream strR;
    strR<<"right_v"<<arm_version;
    std::string typeR = strR.str();
    armR = new iCubArm(typeR);

    std::ostringstream strL;
    strL<<"left_v"<<arm_version;
    std::string typeL = strL.str();
    armL = new iCubArm(typeL);

    ts.update();

    jntsT = 3; //nr torso joints


    //******************* PATH ******************
    bool ok = true;

    armsRF.setVerbose(false);
    armsRF.setDefaultContext("periPersonalSpace");
//        armsRF.setDefaultConfigFile("skinManAll.ini");
    armsRF.configure(0,NULL);

    path = armsRF.getHomeContextPath().c_str();
    path = path+"/";
//    string taxelsFile;
    if (rf.check("taxelsFile"))
    {
        taxelsFile = rf.find("taxelsFile").asString();
    }
    else
    {
        taxelsFile = "taxels"+modality+".ini";
        rf.setDefault("taxelsFile",taxelsFile.c_str());
    }
    yInfo("Storing file set to: %s", (path+taxelsFile).c_str());

    /********** Open right arm interfaces (if they are needed) ***************/
    if (armsRF.check("rightHand") || armsRF.check("rightForeArm") ||
       (!armsRF.check("rightHand") && !armsRF.check("rightForeArm") && !armsRF.check("leftHand") && !armsRF.check("leftForeArm")))
    {
        for (int i = 0; i < jntsT; i++)
            armR->releaseLink(i); //torso will be enabled
        Property OptR;
        OptR.put("robot",  robot.c_str());
        OptR.put("part",   "right_arm");
        OptR.put("device", "remote_controlboard");
        OptR.put("remote",("/"+robot+"/right_arm").c_str());
        OptR.put("local", ("/"+name +"/right_arm").c_str());

        if (!ddR.open(OptR))
        {
            yError("[%s] : could not open right_arm PolyDriver!\n",name.c_str());
            return false;
        }
        ok = 1;
        if (ddR.isValid())
        {
            ok = ok && ddR.view(iencsR);
        }
        if (!ok)
        {
            yError("[%s] Problems acquiring right_arm interfaces!!!!\n",name.c_str());
            return false;
        }
        iencsR->getAxes(&jntsR);
        encsR = new yarp::sig::Vector(jntsR,0.0); //should be 16 - arm + fingers
        jntsAR = 7; //nr. arm joints only - without fingers
        qR.resize(jntsAR,0.0); //current values of arm joints (should be 7)

    }

    /********** Open left arm interfaces (if they are needed) ****************/
    if (armsRF.check("leftHand") || armsRF.check("leftForeArm") ||
       (!armsRF.check("rightHand") && !armsRF.check("rightForeArm") && !armsRF.check("leftHand") && !armsRF.check("leftForeArm")))
    {
        for (int i = 0; i < jntsT; i++)
            armL->releaseLink(i); //torso will be enabled
        Property OptL;
        OptL.put("robot",  robot.c_str());
        OptL.put("part",   "left_arm");
        OptL.put("device", "remote_controlboard");
        OptL.put("remote",("/"+robot+"/left_arm").c_str());
        OptL.put("local", ("/"+name +"/left_arm").c_str());

        if (!ddL.open(OptL))
        {
            yError("[%s] : could not open left_arm PolyDriver!\n",name.c_str());
            return false;
        }
        ok = 1;
        if (ddL.isValid())
        {
            ok = ok && ddL.view(iencsL);
        }
        if (!ok)
        {
            yError("[%s] Problems acquiring left_arm interfaces!!!!\n",name.c_str());
            return false;
        }
        iencsL->getAxes(&jntsL);
        encsL = new yarp::sig::Vector(jntsL,0.0); //should be 16 - arm + fingers
        jntsAL = 7; //nr. arm joints only - without fingers
        qL.resize(jntsAL,0.0); //current values of arm joints (should be 7)

    }

    /**************************/
    Property OptT;
    OptT.put("robot",  robot.c_str());
    OptT.put("part",   "torso");
    OptT.put("device", "remote_controlboard");
    OptT.put("remote",("/"+robot+"/torso").c_str());
    OptT.put("local", ("/"+name +"/torso").c_str());

    if (!ddT.open(OptT))
    {
        yError("[%s] Could not open torso PolyDriver!",name.c_str());
        return false;
    }
    ok = 1;
    if (ddT.isValid())
    {
        ok = ok && ddT.view(iencsT);
    }
    if (!ok)
    {
        yError("[%s] Problems acquiring head interfaces!!!!",name.c_str());
        return false;
    }
    iencsT->getAxes(&jntsT);
    encsT = new yarp::sig::Vector(jntsT,0.0);
    qT.resize(jntsT,0.0); //current values of torso joints (3, in the order expected for iKin: yaw, roll, pitch)


    //************* skinManager Resource finder **************
    ResourceFinder skinRF;
    skinRF.setVerbose(false);
    skinRF.setDefaultContext("skinGui");                //overridden by --context parameter
    skinRF.setDefaultConfigFile("skinManAll.ini");      //overridden by --from parameter
    skinRF.configure(0,NULL);

    //int partNum=4;

    Bottle &skinEventsConf = skinRF.findGroup("SKIN_EVENTS");
    if(!skinEventsConf.isNull())
    {
        yInfo("SKIN_EVENTS section found\n");

        // the code below relies on a fixed order of taxel pos files in skinManAll.ini
        if(skinEventsConf.check("taxelPositionFiles"))
        {
            Bottle *taxelPosFiles = skinEventsConf.find("taxelPositionFiles").asList();

            if (rf.check("leftHand") || rf.check("leftForeArm") || rf.check("rightHand") || rf.check("rightForeArm"))
            {
                if (rf.check("leftHand"))
                {
                    string taxelPosFile = taxelPosFiles->get(0).asString().c_str();
                    string filePath(skinRF.findFile(taxelPosFile.c_str()));
                    if (filePath!="")
                    {
                        yInfo("[%s] filePath leftHand: %s\n",name.c_str(),filePath.c_str());
                        filenames.push_back(filePath);
                    }
                }
                if (rf.check("leftForeArm"))
                {
                    string taxelPosFile = taxelPosFiles->get(1).asString().c_str();
                    string filePath(skinRF.findFile(taxelPosFile.c_str()));
                    if (filePath!="")
                    {
                        yInfo("[%s] filePath leftForeArm: %s\n",name.c_str(),filePath.c_str());
                        filenames.push_back(filePath);
                    }
                }
                if (rf.check("rightHand"))
                {
                    string taxelPosFile = taxelPosFiles->get(3).asString().c_str();
                    string filePath(skinRF.findFile(taxelPosFile.c_str()));
                    if (filePath!="")
                    {
                        yInfo("[%s] filePath rightHand: %s\n",name.c_str(),filePath.c_str());
                        filenames.push_back(filePath);
                    }
                }
                if (rf.check("rightForeArm"))
                {
                    string taxelPosFile = taxelPosFiles->get(4).asString().c_str();
                    string filePath(skinRF.findFile(taxelPosFile.c_str()));
                    if (filePath!="")
                    {
                        yInfo("[%s] filePath rightForeArm: %s\n",name.c_str(),filePath.c_str());
                        filenames.push_back(filePath);
                    }
                }
            }
            else
            {
                string taxelPosFile = taxelPosFiles->get(0).asString().c_str();
                string filePath(skinRF.findFile(taxelPosFile.c_str()));
                if (filePath!="")
                {
                    yInfo("[%s] filePath leftHand: %s\n",name.c_str(),filePath.c_str());
                    filenames.push_back(filePath);
                }
                taxelPosFile.clear(); filePath.clear();

                taxelPosFile = taxelPosFiles->get(1).asString().c_str();
                filePath = skinRF.findFile(taxelPosFile.c_str());
                if (filePath!="")
                {
                    yInfo("[%s] filePath leftForeArm: %s\n",name.c_str(),filePath.c_str());
                    filenames.push_back(filePath);
                }
                taxelPosFile.clear(); filePath.clear();

                taxelPosFile = taxelPosFiles->get(3).asString().c_str();
                filePath = skinRF.findFile(taxelPosFile.c_str());
                if (filePath!="")
                {
                    yInfo("[%s] filePath rightHand: %s\n",name.c_str(),filePath.c_str());
                    filenames.push_back(filePath);
                }
                taxelPosFile.clear(); filePath.clear();

                taxelPosFile = taxelPosFiles->get(4).asString().c_str();
                filePath = skinRF.findFile(taxelPosFile.c_str());
                if (filePath!="")
                {
                    yInfo("[%s] filePath rightForeArm: %s\n",name.c_str(),filePath.c_str());
                    filenames.push_back(filePath);
                }
            }
        }
    }
    else
    {
        yError("[%s] No skin configuration files found.",name.c_str());
        return 0;
    }

    yDebug("[%s] Setting up iCubSkin...",name.c_str());
    iCubSkinSize = filenames.size();

    for(unsigned int i=0;i<filenames.size();i++)
    {
        string filePath = filenames[i];
        yDebug("i: %i filePath: %s",i,filePath.c_str());
        skinPartPWE sP(modality);
        if (setTaxelPosesFromFile(filePath,sP) )
        {
            iCubSkin.push_back(sP);
        }
    }

    load(); //here the representation params (bins, extent etc.) will be loaded and set to the pwe of every taxel

    yInfo("iCubSkin correctly instantiated. Size: %lu",iCubSkin.size());

    if (verbosity>= 2)
    {
        for (size_t i = 0; i < iCubSkin.size(); i++)
        {
            iCubSkin[i].print(verbosity);
        }
    }
    iCubSkinSize = iCubSkin.size();

//        rpcSrvr.open(("/"+name+"/rpc:i").c_str());
//        attach(rpcSrvr);


    return true;
}

//********************************************
bool    vtCalib::respond(const Bottle &command, Bottle &reply)
{
    int ack =Vocab::encode("ack");
    int nack=Vocab::encode("nack");

    return true;
}

//********************************************
bool    vtCalib::updateModule()
{
    ts.update();

    // PPS event (in this case only human pose)
    event                           = eventsPort.read(false);
    // read skin contact
    skinContactList *skinContacts   = skinPortIn.read(false);
    // read body parts from skeleton3D
//    Bottle          *bodyParts      = skeleton3DPortIn.read(false);

    // update the kinematic chain wrt World Reference Frame
    readEncodersAndUpdateArmChains();
//    readHeadEncodersAndUpdateEyeChains(); //has to be called after readEncodersAndUpdateArmChains(), which reads torso encoders

    // project taxels in World Reference Frame
    for (size_t i = 0; i < iCubSkin.size(); i++)
    {
        for (size_t j = 0; j < iCubSkin[i].taxels.size(); j++)
        {
            iCubSkin[i].taxels[j]->setWRFPosition(locateTaxel(iCubSkin[i].taxels[j]->getPosition(),iCubSkin[i].name));
        }
    }

    Bottle inputEvents;
    inputEvents.clear();

    if (event == NULL)
    {
        // if there is nothing from the port but there was a previous event,
        // and it did not pass more than 0.2 seconds from the last data, let's use that
        if ((yarp::os::Time::now() - timeNow <= 0.2) && incomingEvents.size()>0)
        {
            for(std::vector<IncomingEvent>::iterator it = incomingEvents.begin(); it!=incomingEvents.end(); it++)
            {
                Bottle &b = inputEvents.addList();
                b = it->toBottle();
            }
            printMessage(4,"Assigned %s to inputEvents from memory.\n",inputEvents.toString().c_str());
        }
    }
    else
    {
        timeNow     = yarp::os::Time::now();
        inputEvents = *event; //we assign what we just read from the port
        printMessage(4,"Read %s from events port.\n",event->toString().c_str());
    }


    incomingEvents.clear();
    resetTaxelEventVectors();

    // process the port coming from the visuoTactileWrapper
//    if (event != NULL)
    if (inputEvents.size() != 0)
    {
//        yDebug("[%s] Got pps events!!!",name.c_str());
        // read the events
//        for (int i = 0; i < event->size(); i++)
        for (int i = 0; i < inputEvents.size(); i++)
        {
//            incomingEvents.push_back(IncomingEvent(*(event->get(i).asList())));
            incomingEvents.push_back(IncomingEvent(*(inputEvents.get(i).asList())));
            printMessage(3,"\n[EVENT] %s\n", incomingEvents.back().toString().c_str());
        }
    }
    if (incomingEvents.size()>0)
    {
//        yDebug("[%s] Project pps events onto taxels FoR!!!",name.c_str());
        projectIncomingEvents();     // project event onto the taxels' FoR and add them to taxels' representation
        // only if event lies inside taxel's RF

        computeResponse(stress);    // compute the response of each taxel
    }

    sendContactsToSkinGui();
    managePPSevents();

    bool hasTouchPart = false;
    Vector touchPart(3,0.0);
    // detect skin contact
    if (skinContacts)
    {
        std::vector<unsigned int> IDv; IDv.clear();
        int IDx = -1;
        contactPts.clear();
        partKeypoints.clear();
        touchArmKeypts.clear();
        if (detectContact(skinContacts, IDx, IDv))
        {
            yInfo("[%s] Contact! Collect tactile data..",name.c_str());
            timeNow     = yarp::os::Time::now();
            yInfo("[%s] obtain skeleton3D bodypart keypoints",name.c_str());
//            if (obtainSkeleton3DParts(partKeypoints))
            if (obtainHandsFromOPC(partKeypoints))
            {
                for (int i=0; i<partKeypoints.size(); i++)
                    yDebug("partKeypoints[%i] = %s",i,partKeypoints[i].toString(3,3).c_str());
                hasTouchPart = extractClosestPart2Touch(touchPart);
                yInfo("touchPart position: %s",touchPart.toString(3,3).c_str());
                touchArmKeypts.push_back(touchPart);
                if (touchPart==obtainPartFromOPC(partner,"handRight"))
                {
                    touchArmKeypts.push_back(obtainPartFromOPC(partner,"elbowRight"));
                }
                else if (touchPart==obtainPartFromOPC(partner,"handLeft"))
                {
                    touchArmKeypts.push_back(obtainPartFromOPC(partner,"elbowLeft"));
                }
            }
        }
    }

    // dump the contact points
    if (contactPts.size()>0 && hasTouchPart)
    {
        Bottle contactBottle;
        contactBottle.clear();

        vector2bottle(contactPts, contactBottle);
        contactDumperPortOut.setEnvelope(ts);
        contactDumperPortOut.write(contactBottle);

        Bottle touchHumanPartBottle;
        touchHumanPartBottle.clear();
//        for (int8_t i; i<touchPart.size(); i++)
//            touchHumanPartBottle.addDouble(touchPart[i]);

        vector2bottle(touchArmKeypts, touchHumanPartBottle);
        partPoseDumperPortOut.setEnvelope(ts);
        partPoseDumperPortOut.write(touchHumanPartBottle);
    }
//    if (hasTouchPart)
//    {
//        Bottle touchHumanPartBottle;
//        touchHumanPartBottle.clear();
//        for (int8_t i; i<touchPart.size(); i++)
//            touchHumanPartBottle.addDouble(touchPart[i]);

//        partPoseDumperPortOut.setEnvelope(ts);
//        partPoseDumperPortOut.write(touchHumanPartBottle);
//    }

    return true;
}

void vtCalib::managePPSevents()
{
    // main/src/modules/skinManager/src/compensationThread.cpp:250
    vector <int> taxelsIDs;
    string part = SkinPart_s[SKIN_PART_UNKNOWN];
    int iCubSkinID=-1;
    bool isThereAnEvent = false;

    Bottle & out = ppsEventsPortOut.prepare();     out.clear();
    Bottle b;     b.clear();

    if (incomingEvents.size()>0)  // if there's an event
    {
        for (int i = 0; i < iCubSkinSize; i++) // cycle through the skinparts
        {
            b.clear(); //so there will be one bottle per skin part (if there was a significant event)
            taxelsIDs.clear();
            isThereAnEvent = false;

            //take only highly activated "taxels"
            for (size_t j = 0; j < iCubSkin[i].taxels.size(); j++) // cycle through the taxels
            {
                if (dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j])->Resp > PPS_AGGREG_ACT_THRESHOLD)

                {
                    taxelsIDs.push_back(iCubSkin[i].taxels[j]->getID());
                    isThereAnEvent = true;
                }
            }

            if (isThereAnEvent && taxelsIDs.size()>0)
            {
                yInfo("[%s] managePPSevents: there is an events been able to project on a taxel!!!",name.c_str());
                Vector geoCenter(3,0.0), normalDir(3,0.0);
                Vector geoCenterWRF(3,0.0), normalDirWRF(3,0.0); //in world reference frame
                double w = 0.0;
                double w_max = 0.0;
                double w_sum = 0.0;
                part  = iCubSkin[i].name;

                //the output format on the port will be:
                //(SkinPart_enum x_linkFoR y_linkFoR z_linkFoR n1_linkFoR n2_linkFoR n3_linkFoR x_RootFoR y_RootFoR z_RootFoR n1_RootFoR n2_RootFoR n3_RootFoR magnitude SkinPart_string)
                //paralleling the one produced in skinEventsAggregator skinEventsAggregThread::run()

                b.addInt(getSkinPartFromString(iCubSkin[i].name));

                for (size_t k = 0; k < taxelsIDs.size(); k++)
                {
                    for (size_t p = 0; p < iCubSkin[i].taxels.size(); p++) //these two loops are not an efficient implementation
                    {
                        if (iCubSkin[i].taxels[p]->getID() == taxelsIDs[k])
                        {
                            w = dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[p])->Resp;
                            printMessage(4,"part %s: pps taxel ID %d, pos (%s), activation: %.2f\n",part.c_str(),taxelsIDs[k],iCubSkin[i].taxels[p]->getPosition().toString(3,3).c_str(),w);
                            //The final geoCenter and normalDir will be a weighted average of the activations
                            geoCenter += iCubSkin[i].taxels[p]->getPosition()*w; //Matej, 24.2., changing convention - link not Root FoR
                            normalDir += iCubSkin[i].taxels[p]->getNormal()*w;
                            geoCenterWRF += iCubSkin[i].taxels[p]->getWRFPosition()*w; //original code
                            normalDirWRF += locateTaxel(iCubSkin[i].taxels[p]->getNormal(),part)*w;
                            w_sum += w;
                            if (w>w_max)
                                w_max = w;
                        }
                    }
                }

                geoCenter /= w_sum;
                normalDir /= w_sum;
                geoCenterWRF /= w_sum;
                normalDirWRF /= w_sum;
                vectorIntoBottle(geoCenter,b);
                vectorIntoBottle(normalDir,b);
                vectorIntoBottle(geoCenterWRF,b);
                vectorIntoBottle(normalDirWRF,b);
                b.addDouble(w_max);
                //b.addDouble(w_max/255.0); // used to be this before adapting parzenWindowEstimator1D::getF_X_scaled
                //should be inside <0,1> but if the event has a >0 threat value, response is amplified and may exceed 1
                b.addString(part);
                out.addList().read(b);
            }
        }

        ppsEventsPortOut.setEnvelope(ts);
        ppsEventsPortOut.write();     // let's send only if there was en event
    }
}

void vtCalib::sendContactsToSkinGui()
{
    Vector respToSkin;

    for(int i=0; i<iCubSkinSize; i++)
    {
        respToSkin.resize(iCubSkin[i].size,0.0);   // resize the vector to the skinPart

        if (incomingEvents.size()>0)
        {
//            yInfo("[%s] sendContactsToSkinGui: incomingEvents not empty!!!",name.c_str());
            for (size_t j = 0; j < iCubSkin[i].taxels.size(); j++)
            {
                if(iCubSkin[i].repr2TaxelList.empty())
                {
                    //we simply light up the taxels themselves
                    respToSkin[iCubSkin[i].taxels[j]->getID()] = RESP_GAIN_FOR_SKINGUI * dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j])->Resp;
                }
                else
                {
                    //we light up all the taxels represented by the particular taxel
                    list<unsigned int> l = iCubSkin[i].repr2TaxelList[iCubSkin[i].taxels[j]->getID()];

                    if (l.empty())
                    {
                        yWarning("skinPart %d Taxel %d : no list of represented taxels is available, even if repr2TaxelList is not empty",i,iCubSkin[i].taxels[j]->getID());
                        respToSkin[iCubSkin[i].taxels[j]->getID()] = RESP_GAIN_FOR_SKINGUI * dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j])->Resp;
                    }
                    else
                    {
                        for(list<unsigned int>::const_iterator iter_list = l.begin(); iter_list != l.end(); iter_list++)
                        {
                            //for all the represented taxels, we assign the activation of the super-taxel
                            respToSkin[*iter_list] =  RESP_GAIN_FOR_SKINGUI * dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j])->Resp;
                        }
                    }
                }
            }
        }


        Bottle colorBottle;
        colorBottle.addInt(0);
        colorBottle.addInt(200);
        colorBottle.addInt(100);

        BufferedPort<Bottle> *outPort;
        if(iCubSkin[i].name == SkinPart_s[SKIN_LEFT_FOREARM])
        {
            outPort = &skinGuiPortForearmL;
        }
        else if(iCubSkin[i].name == SkinPart_s[SKIN_RIGHT_FOREARM])
        {
            outPort = &skinGuiPortForearmR;
        }
        else if(iCubSkin[i].name == SkinPart_s[SKIN_LEFT_HAND])
        {
            outPort = &skinGuiPortHandL;
        }
        else if(iCubSkin[i].name == SkinPart_s[SKIN_RIGHT_HAND])
        {
            outPort = &skinGuiPortHandR;
        }

        Bottle dataBottle;
        dataBottle.addList().read(respToSkin);

        Bottle& outputBottle=outPort->prepare();
        outputBottle.clear();

        outputBottle.addList() = *(dataBottle.get(0).asList());
        outputBottle.addList() = colorBottle;

        outPort->setEnvelope(ts);
        outPort->write();
    }
}

bool vtCalib::projectIncomingEvents()
{
    for (vector<IncomingEvent>::const_iterator it = incomingEvents.begin() ; it != incomingEvents.end(); it++)
    {

        for (int i = 0; i < iCubSkinSize; i++)
        {
            IncomingEvent evt = *it;
            Matrix T_a = eye(4);               // transform matrix relative to the arm
            if ((iCubSkin[i].name == SkinPart_s[SKIN_LEFT_FOREARM]) || (iCubSkin[i].name == SkinPart_s[SKIN_LEFT_HAND]))
            {
                if (iCubSkin[i].name == SkinPart_s[SKIN_LEFT_FOREARM])
                    T_a = armL -> getH(3+4, true);
                else //(iCubSkin[i].name == SkinPart_s[SKIN_LEFT_HAND])
                    T_a = armL -> getH(3+6, true);
            }
            else if ((iCubSkin[i].name == SkinPart_s[SKIN_RIGHT_FOREARM]) || (iCubSkin[i].name == SkinPart_s[SKIN_RIGHT_HAND]))
            {
                if (iCubSkin[i].name == SkinPart_s[SKIN_RIGHT_FOREARM])
                    T_a = armR -> getH(3+4, true);
                else //(iCubSkin[i].name == SkinPart_s[SKIN_RIGHT_HAND])
                    T_a = armR -> getH(3+6, true);

                // Using vtMappingTF
//                yInfo("[%s] ORIGIN event position: %s",name.c_str(),evt.Pos.toString(3,3).c_str());
                double conf = 2.0 - (evt.Threat+1.0)/1.0;
                yInfo("[%s] threat: %0.3f, conf: %0.3f",name.c_str(), evt.Threat, conf);

                if (use_vtMappingTF && norm(evt.Pos)<=0.7 && conf<=conf_thres)
                {
                    Vector hR(3,0.0),hL(3,0.0),eb(3,0.0);
                    opc->checkout();
                    partner = opc->addOrRetrieveEntity<Agent>(partner_default_name);
                    if (partner && partner->m_present==1.0)
                    {
                        hR = obtainPartFromOPC(partner,"handRight");
                        hL = obtainPartFromOPC(partner,"handLeft");

                        if (norm(evt.Pos-hR)<=0.001 || norm(evt.Pos-hL)<=0.001)
                        {
                            yInfo("[%s] handRight pose: %s",name.c_str(),hR.toString(3,3).c_str());
                            yInfo("[%s] handLeft pose: %s",name.c_str(),hL.toString(3,3).c_str());
                            yInfo("[%s] ORIGIN event position: %s",name.c_str(),(*it).Pos.toString(3,3).c_str());

                            if (use_elbow)
                            {
                                if (norm(evt.Pos-hR)<=0.001)
                                    eb = obtainPartFromOPC(partner,"elbowRight");
                                else if (norm(evt.Pos-hL)<=0.001)
                                    eb = obtainPartFromOPC(partner,"elbowLeft");
                                yInfo("[%s] elbow pose: %s",name.c_str(),eb.toString(3,3).c_str());
                                vtMapRight->setInput(evt.Pos,eb);
                            }
                            else
                                vtMapRight->setInput(evt.Pos);
                            vtMapRight->computeMapping();
                            vtMapRight->getOutput(evt.Pos);
                            yInfo("[%s] MAPPED event position: %s",name.c_str(),evt.Pos.toString(3,3).c_str());
                        }
                    }
                }
            }
            else
                yError("[%s] in projectIncomingEvent!\n", name.c_str());

            // yInfo("T_A:\n%s",T_a.toString().c_str());
//            printMessage(5,"\nProject incoming event %s \t onto %s taxels\n",it->toString().c_str(),iCubSkin[i].name.c_str());
            IncomingEvent4TaxelPWE projEvent;
            for (size_t j = 0; j < iCubSkin[i].taxels.size(); j++)
            {
//                printMessage(6,"    Projecting onto taxel %d (Pos in Root FoR: %s Pos in local FoR: %s).\n",
//                             iCubSkin[i].taxels[j]->getID(),
//                             iCubSkin[i].taxels[j]->getWRFPosition().toString().c_str(),
//                             iCubSkin[i].taxels[j]->getPosition().toString().c_str());
                projEvent = projectIntoTaxelRF(iCubSkin[i].taxels[j]->getFoR(),T_a,evt); //project's into taxel RF and subtracts object radius from z pos in the new frame
//                printMessage(6,"\tProjected event: %s\n",projEvent.toString().c_str());
                if(dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j])->insideRFCheck(projEvent)) ////events outside of taxel's RF will not be added
                {
                    dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j])->Evnts.push_back(projEvent); //here every taxel (TaxelPWE) is updated with the events
//                    printMessage(6,"\tLies inside RF - pushing to taxelPWE.Events.\n");
                }
//                else
//                    printMessage(6,"\tLies outside RF.\n");
//                    yWarning("[%s] projectIncommingEvents: \tLies outside RF.\n");

                //printMessage(5,"Repr. taxel ID %i\tEvent: %s\n",j,dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j])->Evnt.toString().c_str());
            }
        }
    }
    return true;
}

IncomingEvent4TaxelPWE vtCalib::projectIntoTaxelRF(const Matrix &RF,const Matrix &T_a,const IncomingEvent &e)
{
    IncomingEvent4TaxelPWE Event_projected = e;

    Matrix T_a_proj = T_a * RF;

    Vector p=e.Pos; p.push_back(1);
    Vector v=e.Vel; v.push_back(1);

    Event_projected.Pos = SE3inv(T_a_proj)*p;        Event_projected.Pos.pop_back();
    Event_projected.Vel = SE3inv(T_a_proj)*v;        Event_projected.Vel.pop_back();

    if (e.Radius != -1.0)
    {
        Event_projected.Pos(2) -= Event_projected.Radius; //considering the radius, this brings the object closer in z  by the radius
        //for the rest of the calculations (in particular in x,y), the object is treated as a point
    }

    Event_projected.computeNRMTTC();

    return Event_projected;
}

bool vtCalib::computeResponse(double stress_modulation)
{
    printMessage(4,"\n\n *** [vtRFThread::computeResponse] Taxel responses ***:\n");
//    yDebug("[%s] computeResponse",name.c_str());
    for (int i = 0; i < iCubSkinSize; i++)
    {
        printMessage(4,"\n ** %s ** \n",iCubSkin[i].name.c_str());
        for (size_t j = 0; j < iCubSkin[i].taxels.size(); j++)
        {
            dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j])->computeResponse(stress_modulation);
            printMessage(4,"\t %ith (ID: %d) %s taxel response %.2f (with stress modulation:%.2f)\n",j,iCubSkin[i].taxels[j]->getID(),iCubSkin[i].name.c_str(),dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j])->Resp,stress_modulation);
        }
    }

    return true;
}

string vtCalib::load()
{
    armsRF.setVerbose(true);
//    armsRF.setDefaultContext("periPersonalSpace");
//    string fileName=armsRF.findFile("taxelsFile").c_str();
    string fileName = path+taxelsFile;
    armsRF.setVerbose(false);
    if (fileName=="")
    {
        yWarning("[vtRF::load] No filename has been found. Skipping..");
        string ret="";
        return ret;
    }

    yInfo("[vtRF::load] File loaded: %s", fileName.c_str());
    Property data; data.fromConfigFile(fileName.c_str());
    Bottle b; b.read(data);
    yDebug("[vtRF::load] iCubSkinSize %i",iCubSkinSize);

    for (int i = 0; i < iCubSkinSize; i++)
    {
        Bottle bb = b.findGroup(iCubSkin[i].name.c_str());

        if (bb.size() > 0)
        {
            string modality = bb.find("modality").asString();
            int nTaxels     = bb.find("nTaxels").asInt();
            int size        = bb.find("size").asInt();

            iCubSkin[i].size     = size;
            iCubSkin[i].modality = modality;

            Matrix ext;
            std::vector<int>    bNum;
            std::vector<int>    mapp;

            Bottle *bbb;
            bbb = bb.find("ext").asList();
            if (modality=="1D")
            {
                ext = matrixFromBottle(*bbb,0,1,2); //e.g.  ext  (-0.1 0.2) ~ (min max) will become [-0.1 0.2]
            }
            else
            {
                ext = matrixFromBottle(*bbb,0,2,2); //e.g. (-0.1 0.2 0.0 1.2) ~ (min_distance max_distance min_TTC max_TTC)
                //will become [min_distance max_distance ; min_TTC max_TTC]
            }

            bbb = bb.find("binsNum").asList();
            bNum.push_back(bbb->get(0).asInt());
            bNum.push_back(bbb->get(1).asInt());

            bbb = bb.find("Mapping").asList();
            yDebug("[vtRF::load][%s] size %i\tnTaxels %i\text %s\tbinsNum %i %i",iCubSkin[i].name.c_str(),size,
                                                  nTaxels,toVector(ext).toString(3,3).c_str(),bNum[0],bNum[1]);
            printMessage(3,"Mapping\n");
            for (int j = 0; j < size; j++)
            {
                mapp.push_back(bbb->get(j).asInt());
                if (verbosity>=3)
                {
                    printf("%i ",mapp[j]);
                }
            }
            if (verbosity>=3) printf("\n");
            iCubSkin[i].taxel2Repr = mapp;

            for (int j = 0; j < nTaxels; j++)
            {
                // 7 are the number of lines in the skinpart group that are not taxels
                bbb = bb.get(j+7).asList();
                printMessage(3,"Reading taxel %s\n",bbb->toString().c_str());

                for (size_t k = 0; k < iCubSkin[i].taxels.size(); k++)
                {
                    if (iCubSkin[i].taxels[k]->getID() == bbb->get(0).asInt())
                    {
                        if (dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[k])->pwe->resize(ext,bNum))
                        {
                            dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[k])->pwe->setPosHist(matrixFromBottle(*bbb->get(1).asList(),0,bNum[0],bNum[1]));
                            dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[k])->pwe->setNegHist(matrixFromBottle(*bbb->get(2).asList(),0,bNum[0],bNum[1]));
                        }
                    }
                }
            }
        }
    }

    return fileName;
}


void vtCalib::resetTaxelEventVectors()
{
//    printMessage(4,"[vtCalib::resetTaxelEventVectors()]\n");
    for (int i = 0; i < iCubSkinSize; i++)
        for (size_t j = 0; j < iCubSkin[i].taxels.size(); j++)
            (dynamic_cast<TaxelPWE*>(iCubSkin[i].taxels[j]))->Evnts.clear();
}


//********************************************
double  vtCalib::getPeriod()
{
    return period;
}

//********************************************
bool    vtCalib::close()
{
    yInfo("[%s] Closing module..",name.c_str());

    eventsPort.interrupt();
    eventsPort.close();

    ppsEventsPortOut.interrupt();
    ppsEventsPortOut.close();
    yDebug("ppsEventsPortOut successfully closed!\n");

    // closePort(skinGuiPortForearmL);
    skinGuiPortForearmL.interrupt();
    skinGuiPortForearmL.close();
    yDebug("  skinGuiPortForearmL successfully closed!\n");
    // closePort(skinGuiPortForearmR);
    skinGuiPortForearmR.interrupt();
    skinGuiPortForearmR.close();
    yDebug("  skinGuiPortForearmR successfully closed!\n");
    // closePort(skinGuiPortHandL);
    skinGuiPortHandL.interrupt();
    skinGuiPortHandL.close();
    yDebug("  skinGuiPortHandL successfully closed!\n");
    // closePort(skinGuiPortHandR);
    skinGuiPortHandR.interrupt();
    skinGuiPortHandR.close();
    yDebug("  skinGuiPortHandR successfully closed!\n");

    skinPortIn.close();
    skeleton3DPortIn.close();
    partPoseDumperPortOut.close();
    contactDumperPortOut.close();
    opc->close();
    yDebug("[%s]Closing controllers..\n",name.c_str());
    ddR.close();
    ddL.close();
    ddT.close();
    ddH.close();

    yDebug("[%s]Deleting misc stuff..\n",name.c_str());
    delete armR;
    armR = NULL;
    delete armL;
    armL = NULL;

    if (use_vtMappingTF)
    {
        delete vtMapRight;
//    delete vtMapLeft;
    }
//    delete event;
//    delete opc;

    return true;

}

