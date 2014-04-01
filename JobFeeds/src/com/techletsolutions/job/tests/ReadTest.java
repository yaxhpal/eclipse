package com.techletsolutions.job.tests;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import com.techletsolutions.job.categories.Categories;
import com.techletsolutions.job.feeds.JobItem;
import com.techletsolutions.job.model.JobFeed;
import com.techletsolutions.job.read.JobFeedParser;
import com.techletsolutions.job.websites.JobSites;
import com.techletsolutions.job.websites.WebSite;
// import java.util.logging.Logger;

public class ReadTest {
	
	// assumes the current class is called logger
	// private final static Logger LOGGER = Logger.getLogger(ReadTest.class .getName()); 
	
	// Database URL
	static final String DB_URL = "jdbc:mysql://localhost/hulk";
	//  Database credentials
	static final String USER = "root";
	static final String PASS = "";

	static Connection conn = null;
	// Connection

	public static void main(String[] args) throws Exception {
		openDBConnection();
		readAllFeeds();
		closeDBConnection();
	}

	public static void readAllFeeds() {
		JobFeedParser parser = null;
		JobFeed jobFeed = null;
		List<String> categories = (new Categories()).getCategories();
		List<WebSite> websites = (new JobSites()).getJobsites();
		for (WebSite webSite : websites) {
			for (String category: categories) {
				parser = new JobFeedParser(webSite.getUrl().replace("<CATEGORY>", category), category);
				jobFeed = parser.readFeed();
				for (JobItem jobItem : jobFeed.getJobItems()) {
					saveJobItem(jobItem, webSite.getName());
					
				}
			}
		}
	}
	
	public static void saveJobItem(JobItem jobItem, String source) {
		PreparedStatement stmt = null;
		try {
			String sql = "INSERT INTO jobfeeds (jobid, source, title, description, link, pubdate, publisher, category)"
					+ " VALUES (?,?,?,?,?,?,?,?);";
			stmt = conn.prepareStatement(sql);
			stmt.setString(1, jobItem.getGuid());
			stmt.setString(2, source);
			stmt.setString(3, jobItem.getTitle());
			stmt.setString(4, jobItem.getDescription());
			stmt.setString(5, jobItem.getLink());
			SimpleDateFormat pubDate = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss zzz");
			Date date = pubDate.parse(jobItem.getPubDate());
			stmt.setTimestamp(6, new Timestamp(date.getTime()));
			stmt.setString(7, jobItem.getSource());
			stmt.setString(8, jobItem.getCategory());
			stmt.execute();
		} catch (Exception e) {
			if (e.getLocalizedMessage().contains("jobid_UNIQUE")) {
				System.out.println("Job with id: "+jobItem.getGuid()+" already exists.");
			} else {
				e.printStackTrace();
			}
		}
	}

	public static Connection openDBConnection() throws SQLException {
		if (conn == null ||  conn.isClosed()){
			conn = DriverManager.getConnection(DB_URL, USER, PASS);
		} 
		return conn;
	}
	
	public static void closeDBConnection() throws SQLException {
		if (conn != null || conn.isClosed()){
			conn.close();
		}
	}
}

