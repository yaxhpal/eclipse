import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.imageio.ImageIO;


public class ImageUtils {


	public static void main(String[] args) throws IOException {
		File dir = new File("/home/yashpal/projects/artproject/data/Data_03.03.14/1200 images");
		File[] files = dir.listFiles();
		List<Integer> list = new ArrayList<Integer>(311);
		for (File file : files) {

			try {
				BufferedImage bimg = ImageIO.read(file);
				int width          = bimg.getWidth();
				int height         = bimg.getHeight();
				String id = file.getName().replace(".jpg", "");
				list.add(new Integer(id));
				// System.out.println("Name: "+file.getName()+" Width: "+width+" Height: "+height);
			} catch (Exception e) {
				System.out.println(file.getName());
			}
		}
		int counter = 1;
		for (Integer integer : list) {
//			System.out.println((counter++)+": "+integer);
		}

	}
}

/*
 
 65.jpg - 1570
277.jpg - 776
123.jpg - 959

 
 */
 
