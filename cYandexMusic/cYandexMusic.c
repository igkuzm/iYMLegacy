/**
 * File              : cYandexMusic.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 11.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <curl/curl.h>
#include <time.h>
#include "cYandexMusic.h"
#include "cJSON.h"
#include "structures.h"
#include "ezxml.h"
#include "md5.h"
#include "uuid4.h"

//add strptime for winapi
#ifdef _WIN32
char * strptime(const char* s, const char* f, struct tm* tm);
#endif

#define API_URL "https://api.music.yandex.net"
#define VERIFY_SSL 0

#define YD_ANSWER_LIMIT 20

static int lastpath(const char *filename) {
		const char *slash = strrchr(filename, '/');
		if (!slash || slash == filename)
			return 0;
		return slash - filename;
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


struct str {
	char *ptr;
	size_t len;
};

void init_str(struct str *s) {
	s->len = 0;
	s->ptr = malloc(s->len+1);
	if (!s->ptr){
		perror("malloc");
		return;
	}
	s->ptr[0] = '\0';
}

size_t writefunc(void *ptr, size_t size, size_t nmemb, struct str *s)
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
		
	struct str s;
	init_str(&s);
	
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

		printf("REQUEST STRING: %s\n", requestString);
		curl_easy_setopt(curl, CURLOPT_URL, requestString);
		curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, http_method);		
		curl_easy_setopt(curl, CURLOPT_HEADER, 0);
		curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);		

		/* enable verbose for easier tracing */
		/*curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);		*/

		struct curl_slist *header = NULL;
	    header = curl_slist_append(header, "Connection: close");		
			//header = curl_slist_append(header, "Content-Type: application/json");
			header = curl_slist_append(header, "Content-Type: application/x-www-form-urlencoded");
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
	int (*callback)(void *, playlist_t *, track_t *, const char *);
	const char *image_size; 
};
static void c_yandex_music_get_feed_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_get_feed_data *d = data;
	
	const char *size = "orig";
	if (d->image_size)
		size = d->image_size;

	if (error)
		if (d->callback)
			d->callback(d->user_data, NULL, NULL, error);
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			//d->callback(d->user_data, NULL, NULL, cJSON_Print(json));
			//return;
			cJSON *generatedPlaylists = 
					cJSON_GetObjectItem(json, "generatedPlaylists");
			if (generatedPlaylists){
				cJSON *generatedPlaylist;
			 for (generatedPlaylist = generatedPlaylists->child;
					 generatedPlaylist;
					 generatedPlaylist = generatedPlaylist->next) 
			 {
				cJSON *data = 
						cJSON_GetObjectItem(generatedPlaylist, "data");
				if (data){
					playlist_t *p = 
							c_yandex_music_playlist_new_from_json(data);
					if (p){
						// fix image
						if (p->ogImage){
							char str[BUFSIZ];
							int i = lastpath(p->ogImage);
							p->ogImage[i] = 0;
							sprintf(str, "https://%s/%s", p->ogImage, size);
							free(p->ogImage);
							p->ogImage = strdup(str);
						}
						if (d->callback)
							if (d->callback(d->user_data, p, NULL, NULL))
								return;
					}
				}
			 }	
			}
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
								//fix uris
								if (p->coverUri){
									char str[BUFSIZ];
									int i = lastpath(p->coverUri);
									p->coverUri[i] = 0;
									sprintf(str, "https://%s/%s", p->coverUri, size);
									free(p->coverUri);
									p->coverUri = strdup(str);
								}	
								if (p->ogImage){
									char str[BUFSIZ];
									int i = lastpath(p->ogImage);
									p->ogImage[i] = 0;
									sprintf(str, "https://%s/%s", p->ogImage, size);
									free(p->ogImage);
									p->ogImage = strdup(str);
								}

								if (d->callback)
									if (d->callback(d->user_data, NULL, p, NULL))
										return;
							}
						}
					}
				}
			}
		} else {
			if (d->callback){
				char msg[BUFSIZ];
				sprintf(msg, "can't parse json from string: %s", str);
				d->callback(d->user_data, NULL, NULL, msg);
			}
		}
	}
}
int c_yandex_music_get_feed(
		const char *token,       
		const char *image_size,
		void *user_data, 
		int (*callback)         
				(void *user_data,
				 playlist_t * playlist,
				 track_t * track,
				 const char *error))
{
	struct c_yandex_music_get_feed_data d =
		{user_data, callback, image_size};
	return c_yandex_music_run_method(
			"GET", token, NULL, &d, c_yandex_music_get_feed_cb, "/feed", NULL);
}

