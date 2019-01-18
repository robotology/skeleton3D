# Copyright: (C) 2017 iCub Facility - Istituto Italiano di Tecnologia
# Authors: NGUYEN Dong Hai Phuong 
# Emails: phuong.nguyen@iit.it
# CopyPolicy: Released under the terms of the GNU GPL v2.0.
#
# skeleton3D.thrift

struct Vector {
  1: list<double> content;
} (
  yarp.name = "yarp::sig::Vector"
  yarp.includefile="yarp/sig/Vector.h"
)

/**
* skeleton3D_IDL
*
* IDL Interface to \ref skeleton3D services.
*/
service skeleton3D_IDL
{
  /**
  * Sets body valence (threat).
  * @param _valence thread value for all body parts.
  * @return true/false on success/failure.
  */
  bool set_valence(1:double _valence);

  /**
  * Gets the body valence.
  * @return the current body_valence value.
  */
  double get_valence();

  /**
  * Sets hand valence (threat).
  * @param _valence thread value for both hands only.
  * @param _hand string value of handLeft/handRight/both.
  * @return true/false on success/failure.
  */
  bool set_valence_hand(1:double _valence, 2:string _hand);

  /**
  * Gets the hand valence.
  * @param _hand string value of handLeft/handRight/both.
  * @return the current hand_valence value.
  */
  double get_valence_hand(1:string _hand);

  /**
  * Sets objects' valence (threat).
  * @param _valence thread value for all objects.
  * @return true/false on success/failure.
  */
  bool set_valence_obj(1:double _valence);

  /**
  * Gets the objects' valence.
  * @return the current obj_valence value.
  */
  double get_valence_obj();

  /**
  * Sets the order of median filters for body parts
  * @param _order thread value for all body parts.
  * @return true/false on success/failure.
  */
  bool set_filter_order(1:i16 _order);

  /**
  * Gets the order of median filters for body parts
  * @return the current filterOrder value.
  */
  i16 get_filter_order();

  /**
  * Sets dThresholdDisparition.
  * @param _thr threshold value.
  * @return true/false on success/failure.
  */
  bool set_threshold_disparition(1:double _thr);

  /**
  * Gets the dThresholdDisparition.
  * @return the current dThresholdDisparition value.
  */
  double get_threshold_disparition();

  /**
  * Sets fake hand position (useful in simulation).
  * @param _pos fake hand position.
  * @return true/false on success/failure.
  */
  bool set_fake_hand_pos(1:Vector _pos);

  /**
  * Gets the fake hand position (useful in simulation).
  * @return the current fakeHandPos value.
  */
  Vector get_fake_hand_pos();

  /**
  * Enables the function to create a fake rightHand
  * @return true/false on success/failure.
  */
  bool enable_fake_hand();

  /**
  * Disables the function to create a fake rightHand
  * @return true/false on success/failure.
  */
  bool disable_fake_hand();

  /**
  * Enables the usage of body part confidence to modulate the thread
  * @return true/false on success/failure.
  */
  bool enable_part_conf();

  /**
  * Disables the usage of body part confidence to modulate the thread
  * @return true/false on success/failure.
  */
  bool disable_part_conf();

  /**
  * Enables the function to calculate the midpoints in forearms
  * @return true/false on success/failure.
  */
  bool enable_mid_arms();

  /**
  * Disables the function to calculate the midpoints in forearms
  * @return true/false on success/failure.
  */
  bool disable_mid_arms();

  /**
  * Enables the function to train the tool
  * @param hand is human's hand holding object (left/right)
  * @return true/false on success/failure.
  */
  bool enable_tool_training(1:string hand);

  /**
  * Disables the function to train the tool
  * @return true/false on success/failure.
  */
  bool disable_tool_training();

  /**
  * Sets workspace_x_max.
  * @param workspace_x_max to constraint the workspace for 3D skeleton, ignore skeleton outside this threshold.
  * @return true/false on success/failure.
  */
  bool set_workspace_x_max(1:double workspace_x_max);

  /**
  * Gets workspace_x_max.
  * @return the current workspace_x_max value.
  */
  double get_workspace_x_max();

  /**
  * Sets workspace_x_min.
  * @param workspace_x_min to constraint the workspace for 3D skeleton, ignore skeleton outside this threshold.
  * @return true/false on success/failure.
  */
  bool set_workspace_x_min(1:double workspace_x_min);

  /**
  * Gets workspace_x_min.
  * @return the current workspace_x_min value.
  */
  double get_workspace_x_min();

  /**
  * Sets workspace_y_min.
  * @param workspace_y_min to constraint the workspace for 3D skeleton, ignore skeleton outside this threshold.
  * @return true/false on success/failure.
  */
  bool set_workspace_y_min(1:double workspace_y_min);

  /**
  * Gets workspace_y_min.
  * @return the current workspace_y_min value.
  */
  double get_workspace_y_min();

  /**
  * Sets workspace_y_max.
  * @param workspace_y_max to constraint the workspace for 3D skeleton, ignore skeleton outside this threshold.
  * @return true/false on success/failure.
  */
  bool set_workspace_y_max(1:double workspace_y_max);

  /**
  * Gets workspace_y_max.
  * @return the current workspace_y_max value.
  */
  double get_workspace_y_max();

}
