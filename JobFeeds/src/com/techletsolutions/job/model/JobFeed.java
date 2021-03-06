package com.techletsolutions.job.model;

import java.util.ArrayList;
import java.util.List;

import com.techletsolutions.job.feeds.JobItem;

/*
 * Stores an RSS feed
 */
public class JobFeed {

	final String title;
	final String link;
	final String description;
	final String language;
	final String copyright;
	final String pubDate;

	final List<JobItem> entries = new ArrayList<JobItem>();

	public JobFeed(String title, String link, String description, String language, String copyright, String pubDate) {
		this.title = title;
		this.link = link;
		this.description = description;
		this.language = language;
		this.copyright = copyright;
		this.pubDate = pubDate;
	}

	public List<JobItem> getJobItems() {
		return entries;
	}

	public String getTitle() {
		return title;
	}

	public String getLink() {
		return link;
	}

	public String getDescription() {
		return description;
	}

	public String getLanguage() {
		return language;
	}

	public String getCopyright() {
		return copyright;
	}

	public String getPubDate() {
		return pubDate;
	}
	
	public String getGuid() {
		return pubDate;
	}

	@Override
	public String toString() {
		return "Feed [copyright=" + copyright + ", description=" + description
				+ ", language=" + language + ", link=" + link + ", pubDate="
				+ pubDate + ", title=" + title + "]";
	}

}