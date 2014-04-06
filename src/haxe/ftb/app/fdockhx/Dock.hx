/**
* FDockHx
* written by Michel Romecki (contact@mromecki.fr, filt3r@free.fr)
* 
* Haxe 3 Compatible : flash/openFL/SWHX
*/

package ftb.app.fdockhx;

import flash.display.Sprite;
import flash.display.DisplayObjectContainer;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.text.TextFieldAutoSize;
import flash.filters.GlowFilter;
import flash.events.MouseEvent;
#if openfl
	import openfl.Assets;
#end

import feffects.Tween;
import feffects.easing.Sine;

typedef DockConfig = {
	minSize		: Int,				// minimum icon's size
	maxSize		: Int,				// maximum icon's size
	spread		: Int,				// number of _icons magnified while magnification
	delay		: Int,				// motion tween delay for dock's apparition
	spacing		: Int,				// space between icons
	fontSize	: Int,				// font size used for the displayed text
	location	: DockLocation,		// dock's location on the screen (see DockLocation)
	hidden		: Bool,				// hide dock when rolling out?
	background	: Int,				// background color with alpha channel (or 'none')
	border		: Int				// border color with alpha channel (or 'none')
}

enum DockLocation {
	top;
	left;
	right;
	bottom;
}

class DockIcon extends Sprite {
	public var label		: String;	// text displayed while rolling over
	public var path			: String;	// extern application's path to launch when clicking
	public var minScale		: Float;	// minimum icon's scale
	public var maxScale		: Float;	// maximum icon's scale
	public var amplitude	: Float;	// scale's amplitude
	
	public function new() {
		super();
		// HTML5 bug, bitmap catches mouse's events
		mouseChildren = false;
	}
}

class DockLabel extends Sprite {
	public var text (default, set_text)	: String;		// dock's label text getter/setter
	
	var _tf		: TextField;
	
	public function new( size : Int ) {
		super();
		
		var tfx 	= new TextFormat();
		tfx.color 	= 0xFFFFFF;
		#if openfl
			tfx.font 	= Assets.getFont( "tahomabd" ).fontName;
		#else
			tfx.font 	= new TahomaBold().fontName;
		#end
		tfx.bold 	= true;
		tfx.size 	= size;
		tfx.align 	= TextFormatAlign.CENTER;
				
		_tf 					= new TextField();
		_tf.defaultTextFormat 	= tfx;
		_tf.autoSize 			= TextFieldAutoSize.LEFT;
		_tf.selectable 			= false;
		_tf.width 				= 220;
		_tf.multiline 			= true;
		_tf.wordWrap 			= true;
		_tf.embedFonts 			= true;
				
		var spread 	=  Math.round( tfx.size * .1 );
		//_tf.filters 	= [ new GlowFilter( 0x000000, 1, spread, spread, 3, 3 ) ];
		addChild( _tf );
	}
	
	function set_text( s : String ) : String {
		_tf.text 	= s;
		_tf.x 		= -_tf.width * .5;
		_tf.y 		= -_tf.height * .5;
		return s;
	}
}

class Dock extends Sprite {
	var _target			: DisplayObjectContainer;	// Display object where the dock is attached
	var _icons			: Array<DockIcon>;			
	var _config			: DockConfig;				
	var _label			: DockLabel;				// Icon's name label
	var _iconsContainer	: Sprite;					// Display object where icons are attached
	var _bar			: Sprite;					// Background _bar
	var _sensor			: Sprite;					
	var _tween			: Tween;					// FEffects Tween instance
	var _totalDist		: Float;					// Used to compute magnify
	var _openScale		: Float;					// Used by tween to compute dock’s visibility
	var _screenWidth	: Float;					// Used to compute dock’s location on the screen
	var _screenHeight	: Float;
	var _offsetSensor	: Float;					// margin offset when the dock is hidden
	var _callback		: DockIcon->Void;			// callback function called on click
			
