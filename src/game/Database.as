package game
{
	import net.flashpunk.graphics.Spritemap;
	public class Database 
	{
		//sprites
		[Embed(source = "sprites/bSheet.png")] private static const SPR1:Class;
		[Embed(source = "sprites/fSheet.png")] private static const SPR2:Class;
		[Embed(source = "sprites/pSheet.png")] private static const SPR3:Class;
		[Embed(source = "sprites/wSheet.png")] private static const SPR4:Class;
		[Embed(source = "sprites/tSheet.png")] private static const SPR5:Class;
		[Embed(source = "sprites/uSheet.png")] private static const SPR6:Class;
		[Embed(source = "sprites/mSheet.png")] private static const SPR7:Class;
		
		//files
		[Embed(source = "data/data.txt", mimeType = "application/octet-stream")] private static const DATA:Class;
		[Embed(source="data/lines.txt", mimeType = "application/octet-stream")] private static const LINES:Class;
		
		public static const NONE:uint = 9999;
		public static const SUBMOD:uint = 1000;
		public var spriteSheets:Array = new Array();
		public var lines:Array = new Array();
		public var types:Array = new Array();
		public var stats:Array = new Array();
		private var sheets:Array = new Array();
		public var progressionDatas:Array = new Array();
		public var features:Array = new Array();
		public var attacks:Array = new Array();
		public var races:Array = new Array();
		public var specials:Array = new Array();
		public var statusEffects:Array = new Array();
		public var derivedFormulas:Array = new Array();
		public var classes:Array = new Array();
		public var attackLists:Array = new Array();
		public var featureLists:Array = new Array();
		public var damageMults:Array = new Array();
		public var raceAppearances:Array = new Array();
		public var attackAnimMoveTypes:Array = new Array();
		public var attackAnims:Array = new Array();
		public var outfitBits:Array = new Array();
		public var nameGens:Array = new Array();
		public var tiles:Array = new Array();
		public var combinations:Array = new Array();
		public var items:Array = new Array();
		public var mapTypes:Array = new Array();
		public var itemTypes:Array = new Array();
		public var encounters:Array = new Array();
		
		public function Database() 
		{
			//read lines
			var lineNames:Array = new Array();
			var data:Array = new LINES().toString().split("\n");
			for (var i:uint = 0; i < data.length - 1; i++)
			{
				var line:String = data[i];
				if (line.charAt(0) != "/")
				{
					var lineName:String = "";
					var lineContent:String = "";
					var onName:Boolean = true;
					for (var j:uint = 0; j < line.length - 1; j++)
					{
						if (onName && line.charAt(j) == " ")
							onName = false;
						else if (onName)
							lineName += line.charAt(j);
						else
							lineContent += line.charAt(j);
					}
					lineNames.push(lineName);
					lines.push(lineContent);
				}
			}
			
			//read data
			
			data = new DATA().toString().split("\n");
			
			//analyze data
			var allArrays:Array = new Array();
			//remember to push each data array into allarrays
			//if you don't put something into allArrays, it won't be linked with anything
			
			allArrays.push(sheets);
			allArrays.push(types);
			allArrays.push(featureLists);
			allArrays.push(races);
			allArrays.push(attacks);
			allArrays.push(features);
			allArrays.push(classes);
			allArrays.push(mapTypes);
			allArrays.push(nameGens);
			allArrays.push(stats);
			allArrays.push(items);
			allArrays.push(itemTypes);
			allArrays.push(combinations);
			allArrays.push(specials);
			allArrays.push(derivedFormulas);
			allArrays.push(damageMults);
			allArrays.push(statusEffects);
			allArrays.push(tiles);
			allArrays.push(encounters);
			allArrays.push(attackLists);
			allArrays.push(raceAppearances);
			allArrays.push(attackAnims);
			allArrays.push(attackAnimMoveTypes);
			allArrays.push(progressionDatas);
			allArrays.push(outfitBits);
			
			var arrayOn:Array;
			for (i = 0; i < data.length; i++)
			{
				line = data[i];
				line = line.substr(0, line.length - 1);
				if (line.charAt(0) != "/")
				{
					switch(line)
					{
					case "ATTACKANIM:":
						arrayOn = attackAnims;
						break;
					case "ITEM:":
						arrayOn = items;
						break;
					case "ENCOUNTER:":
						arrayOn = encounters;
						break;
					case "ITEMTYPE:":
						arrayOn = itemTypes;
						break;
					case "NAMEGEN:":
						arrayOn = nameGens;
						break;
					case "ATTACKANIMMOVETYPE:":
						arrayOn = attackAnimMoveTypes;
						break;
					case "MAPTYPE:":
						arrayOn = mapTypes;
						break;
					case "TILE:":
						arrayOn = tiles;
						break;
					case "RACE:":
						arrayOn = races;
						break;
					case "PROGRESSIONDATA:":
						arrayOn = progressionDatas;
						break;
					case "RACEAPPEARANCE:":
						arrayOn = raceAppearances;
						break;
					case "FEATURELIST:":
						arrayOn = featureLists;
						break;
					case "COMBINATION:":
						arrayOn = combinations;
						break;
					case "CLASS:":
						arrayOn = classes;
						break;
					case "TYPE:":
						arrayOn = types;
						break;
					case "DAMAGEMULT:":
						arrayOn = damageMults;
						break;
					case "ATTACK:":
						arrayOn = attacks;
						break;
					case "ATTACKLIST:":
						arrayOn = attackLists;
						break;
					case "STAT:":
						arrayOn = stats;
						break;
					case "FEATURE:":
						arrayOn = features;
						break;
					case "SHEET:":
						arrayOn = sheets;
						break;
					case "STATUSEFFECT:":
						arrayOn = statusEffects;
						break;
					case "SPECIAL:":
						arrayOn = specials;
						break;
					case "DERIVEDFORMULA:":
						arrayOn = derivedFormulas;
						break;
					case "OUTFITBIT:":
						arrayOn = outfitBits;
						break;
					case "FILLERDATA:":
						arrayOn = new Array();
						break;
					default:
						//tbis is a data line
						var ar:Array = line.split(" ");
						var newEntry:Array = new Array();
						for (j = 0; j < ar.length; j++)
						{
							//see if it's a string or a number
							if (j == 0)
								newEntry.push(ar[j]); //it's the name
							else if (ar[j] == "none") //it's an empty reference
								newEntry.push(NONE);
							else if (ar[j] == "true")
								newEntry.push(1);
							else if (ar[j] == "false")
								newEntry.push(0);
							else if (isNaN(ar[j]))
							{
								var st:String = ar[j] as String;
								if (st.charAt(0) == "@") //it's a line!
								{
									if (ar[j] == "@none") //it's an empty line
										newEntry.push(NONE);
									else
									{
										//find the line
										var foundLine:Boolean = false;
										for (var k:uint = 0; k < lineNames.length; k++)
											if ("@" + lineNames[k] == ar[j])
											{
												foundLine = true;
												newEntry.push(k);
												break;
											}
										if (!foundLine)
										{
											trace("Unable to find line " + ar[j]);
											newEntry.push(NONE);
										}
									}
								}
								else
									newEntry.push(st);
							}
							else
								newEntry.push((uint) (ar[j]));
						}
						//push the finished list
						arrayOn.push(newEntry);
						break;
					}
				}
			}
			
			//link them
			link(allArrays);
			
			//load up spritesheets
			for (i = 0; i < sheets.length; i++)
			{
				var SRC:Class;
				switch(i)
				{
				case 0:
					SRC = SPR1;
					break;
				case 1:
					SRC = SPR2;
					break;
				case 2:
					SRC = SPR3;
					break;
				case 3:
					SRC = SPR4;
					break;
				case 4:
					SRC = SPR5;
					break;
				case 5:
					SRC = SPR6;
					break;
				case 6:
					SRC = SPR7;
					break;
				}
				
				var spr:Spritemap = new Spritemap(SRC, sheets[i][1], sheets[i][2]);
				spriteSheets.push(spr);
			}
		}
		
		private function link(allArrays:Array):void
		{
			for (var i:uint = 0; i < allArrays.length; i++)
			{
				var arrayOn:Array = allArrays[i];
				
				for (var j:uint = 0; j < arrayOn.length; j++)
				{
					var entry:Array = arrayOn[j];
					
					for (var k:uint = 1; k < entry.length; k++)
					{
						if (isNaN(entry[k]))
						{
							var st:String = entry[k] as String;
							if (st.charAt(0) == "#") //it's a literal word
							{
								var newSt:String = "";
								for (var l:uint = 1; l < st.length; l++)
								{
									if (st.charAt(l) == "#")
										newSt += " ";
									else
										newSt += st.charAt(l);
								}
								entry[k] = newSt;
							}
							else
							{
								//link it somewhere
								
								var found:Boolean = false;
								for (l = 0; l < allArrays.length && !found; l++)
								{
									var arrayCheck:Array = allArrays[l];
									
									for (var m:uint = 0; m < arrayCheck.length; m++)
									{
										if (arrayCheck[m][0] == st)
										{
											entry[k] = m;
											found = true;
											break;
										}
									}
								}
								
								if (!found)
									trace("Unable to find " + entry[k]);
							}
						}
					}
				}
			}
		}
	}

}