package com.techletsolutions.xls;

import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;

import com.techletsolutions.questionparser.Question;

public class XLSUtils {

	private static final String[] xlsSheetHeades = {"Question No.","Question", "Statements", "Question Asked", 
									 "OptionA", "OptionB", "OptionC", "OptionD", "Answer", "Explanation"};
			  
    private static final Map<String, Integer> columnsIndex = new HashMap<String, Integer>();
    static {
    	for (int i = 0; i < xlsSheetHeades.length; i++) {
    		columnsIndex.put(xlsSheetHeades[i],i);	
		}
    }
	
	public static void saveIntoXLS(ArrayList<Question> questions, String outputFile) {
		HSSFWorkbook workbook = new HSSFWorkbook();
		HSSFSheet sheet = workbook.createSheet("Questions");
		int questionCounter = 0, rownum = 0;
		Row row = null;
		Cell cell = null;
		row = sheet.createRow(rownum++);
		for (String columnName : xlsSheetHeades) {
			cell = row.createCell(columnsIndex.get(columnName));
			cell.setCellValue(columnName);
		}
		for (Question question : questions) {
			questionCounter++;
			row  =  sheet.createRow(rownum++);
			
			cell = row.createCell(columnsIndex.get(xlsSheetHeades[0]));
			cell.  setCellValue("" + questionCounter);
			
			cell = row.createCell(columnsIndex.get(xlsSheetHeades[1]));
			cell.setCellValue(question.getQuestionStatement());
			
			List<String> statements = question.getStatements();
			
			cell = row.createCell(columnsIndex.get(xlsSheetHeades[2]));
			for(String statement : statements) {
				cell.setCellValue(cell.getStringCellValue()+"\n"+ statement);
			}

			cell = row.createCell(columnsIndex.get(xlsSheetHeades[3]));
			cell.setCellValue(question.getQuestionAsked());
			
			cell = row.createCell(columnsIndex.get(xlsSheetHeades[4]));
			cell.setCellValue(question.getOptionA());
			
			cell = row.createCell(columnsIndex.get(xlsSheetHeades[5]));
			cell.setCellValue(question.getOptionB());
			
			
			cell = row.createCell(columnsIndex.get(xlsSheetHeades[6]));
			cell.setCellValue(question.getOptionC());
			
			cell = row.createCell(columnsIndex.get(xlsSheetHeades[7]));
			cell.setCellValue(question.getOptionD());
			
			
			cell = row.createCell(columnsIndex.get(xlsSheetHeades[8]));
			cell.setCellValue(question.getAnswer());
			

			cell = row.createCell(columnsIndex.get(xlsSheetHeades[9]));
			cell.setCellValue(question.getExplanation());
		}
		try {
			FileOutputStream out = new FileOutputStream(new File(outputFile));
			workbook.write(out);
			out.close();
			System.out.println("Excel written successfully..");
		} catch (Exception e) {
			System.out.println("Could not write into XLS Sheet: " + e.getMessage());
		}
	}
}
