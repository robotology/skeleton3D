# Copyright: (C) 2018 iCub Facility - Istituto Italiano di Tecnologia
# Authors: NGUYEN Dong Hai Phuong 
# Emails: phuong.nguyen@iit.it
# CopyPolicy: Released under the terms of the GNU GPL v2.0.
#
# collaboration.thrift

struct Vector {
  1: list<double> content;
} (
  yarp.name = "yarp::sig::Vector"
  yarp.includefile="yarp/sig/Vector.h"
)

/**
* collaboration_IDL
*
* IDL Interface to \ref collaboration services.
*/
service collaboration_IDL
{
  /**
  * Receive object with name from human.
  * @param _object name of object.
  * @return true/false on success/failure.
  */
  bool receive_object(1:string _object);

  /**
  * Hand-over object with name to human.
  * @param _object name of object.
  * @return true/false on success/failure
  */
  bool hand_over_object(1:string _object);

  /**
  * Move arm to a pos, use to test connect with ReactCtrl.
  * @param _pos Vector of position.
  * @return true/false on success/failure.
  */
  bool move_pos_React(1:Vector _pos);

  /**
  * Take target at a position, use to test connect with ARE.
  * @param _pos Vector of position.
  * @param _arm left/right arm in string
  * @return true/false on success/failure.
  */
  bool take_pos_ARE(1:Vector _pos, 2:string _arm);

  /**
  * Grasp target at a position, use to test connect with ARE.
  * @param _pos Vector of position.
  * @param _arm left/right arm in string
  * @return true/false on success/failure.
  */
  bool grasp_pos_ARE(1:Vector _pos, 2:string _arm);

  /**
  * Give object to a person, use to test connect with ARE.
  * @param _partH name of human part in string.
  * @param _armR left/right arm in string
  * @return true/false on success/failure.
  */
  bool give_human_ARE(1:string _partH, 2:string _armR);

  /**
  * Stop motion with React
  * @return true/false on success/failure.
  */
  bool stop_React();

  /**
  * Home ARE
  * @return true/false on success/failure.
  */
  bool home_ARE();

  /**
  * move torso
  * @param _ang Vector of angle.
  * @return true/false on success/failure.
  */
  bool move_torso(1:Vector _ang);
}
