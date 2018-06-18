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
  * @param _human_part name of human body part, should be a hand.
  * @return true/false on success/failure
  */
  bool hand_over_object(1:string _object, 2:string _human_part);

  /**
  * Move arm to a pos, use to test connect with ReactCtrl.
  * @param _pos Vector of position.
  * @param _timeout double of timeout
  * @return true/false on success/failure.
  */
  bool move_pos_React(1:Vector _pos, 2:double _timeout);

  /**
  * Take target at a position, use to test connect with ARE.
  * @param _pos Vector of position.
  * @param _arm left/right arm in string
  * @return true/false on success/failure.
  */
  bool take_pos_ARE(1:Vector _pos, 2:string _arm);

  /**
  * Drop target at a position, use to test connect with ARE.
  * @param _pos Vector of position.
  * @param _arm left/right arm in string
  * @return true/false on success/failure.
  */
  bool drop_pos_ARE(1:Vector _pos, 2:string _arm);

  /**
  * Grasp target at a position, use to test connect with ARE.
  * @param _pos Vector of position.
  * @param _arm left/right arm in string
  * @return true/false on success/failure.
  */
  bool grasp_pos_ARE(1:Vector _pos, 2:string _arm);

  /**
  * Grasp target at a position, use to test connect with pure Cartesian and Joint controller.
  * @param _pos Vector of position.
  * @param _arm left/right arm in string
  * @return true/false on success/failure.
  */
  bool grasp_pos_Raw(1:Vector _pos, 2:string _arm);

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
  * Move hands to ARE home position & look at home position
  * @return true/false on success/failure.
  */
  bool home_all();

  /**
  * move torso
  * @param _ang Vector of angle.
  * @return true/false on success/failure.
  */
  bool move_torso(1:Vector _ang);

  /**
  * Set posTol
  * @param _tol double value of tolerence for position, used with ReactCtrl
  * @return true/false on success/failure.
  */
  bool set_posTol(1:double _tol);

  /**
  * Get posTol
  * @return double value of posTol
  */
  double get_posTol();

  /**
  * Set homeAng
  * @param _angs Vector value of homeAng
  * @return true/false on success/failure.
  */
  bool set_homeAng(1:Vector _angs);

  /**
  * Close robot hand
  * @param _arm left/right arm in string
  * @return true/false on success/failure.
  */
  bool close_hand(1:string _arm);

  /**
  * Open robot hand
  * @param _arm left/right arm in string
  * @return true/false on success/failure.
  */
  bool open_hand(1:string _arm);
}