struct c_yandex_music_get_download_url_data {
	void *user_data; 
	int (*callback)(void *, const char *, const char *);
	const char *token;
};
static void c_yandex_music_get_download_url_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_get_download_url_data *d = data;
	if (error)
		if (d->callback)
			d->callback(d->user_data, NULL, error);
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			cJSON *item;
			for (item = json->child; item; item = item->next) {
			//cJSON *item = json->child;
			//if (item){
				// ok! we have download info
				struct downloadInfo downloadInfo;
				init_downloadInfo(&downloadInfo, item);
				//d->callback(d->user_data, NULL, downloadInfo.codec);

				// get xml with url
				CURL *curl = curl_easy_init();
				struct str s;
				init_str(&s);
				
				if(curl) {
					char authorization[BUFSIZ];
					sprintf(authorization, "Authorization: OAuth %s", d->token);
					
					curl_easy_setopt(curl, CURLOPT_URL, downloadInfo.downloadInfoUrl);
					curl_easy_setopt(curl, CURLOPT_HEADER, 0);
					curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);		
					curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
					curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);
					curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, VERIFY_SSL);		
					
					struct curl_slist *header = NULL;
					header = curl_slist_append(header, authorization);
					curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header);

					CURLcode res = curl_easy_perform(curl);

					if (res) { //handle erros
						if (d->callback)
							d->callback(d->user_data, NULL, curl_easy_strerror(res));
						free(s.ptr);
						curl_easy_cleanup(curl);
						curl_slist_free_all(header);
						continue;;			
						//return;
					}		
					curl_easy_cleanup(curl);
					curl_slist_free_all(header);
					
					//find sign
					char sign[BUFSIZ];
					char * pattern = "sign=";
					int len = strlen(pattern);
					long start = strfnd(downloadInfo.downloadInfoUrl, pattern); 
					if (start < 0)
						continue;
						//return;
					long end = strfnd(&(downloadInfo.downloadInfoUrl[start]), "&");
					long clen = end - len;
					strncpy(sign, &(downloadInfo.downloadInfoUrl[start + len]), clen);
					sign[clen] = 0;

					//parse XML answer
					ezxml_t xml = 
							ezxml_parse_str(s.ptr, -1);
					if (xml){
						ezxml_t host = 
								ezxml_get(xml, "host", -1);
						ezxml_t path = 
								ezxml_get(xml, "path", -1);
						ezxml_t ts = 
								ezxml_get(xml, "ts", -1);
						ezxml_t s = 
								ezxml_get(xml, "s", -1);

						// generate signature
						char str[BUFSIZ], url[BUFSIZ];
						//sprintf(str, 
								//"XGRlBW9FXlekgbPrRHuSiA"
								//"%s%s", &((path->txt)[1]), s->txt);
						//md5String(str, sign);

						sprintf(url, "https://%s/get-%s/%s/%s%s",
								host->txt, downloadInfo.codec, sign, ts->txt, path->txt);

						if (d->callback)
							if (d->callback(d->user_data, url, NULL))
								break;
								//return;
					}
					free(s.ptr);
				}	
			}
		} else {
			if (d->callback){
				char msg[BUFSIZ];
				sprintf(msg, "can't parse json from string: %s", str);
				d->callback(d->user_data, NULL, msg);
			}
		}
	}
}
int c_yandex_music_get_download_url(
		const char *token,       
		const char *track_id,    
		void *user_data, 
		int (*callback)
				(void *user_data,
				 const char * url,
				 const char *error))
{
	struct c_yandex_music_get_download_url_data d =
		{user_data, callback, token};
	char method[BUFSIZ];
	sprintf(method, "tracks/%s/download-info", track_id);
	return c_yandex_music_run_method(
			"GET", token, NULL, &d, c_yandex_music_get_download_url_cb, method, NULL);
}