	public function new( icons : Array<DockIcon>, config : DockConfig, cb : DockIcon->Void ) {
		super();
		
		// Initialize main values and constants		
		_icons 		= icons;
		_config 	= config;
		_callback 	= cb;
		
		_openScale 		= 0;
		_offsetSensor 	= 5;
		var middleSize 	= ( _config.minSize + _config.maxSize ) * .5;
		_totalDist 		= _config.spread * ( middleSize + _config.spacing );
	}
		
	public function create( target : DisplayObjectContainer ) {
		// Display object skeleton creating
		_target 		= target;
		_label 			= new DockLabel( _config.fontSize );
		_sensor 		= new Sprite();
		_bar 			= new Sprite();
		_iconsContainer = new Sprite();
		
		addChild( _label );
		addChild( _sensor );
		addChild( _bar );
		addChild( _iconsContainer );
		_target.addChild( this );
		
		// Dock's building		
		setLocation();
		createLabel();
		createIcons();
		createSensor();
		createBar();
		// Dock's view initializing
		magnify();
		
		// Needed when hidden property is set to true in the _config XML
		if ( _config.hidden )
			_iconsContainer.y = _bar.y = _sensor.y = -_config.minSize;
		
		// Setting the event listeners
		addEventListener( MouseEvent.MOUSE_MOVE, magnify );
		addEventListener( MouseEvent.ROLL_OVER, fadeIn );
		addEventListener( MouseEvent.ROLL_OUT, fadeOut );
	}
	
	// function that clean up the scene
	public function destroy() {
		removeEventListener( MouseEvent.ROLL_OUT, fadeOut );
		removeEventListener( MouseEvent.ROLL_OVER, fadeIn );
		removeEventListener( MouseEvent.MOUSE_MOVE, magnify );
		
		removeChild( _sensor );
		removeChild( _bar );
		removeChild( _iconsContainer );		
		removeChild( _label );
				
		_target.removeChild( this );
	}
	
	function setLocation() {
		switch( _config.location )	{
			case right	:
				rotation 		= 90;
				_screenWidth 	= _target.stage.stageHeight;
				x 				= _target.stage.stageWidth;
				
			case bottom	:
				rotation 		= 180;
				_screenWidth 	= _target.stage.stageWidth;
				x 				= _target.stage.stageWidth;
				_label.rotation = -rotation;
				_icons.reverse();
				y 				= _target.stage.stageHeight;
				
			case left	:
				rotation 		= 270;
				_screenWidth 	= _target.stage.stageHeight;
				_icons.reverse();
				y 				= _target.stage.stageHeight;
				
			case top	:
				_screenWidth 	= _target.stage.stageWidth;
		}	
	}
	
	function createSensor()	{
		var gfx 	= _sensor.graphics;
		var width 	= _icons.length * _config.minSize + _icons[ 0 ].width * .5;
		var height 	= _config.minSize + _offsetSensor;
				
		gfx.clear();
		gfx.beginFill( 0xFFFFFF, 0.01 );
		gfx.lineTo( width, 0 );
		gfx.lineTo( width, height );
		gfx.lineTo( 0, height );
		gfx.lineTo( 0, 0 );
		gfx.endFill();
	}
		
	function createBar() {
		var gfx 	= _bar.graphics;
		var width 	= _icons.length * _config.minSize + _icons[ 0 ].width * .5;
		var height 	= _config.minSize;
		var bgColor	= _config.background;
		var bgAlpha	= ( bgColor >> 24 & 0xFF ) / 255;
		bgColor		= bgColor & 0xFFFFFF;	
		var bColor	= _config.border;
		var bAlpha	= ( bColor >> 24 & 0xFF ) / 255;
		bColor		= bColor & 0xFFFFFF;	
		
		gfx.clear();
		gfx.lineStyle( 1, bColor, bAlpha );
		gfx.beginFill( bgColor, bgAlpha );
		gfx.lineTo( width, 0 );
		gfx.lineTo( width, height );
		gfx.lineTo( 0, height );
		gfx.lineTo( 0, 0 );
		gfx.endFill();	
	}
	
	function createLabel() {
		_label.visible = false;
	}
	
