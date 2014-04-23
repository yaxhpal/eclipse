package org.yaxhpal.io;

/**
 * This is an example of reading a text file.
 * 
 * @author <a href="mailto:yaxhpal@gmail.com">Yashpal Meena</a>
 * 
 *
 */
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;

public class ReadTextFile {
	
	final static String FILE_NAME = "/tmp//sandbox/input.txt";
	final static String OUTPUT_FILE_NAME = "/tmp/sandbox/output.txt";
	final static Charset ENCODING = StandardCharsets.UTF_8;

	public static void main(String... aArgs) throws IOException{
		ReadTextFile text = new ReadTextFile();

		//treat as a small file
		List<String> lines = text.readSmallTextFile(FILE_NAME);
		log(lines);
		lines.add("This is a line added in code.");
		text.writeSmallTextFile(lines, FILE_NAME);

		//treat as a large file - use some buffering
		text.readLargerTextFileAlternate(FILE_NAME);
		lines = Arrays.asList("Down to the Waterline", "Water of Love");
		text.writeLargerTextFile(OUTPUT_FILE_NAME, lines);   
	}


	//For smaller files

	/**
	 *  Note: the Javadoc of Files.readAllLines says it's intended for small
	 *  files. But its implementation uses buffering, so it's likely good 
	 *  even for fairly large files.
	 */  
	List<String> readSmallTextFile(String aFileName) throws IOException {
		Path path = Paths.get(aFileName);
		return Files.readAllLines(path, ENCODING);
	}

	void writeSmallTextFile(List<String> aLines, String aFileName) throws IOException {
		Path path = Paths.get(aFileName);
		Files.write(path, aLines, ENCODING);
	}

	//For larger files

	void readLargerTextFile(String aFileName) throws IOException {
		Path path = Paths.get(aFileName);
		try (Scanner scanner =  new Scanner(path, ENCODING.name())){
			while (scanner.hasNextLine()){
				//process each line in some way
				log(scanner.nextLine());
			}      
		}
	}

	void readLargerTextFileAlternate(String aFileName) throws IOException {
		Path path = Paths.get(aFileName);
		try (BufferedReader reader = Files.newBufferedReader(path, ENCODING)){
			String line = null;
			while ((line = reader.readLine()) != null) {
				//process each line in some way
				log(line);
			}      
		}
	}

	void writeLargerTextFile(String aFileName, List<String> aLines) throws IOException {
		Path path = Paths.get(aFileName);
		try (BufferedWriter writer = Files.newBufferedWriter(path, ENCODING)){
			for(String line : aLines){
				writer.write(line);
				writer.newLine();
			}
		}
	}

	private static void log(Object aMsg){
		System.out.println(String.valueOf(aMsg));
	}

} 