struct c_yandex_music_search_data {
	void *user_data; 
	int (*callback)(void *, playlist_t *, album_t *, track_t *, const char *);
	const char *token;
	const char *image_size;	 // NULL - for original
};
static void c_yandex_music_search_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_search_data *d = data;
	if (error)
		if (d->callback)
			d->callback(d->user_data, NULL, NULL, NULL, error);
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			//d->callback(d->user_data, NULL, NULL, NULL, cJSON_Print(json));
			//return;
			cJSON *best = cJSON_GetObjectItem(json, "best");
			if (best){
				cJSON *type = cJSON_GetObjectItem(json, "type");
				cJSON *result = cJSON_GetObjectItem(json, "result");
				if (result){
					track_t *p = c_yandex_music_track_new_from_json(result);
					if (p){
						//set type
						if (type && type->valuestring){
							/*if (p->type)*/
								/*free(p->type);*/
							p->type = strdup(type->valuestring);
						}
						//fix uris
						const char *size = "orig";
						if (d->image_size)
							size = d->image_size;
						if (p->coverUri){
							char str[BUFSIZ];
							int i = lastpath(p->coverUri);
							p->coverUri[i] = 0;
							sprintf(str, "https://%s/%s", p->coverUri, size);
							free(p->coverUri);
							p->coverUri = strdup(str);
						}	
						if (p->ogImage){
							char str[BUFSIZ];
							int i = lastpath(p->ogImage);
							p->ogImage[i] = 0;
							sprintf(str, "https://%s/orig", p->ogImage);
							free(p->ogImage);
							p->ogImage = strdup(str);
						}
						if (d->callback){
							d->callback(d->user_data, NULL, NULL, p, NULL);
						}
					}
				}
			}
			cJSON *tracks = cJSON_GetObjectItem(json, "tracks");
			if (tracks){
				cJSON *results = cJSON_GetObjectItem(tracks, "results");
				cJSON *track;
				for (track=results->child; track; track = track->next){
					track_t *p = c_yandex_music_track_new_from_json(track);
					if (p){
						// set type
						/*if (p->type)*/
							/*free(p->type);*/
						p->type = strdup("track");
						//fix uris
						const char *size = "orig";
						if (d->image_size)
							size = d->image_size;
						if (p->coverUri){
							char str[BUFSIZ];
							int i = lastpath(p->coverUri);
							p->coverUri[i] = 0;
							sprintf(str, "https://%s/%s", p->coverUri, size);
							free(p->coverUri);
							p->coverUri = strdup(str);
						}	
						if (p->ogImage){
							char str[BUFSIZ];
							int i = lastpath(p->ogImage);
							p->ogImage[i] = 0;
							sprintf(str, "https://%s/orig", p->ogImage);
							free(p->ogImage);
							p->ogImage = strdup(str);
						}
						if (d->callback){
							if (d->callback(d->user_data, NULL, NULL, p, NULL))
								break;
						}
					}
				}
			}
			cJSON *albums = cJSON_GetObjectItem(json, "albums");
			if (albums){
				cJSON *results = cJSON_GetObjectItem(albums, "results");
				cJSON *album;
				for (album=results->child; album; album = album->next){
					album_t *p = c_yandex_music_album_new_from_json(album);
					if (p){
						//fix uris
						const char *size = "orig";
						if (d->image_size)
							size = d->image_size;
						if (p->coverUri){
							char str[BUFSIZ];
							int i = lastpath(p->coverUri);
							p->coverUri[i] = 0;
							sprintf(str, "https://%s/%s", p->coverUri, size);
							free(p->coverUri);
							p->coverUri = strdup(str);
						}	
						if (p->ogImage){
							char str[BUFSIZ];
							int i = lastpath(p->ogImage);
							p->ogImage[i] = 0;
							sprintf(str, "https://%s/orig", p->ogImage);
							free(p->ogImage);
							p->ogImage = strdup(str);
						}
						if (d->callback){
							 if (d->callback(d->user_data, NULL, p, NULL, NULL))
								break;
						}
					}
				}
			}
			cJSON *podcasts = cJSON_GetObjectItem(json, "podcasts");
			if (podcasts){
				cJSON *results = cJSON_GetObjectItem(podcasts, "results");
				cJSON *album;
				for (album=results->child; album; album = album->next){
					album_t *p = c_yandex_music_album_new_from_json(album);
					if (p){
						// set type
						/*if (p->type)*/
							/*free(p->type);*/
						p->type = strdup("podcast");
						//fix uris
						const char *size = "orig";
						if (d->image_size)
							size = d->image_size;
						if (p->coverUri){
							char str[BUFSIZ];
							int i = lastpath(p->coverUri);
							p->coverUri[i] = 0;
							sprintf(str, "https://%s/%s", p->coverUri, size);
							free(p->coverUri);
							p->coverUri = strdup(str);
						}	
						if (p->ogImage){
							char str[BUFSIZ];
							int i = lastpath(p->ogImage);
							p->ogImage[i] = 0;
							sprintf(str, "https://%s/orig", p->ogImage);
							free(p->ogImage);
							p->ogImage = strdup(str);
						}
						if (d->callback){
							if (d->callback(d->user_data, NULL, p, NULL, NULL))
								break;
						}
					}
				}
			}
			cJSON *podcast_episodes = cJSON_GetObjectItem(json, "podcast_episodes");
			if (podcast_episodes){
				cJSON *results = cJSON_GetObjectItem(podcast_episodes, "results");
				cJSON *track;
				for (track=results->child; track; track = track->next){
					track_t *p = c_yandex_music_track_new_from_json(track);
					if (p){
						// set type
						/*if (p->type)*/
							/*free(p->type);*/
						p->type = strdup("podcast_episode");
						//fix uris
						const char *size = "orig";
						if (d->image_size)
							size = d->image_size;
						if (p->coverUri){
							char str[BUFSIZ];
							int i = lastpath(p->coverUri);
							p->coverUri[i] = 0;
							sprintf(str, "https://%s/%s", p->coverUri, size);
							free(p->coverUri);
							p->coverUri = strdup(str);
						}	
						if (p->ogImage){
							char str[BUFSIZ];
							int i = lastpath(p->ogImage);
							p->ogImage[i] = 0;
							sprintf(str, "https://%s/orig", p->ogImage);
							free(p->ogImage);
							p->ogImage = strdup(str);
						}
						if (d->callback){
							if (d->callback(d->user_data, NULL, NULL, p, NULL))
								break;
						}
					}
				}
			}
			cJSON *playlists = cJSON_GetObjectItem(json, "playlists");
			if (playlists){
				cJSON *results = cJSON_GetObjectItem(playlists, "results");
				cJSON *playlist;
				for (playlist=results->child; playlist; playlist = playlist->next){
					playlist_t *p = c_yandex_music_playlist_new_from_json(playlist);
					if (p){
						//fix uris
						const char *size = "orig";
						if (d->image_size)
							size = d->image_size;
						if (p->ogImage){
							char str[BUFSIZ];
							int i = lastpath(p->ogImage);
							p->ogImage[i] = 0;
							sprintf(str, "https://%s/orig", p->ogImage);
							free(p->ogImage);
							p->ogImage = strdup(str);
						}
						if (d->callback){
							if (d->callback(d->user_data, p, NULL, NULL, NULL))
								break;
						}
					}
				}
			}

		}
	}
}

