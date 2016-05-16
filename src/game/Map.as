package game 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.World;
	import net.flashpunk.FP;
	
	public class Map extends World
	{
		private var width:uint;
		private var height:uint;
		private var mapType:uint;
		
		private var heightAr:Array;
		private var walkers:Array;
		private var tilesAr:Array;
		private var pl:Walker;
		private var rampAr:Array;
		private var difficulty:uint;
		
		//generation constants
		private static const MAXHEIGHT:uint = 6;
		private static const AGREEREQUIREMENT:uint = 2;
		private static const SEBUFFER:uint = 5;
		private static const MINBLOBSIZE:uint = 6;
		private static const BRUSHSIZE:uint = 3;
		private static const FINEBRUSHCHANCE:Number = 0.4;
		private static const RANDOMWALKCHANCE:Number = 0.25;
		private static const MAXWALKSTEPS:uint = 150;
		private static const BORDERSIZE:uint = 20;
		private static const BELOWLOOK:uint = 3;
		
		//appearance constants
		private static const TILEDARKENFACTOR:Number = 0.3;
		
		public function Map(oldPl:Walker, diff:uint = 1) 
		{
			mapType = 0;
			
			Saver.openProfile("test");
			if (Saver.profileContents.length > 0 && !oldPl)
			{
				loadMap(Saver.profileContents);
			}
			else
			{
				difficulty = diff;
				mapGenerate(120, 80, oldPl);
				if (newPartyMember)
					saveMap(Saver.newProfileContents);
			}
			Saver.closeProfile();
		}
		
		private function get newPartyMember():Boolean
		{
			//for now just auto do this if the party size is lower than the difficulty
			return pl.partySize < difficulty && pl.partySize < Battle.MAXPARTY;
			//return pl.partySize == 0;
		}
		
		public function addPartyMember(cr:Creature):void
		{
			pl.addPartyMember(cr);
			Saver.openProfile("test");
			saveMap(Saver.newProfileContents);
			Saver.closeProfile();
		}
		
		private function loadMap(loadFrom:Array):void
		{
			var p:uint = 0;
			
			width = loadFrom[p++];
			height = loadFrom[p++];
			difficulty = loadFrom[p++];
			mapType = loadFrom[p++];
			
			heightAr = new Array();
			rampAr = new Array();
			tilesAr = new Array();
			walkers = new Array();
			for (var i:uint = 0; i < width * height; i++)
			{
				heightAr.push(loadFrom[p++]);
				rampAr.push(loadFrom[p++]);
				tilesAr.push(loadFrom[p++]);
				if (loadFrom[p++])
				{
					var isPlayer:Boolean = loadFrom[p++];
					p = Walker.load(loadFrom, p, walkers);
					if (isPlayer)
						pl = walkers[walkers.length - 1];
				}
				else
					walkers.push(null);
			}
		}
		
		private function saveMap(saveTo:Array):void
		{
			saveTo.push(width);
			saveTo.push(height);
			saveTo.push(difficulty);
			saveTo.push(mapType);
			
			for (var i:uint = 0; i < width * height; i++)
			{
				saveTo.push(heightAr[i]);
				saveTo.push(rampAr[i]);
				saveTo.push(tilesAr[i]);
				if (walkers[i])
				{
					saveTo.push(true);
					saveTo.push(walkers[i] == pl);
					(walkers[i] as Walker).save(saveTo);
				}
				else
					saveTo.push(false);
			}
		}
		
		public override function update():void
		{
			if (newPartyMember)
			{
				//add the first party member
				FP.world = new PartyGen(Battle.getProgressionData(difficulty)[6]);
				return;
			}
			
			
			if (pl.x > width - BORDERSIZE && !pl.animating)
			{
				//they have entered the next map
				(FP.engine as Main).loadMap(pl, difficulty + 1);
				return;
			}
			
			pl.playerInput();
			
			for (var i:uint = 0; i < width * height; i++)
				if (walkers[i])
				{
					if (walkers[i].dead)
						walkers[i] = null;
					else
						walkers[i].update();
				}
		}
		
		public function finishMove(x:uint, y:uint):void
		{
			walkers[toI(x, y)] = null;
		}
		
		public function walkerAt(x:uint, y:uint):Walker
		{
			if (x >= width || y >= height)
				return null;
			return walkers[toI(x, y)];
		}
		
		public function tryMove(startX:uint, startY:uint, endX:uint, endY:uint):Boolean
		{
			if (endX >= width || endY >= height || endX < BORDERSIZE)
				return false;
			var startI:uint = toI(startX, startY);
			var endI:uint = toI(endX, endY);
			if (walkers[endI])
				return false; //its occupied
			var startHeight:uint = heightAr[startI];
			var endHeight:uint = heightAr[endI];
			var valid:Boolean;
			if (startHeight >= endHeight)
				valid = true; //you are either walking off a cliff, or going constant; easy
			else if (startHeight < endHeight - 1)
				valid = false; //it's too far to go up, even with a ramp
			else
				valid = rampAr[endI];
				
			if (valid)
				walkers[endI] = walkers[startI];
			return valid;
		}
		
		public static function get tileWidth():uint { return Main.data.spriteSheets[4].width; }
		public static function get tileHeight():uint { return Main.data.spriteSheets[4].height; }
		public static function get underTileHeight():uint { return Main.data.spriteSheets[5].height; }
		public function getHeightNum(x:uint, y:uint):Number
		{
			var hNum:Number = heightAr[toI(x, y)] * underTileHeight * 2 + MAXHEIGHT * tileHeight;
			if (rampAr[toI(x, y)])
				hNum -= underTileHeight;
			if (rampAr[toI(pl.x, pl.y)])
				hNum += underTileHeight;
			return hNum;
		}
		
		public override function render():void
		{
			if (newPartyMember)
				return; //dont draw anything before they select a first party member
			
			/**
			renderPreview();
			return;
			/**/
			
			var playerHeight:uint = heightAr[toI(pl.x, pl.y)];
			var xPro:uint = 0;
			if (pl.xS != 0)
				xPro = 1;
			var yPro:uint = 0;
			if (pl.yS != 0)
				yPro = 1;
			var renderXStart:int = pl.x - FP.halfWidth / tileWidth - xPro;
			var renderYStart:int = pl.y - MAXHEIGHT - FP.halfHeight / tileHeight - yPro;
			var xW:uint = FP.width / tileWidth + 2 * xPro;
			var yH:uint = FP.height / tileHeight + MAXHEIGHT * 2 + 2 * yPro;
			if (renderXStart < 0)
				renderXStart = 0;
			if (renderYStart < 0)
				renderYStart = 0;
			if (renderXStart + xW > width)
				renderXStart = width - xW;
			if (renderYStart + yH > height)
				renderYStart = height - yH;
				
			var toDraw:Array = new Array();
			for (var y:uint = 0; y < yH; y++)
				for (var x:uint = 0; x < xW; x++)
					toDraw.push(toI(x + renderXStart, y + renderYStart));
			
			toDraw.sort(drawSort);
			
			FP.camera.x = (renderXStart + xPro) * tileWidth - pl.xS;
			FP.camera.y = (renderYStart + yPro) * tileHeight - pl.yS;
		
			for (var j:uint = 0; j < toDraw.length; j++)
			{
				var i:uint = toDraw[j];
				
				x = toX(i);// - renderXStart;
				y = toY(i);// - renderYStart;
				var h:uint = heightAr[i];
					
				var drawX:Number = x * tileWidth;
				var drawY:Number = y * tileHeight - getHeightNum(x, y);
				
				var tile:uint = tilesAr[i];
				getTileSheet(tile, i, rampAr[i]).render(FP.buffer, new Point(drawX, drawY), FP.camera);
				var underTile:uint = Main.data.tiles[tile][4];
				
				var underTiles:uint = 0;
				if (y < height - 1)
				{
					if (heightAr[i + width] < h)
						underTiles = 2 * (h - heightAr[i + width]);
					if (rampAr[i + width] && heightAr[i + width] <= h)
						underTiles += 1;
					if (rampAr[i] && underTiles > 0)
						underTiles -= 1;
				}
				
				var underSheet:Spritemap = getTileSheet(underTile, i, false);
				for (var k:uint = 0; k < underTiles; k++)
					underSheet.render(FP.buffer, new Point(drawX, drawY + tileHeight + underTileHeight * k), FP.camera);
					
				if (walkers[i])
					walkers[i].render();
			}
			
			pl.renderInventory();
		}
		
		private function getTileSheet(tile:uint, i:uint, ramp:Boolean):Spritemap
		{
			var h:uint = heightAr[i];
			var sheet:Spritemap = Main.data.spriteSheets[Main.data.tiles[tile][1]];
			sheet.frame = Main.data.tiles[tile][2];
			var hFactor:Number = h;
			if (ramp)
				hFactor -= 0.5;
			sheet.color = FP.colorLerp(0x000000, Main.data.tiles[tile][3],
							1 - TILEDARKENFACTOR + TILEDARKENFACTOR * hFactor / MAXHEIGHT);
			return sheet;
		}
		
		public function drawSort(a:uint, b:uint):int
		{
			if (heightAr[a] > heightAr[b])
				return 1;
			else if (heightAr[b] > heightAr[a])
				return -1;
			
			var aY:int = toY(a);// - heightAr[a];
			var bY:int = toY(b);// - heightAr[b];
			if (aY > bY)
				return 1;
			else if (bY > aY)
				return -1;
			var aX:uint = toX(a);
			var bX:uint = toX(b);
			if (aX > bX)
				return -1;
			else if (bX > aX)
				return 1;
			else
				return 0;
		}
		
		public function get playerParty():Array { return pl.getParty(); }
		
		private function renderPreview():void
		{
			for (var y:uint = 0; y < height; y++)
				for (var x:uint = 0; x < width; x++)
				{
					var at:uint = heightAr[toI(x, y)];
					var c:uint = FP.colorLerp(0x111111, 0xFFFFFF, at * 1.0 / MAXHEIGHT);
					if (rampAr[toI(x, y)])
						c = 0x0000FF;
						
					FP.buffer.fillRect(new Rectangle(5 * x, 5 * y, 5, 5), c);
				}
		}
		
		private function mapGenerate(w:uint, h:uint, oldPl:Walker):void
		{
			//map variables
			var maxHeight:uint = 4;
			var smoothRounds:uint = 3;
			
			if (maxHeight > MAXHEIGHT - 2)
			{
				trace("INVALID MAX HEIGHT " + maxHeight);
				maxHeight = MAXHEIGHT - 2;
			}
			
			width = w + smoothRounds * 2;
			height = h + smoothRounds * 2;
			
			heightAr = new Array();
			for (var i:uint = 0; i < width * height; i++)
				heightAr.push(0);
			for (var y:uint = 0; y < height; y += BRUSHSIZE)
				for (var x:uint = 0; x < width; x += BRUSHSIZE)
				{
					var hP:uint = Math.random() * (maxHeight + 1);
					for (var y2:uint = 0; y2 < BRUSHSIZE; y2++)
						for (var x2:uint = 0; x2 < BRUSHSIZE; x2++)
							heightAr[toI(x + x2, y + y2)] = hP;
				}
			for (i = 0; i < width * height; i++)
				if (Math.random() < FINEBRUSHCHANCE)
				{
					hP = Math.random() * (maxHeight + 1);
					heightAr[i] = hP;
				}
			
			//now do a few rounds of a quick cellular smooth
			for (i = 0; i < smoothRounds; i++)
				heightAr = smooth(heightAr);
				
			//pick a start and an end
			var startY:uint = Math.random() * (height - SEBUFFER * 2) + SEBUFFER;
			var endY:uint = Math.random() * (height - SEBUFFER * 2) + SEBUFFER;
			
			removeTinyBlobs();
			rampAr = rampGenerate(toI(0, startY), toI(width - 1, endY), maxHeight + 2);
			if (!rampAr)
			{
				//it was unable to generate a path
				//so start over
				heightAr = null;
				return mapGenerate(w, h, oldPl);
			}
			
			//recut
			var yAdd:int = recutMap(maxHeight + 2);
			startY += yAdd;
			endY += yAdd;
			makeExit(startY, endY);
			
			//get the tile identities
			var tileset:uint = Main.data.mapTypes[mapType][1];
			var upperTile:uint = Main.data.featureLists[tileset][1];
			var otherTiles:Array = new Array();
			for (i = 2; i < Main.data.featureLists[tileset].length; i++)
				otherTiles.push(Main.data.featureLists[tileset][i]);
			
			//actually give everything a tile identity
			tilesAr = new Array();
			for (i = 0; i < width * height; i++)
			{
				var tPick:uint = Math.random() * otherTiles.length;
				tPick = otherTiles[tPick];
				tilesAr.push(tPick);
			}
			
			//smooth the tile identity
			for (i = 0; i < smoothRounds; i++)
				identitySmooth();
			
			//place the upper tiles
			for (i = 0; i < width * height; i++)
				if (heightAr[i] == maxHeight + 2)
					tilesAr[i] = upperTile;
			
			//prepare walkers
			walkers = new Array();
			for (i = 0; i < width * height; i++)
				walkers.push(null);
			
			if (oldPl)
			{
				pl = oldPl;
				pl.teleportTo(BORDERSIZE, startY);
			}
			else
			{
				pl = new Walker(BORDERSIZE, startY, 1, false, new Array());
				pl.inventoryAdd(new Item(1, 3));
				pl.inventoryAdd(new Item(0, 2));
				var fAt:Item = new Item();
				fAt.fromAttack(7);
				pl.inventoryAdd(fAt);
			}
			walkers[toI(BORDERSIZE, startY)] = pl;
			
			
			//make some enemy encounters
			for (i = 0; i < 15; i++)
				while (true)
				{
					var j:uint = Math.random() * height * width;
					if (!walkers[j] && heightAr[j] <= maxHeight && toX(j) < width - BORDERSIZE)
					{
						walkers[j] = new Walker(toX(j), toY(j), difficulty, false, null, Main.data.encounters.length * Math.random());
						break;
					}
				}
		}
		
		private function identitySmooth():void
		{
			var tId:Array = new Array();
			for (var i:uint = 0; i < width * height; i++)
				tId.push(tilesAr[i]);
				
			for (var y:uint = 1; y < height - 1; y++)
				for (var x:uint = 1; x < width - 1; x++)
				{
					var around:Array = new Array();
					var at:uint = tilesAr[toI(x, y)];
					around.push(tilesAr[toI(x - 1, y)]);
					around.push(tilesAr[toI(x + 1, y)]);
					around.push(tilesAr[toI(x, y - 1)]);
					around.push(tilesAr[toI(x, y + 1)]);
					
					var neighborsAgree:uint = 0;
					for (i = 0; i < around.length; i++)
						if (around[i] == at)
							neighborsAgree += 1;
					
					if (neighborsAgree <= around.length - AGREEREQUIREMENT)
					{
						var tPick:uint = Math.random() * around.length;
						tId[toI(x, y)] = around[tPick];
					}
				}
			tilesAr = tId;
		}
		
		private function makeExit(startY:uint, endY:uint):void
		{
			var exitHeight:uint = heightAr[toI(width - 1 - BORDERSIZE, endY)];
			for (var x:uint = width - BORDERSIZE; x < width; x++)
				for (var y:uint = endY - 1; y <= endY + 1; y++)
					heightAr[toI(x, y)] = exitHeight;
			//make fake enterance too
			for (x = 0; x < BORDERSIZE; x++)
				for (y = startY - 1; y <= startY + 1; y++)
					heightAr[toI(BORDERSIZE - x - 1, y)] -= 1;
		}
		
		private function recutMap(fillHeight:uint):int
		{
			var t:uint = height;
			var b:uint = 0;
			var l:uint = width;
			var r:uint = 0;
			
			for (var y:uint = 0; y < height; y++)
				for (var x:uint = 0; x < width; x++)
					if (heightAr[toI(x, y)] != fillHeight)
					{
						if (x < l)
							l = x;
						if (x > r)
							r = x;
						if (y < t)
							t = y;
						if (y > b)
							b = y;
					}
					
			var newHeightAr:Array = new Array();
			var newRampAr:Array = new Array();
			var newWidth:uint = r - l + 1 + BORDERSIZE * 2;
			var newHeight:uint = b - t + 1 + BORDERSIZE * 2;
			for (var i:uint = 0; i < newWidth * newHeight; i++)
			{
				newHeightAr.push(fillHeight);
				newRampAr.push(false);
			}
			for (y = t; y <= b; y++)
				for (x = l; x <= r; x++)
				{
					var oldI:uint = toI(x, y);
					var newI:uint = (BORDERSIZE + x - l) + (BORDERSIZE + y - t) * newWidth;
					newHeightAr[newI] = heightAr[oldI];
					newRampAr[newI] = rampAr[oldI];
				}
			
			heightAr = newHeightAr;
			rampAr = newRampAr;
			width = newWidth;
			height = newHeight;
			
			return BORDERSIZE - t;
		}
		
		private function toX(i:uint):uint { return i % width; }
		private function toY(i:uint):uint { return i / width; }
		private function toI(x:uint, y:uint):uint { return x + y * width; }
		
		private function smooth(ar:Array):Array
		{
			var newAr:Array = new Array();
			for (var y:uint = 1; y < height - 1; y++)
				for (var x:uint = 1; x < width - 1; x++)
				{
					var i:uint = toI(x, y);
					var neighbors:Array = [ar[i - 1], ar[i + 1], ar[i - width], ar[i + width]];
					var at:uint = ar[i];
					
					//if there are enougb neighbors of a given height, change to that
					var neighborsFreq:Array = new Array();
					for (var j:uint = 0; j <= MAXHEIGHT; j++)
						neighborsFreq.push(0);
					for (j = 0; j < neighbors.length; j++)
						neighborsFreq[neighbors[j]] += 1;
					var mostCommonNeighbor:uint = 0;
					for (j = 0; j < neighborsFreq.length; j++)
						if (neighborsFreq[j] >= neighborsFreq[mostCommonNeighbor])
							mostCommonNeighbor = j;
					if (neighborsFreq[mostCommonNeighbor] >= AGREEREQUIREMENT)
						at = mostCommonNeighbor;
					
					newAr.push(at);
				}
				
			width -= 2;
			height -= 2;
			return newAr;
		}
		
		
		// ramp generate and friends
		private function getBlobs(beginI:uint, endI:uint):Array
		{
			var blobs:Array = new Array();
			var blobNumberLookup:Array = new Array();
			var beginBlob:uint;
			var endBlob:uint;
			
			for (var i:uint = 0; i < width * height; i++)
				blobNumberLookup.push(Database.NONE);
			
			for (i = 0; i < width * height; i++)
				if (blobNumberLookup[i] == Database.NONE)
				{
					//this is the start of a new blob!
					var blobHeight:uint = heightAr[i];
					var blobSquares:Array = new Array();
					
					//find the exact size
					var bIQ:Array = new Array();
					bIXRegister(i, 0, 0, bIQ, blobSquares, blobNumberLookup, blobs.length, blobHeight);
					
					while (bIQ.length > 0)
					{
						var bIX:uint = bIQ.pop();
						
						if (bIX == beginI)
							beginBlob = blobs.length;
						else if (bIX == endI)
							endBlob = blobs.length;
							
						bIXRegister(bIX, -1, 0, bIQ, blobSquares, blobNumberLookup, blobs.length, blobHeight);
						bIXRegister(bIX, 1, 0, bIQ, blobSquares, blobNumberLookup, blobs.length, blobHeight);
						bIXRegister(bIX, 0, -1, bIQ, blobSquares, blobNumberLookup, blobs.length, blobHeight);
						bIXRegister(bIX, 0, 1, bIQ, blobSquares, blobNumberLookup, blobs.length, blobHeight);
					}
					
					blobs.push(blobSquares);
				}
				
			return new Array(blobs, blobNumberLookup, beginBlob, endBlob);
		}
		
		private function removeTinyBlobs():void
		{
			//first, get the blobs
			var blobGetData:Array = getBlobs(0, 0);
			var blobs:Array = blobGetData[0];
			var blobNumberLookup:Array = blobGetData[1];
			
			for (var i:uint = 0; i < blobs.length; i++)
				if (blobs[i].length < MINBLOBSIZE)
				{
					var blob:Array = blobs[i];
					var neighbors:Array = new Array();
					for (var j:uint = 0; j < blob.length; j++)
					{
						for (var k:uint = 0; k < 4; k++)
						{
							var xA:int = 0;
							var yA:int = 0;
							switch(k)
							{
							case 0:
								if (toX(blob[j]) > 0)
									xA = -1;
								break;
							case 1:
								if (toY(blob[j]) > 0)
									yA = -1;
								break;
							case 2:
								if (toX(blob[j]) < width - 1)
									xA = 1;
								break;
							case 3:
								if (toY(blob[j]) < height - 1)
									yA = 1;
								break;
							}
							var posNe:uint = toI(toX(blob[j]) + xA, toY(blob[j]) + yA);
							if (blobNumberLookup[posNe] != i)
								neighbors.push(posNe);
						}
					}
					
					if (neighbors.length == 0)
						trace("Neighbor detect error");
					
					var neighbor:uint = Math.random() * neighbors.length;
					neighbor = neighbors[neighbor];
					var nHeight:uint = heightAr[neighbor];
					var nBlob:uint = blobNumberLookup[neighbor];
					//change every square of the blob to be this new height
					for (j = 0; j < blob.length; j++)
					{
						heightAr[blob[j]] = nHeight;
						blobs[nBlob].push(blob[j]);
						blobNumberLookup[blob[j]] = nBlob;
					}
					blobs[i] = new Array(); //it's empty now
				}
		}
		
		private function rampGenerate(beginI:uint, endI:uint, fillHeight:uint):Array
		{
			//first, get the blobs
			var blobGetData:Array = getBlobs(beginI, endI);
			var blobs:Array = blobGetData[0];
			var blobNumberLookup:Array = blobGetData[1];
			var beginBlob:uint = blobGetData[2];
			var endBlob:uint = blobGetData[3];
				
			//now find the links between blobs
			var blobUpLinks:Array = new Array();
			var blobDownLinks:Array = new Array();
			for (var i:uint = 0; i < blobs.length; i++)
			{
				var bUL:Array = new Array();
				var bDL:Array = new Array();
				for (var j:uint = 0; j < blobs.length; j++)
				{
					bUL.push(new Array());
					bDL.push(new Array());
				}
				blobUpLinks.push(bUL);
				blobDownLinks.push(bDL);
			}
			for (i = 0; i < width * height; i++)
				blobLink(i, blobUpLinks[blobNumberLookup[i]], blobDownLinks[blobNumberLookup[i]], blobNumberLookup);
			
			//now clean up a bit
			cleanLinks(blobUpLinks);
			cleanLinks(blobDownLinks);
			
			//initialize ramp array
			var rampAr:Array = new Array();
			for (i = 0; i < width * height; i++)
				rampAr.push(false);
			
			//now that you have the links, move around
			var blobPathing:Array = getBlobPathing(blobs, blobUpLinks, blobDownLinks, endBlob);
			var blobOn:uint = beginBlob;
			var relevantBlobs:Array = new Array();
			for (i = 0; i < blobs.length; i++)
				relevantBlobs.push(false);
			var terminator:uint = 0;
			while (blobOn != endBlob)
			{
				terminator += 1;
				if (terminator == MAXWALKSTEPS)
				{
					trace("INVALID PATH");
					return null;
				}
				
				relevantBlobs[blobOn] = true;
				
				var hasDown:Boolean = false;
				for (i = 0; i < blobs.length; i++)
					if (blobDownLinks[blobOn][i] != Database.NONE)
					{
						hasDown = true;
						break;
					}
				
				var blobNew:uint;
				if (true || (hasDown && Math.random() > RANDOMWALKCHANCE))
				{
					//go for the shortest path
					blobNew = blobPathing[blobOn];
					
					if (blobNew == Database.NONE)
					{
						trace("INVALID PATH");
						return null;
					}
				}
				else
				{
					//random walk
					var possibleTo:Array = new Array();
					getLinksTo(blobUpLinks, blobOn, possibleTo);
					getLinksTo(blobDownLinks, blobOn, possibleTo);
					
					var pick:uint = Math.random() * possibleTo.length;
					blobNew = possibleTo[pick];
				}
				
				//if it's an up link, activate the ramp
				var uLink:uint = blobUpLinks[blobOn][blobNew];
				if (uLink != Database.NONE)
				{
					//it is an up link!
					rampAr[uLink] = true;
				}
				
				relevantBlobs[blobNew] = true;
				blobOn = blobNew;
			}
			
			for (i = 0; i < blobs.length; i++)
				if (!relevantBlobs[i])
					for (j = 0; j < blobs[i].length; j++)
						heightAr[blobs[i][j]] = fillHeight;
			
			return rampAr;
		}
		
		private function getLinksTo(links:Array, from:uint, to:Array):void
		{
			for (var i:uint = 0; i < links[from].length; i++)
				if (links[from][i] != Database.NONE)
					to.push(i);
		}
		
		private function getBlobPathing(blobs:Array, blobUpLinks:Array, blobDownLinks:Array, around:uint):Array
		{
			var explored:Array = new Array();
			var fromAr:Array = new Array();
			for (var i:uint = 0; i < blobs.length; i++)
			{
				explored.push(Database.NONE);
				fromAr.push(Database.NONE);
			}
				
			var iQ:Array = new Array();
			explored[around] = 0;
			iQ.push(around);
			
			while (iQ.length > 0)
				blobExploreInner(iQ, blobUpLinks, blobDownLinks, explored, fromAr);
			
			return fromAr;
		}
		
		private function blobExploreInner(iQ:Array, blobUpLinks:Array, blobDownLinks:Array, explored:Array, fromAr:Array):void
		{
			var i:uint = iQ.pop();
			
			blobExploreLinks(i, iQ, blobUpLinks, explored, fromAr);
			blobExploreLinks(i, iQ, blobDownLinks, explored, fromAr);
		}
		
		private function blobExploreLinks(i:uint, iQ:Array, links:Array, explored:Array, fromAr:Array):void
		{
			var d:uint = explored[i] + 1;
			for (var j:uint = 0; j < links.length; j++)
			{
				var link:uint = links[j][i];
				if (link != Database.NONE && explored[j] > d)
				{
					iQ.push(j);
					fromAr[j] = i;
					explored[j] = d;
				}
			}
		}
		
		private function cleanLinks(links:Array):void
		{
			for (var i:uint = 0; i < links.length; i++)
			{
				var lnk:Array = links[i];
				for (var j:uint = 0; j < lnk.length; j++)
				{
					var l:Array = lnk[j];
					if (l.length > 0)
					{
						//there are many links, so pick one and remove all the others
						var pick:uint = Math.random() * l.length;
						var nL:Array = new Array();
						lnk[j] = l[pick];
					}
					else
						lnk[j] = Database.NONE;
				}
			}
		}
		
		private function blobLink(i:uint, upLinks:Array, downLinks:Array, blobNumberLookup:Array):void
		{
			for (var k:uint = 0; k < 4; k++)
			{
				var xA:int = 0;
				var yA:int = 0;
				switch(k)
				{
				case 0:
					if (toX(i) > 0)
						xA = -1;
					break;
				case 1:
					if (toY(i) > 0)
						yA = -1;
					break;
				case 2:
					if (toX(i) < width - 1)
						xA = 1;
					break;
				case 3:
					if (toY(i) < height - 1)
						yA = 1;
					break;
				}
				if (xA != 0 || yA != 0)
				{
					var neighbor:uint = toI(toX(i) + xA, toY(i) + yA);
					if (blobNumberLookup[neighbor] != blobNumberLookup[i])
					{
						var aBlob:uint = blobNumberLookup[i];
						var nBlob:uint = blobNumberLookup[neighbor];
						var aHeight:uint = heightAr[i];
						var nHeight:uint = heightAr[neighbor];
						if (belowClear(neighbor, aBlob, nBlob, blobNumberLookup) && (aHeight > nHeight ||
							Math.abs(nHeight - aHeight) == 1)) //a ramp can only go up one height difference
						{
							var addTo:Array;
							if (aHeight > nHeight)
								addTo = downLinks[nBlob];
							else
								addTo = upLinks[nBlob];
							addTo.push(neighbor);
						}
					}
				}
			}
		}
		
		private function belowClear(i:uint, aBlob:uint, nBlob:uint, bnl:Array):Boolean
		{
			if (toY(i) >= height - BELOWLOOK)
				return false;
			for (var j:uint = 1; j <= BELOWLOOK; j++)
			{
				var b:uint = bnl[i + width * j];
				if (b != nBlob && b != aBlob)
					return false;
			}
			return true;
		}
		
		private function bIXRegister(bIX:uint, xA:int, yA:int, bIQ:Array, blobSquares:Array, blobNumberLookup:Array, blobNumber:uint, blobHeight:uint):void
		{
			var x:uint = toX(bIX);
			var y:uint = toY(bIX);
			if ((x == 0 && xA == -1) || (y == 0 && yA == -1) || (x == width - 1 && xA == 1) || (y == height - 1 && yA == 1))
				return;
			var newI:uint = toI(x + xA, y + yA);
			if (blobNumberLookup[newI] != Database.NONE)
				return;
			if (heightAr[newI] != blobHeight)
				return;
				
			blobSquares.push(newI);
			bIQ.push(newI);
			blobNumberLookup[newI] = blobNumber;
		}
	}

}