	function createIcons() {
		for ( i in 0..._icons.length ) {
			var icon = _icons[ i ];
			icon.addEventListener( flash.events.MouseEvent.MOUSE_MOVE, setLabel );
			icon.addEventListener( flash.events.MouseEvent.CLICK, click );
			
			icon.width = icon.height = _config.minSize;
			if ( i == 0 )
				icon.x = icon.width * .5;
			else
				icon.x = _icons[ i - 1 ].x + _icons[ i - 1 ].width + _config.spacing;
			icon.y 			= icon.width * .5;
			icon.rotation 	= -rotation;
					
			icon.minScale 	= _icons[ 0 ].scaleX;
			icon.maxScale 	= icon.minScale / _config.minSize * _config.maxSize;
			icon.amplitude 	= icon.maxScale - icon.minScale;
			
			_iconsContainer.addChild( icon );
		}
	}
	
	function magnify(?_) {
		var icon 			: DockIcon	= null;
		var previousIcon 	: DockIcon	= null;
		var ref 		= _iconsContainer.mouseX;
		var dist		= 0.0;
		var newScale	= 0.0;
		for ( i in 0..._icons.length )	{
			icon = _icons[ i ];
			// Distance from the mouse cursor to the icon to resize
			var res = ref - icon.x;
			dist =  res < 0 ? -res : res;
			// Compute the new icon's scale
			newScale = ( icon.minScale + icon.amplitude * ( _totalDist -  dist ) / _totalDist ) * _openScale;
			
			// Ensure that scale isn't smaller than minScale
			icon.scaleX = icon.scaleY = newScale < icon.minScale ? icon.minScale : newScale;
			
			// Place icon's on _iconsContainer after scaling
			if ( i == 0 )
				icon.x = icon.width * .5;			
			else
				icon.x = previousIcon.x + previousIcon.width * .5 + icon.width * .5 + _config.spacing;
			icon.y 			= icon.width * .5;
			previousIcon 	= icon;
		}
		// resize the background and the _sensor and center the dock on the edge
		_iconsContainer.x 			= ( _screenWidth - _iconsContainer.width ) * .5;
		_bar.x 		= _sensor.x 	= _iconsContainer.x;
		_bar.width 	= _sensor.width = _iconsContainer.width;
		_sensor.height 				= _iconsContainer.height + _offsetSensor;
	}
	
	function setLabel( e : MouseEvent )	{
		var currentIcon : DockIcon = e.target;
		_label.text 	= currentIcon.label;
		_label.x 		= _iconsContainer.x + currentIcon.x;
	}
	
	function click( e : MouseEvent ) {
		_callback( e.target );
	}
	
	function fadeIn(_) {
		if ( _tween != null )
			_tween.stop();
		
		// callback function that receive the intermediate values from the tween
		// and applies it to _openScale propertie used to compute the icons' size
		var update = function ( e : Float )	{
			_openScale = e;
			if ( _config.hidden )
				_iconsContainer.y = _bar.y = _sensor.y = ( -_config.minSize ) * ( 1 - e );
			magnify();
			
		};
		
		// callback function called on end of the _tween
		var end = function () {
			_label.y 		= _config.maxSize + _label.height * .5;
			_label.visible 	= true;
		};
		// Creating a numerical _tween from actual _openScale to "1"
		_tween = new Tween( _openScale, 1, _config.delay );
		_tween.setEasing( Sine.easeOut );
		_tween.onUpdate( update );
		_tween.onFinish( end );
		_tween.start();
	}
	
	function fadeOut(_)	{
		_label.visible = false;
		if ( _tween != null )
			_tween.stop();
		
		var update = function ( e : Float ) {
			_openScale = e;
			if ( _config.hidden )
				_iconsContainer.y = _bar.y = _sensor.y = ( -_config.minSize ) * ( 1 - e );
			magnify();
		};
		
		// Creating a numerical tween from actual _openScale to "0"
		_tween = new Tween( _openScale, 0, _config.delay );
		_tween.setEasing( Sine.easeOut );
		_tween.onUpdate( update );
		_tween.start();
	}
}