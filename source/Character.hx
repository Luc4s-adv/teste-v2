package;

import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import Section.SwagSection;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;
		var library:String = null;
		switch (curCharacter)
		{
			case 'gf':
				// GIRLFRIEND CODE
				frames = AtlasFrameMaker.construct('FULL_GF',
				['GF Dance Beat','Sad','Cheer','Left','Down','Up','Right','Fear']
				);
				//frames = tex;
				animation.addByPrefix('cheer', 'Cheer', 24, false);
				animation.addByPrefix('singLEFT', 'Left', 24, false);
				animation.addByPrefix('singRIGHT', 'Right', 24, false);
				animation.addByPrefix('singUP', 'Up', 24, false);
				animation.addByPrefix('singDOWN', 'Down', 24, false);
				animation.addByIndices('sad', 'Sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
				animation.addByIndices('danceLeft', 'GF Dance Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dance Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				animation.addByIndices('hairBlow', "GF Dancing Beat Hair blowing", [0, 1, 2, 3], "", 24);
				animation.addByIndices('hairFall', "GF Dancing Beat Hair Landing", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);
				animation.addByPrefix('scared', 'Fear', 24);

				addOffset('cheer', 2, -28);
				addOffset('sad', -8, -16);
				addOffset('danceLeft', 2, -11);
				addOffset('danceRight', 2, -11);

				addOffset("singUP", 2, -28);
				addOffset("singRIGHT", 2, -20);
				addOffset("singLEFT", 3, -14);
				addOffset("singDOWN", 3, -44);
				addOffset('hairBlow', 35, -31);
				addOffset('hairFall', -9, -12);

				addOffset('scared', 1, -22);

				playAnim('danceRight');

			case 'gf-eggman':
				frames = AtlasFrameMaker.construct('EGGMAN');
				animation.addByIndices('danceLeft', 'Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				playAnim('danceRight');
				setGraphicSize(Std.int(width * 0.8));
				updateHitbox();

				addOffset('danceLeft', 2, -11);
				addOffset('danceRight', 2, -11);

			case 'gfpico':
				// GIRLFRIEND CODE
				//tex = AtlasFrameMaker.construct('assets/images/TextureAtlas/PICO_GF')
				frames = AtlasFrameMaker.construct('FULL_GF',
				['GF Dance Beat 2','Sad 2','GF Dancing Beat Hair Blowing 2','GF Dancing Beat Hair Landing 2']);
				animation.addByPrefix('sad', 'Sad 2', 24, false);
				animation.addByIndices('danceLeft', 'GF Dance Beat 2', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dance Beat 2', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				animation.addByIndices('hairBlow', "GF Dancing Beat Hair Blowing 2", [0, 1, 2, 3], "", 24);
				animation.addByIndices('hairFall', "GF Dancing Beat Hair Landing 2", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);

				addOffset('sad', 2, -24);
				addOffset('danceLeft', 2, -11);
				addOffset('danceRight', 2, -11);

				addOffset('hairBlow', -9, -59);
				addOffset('hairFall', -10, -35);

				playAnim('danceRight');

			case 'gfpico2':
				// GIRLFRIEND CODE
			
				frames = AtlasFrameMaker.construct('FULL_GF',
				['GF Dance Beat 3','Sad 3','GF Dancing Beat Hair Blowing 3','GF Dancing Beat Hair Landing 3']);
				// frames = tex;
				 animation.addByIndices('sad', 'Sad 3', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
				animation.addByIndices('danceLeft', 'GF Dance Beat 3', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dance Beat 3', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				animation.addByIndices('hairBlow', "GF Dancing Beat Hair Blowing 3", [0, 1, 2, 3], "", 24);
				animation.addByIndices('hairFall', "GF Dancing Beat Hair Landing 3", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);
			

				addOffset('sad', 4, -25);
				addOffset('danceLeft', 2, -11);
				addOffset('danceRight', 2, -11);

				addOffset('hairBlow', -12, -61);
				addOffset('hairFall', -7, -37);

				playAnim('danceRight');

			case 'dad':
				// DAD ANIMATION LOADING CODE
				frames = AtlasFrameMaker.construct('DAD');
				animation.addByPrefix('idle', 'Idle',24);
				animation.addByPrefix('singUP', 'Up', 24);
				animation.addByPrefix('singDOWN', 'Down',24);
				animation.addByPrefix('singLEFT', 'Left',24);
				animation.addByPrefix('singRIGHT', 'Right',24);


				addOffset('idle', 0, 170);
				addOffset("singUP", 6, 192);
				addOffset("singRIGHT", -3, 144);
				addOffset("singLEFT", 54, 140);
				addOffset("singDOWN", 3, 113);

				playAnim('idle');

			case 'mom-car':
				frames = AtlasFrameMaker.construct('HD_MOM');

				animation.addByPrefix('idle', "Idle", 24, false);
				animation.addByPrefix('singUP', "Up", 24, false);
				animation.addByPrefix('singDOWN', "Down", 24, false);
				animation.addByPrefix('singLEFT', 'Left', 24, false);
				// ANIMATION IS CALLED MOM LEFT POSE BUT ITS FOR THE RIGHT
				// CUZ DAVE IS DUMB!
				animation.addByPrefix('singRIGHT', 'Right', 24, false);

				addOffset('idle');
				addOffset("singUP", 35, 105);
				addOffset("singRIGHT", 58, -35);
				addOffset("singLEFT", 230, 37);
				addOffset("singDOWN", 20, -176);

				playAnim('idle');


			case 'pico':
			
				frames = AtlasFrameMaker.construct('PICO');
				animation.addByPrefix('idle','Idle',24,false);
				animation.addByPrefix('singUP','Up',24,false);
				animation.addByPrefix('singRIGHT','Left',24,false);
				animation.addByPrefix('singLEFT','Right',24,false);
				animation.addByPrefix('singDOWN','Down',24,false);
				animation.addByPrefix('shoot','Shoot',24,false);

				animation.addByPrefix('idle-cracked','Cracked Idle',24,false);
				animation.addByPrefix('singUP-cracked','Cracked Up',24,false);
				animation.addByPrefix('singRIGHT-cracked','Cracked Left',24,false);
				animation.addByPrefix('singLEFT-cracked','Cracked Right',24,false);
				animation.addByPrefix('singDOWN-cracked','Cracked Down',24,false);
				animation.addByPrefix('shoot-cracked','Cracked Shoot',24,false);
				
		
				// frameWidth = Std.int(frames.getByIndex(0).parent.width / 2);
				// frameHeight = Std.int(frames.getByIndex(0).parent.height / 2);

				addOffset('idle', 0, 0);

				addOffset("singUP", -24, 102);

				addOffset("singLEFT", 60, 1);

				addOffset("singRIGHT", -41, -5);

				addOffset("singDOWN", 118, 3);

				addOffset("shoot", 128, 116);

				addOffset('idle-cracked', 0, 0);

				addOffset("singUP-cracked", -24, 102);

				addOffset("singLEFT-cracked", 60, 1);

				addOffset("singRIGHT-cracked", -41, -5);

				addOffset("singDOWN-cracked", 118, 3);

				addOffset("shoot-cracked", 128, 116);


				playAnim('idle');

				flipX = true;

			case 'bf':
				//var tex = Paths.getSparrowAtlas('characters/BOYFRIEND');
				frames = AtlasFrameMaker.construct('HD_BF');

				animation.addByPrefix('idle','Idle',24,false);
				animation.addByPrefix('idle-stressed', 'Stressed Idle', 24, false);
				animation.addByPrefix('singUP', 'Up', 24, false);
				animation.addByPrefix('singUP-stressed', 'Stressed Up', 24, false);
				animation.addByPrefix('singLEFT','Left',24, false);
				animation.addByPrefix('singLEFT-stressed', 'Stressed Left', 24, false);
				animation.addByPrefix('singRIGHT', 'Right', 24, false);
				animation.addByPrefix('singRIGHT-stressed', 'Stressed Right', 24, false);
				animation.addByPrefix('singDOWN', 'Down', 24, false);
				animation.addByPrefix('singDOWN-stressed', 'Stressed Down', 24, false);
				animation.addByPrefix('singUPmiss', 'Miss Up', 24, false);
				animation.addByPrefix('singUPmiss-stressed', 'Miss Up', 24, false);
				animation.addByPrefix('singLEFTmiss', 'Miss Left', 24, false);
				animation.addByPrefix('singLEFTmiss-stressed', 'Miss Left', 24, false);
				animation.addByPrefix('singRIGHTmiss', 'Miss Right', 24, false);
				animation.addByPrefix('singRIGHTmiss-stressed', 'Miss Right', 24, false);
				animation.addByPrefix('singDOWNmiss', 'Miss Down', 24, false);
				animation.addByPrefix('singDOWNmiss-stressed', 'Miss Down', 24, false);
				animation.addByPrefix('hey', 'HEY!!', 24, false);

				animation.addByPrefix('scared', 'Shaking', 24);
				setGraphicSize(Std.int(width * 0.94));
				updateHitbox();

				addOffset('idle', -5);
				addOffset("singUP", -49, 92);
				addOffset("singRIGHT", -62, 9);
				addOffset("singLEFT", -14, 4);
				addOffset("singDOWN", -8, -38);

				addOffset("singUPmiss", -63, -56);
				addOffset("singRIGHTmiss", -66, -59);
				addOffset("singLEFTmiss", -39, -54);
				addOffset("singDOWNmiss", -51, -92);

				addOffset('idle-stressed', -5);
				addOffset("singUP-stressed", -49, 92);
				addOffset("singRIGHT-stressed", -62, 9);
				addOffset("singLEFT-stressed", -14, 4);
				addOffset("singDOWN-stressed", -8, -38);

				//addOffset("singUPmiss-stressed", -45, 54);
				//addOffset("singRIGHTmiss-stressed", -42, 54);
				//addOffset("singLEFTmiss-stressed", 1, 17);
				//addOffset("singDOWNmiss-stressed", -32, -43);

				//addOffset("hey", -1, -1);
				//addOffset('scared', -5, 9);

				playAnim('danceLeft');
				// color = FlxColor.BLACK;

				flipX = true;

			case 'bf-car':
				//var tex = Paths.getSparrowAtlas('characters/bfCar');
				frames = AtlasFrameMaker.construct('HD_BF_CAR');
				animation.addByPrefix('idle', 'Idle', 24, false);
				animation.addByPrefix('idle-stressed', 'Stressed Idle', 24, false);
				animation.addByIndices('singUP', 'Up',[0,1,2,3],"", 24, false);
				animation.addByIndices('singUP-stressed', 'Stressed Up',[0,1,2,3],"", 24, false);
				animation.addByIndices('singLEFT', 'Left',[0,1,2,3],"", 24, false);
				animation.addByIndices('singLEFT-stressed', 'Stressed Left',[0,1,2,3],"", 24, false);
				animation.addByIndices('singRIGHT', 'Right',[0,1,2,3],"", 24, false);
				animation.addByIndices('singRIGHT-stressed', 'Stressed Right',[0,1,2,3],"", 24, false);
				animation.addByIndices('singDOWN', 'Down',[0,1,2,3],"", 24, false);
				animation.addByIndices('singDOWN-stressed', 'Stressed Down',[0,1,2,3],"", 24, false);
				animation.addByPrefix('singUPmiss', 'Up Miss', 24, false);
				animation.addByPrefix('singUPmiss-stressed', 'Up Miss', 24, false);
				animation.addByPrefix('singLEFTmiss', 'Left Miss', 24, false);
				animation.addByPrefix('singLEFTmiss-stressed', 'Left Miss', 24, false);
				animation.addByPrefix('singRIGHTmiss', 'Right Miss', 24, false);
				animation.addByPrefix('singRIGHTmiss-stressed', 'Right Miss', 24, false);
				animation.addByPrefix('singDOWNmiss', 'Miss Down', 24, false);
				animation.addByPrefix('singDOWNmiss-stressed', 'Miss Down', 24, false);
				animation.addByPrefix('dodge', 'Dodge', 24, false);
				addOffset('idle', -5);
				addOffset("singUP", -17, 24);
				addOffset("singRIGHT", -20, -4);
				addOffset("singLEFT", 12, -15);
				addOffset("singDOWN", -16, -79);
				addOffset("singUPmiss", -20, 15);
				addOffset("singRIGHTmiss", -15, -21);
				addOffset("singLEFTmiss", 9, -21);
				addOffset("singDOWNmiss", -11, -69);
				addOffset('idle-stressed', 12, 4);
				addOffset("singUP-stressed", 0, 14);
				addOffset("singRIGHT-stressed", -21, 0);
				addOffset("singLEFT-stressed", -10, -6);
				addOffset("singDOWN-stressed", -27, -47);
				addOffset("singUPmiss-stressed", -74, 66);
				addOffset("singRIGHTmiss-stressed", -14, 6);
				addOffset("singLEFTmiss-stressed", -18, -9);
				addOffset("singDOWNmiss-stressed", -37, -61);
				addOffset('dodge', 52, -37);
				playAnim('idle');

				flipX = true;

			case 'parents-christmas-atlas':
				frames = AtlasFrameMaker.construct('PARENTS_CHRISTMAS');
				animation.addByPrefix('idle', 'Parent Christmas Idle', 24, false);
				animation.addByPrefix('singUP', 'Up Dad', 24, false);
				animation.addByPrefix('singDOWN', 'Down Dad', 24, false);
				animation.addByPrefix('singLEFT', 'Left Dad', 24, false);
				animation.addByPrefix('singRIGHT', 'Right Dad', 24, false);
				animation.addByPrefix('singUP-alt', 'Up Mom', 24, false);
				animation.addByPrefix('singDOWN-alt', 'Down Mom', 24, false);
				animation.addByPrefix('singLEFT-alt', 'Left Mom', 24, false);
				animation.addByPrefix('singRIGHT-alt', 'Right Mom', 24, false);

				addOffset('idle');
				addOffset("singUP", -73, 36);
				addOffset("singRIGHT", -1, 4);
				addOffset("singLEFT", 0, 6);
				addOffset("singDOWN", -38, -1);
				addOffset("singUP-alt", -43, 27);
				addOffset("singRIGHT-alt", 0, 0);
				addOffset("singLEFT-alt", -3, 7);
				addOffset("singDOWN-alt", -40, -15);

				playAnim('idle');
			//case 'your character name in case you want to hardcode them instead':

			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = SUtil.getPath() + Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = SUtil.getPath() + Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				var spriteType = "sparrow";
				//sparrow
				//packer
				//texture
				#if MODS_ALLOWED
				var modTxtToFind:String = Paths.modsTxt(json.image);
				var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);
				
				//var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				//var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();
				
				if (FileSystem.exists(modTxtToFind) || FileSystem.exists(SUtil.getPath() + txtToFind) || Assets.exists(txtToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
				#end
				{
					spriteType = "packer";
				}
				
				#if MODS_ALLOWED
				var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
				var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
				
				//var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				//var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();
				
				if (FileSystem.exists(modAnimToFind) || FileSystem.exists(SUtil.getPath() + animToFind) || Assets.exists(animToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
				#end
				{
					spriteType = "texture";
				}

				switch (spriteType){
					
					case "packer":
						frames = Paths.getPackerAtlas(json.image);
					
					case "sparrow":
						frames = Paths.getSparrowAtlas(json.image);
					
					case "texture":
						frames = AtlasFrameMaker.construct(json.image);
				}
				imageFile = json.image;

				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if(!ClientPrefs.globalAntialiasing) antialiasing = false;

				animationsArray = json.animations;
				if(animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;
						if(animIndices != null && animIndices.length > 0) {
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						} else {
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if(anim.offsets != null && anim.offsets.length > 1) {
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
					}
				} else {
					quickAnimAdd('idle', 'BF idle dance');
				}
				//trace('Loaded file to character ' + curCharacter);
		}
		originalFlipX = flipX;

		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;

			/*// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
			{
				// var animArray
				if(animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
				{
					var oldRight = animation.getByName('singRIGHT').frames;
					animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
					animation.getByName('singLEFT').frames = oldRight;
				}

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}*/
		}
	}

	override function update(elapsed:Float)
	{
		if(!debugMode && animation.curAnim != null)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed;
				if(heyTimer <= 0)
				{
					if(specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * 0.001 * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}
		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(animation.getByName('idle' + idleSuffix) != null) {
					playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}
}
