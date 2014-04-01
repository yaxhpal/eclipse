package com.techletsolutions.questionparser;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;

import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

public class GTKTodayParser {
	public static void main(String[] args) throws Exception {

		newParser();
		System.exit(0);

		Hashtable<String, String> question = new Hashtable<String, String>();
		ArrayList<Hashtable<String, String>> questions = new ArrayList<Hashtable<String, String>>();
		String outputFile = "/home/yashpal/projects/erewise/parser/2012-general-studies-paper.html";
		//File input = new File("/home/yashpal/gkt.html");
		//Document doc = Jsoup.parse(input, "UTF-8", "http://www.gktoday.in/");
		//Document doc = Jsoup.connect("http://www.gktoday.in/solution-upsc-civil-services-preliminary-examination-2013-paper-1-general-studies/").get();
		//Document doc = Jsoup.connect("http://www.gktoday.in/solution-of-the-upsc-prelims-2011-general-studies-paper/").get();

		File input = new File(outputFile);
		Document doc = Jsoup.parse(input, "UTF-8", "http://www.gktoday.in/");

		//BufferedWriter htmlWriter = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputFile), "UTF-8"));
		//htmlWriter.write(doc.toString());
		//htmlWriter.close();
		//System.exit(0);

		Elements paragraphs = doc.getElementsByTag("p");
		int questionCounter = 1, optionCounter = 0, choiceCounter = 0;
		boolean questionStart = false, explanationStart = false;
		String paraText = "";
		for (Element paragraph : paragraphs) {
			paraText = paragraph.text();
			if (paraText.matches("^" + questionCounter + "\\..*")) {
				questionCounter++;
				if (!questionStart) {
					questionStart = true;
					optionCounter = 0;
					choiceCounter = 0;
					explanationStart = false;
				}
				question = new Hashtable<String, String>();
				question.put("questionStatement",paraText.replaceFirst("[\\d]+\\.", "").trim());
				System.out.println(question.get("questionStatement"));
				question.put("Explanation", "");
				question.put("questionEndStatement","");
			} else if (questionStart && (paraText.matches("^[\\[\\]ABCD\\.]+.*"))) {
				optionCounter++;
				switch (optionCounter) {
				case 1: 
					question.put("optionA", paraText.replaceFirst("^[\\[\\]ABCD\\.]+", "").trim());
					break;
				case 2: 
					question.put("optionB", paraText.replaceFirst("^[\\[\\]ABCD\\.]+", "").trim());
					break;
				case 3: 
					question.put("optionC", paraText.replaceFirst("^[\\[\\]ABCD\\.]+", "").trim());
					break;
				case 4:
					question.put("optionD", paraText.replaceFirst("^[\\[\\]ABCD\\.]+", "").trim());
					questions.add(question);
					questionStart = false;
					break;
				default:
					question.put("optionE", paraText.trim());
					questionStart = false;
					break;
				}
			} else if (questionStart && (paraText.matches("^[\\d]\\..*"))) {
				choiceCounter++;
				question.put("choice" + choiceCounter, paraText.trim());
			} else if (paraText.matches("^Answer:.*")) {
				question.put("Answer", paraText.replaceFirst("^Answer:", "").trim());
				explanationStart = true;
			} else if (choiceCounter > 0 && optionCounter == 0 && !(paraText.matches("^[\\d]\\..*"))) {
				question.put("questionEndStatement", question.get("questionEndStatement")+ paraText.trim());
			} else {
				if (paraText.matches(".*PDF.*")) {
					explanationStart = false;
				}
				if (explanationStart) {
					question.put("Explanation", question.get("Explanation")+ " " + paraText.trim());
				}
			}

		}
		printQuestion(questions);
		// saveIntoXLS(questions);
	}

	public static void newParser() throws IOException {
		Hashtable<String, String> question = new Hashtable<String, String>();
		ArrayList<Hashtable<String, String>> questions = new ArrayList<Hashtable<String, String>>();
		// String outputFile = "/home/yashpal/projects/erewise/parser/2012-general-studies-paper.html";
		String outputFile = "/home/yashpal/projects/erewise/parser/jargron.html";
		File input = new File(outputFile);
		Document doc = Jsoup.parse(input, "UTF-8", "http://www.gktoday.in/");
		Elements paragraphs = doc.getElementsByTag("p");
		int questionCounter = 1;
		String paraText = "";
		String[] parts = null; //= text.split("@#\\$%\\$#");
		for (Element paragraph : paragraphs) {
			paraText = paragraph.text();
			if (paraText.matches("^" + questionCounter + "\\..*")) {
				parts = paraText.split("@#\\$%\\$#");
				int i = 0;
				int optionCounter = 0;
				int choiceCounter = 0;
				String option = "";
				for (String string : parts) {
					string = string.trim();
					if (i == 0) {
						question.put("questionStatement",string.replaceFirst("[\\d]+\\.", "").trim());
					} else {
						if (string.matches("^[\\(\\)abcd\\.]+.*")) {
							optionCounter++;
							option = string.replaceFirst("\\(.?\\)", "").trim();
							switch (optionCounter) {
							case 1: 
								question.put("optionA", option);
								break;
							case 2: 
								question.put("optionB", option);
								break;
							case 3: 
								question.put("optionC", option);
								break;
							case 4:
								question.put("optionD", option);
								questions.add(question);
								question = new Hashtable<String, String>();
								break;
							default:
								question.put("optionE", string.trim());
								break;
							}	
						} else {
							choiceCounter++;
							if (string.trim().matches("^[\\d]\\..*")) {
								question.put("choice" + choiceCounter, string.trim());
							} else {
								question.put("questionEndStatement", string.trim());
							}
						}
					}
					i++;
				}
				questionCounter++;
			} 
			if (paragraph.hasClass("answer")) {
				parts = paraText.split("@#\\$%\\$#");
				if (parts.length > 1) {
					question.put("Answer", parts[0].trim());
					question.put("Explanation", parts[1].trim());
				} else {
					question.put("Answer", "?");
					question.put("Explanation", paraText.trim());
				}
				questions.add(question);
				question = new Hashtable<String, String>();
			}
		}
		printQuestion(questions);
		//saveIntoXLS(questions, "/home/yashpal/projects/erewise/questions/jargron.xls");
	}

