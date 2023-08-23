/**
 * File              : cYandexOAuth.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 12.08.2023
 * Last Modified Date: 22.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
#include "uuid4.h"
#include "cJSON.h"
#include <unistd.h>

#include "cYandexOAuth.h"

/* return allocated c null-terminated string
 * with url to get oauth code or NULL on error*/
char * c_yandex_oauth_code_on_page(const char *client_id) {
	
	char *s = (char *)malloc(BUFSIZ);
	if (!s){
		perror("malloc");
		return NULL;
	}
	
	sprintf(s, 
			"https://oauth.yandex.ru/authorize?response_type=code"	
			"&client_id=%s", client_id);
	
	return s;
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
char *c_yandex_oauth_code_from_html(
		const char *html)
{
	const char * patterns[] = {
		"verification_code%3Fcode%3D",
		"class=\"verification-code-code\">"
	};
	const char *pattern_ends[] = {
		"&",
		"<"
	};	

	int i;
	for (int i = 0; i < 2; i++) {
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

struct string {
	char *ptr;
	size_t len;
};

static void 
init_string(struct string *s) {
	s->len = 0;
	s->ptr = (char *)malloc(s->len+1);
	if (!s->ptr){
		perror("malloc");
		return;
	}
	s->ptr[0] = '\0';
}

static size_t 
writefunc(
		void *ptr, size_t size, size_t nmemb, struct string *s)
{
	size_t new_len = s->len + size*nmemb;
	s->ptr = (char *)realloc(s->ptr, new_len+1);
	if (!s->ptr){
		perror("realloc");
		return 0;
	}
	memcpy(s->ptr+s->len, ptr, size*nmemb);
	s->ptr[new_len] = '\0';
	s->len = new_len;

	return size*nmemb;
}

void c_yandex_oauth_code_from_user(
		const char *client_id, 
		const char *device_name,  //device name - any
		void * user_data,
		int (*callback)(
			void * user_data,
			const char * device_code,
			const char * user_code,
			const char * verification_url,
			int interval,
			int expires_in,
			const char * error
			)
		)
{
	if (client_id == NULL) {
		callback(user_data, NULL, NULL, NULL, 0, 0, "cYandexDisk: No client_id");
		return;
	}
	
	if (device_name == NULL) {
		callback(user_data, NULL, NULL, NULL, 0, 0, "cYandexDisk: No deivce_name");
		return;
	}

	char device_id[37];
	UUID4_STATE_T state; UUID4_T uuid;
	uuid4_seed(&state);
	uuid4_gen(&state, &uuid);
	if (!uuid4_to_s(uuid, device_id, 37)){
		callback(user_data, NULL, NULL, NULL, 0, 0, "cYandexDisk: Can't genarate UUID");
		return;
	}
	
	CURL *curl = curl_easy_init();
		
	struct string s;
	init_string(&s);

	if(curl) {
		char requestString[] = "https://oauth.yandex.ru/device/code";	
		
		curl_easy_setopt(curl, CURLOPT_URL, requestString);
		curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");		
		curl_easy_setopt(curl, CURLOPT_HEADER, 0);

		struct curl_slist *header = NULL;
	    header = curl_slist_append(header, "Connection: close");		
	    header = curl_slist_append(header, "Content-Type: application/x-www-form-urlencoded");		
		curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header);
		
		char post[BUFSIZ];
		sprintf(post, "%s&client_id=%s",		post, client_id);
		sprintf(post, "%s&device_id=%s",		post, device_id);
		sprintf(post, "%s&device_name=%s",	post, device_name);
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post);
		curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, strlen(post));
	    
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);

        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, VERIFY_SSL);		

		CURLcode res = curl_easy_perform(curl);

		if (res) { //handle erros
			callback(user_data, NULL, NULL, NULL, 0, 0, curl_easy_strerror(res));
			free(s.ptr);
			curl_easy_cleanup(curl);
			curl_slist_free_all(header);
      return;			
		}		
		curl_easy_cleanup(curl);
		curl_slist_free_all(header);
	
		//parse JSON answer
		cJSON *json = cJSON_ParseWithLength(s.ptr, s.len);
		free(s.ptr);
		if (cJSON_IsObject(json)) {
			cJSON *device_code = cJSON_GetObjectItem(json, "device_code");			
			if (!device_code) { //handle errors
				cJSON *error_description = cJSON_GetObjectItem(json, "error_description");
				if (!error_description) {
					callback(user_data, NULL, NULL, NULL, 0, 0, "unknown error!"); //no error code in JSON answer
					cJSON_free(json);
					return;
				}
				callback(user_data, NULL, NULL, NULL, 0, 0, error_description->valuestring); //no error code in JSON answer
				cJSON_free(json);
				return;
			}
			//OK - we have a code
			callback(user_data, 
					device_code->valuestring, 
					cJSON_GetObjectItem(json, "user_code")->valuestring, 
					cJSON_GetObjectItem(json, "verification_url")->valuestring, 
					cJSON_GetObjectItem(json, "interval")->valueint, 
					cJSON_GetObjectItem(json, "expires_in")->valueint, 
					NULL
					);
			cJSON_free(json);
		}	
	}

}

