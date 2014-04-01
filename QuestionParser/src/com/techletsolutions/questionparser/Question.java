package com.techletsolutions.questionparser;

public class Question {
	public String text;
	public String answer;
	
	@Override
	public String toString() {
		return "Question Text: "+ text+"\n"+"Answer Text: "+answer+"\n";
	}
}
