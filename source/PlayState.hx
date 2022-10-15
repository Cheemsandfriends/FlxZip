package;

#if html5
import js.Browser;
#end
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.zip.Reader;
import lime.app.Application;
import lime.utils.Assets;

using StringTools;

class PlayState extends FlxState
{
	var zip:Zip;
	var curFile(default, set):Int;
	var prefix:String = "";
	var texts:FlxTypedSpriteGroup<FlxText> = new FlxTypedSpriteGroup();
	var descriptText:FlxText;
	var selectable:Bool = true;
	var tween:VarTween = null;
	var timer:FlxTimer = null;

	override public function create()
	{
		#if html5
		@:privateAccess
		trace(Browser.window.innerWidth);
		#end
		super.create();
		zip = new Zip(Assets.getBytes("assets/data/test.zip"));
		zip.read();
		refreshEntries();
		add(texts);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.anyJustPressed([UP, DOWN]))
		{
			if (selectable)
			{
				texts.members[curFile].color = FlxColor.WHITE;

				(FlxG.keys.pressed.UP) ? curFile++ : curFile--;
			}
			else
			{
				if (descriptText.color != FlxColor.RED)
				{
					if (descriptText.height + descriptText.y > FlxG.height && FlxG.keys.pressed.UP)
						descriptText.y -= 20;
					else if ((descriptText.height + descriptText.y) < 0 && FlxG.keys.pressed.DOWN)
						descriptText.y += 20;
				}
				else if (tween != null)
				{
					descriptText.alpha = 1;
					tween.start();
				}
			}
		}

		var curText = texts.members[curFile];
		if (curText != null)
			curText.color = FlxColor.YELLOW;
		if (FlxG.keys.justPressed.ENTER && selectable)
		{
			if (curText.text.endsWith("/"))
			{
				prefix += curText.text;
				refreshEntries();
			}
			else
			{
				var stuff = zip.unzip(zip.extract(prefix + curText.text)).data;
				selectable = false;
				if (stuff.toString() == "")
				{
					descriptText = new FlxText(curText.width + 5, curText.y, 0, "EMPTY!", 32);
					descriptText.color = FlxColor.RED;
					add(descriptText);
					timer = new FlxTimer().start(0.5, function(_)
					{
						tween = FlxTween.tween(descriptText, {alpha: 0}, 0.5, {
							type: FlxTweenType.ONESHOT,
							onComplete: function(_)
							{
								descriptText.destroy();
								remove(descriptText);
								tween = null;
								selectable = true;
							}
						});
						timer.destroy();
						timer = null;
					});
					return;
				}
				curText.text += ":";
				descriptText = new FlxText(curText.width + 20, curText.height, FlxG.width - (curText.width + 20 + 32), stuff.toString(), 32);
				add(descriptText);
			}
		}
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			if (selectable)
			{
				if (prefix == "")
					return;

				var i = prefix.length - 2;
				while (prefix.charAt(i) != "/" && i >= 0)
				{
					prefix = prefix.substring(0, i);
					i--;
				}
				refreshEntries();
			}
			else
			{
				if (descriptText.color != FlxColor.RED)
					curText.text = curText.text.substring(0, curText.text.length - 1);
				else if (timer != null)
				{
					timer.cancel();
					timer.destroy();
					timer = null;
					if (tween != null)
					{
						tween.cancel();
						tween.destroy();
						tween = null;
					}
				}
				remove(descriptText);
				descriptText.destroy();
				selectable = true;
			}
		}
	}

	function refreshEntries()
	{
		for (i in 0...texts.members.length)
		{
			var text = texts.members[0];

			if (text != null)
			{
				texts.remove(text, true);
				text.destroy();
			}
		}
		var i = 0;
		for (entry in zip.getEntryNames(prefix))
		{
			var text = new FlxText(0, texts.height + 30 + 50 * i, 0, entry.substring(prefix.length), 32);
			texts.add(text);
			i++;
		}
	}

	function set_curFile(select:Int)
	{
		if (select < 0)
			select = texts.length - 1;
		select %= texts.length;

		return curFile = select;
	}
}
