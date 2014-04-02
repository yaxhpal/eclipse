package com.techletsolutions.questionparser;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

public class QParser {

	public static void main(String[] args) throws IOException {
		quizParser();
	}
	
	public static void quizParser() throws IOException {
		ArrayList<Question> questions = new ArrayList<Question>();
		Document doc = Jsoup.parse( new File("/home/yashpal/projects/erewise/parser/jargron.html"), "UTF-8", "http://www.gktoday.in/");
		Elements paragraphs = doc.getElementsByTag("p");
		int questionCounter = 1;
		String paraText = "";
		String[] parts = null;
		Question question = new Question();
		for (Element paragraph : paragraphs) {
			paraText = paragraph.text();
			if (paraText.matches("^" + questionCounter + "\\..*")) {
				parts = paraText.split("@#\\$%\\$#");
				int i = 0;
				int optionCounter = 0;
				String option = "";
				for (String string : parts) {
					string = string.trim();
					if (i == 0) {
						question.setQuestionStatement(string.replaceFirst("[\\d]+\\.", "").trim());
					} else {
						if (string.matches("^[\\(\\)abcd\\.]+.*")) {
							optionCounter++;
							option = string.replaceFirst("\\(.?\\)", "").trim();
							switch (optionCounter) {
							case 1: 
								question.setOptionA(option);
								break;
							case 2: 
								question.setOptionB(option);
								break;
							case 3: 
								question.setOptionC(option);
								break;
							case 4:
								question.setOptionD(option);
								questions.add(question);
								question = new Question();
								break;
							default:
								// TODO Do some useful stuff
								break;
							}	
						} else {
							if (string.matches("^[\\d]\\..*")) {
								question.addStatement(string);
							} else {
								question.setQuestionAsked(string);
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
					question.setAnswer(parts[0].trim());
					question.setExplanation(parts[1].trim());
				} else {
					question.setAnswer("?");
					question.setExplanation(parts[1].trim());
				}
				questions.add(question);
			}
		}
		int i = 1;
		for (Question quiz : questions) {
			quiz.printIt(i++);
		}
	}	
}
