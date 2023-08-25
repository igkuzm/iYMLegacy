/**
 * File              : oauth.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 23.08.2023
 * Last Modified Date: 23.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* return allocated c null-terminated string
 * with url to get oauth code or NULL on error*/
char * c_yandex_oauth_url(const char *client_id) {
	return strdup( 
			"https://oauth.yandex.ru/authorize"
			"?response_type=token&client_id="
			"23cabbbdc6cd418abb4b39c32c41195d");
}

static long 
strfnd( 
		const char * haystack, 
		const char * needle
		)
{
	//find position of search word in haystack
	const char *p = strstr(haystack, needle);
	if (p)
		return p - haystack;
	return -1;
}

/* return allocated c null-terminated string
 * with oauth code or NULL on error*/
char *c_yandex_oauth_token_from_html(
		const char *html)
{
	const char * patterns[] = {
		"access_token="
	};
	const char *pattern_ends[] = {
		"&"
	};	

	int i;
	for (int i = 0; i < 1; i++) {
		const char * s = patterns[i]; 
		int len = strlen(s);

		//find start of verification code class structure in html
		long start = strfnd(html, s); 
		if (start >= 0){
			//find end of code
			long end = strfnd(&html[start], pattern_ends[i]);

			//find length of verification code
			long clen = end - len;

			//allocate code and copy
			char * code = (char *)malloc(clen + 1);
			if (!code){
				perror("malloc");
				return NULL;
			}

			strncpy(code, &html[start + len], clen);
			code[clen] = 0;

			return code;
		}
	}
	return NULL;
}


