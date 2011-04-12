package com.neave.fractal
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;

	public final class MandelbrotSet extends EventDispatcher
	{
		// Class constants
		static public const DRAW_COMPLETED:String = "drawCompleted";
		static public const MAX_ZOOM:Number = 1e14;
		
		// Main variables
		private var colors:Vector.<uint>;
		
		public var bitmapData:BitmapData;
		public var x:Number;
		public var y:Number;
		public var z:Number;
		
		/**
		 * Creates a Mandelbrot set function
		 * 
		 * @param	bitmapData		The BitmapData to draw the Mandelbrot fractal into
		 * @param	x				The x starting position
		 * @param	y				The y starting position
		 * @param	z				The z starting position
		 */
		public function MandelbrotSet(bitmapData:BitmapData, x:Number = 0, y:Number = 0, z:Number = 1)
		{
			this.bitmapData = bitmapData;
			this.x = x;
			this.y = y;
			this.z = z;
			
			initColors();
		}
		
		/**
		 * Draws an area of the Mandelbrot fractal
		 * 
		 * @param	rect		The bounding box of the fratal to draw
		 * @param	ox			The x offset
		 * @param	oy			The y offset
		 * @param	oz			The z offset
		 */
		public function draw(rect:Rectangle, ox:Number = 0, oy:Number = 0, oz:Number = 0):void
		{
			// Limit zoom
			if (oz + z > MandelbrotSet.MAX_ZOOM) return;
			
			// Offset position
			ox += x;
			oy += y;
			oz += z;
			
			// Calculate real and imaginary bounding box
			var minR:Number = oy - 1 / oz;
			var maxR:Number = oy + 1 / oz;
			var minI:Number = ox - 1 / oz;
			var maxI:Number = ox + 1 / oz;
			var left:uint = rect.left;
			var top:uint = rect.top;
			var width:uint = rect.width;
			var height:uint = rect.height;
			var stepX:Number = (maxR - minR) / width;
			var stepY:Number = (maxI - minI) / height;
			var cr:Number, ci:Number, zr:Number, zi:Number, zr2:Number, zi2:Number, i:uint, j:uint, k:uint;
			
			// Draw the fractal into each pixel of this bounding box
			bitmapData.lock();
			bitmapData.fillRect(rect, 0xff000a00);
			
			for (i = width; i--; )
			{
				cr = minR + stepX * i;
				
				for (j = height; j--; )
				{
					// Initialize real and imaginary values
					ci = minI + stepY * j;
					zr = zi = 0;
					
					// Loop through the values to create the fractal
					for (k = 200; k--; )
					{
						// Square the values
						zr2 = zr * zr;
						zi2 = zi * zi;
						
						// Draw the pixel
						if (zr2 + zi2 > 4)
						{
							bitmapData.setPixel(j + left, i + top, colors[(199 - k)]);
							break;
						}
						
						// Mandelbrot calculation
						zi = zr * zi * 2 + ci;
						zr = zr2 - zi2 + cr;	
					}
				}
			}
			
			bitmapData.unlock(rect);
			
			// Drawing of this bounding box has completed, dispatch event
			dispatchEvent(new Event(MandelbrotSet.DRAW_COMPLETED));
		}
		
		/**
		 * Resets the Mandelbrot to its initial fully zoomed out view
		 */
		public function reset():void
		{
			x = y = 0;
			z = 1;
		}
		
		/**
		 * Creates the 'colors' vector of 200 color values
		 */
		private function initColors():void
		{
			colors = new Vector.<uint>();
			
			var c:uint = 0xff;
			for (var i:uint = 0; i < 25; i++)
			{
				colors[i] = (0) << 16 | (0xff - c) << 8 | (0);
				c -= 10;
			}
			c = 0xff;
			for (i = 25; i < 50; i++)
			{
				colors[i] = (0xff - c) << 16 | (0xff) << 8 | (0);
				c -= 10;
			}
			c = 0xff;
			for (i = 50; i < 75; i++)
			{
				colors[i] = (c) << 16 | (c) << 8 | (0xff - c);
				c -= 10;
			}
			c = 0xff;
			for (i = 75; i < 100; i++)
			{
				colors[i] = (0xff - c) << 16 | (0) << 8 | (0xff);
				c -= 10;
			}
			c = 0xff;
			for (i = 100; i < 125; i++)
			{
				colors[i] = (0xff) << 16 | (0) << 8 | (c);
				c -= 10;
			}
			c = 0xff;
			for (i = 125; i < 150; i++)
			{
				colors[i] = (c) << 16 | (0xff - c) << 8 | (0);
				c -= 10;
			}
			c = 0xff;
			for (i = 150; i < 175; i++)
			{
				colors[i] = (0xff - c) << 16 | (0xff) << 8 | (0);
				c -= 10;
			}
			c = 0xff;
			for (i = 175; i < 200; i++)
			{
				colors[i] = (c) << 16 | (c) << 8 | (0xff - c);
				c -= 10;
			}
		}
	}
}