int c_yandex_music_search(
		const char *token,       
		const char *search,    
		const char *image_size,	 // NULL - for original
		void *user_data, 
		int (*callback)
				(void *user_data,
				 playlist_t * playlist,
				 album_t * album,
				 track_t *track,
				 const char *error))
{
	int ret = -1;
	struct c_yandex_music_search_data d =
		{user_data, callback, token, image_size};

	CURL *curl = curl_easy_init();
	if (curl){
		char *search_str = curl_easy_escape(curl, search, strlen(search));
		if (search_str){
			char text[BUFSIZ];
			sprintf(text, "text=%s", search_str);
			ret =  c_yandex_music_run_method(
					"GET", token, NULL, &d, c_yandex_music_search_cb, 
					"search", text, "page=0", "type=all", "nocorrect=false", NULL);

			free(search_str);
		}
		curl_easy_cleanup(curl);
	}
	return ret;
}

static void c_yandex_music_get_uid_cb(
		void *data, const char *str, const char *error)
{
	long *puid = data;
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			cJSON *account = cJSON_GetObjectItem(json, "account");
			if (account){
				cJSON *uid = cJSON_GetObjectItem(account, "uid");
				if (uid){
					*puid = uid->valueint;
				}
			}
		}
	}
}
	
long c_yandex_music_get_uid(const char *token){
	long uid = 0;
	c_yandex_music_run_method(
					"GET", token, NULL, &uid, c_yandex_music_get_uid_cb, 
					"account/status", NULL);
	return uid;
}

