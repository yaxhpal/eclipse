package com.techletsolutions.questionparser;

import java.io.IOException;

import org.jsoup.Jsoup;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

public class TestParser {
	public static void main(String[] args) throws IOException {
		
		{
			testingIt();
		}
		System.exit(0);
		
		// Validate.isTrue(args.length == 1, "usage: supply url to fetch");
		String url = "http://www.simplyhired.co.in/";
		print("Fetching %s...", url);

		Document doc = Jsoup.connect(url).get();
		Elements links = doc.select("a[href]");
		//        Elements media = doc.select("[src]");
		//        Elements imports = doc.select("link[href]");

		//        print("\nMedia: (%d)", media.size());
		//        for (Element src : media) {
		//            if (src.tagName().equals("img"))
		//                print(" * %s: <%s> %sx%s (%s)",
		//                        src.tagName(), src.attr("abs:src"), src.attr("width"), src.attr("height"),
		//                        trim(src.attr("alt"), 20));
		//            else
		//                print(" * %s: <%s>", src.tagName(), src.attr("abs:src"));
		//        }
		//
		//        print("\nImports: (%d)", imports.size());
		//        for (Element link : imports) {
		//            print(" * %s <%s> (%s)", link.tagName(),link.attr("abs:href"), link.attr("rel"));
		//        }

		print("\nLinks: (%d)", links.size());

		for (Element link : links) {
			if (link.attr("abs:href").contains("/a/jobs/list/q-")) {
				//print(" * a: <%s>  (%s)", link.attr("abs:href"), trim(link.text(), 35));
				System.out.println(link.attr("abs:href"));
			}
		}
	}

	private static void print(String msg, Object... args) {
		System.out.println(String.format(msg, args));
	}

	private static String trim(String s, int width) {
		if (s.length() > width)
			return s.substring(0, width-1) + ".";
		else
			return s;
	}
	
	public static void testingIt() {
		String test = "Question Text: 90. In the areas covered under the Panchayat (Extension to the Scheduled Areas) Act, 1996. What is the role/power of Gram Sabha?@#$%$# 1. Gram Sabha has the power to prevent alienation of land in the Scheduled Areas.@#$%$# 2 . Gram Sabha has the ownership of minor forest produce.@#$%$# 3. Recommendation of Gram Sabha is required for granting prospecting licence or mining lease for any mineral in the Scheduled Areas .@#$%$# Which of the statements given above is/are correct?@#$%$# [A]1 Only@#$%$# [B]1 and 2 Only@#$%$# [C]2 & 3 Only@#$%$# [D]1,2, & 3@#$%$#";
		String[] parts = test.split("@#\\$%\\$#");
		for (String string : parts) {
			System.out.println(string);
		}
	}
}
