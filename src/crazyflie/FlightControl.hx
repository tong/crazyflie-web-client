package crazyflie;

class FlightControl {

	public var maxAngle = 30.0;
	public var maxYaw = 200.0;
	public var maxThrust = 90.0; //%
	public var minThrust = 30.0;
	public var slewLimit = 45.0;
	public var thrustLoweringSlewrate = 30.0;

	public var pitchTrim = 0.0;
	public var rollTrim = 0.0;

	public function new() {}

}
