package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import haxe.io.Path;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.system.System;
#if android
import android.content.Context;
import android.os.Build;
#end

class Main extends Sprite {
	public static var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	public static var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var fpsVar:FPS;

	public static var skipNextDump:Bool = false;
	public static var forceNoVramSprites:Bool = #if (desktop && !web) false #else true #end;

	public static function main():Void {
		Lib.current.addChild(new Main());
	}

	public function new() {
		super();
		
		if (stage != null) {
			init();
		}
		else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE)) {
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	public function setupGame():Void {
		#if android
		if (VERSION.SDK_INT > 30)
			Sys.setCwd(Path.addTrailingSlash(Context.getObbDir()));
		else
			Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(System.documentsDirectory);
		#end

		#if mobile
		Storage.copyNecessaryFiles();
		#end
		
		#if !debug
		initialState = TitleState;
		#end
		FlxTransitionableState.skipNextTransOut = true;
		
		fpsVar = new FPS(10, 4, 0xFFFFFF);

		if (fpsVar != null) {
			fpsVar.visible = false;
		}
		
		addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));

		FlxG.signals.preStateSwitch.add(function () {
			if (!Main.skipNextDump) {
				Paths.clearStoredMemory(true);
				FlxG.bitmap.dumpCache();
			}
		});
		FlxG.signals.postStateSwitch.add(function () {
			Paths.clearUnusedMemory();
			Main.skipNextDump = false;
		});

		addChild(fpsVar);
		
		#if html5
		FlxG.autoPause = false;
		#end

		FlxG.signals.gameResized.add(function (w, h) {
			//if(fpsVar != null)
				//fpsVar.positionFPS(10, 3, Math.min(Lib.current.stage.stageWidth / FlxG.width, Lib.current.stage.stageHeight / FlxG.height));
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
