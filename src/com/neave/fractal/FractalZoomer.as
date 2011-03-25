package com.neave.fractal
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.Timer;

	public final class FractalZoomer
	{
		// Main constants
		private const ZOOM_INC:Number = 1.125; // The amount to increment when zooming in
		private const MIN_ZOOM:Number = 6; // Start at a higher zoom level
		private const KEY_STEP:uint = 16; // How much to pan with each key press
		private const TILE_SIZE:uint = 64; // The bitamp is split into tiles of this size
		
		// Main variables
		private var stage:Stage;
		private var crosshair:Crosshair;
		private var drawComplete:Boolean;
		private var dragBitmap:Boolean;
		private var dragPoint:Point;
		private var keyX:Number = 0;
		private var keyY:Number = 0;
		private var keyZ:Number = 1;
		private var tileColumns:uint;
		private var tileRows:uint;
		private var tileCount:uint;
		private var tileOrder:Array;
		private var timer:Timer;
		private var keyTimer:Timer;
		private var mb:MandelbrotSet;
		private var bitmap:Bitmap;
		private var bitmapData:BitmapData;
		private var bitmapX:int;
		private var bitmapY:int;
		
		public function FractalZoomer(stage:Stage)
		{
			this.stage = stage;
			
			initStage();
			initMandelbrot();
			initTimer();
			addCrosshair();
			onResize(null);
			
			setTileOrder();
			drawFirstTile();
			
			Mouse.cursor = MouseCursor.HAND;
		}
		
		private function initStage():void
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
		
		private function initMandelbrot():void
		{
			setColsRows();
			bitmap = new Bitmap();
			initBitmap();
			stage.addChild(bitmap);
			
			mb = new MandelbrotSet(bitmapData, 0, -0.6, 1);
			mb.addEventListener(MandelbrotSet.DRAW_COMPLETED, onDrawCompleted);
			zoom(MIN_ZOOM);
		}
		
		private function setColsRows():void
		{
			tileColumns = Math.ceil(stage.stageWidth / TILE_SIZE);
			tileRows = Math.ceil(stage.stageHeight / TILE_SIZE);
		}
		
		private function initBitmap():void
		{
			bitmapData = bitmap.bitmapData = new BitmapData(tileColumns * TILE_SIZE, tileRows * TILE_SIZE, false, 0xff000a00);
		}
		
		private function initTimer():void
		{
			// Update display as often as possible
			timer = new Timer(1, 0);
			timer.addEventListener(TimerEvent.TIMER, update);
			
			// Update key presses a little less quickly
			keyTimer = new Timer(16, 0);
			keyTimer.addEventListener(TimerEvent.TIMER, keyUpdate);
		}
		
		private function addCrosshair():void
		{
			crosshair = new Crosshair();
			stage.addChild(crosshair);
		}
		
		private function setTileOrder():void
		{
			tileOrder = new Array();
			
			for (var x:uint = tileColumns; x--; )
			{
				var dx:Number = (tileColumns / 2 - x - 0.5) * TILE_SIZE;
				
				for (var y:uint = tileRows; y--; )
				{
					var dy:Number = (tileRows / 2 - y - 0.5) * TILE_SIZE;
					tileOrder.push( { x:x, y:y, d:dx * dx + dy * dy } );
				}
			}
			
			// Sort order of tiles based on distance from center
			tileOrder.sortOn("d", Array.NUMERIC);
		}
		
		private function drawFirstTile():void
		{
			timer.reset();
			timer.start();
			
			drawComplete = false;
			tileCount = 0;
			drawNextTile();
		}
		
		private function drawNextTile():void
		{
			drawTile(tileOrder[tileCount].x, tileOrder[tileCount].y);
			
			// If this is the last tile, don't draw the next one
			if (tileCount < tileOrder.length - 1)
			{
				tileCount++;
			}
			else
			{
				drawComplete = false;
				tileCount = 0;
				timer.stop();
			}
		}
		
		private function drawTile(x:uint, y:uint):void
		{
			mb.draw
			(
				new Rectangle(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE),
				x * 2 / mb.z - (tileColumns - 1),
				y * 2 / mb.z - (tileRows - 1),
				0
			);
		}
		
		private function clearBitmap():void
		{
			bitmapData.fillRect(bitmapData.rect, 0xff000a00);
		}
		
		private function zoom(inc:Number):void
		{
			var mbz:Number = mb.z * inc;
			
			if (mbz < MIN_ZOOM || inc > MandelbrotSet.MAX_ZOOM) return;
			
			mb.z = mbz;
			
			// Re-center bitmap after zooming
			mb.x += (tileColumns - 1) * (inc - 1) / mbz;
			mb.y += (tileRows - 1) * (inc - 1) / mbz;
			
			bitmapData.lock();
			
			// Draw the zoomed bitmap back into the bitmap
			var zoomBitmapData:BitmapData = bitmapData.clone();
			var m:Matrix = new Matrix();
			m.scale(inc, inc);
			m.translate((1 - inc) * bitmapData.width / 2, (1 - inc) * bitmapData.height / 2);
			
			// Zooming in or out?
			if (inc < 1)
			{
				clearBitmap();
				bitmapData.draw(zoomBitmapData, m, null, null, null, false);
			}
			else
			{
				bitmapData.draw(zoomBitmapData, m, null, null, null, true);
			}
			
			zoomBitmapData.dispose();
			bitmapData.unlock();
		}
		
		public function zoomIn():void
		{
			// Only redraw if zoom value has changed
			var mbz:Number = mb.z;
			zoom(ZOOM_INC);
			if (mb.z != mbz) drawFirstTile();
		}
		
		public function zoomOut():void
		{
			// Only redraw if zoom value has changed
			var mbz:Number = mb.z;
			zoom(1 / ZOOM_INC);
			if (mb.z != mbz) drawFirstTile();
		}
		
		private function pan(x:Number, y:Number):void
		{
			bitmapData.lock();
			
			var panSrc:BitmapData = bitmapData.clone();
			var m:Matrix = new Matrix();
			m.translate(x, y);
			
			// Redraw the bitmap into this position
			clearBitmap();
			bitmapData.draw(panSrc, m, null, null, null, false);
			
			panSrc.dispose();
			bitmapData.unlock();
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			dragBitmap = true;
			dragPoint = new Point(stage.mouseX, stage.mouseY);
		}
		
		private function onMouseMove(event:MouseEvent):void
		{
			if (!dragBitmap) return;
			
			bitmap.x = int(stage.mouseX - dragPoint.x + bitmapX);
			bitmap.y = int(stage.mouseY - dragPoint.y + bitmapY);
			event.updateAfterEvent();
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			if (!dragBitmap) return;
			
			// Find the bitmap's new position
			dragBitmap = false;
			bitmap.x = bitmapX;
			bitmap.y = bitmapY;
			
			// Redraw the bitmap in this position
			var dx:int = int(dragPoint.x - stage.mouseX);
			var dy:int = int(dragPoint.y - stage.mouseY);
			if (dx != 0 || dy != 0)
			{
				// Dragging occured, redraw the bitmap
				mb.x += dx * 2 / (TILE_SIZE * mb.z);
				mb.y += dy * 2 / (TILE_SIZE * mb.z);
				pan(-dx, -dy);
			}
			else
			{
				// No dragging occured so instead re-center the view on mouse click position
				mb.x += (stage.mouseX * 2 - stage.stageWidth) / (TILE_SIZE * mb.z);
				mb.y += (stage.mouseY * 2 - stage.stageHeight) / (TILE_SIZE * mb.z);
				pan(stage.stageWidth / 2 - stage.mouseX, stage.stageHeight / 2 - stage.mouseY);
			}
			
			drawFirstTile();
		}
		
		private function onMouseWheel(event:MouseEvent):void
		{
			if (event.delta > 0) zoomIn();
			else zoomOut();
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{		
				case Keyboard.LEFT:
					keyX = -KEY_STEP;
					break;
				
				case Keyboard.RIGHT:
					keyX = KEY_STEP;
					break;
				
				case Keyboard.UP:
					keyY = -KEY_STEP;
					break;
				
				case Keyboard.DOWN:
					keyY = KEY_STEP;
					break;
				
				case Keyboard.EQUAL:
				case Keyboard.NUMPAD_ADD:
					keyZ = ZOOM_INC;
					break;
				
				case Keyboard.MINUS:
				case Keyboard.NUMPAD_SUBTRACT:
					keyZ = 1 / ZOOM_INC;
					break;
			}
			
			if (keyX || keyY || keyZ != 1)
			{
				keyTimer.start();
			}
		}
		
		private function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.LEFT:
				case Keyboard.RIGHT:
					keyX = 0;
					break;
				
				case Keyboard.UP:
				case Keyboard.DOWN:
					keyY = 0;
					break;
				
				case Keyboard.EQUAL:
				case Keyboard.NUMPAD_ADD:
				case Keyboard.MINUS:
				case Keyboard.NUMPAD_SUBTRACT:
					keyZ = 1;
					break;
			}
			
			if (keyX == 0 && keyY == 0 && keyZ == 1)
			{
				keyTimer.reset();
				keyTimer.stop();
			}
		}
		
		private function onDrawCompleted(event:Event):void
		{
			drawComplete = true;
		}
		
		private function update(event:TimerEvent):void
		{
			// Only draw the next tile when the current tile has finished drawing
			if (drawComplete)
			{
				drawComplete = false;
				drawNextTile();
				event.updateAfterEvent();
			}
		}
		
		private function keyUpdate(event:TimerEvent):void
		{
			if (keyX || keyY)
			{
				mb.x += keyX * 2 / (TILE_SIZE * mb.z);
				mb.y += keyY * 2 / (TILE_SIZE * mb.z);
				pan(-keyX, -keyY);
			}
			
			var oldZ:Number = mb.z;
			if (keyZ) zoom(keyZ);
			
			if (mb.z != oldZ || keyX || keyY)
			{
				drawFirstTile();
			}
		}
		
		private function onResize(event:Event):void
		{
			// Re-center crosshair
			crosshair.x = stage.stageWidth / 2;
			crosshair.y = stage.stageHeight / 2;
			
			// Re-center bitmap
			bitmap.x = bitmapX = (tileColumns - (stage.stageWidth / TILE_SIZE)) * TILE_SIZE / -2;
			bitmap.y = bitmapY = (tileRows - (stage.stageHeight / TILE_SIZE)) * TILE_SIZE / -2;
			
			var oldCols:uint = tileColumns;
			var oldRows:uint = tileRows;
			setColsRows();
			
			// Don't change anything if the number of tiles are the same
			if (tileColumns == oldCols && tileRows == oldRows) return;
			
			// Reset key presses
			keyX = keyY = 0;
			keyZ = 1;
			keyTimer.stop();
			
			// Update bitmap with new sizes
			initBitmap();
			mb.bitmapData = bitmapData;
			mb.x += (tileColumns - oldCols) * (mb.z - 1) / mb.z;
			mb.y += (tileRows - oldRows) * (mb.z - 1) / mb.z;
			
			setTileOrder();
			drawFirstTile();
		}
		
		public function reset():void
		{
			mb.reset();
			zoom(MIN_ZOOM);
			
			clearBitmap();
			drawFirstTile();
		}
		
		public function dispose():void
		{
			mb.removeEventListener(MandelbrotSet.DRAW_COMPLETED, onDrawCompleted);
			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER, update);
			keyTimer.stop();
			keyTimer.removeEventListener(TimerEvent.TIMER, keyUpdate);
			stage.removeEventListener(Event.RESIZE, onResize);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			bitmapData.dispose();
			bitmapData = null;
		}
	}
}