struct c_yandex_music_get_playlist_tracks_data {
	void *user_data; 
	int (*callback)(void *, track_t *, const char *);
	const char *image_size; 
};
static void c_yandex_music_get_playlist_tracks_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_get_playlist_tracks_data *d = data;
	
	const char *size = "orig";
	if (d->image_size)
		size = d->image_size;

	if (error)
		if (d->callback)
			d->callback(d->user_data, NULL, error);
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			//d->callback(d->user_data, NULL, cJSON_Print(json));
			//return;
			cJSON *tracks = 
				cJSON_GetObjectItem(json, "tracks");
			if (tracks){
				cJSON *child;
				for (child = tracks->child; child; child = child->next) 
				{
					cJSON *track = 
						cJSON_GetObjectItem(child, "track");
						if (track){
							track_t *p = 
								c_yandex_music_track_new_from_json(track);
							if (p){
								//fix uris
								if (p->coverUri){
									char str[BUFSIZ];
									int i = lastpath(p->coverUri);
									p->coverUri[i] = 0;
									sprintf(str, "https://%s/%s", p->coverUri, size);
									free(p->coverUri);
									p->coverUri = strdup(str);
								}	
								if (p->ogImage){
									char str[BUFSIZ];
									int i = lastpath(p->ogImage);
									p->ogImage[i] = 0;
									sprintf(str, "https://%s/%s", p->ogImage, size);
									free(p->ogImage);
									p->ogImage = strdup(str);
								}

								if (d->callback)
									if (d->callback(d->user_data, p, NULL))
										return;
							}
						}
					}
				}
		} else {
			if (d->callback){
				char msg[BUFSIZ];
				sprintf(msg, "can't parse json from string: %s", str);
				d->callback(d->user_data, NULL, msg);
			}
		}
	}
}


int c_yandex_music_get_playlist_tracks(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		long playlist_uid,
		long playlist_kind,
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 track_t * track,
				 const char *error))
{
	struct c_yandex_music_get_playlist_tracks_data d =
		{user_data, callback, image_size};
	
	char method[BUFSIZ];
	sprintf(method, "users/%ld/playlists/%ld", playlist_uid, playlist_kind);
	return c_yandex_music_run_method(
			"GET", token, NULL, &d, c_yandex_music_get_playlist_tracks_cb, method, NULL);

}

struct c_yandex_music_get_track_by_id_data {
	void *user_data; 
	int (*callback)(void *, track_t *, const char *);
	const char *image_size; 
	const char *token;       
};

static void c_yandex_music_get_track_by_id_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_get_track_by_id_data *d = data;
	
	const char *size = "orig";
	if (d->image_size)
		size = d->image_size;

	if (error)
		if (d->callback)
			d->callback(d->user_data, NULL, error);
	if (str){
		cJSON *tracks = cJSON_Parse(str);
		if (tracks){
			cJSON *track = tracks->child;
			if (track){
				track_t *p = 
					c_yandex_music_track_new_from_json(track);
				if (p){
					//fix uris
					if (p->coverUri){
						char str[BUFSIZ];
						int i = lastpath(p->coverUri);
						p->coverUri[i] = 0;
						sprintf(str, "https://%s/%s", p->coverUri, size);
						free(p->coverUri);
						p->coverUri = strdup(str);
					}	
					if (p->ogImage){
						char str[BUFSIZ];
						int i = lastpath(p->ogImage);
						p->ogImage[i] = 0;
						sprintf(str, "https://%s/%s", p->ogImage, size);
						free(p->ogImage);
						p->ogImage = strdup(str);
					}

					if (d->callback)
						d->callback(d->user_data, p, NULL);
				}
			}
		} else {
			if (d->callback){
				char msg[BUFSIZ];
				sprintf(msg, "can't parse json from string: %s", str);
				d->callback(d->user_data, NULL, msg);
			}
		}
	}
}


int c_yandex_music_get_track_by_id(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		const char *trackId,
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 track_t * track,
				 const char *error))
{
	struct c_yandex_music_get_track_by_id_data d =
		{user_data, callback, image_size, token};
	
	char method[BUFSIZ];
	sprintf(method, "tracks/%s", trackId);
	return c_yandex_music_run_method(
			"GET", token, NULL, &d, c_yandex_music_get_track_by_id_cb, method, NULL);
}

