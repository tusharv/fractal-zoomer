package com.neave.fractal
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
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
	import flash.ui.Multitouch;
	import flash.utils.Timer;

	public final class FractalZoomer extends Sprite
	{
		// Main constants
		private const IS_TOUCH:Boolean = Multitouch.supportsTouchEvents;
		private const ZOOM_INC:Number = IS_TOUCH ? 2 : 1.125; // The amount to increment when zooming in
		private const MIN_ZOOM:Number = 6; // Start at a higher zoom level
		private const KEY_STEP:uint = 16; // How much to pan with each key press
		private const TILE_SIZE:uint = 64; // The bitamp is split into tiles of this size
		
		// Main variables
		private var fractalWidth:uint;
		private var fractalHeight:uint;
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
		private var crosshair:Crosshair;
		private var zoomInButton:ZoomButton;
		private var zoomOutButton:ZoomButton;
		
		public function FractalZoomer(fractalWidth:uint = 512, fractalHeight:uint = 512)
		{
			this.fractalWidth = fractalWidth;
			this.fractalHeight = fractalHeight;
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			initMandelbrot();
			initCrosshair();
			initZoomButtons();
			initTimer();
			
			setSize(fractalWidth, fractalHeight);
			setTileOrder();
			drawFirstTile();
			
			Mouse.cursor = MouseCursor.HAND;
		}
		
		private function initMandelbrot():void
		{
			setColsRows();
			bitmap = new Bitmap();
			initBitmap();
			addChild(bitmap);
			
			mb = new MandelbrotSet(bitmapData, 0, -0.6, 1);
			mb.addEventListener(MandelbrotSet.DRAW_COMPLETED, onDrawCompleted);
			zoom(MIN_ZOOM);
		}
		
		private function setColsRows():void
		{
			tileColumns = Math.ceil(fractalWidth / TILE_SIZE);
			tileRows = Math.ceil(fractalHeight / TILE_SIZE);
		}
		
		private function initBitmap():void
		{
			// Create a copy of the old bitmap data
			var oldBitmapData:BitmapData;
			if (bitmapData !== null)
			{
				oldBitmapData = bitmapData.clone();
			}
			
			// Create the new size bitmap data
			bitmapData = bitmap.bitmapData = new BitmapData(tileColumns * TILE_SIZE, tileRows * TILE_SIZE, false, 0xff000a00);
			
			// Copy the old bitmap data into the new bitmap data
			if (oldBitmapData !== null)
			{
				bitmapData.copyPixels(oldBitmapData, oldBitmapData.rect, new Point((bitmapData.width - oldBitmapData.width) / 2, (bitmapData.height - oldBitmapData.height) / 2));
				oldBitmapData.dispose();
			}
		}
		
		private function initTimer():void
		{
			// Update render as often as possible
			timer = new Timer(1, 0);
			timer.addEventListener(TimerEvent.TIMER, update);
			
			// Update key presses a little less quickly
			keyTimer = new Timer(16, 0);
			keyTimer.addEventListener(TimerEvent.TIMER, keyUpdate);
		}
		
		private function initCrosshair():void
		{
			crosshair = new Crosshair();
			addChild(crosshair);
		}
		
		private function initZoomButtons():void
		{
			zoomInButton = new ZoomButton(true);
			zoomInButton.addEventListener(MouseEvent.MOUSE_DOWN, onZoomInPress);
			zoomInButton.addEventListener(MouseEvent.MOUSE_UP, onZoomRelease);
			zoomInButton.addEventListener(MouseEvent.MOUSE_OUT, onZoomRelease);
			addChild(zoomInButton);
			
			zoomOutButton = new ZoomButton(false);
			zoomOutButton.addEventListener(MouseEvent.MOUSE_DOWN, onZoomOutPress);
			zoomOutButton.addEventListener(MouseEvent.MOUSE_UP, onZoomRelease);
			zoomOutButton.addEventListener(MouseEvent.MOUSE_OUT, onZoomRelease);
			addChild(zoomOutButton);
		}
		
		private function onZoomInPress(event:MouseEvent):void
		{
			event.stopPropagation();
			keyZ = ZOOM_INC;
			keyTimer.start();
		}
		
		private function onZoomOutPress(event:MouseEvent):void
		{
			event.stopPropagation();
			keyZ = 1 / ZOOM_INC;
			keyTimer.start();
		}
		
		private function onZoomRelease(event:MouseEvent):void
		{
			event.stopPropagation();
			keyZ = 1;
			keyTimer.reset();
			keyTimer.stop();
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
		
		public function zoomIn(dz:Number):void
		{
			// Only redraw if zoom value has changed
			var mbz:Number = mb.z;
			zoom(dz);
			if (mb.z != mbz) drawFirstTile();
		}
		
		public function zoomOut(dz:Number):void
		{
			// Only redraw if zoom value has changed
			var mbz:Number = mb.z;
			zoom(1 / dz);
			if (mb.z != mbz) drawFirstTile();
		}
		
		public function pan(dx:Number, dy:Number):void
		{
			bitmapData.lock();
			
			var panSrc:BitmapData = bitmapData.clone();
			var m:Matrix = new Matrix();
			m.translate(dx, dy);
			
			// Redraw the bitmap into this position
			clearBitmap();
			bitmapData.draw(panSrc, m, null, null, null, false);
			
			panSrc.dispose();
			bitmapData.unlock();
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			dragBitmap = true;
			dragPoint = new Point(int(event.localX), int(event.localY));
		}
		
		private function onMouseMove(event:MouseEvent):void
		{
			if (!dragBitmap) return;
			
			bitmap.x = int(event.localX) - dragPoint.x + bitmapX;
			bitmap.y = int(event.localY) - dragPoint.y + bitmapY;
			event.updateAfterEvent();
		}
		
		private function onMouseLeave(event:Event):void
		{
			dragBitmap = false;
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			if (!dragBitmap) return;
			
			// Find the bitmap's new position
			dragBitmap = false;
			bitmap.x = bitmapX;
			bitmap.y = bitmapY;
			var mx:int = event.localX;
			var my:int = event.localY;
			
			// Redraw the bitmap in this position
			var dx:int = dragPoint.x - mx;
			var dy:int = dragPoint.y - my;
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
				mb.x += (mx * 2 - fractalWidth) / (TILE_SIZE * mb.z);
				mb.y += (my * 2 - fractalHeight) / (TILE_SIZE * mb.z);
				pan(fractalWidth / 2 - mx, fractalHeight / 2 - my);
			}
			
			drawFirstTile();
		}
		
		private function onMouseWheel(event:MouseEvent):void
		{
			if (event.delta > 0) zoomIn(ZOOM_INC);
			else zoomOut(ZOOM_INC);
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
				
				case Keyboard.C:
					if (contains(crosshair)) removeChild(crosshair);
					else addChild(crosshair);
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
			// Don't update on mobile whilst dragging
			if (IS_TOUCH && dragBitmap) return;
			
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
		
		private function updateSize(fractalWidth:uint, fractalHeight:uint):void
		{
			this.fractalWidth = fractalWidth;
			this.fractalHeight = fractalHeight;
			
			// Re-center crosshair
			crosshair.x = Math.round(fractalWidth * 0.5);
			crosshair.y = Math.round(fractalHeight * 0.5);
			
			// Position zoom buttons
			zoomInButton.x = (fractalWidth - 50) / 2 - 35;
			zoomOutButton.x = (fractalWidth - 50) / 2 + 35;
			zoomInButton.y = zoomOutButton.y = fractalHeight - (fractalHeight < 500 ? 65 : 100);
			
			scrollRect = new Rectangle(0, 0, fractalWidth, fractalHeight);
		}
		
		public function setSize(fractalWidth:uint, fractalHeight:uint):void
		{
			updateSize(fractalWidth, fractalHeight);
			
			var oldCols:uint = tileColumns;
			var oldRows:uint = tileRows;
			setColsRows();
			
			// Re-center bitmap
			bitmap.x = bitmapX = (tileColumns - (fractalWidth / TILE_SIZE)) * TILE_SIZE * -0.5;
			bitmap.y = bitmapY = (tileRows - (fractalHeight / TILE_SIZE)) * TILE_SIZE * -0.5;
			
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
			
			removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			
			if (stage !== null)
			{
				stage.removeEventListener(Event.MOUSE_LEAVE, onMouseUp);
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			}
			
			bitmapData.dispose();
			bitmapData = null;
		}
	}
}