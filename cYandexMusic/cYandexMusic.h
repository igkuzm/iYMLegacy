/**
 * File              : cYandexMusic.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 10.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#ifndef C_YM_H
#define C_YM_H

#ifdef __cplusplus
extern "C" {
#endif

#include "structures.h"

char * c_yandex_oauth_url();
char *c_yandex_oauth_token_from_html(
		const char *html);

/* run yandex music api method and callback json/error
 * Return 0 on success or -1 on error*/
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
		... );                   // - params list - NULL-terminate

/* return user id for token or 0 on error */
long c_yandex_music_get_uid(const char *token);

/* run yandex music api method and callbacks with recomended
 * tracks. Return 0 on success or -1 on error*/
int c_yandex_music_get_feed(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 playlist_t * playlist,
				 track_t * track,
				 const char *error));

/* run yandex music api method and callback download info
 * Return 0 on success or -1 on error*/
int c_yandex_music_get_download_url(
		const char *token,       // authorization token
		const char *track_id,    // track id
		void *user_data, 
		int (*callback)          // return non-zero to stop function
				(void *user_data,
				 const char * url,
				 const char *error));

int c_yandex_music_search(
		const char *token,       
		const char *search,    
		const char *image_size,	 // NULL - for original
		void *user_data, 
		int (*callback)
				(void *user_data,
				 playlist_t * playlist,
				 album_t * album,
				 track_t * track,
				 const char *error));

/* run yandex music api method and callbacks with playlist
 * tracks. Return 0 on success or -1 on error*/
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
				 const char *error));

int c_yandex_music_remove_playlist(
		const char *token,       // authorization token
		long playlist_uid,
		long playlist_kind,
		void *user_data, 
		void (*callback)          
				(void *user_data,
				 const char *error));




/* run yandex music api method and callbacks with album
 * tracks. Return 0 on success or -1 on error*/
int c_yandex_music_get_album_tracks(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		long album_id,
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 track_t * track,
				 const char *error));

/* run yandex music api method and callbacks with favofites
 * tracks for user. Return 0 on success or -1 on error*/
int c_yandex_music_get_user_playlists(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		long uid,                // user id
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 playlist_t * playlist,
				 const char *error));


/* run yandex music api method and callbacks with favofites
 * tracks for user. Return 0 on success or -1 on error*/
int c_yandex_music_get_favorites(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		long uid,                // user id
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 track_t * track,
				 const char *error));

int c_yandex_music_get_track_by_id(
		const char *token,       // authorization token
		const char *image_size,	 // NULL - for original
		const char *trackId,
		void *user_data, 
		int (*callback)          // callback for each track
														 // return non-zero to stop function
				(void *user_data,
				 track_t * track,
				 const char *error));

/* post to yandex music current playing track
 * %uuid is unique id of playing track - or 
 * NULL to generate new;
 * Return uuid on success or NULL on error */
char * c_yandex_music_post_current(
		const char *token,       // authorization token
		const char *uuid,        // uuid of playing track
		const char *trackId,
		int track_length_seconds,
		int track_played_seconds,
		long uid,                // user id
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *error));
	
int c_yandex_music_set_like_current(
		const char *token,       // authorization token
		long uid,                // user id
		const char *trackId,
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *error));
	
int c_yandex_music_set_unlike_current(
		const char *token,       // authorization token
		long uid,                // user id
		const char *trackId,
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *error));

// return NULL on error
playlist_t * c_yandex_music_create_playlist(
		const char *token,       // authorization token
		long uid,                // user id
		const char *title,
		void *user_data, 
		void (*callback)         // response and error handler - NULL-able
				(void *user_data,
				 const char *error));

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
				 const char *error));

#
#ifdef __cplusplus
}  /* end of the 'extern "C"' block */
#endif

#endif /* ifndef C_YM_H */
