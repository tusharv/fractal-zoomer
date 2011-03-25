package
{
	import com.neave.fractal.FractalZoomer;
	
	import flash.display.Sprite;

	[SWF(width="800", height="600", backgroundColor="#000a00", frameRate="31")]	
	public class Main extends Sprite
	{
		private var fractal:FractalZoomer;
		
		public function Main()
		{
			stage.showDefaultContextMenu = false;
			fractal = new FractalZoomer(stage);
		}
	}
}