import java.io.File;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;


public class Main {

	public static void main(String[] args) throws SQLException {
		List<Artist> oeuvres_artists = new ArrayList<> ();
		List<Artist> oeuvres_clean_artists = new ArrayList<> ();

		Connection oeuvres =  DriverManager.getConnection("jdbc:mysql://localhost/oeuvres", "root", "");
		Connection oeuvres_clean =  DriverManager.getConnection("jdbc:mysql://localhost/oeuvres_clean", "root", "");

		Statement oeuvresStmt = oeuvres.createStatement();
		ResultSet oeuvres_rs = oeuvresStmt.executeQuery("select id, firstName, lastName, yearOfBirth, birthPlace from Artist;");

		Artist artist = null;
		while(oeuvres_rs.next()) {
			artist = new Artist();
			artist.id = oeuvres_rs.getLong(1);
			artist.firstName = oeuvres_rs.getString(2);
			artist.lastName = oeuvres_rs.getString(3);
			artist.yearOfBirth = oeuvres_rs.getInt(4);
			artist.birthPlace = oeuvres_rs.getString(5);
			oeuvres_artists.add(artist);
		}

		Statement oeuvres_clean_Stmt = oeuvres_clean.createStatement();
		ResultSet oeuvres_clean_rs = oeuvres_clean_Stmt.executeQuery("select id, firstName, lastName, yearOfBirth, birthPlace from Artist;");

		while(oeuvres_clean_rs.next()) {
			artist = new Artist();
			artist.id = oeuvres_clean_rs.getLong(1);
			artist.firstName = oeuvres_clean_rs.getString(2);
			artist.lastName = oeuvres_clean_rs.getString(3);
			artist.yearOfBirth = oeuvres_clean_rs.getInt(4);
			artist.birthPlace = oeuvres_clean_rs.getString(5);
			oeuvres_clean_artists.add(artist);
		}



		int counter = 1;
		for (Artist artist1 : oeuvres_artists) {
			for (Artist artist2 : oeuvres_clean_artists) {

				/*
				if (artist1.firstName.trim().equalsIgnoreCase(artist2.firstName.trim()) && 
						artist1.lastName.trim().equalsIgnoreCase(artist2.lastName.trim()) && 
						artist1.birthPlace.trim().equalsIgnoreCase(artist2.birthPlace.trim())) {

					System.out.println(counter++);
					System.out.println("Artist-1: "+ artist1.firstName +", "+ artist1.lastName +", "+ artist1.yearOfBirth +", "+artist1.birthPlace);
					System.out.println("Artist-2: "+ artist2.firstName +", "+ artist2.lastName +", "+ artist2.yearOfBirth +", "+artist2.birthPlace);
					System.out.println();

					}
				} */



				//				if (artist1.firstName.equalsIgnoreCase(artist2.firstName) && artist1.lastName.equalsIgnoreCase(artist2.lastName)
				//						&& (artist1.yearOfBirth == artist2.yearOfBirth) && artist1.birthPlace.equalsIgnoreCase(artist2.birthPlace)) {

				if (artist1.firstName.trim().equalsIgnoreCase(artist2.firstName.trim()) && 
						artist1.lastName.trim().equalsIgnoreCase(artist2.lastName.trim()) && 
						artist1.birthPlace.trim().equalsIgnoreCase(artist2.birthPlace.trim())) {
					System.out.println(counter++);
					System.out.println("Artist-1: "+ artist1.firstName +", "+ artist1.lastName +", "+ artist1.yearOfBirth +", "+artist1.birthPlace);
					System.out.println("Artist-2: "+ artist2.firstName +", "+ artist2.lastName +", "+ artist2.yearOfBirth +", "+artist2.birthPlace);
					System.out.println();
					File file = new File("/home/yashpal/projects/artproject/data/Data_03.03.14/artists/"+artist1.id+".jpg");
					File file2 = new File("/home/yashpal/projects/artproject/data/Data_03.03.14/artists/"+artist2.id+".jpg");
					// Rename file (or directory)
					boolean success = file.renameTo(file2);

					if (success) {
						System.out.println("Renamed successfully.");
					} else {
						System.out.println("Renamed unsuccessful.");
					}
					System.out.println();
					System.out.println();
					System.out.println();
				}


				//				System.out.println(counter++);
				//				System.out.println("Artist-1: "+ artist1.firstName +", "+ artist1.lastName +", "+ artist1.yearOfBirth +", "+artist1.birthPlace);
				//				System.out.println("Artist-2: "+ artist2.firstName +", "+ artist2.lastName +", "+ artist2.yearOfBirth +", "+artist2.birthPlace);
				//				System.out.println();
			}
		}

		oeuvresStmt.close();
		oeuvres_clean_Stmt.close();
	}
}


class Artist {
	Long id;
	String firstName;
	String lastName;
	int yearOfBirth;
	String birthPlace;
}