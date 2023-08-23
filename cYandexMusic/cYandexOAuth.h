/**
 * File              : cYandexOAuth.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 12.08.2023
 * Last Modified Date: 22.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#ifndef C_YANDEX_OAUTH_H
#define C_YANDEX_OAUTH_H

#ifdef __cplusplus
extern "C" {
#endif

#define VERIFY_SSL 0L

/*
 * Получение OAuth-токенов
 * Яндекс авторизует приложения с помощью OAuth-токенов. 
 * Каждый токен предоставляет определенному приложению доступ 
 * к данным определенного пользователя.
 *
 * Чтобы использовать протокол OAuth:
 * 1. Зарегистрируйте свое OAuth-приложение.
 *		https://oauth.yandex.ru/client/new
 * 2. Подучите код подтверждения 
 *		выберите один из способов:
 *		2.1 Получение кода подтверждения из URL перенаправления:
 *
 *		2.2 Получение кода подтверждения от пользователя:
 *				2.2.1 Получить url от c_yandex_oauth_code_on_page
 *				2.2.2 Пользователь должен открыть url в браузере 
 *				и получить код (примеры в examples). 
 *				Получить код из html браузера можно:
 *				c_yandex_oauth_code_from_html
 *
 *		2.3 Ввод кода на странице авторизации Яндекс OAuth
 *				2.3.1 Получить device_code, user_code и url 
 *				для получения кода подтверждения от
 *				c_yandex_oauth_code_from_user
 *				2.3.2 Попросить пользователя перейти на страницу
 *				url и ввести user_code. Одновременно запусить
 *				c_yandex_oauth_get_token_from_user. Пункт 3 не нужен.
 *
 * 3. Получить токен:
 * c_yandex_oauth_get_token
*/

/* return allocated c null-terminated string
 * with url to get oauth code or NULL on error*/
char * c_yandex_oauth_code_on_page(const char *client_id);

/* return allocated c null-terminated string
 * with oauth code or NULL on error*/
char * c_yandex_oauth_code_from_html(const char *html);

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
		);

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
	);

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
		);

#ifdef __cplusplus
}  /* end of the 'extern "C"' block */
#endif

#endif /* ifndef C_YANDEX_OAUTH_H */
// vim:ft=c
