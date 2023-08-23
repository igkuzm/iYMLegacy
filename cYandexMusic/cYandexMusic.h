/**
 * File              : cYandexMusic.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 23.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#ifndef C_YM_H
#define C_YM_H

#ifdef __cplusplus
extern "C" {
#endif

#include "structures.h"

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

/* run yandex music api method and callbacks with playlists
 * Return 0 on success or -1 on error*/
int c_yandex_music_get_feed(
		const char *token,       // authorization token
		void *user_data, 
		int (*callback)         // callback for each track
														// return non-zero to stop function
				(void *user_data,
				 track_t * track,
				 const char *error));

#ifdef __cplusplus
}  /* end of the 'extern "C"' block */
#endif

#endif /* ifndef C_YM_H */
