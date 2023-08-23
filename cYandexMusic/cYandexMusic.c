/**
 * File              : cYandexMusic.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 23.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <curl/curl.h>
#include "cYandexMusic.h"
#include "cJSON.h"
#include "structures.h"

//add strptime for winapi
#ifdef _WIN32
char * strptime(const char* s, const char* f, struct tm* tm);
#endif

#define API_URL "https://api.music.yandex.net"
#define VERIFY_SSL 0

#define YD_ANSWER_LIMIT 20

struct string {
	char *ptr;
	size_t len;
};

void init_string(struct string *s) {
	s->len = 0;
	s->ptr = malloc(s->len+1);
	if (!s->ptr){
		perror("malloc");
		return;
	}
	s->ptr[0] = '\0';
}

size_t writefunc(void *ptr, size_t size, size_t nmemb, struct string *s)
{
	size_t new_len = s->len + size*nmemb;
	s->ptr = realloc(s->ptr, new_len+1);
	if (!s->ptr){
		perror("realloc");
		return 0;
	}
	memcpy(s->ptr+s->len, ptr, size*nmemb);
	s->ptr[new_len] = '\0';
	s->len = new_len;

	return size*nmemb;
}

int c_yandex_music_run_method(
		const char *http_method, // "GET", "POST", etc
		const char *token,       // authorization token
		const char *body,        // content of message - NULL-able
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *response_json,
				 const char *error), 
		const char *method,      // method name from yandex music api
		...)                    // - params list - NULL-terminate
{
	char authorization[BUFSIZ];
	sprintf(authorization, "Authorization: OAuth %s", token);

	CURL *curl = curl_easy_init();
		
	struct string s;
	init_string(&s);
	
	if(curl) {
		char requestString[BUFSIZ];	
		sprintf(requestString, "%s/%s", API_URL, method);
		va_list argv;
		va_start(argv, method);
		char *arg = va_arg(argv, char*);
		if (arg) {
			sprintf(requestString, "%s?%s", requestString, arg);
			arg = va_arg(argv, char*);	
		}
		while (arg) {
			sprintf(requestString, "%s&%s", requestString, arg);
			arg = va_arg(argv, char*);	
		}
		va_end(argv);

		curl_easy_setopt(curl, CURLOPT_URL, requestString);
		curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, http_method);		
		curl_easy_setopt(curl, CURLOPT_HEADER, 0);
		curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);		

		/* enable verbose for easier tracing */
		/*curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);		*/

		struct curl_slist *header = NULL;
	    header = curl_slist_append(header, "Connection: close");		
	    header = curl_slist_append(header, "Content-Type: application/json");
	    header = curl_slist_append(header, "Accept: application/json");
	    header = curl_slist_append(header, authorization);
		curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header);

		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);

		if (body) {
			curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
			curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, strlen(body));
		}

		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, VERIFY_SSL);		

		CURLcode res = curl_easy_perform(curl);

		if (res) { //handle erros
			if (callback)
				callback(user_data, NULL, curl_easy_strerror(res));
			free(s.ptr);
			curl_easy_cleanup(curl);
			curl_slist_free_all(header);
      return -1;			
		}		
		curl_easy_cleanup(curl);
		curl_slist_free_all(header);
		
		//parse JSON answer
		cJSON *json = cJSON_ParseWithLength(s.ptr, s.len);
		if (json){
			cJSON *error_in_json = cJSON_GetObjectItem(json, "error");
			if (error_in_json){
				cJSON *message = cJSON_GetObjectItem(error_in_json, "message");
				if (message){
					if (callback)
						callback(user_data, NULL, message->valuestring);
				} else {
					if (callback)
						callback(user_data, NULL, "unknown error");
				}
				cJSON_free(json);
				free(s.ptr);
				return -1;
			} else {
				cJSON *result = cJSON_GetObjectItem(json, "result");
				if (result){
					if (callback)
						callback(user_data, cJSON_Print(result), NULL);
					cJSON_free(json);
					free(s.ptr);
					return 0;
				} else {
					char msg[BUFSIZ];
					sprintf(msg, "json with no result: %s", cJSON_Print(json));
					if (callback)
						callback(user_data, NULL, NULL);
					cJSON_free(json);
					free(s.ptr);
					return 0;
				}
			}
		} else {
			if (callback){
				char msg[BUFSIZ];
				sprintf(msg, "can't parse json from string: %s", s.ptr);
				callback(user_data, NULL, msg);
			}
			free(s.ptr);
			return -1;
		}
	}

	return 0;
}

struct c_yandex_music_get_feed_data {
	void *user_data; 
	int (*callback)(void *, track_t *, const char *);
};
static void c_yandex_music_get_feed_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_get_feed_data *d = data;
	if (error)
		if (d->callback)
			d->callback(d->user_data, NULL, error);
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			cJSON *days = 
				cJSON_GetObjectItem(json, "days");
			if (days){
				cJSON *day;
				for (day = days->child; day; day = day->next) 
				{
					cJSON *tracksToPlay = 
						cJSON_GetObjectItem(day, "tracksToPlay");
					if (tracksToPlay){
						cJSON *track;
						for (track = tracksToPlay->child; track; 
								track = track->next) 
						{
							track_t *p = 
								c_yandex_music_track_new_from_json(track);
							if (p){
								if (d->callback)
									if (d->callback(d->user_data, p, NULL))
										break;
							}
						}
					} else
						if (d->callback)
							d->callback(d->user_data, NULL, 
									"day has no tracks to play");
				}
			} else 
				if (d->callback)
					d->callback(d->user_data, NULL, 
							"json has no days");
		} else {
			if (d->callback){
				char msg[BUFSIZ];
				sprintf(msg, "can't parse json from string: %s", str);
				d->callback(d->user_data, NULL, msg);
			}
		}
	}
}
int c_yandex_music_get_feed(
		const char *token,       
		void *user_data, 
		int (*callback)         
				(void *user_data,
				 track_t * track,
				 const char *error))
{
	struct c_yandex_music_get_feed_data d =
		{user_data, callback};
	return c_yandex_music_run_method(
			"GET", token, NULL, &d, c_yandex_music_get_feed_cb, "/feed", NULL);
}