struct c_yandex_music_get_favorites_data {
	void *user_data; 
	int (*callback)(void *, track_t *, const char *);
	const char *image_size; 
	const char *token;
};
static void c_yandex_music_get_favorites_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_get_favorites_data *d = data;
	
	const char *size = "orig";
	if (d->image_size)
		size = d->image_size;

	if (error)
		if (d->callback)
			d->callback(d->user_data, NULL, error);
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			//d->callback(d->user_data, NULL, cJSON_Print(json));
			//return;
			cJSON *library = 
				cJSON_GetObjectItem(json, "library");
			if (library){
				cJSON *tracks = 
					cJSON_GetObjectItem(library, "tracks");
				if (tracks){
					cJSON *child;
					for (child = tracks->child; child; child = child->next) 
					{
						cJSON *id = 
								cJSON_GetObjectItem(child, "id");
						if (id && id->valuestring){
							// get track by id
							c_yandex_music_get_track_by_id(
									d->token, 
									d->image_size, 
									id->valuestring, 
									d->user_data, d->callback);

						}
					}
				}
			}
		} else {
			if (d->callback){
				char msg[BUFSIZ];
				sprintf(msg, "can't parse json from string: %s", str);
				d->callback(d->user_data, NULL, msg);
			}
		}
	}
}


int c_yandex_music_get_favorites(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		long uid,
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 track_t * track,
				 const char *error))
{
	struct c_yandex_music_get_favorites_data d =
		{user_data, callback, image_size, token};
	
	char method[BUFSIZ];
	sprintf(method, "users/%ld/likes/tracks", uid);
	return c_yandex_music_run_method(
			"GET", token, NULL, &d, c_yandex_music_get_favorites_cb, method, NULL);
}

struct c_yandex_music_post_current_data {
	void *user_data; 
	void (*callback)(void *, const char *);
	const char *token;       
};

static void c_yandex_music_post_current_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_post_current_data *d = data;
	
	if (error)
		if (d->callback)
			d->callback(d->user_data, error);
}

char * c_yandex_music_post_current(
		const char *token,       // authorization token
		const char *uuid,
		const char *trackId,
		int track_length_seconds,
		int track_played_seconds,
		long uid,
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *error))
{
	char *uuid_str = NULL;
	if (!uuid){
		uuid_str = malloc(37);
		if (!uuid_str){
			if (callback)
				callback(user_data, "can't allocate memory");
			return NULL;
		}
		UUID4_STATE_T state; UUID4_T uuid_;
		uuid4_seed(&state);
		uuid4_gen(&state, &uuid_);
		if (!uuid4_to_s(uuid_, uuid_str, 37)){
			if (callback)
				callback(user_data, "can't generate uuid");
			return NULL;
		}
		uuid = uuid_str;
	}

	struct c_yandex_music_post_current_data d = 
		{user_data, callback, token};

	time_t t = time(NULL);
	struct tm *tp = gmtime(&t);
	char date[128] = "";
	//strftime(date, 128, "%Y-%m-%dT%H:%M:%SZ", tp);
	sprintf(date, "%04d-%02d-%02dT%02d%%3A%02d%%3A%02d.000Z", 
			tp->tm_year + 1900, tp->tm_mon + 1, tp->tm_mday,
			tp->tm_hour, tp->tm_min, tp->tm_sec);

			char body[BUFSIZ] = "";
			sprintf(body, 
					"from=cYandexMusic"
					"&uid=%ld"
					"&track-id=%s"
					"&play-id=%s"
					"&track-length-seconds=%d"
					"&total-played-seconds=%d"
					"&client-now=%s"
					"&timestamp=%s",
					uid, trackId, uuid, track_length_seconds, 
					track_played_seconds, date, date);
		
		if (c_yandex_music_run_method(
					"POST", token, body, &d, 
					c_yandex_music_post_current_cb, "play-audio", NULL))
		{
			if (uuid_str)
				free(uuid_str);
			return NULL;
		}
		return uuid_str;
}
	
struct c_yandex_music_get_album_tracks_data {
	void *user_data; 
	int (*callback)(void *, track_t *, const char *);
	const char *image_size; 
};
static void c_yandex_music_get_album_tracks_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_get_album_tracks_data *d = data;
	
	const char *size = "orig";
	if (d->image_size)
		size = d->image_size;

	if (error)
		if (d->callback)
			d->callback(d->user_data, NULL, error);
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			//d->callback(d->user_data, NULL, cJSON_Print(json));
			//return;
			cJSON *volumes = cJSON_GetObjectItem(json, "volumes");
			if (volumes){
				cJSON *volume;
				for (volume = volumes->child;
						 volume;
						 volume = volume->next)
				{
					cJSON *track;
					for (track = volume->child;
							track;
							track = track->next)
					{
								track_t *p = 
									c_yandex_music_track_new_from_json(track);
								if (p){
									//fix uris
									if (p->coverUri){
										char str[BUFSIZ];
										int i = lastpath(p->coverUri);
										p->coverUri[i] = 0;
										sprintf(str, "https://%s/%s", p->coverUri, size);
										free(p->coverUri);
										p->coverUri = strdup(str);
									}	
									if (p->ogImage){
										char str[BUFSIZ];
										int i = lastpath(p->ogImage);
										p->ogImage[i] = 0;
										sprintf(str, "https://%s/%s", p->ogImage, size);
										free(p->ogImage);
										p->ogImage = strdup(str);
									}

									if (d->callback)
										d->callback(d->user_data, p, NULL);
								}
							}
						}
			}
		}
	}
}
	