	public static void testingIt(String text) {
		String[] parts = text.split("@#\\$%\\$#");
		for (String string : parts) {
			System.out.println(string);
		}
	}

	public static void gktHtmlWriter() throws Exception {
		String urlpattern = "http://www.gktoday.in/solution-of-the-upsc-civil-services-preliminary-examination-2012-gs-paper-1/PAGE/";
		String url = "";
		String outputFile = "/home/yashpal/projects/erewise/parser/2012-general-studies-paper.html";
		int counter = 1;
		while (counter < 11) {
			url = urlpattern.replace("PAGE", (counter++)+"");
			System.out.println(url);
			Document doc = Jsoup.connect(url).get();
			Element el = doc.getElementsByClass("entry").first();
			//BufferedWriter htmlWriter = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputFile), "UTF-8"));
			//htmlWriter.write(el.toString());
			try(PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(outputFile, true)))) {
				out.println(el.html());
			}catch (IOException e) {
				e.printStackTrace();
			}			
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				//Handle exception
			}
		}
		System.exit(0);
	}

	private static void printQuestion(ArrayList<Hashtable<String, String>> questions) {
		int questionCounter = 1;
		for (Hashtable<String, String> question : questions) {
			System.out.println(questionCounter + ". "+ question.get("questionStatement"));
			questionCounter++;
			int i = 1;
			while (question.containsKey("choice" + i)) {
				System.out.println("\t" + question.get("choice" + i));
				i++;
			}
			if (question.containsKey("questionEndStatement")) {
				System.out.println("\t" + question.get("questionEndStatement"));
			}

			if (question.containsKey("optionA")) {
				System.out.println("\tA. " + question.get("optionA"));
			}
			if (question.containsKey("optionB")) {
				System.out.println("\tB. " + question.get("optionB"));
			}
			if (question.containsKey("optionC")) {
				System.out.println("\tC. " + question.get("optionC"));
			}
			if (question.containsKey("optionD")) {
				System.out.println("\tD. " + question.get("optionD"));
			}
			System.out.println("The Answer is: " + question.get("Answer"));
			System.out.println("Explanation: " + question.get("Explanation") + "\n\n\n\n");
		}
	}

	private static void saveIntoXLS(ArrayList<Hashtable<String, String>> questions, String outputFile) {
		HSSFWorkbook workbook = new HSSFWorkbook();
		HSSFSheet sheet = workbook.createSheet("Questions");
		int questionCounter = 0, rownum = 0, cellnum = 0;
		Row row = sheet.createRow(rownum++);
		Cell cell = row.createCell(cellnum++);
		cell.setCellValue("Question No.");
		cell = row.createCell(cellnum++);
		cell.setCellValue("Question");
		cell = row.createCell(cellnum++);
		cell.setCellValue("Choices");
		cell = row.createCell(cellnum++);
		cell.setCellValue("questionEndStatement");
		cell = row.createCell(cellnum++);
		cell.setCellValue("OptionA");
		cell = row.createCell(cellnum++);
		cell.setCellValue("OptionB");
		cell = row.createCell(cellnum++);
		cell.setCellValue("OptionC");
		cell = row.createCell(cellnum++);
		cell.setCellValue("OptionD");
		cell = row.createCell(cellnum++);
		cell.setCellValue("Answer");
		cell = row.createCell(cellnum++);
		cell.setCellValue("Explanation");
		String choices;
		for (Hashtable<String, String> question : questions) {
			questionCounter++;
			cellnum = 0;
			choices = "";
			row = sheet.createRow(rownum++);
			cell = row.createCell(cellnum++);
			cell.setCellValue("" + questionCounter);
			cell = row.createCell(cellnum++);
			cell.setCellValue(question.get("questionStatement"));
			int i = 1;
			while (question.containsKey("choice" + i)) {
				choices += question.get("choice" + i) + "\n";
				i++;
			}
			cell = row.createCell(cellnum++);
			cell.setCellValue(choices);

			if (question.containsKey("questionEndStatement")) {
				cell = row.createCell(cellnum++);
				cell.setCellValue(question.get("questionEndStatement"));
			} else {
				cellnum++;
			}

			if (question.containsKey("optionA")) {
				cell = row.createCell(cellnum++);
				cell.setCellValue(question.get("optionA"));
			}
			if (question.containsKey("optionB")) {
				cell = row.createCell(cellnum++);
				cell.setCellValue(question.get("optionB"));
			}
			if (question.containsKey("optionC")) {
				cell = row.createCell(cellnum++);
				cell.setCellValue(question.get("optionC"));
			}
			if (question.containsKey("optionD")) {
				cell = row.createCell(cellnum++);
				cell.setCellValue(question.get("optionD"));
			}
			cell = row.createCell(cellnum++);
			cell.setCellValue(question.get("Answer"));
			cell = row.createCell(cellnum++);
			cell.setCellValue(question.get("Explanation"));
		}
		try {
			FileOutputStream out = new FileOutputStream(new File(outputFile));
			workbook.write(out);
			out.close();
			System.out.println("Excel written successfully..");
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
