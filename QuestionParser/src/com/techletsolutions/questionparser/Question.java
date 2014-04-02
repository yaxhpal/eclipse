package com.techletsolutions.questionparser;

import java.util.ArrayList;
import java.util.List;


public class Question {
	private String questionStatement;
	private String optionA;
	private String optionB;
	private String optionC;
	private String optionD;
	private List<String>   statements;
	private String questionAsked;
	private String answer;
	private String explanation;

	public Question() {
		questionStatement="";
		optionA="";
		optionB="";
		optionC="";
		optionD="";
		questionAsked="";
		answer="";
		explanation="";
		statements = new ArrayList<String>();
	}

	@Override
	public String toString() {
		String question = "";
		question += questionStatement +"\n";
		if (statements != null) {
			for (String statement : statements) {
				question += statement+"\n";
			}
		}
		
		if (isNotEmpty(questionAsked)) {
			question += questionAsked+"\n";
		}
		
		if (isNotEmpty(optionA)) {
			question += "\tA. " + optionA + "\n";
		}
		
		if (isNotEmpty(optionB)) {
			question += "\tB. " + optionB + "\n";
		}
		
		if (isNotEmpty(optionC)) {
			question += "\tC. " + optionC + "\n";
		}
		
		if (isNotEmpty(optionD)) {
			question += "\tD. " + optionD + "\n";
		}
		
		if (isNotEmpty(answer)) {
			question += "The Answer is: " +answer + "\n";
		}
		
		if (isNotEmpty(explanation)) {
			question += "Explanation: "+ explanation + "\n";
		}
		return question;
	}

	
	public boolean isNotEmpty(String string) {
		if (string == null || "".equals(string.trim())){
			return false;
		}
		return true;
	}

	public String getQuestionStatement() {
		return questionStatement;
	}


	public void setQuestionStatement(String questionStatement) {
		this.questionStatement = questionStatement;
	}


	public String getOptionA() {
		return optionA;
	}


	public void setOptionA(String optionA) {
		this.optionA = optionA;
	}


	public String getOptionB() {
		return optionB;
	}


	public void setOptionB(String optionB) {
		this.optionB = optionB;
	}


	public String getOptionC() {
		return optionC;
	}


	public void setOptionC(String optionC) {
		this.optionC = optionC;
	}


	public String getOptionD() {
		return optionD;
	}


	public void setOptionD(String optionD) {
		this.optionD = optionD;
	}


	public List<String> getStatements() {
		return statements;
	}


	public void setStatements(List<String> statements) {
		this.statements = statements;
	}

	public void addStatement(String statement) {
		this.statements.add(statement);
	}

	public String getQuestionAsked() {
		return questionAsked;
	}


	public void setQuestionAsked(String questionAsked) {
		this.questionAsked = questionAsked;
	}


	public String getAnswer() {
		return answer;
	}


	public void setAnswer(String answer) {
		this.answer = answer;
	}


	public String getExplanation() {
		return explanation;
	}


	public void setExplanation(String explanation) {
		this.explanation = explanation;
	}

	public void printIt() {
		System.out.println(toString());
	}
	
	public void printIt(int index) {
		System.out.println(index +". "+toString());
	}
}