int c_yandex_music_get_album_tracks(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		long album_id,
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 track_t * track,
				 const char *error))
{
	struct c_yandex_music_get_album_tracks_data d =
			{user_data, callback, image_size};
	
	char method[BUFSIZ];
	sprintf(method, "albums/%ld/with-tracks", album_id);
	return c_yandex_music_run_method(
			"GET", token, NULL, &d, c_yandex_music_get_album_tracks_cb, method, NULL);
}

struct c_yandex_music_get_user_playlists_data {
	void *user_data; 
	int (*callback)(void *, playlist_t *, const char *);
	const char *image_size; 
};
static void c_yandex_music_get_user_playlists_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_get_user_playlists_data *d = data;
	
	const char *size = "orig";
	if (d->image_size)
		size = d->image_size;

	if (error)
		if (d->callback)
			d->callback(d->user_data, NULL, error);
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			//d->callback(d->user_data, NULL, cJSON_Print(json));
			//return;
			cJSON *playlist;
			for (playlist=json->child; playlist; playlist = playlist->next){
				playlist_t *p = c_yandex_music_playlist_new_from_json(playlist);
				if (p){
					//fix uris
					const char *size = "orig";
					if (d->image_size)
						size = d->image_size;
					if (p->ogImage){
						char str[BUFSIZ];
						int i = lastpath(p->ogImage);
						p->ogImage[i] = 0;
						sprintf(str, "https://%s/orig", p->ogImage);
						free(p->ogImage);
						p->ogImage = strdup(str);
					}
					if (d->callback){
						if (d->callback(d->user_data, p, NULL))
							break;
					}
				}
			}
		}
	}
}

int c_yandex_music_get_user_playlists(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		long uid,                // user id
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 playlist_t * playlist,
				 const char *error))
{
	struct c_yandex_music_get_user_playlists_data d =
			{user_data, callback, image_size};
	
	char method[BUFSIZ];
	sprintf(method, "users/%ld/playlists/list", uid);
	return c_yandex_music_run_method(
			"GET", token, NULL, &d, c_yandex_music_get_user_playlists_cb, method, NULL);
}

struct c_yandex_music_remove_playlist_data {
	void *user_data; 
	void (*callback)(void *, const char *);
	const char *token;       
};

static void c_yandex_music_remove_playlist_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_remove_playlist_data *d = data;
	
	if (error)
		if (d->callback)
			d->callback(d->user_data, error);
}

int c_yandex_music_remove_playlist(
		const char *token,       // authorization token
		long playlist_uid,
		long playlist_kind,
		void *user_data, 
		void (*callback)          
				(void *user_data,
				 const char *error))
{
struct c_yandex_music_remove_playlist_data d =
		{user_data, callback};
	
	char method[BUFSIZ];
	sprintf(method, "users/%ld/playlists/%ld/delete", playlist_uid, playlist_kind);
	return c_yandex_music_run_method(
			"POST", token, NULL, &d, c_yandex_music_remove_playlist_cb, method, NULL);
}

struct c_yandex_music_like_current_data {
	void *user_data; 
	void (*callback)(void *, const char *);
	const char *token;       
};

static void c_yandex_music_like_current_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_like_current_data *d = data;
	
	if (error)
		if (d->callback)
			d->callback(d->user_data, error);
}

int c_yandex_music_set_like_current(
		const char *token,       // authorization token
		long uid,
		const char *trackId,
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *error))
{
	struct c_yandex_music_like_current_data d = 
		{user_data, callback, token};
	
	char method[BUFSIZ] = "";
	sprintf(method, "users/%ld/likes/tracks/add-multiple", uid);
	
	char body[BUFSIZ] = "";
	sprintf(body, "track-ids=%s", trackId);
	//sprintf(body, "{'track-ids': [%s]}", trackId);
	
	return c_yandex_music_run_method(
			"POST", token, body, &d, c_yandex_music_like_current_cb, method, NULL);
}
	
