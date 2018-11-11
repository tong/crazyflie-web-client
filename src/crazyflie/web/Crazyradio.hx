package crazyflie.web;

import js.Browser.console;
import js.Promise;
import js.USBDevice;
import js.USBOutTransferResult;
import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Uint8Array;

@:enum abstract DataRate(Int) to Int {
	var KPS250 = 0;
	var MPS1 = 1;
	var MPS2 = 2;
}

@:enum abstract Power(Int) to Int {
	var P_M18DBM = 0;
	var P_M12DBM = 1;
	var P_M6DBM = 2;
	var P_0DBM = 3;
}

class Crazyradio {

	public static inline var CRADIO_VID = 0x1915;
	public static inline var CRADIO_PID = 0x7777;

	public static inline var SET_RADIO_CHANNEL = 0x01;
	public static inline var SET_RADIO_ADDRESS = 0x02;
	public static inline var SET_DATA_RATE = 0x03;
	public static inline var SET_RADIO_POWER = 0x04;
	public static inline var SET_RADIO_ARD = 0x05;
	public static inline var SET_RADIO_ARC = 0x06;

	public static inline var ACK_ENABLE = 0x10;
	public static inline var SET_CONT_CARRIER = 0x20;
	public static inline var SCANN_CHANNELS = 0x21;
	public static inline var LAUNCH_BOOTLOADER = 0xFF;

	public var device(default,null) : USBDevice;

	public function new( device : USBDevice ) {
		this.device = device;
	}

	public function open() : Promise<Dynamic> {
		return device.open()
			.then( r -> return device.selectConfiguration(1) )
			.then( r -> return device.claimInterface(0) )
			.then( r -> return setAddress() )
			.then( r -> return setDataRate( KPS250 ) )
			.then( r -> return setACKEnable( true ) );
		//	.then( r -> return setChannel( 2 ) )
		//	.then( r -> return setContCarrier( false ) )
		//	.then( r -> return setPower( P_0DBM ) )
		//	.then( r -> return setARC( 3 ) )
		//	.then( r -> return setARDBytes( 32 ) );
	}

	public function close() : Promise<Dynamic> {
		return device.releaseInterface(0).then( function(){
			return device.reset();
			/*
			return device.releaseInterface(0).then( function(){
				trace("releaseInterface");
				return device.close();
			});
			*/
		});
	}

	public function scanChannel( channel : Int ) {
		return setChannel( channel ).then( function(r){
			var buf = new ArrayBuffer(1);
			var view = new DataView( buf );
			view.setUint8( 0, 0xFF );
			sendPacket( buf ).then( function(r){
				//trace(r );
				var decoder = new js.html.TextDecoder();
				console.log(decoder.decode(r.data));
			});
		});
	}

	/*
	public function scanChannels( start = 0, stop = 125 ) {
		var channel = start;
		function scanNext() {
			//trace("scan "+channel);
			setChannel( channel ).then( function(r){
				//trace( r );
				var buf = new ArrayBuffer(1);
				var view = new DataView( buf );
				view.setUint8( 0, 0xFF );
				sendPacket( buf ).then( function(r){
					trace( channel, r );
					channel++;
					if( channel <= stop )
						scanNext();
					else {
						trace("done");
					}
				});
			});
		}
		scanNext();
	}
	*/

	public function setDataRate( datarate : DataRate ) : Promise<USBOutTransferResult> {
		return sendVendorSetup( SET_DATA_RATE, datarate, 0 );
	}

	public function setChannel( channel : Int ) : Promise<USBOutTransferResult> {
		return sendVendorSetup( SET_RADIO_CHANNEL, channel, 0 );
	}

	public function setContCarrier( active : Bool ) : Promise<USBOutTransferResult> {
		return sendVendorSetup( SET_CONT_CARRIER, active ? 1 : 0, 0 );
	}

	//function setAddress( address : Int ) {
	public function setAddress() : Promise<USBOutTransferResult> {
		return sendVendorSetup( SET_RADIO_ADDRESS, 0, 0 );
	}

	public function setPower( power : Power ) : Promise<USBOutTransferResult> {
		return sendVendorSetup( SET_RADIO_POWER, power, 0 );
	}

	public function setARC( arc : Int ) : Promise<USBOutTransferResult> {
		return sendVendorSetup( SET_RADIO_ARC, arc, 0 );
	}

	public function setARDBytes( nbytes : Int = 0x80 ) : Promise<USBOutTransferResult> {
		return sendVendorSetup( SET_RADIO_ARD, nbytes, 0 );
	}

	public function setACKEnable( enable : Bool ) : Promise<USBOutTransferResult> {
		return sendVendorSetup( ACK_ENABLE, enable ? 1 : 0, 0 );
	}

	function sendVendorSetup( request : Int, value : Int, index : Int, ?data : ArrayBuffer ) : Promise<USBOutTransferResult> {
		if( data == null ) data = new ArrayBuffer(0);
		return device.controlTransferOut({
			requestType: 'vendor',
			recipient: 'device',
			request: request,
			value: value,
			index: index,
		}, data );
	}

	function getVendorSetup( request : Int, value : Int, index : Int, length : Int ) {
		return device.controlTransferIn({
			requestType: 'vendor',
			recipient: 'device',
			request: request,
			value: value,
			index: index,
		}, length );
	}

	public function sendSetpoint( roll : Float, pitch : Float, yaw : Float, thrust : Int ) : Promise<USBOutTransferResult> {
		var buf = new ArrayBuffer( 15 );
    	var view = new DataView( buf );
		view.setUint8( 0, 0x30 );      // CRTP header
	    view.setFloat32( 1, roll, true );
	    view.setFloat32( 5, pitch, true );
	    view.setFloat32( 9, yaw, true );
	    view.setUint16( 13, thrust, true );
		return sendPacket( buf );
	}

	public function sendPacket( data : ArrayBuffer ) : Promise<USBOutTransferResult> {
		return device.transferOut( 0x01, data ).then( function(r){
			//console.debug( r );
			return device.transferIn( 1, 64 );
			/*
			return device.transferIn( 1, 64 ).then( function(r){
				return r.data;
				console.debug( r );
				//var ack = new Uint8Array( r.data );
				//trace( ack );
				var decoder = new js.html.TextDecoder();
				console.log('Received: ' + decoder.decode(r.data));

				//return false; //r.data.getUint8() == 0;
				//trace(r.data.getUint8());
				//var ack = new Uint8Array(r.data);
				//trace(ack);
				//trace(ack.buffer);
			});
			*/
		});
	}

	public static function findDevices() : Promise<Array<USBDevice>> {
		var usb = untyped navigator.usb;
		return usb.getDevices().then( found -> {
			return found.filter( dev -> {
				return dev.productId == CRADIO_PID && dev.vendorId == CRADIO_VID;
			} );
		});
	}
}
