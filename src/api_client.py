import requests
from dotenv import load_dotenv
import os
from logger import setup_logging
import pandas as pd
from time import sleep

logger = setup_logging()

parent_dir = os.path.dirname(os.path.dirname(__file__))
load_dotenv(os.path.join(parent_dir, '.env'))

API_URL = os.getenv('API_URL')

max_attempts = 2
reques_timeout = 60
retry_delay = 10

def get_data(target_date):
    if not API_URL:
        raise ValueError('Переменная API_URL не найдена в .env')
    for attempt in range(1, max_attempts+1):
        try:
            logger.info(f'Запрос данных за {target_date}. Попытка {attempt}/{max_attempts}')
            response = requests.get(API_URL, params = {'date':target_date}, timeout=reques_timeout)
            logger.info(f'Дата:{target_date}, HTTP статус: {response.status_code}')
            response.raise_for_status()
            data = response.json()
            break
        except requests.exceptions.RequestException as error:
                if attempt == max_attempts:
                    logger.exception(f'Запрос данных за {target_date} завершился ошибкой после {max_attempts} попыток')
                    raise
                logger.warning(f'Ошибка запроса данных за {target_date}:{error}. Повтор через {retry_delay} секунд.')
                sleep(retry_delay)
    if not isinstance(data, list):
         raise ValueError(f'За {target_date} API вернул неожиданный тип: {type(data).__name__}')

    df = pd.DataFrame(data)
    logger.info(f'За {target_date} получено строк: {len(df)}')
    return df
    

