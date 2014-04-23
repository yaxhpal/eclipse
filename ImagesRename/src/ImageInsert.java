import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import javax.imageio.ImageIO;

public class ImageInsert {
	
	public static void main(String[] args) throws SQLException, IOException {
		Connection oeuvres_clean =  DriverManager.getConnection("jdbc:mysql://localhost/oeuvres_clean", "root", "");
		//PreparedStatement pst = oeuvres_clean.prepareStatement("insert into Image (name, width, height, artwork_id, version) values (?,?,?,?, ?);");
		PreparedStatement pst = oeuvres_clean.prepareStatement("Update Image set width='1200', height=? where id=?");
		Statement sth = oeuvres_clean.createStatement();
//		ResultSet rs = sth.executeQuery("select id, width, height from Artwork;");
//		int counter = 1;
//		while(rs.next()) {
//			pst.setString(1,  ""+counter++);
//			pst.setInt(2, rs.getInt(3));
//			pst.setInt(3, rs.getInt(2));
//			pst.setLong(4, rs.getLong(1));
//			pst.setInt(5, 0);
//			pst.executeUpdate();
//		}
		
		for (Dimensions dimension : readDimentions()) {
			pst.setInt(1, dimension.height);
			pst.setLong(2, dimension.index);
			pst.executeUpdate();
		}
		oeuvres_clean.close();
	}
	
	
	public static List<Dimensions> readDimentions () throws IOException {
		File dir = new File("/home/yashpal/projects/artproject/data/Data_03.03.14/1200 images");
		File[] files = dir.listFiles();
		List<Dimensions> list = new ArrayList<Dimensions>(311);
		for (File file : files) {
			try {
				BufferedImage bimg = ImageIO.read(file);
				int width          = bimg.getWidth();
				int height         = bimg.getHeight();
				String id = file.getName().replace(".jpg", "");
				list.add(new Dimensions(new Integer(id), height));
			} catch (Exception e) {
				System.out.println(file.getName());
			}
		}
		list.add(new Dimensions(65, 1570));
		list.add(new Dimensions(277, 776));
		list.add(new Dimensions(123, 959));
		return list;
	}
}

class Dimensions {
	public Integer index;
	public Integer height;
	
	public Dimensions(Integer index, Integer height) {
		this.index = index;
		this.height = height;
	}
}
