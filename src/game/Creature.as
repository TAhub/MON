package game 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.utils.Draw;
	
	public class Creature 
	{
		//spacing constants
		private static const VSPACE:uint = 90;
		private static const BARPADDING:uint = 3;
		private static const BARWIDTH:uint = 80;
		private static const INTERFACEHPADDING:uint = 10;
		private static const BARHEIGHT:uint = 20;
		private static const INTERFACEVPADDING:uint = 5;
		private static const ACTIVEFORWARD:uint = 40;
		private static const BARHIGHLIGHT:uint = 1;
		
		//animation constants
		private static const ANIMSTARTPOINT:Number = 0.15;
		private static const ANIMMOVEHITPOINT:Number = 0.5;
		private static const ANIMMOVEENDPOINT:Number = 1;
		private static const ANIMSHOOTHITPOINT:Number = 0.4;
		private static const ANIMSHOOTENDPOINT:Number = ANIMSHOOTHITPOINT + 0.1;
		private static const ANIMNONEHITPOINT:Number = ANIMSTARTPOINT + 0.05;
		private static const ANIMNONEENDPOINT:Number = ANIMNONEHITPOINT + 0.1;
		private static const ANIMSPEED:Number = 0.4;
		private static const FORWARDSPEED:Number = 1.5 * ANIMSPEED / ANIMSTARTPOINT;
		private static const INVISIOFF:Number = 0.25;
		
		//circle draw constants
		private static const CIRCLEMAXTHICKNESS:uint = 25;
		private static const CIRCLEMINTHICKNESS:uint = 3;
		private static const CIRCLEMAXRADIUS:uint = 200;
		private static const CIRCLEMINRADIUS:uint = 10;
		private static const CIRCLEMAXALPHA:Number = 0.5;
		private static const NUMCIRCLES:uint = 3;
		private static const CIRCLEOFFSET:Number = 0.05;
		
		//mechanical constants
		private static const MINACCURACY:Number = 0.4;
		private static const MAXACCURACY:Number = 0.95;
		private static const MINRESIST:Number = 0.1;
		private static const MAXRESIST:Number = 0.8;
		private static const MINDAMAGEMULT:Number = 0.25;
		private static const DAMAGEVARIATION:Number = 0.2;
		private static const MAXSTATDOWNRESIST:Number = 0.6;
		private static const RESISTDIV:uint = 250;
		private static const STARTSTATPOINTMAX:uint = 80;
		public static const MAXATTACKS:uint = 5;
		
		//synergy constants
		private static const SYNERBONUSREL:uint = 15;
		private static const SYNERBONUSNEUT:uint = 10;
		private static const SYNERBONUSNOREL:uint = 8;
		private static const SYNERPENALREL:uint = 10;
		private static const SYNERPENALNEUT:uint = 0;
		private static const SYNERPENALNOREL:uint = 0;
		private static const SYNERGYPOINTS:uint = 40;
		
		//appearance stats
		private var gender:uint;
		private var skinColor:uint;
		private var hairColor:uint;
		private var eyeColor:uint;
		private var hairStyle:uint;
		private var raceAppearance:uint;
		private var outfit:Array;
		public var name:String;
		
		//base stats
		private var stats:Array;
		private var progression:Array;
		private var statPoints:Array;
		private var exp:uint;
		
		//synergy
		private var synergy:Array;
		private var synerStat:uint;
		
		//misc permanent values
		private var good:Boolean;
		private var atkList:uint;
		private var atkList2:uint;
		private var type:uint;
		private var attacks:Array;
		
		//derived stats
		private var maxHealth:uint;
		private var health:uint;
		private var maxPower:uint;
		private var power:uint;
		private var initiative:uint;
		private var accuracy:uint;
		private var evasion:uint;
		private var resistance:uint;
		
		//invisible secondaries
		private var damageMult:Number;
		
		//misc temporary values
		private var status:uint;
		private var statusNew:Boolean;
		
		//temporary
		private var defenseMult:Number;
		private var initiativeBonus:int;
		private var chosenAttack:uint;
		private var target:Creature;
		private var lastActive:Boolean;
		private var hasPOW:Boolean;
		private var forward:Number;
		private var animTimer:Number;
		private var highlighted:Boolean;
		private var accuracyBonus:uint;
		
		public function load(loadFrom:Array, p:uint):uint
		{
			good = loadFrom[p++];
			
			//appearance data
			raceAppearance = loadFrom[p++];
			gender = loadFrom[p++];
			skinColor = loadFrom[p++];
			hairColor = loadFrom[p++];
			eyeColor = loadFrom[p++];
			hairStyle = loadFrom[p++];
			
			//outfit
			outfit = new Array();
			var outfitSize:uint = loadFrom[p++];
			for (var i:uint = 0; i < outfitSize; i++)
				outfit.push(loadFrom[p++]);
			
			//name
			name = loadFrom[p++];
			
			if (good)
			{
				//synergy
				synergy = new Array();
				for (i = 0; i < Battle.MAXPARTY; i++)
					synergy.push(loadFrom[p++]);
				synerStat = loadFrom[p++];
			}
			
			//stats
			exp = loadFrom[p++];
			stats = new Array();
			if (good)
			{
				progression = new Array();
				statPoints = new Array();
			}
			for (i = 0; i < Main.data.stats.length; i++)
			{
				stats.push(loadFrom[p++]);
				if (good)
				{
					progression.push(loadFrom[p++]);
					statPoints.push(loadFrom[p++]);
				}
			}
			type = loadFrom[p++];
			
			//attacks
			if (good)
			{
				atkList = loadFrom[p++];
				atkList2 = loadFrom[p++];
			}
			else
			{
				atkList = Database.NONE;
				atkList2 = Database.NONE;
			}
			attacks = new Array();
			var attackSize:uint = loadFrom[p++];
			for (i = 0; i < attackSize; i++)
				attacks.push(loadFrom[p++]);
			
			//derived/misc
			status = Database.NONE;
			statusNew = true;
			deriveStats();
			turnOver();
			health = loadFrom[p++];
			power = loadFrom[p++];
			forward = 0;
			lastActive = false;
			highlighted = false;
			
			return p;
		}
		
		public function save(saveTo:Array):void
		{
			saveTo.push(good);
			
			//appearance data
			saveTo.push(raceAppearance);
			saveTo.push(gender);
			saveTo.push(skinColor);
			saveTo.push(hairColor);
			saveTo.push(eyeColor);
			saveTo.push(hairStyle);
			
			//outfit
			saveTo.push(outfit.length);
			for (var i:uint = 0; i < outfit.length; i++)
				saveTo.push(outfit[i]);
			
			//name
			saveTo.push(name);
			
			//synergy
			if (good)
			{
				for (i = 0; i < Battle.MAXPARTY; i++)
					saveTo.push(synergy[i]);
				saveTo.push(synerStat);
			}
			
			//stats
			saveTo.push(exp);
			for (i = 0; i < Main.data.stats.length; i++)
			{
				saveTo.push(stats[i]);
				if (good)
				{
					saveTo.push(progression[i]);
					saveTo.push(statPoints[i]);
				}
			}
			saveTo.push(type);
			
			//attacks
			if (good)
			{
				saveTo.push(atkList);
				saveTo.push(atkList2);
			}
			saveTo.push(attacks.length);
			for (i = 0; i < attacks.length; i++)
				saveTo.push(attacks[i]);
			
			//derived/misc
			saveTo.push(health);
			saveTo.push(power);
		}
		
		public function setAppearance(traits:Array):void
		{
			//appearance
			var p:uint = 2;
			gender = traits[p++];
			skinColor = Main.data.featureLists[Main.data.raceAppearances[raceAppearance][2]][traits[p++] + 1];
			eyeColor = Main.data.featureLists[Main.data.raceAppearances[raceAppearance][5]][traits[p++] + 1];
			hairStyle = Main.data.featureLists[Main.data.raceAppearances[raceAppearance][6]][traits[p++] + 1];
			hairColor = Main.data.featureLists[Main.data.raceAppearances[raceAppearance][7]][traits[p++] + 1];
			name = nameGen(traits[0], traits[1]);
			
			//outfit
			var outfitSet:uint = Main.data.classes[traits[0]][11];
			outfit = new Array();
			for (var i:uint = 0; i < 4; i++)
			{
				var outN:uint = traits[p + 3 - i];
				if (Main.data.featureLists[outfitSet + i].length > 0)
				{
					var outPick:uint = Main.data.featureLists[outfitSet + i][outN + 1];
					if (outPick != Database.NONE)
						outfit.push(outPick);
				}
			}
		}
		
		public function Creature(classI:uint = 888, race:uint = 0, goodGuy:Boolean = true, startLevel:uint = 0, extraAttacks:uint = 0)
		{
			if (classI == 888)
			{
				//this is going to be loaded
				//so dont bother doing any work here
				return;
			}
			
			good = goodGuy;
			
			//appearance
			raceAppearance = Main.data.races[race][1];
			gender = Math.random() * 2;
			skinColor = getFromList(Main.data.raceAppearances[raceAppearance][2]);
			hairColor = getFromList(Main.data.raceAppearances[raceAppearance][7]);
			eyeColor = getFromList(Main.data.raceAppearances[raceAppearance][5]);
			hairStyle = getFromList(Main.data.raceAppearances[raceAppearance][6]);
			
			//name
			name = nameGen(classI, race);
			
			var outfitSet:uint = Main.data.classes[classI][11];
			outfit = new Array();
			if (outfitSet != Database.NONE)
			{
				for (var i:uint = 0; i < 4; i++)
				{
					var outPick:uint = getFromList(outfitSet + i);
					if (outPick != Database.NONE)
						outfit.push(outPick);
				}
			}
			
			//mechanics
			//note that class isnt stored; everything it adds should be stored, so that you can stack class/race bonuses safely
			type = Main.data.classes[classI][1];
			
			if (good)
			{
				synergy = new Array();
				for (i = 0; i < Battle.MAXPARTY; i++)
					synergy.push(0);
				synerStat = Main.data.races[race][12];
			}
			
			stats = new Array();
			stats.push(1); //lvl
			for (i = 1; i < Main.data.stats.length; i++)
				stats.push(Main.data.classes[classI][2 + i] + Main.data.races[race][2 + i]);
				
			if (good)
			{
				//exp is how close you are to your next level
				exp = 0;
			}
			else
			{
				//exp is the reward for beating you
				exp = deriveStat(7, Main.data.derivedFormulas);
			}
			
			//set up stat points array, for progression
			//everything but level starts out with a random number to keep things a bit uneven
			statPoints = new Array();
			statPoints.push(0);
			for (i = 1; i < stats.length; i++)
			{
				var stPoints:uint = Math.random() * STARTSTATPOINTMAX;
				statPoints.push(stPoints);
			}
			
			progression = new Array();
			progression.push(100); //lvl progression
			for (i = 1; i < Main.data.stats.length; i++)
				progression.push(Main.data.classes[classI][1 + Main.data.stats.length + i] +
															Main.data.races[race][1 + Main.data.stats.length + i]);
			
			//level up
			if (startLevel > 1)
				progressTo(startLevel);
			
			//set status here so that turnOver doesnt freak out
			status = Database.NONE;
			statusNew = true;
			
			deriveStats();
			turnOver();
			health = maxHealth;
			power = maxPower;
			
			//get the attack lists
			atkList = Main.data.classes[classI][2];
			atkList2 = Main.data.races[race][2];
			
			//get your base attacks, based on the list
			attacks = new Array();
			if (atkList != Database.NONE)
				attacks.push(Main.data.attackLists[atkList][1]);
			if (atkList2 != Database.NONE)
				attacks.push(Main.data.attackLists[atkList2][1]);
			
			//get any applicable extra attacks
			var uA:Array = usableAttacks;
			for (i = 0; i < extraAttacks; i++)
			{
				while (true)
				{
					var pick:uint = uA.length * Math.random();
					pick = uA[pick];
					var alreadyHas:Boolean = false;
					for (var j:uint = 0; j < attacks.length; j++)
						if (attacks[j] == pick)
						{
							alreadyHas = true;
							break;
						}
					if (!alreadyHas)
					{
						attacks.push(pick);
						break;
					}
				}
			}
				
			//misc
			forward = 0;
			lastActive = false;
			highlighted = false;
		}
		
		public function removeAttack(atk:uint):void
		{
			var newList:Array = new Array();
			for (var i:uint = 0; i < attacks.length; i++)
				if (attacks[i] != atk)
					newList.push(attacks[i]);
			attacks = newList;
		}
		public function get attackList():Array { return attacks; }
		
		public function canUseAttack(atk:uint):Boolean
		{
			var lst:Array = usableAttacks;
			for (var i:uint = 0; i < lst.length; i++)
				if (lst[i] == atk)
					return true;
			return false;
		}
		
		private function get usableAttacks():Array
		{
			var uA:Array = new Array();
			for (var l:uint = 0; l < 2; l++)
			{
				var list:Array = null;
				if (l == 0 && atkList != Database.NONE)
					list = Main.data.attackLists[atkList];
				else if (l == 1 && atkList2 != Database.NONE)
					list = Main.data.attackLists[atkList2];
				if (list)
					for (var i:uint = 1; i < list.length; i++)
					{
						var alreadyHas:Boolean = false;
						for (var j:uint = 0; j < uA.length; j++)
							if (uA[j] == list[i])
							{
								alreadyHas = true;
								break;
							}
						if (!alreadyHas)
							uA.push(list[i]);
					}
			}
			return uA;
		}
		
		private function nameGen(classI:uint, race:uint):String
		{
			var titleStart:uint = Main.data.classes[classI][12];
			var nameGen:uint = Main.data.races[race][11];
			if (titleStart == Database.NONE || nameGen == Database.NONE)
				return Main.data.races[race][0];
			var title:String = Main.data.lines[titleStart + gender];
			var first:String = nameBitPick(Main.data.nameGens[nameGen][1 + gender * 2], Main.data.nameGens[nameGen][2 + gender * 2]);
			var nick:String = nameBitPick(Main.data.nameGens[nameGen][5], Main.data.nameGens[nameGen][6]);
			var last:String = nameBitPick(Main.data.nameGens[nameGen][7], Main.data.nameGens[nameGen][8]);
			
			//generate name forms
			var forms:Array = new Array();
			forms.push( first + " " + last);
			forms.push( first + " " + last);
			forms.push( first + " \"" + nick + "\" " + last);
			forms.push( "\"" + nick + "\" " + last );
			forms.push( title + " " + first + " " + last );
			forms.push( first + " the " + nick);
			
			var pick:uint = Math.random() * forms.length;
			return forms[pick];
		}
		
		private function nameBitPick(from:uint, to:uint):String
		{
			var pick:uint = Math.random() * (to - from + 1) + from;
			return Main.data.lines[pick];
		}
		
		public function get powerMax():Boolean { return power >= maxPower; }
		
		public function useDrink(it:Item):void
		{
			var drinkPower:uint = Main.data.items[it.id][4];
			power += drinkPower;
			if (power > maxPower)
				power = maxPower;
		}
		
		private function progressTo(toLvl:uint):void
		{
			while (stats[0] < toLvl)
			{
				for (var i:uint = 0; i < stats.length; i++)
				{
					//add stat points
					var spAdd:uint = progression[i];
					statPoints[i] += spAdd;
					
					if (good)
					{
						statPoints[i] += synergyBonuses[i];
						if (synergyBonuses[i] > 0)
							trace(name + " gained " + synergyBonuses[i] + " bonus " + Main.data.stats[i][0] + " points from synergy!");
					}
					
					//spend stat points on stat ups
					var add:uint = 0;
					while (statPoints[i] >= 100)
					{
						statPoints[i] -= 100;
						add += 1;
					}
					
					stats[i] += add;
				}
			}
		}
		
		private function getFromList(fl:uint):uint
		{
			if (fl == Database.NONE)
				return Database.NONE;
			var choice:uint = 1 + Math.random() * (Main.data.featureLists[fl].length - 1);
			return Main.data.featureLists[fl][choice];
		}
		
		public function get effectiveInitiative():uint
		{
			if (initiative < -initiativeBonus)
				return 0; //it'll overflow
			if (initiative == 0 && initiativeBonus == 0)
				return 1; //your initiative cant go to 0 unless you have an initiative penalty
			return initiative + initiativeBonus;
		}
		
		public function highlight():void { highlighted = true; }
		
		private function resistanceRoll(difficulty:uint):Boolean
		{
			if (dead)
				return true; //you cant get status effects if you die
			var resist:Number = resistance * 0.01 - difficulty * 0.01;
			if (resist > MAXRESIST)
				resist = MAXRESIST;
			if (resist < MINRESIST)
				resist = MINRESIST;
			return Math.random() < resist;
		}
		
		public function refresh():void
		{
			deriveStats();
			turnOver();
		}
		
		public function turnOver():void
		{
			resetTemps();
			chosenAttack = Database.NONE;
				
			if (status != Database.NONE)
			{
				var value:uint = Main.data.statusEffects[status][1];
				var shakeChance:uint = Main.data.statusEffects[status][1];
				
				if (!statusNew && Math.random() <= shakeChance * 0.01)
				{
					//shake the effect
					status = Database.NONE;
					trace("Shook effect");
				}
				else
				{
					//mark that you have spent at least one round suffering the effect
					//to prevent someone from succumbing to an effect and then shaking it without it doing anything
					statusNew = false;
					
					
					switch(status)
					{
					case 0: //poison
						var poisonDam:uint = maxHealth * value * 0.01;
						if (poisonDam == 0)
							poisonDam = 1;
						var oldHealth:uint = health;
						if (health > poisonDam)
							health -= poisonDam;
						else
							health = 1;
						if (oldHealth > health)
							trace("Took " + (oldHealth - health) + " damage from poison");
						break;
					case 1: //shaken
						defenseMult *= 1 + (value * 0.01);
						break;
					}
				}
			}
		}
		
		public function get animating():Boolean { return animTimer != -1; }
		
		public function update():void
		{
			if (lastActive && forward < 1)
			{
				forward += FP.elapsed * FORWARDSPEED;
				if (forward > 1)
					forward = 1;
			}
			else if (!lastActive && forward > 0)
			{
				forward -= FP.elapsed * FORWARDSPEED;
				if (forward < 0)
					forward = 0;
			}
			
			if (animTimer != -1)
			{
				animTimer += FP.elapsed * ANIMSPEED;
				
				var powPoint:Number;
				var endPoint:Number;
				switch(Main.data.attackAnims[attackAnimation][1])
				{
				case 0:
				case 4:
					powPoint = ANIMMOVEHITPOINT;
					endPoint = ANIMMOVEENDPOINT;
					break;
				case 1:
				case 2:
					powPoint = ANIMSHOOTHITPOINT;
					endPoint = ANIMSHOOTENDPOINT;
					break;
				case 3:
				case 5:
					powPoint = ANIMNONEHITPOINT;
					endPoint = ANIMNONEENDPOINT;
					break;
				}
				if (animTimer > powPoint && hasPOW)
				{
					//unleash the attack!
					finishAttack();
					hasPOW = false;
				}
				
				if (animTimer >= endPoint)
					animTimer = -1; //animation is over
			}
		}	
		
		public function pickRandomAttack():void
		{
			var ch:uint = Math.random() * validAttacks.length;
			chooseAttack(validAttacks[ch]);
		}
		
		private function get attackAnimation():uint { return Main.data.attacks[chosenAttack][8]; }
		private function get interfaceWidth():uint { return INTERFACEHPADDING * 2 + BARWIDTH; }
		private function get interfaceHeight():uint { return INTERFACEVPADDING * 3 + BARHEIGHT * 2; }
		private function get safeBodyStyle():uint
		{
			if (bodyStyle == Database.NONE)
				return 0;
			else
				return bodyStyle;
		}
		private function get spriteWidth():uint {return Main.data.spriteSheets[Main.data.features[safeBodyStyle][1]].width; }
		private function get spriteHeight():uint { return Main.data.spriteSheets[Main.data.features[safeBodyStyle][1]].height; }
		private function getDrawX ():Number
		{
			if (good)
				return interfaceWidth + ACTIVEFORWARD * forward;
			else
				return FP.width - spriteWidth - interfaceWidth - ACTIVEFORWARD * forward;
		}
		
		private function getDrawY (num:uint):Number
		{
			return num * VSPACE;
		}
		
		private function limitedLerp(a:Number, b:Number, tStart:Number, tEnd:Number, t:Number):Number
		{
			if (t < tStart || t > tEnd)
				return 0;
			else
				return FP.lerp(a, b, (t - tStart) / (tEnd - tStart));
		}
		
		private function drawFeature(x:Number, y:Number,  fNum:uint, fColor:uint, a:Number = 1, scale:Number = 1):void
		{
			if (fNum == Database.NONE)
				return;
				
			var spr:Spritemap = Main.data.spriteSheets[Main.data.features[fNum][1]];
			spr.frame = Main.data.features[fNum][2 + gender];
			spr.flipped = !good;
			spr.color = fColor;
			
			var xAdd:int = Main.data.features[fNum][4] - Database.SUBMOD;
			var yAdd:int = Main.data.features[fNum][5] - Database.SUBMOD;
			if (!good)
				xAdd = spriteWidth - spr.width - xAdd;
			spr.scale = scale;
			spr.alpha = a;
			spr.render(FP.buffer, new Point(x + scale * xAdd, y + scale * yAdd), FP.camera);
		}
		
		private function get animal():Boolean { return Main.data.raceAppearances[raceAppearance][19]; }
		private function get bodyStyle():uint { return Main.data.raceAppearances[raceAppearance][1]; }
		private function get eyeStyle():uint { return Main.data.raceAppearances[raceAppearance][3]; }
		private function get pupilStyle():uint { return Main.data.raceAppearances[raceAppearance][4]; }
		private function get mouthStyle():uint { return Main.data.raceAppearances[raceAppearance][8]; }
		
		public function renderProjectile(num:uint, targetNum:uint):void
		{
			var aamt:uint = Main.data.attackAnims[attackAnimation][1];
			if (aamt == 1 || aamt == 2)
			{
				var progress:Number = limitedLerp(0, 1, ANIMSTARTPOINT, ANIMSHOOTHITPOINT, animTimer);
				if (progress > 0)
				{
					if (aamt == 2) //leech
						progress = 1 - progress;
						
					var ft:uint = Main.data.attackAnims[attackAnimation][4];
					var c:uint = Main.data.attackAnims[attackAnimation][5];
					if (c == Database.NONE) //set it to type color
						c = (FP.engine as Main).variateColor(Main.data.types[Main.data.attacks[chosenAttack][1]][1]);
					var pX:Number = getDrawX() * (1 - progress) + target.getDrawX() * progress;
					var pY:Number = getDrawY(num) * (1 - progress) + target.getDrawY(targetNum) * progress;
					
					if (aamt == 2) //leech
						target.drawFeature(pX, pY, ft, c);
					else
						drawFeature(pX, pY, ft, c);
				}
			}
			
			//make a colored circle
			if (animTimer >= ANIMSTARTPOINT)
				return; //too late to draw the circle
			
			for (var i:uint = 0; i < NUMCIRCLES; i++)
			{
				var circleStart:Number = CIRCLEOFFSET * i;
				if (animTimer > circleStart)
				{
					var circleR:Number = limitedLerp(CIRCLEMINRADIUS, CIRCLEMAXRADIUS, circleStart, ANIMSTARTPOINT, animTimer);
					var circleT:Number = limitedLerp(CIRCLEMAXTHICKNESS, CIRCLEMINTHICKNESS, circleStart, ANIMSTARTPOINT, animTimer);
					var circleType:uint = Main.data.attacks[chosenAttack][1];
					if (circleType == Database.NONE)
						circleType = type; //give it your type's color
					var circleC:uint = (FP.engine as Main).variateColor(Main.data.types[circleType][1]);
					var circleA:Number = limitedLerp(CIRCLEMAXALPHA, 0, circleStart, ANIMSTARTPOINT, animTimer);
					Draw.circlePlus(getDrawX() + spriteWidth / 2, getDrawY(num) + spriteHeight / 2, circleR, circleC, circleA, false, circleT);
				}
			}
		}
		
		public function renderAt(x:Number, y:Number, a:Number = 1, fitTo:Number = -1):void
		{
			var scale:Number = 1;
			if (fitTo != -1)
			{
				if (spriteWidth == spriteHeight)
					scale = fitTo / spriteWidth;
				else if (spriteWidth > spriteHeight)
				{
					scale = fitTo / spriteWidth;
					y += (spriteWidth - spriteHeight) * scale * 0.5;
				}
				else
				{
					scale = fitTo / spriteHeight;
					x += (spriteHeight - spriteWidth) * scale * 0.5;
				}
			}
			
			//draw yourself
			//draw your body
			drawFeature(x, y, bodyStyle, skinColor, a, scale); //body
			drawFeature(x, y, eyeStyle, 0xFFFFFF, a, scale); //eye
			drawFeature(x, y, pupilStyle, eyeColor, a, scale); //pupil
			drawFeature(x, y, mouthStyle, skinColor, a, scale); //mouth
			drawFeature(x, y, hairStyle, hairColor, a, scale); //hair
			
			//finally the outfit is drawn
			//this is because it can alter the body-shape, so it has to go after hair and such
			for (var i:uint = 0; i < outfit.length; i++)
				drawFeature(x, y, Main.data.outfitBits[outfit[i]][1], Main.data.outfitBits[outfit[i]][2], a, scale);
			
			//and last, the weapon is drawn
			if (chosenAttack != Database.NONE && !animal)
			{
				var wC:uint = Main.data.attackAnims[attackAnimation][3];
				if (wC == Database.NONE)
					wC = (FP.engine as Main).variateColor(Main.data.types[Main.data.attacks[chosenAttack][1]][1]);
				drawFeature(x, y, Main.data.attackAnims[attackAnimation][2], wC, a, scale);
			}
		}
		
		public function render(active:Boolean, num:uint, targetNum:uint, introSlide:Number):void
		{
			lastActive = active;
			var x:Number = getDrawX();
			var y:Number = getDrawY(num);
			var a:Number = 1;
			
			//possibly change those x/y values if you are moving for an attack anim
			if (introSlide != 1)
			{
				var isXA:Number = introSlide / Battle.INTROSLIDEDONE;
				if (isXA > 1)
					isXA = 1;
				isXA = (1 - isXA) * (interfaceWidth + spriteWidth);
				if (good)
					x -= isXA;
				else
					x += isXA;
			}
			else if (animating)
			{
				var moveType:uint = Main.data.attackAnims[attackAnimation][1];
				if (moveType == 0 || moveType == 4)
				{
					var progress:Number = limitedLerp(0, 1, ANIMSTARTPOINT, ANIMMOVEHITPOINT, animTimer) +
										limitedLerp(1, 0, ANIMMOVEHITPOINT, ANIMMOVEENDPOINT, animTimer);
					var betX:int; //the betX factor is so you dont go INTO the enemy
					if (good)
						betX = -spriteWidth;
					else
						betX = target.spriteWidth;
					x = (1 - progress) * x + progress * (target.getDrawX() + betX);
					y = (1 - progress) * y + progress * target.getDrawY(targetNum);
					if (moveType == 4)
						a = limitedLerp(1, 0, 0, INVISIOFF, progress) + limitedLerp(0, 1, 1 - INVISIOFF, 1, progress);
				}
				else if (moveType == 5 && animTimer > ANIMSTARTPOINT)
					a = limitedLerp(1, 0, ANIMSTARTPOINT, ANIMNONEHITPOINT, animTimer) +
						limitedLerp(0, 1, ANIMNONEHITPOINT, ANIMNONEENDPOINT, animTimer);
			}
			
			renderAt(x, y, a);
			
			if (introSlide != 1)
				return; //dont draw interface stuff until you are done sliding
			
			//draw interface bars
			var barX:Number = 0;
			var barY:Number = getDrawY(num);
			if (!good)
				barX = FP.width - interfaceWidth;
			
			//health bar
			drawBar(barX, barY, 1.0 * health / maxHealth, 0x00FF00, 0x005500);
			
			//power bar
			drawBar(barX, barY + INTERFACEVPADDING + BARHEIGHT, 1.0 * power / maxPower, 0x0000FF, 0x000055);
			
			if (status != Database.NONE || dead)
				drawStatus(barX, barY + INTERFACEVPADDING * 2 + BARHEIGHT * 2);
			
			highlighted = false;
		}
		
		private function drawStatus(x:Number, y:Number):void
		{
			x += INTERFACEHPADDING;
			y += INTERFACEVPADDING;
			
			var nm:String;
			var c1:uint;
			var c2:uint;
			switch(status)
			{
			case 0:
				nm = "PSN";
				c1 = 0x00FF00;
				c2 = 0x005500;
				break;
			case 1:
				nm = "SHK";
				c1 = 0xFF00FF;
				c2 = 0x550055;
				break;
			default: //youre dead
				nm = "KOD";
				c1 = 0xFFFFFF;
				c2 = 0x555555;
				break;
			}
			
			var nmTxt:Text = new Text(nm);
			
			if (highlighted)
			{
				//draw the highlight
				FP.buffer.fillRect(new Rectangle(x - BARHIGHLIGHT, y - BARHIGHLIGHT,
												nmTxt.width + BARPADDING * 2 + BARHIGHLIGHT * 2,
												nmTxt.height + BARPADDING * 2 + BARHIGHLIGHT * 2), 0xFFFFFF);
			}
			
			//draw the bar border
			FP.buffer.fillRect(new Rectangle(x, y, nmTxt.width + BARPADDING * 2, nmTxt.height + BARPADDING * 2), c1);
			
			//draw the inner bar
			FP.buffer.fillRect(new Rectangle(x + BARPADDING, y + BARPADDING, nmTxt.width, nmTxt.height), c2);
			
			//draw the text
			nmTxt.color = c1;
			nmTxt.render(FP.buffer, new Point(x + BARPADDING + 1, y + BARPADDING + 1), FP.camera);
		}
		
		private function drawBar(x:Number, y:Number, per:Number, c:uint, bC:uint):void
		{
			x += INTERFACEHPADDING;
			y += INTERFACEVPADDING;
			
			if (highlighted)
			{
				//draw the highlight
				FP.buffer.fillRect(new Rectangle(x - BARHIGHLIGHT, y - BARHIGHLIGHT,
												BARWIDTH + BARHIGHLIGHT * 2, BARHEIGHT + BARHIGHLIGHT * 2), 0xFFFFFF);
			}
			
			//draw the bar border
			FP.buffer.fillRect(new Rectangle(x, y, BARWIDTH, BARHEIGHT), 0x555555);
			
			//draw the underbar
			FP.buffer.fillRect(new Rectangle(x + BARPADDING, y + BARPADDING,
											BARWIDTH - BARPADDING * 2, BARHEIGHT - BARPADDING * 2), bC);
			
			//draw the overbar
			FP.buffer.fillRect(new Rectangle(x + BARPADDING, y + BARPADDING,
											(BARWIDTH - BARPADDING * 2) * per, BARHEIGHT - BARPADDING * 2), c);
		}
		
		public function chooseAttack(attack:uint):void
		{
			//lock into an attack
			if (!canUse(attack))
				return; //cant pay it
			
			//pay the cost
			var cost:uint = Main.data.attacks[attack][5];
			power -= cost;
			
			chosenAttack = attack;
		}
		
		public function executePrebattleSpecials(target:Creature):void
		{
			executeSpecial(Main.data.attacks[chosenAttack][6], target, true, 0);
			executeSpecial(Main.data.attacks[chosenAttack][7], target, true, 0);
		}
		
		public function get dead():Boolean { return health == 0; }
		public function get lockedIn():Boolean { return chosenAttack != Database.NONE; }
		public function get validAttacks():Array
		{
			var vA:Array = new Array();
			for (var i:uint = 0; i < attacks.length; i++)
				if (canUse(attacks[i]))
					vA.push(attacks[i]);
			if (vA.length == 0) //cant use any attacks
				vA.push(0); //get 
			return vA;
		}
		
		public function endBattle():void
		{
			status = Database.NONE;
			turnOver();
		}
		
		public function startAttack(on:Creature):void
		{
			target = on;
			animTimer = 0;
			hasPOW = true;
		}
		
		public function getAttackDamage(attack:uint):uint
		{
			var constant:uint = Main.data.attacks[attack][2];
			var statUsed:uint = Main.data.attacks[attack][3];
			var statMult:Number = Main.data.attacks[attack][4] * 0.01;
			var damage:uint = constant + stats[statUsed] * statMult;
			damage *= damageMult;
			return damage;
		}
		
		private function finishAttack():void
		{
			//roll for accuracy to see if it actually hits
			var toHit:Number = 1.0 + (accuracy + accuracyBonus) * 0.01 - target.evasion * 0.01;
			if (toHit > MAXACCURACY)
				toHit = MAXACCURACY;
			if (toHit < MINACCURACY)
				toHit = MINACCURACY;
			var hit:Boolean = Math.random() <= toHit;
			
			//see how much damage it will do
			var damage:uint = getAttackDamage(chosenAttack);
			var noDamAttack:Boolean = damage == 0;
			
			if (!hit && !noDamAttack) //attacks that do 0 damage can't miss (since they are probably self-buffs)
			{
				trace(Main.data.attacks[chosenAttack][0] + " missed.");
				return; //if you missed this is over
			}
			
			//add damage variation
			var vari:Number = Math.random() * DAMAGEVARIATION;
			if (Math.random() > 0.5)
				damage = damage * (1 + vari); //raise the damage, but round down
			else
				damage = Math.ceil(damage * (1 - vari)); //lower the damage, but round up
			
			//take into account elements and damage mods
			var atType:uint = Main.data.attacks[chosenAttack][1];
			if (atType == Database.NONE)
				atType = type; //chameleon type, so give it your type
			var elemMult:Number = Main.getDamagePercent(atType, target.type) * 0.01;
			damage = Math.ceil(elemMult * target.defenseMult * damage);
			
			if (!noDamAttack)
				trace(Main.data.attacks[chosenAttack][0] + " for " + damage + " damage.");
			
			//apply the damage
			if (target.health > damage)
				target.health -= damage;
			else
				target.health = 0;
				
			if (target.status != Database.NONE && target.dead)
				target.status = Database.NONE; //if you kill an enemy, wipe their statuses
				
			executeSpecial(Main.data.attacks[chosenAttack][6], target, false, damage);
			executeSpecial(Main.data.attacks[chosenAttack][7], target, false, damage);
		}
		
		private function get statDownResist():Number
		{
			var sdr:Number = resistance / RESISTDIV;
			if (sdr > MAXSTATDOWNRESIST)
				sdr = MAXSTATDOWNRESIST;
			return 1 - sdr;
		}
		
		private function executeSpecial(special:uint, target:Creature, preAttack:Boolean, damage:uint):void
		{
			if (special == Database.NONE)
				return; //its not a special
				
			if (Main.getImmuneTo(special, target.type))
				return; //it's immune
				
			var value:uint = deriveStat(special, Main.data.specials);
				
			switch(special)
			{
			case 0: //leech
				if (preAttack)
					return;
				
				//who needs to be healed?
				var allies:Array = (FP.world as Battle).getAllies(this);
				var needHealing:Array = new Array();
				for (var i:uint = 0; i < allies.length; i++)
				{
					var al:Creature = allies[i];
					if (!al.dead && al != this && al.health < al.maxHealth)
						needHealing.push(al);
				}
				
				var healing:uint = damage * value * 0.01;
				
				//what is the total damage?
				var totalInjury:uint = 0;
				for (i = 0; i < needHealing.length; i++)
				{
					al = needHealing[i];
					totalInjury += al.maxHealth - al.health;
				}
				
				if (totalInjury <= healing)
				{
					//just fully heal all allies
					for (i = 0; i < needHealing.length; i++)
					{
						al = needHealing[i];
						al.health = al.maxHealth;
					}
				}
				else
				{
					//split healing among allies
					for (i = 0; i < needHealing.length; i++)
					{
						al = needHealing[i];
						
						//they get a proportion of the healing of the heal based on the proportion of their injury
						//to the total injury
						var injury:uint = al.maxHealth - al.health;
						var heal:uint = healing * injury / totalInjury;
						al.health += heal;
						if (al.health > al.maxHealth)
							al.health = al.maxHealth;
					}
				}
				
				break;
			case 1: //poison
				if (preAttack)
					return;
				
				if (!target.resistanceRoll(value))
				{
					trace("Poisoned");
					target.status = 0;
					statusNew = true;
				}
				break;
			case 2: //daze
				if (preAttack)
					return;
				if (target.initiative == 0)
					return; //already pretty dazed
					
				value *= target.statDownResist; //their resistance lowers the daze amount
				trace("Dazed");
				
				if (target.initiative > value)
					target.initiative -= value;
				else
					target.initiative = 0;
				break;
			case 3: //exhaust
				if (preAttack)
					return;
				if (target.power == 0)
					return; //no need to exhaust
				
				if (target.power > value)
					target.power -= value;
				else
					target.power = 0;
				break;
			case 4: //priority
				if (!preAttack)
					return;
				
				initiativeBonus = value;
				break;
			case 5: //builder
				if (preAttack)
					return;
				
				power += value;
				if (power > maxPower)
					power = maxPower;
				break;
			case 6: //defensive
				if (!preAttack)
					return;
					
				if (value > 100)
					value = 100; //don't want to make damage overflow
				
				defenseMult *= 1 - (value * 0.01);
				break;
			case 7: //shaken
				if (preAttack)
					return;
					
				if (!target.resistanceRoll(value))
				{
					trace("Shaken");
					target.status = 1;
					statusNew = true;
				}
				break;
			case 8: //blind
				if (preAttack)
					return;
				if (target.accuracy == 0)
					return; //they're already pretty blind
					
				value *= target.statDownResist; //their resistance lowers the blind amount
				trace("Blinded");
				
				if (target.accuracy > value)
					target.accuracy -= value;
				else
					target.accuracy = 0;
				break;
			case 9: //strengthen
				if (preAttack)
					return;
				
				damageMult += value * 0.01;
				trace("Strengthened");
				break;
			case 10: //weaken
				if (preAttack)
					return;
				if (target.damageMult == MINDAMAGEMULT)
					return; //already pretty weakened
				
				value *= target.statDownResist;
				trace("Weakened");
				target.damageMult -= value * 0.01;
				if (target.damageMult < MINDAMAGEMULT)
					target.damageMult = MINDAMAGEMULT;
				break;
			case 11: //accurate
				if (!preAttack)
					return;
					
				accuracyBonus = value;
				break;
			case 12: //anti-priority
				if (!preAttack)
					return;
				
				initiativeBonus = -value;
				break;
			case 13: //mirror
				break;
			}
		}
		
		public function mirrorAction(enemy:Creature):void
		{
			var myMirror:Boolean = Main.data.attacks[chosenAttack][6] == 13;
			var theirMirror:Boolean = Main.data.attacks[enemy.chosenAttack][6] == 13;
			if (myMirror)
			{
				if (theirMirror)
					chosenAttack = 0; //it becomes flail; they will then copy flail
				else
					chosenAttack = enemy.chosenAttack; //it becomes their attack
			}
		}
		
		private function canUse(attack:uint):Boolean
		{
			var cost:uint = Main.data.attacks[attack][5];
			return power >= cost;
		}
		
		private function get levelCost():uint { return deriveStat(6, Main.data.derivedFormulas); }
		public function get expReward():uint { return exp; }
		public function awardExp(award:uint):void
		{
			exp += award;
			trace(name + " got " + award + " exp.");
			while (exp >= levelCost)
			{
				exp -= levelCost;
				progressTo(stats[0] + 1);
				trace(name + " leveled to " + stats[0]);
			}
		}
		
		private function deriveStats():void
		{
			maxHealth = deriveStat(0, Main.data.derivedFormulas);
			maxPower = deriveStat(1, Main.data.derivedFormulas);
			initiative = deriveStat(2, Main.data.derivedFormulas);
			accuracy = deriveStat(3, Main.data.derivedFormulas);
			evasion = deriveStat(4, Main.data.derivedFormulas);
			resistance = deriveStat(5, Main.data.derivedFormulas);
			// level cost is 6
			// exp reward is 7
			
			//also set invisible secondaries, which are kinda like temporaries but... not temporary
			damageMult = 1;
		}
		
		private function resetTemps():void
		{
			defenseMult = 1;
			initiativeBonus = 0;
			animTimer = -1;
			accuracyBonus = 0;
		}
		
		private function deriveStat(formula:uint, ar:Array):uint
		{
			var stat:uint = ar[formula][1]; //the constant
			var size:uint = ar[formula].length / 2;
			for (var i:uint = 1; i < size; i++)
			{
				var statUsed:uint = ar[formula][i * 2];
				var statMult:Number = ar[formula][i * 2 + 1] * 0.01;
				stat += Math.ceil(stats[statUsed] * statMult);
			}
			
			return stat;
		}
		
		//synergy calculations
		public function synergyModify():void
		{
			if (dead)
				return;
				
			for (var i:uint = 0; i < relAllies.length; i++)
			{
				if (relAllies[i] != this)
				{
					var rel:Boolean = relationship == i;
					var neut:Boolean = relationship == Database.NONE && relAllies[i].relationship == Database.NONE;
					
					var add:uint;
					var sub:uint;
					
					if (rel)
					{
						add = SYNERBONUSREL;
						sub = SYNERPENALREL;
					}
					else if (neut)
					{
						add = SYNERBONUSNEUT;
						sub = SYNERPENALNEUT;
					}
					else
					{
						add = SYNERBONUSNOREL;
						sub = SYNERPENALNOREL;
					}
					
					if (!relAllies[i].dead)
						synergy[i] += add;
					else if (synergy[i] > sub)
						synergy[i] -= sub;
					else
						synergy[i] = 0;
				}
			}
		}
		
		public function rest(food:Item):void
		{
			health = maxHealth;
			power = maxPower;
			
			var synBonus:uint = Main.data.items[food.id][4];
			if (synBonus > 0)
			{
				var mySpot:uint = 0;
				for (var i:uint = 0; i < relAllies.length; i++)
					if (relAllies[i] == this)
					{
						mySpot = i;
						break;
					}
				
				//assign syn bonuses
				for (i = 0; i < relAllies.length; i++)
					if (i != mySpot)
					{
						var al:Creature = relAllies[i];
						
						//do you get a bonus with them?
						var foundMe:Boolean = false;
						var foundThem:Boolean = false;
						for (var j:uint = 5; j < Main.data.items[food.id].length; j++)
						{
							if (raceAppearance == Main.data.items[food.id][j])
								foundMe = true;
							if (al.raceAppearance == Main.data.items[food.id][j])
								foundThem = true;
							if (foundMe && foundThem)
								break;
						}
						
						if (foundMe && foundThem)
						{
							//you both get synergy bonuses with each other
							synergy[i] += synBonus;
							al.synergy[mySpot] += synBonus;
						}
					}
			}
		}
		
		private function get synergyBonuses():Array
		{
			var totalTickets:uint = 0;
			var tickets:Array = new Array();
			
			for (var i:uint = 0; i < Battle.MAXPARTY; i++)
			{
				var tic:uint = synergy[i];
				totalTickets += tic;
				tickets.push(tic);
			}
			
			var bon:Array = new Array();
			bon.push(0);
			for (i = 1; i < progression.length; i++)
			{
				var bonAt:uint = 0;
				for (var j:uint = 0; j < Battle.MAXPARTY; j++)
				{
					if (totalTickets > 0 && tickets[j] > 0 && !dead && i == relAllies[j].synerStat)
						bonAt += SYNERGYPOINTS * tickets[j] * 1.0 / totalTickets;
				}
				bon.push(bonAt);
			}
			return bon;
		}
		
		public function get relationship():uint
		{
			for (var i:uint = 0; i < relAllies.length; i++)
			{
				var al:Creature = relAllies[i];
				if (al != this && relAllies[al.biggestSynergy] == this && biggestSynergy == i)
					return i;
			}
			return Database.NONE;
		}
		
		private function get relAllies():Array
		{
			var bat:Battle = FP.world as Battle;
			if (bat)
				return bat.getAllies(this);
			
			var map:Map = FP.world as Map;
			if (map)
				return map.playerParty;
				
			return null;
		}
		
		private function get biggestSynergy():uint
		{
			var bSyn:uint = Database.NONE;
			var bSynS:uint = 0;
			var bSynTie:Boolean = false;
			for (var i:uint = 0; i < Battle.MAXPARTY; i++)
			{
				var syn:uint = synergy[i];
				if (syn > bSynS)
				{
					bSyn = i;
					bSynS = syn;
					bSynTie = false;
				}
				else if (syn == bSynS)
					bSynTie = true;
			}
			
			if (bSynTie)
				return Database.NONE; //ties are unacceptable
			else
				return bSyn;
		}
	}

}