void c_yandex_oauth_get_token_from_user(
		const char *device_code, 
		const char *client_id,    //id of application in Yandex
		const char *client_secret,//secret of application in Yandex
		int interval,
		int expires_in,
		void * user_data,
		int (*callback)(
			void * user_data,
			const char * access_token,
			int expires_in,
			const char * refresh_token,
			const char * error
			)
	)
{	
	if (device_code == NULL) {
		callback(user_data, NULL, 0, NULL, "cYandexDisk: No device_code");
		return;
	}
	if (client_id == NULL) {
		callback(user_data, NULL, 0, NULL, "cYandexDisk: No client_id");
		return;
	}
	if (client_secret == NULL) {
		callback(user_data, NULL, 0, NULL, "cYandexDisk: No client_secret");
		return;
	}

	char device_id[37];
	UUID4_STATE_T state; UUID4_T uuid;
	uuid4_seed(&state);
	uuid4_gen(&state, &uuid);
	if (!uuid4_to_s(uuid, device_id, 37)){
		callback(user_data, NULL, 0, NULL, "cYandexDisk: Can't genarate UUID");
		return;
	}
	
	CURL *curl = curl_easy_init();
		
	struct string s;
	init_string(&s);

	if(curl) {
		char requestString[] = "https://oauth.yandex.ru/token";	
		
		curl_easy_setopt(curl, CURLOPT_URL, requestString);
		curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");		
		curl_easy_setopt(curl, CURLOPT_HEADER, 0);

		struct curl_slist *header = NULL;
	    header = curl_slist_append(header, "Connection: close");		
	    header = curl_slist_append(header, "Content-Type: application/x-www-form-urlencoded");		
		curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header);
		
		char post[BUFSIZ];
		sprintf(post, "grant_type=device_code");		
		sprintf(post, "%s&code=%s",				  post, device_code);
		sprintf(post, "%s&client_id=%s",		post, client_id);
		sprintf(post, "%s&client_secret=%s",post, client_secret);
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post);
		curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, strlen(post));
	    
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);

    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, VERIFY_SSL);		

		int i;
		for (i=0; i < expires_in; i += interval){
			
			CURLcode res = curl_easy_perform(curl);

			if (res) { //handle erros
				callback(user_data, NULL, 0, NULL, curl_easy_strerror(res));
				free(s.ptr);
				curl_easy_cleanup(curl);
				curl_slist_free_all(header);
				continue;			
			}		
			curl_easy_cleanup(curl);
			curl_slist_free_all(header);
			
			//parse JSON answer
			cJSON *json = cJSON_ParseWithLength(s.ptr, s.len);
			free(s.ptr);
			if (cJSON_IsObject(json)) {
				cJSON *access_token = cJSON_GetObjectItem(json, "access_token");			
				if (!access_token) { //handle errors
					cJSON *error_description = cJSON_GetObjectItem(json, "error_description");
					if (!error_description) {
						callback(user_data, NULL, 0, NULL, "unknown error!"); //no error code in JSON answer
						cJSON_free(json);
						continue;
					}
					callback(user_data, NULL, 0, NULL, error_description->valuestring);
					cJSON_free(json);
					continue;
				}
				//OK - we have a token
				callback(user_data, access_token->valuestring, cJSON_GetObjectItem(json, "expires_in")->valueint, cJSON_GetObjectItem(json, "refresh_token")->valuestring, NULL);
				cJSON_free(json);
				break;
			}	
			sleep(interval);
		}
	}
}

