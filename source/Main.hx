package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		#if (flixel != "5.0.0")
		addChild(new FlxGame(0, 0, PlayState));
		#end
	}
}