int c_yandex_music_set_unlike_current(
		const char *token,       // authorization token
		long uid,
		const char *trackId,
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *error))
{
	struct c_yandex_music_like_current_data d = 
		{user_data, callback, token};
	
	char method[BUFSIZ] = "";
	sprintf(method, "users/%ld/likes/tracks/remove", uid);
	
	char body[BUFSIZ] = "";
	sprintf(body, "track-ids=%s", trackId);
	//sprintf(body, "{'track-ids': [%s]}", trackId);
	
	return c_yandex_music_run_method(
			"POST", token, body, &d, c_yandex_music_like_current_cb, method, NULL);
}
	

struct c_yandex_music_create_playlist_data {
	void *user_data; 
	void (*callback)(void *, const char *);
	const char *token;       
	playlist_t **p;
};

static void c_yandex_music_create_playlist_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_create_playlist_data *d = data;
	
	if (error)
		if (d->callback)
			d->callback(d->user_data, error);
	
	if (str){
		cJSON *json = cJSON_Parse(str);
		if (json){
			//d->callback(d->user_data, cJSON_Print(json));
			//return;
			playlist_t *p = 
					c_yandex_music_playlist_new_from_json(json);
			if (p){
				// fix image
				if (p->ogImage){
					char str[BUFSIZ];
					int i = lastpath(p->ogImage);
					p->ogImage[i] = 0;
					sprintf(str, "https://%s/%s", p->ogImage, "orig");
					free(p->ogImage);
					p->ogImage = strdup(str);
				}
				d->p[0] = p;
			}
		}
	}
}

playlist_t * c_yandex_music_create_playlist(
		const char *token,       // authorization token
		long uid,                // user id
		const char *title,
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *error))
{
	playlist_t *p = NULL;
	struct c_yandex_music_create_playlist_data d = 
		{user_data, callback, token, &p};
	
	char method[BUFSIZ] = "";
	sprintf(method, "users/%ld/playlists/create", uid);
	
	CURL *curl = curl_easy_init();
	if (curl){
		char *title_str = curl_easy_escape(curl, title, strlen(title));
		if (title_str){
			char body[BUFSIZ];
			sprintf(body, "title=%s&visibility=public", title_str);
			c_yandex_music_run_method(
					"POST", token, body, &d, c_yandex_music_create_playlist_cb, 
					method, NULL);

			free(title_str);
		}
		curl_easy_cleanup(curl);
	}
	return p;
}

struct c_yandex_music_playlist_add_tracks_data {
	void *user_data; 
	void (*callback)(void *, const char *);
	const char *token;       
};

static void c_yandex_music_playlist_add_tracks_cb(
		void *data, const char *str, const char *error)
{
	struct c_yandex_music_playlist_add_tracks_data *d = data;
	
	if (error)
		if (d->callback)
			d->callback(d->user_data, error);
}

int c_yandex_music_playlist_add_tracks(
		const char *token,       // authorization token
		long uid,                // user id
		long kind,
		long * track_ids,
		long * album_ids,
		int count,
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *error))
{
	int ret = -1;
	struct c_yandex_music_playlist_add_tracks_data d = 
		{user_data, callback, token};

	char method[BUFSIZ] = "";
	sprintf(method, "users/%ld/playlists/%ld/change-relative", uid, kind);
	
	//"{\"diff\":{\"op\":\"insert\",\"at\":0,\"tracks\":[{\"id\":\"20599729\",\"albumId\":\"2347459\"}]}}"
	
	char str[BUFSIZ] = 
		"{\"diff\":{\"op\":\"insert\",\"at\":0,\"tracks\":[";

	int i;
	for (i = 0; i < count; ++i) {
		char track[128];
		sprintf(track, "{\"id\":\"%ld\", \"albumId\": \"%ld\"}", track_ids[i], album_ids[i]);
		strcat(str, track);
		if (i < count + 1)
			strcat(str, ", ");
	}
	strcat(str, "]}}");

	CURL *curl = curl_easy_init();
	if (curl){
		char *str_ = curl_easy_escape(curl, str, strlen(str));
		if (str_){
			char body[BUFSIZ];
			sprintf(body, "diff='\\''%s'\\''%%20&revision=0", str_);
			//printf("BODY: %s\n", body);
			//callback(user_data, body);
			ret =  c_yandex_music_run_method(
					"POST", token, body, &d, c_yandex_music_playlist_add_tracks_cb, 
					method, NULL);

			free(str_);
		}
		curl_easy_cleanup(curl);
	}
	return ret;
}
	

