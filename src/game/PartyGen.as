package game 
{
	import flash.geom.Point;
	import net.flashpunk.Engine;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.World;
	import net.flashpunk.FP;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	
	public class PartyGen extends World
	{
		private var cr:Creature;
		private var traits:Array;
		private var traitOn:uint;
		private var level:uint;
		
		//keystring fuckery
		private var oldKS:String;
		private static const MAXNAME:uint = 30;
		
		//menu spacing
		private static const MENUTOP:Number = 150;
		
		//font colors
		public static const TEXTSELECTEDCOLOR:uint = 0xFFFFFF;
		public static const TEXTNEUTRALCOLOR:uint = 0x999999;
		
		public function PartyGen(startLevel:uint)
		{
			traits = new Array();
			for (var i:uint = 0; i < 11; i++)
				traits.push(0);
			traits.push("");
			traits.push(0);
			
			traitOn = 0;
			
			oldKS = "";
			
			level = startLevel;
			generateCreature();
		}
		
		private function sanitizeKeystring():void
		{
			var nKS:String = "";
			for (var i:uint = 0; i < Input.keyString.length && i < MAXNAME; i++)
			{
				var eC:uint = Input.keyString.charCodeAt(i);
				if ((eC >= "A".charCodeAt(0) && eC <= "Z".charCodeAt(0)) ||
					(eC >= "a".charCodeAt(0) && eC <= "z".charCodeAt(0)) ||
					eC == " ".charCodeAt(0) || eC == "\"".charCodeAt(0))
					nKS += String.fromCharCode(eC);
			}
			Input.keyString = nKS;
			
			oldKS = Input.keyString;
		}
		
		public override function update():void
		{
			if (Input.pressed(Key.SPACE) && traitOn == 12)
			{
				(FP.engine as Main).returnToMap(cr);
				return;
			}
			
			if (traitOn == 11)
			{
				sanitizeKeystring();
				
				if (Input.keyString.length == 0 && traits[traitOn].length > 0)
				{
					traits[traitOn] = "";
					generateCreature();
				}	
				else if (Input.keyString.length > 0 && Input.lastKey != Key.UP && Input.lastKey != Key.DOWN)
				{
					traits[traitOn] = Input.keyString;
					cr.name = traits[traitOn];
					return;
				}
			}
			else
			{
				//trim whitespace here
				if (oldKS.length > 0)
				{
					var TRIM:RegExp = /^ +| +$/g;
					oldKS = oldKS.replace(TRIM, "");
					cr.name = oldKS;
				}
				
				if (Input.keyString != oldKS)
					Input.keyString = oldKS;
			}
			
			var tAdd:int = 0;
			if (Input.pressed(Key.UP))
				tAdd -= 1;
			if (Input.pressed(Key.DOWN))
				tAdd += 1;
				
			if (tAdd != 0)
			{
				if (tAdd == -1 && traitOn == 0)
					traitOn = traits.length - 1;
				else if (tAdd == 1 && traitOn == traits.length - 1)
					traitOn = 0;
				else
					traitOn += tAdd;
			}
			else
			{
				var vAdd:int = 0;
				if (Input.pressed(Key.LEFT))
					vAdd -= 1;
				if (Input.pressed(Key.RIGHT))
					vAdd += 1;
					
				if (vAdd != 0 && getTraitMax(traitOn) > 1)
				{
					if (vAdd == -1 && traits[traitOn] == 0)
						traits[traitOn] = getTraitMax(traitOn) - 1;
					else if (vAdd == 1 && traits[traitOn] == getTraitMax(traitOn) - 1)
						traits[traitOn] = 0;
					else
						traits[traitOn] += vAdd;
					
					if (traitOn == 0)
					{
						resetOutfit();
						checkValidClass(vAdd);
						checkValidRace(1);
					}
					else if (traitOn == 1)
					{
						resetAppearance();
						checkValidRace(vAdd);
					}
					
					generateCreature();
				}
			}
		}
		
		private function get validClass():Boolean
		{
			for (var i:uint = 0; i < Main.data.combinations.length; i++)
			{
				var comb:Array = Main.data.combinations[i];
				if (comb[3] && comb[1] == traits[0])
					return true;
			}
			return false;
		}
		
		private function checkValidClass(dir:int):void
		{
			if (!validClass)
			{
				//increase the class and check valid again
				resetOutfit();
				if (traits[0] == 0 && dir == -1)
					traits[0] = Main.data.classes.length - 1;
				else if (traits[0] == Main.data.classes.length - 1 && dir == 1)
					traits[0] = 0;
				else
					traits[0] += dir;
				checkValidClass(dir);
			}
		}
		
		private function get validRace():Boolean
		{
			for (var i:uint = 0; i < Main.data.combinations.length; i++)
			{
				var comb:Array = Main.data.combinations[i];
				if (comb[3] && comb[1] == traits[0] && comb[2] == traits[1])
					return true;
			}
			return false;
		}
		
		private function checkValidRace(dir:int):void
		{
			if (!validRace)
			{
				//increase race and check valid again
				resetAppearance();
				if (traits[1] == Main.data.races.length -1 && dir == 1)
					traits[1] = 0;
				else if (traits[1] == 0 && dir == -1)
					traits[1] = Main.data.races.length - 1;
				else
					traits[1] += dir;
				
				checkValidRace(dir);
			}
		}
		
		private function resetAppearance():void
		{
			//reset appearance (apart from gender)
			for (var j:uint = 3; j <= 6; j++)
				traits[j] = 0;
		}
		
		private function resetOutfit():void
		{
			//reset outfit
			for (var j:uint = 7; j <= 10; j++)
				traits[j] = 0;
		}
		
		private function getTraitName(i:uint):String
		{
			switch(i)
			{
			case 0:
				return "Class: ";
			case 1:
				return "Race: ";
			case 2:
				return "Gender: ";
			case 3:
				return "Skin Color: ";
			case 4:
				return "Eye Color: ";
			case 5:
				return "Hair Style: ";
			case 6:
				return "Hair Color: ";
			case 7:
				return "Accessory: ";
			case 8:
				return "Shirt: ";
			case 9:
				return "Pants: ";
			case 10:
				return "Shoes: ";
			case 11:
				return "Name: ";
			case 12:
				return "Done?";
			default:
				return "";
			}
		}
		
		private function getPickName(i:uint):String
		{
			var pick:uint = traits[i];
			switch (i)
			{
			case 0:
				return Main.data.lines[Main.data.classes[pick][12] + traits[2]];
			case 1:
				return Main.data.races[pick][0];
			case 2:
				if (pick == 0)
					return "Male";
				else
					return "Female";
			case 7:
			case 8:
			case 9:
			case 10:
				var outfitN:uint = Main.data.classes[traits[0]][11];
				var outfitP:uint = Main.data.featureLists[outfitN + (10 - i)][pick + 1];
				if (outfitP == Database.NONE)
					return "None";
				else
					return Main.data.outfitBits[outfitP][0];
			case 11:
				return cr.name;
			case 12:
				return "";
			default:
				return "" + pick;
			}
		}
		
		private function getTraitMax(i:uint):uint
		{
			var raceA:Array = Main.data.raceAppearances[Main.data.races[traits[1]][1]];
			switch(i)
			{
			case 0:
				return Main.data.classes.length;
			case 1:
				return Main.data.races.length;
			case 2:
				return 2;
			case 3:
				return Main.data.featureLists[raceA[2]].length - 1;
			case 4:
				return Main.data.featureLists[raceA[5]].length - 1;
			case 5:
				return Main.data.featureLists[raceA[6]].length - 1;
			case 6:
				return Main.data.featureLists[raceA[7]].length - 1;
			case 7:
			case 8:
			case 9:
			case 10:
				var outfitN:uint = Main.data.classes[traits[0]][11];
				return Main.data.featureLists[outfitN + (10 - i)].length - 1;
			default:
				return 0;
			}
		}
		
		private function generateCreature():void
		{
			cr = new Creature(traits[0], traits[1], true, level, 0);
			cr.setAppearance(traits);
			if (traits[11] != "")
				cr.name = traits[11];
		}
		
		public override function render():void
		{
			cr.renderAt(0, 0);
			
			//menu
			var y:Number = MENUTOP;
			y = renderHeader("STATS:", y);
			y = renderItem(0, y);
			y = renderItem(1, y);
			y = renderHeader("APPEARANCE:", y);
			y = renderItem(2, y);
			y = renderItem(3, y);
			y = renderItem(4, y);
			y = renderItem(5, y);
			y = renderItem(6, y);
			y = renderHeader("OUTFIT:", y);
			y = renderItem(7, y);
			y = renderItem(8, y);
			y = renderItem(9, y);
			y = renderItem(10, y);
			y = renderHeader("FINALIZE:", y);
			y = renderItem(11, y);
			y = renderItem(12, y);
		}
		
		private function renderHeader(str:String, y:Number, selected:Boolean = false):Number
		{
			var tx:Text = new Text(str);
			if (!selected)
				tx.color = TEXTNEUTRALCOLOR;
			else
				tx.color = TEXTSELECTEDCOLOR;
			tx.render(FP.buffer, new Point(0, y), new Point(0, 0));
			return y + tx.height;
		}
		
		private function renderItem(i:uint, y:Number):Number
		{
			return renderHeader(getTraitName(i) + getPickName(i), y, i == traitOn);
		}
	}

}