void c_yandex_oauth_get_token(
		const char *verification_code, 
		const char *client_id, 
		const char *client_secret, 
		const char *device_name, 
		void * user_data,
		int (*callback)(
			void * user_data,
			const char * access_token,
			int expires_in,
			const char * refresh_token,
			const char * error
			)
		)
{
	if (verification_code == NULL) {
		callback(user_data, NULL, 0, NULL, "cYandexDisk: No verification_code");
		return;
	}

	char device_id[37];
	UUID4_STATE_T state; UUID4_T uuid;
	uuid4_seed(&state);
	uuid4_gen(&state, &uuid);
	if (!uuid4_to_s(uuid, device_id, 37)){
		callback(user_data, NULL, 0, NULL, "cYandexDisk: Can't genarate UUID");
		return;
	}
	
	CURL *curl = curl_easy_init();
		
	struct string s;
	init_string(&s);

	if(curl) {
		char requestString[] = "https://oauth.yandex.ru/token";	
		
		curl_easy_setopt(curl, CURLOPT_URL, requestString);
		curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");		
		curl_easy_setopt(curl, CURLOPT_HEADER, 0);

		struct curl_slist *header = NULL;
	    header = curl_slist_append(header, "Connection: close");		
	    header = curl_slist_append(header, "Content-Type: application/x-www-form-urlencoded");		
		curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header);
		
		char post[BUFSIZ];
		sprintf(post, "grant_type=authorization_code");		
		sprintf(post, "%s&code=%s",				post, verification_code);
		sprintf(post, "%s&client_id=%s",		post, client_id);
		sprintf(post, "%s&client_secret=%s",	post, client_secret);
		sprintf(post, "%s&device_id=%s",		post, device_id);
		sprintf(post, "%s&device_name=%s",		post, device_name);
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post);
		curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, strlen(post));
	    
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);

        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, VERIFY_SSL);		

		CURLcode res = curl_easy_perform(curl);

		if (res) { //handle erros
			callback(user_data, NULL, 0, NULL, curl_easy_strerror(res));
			free(s.ptr);
			curl_easy_cleanup(curl);
			curl_slist_free_all(header);
      return;			
		}		
		curl_easy_cleanup(curl);
		curl_slist_free_all(header);
		
		//parse JSON answer
		cJSON *json = cJSON_ParseWithLength(s.ptr, s.len);
		free(s.ptr);
		if (cJSON_IsObject(json)) {
			cJSON *access_token = cJSON_GetObjectItem(json, "access_token");			
			if (!access_token) { //handle errors
				cJSON *error_description = cJSON_GetObjectItem(json, "error_description");
				if (!error_description) {
					callback(user_data, NULL, 0, NULL, "unknown error!"); //no error code in JSON answer
					cJSON_free(json);
					return;
				}
				callback(user_data, NULL, 0, NULL, error_description->valuestring);
				cJSON_free(json);
				return;
			}
			//OK - we have a token
			callback(user_data, access_token->valuestring, cJSON_GetObjectItem(json, "expires_in")->valueint, cJSON_GetObjectItem(json, "refresh_token")->valuestring, NULL);
			cJSON_free(json);
		}	
	}
}
// vim:ft=c
