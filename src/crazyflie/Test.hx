package crazyflie;

import haxe.Timer;
import crazyflie.web.Crazyradio;
import js.Promise;

class Test {

	/**
		Ramps the motors up/down
	*/
	public static function rampMotors( radio : Crazyradio ) {

		var timer = new Timer( 30 );

		var roll = 0.0;
		var pitch = 0.0;
		var yaw = 0.0;
		var thrust = 20000;
		var thrust_mult = 1;
		var thrust_step = 500;

		radio.sendSetpoint( 0, 0, 0, 0 );

		return new Promise( function(resolve,reject){
			timer.run = function(){
				radio.sendSetpoint( roll, pitch, yaw, thrust );
				if( thrust >= 25000 )
					thrust_mult = -1;
				thrust += thrust_step * thrust_mult;
				if( thrust < 20000 ) {
					timer.stop();
					radio.sendSetpoint( 0, 0, 0, 0 );
					return resolve( null );
					/*
					Timer.delay( function() {
						radio.close().then( function(e){
							trace("DONE");
						});
					}, 100 );
					*/
				}
			}
		});
	}
}
